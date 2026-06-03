---
name: ez-dev
description: 完整功能开发流程（需求→设计→计划→TDD开发→测试→完成）。触发：用户提出明确的开发任务时——"开发X"/"实现X"/"添加X功能"/"新功能"/"做个新特性"/"重构X"/"修复X bug"。不要用于：单行修改、配置调整、纯文档编写、"xxx怎么用"问答、bug 原因排查、纯阅读/理解代码、对话式咨询。核心原则：worktree开发、独立Subagent审查、用户手动merge。
---

# EZ-DEV: 开发流程与原则

## 核心原则

### 完成粒度

- 谨慎决策什么样的功能记为「已完成」——是否构成**独立可交付的功能点**？
- 不要每个小的功能开发都记作一条 work_done 条目
- 按**实际的大功能点**来记录；小的更新/修复/优化应作为**补丁**附在所属大功能点下
- **判定标准**（同时满足才算独立条目）：
  | 维度 | 独立条目 | 补丁 |
  |------|---------|------|
  | 业务边界 | 解决独立的用户场景/问题域 | 隶属于已有大功能点的局部优化 |
  | 文档载体 | 需要独立 `.dev_doc/{feature}/` | 复用现有 feature 文档 |
  | 可独立验收 | 完整"输入→处理→输出"链路 | 只是大链路中的一环 |
  | 价值颗粒度 | 一次发布即可对外兑现价值 | 离开主条目无独立价值 |
- 反例：把"stdq 中范围重构""多日 TypeError 修复""duckdb 写 parquet"拆成 3 个独立 work_done 条目
- 正例：统一为 1 个「stdq 卫星遥测数据查询 Skill」条目 + 补丁记录

### Worktree

- 所有代码开发在 worktree 中进行
- 各 Subagent 独立 worktree
- 合流必须保留分支历史

### 文档

- 开发文档存 `.dev_doc/<feature>/`
- 禁止根目录存 .md 开发文档
- 禁止 worktree 外存开发文档
- 禁止公共 `.dev_doc/status.md`（per-feature 允许）
- `tests/` 和 `.dev_doc/` 不入 git 仓库（需手动同步到本地分支）
- 文档路径：dev-handbook.md（手册）/ status.md（状态）/ test-report.md（测试报告）/ summary.md（总结）

### Review

- 关键节点（Phase 1 / Phase 3）由独立 Subagent 审查
- Subagent 不加载前序对话，从"新开发者"视角审查
- 致命问题必须修复；非致命问题记录继续
- 闭环：失败 → 自纠 → 再 Review → 1 次机会 → 仍失败暂停

#### 致命问题（必须修复）

- 核心功能无法正常工作
- 安全漏洞或数据泄露风险
- 资源泄露（连接、文件、内存）
- 破坏向后兼容性
- 严重性能问题

#### 非致命问题（记录继续）

- 代码风格不一致
- 边界条件遗漏（有合理兜底）
- 文档不完整（代码本身可理解）
- 重复代码（不导致 bug）
- 未来优化建议

### TDD

- red → green → refactor 循环
- 每循环提交
- 提交前自检

### 测试

- 0 failures 才能通过
- 每功能点至少 1 个测试
- 测试点分级：P0 核心业务逻辑 / P1 边界条件 / P2 异常处理
- 覆盖：新生成 + 现有关联 + 影响回归

### 合并

- 禁止 AI 主动合入本地分支
- merge 由用户执行
- squash 所有 commit 为 1 个

### 跨文件/共享依赖

- 多 Subagent 仅可并行无文件/数据依赖的模块
- 共享文件/数据依赖的模块必须串行

---

## 关键约定

### Subagent 启动约定

- 不加载主对话历史，仅给定输入文件清单
- 必填返回结构：ok（是否通过）/ fatal（致命问题列表）/ non_fatal（非致命问题列表）/ suggestions（改进建议列表）
- 工具白名单：只读工具，不修改代码

### 文档必填字段

- dev-handbook.md：背景 / 目标 / 方案对比 / 接口设计 / 任务拆分 / 并发分析 / 风险 / 验收
- status.md（per-feature）：阶段 / 完成项 / 进行中 / 阻塞 / 下一步
- test-report.md：P0/P1/P2 测试点 / 覆盖率 / 0 failures 证据
- summary.md：变更摘要 / worktree 路径 / 合并命令预览

### 并发分组规则

- 共享依赖识别：共同 import 模块 / 共同读写的数据结构 / 共享全局状态
- 无共享依赖的模块可并行
- 共享依赖模块必须串行

### squash 与合流的关系

- Phase 2 工作流内合流：worktree 间合并，保留分支分叉图
- Phase 4 最终落地：squash 为单 commit 入目标分支
- 二者不冲突：合流 ≠ squash，分属不同阶段

---

## 流程

### Phase 1: 需求分析+设计+计划

- 通过 brainstorming 澄清需求
- 展示候选方案对比
- 写 dev-handbook.md（实现计划 + 并发可行性分析）
- 独立 Subagent 审查
- 用户批准

### Phase 2: 并行开发

- 在 worktree 中开发
- 多 Subagent 并行（按并发分析）
- 各 Subagent 走 TDD 循环 + 频繁提交
- 各 Subagent 独立 commit 到自己的 worktree
- 合流（保留分支历史）
- 更新 status.md

### Phase 3: 测试+Review

- 独立 Subagent 补全测试 + 执行（0 failures）
- 独立 Subagent 质量审计
- 致命问题 → 回 Phase 2 修复 → 重新 Phase 3
- worktree 提交

### Phase 4: 完成

- squash 所有 commit
- 同步 tests/ 和 .dev_doc/ 到本地分支
- 调用 doc_integrate
- 调用 todo_list_manager
- 通知用户（merge 由用户执行）

---

## 异常处理

### 中断/放弃

- 立即停止
- 检查 worktree 状态（commit / untracked）
- 用户选择保留或删除 worktree
- 告知用户当前进度和恢复方式
