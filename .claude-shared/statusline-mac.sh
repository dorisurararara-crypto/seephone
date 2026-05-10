#!/usr/bin/env bash
# Claude Code statusline (Mac/Linux bash)
# Reads JSON from stdin, prints: folder | branch | model | ctx [bar] %
# Bootstrap-mac.sh copies this to ~/.claude/statusline.sh

set +e

raw=$(cat)
if [ -z "$raw" ]; then
  echo "claude"
  exit 0
fi

# Try jq, fallback to grep/sed
if command -v jq >/dev/null 2>&1; then
  cwd=$(echo "$raw" | jq -r '.cwd // ""')
  model=$(echo "$raw" | jq -r '.model.display_name // "?"')
  transcript=$(echo "$raw" | jq -r '.transcript_path // ""')
else
  cwd=$(echo "$raw" | grep -o '"cwd":"[^"]*"' | sed 's/"cwd":"\([^"]*\)"/\1/')
  model=$(echo "$raw" | grep -o '"display_name":"[^"]*"' | head -1 | sed 's/"display_name":"\([^"]*\)"/\1/')
  transcript=$(echo "$raw" | grep -o '"transcript_path":"[^"]*"' | sed 's/"transcript_path":"\([^"]*\)"/\1/')
fi

folder=$(basename "$cwd" 2>/dev/null || echo "?")

# Git branch
branch="-"
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(cd "$cwd" 2>/dev/null && git branch --show-current 2>/dev/null || echo "-")
  [ -z "$branch" ] && branch="-"
fi

# Context estimation
pct=0
bar="----------"
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  size=$(wc -c < "$transcript" 2>/dev/null || echo 0)
  # Opus 4.7 1M context = 4M chars (1 token ≈ 4 chars)
  max_chars=4000000
  pct=$(( size * 100 / max_chars ))
  [ $pct -gt 100 ] && pct=100
  filled=$(( pct / 10 ))
  [ $filled -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for i in $(seq 1 $filled); do bar="${bar}#"; done
  for i in $(seq 1 $empty); do bar="${bar}-"; done
fi

# ANSI color codes
reset=$'\033[0m'
dim=$'\033[2m'
gold=$'\033[33m'
cyan=$'\033[36m'
red=$'\033[31m'

ctx_color="$cyan"
[ $pct -ge 60 ] && ctx_color="$gold"
[ $pct -ge 80 ] && ctx_color="$red"

printf "%s📁%s %s%s%s %s|%s %s🌿%s %s %s|%s %s🤖%s %s %s|%s %s📊%s %s[%s]%s %s%d%%%s\n" \
  "$dim" "$reset" "$gold" "$folder" "$reset" \
  "$dim" "$reset" \
  "$dim" "$reset" "$branch" \
  "$dim" "$reset" \
  "$dim" "$reset" "$model" \
  "$dim" "$reset" \
  "$dim" "$reset" "$ctx_color" "$bar" "$reset" "$ctx_color" "$pct" "$reset"
