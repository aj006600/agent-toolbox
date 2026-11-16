# agent-toolbox

個人的 agent skill 與 plugin 收藏，同時是一個可以安裝的 marketplace。

## How It Works

- **Skill** 是一個含 `SKILL.md` 的資料夾；不屬於任何 plugin、單獨存在的叫**散裝 skill**。**Plugin** 是帶 `plugin.json` 的套件，裡面可以有 skill、agent、slash command、hook 和 MCP server。
- **條目**是清單（`.claude-plugin/marketplace.json`）裡的一筆記錄，對應一個可安裝的散裝 skill 或 plugin。
- **自製**的內容，檔案就放在這個 repo 的 `skills/` 或 `plugins/`。
- **外部**的內容，這裡只有一筆指向對方 repo 的條目，不複製對方的檔案，更新時跟著對方的最新版。
- 你的電腦是從 GitHub 上的清單安裝的，所以清單的變更要 push 之後才會生效。
- 沒有自動更新：你電腦上裝的東西，只在你下指令時才會變動。

## Installation

```
/plugin marketplace add aj006600/agent-toolbox
/plugin install <條目>@agent-toolbox
```

安裝後重啟 Claude Code。散裝 skill 會以 `<條目>:<skill 名稱>` 出現，例如 `llm-wiki:llm-wiki`；plugin 的前綴是它自己的 plugin 名稱，通常與條目同名。

要用這裡的腳本，另外把 repo clone 下來：`git clone https://github.com/aj006600/agent-toolbox.git`。

## Own Skills

原始檔在 [`skills/`](skills/)，每個 skill 各自一筆條目。

| 條目 | 用途 | 觸發方式 |
|---|---|---|
| [llm-wiki](skills/llm-wiki/SKILL.md) | 依 Karpathy 的 LLM Wiki 模式，建立並維護互相連結的 markdown 知識庫 | 提到建立、匯入、查詢或檢查 wiki / knowledge base 時 |

## Own Plugins

原始檔在 `plugins/<名稱>/`，每個 plugin 各自一筆條目。

| 條目 | 用途 | 內容 |
|---|---|---|

## External

| 條目 | 種類 | 來源 | 用途 | 我的評語 |
|---|---|---|---|---|
| mattpocock-skills | plugin | [mattpocock/skills](https://github.com/mattpocock/skills) | 工程流程 skill：grilling、TDD、code review、domain modeling 等 | |
| trader-skill | plugin | [jakeschincariol/trader-skill](https://github.com/jakeschincariol/trader-skill) | 11 個投資 skill：複製投資人 13F 持股、追蹤新聞與國會議員交易、依預算配置部位、風險檢查、再平衡 | |

## Updating

```bash
./update.sh              # 更新這台電腦上所有從這裡安裝的條目
./update.sh <條目>...    # 只更新指定的條目
```

更新後重啟 Claude Code。需要 `git`、`jq` 和 `claude` CLI。

腳本會先用 Claude Code 內建的更新，再確認結果。對方沒改版本號時內建的更新不會生效，這種情況腳本會把那個條目移除再重新安裝。自製內容改了之後，push 再跑 `./update.sh` 即可。

想讓某個外部條目停在特定版本時，在清單裡那一筆的 `source` 加上 `"sha": "<完整 commit 編號>"`，commit 並 push。之後 `./update.sh` 會讓它維持在那個版本，直到你改掉或拿掉這一行。

## Adding

```bash
./add.sh https://github.com/<帳號>/<repo>                 # 外部：整個 repo 是一個 plugin 或一個 skill
./add.sh https://github.com/<帳號>/<repo> <子資料夾>      # 外部：repo 裡的某一個 plugin 或 skill
./add.sh skills/<名稱> --desc "<英文一句說明>"            # 自製散裝 skill（先建好 skills/<名稱>/SKILL.md）
./add.sh plugins/<名稱>                                   # 自製 plugin（先建好 plugins/<名稱>/）
```

1. 外部的散裝 skill 也要加 `--desc "<英文一句說明>"`；plugin 會沿用它自己的說明。
2. 腳本會把條目加進清單和上面對應的表格。對方 repo 根目錄不是 plugin 也不是 skill 時，它會列出可以加的子資料夾；條目名稱已被使用時，它會停止且不做任何變更，決定新名稱後加上 `--name <名稱>` 重跑。
3. 把表格裡的 `（待填）` 填好。
4. commit 並 push。自製內容要連同它的資料夾一起 commit。
5. 執行 `/plugin marketplace update agent-toolbox` 和 `/plugin install <條目>@agent-toolbox`，然後重啟 Claude Code。

自製 plugin 的資料夾要有 `.claude-plugin/plugin.json`（`name` 與資料夾同名，不寫 `version`）。內容依需要放：`skills/<skill 名>/SKILL.md`、`agents/<agent 名>.md`、`commands/<指令名>.md`、`hooks/hooks.json`、`.mcp.json`。

## Removing

1. 從 `.claude-plugin/marketplace.json` 刪掉那一筆條目，並刪掉上面表格的那一列；自製的連同資料夾一起刪。
2. commit 並 push。
3. 在每台裝過的電腦執行 `/plugin uninstall <條目>@agent-toolbox`。
