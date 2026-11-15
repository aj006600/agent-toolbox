# oh-my-skills

個人的 agent skill 收藏：自己做的 skill 放在這裡，GitHub 上看到的好 skill 只記錄連結與評語。

## 安裝

```
/plugin marketplace add aj006600/oh-my-skills
/plugin install oh-my-skills@oh-my-skills
```

安裝後 skill 會以 `oh-my-skills:<skill 名稱>` 出現。只想在本機用、不要前綴的話，改用 symlink：

```bash
ln -s "$(pwd)/skills/llm-wiki" ~/.claude/skills/llm-wiki
```

## 更新

```bash
./update.sh                      # 更新所有從這個 marketplace 安裝的 plugin
./update.sh mattpocock-skills    # 只更新指定的 plugin
```

需要 `jq`。更新後要重啟 Claude Code 才會生效。

## My Skills

自己做的 skill，原始檔在 [`skills/`](skills/)。

| Skill | 用途 | 觸發方式 |
|---|---|---|
| [llm-wiki](skills/llm-wiki/SKILL.md) | 依 Karpathy 的 LLM Wiki 模式，建立並維護互相連結的 markdown 知識庫 | 提到建立、匯入、查詢或檢查 wiki / knowledge base 時 |

## Curated

別人做的好 skill / plugin。不複製檔案，只在 [`marketplace.json`](.claude-plugin/marketplace.json) 加一筆指向對方 repo 的條目；不寫 `sha`，安裝時直接抓對方最新版。有改過內容的才放進 `vendored/`，並註明來源、license 與 commit。

| Skill | 來源 | 用途 | 我的評語 | 安裝方式 |
|---|---|---|---|---|
| mattpocock-skills | [mattpocock/skills](https://github.com/mattpocock/skills) | 工程流程 skill：grilling、TDD、code review、domain modeling 等 | | `/plugin install mattpocock-skills@oh-my-skills` |
| trader-skill | [jakeschincariol/trader-skill](https://github.com/jakeschincariol/trader-skill) | 11 個投資 skill：複製投資人 13F 持股、追蹤新聞與國會議員交易、依預算配置部位、風險檢查、再平衡 | | `/plugin install trader-skill@oh-my-skills` |

## 新增 skill

- **自己做的**：建立 `skills/<name>/SKILL.md`，並在 My Skills 表格加一列。
- **別人的**：在 `.claude-plugin/marketplace.json` 加一筆條目，並在 Curated 表格加一列。
