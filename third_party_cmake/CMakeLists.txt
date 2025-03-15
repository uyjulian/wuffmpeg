# Copyright (c) third_party_cmake developers

cmake_minimum_required(VERSION 3.0)
project(third_party_cmake)

if((NOT DEFINED CMAKE_BUILD_TYPE) OR (NOT CMAKE_BUILD_TYPE) OR (CMAKE_BUILD_TYPE STREQUAL ""))
set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

set(DEPENDENCY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build-libraries)
file(MAKE_DIRECTORY ${DEPENDENCY_OUTPUT_DIRECTORY}/include)

include(ExternalProject)

if(NOT DEFINED TOOL_TRIPLET_PREFIX)
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL i686)
set(TOOL_TRIPLET_PREFIX i686-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL amd64)
set(TOOL_TRIPLET_PREFIX x86_64-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm)
set(TOOL_TRIPLET_PREFIX armv7-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm64)
set(TOOL_TRIPLET_PREFIX aarch64-w64-mingw32-)
endif()
if(NOT DEFINED TOOL_TRIPLET_PREFIX)
set(TOOL_TRIPLET_PREFIX i686-w64-mingw32-)
endif()
endif()
if(NOT DEFINED FFMPEG_ARCH)
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL i686)
set(FFMPEG_ARCH x86)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL amd64)
set(FFMPEG_ARCH x86_64)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm)
set(FFMPEG_ARCH arm)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm64)
set(FFMPEG_ARCH aarch64)
endif()
if(NOT DEFINED FFMPEG_ARCH)
set(FFMPEG_ARCH x86)
endif()
endif()

ExternalProject_Add(ffmpeg-build
    URL https://ffmpeg.org/releases/ffmpeg-5.0.tar.xz
    URL_HASH SHA256=51e919f7d205062c0fd4fae6243a84850391115104ccf1efc451733bc0ac7298
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND
		<SOURCE_DIR>/configure
			"--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
			--enable-optimizations
			--disable-asm
			--disable-avdevice
			--disable-cuda
			--disable-cuvid
			--disable-debug
			--disable-doc
			--disable-nvenc
			--disable-postproc
			--disable-programs
			--disable-pthreads
			--disable-schannel
			--disable-shared
			--disable-audiotoolbox
			--disable-d3d11va
			--disable-dxva2
			--enable-swresample
			--enable-runtime-cpudetect
			--enable-static
			--enable-w32threads
			--disable-everything
			--disable-protocols
			--disable-network
			--disable-devices
			--enable-decoders
			--enable-demuxers
			--disable-decoder=imm5,rawvideo,wrapped_avframe,xface,yop,012v,4xm,8bps,aasc,agm,alias_pix,amv,anm,ansi,arbc,argo,asv1,asv2,aura,aura2,av1,avrn,avrp,avs,avui,ayuv,bethsoftvid,bfi,binkvideo,bintext,bmp,bmv_video,brender_pix,c93,camstudio,camtasia,cavs,cdgraphics,cdtoons,cdxl,cinepak,clearvideo,cljr,cpia,cyuv,dfa,dpx,dsicinvideo,dxa,eacmv,eamad,eatgq,eatgv,eatqi,escape124,escape130,fits,flashsv,flashsv2,flic,fmvc,frwu,g2m,gdv,gif,h261,hnm4video,hq_hqa,idcinvideo,idf,iff,imm4,indeo2,indeo3,indeo4,indeo5,interplayvideo,ipu,jpegls,jv,kgv1,kmvc,loco,lscr,m101,mjpeg,mjpegb,mmvideo,mobiclip,motionpixels,msa1,mscc,msp2,msrle,mss1,mss2,msvideo1,mts2,mv30,mvc1,mvc2,mvdv,mvha,mwsc,mxpeg,nuv,paf_video,pam,pbm,pcx,pfm,pgm,pgmyuv,pgx,pictor,ppm,prosumer,ptx,qdraw,qpeg,qtrle,r10k,r210,rasc,rl2,roqvideo,rpza,rscc,rv10,rv20,sanm,scpr,screenpresso,sga,sgi,sgirle,simbiosis_imx,smackvid,smc,smvjpeg,snow,sp5x,speedhq,srgc,sunrast,svq1,targa,targa_y216,tdsc,thp,tiertexseqvideo,tmv,truemotion1,truemotion2,truemotion2rt,tscc2,txd,ultimotion,v210x,v308,v408,vb,vc1,vc1image,vcr1,vmdvideo,vmnc,vp5,vp6,vp6f,vp7,vqavideo,wcmv,wmv3,wmv3image,wnv1,xan_wc3,xan_wc4,xbin,xbm,xl,xpm,xwd,y41p,yuv4,zerocodec,zmbv,flv,h263,h263i,h263p,msmpeg4,msmpeg4v1,msmpeg4v2,svq3,wmv1,wmv2,bitpacked,dds,dirac,fic,vp6a,mpeg1video,mpeg2video,mpegvideo,aic,apng,cfhd,cllc,cri,dxtory,fraps,lagarith,mdec,mimic,mszh,notchlc,photocd,pixlet,png,psd,rv30,rv40,sheervideo,tiff,utvideo,vble,webp,ylc,ffvhuff,huffyuv,hymt,mpeg4,theora,vp3,vp4,dnxhd,dvvideo,dxv,exr,ffv1,h264,hap,hevc,hqx,jpeg2000,magicyuv,prores,v210,v410,vp8,vp9
			--arch=${FFMPEG_ARCH}
			--enable-cross-compile
			--cross-prefix=${TOOL_TRIPLET_PREFIX}
			--target-os=mingw64
    BUILD_COMMAND make -C <BINARY_DIR> && make -C <BINARY_DIR> install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libavformat.a ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libavcodec.a ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libswresample.a ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libswscale.a ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libavutil.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS ffmpeg-build)

foreach(CUR_DEPEND IN LISTS THIRDPARTY_DEPENDS)
ExternalProject_Get_Property(${CUR_DEPEND} BUILD_BYPRODUCTS)
list(APPEND THIRDPARTY_LIBRARIES ${BUILD_BYPRODUCTS})
endforeach()

add_custom_command(
    OUTPUT ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a
    COMMAND 
    	printf 'create %s\\n' ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a > ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	printf 'addlib %s\\n' ${THIRDPARTY_LIBRARIES} >> ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	printf 'save\\nend\\n' >> ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	cat ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri | ${CMAKE_AR} -M
    DEPENDS ${THIRDPARTY_DEPENDS}
)

add_custom_command(
	OUTPUT ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
	COMMAND touch ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
	DEPENDS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a
)

add_custom_target(main_output_target
	ALL
	DEPENDS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
)
