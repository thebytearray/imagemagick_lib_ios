#!/bin/bash

xml2_compile() {
	echo "[|- MAKE libxml2 $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	try cp "${XML2_LIB_DIR}_${BUILDINGFOR}/lib/libxml2.a" "$LIB_DIR/libxml2.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/libxml2"
		try cp -r "${XML2_LIB_DIR}_${BUILDINGFOR}/include/libxml2" "$LIB_DIR/include/"
		# Optional top-level headers (not always installed next to libxml2/ in 2.9.x).
		shopt -s nullglob
		for _h in "${XML2_LIB_DIR}_${BUILDINGFOR}/include"/libxml*.h; do
			[ -f "$_h" ] && cp "$_h" "$LIB_DIR/include/"
		done
		shopt -u nullglob
	fi
	try make distclean
}

_xml2_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

xml2() {
	echo "[+ libxml2: $1]"
	cd "$XML2_DIR"
	LIBNAME_x2=libxml2.a
	if [ "${ENABLE_ICU:-1}" = "1" ]; then
		_icu_flags=(--with-icu="${ICU_LIB_DIR}_${BUILDINGFOR}")
	else
		_icu_flags=(--without-icu)
	fi
	_cfg=(--prefix="${XML2_LIB_DIR}_${BUILDINGFOR}" --without-python --without-readline \
		--with-zlib="${ZLIB_LIB_DIR}_${BUILDINGFOR}" --with-iconv="${ICONV_LIB_DIR}_${BUILDINGFOR}" \
		--with-lzma="${LZMA_LIB_DIR}_${BUILDINGFOR}" "${_icu_flags[@]}")
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure "${_cfg[@]}" --host="$(_xml2_host)"
		xml2_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure "${_cfg[@]}" --host="$(_xml2_host)"
		xml2_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure "${_cfg[@]}" --host="$(_xml2_host)"
		xml2_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		try ./configure "${_cfg[@]}" --host="${MAC_HOST_TRIPLE}"
		xml2_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		try ./configure "${_cfg[@]}" --host="${MAC_HOST_TRIPLE}"
		xml2_compile
		restore
	else
		echo "[ERR xml2: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_x2")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_x2.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_x2.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_x2.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_x2.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_x2.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_x2.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_x2"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libxml2_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_x2.$cand" ] && try cp "$LIB_DIR/$LIBNAME_x2.$cand" "$LIB_DIR/$LIBNAME_x2" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_x2.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_x2.arm64-sim" "$LIB_DIR/libxml2_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_x2.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_x2.x86_64" "$LIB_DIR/libxml2_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_x2.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_x2.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libxml2_mac.a" "$LIB_DIR/$LIBNAME_x2.mac-arm64" "$LIB_DIR/$LIBNAME_x2.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_x2.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_x2.mac-arm64" "$LIB_DIR/libxml2_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_x2.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_x2.mac-x86_64" "$LIB_DIR/libxml2_mac.a"; fi
	fi
}
