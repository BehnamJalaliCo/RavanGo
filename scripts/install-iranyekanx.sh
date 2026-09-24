#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: FONTIRAN_LICENSE_CODE=123456 sh scripts/install-iranyekanx.sh /path/to/IRANYekanX-Pro.zip" >&2
  exit 64
fi

ZIP_PATH="$1"
LICENSE_CODE="${FONTIRAN_LICENSE_CODE:-}"

case "$LICENSE_CODE" in
  [0-9][0-9][0-9][0-9][0-9][0-9]) ;;
  *)
    echo "FONTIRAN_LICENSE_CODE must be exactly six digits." >&2
    exit 65
    ;;
esac

if [ ! -f "$ZIP_PATH" ]; then
  echo "Font archive not found: $ZIP_PATH" >&2
  exit 66
fi

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DEST_DIR="$ROOT_DIR/RavanGo/Resources/Fonts"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

mkdir -p "$DEST_DIR"

for weight in Regular Medium DemiBold Bold; do
  name="IRANYekanXFaNum-${weight}.ttf"
  match="$(unzip -Z1 "$ZIP_PATH" | awk -v n="$name" '$0 ~ /Farsi numerals\// && $0 ~ n "$" { print; exit }')"
  if [ -z "$match" ]; then
    echo "Could not find $name in the supplied archive." >&2
    exit 67
  fi
  unzip -p "$ZIP_PATH" "$match" > "$DEST_DIR/$name"
done

license_entry="$(unzip -Z1 "$ZIP_PATH" | awk '$0 ~ /FontLicense\.txt$/ { print; exit }')"
if [ -z "$license_entry" ]; then
  echo "Could not find FontLicense.txt in the supplied archive." >&2
  exit 68
fi

unzip -p "$ZIP_PATH" "$license_entry" > "$TMP_DIR/FontLicense.txt"
python3 - "$TMP_DIR/FontLicense.txt" "$DEST_DIR/FontLicense.txt" "$LICENSE_CODE" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
code = sys.argv[3]
updated = source.replace("(.....)", f"({code})")
Path(sys.argv[2]).write_text(updated, encoding="utf-8")
PY

echo "Installed four licensed IRANYekanXFaNum fonts locally."
echo "Created RavanGo/Resources/Fonts/FontLicense.txt locally."
echo "These files are intentionally ignored by Git."
