# 更新日志（Changelog）

本文件记录 **万店精灵 CLI Skill（本文档仓库）** 的版本变更，遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

> 说明：这里记录的是 **Skill 文档（SKILL.md / skill.json 等）** 的版本，与 wdjlcli 可执行文件本身的版本相互独立。
>
> 版本号同时维护在 [skill.json](./skill.json) 的 `version` 字段与 [SKILL.md](./SKILL.md) frontmatter 的 `version` 字段中，两者应保持一致。

版本类型说明：`新增` / `变更` / `修复` / `移除` / `废弃` / `安全`。

## [1.1.1] - 2026-10-06

### 变更

- `publish datapacket` 增强目录导入：目录路径递归扫描所有子目录；数据包文件不再限定 `.txt` 扩展名，格式按内容自动识别；目录中的图片/视频/压缩包等二进制文件与超过 50MB 的文件自动跳过；店铺不存在时退出码由 0 修正为 1。

## [1.1.0] - 2026-10-06

### 新增

- 新增 `publish transfer` 店铺互传上货命令文档（SKILL.md 触发场景、命令小节、使用示例与 skill.json 命令定义）。
- 新增上货配置键文档：`FilterIds`（商品ID过滤）、`RandomModelGenerateEnabled`/`BrandAddRandomCharEnabled`/`RandomSeriesGenerateEnabled`（随机型号/品牌随机字符/随机系列）、`TitleRemoveRange`（标题范围清除，当前版本暂未生效）、`PddSingleBuyPrice`（拼多多单买价）、`ExplainVideoCopy`（拼多多讲解视频）、闲鱼 `XianyuPlatExten` 与拼多多 `VirtualGoodsSpotDeliveryHour` 发货扩展。

### 变更

- `publish links` 文档更新：`--url` 支持完整商品链接与纯商品ID，支持逗号/分号/空格分隔的多个混合输入，来源平台按链接域名自动识别。
- `publish datapacket` 文档补充失败提示与退出码语义（单个文件解析失败打印错误原因；无法识别格式打印警告并跳过；全部无有效商品时以退出码 1 结束）。
- `DelText`（删除详情文字）配置处理器已实现并生效，移除"暂未生效"标注。
- `DetailImgHeight`（详情图高度切片）补充 SplitMode 语义与自定义高度回退说明。

### 修复

- 修正 CONFIG_REFERENCE.md 中全部 `config set` 示例语法：位置参数写法 `config set <KEY> <VALUE> --shopid <店铺ID>` 统一改为选项写法 `config set -k <KEY> -v <VALUE> -s <店铺ID>`。

## [1.0.0] - 2026-07-24

### 新增

- 引入 Skill 版本管理机制：在 `skill.json` 与 `SKILL.md` frontmatter 中新增 `version` 字段。
- 新增 `CHANGELOG.md` 记录 Skill 文档版本变更。
- 新增 Skill 自更新脚本 `scripts/skill-update.ps1`（Windows）与 `scripts/skill-update.sh`（Linux/macOS），用于检测更新状态并通过 git 拉取最新版本。

### 说明

- 首个正式标记版本，整理已有的登录、店铺管理、商品采集上货、配置管理、Daemon 模式等命令文档。
