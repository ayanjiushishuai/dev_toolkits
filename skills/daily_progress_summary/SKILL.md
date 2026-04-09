---
name: daily-progress-summary
description: 生成每日开发进度总结报告。当用户说"生成开发进度报告"、"总结今日进度"、"日报"、"daily report"、"开发进度"、"整理进度"时触发。
---

# Daily Progress Summary Skill

本 skill 生成每日开发进度总结报告，包含任务汇总、代码变更、实际开发进展和待解决问题。

## 核心原则

- **聚焦开发进度**：关注功能开发和任务完成情况
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

HTML报告文件，保存到 `.dev_doc/daily_process/YYYY-MM-DD.html`

---

## 执行步骤

### Step 1: 创建输出目录

```bash
mkdir -p .dev_doc/daily_process
```

### Step 2: 读取源文件

并行读取：
- `.dev_doc/todo.md`
- `.dev_doc/work_done.md`
- `.dev_doc/status.md`（如果存在）

### Step 3: 获取Git信息

```bash
# 最近7天的提交记录
git log --oneline --since="7 days ago" -20

# 当前未提交的变更
git status --short

# 今日变更统计
git diff --stat HEAD
```

### Step 4: 解析信息

#### 4.1 任务汇总（来自 todo.md）

按优先级分组：
- **P0**：紧急且重要，必须优先处理
- **P1**：重要任务，近期应该完成
- **P2**：常规任务
- **P3**：低优先级

#### 4.2 今日完成（来自 work_done.md）

- 提取今日完成的事项
- 按模块分类

#### 4.3 开发进展（来自 status.md 或 git log）

- 当前进行的阶段
- 阶段进度百分比

#### 4.4 代码变更

- 已提交但未合并的提交
- 未提交的本地变更

### Step 5: 生成HTML报告

---

## HTML报告模板

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>开发进度总结 - {{date}}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; border-bottom: 2px solid #4A90E2; padding-bottom: 10px; }
        h2 { color: #4A90E2; margin-top: 30px; }
        section { background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background: #4A90E2; color: white; }
        .p0 { color: #e74c3c; font-weight: bold; }
        .p1 { color: #e67e22; }
        .p2 { color: #3498db; }
        .p3 { color: #95a5a6; }
        .completed { background: #d4edda; }
        .in-progress { background: #cce5ff; }
        .pending { background: #fff3cd; }
        .meta { color: #666; font-size: 0.9em; }
        ul { margin: 10px 0; }
        li { margin: 5px 0; }
        pre { background: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 12px; }
        .stat-box { display: flex; gap: 20px; margin: 15px 0; }
        .stat { background: white; padding: 15px 25px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-value { font-size: 28px; font-weight: bold; color: #4A90E2; }
        .stat-label { font-size: 14px; color: #666; }
    </style>
</head>
<body>
    <h1>开发进度总结 - {{date}}</h1>

    <section id="overview">
        <h2>概览</h2>
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
        </div>
        <p><strong>当前阶段：</strong>{{phase}}</p>
        <p><strong>功能：</strong>{{feature}}</p>
        <p><strong>状态：</strong>{{status}}</p>
    </section>

    <section id="tasks">
        <h2>任务汇总</h2>
        <table>
            <tr><th>优先级</th><th>模块</th><th>任务</th><th>说明</th></tr>
            {{task_rows}}
        </table>
    </section>

    <section id="completed">
        <h2>今日/本周完成</h2>
        <table>
            <tr><th>日期</th><th>模块</th><th>完成事项</th></tr>
            {{completed_rows}}
        </table>
    </section>

    <section id="changes">
        <h2>代码变更</h2>
        <h3>最近7天提交</h3>
        <pre>{{git_log}}</pre>
        <h3>未提交变更</h3>
        <pre>{{git_status}}</pre>
    </section>

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

## 下一步行动：开发任务视角

**重要**：下一步行动应该是**开发任务**，不是代码合入。

### 正确的下一步示例

- 「继续完成 P0 任务：表检索重复调用优化」
- 「开始 P1 任务：数据库检索缓存机制优化」
- 「完成当前功能的测试用例编写」
- 「调研神通数据库兼容方案」
- 「准备 AskUserQuestion Skill 的实现方案」

### 错误的下一步示例（不应出现）

- 「合并 feature/async-query 分支」❌
- 「将 worktree 合并到 dev_zby」❌
- 「提交 PR」❌

### 优先级分析

根据 todo.md 中的任务优先级，分析：

1. **P0 任务状态**：有多少 P0 任务未完成，是否阻塞
2. **P1 任务进展**：本周 P1 任务完成情况
3. **下周计划**：基于当前进度，下周应该关注什么

---

## 注意事项

1. **使用中文输出**
2. **优先展示 P0 和 P1 任务**
3. **下一步只包含开发任务**，不包含合入/合并/PR 等操作
4. **代码变更需要同时展示已提交和未提交的**
5. **报告生成后告知用户文件路径**

---

## 成功标准

- HTML 文件成功生成在 `.dev_doc/daily_process/{date}.html`
- 包含所有主要部分（概览、任务、已完成、变更、后续计划）
- 任务按优先级正确分类
- Git 信息完整准确
- 下一步聚焦开发任务，不涉及代码合入
