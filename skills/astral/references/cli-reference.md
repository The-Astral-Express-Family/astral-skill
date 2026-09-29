# astral-cli 命令参考（v0.1.x 实装口径）

> 覆盖协议快照 v2.x 的已实现命令。对未知 CLI 版本先 `astral version --json` 与
> `astral help` 核对，再执行；命令缺失时如实报告差异，不要臆造行为。

## 全局约定

- 人类输出带颜色（遵循 `NO_COLOR` 与 TTY 检测）；**`--json` 模式 stdout 恒为单个
  JSON 对象**，进度/诊断走 stderr——Agent/自动化一律加 `--json`。
- stdout 是结果数据、stderr 是诊断日志；有 JSON 时绝不解析人类表格。
- 歧义场景用稳定资源 ID（`tsk_...` / `agt_...`）而非显示名。
- `ASTRAL_TOKEN` 环境变量优先于凭证文件且不落盘。
- 退出码稳定：

| 码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | 一般失败 |
| 2 | 用法错误（含本地 push 拦截门，见 documents-sync.md） |
| 3 | 鉴权/授权失败 |
| 4 | 未找到 |
| 5 | 冲突 |
| 6 | 网络不可达 |
| 7 | 超时 |
| 8 | 本地工作区/同步错误（含非约定位置不可自更新） |
| 9 | 客户端/服务端协议不兼容 |
| 10 | 更新包校验失败 |

业务细节看结构化 `error.code`，不要自创退出码；不要仅凭退出码判断业务结果。
不可自动重试：revision 冲突、scope 不足、任务已被他人认领。

## 认证与身份

```bash
astral login <server_url>       # 设备码流；浏览器审批，轮询换 token 对
astral register <server_url> (--invite-code CODE | --bootstrap)
                                # 注册；成功默认衔接设备码登录，--no-login 跳过
astral whoami [server_url]      # 当前身份；401 自动惰性刷新一次
astral logout [server_url]      # 服务端登出 + 清本地会话
astral profile show             # 自己的资料
astral profile set <fields>     # 更新资料（PATCH /auth/me）
```

## 工作区绑定

```bash
astral init <url>[/<ws>] [path] [--create] [--rebind]
```

- 在项目根执行，写入 `.astral/config.json` 绑定；`--create` 可创建新 workspace；
  `--rebind` 换绑。
- URL 简写 `<url>/<ws>` 直接指向 workspace。
- 后续命令的 workspace 解析优先级：**命令行 flag > 仓库绑定（.astral/）> 环境变量 >
  用户级默认**。多项目机器注意别误继承别的项目的绑定。

## 任务（todo，协议 v2 容器子任务树）

```bash
astral todo list                # 平面查询（支持检索；--json 机器可读）
astral todo add <title>         # 创建任务
astral todo show <id>           # 详情（含子任务/租约/revision）
astral todo claim <id>          # 原子认领，获得租约
astral todo done <id> --summary <text>   # 附结果摘要完结
astral todo search <query>      # 检索
```

- **认领是排他租约**：失败即他人持有，不要重试抢，除非人明确授权接管。
- 认领前先读任务详情与相关消息；`show` 里的 revision/租约状态是判断依据。
- 消息线程可挂到 `task:<id>`（见 msg）。

## 标签（tags，两步确认防重复创建）

```bash
astral tags list
astral tags create <name>            # propose：服务端 pending + 生成确认码
astral tags create <name> --confirm <code>   # 三思后确认才真正创建
astral tags rename <old> <new>
astral tags delete <name>            # 同样走两步确认
```

## 消息（msg）

```bash
astral msg send --workspace <message>    # 工作区广播
astral msg send actor:<id> <message>     # 定点私信
astral msg send task:<id> <message>      # 任务线程
astral msg list [scope]                  # 列出消息/线程
```

消息结构建议：`上下文 → 变更/结果 → 请求的下一步`。只在会改变对方下一步行动时发消息；
Presence 已能表达的信息不要刷屏。**永不**在消息里传凭证/密钥/密码。

## 受管文档（document）

```bash
astral document manifest        # 远端清单（revision/hash），拉取正文前的判据
astral document get <path>      # 取正文（--revision N 可取历史版本）
astral document push <path>     # CAS 写入；缺省覆盖非空异内容被本地拦截（见下）
astral document delete <path>   # tombstone 删除（带 base_revision，可复活）
astral document history <path>  # 服务端版本链（document_versions）
astral document conflicts list | show <id> | resolve <id> <resolution>
```

- 读写语义、`--force` 门、冲突四选一（ours/theirs/merged/manual）、历史保留窗口等
  完整规则见 [documents-sync.md](documents-sync.md)。
- flag 细节（显式 base 的写法等）以 `astral document push --help` 为准。

## 事件（event）

```bash
astral event listen             # SSE → stdout JSON Lines；断线自动续传
```

事件消费按幂等处理：能记游标就从上次处理位置续传；`security.*` 与 `document.updated`
等事件类型用于感知成员变动与文档变更。

## 诊断与维护

```bash
astral doctor                   # 本地体检 + 服务端连通性探测（--json 可读）
astral version [--json]         # 版本信息
astral update [--check] [ver]   # 自更新（仅约定安装位置，见 install.md）
```

排错入口永远是 `astral doctor --json`；常见症状对照 [troubleshooting.md](troubleshooting.md)。

## 未实装 / 桩（截至 v0.1.x）

- `astral agent ...`（agent 凭证签发/撤销）——服务端契约已就绪，CLI 侧待实施；
  当前走 Web 控制台 MembersView。
- 早期设计稿里的 `astral workspace sync/list/create`、`astral document diff/resolve`
  独立合并引擎等**合并命令未实装**——同步以 manifest/get/push 的显式组合为准。
