#!/usr/bin/env bash
# Vendor the lattice into a consumer project and pin exactly what was copied.
#
# BAML has no package imports yet ([dependencies] is unsupported), so a shared
# lattice is copied, not depended on. The pin is what makes the copy auditable:
# a consumer can prove which commit its .baml files came from, and a hash of
# each file proves they have not been edited in place.
#
#   ./scripts/vendor.sh /path/to/consumer      # copy into consumer/baml_src/
#   ./scripts/verify.sh /path/to/consumer      # non-zero if a copy drifted
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:?usage: vendor.sh <consumer-dir>}"
DEST="$TARGET/baml_src"
mkdir -p "$DEST"

COMMIT="$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo uncommitted)"
MANIFEST="$TARGET/LATTICE_VENDORED"
: > "$MANIFEST"
echo "# vendored from isotope-baml @ $COMMIT on $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$MANIFEST"

for f in "$HERE"/baml_src/*.baml; do
  name="$(basename "$f")"
  cp "$f" "$DEST/$name"
  printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d' ' -f1)" "$name" >> "$MANIFEST"
done

echo "vendored $(grep -c '\.baml$' "$MANIFEST") file(s) from $COMMIT into $DEST"
