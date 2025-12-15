#!/bin/bash

png_compile() {
	echo "[|- MAKE $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC/DYLIB $BUILDINGFOR]"
    
    mkdir -p $LIB_DIR/png_${BUILDINGFOR}_dylib
    mkdir -p ${PNG_LIB_DIR}_${BUILDINGFOR}/
    
	try cp ${PNG_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_png $LIB_DIR/libpng.a.$BUILDINGFOR
	try cp ${PNG_LIB_DIR}_${BUILDINGFOR}/lib/$LIBPATH_png_dylib $LIB_DIR/png_${BUILDINGFOR}_dylib/libpng.dylib
    
	first=`echo $ARCHS | awk '{print $1;}'`
    
	if [ "$BUILDINGFOR" == "$first" ]; then
		echo "[|- CP include files (arch ref: $first)]"
		# copy the include files
		try cp -r ${PNG_LIB_DIR}_${BUILDINGFOR}/include/libpng*/ $LIB_DIR/include/png/
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

png () {
	echo "[+ PNG: $1]"
	cd $PNG_DIR
	
	LIBPATH_png=libpng16.a
	LIBPATH_png_dylib=libpng16.dylib
    
	
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		try ./configure prefix=${PNG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=arm-apple-darwin
		png_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags $1
#        echo "1"
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
#        echo $CC
        
		try ./configure prefix=${PNG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=arm-apple-darwin
#        echo "111"
		png_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags $1
        echo "2"
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc" # override clang
		try ./configure prefix=${PNG_LIB_DIR}_${BUILDINGFOR} --enable-shared --enable-static --host=${BUILDINGFOR}-apple-darwin
		png_compile
		restore
	else
		echo "[ERR: Nothing to do for $1]"
	fi
	
	 joinlibs=$(check_for_archs $LIB_DIR/libpng.a)
	 if [ $joinlibs == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		 echo "[|- COMBINE $ARCHS]"
		 accumul_dev=""
		 accumul_sim=""
		 for i in $ARCHS; do
			 case "$i" in
				 armv7|armv7s|arm64)
					 if [ -e $LIB_DIR/libpng.a.$i ]; then
						 accumul_dev="$accumul_dev -arch $i $LIB_DIR/libpng.a.$i"
					 fi
				 ;;
				 x86_64)
					 if [ -e $LIB_DIR/libpng.a.$i ]; then
						 accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/libpng.a.$i"
					 fi
				 ;;
				 arm64-sim)
					 if [ -e $LIB_DIR/libpng.a.$i ]; then
						 accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/libpng.a.$i"
					 fi
				 ;;
			 esac
		 done
		 if [ -n "$accumul_dev" ]; then
			 try lipo $accumul_dev -create -output $LIB_DIR/libpng.a
			 echo "[+ DEVICE FAT DONE]"
		 fi
		 if [ -n "$accumul_sim" ]; then
			 try lipo $accumul_sim -create -output $LIB_DIR/libpng_sim.a
			 echo "[+ SIMULATOR FAT DONE]"
		 fi
	 fi

	 if [ "$ENABLE_FAT" != "1" ]; then
		 dev_src=""
		 for cand in arm64 armv7s armv7; do
			 file="$LIB_DIR/libpng.a.$cand"
			 if [ -e "$file" ]; then
				 dev_src="$file"
				 break
			 fi
		 done
		 if [ -n "$dev_src" ]; then
			 try cp "$dev_src" "$LIB_DIR/libpng.a"
		 fi
		 if [ -e "$LIB_DIR/libpng.a.arm64-sim" ]; then
			 try cp "$LIB_DIR/libpng.a.arm64-sim" "$LIB_DIR/libpng_sim.a"
		 fi
		 if [ -e "$LIB_DIR/libpng.a.x86_64" ]; then
			 try cp "$LIB_DIR/libpng.a.x86_64" "$LIB_DIR/libpng_x86.a"
		 fi
	 fi
}
