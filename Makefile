# Copyright (C) 2020-2020 Julian Uy
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

CC = i686-w64-mingw32-gcc
CXX = i686-w64-mingw32-g++
AR = i686-w64-mingw32-ar
ASM = nasm
WINDRES = i686-w64-mingw32-windres
STRIP = i686-w64-mingw32-strip
GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I.. -Iexternal/ffmpeg -Iexternal/ffmpeg/build
ALLSRCFLAGS += $(INCFLAGS) -DGIT_TAG=\"$(GIT_TAG)\"
ASMFLAGS += $(ALLSRCFLAGS) -fwin32 -DWIN32
CFLAGS += -O3 -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DUNICODE -D_UNICODE 
CXXFLAGS += $(CFLAGS)
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += -static -static-libgcc -shared -Wl,--kill-at
LDLIBS += -lws2_32 -lbcrypt -luuid

%.o: %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) -o $@ $<

%.o: %.asm
	@printf '\t%s %s\n' ASM $<
	$(ASM) $(ASMFLAGS) $< -o$@ 

%.o: %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

FFMPEG_SOURCES += external/ffmpeg/build/libavformat/libavformat.a external/ffmpeg/build/libavcodec/libavcodec.a external/ffmpeg/build/libswresample/libswresample.a external/ffmpeg/build/libswscale/libswscale.a external/ffmpeg/build/libavutil/libavutil.a
SOURCES := tvpsnd.c WUMainUnit.cpp wuffmpeg.rc $(FFMPEG_SOURCES)
OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.asm=.o)
OBJECTS := $(OBJECTS:.rc=.o)

BINARY ?= wuffmpeg-unstripped.dll
BINARY_STRIPPED ?= wuffmpeg.dll
ARCHIVE ?= wuffmpeg.$(GIT_TAG).7z

all: $(BINARY)

archive: $(ARCHIVE)

clean:
	rm -f $(OBJECTS) $(BINARY) $(ARCHIVE)
	rm -rf external/ffmpeg/build

$(FFMPEG_SOURCES):
	cd external/ffmpeg && mkdir build && cd build && ../configure --disable-avdevice --disable-cuda --disable-cuvid --disable-debug --disable-doc --disable-nvenc --disable-postproc --disable-programs --disable-pthreads --disable-schannel --disable-shared --disable-audiotoolbox --disable-d3d11va --disable-dxva2 --enable-swresample --enable-runtime-cpudetect --enable-static --enable-w32threads --disable-everything --disable-protocols --disable-network --disable-devices --enable-decoder=8svx_exp,8svx_fib,aac,aac_fixed,aac_latm,ac3,ac3_fixed,adpcm_4xm,adpcm_adx,adpcm_afc,adpcm_agm,adpcm_aica,adpcm_ct,adpcm_dtk,adpcm_ea,adpcm_ea_maxis_xa,adpcm_ea_r1,adpcm_ea_r2,adpcm_ea_r3,adpcm_ea_xas,g722,g726,g726le,adpcm_ima_amv,adpcm_ima_apc,adpcm_ima_dat4,adpcm_ima_dk3,adpcm_ima_dk4,adpcm_ima_ea_eacs,adpcm_ima_ea_sead,adpcm_ima_iss,adpcm_ima_oki,adpcm_ima_qt,adpcm_ima_rad,adpcm_ima_smjpeg,adpcm_ima_wav,adpcm_ima_ws,adpcm_ms,adpcm_mtaf,adpcm_psx,adpcm_sbpro_2,adpcm_sbpro_3,adpcm_sbpro_4,adpcm_swf,adpcm_thp,adpcm_thp_le,adpcm_vima,adpcm_xa,adpcm_yamaha,alac,amrnb,amrwb,ape,aptx,aptx_hd,atrac1,atrac3,atrac3al,atrac3plus,atrac3plusal,atrac9,on2avc,binkaudio_dct,binkaudio_rdft,bmv_audio,comfortnoise,cook,dolby_e,dsd_lsbf,dsd_lsbf_planar,dsd_msbf,dsd_msbf_planar,dsicinaudio,dss_sp,dst,dca,dvaudio,eac3,evrc,flac,g723_1,g729,gremlin_dpcm,gsm,gsm_ms,hcom,iac,imc,interplay_dpcm,interplayacm,mace3,mace6,metasound,mlp,mp1,mp1float,mp2,mp2float,mp3float,mp3,mp3adufloat,mp3adu,mp3on4float,mp3on4,als,mpc7,mpc8,nellymoser,opus,paf_audio,pcm_alaw,pcm_bluray,pcm_dvd,pcm_f16le,pcm_f24le,pcm_f32be,pcm_f32le,pcm_f64be,pcm_f64le,pcm_lxf,pcm_mulaw,pcm_s16be,pcm_s16be_planar,pcm_s16le,pcm_s16le_planar,pcm_s24be,pcm_s24daud,pcm_s24le,pcm_s24le_planar,pcm_s32be,pcm_s32le,pcm_s32le_planar,pcm_s64be,pcm_s64le,pcm_s8,pcm_s8_planar,pcm_u16be,pcm_u16le,pcm_u24be,pcm_u24le,pcm_u32be,pcm_u32le,pcm_u8,pcm_vidc,pcm_zork,qcelp,qdm2,qdmc,real_144,real_288,ralf,roq_dpcm,s302m,sbc,sdx2_dpcm,shorten,sipr,smackaud,sol_dpcm,tak,truehd,truespeech,tta,twinvq,vmdaudio,vorbis,wavesynth,wavpack,ws_snd1,wmalossless,wmapro,wmav1,wmav2,wmavoice,xan_dpcm,xma1,xma2 --enable-demuxer=3dostr,4xm,aa,aac,ac3,acm,act,adf,adp,ads,adx,aea,afc,aiff,aix,alaw,alias_pix,amr,amrnb,amrwb,anm,apc,ape,apng,aptx,aptx_hd,aqtitle,asf,asf_o,ass,ast,au,avfoundation,avi,avr,avs,avs2,bethsoftvid,bfi,bfstm,bin,bink,bit,bmp_pipe,bmv,boa,brender_pix,brstm,c93,caf,cavsvideo,cdg,cdxl,cine,codec2,codec2raw,concat,data,daud,dcstr,dds_pipe,dfa,dhav,dirac,dnxhd,dpx_pipe,dsf,dsicin,dss,dts,dtshd,dv,dvbsub,dvbtxt,dxa,ea,ea_cdata,eac3,epaf,exr_pipe,f32be,f32le,f64be,f64le,ffmetadata,film_cpk,filmstrip,fits,flac,flic,flv,frm,fsb,g722,g723_1,g726,g726le,g729,gdv,genh,gif,gif_pipe,gsm,gxf,h261,h263,h264,hcom,hevc,hls,hnm,ico,idcin,idf,iff,ifv,image2,image2pipe,ingenient,ipmovie,ircam,iss,iv8,ivf,ivr,j2k_pipe,jacosub,jpeg_pipe,jpegls_pipe,jv,kux,live_flv,lmlm4,loas,lrc,lvf,lxf,m4v,matroska,mgsts,microdvd,mjpeg,mjpeg_2000,mlp,mlv,mm,mmf,mov,mp3,mpc,mpc8,mpeg,mpegts,mpegtsraw,mpegvideo,mpjpeg,mpl2,mpsub,msf,msnwctcp,mtaf,mtv,mulaw,musx,mv,mvi,mxf,mxg,nc,nistsphere,nsp,nsv,nut,nuv,ogg,oma,paf,pam_pipe,pbm_pipe,pcx_pipe,pgm_pipe,pgmyuv_pipe,pictor_pipe,pjs,pmp,png_pipe,ppm_pipe,psd_pipe,psxstr,pva,pvf,qcp,qdraw_pipe,r3d,rawvideo,realtext,redspark,rl2,rm,roq,rpl,rsd,rso,rtp,rtsp,s16be,s16le,s24be,s24le,s32be,s32le,s337m,s8,sami,sap,sbc,sbg,scc,sdp,sdr2,sds,sdx,ser,sgi_pipe,shn,siff,sln,smjpeg,smk,smush,sol,sox,spdif,srt,stl,subviewer,subviewer1,sunrast_pipe,sup,svag,svg_pipe,swf,tak,tedcaptions,thp,tiertexseq,tiff_pipe,tmv,truehd,tta,tty,txd,ty,u16be,u16le,u24be,u24le,u32be,u32le,u8,v210,v210x,vag,vc1,vc1test,vidc,vividas,vivo,vmd,vobsub,voc,vpk,vplayer,vqf,w64,wav,wc3movie,webm_dash_manifest,webp_pipe,webvtt,wsaud,wsd,wsvqa,wtv,wv,wve,xa,xbin,xmv,xpm_pipe,xvag,xwd_pipe,xwma,yop,yuv4mpegpipe --enable-parser=aac,aac_latm,ac3,adx,av1,avs2,bmp,cavsvideo,cook,dca,dirac,dnxhd,dpx,dvaudio,dvbsub,dvd_nav,dvdsub,flac,g723_1,g729,gif,gsm,h261,h263,h264,hevc,mjpeg,mlp,mpeg4video,mpegaudio,mpegvideo,opus,png,pnm,rv30,rv40,sbc,sipr,tak,vc1,vorbis,vp3,vp8,vp9,xma --arch=x86 --enable-cross-compile --cross-prefix=i686-w64-mingw32- --target-os=mingw32 && $(MAKE)

WUMainUnit.cpp: $(FFMPEG_SOURCES)

$(BINARY_STRIPPED): $(BINARY)
	$(STRIP) $^ -o $@

$(ARCHIVE): $(BINARY_STRIPPED) README.md supported_list.md LICENSE
	rm -f $(ARCHIVE)
	7z a $@ $^

$(BINARY): $(OBJECTS) 
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)
