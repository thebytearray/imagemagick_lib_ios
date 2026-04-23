#!/bin/bash

aom_compile() {
	local p="${AOM_LIB_DIR}_${BUILDINGFOR}"
	echo "[|- CMAKE libaom $BUILDINGFOR"
	im_ios_delegate_cmake_base "$1"
	_neon=1
	case "${_IM_CMAKE_ARCH}" in x86_64|i386) _neon=0 ;; esac
	rm -rf _aombuild
	mkdir _aombuild
	(
		cd _aombuild
		try cmake "$AOM_DIR" \
			-DCMAKE_INSTALL_PREFIX="$p" \
			"${_IM_CMAKE_OPTS[@]}" \
			-DENABLE_DOCS=0 \
			-DENABLE_TESTS=0 \
			-DENABLE_TOOLS=0 \
			-DENABLE_EXAMPLES=0 \
			-DBUILD_SHARED_LIBS=OFF \
			-DCONFIG_AV1_DECODER=1 \
			-DCONFIG_AV1_ENCODER=1 \
			-DAOM_TARGET_CPU=generic \
			-DENABLE_NEON="$_neon"
		try cmake --build . --parallel "${CORESNUM:-4}"
		try cmake --install .
	)
	rm -rf _aombuild
	try cp "${p}/lib/libaom.a" "$LIB_DIR/libaom.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/aom"
		try cp -r "${p}/include/aom/." "$LIB_DIR/include/aom/"
	fi
}

aom() {
	echo "[+ libaom: $1]"
	cd "$AOM_DIR"
	LIBNAME_a=libaom.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		export CXX="$(xcrun -find -sdk iphonesimulator clang++)"
		aom_compile "$1"
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcrun -find -sdk iphoneos clang)"
		export CXX="$(xcrun -find -sdk iphoneos clang++)"
		aom_compile "$1"
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		export CXX="$(xcrun -find -sdk iphonesimulator clang++)"
		aom_compile "$1"
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		export CC="$(xcrun -find -sdk macosx clang)"
		export CXX="$(xcrun -find -sdk macosx clang++)"
		aom_compile "$1"
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		export CC="$(xcrun -find -sdk macosx clang)"
		export CXX="$(xcrun -find -sdk macosx clang++)"
		aom_compile "$1"
		restore
	else
		echo "[ERR aom: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_a")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_a.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_a.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_a.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_a.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_a.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_a.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_a"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libaom_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_a.$cand" ] && try cp "$LIB_DIR/$LIBNAME_a.$cand" "$LIB_DIR/$LIBNAME_a" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_a.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_a.arm64-sim" "$LIB_DIR/libaom_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_a.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_a.x86_64" "$LIB_DIR/libaom_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_a.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_a.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libaom_mac.a" "$LIB_DIR/$LIBNAME_a.mac-arm64" "$LIB_DIR/$LIBNAME_a.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_a.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_a.mac-arm64" "$LIB_DIR/libaom_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_a.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_a.mac-x86_64" "$LIB_DIR/libaom_mac.a"; fi
	fi
}
