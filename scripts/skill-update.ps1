<#
.SYNOPSIS
    万店精灵 CLI Skill 更新脚本 (Windows)
.DESCRIPTION
    检测本 Skill 仓库是否有可用更新，并通过 git 拉取最新版本。
    Skill 通过 git clone 安装到各 AI Agent IDE 的 skills 目录，本脚本对该 git 仓库执行
    fetch/status 检查与 pull 更新，并读取 skill.json 的 version 字段展示当前版本。
.PARAMETER Branch
    远程分支名，默认 main。
.PARAMETER Check
    仅检查更新状态，不执行 pull。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts/skill-update.ps1
    powershell -ExecutionPolicy Bypass -File scripts/skill-update.ps1 -Check
#>

param(
    [string]$Branch = "main",
    [switch]$Check
)

$ErrorActionPreference = "Stop"

function Write-Success { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Info    { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Err     { param([string]$Message); Write-Host $Message -ForegroundColor Red }

# 定位 Skill 仓库根目录（脚本位于 scripts/ 子目录下）
$SkillRoot = Split-Path -Parent $PSScriptRoot

Write-Info "===== 万店精灵 CLI Skill 更新程序 ====="
Write-Info "Skill 目录: $SkillRoot"

# 确认 git 可用
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "未检测到 git，请先安装 git 后重试。"
    exit 1
}

# 确认是 git 仓库
if (-not (Test-Path (Join-Path $SkillRoot ".git"))) {
    Write-Err "当前 Skill 不是通过 git clone 安装的（未找到 .git 目录），无法自动更新。"
    Write-Info "请重新使用 git clone 安装，或手动下载最新版本覆盖。"
    exit 1
}

# 读取当前版本
$SkillJson = Join-Path $SkillRoot "skill.json"
$currentVersion = "unknown"
if (Test-Path $SkillJson) {
    try {
        $currentVersion = (Get-Content $SkillJson -Raw | ConvertFrom-Json).version
        if ([string]::IsNullOrWhiteSpace($currentVersion)) { $currentVersion = "unknown" }
    } catch {
        $currentVersion = "unknown"
    }
}
Write-Info "当前 Skill 版本: $currentVersion"

Push-Location $SkillRoot
try {
    Write-Info "正在从远程获取最新信息..."
    git fetch origin --tags 2>&1 | Out-Null

    $local  = (git rev-parse HEAD).Trim()
    $remote = (git rev-parse "origin/$Branch" 2>$null)
    if ([string]::IsNullOrWhiteSpace($remote)) {
        Write-Err "无法解析远程分支 origin/$Branch，请确认分支名是否正确（可用 -Branch 指定）。"
        exit 1
    }
    $remote = $remote.Trim()

    if ($local -eq $remote) {
        Write-Success "当前已是最新版本 ($currentVersion)，无需更新。"
        exit 0
    }

    $behind = (git rev-list --count "HEAD..origin/$Branch").Trim()
    Write-Info "检测到更新：落后远程 $behind 个提交。更新内容："
    git log --oneline "HEAD..origin/$Branch"

    if ($Check) {
        Write-Info ""
        Write-Info "仅检查模式（-Check）：未执行更新。运行不带 -Check 的命令即可更新。"
        exit 0
    }

    # 检查本地是否有未提交改动
    $dirty = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($dirty)) {
        Write-Err "本地存在未提交的改动，为避免冲突已中止更新。请先提交或还原改动后重试："
        git status --short
        exit 1
    }

    Write-Info "正在拉取最新版本..."
    git pull origin $Branch

    # 重新读取版本
    $newVersion = "unknown"
    if (Test-Path $SkillJson) {
        try { $newVersion = (Get-Content $SkillJson -Raw | ConvertFrom-Json).version } catch {}
    }

    Write-Success ""
    Write-Success "===== 更新成功! ====="
    Write-Success "Skill 已从 $currentVersion 更新至 $newVersion"
    Write-Info "如需查看变更详情，请阅读 CHANGELOG.md"
} finally {
    Pop-Location
}
