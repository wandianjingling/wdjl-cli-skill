<#
.SYNOPSIS
    万店精灵 CLI Windows 更新脚本
.DESCRIPTION
    从远程发布服务器下载最新 Windows 便携包，覆盖安装到 %LOCALAPPDATA%\wdjlcli。
    更新失败时自动回滚到备份版本。
.PARAMETER BaseUrl
    发布包根 URL，默认 https://res.wandianjingling.com/wdjlcli/Releases_win-x86
.PARAMETER IndexBaseUrl
    更新索引（releases.*.json / RELEASES）根 URL，默认 https://res2.wandianjingling.com/wdjlcli/Releases_win-x86
.PARAMETER Version
    指定版本号。留空则自动从 RELEASES 索引文件获取最新版本。
#>

param(
    [string]$BaseUrl = "https://res.wandianjingling.com/wdjlcli/Releases_win-x86",
    [string]$IndexBaseUrl = "https://res2.wandianjingling.com/wdjlcli/Releases_win-x86",
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

function Write-Success { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Info    { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Err     { param([string]$Message); Write-Host $Message -ForegroundColor Red }

$InstallDir  = "$env:LOCALAPPDATA\wdjlcli"
$BackupDir   = "$env:LOCALAPPDATA\wdjlcli.bak"
$TempFile    = "$env:TEMP\wdjlcli-win-Portable.zip"
$VersionFile = "$InstallDir\.version"

Write-Info "===== 万店精灵 CLI 更新程序 ====="
Write-Info "安装目录: $InstallDir"

if (-not (Test-Path $InstallDir)) {
    Write-Err "未检测到安装目录，请先执行 install.ps1 安装 wdjlcli。"
    exit 1
}

# 读取当前版本
$currentVersion = if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { "unknown" }
Write-Info "当前安装版本: $currentVersion"

# 获取目标版本号
$targetVersion = $Version
if ([string]::IsNullOrWhiteSpace($targetVersion)) {
    Write-Info "正在获取最新版本号..."
    try {
        # 优先读取 Velopack 标准 RELEASES 文件（比 releases.win.json 更可靠），索引从新域名获取
        $releasesUrl = "$IndexBaseUrl/RELEASES"
        $response = Invoke-WebRequest -Uri $releasesUrl -UseBasicParsing -ErrorAction Stop
        $rawContent = $response.Content
        # IIS 可能把无扩展名文件当作二进制返回，需要解码
        if ($rawContent -is [byte[]]) {
            $releasesContent = [System.Text.Encoding]::UTF8.GetString($rawContent).Trim()
        } else {
            $releasesContent = $rawContent.Trim()
        }
        $releaseLines = @($releasesContent -split "`r?`n" | Where-Object { $_.Trim() -ne "" })
        if ($releaseLines.Count -eq 0) {
            throw "RELEASES 文件为空"
        }
        # 取最后一行作为最新版本（Velopack RELEASES 按版本顺序排列）
        $latestLine = $releaseLines[-1]
        $parts = @($latestLine -split "\s+")
        if ($parts.Count -lt 2) {
            throw "RELEASES 文件格式错误"
        }
        $nupkgName = $parts[1]
        # 从文件名提取版本：
        # wdjlcli-1.0.0-rev738-full.nupkg -> 1.0.0-rev738
        # wdjlcli-1.0.0-rev738-linux-full.nupkg -> 1.0.0-rev738
        if ($nupkgName -match "wdjlcli-(.+?)-(?:(linux|osx|win)-)?full\.nupkg") {
            $targetVersion = $Matches[1]
        } else {
            throw "无法从文件名解析版本: $nupkgName"
        }
        Write-Info "最新版本: $targetVersion"
    } catch {
        Write-Err "获取最新版本号失败: $_"
        exit 1
    }
}

if ($currentVersion -eq $targetVersion) {
    Write-Success "当前已是最新版本 ($currentVersion)，无需更新。"
    exit 0
}
Write-Info "准备从 $currentVersion 更新到 $targetVersion ..."

# 终止 wdjlcli 进程
Write-Info "正在终止 wdjlcli 进程..."
Get-Process wdjlcli -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Info "进程已终止（若存在）。"

# 备份当前安装目录
if (Test-Path $BackupDir) {
    Write-Info "清除旧备份目录: $BackupDir"
    Remove-Item -Path $BackupDir -Recurse -Force
}
Write-Info "正在备份当前安装目录到: $BackupDir"
Copy-Item -Path $InstallDir -Destination $BackupDir -Recurse -Force
Write-Success "备份完成。"

# 远程目前把发布文件直接放在 BaseUrl 根目录
$DownloadUrl = "$BaseUrl/wdjlcli-win-Portable.zip"
Write-Info "下载地址: $DownloadUrl"

try {
    Write-Info "正在下载新版本安装包..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing -ErrorAction Stop
    if ((Get-Item $TempFile).Length -eq 0) {
        throw "下载的文件大小为 0"
    }
    Write-Success "下载完成。"

    Write-Info "清空旧安装目录..."
    Remove-Item -Path $InstallDir -Recurse -Force
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    Write-Info "正在解压新版本..."
    Expand-Archive -Path $TempFile -DestinationPath $InstallDir -Force -ErrorAction Stop
    Write-Success "解压完成。"

    $exeDir = "$InstallDir\current"
    if (-not (Test-Path $exeDir)) {
        throw "解压后未找到 current 目录，发布包结构可能已变更。"
    }

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$exeDir*") {
        $newPath = "$currentPath;$exeDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Info "已将 $exeDir 添加到用户 PATH"
    }

    $targetVersion | Set-Content -Path $VersionFile -NoNewline
    Write-Success "版本信息已更新: $targetVersion"

    Remove-Item -Path $BackupDir -Recurse -Force
    Write-Info "已删除备份目录。"

    Write-Success ""
    Write-Success "===== 更新成功! ====="
    Write-Success "wdjlcli 已更新至版本: $targetVersion"

} catch {
    Write-Err "更新失败: $_"
    Write-Info "正在回滚到备份版本..."
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $BackupDir) {
        Move-Item -Path $BackupDir -Destination $InstallDir -Force
        Write-Success "已成功回滚到版本: $currentVersion"
    } else {
        Write-Err "备份目录不存在，无法回滚，请重新运行 install.ps1 安装。"
    }
    exit 1
} finally {
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
    }
}
