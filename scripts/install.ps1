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
$NupkgFile   = "$env:TEMP\wdjlcli-install.nupkg"
$VersionFile = "$InstallDir\.version"

Write-Info "===== 万店精灵 CLI 安装程序 ====="

try {
    # 从 Velopack RELEASES 文件读取最新版本号与 nupkg 文件名（索引从新域名获取）
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
            $releaseLines = @($releasesContent -split "`r?`n" | Where-Object { $_.Trim() -ne "" })
            if ($releaseLines.Count -gt 0) {
                $latestLine = $releaseLines[-1]
                $parts = @($latestLine -split "\s+")
                if ($parts.Count -ge 2) {
                    $nupkgName = $parts[1]
                    $nupkgSha1 = $parts[0].TrimStart([char]0xFEFF, ' ', "`t")
                    if ($nupkgName -match "wdjlcli-(.+?)-(?:(linux|osx|win)-)?full\.nupkg") {
                        $latestVersion = $Matches[1]
                    }
                }
            }
        } catch {
            $latestVersion = "unknown"
        }
    }

    # 指定版本时未经过 RELEASES 解析，需要构造 nupkg 文件名
    if ([string]::IsNullOrWhiteSpace($nupkgName)) {
        $nupkgName = "wdjlcli-$latestVersion-full.nupkg"
    }

    # 直接下载 RELEASES 中列出的 nupkg（与版本号严格对应，避免固定名 zip 不同步的问题）
    Write-Info "正在下载安装包: $nupkgName ..."
    $downloaded = $false
    foreach ($base in @($IndexBaseUrl, $BaseUrl)) {
        $DownloadUrl = "$base/$nupkgName"
        Write-Info "下载地址: $DownloadUrl"
        try {
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $NupkgFile -UseBasicParsing -ErrorAction Stop
            if ((Get-Item $NupkgFile).Length -gt 0) {
                $downloaded = $true
                break
            }
        } catch {
            Write-Info "从该地址下载失败，尝试备用地址..."
        }
    }
    if (-not $downloaded) {
        throw "nupkg 下载失败：所有下载地址均不可用，请检查网络或远程文件是否存在。"
    }

    # 若 RELEASES 提供了 SHA1，校验下载完整性
    if (-not [string]::IsNullOrWhiteSpace($nupkgSha1)) {
        $actualSha1 = (Get-FileHash -Path $NupkgFile -Algorithm SHA1).Hash
        if ($actualSha1 -ne $nupkgSha1.ToUpper()) {
            throw "SHA1 校验失败（期望 $nupkgSha1，实际 $actualSha1），安装包可能已损坏"
        }
        Write-Info "SHA1 校验通过。"
    }

    if (Test-Path $InstallDir) {
        Remove-Item -Path "$InstallDir\*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # nupkg 本质是 zip，Expand-Archive 要求 .zip 扩展名，先复制改名再解压
    Write-Info "正在解压 nupkg 并提取 lib/app ..."
    $zipCopy    = "$env:TEMP\wdjlcli-install-nupkg.zip"
    $extractDir = "$env:TEMP\wdjlcli-install-extract"
    if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force }
    Copy-Item -Path $NupkgFile -Destination $zipCopy -Force
    Expand-Archive -Path $zipCopy -DestinationPath $extractDir -Force

    $appDir = Join-Path $extractDir "lib\app"
    if (-not (Test-Path $appDir)) {
        throw "nupkg 中未找到 lib/app 目录，发布包结构可能已变更。"
    }
    $exeDir = "$InstallDir\current"
    New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
    Copy-Item -Path "$appDir\*" -Destination $exeDir -Recurse -Force
    Remove-Item -Path $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $zipCopy -Force -ErrorAction SilentlyContinue

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
    if (Test-Path $NupkgFile) {
        Remove-Item -Path $NupkgFile -Force -ErrorAction SilentlyContinue
    }
}
