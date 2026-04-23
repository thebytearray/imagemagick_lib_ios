#!/bin/bash

heif_compile() {
	local p="${HEIF_LIB_DIR}_${BUILDINGFOR}"
	local dp="${DE265_LIB_DIR}_${BUILDINGFOR}"
	local ap="${AOM_LIB_DIR}_${BUILDINGFOR}"
	echo "[|- CMAKE libheif $BUILDINGFOR"
	rm -rf _heifbuild
	mkdir _heifbuild
	(
		cd _heifbuild
		local sysroot="" archc=""
		case "$1" in
			armv7|armv7s|arm64) sysroot="$IOSSDKROOT" archc="$1" ;;
			arm64-sim) sysroot="$SIMSDKROOT" archc="arm64" ;;
			i386|x86_64) sysroot="$SIMSDKROOT" archc="$1" ;;
			mac-arm64) sysroot="$MACSDKROOT" archc="arm64" ;;
			mac-x86_64) sysroot="$MACSDKROOT" archc="x86_64" ;;
		esac
		try cmake "$HEIF_DIR" \
			-DCMAKE_INSTALL_PREFIX="$p" \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_PREFIX_PATH="$dp;$ap" \
			-DWITH_LIBDE265=ON \
			-DWITH_AOM_DECODER=ON \
			-DWITH_AOM_ENCODER=ON \
			-DBUILD_SHARED_LIBS=OFF \
			-DBUILD_STATIC_LIBS=ON \
			-DENABLE_PLUGIN_LOADING=OFF \
			-DCMAKE_OSX_SYSROOT="$sysroot" \
			-DCMAKE_OSX_ARCHITECTURES="$archc" \
			-DCMAKE_C_COMPILER="${CC:-$(xcrun -find clang)}" \
			-DCMAKE_CXX_COMPILER="${CXX:-$(xcrun -find clang++)}"
		try cmake --build . --parallel "${CORESNUM:-4}"
		try cmake --install .
	)
	rm -rf _heifbuild
	try cp "${p}/lib/libheif.a" "$LIB_DIR/libheif.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/libheif"
		try cp -r "${p}/include/libheif/." "$LIB_DIR/include/libheif/" 2>/dev/null || try cp -r "${p}/include/." "$LIB_DIR/include/libheif/"
	fi
}

heif() {
	echo "[+ libheif: $1]"
	cd "$HEIF_DIR"
	LIBNAME_h=libheif.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		export CXX="$(xcrun -find -sdk iphonesimulator clang++)"
		heif_compile "$1"
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcrun -find -sdk iphoneos clang)"
		export CXX="$(xcrun -find -sdk iphoneos clang++)"
		heif_compile "$1"
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcrun -find -sdk iphonesimulator clang)"
		export CXX="$(xcrun -find -sdk iphonesimulator clang++)"
		heif_compile "$1"
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		export CC="$(xcrun -find -sdk macosx clang)"
		export CXX="$(xcrun -find -sdk macosx clang++)"
		heif_compile "$1"
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		export CC="$(xcrun -find -sdk macosx clang)"
		export CXX="$(xcrun -find -sdk macosx clang++)"
		heif_compile "$1"
		restore
	else
		echo "[ERR heif: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_h")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_h.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_h.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_h.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_h.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_h.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_h.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_h"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libheif_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_h.$cand" ] && try cp "$LIB_DIR/$LIBNAME_h.$cand" "$LIB_DIR/$LIBNAME_h" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_h.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_h.arm64-sim" "$LIB_DIR/libheif_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_h.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_h.x86_64" "$LIB_DIR/libheif_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_h.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_h.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libheif_mac.a" "$LIB_DIR/$LIBNAME_h.mac-arm64" "$LIB_DIR/$LIBNAME_h.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_h.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_h.mac-arm64" "$LIB_DIR/libheif_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_h.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_h.mac-x86_64" "$LIB_DIR/libheif_mac.a"; fi
	fi
}
