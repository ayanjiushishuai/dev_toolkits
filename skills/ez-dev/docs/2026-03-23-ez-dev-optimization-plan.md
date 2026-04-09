# ez-dev Skill 优化方案

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 优化 ez-dev skill 的描述和流程，解决已发现的7个关键问题

**Architecture:** 通过精确化触发描述、统一skill命名、外化配置、补充异常处理流程来提升skill的可靠性和可维护性

**Tech Stack:** SKILL.md YAML frontmatter + Markdown

---

## Task 1: 优化触发描述 (description)

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:1-3`

### 优化理由

当前描述过于宽泛，缺乏具体触发短语。根据 skill-creator 最佳实践，描述应该：
1. 包含具体触发短语（pushy风格）
2. 说明什么情况不应该触发
3. 覆盖边界场景

### 现有描述
```yaml
description: "完整的开发流程skill，串联需求分析→设计→计划→TDD开发→验证→完成的全流程。适用于用户提出新功能开发、特性实现、bug修复等开发任务。"
```

### 优化后描述
```yaml
description: "完整的开发流程skill，串联需求分析→设计→计划→TDD开发→验证→完成的全流程。触发条件：用户提出"帮我开发..."、"实现一个..."、"添加...功能"、"修复...bug"、"新功能"、"特性实现"等明确开发请求时自动触发。简单配置修改、单一文件编辑等不需要此流程。核心原则：前期充分沟通确认方案，中后期减少沟通让LLM自主决策，通过测试验证可行性。"
```

---

## Task 2: 统一 Skill 命名空间

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:54-63` (Phase 2 skill table)
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:120` (Phase 5)

### 问题

| 位置 | 当前值 | 问题 |
|------|--------|------|
| Phase 2 | `code-review:code-review` | 带命名空间前缀 |
| Phase 2 | `frontend-design` | 无命名空间 |
| Phase 2 | `test` | 无命名空间 |
| Phase 5 | `test` | 无命名空间 |
| Phase 6 模板 | `verification-before-completion` | 与实际调用不符 |

### 优化方案

统一使用命名空间前缀，与其他 superpowers skill 保持一致：

| 场景 | 调用 skill |
|------|-----------|
| 前端界面/组件 | `frontend-design:frontend-design` |
| 文档/笔记管理 | `obsidian:obsidian-markdown` |
| API/后端开发 | `superpowers:brainstorming` |
| 搜索文档/技术问题 | `mcp__plugin_context7_context7__query-docs` |
| 代码审查 | `superpowers:code-review` |
| 其他 | `superpowers:brainstorming` |

Phase 5 改为 `superpowers:verification-before-completion`

---

## Task 3: 外部化 Worktree 配置

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:99` (Phase 4)
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:173-186` (分支管理)

### 问题

- 第99行硬编码 `dev_zby` 分支
- 第177行 worktree 路径 `../huashan-dev-<feature>` 与项目 CLAUDE.md 规定的 `.worktrees/` 不一致

### 优化方案

在 skill 开头添加配置变量声明：

```markdown
## 配置（根据项目调整）

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `WORKTREE_BASE_DIR` | `.worktrees` | worktree 根目录 |
| `DEFAULT_BRANCH` | `dev_zby` | 基于分支创建 worktree |
| `WORKTREE_PREFIX` | `huashan-dev-` | worktree 目录前缀 |

> 如果项目有 CLAUDE.md 规定，以项目规定优先
```

分支管理部分改为：
```bash
git worktree add .worktrees/<name> -b feature/<name>
```

---

## Task 4: 澄清 Phase 1 流程

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:24-50`

### 问题

- 第24行说"调用 skill: brainstorming"
- 第38行说"优先通过 askuserquestion，一次性的问出所有问题"

这两者存在冲突——brainstorming skill 本身就是做需求澄清的，不应该跳过它直接用 AskUserQuestion。

### 优化方案

重新定义 Phase 1 内部逻辑：

```markdown
### Phase 1: 需求分析（高沟通）

**调用 skill:** `superpowers:brainstorming`

**内部流程：**
1. **启动 brainstorming skill** 进行需求澄清
2. brainstorming 会通过多轮提问探索需求
3. 如果用户在原始请求中已提供足够信息，可以简化 brainstorming 流程
4. 方案选择阶段仍然需要多方案对比和用户批准

**关键原则：**
- 不要跳过 brainstorming skill 直接用 AskUserquestion
- brainstorming 的多轮提问本身就是高沟通的体现
- 只有当用户明确说"需求很清楚了"时才简化流程
```

---

## Task 5: 补充中断/放弃处理流程

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:315-322` (注意事项)

### 问题

当用户说"算了""不用了""取消"时，没有指导如何处理：
- 已创建的 worktree
- 未提交的更改
- 已生成的文档

### 优化方案

在"注意事项"前添加新章节：

```markdown
## 中断与放弃处理

### 识别中断信号
用户可能说："算了"、"不用了"、"取消吧"、"先不做"、"停"

### 处理流程

1. **立即停止** - 不继续创建新文件或修改
2. **检查 worktree 状态**
   ```bash
   # 查看所有 worktree
   git worktree list

   # 如果有未提交的更改
   git status
   ```
3. **清理选项**
   - **保留更改**: worktree 保留，用户可稍后继续
   - **放弃更改**: 删除 worktree
     ```bash
     git worktree remove .worktrees/<name>
     ```
4. **记录状态** - 告诉用户当前进度和后续恢复方式

### 最小化损失原则
- 已 commit 的内容在 worktree 中是安全的
- 未 commit 的更改如果用户不要了再删除
```

---

## Task 6: 精确化快速模式条件

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:155-169`

### 问题

"单文件修改"边界模糊，实际开发中很难判断。

### 优化方案

更明确的判断条件：

```markdown
### 快速模式条件（必须同时满足）

| 条件 | 说明 | 反例 |
|------|------|------|
| 改动范围 | 单一文件，修改行数 < 50 | 多文件、跨模块 |
| 复杂度 | 无新增接口/函数 | 新增 API、数据库迁移 |
| 依赖 | 无外部依赖变化 | 需要新依赖、新配置 |
| 用户意图 | 用户明确说"快速"、"简单"、"| 用户说"认真做"、"完整实现" |
| 测试 | 已有测试覆盖或无需测试 | 需要新增测试用例 |

**决策流程：**
```
用户请求 → 满足全部5项条件？ → 是 → 快速模式
                          → 否 → 完整流程
```

---

## Task 7: Phase 6 正确调用 skill

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:131-139`

### 问题

Phase 6 说"调用 skill: 无"，但 `finishing-a-development-branch` skill 专门处理这个阶段。

### 优化方案

```markdown
### Phase 6: 完成

**调用 skill:** `superpowers:finishing-a-development-branch`

**任务：**
1. 调用 `finishing-a-development-branch` skill
2. 它会处理：
   - 确认当前开发的实际修改内容
   - 将 worktree 中的变更代码拷贝至本地
   - 更新相关文档
   - 清理开发用的 worktree
```

---

## Task 8: 更新输出模板

**Files:**
- Modify: `C:\Users\mraya\.claude\skills\ez-dev\SKILL.md:206-207`

### 问题

Phase 6 模板写的是 `verification-before-completion`，实际应该调用 `finishing-a-development-branch`

### 优化方案

```markdown
[6] 完成     → finishing-a-development-branch
```

---

## 汇总：修改清单

| Task | 优先级 | 改动点 |
|------|--------|--------|
| Task 1 | 高 | description 触发短语 |
| Task 2 | 高 | skill 命名空间统一 |
| Task 3 | 高 | worktree 配置外化 |
| Task 4 | 中 | Phase 1 流程澄清 |
| Task 5 | 中 | 中断处理流程 |
| Task 6 | 低 | 快速模式条件精确化 |
| Task 7 | 高 | Phase 6 正确调用 |
| Task 8 | 中 | 输出模板更新 |

---

## 验证方式

1. 逐 Task 应用修改
2. 对照修改清单确认无遗漏
3. 完整阅读 SKILL.md 确认逻辑流畅