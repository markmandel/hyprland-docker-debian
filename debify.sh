#!/usr/bin/env bash

# Copyright 2025 Mark Mandel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

# debify.sh <package_name> <version> <manifest_file> [dep1 [dep2 ...]]
# Creates a .deb from a list of installed files. Optional dependencies can be provided
# as additional arguments. For versioned dependencies with spaces (e.g. "hyprutils (>= 0.8.2)"),
# quote the whole dependency argument when calling this script.

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <package_name> <version> <manifest_file> [dep1 [dep2 ...]]" >&2
  exit 1
fi

NAME="$1"
VERSION_RAW="$2"
MANIFEST="$3"

# Optional dependencies from 4th+ args
DEPS=( )
if [[ $# -gt 3 ]]; then
  # shellcheck disable=SC2206
  DEPS=("${@:4}")
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "Manifest file not found: $MANIFEST" >&2
  exit 1
fi

# Normalize version: strip a leading 'v' if present
VERSION="${VERSION_RAW#v}"

# Create staging directory
WORKDIR="$(mktemp -d)"
PKGROOT="$WORKDIR/pkgroot"
mkdir -p "$PKGROOT"

# Copy files listed in manifest preserving paths. Many manifests contain absolute paths.
# Use tar to stream files and extract into the staging root to avoid requiring extra tools.
# Filter out empty lines just in case.
TMPLIST="$WORKDIR/manifest.txt"
grep -v '^[[:space:]]*$' "$MANIFEST" > "$TMPLIST"

if [[ ! -s "$TMPLIST" ]]; then
  echo "Manifest appears empty: $MANIFEST" >&2
  exit 1
fi

# Create archive from absolute paths and extract into package root
# -P preserves absolute paths when creating archive
# We remove the leading / when extracting by using --transform; however GNU tar transform can be complex across OS.
# Simpler: extract with -P to absolute locations but change directory to a fake root via --one-top-level is not available for -x with -P.
# Instead, we stream and then extract with --absolute-names disabled but using sed to strip leading /. We'll preprocess list to strip leading / for extraction base.
STRIPPED_LIST="$WORKDIR/manifest_stripped.txt"
sed 's#^/##' "$TMPLIST" > "$STRIPPED_LIST"

# Create a tar stream from real filesystem and extract under PKGROOT
# We must feed tar with absolute paths to read, but extract under PKGROOT keeping the same structure.
# We'll create the tar with absolute paths (-P) then extract ignoring the leading / by using --strip-components=0 is ineffective for absolute paths.
# Alternative approach: use rsync if available; fall back to tar trick.
if command -v rsync >/dev/null 2>&1; then
  rsync -a --files-from="$TMPLIST" / "$PKGROOT"
else
  # tar-based fallback: copy files one by one to preserve symlinks and perms
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    src="$f"
    # Ensure directory exists in pkgroot
    rel="${src#/}"
    dstdir="$PKGROOT/$(dirname "$rel")"
    mkdir -p "$dstdir"
    # Copy file or link preserving attributes
    if [[ -L "$src" ]]; then
      # replicate symlink
      target="$(readlink "$src")"
      ln -sfn "$target" "$PKGROOT/$rel"
    elif [[ -d "$src" ]]; then
      mkdir -p "$PKGROOT/$rel"
    else
      install -Dm644 /dev/null "$PKGROOT/$rel" >/dev/null 2>&1 || true
      cp -a --no-preserve=ownership "$src" "$PKGROOT/$rel"
    fi
  done < "$TMPLIST"
fi

# Create minimal control metadata
DEBIAN_DIR="$PKGROOT/DEBIAN"
mkdir -p "$DEBIAN_DIR"
ARCH="amd64"
{
  echo "Package: $NAME"
  echo "Version: $VERSION"
  echo "Architecture: $ARCH"
  echo "Maintainer: Mark Mandel <mark.mandel@gmail.com>"
  echo "Section: utils"
  echo "Priority: optional"
  if [[ ${#DEPS[@]} -gt 0 ]]; then
    # Join deps by ", "
    dep_line="${DEPS[0]}"
    for ((i=1; i<${#DEPS[@]}; i++)); do
      dep_line=", $dep_line" # prepend to preserve any commas inside items (not needed, but safe)
      dep_line="${DEPS[i]}$dep_line"
    done
    # Simpler join approach
    dep_line="$(IFS=,; echo "${DEPS[*]}")"
    # Replace commas with ", " spacing for readability if caller did not include spaces
    dep_line="${dep_line//,/\, }"
    echo "Depends: $dep_line"
  fi
  echo "Description: $NAME built from source via hyprland-docker-debian"
  echo " This package was auto-generated from installed files."
} > "$DEBIAN_DIR/control"

# Build the deb
OUTDIR="/opt/hyprland/archives"
mkdir -p "$OUTDIR"
OUTPUT="$OUTDIR/${NAME}_${VERSION}_${ARCH}.deb"

dpkg-deb --build "$PKGROOT" "$OUTPUT"

echo "Built: $OUTPUT"
