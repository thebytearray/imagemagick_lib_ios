#!/bin/bash

fontconfig_compile() {
    echo "[|- MAKE $BUILDINGFOR]"
    try make -j$CORESNUM
    try make install-exec
    mkdir -p ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/etc/fonts
    if [ -f ./fonts.conf ]; then
        try cp ./fonts.conf ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/etc/fonts/fonts.conf
    elif [ -f fonts.conf ]; then
        try cp fonts.conf ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/etc/fonts/fonts.conf
    fi
    echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    mkdir -p $LIB_DIR/fontconfig_${BUILDINGFOR}_dylib/

	try cp ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_fontconfig $LIB_DIR/libfontconfig.a.$BUILDINGFOR
	try cp ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_fontconfig_dylib $LIB_DIR/fontconfig_${BUILDINGFOR}_dylib/libfontconfig.dylib
	first=`echo $ARCHS | awk '{print $1;}'`
    
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		mkdir -p $LIB_DIR/include/fontconfig
		try cp -r ${FONTCONFIG_LIB_DIR}_${BUILDINGFOR}/include/fontconfig*/ $LIB_DIR/include/fontconfig/
	fi
    echo "[|- CLEAN $BUILDINGFOR]"
    if [ -f Makefile ]; then
        try make distclean
    fi
}

fontconfig () {
    echo "[+ fontconfig: $1]"
    cd $FONTCONFIG_DIR
    
    LIBPATH_fontconfig=libfontconfig.a
    LIBPATH_fontconfig_dylib=libfontconfig.dylib
    
    if [ "$1" == "arm64-sim" ]; then
        save
        armsimflags
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc"
        export PKG_CONFIG_PATH="${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
        host_arch="aarch64"
        try ./configure \
        --prefix=${FONTCONFIG_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin
        fontconfig_compile
        restore
    elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
        save
        armflags $1
#        echo "1"
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
        export PKG_CONFIG_PATH="${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
#        echo $PKG_CONFIG_PATH
        
        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            arm64) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
        esac
        try ./configure \
        --prefix=${FONTCONFIG_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin
        # --with-pic \
        # --enable-static \
        # --disable-shared \
        # --disable-fast-install \
        # --disable-rpath \
        # --disable-libxml2 \
        # --disable-docs \
        # --disable-expat \
        # --host=arm-apple-darwin
#        echo "111"
		fontconfig_compile
		restore
    elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        save
        intelflags $1
        echo "2"
        # 先清理一下
        if [ -f Makefile ]; then
            try make distclean
        fi
        # 重新生成configure文件
        autoreconf -f -i 
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc"
        # 清除之前的PKG_CONFIG_PATH，然后设置新的路径
        export PKG_CONFIG_PATH=""
        export PKG_CONFIG_PATH="${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
        # 显式指定库路径，确保使用正确架构的库
        export LDFLAGS="-L${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib -L${PNG_LIB_DIR}_${BUILDINGFOR}/lib"
        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            x86_64) host_arch="x86_64" ;;
            i386) host_arch="i386" ;;
        esac
        try ./configure \
        --prefix=${FONTCONFIG_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin
        
        fontconfig_compile
        restore
    elif [ "$1" == "mac-arm64" ]; then
        save
        macflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        # 清理并刷新 autotools（部分版本在 macOS 需要）
        if [ -f Makefile ]; then
            try make distclean
        fi
        autoreconf -f -i || true
        # 依赖路径
        export PKG_CONFIG_PATH="${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:${EXPAT_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
        export LDFLAGS="$LDFLAGS -L${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib -L${PNG_LIB_DIR}_${BUILDINGFOR}/lib -L${EXPAT_LIB_DIR}_${BUILDINGFOR}/lib"
        try ./configure \
        --prefix=${FONTCONFIG_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${MAC_HOST_TRIPLE} \
        CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
        fontconfig_compile
        restore
    else
        echo "[ERR: Nothing to do for $1]"
    fi
    
    joinlibs=$(check_for_archs $LIB_DIR/libfontconfig.a)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/libfontconfig.a.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/libfontconfig.a.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/libfontconfig.a.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/libfontconfig.a.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/libfontconfig.a.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/libfontconfig.a.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libfontconfig.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libfontconfig_sim.a
        fi
    fi

    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/libfontconfig.a.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libfontconfig.a"
        fi
        if [ -e "$LIB_DIR/libfontconfig.a.arm64-sim" ]; then
            try cp "$LIB_DIR/libfontconfig.a.arm64-sim" "$LIB_DIR/libfontconfig_sim.a"
        fi
        if [ -e "$LIB_DIR/libfontconfig.a.x86_64" ]; then
            try cp "$LIB_DIR/libfontconfig.a.x86_64" "$LIB_DIR/libfontconfig_x86.a"
        fi
        if [ -e "$LIB_DIR/libfontconfig.a.mac-arm64" ]; then
            try cp "$LIB_DIR/libfontconfig.a.mac-arm64" "$LIB_DIR/libfontconfig_mac.a"
        fi
    fi
}
