# 安装、更新与构建

## 渠道优先级

1. 一键安装脚本（官方发布产物）；
2. `astral update` 自更新（已装 CLI 时）；
3. 源码构建（开发场景）。

brew / winget / scoop 渠道**计划中，尚未发布**——不要臆造包名 / tap / bucket；
发现渠道存在前一律走脚本或源码构建。

## 一键安装

Linux / macOS（POSIX sh）：

```bash
curl -fsSL https://raw.githubusercontent.com/The-Astral-Express-Family/astral-cli/main/scripts/install.sh | sh
```

Windows（PowerShell 5.1+）：

```powershell
powershell -c "iwr -useb https://raw.githubusercontent.com/The-Astral-Express-Family/astral-cli/main/scripts/install.ps1 | iex"
```

要点：

- 安装位置：POSIX `~/.local/bin/astral`；Windows `%LOCALAPPDATA%\Programs\astral\astral.exe`
  （自动追加用户 PATH，**重开终端生效**）。
- 装指定版本：`ASTRAL_VERSION=v0.2.1 sh install.sh`（PowerShell：`$env:ASTRAL_VERSION='v0.2.1'`）。
- 自定义 POSIX 目录：`ASTRAL_INSTALL_DIR=/custom/bin sh install.sh`——非约定位置**不可
  `astral update` 自更新**（见下）。
- 依赖仅 curl/tar/sha256sum（POSIX）或系统 PowerShell cmdlet（Windows）；代理自动识别
  `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` / `ALL_PROXY`（含小写），Windows 版遵循系统代理。
- 默认「latest」走 GitHub API：代理出口 IP 被限流（`API rate limit exceeded`）时脚本会失败；
  用 `ASTRAL_VERSION=v0.1.1-alpha.5` 钉版本（走 release 下载而非 API）即可绕开。

## 更新（astral update）

```bash
astral update              # 升级到最新 release
astral update v0.2.1       # 安装指定版本（支持降级回滚）
astral update --check      # 只查询不安装
```

- 仅约定安装位置（`~/.local/bin`、`%LOCALAPPDATA%\Programs\astral`）可自更新；
  源码构建 / 自定义位置会得到退出码 **8** 的明确提示。
- 下载后强制 SHA256 校验（对 SHA256SUMS.txt），失配退出码 **10**。

## 安装后验证

```bash
astral version --json
astral doctor --json
```

至少确认：二进制可启动、版本 / 架构符合预期、服务端配置明确、TLS/DNS 可达、
当前 workspace 不是从别的项目误继承的。

## 源码构建

仅在无预构建产物或开发 CLI 时使用。要求：CMake ≥ 3.25、Ninja、C++20 编译器
（GCC 11+ / Clang 14+ / MSVC 19.30+）、vcpkg（manifest 模式，`VCPKG_ROOT` 指向 vcpkg）。

```bash
cmake --preset dev && cmake --build --preset dev && ctest --preset dev   # 日常开发
cmake --preset release && cmake --build --preset release                 # 发布构建
cmake --preset system && cmake --build --preset system                   # Linux 免 vcpkg（系统库）
```

| Preset | 用途 |
| --- | --- |
| `dev` | Debug + 单测 |
| `release` | Release、无测试 |
| `ci` | CI 同款（Release、测试、`-Werror`） |
| `asan` | dev + ASan/UBSan |
| `system` | Linux 用系统库快速构建 |

Windows 注意：本地 vcpkg 构建必须与 CI / 发行同款加
`-DVCPKG_TARGET_TRIPLET=x64-windows-static`（静态 CRT + 静态第三方库，单 exe 自包含），
动态链接产物会被 CI 的静态断言拒绝。无 MSVC/vcpkg 的机器也可用 msys2 ucrt64
系统依赖构建（Catch2 包名为 `catch`），产物仅限本机调试。

## 服务端镜像（自托管取用）

镜像 `ghcr.io/the-astral-express-family/astral-modulator`（amd64），由 modulator 仓
docker.yml 发布，webdist 同源打进镜像：

| 触发 | 标签 |
|---|---|
| merge 到 main | `dev`（滚动）、`dev-<短sha>`（可回溯） |
| tag `v1.2.3` | `1.2.3`、`1.2`、`1`、`latest` + 自动 GitHub Release |
| tag `v1.2.3-rc.1` | 仅 `1.2.3-rc.1`（预发布不动 `latest` 与移动标签） |

- GHCR 包默认 private，首次发布后需在 package settings 手动改 visibility。
- 镜像名全小写；`VERSION` build-arg 随触发源写入 OCI label。
- 部署与配置见 [platform-deployment.md](platform-deployment.md)。
