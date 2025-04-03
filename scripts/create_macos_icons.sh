 #!/bin/bash

# 错误时退出
set -e

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
command -v convert >/dev/null 2>&1 || log_error "需要安装ImageMagick (brew install imagemagick)"

# 设置变量
SOURCE_ICON="Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png"
OUTPUT_DIR="Resources/Assets.xcassets/AppIcon.appiconset"
TEMP_DIR="/tmp/macos_icons"

# 创建临时目录
mkdir -p "$TEMP_DIR"

# 创建macOS风格的圆角图标函数
create_rounded_icon() {
    local input=$1
    local output=$2
    local size=$3
    
    log_info "生成 ${size}x${size} 圆角图标..."
    
    # 创建模板
    convert -size ${size}x${size} xc:none -fill white \
        -draw "roundrectangle 0,0,${size},${size},$(echo "$size/5"|bc -l),$(echo "$size/5"|bc -l)" \
        "$TEMP_DIR/mask_${size}.png"
    
    # 调整大小并应用模板
    convert "$input" -resize ${size}x${size} \
        "$TEMP_DIR/mask_${size}.png" -alpha Off \
        -compose CopyOpacity -composite "$output"
}

# 检查源图标
if [ ! -f "$SOURCE_ICON" ]; then
    if [ -f "Resources/Assets.xcassets/AppIcon.appiconset/logo.png" ]; then
        log_info "使用logo.png作为源图标..."
        SOURCE_ICON="Resources/Assets.xcassets/AppIcon.appiconset/logo.png"
    else
        log_error "源图标文件不存在: $SOURCE_ICON"
    fi
fi

# 生成不同尺寸的图标
log_info "开始生成macOS风格圆角图标..."

# 生成1024x1024图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_1024x1024.png" 1024

# 生成512x512图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_512x512.png" 512

# 生成256x256图标  
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_256x256.png" 256

# 生成128x128图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_128x128.png" 128

# 生成64x64图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_64x64.png" 64

# 生成32x32图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_32x32.png" 32

# 生成16x16图标
create_rounded_icon "$SOURCE_ICON" "$OUTPUT_DIR/icon_16x16.png" 16

# 清理临时文件
rm -rf "$TEMP_DIR"

log_info "macOS风格圆角图标生成完成"
log_info "请运行 scripts/package.sh 重新打包应用"