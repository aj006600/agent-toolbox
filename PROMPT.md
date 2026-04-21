---
name: llm-wiki
description: 當使用者要求建立、初始化或啟動 wiki 或知識庫；匯入（ingest）、新增或處理一份來源到 wiki 中；查詢自己的 wiki 或知識庫；對 wiki 進行 lint、稽核或健康檢查；或在研究情境中提到自己的 wiki、知識庫、第二大腦（second brain）或持續累積的筆記時啟用 —— 即使使用者沒有明確說出「LLM wiki」也要觸發。本 skill 基於 Karpathy 的 LLM Wiki 模式，建立並維護一個持久、互相連結的 markdown 知識庫（作為 RAG 的替代方案：一次編纂、持續更新）。
---

# Karpathy 的 LLM Wiki

以互相連結的 markdown 檔案為載體，建立並維護一個持久、會持續累積複利效應的知識庫。
基於 [Andrej Karpathy 的 LLM Wiki 模式](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。

和傳統 RAG 不同（RAG 每次查詢都從零重新發掘知識），wiki 只編纂一次、並持續保持最新狀態。交叉引用早已就位。矛盾之處早已被標記。綜合結論反映了所有已匯入的內容。

**分工原則：** 人類負責策展來源與主導分析方向。Agent 負責摘要、交叉引用、歸檔、並維持一致性。

## 何時啟用本 Skill

當使用者做下列事情時啟用：
- 要求建立、初始化或啟動一個 wiki 或知識庫
- 要求匯入、新增或處理一份來源進入 wiki
- 提出問題，且在設定路徑存在一個既有 wiki
- 要求對 wiki 進行 lint、稽核或健康檢查
- 在研究情境中提到自己的 wiki、知識庫或「筆記」

## Wiki 路徑解析

依下列順序決定 wiki 路徑：

1. **使用者訊息中明示** — 若使用者提到路徑，直接採用。
2. **環境變數** — 檢查 `$LLM_WIKI_PATH`。
3. **預設位置** — 若 `~/wiki` 存在則採用。
4. **詢問或建立** — 否則向使用者確認；初始化新 wiki 時預設為 `~/wiki`。

為了後續操作方便，將路徑存入 shell 變數 `WIKI`：
```bash
WIKI="${LLM_WIKI_PATH:-$HOME/wiki}"
```

Wiki 本身只是一個放滿 markdown 檔案的目錄 —— 可以用 Obsidian、VS Code 或任何編輯器打開。不需要資料庫，也不需要任何特別工具。

## 架構：三層式設計

```
wiki/
├── SCHEMA.md           # 慣例、結構規則、領域設定
├── index.md            # 分類目錄，每筆一行摘要
├── log.md              # 時序行為紀錄（只能追加，每年輪替）
├── raw/                # 第 1 層：不可變的原始素材
│   ├── articles/       # 網頁文章、剪報
│   ├── papers/         # PDF、arxiv 論文
│   ├── transcripts/    # 會議筆記、訪談逐字稿
│   └── assets/         # 來源所引用的圖片、圖表
├── entities/           # 第 2 層：實體頁（人、組織、產品、模型）
├── concepts/           # 第 2 層：概念 / 主題頁
├── comparisons/        # 第 2 層：並列對照分析
└── queries/            # 第 2 層：值得保留的查詢結果
```

**第 1 層 — 原始來源：** 不可變。Agent 只讀不改。
**第 2 層 — Wiki：** Agent 擁有的 markdown 檔案。由 agent 建立、更新、交叉引用。
**第 3 層 — Schema：** `SCHEMA.md` 定義結構、慣例、以及標籤分類法（tag taxonomy）。

## 接續既有 Wiki（關鍵 —— 每個 session 都要做）

當使用者已有 wiki，**做任何動作前一定要先定位自己**：

① **讀 `SCHEMA.md`** —— 理解領域、慣例、標籤分類法。
② **讀 `index.md`** —— 瞭解哪些頁面存在、各自摘要為何。
③ **掃最近的 `log.md`** —— 讀最後 20-30 筆，掌握近期動向。

對 `$WIKI/SCHEMA.md`、`$WIKI/index.md`、`$WIKI/log.md` 使用 `Read` 工具（讀 `log.md` 時用 `offset` 參數抓最後 20-30 行）。

完成定位後才能進行 ingest、query 或 lint。這能避免：
- 為已存在的實體重複建頁
- 遺漏對既有內容的交叉引用
- 違反 schema 的慣例
- 重做 log 裡已記錄的工作

若 wiki 規模已達 100+ 頁，在新建任何內容前，也對目前主題快速用 `Grep` 搜一下。

## 初始化新 Wiki

當使用者要求建立或啟動 wiki 時：

1. 決定 wiki 路徑（從 config、環境變數、或詢問使用者；預設 `~/wiki`）
2. 建立上述目錄結構
3. 詢問使用者 wiki 的領域範圍 —— 越具體越好
4. 依領域客製化 `SCHEMA.md`（見下方模板）
5. 寫入初始 `index.md`（含分類標題）
6. 寫入初始 `log.md`（含建立紀錄）
7. 確認 wiki 已備妥，並建議首批可匯入的來源

### SCHEMA.md 模板

依使用者領域調整。Schema 約束 agent 的行為並確保一致性：

```markdown
# Wiki Schema

## Domain
[此 wiki 涵蓋的主題 —— 例如「AI/ML 研究」、「個人健康」、「新創情報」]

## Conventions
- 檔名：全小寫、連字號分隔、無空白（例如 `transformer-architecture.md`）
- 每個 wiki 頁面都以 YAML frontmatter 開頭（見下方）
- 頁面之間使用 `[[wikilinks]]` 連結（每頁至少 2 個對外連結）
- 更新頁面時一定要更新 `updated` 日期
- 每個新頁面都必須加入 `index.md` 的正確分類下
- 每個動作都必須追加至 `log.md`

## Frontmatter
  ```yaml
  ---
  title: Page Title
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  type: entity | concept | comparison | query | summary
  tags: [from taxonomy below]
  sources: [raw/articles/source-name.md]
  ---
  ```

## Tag Taxonomy
[為該領域定義 10-20 個頂層標籤。新增標籤前必須先在此處登記。]

AI/ML 範例：
- Models: model, architecture, benchmark, training
- People/Orgs: person, company, lab, open-source
- Techniques: optimization, fine-tuning, inference, alignment, data
- Meta: comparison, timeline, controversy, prediction

規則：頁面使用的每個標籤都必須出現在此分類法中。若需新增標籤，先加到這裡再使用。這能防止標籤氾濫。

## Page Thresholds
- **建立新頁** 當一個實體/概念出現在 2 份以上來源，或在單一來源中佔核心地位
- **加到既有頁** 當來源提到已涵蓋的內容
- **不要建頁** 給順帶一提、次要細節、或領域外的事物
- **拆頁** 當頁面超過約 200 行 —— 拆成子主題並建立交叉連結
- **歸檔** 當頁面內容已被完全取代 —— 移至 `_archive/`、從 index 移除

## Entity Pages
每個值得紀錄的實體一頁。包含：
- 概述 / 它是什麼
- 關鍵事實與日期
- 與其他實體的關係（`[[wikilinks]]`）
- 來源引用

## Concept Pages
每個概念或主題一頁。包含：
- 定義 / 說明
- 當前知識狀態
- 未解問題或爭議
- 相關概念（`[[wikilinks]]`）

## Comparison Pages
並列對照分析。包含：
- 比較什麼、為何比較
- 比較面向（建議用表格）
- 結論或綜合判斷
- 來源

## Update Policy
當新資訊與既有內容衝突：
1. 檢查日期 —— 較新的來源通常取代較舊的
2. 若確實互相矛盾，同時記錄兩種立場，附上日期與來源
3. 在 frontmatter 標記矛盾：`contradictions: [page-name]`
4. 在 lint 報告中旗標起來供使用者複審
```

### index.md 模板

Index 依類型分區。每筆一行：wikilink + 摘要。

```markdown
# Wiki Index

> 內容目錄。每個 wiki 頁面依類型列出，附一行摘要。
> 任何查詢之前先讀這裡找相關頁面。
> Last updated: YYYY-MM-DD | Total pages: N

## Entities
<!-- 區內依字母序 -->

## Concepts

## Comparisons

## Queries
```

**擴充規則：** 任一分區超過 50 筆時，依首字母或子領域拆成子分區。整個 index 超過 200 筆時，建立 `_meta/topic-map.md`，依主題群組頁面以加速導覽。

### log.md 模板

```markdown
# Wiki Log

> 所有 wiki 行為的時序紀錄。只追加。
> 格式：`## [YYYY-MM-DD] action | subject`
> 動作類型：ingest, update, query, lint, create, archive, delete
> 當此檔超過 500 筆時輪替：改名為 log-YYYY.md，開新檔。

## [YYYY-MM-DD] create | Wiki initialized
- Domain: [領域]
- Structure created with SCHEMA.md, index.md, log.md
```

## 核心操作

### 1. Ingest（匯入）

當使用者提供一份來源（URL、檔案、貼文），將其整合進 wiki：

① **擷取原始來源：**
   - URL → 用 `WebFetch` 取得 markdown，存到 `raw/articles/`
   - PDF → 用 `Bash`（`curl`）下載，存到 `raw/papers/`；用 `Read` 並搭配 `pages` 參數擷取內容
   - 貼文字 → 存到對應的 `raw/` 子目錄
   - 檔名要有辨識度：`raw/articles/karpathy-llm-wiki-2026.md`

② **與使用者討論重點** —— 哪些有意思、哪些對該領域很重要。（自動化 / cron 情境可跳過，直接往下。）

③ **檢查已有什麼** —— 搜尋 `index.md`、用 `Grep` 為提到的實體/概念找既有頁面。這一步正是「會成長的 wiki」和「一堆重複檔」之間的分水嶺。

④ **撰寫或更新 wiki 頁面：**
   - **新實體 / 新概念：** 只有符合 SCHEMA.md 中的 Page Thresholds（2 份以上來源提及、或在單一來源為核心）才建頁
   - **既有頁面：** 補充新資訊、更新事實、更新 `updated` 日期。新資訊與舊內容矛盾時，依 Update Policy 處理。
   - **交叉引用：** 每個新建或更新的頁面必須透過 `[[wikilinks]]` 連到至少 2 個其他頁。檢查既有頁面是否也反向連結回來。
   - **標籤：** 只能使用 SCHEMA.md 分類法中的標籤

⑤ **更新導覽：**
   - 將新頁加入 `index.md` 的正確分區，依字母序排列
   - 更新 index 標頭的「Total pages」計數與「Last updated」日期
   - 追加至 `log.md`：`## [YYYY-MM-DD] ingest | Source Title`
   - 在 log 條目中列出每個被建立或更新的檔案

⑥ **回報變動** —— 向使用者列出每一個被建立或更新的檔案。

單一來源可能觸發 5-15 個 wiki 頁的更新。這是正常且理想的 —— 這就是複利效應。

### 2. Query（查詢）

當使用者問一個與 wiki 領域相關的問題時：

① **用 `Read` 工具讀 `index.md`** 來找出相關頁面。
② **若 wiki 已達 100+ 頁**，另外用 `Grep` 在所有 `.md` 檔案裡搜關鍵字 —— 只靠 index 可能會漏掉相關內容。
③ **用 `Read` 工具讀相關頁面**。
④ **從已編纂的知識中綜合出答案**。引用你參考的 wiki 頁：「根據 [[page-a]] 與 [[page-b]]……」
⑤ **有價值的答案歸檔回 wiki** —— 若答案是一份實質的比較、深度分析、或新穎綜合，在 `queries/` 或 `comparisons/` 建頁。不要歸檔瑣碎查閱 —— 只存「重新推導會很痛」的答案。
⑥ **更新 log.md**，紀錄此次查詢及是否被歸檔。

### 3. Lint（檢核）

當使用者要求 lint、健康檢查或稽核 wiki 時：

① **孤兒頁（Orphan pages）：** 找出沒有任何其他頁面透過 `[[wikilinks]]` 連入的頁面。
用 `Bash` + `python3` 跑程式化掃描：

```bash
python3 <<'PY'
import os, re
from collections import defaultdict
WIKI = os.path.expanduser(os.environ.get("LLM_WIKI_PATH", "~/wiki"))
inbound = defaultdict(set)
pages = []
for root, _, files in os.walk(WIKI):
    for f in files:
        if not f.endswith(".md"): continue
        p = os.path.join(root, f)
        pages.append(p)
        text = open(p, encoding="utf-8", errors="ignore").read()
        for target in re.findall(r"\[\[([^\]|#]+)", text):
            inbound[target.strip()].add(p)
orphans = [p for p in pages if not inbound.get(os.path.splitext(os.path.basename(p))[0])]
print("Orphans:", len(orphans))
for p in orphans[:50]: print(" ", p)
PY
```

② **斷鏈：** 找出指向不存在頁面的 `[[links]]`。

③ **Index 完整性：** 每個 wiki 頁面都該出現在 `index.md` 中。比對檔案系統與 index 條目。

④ **Frontmatter 驗證：** 每個 wiki 頁面都必須具備全部必要欄位（title、created、updated、type、tags、sources）。標籤必須來自分類法。

⑤ **內容過時：** `updated` 日期比最新提及同一批實體的來源還舊超過 90 天的頁面。

⑥ **矛盾：** 相同主題但陳述相互衝突的頁面。找出共用標籤/實體卻陳述不同事實的頁面。

⑦ **頁面長度：** 旗標超過 200 行的頁面 —— 拆頁候選。

⑧ **標籤稽核：** 列出所有使用中的標籤，旗標任何不在 SCHEMA.md 分類法內的。

⑨ **Log 輪替：** 若 `log.md` 超過 500 筆，執行輪替。

⑩ **回報發現**，附上具體檔案路徑與建議動作，依嚴重度分組（斷鏈 > 孤兒頁 > 過時內容 > 樣式問題）。

⑪ **追加至 log.md：** `## [YYYY-MM-DD] lint | N issues found`

## 使用 Wiki 的技巧

### 搜尋

- 依內容找頁面：`Grep`，搭配 pattern 與 `path=$WIKI`、`glob="*.md"`。
- 依檔名找頁面：`Glob`，用 `**/*.md` 這類 pattern、路徑為 `$WIKI`。
- 依標籤找頁面：對 `*.md` 使用 `Grep` 搜 `tags:.*alignment`。
- 近期動態：`Read` `$WIKI/log.md`，用 `offset` 抓最後 20 行。

### 批次 Ingest

同時匯入多份來源時，批次處理更新：
1. 先一次讀完所有來源
2. 橫跨所有來源辨識出全部實體與概念
3. 對全部實體/概念一次搜尋既有頁面（一次掃描，不是 N 次）
4. 一次批次建立/更新頁面（避免重複更新）
5. 最後一次性更新 `index.md`
6. 寫單一一筆涵蓋整批的 log 條目

### 歸檔

當內容被完全取代、或領域範圍調整時：
1. 建立 `_archive/` 目錄（若尚未存在）
2. 將頁面依原本路徑移入 `_archive/`（例如 `_archive/entities/old-page.md`）
3. 從 `index.md` 移除
4. 更新所有曾連向該頁的頁面 —— 把 wikilink 換成純文字加「(archived)」
5. 把歸檔動作記入 log

### Obsidian 整合

Wiki 目錄開箱即可作為 Obsidian vault 使用：
- `[[wikilinks]]` 會呈現為可點擊連結
- Graph View 可視化知識網絡
- YAML frontmatter 可驅動 Dataview 查詢
- `raw/assets/` 目錄存放透過 `![[image.png]]` 引用的圖片

要達到最佳效果：
- 將 Obsidian 的附件資料夾設為 `raw/assets/`
- 啟用 Obsidian 設定中的「Wikilinks」（通常預設已開）
- 安裝 Dataview 外掛以執行 `TABLE tags FROM "entities" WHERE contains(tags, "company")` 這類查詢

### Obsidian Headless（server 與無顯示器的機器）

在沒有顯示器的 server 上，可用 `obsidian-headless` 讓 agent 寫入 wiki，同時你在 laptop 或手機上透過 Obsidian Sync 讀取同一個 vault —— 變更數秒內同步。完整設定流程（npm 安裝、vault 登入、`ob sync-setup`、持續同步、systemd user service 模板、以及 `loginctl enable-linger` 注意事項）放在 `references/obsidian-headless.md` —— 當使用者真的需要架這套時，再用 `Read` 工具讀取。

## 易犯陷阱

- **絕對不要修改 `raw/` 裡的檔案** —— 來源不可變。更正寫在 wiki 頁面。
- **永遠先定位** —— 新 session 中做任何操作前，先讀 SCHEMA + index + 近期 log。跳過這步會造成重複與漏連結。
- **永遠更新 `index.md` 和 `log.md`** —— 跳過這步 wiki 會退化。這兩個檔是導覽骨幹。
- **不要為順帶一提的內容建頁** —— 遵循 SCHEMA.md 中的 Page Thresholds。名字只在註腳出現一次，不值得開實體頁。
- **不要建沒有交叉引用的頁** —— 孤立的頁面等於隱形。每一頁都必須至少連到 2 個其他頁。
- **Frontmatter 必要** —— 它是搜尋、過濾、陳舊偵測的基礎。
- **標籤必須來自分類法** —— 自由發揮的標籤會退化成雜訊。新標籤先加進 SCHEMA.md，再使用。
- **保持頁面可速讀** —— 一個 wiki 頁應在 30 秒內讀完。超過 200 行就拆頁。深入分析搬到專屬的 deep-dive 頁。
- **大量更新前先詢問** —— 若一次 ingest 會動到 10+ 個既有頁面，先和使用者確認範圍。
- **輪替 log** —— 當 `log.md` 超過 500 筆，改名 `log-YYYY.md`、開新檔。Agent 應在 lint 時檢查 log 大小。
- **明確處理矛盾** —— 不要默默覆蓋。同時紀錄兩邊說法與日期，在 frontmatter 標記，於 lint 報告旗標供使用者複審。
