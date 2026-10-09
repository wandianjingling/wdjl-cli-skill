#!/bin/bash

# 万店精灵 CLI Linux 安装脚本（AppImage 版）

set -euo pipefail

BASE_URL="https://res.wandianjingling.com/wdjlcli/Releases_linux-x64"
INDEX_BASE_URL="https://res2.wandianjingling.com/wdjlcli/Releases_linux-x64"
VERSION=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --base-url) BASE_URL="$2"; shift ;;
        --index-base-url) INDEX_BASE_URL="$2"; shift ;;
        --version) VERSION="$2"; shift ;;
        *) echo "[ERROR] 未知参数: $1"; exit 1 ;;
    esac
    shift
done

INSTALL_DIR="$HOME/.wdjlcli"
LOCAL_BIN_DIR="$HOME/.local/bin"
SYMLINK="$LOCAL_BIN_DIR/wdjlcli"
APP_IMAGE="$INSTALL_DIR/wdjlcli.AppImage"
VERSION_FILE="$INSTALL_DIR/.version"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

write_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
write_info()    { echo -e "${CYAN}[INFO] $1${NC}"; }
write_err()     { echo -e "${RED}[ERROR] $1${NC}"; }

cleanup() {
    if [ -f "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
}
TEMP_FILE=""
trap cleanup EXIT
trap 'write_err "安装脚本执行过程中发生异常退出 (行号: $LINENO)"' ERR

write_info "===== 万店精灵 CLI 安装程序 (AppImage 版) ====="

# FUSE 检测与自动安装：AppImage 传统上依赖 libfuse2
check_and_install_fuse() {
    write_info "检测 FUSE 挂载引擎..."
    if ldconfig -p 2>/dev/null | grep -q "libfuse.so.2"; then
        write_success "FUSE2 引擎已就绪。"
        return 0
    fi
    if command -v fusermount3 >/dev/null 2>&1 && ldconfig -p 2>/dev/null | grep -q "libfuse3.so.3"; then
        write_info "检测到 FUSE3。部分 AppImage 可能需要 libfuse2，如运行失败请手动安装 libfuse2。"
        return 0
    fi

    write_info "未检测到 libfuse2，正在根据发行版自动请求权限安装..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y && sudo apt-get install -y libfuse2
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fuse-libs
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y fuse-libs
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm fuse2
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y libfuse2
    else
        write_err "未知的 Linux 发行版，无法自动安装 FUSE2 引擎。请手动安装 libfuse2 或 fuse3 后重试。"
        exit 1
    fi
    write_success "FUSE2 引擎安装完毕！"
}
check_and_install_fuse

# 解析目标版本号（从 Velopack RELEASES-linux 获取最新版本，索引从新域名获取）
installed_version="$VERSION"
if [ -z "$installed_version" ]; then
    write_info "正在获取最新版本号..."
    releases_line=""
    if command -v curl >/dev/null 2>&1; then
        releases_line="$(curl -fsSL "${INDEX_BASE_URL}/RELEASES-linux" 2>/dev/null | grep -E '^[0-9a-fA-F]+[[:space:]]+wdjlcli-.+-full\.nupkg' | tail -1)"
    elif command -v wget >/dev/null 2>&1; then
        releases_line="$(wget -qO- "${INDEX_BASE_URL}/RELEASES-linux" 2>/dev/null | grep -E '^[0-9a-fA-F]+[[:space:]]+wdjlcli-.+-full\.nupkg' | tail -1)"
    fi
    nupkg_name="$(echo "$releases_line" | awk '{print $2}')"
    tmp="${nupkg_name#wdjlcli-}"
    tmp="${tmp%-full.nupkg}"
    tmp="${tmp%-linux}"
    tmp="${tmp%-osx}"
    tmp="${tmp%-win}"
    if [ -n "$tmp" ]; then
        installed_version="$tmp"
    else
        write_err "无法从 RELEASES-linux 索引解析最新版本号，请检查网络或索引文件是否可用。"
        exit 1
    fi
    write_info "最新版本: $installed_version"
fi

# 候选安装包（按优先级）：带版本号的 AppImage
# CDN 缓存按文件名隔离，版本号命名不受固定名缓存影响；
# 不再回退到固定名 AppImage（固定名会被 CDN 边缘节点长期缓存，容易装到旧版本）
candidates=(
    "wdjlcli-${installed_version}-linux.AppImage"
    "wdjlcli-${installed_version}.AppImage"
)

# 下载文件
write_info "正在下载安装包..."
TEMP_FILE="$(mktemp /tmp/wdjlcli-XXXXXX.AppImage)"
downloaded=false
for cand in "${candidates[@]}"; do
    for base in "$INDEX_BASE_URL" "$BASE_URL"; do
        DOWNLOAD_URL="${base}/${cand}"
        write_info "下载地址: $DOWNLOAD_URL"
        if command -v curl >/dev/null 2>&1; then
            curl -f -sSL "$DOWNLOAD_URL" -o "$TEMP_FILE" || continue
        elif command -v wget >/dev/null 2>&1; then
            wget -q "$DOWNLOAD_URL" -O "$TEMP_FILE" || continue
        else
            write_err "未找到 curl 或 wget，无法下载。"
            exit 1
        fi
        if [ -s "$TEMP_FILE" ]; then
            downloaded=true
            break
        fi
    done
    if [ "$downloaded" = true ]; then
        break
    fi
done

if [ "$downloaded" != true ]; then
    write_err "下载失败：所有候选地址均不可用，请检查网络或远程文件是否存在。"
    exit 1
fi

# 清理与创建目录
if [ -d "$INSTALL_DIR" ]; then
    write_info "清理旧版本..."
    rm -rf "${INSTALL_DIR:?}"/*
else
    mkdir -p "$INSTALL_DIR"
fi
mkdir -p "$LOCAL_BIN_DIR"

# 部署 AppImage
write_info "正在部署 CLI..."
chmod +x "$TEMP_FILE"
mv "$TEMP_FILE" "$APP_IMAGE"

# 创建/更新符号链接
ln -sf "$APP_IMAGE" "$SYMLINK"
write_info "已创建符号链接: $SYMLINK"

# 注入环境变量 (PATH)
SHELL_RC_FILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC_FILE="$HOME/.bashrc"
else
    SHELL_RC_FILE="$HOME/.profile"
fi

if ! grep -q "$LOCAL_BIN_DIR" "$SHELL_RC_FILE" 2>/dev/null; then
    echo -e "\n# wdjlcli PATH\nexport PATH=\"\$PATH:$LOCAL_BIN_DIR\"" >> "$SHELL_RC_FILE"
    write_info "已将 $LOCAL_BIN_DIR 注册到 $SHELL_RC_FILE"
    write_info "请执行 'source $SHELL_RC_FILE' 或重启终端以生效。"
else
    write_info "PATH 中已包含 $LOCAL_BIN_DIR"
fi

# 写入版本号
echo -n "$installed_version" > "$VERSION_FILE"

write_success "部署完成！运行 'wdjlcli --help' 查看用法。"
