# oh-my-skills

個人的 agent skill 與 plugin 收藏，同時是一個可供安裝的 marketplace。

## Language

### 內容的種類

**Skill**:
一個含 `SKILL.md` 的資料夾，是可被 agent 載入的最小單位。

**散裝 skill**:
不屬於任何 plugin、單獨存在的 skill。
_Avoid_: 獨立 skill、單一 skill

**Plugin**:
帶有 `plugin.json` 的套件，可包含多個 skill 以及其他元件。
_Avoid_: 套件包、skill 合集

### 內容的來源

**自製**:
檔案存放在這個 repo 裡的散裝 skill 或 plugin。
_Avoid_: 自己的、本地的

**外部**:
檔案存放在別人 repo 裡的散裝 skill 或 plugin；這個 repo 只持有指向它的條目，不持有檔案。
_Avoid_: 第三方、收藏的、curated

### Marketplace

**條目**:
marketplace 清單裡的一筆記錄，對應一個可安裝的散裝 skill 或 plugin。它是安裝、鎖定版本、更新的最小單位。
_Avoid_: 項目、entry、清單項

**鎖定版本**:
外部條目所固定的對方 repo 的某一個 commit。自製條目沒有鎖定版本。
_Avoid_: 鎖 sha、pin、釘版本
