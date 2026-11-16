# oh-my-skills

個人的 agent skill 與 plugin 收藏，同時是一個可以安裝的 marketplace。名詞定義見 [GLOSSARY.md](GLOSSARY.md)。

- **自製**的散裝 skill 和 plugin，檔案放在這個 repo。
- **外部**的散裝 skill 和 plugin，這裡只有一筆指向對方 repo 的條目，並鎖定在某個版本。

## 安裝

```
/plugin marketplace add aj006600/oh-my-skills
/plugin install <條目>@oh-my-skills
```

安裝後 skill 會以 `<條目>:<skill 名稱>` 出現，例如 `llm-wiki:llm-wiki`。

## 自製散裝 skill

原始檔在 [`skills/`](skills/)，每個 skill 各自一筆條目。

| 條目 | 用途 | 觸發方式 |
|---|---|---|
| [llm-wiki](skills/llm-wiki/SKILL.md) | 依 Karpathy 的 LLM Wiki 模式，建立並維護互相連結的 markdown 知識庫 | 提到建立、匯入、查詢或檢查 wiki / knowledge base 時 |

## 自製 plugin

原始檔在 `plugins/<名稱>/`。目前沒有。

## 外部

| 條目 | 種類 | 來源 | 用途 | 我的評語 |
|---|---|---|---|---|
| mattpocock-skills | plugin | [mattpocock/skills](https://github.com/mattpocock/skills) | 工程流程 skill：grilling、TDD、code review、domain modeling 等 | |
| trader-skill | plugin | [jakeschincariol/trader-skill](https://github.com/jakeschincariol/trader-skill) | 11 個投資 skill：複製投資人 13F 持股、追蹤新聞與國會議員交易、依預算配置部位、風險檢查、再平衡 | |

## 更新外部條目

外部條目都鎖定在對方 repo 的某個 commit，只有你下指令時才會變動。

```bash
./update.sh                    # 看狀態：鎖定版本、對方最新版、是否有更新（附比較連結）
./update.sh --all              # 所有外部條目升到對方最新版
./update.sh <條目>             # 單一條目升到對方最新版
./update.sh <條目> <版本>      # 單一條目升或降到指定版本（分支、tag 或完整 commit 編號）
./update.sh --sync             # 只把這台電腦已安裝的東西對齊到目前的鎖定版本
```

升降版本會自動 commit 並 push `marketplace.json`，再更新這台電腦上已安裝的條目；更新後要重啟 Claude Code 才生效。需要 `git`、`jq` 和 `claude` CLI。

## 新增內容

- **自製散裝 skill**：建立 `skills/<名稱>/SKILL.md`，在 `.claude-plugin/marketplace.json` 加一筆條目，並在上表加一列。
- **自製 plugin**：建立 `plugins/<名稱>/`（含 `.claude-plugin/plugin.json`），其餘同上。
- **外部**：在 `marketplace.json` 加一筆指向對方 repo 的條目並鎖定在對方最新版，並在上表加一列。
