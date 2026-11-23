#!/bin/sh
# Host IDE runner for pano.com under tnylpo.
# Supports .z80 / .asm (via z80asm.com) and .pas (via pasta80 --cpm).
# Usage: ./mcp_cpm.sh [filename]

SRC="${1:-}"
PASTA80="${PASTA80:-pasta80}"
TNYLPO="${TNYLPO:-tnylpo}"

format_z80asm_err() {
  src_name="$1"
  awk -v src="$src_name" '
    { gsub(/\r/, "") }
    match($0, / - .* Line [0-9]+$/) {
      line_idx = match($0, / Line [0-9]+$/)
      if (line_idx > 0) {
        sep = index($0, " - ")
        msg = substr($0, sep + 3, line_idx - sep - 3)
        lnum = substr($0, line_idx + 6) + 0
        printf "*** Error at %s(%d,1): %s\n", src, lnum, msg
        found = 1
        exit 0
      }
    }
    END {
      if (!found) exit 1
    }
  '
}

while :; do
  "$TNYLPO" -s pano.com "$SRC"

  [ -f PANO.TMP ] || break

  ACT=$(sed -n '1p' PANO.TMP | tr -d '\r\032')
  SRC=$(sed -n '2p' PANO.TMP | tr -d '\r\032')
  OUTBIN=$(sed -n '3p' PANO.TMP | tr -d '\r\032')
  ROWS=$(sed -n '4p' PANO.TMP | tr -d '\r\032')
  COLS=$(sed -n '5p' PANO.TMP | tr -d '\r\032')

  [ -n "$SRC" ] || break

  rm -f "$OUTBIN" PANO.ERR
  echo "Building $SRC -> $OUTBIN..."

  EXT=$(printf '%s' "$SRC" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
  STEM=$(printf '%s' "$SRC" | sed 's/\.[^.]*$//')
  BUILD_OK=0

  if [ "$EXT" = "pas" ]; then
    if "$PASTA80" --cpm "$SRC" > PANO.ERR 2>&1 && [ -f "$OUTBIN" ]; then
      BUILD_OK=1
    fi
  else
    TMP_Z80=""
    if [ "$EXT" != "z80" ] && [ ! -e "${STEM}.z80" ]; then
      cp "$SRC" "${STEM}.z80"
      TMP_Z80="${STEM}.z80"
    fi
    RAW_LOG=$(mktemp /tmp/z80asm.XXXXXX)
    "$TNYLPO" z80asm.com "${STEM}/f" > "$RAW_LOG" 2>&1 || true
    cat "$RAW_LOG"
    [ -n "$TMP_Z80" ] && rm -f "$TMP_Z80"
    if grep -q '0 Error(s) Detected\.' "$RAW_LOG" && [ -f "$OUTBIN" ]; then
      BUILD_OK=1
    else
      rm -f "$OUTBIN"
      if ! format_z80asm_err "$SRC" < "$RAW_LOG" > PANO.ERR; then
        printf '*** Error: Assembly failed\n' > PANO.ERR
      fi
    fi
    rm -f "$RAW_LOG"
  fi

  if [ "$BUILD_OK" -eq 1 ]; then
    printf 'OK\r\n%s\r\n%s\r\n%s\r\n%s\r\n' "$SRC" "$OUTBIN" "$ROWS" "$COLS" > PANO.TMP
    if [ "$ACT" = "R" ]; then
      echo
      echo "Running $OUTBIN..."
      "$TNYLPO" "$OUTBIN"
      printf '\nPress Enter to return to pano...'
      read -r _unused
    fi
  else
    printf 'ERR\r\n%s\r\n%s\r\n%s\r\n%s\r\n' "$SRC" "$OUTBIN" "$ROWS" "$COLS" > PANO.TMP
  fi
done
