#!/usr/bin/env bash
# Bump delegates-manifest.sh defaults from Android-ImageMagick7/Android.mk *_LIB_PATH lines.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_MK="${1:-$SCRIPT_DIR/../../Android-ImageMagick7/Android.mk}"
MANIFEST="${2:-$SCRIPT_DIR/delegates-manifest.sh}"
if [[ ! -f "$ANDROID_MK" ]]; then
	echo "delegates-sync-from-android: missing $ANDROID_MK" >&2
	echo "Usage: $0 [/path/to/Android.mk] [delegates-manifest.sh]" >&2
	exit 1
fi
if [[ ! -f "$MANIFEST" ]]; then
	echo "delegates-sync-from-android: missing $MANIFEST" >&2
	exit 1
fi

python3 - "$ANDROID_MK" "$MANIFEST" <<'PY'
import re
import sys
from pathlib import Path

android, manifest = Path(sys.argv[1]), Path(sys.argv[2])
text = android.read_text(encoding="utf-8", errors="replace")
paths: dict[str, str] = {}
for m in re.finditer(
    r"^\s*([A-Z0-9_]+)_LIB_PATH\s*:=\s*\$\(LOCAL_PATH\)/(\S+)",
    text,
    re.MULTILINE,
):
    key, raw = m.group(1), m.group(2)
    raw = raw.split("#", 1)[0].strip()
    paths[key] = raw

vers: dict[str, str] = {}


def setv(dm: str, v: str) -> None:
    if v:
        vers[dm] = v


# Map Android.mk variable names → DM_* version keys (manifest export names).
if "JPEG" in paths:
    s = paths["JPEG"]
    if s.startswith("libjpeg-turbo-"):
        setv("DM_JPEGTURBO_VERSION", s.removeprefix("libjpeg-turbo-"))
if "PNG" in paths:
    s = paths["PNG"]
    if s.startswith("libpng-"):
        setv("DM_PNG_VERSION", s.removeprefix("libpng-"))
if "TIFF" in paths:
    s = paths["TIFF"].split("/")[0]
    m = re.search(r"libtiff-v?([\d.]+)", s)
    if m:
        setv("DM_TIFF_VERSION", m.group(1))
if "OPENJPEG" in paths:
    s = paths["OPENJPEG"]
    if s.startswith("libopenjpeg-"):
        setv("DM_OPENJPEG_VERSION", s.removeprefix("libopenjpeg-"))
if "FFTW" in paths:
    s = paths["FFTW"]
    if s.startswith("libfftw-"):
        setv("DM_FFTW_VERSION", s.removeprefix("libfftw-"))
if "XML2" in paths:
    s = paths["XML2"]
    if s.startswith("libxml2-"):
        setv("DM_XML2_VERSION", s.removeprefix("libxml2-"))
if "ICONV" in paths:
    s = paths["ICONV"]
    if s.startswith("libiconv-"):
        setv("DM_ICONV_VERSION", s.removeprefix("libiconv-"))
if "LZMA" in paths:
    s = paths["LZMA"]
    if s.startswith("xz-"):
        setv("DM_XZ_VERSION", s.removeprefix("xz-"))
if "BZLIB" in paths:
    s = paths["BZLIB"]
    if s.startswith("bzip-"):
        setv("DM_BZIP2_VERSION", s.removeprefix("bzip-"))
if "LCMS" in paths:
    s = paths["LCMS"]
    if s.startswith("liblcms2-"):
        setv("DM_LCMS2_VERSION", s.removeprefix("liblcms2-"))
if "DE265" in paths:
    s = paths["DE265"]
    if s.startswith("libde265-"):
        setv("DM_DE265_VERSION", s.removeprefix("libde265-"))
if "HEIF" in paths:
    s = paths["HEIF"]
    if s.startswith("libheif-"):
        setv("DM_HEIF_VERSION", s.removeprefix("libheif-"))
if "WEBP" in paths:
    s = paths["WEBP"]
    if s.startswith("libwebp-"):
        setv("DM_WEBP_VERSION", s.removeprefix("libwebp-"))
if "FREETYPE" in paths:
    s = paths["FREETYPE"]
    if s.startswith("libfreetype2-"):
        setv("DM_FREETYPE_VERSION", s.removeprefix("libfreetype2-"))
if "ICU" in paths:
    s = paths["ICU"]
    m = re.search(r"libicu4c-(\d+)-(\d+)", s)
    if m:
        setv("DM_ICU_VERSION", f"{m.group(1)}_{m.group(2)}")

mt = manifest.read_text(encoding="utf-8")
for dm, val in sorted(vers.items()):
    esc = re.escape(dm)
    pat = r"^export " + esc + r'="\$\{' + esc + r":-([^}]*)\}\"\s*$"
    repl = f'export {dm}="${{{dm}:-{val}}}"'
    new_mt, n = re.subn(pat, repl, mt, count=1, flags=re.MULTILINE)
    if n != 1:
        print(f"delegates-sync-from-android: skip {dm}={val!r} (no single match)", file=sys.stderr)
    else:
        mt = new_mt
        print(f"updated {dm} -> {val}")

manifest.write_text(mt, encoding="utf-8")
PY
