---
name: update_doc
description: |
  开发文档健康度审计与更新。当用户说"整理文档"、"审计文档"、"更新 dev_doc"、"检查文档过时"、"整理 .dev_doc"、"doc audit"、"文档健康度"或任何涉及 .dev_doc/ 目录下文档整理、健康度检查、废弃内容清理时，必须使用此 skill。
  也适用于：大规模代码变更后检查文档一致性、PR/分支合并前文档核查。
  此 skill 是通用跨项目 skill，适用任何包含 .dev_doc/ 的项目。
  不执行任何外部脚本，只通过 LLM 的原生工具（Glob、Grep、Read 等）完成审计。
---

## 第一步：定位项目与初始化状态

### 1.1 找到 .dev_doc/ 目录
从当前工作目录向上查找，找到包含 `.dev_doc/` 的项目根目录。

### 1.2 检查审计状态目录
检查 `.dev_doc/.update_doc_state/` 是否存在：
- 若不存在，用 **Write** 工具创建它

### 1.3 读取已忽略问题
读取 `.dev_doc/.update_doc_state/dismissed.json`（如果存在），获取用户已永久忽略的 issue_id 列表。

### 1.4 读取上次审计日期
读取 `.dev_doc/.update_doc_state/audit_state.json`（如果存在），获取 `last_audit` 字段。

---

## 第二步：收集所有文档

使用 **Glob** 工具：

```
pattern: .dev_doc/**/*.md
```

过滤掉 `.dev_doc/.update_doc_state/` 下的文件。
记录总文档数。

---

## 第三步：构建文档引用关系

使用 **Grep** 工具扫描所有 `.dev_doc/` 下的 `.md` 文件：

**任务 1：统计每个文档被引用的次数（孤立文档检测）**
- pattern: 文件名（如 `architecture.md`）
- 在所有 `.dev_doc/*.md` 中搜索该文件名
- 被引次数 = 0 → 标记为孤立文档候选 → **LOW**

**任务 2：收集所有内部 .md 链接**
- pattern: `](` 找出所有 `](xxx.md)` 和 `](../xxx.md)` 链接
- 将链接中的目标路径解析为绝对路径
- 用 **Glob** 验证每个链接目标是否存在
- 不存在 → 记录为 `broken_md_link` → **HIGH**

---

## 第四步：审计维度（逐项执行）

对每份文档执行以下检查，通过 **Read** 读取文档内容，**Grep** 验证引用：

### 4.1 broken_ref — 代码文件引用失效（HIGH）
在文档中搜索 `.py` 文件路径（`xxx.py`、`Agent/xxx.py`、`extra_function/...py` 等）。
用 **Glob** 验证每个引用的文件是否存在于项目目录。

### 4.2 deprecated — 废弃内容不一致（HIGH / MEDIUM）
用 **Grep** 在文档中搜索关键词：
- `废弃`、`deprecated`、`obsolete`、`已删除`、`已移除`、`nano.*废弃`、`废弃.*nano`
- 找到后，用 **Grep** 在代码中确认该内容是否仍存在
  - 文档说废弃但代码仍存在 → **HIGH**（不一致）
  - 文档说废弃且代码已清理 → **MEDIUM**（建议更新措辞）

### 4.3 multi_version — 多版本文档并存（MEDIUM）
用 **Glob** 扫描 `.dev_doc/` 下所有 `.md` 文件，识别有版本后缀的文件（如 `xxx_v5.md`、`xxx v5.6.md`、`xxx-v2.md`）。
同系列有两个以上版本 → 保留最新，旧版本标记为待归档 → **MEDIUM**

### 4.4 stale_plan — 过期计划文件（MEDIUM）
用 **Glob** 识别 `YYYY-MM-DD-*.md` 格式文件（日期前缀的计划/设计文档）。
读取 `work_done.md` 和 `status.md`，检查该计划是否已标记完成（`已完成`、`done`、`completed`）。
若计划已完成但文档仍在根目录未归档 → **MEDIUM**

### 4.5 orphaned — 孤立文档（LOW）
根据第三步收集的引用统计，无任何其他文档引用的文档 → **LOW**

---

## 第五步：记录问题并生成 issue_id

对每个发现的问题，用 **Write** 工具创建稳定可重复的 issue_id：

**issue_id 生成规则**：
将以下字符串拼接后计算 md5 前12位：
```
"doc路径 | 行号 | 信号文本 | 问题类型"
```

**问题记录格式**（供后续第六步使用）：
```
[issue_id] | [risk] | [category] | [doc] | [line] | [signal] | [problem] | [suggestion]
```

过滤：已存在于 dismissed.json 的 issue_id 跳过，不出现在报告中。

---

## 第六步：生成诊断报告

使用 **Write** 工具，将报告写入：
`.dev_doc/.update_doc_state/diagnostic_report_<YYYYMMDD>.md`

**报告结构**：

```markdown
# .dev_doc 文档健康度诊断报告

**生成时间**：YYYY-MM-DD HH:mm
**审计范围**：.dev_doc/ 下所有 .md 文件（X 个）
**上次审计**：YYYY-MM-DD（首次审计则注明）

---

## 执行摘要

| 风险等级 | 数量 | 状态 |
|---------|------|------|
| HIGH    | X    | ⚠️  待处理 |
| MEDIUM  | X    | 📋  建议处理 |
| LOW     | X    | 💡  可选处理 |
| 已忽略  | X    | 🔕 永久忽略 |

---

## HIGH 级问题（必须处理）

### [#N] [category] — [问题简述]
**文档**：`.dev_doc/xxx.md`，第 N 行
**信号**：`[引用的原始文本]`
**问题**：`[问题描述]`
**建议**：`[修复建议]`
**Issue ID**：`[issue_id]`

> [FIX] [IGNORE] [SKIP]

---

## MEDIUM 级问题（建议处理）

### [MN] [category] — [问题简述]
...

## LOW 级问题（可选处理）

### [LN] [category] — [问题简述]
...

---

## 当前文档架构

[.dev_doc/ 目录树]

---

## 下次审计建议

建议在下一次大规模代码变更后或 PR 合并前再次运行 `/update_doc`。
```

---

## 第七步：向用户逐项确认

按 HIGH → MEDIUM → LOW 顺序展示每个问题。
**对每个问题，用户选择一项**：

| 选择 | 操作 |
|------|------|
| **FIX** | LLM 直接执行修复（用 Edit/Delete/Rename 工具），更新文档或移动/删除文件 |
| **IGNORE** | 将该 issue_id 追加写入 `.dev_doc/.update_doc_state/dismissed.json` |
| **SKIP** | 不记录，本次跳过，下次审计仍会出现 |

---

## 第八步：更新审计状态

用 **Write** 工具更新 `.dev_doc/.update_doc_state/audit_state.json`：

```json
{
  "last_audit": "YYYY-MM-DD",
  "total_docs": X,
  "issues_count": {
    "HIGH": X,
    "MEDIUM": X,
    "LOW": X,
    "dismissed": X
  }
}
```

---

## 注意事项

- 审计前先执行 `git status`，确保工作目录已提交
- FIX 操作中涉及删除/移动文件时，先 `git add` 当前状态
- 如果 `.dev_doc/` 超过 50 个文件，分批处理并向用户说明进度
- dismissed.json 的记录仅对同一 issue_id 有效，不扩展到整篇文档
- 报告中所有 Issue ID 均为稳定哈希，下次审计可精确匹配已忽略项
