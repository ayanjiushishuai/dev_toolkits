---
name: ez-dev
description: "完整开发流程skill，串联需求分析→独立Review→设计→独立Review→计划→独立Review→TDD开发→用例生成+执行→质量抽查→完成。触发条件：用户提出"帮我开发..."、"实现一个..."、"添加...功能"、"修复...bug"、"新功能"、"特性实现"等明确开发请求时。**核心原则**：前期充分高沟通+严格独立Review发现问题，Review失败后**自纠闭环不等待确认**，中后期LLM自主决策，通过测试验证。小改动可走**快速路径**。**需要用户确认的节点**：Phase 1 方案选择、Phase 2 设计敲定、Phase 6 完成最终确认。Phase 6开发完成后自动整合文档，由用户手动merge。"
---

# EZ-DEV: 完整开发流程

★ Insight ─────────────────────────────────────
这个skill是严格的线性流程，每个Phase必须按顺序执行。
所有 Review 节点都由**独立 Subagent** 执行，不持有前序 Phase 上下文。
所有开发必须在 worktree 中进行。
Review 失败 → 返回对应 Phase 调整 → 重新 Review（必须通过）。
─────────────────────────────────────────────────

---

## 独立 Review 机制

### 通用规则（适用于所有 Review 节点）

**Review Agent 启动方式：**
- 启动独立 Subagent，不加载前序 Phase 的对话上下文
- 只读取必要的文档文件（`.dev_doc/<feature>/` 下的对应文档）
- 以"刚接手这个需求的新开发者"视角进行审查

**Review 结论：**
| 结论 | 含义 | 后续动作 |
|------|------|----------|
| ✅ 通过 | 无严重问题 | 进入下一 Phase |
| ❌ 不通过 | 发现需要修正的问题 | 返回对应 Phase 调整后，**重新执行独立 Review** |

**失败循环：** Review 不通过 → 调整 → 重新 Review → 通过 → 继续。任何 Phase 的 Review 都必须通过才能进入下一 Phase。

### Review 节点一览

| Phase | Review 内容 | 输入文档 | 并发 |
|-------|-------------|----------|------|
| Phase 1.5 | 独立方案自审 | design.md、模块代码 | |
| Phase 2.5 | 独立设计 Review | design.md、requirement.md | |
| Phase 3.1 + 3.2 | 计划完整性 + 合规门禁 | plan.md、design.md | ✅ 并发 |
| Phase 5.1 | 用例生成+执行 | plan.md、design.md、worktree 代码 | 独立 Subagent |
| Phase 5.5 | 用例质量抽查+代码确认 | plan.md、tests/ 用例、worktree 代码 | 独立 Subagent |

---

## ⚠️ CRITICAL RULES

**以下规则无论任何情况都必须遵守：**

| 规则 | 说明 | 违规后果 |
|------|------|----------|
| **Worktree 强制** | 所有代码开发必须在 worktree 中进行，禁止直接在本地分支写代码 | 主分支污染 |
| **Review 强制** | 所有 Review 节点必须由独立 Subagent 执行，失败必须返回调整 | 质量无保证 |
| **Phase 顺序** | 禁止跳过任何 Phase，每个 Phase 都必须完整执行 | 流程残缺 |
| **Phase 声明** | 进入新 Phase 时必须向用户声明当前阶段 | 用户失去掌控 |
| **文档存储** | superpower skill 产出文档必须存储在 `.dev_doc/<feature>/` 下，参见 `references/document-storage.md` | 文档散落 |
| **merge 用户手动** | merge 操作由用户执行，AI 不自动合并 worktree | 人工确认缺失 |

---

## 🔄 自纠闭环原则

**核心改变：Review 失败后立即自纠，不再等用户确认。**

| 需要用户确认的节点 | 不需要用户确认（自主闭环） |
|--------------------|---------------------------|
| Phase 1 方案选择（多方案对比后） | Phase 1.5 Review 失败 → 自纠 → 重新 Review |
| Phase 2 设计敲定 | Phase 2.5 Review 失败 → 自纠 → 重新 Review |
| Phase 6 完成最终确认 | Phase 3.1/3.2 Review 失败 → 自纠 → 重新 Review |
| **重大方向变动**（需用户决策） | Phase 5.1 执行失败 → 自纠 → 重跑测试 |
|  | Phase 5.5 Review 失败 → 自纠 → 重新测试 → 重新 Review |

**自纠循环规则：**
- Review 失败 → 立即根据 Review 意见自纠 → 重新执行 Review
- 自纠后仍然失败 → 再给 1 次机会（最多 2 次 Review 循环）
- **2 次后仍失败 → 区分问题类型处理：**
  - **致命问题**（阻断功能交付）：暂停，向用户汇报卡点，请求决策
  - **非致命问题**（不影响核心功能）：记录问题，继续后续流程

**⚠️ 注意：** Phase 1 方案选择和 Phase 2 设计敲定仍需用户批准，这是因为这是"方向性"决策，后续工作基于此展开，需要用户的 domain knowledge。Review 失败后的自纠是对已批准方案的修正，不涉及方向改变。

---

## 配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `WORKTREE_BASE_DIR` | `.worktrees` | worktree 根目录 |
| `DEFAULT_BRANCH` | `dev_zby` | 基于分支创建 worktree |

> 如果项目有 CLAUDE.md 规定，以项目规定优先

---

## 快速路径

★ Insight ─────────────────────────────────────
**不是所有任务都需要跑完完整流程**。
对于小改动，可以走快速路径，节省 9 个 Phase。
关键判断：改动是否真的"小而独立"。
─────────────────────────────────────────────────

### 快速路径条件（必须同时满足）

| 条件 | 说明 | 反例 |
|------|------|------|
| 改动范围 | 单一文件，修改 < 30 行 | 多文件、跨模块 |
| 复杂度 | 无新增接口/函数/依赖 | 新增 API、数据库迁移 |
| 依赖 | 无外部依赖变化 | 需要新依赖、新配置 |
| 用户意图 | 用户明确说"快速"、"简单"、"小改动" | 用户说"认真做"、"完整实现" |
| 测试 | 已有测试覆盖或无需测试 | 需要新增测试用例 |

**判断决策：**
```
用户请求 → 满足全部 5 项条件？ → 是 → 快速路径
                            → 否 → 完整流程
```

### 快速路径流程

```
Phase 1      简化 brainstorming（直接确认范围）
    ↓
Phase 4      TDD开发（串行，单一 worktree）
    ↓
Phase 5.2    测试执行（如有测试）
    ↓
Phase 6      完成（简化版，跳过 doc_integrate）
```

**绕过 Phase：**
- Phase 1.5（方案自审）→ 跳过
- Phase 2（设计方案）→ 简化
- Phase 2.5（设计 Review）→ 跳过
- Phase 3（实现计划）→ 跳过
- Phase 3.1+3.2（计划 Review）→ 跳过
- Phase 4.1（代码 Review）→ 跳过
- Phase 5, 5.1, 5.5 → 简化或跳过

**⚠️ 快速路径限制：**
- 仍必须在 worktree 中开发
- 仍需用户确认方案（简化版）
- 如开发中发现复杂度超出预期 → 切换回完整流程

---

## 阶段状态追踪

**输出文件:** `.dev_doc/<feature>/status.md`

> ⚠️ **重要**: 每个功能必须使用独立的状态文件路径，格式为 `.dev_doc/<功能名>/status.md`

**状态文档结构:**
```markdown
# 开发状态

## 当前阶段
- **Phase:** [Phase X]
- **功能:** [功能名称]
- **状态:** [进行中/暂停/已完成]
- **更新:** [YYYY-MM-DD HH:mm]

## 开发进度
- [ ] 需求分析 (Phase 1)
- [ ] 独立方案自审 (Phase 1.5) ← 独立 Subagent
- [ ] 设计方案 (Phase 2)
- [ ] 独立设计 Review (Phase 2.5) ← 独立 Subagent
- [ ] 实现计划 (Phase 3) ← 必须包含并发可行性分析
- [ ] 并行独立 Review (Phase 3.1 + 3.2) ← 独立 Subagent 并发执行
- [ ] TDD开发 (Phase 4) ← 可选多 Subagent 并发
- [ ] 并发合流 (Phase 4.5) ← 仅并发开发时有
- [ ] 用例生成+执行 (Phase 5.1) ← 独立 Subagent
- [ ] 用例质量抽查 (Phase 5.5) ← 独立 Subagent
- [ ] Worktree 提交 (Phase 5.6)
- [ ] 完成 (Phase 6) ← 自动调用 doc_integrate

## Review 记录
| Phase | Review 结果 | 日期 |
|-------|------------|------|
| Phase 1.5 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 2.5 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 3.1 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 3.2 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 5.5 | ✅通过/❌不通过 | YYYY-MM-DD |

## 注意事项
- [当前需要注意的事项]
```

**更新时机:** Phase 转换时（必须）、每次开发暂停前

---

## Phase 1: 需求分析

**调用 skill:** `superpowers:brainstorming`

**沟通程度:** 极高

**任务:** 深入理解需求，通过 brainstorming 多轮提问确认，列举候选方案评估影响范围

**步骤:**
1. **启动 brainstorming skill** 进行需求澄清
2. brainstorming 通过多轮提问探索需求
3. **方案选择阶段需要多方案对比和用户批准**
4. **列举具体开发方案，评估涉及模块，说明影响范围**

**方案评估要求（必须执行）:**
```
在进入 Phase 2 前，必须向用户展示：

## 候选方案对比

### 方案 A: [方案名称]
- **实现思路:** [简要描述]
- **涉及模块:** [列出所有会修改的模块]
- **影响范围:** [对上下游、其他功能的影响]
- **风险点:** [主要技术风险]
- **预估复杂度:** [高/中/低]

### 方案 B: [方案名称]
- ...

## 模块影响分析
| 模块 | 影响程度 | 说明 |
|------|----------|------|
| [模块A] | 高/中/低 | [具体影响] |
| [模块B] | 高/中/低 | [具体影响] |

请选择您期望的方案，或提出修改意见。
```

**阶段声明:**
```
📋 进入 Phase 1: 需求分析
请描述您的需求，我将通过多轮提问澄清关键细节...
```

**文档存储:** ⚠️ 参见 `references/document-storage.md`

**完成标准:** 用户明确批准了某一方案及其影响范围

---

## Phase 1.5: 独立方案自审

**沟通程度:** 低（独立 Subagent 执行）

**触发时机:** Phase 1 用户批准方案后

**任务:** 启动独立 Subagent，以"接手者"视角审查方案，读取设计文档和模块代码进行自审

**执行方式:**
```
启动独立 Subagent（Agent tool）：
- 角色：刚接手需求的新开发者
- 只读取：.dev_doc/<feature>/design.md、相关模块代码
- 不加载：Phase 1 的对话上下文
- 任务：按照 references/design-review.md 的 Phase 1.5 清单逐项检查
```

**输出:** `.dev_doc/<feature>/design-review.md`

**Review 检查清单:** 参见 `references/design-review.md` 的 Phase 1.5 清单

**阶段声明:**
```
🔍 进入 Phase 1.5: 独立方案自审
正在启动独立 Review Agent...
```

**Review 失败处理:**
- Review Agent 报告问题 → 直接在设计文档中调整方案 → 重新执行 Phase 1.5 Review
- ⚠️ **自纠闭环原则**：Review 失败后立即自纠，不要停下来等用户确认
- 自纠后 Review 仍然失败 → 再给 1 次机会（最多 2 次循环）
- 2 次后仍失败 → 致命问题暂停报告用户，非致命问题记录继续

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 2: 设计方案

**调用 skill:** 场景化

| 场景 | 调用 skill |
|------|-----------|
| 前端界面/组件 | `frontend-design:frontend-design` |
| 文档/笔记管理 | `obsidian:obsidian-markdown` |
| API/后端开发 | `superpowers:brainstorming` |
| 其他 | `superpowers:brainstorming` |

**沟通程度:** 高

**文档存储:** ⚠️ 参见 `references/document-storage.md`

**阶段声明:**
```
🎨 进入 Phase 2: 设计方案
正在为您设计详细方案...
```

**完成标准:** 用户批准了设计方案

---

## Phase 2.5: 独立设计 Review

**沟通程度:** 低（独立 Subagent 执行）

**触发时机:** Phase 2 用户批准设计后

**任务:** 启动独立 Subagent，以"接手者"视角审查设计方案

**执行方式:**
```
启动独立 Subagent（Agent tool）：
- 角色：刚接手需求的新开发者
- 只读取：.dev_doc/<feature>/design.md、requirement.md、plan.md
- 不加载：Phase 1-2 的对话上下文
- 任务：按照 references/design-review.md 的 Phase 2.5 清单逐项检查
```

**输出:** Review 报告

**Review 检查清单:** 参见 `references/design-review.md` 的 Phase 2.5 清单

**阶段声明:**
```
🔍 进入 Phase 2.5: 独立设计 Review
正在以接手者视角审查设计方案...
```

**Review 失败处理:**
- Review Agent 报告问题 → 直接在 design.md 中调整设计 → 重新执行 Phase 2.5 Review
- ⚠️ **自纠闭环原则**：Review 失败后立即自纠，不要停下来等用户确认
- 自纠后 Review 仍然失败 → 再给 1 次机会（最多 2 次循环）
- 2 次后仍失败 → 致命问题暂停报告用户，非致命问题记录继续

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 3: 实现计划

**调用 skill:** `superpowers:writing-plans`

**沟通程度:** 中

**文档存储:** ⚠️ 参见 `references/document-storage.md`

**步骤:**
1. 计划保存到 `.dev_doc/<feature>/plan.md`
2. 包含每个步骤的：精确文件路径、测试代码框架、运行命令
3. **⚠️ 必须分析并发可行性**：在计划中明确标注哪些模块可并发执行

**并发可行性分析要求:**
```
## 并发可行性分析

### 可并发模块（无依赖，可并行开发）
| 模块 | 依赖关系 | 说明 |
|------|----------|------|
| 模块A | 独立 | 无文件/数据依赖 |
| 模块B | 独立 | 无文件/数据依赖 |

### 不可并发模块（必须串行）
| 模块 | 依赖关系 | 说明 |
|------|----------|------|
| 模块C | 依赖模块A | 需等模块A完成后才能开始 |

### 并发执行方案
如果存在可并发模块 → 采用多 Subagent 并行开发
如果无可并发模块 → 采用串行开发
```

**阶段声明:**
```
📝 进入 Phase 3: 实现计划
正在制定详细实现计划...
正在分析并发可行性...
```

**完成标准:** 计划文档完成，包含并发可行性分析

---

## Phase 3.1 + 3.2: 并行独立 Review（可并发执行）

**沟通程度:** 低（独立 Subagent 执行）

★ Insight ─────────────────────────────────────
Phase 3.1 和 Phase 3.2 可以**并发执行**：
- 两者读取相同的文档（plan.md、design.md）
- 检查维度不同（完整性 vs 合规性）
- 并行节省时间，且互不影响
─────────────────────────────────────────────────

**触发时机:** Phase 3 计划文档完成后

**并发执行方式:**
```
同时启动两个独立 Subagent（Agent tool）：

Subagent A - 计划完整性审查：
- 角色：刚接手需求的新开发者
- 只读取：.dev_doc/<feature>/plan.md、design.md
- 不加载：Phase 1-3 的对话上下文
- 任务：检查计划是否完整、无 TODOs/占位符、任务分解清晰可执行

Subagent B - 合规门禁审查：
- 角色：质量审计员
- 只读取：.dev_doc/<feature>/plan.md、design.md、requirement.md
- 不加载：Phase 1-3 的对话上下文
- 任务：按照合规检查清单逐项审查
```

**Phase 3.1 检查项:**
- [ ] 计划是否完整（无 TODOs、占位符）
- [ ] 任务分解是否清晰可执行
- [ ] 是否与设计对齐
- [ ] 每个功能点都有对应实现步骤
- [ ] 每个功能点都有对应测试计划

**Phase 3.2 检查清单:**

| 检查项 | 通过标准 |
|--------|----------|
| 需求覆盖 | 原需求中的每个功能点都有对应的实现计划 |
| 无过度设计 | 没有实现需求范围之外的功能 |
| 实现路径 | 每个功能点都有明确的实现方案 |
| 风险识别 | 已识别并规划了主要技术风险 |
| 测试计划 | 每个功能点都有对应的测试用例 |
| 影响分析 | 已分析改动对其他模块及上下游的可能影响 |

**阶段声明:**
```
🔍 进入 Phase 3.1 + 3.2: 并行独立 Review
正在同时审查计划完整性和合规性...
```

**Review 失败处理:**
- **并发 Review 只需都通过，任一失败 → 一起修复，一起再审**
  - Phase 3.1 或 3.2 失败 → 统一在 plan.md 中修复所有问题
  - 修复后统一重新执行两个 Review（再次并发）
  - 最多 2 轮循环后，按问题分级处理（致命暂停，非致命继续）
- 两个都通过 → 进入 Phase 4

**完成标准:** 两个独立 Subagent 都给出 ✅通过 结论

---

## Phase 4: TDD开发

**沟通程度:** 低

**⚠️ Worktree 强制要求**

★ Insight ─────────────────────────────────────
Worktree 隔离是保护主分支不被污染的关键机制。
跳过 worktree = 违反 CRITICAL RULES。
开发完成后 worktree 保留，由用户手动 merge。
并发开发必须为每个 Subagent 创建独立 worktree。
─────────────────────────────────────────────────

**所有开发必须在 worktree 中进行，禁止直接在本地分支开发。**

**决策：根据 Phase 3 的并发可行性分析，选择执行策略：**

### 策略 A：多 Subagent 并行开发（当存在可并发模块时）
```
1. 为每个并发模块创建独立 worktree
   git worktree add .worktrees/<feature>-<模块A> -b feature/<feature>-<模块A>
   git worktree add .worktrees/<feature>-<模块B> -b feature/<feature>-<模块B>

2. 同时启动多个独立 Subagent 并行开发
   Subagent A：
   - 角色：模块开发者
   - 只读取：.dev_doc/<feature>/plan.md（模块A部分）
   - 工作目录：.worktrees/<feature>-<模块A>
   - 任务：按照计划执行模块A的开发

   Subagent B：
   - 角色：模块开发者
   - 只读取：.dev_doc/<feature>/plan.md（模块B部分）
   - 工作目录：.worktrees/<feature>-<模块B>
   - 任务：按照计划执行模块B的开发

3. 各 Subagent 独立提交到各自的 worktree
4. 合并回主 feature worktree
```

### 策略 B：串行开发（当无可并发模块时）
```
1. 创建单一 worktree
   git worktree add .worktrees/<feature> -b feature/<feature>

2. 按计划顺序执行每个任务
3. 严格遵循 red-green-refactor 循环
4. 频繁提交（每个功能点或2-5步后）
```

**阶段声明（并发模式）:**
```
🔧 进入 Phase 4: TDD开发（并发模式）
正在为 [模块A]、[模块B] 创建独立 worktree...
正在启动并行 Subagent 开发...
```

**阶段声明（串行模式）:**
```
🔧 进入 Phase 4: TDD开发（串行模式）
已在 worktree 中开始开发，LLM 将自主执行计划...
```

**状态更新:** 进入 Phase 4 时更新 `.dev_doc/<feature>/status.md`

**任务进度更新（调用 todo_list_manager）:**
```
进入 Phase 4 后，立即调用 todo_list_manager skill：
- 将对应任务状态更新为"进行中"
- 记录当前阶段和预计完成时间
⚠️ 这是一个主动调用，不等待用户确认
```

**完成标准:** 计划中所有任务完成，所有测试通过

**⚠️ 并发开发注意事项：**
- 只有 Phase 3 标记为"可并发"的模块才能并行开发
- 涉及共享文件/数据依赖的模块必须串行
- 各 Subagent 必须独立提交，不可相互覆盖

---

## Phase 4.5: 并发合流（仅并发开发时有）

**沟通程度:** 低

**触发时机:** Phase 4 并行开发完成后（仅当存在多个并发 worktree 时）

**核心价值:** 多个 Subagent 在各自 worktree 开发后，需要合并到主 feature worktree 才能被 Phase 5.5 统一审查

**执行方式:**
```bash
# 1. 切换到主 feature worktree
cd .worktrees/<feature>
git checkout feature/<feature>

# 2. 依次合并各模块 worktree（--no-ff 保留分支历史）
git merge feature/<feature>-<模块A> --no-ff -m "Merge <模块A> into <feature>"
git merge feature/<feature>-<模块B> --no-ff -m "Merge <模块B> into <feature>"

# 3. 解决可能的冲突
# 如有冲突 → 解决后提交

# 4. 验证合流结果
git log --oneline --graph --all | head -20
```

**阶段声明:**
```
🔀 进入 Phase 4.5: 并发合流
正在将各模块 worktree 合并到主分支...
```

**完成标准:** 所有模块合并到主 feature worktree，无冲突

---

## Phase 5.1: 用例生成+执行（独立 Subagent）

**沟通程度:** 低

★ Insight ─────────────────────────────────────
**生成+执行一体化**：
- 原 Phase 5.1 生成用例 + Phase 5.2 执行，合并为单一 Subagent
- 生成用例后立即执行，发现语法/导入错误立刻修复
- 避免用例生成后隔了很久才发现跑不通
─────────────────────────────────────────────────

**目的:** 通过独立 Subagent 生成测试用例并立即执行验证

**用例生成+执行方式（独立 Subagent）:**
```
启动独立 Subagent（Agent tool）：
- 角色：测试工程师
- 只读取：.dev_doc/<feature>/plan.md、design.md、status.md、worktree 代码
- 不加载：Phase 1-4.5 的对话上下文
- 任务：
  1. 分析功能点和实现细节
  2. 为每个功能点生成至少 1 个针对性测试用例
  3. 识别现有关联测试（tests/ 目录）
  4. 将生成的测试用例写入 tests/ 目录
  5. **立即执行测试**（本地或 scp 到远程执行）
  6. 如有失败 → 修复后重新执行
- 输出：测试用例文件 + 测试执行结果
```

**测试策略核心:**
- **新生成测试**：每个功能点至少 1 个测试用例
- **现有关联测试**：匹配与本次开发相关的已有测试
- **影响回归测试**：针对改动可能影响的上下游模块

**证据要求:**
- 测试输出必须包含 0 failures
- 必须有实际运行的命令和输出

**阶段声明:**
```
🤖 进入 Phase 5.1: 用例生成+执行
正在启动独立 Subagent 生成用例并执行测试...
```

**失败处理（强制循环）:**
```
❌ 测试失败
失败测试: [测试名]
失败原因: [具体原因]
正在修复...
修复后重新测试...

⚠️ 循环直到所有测试通过（0 failures）方可进入 Phase 5.5
```

**完成标准:**
- 所有测试通过（0 failures）
- ⚠️ **代码保留在 worktree 中**

---

## Phase 5.5: 用例质量抽查+代码确认（独立 Subagent）

**沟通程度:** 低

★ Insight ─────────────────────────────────────
**合并原 Phase 4.1 代码审查 + Phase 5 验证审查 + Phase 5.5 用例质量审查 为单一 Review**：
- 避免三次独立 Subagent 调用审相似内容
- 代码审查、测试覆盖、用例质量一次性确认
- 问题分级：致命问题阻断，非致命问题记录继续
─────────────────────────────────────────────────

**触发时机:** Phase 5.1（用例生成+执行）完成后

**执行方式（独立 Subagent 审查）：**
```
启动独立 Subagent（Agent tool）：
- 角色：测试质量审计员 + 代码审计员
- 只读取：worktree 代码、tests/ 目录下的测试用例、plan.md、design.md
- 不加载：Phase 1-5.1 的对话上下文
- 任务：
  1. 代码质量抽查（致命问题）
  2. 测试覆盖率确认（是否每个功能点都有对应测试）
  3. 用例质量抽查（边界条件、异常场景是否覆盖）
  4. 确认测试执行结果（0 failures）
- 输出：用例质量抽查报告
```

**审查检查清单（精简版）：**
- [ ] 代码无致命问题（资源泄露、严重 bug）
- [ ] 测试覆盖率充分（每个功能点有对应测试）
- [ ] 测试执行结果 0 failures
- [ ] 边界条件和异常场景有基本覆盖（抽样）

**非致命问题处理：**
- 发现非致命问题 → 记录在案，继续通过
- 只有致命问题才阻断

**阶段声明:**
```
🔍 进入 Phase 5.5: 用例质量抽查+代码确认
正在启动独立 Subagent 进行最终审查...
```

**失败处理：**
- 发现致命问题 → 在 worktree 中修复 → 重新执行 Phase 5.5
- 最多 2 次循环后仍失败 → 暂停，向用户汇报卡点

**完成标准:** 独立 Subagent 审查通过

---

## Phase 5.6: Worktree 提交

**沟通程度:** 低

**前提:** Phase 5.5 审查通过

**⚠️ 所有测试必须通过（0 failures）才能进入此阶段**

**任务:**
1. 在 worktree 中提交所有代码变更
   ```bash
   cd .worktrees/<feature>
   git add -A
   git commit -m "[完成] <feature>: <功能描述>"
   ```
   ⚠️ **暂不通知用户**，等待 Phase 6 完成 doc_integrate 后再统一通知

**阶段声明:**
```
📦 Phase 5.6: Worktree 提交完成
正在等待 Phase 6 整合文档...
```

**完成标准:** worktree 中存在提交记录

---

## Phase 6: 完成

**前提:** Phase 5.6 Worktree 提交完成

**沟通程度:** 低

**核心变化:** ⚠️ 不再调用 `finishing-a-development-branch`。merge 由用户手动执行。

**阶段声明:**
```
🎉 进入 Phase 6: 完成
正在整合文档，准备交付...
```

**任务:**
1. **自动调用 `doc_integrate` skill** 整合开发文档
   ```
   调用 doc_integrate skill
   - 扫描 .dev_doc/<feature>/ 下的所有文档
   - 验证文档与代码一致性
   - 整合到模块 README
   - 生成 CHANGELOG
   ```
2. **同步开发文档到本地分支**
   ```
   由于 .gitignore 忽略了 .dev_doc/，无法通过 git merge 自动合并
   必须手动将开发文档从 worktree 复制到本地分支：

   cp -r .worktrees/<feature>/.dev_doc/<feature>/* .dev_doc/<feature>/

   ⚠️ 注意：如果本地分支 .dev_doc/<feature>/ 已存在，cp 会覆盖已有文件
   ```

   **同步验证测试（必须执行）:**
   ```
   # 验证文件数量一致
   SOURCE_COUNT=$(find .worktrees/<feature>/.dev_doc/<feature>/ -type f | wc -l)
   DEST_COUNT=$(find .dev_doc/<feature>/ -type f | wc -l)
   if [ "$SOURCE_COUNT" -eq "$DEST_COUNT" ]; then
       echo "同步验证通过：$SOURCE_COUNT 个文件已同步"
   else
       echo "警告：源文件 $SOURCE_COUNT 个，目标文件 $DEST_COUNT 个"
   fi
   ```
3. **更新任务状态（调用 todo_list_manager）**
   ```
   ⚠️ 必须主动调用 todo_list_manager skill，不能省略或延迟

   调用 todo_list_manager skill：
   - 标记对应任务状态为"已完成"或"开发完成，等待 merge"
   - 记录完成时间和交付物信息
   - ⚠️ 注意：不判断任务结束，只更新进度
   ```
4. **生成开发总结** `.dev_doc/<feature>/summary.md`
5. **通知用户并提示 merge**
   ```
   ✅ Phase 6 完成！所有文档已整合。
   worktree 已就绪，可以执行以下操作：
   - 手动 merge: git merge .worktrees/<feature>
   - 删除 worktree: git worktree remove .worktrees/<feature>
   ```

★ Insight ─────────────────────────────────────
文档同步的必要性：
- .gitignore 排除了 .dev_doc/，worktree 的文档无法自动合并
- 必须手动复制或使用 git merge --no-ff 合并
- 建议先复制到本地分支，再 merge worktree 代码
─────────────────────────────────────────────────

**完成标准:** doc_integrate 执行完成，文档已同步，任务进度已更新，worktree 已提交通知用户

---

## 中断处理

用户说"算了"/"不用了"时：
1. 立即停止
2. 检查 worktree 状态：`git worktree list`
3. 保留（用户可继续）或删除：`git worktree remove .worktrees/<name>`
4. 记录进度（已整理的文档不要删除）

---

## 沟通节奏总结

| 阶段 | 沟通程度 | 关键产出 |
|------|----------|----------|
| Phase 1 | **极高** | 需求确认 + 候选方案 + 影响范围 |
| Phase 1.5 | 低（独立 Review） | 方案自审报告 |
| Phase 2 | **高** | 详细设计方案 |
| Phase 2.5 | 低（独立 Review） | 设计 Review 报告 |
| Phase 3 | **中** | 实现计划（含并发可行性分析） |
| Phase 3.1 + 3.2 | **低（并发 Subagent）** | 并行审查通过 |
| Phase 4 | **低（可选并发）** | 自主开发（串行/并行） |
| Phase 4.5 | **低** | 并发合流（仅并发时） |
| Phase 5.1 | **低（独立 Subagent）** | 用例生成+执行完成 |
| Phase 5.5 | **低（独立 Subagent）** | 用例质量抽查+代码确认 |
| Phase 5.6 | **低** | Worktree 提交完成 |
| Phase 6 | **低** | doc_integrate 自动整合 |

---

## 调用 Skill 一览

| Phase | 调用 skill | 备注 |
|-------|-----------|------|
| Phase 1 | `superpowers:brainstorming` | |
| Phase 2 | `frontend-design:frontend-design` / `superpowers:brainstorming` 等 | |
| Phase 3 | `superpowers:writing-plans` | **包含并发可行性分析** |
| Phase 3.1 + 3.2 | 独立 Subagent | **并发执行** |
| Phase 4 | 独立 Subagent（可选多并发）+ `todo_list_manager` | **策略A: 并发 / 策略B: 串行** |
| Phase 4.5 | - | 仅并发开发时有，合流操作 |
| Phase 5.1 | 独立 Subagent | **用例生成+执行** |
| Phase 5.5 | 独立 Subagent | **用例质量抽查+代码确认** |
| Phase 5.6 | - | Worktree 提交 |
| Phase 6 | `doc_integrate` + `todo_list_manager` | |

---

## Subagent 并发执行场景

★ Insight ─────────────────────────────────────
并发 Subagent 的核心价值：
- 独立执行：subagent 之间无上下文共享，避免互相影响
- 客观视角：没有前序"生成记录"的锚定效应
- 效率提升：并行处理耗时任务
─────────────────────────────────────────────────

| 场景 | 为什么适合并发 | 效益 |
|------|---------------|------|
| Phase 3.1 + 3.2 | 读取相同文档，检查维度不同 | 节省 50% 时间 |
| Phase 4 多独立模块 | 子模块之间无依赖 | 并行开发提速 |

**并发执行原则：**
- 只有相互独立、无数据依赖的 Phase 才能并发
- 并发 Subagent 必须独立启动，不共享上下文
- 任一并发任务失败，需返回重做对应部分

**Phase 3 → Phase 4 决策流程：**
```
Phase 3 计划完成后：
  ├── 存在可并发模块？ → Phase 4 采用多 Subagent 并行开发
  │   ├── 为每个并发模块创建独立 worktree
  │   ├── 同时启动多个 Subagent
  │   ├── 各 Subagent 独立提交
  │   └── Phase 4.5 合流到主 feature worktree
  │
  └── 无可并发模块？ → Phase 4 采用串行开发
      ├── 创建单一 worktree
      └── 按计划顺序执行
```
