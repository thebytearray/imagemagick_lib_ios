#!/bin/bash

fftw_compile() {
	echo "[|- MAKE fftw $BUILDINGFOR]"
	try make -j$CORESNUM
	try make install
	try cp "${FFTW_LIB_DIR}_${BUILDINGFOR}/lib/libfftw3.a" "$LIB_DIR/libfftw3.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include/fftw"
		try cp "${FFTW_LIB_DIR}_${BUILDINGFOR}/include/fftw3.h" "$LIB_DIR/include/fftw/" 2>/dev/null || try cp -r "${FFTW_LIB_DIR}_${BUILDINGFOR}/include/." "$LIB_DIR/include/fftw/"
	fi
	try make distclean
}

_fftw_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

fftw() {
	echo "[+ fftw3: $1]"
	cd "$FFTW_DIR"
	LIBNAME_f=libfftw3.a
	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${FFTW_LIB_DIR}_${BUILDINGFOR}" --disable-fortran --enable-static --disable-shared \
			--host="$(_fftw_host)"
		fftw_compile
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${FFTW_LIB_DIR}_${BUILDINGFOR}" --disable-fortran --enable-static --disable-shared \
			--host="$(_fftw_host)"
		fftw_compile
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		try ./configure --prefix="${FFTW_LIB_DIR}_${BUILDINGFOR}" --disable-fortran --enable-static --disable-shared \
			--host="$(_fftw_host)"
		fftw_compile
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		try ./configure --prefix="${FFTW_LIB_DIR}_${BUILDINGFOR}" --disable-fortran --enable-static --disable-shared \
			--host="${MAC_HOST_TRIPLE}"
		fftw_compile
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		try ./configure --prefix="${FFTW_LIB_DIR}_${BUILDINGFOR}" --disable-fortran --enable-static --disable-shared \
			--host="${MAC_HOST_TRIPLE}"
		fftw_compile
		restore
	else
		echo "[ERR fftw: $1]"
	fi
	joinlibs=$(check_for_archs "$LIB_DIR/$LIBNAME_f")
	if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
		accumul_dev=""
		accumul_sim=""
		for i in $ARCHS; do
			case "$i" in
				armv7|armv7s|arm64) [ -e "$LIB_DIR/$LIBNAME_f.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$LIBNAME_f.$i" ;;
				x86_64) [ -e "$LIB_DIR/$LIBNAME_f.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$LIBNAME_f.$i" ;;
				arm64-sim) [ -e "$LIB_DIR/$LIBNAME_f.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$LIBNAME_f.$i" ;;
			esac
		done
		[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$LIBNAME_f"
		[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/libfftw3_sim.a"
	fi
	if [ "$ENABLE_FAT" != "1" ]; then
		for cand in arm64 armv7s armv7; do
			[ -e "$LIB_DIR/$LIBNAME_f.$cand" ] && try cp "$LIB_DIR/$LIBNAME_f.$cand" "$LIB_DIR/$LIBNAME_f" && break
		done
		[ -e "$LIB_DIR/$LIBNAME_f.arm64-sim" ] && try cp "$LIB_DIR/$LIBNAME_f.arm64-sim" "$LIB_DIR/libfftw3_sim.a"
		[ -e "$LIB_DIR/$LIBNAME_f.x86_64" ] && try cp "$LIB_DIR/$LIBNAME_f.x86_64" "$LIB_DIR/libfftw3_x86.a"
		if [ -e "$LIB_DIR/$LIBNAME_f.mac-arm64" ] && [ -e "$LIB_DIR/$LIBNAME_f.mac-x86_64" ]; then
			try lipo -create -output "$LIB_DIR/libfftw3_mac.a" "$LIB_DIR/$LIBNAME_f.mac-arm64" "$LIB_DIR/$LIBNAME_f.mac-x86_64"
		elif [ -e "$LIB_DIR/$LIBNAME_f.mac-arm64" ]; then try cp "$LIB_DIR/$LIBNAME_f.mac-arm64" "$LIB_DIR/libfftw3_mac.a"
		elif [ -e "$LIB_DIR/$LIBNAME_f.mac-x86_64" ]; then try cp "$LIB_DIR/$LIBNAME_f.mac-x86_64" "$LIB_DIR/libfftw3_mac.a"; fi
	fi
}
