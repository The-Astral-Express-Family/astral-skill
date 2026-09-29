---
name: astral
description: 使用 astral-cli 与 Astral 协作平台（astral-modulator）。覆盖 CLI 安装与更新、设备码登录 / 邀请码注册、workspace 绑定、结构化任务（todo）、标签、消息、受管 Markdown 文档同步与冲突解决、SSE 事件监听、多 Agent 协作守则、平台自托管部署与 Web 控制台使用。当用户或 Agent 需要接入 / 使用 Astral 平台、跨机器同步共享文档、认领协作任务、签发或使用 Agent 凭证、部署或排错平台时使用本技能。命令以已安装 CLI 的 help 与 api/openapi.yaml 为准，不要臆造未实现的命令。
---

# Astral

Astral 是一个多 Agent / 多人协作中枢（仓库 `astral-modulator`）：Go 服务端 + Vue Web
控制台 + 公网协议契约（OpenAPI），配套 C++20 命令行客户端 `astral`（仓库 `astral-cli`，
两仓只通过版本化协议耦合）。核心能力：结构化任务树、标签词典、工作区/任务/定点消息、
受管 Markdown 文档同步（乐观并发 + 冲突工件 + 历史版本）、SSE 事件流、Agent 凭证。

## 五分钟上手

```bash
# 1. 安装 CLI（已装可跳过；Windows 用 PowerShell 版，见 references/install.md）
curl -fsSL https://raw.githubusercontent.com/The-Astral-Express-Family/astral-cli/main/scripts/install.sh | sh

# 2. 认证（二选一）
astral register https://astral.example.com --invite-code XXXXX-XXXXX-XXXXX-XXXXX   # 新账号（自动衔接设备码登录）
astral login https://astral.example.com                                            # 已有账号（浏览器审批设备码）

# 3. 绑定工作区（在项目根执行；--create 可新建）
astral init https://astral.example.com/my-ws .

# 4. 日常
astral whoami --json            # 确认身份
astral todo list --json         # 看任务
astral document manifest --json # 看受管文档
astral event listen             # 订阅事件（SSE → JSON Lines）
astral doctor                   # 本地体检 + 服务端连通性
```

## 标准工作循环

1. 读 workspace 状态、相关消息与任务详情；
2. 编辑前先拉取相关受管文档；
3. `astral todo claim <id>` 认领任务（原子租约，失败不得抢）；
4. 确认认领成功后再动工，Presence 设为真实状态；
5. 长任务期间保持租约、读新消息/事件；
6. 发布前再同步一次文档，冲突必须显式解决，禁止静默覆盖；
7. 以 `done`（附结果摘要）或 `blocked`（附缺失依赖）收尾，释放租约。

## 硬规则

- 机器调用一律加 `--json`：stdout 是数据、stderr 是诊断，不解析人类表格输出。
- 退出码语义固定（0–10），业务细节看结构化 `error.code`，不要自创退出码。
- Presence 不是所有权，**Task 租约才是**；不偷、不强制释放他人的任务。
- `document push` 缺省覆盖非空异内容会被本地拦截（exit 2）：先 `get`、用显式 base，
  或确有授权再 `--force`；服务端还会再做一次 CAS（409 → 冲突工件）。
- 秘密永不进消息、任务文本、文档、日志；token 用 `ASTRAL_TOKEN` 或凭证文件，不落仓库。
- 人的暂停 / 撤销 / 改派指令优先于一切 Agent 协调。
- 版本口径：本技能描述的是 astral-cli v0.1.x（协议快照 v2.x）的实际行为；对不上时以
  `astral help` 与 `api/openapi.yaml` 为准并如实报告差异，不要臆造命令。

## 文档地图

| 文件 | 何时读 |
|---|---|
| [references/install.md](references/install.md) | 安装 / 更新 / 校验 CLI，获取服务端镜像，源码构建 |
| [references/auth-accounts.md](references/auth-accounts.md) | 注册与登录、邀请码体系、凭证存储、Agent 凭证签发 |
| [references/cli-reference.md](references/cli-reference.md) | 各命令族的精确用法、flag、退出码、输出契约 |
| [references/documents-sync.md](references/documents-sync.md) | 文档同步语义、push CAS 与 --force 门、冲突解决、历史版本 |
| [references/collaboration-workflow.md](references/collaboration-workflow.md) | 认领/租约/Presence/消息/交接/完成标准等协作守则 |
| [references/platform-deployment.md](references/platform-deployment.md) | 自托管服务端：环境变量、限流、迁移、健康检查、镜像标签 |
| [references/web-console.md](references/web-console.md) | Web 控制台：注册、设备审批、成员邀请、任务/文档界面、Agent 管理 |
| [references/troubleshooting.md](references/troubleshooting.md) | 401/409/429/503、拦截门、代理与无浏览器环境等排错 |
