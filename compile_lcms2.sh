#!/bin/bash

lcms2_compile() {
	echo "[|- MAKE lcms2 $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	echo "[|- CP STATIC $BUILDINGFOR]"
	try cp "${LCMS2_LIB_DIR}_${BUILDINGFOR}/lib/liblcms2.a" "$LIB_DIR/liblcms2.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/lcms2"
		try cp -r "${LCMS2_LIB_DIR}_${BUILDINGFOR}/include/." "$LIB_DIR/include/lcms2/"
	fi
	echo "[|- CLEAN $BUILDINGFOR]"
	try make distclean
}

_lcms2_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

lcms2() {
	echo "[+ lcms2: $1]"
	cd "$LCMS2_DIR"
	LIBNAME_lcms=liblcms2.a

	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${LCMS2_LIB_DIR}_${BUILDINGFOR}" --disable-shared --enable-static \
			--disable-dependency-tracking --host="$(_lcms2_host)"
		lcms2_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${LCMS2_LIB_DIR}_${BUILDINGFOR}" --disable-shared --enable-static \
			--disable-dependency-tracking --host="$(_lcms2_host)"
		lcms2_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LCMS2_LIB_DIR}_${BUILDINGFOR}" --disable-shared --enable-static \
			--disable-dependency-tracking --host="$(_lcms2_host)"
		lcms2_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LCMS2_LIB_DIR}_${BUILDINGFOR}" --disable-shared --enable-static \
			--disable-dependency-tracking --host="${MAC_HOST_TRIPLE}"
		lcms2_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		echo "[|- CONFIG $BUILDINGFOR]"
		try ./configure --prefix="${LCMS2_LIB_DIR}_${BUILDINGFOR}" --disable-shared --enable-static \
			--disable-dependency-tracking --host="${MAC_HOST_TRIPLE}"
		lcms2_compile
		restore
	else
		echo "[ERR: lcms2 nothing for $1]"
	fi

	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_lcms")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64)
					[ -e "$LIB_DIR/$LIBNAME_lcms.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_lcms.$i"
					;;
				x86_64)
					[ -e "$LIB_DIR/$LIBNAME_lcms.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_lcms.$i"
					;;
				arm64-sim)
					[ -e "$LIB_DIR/$LIBNAME_lcms.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_lcms.$i"
					;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_lcms"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/liblcms2_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			if [ -e "$LIB_DIR/$LIBNAME_lcms.$cand" ]; then
				try cp "$LIB_DIR/$LIBNAME_lcms.$cand" "$LIB_DIR/$LIBNAME_lcms"
				break
			fi
		done
		[ -e "$LIB_DIR/$LIBNAME_lcms.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_lcms.arm64-sim" "$LIB_DIR/liblcms2_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_lcms.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_lcms.x86_64" "$LIB_DIR/liblcms2_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_lcms.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_lcms.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/liblcms2_mac.a" "$LIB_DIR/$LIBNAME_lcms.mac-arm64" "$LIB_DIR/$LIBNAME_lcms.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_lcms.mac-arm64" ]; then
			try cp "$LIB_DIR/$LIBNAME_lcms.mac-arm64" "$LIB_DIR/liblcms2_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_lcms.mac-x86_64" ]; then
			try cp "$LIB_DIR/$LIBNAME_lcms.mac-x86_64" "$LIB_DIR/liblcms2_mac.a"
		fi
	fi
}
