#!/bin/bash

jpeg_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
        
    mkdir -p $LIB_DIR/jpeg_${BUILDINGFOR}_dylib
    mkdir -p ${JPEG_LIB_DIR}_${BUILDINGFOR}/
    
	try cp ${JPEG_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_jpeg $LIB_DIR/$LIBNAME_jpeg.$BUILDINGFOR
	try cp ${JPEG_LIB_DIR}_${BUILDINGFOR}/lib/libjpeg.9.dylib $LIB_DIR/jpeg_${BUILDINGFOR}_dylib/libjpeg.dylib
	first=`echo $ARCHS | awk '{print $1;}'`
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		try cp -r ${JPEG_LIB_DIR}_${BUILDINGFOR}/include/ $LIB_DIR/include/jpeg/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

jpeg () {
	 echo "[+ JPEG: $1]"
	 cd $JPEG_DIR
	 echo $JPEG_DIR
	 LIBPATH_jpeg=libjpeg.a
	 LIBNAME_jpeg=`basename $LIBPATH_jpeg`
	 
	 if [ "$1" == "arm64-sim" ]; then
		 save
		 armsimflags
		 echo "[|- CONFIG $BUILDINGFOR]"
		 export CC="$(xcode-select -print-path)/usr/bin/gcc"
		 try sh ./configure prefix=${JPEG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=arm-apple-darwin
		 jpeg_compile
		 restore
	 elif  [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		 save
		 armflags $1
		 echo "[|- CONFIG $BUILDINGFOR]"
		 try sh ./configure prefix=${JPEG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=arm-apple-darwin
		 jpeg_compile
		 restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags $1
        export CC="$(xcode-select -print-path)/usr/bin/gcc"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure prefix=${JPEG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=${BUILDINGFOR}-apple-darwin
		jpeg_compile
		restore
    elif [ "$1" == "mac-arm64" ]; then
        save
        macflags $1
        echo "[|- CONFIG $BUILDINGFOR]"
        try sh ./configure prefix=${JPEG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=${MAC_HOST_TRIPLE}
        jpeg_compile
        restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	 joinlibs=$(check_for_archs $LIB_DIR/$LIBNAME_jpeg)
	 if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		 echo "[|- COMBINE $ARCHS]"
		 accumul_dev=""
		 accumul_sim=""
		 for i in $ARCHS; do
			 case "$i" in
				 armv7|armv7s|arm64)
					 if [ -e $LIB_DIR/$LIBNAME_jpeg.$i ]; then
						 accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_jpeg.$i"
					 fi
				 ;;
				 x86_64)
					 if [ -e $LIB_DIR/$LIBNAME_jpeg.$i ]; then
						 accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_jpeg.$i"
					 fi
				 ;;
				 arm64-sim)
					 if [ -e $LIB_DIR/$LIBNAME_jpeg.$i ]; then
						 accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_jpeg.$i"
					 fi
				 ;;
			 esac
		 done
		 if [ -n "$accumul_dev" ]; then
			 try lipo $accumul_dev -create -output $LIB_DIR/$LIBNAME_jpeg
			 echo "[+ DEVICE FAT DONE]"
		 fi
		 if [ -n "$accumul_sim" ]; then
			 try lipo $accumul_sim -create -output $LIB_DIR/`basename $LIBNAME_jpeg .a`_sim.a
			 echo "[+ SIMULATOR FAT DONE]"
		 fi
	 fi

	 if [ "$ENABLE_FAT" != "1" ]; then
		 dev_src=""
		 for cand in arm64 armv7s armv7; do
			 file="$LIB_DIR/$LIBNAME_jpeg.$cand"
			 if [ -e "$file" ]; then
				 dev_src="$file"
				 break
			 fi
		 done
		 if [ -n "$dev_src" ]; then
			 try cp "$dev_src" "$LIB_DIR/$LIBNAME_jpeg"
		 fi
		 if [ -e "$LIB_DIR/$LIBNAME_jpeg.arm64-sim" ]; then
			 try cp "$LIB_DIR/$LIBNAME_jpeg.arm64-sim" "$LIB_DIR/`basename $LIBNAME_jpeg .a`_sim.a"
		 fi
		 if [ -e "$LIB_DIR/$LIBNAME_jpeg.x86_64" ]; then
			 try cp "$LIB_DIR/$LIBNAME_jpeg.x86_64" "$LIB_DIR/`basename $LIBNAME_jpeg .a`_x86.a"
		 fi
		 if [ -e "$LIB_DIR/$LIBNAME_jpeg.mac-arm64" ]; then
			 try cp "$LIB_DIR/$LIBNAME_jpeg.mac-arm64" "$LIB_DIR/`basename $LIBNAME_jpeg .a`_mac.a"
		 fi
	 fi
}
