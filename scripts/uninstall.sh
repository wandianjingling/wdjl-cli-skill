#!/usr/bin/env bash
# uninstall.sh - 万店精灵 CLI Linux/macOS 卸载脚本
# 用法: bash uninstall.sh
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${YELLOW}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }
error()   { echo -e "${RED}$*${NC}" >&2; }

INSTALL_DIR="$HOME/.wdjlcli"
LOCAL_BIN_DIR="$HOME/.local/bin"
SYMLINK="$LOCAL_BIN_DIR/wdjlcli"

info "===== 万店精灵 CLI 卸载程序 ====="
info "安装目录: $INSTALL_DIR"

if [[ ! -d "$INSTALL_DIR" ]]; then
    info "未检测到安装目录 $INSTALL_DIR，wdjlcli 可能未安装或已被手动删除。"
    exit 0
fi

# 终止 wdjlcli 进程
info "正在终止 wdjlcli 进程..."
pkill -x wdjlcli 2>/dev/null || true
info "进程已终止（若存在）。"

# 删除安装目录
info "正在删除安装目录: $INSTALL_DIR"
rm -rf "$INSTALL_DIR"
success "安装目录已删除。"

# 删除符号链接
if [[ -L "$SYMLINK" ]]; then
    info "正在删除符号链接: $SYMLINK"
    rm -f "$SYMLINK"
    success "符号链接已删除。"
else
    info "符号链接 $SYMLINK 不存在，跳过。"
fi

# 尝试从常见 shell profile 中移除 PATH 配置
info "正在清理 shell profile 中的 PATH 配置..."
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
    if [[ -f "$rc" ]]; then
        # 删除包含 wdjlcli PATH 注释和对应 export 行的块
        if grep -q "# wdjlcli PATH" "$rc" 2>/dev/null; then
            sed -i '/# wdjlcli PATH/d' "$rc"
            sed -i '\#export PATH="\$PATH:'"$LOCAL_BIN_DIR"'"#d' "$rc"
            info "已清理 $rc"
        fi
    fi
done

success ""
success "===== 卸载成功! ====="
success "wdjlcli 已从系统中移除。"
info "请重新打开终端以使 PATH 更改生效。"
