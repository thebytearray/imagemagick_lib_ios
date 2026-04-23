#!/bin/bash

zlib_compile() {
	echo "[|- MAKE zlib $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	try cp "${ZLIB_LIB_DIR}_${BUILDINGFOR}/lib/libz.a" "$LIB_DIR/libz.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/zlib"
		try cp "${ZLIB_LIB_DIR}_${BUILDINGFOR}/include/"*.h "$LIB_DIR/include/zlib/" 2>/dev/null || true
	fi
	try make distclean
}

_zlib_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

zlib() {
	echo "[+ zlib: $1]"
	cd "$ZLIB_DIR"
	LIBNAME_z=libz.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${ZLIB_LIB_DIR}_${BUILDINGFOR}"
		zlib_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${ZLIB_LIB_DIR}_${BUILDINGFOR}"
		zlib_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${ZLIB_LIB_DIR}_${BUILDINGFOR}"
		zlib_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		try ./configure --prefix="${ZLIB_LIB_DIR}_${BUILDINGFOR}"
		zlib_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		try ./configure --prefix="${ZLIB_LIB_DIR}_${BUILDINGFOR}"
		zlib_compile
		restore
	else
		echo "[ERR zlib: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_z")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_z.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_z.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_z.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_z.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_z.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_z.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_z"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libz_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_z.$cand" ] && try cp "$LIB_DIR/$LIBNAME_z.$cand" "$LIB_DIR/$LIBNAME_z" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_z.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_z.arm64-sim" "$LIB_DIR/libz_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_z.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_z.x86_64" "$LIB_DIR/libz_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_z.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_z.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libz_mac.a" "$LIB_DIR/$LIBNAME_z.mac-arm64" "$LIB_DIR/$LIBNAME_z.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_z.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_z.mac-arm64" "$LIB_DIR/libz_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_z.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_z.mac-x86_64" "$LIB_DIR/libz_mac.a"; fi
	fi
}
