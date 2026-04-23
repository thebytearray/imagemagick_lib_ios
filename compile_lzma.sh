#!/bin/bash

lzma_compile() {
	echo "[|- MAKE lzma $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC $BUILDINGFOR]"
	try cp "${LZMA_LIB_DIR}_${BUILDINGFOR}/lib/liblzma.a" "$LIB_DIR/liblzma.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/lzma"
		try cp -r "${LZMA_LIB_DIR}_${BUILDINGFOR}/include/." "$LIB_DIR/include/lzma/"
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

_lzma_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

lzma() {
	echo "[+ LZMA/xz: $1]"
	cd "$LZMA_DIR"
	LIBNAME_lzma=liblzma.a

	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${LZMA_LIB_DIR}_${BUILDINGFOR}" --disable-debug --disable-dependency-tracking \
			--enable-static --disable-shared --host="$(_lzma_host)"
		lzma_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${LZMA_LIB_DIR}_${BUILDINGFOR}" --disable-debug --disable-dependency-tracking \
			--enable-static --disable-shared --host="$(_lzma_host)"
		lzma_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LZMA_LIB_DIR}_${BUILDINGFOR}" --disable-debug --disable-dependency-tracking \
			--enable-static --disable-shared --host="$(_lzma_host)"
		lzma_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LZMA_LIB_DIR}_${BUILDINGFOR}" --disable-debug --disable-dependency-tracking \
			--enable-static --disable-shared --host="${MAC_HOST_TRIPLE}"
		lzma_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LZMA_LIB_DIR}_${BUILDINGFOR}" --disable-debug --disable-dependency-tracking \
			--enable-static --disable-shared --host="${MAC_HOST_TRIPLE}"
		lzma_compile
		restore
	else
		echo "[ERR: lzma nothing for $1]"
	fi

	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_lzma")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64)
					[ -e "$LIB_DIR/$LIBNAME_lzma.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_lzma.$i"
					;;
				x86_64)
					[ -e "$LIB_DIR/$LIBNAME_lzma.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_lzma.$i"
					;;
				arm64-sim)
					[ -e "$LIB_DIR/$LIBNAME_lzma.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_lzma.$i"
					;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_lzma"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/liblzma_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			if [ -e "$LIB_DIR/$LIBNAME_lzma.$cand" ]; then
				try cp "$LIB_DIR/$LIBNAME_lzma.$cand" "$LIB_DIR/$LIBNAME_lzma"
				break
			fi
		done
		[ -e "$LIB_DIR/$LIBNAME_lzma.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_lzma.arm64-sim" "$LIB_DIR/liblzma_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_lzma.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_lzma.x86_64" "$LIB_DIR/liblzma_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_lzma.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_lzma.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/liblzma_mac.a" "$LIB_DIR/$LIBNAME_lzma.mac-arm64" "$LIB_DIR/$LIBNAME_lzma.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_lzma.mac-arm64" ]; then
			try cp "$LIB_DIR/$LIBNAME_lzma.mac-arm64" "$LIB_DIR/liblzma_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_lzma.mac-x86_64" ]; then
			try cp "$LIB_DIR/$LIBNAME_lzma.mac-x86_64" "$LIB_DIR/liblzma_mac.a"
		fi
	fi
}
