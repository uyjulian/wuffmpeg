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
