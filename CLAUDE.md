## What this repo is

個人的 agent skill 與 plugin 收藏，同時是一個 marketplace。名詞一律照 `GLOSSARY.md`；運作方式與操作步驟見 `README.md`。

## Commands

清單（`.claude-plugin/marketplace.json`）與 README 表格的增刪一律用腳本，不要手改。每支腳本不帶參數或加 `--help` 可看用法。

| 指令 | 用途 |
|---|---|
| `./add.sh skills/<名稱>` / `./add.sh plugins/<名稱>` | 把已建好的自製散裝 skill 或自製 plugin 加進清單與 README |
| `./add.sh <git url> [子資料夾]` | 新增外部條目：自動判斷是 plugin 還是散裝 skill，鎖定在對方最新 commit |
| `./remove.sh <條目>` | 從清單與 README 移除條目 |
| `./update.sh` | 看外部條目的鎖定版本、是否有更新、是否暫停升級 |
| `./update.sh <條目> [版本]` / `--all` / `--sync` | 升降鎖定版本、同步本機安裝 |
| `./update.sh --hold <條目> [原因]` / `--unhold <條目>` | 暫停或恢復某條目的升級 |
| `./test-entry.sh <條目>...` | 在隔離的暫時 marketplace 實際安裝條目，確認 skill 看得到，測完自動清除 |
| `./check.sh` | 檢查清單、資料夾、README 是否一致 |

`.claude/hooks/` 的兩個 hook 會在 `git commit` 前自動執行：`check.sh` 沒通過，或 commit 訊息含 AI 工具署名，commit 就會被擋下。

## Development workflow

- `main` 是唯一分支，改動直接 commit 並 push `main`，不開 feature branch、不開 PR。
- 設計還在討論時不改檔案；我明確說要做才動手。
- 改完先讓我看過，我同意才 commit 與 push。例外是 `update.sh` 在升降版本、暫停或恢復升級時的自動 commit 與 push。
- 我要求升降版本或同步時，直接跑 `update.sh`。它會更新這台電腦上已安裝的條目，這是我要的。
- 除此之外不要替我安裝或解除安裝任何東西。README 裡的 `/plugin install`、`/plugin uninstall` 是寫給我執行的。
- `update.sh` 發現 `marketplace.json` 有未 commit 的修改就會停止。清單裡有還在等我看的修改、我又要求升降版本時，停下來問我要先處理哪一個，不要為了讓腳本能跑而自行 commit。
- 新增或修改條目後，commit 前先跑 `./test-entry.sh <條目>` 確認裝得起來。它只使用名為 `oh-my-skills-test` 的暫時 marketplace，不會動到我真正的安裝，所以不用先問我。

## Repo rules

- 外部內容只加條目，不複製對方的檔案。同一個外部 repo 的多個散裝 skill 或多個 plugin，各自一筆條目。
- `add.sh` 在 README 留下的 `（待填）` 要填完：「用途」「觸發方式」用繁體中文寫；External 表格的「我的評語」留空給我填。
- `add.sh` 回報條目撞名、或警告 skill 前綴會與其他 plugin 相同時，停下來告訴我，不要自行決定。
- 我指定某條目停在特定版本，或因為新版不好用而退版時，問我要不要 `--hold`。被暫停的條目 `--all` 會跳過；要動它必須明確指定版本或先 `--unhold`。
- 移除條目後，提醒我在每台裝過的電腦解除安裝（`remove.sh` 會印出指令）。自製內容的檔案 `remove.sh` 不會刪，要不要刪由我決定。
- `TC.md` 是給我自己看的繁體中文版 `SKILL.md`，沒有功能上的作用。skill 有 `TC.md` 時，改 `SKILL.md` 要在同一個 commit 同步更新它；新 skill 不需要附，除非我要求。
- 自製 plugin 的 `plugin.json` 寫 `name`（與資料夾同名）、`description`、`author`，不寫 `version`；skill 放在 `plugins/<名稱>/skills/<skill 名>/SKILL.md`。

## Conventions

- **Commit message**：輕量 Conventional Commits，英文，不用 emoji。`<type>: <description>`，type 取 `feat/fix/docs/refactor/chore`。新增或移除條目用 `feat`（例：`feat: add foo skill`）；修改 skill 內容時，改變行為用 `feat`、修正錯誤用 `fix`。較早的 commit 沒照這個格式，不要仿照。
- **不留 AI credit**：commit message、文件、程式碼都不寫 AI 工具的署名。
- **文件語言**：章節標題英文（`## Installation`）、內文繁體中文、技術術語保留英文。腳本的註解與輸出用英文。
- **文檔同步**：腳本的用法或行為有變更時，在同一個 commit 內同步更新 README 與這份文件。
- **文件不寫鎖定版本**：README 不記錄各條目鎖在哪個 commit，要看就跑 `./update.sh`。
- **先驗證再採用**：Claude Code 的 plugin 與 marketplace 行為以實測或官方文檔為準，不憑推斷寫進腳本或文件；沒驗證過的要明講。
- **規則提議**：同類糾正第二次發生時，主動提議把教訓歸位，先給我看擬新增的內容，我同意才寫。歸位優先序：能用腳本或 hook 強制的進腳本或 hook，其次才是這份文件。
