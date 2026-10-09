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
$PkgFile     = "$env:TEMP\wdjlcli-install.pkg"
$VersionFile = "$InstallDir\.version"

# 候选安装包（按优先级）：带版本号的便携包 -> RELEASES 中的 nupkg
# 不再回退到固定名便携包：固定名会被 CDN 边缘节点长期缓存，容易装到旧版本
function Get-PackageCandidates([string]$ver, [string]$nupkg) {
    $list = @()
    if (-not [string]::IsNullOrWhiteSpace($ver) -and $ver -ne "unknown") {
        $list += @{ Name = "wdjlcli-$ver-win-Portable.zip"; Type = "zip" }
    }
    if (-not [string]::IsNullOrWhiteSpace($nupkg)) {
        $list += @{ Name = $nupkg; Type = "nupkg" }
    } elseif (-not [string]::IsNullOrWhiteSpace($ver) -and $ver -ne "unknown") {
        $list += @{ Name = "wdjlcli-$ver-full.nupkg"; Type = "nupkg" }
    }
    return $list
}

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
            if ($releaseLines.Count -eq 0) {
                throw "RELEASES 文件为空"
            }
            $latestLine = $releaseLines[-1]
            $parts = @($latestLine -split "\s+")
            if ($parts.Count -lt 2) {
                throw "RELEASES 文件格式错误"
            }
            $nupkgName = $parts[1]
            $nupkgSha1 = $parts[0].TrimStart([char]0xFEFF, ' ', "`t")
            if ($nupkgName -match "wdjlcli-(.+?)-(?:(linux|osx|win)-)?full\.nupkg") {
                $latestVersion = $Matches[1]
            } else {
                throw "无法从文件名解析版本: $nupkgName"
            }
        } catch {
            Write-Err "获取最新版本号失败: $_"
            exit 1
        }
    }

    # 按候选清单依次尝试下载（版本号命名优先，CDN 缓存按文件名隔离，不受固定名缓存影响）
    $downloaded = $false
    $pkgType = $null
    foreach ($cand in (Get-PackageCandidates $latestVersion $nupkgName)) {
        foreach ($base in @($IndexBaseUrl, $BaseUrl)) {
            $DownloadUrl = "$base/$($cand.Name)"
            Write-Info "下载地址: $DownloadUrl"
            try {
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $PkgFile -UseBasicParsing -ErrorAction Stop
                if ((Get-Item $PkgFile).Length -gt 0) {
                    $downloaded = $true
                    $pkgType = $cand.Type
                    break
                }
            } catch {
                Write-Info "该地址不可用，尝试下一个..."
            }
        }
        if ($downloaded) { break }
    }
    if (-not $downloaded) {
        throw "安装包下载失败：所有候选地址均不可用，请检查网络或远程文件是否存在。"
    }

    # 若下载的是 RELEASES 中列出的 nupkg，用其 SHA1 校验完整性
    if ($pkgType -eq "nupkg" -and -not [string]::IsNullOrWhiteSpace($nupkgSha1)) {
        $actualSha1 = (Get-FileHash -Path $PkgFile -Algorithm SHA1).Hash
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

    # zip/nupkg 都用 Expand-Archive 解压（nupkg 本质是 zip，需先改为 .zip 扩展名）
    Write-Info "正在解压安装包 ($pkgType) ..."
    $zipCopy    = "$env:TEMP\wdjlcli-install-pkg.zip"
    $extractDir = "$env:TEMP\wdjlcli-install-extract"
    if (Test-Path $extractDir) { Remove-Item -Path $extractDir -Recurse -Force }
    Copy-Item -Path $PkgFile -Destination $zipCopy -Force
    Expand-Archive -Path $zipCopy -DestinationPath $extractDir -Force

    if ($pkgType -eq "nupkg") {
        # nupkg 结构：应用文件位于 lib/app
        $appDir = Join-Path $extractDir "lib\app"
        if (-not (Test-Path $appDir)) {
            throw "nupkg 中未找到 lib/app 目录，发布包结构可能已变更。"
        }
        $exeDir = "$InstallDir\current"
        New-Item -ItemType Directory -Path $exeDir -Force | Out-Null
        Copy-Item -Path "$appDir\*" -Destination $exeDir -Recurse -Force
    } else {
        # 便携 zip 结构：实际可执行文件位于 current/ 子目录
        $appDir = Join-Path $extractDir "current"
        if (-not (Test-Path $appDir)) {
            throw "便携包中未找到 current 目录，发布包结构可能已变更。"
        }
        Copy-Item -Path $appDir -Destination $InstallDir -Recurse -Force
        $exeDir = "$InstallDir\current"
    }
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
    if (Test-Path $PkgFile) {
        Remove-Item -Path $PkgFile -Force -ErrorAction SilentlyContinue
    }
}
