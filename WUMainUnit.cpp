// Copyright (C) 2020-2020 Julian Uy
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <objidl.h>
#include <bcrypt.h>
#include "tvpsnd.h"

#define EXPORT(hr) extern "C" __declspec(dllexport) hr __stdcall

ITSSStorageProvider *StorageProvider = NULL;

extern "C" {
#ifndef __STDC_CONSTANT_MACROS
#define __STDC_CONSTANT_MACROS
#endif
#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif
#ifndef UINT64_C
#define UINT64_C(x) (x##ULL)
#endif
#include "libavutil/avutil.h"
#include "libavutil/opt.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
};

class FFMPEGWaveDecoder : public ITSSWaveDecoder
{
	ULONG RefCount;
	bool  IsPlanar;

	int            StreamIdx;
	int            audio_buf_index;
	int            audio_buf_samples;
	int64_t        audio_frame_next_pts;
	uint64_t       stream_start_time;
	TSSWaveFormat  TSSFormat;
	AVSampleFormat AVFmt;
	AVStream *     AudioStream;

	AVPacket         Packet;
	IStream *        InputStream;
	AVFormatContext *FormatCtx;
	AVCodecContext  *CodecCtx;
	AVFrame *        frame;


public:
	HRESULT Open(wchar_t *url);
	int     audio_decode_frame();
	void    Clear();
	bool    ReadPacket();

	FFMPEGWaveDecoder()
		: RefCount(1)
		, InputStream(nullptr)
		, FormatCtx(nullptr)
		, CodecCtx(nullptr)
		, frame(nullptr)
	{
		av_log_set_level(AV_LOG_QUIET);
#if 0
		av_register_all();
#endif
		memset(&Packet, 0, sizeof(Packet));
		memset(&TSSFormat, 0, sizeof(TSSFormat));
	}
	virtual ~FFMPEGWaveDecoder()
	{
		Clear();
	}

public:
	// IUnknown
	HRESULT __stdcall QueryInterface(REFIID iid, void **ppvObject);
	ULONG __stdcall AddRef(void);
	ULONG __stdcall Release(void);

	// ITSSWaveDecoder
	HRESULT __stdcall GetFormat(TSSWaveFormat *format);
	HRESULT __stdcall Render(void *buf, unsigned long bufsamplelen, unsigned long *rendered, unsigned long *status);
	HRESULT __stdcall SetPosition(unsigned __int64 samplepos);
};

HRESULT __stdcall FFMPEGWaveDecoder::QueryInterface(REFIID iid, void **ppvObject)
{
	if (!ppvObject)
	{
		return E_INVALIDARG;
	}

	*ppvObject = NULL;
	if (!memcmp(&iid, &IID_IUnknown, 16))
	{
		*ppvObject = (IUnknown *)this;
	}
	else if (!memcmp(&iid, &IID_ITSSWaveDecoder, 16))
	{
		*ppvObject = (ITSSWaveDecoder *)this;
	}

	if (*ppvObject)
	{
		AddRef();
		return S_OK;
	}
	return E_NOINTERFACE;
}

ULONG __stdcall FFMPEGWaveDecoder::AddRef()
{
	return ++RefCount;
}

ULONG __stdcall FFMPEGWaveDecoder::Release()
{
	if (RefCount == 1)
	{
		delete this;
		return 0;
	}
	else
	{
		return --RefCount;
	}
}

HRESULT __stdcall FFMPEGWaveDecoder::GetFormat(TSSWaveFormat *format)
{
	*format = TSSFormat;

	return S_OK;
}


static int AVReadFunc(void *opaque, uint8_t *buf, int buf_size)
{
	ULONG read;
	((IStream *)opaque)->Read((void *)buf, buf_size, &read);
	if (read == 0)
	{
		return AVERROR_EOF;
	}
	return read;
}

static int64_t AVSeekFunc(void *opaque, int64_t offset, int whence)
{
	if (whence == AVSEEK_SIZE)
	{
		STATSTG stg;
		((IStream *)opaque)->Stat(&stg, STATFLAG_NONAME);
		return stg.cbSize.QuadPart;
	}
	ULARGE_INTEGER curpos;
	((IStream *)opaque)->Seek((LARGE_INTEGER){(DWORD)offset}, whence & 0xFF, &curpos);
	return curpos.QuadPart;
}

template <typename T>
static unsigned char *_CopySamples(unsigned char *dst, AVFrame *frame, int samples, int buf_index)
{
	int buf_pos = buf_index * sizeof(T);
	T * pDst    = (T *)dst;
	for (int i = 0; i < samples; ++i, buf_pos += sizeof(T))
	{
		for (int j = 0; j < frame->channels; ++j)
		{
			*pDst++ = *(T *)(frame->data[j] + buf_pos);
		}
	}
	return (unsigned char *)pDst;
}

static unsigned char *CopySamples(unsigned char *dst, AVFrame *frame, int samples, int buf_index)
{
	switch (frame->format)
	{
		case AV_SAMPLE_FMT_FLTP:
		case AV_SAMPLE_FMT_S32P:
			return _CopySamples<uint32_t>(dst, frame, samples, buf_index);
		case AV_SAMPLE_FMT_S16P:
			return _CopySamples<uint16_t>(dst, frame, samples, buf_index);
		default:
			return nullptr;
	}
}

HRESULT FFMPEGWaveDecoder::Render(void *buf, unsigned long bufsamplelen,
								  unsigned long *rendered, unsigned long *status)
{
	if (!InputStream)
	{
		return E_FAIL;
	}
	int            remain      = bufsamplelen;
	int            sample_size = av_samples_get_buffer_size(NULL, TSSFormat.dwChannels, 1, AVFmt, 1);
	unsigned char *stream      = (unsigned char *)buf;
	while (remain)
	{
		if (audio_buf_index >= audio_buf_samples)
		{
			int decoded_samples = audio_decode_frame();
			if (decoded_samples < 0)
			{
				break;
			}
			audio_buf_samples = decoded_samples;
			audio_buf_index   = 0;
		}
		int samples = audio_buf_samples - audio_buf_index;
		if (samples > remain)
		{
			samples = remain;
		}

		if (!IsPlanar || TSSFormat.dwChannels == 1)
		{
			memcpy(stream, (frame->data[0] + audio_buf_index * sample_size), samples * sample_size);
			stream += samples * sample_size;
		}
		else
		{
			stream = CopySamples(stream, frame, samples, audio_buf_index);
		}
		remain -= samples;
		audio_buf_index += samples;
	}

	if (rendered)
	{
		*rendered = bufsamplelen - remain;
	}
	if (status)
	{
		*status = !remain;
	}

	return S_OK;
}

HRESULT FFMPEGWaveDecoder::SetPosition(unsigned __int64 samplepos)
{
	if (!InputStream)
	{
		return E_FAIL;
	}
	if (samplepos && !TSSFormat.dwSeekable)
	{
		return E_FAIL;
	}

	int64_t seek_target = samplepos / av_q2d(AudioStream->time_base) / TSSFormat.dwSamplesPerSec;
	if (AudioStream->start_time != AV_NOPTS_VALUE)
	{
		seek_target += AudioStream->start_time;
	}
	if (Packet.duration <= 0)
	{
		if (!ReadPacket())
		{
			int ret = avformat_seek_file(FormatCtx, StreamIdx, 0, 0, 0, AVSEEK_FLAG_BACKWARD);
			if (ret < 0)
			{
				return E_FAIL;
			}
			if (!ReadPacket())
			{
				return E_FAIL;
			}
		}
	}
	int64_t seek_temp = seek_target - Packet.duration;
	for (;;)
	{
		if (seek_temp < 0)
		{
			seek_temp = 0;
		}
		int ret = avformat_seek_file(FormatCtx, StreamIdx, seek_temp, seek_temp, seek_temp, AVSEEK_FLAG_BACKWARD);
		if (ret < 0)
		{
			return E_FAIL;
		}
		if (!ReadPacket())
		{
			return E_FAIL;
		}
		if (seek_target < Packet.dts)
		{
			seek_temp -= Packet.duration;
			continue;
		}
		do
		{
			audio_buf_samples = audio_decode_frame();
			if (audio_buf_samples < 0)
			{
				return E_FAIL;
			}
		} while ((int64_t)samplepos > audio_frame_next_pts);
		audio_buf_index = ((int64_t)samplepos - frame->pts);
		if (audio_buf_index < 0)
		{
			audio_buf_index = 0;
		}
		return S_OK;
	}
	return E_FAIL;
}

void FFMPEGWaveDecoder::Clear()
{
	av_packet_unref(&Packet);
	if (frame)
	{
		av_frame_free(&frame);
		frame = nullptr;
	}
	if (CodecCtx)
	{
		avcodec_free_context(&CodecCtx);
		CodecCtx = nullptr;
	}
	if (FormatCtx)
	{
#if 0
		for (unsigned int i = 0; i < FormatCtx->nb_streams; ++i)
		{
			avcodec_close(FormatCtx->streams[i]->codec);
		}
#endif
		av_free(FormatCtx->pb->buffer);
		av_free(FormatCtx->pb);
		avformat_close_input(&FormatCtx);
		FormatCtx = nullptr;
	}
	if (InputStream)
	{
		InputStream->Release();
		InputStream = nullptr;
	}
}

HRESULT FFMPEGWaveDecoder::Open(wchar_t *url)
{
	Clear();
	HRESULT hr = StorageProvider->GetStreamForRead(url, (IUnknown **)&InputStream);
	if (FAILED(hr))
	{
		InputStream = nullptr;
		return hr;
	}
	int          bufSize = 32 * 1024;
	AVIOContext *pIOCtx  = avio_alloc_context((unsigned char *)av_malloc(bufSize + AVPROBE_PADDING_SIZE), bufSize, 0, InputStream, AVReadFunc, 0, AVSeekFunc);

	const AVInputFormat *fmt = nullptr;
	char           holder[512];
	wcstombs(holder, url, sizeof(holder));
	av_probe_input_buffer2(pIOCtx, &fmt, holder, nullptr, 0, 0);
	AVFormatContext *ic = FormatCtx = avformat_alloc_context();
	ic->pb                          = pIOCtx;
	if (avformat_open_input(&ic, "", fmt, nullptr) < 0)
	{
		FormatCtx = nullptr;
		return E_FAIL;
	}
	if (avformat_find_stream_info(ic, nullptr) < 0)
	{
		return E_FAIL;
	}

	if (ic->pb)
	{
		ic->pb->eof_reached = 0;
	}

	const AVCodec* codec;
	StreamIdx = av_find_best_stream(ic, AVMEDIA_TYPE_AUDIO, -1, -1, &codec, 0);

	if (StreamIdx < 0 || StreamIdx == AVERROR_STREAM_NOT_FOUND)
	{
		return E_FAIL;
	}

	AVCodecContext *avctx = CodecCtx = avcodec_alloc_context3(codec);
	if (avctx == nullptr)
	{
		return E_FAIL;
	}

	AVStream *stream = FormatCtx->streams[StreamIdx];

	if (avcodec_parameters_to_context(avctx, stream->codecpar) < 0)
	{
		return E_FAIL;
	}

	avctx->workaround_bugs   = 1;
	avctx->error_concealment = 3;

	if (avcodec_open2(avctx, avcodec_find_decoder(avctx->codec_id), nullptr) < 0)
	{
		return E_FAIL;
	}

	memset(&TSSFormat, 0, sizeof(TSSFormat));

	TSSFormat.dwSamplesPerSec = avctx->sample_rate;
	TSSFormat.dwChannels      = avctx->channels;
	TSSFormat.dwSeekable =
		(FormatCtx->iformat->flags & (AVFMT_NOBINSEARCH | AVFMT_NOGENSEARCH | AVFMT_NO_BYTE_SEEK)) != (AVFMT_NOBINSEARCH | AVFMT_NOGENSEARCH | AVFMT_NO_BYTE_SEEK);
	switch (AVFmt = avctx->sample_fmt)
	{
		case AV_SAMPLE_FMT_S16P:
		case AV_SAMPLE_FMT_S16:
			TSSFormat.dwBitsPerSample = 16;
			break;
		case AV_SAMPLE_FMT_FLTP:
		case AV_SAMPLE_FMT_FLT:
			TSSFormat.dwBitsPerSample = 32;
			TSSFormat.dwBitsPerSample += 0x10000; // to identify as float
			break;
		case AV_SAMPLE_FMT_S32P:
		case AV_SAMPLE_FMT_S32:
			TSSFormat.dwBitsPerSample = 32;
			break;
		default:
			return E_FAIL;
	}
	IsPlanar = false;
	if (AVFmt == AV_SAMPLE_FMT_S16P ||
		AVFmt == AV_SAMPLE_FMT_FLTP ||
		AVFmt == AV_SAMPLE_FMT_S32P)
	{
		IsPlanar = true;
	}
	AudioStream                = stream;
	TSSFormat.dwTotalTime      = av_q2d(AudioStream->time_base) * AudioStream->duration * 1000;
	TSSFormat.ui64TotalSamples = av_q2d(AudioStream->time_base) * AudioStream->duration * TSSFormat.dwSamplesPerSec;

	audio_buf_index       = 0;
	audio_buf_samples     = 0;
	audio_frame_next_pts  = 0;

	return S_OK;
}

int FFMPEGWaveDecoder::audio_decode_frame()
{
#if 0
	AVStream *      audio_st = AudioStream;
#endif
	AVCodecContext *dec      = CodecCtx;
	if (!frame)
	{
		frame = av_frame_alloc();
	}
	for (;;)
	{
		for (;;)
		{
			av_frame_unref(frame);

			int frame_ret = avcodec_receive_frame(dec, frame);
			if (frame_ret == AVERROR(EAGAIN))
			{
				break;
			}
			if (frame_ret < 0)
			{
				// Error
				return -1;
			}

			AVRational tb = {1, frame->sample_rate};

			if (frame->pts != AV_NOPTS_VALUE)
			{
				frame->pts = av_rescale_q(frame->pts, dec->time_base, tb);
			}
#if 0
			else if (frame->pkt_pts != AV_NOPTS_VALUE)
			{
				frame->pts = av_rescale_q(frame->pkt_pts, audio_st->time_base, tb);
			}
#endif
			else if (audio_frame_next_pts != AV_NOPTS_VALUE)
			{
				AVRational a = {1, (int)TSSFormat.dwSamplesPerSec};
				frame->pts   = av_rescale_q(audio_frame_next_pts, a, tb);
			}

			if (frame->pts != AV_NOPTS_VALUE)
			{
				audio_frame_next_pts = frame->pts + frame->nb_samples;
			}

			return frame->nb_samples;
		}

		if (!ReadPacket())
		{
			return -1;
		}

		int packet_result = avcodec_send_packet(dec, &Packet);
		if (packet_result < 0)
		{
		    return -1;
		}
	}
	return -1;
}

bool FFMPEGWaveDecoder::ReadPacket()
{
	for (;;)
	{
		av_packet_unref(&Packet);

		int ret = av_read_frame(FormatCtx, &Packet);
		if (ret < 0)
		{
			return false;
		}
		if (Packet.stream_index == StreamIdx)
		{
			stream_start_time = AudioStream->start_time;
			return true;
		}
	}
	return false;
}


class FFMPEGWaveDecoderModule : public ITSSModule
{
	ULONG RefCount;

public:
	FFMPEGWaveDecoderModule();
	virtual ~FFMPEGWaveDecoderModule();

public:
	// IUnknown
	HRESULT __stdcall QueryInterface(REFIID iid, void **ppvObject);
	ULONG __stdcall AddRef(void);
	ULONG __stdcall Release(void);

	// ITSSModule
	HRESULT __stdcall GetModuleCopyright(LPWSTR buffer, unsigned long buflen);
	HRESULT __stdcall GetModuleDescription(LPWSTR buffer, unsigned long buflen);
	HRESULT __stdcall GetSupportExts(unsigned long index, LPWSTR mediashortname, LPWSTR buf, unsigned long buflen);
	HRESULT __stdcall GetMediaInfo(LPWSTR url, ITSSMediaBaseInfo **info);
	HRESULT __stdcall GetMediaSupport(LPWSTR url);
	HRESULT __stdcall GetMediaInstance(LPWSTR url, IUnknown **instance);
};

FFMPEGWaveDecoderModule::FFMPEGWaveDecoderModule()
{
	RefCount = 1;
}

FFMPEGWaveDecoderModule::~FFMPEGWaveDecoderModule()
{
}


HRESULT __stdcall FFMPEGWaveDecoderModule::QueryInterface(REFIID iid, void **ppvObject)
{
	if (!ppvObject)
	{
		return E_INVALIDARG;
	}

	*ppvObject = NULL;
	if (!memcmp(&iid, &IID_IUnknown, 16))
	{
		*ppvObject = (IUnknown *)this;
	}
	else if (!memcmp(&iid, &IID_ITSSModule, 16))
	{
		*ppvObject = (ITSSModule *)this;
	}

	if (*ppvObject)
	{
		AddRef();
		return S_OK;
	}
	return E_NOINTERFACE;
}

ULONG __stdcall FFMPEGWaveDecoderModule::AddRef()
{
	return ++RefCount;
}

ULONG __stdcall FFMPEGWaveDecoderModule::Release()
{
	if (RefCount == 1)
	{
		delete this;
		return 0;
	}
	else
	{
		return --RefCount;
	}
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetModuleCopyright(LPWSTR buffer, unsigned long buflen)
{
	wcsncpy(buffer, L"ffmpeg decoder for TVP Sound System Copyright (C) 2020-2020 Julian Uy", buflen);
	return S_OK;
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetModuleDescription(LPWSTR buffer, unsigned long buflen)
{
	wcsncpy(buffer, L"ffmpeg decoder for TVP Sound System", buflen);
	return S_OK;
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetSupportExts(unsigned long index, LPWSTR mediashortname, LPWSTR buf, unsigned long buflen)
{
	if (index >= 1)
	{
		return S_FALSE;
	}
	wcscpy(mediashortname, L"ffmpeg supported file");
	wcsncpy(buf, L"", buflen); // Allow any extension.
	return S_OK;
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetMediaInfo(LPWSTR url, ITSSMediaBaseInfo **info)
{
	return E_NOTIMPL;
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetMediaSupport(LPWSTR url)
{
	return E_NOTIMPL;
}

HRESULT __stdcall FFMPEGWaveDecoderModule::GetMediaInstance(LPWSTR url, IUnknown **instance)
{
	HRESULT            hr;
	FFMPEGWaveDecoder *decoder = new FFMPEGWaveDecoder();
	hr                         = decoder->Open(url);
	if (FAILED(hr))
	{
		delete decoder;
		return hr;
	}

	*instance = (IUnknown *)decoder;

	return S_OK;
}

EXPORT(HRESULT)
GetModuleInstance(ITSSModule **out, ITSSStorageProvider *provider, IStream *config, HWND mainwin)
{
	StorageProvider = provider;
	*out            = new FFMPEGWaveDecoderModule();
	return S_OK;
}

// Stub for bcrypt, to lower system requirement
extern "C" NTSTATUS BCryptOpenAlgorithmProvider(BCRYPT_ALG_HANDLE *phAlgorithm, LPCWSTR pszAlgId, LPCWSTR pszImplementation, ULONG dwFlags)
{
	return STATUS_INVALID_PARAMETER;
}

extern "C" NTSTATUS BCryptGenRandom(BCRYPT_ALG_HANDLE hAlgorithm, PUCHAR pbBuffer, ULONG cbBuffer, ULONG dwFlags)
{
	return STATUS_INVALID_PARAMETER;
}

extern "C" NTSTATUS BCryptCloseAlgorithmProvider(BCRYPT_ALG_HANDLE hAlgorithm, ULONG dwFlags)
{
	return STATUS_INVALID_PARAMETER;
}
