# lansenger CLI 自动安装脚本（Windows，幂等，已装则秒退）
# 用法：powershell -ExecutionPolicy Bypass -File scripts/setup.ps1

if (Get-Command lansenger -ErrorAction SilentlyContinue) {
  Write-Host "✓ lansenger 已安装：$(lansenger --version 2>$null | Select-Object -First 1)"
  exit 0
}

Write-Host "… lansenger 未检测到，开始自动安装"

# 1. pip
if (Get-Command pip -ErrorAction SilentlyContinue) {
  Write-Host "→ 尝试 pip install lansenger-cli"
  pip install lansenger-cli
  if (Get-Command lansenger -ErrorAction SilentlyContinue) { }
}

# 2. pipx
if (-not (Get-Command lansenger -ErrorAction SilentlyContinue) -and (Get-Command pipx -ErrorAction SilentlyContinue)) {
  Write-Host "→ 尝试 pipx install lansenger-cli"
  pipx install lansenger-cli
}

# 3. npm
if (-not (Get-Command lansenger -ErrorAction SilentlyContinue) -and (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Host "→ 尝试 npm install -g lansenger-cli"
  npm install -g lansenger-cli
}

# 4. go
if (-not (Get-Command lansenger -ErrorAction SilentlyContinue) -and (Get-Command go -ErrorAction SilentlyContinue)) {
  Write-Host "→ 尝试 go install lansenger"
  go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
}

if (Get-Command lansenger -ErrorAction SilentlyContinue) {
  Write-Host "✓ 安装成功：$(lansenger --version 2>$null | Select-Object -First 1)"
  Write-Host "  下一步：按 docs/setup-for-ai-agents.md Step 2 配置凭证"
  exit 0
}

Write-Host "✗ 自动安装失败。手动安装任选其一："
Write-Host "  pip install lansenger-cli"
Write-Host "  pipx install lansenger-cli"
Write-Host "  npm install -g lansenger-cli"
Write-Host "  go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest"
Write-Host "  完整指引见 docs/setup-for-ai-agents.md"
exit 1
