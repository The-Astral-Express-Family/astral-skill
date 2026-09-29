# astral-skill

Astral 的 Agent 技能包：一个面向 AI coding agent（ZCode / Claude 等）的 `astral` skill，
教 agent 如何**安装与使用 astral-cli**、**接入 Astral 协作平台（astral-modulator）**，
以及**自托管部署**平台。

内容来源：astral-cli v0.1.x（协议快照 v2.x）的实装行为与 astral-modulator 的
docs/（registration / deployment / sync-semantics / architecture 等）。

## 包含的 skill

| skill | 说明 |
|---|---|
| `astral` | 一站式：CLI 安装与更新、设备码登录 / 邀请码注册、workspace 绑定、`todo` / `tags` / `msg` / `document` / `event` 命令族、文档同步与冲突解决、多 Agent 协作守则、平台部署与 Web 控制台使用。入口 [skills/astral/SKILL.md](skills/astral/SKILL.md)，详细文档在其 `references/` 下共 8 篇 |

## 安装

### skill.sh（推荐）

需要 bash（Linux / macOS 自带；Windows 用 Git Bash）。在仓库根执行：

```bash
./skill.sh                  # 全局安装：~/.agents/skills/astral 与 ~/.zcode/skills/astral
```

全部命令与选项：

```bash
./skill.sh install          # 同上，全局安装（默认命令，可省略 install）
./skill.sh install --local  # 安装到当前项目 .agents/skills/astral（随项目入库）
./skill.sh --agents-only    # 只装 ~/.agents/skills/
./skill.sh --zcode-only     # 只装 ~/.zcode/skills/
./skill.sh --dir /some/root # 装到 <root>/astral
./skill.sh uninstall        # 从对应范围移除（选项同 install）
./skill.sh list             # 列出 skill 内容与默认安装目标
./skill.sh --help
```

重复执行即覆盖更新（先 `git pull` 本仓库再重跑一遍即可升级）。

### 手动安装

不想跑脚本的话，把 `skills/astral/` 整个目录拷到任一技能目录并保持目录名 `astral`：

```bash
mkdir -p ~/.agents/skills
cp -r skills/astral ~/.agents/skills/astral
```

### 验证

```bash
ls ~/.agents/skills/astral          # 应看到 SKILL.md、references/、agents/
ls ~/.zcode/skills/astral
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
