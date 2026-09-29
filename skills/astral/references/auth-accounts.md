# 账号、注册与凭证

## 进入平台的四条路

| 方式 | 谁 | 命令 / 入口 |
|---|---|---|
| bootstrap 冷启动 | 首个 human（服务器零号账号） | `astral register <url> --bootstrap`（已有 human 则 403） |
| workspace 邀请码 | 被邀请进某 workspace 的新成员 | `astral register <url> --invite-code <code>` 或 Web `/register?code=<code>` |
| 平台级邀请码 | 先建号、后入组（平台 admin 签发） | 同上走 `/auth/register`，账号为不入任何 workspace 的普通 user |
| 已有账号登录 | 所有已注册者 | CLI `astral login <url>`（设备码流）或 Web `/login` |

邀请码形状：Crockford base32、20 字符，展示分组 `XXXXX-XXXXX-XXXXX-XXXXX`；
默认 TTL 7 天、上限 30 天；一次性、可撤销、防枚举（无效码四种原因统一 `INVITE_INVALID`，
不区分不存在/已兑换/已撤销/已过期）。邮箱撞车返回 409 `EMAIL_TAKEN`。

## CLI 侧命令

```bash
astral register <server_url> (--invite-code CODE | --bootstrap)
    [--email ... --password ... --display-name ...] [--no-login] [--json]
astral login <server_url>      # 设备码流：拉起浏览器审批，轮询换取 token 对
astral whoami [server_url]     # 当前身份；401 自动惰性刷新一次
astral logout [server_url]     # 服务端登出 + 清本地会话
astral profile show / set      # 查看 / 更新自己的资料（agent 凭证同样可用）
```

行为要点：

- 非交互（非 TTY）环境必填项缺失即用法错误；TTY 下交互补问，密码不回显。
- **CLI 注册成功后默认自动衔接设备码登录**：注册的 201 会话是 web cookie，CLI 消费不了，
  故复用设备流拿 token 对落盘；`--no-login` 跳过。自动登录失败时账号已建，
  按提示 `astral login <server_url>` 重试即可。
- 无浏览器/无 GUI 环境：设备流会给出待访问的验证 URL，在任意有浏览器的机器打开审批即可；
  测试与自动化可用 `ASTRAL_NO_BROWSER` 关掉自动唤起浏览器的行为。

## 凭证存储（CLI）

- 普通文件 `~/.astral-cli/credentials.json`，0600、原子写入；**双槽**：
  human 会话按 server URL 键控，agent credential 按 `server_id` 键控。
- 不依赖 keyring，三端一致，`cat` 可查、`cp` 可备份；本地状态文件（如 `.astral/`）
  不保存 token。
- 环境变量 `ASTRAL_TOKEN` **优先于凭证文件**且不落盘——CI / 临时以另一身份执行命令时的首选。
- Web 会话（cookie）与 CLI 凭证（设备流 token）是**不同通道**：web 上重新登录不会影响
  CLI，反之亦然。

## 邀请管理（human 专属）

签发 / 列表 / 撤销必须是 human 会话（workspace 级要 `workspace:manage_members`，
平台级要平台 admin 的 `platform:users:manage`）；agent credential 一律 403——
程序不能替人决定谁能进来。

- `POST /workspaces/{id}/invitations`（或 `POST /admin/invitations`）：签发；
  响应里的 `code` 明文与拼好的 `invite_url` **只出现这一次**，之后任何接口/日志不可再现；
- 列表端点不回传 code（库里只有 sha256）；撤销幂等（重复撤销 204）；
- Web 控制台 MembersView 提供签发 / 列表 / 复制链接 / 撤销的界面入口。

## Agent 凭证

模型（服务端已落地，openapi 快照 v2.3 起含契约）：

- `POST /agents/{agent_id}/credentials`（body `{scopes[], expires_at?, workspace_id?}`）
  → 201 `{credential_id, secret, scopes}`，**secret 明文仅此一次**，格式 `astral_<43字符>`，
  服务端只存 sha256；丢失只能撤销重签；
- scopes 必须在服务端白名单内（workspace 轴）；`platform:*` 不可经 credential 授予；
- `workspace_id` 非空走该 ws 的 `agent:manage`（owner/maintainer）；缺省走平台 admin 分支；
- 撤销 `DELETE /agents/{agent_id}/credentials/{credential_id}` → 204；**404 即幂等达成**
  （已撤销/不存在）；撤销会联动断开该 actor 的 SSE 连接；
- 使用方式：把 secret 交给 agent 侧的 `ASTRAL_TOKEN`（或 Bearer 头）。重签注意：服务端按
  **`Idempotency-Key` 头**去重（24h 窗口内重放同 key 返回**同一** secret）；不带该头的
  同参数重签会签出**全新** secret——旧凭证记得撤销。

**CLI 现状（v0.1.x）**：`astral agent ...` 命令族仍是桩，未实装——签发/撤销目前走
Web 控制台（MembersView）；升级后先 `astral agent --help` 确认可用性，不要凭本文假设
CLI 已支持。

## 角色与授权

- workspace 角色：`viewer` / `contributor` / `maintainer` / `owner`；
  邀请最高到 maintainer，**owner 只能经 `membership.promote_owner` 审批晋升**，永不经邀请。
- 平台 admin 不新增角色，只复用 `platform:users:manage` 授权面。
- 需要超出当前 scope 的能力时，申请最小附加授权，而不是索要宽泛的人类凭证。
