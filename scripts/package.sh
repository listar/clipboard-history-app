#!/bin/bash

# Build the project
swift build -c release

# Create app bundle structure
APP_NAME="Clipboard History.app"
CONTENTS_DIR="build/$APP_NAME/Contents"
mkdir -p "$CONTENTS_DIR"/{MacOS,Resources}

# Copy binary
cp .build/release/ClipboardHistoryApp "$CONTENTS_DIR/MacOS/"

# Copy Info.plist and resources
cp Resources/Info.plist "$CONTENTS_DIR/"
cp -r Resources/Assets.xcassets "$CONTENTS_DIR/Resources/"

# Sign the app (需要开发者证书)
codesign --force --sign "Developer ID Application: Your Name" "build/$APP_NAME"

# Create DMG
create-dmg \
  --volname "Clipboard History" \
  --volicon "Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "$APP_NAME" 200 190 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 600 185 \
  "build/Clipboard History.dmg" \
  "build/$APP_NAME"