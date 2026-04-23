#!/usr/bin/env bash
# Download delegate sources into build/ImageMagick-<ver>/IMDelegates (CI + local).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/delegates-manifest.sh"
IM_VERSION="${1:?Usage: ensure-delegate-sources.sh IM_VERSION (e.g. 7.1.0-2)}"
DELEGATES_DIR="$IMROOT/build/ImageMagick-$IM_VERSION/IMDelegates"
mkdir -p "$DELEGATES_DIR"
cd "$DELEGATES_DIR"

FORCE="${FORCE_DELEGATE_FETCH:-0}"

fetch_tgz() {
  local url="$1" dest="$2"
  if [[ -d "$dest" && "$FORCE" != "1" ]]; then
    echo "[ensure] $dest already present"
    return 0
  fi
  [[ "$FORCE" == "1" && -d "$dest" ]] && rm -rf "$dest"
  echo "[ensure] fetching $(basename "$url")"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$url" -o "$tmp"
  tar -xzf "$tmp"
  rm -f "$tmp"
}

fetch_txz() {
  local url="$1" dest="$2"
  if [[ -d "$dest" && "$FORCE" != "1" ]]; then
    echo "[ensure] $dest already present"
    return 0
  fi
  [[ "$FORCE" == "1" && -d "$dest" ]] && rm -rf "$dest"
  echo "[ensure] fetching $(basename "$url")"
  local tmp
  tmp="$(mktemp)"
  curl -fsSL "$url" -o "$tmp"
  tar -xJf "$tmp"
  rm -f "$tmp"
}

fetch_txz "$DM_XZ_URL" "$DM_XZ_DIR"
fetch_tgz "$DM_BZIP2_URL" "$DM_BZIP2_DIR"
fetch_tgz "$DM_LCMS2_URL" "$DM_LCMS2_DIR"
fetch_tgz "$DM_OPENJPEG_URL" "$DM_OPENJPEG_DIR"
fetch_txz "$DM_PNG_URL" "$DM_PNG_DIR"
fetch_tgz "$DM_TIFF_URL" "$DM_TIFF_DIR"
fetch_tgz "$DM_WEBP_URL" "$DM_WEBP_DIR"
fetch_txz "$DM_FREETYPE_URL" "$DM_FREETYPE_DIR"
fetch_tgz "$DM_ZLIB_URL" "$DM_ZLIB_DIR"
fetch_tgz "$DM_ICONV_URL" "$DM_ICONV_DIR"
if [[ -d icu/source && "$FORCE" != "1" ]]; then
	echo "[ensure] icu/ already present"
else
	[[ "$FORCE" == "1" && -d icu ]] && rm -rf icu
	echo "[ensure] fetching ICU $(basename "$DM_ICU_URL")"
	tmp_icu="$(mktemp)"
	curl -fsSL "$DM_ICU_URL" -o "$tmp_icu"
	tar -xzf "$tmp_icu"
	rm -f "$tmp_icu"
fi
fetch_txz "$DM_XML2_URL" "$DM_XML2_DIR"
fetch_tgz "$DM_FFTW_URL" "$DM_FFTW_DIR"
fetch_tgz "$DM_JPEGTURBO_URL" "$DM_JPEGTURBO_DIR"
fetch_tgz "$DM_DE265_URL" "$DM_DE265_DIR"
fetch_tgz "$DM_AOM_URL" "$DM_AOM_DIR"
fetch_tgz "$DM_HEIF_URL" "$DM_HEIF_DIR"

echo "[ensure] IMDelegates ready under $DELEGATES_DIR"
