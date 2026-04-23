#!/bin/bash

im_compile() {
    echo "[|- MAKE $BUILDINGFOR]"
    try make -j$CORESNUM
    try make install
    echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    try cp $LIBPATH_core $LIB_DIR/$LIBNAME_core.$BUILDINGFOR
    try cp $LIBPATH_wand $LIB_DIR/$LIBNAME_wand.$BUILDINGFOR
    try cp $LIBPATH_magickpp $LIB_DIR/$LIBNAME_magickpp.$BUILDINGFOR
    first=`echo $ARCHS | awk '{print $1;}'`

    if [ "$BUILDINGFOR" == "$first" ]; then  # copy include and config files
        # copy the wand/ + core/ headers
        mkdir -p $LIB_DIR/include/MagickCore $LIB_DIR/include/MagickWand $LIB_DIR/include/magick++
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/include/ImageMagick-*/MagickCore/ $LIB_DIR/include/MagickCore/
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/include/ImageMagick-*/MagickWand/ $LIB_DIR/include/MagickWand/
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/include/ImageMagick-*/magick++/ $LIB_DIR/include/magick++/
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/include/ImageMagick-*/Magick++.h $LIB_DIR/include/Magick++.h

        # copy configuration files needed for certain functions
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/etc/ImageMagick-*/ $LIB_DIR/include/im_config/
        try cp -r ${IM_LIB_DIR}_${BUILDINGFOR}/share/ImageMagick-*/ $LIB_DIR/include/im_config/
    fi
    echo "[|- CLEAN $BUILDINGFOR]"
    if [ -f Makefile ]; then
        try make distclean
    fi
}

# Shared delegates — aligned with Android-ImageMagick7 Application.mk (incl. zlib, iconv, xml2, fftw, heif stack when ENABLE_HEIF=1).
_im_delegate_exports() {
	local a="$1"
	local crt=""
	[ -n "${IOS_SDK_EXTRAS_INCLUDE:-}" ] && crt="-I${IOS_SDK_EXTRAS_INCLUDE}"
	export PKG_CONFIG_PATH="${PNG_LIB_DIR}_${a}/lib/pkgconfig/:${JPEG_LIB_DIR}_${a}/lib/pkgconfig/:${TIFF_LIB_DIR}_${a}/lib/pkgconfig/:${WEBP_LIB_DIR}_${a}/lib/pkgconfig/:${LZMA_LIB_DIR}_${a}/lib/pkgconfig/:${LCMS2_LIB_DIR}_${a}/lib/pkgconfig/:${OPENJPEG_LIB_DIR}_${a}/lib/pkgconfig/:${FREETYPE_LIB_DIR}_${a}/lib/pkgconfig/:${FONTCONFIG_LIB_DIR}_${a}/lib/pkgconfig/:${EXPAT_LIB_DIR}_${a}/lib/pkgconfig/:${XML2_LIB_DIR}_${a}/lib/pkgconfig/:${FFTW_LIB_DIR}_${a}/lib/pkgconfig/"
	if [ "${ENABLE_ICU:-1}" = "1" ]; then
		export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${ICU_LIB_DIR}_${a}/lib/pkgconfig:"
	fi
	if [ "${ENABLE_HEIF:-1}" = "1" ]; then
		export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${HEIF_LIB_DIR}_${a}/lib/pkgconfig:"
	fi
	export CPPFLAGS="${crt} -I$LIB_DIR/include/zlib -I$LIB_DIR/include/iconv -I$LIB_DIR/include/libxml2 -I$LIB_DIR/include/fftw -I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png -I$LIB_DIR/include/webp -I$LIB_DIR/include/tiff -I$LIB_DIR/include/lzma -I$LIB_DIR/include/lcms2 -I$LIB_DIR/include/openjp2 -I$LIB_DIR/include/bzlib -I$IM_LIB_DIR/include/ImageMagick-7 -I$LIB_DIR/include/fontconfig -I$LIB_DIR/include/expat"
	if [ "${ENABLE_ICU:-1}" = "1" ]; then
		export CPPFLAGS="${CPPFLAGS} -I${ICU_LIB_DIR}_${a}/include"
	fi
	if [ "${ENABLE_HEIF:-1}" = "1" ]; then
		export CPPFLAGS="${CPPFLAGS} -I$LIB_DIR/include/libheif"
	fi
	export LDFLAGS="$LDFLAGS -L${JPEG_LIB_DIR}_${a}/lib -L$LIB_DIR/jpeg_${a}_dylib/ -L${PNG_LIB_DIR}_${a}/lib -L${LIB_DIR}/png_${a}_dylib/ -L${WEBP_LIB_DIR}_${a}/lib -L$LIB_DIR/webp_${a}_dylib/ -L${TIFF_LIB_DIR}_${a}/lib -L$LIB_DIR/tiff_${a}_dylib/ -L$LIB_DIR/fontconfig_${a}_dylib/ -L$LIB_DIR/expat_${a}_dylib/ -L${ZLIB_LIB_DIR}_${a}/lib -L${ICONV_LIB_DIR}_${a}/lib -L${XML2_LIB_DIR}_${a}/lib -L${FFTW_LIB_DIR}_${a}/lib -L${LZMA_LIB_DIR}_${a}/lib -L${LCMS2_LIB_DIR}_${a}/lib -L${OPENJPEG_LIB_DIR}_${a}/lib"
	if [ "${ENABLE_ICU:-1}" = "1" ]; then
		export LDFLAGS="${LDFLAGS} -L${ICU_LIB_DIR}_${a}/lib"
	fi
	if [ "${ENABLE_HEIF:-1}" = "1" ]; then
		export LDFLAGS="${LDFLAGS} -L${HEIF_LIB_DIR}_${a}/lib -L${DE265_LIB_DIR}_${a}/lib -L${AOM_LIB_DIR}_${a}/lib"
	fi
	local _heif_libs=""
	if [ "${ENABLE_HEIF:-1}" = "1" ]; then
		# Static libheif: pull in libde265 + libaom explicitly (pkg-config often omits private deps).
		_heif_libs=" -lheif -lde265 -laom -lc++"
	fi
	# Static link: libxml2 built with ICU leaves ICU symbols unresolved until ICU libs follow -lxml2.
	local _icu_libs=""
	if [ "${ENABLE_ICU:-1}" = "1" ]; then
		_icu_libs=" -licui18n -licuuc -licudata"
	fi
	export LIBS="${LIB_DIR}/libbz2.a.${a} -llzma -llcms2 -lopenjp2 -ltiff -ljpeg -lz -liconv -lxml2 -lfftw3${_icu_libs}${_heif_libs} $(pkg-config --libs freetype2 2>/dev/null) $(pkg-config --libs libpng16 2>/dev/null) $(pkg-config --libs libwebp 2>/dev/null) $(pkg-config --libs fontconfig 2>/dev/null) $(pkg-config --libs expat 2>/dev/null) $LIBS"
}

im () {
	echo "[+ IM: $1]"
	cd $IM_DIR
	_HEIC_CFG="--without-heic"
	[ "${ENABLE_HEIF:-1}" = "1" ] && _HEIC_CFG="--with-heic=yes"
	
	# static library that will be generated
	LIBPATH_core=${IM_LIB_DIR}_$1/lib/libMagickCore-7.Q8HDRI.a
	LIBNAME_core=`basename $LIBPATH_core`
	LIBPATH_wand=${IM_LIB_DIR}_$1/lib/libMagickWand-7.Q8HDRI.a
	LIBNAME_wand=`basename $LIBPATH_wand`
	LIBPATH_magickpp=${IM_LIB_DIR}_$1/lib/libMagick++-7.Q8HDRI.a
	LIBNAME_magickpp=`basename $LIBPATH_magickpp`
	
    if [ "$1" == "arm64-sim" ]; then
        save
        armsimflags
        _im_delegate_exports "$1"

        echo "[|- CONFIG $BUILDINGFOR]"
        host_arch="aarch64"
        try ./configure \
            --prefix=${IM_LIB_DIR}_${BUILDINGFOR} \
            --disable-opencl \
            --disable-largefile \
            --with-quantum-depth=8 \
            --with-magick-plus-plus \
            --with-jpeg \
            --with-png \
            --with-tiff \
            --with-freetype \
            --with-fontconfig \
            --with-xml \
            --with-webp \
            --without-perl \
            --without-x \
            --disable-shared \
            --disable-openmp \
            --with-bzlib=yes \
            --without-openexr \
            --without-zstd \
            --with-lcms=yes \
            --with-lzma=yes \
            --with-openjp2=yes \
            --with-fftw=yes \
            ${_HEIC_CFG} \
            --without-zip \
            --host=${host_arch}-apple-darwin
        im_compile
        restore
    elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
        save
        armflags $1
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		# export CPPFLAGS="-I$LIB_DIR/include/jpeg -I$LIB_DIR/include/png  -I$LIB_DIR/include/webp -I$IM_LIB_DIR/include/ImageMagick-7 -I$LIB_DIR/include/fontconfig"
        
        export CFLAGS="$CFLAGS -DTARGET_OS_IPHONE "
        _im_delegate_exports "$1"

		echo "[|- CONFIG $BUILDINGFOR]"
        
        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            arm64) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
        esac
        try ./configure \
            --prefix=${IM_LIB_DIR}_${BUILDINGFOR} \
			--disable-opencl \
            --disable-largefile \
            --with-quantum-depth=8 \
            --with-magick-plus-plus \
            --with-jpeg \
            --with-png \
            --with-tiff \
            --with-freetype \
            --with-fontconfig \
			--with-xml \
			--with-webp \
			--without-perl \
            --without-x \
            --disable-shared \
            --disable-openmp \
            --with-bzlib=yes \
            --without-openexr \
            --without-zstd \
            --with-lcms=yes \
            --with-lzma=yes \
            --with-openjp2=yes \
            --with-fftw=yes \
            ${_HEIC_CFG} \
			--without-zip \
            --host=${host_arch}-apple-darwin
            
		im_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        echo "x86"
		save
        intelflags $1
        # 先清理一下
		# try make distclean

		echo "LIBPATH_magickpp=$LIBPATH_magickpp"
		echo "BUILDINGFOR=$BUILDINGFOR"
		echo "当前架构=$1"
	
        # export CC="clang"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
        _im_delegate_exports "$1"

		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure \
		    --prefix=${IM_LIB_DIR}_${BUILDINGFOR} \
            --disable-opencl \
            --disable-largefile \
            --with-quantum-depth=8 \
            --with-magick-plus-plus \
            --with-jpeg \
            --with-png \
            --with-tiff \
            --with-freetype \
            --with-fontconfig \
			--with-xml \
			--with-webp \
            --without-perl \
            --without-x \
            --disable-shared \
            --disable-openmp \
            --with-bzlib=yes \
            --without-openexr \
            --without-zstd \
            --with-lcms=yes \
            --with-lzma=yes \
            --with-openjp2=yes \
            --with-fftw=yes \
            ${_HEIC_CFG} \
			--without-zip \
            --host=${BUILDINGFOR}-apple-darwin
            
		im_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags $1
		_im_delegate_exports "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure \
		    --prefix=${IM_LIB_DIR}_${BUILDINGFOR} \
		    --disable-opencl \
		    --disable-largefile \
		    --with-quantum-depth=8 \
		    --with-magick-plus-plus \
		    --with-jpeg \
		    --with-png \
		    --with-tiff \
		    --with-freetype \
		    --with-fontconfig \
		    --with-xml \
		    --with-webp \
		    --without-perl \
		    --without-x \
		    --disable-shared \
		    --disable-openmp \
		    --with-bzlib=yes \
		    --without-openexr \
		    --without-zstd \
		    --with-lcms=yes \
		    --with-lzma=yes \
		    --with-openjp2=yes \
		    --with-fftw=yes \
		    ${_HEIC_CFG} \
		    --without-zip \
		    --host=${MAC_HOST_TRIPLE} \
		    CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS" LIBS="$LIBS"
		im_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		_im_delegate_exports "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure \
		    --prefix=${IM_LIB_DIR}_${BUILDINGFOR} \
		    --disable-opencl \
		    --disable-largefile \
		    --with-quantum-depth=8 \
		    --with-magick-plus-plus \
		    --with-jpeg \
		    --with-png \
		    --with-tiff \
		    --with-freetype \
		    --with-fontconfig \
		    --with-xml \
		    --with-webp \
		    --without-perl \
		    --without-x \
		    --disable-shared \
		    --disable-openmp \
		    --with-bzlib=yes \
		    --without-openexr \
		    --without-zstd \
		    --with-lcms=yes \
		    --with-lzma=yes \
		    --with-openjp2=yes \
		    --with-fftw=yes \
		    ${_HEIC_CFG} \
		    --without-zip \
		    --host=${MAC_HOST_TRIPLE} \
		    CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" CPPFLAGS="$CPPFLAGS" LIBS="$LIBS"
		im_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
    # join libMagickCore
    echo "core $LIB_DIR/$LIBNAME_core"
    joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_core)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "111"
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/$LIBNAME_core.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_core.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/$LIBNAME_core.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_core.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/$LIBNAME_core.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_core.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libMagickCore.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libMagickCore_sim.a
        fi
        echo "[+ DONE]"
    fi

	    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/$LIBNAME_core.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libMagickCore.a"
        fi
        if [ -e "$LIB_DIR/$LIBNAME_core.arm64-sim" ]; then
            try cp "$LIB_DIR/$LIBNAME_core.arm64-sim" "$LIB_DIR/libMagickCore_sim.a"
        fi
	        if [ -e "$LIB_DIR/$LIBNAME_core.x86_64" ]; then
	            try cp "$LIB_DIR/$LIBNAME_core.x86_64" "$LIB_DIR/libMagickCore_x86.a"
	        fi
	        if [ -e "$LIB_DIR/$LIBNAME_core.mac-arm64" ]; then
	            mac_arm="$LIB_DIR/$LIBNAME_core.mac-arm64"
	            mac_x86="$LIB_DIR/$LIBNAME_core.mac-x86_64"
	            if [ -e "$mac_x86" ]; then
	                try lipo -create -output "$LIB_DIR/libMagickCore_mac.a" "$mac_arm" "$mac_x86"
	            else
	                try cp "$mac_arm" "$LIB_DIR/libMagickCore_mac.a"
	            fi
	        fi
	    fi

	# join libMacigkWand
    joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_wand)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "222"
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/$LIBNAME_wand.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_wand.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/$LIBNAME_wand.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_wand.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/$LIBNAME_wand.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_wand.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libMagickWand.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libMagickWand_sim.a
        fi
        echo "[+ DONE]"
    fi

	    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/$LIBNAME_wand.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libMagickWand.a"
        fi
        if [ -e "$LIB_DIR/$LIBNAME_wand.arm64-sim" ]; then
            try cp "$LIB_DIR/$LIBNAME_wand.arm64-sim" "$LIB_DIR/libMagickWand_sim.a"
        fi
	        if [ -e "$LIB_DIR/$LIBNAME_wand.x86_64" ]; then
	            try cp "$LIB_DIR/$LIBNAME_wand.x86_64" "$LIB_DIR/libMagickWand_x86.a"
	        fi
	        if [ -e "$LIB_DIR/$LIBNAME_wand.mac-arm64" ]; then
	            mac_arm="$LIB_DIR/$LIBNAME_wand.mac-arm64"
	            mac_x86="$LIB_DIR/$LIBNAME_wand.mac-x86_64"
	            if [ -e "$mac_x86" ]; then
	                try lipo -create -output "$LIB_DIR/libMagickWand_mac.a" "$mac_arm" "$mac_x86"
	            else
	                try cp "$mac_arm" "$LIB_DIR/libMagickWand_mac.a"
	            fi
	        fi
	    fi

    joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_magickpp)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		echo "333"
		echo "[|- COMBINE $ARCHS]"
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			file="$LIB_DIR/$LIBNAME_magickpp.$i"
			if [ -e "$file" ]; then
				info=$(lipo -info "$file" 2>/dev/null)
				arch_flag="$i"
				if echo "$info" | grep -q "x86_64"; then arch_flag="x86_64"; fi
				if echo "$info" | grep -q "arm64"; then arch_flag="arm64"; fi
				case "$i" in
					armv7|armv7s|arm64)
						accumul_dev="$accumul_dev -arch $arch_flag $file"
					;;
					x86_64|arm64-sim)
						accumul_sim="$accumul_sim -arch $arch_flag $file"
					;;
				esac
			fi
		done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libMagick++.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libMagick++_sim.a
        fi
        echo "[+ DONE]"
    fi

	    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/$LIBNAME_magickpp.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libMagick++.a"
        fi
        if [ -e "$LIB_DIR/$LIBNAME_magickpp.arm64-sim" ]; then
            try cp "$LIB_DIR/$LIBNAME_magickpp.arm64-sim" "$LIB_DIR/libMagick++_sim.a"
        fi
	        if [ -e "$LIB_DIR/$LIBNAME_magickpp.x86_64" ]; then
	            try cp "$LIB_DIR/$LIBNAME_magickpp.x86_64" "$LIB_DIR/libMagick++_x86.a"
	        fi
	        if [ -e "$LIB_DIR/$LIBNAME_magickpp.mac-arm64" ]; then
	            mac_arm="$LIB_DIR/$LIBNAME_magickpp.mac-arm64"
	            mac_x86="$LIB_DIR/$LIBNAME_magickpp.mac-x86_64"
	            if [ -e "$mac_x86" ]; then
	                try lipo -create -output "$LIB_DIR/libMagick++_mac.a" "$mac_arm" "$mac_x86"
	            else
	                try cp "$mac_arm" "$LIB_DIR/libMagick++_mac.a"
	            fi
	        fi
	    fi
}
