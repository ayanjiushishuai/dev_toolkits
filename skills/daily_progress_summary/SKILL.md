---
name: daily-progress-summary
description: 生成每日开发进度总结报告。并行执行进度总结、任务更新、全量测试、文档整理，汇总成HTML报告。
---

# Daily Progress Summary Skill

本 skill 执行每日自动化巡检流程，并行下发4个子任务，全部完成后汇总成HTML报告。

★ Insight ─────────────────────────────────────
1. **并行 + 串行**：4个子任务并行执行，全部完成后才生成汇总报告
2. **测试优先**：测试失败优先修复而非跳过，这是报告可信度的基石
3. **文档追踪代码**：代码是唯一的真，文档必须追代码
─────────────────────────────────────────────────

## 核心原则

- **聚焦开发进度**：关注功能开发和任务完成情况
- **测试失败必须展示**：测试报告的失败用例需详细展示报错原因
- **下一步是开发任务**：不涉及代码合入，聚焦待开发功能
- **优先级驱动**：结合 P0/P1/P2/P3 优先级判断任务进度

---

## 输入

- `.dev_doc/todo.md` - 待办事项清单
- `.dev_doc/work_done.md` - 已完成事项清单
- `.dev_doc/status.md` - 当前开发状态（如果有）
- `git log` - 最近提交记录
- `git status` - 当前代码变更状态

---

## 输出

HTML报告文件，保存到 `.dev_doc/daily_reports/YYYY-MM-DD.html`

---

## 执行流程

```
┌─────────────────────────────────────────────────────────────────────┐
│  Step 1: 并行下发4个子任务                                           │
│                                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐      │
│  │ 每日进度总结     │  │ 进度更新与日报   │  │ 全量自动测试    │      │
│  │ (daily_summary) │  │ (todo_update)   │  │ (test_runner)  │      │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘      │
│           └─────────────────┬─────────────────┬─────────────────┘    │
│                             ▼                                     │
│                    ┌─────────────────┐                             │
│                    │  文档整理        │                             │
│                    │ (doc_integrate) │                             │
│                    └────────┬────────┘                             │
│                             │                                     │
│                             ▼ all complete                        │
│  Step 2: 汇总生成HTML报告                                           │
│                    ↓                                               │
│  .dev_doc/daily_reports/YYYY-MM-DD.html                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: 并行下发4个子任务

使用 dispatching-parallel-agents skill，下发4个独立 agent：

### Agent 1: 每日进度总结 (daily_summary)

**任务**：生成每日进度总结

**执行内容**：
1. 读取 `.dev_doc/todo.md`、`.dev_doc/work_done.md`、`.dev_doc/status.md`（如果存在）
2. 执行 git log 和 git status 获取代码变更
3. 按优先级汇总任务状态
4. 生成结构化总结（JSON格式返回）

**返回格式**：
```json
{
  "agent": "daily_summary",
  "phase": "当前阶段",
  "feature": "当前功能",
  "status": "状态描述",
  "today_commits": 数字,
  "week_completed": 数字,
  "pending_p0": 数字,
  "tasks_by_priority": {...},
  "git_summary": "git log摘要",
  "git_status": "未提交变更摘要"
}
```

### Agent 2: 进度更新与日报 (todo_update)

**任务**：根据当日 git 提交和代码变动，更新 todo 状态

**执行内容**：
1. 读取 `.dev_doc/todo.md`
2. 分析今日 git commits：哪些任务相关的代码有变动
3. 根据代码验证（参考 todo_list_manager 的两阶段检测策略）判断任务是否已完成
4. 更新 todo.md：将已完成的任务标记/迁移
5. 生成任务清理报告

**返回格式**：
```json
{
  "agent": "todo_update",
  "tasks_cleaned": [
    {"task": "任务名", "action": "migrated_to_work_done", "reason": "分支已合并"}
  ],
  "todo_updates": "todo.md变更摘要",
  "report": "任务清理报告markdown"
}
```

### Agent 3: 全量自动测试 (test_runner)

**任务**：执行全量测试，修复失败用例，输出测试报告

**执行内容**：
1. 确认远程测试环境可用（ssh dev@192.168.110.52 -p 2223）
2. 如代码有更新，先 scp 同步代码到远程
3. 执行全量测试：`cd /tmp/dev/huashan_dev && python3 -m pytest tests/ -v`
4. 如果有测试失败：
   - 分析失败原因
   - 尝试修复（优先修复环境问题、依赖问题）
   - 重新执行测试验证修复
   - 如果是代码 bug，记录但不阻塞流程
5. 生成测试报告

**返回格式**：
```json
{
  "agent": "test_runner",
  "total_tests": 数字,
  "passed": 数字,
  "failed": 数字,
  "skipped": 数字,
  "pass_rate": "xx%",
  "failures": [
    {
      "test_name": "test_xxx",
      "file": "tests/xxx.py",
      "error": "错误信息摘要",
      "reason": "可能的原因分析"
    }
  ],
  "test_report_path": "报告文件路径",
  "fixed_issues": ["修复的问题列表"]
}
```

### Agent 4: 文档整理 (doc_integrate)

**任务**：整理当日散落的文档到规范路径

**执行内容**：
1. 执行 doc_integrate skill 的标准流程：
   - 扫描 `.dev_doc/` 根目录的日期前缀文档（YYYY-MM-DD-*.md）
   - 扫描非规范路径的散落文档
   - 识别 ez-dev 遗留文档（`.dev_doc/<feature>/`）
2. 对每份文档执行代码验证
3. 执行整合：合并到模块 README / 移动到 design/ / 删除
4. 更新模块 CHANGELOG.md
5. 生成文档整合报告

**返回格式**：
```json
{
  "agent": "doc_integrate",
  "integrated": ["已整合的文档列表"],
  "deleted": ["已删除的文档列表"],
  "moved_to_design": ["移至design/的文档列表"],
  "preserved": ["保留的文档列表"],
  "report": "完整整合报告markdown"
}
```

### 并行下发命令

```python
# 4个agent并行下发
Agent("daily_summary", prompt=每日进度总结任务)
Agent("todo_update", prompt=进度更新任务)
Agent("test_runner", prompt=全量测试任务)
Agent("doc_integrate", prompt=文档整理任务)
# 等待全部完成
```

---

## Step 2: 汇总生成HTML报告

所有子任务完成后，将4个agent的结果汇总成一个HTML报告。

**报告结构**（核心原则：开头展示概览，下方展示细节）：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>每日开发巡检报告 - {{date}}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 1400px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; border-bottom: 2px solid #4A90E2; padding-bottom: 10px; }
        h2 { color: #4A90E2; margin-top: 30px; }
        h3 { color: #666; margin-top: 20px; }
        section { background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .alert { background: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .alert-error { background: #f8d7da; border: 1px solid #dc3545; }
        .alert-success { background: #d4edda; border: 1px solid #28a745; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #4A90E2; color: white; }
        .p0 { color: #dc3545; font-weight: bold; }
        .p1 { color: #e67e22; }
        .p2 { color: #3498db; }
        .p3 { color: #95a5a6; }
        .completed { background: #d4edda; }
        .in-progress { background: #cce5ff; }
        .pending { background: #fff3cd; }
        .failed { background: #f8d7da; }
        .meta { color: #666; font-size: 0.9em; }
        ul { margin: 10px 0; }
        li { margin: 5px 0; }
        pre { background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 12px; }
        .stat-box { display: flex; gap: 20px; margin: 15px 0; flex-wrap: wrap; }
        .stat { background: white; padding: 15px 25px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); min-width: 120px; }
        .stat-value { font-size: 28px; font-weight: bold; color: #4A90E2; }
        .stat-label { font-size: 14px; color: #666; }
        .stat-error { color: #dc3545; }
        .badge { display: inline-block; padding: 3px 8px; border-radius: 3px; font-size: 12px; }
        .badge-success { background: #28a745; color: white; }
        .badge-danger { background: #dc3545; color: white; }
        .badge-warning { background: #ffc107; color: #333; }
        .timestamp { float: right; color: #999; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>每日开发巡检报告 <span class="timestamp">{{YYYY-MM-DD}}</span></h1>

    <!-- 概览区 - 核心指标一眼可见 -->
    <section id="overview">
        <h2>巡检概览</h2>
        <div class="stat-box">
            <div class="stat">
                <div class="stat-value">{{today_commits}}</div>
                <div class="stat-label">今日提交</div>
            </div>
            <div class="stat">
                <div class="stat-value">{{week_completed}}</div>
                <div class="stat-label">本周完成</div>
            </div>
            <div class="stat">
                <div class="stat-value">{{pending_p0}}</div>
                <div class="stat-label">待处理P0</div>
            </div>
            <div class="stat">
                <div class="stat-value {{#if test_failures}}stat-error{{/if}}">{{test_pass_rate}}</div>
                <div class="stat-label">测试通过率</div>
            </div>
            <div class="stat">
                <div class="stat-value">{{docs_integrated}}</div>
                <div class="stat-label">文档已整理</div>
            </div>
        </div>
        <p><strong>当前阶段：</strong>{{phase}}</p>
        <p><strong>功能：</strong>{{feature}}</p>
        <p><strong>状态：</strong>{{status}}</p>
    </section>

    <!-- 测试结果区 - 失败用例必须展示 -->
    {{#if test_failures}}
    <section id="test-results" class="alert-error" style="background: #f8d7da; border: 1px solid #dc3545;">
        <h2 style="color: #dc3545;">⚠️ 测试失败详情 <span class="badge badge-danger">{{test_failures.length}} 个失败</span></h2>
        <p><strong>通过率：</strong>{{test_pass_rate}} ({{test_passed}}/{{test_total}})</p>

        {{#each test_failures}}
        <div style="background: white; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #dc3545;">
            <h3 style="color: #333; margin-top: 0;">❌ {{test_name}}</h3>
            <p><strong>文件：</strong><code>{{file}}</code></p>
            <p><strong>错误信息：</strong></p>
            <pre style="background: #fff; color: #333;">{{error}}</pre>
            <p><strong>可能原因：</strong>{{reason}}</p>
            {{#if fixed}}
            <p><strong>修复状态：</strong><span class="badge badge-success">已修复 ✓</span></p>
            {{else}}
            <p><strong>修复状态：</strong><span class="badge badge-danger">未修复</span></p>
            {{/if}}
        </div>
        {{/each}}

        {{#if test_report_url}}
        <p><strong>完整测试报告：</strong><a href="{{test_report_url}}">{{test_report_url}}</a></p>
        {{/if}}
    </section>
    {{else}}
    <section id="test-results" class="alert-success">
        <h2 style="color: #28a745;">✓ 测试结果 <span class="badge badge-success">全部通过</span></h2>
        <p><strong>通过率：</strong>{{test_pass_rate}} ({{test_passed}}/{{test_total}})</p>
        {{#if test_report_url}}
        <p><strong>完整测试报告：</strong><a href="{{test_report_url}}">{{test_report_url}}</a></p>
        {{/if}}
    </section>
    {{/if}}

    <!-- 任务更新报告 -->
    <section id="todo-updates">
        <h2>任务状态更新</h2>
        {{#if tasks_cleaned}}
        <p>今日清理了 {{tasks_cleaned.length}} 个任务：</p>
        <table>
            <tr><th>任务</th><th>操作</th><th>原因</th></tr>
            {{#each tasks_cleaned}}
            <tr>
                <td>{{task}}</td>
                <td><span class="badge badge-success">{{action}}</span></td>
                <td>{{reason}}</td>
            </tr>
            {{/each}}
        </table>
        {{else}}
        <p>今日无任务状态变更。</p>
        {{/if}}
    </section>

    <!-- 文档整理报告 -->
    <section id="doc-integrate">
        <h2>文档整理</h2>
        {{#if docs_integrated}}
        <div style="display: flex; gap: 20px; margin: 10px 0; flex-wrap: wrap;">
            <div class="stat" style="background: #d4edda;">
                <div class="stat-value" style="color: #28a745;">{{docs_integrated}}</div>
                <div class="stat-label">已整合</div>
            </div>
            <div class="stat" style="background: #cce5ff;">
                <div class="stat-value" style="color: #004085;">{{docs_design}}</div>
                <div class="stat-label">移至design</div>
            </div>
            <div class="stat" style="background: #f8d7da;">
                <div class="stat-value" style="color: #721c24;">{{docs_deleted}}</div>
                <div class="stat-label">已删除</div>
            </div>
        </div>
        {{/if}}
        {{doc_report}}
    </section>

    <!-- 任务汇总 -->
    <section id="tasks">
        <h2>任务汇总</h2>
        <table>
            <tr><th>优先级</th><th>模块</th><th>任务</th><th>说明</th></tr>
            {{task_rows}}
        </table>
    </section>

    <!-- 代码变更 -->
    <section id="changes">
        <h2>代码变更</h2>
        <h3>最近提交</h3>
        <pre>{{git_log}}</pre>
        <h3>未提交变更</h3>
        <pre>{{git_status}}</pre>
    </section>

    <!-- 后续开发计划 -->
    <section id="next-steps">
        <h2>后续开发计划</h2>
        <p><strong>基于今日进度和优先级：</strong></p>
        <ul>
            {{next_dev_tasks}}
        </ul>
        <h3>任务优先级分析</h3>
        <ul>
            {{priority_analysis}}
        </ul>
    </section>
</body>
</html>
```

---

## Step 3: 保存报告

```bash
mkdir -p .dev_doc/daily_reports
# 报告已在上一步生成，直接保存为 .dev_doc/daily_reports/YYYY-MM-DD.html
```

---

## 子任务详细说明

### daily_summary 详细执行步骤

**Step 1**: 创建输出目录
```bash
mkdir -p .dev_doc/daily_reports
```

**Step 2**: 并行读取源文件
- `.dev_doc/todo.md`
- `.dev_doc/work_done.md`
- `.dev_doc/status.md`（如果存在）

**Step 3**: 获取Git信息
```bash
git log --oneline --since="7 days ago" -20
git status --short
git diff --stat HEAD
```

**Step 4**: 解析信息，生成结构化数据

### todo_update 详细执行步骤

**Step 0**: 读取 todo.md，扫描所有待办任务

**Step 1**: 两阶段检测已完成任务

阶段1（有分支信息）：
```bash
git branch --merged {main_branch} | grep {分支名}
```

阶段2（无分支或未通过）：
```bash
git log --oneline main --all --grep="{关键词}" -n 5
git log --oneline main --all -S "{关键词}" -n 3
```

**Step 2**: 执行迁移
- 已合并 → 追加到 work_done.md，从 todo.md 删除
- 未合并 → 保持不动
- 无法判断 → 标记为"存疑"

**Step 3**: 输出任务清理报告

### test_runner 详细执行步骤

**Step 1**: 确认远程环境
```bash
ssh dev@192.168.110.52 -p 2223 "cd /tmp/dev/huashan_dev && ls -la"
```

**Step 2**: 如代码有更新，scp 同步
```bash
scp -P 2223 -r <changed_files> dev@192.168.110.52:/tmp/dev/huashan_dev/
```

**Step 3**: 执行全量测试
```bash
ssh dev@192.168.110.52 -p 2223 "cd /tmp/dev/huashan_dev && python3 -m pytest tests/ -v --tb=short"
```

**Step 4**: 分析失败原因并尝试修复
- 环境/依赖问题 → 修复后重新测试
- 代码 bug → 记录到报告，不阻塞

**Step 5**: 生成测试报告

### doc_integrate 详细执行步骤

参考 doc_integrate skill 的标准流程：

**Step 1**: 扫描散落文档
- `.dev_doc/` 根目录的日期前缀文档
- 非规范路径的散落文档
- ez-dev 遗留文档

**Step 2**: 代码验证（核心步骤）
- 检查文档提到的文件是否存在
- 对比接口签名
- git log 确认代码变动时间

**Step 3**: 执行整合
- 已完成 → 合并到模块 README
- 代码不存在且30天+ → 删除
- 设计文档 → 移动到 design/ 子目录

**Step 4**: 输出整合报告

---

## 注意事项

1. **使用中文输出**
2. **测试失败必须展示在报告最显眼位置**（概览区附近）
3. **下一步只包含开发任务**，不包含合入/合并/PR 等操作
4. **报告生成后告知用户文件路径**
5. **并行下发后必须等待所有 agent 完成后才能生成汇总报告**

---

## 成功标准

- HTML 文件成功生成在 `.dev_doc/daily_reports/{date}.html`
- 包含所有主要部分（概览、测试结果、任务更新、文档整理、任务、变更、后续计划）
- 测试失败用例详细展示（错误信息、可能原因）
- 4个 agent 的结果都正确汇总
- 下一步聚焦开发任务，不涉及代码合入
