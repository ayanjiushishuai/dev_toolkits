# Phase 5.1 测试策略

★ Insight ─────────────────────────────────────
这是 AI 自动化测试节点，完全自主执行。
测试用例基于需求和开发进度自动生成。
测试代码写入 tests/ 目录，远程环境执行。
─────────────────────────────────────────────────

---

## 目的

在用户手动测试前，通过自动化测试验证功能完整性。

---

## 输入

1. `.dev_doc/<feature>/status.md` - 开发进度和功能点
2. `.dev_doc/<feature>/plan.md` - 实现计划
3. `.dev_doc/<feature>/design.md` - 设计文档
4. `worktree` 中的代码变动

---

## 输出

1. `tests/` 目录下生成的测试文件
2. 远程环境测试执行结果
3. 测试报告 `.dev_doc/<feature>/test-report.md`

---

## 测试用例来源（双重覆盖）

| 类别 | 来源 | 生成/匹配方式 |
|------|------|---------------|
| **新生成** | 本次开发内容 | 基于 `status.md` 功能列表 + `plan.md` 实现步骤 + worktree 代码变动，生成针对性测试 |
| **现有关联** | 已有的相关测试 | 扫描 `tests/` 目录，匹配与开发模块相关的现有测试用例，确保覆盖完整 |

---

## 测试用例策略

1. **新生成测试** - 每个功能点至少生成 1 个测试用例
2. **现有关联测试** - 识别并确认执行与本次开发相关的已有测试用例
3. **影响回归测试** - 针对改动可能影响的上下游模块，匹配相关现有测试
4. **完整覆盖** - 新生成 + 现有关联的总覆盖率达到功能点的 100%

---

## 测试框架对接

| 测试类型 | 写入位置 | 执行命令 |
|----------|----------|----------|
| 工具单元测试 | `tests/tools/` | `pytest tests/tools/ -v -m unit` |
| 集成测试 | `tests/integration/` | `pytest tests/integration/ -v` |
| 端到端测试 | `tests/data/test_cases_<feature>.xlsx` | `python tests/batch_runner.py` |

---

## 执行流程

```
1. 分析阶段
   ├── 读取 .dev_doc/<feature>/status.md → 获取功能点列表
   ├── 读取 .dev_doc/<feature>/plan.md → 获取已完成的实现步骤
   ├── 分析 worktree 代码变动 → 确定需要测试的文件
   └── 扫描 tests/ 目录 → 匹配现有关联测试用例

2. 生成阶段
   ├── 基于功能点生成测试用例（每个功能点至少 1 个测试）
   ├── 基于代码变动生成针对性测试
   └── 写入 tests/ 目录

3. 执行阶段
   ├── scp 测试文件到远程环境（如需要）
   ├── SSH 远程执行: ssh dev@192.168.110.52 -p 2223
   └── cd /tmp/dev/huashan_dev && python -m pytest tests/ -v

4. 报告阶段
   ├── 汇总测试结果（passed/failed/skipped）
   ├── 分析失败原因
   └── 生成报告 .dev_doc/<feature>/test-report.md

5. 合并阶段（⭐ 用户手动 merge）
   ├── ⚠️ 不再自动合并，所有变更保留在 worktree 中
   ├── 通知用户：worktree 代码已就绪，等待手动 merge
   └── 保留 worktree，不删除，等待用户验收通过
```

---

## 测试断言标准

```python
# 必须包含的具体断言
assert response is not None           # 响应不为空
assert "error" not in response         # 无错误
assert len(response) > 0              # 有实际内容

# 基于功能的断言（示例）
assert "预期结果" in response          # 包含预期关键词
assert isinstance(response, dict)      # 类型正确
```

---

## 完成标准

- 测试用例覆盖所有功能点（新生成 + 现有关联）
- 所有测试通过（0 failures）
- ⚠️ **代码保留在 worktree 中，等待用户手动 merge**
- 如有失败，修复后重新测试直到通过

---

## 失败处理

```
❌ 测试失败
失败测试: [测试名]
失败原因: [具体原因]
正在修复...
修复后重新测试...
```
