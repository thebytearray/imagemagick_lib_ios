#!/bin/bash
# ICU4C — cross-build for iOS/macOS targets (Android-ImageMagick7 uses libicu4c-64-2).
# Requires a one-time native host build under $BUILDROOT/icu-host-bld (--with-cross-build).

icu_compile() {
	echo "[|- MAKE ICU $BUILDINGFOR]"
	try make -j"$CORESNUM"
	try make install
	try cp "${ICU_LIB_DIR}_${BUILDINGFOR}/lib/libicuuc.a" "$LIB_DIR/libicuuc.a.$BUILDINGFOR"
	try cp "${ICU_LIB_DIR}_${BUILDINGFOR}/lib/libicui18n.a" "$LIB_DIR/libicui18n.a.$BUILDINGFOR"
	try cp "${ICU_LIB_DIR}_${BUILDINGFOR}/lib/libicudata.a" "$LIB_DIR/libicudata.a.$BUILDINGFOR"
	first=$(echo "$ARCHS" | awk '{print $1;}')
	if [ "$BUILDINGFOR" == "$first" ]; then
		try mkdir -p "$LIB_DIR/include"
		try cp -R "${ICU_LIB_DIR}_${BUILDINGFOR}/include/unicode" "$LIB_DIR/include/"
	fi
	cd "$BUILDROOT" || exit 1
	try rm -rf "$ICU_TARGET_BLD"
}

_icu_host() {
	case "$BUILDINGFOR" in
		arm64|arm64-sim) echo "aarch64-apple-darwin" ;;
		armv7|armv7s) echo "arm-apple-darwin" ;;
		x86_64|i386) echo "${BUILDINGFOR}-apple-darwin" ;;
		mac-arm64) echo "arm-apple-darwin" ;;
		mac-x86_64) echo "x86_64-apple-darwin" ;;
		*) echo "arm-apple-darwin" ;;
	esac
}

_ensure_icu_host_tools() {
	local icu_src="$ICU_DIR"
	local host_bld="${BUILDROOT}/icu-host-bld"
	[ -f "$icu_src/configure" ] || {
		echo "[ERR] ICU source missing: $icu_src (run scripts/ensure-delegate-sources.sh)"
		exit 1
	}
	if [ -f "$host_bld/config.status" ]; then
		return 0
	fi
	echo "[+ ICU host tools (one-time, native macOS) -> $host_bld]"
	mkdir -p "$host_bld"
	(
		cd "$host_bld" || exit 1
		if [ -x "$icu_src/runConfigureICU" ]; then
			try "$icu_src/runConfigureICU" MacOSX
		else
			try "$icu_src/configure" --prefix="$host_bld/dist" --enable-static --disable-shared --disable-tests --disable-samples
		fi
		try make -j"$CORESNUM"
	)
}

icu() {
	echo "[+ ICU4C: $1]"
	_ensure_icu_host_tools
	local host_bld="${BUILDROOT}/icu-host-bld"
	export ICU_TARGET_BLD="${BUILDROOT}/icu-target-$1-bld"
	rm -rf "$ICU_TARGET_BLD"
	mkdir -p "$ICU_TARGET_BLD"

	_icu_configure_and_build() {
		cd "$ICU_TARGET_BLD" || exit 1
		try "$ICU_DIR/configure" \
			--host="$(_icu_host)" \
			--with-cross-build="$host_bld" \
			--prefix="${ICU_LIB_DIR}_${BUILDINGFOR}" \
			--enable-static \
			--disable-shared \
			--disable-tools \
			--disable-tests \
			--disable-samples \
			--disable-extras \
			--disable-renaming
		icu_compile
	}

	if [ "$1" == "arm64-sim" ]; then
		save
		armsimflags
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		_icu_configure_and_build
		restore
	elif [ "$1" == "armv7" ] || [ "$1" == "armv7s" ] || [ "$1" == "arm64" ]; then
		save
		armflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		_icu_configure_and_build
		restore
	elif [ "$1" == "i386" ] || [ "$1" == "x86_64" ]; then
		save
		intelflags "$1"
		export CC="$(xcode-select -print-path)/usr/bin/gcc"
		_icu_configure_and_build
		restore
	elif [ "$1" == "mac-arm64" ]; then
		save
		macflags "$1"
		_icu_configure_and_build
		restore
	elif [ "$1" == "mac-x86_64" ]; then
		save
		macx86flags
		_icu_configure_and_build
		restore
	else
		echo "[ERR icu: $1]"
	fi

	for _lib in libicuuc.a libicui18n.a libicudata.a; do
		joinlibs=$(check_for_archs "$LIB_DIR/$_lib")
		if [ "$joinlibs" == "OK" ] && [ "$ENABLE_FAT" = "1" ]; then
			accumul_dev=""
			accumul_sim=""
			for i in $ARCHS; do
				case "$i" in
					armv7|armv7s|arm64) [ -e "$LIB_DIR/$_lib.$i" ] && accumul_dev="$accumul_dev -arch $i $LIB_DIR/$_lib.$i" ;;
					x86_64) [ -e "$LIB_DIR/$_lib.$i" ] && accumul_sim="$accumul_sim -arch x86_64 $LIB_DIR/$_lib.$i" ;;
					arm64-sim) [ -e "$LIB_DIR/$_lib.$i" ] && accumul_sim="$accumul_sim -arch arm64 $LIB_DIR/$_lib.$i" ;;
				esac
			done
			[ -n "$accumul_dev" ] && try lipo $accumul_dev -create -output "$LIB_DIR/$_lib"
			[ -n "$accumul_sim" ] && try lipo $accumul_sim -create -output "$LIB_DIR/${_lib%.a}_sim.a"
		fi
	done
	if [ "$ENABLE_FAT" != "1" ]; then
		for _lib in libicuuc.a libicui18n.a libicudata.a; do
			for cand in arm64 armv7s armv7; do
				[ -e "$LIB_DIR/$_lib.$cand" ] && try cp "$LIB_DIR/$_lib.$cand" "$LIB_DIR/$_lib" && break
			done
		done
	fi
}
