#!/bin/sh
set -eu

FONT_DIR="${SRCROOT}/RavanGo/Resources/Fonts"
DEST_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

mkdir -p "$DEST_DIR"

for name in   IRANYekanXFaNum-Regular.ttf   IRANYekanXFaNum-Medium.ttf   IRANYekanXFaNum-DemiBold.ttf   IRANYekanXFaNum-Bold.ttf
do
  if [ -f "$FONT_DIR/$name" ]; then
    cp -f "$FONT_DIR/$name" "$DEST_DIR/$name"
  fi
done

if [ -f "$FONT_DIR/FontLicense.txt" ]; then
  cp -f "$FONT_DIR/FontLicense.txt" "$DEST_DIR/FontLicense.txt"
fi
