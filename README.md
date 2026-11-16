# oh-my-skills

個人的 agent skill 與 plugin 收藏，同時是一個可以安裝的 marketplace。名詞定義見 [GLOSSARY.md](GLOSSARY.md)。

- **自製**的散裝 skill 和 plugin，檔案放在這個 repo。
- **外部**的散裝 skill 和 plugin，這裡只有一筆指向對方 repo 的條目，並鎖定在某個版本。

## How It Works

```
這個 repo（GitHub）                         你的電腦（Claude Code）
┌──────────────────────────────┐
│ skills/、plugins/             │  自製：檔案就在這裡
│ .claude-plugin/              │
│   marketplace.json           │──安裝／更新──▶  已安裝的條目
│     自製條目 → 指向上面的資料夾 │
│     外部條目 → 對方 repo + 鎖定版本 ──▶ 從對方 repo 抓那個版本
└──────────────────────────────┘
```

- `marketplace.json` 是清單，每一筆條目對應一個可安裝的散裝 skill 或 plugin。
- 自製條目沒有鎖定版本，用的是這個 repo 的內容。改了之後要 push，再在電腦上同步並重啟才會生效。
- 外部條目不複製對方的檔案，只記錄對方 repo 的位置和鎖定版本（某一個 commit）。對方之後怎麼改都不會影響你，直到你自己升版。
- 你的電腦是從 GitHub 上的清單安裝的，所以清單的變更要 push 之後才會生效。
- 沒有任何自動更新：清單和你電腦上的安裝，都只在你下指令時才會變動。

## Installation

```
/plugin marketplace add aj006600/oh-my-skills
/plugin install <條目>@oh-my-skills
```

安裝後 skill 會以 `<條目>:<skill 名稱>` 出現，例如 `llm-wiki:llm-wiki`。外部 plugin 的前綴是對方原本的 plugin 名稱，通常與條目同名。

## Own Skills

原始檔在 [`skills/`](skills/)，每個 skill 各自一筆條目。

| 條目 | 用途 | 觸發方式 |
|---|---|---|
| [llm-wiki](skills/llm-wiki/SKILL.md) | 依 Karpathy 的 LLM Wiki 模式，建立並維護互相連結的 markdown 知識庫 | 提到建立、匯入、查詢或檢查 wiki / knowledge base 時 |

## Own Plugins

原始檔在 `plugins/<名稱>/`。目前沒有。

| 條目 | 用途 | 包含的 skill |
|---|---|---|

## External

| 條目 | 種類 | 來源 | 用途 | 我的評語 |
|---|---|---|---|---|
| mattpocock-skills | plugin | [mattpocock/skills](https://github.com/mattpocock/skills) | 工程流程 skill：grilling、TDD、code review、domain modeling 等 | |
| trader-skill | plugin | [jakeschincariol/trader-skill](https://github.com/jakeschincariol/trader-skill) | 11 個投資 skill：複製投資人 13F 持股、追蹤新聞與國會議員交易、依預算配置部位、風險檢查、再平衡 | |

## Updating External Entries

外部條目都鎖定在對方 repo 的某個 commit，只有你下指令時才會變動。

```bash
./update.sh                    # 看狀態：鎖定版本、對方最新版、是否有更新（附比較連結）
./update.sh --all              # 所有外部條目升到對方最新版
./update.sh <條目>             # 單一條目升到對方最新版
./update.sh <條目> <版本>      # 單一條目升或降到指定版本（分支、tag 或完整 commit 編號）
./update.sh --sync             # 先 git pull，再把這台電腦已安裝的東西對齊到目前的鎖定版本
```

升降版本會自動 commit 並 push `marketplace.json`，再更新這台電腦上已安裝的條目；更新後要重啟 Claude Code 才生效。需要 `git`、`jq` 和 `claude` CLI。

- `marketplace.json` 有未 commit 的修改時，升降版本會拒絕執行。
- `--all` 會把所有外部條目都升到最新版，包括你刻意停在舊版的；有這種條目時改用逐一升級。
- 外部散裝 skill 的「有更新」看的是對方整個 repo，對方改了別的 skill 也會顯示。

## Common Tasks

### Set up a new machine

1. `git clone https://github.com/aj006600/oh-my-skills.git`（之後要用 `update.sh`）。
2. 在 Claude Code 執行 `/plugin marketplace add aj006600/oh-my-skills`。
3. 對想用的條目執行 `/plugin install <條目>@oh-my-skills`，然後重啟 Claude Code。

### Upgrade an external entry

1. `./update.sh` 看哪些條目有更新，點比較連結看對方改了什麼。
2. `./update.sh <條目>`（或 `./update.sh --all`）升到最新版。
3. 重啟 Claude Code。

### Roll back after an upgrade

升級時腳本會印出一行 `roll back with: ./update.sh <條目> <舊的 commit 編號>`，執行那一行即可。事後想查以前鎖過哪些版本：

```bash
git log -p .claude-plugin/marketplace.json
```

### Catch up on another machine

```bash
./update.sh --sync
```

它會先 `git pull` 這個 repo，再更新已安裝的條目；完成後重啟 Claude Code。不要用 `--all`，它會把所有條目再升到當下最新版。

### Add an external skill or plugin

1. 在 `.claude-plugin/marketplace.json` 加一筆指向對方 repo 的條目，鎖定在對方最新的 commit。對方是散裝 skill 時，每個 skill 各自一筆。
2. 在 External 表格加一列。
3. commit 並 push，再執行 `/plugin marketplace update oh-my-skills` 和 `/plugin install <條目>@oh-my-skills`。

### Add own content

1. 散裝 skill 建立 `skills/<名稱>/SKILL.md`；plugin 建立 `plugins/<名稱>/`（含 `.claude-plugin/plugin.json`）。
2. 在 `marketplace.json` 加一筆條目，並在對應的表格加一列。
3. commit 並 push，再安裝（步驟同上）。

之後修改自製內容，push 後執行 `./update.sh --sync`，再重啟 Claude Code。

### Remove an entry

1. 從 `marketplace.json` 刪掉那一筆條目，並刪掉對應表格的那一列；自製的連同檔案一起刪。
2. commit 並 push。
3. 在每台裝過的電腦執行 `/plugin uninstall <條目>@oh-my-skills`。沒做這一步的話，之後跑 `./update.sh --sync` 會跳過該條目，並印出解除安裝的指令提醒你。
