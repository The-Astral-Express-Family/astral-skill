# 平台部署与运维（astral-modulator 服务端）

## 部署形态

小型自托管基线：`reverse proxy / TLS → astral-server（单二进制/容器）→ PostgreSQL`。
不要求 Kubernetes。Web 控制台与 API **同源**（webdist 经 go:embed 随二进制分发，
根路径静态服务 + SPA fallback），反代只需转发一个服务。

## 本地开发

仓库根 `docker-compose.yml` 提供 PostgreSQL 17（`localhost:5433`，astral/astral/astral，
用 5433 避开本机已有 PG 的 5432）：

```bash
docker compose up -d
cd server
ASTRAL_DATABASE_DSN='postgres://astral:astral@localhost:5433/astral?sslmode=disable' \
ASTRAL_SERVER_ID='srv_dev_local' \
go run ./cmd/astral-server
```

无数据库也能启动（桩模式）：发现/能力/健康可用，受保护端点（含 SSE）与 readyz 返回
**503 INTERNAL_ERROR**。环境变量全集见 `server/internal/config/config.go`。

## 生产配置（环境变量）

```text
ASTRAL_DATABASE_DSN=postgres://...            # 必填
ASTRAL_PUBLIC_URL=https://astral.example.com  # canonical URL，写入 /.well-known/astral
ASTRAL_SERVER_ID=srv_...                      # 首启后固化进 server_meta，库中值优先
ASTRAL_HTTP_ADDR=:8080
ASTRAL_LOG_LEVEL=info

# 限流（进程内 token bucket，单实例 MVP；超限 429 RATE_LIMITED + Retry-After 头；额度设 0 即禁用）
ASTRAL_RATELIMIT_SENSITIVE_PER_MIN=10   # 敏感桶/min/IP：login/register/refresh/device 授权面
ASTRAL_RATELIMIT_POLL_PER_MIN=60        # 轮询桶/min/IP：device token 交换（CLI 3s 轮询必须容纳）
ASTRAL_RATELIMIT_API_PER_MIN=300        # 通用桶/min/actor：其余 /api/v1
ASTRAL_RATELIMIT_SSE_PER_MIN=30         # SSE 桶/min/actor：events 建连（独立于通用桶）
ASTRAL_TRUSTED_PROXY=false              # true=限流 key 采信 XFF 首跳；仅反代已清洗 XFF 时开
```

Secrets 只走环境变量 / secret manager，不提交配置库。

## 容器镜像

`ghcr.io/the-astral-express-family/astral-modulator`（amd64）；web（npm build）与
server 二进制均在镜像内构建，webdist 同源随镜像分发。标签规则：

| 触发 | 标签 |
|---|---|
| merge main | `dev`、`dev-<短sha>` |
| tag `vX.Y.Z` | `X.Y.Z` / `X.Y` / `X` / `latest` + 自动 GitHub Release |
| 预发布 tag（含 `-`） | 仅完整版本号，不动 `latest` 与移动标签，标 prerelease |

main 的 dev 镜像永不打 latest；GHCR 包默认 private，首次发布后手动改 visibility。
两段式 tag（`v1.2`）不命中触发过滤（`v*.*.*`）压根不会跑 workflow；伪 semver
（`v01.2.3` 之类）才在 validate 步骤被拦。发布操作是人类的活：

```bash
git tag v1.2.3 && git push origin v1.2.3   # 全自动：镜像 + Release
```

## 数据库迁移（goose）

- 版本化 SQL（`server/migrations/`），单调递增、幂等；
- 开发默认 `ASTRAL_AUTO_MIGRATE=true` 随启动执行；**生产多实例必须关闭**，由部署流程
  显式 `goose up`，避免并发实例无协调跑 migration；
- deploy 前备份；forward-only 优先；destructive migration 分两个 release（expand/contract）。

## 健康检查与发现

| 端点 | 语义 |
|---|---|
| `GET /healthz` | 进程存活（无依赖检查） |
| `GET /readyz` | 数据库可达才 200，供 LB 摘除节点 |
| `GET /.well-known/astral` | 协议发现，登录前可匿名访问 |

## Scale-out（达到需要时）

stateless API replicas + managed PostgreSQL + NATS JetStream（多实例事件广播成为需求后）
+ 对象存储 / worker / 集中式可观测。多实例时限流计数需换集中式。

## 协议契约（api/ 是 owner）

- 公网契约 = `api/openapi.yaml` + JSON Schema，是 astral-cli 的唯一耦合点
  （CLI 持协议冻结快照，contract tests 消费）；
- 改协议 → 同步服务端 → 在 modulator `TODO.md` 契约变更登记 → 通知 astral-cli 刷快照；
- 验证：`cd server && go vet ./... && go test ./...`（含契约门）、
  `make openapi-lint`（redocly）、`cd web && npm run build`。
