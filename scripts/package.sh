#!/bin/bash

# 错误时退出
set -e

# 生成唯一标识符（时间戳+随机字符串）
TIMESTAMP=$(date +%Y%m%d%H%M%S)
RANDOM_STRING=$(openssl rand -hex 4)
BUILD_ID="${TIMESTAMP}-${RANDOM_STRING}"

# 设置变量
APP_NAME="Clipboard History.app"
DMG_NAME="ClipboardHistory-${BUILD_ID}.dmg"
BUILD_DIR="build-${BUILD_ID}"
CONTENTS_DIR="$BUILD_DIR/$APP_NAME/Contents"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MACOS_DIR="$CONTENTS_DIR/MacOS"
VERSION="1.0.0"
STAGING_DIR="$BUILD_DIR/staging"

# 输出颜色设置
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 辅助函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检查必要工具
command -v swift >/dev/null 2>&1 || log_error "需要安装 Swift"
command -v hdiutil >/dev/null 2>&1 || log_error "需要 hdiutil"
command -v iconutil >/dev/null 2>&1 || log_error "需要 iconutil"

# 清理旧的构建
log_info "清理旧的构建文件..."
rm -rf "$BUILD_DIR"

# 构建项目
log_info "开始构建项目..."
if ! swift build -c release; then
    log_error "构建失败"
fi

# 创建应用程序包结构
log_info "创建应用程序包结构..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$STAGING_DIR"

# 复制二进制文件
log_info "复制二进制文件..."
cp .build/release/ClipboardHistoryApp "$MACOS_DIR/"

# 处理应用图标
log_info "处理应用图标..."
# 创建临时iconset目录
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

# 复制图标文件到iconset目录
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# 生成icns文件
if ! iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"; then
    log_error "生成icns文件失败"
fi

# 复制资源文件
log_info "复制资源文件..."
if [ -d "Resources" ]; then
    cp -R Resources/* "$RESOURCES_DIR/"
fi

# 创建 Info.plist
log_info "创建 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.clipboardhistory.${BUILD_ID}</string>
    <key>CFBundleName</key>
    <string>Clipboard History</string>
    <key>CFBundleExecutable</key>
    <string>ClipboardHistoryApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_ID}</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSPasteboardUsageDescription</key>
    <string>This app requires access to the clipboard to monitor and manage clipboard history.</string>
</dict>
</plist>
EOF

# 设置权限
log_info "设置权限..."
chmod +x "$MACOS_DIR/ClipboardHistoryApp"

# 准备DMG安装界面
log_info "准备DMG安装界面..."
# 创建临时staging目录用于DMG制作
cp -R "$BUILD_DIR/$APP_NAME" "$STAGING_DIR"
# 创建Applications文件夹的链接
ln -s /Applications "$STAGING_DIR/Applications"

# 创建 DMG
log_info "创建 DMG..."
if ! hdiutil create -volname "Clipboard History" \
                    -srcfolder "$STAGING_DIR" \
                    -ov -format UDZO \
                    "$BUILD_DIR/$DMG_NAME"; then
    log_error "创建 DMG 失败"
fi

# 完成
log_info "打包完成！"
log_info "构建 ID: ${BUILD_ID}"
log_info "DMG 文件位于: $BUILD_DIR/$DMG_NAME"

# 清理旧的构建（可选，保留最近3个版本）
find . -name "build-*" -type d | sort -r | tail -n +4 | xargs rm -rf
find . -name "ClipboardHistory-*.dmg" -type f | sort -r | tail -n +4 | xargs rm -f