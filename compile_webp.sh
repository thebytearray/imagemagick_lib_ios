#!/bin/bash

webp_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    
    mkdir -p $LIB_DIR/webp_${BUILDINGFOR}_dylib
    mkdir -p ${WEBP_LIB_DIR}_${BUILDINGFOR}/
    
	echo "1"
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_WEBP $LIB_DIR/libwebp.a.$BUILDINGFOR
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_WEBP_dylib $LIB_DIR/webp_${BUILDINGFOR}_dylib/libwebp.dylib
	
	echo "2"
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$DECLIBLIST $LIB_DIR/libwebpdecoder.a.$BUILDINGFOR

	echo "3"
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$MUXLIBLIST $LIB_DIR/libwebpmux.a.$BUILDINGFOR
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$MUXLIBLIST_dylib $LIB_DIR/webp_${BUILDINGFOR}_dylib/libwebpmux.dylib

	echo "4"
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$DEMUXLIBLIST $LIB_DIR/libwebpdemux.a.$BUILDINGFOR
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$DEMUXLIBLIST_dylib $LIB_DIR/webp_${BUILDINGFOR}_dylib/libwebpdemux.dylib

	echo "5"
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$SHARPYUV $LIB_DIR/libsharpyuv.a.$BUILDINGFOR
	try cp ${WEBP_LIB_DIR}_${BUILDINGFOR}/lib/$sharpyuv_dylib $LIB_DIR/webp_${BUILDINGFOR}_dylib/libsharpyuv.dylib
	echo "6"
    
	first=`echo $ARCHS | awk '{print $1;}'`
    
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		try cp -r ${WEBP_LIB_DIR}_${BUILDINGFOR}/include/webp/ $LIB_DIR/include/webp/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

webp () {
	echo "[+ webp: $1]"
	cd $WEBP_DIR
	
	LIBPATH_WEBP=libwebp.a
	LIBPATH_WEBP_dylib=libwebp.7.dylib

	DECLIBLIST=libwebpdecoder.a
	# DECLIBLIST_dylib=libwebpdecoder.a

  	MUXLIBLIST=libwebpmux.a
	MUXLIBLIST_dylib=libwebpmux.3.dylib

  	DEMUXLIBLIST=libwebpdemux.a
	DEMUXLIBLIST_dylib=libwebpdemux.2.dylib

	SHARPYUV=libsharpyuv.a
	sharpyuv_dylib=libsharpyuv.0.dylib
	

    
	
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		
		try ./configure \
		--prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
		--enable-shared \
		--enable-static \
		--enable-libwebpdecoder --enable-swap-16bit-csp \
		--enable-libwebpmux \
		--host=aarch64-apple-darwin
		
		webp_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags $1
#        echo "1"
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
#        echo $CC
        
		# try ./configure prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
		# --enable-shared \
		# --enable-static \
		# --host=${BUILDINGFOR}-apple-darwin
		try ./configure \
		--prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
		--enable-shared \
		--enable-static \
    	--enable-libwebpdecoder --enable-swap-16bit-csp \
    	--enable-libwebpmux \
		--host=${BUILDINGFOR}-apple-darwin 
#        echo "111"
        webp_compile
		restore
    elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
        save
        intelflags $1
        echo "2"
        # try make distclean
        echo "[|- CONFIG $BUILDINGFOR]"
        export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
        
        try ./configure \
        --prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --enable-libwebpdecoder --enable-swap-16bit-csp \
        --enable-libwebpmux \
        --host=${BUILDINGFOR}-apple-darwin 

        # try ./configure prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=${BUILDINGFOR}-apple-darwin
        webp_compile
        restore
    elif [ "$1" == "mac-arm64" ]; then
        save
        macflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure \
        --prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --enable-libwebpdecoder --enable-swap-16bit-csp \
        --enable-libwebpmux \
        --host=${MAC_HOST_TRIPLE}
        webp_compile
        restore
    elif [ "$1" == "mac-x86_64" ]; then
        save
        macx86flags
        echo "[|- CONFIG $BUILDINGFOR]"
        try ./configure \
        --prefix=${WEBP_LIB_DIR}_${BUILDINGFOR} \
        --enable-shared \
        --enable-static \
        --enable-libwebpdecoder --enable-swap-16bit-csp \
        --enable-libwebpmux \
        --host=${MAC_HOST_TRIPLE}
        webp_compile
        restore
    else
        echo "[ERR: Nothing to do for $1]"
    fi
	
	combine_libs "libwebp"
	combine_libs "libwebpdecoder"
	combine_libs "libwebpmux"
	combine_libs "libwebpdemux"
	combine_libs "libsharpyuv"
}

combine_libs() {
    local lib_name=$1
    joinlibs=$(check_for_archs $LIB_DIR/$lib_name.a)
    if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
        echo "[|- COMBINE $ARCHS]"
        accumul_dev=""
        accumul_sim=""
        for i in $ARCHS; do
            case "$i" in
                armv7|armv7s|arm64)
                    if [ -e $LIB_DIR/$lib_name.a.$i ]; then
                        accumul_dev="$accumul_dev -arch $i $LIB_DIR/$lib_name.a.$i"
                    fi
                ;;
                x86_64)
                    if [ -e $LIB_DIR/$lib_name.a.$i ]; then
                        accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$lib_name.a.$i"
                    fi
                ;;
                arm64-sim)
                    if [ -e $LIB_DIR/$lib_name.a.$i ]; then
                        accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$lib_name.a.$i"
                    fi
                ;;
            esac
        done
        if [ -n "$accumul_dev" ]; then
            try lipo $accumul_dev -create -output $LIB_DIR/$lib_name.a
        fi
        if [ -n "$accumul_sim" ]; then
            try lipo $accumul_sim -create -output $LIB_DIR/${lib_name}_sim.a
        fi
    fi

    if [ "$ENABLE_FAT" != "1" ]; then
        dev_src=""
        for cand in arm64 armv7s armv7; do
            file="$LIB_DIR/$lib_name.a.$cand"
            if [ -e "$file" ]; then
                dev_src="$file"
                break
            fi
        done
        if [ -n "$dev_src" ]; then
            try cp "$dev_src" "$LIB_DIR/$lib_name.a"
        fi
        if [ -e "$LIB_DIR/$lib_name.a.arm64-sim" ]; then
            try cp "$LIB_DIR/$lib_name.a.arm64-sim" "$LIB_DIR/${lib_name}_sim.a"
        fi
        if [ -e "$LIB_DIR/$lib_name.a.x86_64" ]; then
            try cp "$LIB_DIR/$lib_name.a.x86_64" "$LIB_DIR/${lib_name}_x86.a"
        fi
        mac_arm="$LIB_DIR/$lib_name.a.mac-arm64"
        mac_x86="$LIB_DIR/$lib_name.a.mac-x86_64"
        if [ -e "$mac_arm" ] && [ -e "$mac_x86" ]; then
            try lipo -create -output "$LIB_DIR/${lib_name}_mac.a" "$mac_arm" "$mac_x86"
        elif [ -e "$mac_arm" ]; then
            try cp "$mac_arm" "$LIB_DIR/${lib_name}_mac.a"
        elif [ -e "$mac_x86" ]; then
            try cp "$mac_x86" "$LIB_DIR/${lib_name}_mac.a"
        fi
    fi
}
