# 更新日志（Changelog）

本文件记录 **万店精灵 CLI Skill（本文档仓库）** 的版本变更，遵循 [语义化版本](https://semver.org/lang/zh-CN/) 规范。

> 说明：这里记录的是 **Skill 文档（SKILL.md / skill.json 等）** 的版本，与 wdjlcli 可执行文件本身的版本相互独立。
>
> 版本号同时维护在 [skill.json](./skill.json) 的 `version` 字段与 [SKILL.md](./SKILL.md) frontmatter 的 `version` 字段中，两者应保持一致。

版本类型说明：`新增` / `变更` / `修复` / `移除` / `废弃` / `安全`。

## [未发布]

## [1.0.0] - 2026-07-24

### 新增

- 引入 Skill 版本管理机制：在 `skill.json` 与 `SKILL.md` frontmatter 中新增 `version` 字段。
- 新增 `CHANGELOG.md` 记录 Skill 文档版本变更。
- 新增 Skill 自更新脚本 `scripts/skill-update.ps1`（Windows）与 `scripts/skill-update.sh`（Linux/macOS），用于检测更新状态并通过 git 拉取最新版本。

### 说明

- 首个正式标记版本，整理已有的登录、店铺管理、商品采集上货、配置管理、Daemon 模式等命令文档。
