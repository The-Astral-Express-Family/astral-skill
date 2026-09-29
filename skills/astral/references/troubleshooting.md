# 排错速查

第一入口永远是 `astral doctor --json`（本地体检 + 服务端连通性探测），其次是
`astral whoami --json` 与 `astral version --json`。

## 按退出码

| 症状 | 原因 | 处置 |
|---|---|---|
| exit 3（401 鉴权失败，刷新后仍失败） | 会话过期/被撤销；web cookie 与 CLI 凭证是**不同通道** | 重新 `astral login`；CI 用 `ASTRAL_TOKEN`（优先级最高、不落盘）；agent 用其 credential secret |
| exit 2 执行 `document push` | 本地拦截门：缺省覆盖非空且不同的远端 | 先 `document get` 对齐；或显式 base；或确有授权 `--force`（见 documents-sync.md） |
| exit 2 其他 | CLI 用法错误 | 看 stderr 提示与 `--help` |
| exit 4 | 资源不存在（账号零权限时资源也 404） | 确认 workspace 绑定与成员身份 |
| exit 5（409 `DOCUMENT_CONFLICT`） | 服务端 CAS 失败，已落冲突工件 | `document conflicts list/show` → `resolve` 四选一 |
| exit 6 | 网络不可达 | 检查 URL/DNS/代理；CLI 尊重 `HTTP_PROXY`/`HTTPS_PROXY`/`NO_PROXY`/`ALL_PROXY`（含小写） |
| exit 7 | 超时 | 重试幂等操作；检查服务端负载 |
| exit 8 执行 `astral update` | 非约定安装位置不可自更新 | 用官方脚本重装到默认位置，或手动覆盖二进制 |
| exit 8 其他 | 本地工作区/同步错误 | 检查 `.astral/` 绑定与目录状态 |
| exit 9 | 客户端/服务端协议不兼容 | 升级 CLI（`astral update`）或核对服务端版本 |
| exit 10 | 更新包 SHA256 校验失败 | 重试下载；排查代理劫持 |

## 按 HTTP 状态 / 错误码

| 症状 | 原因 | 处置 |
|---|---|---|
| 429 `RATE_LIMITED` | 命中限流桶（敏感 10/min/IP、轮询 60/min/IP、通用 300/min/actor、SSE 30/min/actor） | 按 `Retry-After` 头退避；不要并发打授权面 |
| 503（受保护端点/readyz） | 服务端**无数据库桩模式** | 配好 `ASTRAL_DATABASE_DSN` 重启；`/.well-known/astral` 与 healthz 仍可用 |
| 403（邀请管理/设备审批） | agent credential 调 human 专属端点 | 换 human 会话操作；程序不能替人决定谁能进来 |
| `INVITE_INVALID`（400） | 码不存在/已兑换/已撤销/已过期（四因合一防枚举，不可区分） | 让签发方重发新码 |
| `EMAIL_TAKEN`（409） | 邮箱已注册 | 换邮箱或直接 login |

## 环境类

| 症状 | 处置 |
|---|---|
| 无浏览器/SSH 环境 `astral login` | 设备流会给出验证 URL，在任意有浏览器的机器打开 `/device` 审批；自动化测试用 `ASTRAL_NO_BROWSER` 关闭自动唤起 |
| Windows 装完找不到 `astral` | 安装器追加的是用户 PATH，**重开终端**生效 |
| 颜色乱码 | `NO_COLOR=1` |
| 本机已有 PostgreSQL 占 5432 | 开发 compose 映射 **5433**；DSN 用 `localhost:5433` |
| 误继承别的项目的 workspace 绑定 | workspace 解析优先级 flag > `.astral/` 绑定 > env（三层全缺失即报错）；用 flag 显式指定或重新 `astral init` |
| `document push` 想恢复旧版本 | 无恢复写端点：`document get <path> --revision N` 取回旧内容再 push（过 CAS），历史窗口 TTL 30 天/50 版 |
| `astral agent` 命令不存在 | v0.1.x 未实装，签发/撤销走 Web MembersView；升级后先 `--help` 确认 |
| 端到端不对劲 | 先 `astral doctor --json`；服务端侧看 `/healthz`（进程）与 `/readyz`（数据库）分离判断 |
