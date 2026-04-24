---
name: doc_integrate
description: |
  文档整合与同步维护 Skill。当用户说"整理文档"、"organize docs"、"合并文档"、"更新开发文档"、"同步文档和代码"，
  或执行 `/doc_integrate` 命令时触发。

  核心能力：
  1. 扫描散落到各处的文档，统一整合到 .dev_doc/ 中对应模块的规范路径
  2. 以代码为真，验证文档描述与实际实现是否一致
  3. 将开发、设计文档总结或合并到对应模块的 README.md（追加或修改）
  4. 生成/更新 CHANGELOG.md，记录文档变更和代码变动（git log）

  **绝对不允许**：创建 .archive/ 归档路径、保留非规范路径的文档
  不做：健康度诊断报告、不做任何操作只生成"待开发"列表。
---

# doc_integrate: 文档整合与同步维护

★ Insight ─────────────────────────────────────
**核心原则：代码是唯一的真，文档必须追代码**。
文档状态标记可能过时（开发中断、遗忘更新），但代码不会说谎。
**归档不是整理，是逃避**。文档散落的解决方案是合并到规范路径，不是移走。
**操作对象是文件，不是目录**。不删除目录，只删除文件；不创建目录，只创建文件。
─────────────────────────────────────────────────

---

## 整理原则（优先级排序）

### 原则 1：模块归并
**相关模块应该合并到统一路径**。
- 例：`vector-schema-sync` + `vector-store-async-query` → `vector_store/`
- 例：`milvus-id-field-fix` + `vector-schema-sync` → `vector_store/`（如果都是向量库相关）

**识别方法**：
- 通过代码目录判断：`extra_function/utils/vector_stores` → `vector_store/`
- 通过功能关键词判断：async_query、MilvusAdvanceDB → 向量库模块

### 原则 2：功能整合
**相似的功能模块应该统一整合到一个文档中**。
- 例：异步查询设计（async_query） + 工厂动态支持（factory dynamic）→ 都整合到 `vector_store/README.md`
- 避免：同一个模块功能分散在多个 design.md 中

### 原则 3：完成后合并
**已完成的模块不应该继续保留 design/plan/status 分散文档**。
- ✅ 已完成：design.md + plan.md + status.md → 合并成 `模块/README.md` 的章节
- ⚠️ 进行中：保留 design/plan/status，完成后合并
- ✅ changelog.md → 合并到 `模块/CHANGELOG.md`

### 原则 4：规范路径优先
**模块应在规范路径下，不在临时 feature 目录**。
- `vector_store/` ✅ 是规范路径
- `vector-schema-sync/` ❌ 是临时目录，应该清空合并

### 原则 5：进行中模块不强制合并
**仍在开发的模块（Phase < 6）暂时不处理**。
- 等模块完成后再一次性合并
- 避免多次合并导致文档碎片化

### 原则 6：文档拆分整合
**设计文档不应单独存放，应拆分整合到 README 和 CHANGELOG**。

| 文档内容 | 处理方式 |
|----------|----------|
| 具体设计思路 | → 整合到 `模块/README.md` 对应章节 |
| 变更记录 | → 整合到 `模块/CHANGELOG.md` |
| 待执行计划 | → 整合到 README 作为"待实现"章节 |
| Bug 修复记录 | → 整合到 `模块/CHANGELOG.md` |

**示例**：`2026-04-07-qdrant-payload-schema-design.md` 这类设计文档
- 设计思路（7个问题的解决方案）→ `vector_store/README.md §Qdrant Schema 校验`
- 变更记录 → `vector_store/CHANGELOG.md`
- 文档本身 → 删除

**例外**：如果设计文档包含大量代码示例/详细任务分解（>200行），可保留在 `design/` 子目录，README 添加引用。

### 原则 7：散落文档归类
**所有非标准路径的文档都应归类到规范模块目录下**。

| 散落文档 | 归属 | 处理方式 |
|----------|------|----------|
| `test_fix_plan.md` | `database/` | 整合到 README 作为"待处理" |
| `excel-test-case-library-plan.md` | `database/` | 整合到 README 作为"待实现" |
| `项目代码优化修改.md` | `vector_store/` | 已完成 → CHANGELOG；未完成 → README |
| `text2sql_skill_suite_design.md` | `database/` | 概要 → README，详细 → `design/` |

---

## 概述

本 skill 是 ez-dev 开发流程的收尾环节。ez-dev 创建的 `.dev_doc/<feature>/` 文档（design.md、plan.md、changelog.md）
在开发完成后需要整合到对应模块的 README 中。

**零归档政策**：
- 绝对不创建 `.archive/` 目录
- 不存在"归档"这个选项
- 文档只有两种结局：整合到规范路径，或删除（如果真的毫无价值）

---

## 核心流程

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. 扫描散落文档                                                     │
│     ├── 扫描 .dev_doc/ 根目录的日期前缀文档（YYYY-MM-DD-*.md）        │
│     ├── 扫描非规范路径的散落文档（.archive/ 已禁止）                   │
│     ├── 识别 ez-dev 遗留文档（.dev_doc/<feature>/）                   │
│     └── 构建《文档处理表》                                            │
│                                                                     │
│  2. 代码验证（核心步骤）                                              │
│     ├── 检查文档提到的关键文件是否存在                                 │
│     ├── 对比接口签名、方法实现是否与文档描述一致                      │
│     ├── 用 git log 确认代码实际变动时间                               │
│     └── 决策：整合 / 删除                                            │
│                                                                     │
│  3. 整合执行                                                         │
│     ├── 已完成且代码验证通过 → 合并到模块 README                     │
│     ├── 代码已实现但文档过时 → 更新文档后合并                         │
│     ├── 内容重复或无价值 → 删除                                       │
│     └── 更新模块 CHANGELOG.md                                        │
│                                                                     │
│  4. 同步维护                                                         │
│     ├── 修正文档中与代码不一致的描述                                 │
│     └── 记录同步修正到 CHANGELOG                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 决策树：如何处理每份文档

```
文档
  │
  ├─ 是否提到具体代码文件或方法？
  │   │
  │   ├─ 否 → 检查是否为核心文档（architecture.md 等）
  │   │        ├─ 是 → 移动到 .dev_doc/ 根目录（规范位置）
  │   │        └─ 否 → 内容有价值？→ 合并到相关模块 README
  │   │                否则 → 删除
  │   │
  │   └─ 是 → 代码验证
  │        │
  │        ├─ 代码存在 → 提取文档关键内容，合并到模块 README
  │        │
  │        ├─ 代码不存在
  │        │   ├─ 文档日期 < 30天 → 保留在根目录（可能需要开发）
  │        │   └─ 文档日期 >= 30天 → 删除（不是归档，是丢弃）
  │        │
  │        └─ 无法判断 → 用 git log 确认
  │
  └─ 特殊情况
       │
       ├─ .dev_doc/<feature>/ 目录 → ez-dev 遗留
       │    → 已完成：提取关键内容合并到模块 README
       │    → 未完成：保留在原目录（还不是散落文档）
       │
       └─ 冗余/重复文档 → 合并到最相关的模块 README，删除原文
```

★ Insight ─────────────────────────────────────
**"归档"是一个谎言**。它只是把文档从 A 路径移到 B 路径，
阅读者仍然需要知道它的存在。整合才是真正的整理：
把内容合并到阅读者本来就会去的地方（模块 README）。
─────────────────────────────────────────────────

---

## 状态判断规则

**文档状态标记只是参考，代码才是最终依据。**

| 文档标记 | 实际判断 |
|----------|----------|
| `状态：**已完成开发**` | ✅ 代码验证后整合到模块 README |
| `状态：**开发中**` | ⚠️ 检查代码是否完成，完成则整合 |
| `状态：**方案设计**` / `状态：**待开发**` | 代码验证：存在则更新后整合，不存在则删除 |
| 无状态标记 | 视为"未完成"，按代码验证处理 |
| 30天以上旧文档无完成标记 | 默认删除，除非代码验证通过 |

---

## 规范路径（必须遵守）

```
.dev_doc/
├── .archive/              ← ❌ 禁止创建，已废弃
├── architecture.md        ← ✅ 根目录核心文档，可保留
├── vector_stores/         ← ✅ 模块规范路径
│   ├── README.md
│   ├── CHANGELOG.md
│   └── design/           ← ✅ 设计文档放此处，README 引用
├── data_process/          ← ✅ 模块规范路径
│   ├── README.md
│   └── CHANGELOG.md
└── <feature>/             ← ez-dev 临时目录，完成后应清空
```

**任何不在上述规范路径的文档，都是待整理对象。**

---

## 模块归属识别

通过代码目录判断模块归属：

| 模块 | 代码路径 | 规范路径 |
|------|----------|----------|
| vector_stores | `extra_function/utils/vector_stores/` | `.dev_doc/vector_stores/` |
| database | `extra_function/.../db/` 或 `DBAnalyser` | `.dev_doc/data_process/` |
| timeseries | `timeseries`、`InfluxDB`、`DuckDB` | `.dev_doc/data_process/timeseries/` |
| memory | `memory`、`mem0`、`pensieve` | `.dev_doc/memory/` |
| ptc | `ptc`、`StepExecutor`、`ActionRouter` | `.dev_doc/ptc/` |
| rag | `rag`、`RAG`、`Retrieval_RAG` | `.dev_doc/rag/` |
| llm_compatibility | `llm_compat`、`OpenAICompatibleClient` | `.dev_doc/llm_compatibility/` |

**归并识别**：多个 feature 目录可能属于同一模块。
- `vector-schema-sync` + `vector-store-async-query` + `vector_store_refactor` → 都归入 `vector_stores/`
- `llm-compat-fix` → 归入 `llm_compatibility/`

---

## 整合策略

### 小变动（追加到 README）

- bugfix
- 单个方法改动
- 配置变更

→ 在模块 README 对应章节下追加变更记录

### 大变动（新增章节）

- 新增 provider
- 架构重构
- 多文件联动

→ 新增独立章节或独立文档（README 引用）

### 设计文档

- 完整架构图、流程图
- 长期迭代维护的设计
- 跨模块复杂设计

→ 移动到模块的 `design/` 子目录，README 添加「相关设计」引用

### 冗余文档

- 内容已被其他文档覆盖
- 重复描述同一功能

→ 合并到最相关的模块 README，删除原文

---

## 代码验证方法

### 1. 文件存在性检查

```bash
ls <文档中提到的文件路径>
```

### 2. 方法签名对比

```bash
grep -n "def <方法名>" <文件路径>
```

### 3. Git 历史确认

```bash
git log --oneline --since="<文档日期>" -- <相关代码目录>
```

---

## ez-dev 遗留文档处理

ez-dev 为每个功能创建 `.dev_doc/<feature>/`，包含：

| 文件 | 处理方式 |
|------|----------|
| `status.md` | feature 已完成则提取关键状态到模块 README，未完成则保留 |
| `design.md` | 整合到模块 README 或 `design/` 子目录 |
| `plan.md` | 有价值？→ 合并到模块 README；无价值 → 删除 |
| `changelog.md` | 合并到模块 CHANGELOG |
| 整个 `<feature>/` 目录 | feature 完成后清空，目录本身可删除 |

### 归并处理：多个 feature 目录属于同一模块

**示例**：`vector-schema-sync/` + `vector-store-async-query/` + `vector_store_refactor/` → 都归入 `vector_store/`

处理步骤：
1. 读取每个 feature 目录的 `status.md`，判断是否完成（Phase 6）
2. 已完成模块：提取关键内容（设计决策、变更记录）到模块 README
3. 将各模块的 changelog 合并到模块 CHANGELOG.md
4. 删除各 feature 目录的文件，然后删除目录本身

### 进行中模块不处理

**示例**：`vector-store-factory-dynamic/`（Phase 3.1+3.2）、`llm_compatibility/`（Phase 5.5）

处理原则：
- 等模块完成后再一次性归并
- 避免多次归并导致文档碎片化

---

## CHANGELOG 格式

```markdown
# 模块名 CHANGELOG

## [未整合] YYYY-MM-DD

### 文档变更
- 合并 `2026-03-30-xxx-design.md` 到 README
- 更新 `advanced_search()` 接口描述以匹配 v6.0 实现

### 代码变动（git log）
- `extra_function/utils/vector_stores/providers/local_vector_store.py`
  - 实现 `advanced_search()` 多向量字段支持

### 同步记录
- 文档与代码不一致处已修正：`LocalVectorStore._extract_vector` 逻辑
```

---

## 执行步骤

### Step 1: 扫描散落文档

1. 扫描 `.dev_doc/` 根目录的日期前缀文档（YYYY-MM-DD-*.md）
2. 检查是否存在 `.archive/` 目录（若存在，扫描其内容）
3. 识别 `ez-dev` 遗留文档（`.dev_doc/<feature>/`）

**排除**：architecture.md、status.md、todo.md、work_done.md、开发文档编写原则/

### Step 2: 代码验证（每份文档必须执行）

1. 读取文档，提取关键文件路径
2. 检查文件是否存在
3. 对比接口签名
4. 用 git log 确认代码变动时间
5. 输出决策建议

### Step 3: 执行整合

**代码存在且验证通过 → 合并**
1. 将文档内容合并到模块 README 或移动到 `design/` 子目录
2. 更新模块 CHANGELOG

**代码不存在或已废弃 → 删除**
1. 直接删除文档
2. 在 CHANGELOG 中记录"已删除：<文档名>，原因：代码不存在/无价值"

**注意**：删除不是归档，是明确丢弃。如果文档可能有价值但代码不存在，先检查 git log 确认。

### Step 4: 验证规范路径

1. 确认没有文档留在 `.archive/` 或其他非规范路径
2. 如果发现 `.archive/` 目录存在且有内容，将其文档按上述规则处理，然后删除该目录
3. 输出最终报告

### Step 5: 输出报告

```markdown
# 文档整合报告 - YYYY-MM-DD

## 整合统计
| 状态 | 数量 |
|------|------|
| ✅ 已整合到模块 README | X |
| 📁 已移至 design/ 子目录 | X |
| 🗑️ 已删除（无价值/冗余） | X |
| ❌ 保留在根目录（可能需要开发） | X |

## 整合详情
[每份文档的处理结果和理由]

## 规范路径验证
- .archive/ 目录：✅ 已清理 / ❌ 仍存在（需处理）
- 非规范路径文档：✅ 已全部整合 / ❌ 仍有散落
```

---

## 注意事项

1. **不要生成"待开发"列表** - 每个文档必须有明确处理结果
2. **代码是最终依据** - 文档与代码不符时，以代码为准更新文档
3. **不要保留在 limbo** - 不要说"待后续处理"，要立即决策
4. **git log 是好帮手** - 可以确认代码实际实现时间
5. **.archive/ 绝对禁止** - 发现即清理，不允许存在
6. **删除优于归档** - 如果文档真的没价值，删除它比移到一个没人看的目录更好
7. **操作对象是文件，不是目录** - 只删除文件，不删除目录；不创建目录，只创建文件
