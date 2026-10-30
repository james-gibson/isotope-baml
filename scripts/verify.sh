#!/usr/bin/env bash
# Check that a consumer's vendored copies still match the pins.
#
# A hash proves the file did not change. It does not prove the two sides still
# mean the same thing — that is the behavioural check in the consumer's
# crosscheck (Go reference vs this lattice). Both are needed: a faithful copy of
# a wrong port hashes correctly.
set -euo pipefail

TARGET="${1:?usage: verify.sh <consumer-dir>}"
MANIFEST="$TARGET/LATTICE_VENDORED"
[ -f "$MANIFEST" ] || { echo "no $MANIFEST: nothing vendored" >&2; exit 2; }

fail=0
while read -r want name; do
  case "$want" in \#*|"") continue ;; esac
  path="$TARGET/baml_src/$name"
  if [ ! -f "$path" ]; then
    echo "MISSING  $name" >&2; fail=1; continue
  fi
  got="$(shasum -a 256 "$path" | cut -d' ' -f1)"
  if [ "$got" = "$want" ]; then
    echo "ok       $name"
  else
    echo "DRIFTED  $name" >&2; fail=1
  fi
done < "$MANIFEST"

[ "$fail" -eq 0 ] && echo "vendored lattice matches its pins" || echo "vendored lattice has drifted" >&2
exit "$fail"
