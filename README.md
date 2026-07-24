# 万店精灵 CLI Skill (wdjl-cli-skill)

让 AI Agent 能够通过 CLI 命令操控万店精灵，实现电商商品采集、上货、店铺管理等自动化操作。

仓库地址：https://github.com/wandianjingling/wdjl-cli-skill

---

## 功能特性

- **认证管理**：登录、登出、状态查看
- **多店铺管理**：添加、删除、切换、列表查看
- **商品采集上货**：多平台商品链接采集、待上货列表管理、批量上货
- **配置管理**：50+ 配置参数，覆盖商品过滤、标题、属性、价格、SKU、图片、水印等
- **Daemon 常驻服务模式**：高效支持批量操作

## 支持平台

**操作系统**

| 系统 | 支持状态 |
|------|----------|
| Windows | 支持 |
| Linux | 支持 |
| macOS | 支持 |

**电商平台**

淘宝、天猫、拼多多、抖音、京东、快手、1688

## 前置条件

- .NET 8.0 运行时
- wdjlcli 可执行文件（从万店精灵官方获取）

## 安装说明

将本 Skill 克隆到对应 AI Agent IDE 的 skills 目录即可激活。

### Qoder IDE

```bash
git clone https://github.com/wandianjingling/wdjl-cli-skill.git .qoder/skills/wdjl-cli-skill
```

### GitHub Copilot

```bash
git clone https://github.com/wandianjingling/wdjl-cli-skill.git .github/skills/wdjl-cli-skill
```

### Claude Code

```bash
git clone https://github.com/wandianjingling/wdjl-cli-skill.git .claude/skills/wdjl-cli-skill
```

## 文件结构

```
wdjl-cli-skill/
├── SKILL.md        # Skill 完整文档（AI Agent 读取的主文件，frontmatter 含 version）
├── skill.json      # Skill 元数据定义（工具声明、参数定义，含 version 字段）
├── CHANGELOG.md    # Skill 版本更新日志
├── README.md       # 本文件
├── LICENSE         # MIT 许可证
├── scripts/        # 安装/更新/卸载脚本（含 Skill 自更新脚本 skill-update.*）
└── .gitignore      # Git 忽略规则
```

## 版本与更新

本 Skill 通过 git clone 安装，因此更新判断与更新操作都基于 git。当前版本记录在 [skill.json](./skill.json) 的 `version` 字段及 [SKILL.md](./SKILL.md) frontmatter 中，变更历史见 [CHANGELOG.md](./CHANGELOG.md)。

> 注意：这里说的是 **Skill 文档本身** 的版本，与 wdjlcli 可执行文件的版本相互独立。

### 查看当前版本

```bash
grep version skill.json
```

### 检查是否有更新（不改动本地）

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/skill-update.ps1 -Check
```

```bash
# Linux / macOS
bash scripts/skill-update.sh --check
```

脚本会执行 `git fetch` 并对比本地与远程，若落后则列出待更新的提交；也可手动执行 `git fetch origin && git status` 查看。

### 更新到最新版本

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File scripts/skill-update.ps1
```

```bash
# Linux / macOS
bash scripts/skill-update.sh
```

更新脚本会检测更新状态、展示更新内容，并在本地无未提交改动时通过 `git pull` 拉取最新版本（等价于手动 `git pull`）。

## 快速开始

安装完成后，AI Agent 会自动读取 Skill 文档并激活相关能力。以下为常用命令示例：

**登录**

```bash
wdjlcli login -u 用户名 -p 密码
```

**查看店铺列表**

```bash
wdjlcli shop list
```

**采集商品**

```bash
wdjlcli publish links --url 商品链接 --shopid 店铺ID
```

**查看待上货列表**

```bash
wdjlcli publish list --shopid 店铺ID
```

## 许可证

[MIT License](./LICENSE)
