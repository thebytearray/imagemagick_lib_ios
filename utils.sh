#!/bin/bash

# If command fails the script exits
try () {
    if [ "$1" = "./configure" ] || { [ "$1" = "sh" ] && [ "$2" = "./configure" ]; }; then
        if [ ! -f ./configure ]; then
            if command -v autoreconf >/dev/null 2>&1; then
                autoreconf -f -i >> $OUTPUT_FILE 2>&1
            fi
            if [ -f autogen.sh ]; then
                sh ./autogen.sh >> $OUTPUT_FILE 2>&1
            fi
        fi
    fi
    if [ $VERBOSE -eq 1 ]; then
        echo 1
        "$@" | tee -a $OUTPUT_FILE 2>&1 || exit -1
    else
        "$@" >> $OUTPUT_FILE 2>&1 || exit -1
    fi
}

# Prepares the directory structure needed for the compilation and any additional
# requirement
prepare() {
	# ImageMagick expects crt_externs.h when targeting iOS; use a writable include dir (no sudo — CI-safe).
	export IOS_SDK_EXTRAS_INCLUDE="$LIB_DIR/include/ios_sdk_extras"
	mkdir -p "$IOS_SDK_EXTRAS_INCLUDE"
	if [ ! -f "$IOS_SDK_EXTRAS_INCLUDE/crt_externs.h" ]; then
		if [ -f "${IOSSDKROOT:-}/usr/include/crt_externs.h" ]; then
			cp "${IOSSDKROOT}/usr/include/crt_externs.h" "$IOS_SDK_EXTRAS_INCLUDE/"
		elif [ -f "${SIMSDKROOT:-}/usr/include/crt_externs.h" ]; then
			cp "${SIMSDKROOT}/usr/include/crt_externs.h" "$IOS_SDK_EXTRAS_INCLUDE/"
		else
			_macsdk="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
			if [ -n "$_macsdk" ] && [ -f "$_macsdk/usr/include/crt_externs.h" ]; then
				cp "$_macsdk/usr/include/crt_externs.h" "$IOS_SDK_EXTRAS_INCLUDE/"
			fi
		fi
	fi
	
	# Check if IMDelegates is inside the IM directory or link it
	if [ -e $IM_DELEGATES_DIR ]; then
		:;
	else
		echo "[INFO] IMDelegates not found, linking it"
		ln -s "$BUILDROOT/IMDelegates" "$IM_DIR/IMDelegates"
	fi
	
	# target folder
	mkdir -p $TARGET_LIB_DIR
	# includes
	mkdir -p $LIB_DIR/include/im_config
	mkdir -p $LIB_DIR/include/jpeg
	mkdir -p $LIB_DIR/include/magick
	mkdir -p $LIB_DIR/include/png
	mkdir -p $LIB_DIR/include/webp
	mkdir -p $LIB_DIR/include/tiff
	mkdir -p $LIB_DIR/include/wand
	mkdir -p $LIB_DIR/include/expat
	mkdir -p $LIB_DIR/include/fontconfig
	mkdir -p $LIB_DIR/include/freetype
	mkdir -p $LIB_DIR/include/ghostscript
	mkdir -p $LIB_DIR/include/lzma
	mkdir -p $LIB_DIR/include/lcms2
	mkdir -p $LIB_DIR/include/openjp2
	mkdir -p $LIB_DIR/include/bzlib
	mkdir -p $LIB_DIR/include/zlib
	mkdir -p $LIB_DIR/include/iconv
	mkdir -p $LIB_DIR/include/libxml2
	mkdir -p $LIB_DIR/include/fftw
	mkdir -p $LIB_DIR/include/libheif
	# lib directories
	mkdir -p $ZLIB_LIB_DIR
	mkdir -p $ICONV_LIB_DIR
	mkdir -p $ICU_LIB_DIR
	mkdir -p $XML2_LIB_DIR
	mkdir -p $FFTW_LIB_DIR
	mkdir -p $DE265_LIB_DIR
	mkdir -p $AOM_LIB_DIR
	mkdir -p $HEIF_LIB_DIR
	mkdir -p $JPEG_LIB_DIR
	mkdir -p $PNG_LIB_DIR
	mkdir -p $TIFF_LIB_DIR
	mkdir -p $LZMA_LIB_DIR
	mkdir -p $LCMS2_LIB_DIR
	mkdir -p $BZIP2_LIB_DIR
	mkdir -p $OPENJPEG_LIB_DIR
	# DYLIB directories
	for i in "jpeg" "png" "tiff" "webp"; do
		for j in $ARCHS; do
			mkdir -p $LIB_DIR/${i}_${j}_dylib
		done
	done
}

# For every architecture checks if the coresponding library file exists. Used
# later to merge (with lipo) all the library archives in a fat one
check_for_archs() {
   
	local to_check=$1
	local ret="OK"
	for i in $ARCHS; do
		if [ ! -e $to_check.$i ]; then
			ret="NO"
			break
		fi
	done
	echo $ret
}

# Creates the structure that can be imported in XCode as it is done in the
# example project
structure_for_xcode() {
	echo "[+ Prepairing import for XCode]"
	if [ -e $FINAL_DIR ]; then
		echo "[|- RM $FINAL_DIR/*]"
		try rm -rf ${FINAL_DIR}/*
	else
		echo "[|- MKDIR: $FINAL_DIR]"
		try mkdir -p ${FINAL_DIR}
	fi
	echo "[|- CP ...]"
	try cp -r ${LIB_DIR}/include/ ${FINAL_DIR}/include/
	try cp ${LIB_DIR}/*.a ${FINAL_DIR}/
	echo "[+ DONE!]"
}

# Creates .zips to be uploaded on the ImageMagick FTP site.
# Not useful to many, used by Claudio Marforio.
zip_for_ftp() {
	echo "[+ ZIP]"
	if [ -e $FINAL_DIR ]; then
		tmp_dir="$(pwd)/TMP_IM"
		try cp -R $FINAL_DIR/ $tmp_dir
		try ditto -c -k -rsrc "$tmp_dir" "iOSMagick-FIXME-libs.zip" && echo "[|- CREATED W/ libs]"
		try rm $tmp_dir/libjpeg.a $tmp_dir/libpng.a $tmp_dir/libtiff.a
		try rm -rf $tmp_dir/include/jpeg/ $tmp_dir/include/png/ $tmp_dir/include/tiff/
		try ditto -c -k -rsrc "$tmp_dir" "iOSMagick-FIXME.zip" && echo "[|- CREATED W/O libs]"
		try rm -rf $tmp_dir
	else
		echo "[ERR $FINAL_DIR not present..."
	fi
	echo "[+ DONE: ZIP]"
}
