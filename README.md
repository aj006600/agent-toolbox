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

## My Skills

自己做的 skill，原始檔在 [`skills/`](skills/)。

| Skill | 用途 | 觸發方式 |
|---|---|---|
| [llm-wiki](skills/llm-wiki/SKILL.md) | 依 Karpathy 的 LLM Wiki 模式，建立並維護互相連結的 markdown 知識庫 | 提到建立、匯入、查詢或檢查 wiki / knowledge base 時 |

## Curated

別人做的好 skill。只收連結，不複製檔案；有改過內容的才放進 `vendored/`，並註明來源、license 與 commit。

| Skill | 來源 | 用途 | 我的評語 | 安裝方式 |
|---|---|---|---|---|

## 新增 skill

- **自己做的**：建立 `skills/<name>/SKILL.md`，並在 My Skills 表格加一列。
- **別人的**：在 Curated 表格加一列即可。
