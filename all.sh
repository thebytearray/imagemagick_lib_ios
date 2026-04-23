#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == "clean" ]]; then
	rm -rf "$SCRIPT_DIR/target" "$SCRIPT_DIR/IMPORT_ME" "$SCRIPT_DIR"/*.log 2>/dev/null || true
	echo "Clean done."
	exit 0
fi

if [[ $# -lt 1 ]]; then
	echo "$0 IM_VERSION [zip]  — e.g. $0 7.1.0-2"
	echo "EXAMPLE: $0 7.1.0-2"
	echo "After build, optional: $0 7.1.0-2 zip"
	exit 1
fi

export IM_VERSION="$1"

. "$SCRIPT_DIR/env.sh"
. "$SCRIPT_DIR/flags.sh"
. "$SCRIPT_DIR/utils.sh"
# shellcheck source=scripts/ios_delegate_cmake.sh
. "$SCRIPT_DIR/scripts/ios_delegate_cmake.sh"

. "$SCRIPT_DIR/compile_zlib.sh"
. "$SCRIPT_DIR/compile_iconv.sh"
if [[ "${ENABLE_ICU:-1}" == "1" ]]; then
	. "$SCRIPT_DIR/compile_icu.sh"
fi
. "$SCRIPT_DIR/compile_lzma.sh"
. "$SCRIPT_DIR/compile_bzlib.sh"
. "$SCRIPT_DIR/compile_xml2.sh"
. "$SCRIPT_DIR/compile_fftw.sh"
if [[ "${USE_JPEG_TURBO:-1}" == "1" ]]; then
	. "$SCRIPT_DIR/compile_jpegturbo.sh"
else
	. "$SCRIPT_DIR/compile_jpeg.sh"
fi
. "$SCRIPT_DIR/compile_png.sh"
. "$SCRIPT_DIR/compile_tiff.sh"
. "$SCRIPT_DIR/compile_webp.sh"
. "$SCRIPT_DIR/compile_lcms2.sh"
. "$SCRIPT_DIR/compile_openjpeg.sh"
if [[ "${ENABLE_HEIF:-1}" == "1" ]]; then
	. "$SCRIPT_DIR/compile_de265.sh"
	. "$SCRIPT_DIR/compile_aom.sh"
	. "$SCRIPT_DIR/compile_heif.sh"
fi
. "$SCRIPT_DIR/compile_freetype.sh"
. "$SCRIPT_DIR/compile_expat.sh"
. "$SCRIPT_DIR/compile_fontconfig.sh"
if [[ "${BUILD_GHOSTSCRIPT:-0}" == "1" ]]; then
	. "$SCRIPT_DIR/compile_gs.sh"
fi
. "$SCRIPT_DIR/compile_im.sh"

if [[ "${2:-}" == "zip" ]]; then
	zip_for_ftp
	exit 0
fi

prepare

for i in $ARCHS; do
	zlib "$i"
	iconv "$i"
	if [[ "${ENABLE_ICU:-1}" == "1" ]]; then
		icu "$i"
	fi
	lzma "$i"
	bzlib "$i"
	xml2 "$i"
	fftw "$i"
	if [[ "${USE_JPEG_TURBO:-1}" == "1" ]]; then
		jpegturbo "$i"
	else
		jpeg "$i"
	fi
	png "$i"
	tiff "$i"
	webp "$i"
	lcms2 "$i"
	openjpeg "$i"
	if [[ "${ENABLE_HEIF:-1}" == "1" ]]; then
		de265 "$i"
		aom "$i"
		heif "$i"
	fi
	freetype "$i"
	expat "$i"
	fontconfig "$i"
	if [[ "${BUILD_GHOSTSCRIPT:-0}" == "1" ]]; then
		ghostscript "$i"
	fi
	im "$i"
done

structure_for_xcode
