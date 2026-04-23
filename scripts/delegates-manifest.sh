#!/bin/bash
# Delegate tarball versions — aligned with Android-ImageMagick7/Android.mk.
# Regenerate from Android.mk: scripts/delegates-sync-from-android.sh path/to/Android.mk
# Override any DM_* before sourcing ensure-delegate-sources.sh if needed.

# zlib (Android uses NDK zlib; we build static zlib for libxml2 / ImageMagick parity)
export DM_ZLIB_VERSION="${DM_ZLIB_VERSION:-1.3.1}"
export DM_ZLIB_DIR="zlib-${DM_ZLIB_VERSION}"
export DM_ZLIB_URL="https://zlib.net/zlib-${DM_ZLIB_VERSION}.tar.gz"

export DM_ICONV_VERSION="${DM_ICONV_VERSION:-1.16}"
export DM_ICONV_DIR="libiconv-${DM_ICONV_VERSION}"
export DM_ICONV_URL="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${DM_ICONV_VERSION}.tar.gz"

# ICU4C — matches Android-ImageMagick7 libicu4c-64-2 (tarball extracts to icu/source).
export DM_ICU_VERSION="${DM_ICU_VERSION:-64_2}"
_icu_rel_tag="release-${DM_ICU_VERSION//_/-}"
export DM_ICU_URL="https://github.com/unicode-org/icu/releases/download/${_icu_rel_tag}/icu4c-${DM_ICU_VERSION}-src.tgz"
unset _icu_rel_tag

export DM_XML2_VERSION="${DM_XML2_VERSION:-2.9.9}"
export DM_XML2_DIR="libxml2-${DM_XML2_VERSION}"
# gnome sources path uses the first two components of the version (e.g. 2.9 for 2.9.x)
export DM_XML2_GNOME_BRANCH="${DM_XML2_GNOME_BRANCH:-$(echo "${DM_XML2_VERSION}" | cut -d. -f1-2)}"
export DM_XML2_URL="https://download.gnome.org/sources/libxml2/${DM_XML2_GNOME_BRANCH}/libxml2-${DM_XML2_VERSION}.tar.xz"

export DM_FFTW_VERSION="${DM_FFTW_VERSION:-3.3.8}"
export DM_FFTW_DIR="fftw-${DM_FFTW_VERSION}"
export DM_FFTW_URL="https://www.fftw.org/fftw-${DM_FFTW_VERSION}.tar.gz"

export DM_JPEGTURBO_VERSION="${DM_JPEGTURBO_VERSION:-2.0.2}"
export DM_JPEGTURBO_DIR="libjpeg-turbo-${DM_JPEGTURBO_VERSION}"
export DM_JPEGTURBO_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${DM_JPEGTURBO_VERSION}.tar.gz"

export DM_XZ_VERSION="${DM_XZ_VERSION:-5.2.4}"
export DM_XZ_DIR="xz-${DM_XZ_VERSION}"
export DM_XZ_URL="https://downloads.sourceforge.net/project/lzmautils/xz-${DM_XZ_VERSION}.tar.xz"

export DM_BZIP2_VERSION="${DM_BZIP2_VERSION:-1.0.8}"
export DM_BZIP2_DIR="bzip2-${DM_BZIP2_VERSION}"
export DM_BZIP2_URL="https://sourceware.org/pub/bzip2/bzip2-${DM_BZIP2_VERSION}.tar.gz"

export DM_LCMS2_VERSION="${DM_LCMS2_VERSION:-2.9}"
export DM_LCMS2_DIR="lcms2-${DM_LCMS2_VERSION}"
export DM_LCMS2_URL="https://downloads.sourceforge.net/project/lcms/lcms2/${DM_LCMS2_VERSION}/lcms2-${DM_LCMS2_VERSION}.tar.gz"

export DM_OPENJPEG_VERSION="${DM_OPENJPEG_VERSION:-2.3.1}"
export DM_OPENJPEG_DIR="openjpeg-${DM_OPENJPEG_VERSION}"
export DM_OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v${DM_OPENJPEG_VERSION}.tar.gz"

export DM_PNG_VERSION="${DM_PNG_VERSION:-1.6.37}"
export DM_PNG_DIR="libpng-${DM_PNG_VERSION}"
export DM_PNG_URL="https://downloads.sourceforge.net/project/libpng/libpng16/older-releases/${DM_PNG_VERSION}/libpng-${DM_PNG_VERSION}.tar.xz"

export DM_TIFF_VERSION="${DM_TIFF_VERSION:-4.0.10}"
export DM_TIFF_DIR="tiff-${DM_TIFF_VERSION}"
export DM_TIFF_URL="https://download.osgeo.org/libtiff/tiff-${DM_TIFF_VERSION}.tar.gz"

export DM_WEBP_VERSION="${DM_WEBP_VERSION:-1.0.3}"
export DM_WEBP_DIR="libwebp-${DM_WEBP_VERSION}"
export DM_WEBP_URL="https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${DM_WEBP_VERSION}.tar.gz"

export DM_FREETYPE_VERSION="${DM_FREETYPE_VERSION:-2.10.1}"
export DM_FREETYPE_DIR="freetype-${DM_FREETYPE_VERSION}"
export DM_FREETYPE_URL="https://download.savannah.gnu.org/releases/freetype/freetype-${DM_FREETYPE_VERSION}.tar.xz"

export DM_DE265_VERSION="${DM_DE265_VERSION:-1.0.15}"
export DM_DE265_DIR="libde265-${DM_DE265_VERSION}"
export DM_DE265_URL="https://github.com/strukturag/libde265/releases/download/v${DM_DE265_VERSION}/libde265-${DM_DE265_VERSION}.tar.gz"

export DM_AOM_VERSION="${DM_AOM_VERSION:-3.8.2}"
export DM_AOM_DIR="libaom-${DM_AOM_VERSION}"
export DM_AOM_URL="https://storage.googleapis.com/aom-releases/libaom-${DM_AOM_VERSION}.tar.gz"

export DM_HEIF_VERSION="${DM_HEIF_VERSION:-1.19.7}"
export DM_HEIF_DIR="libheif-${DM_HEIF_VERSION}"
export DM_HEIF_URL="https://github.com/strukturag/libheif/releases/download/v${DM_HEIF_VERSION}/libheif-${DM_HEIF_VERSION}.tar.gz"
