#!/bin/bash

# bzip2 uses a hand-written Makefile (no configure).

bzlib_compile() {
	echo "[|- MAKE bzip2 $BUILDINGFOR]"
	try make -j$CORESNUM CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" libbz2.a
	try cp libbz2.a "$LIB_DIR/libbz2.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/bzlib"
		try cp bzlib.h "$LIB_DIR/include/bzlib/"
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make clean
}

bzlib() {
	echo "[+ bzip2: $1]"
	cd "$BZIP2_DIR"
	LIBNAME_bz=libbz2.a
	export AR="${AR:-$(xcrun -find ar)}"
	export RANLIB="${RANLIB:-$(xcrun -find ranlib)}"

	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		bzlib_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcrun -find -sdk iphoneos clang)"
		bzlib_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		bzlib_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		export CC="$(xcrun -find -sdk macosx clang)"
		bzlib_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		export CC="$(xcrun -find -sdk macosx clang)"
		bzlib_compile
		restore
	else
		echo "[ERR: bzlib nothing for $1]"
	fi

	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_bz")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64)
					[ -e "$LIB_DIR/$LIBNAME_bz.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_bz.$i"
					;;
				x86_64)
					[ -e "$LIB_DIR/$LIBNAME_bz.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_bz.$i"
					;;
				arm64-sim)
					[ -e "$LIB_DIR/$LIBNAME_bz.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_bz.$i"
					;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_bz"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libbz2_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			if [ -e "$LIB_DIR/$LIBNAME_bz.$cand" ]; then
				try cp "$LIB_DIR/$LIBNAME_bz.$cand" "$LIB_DIR/$LIBNAME_bz"
				break
			fi
		done
		[ -e "$LIB_DIR/$LIBNAME_bz.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_bz.arm64-sim" "$LIB_DIR/libbz2_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_bz.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_bz.x86_64" "$LIB_DIR/libbz2_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_bz.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_bz.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libbz2_mac.a" "$LIB_DIR/$LIBNAME_bz.mac-arm64" "$LIB_DIR/$LIBNAME_bz.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_bz.mac-arm64" ]; then
			try cp "$LIB_DIR/$LIBNAME_bz.mac-arm64" "$LIB_DIR/libbz2_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_bz.mac-x86_64" ]; then
			try cp "$LIB_DIR/$LIBNAME_bz.mac-x86_64" "$LIB_DIR/libbz2_mac.a"
		fi
	fi
}
