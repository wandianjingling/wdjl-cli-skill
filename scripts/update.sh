#!/usr/bin/env bash
# update.sh - 万店精灵 CLI Linux/macOS 更新脚本
# 用法: bash update.sh [--base-url <URL>] [--version <version>]
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${YELLOW}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }
error()   { echo -e "${RED}$*${NC}" >&2; }

BASE_URL="https://res.wandianjingling.com/wdjlcli/Releases_linux-x64"
INDEX_BASE_URL="https://res2.wandianjingling.com/wdjlcli/Releases_linux-x64"
VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url)
            BASE_URL="$2"
            shift 2
            ;;
        --index-base-url)
            INDEX_BASE_URL="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        *)
            error "未知参数: $1"
            exit 1
            ;;
    esac
done

INSTALL_DIR="$HOME/.wdjlcli"
BACKUP_DIR="$HOME/.wdjlcli.bak"
VERSION_FILE="$INSTALL_DIR/.version"
LOCAL_BIN_DIR="$HOME/.local/bin"
SYMLINK="$LOCAL_BIN_DIR/wdjlcli"
APP_IMAGE="$INSTALL_DIR/wdjlcli.AppImage"

info "===== 万店精灵 CLI 更新程序 ====="
info "安装目录: $INSTALL_DIR"

if [[ ! -d "$INSTALL_DIR" ]]; then
    error "未检测到安装目录，请先执行 install.sh 安装 wdjlcli。"
    exit 1
fi

# 读取当前版本
current_version="unknown"
if [[ -f "$VERSION_FILE" ]]; then
    current_version="$(cat "$VERSION_FILE")"
fi
info "当前安装版本: $current_version"

# 获取目标版本号
target_version="$VERSION"
if [[ -z "$target_version" ]]; then
    info "正在获取最新版本号..."
    # 更新索引从新域名获取
    releases_url="$INDEX_BASE_URL/RELEASES-linux"
    releases_content=""
    if command -v curl &>/dev/null; then
        releases_content="$(curl -fsSL "$releases_url")"
    elif command -v wget &>/dev/null; then
        releases_content="$(wget -qO- "$releases_url")"
    else
        error "未找到 curl 或 wget，无法获取最新版本号。"
        exit 1
    fi
    # RELEASES-linux 格式：SHA1 FILENAME SIZE
    # 取最后一行作为最新版本，从文件名提取版本号
    latest_line="$(echo "$releases_content" | grep -E '^[0-9a-fA-F]+\s+wdjlcli-.+-full\.nupkg' | tail -1)"
    if [[ -z "$latest_line" ]]; then
        error "无法从 RELEASES-linux 解析版本号。"
        exit 1
    fi
    nupkg_name="$(echo "$latest_line" | awk '{print $2}')"
    # 从文件名提取版本：
    # wdjlcli-1.0.0-rev738-full.nupkg -> 1.0.0-rev738
    # wdjlcli-1.0.0-rev738-linux-full.nupkg -> 1.0.0-rev738
    tmp="${nupkg_name#wdjlcli-}"
    tmp="${tmp%-full.nupkg}"
    tmp="${tmp%-linux}"
    tmp="${tmp%-osx}"
    tmp="${tmp%-win}"
    if [[ -z "$tmp" ]]; then
        error "无法从文件名解析版本: $nupkg_name"
        exit 1
    fi
    target_version="$tmp"
    info "最新版本: $target_version"
fi

if [[ "$current_version" == "$target_version" ]]; then
    success "当前已是最新版本 ($current_version)，无需更新。"
    exit 0
fi
info "准备从 $current_version 更新到 $target_version ..."

# 终止 daemon 进程
info "正在终止 wdjlcli 进程..."
pkill -x wdjlcli 2>/dev/null || true
info "进程已终止（若存在）。"

# 备份当前安装目录
if [[ -d "$BACKUP_DIR" ]]; then
    info "清除旧备份目录: $BACKUP_DIR"
    rm -rf "$BACKUP_DIR"
fi
info "正在备份当前安装目录到: $BACKUP_DIR"
cp -a "$INSTALL_DIR" "$BACKUP_DIR"
success "备份完成。"

# 候选安装包（按优先级）：带版本号的 AppImage -> 固定名 AppImage（兼容旧发布）
# CDN 缓存按文件名隔离，版本号命名不受固定名缓存影响
candidates=(
    "wdjlcli-${target_version}-linux.AppImage"
    "wdjlcli-${target_version}.AppImage"
    "wdjlcli.AppImage"
)

TMP_FILE=""
cleanup() {
    if [[ -n "$TMP_FILE" && -f "$TMP_FILE" ]]; then
        rm -f "$TMP_FILE"
    fi
}
trap cleanup EXIT

TMP_FILE="$(mktemp /tmp/wdjlcli-XXXXXX.AppImage)"
info "正在下载新版本安装包..."

downloaded=false
for cand in "${candidates[@]}"; do
    for base in "$INDEX_BASE_URL" "$BASE_URL"; do
        DOWNLOAD_URL="$base/$cand"
        info "下载地址: $DOWNLOAD_URL"
        if command -v curl &>/dev/null; then
            curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE" || continue
        elif command -v wget &>/dev/null; then
            wget -q "$DOWNLOAD_URL" -O "$TMP_FILE" || continue
        else
            error "未找到 curl 或 wget。"
            exit 1
        fi
        if [[ -s "$TMP_FILE" ]]; then
            downloaded=true
            break
        fi
    done
    if [[ "$downloaded" == "true" ]]; then
        break
    fi
done

if [[ "$downloaded" != "true" ]]; then
    error "下载失败：所有候选地址均不可用，请检查网络或远程文件是否存在。"
    exit 1
fi

install_ok=false
{
    info "清空旧安装目录..."
    rm -rf "${INSTALL_DIR:?}"/*

    info "正在部署新版本..."
    chmod +x "$TMP_FILE"
    mv "$TMP_FILE" "$APP_IMAGE"
    mkdir -p "$LOCAL_BIN_DIR"
    ln -sf "$APP_IMAGE" "$SYMLINK"

    echo -n "$target_version" > "$VERSION_FILE"
    success "版本信息已更新: $target_version"

    install_ok=true
} || true

if [[ "$install_ok" == "true" ]]; then
    rm -rf "$BACKUP_DIR"
    info "已删除备份目录。"

    success ""
    success "===== 更新成功! ====="
    success "wdjlcli 已更新至版本: $target_version"
else
    error "更新失败，正在回滚到备份版本 $current_version ..."
    rm -rf "$INSTALL_DIR" 2>/dev/null || true
    if [[ -d "$BACKUP_DIR" ]]; then
        mv "$BACKUP_DIR" "$INSTALL_DIR"
        ln -sf "$APP_IMAGE" "$SYMLINK" 2>/dev/null || true
        success "已成功回滚到版本: $current_version"
    else
        error "备份目录不存在，无法回滚，请重新运行 install.sh 安装。"
    fi
    exit 1
fi
