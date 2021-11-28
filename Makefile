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

DEPENDENCY_BUILD_DIRECTORY := build-$(TARGET_ARCH)
DEPENDENCY_BUILD_DIRECTORY_FFMPEG := $(DEPENDENCY_BUILD_DIRECTORY)/ffmpeg

FFMPEG_PATH := $(realpath external/ffmpeg)

DEPENDENCY_OUTPUT_DIRECTORY := $(shell realpath build-libraries)-$(TARGET_ARCH)

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

$(FFMPEG_LIBS): $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FFMPEG) && \
	$(FFMPEG_PATH)/configure \
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
		--arch=$(FFMPEG_ARCH) \
		--enable-cross-compile \
		--cross-prefix=$(TOOL_TRIPLET_PREFIX) \
		--target-os=mingw64 \
	&& \
	$(MAKE) && \
	$(MAKE) install

clean::
	rm -rf $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)
