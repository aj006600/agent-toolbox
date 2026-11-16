## What this repo is

個人的 agent skill 與 plugin 收藏，同時是一個 marketplace。名詞一律照 `GLOSSARY.md`；運作方式與操作步驟見 `README.md`。

## Commands

| 指令 | 用途 |
|---|---|
| `./update.sh` | 看外部條目的鎖定版本與是否有更新 |
| `./update.sh <條目> [版本]` / `--all` / `--sync` | 升降鎖定版本、同步本機安裝（詳見 README） |
| `claude plugin validate .` | 驗證 `marketplace.json` |

## Development workflow

- `main` 是唯一分支，改動直接 commit 並 push `main`，不開 feature branch、不開 PR。
- 設計還在討論時不改檔案；我明確說要做才動手。
- 改完先讓我看過，我同意才 commit 與 push。唯一例外是 `update.sh` 升降鎖定版本時的自動 commit 與 push。
- 需要在我的 Claude Code 暫時加 marketplace 或安裝條目來測試時，先問過我；測完把 marketplace、安裝、快取全部移除，並回報環境是否已還原。

## Repo rules

- 自製散裝 skill 放 `skills/<名稱>/`，每個各自一筆條目；自製 plugin 放 `plugins/<名稱>/`。repo 根目錄不是 plugin。
- 外部內容只加條目，不複製對方的檔案。新增時鎖定在對方最新的 commit。
- 同一個外部 repo 的多個散裝 skill 各自一筆條目；條目名稱用對方的 skill 名，撞名時加對方帳號當前綴。
- 鎖定版本只透過 `update.sh` 變更，不手改 `sha`。
- 改過 `marketplace.json` 後跑 `claude plugin validate .`。

## Conventions

- **Commit message**：輕量 Conventional Commits，英文，不用 emoji。`<type>: <description>`，type 取 `feat/fix/docs/refactor/chore`。`update.sh` 產生的訊息是 `chore: bump <條目>`。
- **不留 AI credit**：commit message、文件、程式碼都不寫 AI 工具的署名。
- **文件語言**：章節標題英文（`## Installation`）、內文繁體中文、技術術語保留英文。
- **文檔同步**：條目的新增、移除、改名，以及 `update.sh` 用法的變更，在同一個 commit 內同步更新 README。
- **文件不寫鎖定版本**：README 不記錄各條目鎖在哪個 commit，要看就跑 `./update.sh`。
- **先驗證再採用**：Claude Code 的 plugin 與 marketplace 行為以實測或官方文檔為準，不憑推斷寫進腳本或文件；沒驗證過的要明講。
- **規則提議**：同類糾正第二次發生時，主動提議把教訓寫進這份文件，先給我看擬新增的那一行，我同意才寫。
