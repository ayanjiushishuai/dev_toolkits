---
name: bug_fix
description: Bug修复流程（代码定位→问题复现→问题修复→回归测试→提交完成）。触发：用户报告bug、报错、异常、或说"XX不工作"/"XX报错"/"XX有问题"/"修复XX"/"排查XX"/"XX挂了"/"XX崩了"/"修一下"/"debug"/"fix"，通常会指出文件/函数/错误信息（KeyError/TypeError/OOM/ModuleNotFoundError/堆栈/控制台错误/白屏）或线上事故（内存泄漏/连接池耗尽/间歇性失败/重启后报错）。不要用于：新功能开发（用ez-dev）、配置调整、纯文档编写、"xxx怎么用"问答、纯阅读理解代码、对话式咨询。核心原则：worktree开发、测试复现优先、用户手动merge。
---

# BUG_FIX: Bug修复开发流程

Bug修复是**线性单线任务**：快速定位 → 精准复现 → 最小修改 → 充分验证。流程从 ez-dev 抽取核心约束（Worktree / 文档 / 修复闭环 / 测试分级 / 合并规范），砍掉并行策略与重型 Review，保持轻量。

---

## 核心原则

### Worktree

- 所有代码修改在 worktree 中进行
- Bug 修复默认单 worktree（线性任务，不需要并行）
- 修复策略涉及多模块时仍然单 worktree，但修改按依赖顺序串行

### 文档

- 开发文档存 `.dev_doc/<bug>/`
- 禁止根目录存 .md 开发文档
- 禁止 worktree 外存开发文档
- 必填字段：
  - `status.md`（阶段状态锚点 + 进度 checkbox）
  - `bug-analysis.md`（根因 + 修复策略 + 风险）
  - `test-report.md`（P0/P1/P2 测试点 + 0 failures 证据）
  - `summary.md`（变更摘要 + worktree 路径 + 合并命令预览）

### 修复闭环

**致命问题（必须回退上 Phase 重做）：**
- 修复方向错误（改错根因）
- 修复引入新 bug
- 安全/数据一致性风险
- P0 复现测试改 patch 后仍 fail
- 改动越界（做无关修改）

**非致命问题（记录继续，不阻塞）：**
- 边界条件遗漏（有合理兜底）
- 代码风格不一致
- 文档不完整（代码本身可理解）
- 未来优化建议

**闭环流程：** 失败 → 自纠 → 1 次机会 → 仍失败暂停并向用户报告（当前失败点、已尝试方案、需人工输入）。

### 测试

- 0 failures 才能通过
- 测试点分级：
  - **P0**：复现测试，1:1 对应用户报错（必过）
  - **P1**：根因代码路径边界值（必过）
  - **P2**：相邻场景回归保护（应过）
- 远程测试：参见项目 `CLAUDE.md` 的"测试"章节

### 合并

- 禁止 AI 主动合入本地分支
- merge 由用户执行
- worktree 内可多个 commit（red / green / refactor）
- Phase 5 提示用户："最终入主线时建议 squash 为 1 个 commit"

---

## 关键约定

### 文档必填字段

| 文档 | 时机 | 必填字段 |
|------|------|----------|
| `status.md` | Phase 1 启动 | 当前阶段 / Bug 信息 / 测试清单 / 进度 checkbox |
| `bug-analysis.md` | Phase 1 结束 | 概述 / 根因 / 触发条件 / 修复策略 / 风险 |
| `test-report.md` | Phase 4 结束 | P0/P1/P2 测试点 / 覆盖率 / 0 failures 证据 |
| `summary.md` | Phase 5 结束 | 变更摘要 / worktree 路径 / 合并命令预览 |

### 测试点分级

- P0：`tests/<module>/test_<bug>_reproduce.py` —— 1:1 对应用户报错，必须先 fail 后 pass
- P1：`tests/<module>/test_<bug>_edge_cases.py` —— 根因代码路径的边界值
- P2：`tests/<module>/test_<bug>_regression.py` —— 相邻场景的回归保护

### 配置自动推断

- `WORKTREE_BASE_DIR`：默认 `.worktrees`，启动 Phase 3 时从以下顺序推断：
  1. 项目根 `CLAUDE.md` 中显式声明
  2. 项目根 `.worktreeconfig`（如存在）
  3. 兜底 `.worktrees`
- `DEFAULT_BRANCH`：从 `git symbolic-ref refs/remotes/origin/HEAD` 推断当前主线，缺失则用 `git rev-parse --abbrev-ref HEAD`
- Phase 1 启动时打印推断结果："worktree 基目录：xxx，基准分支：xxx"，推断失败再询问用户
- **不写死任何分支名或路径到 skill 内部**

### 修复策略自审（轻量 Review）

Phase 1 结束后、进入 Phase 2 前，AI 用以下 checklist 自审 `bug-analysis.md`：

```markdown
# 修复策略自审清单

## 根因审查
- [ ] 根因是否找到了真正的代码问题，而不是表象？
- [ ] 调用链追踪是否完整？

## 修复策略审查
- [ ] 修复策略是否针对根因，而不是绕过症状？
- [ ] 是否识别了对其他模块的影响？
- [ ] 边界条件（空值/极值/异常）是否考虑？
- [ ] 是否存在更简单的修复方案？

## 风险审查
- [ ] 是否存在破坏性变更？
- [ ] 向后兼容性是否考虑？
- [ ] 修复后是否会引入新的 bug？

## 结论
- [ ] 通过（进入 Phase 2）
- [ ] 不通过（修订 bug-analysis.md 后重审）
```

不通过则修订 `bug-analysis.md` 后再审；通过则继续。

---

## 流程

### Phase 1: 代码定位

**目标：** 找到问题代码位置 + 完成根因分析 + 修复策略

**步骤：**
1. 收集信息（用户已提供）
   - 报错信息：错误类型、消息、堆栈
   - 场景描述：触发操作步骤
   - 相关模块：用户怀疑或根据堆栈推断

2. 定位问题代码
   - 读取相关模块代码
   - 根据堆栈追踪调用链
   - 找到问题根源行 / 函数

3. 根因分析 + 修复策略
   - 为什么会出现？触发条件？影响范围？
   - 需要改什么文件？改什么内容？风险评估？

4. 修复策略自审（见上 checklist）

5. 配置自动推断（打印 worktree 基目录 + 基准分支）

**输出：**
- `.dev_doc/<bug>/status.md`（启动 + 更新阶段为"代码定位完成"）
- `.dev_doc/<bug>/bug-analysis.md`（根因 + 修复策略 + 风险）

**阶段声明：**
```
🔍 Phase 1: 代码定位
正在定位问题代码 + 分析根因 + 制定修复策略...
```

**完成标准：** 根因清晰、修复策略明确、修复策略自审通过

---

### Phase 2: 问题复现

**目标：** 创建测试用例稳定复现 Bug

**步骤：**
1. 创建 P0 复现测试
   - 在 `tests/<module>/test_<bug>_reproduce.py` 创建
   - 测试必须能复现 Bug
   - 报错信息与用户报告一致

2. 创建 P1 边界测试
   - 在 `tests/<module>/test_<bug>_edge_cases.py` 创建
   - 覆盖根因代码路径的边界值（空值/极值/异常输入）
   - 覆盖相邻场景的类似问题

3. 运行测试确认复现
   - 执行 P0 测试，**必须 fail**
   - 记录复现结果（保留测试输出作为基线）

**阶段声明：**
```
🧪 Phase 2: 问题复现
正在创建 P0 复现测试 + P1 边界测试...
```

**完成标准：** P0 测试稳定复现 Bug（fail），P1 测试创建完成

---

### Phase 3: 问题修复

**目标：** 在 worktree 中最小化修复 Bug

**步骤：**
1. 创建 worktree
   ```bash
   git worktree add <WORKTREE_BASE_DIR>/<bug> -b fix/<bug> <DEFAULT_BRANCH>
   ```
   路径与分支名按"配置自动推断"取

2. 进入 worktree 修改代码
   - 按照 `bug-analysis.md` 的修复策略修改
   - **不要做无关修改**（改动越界属于致命问题）
   - 走 TDD 循环：red（P0 fail）→ green（最小修改让 P0 pass）→ refactor

3. 验证 P0 复现测试通过
   - 跑 `tests/<module>/test_<bug>_reproduce.py`
   - 确认从 fail 变为 pass

**阶段声明：**
```
🔧 Phase 3: 问题修复
已在 worktree 中修复，准备验证...
```

**完成标准：** P0 测试通过，代码修改最小化（仅针对根因）

---

### Phase 4: 回归测试

**目标：** 全面验证修复 + 创建 P2 回归测试

**步骤：**
1. 执行 P0 + P1 确认修复
   - 复现测试 + 边界测试全过

2. 创建 P2 回归测试
   - 在 `tests/<module>/test_<bug>_regression.py` 创建
   - 针对修复代码片段，覆盖可能的回归场景
   - 预防未来类似 bug

3. 运行完整测试套件
   - 参考项目 `CLAUDE.md` 测试章节（本地 / 远程）
   - **0 failures 验证**

4. 记录 `test-report.md`
   - P0/P1/P2 测试点列表
   - 覆盖率（如适用）
   - 全量测试通过证据（命令 + 输出摘要）

**输出：**
- `tests/<module>/test_<bug>_{reproduce,edge_cases,regression}.py`
- `.dev_doc/<bug>/test-report.md`

**阶段声明：**
```
✅ Phase 4: 回归测试
正在执行 P0/P1/P2 + 全量测试套件...
```

**完成标准：** 0 failures，test-report.md 记录完整

---

### Phase 5: 提交完成

**目标：** 整理交付

**步骤：**
1. 提交 worktree
   ```bash
   cd <WORKTREE_BASE_DIR>/<bug>
   git add -A
   git commit -m "[修复] <bug>: <修复描述>"
   ```

2. 同步文档到本地分支
   ```bash
   cp -r <WORKTREE_BASE_DIR>/<bug>/.dev_doc/<bug>/* .dev_doc/<bug>/
   ```

3. 生成 `summary.md`
   - 变更摘要
   - worktree 路径
   - 合并命令预览（如 `git merge --squash fix/<bug>`）

4. 调用 `doc_integrate`（如需归位散落文档）
5. 调用 `todo_list_manager`（更新任务状态）
6. 通知用户
   - worktree 已就绪
   - 提示："可手动 merge；最终入主线建议 squash 为 1 个 commit"

**阶段声明：**
```
🎉 Phase 5: 提交完成
Bug修复完成，worktree 已提交，等待用户 merge
```

**完成标准：** worktree 已提交、summary.md 已生成、用户已通知

---

## 异常处理

### 中断 / 放弃

用户说"算了"/"不用了"/"先停一下"/"暂停"时：
1. 立即停止
2. 检查 worktree 状态
   - `git worktree list`（记录路径）
   - `git status`（commit / untracked / staged）
3. 检查文档状态：`.dev_doc/<bug>/` 哪些文档已创建
4. 询问用户处理方式：
   - **保留 worktree**（下次继续，状态写入 status.md）
   - **删除 worktree**（`git worktree remove` + `git branch -D fix/<bug>`）
   - **归档**（保留 worktree，但 status.md 标记为 inactive）
5. 告知用户：
   - 当前阶段
   - 未完成项
   - 恢复方式（保留时如何继续）

### 修复失败

按"修复闭环"原则处理：
- 致命问题 → 回退到对应 Phase 修订
- 1 次自纠机会
- 仍失败 → 暂停，向用户报告：
  - 当前失败点
  - 已尝试方案
  - 需要的人工输入

### 配置推断失败

`WORKTREE_BASE_DIR` 或 `DEFAULT_BRANCH` 自动推断失败时：
- 不猜测、不写死
- 列出推断过程和失败原因
- 询问用户具体值
