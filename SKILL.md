---
name: wdjlcli
version: 1.3.0
description: 万店精灵 CLI 指令型 Skill，Agent 通过终端执行 wdjlcli 命令与工具交互，不涉及 MCP 调用
---

> **⚠️ AI Agent 必读**
>
> 这是一个 **CLI 指令型 Skill**，Agent 通过终端执行 `wdjlcli` 命令与工具交互，不涉及 MCP 调用。
>
> **运行前提**：
> - 系统已安装 .NET 8 运行时
>   - Windows（win-x86，发布包与本地 `publish/cli` 默认构建均为 win-x86）：安装 .NET 8 Desktop Runtime 或 .NET 8 Runtime
>   - Linux（linux-x64）：安装 .NET 8 Runtime（`apt/yum install dotnet-runtime-8.0`）
>   - macOS（osx-x64 / osx-arm64）：安装 .NET 8 Runtime（`brew install dotnet`）
> - 可执行文件：**Windows** 为 `wdjlcli.exe`，**Linux/macOS** 为 `wdjlcli`（需有执行权限 `chmod +x wdjlcli`）
> - 可执行文件在 PATH 中或使用绝对路径调用
>
> **注意**：wdjlcli 使用 Velopack 作为更新框架。更新索引（`releases.*.json`、`RELEASES` / `RELEASES-linux`）从新域名 `res2.wandianjingling.com` 读取，更新包与安装包仍从原域名 `res.wandianjingling.com` 下载，因此**重启时默认会自动检查并应用更新**。如不希望自动更新，可在启动时加上 `--no-autologin` 或手动控制更新时机。
>
> **全局标志**：
> - `--no-autologin`：跳过自动登录流程
> - `--repl`：强制进入 REPL 交互模式
> - `--daemon`：以 Daemon 常驻模式启动（Windows 使用命名管道，Linux/macOS 使用 Unix Domain Socket）
>
> **执行方式**：
> - 带命令参数 → 直接执行并返回结果（推荐 Agent 使用）
> - Agent 必须等待终端退出，因为终端会持续输出内容，Agent 单方停止就会丢失终端响应（**⚠️ AI Agent 切记**）
> - 无参数或 `--repl` → 进入 REPL 交互模式（适合用户手动操作）
> - `--daemon` → 启动常驻后台服务，通过管道/Socket 接收命令
> - 带命令参数 + daemon 已运行 → 自动以 Client 模式通过管道/Socket 转发命令

# 万店精灵 CLI · 操作指令 Skill

## 安装管理

wdjlcli 支持通过脚本在 Windows、Linux、macOS 上自动安装、更新和卸载。

### 安装目录

| 平台 | 安装路径 | 可执行文件 |
|------|---------|-----------|
| Windows | `%LOCALAPPDATA%\wdjlcli\` | `current\wdjlcli.exe` |
| Linux | `~/.wdjlcli/` | `wdjlcli.AppImage`（通过 `~/.local/bin/wdjlcli` 符号链接调用） |
| macOS | `~/.wdjlcli/` | `wdjlcli` |

> **安装包结构说明**：Windows 便携包是 Velopack 格式，实际可执行文件位于安装目录的 `current/` 子目录中，脚本会自动将 `current/` 加入 PATH。Linux AppImage 会直接存放在 `~/.wdjlcli/`，并通过 `~/.local/bin/wdjlcli` 符号链接暴露到 PATH。

### 快速安装

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

**Linux:**
```bash
bash scripts/install.sh
```

**macOS:**
目前未提供 macOS 安装脚本，需在 macOS 上运行 `publish/cli/publish-all-mac.sh` 构建后手动部署。

安装脚本会自动下载对应平台的发布包、解压到安装目录，并将其加入 PATH（Windows 写入用户 PATH；Linux 写入 shell profile）。

### 更新

wdjlcli 内置 Velopack 自动更新，**重启程序时会自动检查并下载最新版本**。此外也提供手动更新脚本：

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/update.ps1
```

```bash
# Linux
bash scripts/update.sh
```

更新脚本会从新域名 `res2.wandianjingling.com` 上的 Velopack 标准 `RELEASES` / `RELEASES-linux` 索引文件中解析最新版本号，再从原域名 `res.wandianjingling.com` 下载对应平台的发布包并覆盖安装。

### 卸载

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/uninstall.ps1
```

```bash
# Linux / macOS
bash scripts/uninstall.sh
```

卸载会停止运行中的 daemon 进程、删除安装目录并清理 PATH。

## 触发场景

| 用户可能会说 | 执行什么命令 |
|---|---|
| "登录万店精灵" / "登录账号" | `wdjlcli login` |
| "退出登录" | `wdjlcli logout` |
| "登录了没？" / "查看登录状态" | `wdjlcli status` |
| "我有哪些店铺？" / "店铺列表" | `wdjlcli shop list` |
| "添加一个淘宝店铺" / "绑定店铺" | `wdjlcli shop add taobao` |
| "删除店铺" / "移除店铺" | `wdjlcli shop remove` |
| "切换到另一个店铺" | `wdjlcli shop switch` |
| "帮我采集这个链接" / "上货" / "铺货" | `wdjlcli publish links --url <URL>` |
| "把链接同时上货到多个店铺" / "多店铺货" | `wdjlcli publish links --url <URL> --shopid <店铺ID1,店铺ID2>` |
| "查看待上传商品" / "上货列表" | `wdjlcli publish list` |
| "店铺互传" / "店铺搬家" / "把A店商品复制到B店" | `wdjlcli publish transfer --sourceshopid <来源店铺ID> --shopid <目标店铺ID>` |
| "批量改价" / "批量改标题" / "批量改库存" / "批量修改商品" | `wdjlcli goodsupdate submit -s <店铺ID> -t <类型>` |
| "查看批量修改记录" / "批量修改进度" | `wdjlcli goodsupdate records` |
| "查看某批次修改了哪些商品" | `wdjlcli goodsupdate items -b <批次ID>` |
| "取消批量修改" / "停止批量修改" | `wdjlcli goodsupdate cancel -b <批次ID>` |
| "重试批量修改失败的商品" | `wdjlcli goodsupdate retry -b <批次ID>` |
| "查看配置" / "当前配置是什么" | `wdjlcli config list` |
| "修改配置" / "设置运费模板" | `wdjlcli config set -k <KEY> -v <VALUE>` |
| "查看某个配置项" | `wdjlcli config get -k <KEY>` |
| "怎么用？" / "帮助" | `wdjlcli help` |
| "版本号" | `wdjlcli version` |
| "订购/订阅" | `wdjlcli subscribe add` |
| 安装 wdjlcli / 安装万店精灵CLI | 运行 `scripts/install.ps1` 或 `scripts/install.sh` |
| 更新 wdjlcli / 升级万店精灵CLI | 重启程序自动更新；或运行 `scripts/update.ps1` / `scripts/update.sh` |
| 卸载 wdjlcli / 删除万店精灵CLI | 运行 `scripts/uninstall.ps1` 或 `scripts/uninstall.sh` |

## 命令详细说明

### 认证命令

#### `login`

平台账号登录，输入用户名和密码完成认证。

```
wdjlcli login
```

- 交互式输入用户名和密码
- 密码采用加密存储（EncryptHelper）
- 登录成功后自动保存凭证至 AutoLoginConfig.json，后续启动自动登录

**非交互式登录**（支持参数）：
```
wdjlcli login -u <用户名> -p <密码>
wdjlcli login -u <用户名> -p <密码> --save
wdjlcli login -u <用户名> -p <密码> --auto-login
```

| 参数 | 说明 |
|------|------|
| `-u|--username` | 用户名 |
| `-p|--password` | 密码 |
| `--save` | 保存密码到本地凭证文件 |
| `--auto-login` | 保存凭证并设置自动登录 |

#### `logout`

退出当前登录状态。

```
wdjlcli logout
```

#### `status`

查看当前登录状态和账号信息。

```
wdjlcli status
```

### 店铺管理命令（shop）

#### `shop list`

列出当前账号已绑定的所有店铺及其状态。**需登录**。

```
wdjlcli shop list
```

#### `shop add [platform]`

添加新店铺。**需登录**。

```
wdjlcli shop add taobao
wdjlcli shop add pdd
wdjlcli shop add douyin
wdjlcli shop add taobao --browser
```

- 位置参数 `[platform]`：平台标识，支持简写/别名（见下方支持平台列表）；若省略则交互式提示选择
- **默认行为**：若平台支持二维码登录，则在控制台渲染二维码图片，用户扫码即可；若平台不支持二维码登录，则自动打开浏览器窗口进行登录
- 添加 `--browser` 可强制使用浏览器窗口模式登录
- 二维码控制台模式下，控制台会输出二维码临时图片路径
- 轮询检测扫码结果：扫码成功 → 提取 Cookie → 初始化店铺数据；二维码过期 → 自动刷新并重新渲染

> **Agent 注意**：
> 1. 需自动弹出二维码图片(必须), **需要用户用手机扫码**。
> 2. 控制台同步输出二维码图片的临时路径，用户可以手动高清图片可到该路径查看。
> 3. 等待期间不要中断命令，登录成功后命令自动退出。

#### `shop remove`

移除指定店铺。**需登录**。交互式选择要移除的店铺。

```
wdjlcli shop remove
```

#### `shop switch`

切换当前工作店铺。**需登录**。需要显式传入ShopID参数。

```
wdjlcli shop switch <shopId>
```

示例：
```
wdjlcli shop switch 157889500
```
### 订购命令

#### `subscribe add`

订购万店精灵权益。执行后会在控制台打印官方定价页面链接，需用户自行在浏览器中打开并完成订购。

```
wdjlcli subscribe add
```

### 商品采集上货命令（publish）

#### `publish links`

创建商品采集上货任务。**需登录**。支持一次提交把相同链接上货到多个店铺。

```
wdjlcli publish links --url <商品链接>
wdjlcli publish links --url <商品链接> --shopid <店铺ID>
wdjlcli publish links --url <商品链接> --shopid <店铺ID1,店铺ID2,店铺ID3>
wdjlcli publish links --url <商品链接1,商品链接2> --shopid <店铺ID1,店铺ID2> --assigntype 1
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `--url` | 否 | 商品源链接或纯商品ID，支持逗号/分号/空格分隔的多个混合输入，来源平台按链接域名自动识别（1688/淘宝/天猫/拼多多/抖音/京东/快手），不指定则交互式提示输入 |
| `--shopid` | 否 | 指定目标店铺 ID，多个店铺用逗号分隔（相同链接一次上货到多个店铺），不指定则交互式选择当前工作店铺 |
| `-a\|--assigntype` | 否 | 多店铺分配方式：0=重复上货到各店（默认）、1=顺序分配、2=随机平均、3=随机不平均，单店铺时无需指定 |

> 注意：无效的店铺 ID 会在提交前直接报错；任一目标店铺未登录或订购过期会导致整单拒绝，并在错误信息中列出店铺名。

#### `publish list`

查看店铺待上传商品列表。**需登录**。

```
wdjlcli publish list
wdjlcli publish list --shopid <店铺ID>
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `--shopid` | 否 | 指定店铺 ID，不指定则交互式选择当前工作店铺 |

#### `publish datapacket`

导入数据包批量上货。**需登录**。

```
wdjlcli publish datapacket ./goods.txt
wdjlcli publish datapacket ./goods1.txt ./goods2.txt --shopid shop001
wdjlcli publish datapacket ./data_packets/
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `paths` | 是 | 数据包文件路径或目录路径，支持传入多个路径（空格分隔）。文件不限扩展名，数据包格式按内容自动识别；目录会递归扫描所有子目录 |
| `--shopid` | 否 | 指定目标店铺 ID，不指定则交互式选择当前工作店铺 |

**行为说明**：

- 目录路径会递归扫描全部子目录，图片/视频/压缩包等二进制文件与超过 50MB 的文件自动跳过
- 单个文件解析失败时会打印具体错误原因；无法识别格式的文件会打印警告并跳过
- 所有路径都未解析出有效商品时，打印"没有解析出有效商品，未提交上货任务"并以退出码 1 结束

#### `publish transfer`

店铺互传上货（店铺搬家）：将来源店铺的在售商品复制上传到目标店铺。**需登录**。

```
wdjlcli publish transfer --sourceshopid <来源店铺ID> --shopid <目标店铺ID>
wdjlcli publish transfer --sourceshopid shopA -s shopB -g 123456789,987654321
wdjlcli publish transfer --sourceshopid shopA -s shopB -n 连衣裙 --page 2
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `--sourceshopid` | 否 | 来源店铺ID（从该店铺复制商品），不指定则交互选择 |
| `-s\|--shopid` | 否 | 目标店铺ID（商品上传到该店铺），不指定则交互选择 |
| `-g\|--goodsids` | 否 | 来源店铺商品ID，多个用逗号分隔；不指定则查询来源店铺在售商品列表后交互输入 |
| `-n\|--name` | 否 | 按商品名称搜索来源店铺在售商品 |
| `--page` | 否 | 来源店铺在售商品列表页码（默认1，每页20条） |

**行为说明**：

- 来源店铺与目标店铺不能相同
- 只查询/互传在售（上架）商品
- 指定 `-g|--goodsids` 时会先按 ID 反查来源店铺补齐商品信息（抖店互传自动携带 publishIdMap，http 通道必需）；查不到的 ID 会警告并按原 ID 直接互传
- 任务提交后由 Core 上货队列执行（daemon/REPL 模式可保活）

### 商品批量修改命令（goodsupdate）

#### `goodsupdate submit`

提交商品批量修改任务（改价、改标题、改库存等 28 种修改类型）。**需登录**。

```
wdjlcli goodsupdate submit -s <店铺ID> -t price -g 123456789,987654321 -o '{"PriceMode":1,"FixedPrice":99.9}'
wdjlcli goodsupdate submit -s <店铺ID> -t title --options-file options.json
wdjlcli goodsupdate submit -s <店铺ID> -t stock --filter '{"SaleStatus":1}' -o '{"SkuStock":{"StockProcessType":2,"AddStockValue":100}}'
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `-s\|--shopid` | 否 | 目标店铺ID，不指定则打印店铺表后交互输入 |
| `-t\|--type` | 是 | 修改类型，支持枚举名（不区分大小写，如 `title`、`price`、`stock`）或数值（如 `1`、`2`、`13`），取值见下方修改类型速查表 |
| `-g\|--goodsids` | 否 | 商品ID，逗号分隔；指定后为"指定商品"模式；不指定则为"全店商品"模式（按 `--filter` 筛选） |
| `--exclude` | 否 | 全店模式下排除的商品ID，逗号分隔 |
| `--filter` | 否 | 全店模式的筛选条件 JSON（透传 QueryFilter） |
| `-o\|--options` | 否 | 修改参数 JSON 字符串，字段随 `--type` 不同，详见 [BATCH_MODIFY_REFERENCE.md](./BATCH_MODIFY_REFERENCE.md) |
| `--options-file` | 否 | 从 JSON 文件读取修改参数（与 `-o` 二选一；Windows PowerShell 下长 JSON 转义困难时推荐） |
| `--no-wait` | 否 | 提交后不等待完成立即退出 |
| `--timeout` | 否 | 等待超时时间（分钟，默认 30），超时后退出码为 2，批次仍在执行 |

**行为说明**：

- 同一店铺的批次严格串行执行，不同店铺可并行
- 默认提交后轮询批次进度并打印（仅状态变化时输出），直到批次到终态；部分平台（抖店/京东等）的修改为异步提交，等待期间会自动回查平台结果直到真正完成
- **CLI 单次进程退出会中断正在执行的批次（遗留任务在下次登录时标记取消），`--no-wait` 仅建议在 daemon/REPL 模式下使用**；Ctrl+C 中断等待退出码为 130
- `-o|--options` 的字段随 `--type` 不同而不同，组装参数前请读取 [BATCH_MODIFY_REFERENCE.md](./BATCH_MODIFY_REFERENCE.md)
- 平台支持度不一（闲鱼仅支持改标题；得物不支持发货模式/资质/运费模板等），提交不支持的类型会整批失败并写明原因

**修改类型速查表**（`-t|--type` 常用取值，枚举名不区分大小写）：

| 枚举名 | 数值 | 说明 |
|--------|------|------|
| `title` | 1 | 改标题 |
| `price` | 2 | 改价格 |
| `stock` | 13 | 改库存 |
| `salestatus` | 11 | 上下架 |
| `deletegoods` | 10 | 删除商品 |
| `skuname` | 14 | 改SKU名称 |
| `deletesku` | 15 | 删除SKU |

全部 28 种类型及其 options 参数见 [BATCH_MODIFY_REFERENCE.md](./BATCH_MODIFY_REFERENCE.md)。

#### `goodsupdate records`

查询批量修改批次记录。**需登录**。

```
wdjlcli goodsupdate records
wdjlcli goodsupdate records -s <店铺ID> --page 2 --pagesize 50
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `-s\|--shopid` | 否 | 按店铺过滤 |
| `--page` | 否 | 页码（默认1） |
| `--pagesize` | 否 | 每页条数（默认20） |

#### `goodsupdate items`

查询某批次的商品明细。**需登录**。

```
wdjlcli goodsupdate items -b <批次ID>
wdjlcli goodsupdate items -b <批次ID> --page 2 --pagesize 50
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `-b\|--batch` | 是 | 批次ID |
| `--page` | 否 | 页码（默认1） |
| `--pagesize` | 否 | 每页条数（默认20） |

#### `goodsupdate cancel`

取消批量修改批次。**需登录**。

```
wdjlcli goodsupdate cancel -b <批次ID>
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `-b\|--batch` | 是 | 批次ID |

**行为说明**：

- 已提交平台的商品不回滚，未执行的明细标记为已取消

#### `goodsupdate retry`

重试批次中失败的明细。**需登录**。

```
wdjlcli goodsupdate retry -b <批次ID>
```

| 参数 | 必填 | 说明 |
|------|------|------|
| `-b\|--batch` | 是 | 批次ID |

### 配置管理命令（config）

#### `config list`

显示所有配置项及当前值。**需登录**。

```
wdjlcli config list
wdjlcli config list --shopid <店铺ID>
```

#### `config get`

获取单个配置项的值。**需登录**。

```
wdjlcli config get -k <KEY>
wdjlcli config get -k <KEY> --shopid <店铺ID>
```

#### `config set`

设置配置项的值。**需登录**。

```
wdjlcli config set -k <KEY> -v <VALUE>
wdjlcli config set -k <KEY> -v <VALUE> -s <店铺ID>
```

**特殊配置项**（进入交互式流程，`VALUE` 会被忽略）：

| 配置键 | 说明 | 备注 |
|--------|------|------|
| `cat.manual` | 类目手动选择 | 设置后进入交互式多级类目选择流程 |
| `shop.freight` | 运费模板 | 设置后进入交互式运费模板选择流程 |
| `AttrAutoFillRequired` | 属性自动填充 | 设置为 `true` 可自动填充必填属性，解决属性匹配失败问题 |

```
wdjlcli config set -k shop.freight -v dummy
wdjlcli config set -k shop.freight -v dummy -s <店铺ID>
```

> **Agent 注意**：`cat.manual` 和 `shop.freight` 涉及交互式多级选择，Agent 应提示用户这些操作需要手动交互完成。

## 支持平台

| 平台名称 | 标识 | 别名 | 说明 |
|----------|------|------|------|
| 淘宝 | `taobao` | `tb` | 支持二维码控制台登录 |
| 天猫 | `tmall` | - | 不支持二维码登录，使用浏览器窗口 |
| 拼多多 | `pdd` | `拼多多` | 支持二维码控制台登录 |
| 抖音 | `douyin` | `抖音` | 支持二维码控制台登录 |
| 京东 | `jd` | `京东` | 支持二维码控制台登录 |
| 快手 | `kuaishou` | `快手` | 支持二维码控制台登录 |
| 阿里巴巴 1688 | `ali` | `alibaba`、`阿里巴巴` | 有特殊 Cookie 处理 |

## 运行系统平台

| 系统 | 架构 | 运行时要求 | 可执行文件名 |
|------|------|----------|------------|
| Windows | win-x86 | .NET 8 Runtime | `wdjlcli.exe` |
| Linux | x64 | .NET 8 Runtime | `wdjlcli` |
| macOS | x64 (Intel) | .NET 8 Runtime | `wdjlcli` |
| macOS | arm64 (Apple Silicon) | .NET 8 Runtime | `wdjlcli` |

## 配置目录

| 环境 | Windows | Linux/macOS |
|------|---------|-------------|
| Release | `%APPDATA%\wdjl\` | `~/.config/wdjl/`（或 `$XDG_CONFIG_HOME/wdjl/`） |
| Debug | `{WorkingDir}\wdjl\` | `{WorkingDir}/wdjl/` |

**目录结构**：

```
wdjl/
├── config.json            # 全局配置
├── AutoLoginConfig.json   # 自动登录凭证（加密存储）
├── shops/                 # 店铺数据
├── data/                  # 业务数据
├── logs/                  # 运行日志
├── WebCaches/             # 浏览器缓存
└── PlatAttrMap/           # 平台属性映射
```

## Daemon 模式与 Client 模式

### 概述

wdjlcli 支持 **Daemon（常驻服务）+ Client（管道客户端）** 架构，适合需要复用登录状态、减少重复初始化开销的场景。

```
┌─────────────────────────────────────────────┐
│  wdjlcli --daemon          （Daemon 进程）   │
│  · 保持登录状态 & 浏览器实例                │
│  · Windows：命名管道 wdjlcli-{用户名}       │
│  · Linux/macOS： Unix Socket /tmp/wdjlcli-{用户名} │
└────────────────┬────────────────────────────┘
                 │ 命名管道/Unix Socket
┌────────────────▼────────────────────────────┐
│  wdjlcli <命令>            （Client 进程）   │
│  · 检测 daemon 是否运行                     │
│  · 是 → 通过管道/Socket 转发命令，打印输出，退出    │
│  · 否 → 本地直接执行（普通模式）            │
└─────────────────────────────────────────────┘
```

### Daemon 模式

启动常驻 daemon 进程：

```
wdjlcli --daemon
wdjlcli --daemon --no-autologin
```

- daemon 启动后完成一次自动登录，**维持登录状态直到手动停止**
- 通信通道：
  - **Windows**：命名管道（管道名：`wdjlcli-{系统用户名}`）
  - **Linux/macOS**： Unix Domain Socket（`/tmp/wdjlcli-{系统用户名}.sock`）
- 每次收到命令后执行并将 stdout/stderr 写回管道/Socket，返回退出码
- 按 **Ctrl+C** 停止 daemon
- 适合批量操作场景，避免每次命令都重新登录

> **Agent 注意**：以 `is_background=true` 在后台启动 daemon，确保其持续运行后再发送命令。

### Client 模式（自动触发）

Client 模式**无需手动指定**，wdjlcli 自动检测：

```
wdjlcli status        # 若 daemon 运行中 → 自动走管道
wdjlcli publish links --url <URL>   # 同上
```

- 连接超时：**3000ms**，超时后输出错误提示并退出码 1
- 输出格式透明，与本地直接执行的效果一致

### 典型使用场景

**场景：批量上货（Agent 推荐流程）**

```powershell
# Windows PowerShell
# 第 1 步：后台启动 daemon（只需一次）
Start-Process wdjlcli.exe -ArgumentList "--daemon" -WindowStyle Hidden

# 第 2 步：等待 daemon 就绪（约 2 秒）
Start-Sleep -Seconds 2

# 第 3 步：通过 client 模式发送命令（自动走管道）
wdjlcli.exe status
wdjlcli.exe publish links --url https://item.taobao.com/item.htm?id=123456
wdjlcli.exe publish list
```

```bash
# Linux/macOS Bash
# 第 1 步：后台启动 daemon（只需一次）
./wdjlcli --daemon &

# 第 2 步：等待 daemon 就绪（约 2 秒）
sleep 2

# 第 3 步：通过 client 模式发送命令（自动走 Unix Socket）
./wdjlcli status
./wdjlcli publish links --url https://item.taobao.com/item.htm?id=123456
./wdjlcli publish list
```

**关闭 daemon**：
```powershell
# Windows
taskkill /IM wdjlcli.exe /F
```
```bash
# Linux/macOS
killall wdjlcli
# 或使用 Ctrl+C 终止 daemon 进程
```

### 注意事项

- 管道/Socket 名包含系统用户名（`wdjlcli-{用户名}`），**多用户环境下互不干扰**
- daemon 进程同一时刻只处理一个命令请求（串行队列）
- 若 daemon 未启动但执行了带命令参数的调用，**自动降级为本地普通模式**执行，不会报错
- daemon 模式下 `shop add`（控制台扫码）等交互命令由 daemon 进程本身执行，控制台二维码输出会出现在 daemon 的标准输出流中

## REPL 模式

无参数启动或使用 `--repl` 标志进入交互模式：

```
wdjlcli
wdjlcli --repl
```

**REPL 内置命令**：

| 命令 | 说明 |
|------|------|
| `exit` / `quit` | 退出 REPL |

- 支持引号参数（处理包含空格的参数值）
- REPL 中直接输入命令名即可，无需前缀 `wdjlcli`

## 常见问题与解决方案

### 1. 命令找不到 (CommandNotFound)

**问题**：执行 `wdjlcli` 提示命令未找到

**解决**：使用绝对路径调用
<!-- ```powershell
# Windows
D:\work\code\gjx\CyjWork\wdjlcli\bin\Debug\net8.0\win-x64\wdjlcli.exe <命令>
```
```bash
# Linux
/path/to/wdjlcli/bin/Debug/net8.0/linux-x64/wdjlcli <命令>
# macOS (x64)
/path/to/wdjlcli/bin/Debug/net8.0/osx-x64/wdjlcli <命令>
# macOS (Apple Silicon)
/path/to/wdjlcli/bin/Debug/net8.0/osx-arm64/wdjlcli <命令> -->
```

### 2. 店铺切换失败

**问题**：`shop switch` 交互式选择失败

**解决**：直接传入ShopID参数
```
wdjlcli shop switch <shopId>
```

### 3. 上货失败 - 没有匹配到类目

**问题**：商品采集成功但无法上传，提示"没有匹配到类目"

**解决**：设置类目配置
```
wdjlcli config set -k cat.manual -s <店铺ID>
```

### 4. 上货失败 - 属性未能匹配到值

**问题**：提示"属性：XXX未能匹配到值"

**解决**：开启属性自动填充
```
wdjlcli config set -k AttrAutoFillRequired -v true -s <店铺ID>
```

### 5. 上货失败 - 未能找到店铺配置

**问题**：提示"未能找到XXX店的配置，请重新上货"

**解决**：设置运费模板
```
wdjlcli config set -k shop.freight -s <店铺ID>
```

### 6. 添加店铺失败 - 无头浏览器启动失败

**问题**：`shop add` 提示无法下载或启动 Chrome/Chromium

**解决**：
- 检查网络连接，确保可以访问Google服务
- 或手动下载Chrome并放置到缓存目录
- 或配置使用本地已安装的Chrome

### 7. PowerShell中执行登录命令

**问题**：管道输入用户名密码时格式错误

**解决**：使用PowerShell字符串格式
```powershell
"用户名`n密码" | wdjlcli.exe login
```

## 盲区应对

超出上述命令范围的操作（如直接修改数据库、调用未暴露的内部 API、操作非支持平台等），属于**盲区**，按以下顺序回复：

1. **诚实承认**——不装不编，明确告知当前 CLI 不支持该操作
2. **递上已有信息**——提供相关的已知命令或配置
3. **指一条明路**——建议用户查阅 `wdjlcli help`、查看配置目录、或联系技术支持

> 示例："这个操作当前 CLI 还不支持。您可以运行 `wdjlcli help` 查看所有可用命令，或者检查配置目录（Windows: `%APPDATA%/wdjl/`，Linux/macOS: `~/.config/wdjl/`）下的相关文件。如果需要更高级的功能，建议联系万店精灵技术支持。"

**绝对红线**：禁止编造不存在的命令或参数；禁止猜测命令行为；宁少勿错。

## 使用示例

### 示例一：首次登录并添加店铺

> **用户**：我想用万店精灵上货，怎么开始？
>
> **Agent**：好的，先登录您的万店精灵账号。
>
> ```
> wdjlcli login
> ```
>
> 请输入您的用户名和密码完成登录。
>
> **用户**：登录好了，我想添加我的淘宝店铺。
>
> **Agent**：正在添加淘宝店铺，执行后将在控制台显示二维码，请用手机 APP 扫码完成登录，扫码成功后系统自动完成初始化。
>
> ```
> wdjlcli shop add taobao
> ```
>
> 浏览器窗口已打开，请扫码或输入凭证完成淘宝登录。登录成功后工具会自动完成绑定。
>
> **用户**：搞定了。
>
> **Agent**：店铺添加成功。可以用以下命令确认：
>
> ```
> wdjlcli shop list
> ```

### 示例二：商品采集上货

> **用户**：帮我把这个商品采集上架：https://item.taobao.com/item.htm?id=123456
>
> **Agent**：正在创建采集上货任务。
>
> ```
> wdjlcli publish links --url https://item.taobao.com/item.htm?id=123456
> ```
>
> 任务已创建，商品正在采集处理中。您可以用以下命令查看待上传列表：
>
> ```
> wdjlcli publish list
> ```

### 示例三：配置修改

> **用户**：我想看看当前的配置。
>
> **Agent**：
>
> ```
> wdjlcli config list
> ```
>
> **用户**：我想设置运费模板。
>
> **Agent**：运费模板需要交互式选择，执行后请根据提示选择对应的模板。
>
> ```
> wdjlcli config set -k shop.freight -v dummy
> ```

### 示例四：解决属性匹配问题

> **用户**：上货失败，提示属性材质未能匹配
>
> **Agent**：我来帮你开启属性自动填充，这样系统会自动填充必填属性。
>
> ```
> wdjlcli config set -k AttrAutoFillRequired -v true -s <店铺ID>
> ```
>
> 配置完成后，重新上货即可。

### 示例五：店铺互传上货（店铺搬家）

> **用户**：把我 A 店的商品复制到 B 店上架。
>
> **Agent**：好的，先确认两个店铺都已添加并登录，然后执行店铺互传。
>
> ```
> wdjlcli shop list
> wdjlcli publish transfer --sourceshopid <A店ID> --shopid <B店ID>
> ```
>
> 不指定商品 ID 时，会列出 A 店的在售商品供选择后互传；也可以直接指定商品：
>
> ```
> wdjlcli publish transfer --sourceshopid <A店ID> -s <B店ID> -g 123456789,987654321
> ```
>
> 任务已提交到上货队列，可用 `wdjlcli publish list --shopid <B店ID>` 查看进度。

### 示例六：批量修改商品价格

> **用户**：把店铺A所有商品价格统一加 5 元。
>
> **Agent**：好的，先确认店铺ID，然后用 `goodsupdate submit` 提交批量改价任务。改价参数较长，我写入 `price.json` 文件再用 `--options-file` 传入：
>
> ```
> wdjlcli shop list
> wdjlcli goodsupdate submit -s <店铺ID> -t price --options-file price.json
> ```
>
> `price.json` 内容（`PriceItem` 表示按货源价加价，`Operator1Mode=0` 表示加金额）：
>
> ```
> {"PriceMode":2,"PriceItem":{"Operator1Mode":0,"Operator1Value":5}}
> ```
>
> 不指定 `-g|--goodsids` 时为全店商品模式；命令默认会轮询批次进度直到完成。中途如需停止，可另开终端执行：
>
> ```
> wdjlcli goodsupdate cancel -b <批次ID>
> ```

## 注意事项

1. **浏览器登录**：`shop add` 默认使用二维码控制台模式（控制台渲染二维码图片），用户扫码即可完成登录；若平台不支持二维码登录或添加 `--browser` 参数，则会启动浏览器窗口模式（非无头），需要用户在 GUI 窗口中完成登录。Agent 无法代替用户完成扫码或凭证登录。

2. **密码加密**：用户密码通过 EncryptHelper 加密后存储在 AutoLoginConfig.json 中，不会明文保存。

3. **1688 特殊处理**：阿里巴巴 1688 平台存在特殊的 Cookie 处理逻辑（区分 domain 和 path），如遇 1688 店铺登录或操作异常，可能需要重新执行 `shop add ali`。

4. **自动登录**：首次 `login` 成功后，后续启动默认自动登录。如需跳过自动登录，使用 `--no-autologin` 标志。

5. **需登录命令**：`shop *`、`publish *`、`config *`、`goodsupdate *` 系列命令均需先完成登录，未登录时执行会提示错误。

6. **交互式操作**：`cat.manual`（类目选择）和 `shop.freight`（运费模板）涉及多级交互选择，Agent 应提示用户需要手动参与。

7. **属性配置**：遇到属性匹配失败时，优先使用 `AttrAutoFillRequired = true` 开启自动填充，而不是手动配置JSON映射（PowerShell传递中文JSON有编码问题）。

8. **店铺切换**：`shop switch` 必须显式传入ShopID参数，不支持交互式选择。

9. **店铺互传**：`publish transfer` 要求来源店铺与目标店铺均已添加并登录、且订购未过期；来源与目标店铺不能相同，且只互传在售（上架）商品。抖店互传时 CLI 会自动携带 publishId（publishIdMap），无需手动处理。

10. **批量修改批次中断**：`goodsupdate submit` 提交的批次在 CLI 单次进程退出时会被中断并标记为退出取消，长任务请使用 daemon/REPL 模式，或保持默认的 `--wait` 等待到批次终态再退出。

11. 当前 CLI 程序按照标准规范实现，输入命令前可先使用 `wdjlcli <command> -h` 或 `wdjlcli <command> --help` 查看命令参数。

## 上货配置参数参考

详细的上货配置参数说明（商品过滤、基础配置、标题、属性、价格、SKU、图片、水印、平台配置等 12 个类别）请参阅：[CONFIG_REFERENCE.md](./CONFIG_REFERENCE.md)

批量修改参数参考（`goodsupdate submit` 的 `--options` 各类型字段与 JSON 示例）：[BATCH_MODIFY_REFERENCE.md](./BATCH_MODIFY_REFERENCE.md)

当用户需要查询或修改 `config set` 的具体配置项时，请读取该文件获取参数名称、类型、取值范围和 JSON 示例。
