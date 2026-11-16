## What this repo is

個人的 agent skill 與 plugin 收藏，同時是一個 marketplace。運作方式、名詞與操作步驟見 `README.md`。

## Commands

| 指令 | 用途 |
|---|---|
| `./add.sh skills/<名稱> --desc "<英文一句>"` / `./add.sh plugins/<名稱>` | 把已建好的自製散裝 skill 或自製 plugin 加進清單與 README |
| `./add.sh <git url> [子資料夾]` | 新增外部條目，自動判斷是 plugin 還是散裝 skill。散裝 skill 要加 `--desc` |
| `./update.sh` / `./update.sh <條目>...` | 更新這台電腦上已安裝的條目（全部或指定的） |
| `claude plugin validate .` | 驗證 `.claude-plugin/marketplace.json` |

新增條目用 `add.sh`，不要手寫清單。移除條目沒有腳本：刪掉清單裡那一筆和 README 表格的那一列，自製內容連同資料夾一起刪。

## Development workflow

- `main` 是唯一分支，改動直接 commit 並 push `main`，不開 feature branch、不開 PR。
- 設計還在討論時不改檔案；我明確說要做才動手。
- 改完先讓我看過，我同意才 commit 與 push。
- 我要求更新時，直接跑 `update.sh`。除此之外不要替我安裝或解除安裝任何東西；README 裡的 `/plugin install`、`/plugin uninstall` 是寫給我執行的。
- 保持簡單。不要為了少見、而且一個指令就能補救的情況增加腳本、hook 或規則；有這類想法先提出來問我。

## Repo rules

- 外部內容只加條目，不複製對方的檔案。同一個外部 repo 的多個散裝 skill 或多個 plugin，各自一筆條目。
- 外部條目預設不固定版本，跟著對方的最新 commit。我要求固定某一筆時，在清單裡那一筆的 `source` 加上 `"sha": "<完整 commit 編號>"`。
- `--desc` 是條目在 marketplace 裡顯示的說明，用英文寫一句，不要整段照抄 `SKILL.md` 的觸發說明。
- `add.sh` 在 README 留下的 `（待填）` 要填完：「用途」「觸發方式」用繁體中文寫；External 表格的「我的評語」留空給我填。
- `add.sh` 遇到條目撞名會直接停止、不做任何變更。把它印出的訊息告訴我，等我決定後再處理，不要自行決定名稱。
- 新增自製內容時，commit 要包含那個資料夾、清單和 README 三者。
- 移除條目後，提醒我在每台裝過的電腦執行 `/plugin uninstall <條目>@oh-my-skills`。
- `TC.md` 是給我自己看的繁體中文版 `SKILL.md`，沒有功能上的作用。skill 有 `TC.md` 時，改 `SKILL.md` 要在同一個 commit 同步更新它；新 skill 不需要附，除非我要求。
- 自製 plugin 的 `plugin.json` 寫 `name`（與資料夾同名）、`description`、`author`，不寫 `version`；內容放在 plugin 資料夾裡的標準位置：`skills/<skill 名>/SKILL.md`、`agents/`、`commands/`、`hooks/hooks.json`、`.mcp.json`。agent、MCP server 這類不單獨放在 repo 根目錄。

## Conventions

- **Commit message**：輕量 Conventional Commits，英文，不用 emoji。`<type>: <description>`，type 取 `feat/fix/docs/refactor/chore`。新增或移除條目用 `feat`（例：`feat: add foo skill`）；修改 skill 內容時，改變行為用 `feat`、修正錯誤用 `fix`。較早的 commit 沒照這個格式，不要仿照。
- **不留 AI credit**：commit message、文件、程式碼都不寫 AI 工具的署名。
- **文件語言**：章節標題英文（`## Installation`）、內文繁體中文、技術術語保留英文。腳本的註解與輸出用英文。
- **文檔同步**：腳本的用法或行為有變更時，在同一個 commit 內同步更新 README 與這份文件。
- **先驗證再採用**：Claude Code 的 plugin 與 marketplace 行為以實測或官方文檔為準，不憑推斷寫進腳本或文件；沒驗證過的要明講。要實測安裝時，用另一個名字的暫時 marketplace 在暫存資料夾裡進行，不要動到名為 `oh-my-skills` 的那個。
