#!/bin/bash

_IM_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$_IM_ENV_DIR/scripts/delegates-manifest.sh"

# Verbose output or clean output
export VERBOSE=0
export OUTPUT_FILE="$(pwd)/$(date +%Y%m%d-%H%M)_im.log"

export ARCHS="${ARCHS:-mac-arm64}"
export ENABLE_FAT="${ENABLE_FAT:-0}"
export BUILD_GHOSTSCRIPT="${BUILD_GHOSTSCRIPT:-0}"
export USE_JPEG_TURBO="${USE_JPEG_TURBO:-1}"
export ENABLE_HEIF="${ENABLE_HEIF:-1}"
export ENABLE_ICU="${ENABLE_ICU:-1}"

export CORESNUM=$(sysctl hw.ncpu | awk '{print $2}')

export SDKMINVER=9.0
export SDKVER=$(xcodebuild -showsdks | fgrep "iphoneos" | tail -n 1 | awk '{print $2}')
export DEVROOT=$(xcode-select -print-path)/Platforms/iPhoneOS.platform/Developer
export IOSSDKROOT=$DEVROOT/SDKs/iPhoneOS$SDKVER.sdk

if [ ! -d "$DEVROOT" ]; then
	echo "Unable to find the XCode"
	echo "The path is automatically set from 'xcode-select -print-path'"
	echo
	echo "Ensure that 'xcode-select -print-path' works (e.g., Install XCode)"
	exit 1
fi

export SIMSDKVER=$(xcodebuild -showsdks | fgrep "iphonesimulator" | tail -n 1 | awk '{print $4}')
export SIMDEVROOT=$(xcode-select -print-path)/Platforms/iPhoneSimulator.platform/Developer
export SIMSDKROOT=$SIMDEVROOT/SDKs/iPhoneSimulator$SIMSDKVER.sdk

export IMROOT="$(pwd)"
export BUILDROOT="$IMROOT/build"
export IM_DIR="$BUILDROOT/ImageMagick-$IM_VERSION"
export IM_DELEGATES_DIR="$IM_DIR/IMDelegates/"

export ZLIB_DIR="$IM_DIR/IMDelegates/$DM_ZLIB_DIR"
export ICONV_DIR="$IM_DIR/IMDelegates/$DM_ICONV_DIR"
export ICU_DIR="$IM_DIR/IMDelegates/icu/source"
export XML2_DIR="$IM_DIR/IMDelegates/$DM_XML2_DIR"
export FFTW_DIR="$IM_DIR/IMDelegates/$DM_FFTW_DIR"
export JPEG_TURBO_DIR="$IM_DIR/IMDelegates/$DM_JPEGTURBO_DIR"
export LZMA_DIR="$IM_DIR/IMDelegates/$DM_XZ_DIR"
export BZIP2_DIR="$IM_DIR/IMDelegates/$DM_BZIP2_DIR"
export LCMS2_DIR="$IM_DIR/IMDelegates/$DM_LCMS2_DIR"
export OPENJPEG_DIR="$IM_DIR/IMDelegates/$DM_OPENJPEG_DIR"
export DE265_DIR="$IM_DIR/IMDelegates/$DM_DE265_DIR"
export AOM_DIR="$IM_DIR/IMDelegates/$DM_AOM_DIR"
export HEIF_DIR="$IM_DIR/IMDelegates/$DM_HEIF_DIR"

export PNG_DIR="$IM_DIR/IMDelegates/$DM_PNG_DIR"
export WEBP_DIR="$IM_DIR/IMDelegates/$DM_WEBP_DIR"
export TIFF_DIR="$IM_DIR/IMDelegates/$DM_TIFF_DIR"
export GS_DIR="$IM_DIR/IMDelegates/ghostscript-9.54.0"
export FREETYPE_DIR="$IM_DIR/IMDelegates/$DM_FREETYPE_DIR"
export FONTCONFIG_DIR="$IM_DIR/IMDelegates/fontconfig"
export EXPAT_DIR="$IM_DIR/IMDelegates/expat"

export JPEG_LEGACY_DIR="$IM_DIR/IMDelegates/jpeg-9a"
if [ "$USE_JPEG_TURBO" = "1" ]; then
	export JPEG_DIR="$JPEG_TURBO_DIR"
else
	export JPEG_DIR="$JPEG_LEGACY_DIR"
fi

export TARGET_LIB_DIR=$(pwd)/target
export ZLIB_LIB_DIR=$TARGET_LIB_DIR/zlib
export ICONV_LIB_DIR=$TARGET_LIB_DIR/libiconv
export ICU_LIB_DIR=$TARGET_LIB_DIR/libicu
export XML2_LIB_DIR=$TARGET_LIB_DIR/libxml2
export FFTW_LIB_DIR=$TARGET_LIB_DIR/fftw
export JPEG_LIB_DIR=$TARGET_LIB_DIR/libjpeg
export PNG_LIB_DIR=$TARGET_LIB_DIR/libpng
export WEBP_LIB_DIR=$TARGET_LIB_DIR/libwebp
export TIFF_LIB_DIR=$TARGET_LIB_DIR/libtiff
export OPENJPEG_LIB_DIR=$TARGET_LIB_DIR/openjpeg
export LZMA_LIB_DIR=$TARGET_LIB_DIR/liblzma
export BZIP2_LIB_DIR=$TARGET_LIB_DIR/bzip2
export LCMS2_LIB_DIR=$TARGET_LIB_DIR/lcms2
export DE265_LIB_DIR=$TARGET_LIB_DIR/libde265
export AOM_LIB_DIR=$TARGET_LIB_DIR/libaom
export HEIF_LIB_DIR=$TARGET_LIB_DIR/libheif
export GS_LIB_DIR=$TARGET_LIB_DIR/ghostscript
export FREETYPE_LIB_DIR=$TARGET_LIB_DIR/libfreetype
export FONTCONFIG_LIB_DIR=$TARGET_LIB_DIR/fontconfig
export EXPAT_LIB_DIR=$TARGET_LIB_DIR/expat
export IM_LIB_DIR=$TARGET_LIB_DIR/imagemagick
export LIB_DIR=$TARGET_LIB_DIR/im_libs
export FINAL_DIR=$(pwd)/IMPORT_ME
