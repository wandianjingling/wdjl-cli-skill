#!/usr/bin/env bash
# skill-update.sh - 万店精灵 CLI Skill 更新脚本 (Linux/macOS)
#
# 检测本 Skill 仓库是否有可用更新，并通过 git 拉取最新版本。
# Skill 通过 git clone 安装到各 AI Agent IDE 的 skills 目录，本脚本对该 git 仓库执行
# fetch/status 检查与 pull 更新，并读取 skill.json 的 version 字段展示当前版本。
#
# 用法:
#   bash scripts/skill-update.sh              # 检查并更新
#   bash scripts/skill-update.sh --check      # 仅检查更新状态，不执行 pull
#   bash scripts/skill-update.sh --branch dev # 指定远程分支（默认 main）
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${YELLOW}$*${NC}"; }
success() { echo -e "${GREEN}$*${NC}"; }
error()   { echo -e "${RED}$*${NC}" >&2; }

BRANCH="main"
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        *)
            error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 定位 Skill 仓库根目录（脚本位于 scripts/ 子目录下）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_JSON="$SKILL_ROOT/skill.json"

info "===== 万店精灵 CLI Skill 更新程序 ====="
info "Skill 目录: $SKILL_ROOT"

# 确认 git 可用
if ! command -v git &>/dev/null; then
    error "未检测到 git，请先安装 git 后重试。"
    exit 1
fi

# 确认是 git 仓库
if [[ ! -d "$SKILL_ROOT/.git" ]]; then
    error "当前 Skill 不是通过 git clone 安装的（未找到 .git 目录），无法自动更新。"
    info "请重新使用 git clone 安装，或手动下载最新版本覆盖。"
    exit 1
fi

# 读取当前版本（简单解析 skill.json 的 version 字段，避免依赖 jq）
read_version() {
    if [[ -f "$SKILL_JSON" ]]; then
        grep -m1 '"version"' "$SKILL_JSON" | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true
    fi
}

current_version="$(read_version)"
[[ -z "$current_version" ]] && current_version="unknown"
info "当前 Skill 版本: $current_version"

cd "$SKILL_ROOT"

info "正在从远程获取最新信息..."
git fetch origin --tags >/dev/null 2>&1

local_rev="$(git rev-parse HEAD)"
if ! remote_rev="$(git rev-parse "origin/$BRANCH" 2>/dev/null)"; then
    error "无法解析远程分支 origin/$BRANCH，请确认分支名是否正确（可用 --branch 指定）。"
    exit 1
fi

if [[ "$local_rev" == "$remote_rev" ]]; then
    success "当前已是最新版本 ($current_version)，无需更新。"
    exit 0
fi

behind="$(git rev-list --count "HEAD..origin/$BRANCH")"
info "检测到更新：落后远程 $behind 个提交。更新内容："
git log --oneline "HEAD..origin/$BRANCH"

if [[ "$CHECK_ONLY" == "true" ]]; then
    info ""
    info "仅检查模式（--check）：未执行更新。运行不带 --check 的命令即可更新。"
    exit 0
fi

# 检查本地是否有未提交改动
if [[ -n "$(git status --porcelain)" ]]; then
    error "本地存在未提交的改动，为避免冲突已中止更新。请先提交或还原改动后重试："
    git status --short
    exit 1
fi

info "正在拉取最新版本..."
git pull origin "$BRANCH"

new_version="$(read_version)"
[[ -z "$new_version" ]] && new_version="unknown"

success ""
success "===== 更新成功! ====="
success "Skill 已从 $current_version 更新至 $new_version"
info "如需查看变更详情，请阅读 CHANGELOG.md"
