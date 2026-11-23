#!/bin/sh
set -eu

URL="https://deramp.com/downloads/mfe_archive/040-Software/SLR%20Systems/Z80ASM/Z80ASM.COM"
OUT="${1:-z80asm.com}"

curl -fsSL "$URL" -o "$OUT"
echo "Downloaded $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
