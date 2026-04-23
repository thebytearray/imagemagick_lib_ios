#!/bin/bash

de265_compile() {
	echo "[|- MAKE libde265 $BUILDINGFOR]"
	# Build only the library: tools/ use system(3), unavailable on iOS (see rd-curves.cc).
	try make -C libde265 -j$CORESNUM
	try make -C libde265 install
	try cp "${DE265_LIB_DIR}_${BUILDINGFOR}/lib/libde265.a" "$LIB_DIR/libde265.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/libde265"
		try cp -r "${DE265_LIB_DIR}_${BUILDINGFOR}/include/." "$LIB_DIR/include/libde265/"
	fi
	try make -C libde265 distclean
}

_de265_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

de265() {
	echo "[+ libde265: $1]"
	cd "$DE265_DIR"
	LIBNAME_d=libde265.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		try ./configure --prefix="${DE265_LIB_DIR}_${BUILDINGFOR}" --enable-static --disable-shared --disable-dec265 --disable-sherlock265 \
			--host="$(_de265_host)"
		de265_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		try ./configure --prefix="${DE265_LIB_DIR}_${BUILDINGFOR}" --enable-static --disable-shared --disable-dec265 --disable-sherlock265 \
			--host="$(_de265_host)"
		de265_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		try ./configure --prefix="${DE265_LIB_DIR}_${BUILDINGFOR}" --enable-static --disable-shared --disable-dec265 --disable-sherlock265 \
			--host="$(_de265_host)"
		de265_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		try ./configure --prefix="${DE265_LIB_DIR}_${BUILDINGFOR}" --enable-static --disable-shared --disable-dec265 --disable-sherlock265 \
			--host="${MAC_HOST_TRIPLE}"
		de265_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		try ./configure --prefix="${DE265_LIB_DIR}_${BUILDINGFOR}" --enable-static --disable-shared --disable-dec265 --disable-sherlock265 \
			--host="${MAC_HOST_TRIPLE}"
		de265_compile
		restore
	else
		echo "[ERR de265: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_d")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_d.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_d.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_d.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_d.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_d.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_d.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_d"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libde265_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_d.$cand" ] && try cp "$LIB_DIR/$LIBNAME_d.$cand" "$LIB_DIR/$LIBNAME_d" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_d.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_d.arm64-sim" "$LIB_DIR/libde265_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_d.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_d.x86_64" "$LIB_DIR/libde265_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_d.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_d.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libde265_mac.a" "$LIB_DIR/$LIBNAME_d.mac-arm64" "$LIB_DIR/$LIBNAME_d.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_d.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_d.mac-arm64" "$LIB_DIR/libde265_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_d.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_d.mac-x86_64" "$LIB_DIR/libde265_mac.a"; fi
	fi
}
