#!/bin/bash

freetype_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    mkdir -p $LIB_DIR/freetype_${BUILDINGFOR}_dylib/
    mkdir -p ${FREETYPE_LIB_DIR}_${BUILDINGFOR}/
 
	try cp ${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_freetype $LIB_DIR/libfreetype.a.$BUILDINGFOR
	try cp ${FREETYPE_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_freetype_dylib  $LIB_DIR/freetype_${BUILDINGFOR}_dylib/libfreetype.dylib
   
   
	first=`echo $ARCHS | awk '{print $1;}'`
    
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		mkdir -p $LIB_DIR/include/freetype
		try cp -r ${FREETYPE_LIB_DIR}_${BUILDINGFOR}/include/freetype2/ $LIB_DIR/include/freetype/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

freetype () {
    echo "[+ freetype: $1]"
    cd $FREETYPE_DIR
    
    LIBPATH_freetype=libfreetype.a
    LIBPATH_freetype_dylib=libfreetype.dylib
    
    if [ "$1" == "arm64-sim" ]; then
        save
        armsimflags
        echo "[|- CONFIG $BUILDINGFOR]"
        export PKG_CONFIG_PATH="${PNG_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
        export CC="$(xcode-select -print-path)/usr/bin/gcc"

        host_arch="arm64"
        case "$BUILDINGFOR" in
            arm64|arm64-sim) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
            x86_64) host_arch="x86_64" ;;
            i386) host_arch="i386" ;;
        esac
        try ./configure \
        prefix=${FREETYPE_LIB_DIR}_${BUILDINGFOR} \
        --with-pic \
        --with-zlib \
        --with-png \
        --without-harfbuzz \
        --without-bzip2 \
        --without-fsref \
        --without-quickdraw-toolbox \
        --without-quickdraw-carbon \
        --without-ats \
        --enable-static \
        --enable-shared \
        --disable-fast-install \
        --disable-mmap \
        --host=${host_arch}-apple-darwin
        
        freetype_compile
        restore
    elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
        save
        armflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        
        export PKG_CONFIG_PATH="${PNG_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang

        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            arm64|arm64-sim) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
            x86_64) host_arch="x86_64" ;;
            i386) host_arch="i386" ;;
        esac
        try ./configure \
        prefix=${FREETYPE_LIB_DIR}_${BUILDINGFOR} \
        --with-pic \
        --with-zlib \
        --with-png \
        --without-harfbuzz \
        --without-bzip2 \
        --without-fsref \
        --without-quickdraw-toolbox \
        --without-quickdraw-carbon \
        --without-ats \
        --enable-static \
        --enable-shared \
        --disable-fast-install \
        --disable-mmap \
        --host=${host_arch}-apple-darwin
        
        freetype_compile
        restore
    elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        save
        intelflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
        
        export PKG_CONFIG_PATH="${PNG_LIB_DIR}_${BUILDINGFOR}/lib/pkgconfig/:$PKG_CONFIG_PATH"

        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            arm64|arm64-sim) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
            x86_64) host_arch="x86_64" ;;
            i386) host_arch="i386" ;;
        esac
        try ./configure \
        prefix=${FREETYPE_LIB_DIR}_${BUILDINGFOR} \
        --with-pic \
        --with-zlib \
        --with-png \
        --without-harfbuzz \
        --without-bzip2 \
        --without-fsref \
        --without-quickdraw-toolbox \
        --without-quickdraw-carbon \
        --without-ats \
        --enable-static \
        --enable-shared \
        --disable-fast-install \
        --disable-mmap \
        --host=${host_arch}-apple-darwin
         
        freetype_compile
        restore
    else
        echo "[ERR: Nothing to do for $1]"
    fi
    
    joinlibs=$(check_for_archs $LIB_DIR/libfreetype.a)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/libfreetype.a.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/libfreetype.a.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/libfreetype.a.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/libfreetype.a.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/libfreetype.a.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/libfreetype.a.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libfreetype.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libfreetype_sim.a
        fi
    fi

    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/libfreetype.a.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libfreetype.a"
        fi
        if [ -e "$LIB_DIR/libfreetype.a.arm64-sim" ]; then
            try cp "$LIB_DIR/libfreetype.a.arm64-sim" "$LIB_DIR/libfreetype_sim.a"
        fi
        if [ -e "$LIB_DIR/libfreetype.a.x86_64" ]; then
            try cp "$LIB_DIR/libfreetype.a.x86_64" "$LIB_DIR/libfreetype_x86.a"
        fi
    fi
}
