#!/bin/bash

# 设置变量
APP_NAME="Clipboard History.app"
DMG_NAME="ClipboardHistory.dmg"
BUILD_DIR="build"
CONTENTS_DIR="$BUILD_DIR/$APP_NAME/Contents"

# 清理旧的构建
rm -rf "$BUILD_DIR"

# 构建项目
swift build -c release

# 创建应用程序包结构
mkdir -p "$CONTENTS_DIR"/{MacOS,Resources}

# 复制二进制文件
cp .build/release/ClipboardHistoryApp "$CONTENTS_DIR/MacOS/"

# 创建基础的 Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.clipboardhistory</string>
    <key>CFBundleName</key>
    <string>Clipboard History</string>
    <key>CFBundleExecutable</key>
    <string>ClipboardHistoryApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 创建简单的 DMG
hdiutil create -volname "Clipboard History" -srcfolder "$BUILD_DIR/$APP_NAME" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

echo "打包完成！DMG 文件位于: $BUILD_DIR/$DMG_NAME"