#!/usr/bin/env bash
# astral-skill 安装器 —— 把本仓库的 skill 安装到全局/本地技能目录
# 用法见 ./skill.sh --help 或 README.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="astral"
SOURCE_DIR="$SCRIPT_DIR/skills/$SKILL_NAME"

AGENTS_ROOT="$HOME/.agents/skills"
ZCODE_ROOT="$HOME/.zcode/skills"

usage() {
  cat <<'EOF'
astral-skill 安装器

用法:
  ./skill.sh install [选项]    安装 skill（默认命令，可省略 install）
  ./skill.sh uninstall [选项]  移除已安装的 skill
  ./skill.sh list              列出包含的 skill 与默认安装目标
  ./skill.sh -h | --help       显示本帮助

选项:
  --global        安装到全局（默认）：~/.agents/skills/ 与 ~/.zcode/skills/
  --agents-only   只装 ~/.agents/skills/
  --zcode-only    只装 ~/.zcode/skills/
  --local         安装到当前项目 .agents/skills/（随项目入库）
  --dir <path>    自定义安装根目录（skill 装到 <path>/astral）

示例:
  ./skill.sh                    # 全局安装（推荐）
  ./skill.sh install --local    # 装进当前项目
  ./skill.sh uninstall          # 从全局移除
EOF
}

die() { printf '错误: %s\n' "$1" >&2; exit 1; }

[ -d "$SOURCE_DIR" ] || die "找不到 skill 源目录: $SOURCE_DIR"

MODE="install"
SCOPE="global"
CUSTOM_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    install|uninstall|list) MODE="$1" ;;
    --global) SCOPE="global" ;;
    --agents-only) SCOPE="agents" ;;
    --zcode-only) SCOPE="zcode" ;;
    --local) SCOPE="local" ;;
    --dir)
      shift
      [ $# -gt 0 ] || die "--dir 需要一个路径参数"
      CUSTOM_DIR="$1"
      SCOPE="custom"
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数: $1（--help 查看用法）" ;;
  esac
  shift
done

roots_for() {
  case "$SCOPE" in
    global) printf '%s\n%s\n' "$AGENTS_ROOT" "$ZCODE_ROOT" ;;
    agents) printf '%s\n' "$AGENTS_ROOT" ;;
    zcode)  printf '%s\n' "$ZCODE_ROOT" ;;
    local)  printf '%s\n' "$PWD/.agents/skills" ;;
    custom) printf '%s\n' "$CUSTOM_DIR" ;;
  esac
}

install_one() {
  local root="$1" dest
  dest="$root/$SKILL_NAME"
  mkdir -p "$root"
  if [ -e "$dest" ]; then
    printf '  覆盖   %s\n' "$dest"
    rm -rf "$dest"
  fi
  cp -r "$SOURCE_DIR" "$dest"
  printf '  已安装 %s\n' "$dest"
}

uninstall_one() {
  local root="$1" dest
  dest="$root/$SKILL_NAME"
  if [ -e "$dest" ]; then
    rm -rf "$dest"
    printf '  已移除 %s\n' "$dest"
  else
    printf '  跳过（不存在）%s\n' "$dest"
  fi
}

case "$MODE" in
  list)
    printf 'skill 源: %s\n\n包含文件:\n' "$SOURCE_DIR"
    (cd "$SOURCE_DIR" && find . -type f | sort | sed 's/^/  /')
    printf '\n默认全局目标:\n  %s\n  %s\n' \
      "$AGENTS_ROOT/$SKILL_NAME" "$ZCODE_ROOT/$SKILL_NAME"
    ;;
  install)
    printf '安装 skill「%s」（范围: %s）:\n' "$SKILL_NAME" "$SCOPE"
    roots_for | while IFS= read -r root; do install_one "$root"; done
    printf '完成。新开一个 agent 会话即可加载；验证方法见 README.md。\n'
    ;;
  uninstall)
    printf '移除 skill「%s」（范围: %s）:\n' "$SKILL_NAME" "$SCOPE"
    roots_for | while IFS= read -r root; do uninstall_one "$root"; done
    ;;
esac
