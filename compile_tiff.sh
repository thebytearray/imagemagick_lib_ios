#!/bin/bash

tiff_compile() {
    echo "[|- MAKE $BUILDINGFOR]"
    try make -j$CORESNUM
    try make install
    echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    mkdir -p $LIB_DIR/tiff_${BUILDINGFOR}_dylib
    mkdir -p ${TIFF_LIB_DIR}_${BUILDINGFOR}/
    try cp ${TIFF_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_tiff $LIB_DIR/$LIBNAME_tiff.$BUILDINGFOR
    try cp ${TIFF_LIB_DIR}_${BUILDINGFOR}/lib/libtiff.5.dylib $LIB_DIR/tiff_${BUILDINGFOR}_dylib/libtiff.dylib
    first=`echo $ARCHS | awk '{print $1;}'`
    if [ "$BUILDINGFOR" == "$first" ]; then
        echo "[|- CP include files (arch ref: $first)]"
        # copy the include files
        try cp -r ${TIFF_LIB_DIR}_${BUILDINGFOR}/include/ $LIB_DIR/include/tiff/
    fi
    echo "[|- CLEAN $BUILDINGFOR]"
    try make distclean
}

tiff () {
	echo "[+ TIFF: $1]"
	cd $TIFF_DIR
	
	LIBPATH_tiff=libtiff.a
	LIBNAME_tiff=`basename $LIBPATH_tiff`
	
    if [ "$1" == "arm64-sim" ]; then
        save
        armsimflags
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure prefix=${TIFF_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --disable-cxx --host=${MAC_HOST_TRIPLE}
        tiff_compile
        restore
    elif  [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
        save
        armflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure prefix=${TIFF_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --disable-cxx --host=arm-apple-darwin
        tiff_compile
        restore
    elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        save
        intelflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure prefix=${TIFF_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --disable-cxx --host=${BUILDINGFOR}-apple-darwin
        tiff_compile
        restore
    elif [ "$1" == "mac-arm64" ]; then
        save
        macflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure prefix=${TIFF_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --disable-cxx --host=arm-apple-darwin
        tiff_compile
        restore
    elif [ "$1" == "mac-x86_64" ]; then
        save
        macx86flags
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure prefix=${TIFF_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --disable-cxx --host=${MAC_HOST_TRIPLE}
        tiff_compile
        restore
    else
        echo "[ERR: Nothing to do for $1]"
    fi
	
	
    joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_tiff)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/$LIBNAME_tiff.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_tiff.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/$LIBNAME_tiff.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_tiff.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/$LIBNAME_tiff.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_tiff.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/$LIBNAME_tiff
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/`basename $LIBNAME_tiff .a`_sim.a
        fi
    fi

    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/$LIBNAME_tiff.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/$LIBNAME_tiff"
        fi
        if [ -e "$LIB_DIR/$LIBNAME_tiff.arm64-sim" ]; then
            try cp "$LIB_DIR/$LIBNAME_tiff.arm64-sim" "$LIB_DIR/`basename $LIBNAME_tiff .a`_sim.a"
        fi
        if [ -e "$LIB_DIR/$LIBNAME_tiff.x86_64" ]; then
            try cp "$LIB_DIR/$LIBNAME_tiff.x86_64" "$LIB_DIR/`basename $LIBNAME_tiff .a`_x86.a"
        fi
        mac_arm="$LIB_DIR/$LIBNAME_tiff.mac-arm64"
        mac_x86="$LIB_DIR/$LIBNAME_tiff.mac-x86_64"
        if [ -e "$mac_arm" ] && [ -e "$mac_x86" ]; then
            try lipo -create -output "$LIB_DIR/`basename $LIBNAME_tiff .a`_mac.a" "$mac_arm" "$mac_x86"
        elif [ -e "$mac_arm" ]; then
            try cp "$mac_arm" "$LIB_DIR/`basename $LIBNAME_tiff .a`_mac.a"
        elif [ -e "$mac_x86" ]; then
            try cp "$mac_x86" "$LIB_DIR/`basename $LIBNAME_tiff .a`_mac.a"
        fi
    fi
}
