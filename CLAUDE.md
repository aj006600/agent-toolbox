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
- 需要在我的 Claude Code 暫時加 marketplace 或安裝條目來測試時，先問過我；測完把 marketplace、安裝、快取全部移除，並回報環境是否已還原。步驟見 Testing an entry。
- 條目 push 之後的安裝（`/plugin marketplace update`、`/plugin install`）由我自己執行；除非我明確要求，不要替我安裝。
- 我要求升降版本或同步時，直接跑 `update.sh`。它會更新這台電腦上已安裝的條目，這是我要的，不算「替我安裝」。

## Repo rules

- 自製散裝 skill 放 `skills/<名稱>/`，每個各自一筆條目；自製 plugin 放 `plugins/<名稱>/`。repo 根目錄不是 plugin。
- 外部內容只加條目，不複製對方的檔案。
- 新增外部條目時，手動把 `sha` 填成對方最新 commit 的完整 40 字元編號（`git ls-remote <url> HEAD`）。條目建立之後，鎖定版本一律透過 `update.sh` 變更，不手改 `sha`。
- 同一個外部 repo 的多個散裝 skill 各自一筆條目。
- 條目名稱：散裝 skill 用它的資料夾名；plugin 用對方 `.claude-plugin/plugin.json` 的 `name`（對方沒有這個檔案就不是 plugin，改用散裝 skill 的寫法）。`author` 取對方 `plugin.json` 的 `author.name`，沒有就用對方的 GitHub 帳號名。
- 新的外部條目與既有條目撞名時，改成 `<對方帳號>-<名稱>`。新的自製條目與既有條目撞名時，停下來問我。
- 外部 plugin 改了條目名稱仍可安裝（實測過），但安裝後 skill 的前綴仍是對方 `plugin.json` 的 `name`，不是條目名稱。所以兩個外部 plugin 原名相同時，skill 名稱會互相蓋掉；遇到這種情況要告訴我。
- 條目順序：自製散裝 skill、自製 plugin、外部，各組內依加入先後排在最後。
- 條目的 `description` 用英文寫一句。
- `TC.md` 是給我自己看的繁體中文版 `SKILL.md`，沒有功能上的作用。skill 有 `TC.md` 時，改 `SKILL.md` 要在同一個 commit 同步更新它；新 skill 不需要附，除非我要求。
- 移除條目：刪掉清單裡那一筆和 README 表格的那一列（自製的連同檔案），並提醒我在每台裝過的電腦執行 `/plugin uninstall <條目>@oh-my-skills`。沒解除安裝就跑 `./update.sh --sync` 時，腳本會跳過該條目並印出解除安裝的指令，不會替我移除，其他條目照常更新（實測過）。
- 清單檔維持 `jq` 的展開格式（每個欄位各佔一行，照檔案裡現有的條目），因為 `update.sh` 會用 `jq` 重寫整個檔案。
- 改過 `marketplace.json` 後跑 `claude plugin validate .`。

## Entry formats

以下四種寫法都實測過可以安裝；自製條目在 push 之後跑 `./update.sh --sync` 會更新到新的 commit，也實測過。`strict: false` 加 `skills` 用在沒有 `plugin.json` 的散裝 skill：由條目指出 skill 資料夾的位置，路徑相對於 `source`，`./` 表示 `source` 本身就是那個 skill 資料夾。安裝後 skill 的名稱是 `<條目>:<skill 名>`。

外部條目的 `source` 一定要有 `url` 欄位，`update.sh` 靠它查對方的最新 commit。`homepage` 裡的分支名用對方的預設分支。

自製散裝 skill（檔案在 `skills/foo/`）：

```json
{
  "name": "foo",
  "description": "One-line English summary",
  "author": { "name": "YiTsung" },
  "source": "./skills/foo",
  "strict": false,
  "skills": ["./"]
}
```

自製 plugin（檔案在 `plugins/baz/`，內含 `.claude-plugin/plugin.json` 與 `skills/<skill 名>/SKILL.md`；`plugin.json` 寫 `name`、`description`、`author`，不寫 `version`）：

```json
{
  "name": "baz",
  "description": "One-line English summary",
  "author": { "name": "YiTsung" },
  "source": "./plugins/baz"
}
```

外部 plugin（整個 repo 是一個 plugin）：

```json
{
  "name": "cool-plugin",
  "description": "One-line English summary",
  "author": { "name": "Upstream Author" },
  "source": {
    "source": "url",
    "url": "https://github.com/example/cool-plugin.git",
    "sha": "<40-char commit sha>"
  },
  "homepage": "https://github.com/example/cool-plugin"
}
```

外部散裝 skill（對方 repo 不是 plugin，skill 在 `skills/bar/`）：

```json
{
  "name": "bar",
  "description": "One-line English summary",
  "author": { "name": "Upstream Author" },
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/example/many-skills.git",
    "path": "skills/bar",
    "sha": "<40-char commit sha>"
  },
  "strict": false,
  "skills": ["./"],
  "homepage": "https://github.com/example/many-skills/tree/main/skills/bar"
}
```

## Testing an entry

要在 commit 前確認條目真的裝得起來時使用。先問過我，並先檢查兩件事：

- `claude plugin marketplace list --json` 裡沒有 `oh-my-skills`。有的話停下來問我，不要覆蓋。
- 這個 repo 裡有沒有 `.claude/settings.local.json`。原本就有的話先記下內容，測完只移除測試加進去的部分，不要刪檔。

```bash
claude plugin validate .
claude plugin marketplace add "$(pwd)"                      # 以本機路徑加入，讀的是未 commit 的清單
claude plugin install <條目>@oh-my-skills --scope local
claude -p --model haiku "List the available skill names that start with '<條目>:'. Names only." < /dev/null
OMS_NO_GIT=1 ./update.sh <條目> <版本>                      # 只在要測 update.sh 時用；跳過 pull、commit、push
```

測完還原，並回報結果：

```bash
claude plugin uninstall <條目>@oh-my-skills --scope local
claude plugin marketplace remove oh-my-skills
rm -f .claude/settings.local.json && rmdir .claude          # 只在這個檔案是測試產生的時候才刪
rm -rf ~/.claude/plugins/cache/oh-my-skills
```

若測試時用 `update.sh` 動過某條目的鎖定版本，清理前先用 `OMS_NO_GIT=1 ./update.sh <條目> <原本的 sha>` 改回去。不要用 `git checkout` 還原清單，那會連同還沒 commit 的新條目一起丟掉。

## Conventions

- **Commit message**：輕量 Conventional Commits，英文，不用 emoji。`<type>: <description>`，type 取 `feat/fix/docs/refactor/chore`。新增或移除條目用 `feat`（例：`feat: add foo skill`）；修改 skill 內容時，改變行為用 `feat`、修正錯誤用 `fix`。`update.sh` 產生的訊息是 `chore: bump <條目>`。較早的 commit 沒照這個格式，不要仿照。
- **不留 AI credit**：commit message、文件、程式碼都不寫 AI 工具的署名。
- **文件語言**：章節標題英文（`## Installation`）、內文繁體中文、技術術語保留英文。
- **文檔同步**：條目的新增、移除、改名，以及 `update.sh` 用法的變更，在同一個 commit 內同步更新 README。External 表格的「種類」欄填 `plugin` 或 `散裝 skill`；「來源」欄 plugin 連到對方 repo，散裝 skill 連到對方 repo 裡的那個資料夾；「我的評語」欄留空給我填。
- **文件不寫鎖定版本**：README 不記錄各條目鎖在哪個 commit，要看就跑 `./update.sh`。
- **先驗證再採用**：Claude Code 的 plugin 與 marketplace 行為以實測或官方文檔為準，不憑推斷寫進腳本或文件；沒驗證過的要明講。
- **規則提議**：同類糾正第二次發生時，主動提議把教訓寫進這份文件，先給我看擬新增的那一行，我同意才寫。
