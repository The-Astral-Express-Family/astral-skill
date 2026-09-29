# 受管文档同步语义

> 权威口径：modulator 仓 `docs/sync-semantics.md`（Accepted）与 `api/openapi.yaml`
> documents 段。本文是 agent 使用视角的整合。

## 范围

只同步明确纳入 Astral 管理的 UTF-8 Markdown/text 文件。不做二进制、不做 git 对象库、
不做实时多人光标 / CRDT。**Astral 与 Git 正交**：Astral revision 管协作中枢的并发，
Git 管源码版本；不自动执行 git add/commit/push。

include/exclude 是**客户端约定**（`.astral/` 配置持有，服务端不解析）；服务端侧防线是
保留前缀黑名单（`.git/`、`.astral/`、`secrets/`、`.env*` 等）+ push 时大小写冲突检测。
绝对路径、`..`、NUL、symlink 逃逸一律拒绝。

## 三方模型

对每个文档比较：`B` = 上次同步 base、`L` = 当前本地、`R` = 当前远端。

| 情况 | 判定 | 动作 |
|---|---|---|
| L==B && R==B | 无变化 | — |
| L!=B && R==B | 仅本地变 | push |
| L==B && R!=B | 仅远端变 | pull（get） |
| L!=B && R!=B | 双边变 | 客户端合并或落冲突，**服务端不做自动合并** |

hash 为 `sha256:<hex>`，对实际 UTF-8 bytes 计算，**不自动改写换行**。

## push 的两道门

1. **本地拦截门（CLI，5c32909 起）**：缺省 push 覆盖「非空且内容不同」的远端时，
   本地直接拦截（退出码 2），提示三条豁免路径：
   先 `document get` 对齐远端；用显式 base（pinned base，flag 写法以
   `astral document push --help` 为准）；或确有授权时 `--force`。
   显式 base、同内容、空远端不拦。
2. **服务端 CAS**：push 带 `base_revision` + `base_hash`；服务端校验权限/路径/hash 后
   比对当前 revision——不一致返回 **409 `DOCUMENT_CONFLICT`** 并落冲突工件
   （返回体带 `conflict_id` / `current_revision` / `current_hash`）。

## 冲突处理

```bash
astral document conflicts list
astral document conflicts show <id>     # 对比双方
astral document conflicts resolve <id> ours|theirs|merged|manual
```

- 四种解决：保留本地（ours）/ 接受远端（theirs）/ 提交合并结果（merged）/ 手工（manual）。
- 服务端一律落冲突工件 + 409，把合并决策留给客户端/人；`resolve(merged|manual)`
  提交合并内容。
- 红线：**不得仅因「我的版本更新」就无条件覆盖**；本地当前版本不会被自动破坏。
- edit-vs-delete / delete-vs-edit 双边变化一律落冲突工件。

## 删除与复活

- `document delete` 带 `base_revision` 落 tombstone（行保留、deleted=true、revision+1、
  `document.updated` 事件 data.deleted=true）；重复删除幂等 204；
- 对已 tombstone 的路径以 `base_revision=0` push 视为**复活**（revision 续增）；
- manifest 默认排除 tombstone。

## 历史版本（round 41 起，migration 00017）

- 内容被取代（push 快进 / resolve 落地 / 复活 / tombstone）前，同事务归档全量快照；
- 保留窗口：TTL 默认 30 天 + 每文档上限 50 版，先到即剪；
- CLI 读侧：`astral document history <path>`、`astral document get <path> --revision N`；
- **恢复不设写端点**：取回旧内容后走 push + pinned base，恢复操作本身也过 CAS。
- 存在意义：防「盲推静默覆盖」的恢复面——预防（拦截门）+ 恢复（历史链）两侧齐备。

## 建议的同步流程

```bash
astral document manifest --json     # 1. 拉远端清单
# 2. 与本地逐路径分类（无变/仅本地/仅远端/双边）
astral document get <path>          # 3. 仅远端变的拉回
astral document push <path>         # 4. 仅本地变的推上去
# 5. 双边变的：本地合并 → push（新 base）；无法安全合并 → conflicts 流程
```

单个文件冲突不必回滚其他文件的成功同步，但要如实报告 partial-success 结果。
