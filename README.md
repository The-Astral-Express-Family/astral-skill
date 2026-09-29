# astral-skill

Astral 的 Agent 技能包：一个面向 AI coding agent（ZCode / Claude Code / Cursor 等）的
`astral` skill，教 agent 如何**安装与使用 astral-cli**、**接入 Astral 协作平台
（astral-modulator）**，以及**自托管部署**平台。

内容来源：astral-cli v0.1.x（协议快照 v2.x）的实装行为与 astral-modulator 的
docs/（registration / deployment / sync-semantics / architecture 等）。

## 包含的 skill

| skill | 说明 |
|---|---|
| `astral` | 一站式：CLI 安装与更新、设备码登录 / 邀请码注册、workspace 绑定、`todo` / `tags` / `msg` / `document` / `event` 命令族、文档同步与冲突解决、多 Agent 协作守则、平台部署与 Web 控制台使用。入口 [skills/astral/SKILL.md](skills/astral/SKILL.md)，详细文档在其 `references/` 下共 8 篇 |

## 安装

通过 [skills.sh](https://skills.sh) 生态的 skills CLI 安装（需 Node.js）：

```bash
# 全局安装（用户级，所有项目可用）
npx skills add The-Astral-Express-Family/astral-skill -g

# 项目级安装（写 skills-lock.json，装进项目）
npx skills add The-Astral-Express-Family/astral-skill
```

- 仓库已发布到 GitHub 组织（与 astral-cli / astral-modulator 同家族）；离线场景可在
  本仓库根目录用本地路径安装：`npx skills add . -g`。
- 默认把 skill 存到 canonical 目录（全局 `~/.agents/skills/astral`，项目级
  `.agents/skills/astral`），并 symlink/junction 到检测到的各 agent 目录
  （Claude Code、Codex、Cursor、ZCode、OpenCode 等）；`--copy` 改为复制。
- 常用操作：

```bash
npx skills add -l <repo>      # 只列出仓库里可装的 skill，不安装
npx skills add <repo> -g -a pi      # 只装给指定 agent（'*' 为全部检测到的）
npx skills ls -g              # 查看已装 skill 及其 agent 覆盖
npx skills update -g          # 更新到最新版
npx skills remove -g          # 卸载（交互选择）
```

### 验证

```bash
npx skills ls -g                  # 应列出 astral，Agents 一行含 ZCode
ls ~/.agents/skills/astral        # canonical 真身：SKILL.md、references/、agents/
```

新开一个 agent 会话，skill 列表里应出现 `astral`；让它回答「怎么用 astral-cli 登录」
即可冒烟验证。

## 文档地图（skill 的 references/）

| 文件 | 内容 |
|---|---|
| `install.md` | CLI 一键脚本 / `astral update` / 源码构建；服务端 GHCR 镜像与标签 |
| `auth-accounts.md` | bootstrap / 邀请码注册 / 设备码登录；凭证文件双槽；Agent 凭证 |
| `cli-reference.md` | 全命令族参考、`--json` 契约、退出码 0–10 |
| `documents-sync.md` | 三方模型、push CAS 与本地 --force 拦截门、冲突四选一、历史版本 |
| `collaboration-workflow.md` | 认领-租约-心跳-交接-完成标准的协作守则 |
| `platform-deployment.md` | 服务端环境变量、限流、goose 迁移、健康检查、镜像发布规则 |
| `web-console.md` | Web 控制台各页面：注册、设备审批、成员/邀请、任务、文档编辑、Agent 管理 |
| `troubleshooting.md` | 常见错误码与症状 → 原因 → 处置 |

## 版本口径与维护

- skill 描述 astral-cli **v0.1.x**（协议快照 v2.x）与 astral-modulator main 分支行为。
- 上游是两仓的 docs 与 README；本仓库是它们的「agent 使用视角」整合。若与
  `astral help` 或 `api/openapi.yaml` 冲突，**以后者为准**，并欢迎提 PR 修正。
- `astral agent ...` 凭证签发命令族截至 v0.1.x 仍是桩，文档已如实标注。

## License

MIT，见 [LICENSE](LICENSE)。
