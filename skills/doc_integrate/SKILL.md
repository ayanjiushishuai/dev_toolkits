---
name: doc_integrate
description: 文档整合与同步维护 Skill。当用户说"整理文档"、"合并文档"、"更新开发文档"、"同步文档和代码"时触发。扫描散落文档，整合到 .dev_doc/ 对应模块的规范路径，验证文档与代码一致性，更新模块 README 和 CHANGELOG。
---

# doc_integrate: 文档整合与同步维护

## 核心原则

1. **代码是唯一真**。文档状态标记可能过时，代码不会说谎。
2. **不归档，只整合**。散落文档合并到规范路径，不创建 .archive/。
3. **操作对象是文件**。不删除目录，只删除文件；不创建目录，只创建文件。
4. **每份文档必须有明确处理结果**，不保留在"待处理"状态。

## 整理原则

### 原则 1：模块归并
相关模块合并到统一路径。
- `vector-schema-sync` + `vector-store-async-query` → `vector_store/`
- 通过代码目录判断归属：`extra_function/utils/vector_stores` → `vector_store/`

### 原则 2：功能整合
相似功能整合到一个文档中，避免同一模块功能分散在多个 design.md。

### 原则 3：完成后合并
已完成模块（Phase >= 6）的 design/plan/status 文档合并到模块 README。
- design.md + plan.md + status.md → 合并成 `模块/README.md` 章节
- changelog.md → 合并到 `模块/CHANGELOG.md`

### 原则 4：规范路径
模块应在规范路径下，不在临时 feature 目录。
- `vector_store/` ✅
- `vector-schema-sync/` ❌ 临时目录，应清空合并

### 原则 5：进行中模块不强制合并
仍在开发的模块（Phase < 6）暂时不处理，等完成后再合并。

### 原则 6：子目录结构
每个模块子目录下**只保留两个文件**：
- `README.md`：记录模块架构、使用方法
- `CHANGELOG.md`：记录所有历史变更（包括已废除内容）

其他内容全部整合到上述两个文件。

### 原则 7：散落文档处理

| 散落文档 | 归属 |
|----------|------|
| `test_fix_plan.md` | `database/` |
| `excel-test-case-library-plan.md` | `database/` |
| `项目代码优化修改.md` | 已完成→CHANGELOG，未完成→README |
| `text2sql_skill_suite_design.md` | `database/` |

---

## 执行流程

### Step 1: 扫描
1. 扫描 `.dev_doc/` 根目录的日期前缀文档（YYYY-MM-DD-*.md）
2. 扫描所有子目录，检查是否有多余文件（README.md 和 CHANGELOG.md 以外）
3. 识别 ez-dev 遗留文档（`.dev_doc/<feature>/`）

**必须扫描所有子目录**，确保不遗漏任何文档。

### Step 2: 代码验证
对每份提到具体代码文件的文档：
1. 检查文件是否存在
2. 对比接口签名是否一致
3. 用 git log 确认代码实际变动时间

### Step 3: 整合执行
- 代码存在且验证通过 → 合并到模块 README
- 代码不存在且文档超过 30 天 → 删除
- 内容重复或无价值 → 删除

### Step 4: 目录清理
每个子目录下只保留 `README.md` 和 `CHANGELOG.md`：
- 扫描所有子目录的文件
- 多余文件整合到上述两个文件后删除
- 如果子目录内只有这两个文件，确认无误后完成

### Step 5: 报告
```markdown
# 文档整合报告 - YYYY-MM-DD

## 整合统计
| 状态 | 数量 |
|------|------|
| 已整合到模块 README | X |
| 已删除 | X |
| 保留在根目录（可能需要开发） | X |

## 子目录清理
- ✅ vector_stores/：只保留 README.md, CHANGELOG.md
- ✅ database/：只保留 README.md, CHANGELOG.md
...
```

---

## 规范路径

```
.dev_doc/
├── architecture.md        ← 根目录核心文档
├── vector_stores/
│   ├── README.md         ← 架构、使用方法
│   └── CHANGELOG.md      ← 历史变更记录
├── data_process/
│   ├── README.md
│   └── CHANGELOG.md
└── <feature>/            ← ez-dev 临时目录，完成后清空
```

**任何不在规范路径的文档都是待整理对象。**

---

## 标准 README 格式

```markdown
# 模块名

## 概述
一句话描述模块作用。

## 架构
模块整体结构和核心组件。

## 使用方法

### 初始化
```python
from module import ClassName
```

### 核心接口

#### `method_name(param)`
描述方法作用。

**参数：**
- `param` (type): 参数描述

**返回：** 返回值类型和含义

**示例：**
```python
result = method_name("input")
```

## 配置
相关配置项说明。

## 子模块

### 子模块名
子模块作用和用法。
```

## 标准 CHANGELOG 格式

```markdown
# 模块名 CHANGELOG

## [未整合] YYYY-MM-DD

### 文档变更
- 合并 `原文档名` 到 README §章节名
- 删除 `原文档名`：原因

### 代码变动
- `文件路径`
  - 变更描述

### 同步记录
- 文档与代码不一致处已修正：修正内容
```

**关键结构：**

| 区域 | 内容 |
|------|------|
| 概述 | 一句话，不超过两行 |
| 架构 | 组件关系，用文字或代码块描述 |
| 使用方法 | 按初始化→核心接口→配置→子模块顺序 |
| CHANGELOG | 每条变更带日期，包括已删除/废除记录 |

---

## 注意事项

1. 不生成"待开发"列表，每份文档立即决策
2. 文档与代码不符时，以代码为准更新文档
3. .archive/ 禁止，发现即清理
4. git log 是确认代码实现时间的好帮手
5. 删除优于归档，无价值文档直接删除