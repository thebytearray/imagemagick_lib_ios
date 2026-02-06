#!/bin/bash

expat_compile() {
    echo "[|- MAKE $BUILDINGFOR]"
    try make -j$CORESNUM
    try make install
    echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    mkdir -p $LIB_DIR/expat_${BUILDINGFOR}_dylib/

    try cp ${EXPAT_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_expat $LIB_DIR/libexpat.a.$BUILDINGFOR
    try cp ${EXPAT_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_expat_dylib $LIB_DIR/expat_${BUILDINGFOR}_dylib/libexpat.dylib
	first=`echo $ARCHS | awk '{print $1;}'`
    
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		mkdir -p $LIB_DIR/include/expat
		try cp -r ${EXPAT_LIB_DIR}_${BUILDINGFOR}/include/expat* $LIB_DIR/include/expat/
	fi
    echo "[|- CLEAN $BUILDINGFOR]"
    if [ -f Makefile ]; then
        try make distclean
    fi
}

expat () {
	echo "[+ expat: $1]"
	cd $EXPAT_DIR
	
	LIBPATH_expat=libexpat.a
	LIBPATH_expat_dylib=libexpat.dylib
	
    if [ "$1" == "arm64-sim" ]; then
        save
        armsimflags
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc"
        host_arch="aarch64"
        try ./configure \
        --prefix=${EXPAT_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin
        expat_compile
        restore
    elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
        save
        armflags $1
#        echo "1"
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            arm64) host_arch="aarch64" ;;
            armv7|armv7s) host_arch="arm" ;;
        esac
        try ./configure \
        --prefix=${EXPAT_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin
        # --with-pic \
        # --without-docbook \
        # --without-xmlwf \
        # --enable-static \
        # --disable-shared \
        # --disable-fast-install \
        # --host=${BUILDINGFOR}-apple-darwin
#        echo "111"
		expat_compile
		restore
    elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        save
        intelflags $1
        echo "2"
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
        host_arch="$BUILDINGFOR"
        case "$BUILDINGFOR" in
            x86_64) host_arch="x86_64" ;;
            i386) host_arch="i386" ;;
        esac
        try ./configure \
        --prefix=${EXPAT_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${host_arch}-apple-darwin

		expat_compile
		restore
    elif [ "$1" == "mac-arm64" ]; then
        save
        macflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure \
        --prefix=${EXPAT_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${MAC_HOST_TRIPLE} \
        CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
        expat_compile
        restore
    elif [ "$1" == "mac-x86_64" ]; then
        save
        macx86flags
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure \
        --prefix=${EXPAT_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --host=${MAC_HOST_TRIPLE} \
        CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
        expat_compile
        restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
    joinlibs=$(check_for_archs $LIB_DIR/libexpat.a)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/libexpat.a.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/libexpat.a.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/libexpat.a.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/libexpat.a.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/libexpat.a.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/libexpat.a.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/libexpat.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/libexpat_sim.a
        fi
    fi

    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/libexpat.a.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/libexpat.a"
        fi
        if [ -e "$LIB_DIR/libexpat.a.arm64-sim" ]; then
            try cp "$LIB_DIR/libexpat.a.arm64-sim" "$LIB_DIR/libexpat_sim.a"
        fi
        if [ -e "$LIB_DIR/libexpat.a.x86_64" ]; then
            try cp "$LIB_DIR/libexpat.a.x86_64" "$LIB_DIR/libexpat_x86.a"
        fi
        mac_arm="$LIB_DIR/libexpat.a.mac-arm64"
        mac_x86="$LIB_DIR/libexpat.a.mac-x86_64"
        if [ -e "$mac_arm" ] && [ -e "$mac_x86" ]; then
            try lipo -create -output "$LIB_DIR/libexpat_mac.a" "$mac_arm" "$mac_x86"
        elif [ -e "$mac_arm" ]; then
            try cp "$mac_arm" "$LIB_DIR/libexpat_mac.a"
        elif [ -e "$mac_x86" ]; then
            try cp "$mac_x86" "$LIB_DIR/libexpat_mac.a"
        fi
    fi
}
