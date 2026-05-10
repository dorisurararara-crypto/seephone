#!/usr/bin/env bash
# Mac 첫 셋업 — ~/.claude/CLAUDE.md + memory 폴더를 .claude-shared 로 연결
#
# 안전: 기존 파일은 항상 .bak.<timestamp> 로 백업한 뒤 작업.
# 재실행 OK (idempotent).

set -euo pipefail

SHARED_DIR="$(cd "$(dirname "$0")" && pwd)"
TS=$(date +%Y%m%d-%H%M%S)

echo "==> .claude-shared = $SHARED_DIR"

# --- 1. 글로벌 CLAUDE.md 를 @import 두 줄로 치환 ----------------------------
GLOBAL_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$HOME/.claude"

if [ -f "$GLOBAL_MD" ] && [ ! -L "$GLOBAL_MD" ]; then
  cp "$GLOBAL_MD" "$GLOBAL_MD.bak.$TS"
  echo "==> 기존 ~/.claude/CLAUDE.md 백업: $GLOBAL_MD.bak.$TS"
fi

cat > "$GLOBAL_MD" <<EOF
# Auto-loaded from $SHARED_DIR
# 이 파일은 bootstrap-mac.sh 가 관리합니다. 직접 수정하지 마세요.
# 운영 룰 변경은 .claude-shared/global.md (또는 global-mac.md) 에서.

@$SHARED_DIR/global.md
@$SHARED_DIR/global-mac.md
EOF
echo "==> ~/.claude/CLAUDE.md = @import 두 줄로 치환 완료"

# --- 2. 메모리 폴더 심볼릭 링크 ------------------------------------------
MEM_TARGET="$HOME/.claude/projects/-Users-seunghyeon-seephone/memory"
MEM_SRC="$SHARED_DIR/memory"

mkdir -p "$(dirname "$MEM_TARGET")"

if [ -d "$MEM_TARGET" ] && [ ! -L "$MEM_TARGET" ]; then
  echo "==> 기존 메모리 폴더 발견. .claude-shared/memory 와 머지 후 백업 처리"
  # 차이가 있으면 .claude-shared 로 머지 (.claude-shared 우선이지만 누락된 파일은 가져옴)
  for f in "$MEM_TARGET"/*.md; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    if [ ! -f "$MEM_SRC/$base" ]; then
      echo "    + $base 가 .claude-shared 에 없음 — 가져옴"
      cp "$f" "$MEM_SRC/$base"
    fi
  done
  mv "$MEM_TARGET" "$MEM_TARGET.bak.$TS"
  echo "==> 기존 메모리 백업: $MEM_TARGET.bak.$TS"
elif [ -L "$MEM_TARGET" ]; then
  rm "$MEM_TARGET"
fi

ln -sfn "$MEM_SRC" "$MEM_TARGET"
echo "==> 메모리 심볼릭 링크: $MEM_TARGET → $MEM_SRC"

# --- 2.5. statusline + model OpusPlan 자동 셋업 ----------------------------
# 토큰 효율 룰 #8 (global.md 참조)
STATUSLINE_SRC="$SHARED_DIR/statusline-mac.sh"
STATUSLINE_DST="$HOME/.claude/statusline.sh"
SETTINGS_JSON="$HOME/.claude/settings.json"

if [ -f "$STATUSLINE_SRC" ]; then
  cp "$STATUSLINE_SRC" "$STATUSLINE_DST"
  chmod +x "$STATUSLINE_DST"
  echo "==> statusline.sh → ~/.claude/ 복사 (chmod +x)"
fi

# settings.json 패치 (model + statusLine)
if [ -f "$SETTINGS_JSON" ]; then
  if command -v jq >/dev/null 2>&1; then
    cp "$SETTINGS_JSON" "$SETTINGS_JSON.bak.$TS"
    tmp=$(mktemp)
    jq --arg cmd "bash $STATUSLINE_DST" '
      .model = (.model // "opusplan") |
      .statusLine = (.statusLine // {type:"command", command:$cmd, padding:0})
    ' "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
    echo "==> settings.json 갱신 (model=opusplan + statusLine, 백업: $SETTINGS_JSON.bak.$TS)"
  else
    echo "==> jq 없음 — settings.json 수동 갱신 필요. brew install jq 권장"
  fi
else
  echo "==> settings.json 없음 — 새로 생성"
  cat > "$SETTINGS_JSON" <<EOF
{
  "model": "opusplan",
  "statusLine": {
    "type": "command",
    "command": "bash $STATUSLINE_DST",
    "padding": 0
  }
}
EOF
fi

# --- 3. 검증 -----------------------------------------------------------
echo ""
echo "==> 검증"
echo "    ~/.claude/CLAUDE.md:"
sed 's/^/      /' "$GLOBAL_MD"
echo ""
echo "    메모리 링크:"
ls -la "$MEM_TARGET" | sed 's/^/      /'
echo ""
echo "==> 완료. Claude Code 재시작 후 새 세션에서 적용됩니다."
