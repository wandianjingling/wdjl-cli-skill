# uninstall.ps1 - 万店精灵 CLI Windows 卸载脚本
# 用法: .\uninstall.ps1

# ===== 颜色输出辅助函数 =====
function Write-Success { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Info    { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Err     { param([string]$Message); Write-Host $Message -ForegroundColor Red }

# ===== 常量定义 =====
$InstallDir = "$env:LOCALAPPDATA\wdjlcli"

Write-Info "===== 万店精灵 CLI 卸载程序 ====="
Write-Info "安装目录: $InstallDir"

# ===== 检查是否已安装 =====
if (-not (Test-Path $InstallDir)) {
    Write-Info "未检测到安装目录，wdjlcli 可能未安装或已被手动删除。"
    exit 0
}

# ===== 终止 wdjlcli 进程 =====
Write-Info "正在终止 wdjlcli 进程..."
Get-Process wdjlcli -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Info "进程已终止（若存在）。"

# ===== 删除安装目录 =====
Write-Info "正在删除安装目录: $InstallDir"
Remove-Item -Path $InstallDir -Recurse -Force
Write-Success "安装目录已删除。"

# ===== 从用户 PATH 中移除安装目录 =====
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -like "*$InstallDir*") {
    Write-Info "正在从用户 PATH 中移除安装目录..."
    # 将 PATH 按分号拆分，过滤掉目标路径，再拼回
    $newPath = ($currentPath -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Success "已从 PATH 中移除。"
} else {
    Write-Info "安装目录不在用户 PATH 中，跳过。"
}

# ===== 卸载完成提示 =====
Write-Success ""
Write-Success "===== 卸载成功! ====="
Write-Success "wdjlcli 已从系统中移除。"
Write-Info "请重新打开终端以使 PATH 更改生效。"
