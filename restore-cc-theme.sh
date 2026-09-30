#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/codex-cc-skin"
STATE_FILE="$STATE_ROOT/last-install.env"
BACKUP_ASAR="${1:-}"
APP_ASAR_PATH="${2:-${APP_ASAR_PATH:-}}"

if [[ -z "$BACKUP_ASAR" && -f "$STATE_FILE" ]]; then
  # 该文件由安装脚本生成，只包含 shell-escaped 的本地路径。
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  BACKUP_ASAR="${backup_asar:-}"
  APP_ASAR_PATH="${app_asar_path:-$APP_ASAR_PATH}"
fi

[[ -n "$BACKUP_ASAR" && -f "$BACKUP_ASAR" ]] || {
  echo "用法：$SCRIPT_DIR/restore-cc-theme.sh [备份 ASAR] [目标 ASAR]" >&2
  exit 1
}

if [[ -z "$APP_ASAR_PATH" ]]; then
  APP_ASAR_PATH="/usr/lib/chatgpt/resources/app.asar"
fi

app_root="${APP_ASAR_PATH%/resources/app.asar}"
app_binary="$app_root/ChatGPT"
if ps -eo args= | awk -v binary="$app_binary" 'index($0, binary) > 0 { found=1 } END { exit found ? 0 : 1 }'; then
  echo "检测到 Codex 仍在运行，请完全退出后重试。" >&2
  exit 2
fi

APP_OWNER="$(stat -c '%u' "$APP_ASAR_PATH")"
APP_GROUP="$(stat -c '%g' "$APP_ASAR_PATH")"
sudo -A install -o "$APP_OWNER" -g "$APP_GROUP" -m 0644 "$BACKUP_ASAR" "$APP_ASAR_PATH"
echo "已恢复原始 ASAR：$APP_ASAR_PATH"
echo "请重新启动 Codex。"
