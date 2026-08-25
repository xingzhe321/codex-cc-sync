#!/usr/bin/env bash
set -euo pipefail

PACKAGE_VERSION="codex-cc-skin-v23-startup-persist"
ASAR_ASSET="app.asar.cc-skin-v23-startup-persist"
PET_JSON_ASSET="pet-c-c.json"
PET_SPRITESHEET_ASSET="pet-c-c-spritesheet.webp"
PET_ID="c-c"
EXPECTED_ASAR_SHA256="c0623967d61bf1f5a2a6fd4d5a9778899d36b78e020f7b6eff3c9dc31a9f877b"
EXPECTED_ASAR_BYTES="292581104"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASAR_FILE="${CC_SYNC_ASAR_FILE:-}"
PET_SOURCE_DIR="${CC_SYNC_PET_DIR:-}"
RELEASE_BASE_URL="${CC_SYNC_BASE_URL:-}"
APP_ASAR_PATH="${APP_ASAR_PATH:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
TEMP_DIR=""

usage() {
  cat <<'EOF'
用法：
  ./install-cc-theme-pet.sh --release-base-url URL
  ./install-cc-theme-pet.sh --asar-file FILE --pet-dir DIR

环境变量：
  CC_SYNC_BASE_URL   GitHub Release 下载目录，例如
                     https://github.com/OWNER/REPO/releases/latest/download
  GITHUB_TOKEN       私有 Release 使用；不要写入脚本或仓库
  APP_ASAR_PATH      覆盖目标机 app.asar 路径

本地安装示例：
  ./install-cc-theme-pet.sh \
    --asar-file /path/to/app.asar.cc-skin-v23-startup-persist \
    --pet-dir /path/to/outputs/cc-pet
EOF
}

die() {
  echo "错误：$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -f "$TEMP_DIR/$ASAR_ASSET" "$TEMP_DIR/$PET_JSON_ASSET" "$TEMP_DIR/$PET_SPRITESHEET_ASSET"
    rmdir "$TEMP_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

download_asset() {
  local url="$1"
  local output="$2"
  local -a curl_args=(-fsSL --retry 3 --connect-timeout 15)
  if [[ -n "$GITHUB_TOKEN" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl_args+=(-H "Accept: application/octet-stream")
  fi
  command -v curl >/dev/null 2>&1 || die "远程安装需要 curl。"
  curl "${curl_args[@]}" "$url" -o "$output"
}

find_default_app_asar() {
  local candidate
  for candidate in \
    "/usr/lib/chatgpt/resources/app.asar" \
    "/opt/chatgpt/resources/app.asar"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if command -v chatgpt >/dev/null 2>&1; then
    local launcher resolved
    launcher="$(command -v chatgpt)"
    resolved="$(readlink -f "$launcher" 2>/dev/null || true)"
    if [[ -n "$resolved" ]]; then
      candidate="$(dirname "$resolved")/resources/app.asar"
      if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  fi

  return 1
}

assert_app_quit() {
  local app_root app_binary
  app_root="${APP_ASAR_PATH%/resources/app.asar}"
  app_binary="$app_root/ChatGPT"
  if ps -eo args= | awk -v binary="$app_binary" 'index($0, binary) > 0 { found=1 } END { exit found ? 0 : 1 }'; then
    die "检测到 Codex 仍在运行。请使用“文件 → 退出”完全退出后重新执行。"
  fi
}

verify_asar() {
  [[ -f "$ASAR_FILE" ]] || die "找不到主题 ASAR：$ASAR_FILE"
  local actual_hash actual_bytes
  actual_hash="$(sha256sum "$ASAR_FILE" | awk '{print $1}')"
  actual_bytes="$(stat -c '%s' "$ASAR_FILE")"
  [[ "$actual_hash" == "$EXPECTED_ASAR_SHA256" ]] || die "主题包 SHA256 不匹配：$actual_hash"
  [[ "$actual_bytes" == "$EXPECTED_ASAR_BYTES" ]] || die "主题包字节数不匹配：$actual_bytes"
}

verify_pet() {
  [[ -f "$PET_SOURCE_DIR/$PET_JSON_ASSET" || -f "$PET_SOURCE_DIR/pet.json" ]] || die "找不到 C.C. pet.json。"
  [[ -f "$PET_SOURCE_DIR/$PET_SPRITESHEET_ASSET" || -f "$PET_SOURCE_DIR/spritesheet.webp" ]] || die "找不到 C.C. spritesheet.webp。"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --asar-file)
      [[ $# -ge 2 ]] || die "--asar-file 缺少参数。"
      ASAR_FILE="$2"
      shift 2
      ;;
    --pet-dir)
      [[ $# -ge 2 ]] || die "--pet-dir 缺少参数。"
      PET_SOURCE_DIR="$2"
      shift 2
      ;;
    --release-base-url)
      [[ $# -ge 2 ]] || die "--release-base-url 缺少参数。"
      RELEASE_BASE_URL="${2%/}"
      shift 2
      ;;
    --app-asar)
      [[ $# -ge 2 ]] || die "--app-asar 缺少参数。"
      APP_ASAR_PATH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1"
      ;;
  esac
done

if [[ -n "$RELEASE_BASE_URL" ]]; then
  [[ -z "$ASAR_FILE" && -z "$PET_SOURCE_DIR" ]] || die "远程模式不能同时指定本地文件。"
  TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-cc-sync.XXXXXX")"
  ASAR_FILE="$TEMP_DIR/$ASAR_ASSET"
  PET_SOURCE_DIR="$TEMP_DIR/pet"
  mkdir -p "$PET_SOURCE_DIR"
  echo "正在从 Release 下载 v23 主题和 C.C. 宠物…"
  download_asset "$RELEASE_BASE_URL/$ASAR_ASSET" "$ASAR_FILE"
  download_asset "$RELEASE_BASE_URL/$PET_JSON_ASSET" "$PET_SOURCE_DIR/$PET_JSON_ASSET"
  download_asset "$RELEASE_BASE_URL/$PET_SPRITESHEET_ASSET" "$PET_SOURCE_DIR/$PET_SPRITESHEET_ASSET"
else
  [[ -n "$ASAR_FILE" ]] || ASAR_FILE="$SCRIPT_DIR/assets/$ASAR_ASSET"
  [[ -n "$PET_SOURCE_DIR" ]] || PET_SOURCE_DIR="$SCRIPT_DIR/assets/pet/$PET_ID"
fi

if [[ -z "$APP_ASAR_PATH" ]]; then
  APP_ASAR_PATH="$(find_default_app_asar || true)"
fi
[[ -n "$APP_ASAR_PATH" && -f "$APP_ASAR_PATH" ]] || die "找不到目标 Codex app.asar；请用 APP_ASAR_PATH 或 --app-asar 指定。"

if [[ -f "$PET_SOURCE_DIR/$PET_JSON_ASSET" ]]; then
  PET_JSON_FILE="$PET_SOURCE_DIR/$PET_JSON_ASSET"
else
  PET_JSON_FILE="$PET_SOURCE_DIR/pet.json"
fi
if [[ -f "$PET_SOURCE_DIR/$PET_SPRITESHEET_ASSET" ]]; then
  PET_SPRITESHEET_FILE="$PET_SOURCE_DIR/$PET_SPRITESHEET_ASSET"
else
  PET_SPRITESHEET_FILE="$PET_SOURCE_DIR/spritesheet.webp"
fi

verify_asar
verify_pet
grep -Eq '"spriteVersionNumber"[[:space:]]*:[[:space:]]*2' "$PET_JSON_FILE" || die "宠物不是 Codex v2 格式。"
grep -Eq '"spritesheetPath"[[:space:]]*:[[:space:]]*"spritesheet.webp"' "$PET_JSON_FILE" || die "pet.json 没有指向 spritesheet.webp。"
assert_app_quit

STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/codex-cc-skin"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$STATE_ROOT/backups"
PET_BACKUP_DIR="$STATE_ROOT/pet-backups/$STAMP"
mkdir -p "$BACKUP_DIR"
BACKUP_ASAR="$BACKUP_DIR/app.asar.before-$STAMP"
sudo -A install -o "$(id -u)" -g "$(id -g)" -m 0644 "$APP_ASAR_PATH" "$BACKUP_ASAR"

PET_ROOT="${CODEX_HOME:-$HOME/.codex}/pets/$PET_ID"
if [[ -e "$PET_ROOT" ]]; then
  mkdir -p "$PET_BACKUP_DIR"
  cp -a "$PET_ROOT" "$PET_BACKUP_DIR/$PET_ID"
fi

sudo -A install -o root -g root -m 0644 "$ASAR_FILE" "$APP_ASAR_PATH"
mkdir -p "$PET_ROOT"
install -m 0644 "$PET_JSON_FILE" "$PET_ROOT/pet.json"
install -m 0644 "$PET_SPRITESHEET_FILE" "$PET_ROOT/spritesheet.webp"

cat > "$STATE_ROOT/last-install.env" <<EOF
package_version=$(printf '%q' "$PACKAGE_VERSION")
app_asar_path=$(printf '%q' "$APP_ASAR_PATH")
backup_asar=$(printf '%q' "$BACKUP_ASAR")
pet_root=$(printf '%q' "$PET_ROOT")
installed_at=$(printf '%q' "$STAMP")
EOF
chmod 600 "$STATE_ROOT/last-install.env"

FINAL_HASH="$(sha256sum "$APP_ASAR_PATH" | awk '{print $1}')"
[[ "$FINAL_HASH" == "$EXPECTED_ASAR_SHA256" ]] || die "安装后哈希校验失败：$FINAL_HASH"
[[ -f "$PET_ROOT/pet.json" && -f "$PET_ROOT/spritesheet.webp" ]] || die "宠物文件安装不完整。"

echo "安装完成：$PACKAGE_VERSION"
echo "主题：$APP_ASAR_PATH"
echo "宠物：$PET_ROOT"
echo "备份：$BACKUP_ASAR"
echo "恢复：$SCRIPT_DIR/restore-cc-theme.sh"
echo "请重新启动 Codex。"
