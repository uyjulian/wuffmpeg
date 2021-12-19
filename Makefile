# Copyright (C) 2020-2021 Julian Uy
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

BASESOURCES += WUMainUnit.cpp
SOURCES += $(BASESOURCES)

PROJECT_BASENAME = wuffmpeg

USE_TVPSND = 1

RC_FILEDESCRIPTION ?= ffmpeg decoder for TVP Sound System
RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2021 Julian Uy; This product is licensed under the GNU Lesser General Public License version 2.1 or (at your option) any later version.
RC_PRODUCTNAME ?= ffmpeg decoder for TVP Sound System

include external/tp_stubz/Rules.lib.make

DEPENDENCY_SOURCE_DIRECTORY := $(abspath build-source)
DEPENDENCY_SOURCE_DIRECTORY_FFMPEG := $(DEPENDENCY_SOURCE_DIRECTORY)/ffmpeg

DEPENDENCY_SOURCE_FILE_FFMPEG := $(DEPENDENCY_SOURCE_DIRECTORY)/ffmpeg.tar.xz

DEPENDENCY_SOURCE_URL_FFMPEG := https://ffmpeg.org/releases/ffmpeg-4.4.1.tar.xz

$(DEPENDENCY_SOURCE_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_SOURCE_FILE_FFMPEG): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_FFMPEG)

$(DEPENDENCY_SOURCE_DIRECTORY_FFMPEG): $(DEPENDENCY_SOURCE_FILE_FFMPEG)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

DEPENDENCY_BUILD_DIRECTORY := $(abspath build-$(TARGET_ARCH))
DEPENDENCY_BUILD_DIRECTORY_FFMPEG := $(DEPENDENCY_BUILD_DIRECTORY)/ffmpeg

DEPENDENCY_OUTPUT_DIRECTORY := $(abspath build-libraries)-$(TARGET_ARCH)

FFMPEG_LIBS := $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libavformat.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libavcodec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libswresample.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libswscale.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libavutil.a

ifeq (xintel32,x$(TARGET_ARCH))
    FFMPEG_ARCH := x86
endif

ifeq (xintel64,x$(TARGET_ARCH))
    FFMPEG_ARCH := x86_64
endif

ifeq (xarm32,x$(TARGET_ARCH))
    FFMPEG_ARCH := arm
endif

ifeq (xarm64,x$(TARGET_ARCH))
    FFMPEG_ARCH := aarch64
endif

FFMPEG_ARCH ?= x86

EXTLIBS += $(FFMPEG_LIBS)
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

$(BASESOURCES): $(EXTLIBS)

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_BUILD_DIRECTORY_FFMPEG): | $(DEPENDENCY_SOURCE_DIRECTORY_FFMPEG) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG) && \
	$(DEPENDENCY_SOURCE_DIRECTORY_FFMPEG)/configure \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-optimizations \
		--disable-avdevice \
		--disable-cuda \
		--disable-cuvid \
		--disable-debug \
		--disable-doc \
		--disable-nvenc \
		--disable-postproc \
		--disable-programs \
		--disable-pthreads \
		--disable-schannel \
		--disable-shared \
		--disable-audiotoolbox \
		--disable-d3d11va \
		--disable-dxva2 \
		--enable-swresample \
		--enable-runtime-cpudetect \
		--enable-static \
		--enable-w32threads \
		--disable-everything \
		--disable-protocols \
		--disable-network \
		--disable-devices \
		--enable-decoders \
		--disable-decoder=imm5,rawvideo,wrapped_avframe,xface,yop,012v,4xm,8bps,aasc,agm,alias_pix,amv,anm,ansi,arbc,argo,asv1,asv2,aura,aura2,av1,avrn,avrp,avs,avui,ayuv,bethsoftvid,bfi,binkvideo,bintext,bmp,bmv_video,brender_pix,c93,camstudio,camtasia,cavs,cdgraphics,cdtoons,cdxl,cinepak,clearvideo,cljr,cpia,cyuv,dfa,dpx,dsicinvideo,dxa,eacmv,eamad,eatgq,eatgv,eatqi,escape124,escape130,fits,flashsv,flashsv2,flic,fmvc,frwu,g2m,gdv,gif,h261,hnm4video,hq_hqa,idcinvideo,idf,iff,imm4,indeo2,indeo3,indeo4,indeo5,interplayvideo,ipu,jpegls,jv,kgv1,kmvc,loco,lscr,m101,mjpeg,mjpegb,mmvideo,mobiclip,motionpixels,msa1,mscc,msp2,msrle,mss1,mss2,msvideo1,mts2,mv30,mvc1,mvc2,mvdv,mvha,mwsc,mxpeg,nuv,paf_video,pam,pbm,pcx,pfm,pgm,pgmyuv,pgx,pictor,ppm,prosumer,ptx,qdraw,qpeg,qtrle,r10k,r210,rasc,rl2,roqvideo,rpza,rscc,rv10,rv20,sanm,scpr,screenpresso,sga,sgi,sgirle,simbiosis_imx,smackvid,smc,smvjpeg,snow,sp5x,speedhq,srgc,sunrast,svq1,targa,targa_y216,tdsc,thp,tiertexseqvideo,tmv,truemotion1,truemotion2,truemotion2rt,tscc2,txd,ultimotion,v210x,v308,v408,vb,vc1,vc1image,vcr1,vmdvideo,vmnc,vp5,vp6,vp6f,vp7,vqavideo,wcmv,wmv3,wmv3image,wnv1,xan_wc3,xan_wc4,xbin,xbm,xl,xpm,xwd,y41p,yuv4,zerocodec,zmbv,flv,h263,h263i,h263p,msmpeg4,msmpeg4v1,msmpeg4v2,svq3,wmv1,wmv2,bitpacked,dds,dirac,fic,vp6a,mpeg1video,mpeg2video,mpegvideo,aic,apng,cfhd,cllc,cri,dxtory,fraps,lagarith,mdec,mimic,mszh,notchlc,photocd,pixlet,png,psd,rv30,rv40,sheervideo,tiff,utvideo,vble,webp,ylc,ffvhuff,huffyuv,hymt,mpeg4,theora,vp3,vp4,dnxhd,dvvideo,dxv,exr,ffv1,h264,hap,hevc,hqx,jpeg2000,magicyuv,prores,v210,v410,vp8,vp9 \
		--arch=$(FFMPEG_ARCH) \
		--enable-cross-compile \
		--cross-prefix=$(TOOL_TRIPLET_PREFIX) \
		--target-os=mingw64

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig/libavformat.pc: | $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG)
	cd $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG) && \
	$(MAKE) && \
	$(MAKE) install

$(FFMPEG_LIBS): $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig/libavformat.pc

clean::
	rm -rf $(DEPENDENCY_SOURCE_DIRECTORY) $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)
