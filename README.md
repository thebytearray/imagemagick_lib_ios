# imagemagick_lib_ios

ImageMagick build scripts for iOS / macOS (static libs and `IMAll.xcframework`).

Thanks to [marforic](https://github.com/marforic/imagemagick_lib_iphone) for the original iPhone scripts. This repo extends and adapts them for current toolchains and delegates.

**Repository:** [https://github.com/thebytearray/imagemagick_lib_ios](https://github.com/thebytearray/imagemagick_lib_ios)

Delegate versions are aligned with **Android-ImageMagick7** (`Android.mk` + `scripts/delegates-sync-from-android.sh`). That includes **ICU4C** (for libxml2 with ICU, matching Android), **jpeg-turbo**, **FFTW**, **libheif** stack, etc. Set **`ENABLE_ICU=0`** before `env.sh` if you want a faster build without ICU (then libxml2 is built `--without-icu`). **OpenCL** (Qualcomm) and **libltdl** from the Android tree are not ported—iOS builds keep OpenCL off and use a static module layout.

## Architectures

Typical targets: `arm64`, `armv7`, `x86_64` (and simulator / macOS variants as configured in `env.sh` / `all.sh`).

For **App Store device + Apple Silicon simulator** builds, use `ARCHS="arm64 arm64-sim"` (see `env.sh`). **Intel iOS simulator** (`x86_64`) is supported via `intelflags` / `iphonesimulator` SDK in the delegate scripts; include `x86_64` in `ARCHS` only if you still ship an x86_64 simulator slice.

## Delegates (iOS)

CMake-based delegates (`openjpeg`, **libjpeg-turbo**, `libde265`, `libaom`, `libheif`) share `scripts/ios_delegate_cmake.sh` for `CMAKE_OSX_SYSROOT`, architecture, and deployment target so **iphoneos** vs **iphonesimulator** matches `flags.sh`. Static archives are preferred (`BUILD_SHARED_LIBS=OFF` / jpeg-turbo `ENABLE_STATIC=ON`) for typical iOS app linking.

| Toggle | Default | Notes |
|--------|---------|--------|
| `ENABLE_HEIF` | `1` | HEIF stack (de265, aom, libheif); adds **`-lc++`** at link. Set `0` to drop HEIF. |
| `ENABLE_ICU` | `1` | ICU4C + libxml2 `--with-icu` (Android parity). **Host ICU build requires macOS** (`runConfigureICU MacOSX`). Set `ENABLE_ICU=0` before `env.sh` for faster builds or non-mac hosts; libxml2 is then built `--without-icu`. |
| `USE_JPEG_TURBO` | `1` | Builds libjpeg-turbo via CMake when `1`; omit or set `0` to use the classic libjpeg delegate path in `all.sh`. |

## Build output

After a successful run, see the **`IMPORT_ME`** folder for headers and libraries / xcframework pieces used by the Swift wrapper repo ([im-swift](https://github.com/thebytearray/im-swift)).

Example ImageMagick build info (older reference build):

```
Version: ImageMagick 7.1.0-3 Q8 arm 2021-06-25 https://imagemagick.org
Copyright: (C) 1999-2021 ImageMagick Studio LLC
License: https://imagemagick.org/script/license.php
Features: Cipher DPC HDRI 
Delegates (built-in): fontconfig freetype jng jpeg png xml zlib
```

## Troubleshooting

If you see linker errors like:

```
ld: warning: ignoring file /usr/local/Cellar/openexr/... dylib, building for iOS-arm64 but attempting to link with file built for macOS-x86_64
...
Undefined symbols for architecture arm64:
"_FcConfigDestroy", ...
"_png_write_info", ...
```

then Homebrew (or other) **macOS** libraries are being picked up instead of the iOS-built delegates.

**Fix:**

- Remove conflicting Homebrew packages, for example:

```
brew uninstall --ignore-dependencies webp
```

- Or adjust `CPPFLAGS` / `LDFLAGS` so only the delegates built by this project are used, then **rebuild** the libraries.
