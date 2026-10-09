<#
.SYNOPSIS
    万店精灵 CLI Windows 安装脚本
.DESCRIPTION
    从远程发布服务器下载 Windows 便携包并解压到 %LOCALAPPDATA%\wdjlcli，
    同时将安装目录添加到当前用户 PATH。
.PARAMETER BaseUrl
    发布包根 URL，默认 https://res.wandianjingling.com/wdjlcli/Releases_win-x86
.PARAMETER IndexBaseUrl
    更新索引（RELEASES）根 URL，默认 https://res2.wandianjingling.com/wdjlcli/Releases_win-x86
.PARAMETER Version
    指定版本号。留空则下载最新发布包（目前远程仅将文件放在根目录，无版本子目录）。
#>

param(
    [string]$BaseUrl = "https://res.wandianjingling.com/wdjlcli/Releases_win-x86",
    [string]$IndexBaseUrl = "https://res2.wandianjingling.com/wdjlcli/Releases_win-x86",
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

function Write-Success { param([string]$Message); Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Info    { param([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Err     { param([string]$Message); Write-Host "[ERROR] $Message" -ForegroundColor Red }

$InstallDir  = "$env:LOCALAPPDATA\wdjlcli"
$TempFile    = "$env:TEMP\wdjlcli-win-Portable.zip"
$VersionFile = "$InstallDir\.version"

Write-Info "===== 万店精灵 CLI 安装程序 ====="

try {
    # 远程目前把发布文件直接放在 BaseUrl 根目录，没有版本子目录
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $DownloadUrl = "$BaseUrl/wdjlcli-win-Portable.zip"
    } else {
        $DownloadUrl = "$BaseUrl/$Version/wdjlcli-win-Portable.zip"
    }

    # 从 Velopack RELEASES 文件读取最新版本号（索引从新域名获取），用于写入 .version
    $latestVersion = $Version
    if ([string]::IsNullOrWhiteSpace($latestVersion)) {
        try {
            $response = Invoke-WebRequest -Uri "$IndexBaseUrl/RELEASES" -UseBasicParsing -ErrorAction SilentlyContinue
            $rawContent = $response.Content
            if ($rawContent -is [byte[]]) {
                $releasesContent = [System.Text.Encoding]::UTF8.GetString($rawContent).Trim()
            } else {
                $releasesContent = $rawContent.Trim()
            }
            $releaseLines = $releasesContent -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
            if ($releaseLines.Count -gt 0) {
                $latestLine = $releaseLines[-1]
                $parts = $latestLine -split "\s+"
                if ($parts.Count -ge 2) {
                    $nupkgName = $parts[1]
                    if ($nupkgName -match "wdjlcli-(.+?)-(?:(linux|osx|win)-)?full\.nupkg") {
                        $latestVersion = $Matches[1]
                    }
                }
            }
        } catch {
            $latestVersion = "unknown"
        }
    }

    Write-Info "下载地址: $DownloadUrl"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing

    if ((Get-Item $TempFile).Length -eq 0) {
        throw "下载的文件大小为 0，请检查网络或远程文件是否存在。"
    }

    if (Test-Path $InstallDir) {
        Remove-Item -Path "$InstallDir\*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Info "正在解压安装包..."
    Expand-Archive -Path $TempFile -DestinationPath $InstallDir -Force

    # Velopack 便携包结构：实际可执行文件位于 current/ 子目录
    $exeDir = "$InstallDir\current"
    if (-not (Test-Path $exeDir)) {
        throw "解压后未找到 current 目录，发布包结构可能已变更。"
    }

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$exeDir*") {
        if ([string]::IsNullOrEmpty($currentPath)) {
            $newPath = $exeDir
        } else {
            $newPath = "$currentPath;$exeDir"
        }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Info "已将 $exeDir 添加到用户 PATH"
    } else {
        Write-Info "安装目录已在用户 PATH 中"
    }

    $latestVersion | Set-Content -Path $VersionFile -NoNewline
    Write-Success "安装成功! 版本: $latestVersion"
    Write-Info "请重新打开终端后再使用 wdjlcli 命令（当前终端的 PATH 不会自动刷新）。"

} catch {
    Write-Err "安装失败: $_"
    exit 1
} finally {
    if (Test-Path $TempFile) {
        Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
    }
}
