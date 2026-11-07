#!/bin/bash

# Project file and scheme both carry the "!" — copy these from xcodebuild -list output.
PROJECT="Steve's Talking Clock - for the Mac!.xcodeproj"
SCHEME="Steve's Talking Clock - for the Mac!"

# The built .app is named after the TARGET, not the project. From `xcodebuild -list`,
# the target is "Steve's Talking Clock" — so the product is "Steve's Talking Clock.app".
APP_NAME="Steve's Talking Clock"
INSTALL_PATH="/Applications/${APP_NAME}.app"
DERIVED="./build"
BUILD_PATH="${DERIVED}/Build/Products/Release/${APP_NAME}.app"

set -e   # stop on first error

echo "Building Release version..."
xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${DERIVED}" \
    build

if [ ! -d "${BUILD_PATH}" ]; then
    echo "Error: Build succeeded but app not found at '${BUILD_PATH}'."
    echo "Contents of Release folder:"
    ls -la "${DERIVED}/Build/Products/Release/" 2>/dev/null
    exit 1
fi

echo "Quitting old version..."
osascript -e "tell application \"${APP_NAME}\" to quit" 2>/dev/null || true
sleep 1

echo "Installing to /Applications..."
rm -rf "${INSTALL_PATH}"
cp -R "${BUILD_PATH}" "${INSTALL_PATH}"

echo "Installation complete. Launching app..."
open "${INSTALL_PATH}"
