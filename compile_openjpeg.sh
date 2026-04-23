#!/bin/bash

# OpenJPEG 2.x — CMake build.

openjpeg_compile() {
	local prefix="${OPENJPEG_LIB_DIR}_${BUILDINGFOR}"
	echo "[|- CMAKE install OpenJPEG $BUILDINGFOR -> $prefix]"
	rm -rf _buildoj
	mkdir _buildoj
	(
		cd _buildoj
		local sysroot=""
		local archcmake=""
		case "$1" in
			armv7|armv7s|arm64)
				sysroot="$IOSSDKROOT"
				archcmake="$1"
				;;
			arm64-sim)
				sysroot="$SIMSDKROOT"
				archcmake="arm64"
				;;
			i386|x86_64)
				sysroot="$SIMSDKROOT"
				archcmake="$1"
				;;
			mac-arm64)
				sysroot="$MACSDKROOT"
				archcmake="arm64"
				;;
			mac-x86_64)
				sysroot="$MACSDKROOT"
				archcmake="x86_64"
				;;
		esac
		try cmake .. \
			-DCMAKE_INSTALL_PREFIX="$prefix" \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_SHARED_LIBS=ON \
			-DBUILD_STATIC_LIBS=ON \
			-DBUILD_CODEC=ON \
			-DCMAKE_OSX_SYSROOT="$sysroot" \
			-DCMAKE_OSX_ARCHITECTURES="$archcmake" \
			-DCMAKE_C_COMPILER="${CC:-$(xcrun -find clang)}"
		try cmake --build . --parallel "${CORESNUM:-4}"
		try cmake --install .
	)
	rm -rf _buildoj
	echo "[|- CP STATIC $BUILDINGFOR]"
	try cp "${prefix}/lib/libopenjp2.a" "$LIB_DIR/libopenjp2.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/openjp2"
		try cp -r "${prefix}/include/openjpeg-"*/* "$LIB_DIR/include/openjp2/" 2>/dev/null || try cp "${prefix}/include/openjpeg.h" "$LIB_DIR/include/openjp2/" 2>/dev/null || true
		# openjpeg 2.5 installs into include/openjpeg-2.5/
		if [ -d "${prefix}/include" ]; then
			try cp -r "${prefix}/include/." "$LIB_DIR/include/openjp2/" 2>/dev/null || true
		fi
	fi
}

openjpeg() {
	echo "[+ openjpeg: $1]"
	cd "$OPENJPEG_DIR"
	LIBNAME_oj=libopenjp2.a

	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		openjpeg_compile "$1"
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcrun -find -sdk iphoneos clang)"
		openjpeg_compile "$1"
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		openjpeg_compile "$1"
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		export CC="$(xcrun -find -sdk macosx clang)"
		openjpeg_compile "$1"
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		export CC="$(xcrun -find -sdk macosx clang)"
		openjpeg_compile "$1"
		restore
	else
		echo "[ERR: openjpeg nothing for $1]"
	fi

	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_oj")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64)
					[ -e "$LIB_DIR/$LIBNAME_oj.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_oj.$i"
					;;
				x86_64)
					[ -e "$LIB_DIR/$LIBNAME_oj.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_oj.$i"
					;;
				arm64-sim)
					[ -e "$LIB_DIR/$LIBNAME_oj.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_oj.$i"
					;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_oj"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libopenjp2_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			if [ -e "$LIB_DIR/$LIBNAME_oj.$cand" ]; then
				try cp "$LIB_DIR/$LIBNAME_oj.$cand" "$LIB_DIR/$LIBNAME_oj"
				break
			fi
		done
		[ -e "$LIB_DIR/$LIBNAME_oj.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_oj.arm64-sim" "$LIB_DIR/libopenjp2_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_oj.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_oj.x86_64" "$LIB_DIR/libopenjp2_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_oj.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_oj.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libopenjp2_mac.a" "$LIB_DIR/$LIBNAME_oj.mac-arm64" "$LIB_DIR/$LIBNAME_oj.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_oj.mac-arm64" ]; then
			try cp "$LIB_DIR/$LIBNAME_oj.mac-arm64" "$LIB_DIR/libopenjp2_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_oj.mac-x86_64" ]; then
			try cp "$LIB_DIR/$LIBNAME_oj.mac-x86_64" "$LIB_DIR/libopenjp2_mac.a"
		fi
	fi
}
