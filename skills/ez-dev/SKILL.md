---
name: ez-dev
description: "完整开发流程skill，串联需求分析→独立Review→设计→独立Review→计划→独立Review→TDD开发→独立Review→验证→完成。触发条件：用户提出"帮我开发..."、"实现一个..."、"添加...功能"、"修复...bug"、"新功能"、"特性实现"等明确开发请求时。**核心原则**：前期充分高沟通+严格独立Review发现问题，中后期LLM自主决策，通过测试验证。Phase 6开发完成后自动整合文档，由用户手动merge。"
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

| Phase | Review 内容 | 输入文档 |
|-------|-------------|----------|
| Phase 1.5 | 独立方案自审 | design.md、模块代码 |
| Phase 2.5 | 独立设计 Review | design.md、requirement.md |
| Phase 3.1 | 独立计划完整性 Review | plan.md |
| Phase 3.2 | 独立合规门禁 | plan.md、design.md |
| Phase 4.1 | 独立代码 Review | worktree 代码 |
| Phase 5 | verification | worktree 代码、测试结果 |

---

## ⚠️ CRITICAL RULES

**以下规则无论任何情况都必须遵守：**

| 规则 | 说明 | 违规后果 |
|------|------|----------|
| **Worktree 强制** | 所有代码开发必须在 worktree 中进行，禁止直接在本地分支写代码 | 主分支污染 |
| **Review 强制** | 所有 Review 节点必须由独立 Subagent 执行，失败必须返回调整 | 质量无保证 |
| **Phase 顺序** | 禁止跳过任何 Phase，每个 Phase 都必须完整执行 | 流程残缺 |
| **用户批准** | Phase 1 方案和 Phase 2 设计必须用户批准后才能进入下一阶段 | 方向错误 |
| **Phase 声明** | 进入新 Phase 时必须向用户声明当前阶段 | 用户失去掌控 |
| **文档存储** | superpower skill 产出文档必须存储在 `.dev_doc/<feature>/` 下，参见 `references/document-storage.md` | 文档散落 |
| **merge 用户手动** | merge 操作由用户执行，AI 不自动合并 worktree | 人工确认缺失 |

---

## 配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `WORKTREE_BASE_DIR` | `.worktrees` | worktree 根目录 |
| `DEFAULT_BRANCH` | `dev_zby` | 基于分支创建 worktree |

> 如果项目有 CLAUDE.md 规定，以项目规定优先

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
- [ ] 实现计划 (Phase 3)
- [ ] 独立计划完整性 Review (Phase 3.1) ← 独立 Subagent
- [ ] 独立合规门禁 (Phase 3.2) ← 独立 Subagent，必须通过
- [ ] TDD开发 (Phase 4)
- [ ] 独立代码 Review (Phase 4.1) ← 独立 Subagent
- [ ] 验证 (Phase 5) ← 独立 Subagent
- [ ] 自动化测试 (Phase 5.1)
- [ ] 用户验收 (Phase 5.2)
- [ ] 完成 (Phase 6) ← 自动调用 doc_integrate

## Review 记录
| Phase | Review 结果 | 日期 |
|-------|------------|------|
| Phase 1.5 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 2.5 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 3.1 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 3.2 | ✅通过/❌不通过 | YYYY-MM-DD |
| Phase 4.1 | ✅通过/❌不通过 | YYYY-MM-DD |

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
- Review Agent 报告问题 → 返回 Phase 1 调整方案 → 用户重新批准 → 重新执行 Phase 1.5 Review

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
- Review Agent 报告问题 → 返回 Phase 2 调整设计 → 用户重新批准 → 重新执行 Phase 2.5 Review

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 3: 实现计划

**调用 skill:** `superpowers:writing-plans`

**沟通程度:** 中

**文档存储:** ⚠️ 参见 `references/document-storage.md`

**步骤:**
1. 计划保存到 `.dev_doc/<feature>/plan.md`
2. 包含每个步骤的：精确文件路径、测试代码框架、运行命令

**阶段声明:**
```
📝 进入 Phase 3: 实现计划
正在制定详细实现计划...
```

**完成标准:** 计划文档完成

---

## Phase 3.1: 独立计划完整性 Review

**沟通程度:** 低（独立 Subagent 执行）

**触发时机:** Phase 3 计划文档完成后

**任务:** 启动独立 Subagent 审查计划完整性和可执行性

**执行方式:**
```
启动独立 Subagent（Agent tool）：
- 角色：刚接手需求的新开发者
- 只读取：.dev_doc/<feature>/plan.md、design.md
- 不加载：Phase 1-3 的对话上下文
- 任务：检查计划是否完整、无 TODOs/占位符、任务分解清晰可执行
```

**检查项:**
- [ ] 计划是否完整（无 TODOs、占位符）
- [ ] 任务分解是否清晰可执行
- [ ] 是否与设计对齐
- [ ] 每个功能点都有对应实现步骤
- [ ] 每个功能点都有对应测试计划

**阶段声明:**
```
🔍 进入 Phase 3.1: 独立计划完整性 Review
正在审查计划完整性...
```

**Review 失败处理:**
- Review Agent 报告问题 → 返回 Phase 3 调整计划 → 重新执行 Phase 3.1 Review

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 3.2: 独立合规门禁 ⚠️

**沟通程度:** 低（独立 Subagent 执行）

**⚠️ 这是开发前的强制门禁，未通过不得进入 Phase 4**

**触发时机:** Phase 3.1 通过后

**执行方式:**
```
启动独立 Subagent（Agent tool）：
- 角色：质量审计员
- 只读取：.dev_doc/<feature>/plan.md、design.md、requirement.md
- 不加载：Phase 1-3 的对话上下文
- 任务：按照合规检查清单逐项审查
```

**检查清单:**

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
✅ Phase 3.2 独立合规门禁通过
计划满足用户需求，进入 Phase 4 开发阶段

❌ Phase 3.2 独立合规门禁未通过
[具体问题描述]
正在返回 Phase 3 调整计划...
```

**Review 失败处理:**
- Review Agent 报告问题 → 返回 Phase 3 调整计划 → 重新执行 Phase 3.1 Review → 通过后重新执行 Phase 3.2 Review

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 4: TDD开发

**调用 skill:** `superpowers:subagent-driven-development`

**沟通程度:** 低

**⚠️ Worktree 强制要求**

★ Insight ─────────────────────────────────────
Worktree 隔离是保护主分支不被污染的关键机制。
跳过 worktree = 违反 CRITICAL RULES。
开发完成后 worktree 保留，由用户手动 merge。
─────────────────────────────────────────────────

**所有开发必须在 worktree 中进行，禁止直接在本地分支开发。**

```bash
git worktree add .worktrees/<name> -b feature/<name>
```

**⚠️ 第一步必须是创建 worktree，这是强制步骤，不可跳过**

**任务:**
1. **首先创建 worktree**
2. 按计划顺序执行每个任务
3. 严格遵循 red-green-refactor 循环
4. 频繁提交（每个功能点或2-5步后）

**阶段声明:**
```
🔧 进入 Phase 4: TDD开发
已在 worktree 中开始开发，LLM 将自主执行计划...
```

**状态更新:** 进入 Phase 4 时更新 `.dev_doc/<feature>/status.md`

**完成标准:** 计划中所有任务完成，所有测试通过

---

## Phase 4.1: 独立代码综合 Review

**沟通程度:** 低（独立 Subagent 执行）

**触发时机:** Phase 4 开发完成后

**任务:** 启动独立 Subagent 审查 worktree 中的代码质量

**执行方式:**
```
启动独立 Subagent（Agent tool）：
- 角色：代码审计员
- 只读取：.worktrees/<feature>/ 下的代码文件
- 不加载：Phase 1-4 的对话上下文
- 任务：审查代码质量、潜在 bug、测试覆盖、影响分析
```

**检查项:**
- [ ] 代码质量问题（单一职责、错误处理）
- [ ] 潜在 bug 风险
- [ ] 测试覆盖是否充分
- [ ] **影响分析**：改动对其他模块及上下游的影响是否已识别并处理

**通过条件:** 无 Critical 问题

**阶段声明:**
```
🔍 Phase 4.1 独立代码 Review 完成
无 Critical 问题，即将进入 Phase 5 验证...
```

**Review 失败处理:**
- Review Agent 报告问题 → 在 worktree 中修复 → 重新执行 Phase 4.1 Review

**完成标准:** 独立 Subagent 给出 ✅通过 结论

---

## Phase 5: 验证

**调用 skill:** `superpowers:verification-before-completion`

**沟通程度:** 低

**证据要求:**
- 测试输出必须包含 0 failures
- 必须有实际运行的命令和输出

**阶段声明:**
```
🧪 进入 Phase 5: 验证
正在运行测试验证实现...
```

**完成标准:** 所有测试通过，0 failures

---

## Phase 5.1: 自动化测试

**沟通程度:** 低

★ Insight ─────────────────────────────────────
这是 AI 自动化测试节点，完全自主执行。
测试策略详见 `references/test-strategy.md`。
─────────────────────────────────────────────────

**目的:** 在用户手动测试前，通过自动化测试验证功能完整性

**执行流程:** 参见 `references/test-strategy.md`

**测试策略核心:**
- **新生成测试**：每个功能点至少 1 个测试用例
- **现有关联测试**：匹配与本次开发相关的已有测试
- **影响回归测试**：针对改动可能影响的上下游模块

**执行命令:**
```bash
ssh dev@192.168.110.52 -p 2223
cd /tmp/dev/huashan_dev && python -m pytest tests/ -v
```

**阶段声明:**
```
🤖 进入 Phase 5.1: 自动化测试
正在分析需求和代码变动...
正在生成测试用例...
正在远程执行测试...
```

**完成标准:**
- 测试用例覆盖所有功能点（新生成 + 现有关联）
- 所有测试通过（0 failures）
- ⚠️ **代码保留在 worktree 中，等待用户手动 merge**

**失败处理:**
```
❌ 测试失败
失败测试: [测试名]
失败原因: [具体原因]
正在修复...
修复后重新测试...
```

---

## Phase 5.2: 用户验收测试

**沟通程度:** 高

**前提:** Phase 5.1 自动化测试全部通过

**流程:**

1. **LLM 通知用户** - 告知开发已完成，自动化测试已通过，请求验收测试
   ```
   ✅ LLM 开发完成，自动化测试已通过

   功能列表：
   - [功能点1]
   - [功能点2]

   自动化测试结果：
   - 总计: X 个测试
   - 通过: X 个
   - 失败: 0 个

   worktree 已就绪，请手动 merge 并进行验收测试。
   发现问题请告知。
   ```

2. **用户手动 merge + 测试**

3. **发现问题** → **LLM 修复** → **Phase 5.1 重新测试** → **用户重新测试**

4. **用户确认通过** → 进入 Phase 6

**完成标准:** 用户明确确认通过

---

## Phase 6: 完成

**前提:** Phase 5.2 用户验收通过

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
2. **生成开发总结** `.dev_doc/<feature>/summary.md`
3. **通知用户 worktree 代码已就绪，可手动删除**

★ Insight ─────────────────────────────────────
Worktree 保留机制：
- Phase 5.1 测试通过后 → worktree 保留，代码不合并
- Phase 5.2 用户验收通过后 → 保留 worktree，用户手动 merge
- 用户完成 merge 后，可手动删除 worktree
─────────────────────────────────────────────────

**完成标准:** doc_integrate 执行完成，worktree 保留通知用户

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
| Phase 3 | **中** | 实现计划 |
| Phase 3.1 | 低（独立 Review） | 计划完整性通过 |
| Phase 3.2 | 低（独立 Review） | 合规门禁通过 |
| Phase 4-4.1 | **低** | 自主开发 + 代码 Review |
| Phase 5 | 低（独立 Review） | 验证通过 |
| Phase 5.1 | **低** | 自动化测试通过 |
| Phase 5.2 | **高** | 用户手动验收 |
| Phase 6 | **低** | doc_integrate 自动整合 |

---

## 调用 Skill 一览

| Phase | 调用 skill |
|-------|-----------|
| Phase 1 | `superpowers:brainstorming` |
| Phase 2 | `frontend-design:frontend-design` / `superpowers:brainstorming` 等 |
| Phase 3 | `superpowers:writing-plans` |
| Phase 4 | `superpowers:subagent-driven-development` |
| Phase 5 | `superpowers:verification-before-completion` |
| Phase 6 | `doc_integrate` |
