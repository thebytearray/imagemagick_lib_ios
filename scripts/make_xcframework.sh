#!/usr/bin/env bash
set -euo pipefail

SRC_DIR=${1:-$(pwd)}
OUT_DIR=${2:-$(pwd)}
HEADERS_DIR=${3:-"$SRC_DIR/include"}
# platforms to include: ios or ios+mac
PACK_PLATFORMS=${4:-ios}
# include Intel iOS Simulator x86_64: 1 to include, 0 to exclude
INCLUDE_X86_SIM=${5:-0}

mkdir -p "$OUT_DIR/tmp_device" "$OUT_DIR/tmp_sim"

ALL_LIBS=()
while IFS= read -r -d '' f; do
  ALL_LIBS+=("$f")
done < <(find "$SRC_DIR" -maxdepth 1 -name "lib*.a" -print0)

SIM_LIBS=()
DEV_LIBS=()
MAC_LIBS=()
for f in "${ALL_LIBS[@]}"; do
  bn=$(basename "$f")
  if [[ "$bn" == *_sim.a ]]; then
    SIM_LIBS+=("$f")
    continue
  fi
  if [[ "$bn" == *_x86.a ]]; then
    if [[ "$INCLUDE_X86_SIM" == 1 ]]; then
      SIM_LIBS+=("$f")
    else
      MAC_LIBS+=("$f")
    fi
    continue
  fi
  info=$(lipo -info "$f" || true)
  echo "$info" | grep -E -q "arm64|armv7s|armv7" && DEV_LIBS+=("$f") || true
  echo "$info" | grep -q "x86_64" && MAC_LIBS+=("$f") || true
done

has_token() {
  local s="$1"
  local t="$2"
  for x in $s; do
    [[ "$x" == "$t" ]] && return 0
  done
  return 1
}

extract_and_merge() {
  local group=$1
  shift
  local -a libs=("$@")
  local archs=""
  for lib in "${libs[@]}"; do
    if [[ -f "$lib" ]]; then
      info=$(lipo -info "$lib" || true)
      echo "$info" | grep -q "arm64" && { has_token "$archs" arm64 || archs="$archs arm64"; } || true
      echo "$info" | grep -q "x86_64" && { has_token "$archs" x86_64 || archs="$archs x86_64"; } || true
      echo "$info" | grep -q "armv7s" && { has_token "$archs" armv7s || archs="$archs armv7s"; } || true
      echo "$info" | grep -q "armv7" && { has_token "$archs" armv7 || archs="$archs armv7"; } || true
    fi
  done
  local tmpdir="$OUT_DIR/tmp_${group}"
  mkdir -p "$tmpdir"
  rm -f "$OUT_DIR/tmp_${group}_list.txt" || true
  for arch in $archs; do
    local slices=()
    local archtmp="$tmpdir/$arch"
    mkdir -p "$archtmp"
    for lib in "${libs[@]}"; do
      if [[ -f "$lib" ]] && lipo -info "$lib" | grep -q "$arch"; then
        local name
        name=$(basename "$lib")
        if lipo -info "$lib" | grep -q "Non-fat file"; then
          cp "$lib" "$archtmp/$name"
        else
          lipo -extract "$arch" "$lib" -output "$archtmp/$name"
        fi
        slices+=("$archtmp/$name")
      fi
    done
    if [[ ${#slices[@]} -gt 0 ]]; then
      local merged="$OUT_DIR/IMAll_${group}_${arch}.a"
      libtool -static -o "$merged" "${slices[@]}"
      echo "$merged" >> "$OUT_DIR/tmp_${group}_list.txt"
    fi
  done
}

args=()
# merge per-arch into single libraries to avoid duplicate platform identifiers
extract_and_merge device "${DEV_LIBS[@]}"
extract_and_merge sim "${SIM_LIBS[@]}"
if [[ "$PACK_PLATFORMS" == ios+mac ]]; then
  extract_and_merge mac "${MAC_LIBS[@]}"
fi

# collect merged outputs
# reset arg list
args=()
if [[ -f "$OUT_DIR/tmp_device_list.txt" ]]; then
  while IFS= read -r lib; do
    [[ -f "$lib" ]] && args+=( -library "$lib" -headers "$HEADERS_DIR" )
  done < "$OUT_DIR/tmp_device_list.txt"
fi
if [[ -f "$OUT_DIR/tmp_sim_list.txt" ]]; then
  while IFS= read -r lib; do
    [[ -f "$lib" ]] && args+=( -library "$lib" -headers "$HEADERS_DIR" )
  done < "$OUT_DIR/tmp_sim_list.txt"
fi
if [[ "$PACK_PLATFORMS" == ios+mac && -f "$OUT_DIR/tmp_mac_list.txt" ]]; then
  while IFS= read -r lib; do
    [[ -f "$lib" ]] && args+=( -library "$lib" -headers "$HEADERS_DIR" )
  done < "$OUT_DIR/tmp_mac_list.txt"
fi

if [[ ${#args[@]} -eq 0 ]]; then
  echo "no libraries to package"
  exit 1
fi

# cleanup previous output to avoid conflicts
rm -rf "$OUT_DIR/IMAll.xcframework" || true
xcodebuild -create-xcframework "${args[@]}" -output "$OUT_DIR/IMAll.xcframework"
echo "IMAll.xcframework generated at $OUT_DIR/IMAll.xcframework"
