#!/usr/bin/env bash
# Guard hook: 擋下 `git commit` 指令文字中出現的 AI 工具署名
# (Co-Authored-By: Claude、Generated with Claude Code 等)。
# Claude Code PreToolUse hook(註冊於 .claude/settings.json),不是 git pre-commit hook。
#
# 為什麼是硬擋:署名一進 git 歷史就收不回來,而工具預設會加。
# 結束碼必須是 2 才會擋下指令;結束碼 1 只會顯示錯誤,指令照樣執行(實測過)。
#
# 限制:只掃指令文字,看不到 `-F <file>` 的檔案內容。

command -v jq >/dev/null 2>&1 || exit 0

command=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

echo "$command" | grep -qE '(^|[^a-zA-Z])git commit([^a-zA-Z]|$)' || exit 0

findings=$(echo "$command" | grep -iE 'co-authored-by:.*(claude|anthropic)|generated with.*claude|noreply@anthropic\.com')
if [ -n "$findings" ]; then
  echo "[ai-credit-guard] BLOCKED — 指令文字含 AI 工具署名:" >&2
  echo "$findings" | sed 's/^/  - /' >&2
  echo "[ai-credit-guard] 本 repo 的 commit 不留 AI 工具署名(見 CLAUDE.md Conventions)。拿掉這幾行後重新執行。" >&2
  exit 2
fi
exit 0
