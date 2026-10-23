#!/usr/bin/env bash
# lansenger CLI 自动安装脚本（幂等，已装则秒退）
# 用法：bash scripts/setup.sh
# 按 pip → pipx → npm → go 顺序尝试，装完自动验证。

set -uo pipefail

# 已装则直接退出
if command -v lansenger >/dev/null 2>&1; then
  echo "✓ lansenger 已安装：$(lansenger --version 2>/dev/null | head -1)"
  exit 0
fi

echo "… lansenger 未检测到，开始自动安装"

# 1. Python pip（推荐）
for pip in pip3 pip; do
  if command -v "$pip" >/dev/null 2>&1; then
    echo "→ 尝试 $pip install lansenger-cli"
    if "$pip" install --quiet lansenger-cli 2>/dev/null \
       || "$pip" install --user --quiet lansenger-cli 2>/dev/null; then
      echo "  $pip 安装完成"
      break
    else
      echo "  $pip 安装失败（可能是 externally-managed 环境），换下一渠道"
    fi
  fi
done

# 2. pipx（venv 隔离，绕开 PEP 668）
if ! command -v lansenger >/dev/null 2>&1 && command -v pipx >/dev/null 2>&1; then
  echo "→ 尝试 pipx install lansenger-cli"
  pipx install lansenger-cli 2>/dev/null || echo "  pipx 安装失败"
fi

# 3. npm
if ! command -v lansenger >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  echo "→ 尝试 npm install -g lansenger-cli"
  npm install -g --silent lansenger-cli 2>/dev/null || echo "  npm 安装失败（可能是权限不足）"
fi

# 4. go
if ! command -v lansenger >/dev/null 2>&1 && command -v go >/dev/null 2>&1; then
  echo "→ 尝试 go install lansenger"
  go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest 2>/dev/null \
    || echo "  go 安装失败"
fi

# --user / pipx 装到 ~/.local/bin，若不在 PATH 给出提示
if ! command -v lansenger >/dev/null 2>&1; then
  for extra in "$HOME/.local/bin" "$HOME/go/bin"; do
    if [ -x "$extra/lansenger" ]; then
      echo "  检测到 $extra/lansenger，但该目录不在 PATH"
      echo "  请把这行加入 ~/.zshrc 或 ~/.bashrc 后重开终端："
      echo "    export PATH=\"$extra:\$PATH\""
      break
    fi
  done
fi

# 验证
if command -v lansenger >/dev/null 2>&1; then
  echo "✓ 安装成功：$(lansenger --version 2>/dev/null | head -1)"
  echo "  下一步：按 docs/setup-for-ai-agents.md Step 2 配置凭证"
  exit 0
fi

echo "✗ 自动安装失败。手动安装任选其一："
echo "  pip install lansenger-cli"
echo "  pipx install lansenger-cli"
echo "  npm install -g lansenger-cli"
echo "  go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest"
echo "  完整指引见 docs/setup-for-ai-agents.md"
exit 1
