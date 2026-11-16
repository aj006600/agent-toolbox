#!/usr/bin/env bash
# Guard hook: 在 `git commit` 之前跑 ./check.sh,清單、資料夾、README 不一致就擋下 commit。
# Claude Code PreToolUse hook(註冊於 .claude/settings.json),不是 git pre-commit hook,
# 所以 update.sh 自己做的 commit 不會經過這裡。
#
# 結束碼必須是 2 才會擋下指令;結束碼 1 只會顯示錯誤,指令照樣執行(實測過)。

command -v jq >/dev/null 2>&1 || exit 0

command=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$command" ] || exit 0

echo "$command" | grep -qE '(^|[^a-zA-Z])git commit([^a-zA-Z]|$)' || exit 0

if ! output=$("${CLAUDE_PROJECT_DIR:-.}/check.sh" 2>&1); then
  echo "[pre-commit-check] BLOCKED — ./check.sh 沒有通過:" >&2
  echo "$output" >&2
  echo "[pre-commit-check] 修正上面列出的問題後重新 commit。" >&2
  exit 2
fi
exit 0
