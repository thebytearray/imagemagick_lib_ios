#!/bin/bash
# libjpeg-turbo — CMake build (iOS-aligned via scripts/ios_delegate_cmake.sh).

jpegturbo_compile() {
	local p="${JPEG_LIB_DIR}_${BUILDINGFOR}"
	echo "[|- CMAKE install libjpeg-turbo $BUILDINGFOR"
	im_ios_delegate_cmake_base "$1"
	rm -rf _jtbuild
	mkdir _jtbuild
	(
		cd _jtbuild
		try cmake .. \
			-DCMAKE_INSTALL_PREFIX="$p" \
			"${_IM_CMAKE_OPTS[@]}" \
			-DENABLE_STATIC=ON \
			-DENABLE_SHARED=OFF \
			-DWITH_JPEG8=ON
		try cmake --build . --parallel "${CORESNUM:-4}"
		try cmake --install .
	)
	rm -rf _jtbuild
	try cp "${p}/lib/libjpeg.a" "$LIB_DIR/libjpeg.a.$BUILDINGFOR"
	mkdir -p "$LIB_DIR/jpeg_${BUILDINGFOR}_dylib"
	shopt -s nullglob
	_jd=("${p}/lib"/libjpeg.*.dylib)
	shopt -u nullglob
	if [ "${#_jd[@]}" -gt 0 ]; then
		try cp "${_jd[0]}" "$LIB_DIR/jpeg_${BUILDINGFOR}_dylib/libjpeg.dylib"
	fi
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/jpeg"
		try cp -r "${p}/include/." "$LIB_DIR/include/jpeg/"
	fi
}

jpegturbo() {
	echo "[+ libjpeg-turbo: $1]"
	cd "$JPEG_TURBO_DIR"
	LIBNAME_j=libjpeg.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		jpegturbo_compile "$1"
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcrun -find -sdk iphoneos clang)"
		jpegturbo_compile "$1"
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		jpegturbo_compile "$1"
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		export CC="$(xcrun -find -sdk macosx clang)"
		jpegturbo_compile "$1"
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		export CC="$(xcrun -find -sdk macosx clang)"
		jpegturbo_compile "$1"
		restore
	else
		echo "[ERR jpegturbo: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_j")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_j.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_j.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_j.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_j.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_j.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_j.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_j"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libjpeg_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_j.$cand" ] && try cp "$LIB_DIR/$LIBNAME_j.$cand" "$LIB_DIR/$LIBNAME_j" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_j.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_j.arm64-sim" "$LIB_DIR/libjpeg_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_j.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_j.x86_64" "$LIB_DIR/libjpeg_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_j.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_j.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libjpeg_mac.a" "$LIB_DIR/$LIBNAME_j.mac-arm64" "$LIB_DIR/$LIBNAME_j.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_j.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_j.mac-arm64" "$LIB_DIR/libjpeg_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_j.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_j.mac-x86_64" "$LIB_DIR/libjpeg_mac.a"; fi
	fi
}
