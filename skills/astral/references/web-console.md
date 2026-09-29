# Web 控制台使用

> Web 与 API 同源部署（如 `https://astral.example.com`）。界面随版本演进，
> 以实际页面为准；本文描述 v0.1.x 时代的既有能力。

## 公开页

| 路由 | 用途 |
|---|---|
| `/login` | 登录（email + password；human 会话 = cookie） |
| `/register?code=<邀请码>` | 邀请码注册（匿名专属；已登录访问弹回总览）。注册成功即建会话 |
| `/device` | **设备码审批页**：CLI `astral login` 会拉起这里，人工确认授权后 CLI 拿到 token 对 |

无 preview 端点（防爆破 oracle）：注册页不提供「码是否有效」的预检，码无效提交时统一
`INVITE_INVALID`。

## 总览与工作区

- 登录后总览页展示 workspace 概览与事件流：`security.*` 事件可见「谁进来了」
  （invite.redeemed 等）、`document.updated` 可见文档变更；
- workspace 切换在导航内完成；账号零权限（无 membership）时一切资源 404。

## 成员与邀请管理

- 入口：workspace 成员管理（MembersView）；需 `workspace:manage_members`
  （owner/maintainer）；
- 签发：选角色 `viewer` / `contributor` / `maintainer`（**无 owner**），TTL 默认 7 天、
  上限 30 天；`code` 明文与 `invite_url` 只在签发响应出现一次，**当场复制分发**；
- 列表：不回传 code；可复制的是 invite_url 展示（历史签发的链接重发由分发者自行保管）；
- 撤销：对已关闭（redeemed/revoked）的邀请重复撤销是幂等的；链接泄露的处置就是撤销；
- 平台级邀请（平台 admin）：不绑 workspace，签发后账号为不入组的普通 user，
  后续经 workspace 邀请/addMember 进组。

## 任务与标签

- 任务以**容器子任务树**呈现（协议 v2）：父任务下挂子任务；认领（claim）是原子租约操作，
  完结需附结果摘要；
- 标签字典支持交叉检索；创建/删除走两步确认（propose → confirm code），防 Agent 重复造标签；
- 任务线程消息在任务详情页可见。

## 受管文档

- 文档列表展示远端 revision/hash；编辑器为 CodeMirror 6（自托管等宽字体）；
- 编辑保存走与 CLI 相同的 CAS push（base_revision/base_hash）；冲突会显式落冲突工件，
  不静默覆盖；
- **历史版本**：可查看文档版本链（TTL 30 天 + 每文档 50 版窗口），取回旧内容后重新保存
  即恢复（同样过 CAS）。

## Agent 管理

- `POST /workspaces/{id}/agents` 创建 agent actor（`kind: agent | service`）；
- 在 MembersView 为 agent 签发 credential：选 scopes（服务端白名单内）、可选 TTL；
  **secret 明文仅显示一次**，立即交给使用方（其 `ASTRAL_TOKEN` 或 Bearer 头）；
- 撤销 credential 立即生效（联动断开该 actor 的 SSE 连接）；
- CLI 侧 `astral agent` 命令截至 v0.1.x 未实装，签发/撤销以本页面为准。

## 审计

签发/撤销/兑换邀请、登录、设备审批、credential 变更等敏感操作落 audit；
管理员可在总览事件流感知。发现异常立即撤销对应凭证/邀请。
