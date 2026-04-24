---
name: bug_fix
description: "Bug修复开发流程skill，精简6步流程：问题定位→问题分析→问题复现→代码修改（创建worktree）→测试验证→完成。触发条件：用户提出"帮我修bug"、"修复...报错"、"解决...问题"、"fix bug"、"报错如下"等明确Bug修复请求。**核心原则**：轻量高效，去除冗余Review；Worktree强制；测试复现优先。"
---

# BUG_FIX: Bug修复开发流程

★ Insight ─────────────────────────────────────
精简流程 vs ez-dev：
- Bug修复是线性单线任务，不需要并行策略
- 不需要需求开发那种高频沟通
- 重点：快速定位 → 精准修复 → 验证完成
─────────────────────────────────────────────────

---

## ⚠️ CRITICAL RULES

| 规则 | 说明 |
|------|------|
| **Worktree 强制** | 所有代码开发必须在 worktree 中进行 |
| **测试复现优先** | 在修复前必须先创建测试用例复现Bug |
| **远程测试** | 必须通过 ssh dev@192.168.110.52 -p 2223 执行测试 |

---

## 配置

| 配置项 | 默认值 |
|--------|--------|
| `WORKTREE_BASE_DIR` | `.worktrees` |
| `DEFAULT_BRANCH` | `dev_zby` |

---

## 阶段状态追踪

**输出文件:** `.dev_doc/<bug>/status.md`

**状态文档结构:**
```markdown
# Bug修复状态

## 当前阶段
- **Phase:** [Phase X]
- **Bug:** [Bug名称]
- **状态:** [进行中/已完成]

## Bug信息
- **报错信息:** [用户提供的错误信息]
- **相关模块:** [相关模块]

## 测试用例清单
- **复现测试:** `tests/<module>/test_<bug>_reproduce.py`
- **边界测试:** `tests/<module>/test_<bug>_edge_cases.py`
- **回归测试:** `tests/<module>/test_<bug>_regression.py`

## 开发进度
- [ ] Phase 1: 问题定位
- [ ] Phase 2: 问题分析
- [ ] Phase 3: 问题复现 + 边界测试
- [ ] Phase 4: 代码修改
- [ ] Phase 5: 测试验证 + 回归测试
- [ ] Phase 6: 完成
```

---

## Phase 1: 问题定位

**目标:** 找到问题代码位置

**步骤:**
1. 收集信息（用户已提供）
   - 报错信息：错误类型、消息、堆栈
   - 场景描述：触发操作步骤
   - 相关模块：可能相关的代码

2. 定位问题代码
   - 读取相关模块代码
   - 根据堆栈追踪调用链
   - 找到问题根源行/函数

**阶段声明:**
```
🔍 Phase 1: 问题定位
正在定位问题代码...
```

**输出:** `.dev_doc/<bug>/status.md`（更新问题代码位置）

**完成标准:** 问题代码位置已确定

---

## Phase 2: 问题分析

**目标:** 理解Bug根因

**步骤:**
1. 分析根因
   - 为什么会出现这个Bug？
   - 触发条件是什么？
   - 影响范围多大？

2. 确定修复策略
   - 需要改什么文件？
   - 需要改什么内容？
   - 风险评估

**阶段声明:**
```
🔍 Phase 2: 问题分析
正在分析Bug根因...
```

**输出:** `.dev_doc/<bug>/bug-analysis.md`

```markdown
# Bug分析

## Bug概述
- **报错信息:** [错误]
- **影响范围:** [影响]

## 根因分析
- **根本原因:** [根因]
- **触发条件:** [触发条件]

## 修复策略
- **涉及文件:** [文件]
- **修改内容:** [内容]
```

**完成标准:** 根因清晰，修复策略明确

---

## Phase 3: 问题复现

**目标:** 创建测试用例复现Bug + 扩充测试覆盖

**步骤:**
1. 创建复现测试用例
   - 在 `tests/` 目录创建测试
   - 测试必须能复现Bug
   - 测试必须与用户报错一致

2. 分析bug代码路径，创建边界测试用例
   - 分析bug触发的代码路径
   - 识别该路径上的边界条件
   - 创建边界测试用例覆盖：
     - 正常边界值
     - 异常边界值
     - 相邻场景的类似问题

3. 运行测试确认复现
   - 执行测试
   - 确认报错与用户报告一致
   - 记录复现结果

**输出:**
- `tests/<module>/test_<bug>_reproduce.py` - 复现测试
- `tests/<module>/test_<bug>_edge_cases.py` - 边界测试

**完成标准:** 复现测试+边界测试均已创建并记录

---

## Phase 4: 代码修改

**目标:** 在worktree中修复Bug

**⚠️ Worktree 强制要求**

**步骤:**
1. 创建 worktree
   ```bash
   git worktree add .worktrees/<bug> -b fix/<bug>
   ```

2. 进入 worktree 修改代码
   - 按照 Phase 2 的修复策略修改
   - 不要做无关修改

3. 运行测试验证
   - 复现测试应该通过
   - 确认Bug已修复

**阶段声明:**
```
🔧 Phase 4: 代码修改
已在 worktree 中修复，准备验证...
```

**完成标准:** Bug已修复，测试通过

---

## Phase 5: 测试验证

**目标:** 全面验证修复 + 创建回归测试

**步骤:**
1. 执行复现测试确认修复
   - 运行 Phase 3 创建的复现测试
   - 确认bug已修复（测试从fail变为pass）

2. 创建针对修复代码的回归测试用例
   - 分析修复的代码片段
   - 针对该代码片段创建专门的回归测试：
     - 验证修复逻辑正确性
     - 覆盖可能的回归场景
     - 预防未来类似bug

3. 运行完整测试套件
   ```bash
   ssh dev@192.168.110.52 -p 2223
   cd /tmp/dev/huashan_dev && python -m pytest tests/ -v
   ```

4. 确认所有测试通过
   - 回归测试通过
   - 原有测试无新失败
   - 无新引入的问题

5. 提交 worktree
   ```bash
   cd .worktrees/<bug>
   git add -A
   git commit -m "[修复] <bug>: <修复描述>"
   ```

**输出:**
- `tests/<module>/test_<bug>_regression.py` - 回归测试

**完成标准:** 复现测试+回归测试全部通过，worktree 已提交

---

## Phase 6: 完成

**目标:** 整理交付

**步骤:**
1. 同步文档到本地分支
   ```bash
   cp -r .worktrees/<bug>/.dev_doc/<bug>/* .dev_doc/<bug>/
   ```

2. 更新任务状态（调用 todo_list_manager）

3. 通知用户
   - worktree 已就绪
   - 可以手动 merge

**阶段声明:**
```
🎉 Phase 6: 完成
Bug修复完成，worktree 已提交
```

---

## 中断处理

用户说"算了"/"不用了"时：
1. 立即停止
2. 检查 worktree 状态：`git worktree list`
3. 保留或删除 worktree

---

## 流程对比

| 当前 (精简后) | 原版 |
|-------------|------|
| 6 Phase | 14 Phase |
| 无独立Review | 8个独立Review节点 |
| 线性流程 | 并发策略 |
| 轻量高效 | 流程复杂 |

---

## 调用 Skill 一览

| Phase | 调用 skill | 备注 |
|-------|-----------|------|
| Phase 1 | - | 问题定位 |
| Phase 2 | - | 问题分析 |
| Phase 3 | `test` | 测试复现 + 边界测试 |
| Phase 4 | `todo_list_manager` | Worktree开发 |
| Phase 5 | `test` | 测试验证 + 回归测试 |
| Phase 6 | `todo_list_manager` | 完成 |