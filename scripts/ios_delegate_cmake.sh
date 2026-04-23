#!/bin/bash
# Shared CMake settings for iOS Simulator / iOS device / macOS delegate libraries.
# Sourced from all.sh after flags.sh. Call im_ios_delegate_cmake_base after armflags/armsimflags/intelflags/macflags
# so CC/CXX/CFLAGS/CXXFLAGS match the same SDK as autotools delegates.

im_ios_cmake_sysroot_and_arch() {
	local tok="${1:-$BUILDINGFOR}"
	case "$tok" in
		armv7|armv7s|arm64)
			_IM_CMAKE_SYSROOT="${IOSSDKROOT}"
			_IM_CMAKE_ARCH="$tok"
			;;
		arm64-sim)
			_IM_CMAKE_SYSROOT="${SIMSDKROOT}"
			_IM_CMAKE_ARCH="arm64"
			;;
		i386|x86_64)
			_IM_CMAKE_SYSROOT="${SIMSDKROOT}"
			_IM_CMAKE_ARCH="$tok"
			;;
		mac-arm64)
			_IM_CMAKE_SYSROOT="${MACSDKROOT}"
			_IM_CMAKE_ARCH="arm64"
			;;
		mac-x86_64)
			_IM_CMAKE_SYSROOT="${MACSDKROOT}"
			_IM_CMAKE_ARCH="x86_64"
			;;
		*)
			_IM_CMAKE_SYSROOT="${IOSSDKROOT}"
			_IM_CMAKE_ARCH="${tok}"
			;;
	esac
	export _IM_CMAKE_SYSROOT _IM_CMAKE_ARCH
}

# Sets _IM_CMAKE_OPTS array — expand as "${_IM_CMAKE_OPTS[@]}" in cmake invocations.
im_ios_delegate_cmake_base() {
	local tok="${1:-$BUILDINGFOR}"
	im_ios_cmake_sysroot_and_arch "$tok"
	local dep="${SDKMINVER}"
	if [[ "$tok" == mac-* ]]; then
		dep="${MACOS_MIN_VER:-11.0}"
	fi
	_IM_CMAKE_OPTS=(
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_OSX_SYSROOT="${_IM_CMAKE_SYSROOT}"
		-DCMAKE_OSX_ARCHITECTURES="${_IM_CMAKE_ARCH}"
		-DCMAKE_OSX_DEPLOYMENT_TARGET="${dep}"
		-DCMAKE_C_COMPILER="${CC:-$(xcrun -find clang)}"
	)
	if [ -n "${CXX:-}" ]; then
		_IM_CMAKE_OPTS+=(-DCMAKE_CXX_COMPILER="${CXX}")
	fi
	if [ -n "${CFLAGS:-}" ]; then
		_IM_CMAKE_OPTS+=(-DCMAKE_C_FLAGS="${CFLAGS}")
	fi
	if [ -n "${CXXFLAGS:-}" ]; then
		_IM_CMAKE_OPTS+=(-DCMAKE_CXX_FLAGS="${CXXFLAGS}")
	fi
}
