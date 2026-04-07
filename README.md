# Dev Toolkits

个人 Claude Code 开发工具集，包含多个提升开发效率的 Skills。

## Skills

| Skill | 说明 | 触发条件 |
|-------|------|----------|
| **ez-dev** | 完整开发流程（需求→独立Review→设计→TDD→验证→完成） | "帮我开发..."、"实现一个..." |
| **doc_integrate** | 文档整合与同步维护 | "整理文档"、"同步文档" |
| **hs_test** | 华山项目测试技能 | "运行测试"、"执行测试" |
| **test** | 通用测试工程技能 | "测试报告"、"生成测试用例" |
| **update_doc** | 开发文档健康度审计与更新 | "审计文档"、"检查文档过时" |
| **skill-sync** | 同步 skills 到 Git 仓库 | "同步 skills"、"发布 skills" |

---

## 前置要求 ⚠️

**ez-dev 依赖以下官方插件，必须在安装本工具集之前完成安装：**

```bash
# 安装 superpowers 插件（包含 brainstorming, writing-plans, subagent-driven-development 等）
/plugin install superpowers@claude-plugins-official

# 安装 frontend-design 插件
/plugin install frontend-design@claude-plugins-official

# 安装 code-review 插件
/plugin install code-review@claude-plugins-official

# 安装 skill-creator 插件（用于打包发布）
/plugin install skill-creator@claude-plugins-official
```

| 插件 | 提供的 Skills | 用途 |
|------|-------------|------|
| **superpowers** | brainstorming, writing-plans, subagent-driven-development, verification-before-completion | ez-dev 核心依赖 |
| **frontend-design** | frontend-design | ez-dev Phase 2 前端设计 |
| **code-review** | code-review | ez-dev Phase 4.1 代码 Review |
| **skill-creator** | skill-creator | skill-sync 打包发布 |

---

## 安装

### 方式一：直接复制（推荐）

```bash
# 克隆仓库
git clone https://github.com/ayanjiushishuai/dev_toolkits.git

# 复制 skills 到本地 Claude Code skills 目录
cp -r skills/* ~/.claude/skills/
```

> Claude Code 会自动发现 `~/.claude/skills/` 目录下的所有 SKILL.md 文件。

### 方式二：打包安装

1. 下载 Release 中的 `.skill` 文件
2. 将 `.skill` 文件放到 `~/.claude/skills/` 目录
3. 重启 Claude Code 或执行 `/skills` 刷新

---

## 使用说明

### ez-dev 开发流程

```
/ez-dev 帮我开发一个用户认证功能
```

### 同步 Skills

```bash
# 使用 skill-sync skill 自动同步
# 在 Claude Code 中执行 skill-sync skill 的同步流程

# 或手动执行
cd D:/02_code/dev_toolkits
./skills/skill-sync/scripts/sync_and_release.sh
```

---

## 目录结构

```
dev_toolkits/
├── .claude-plugin/          # 插件元数据
├── skills/                   # 所有 Skills
│   ├── ez-dev/              # 完整开发流程
│   │   └── references/      # 引用文档（design-review, test-strategy 等）
│   ├── doc_integrate/       # 文档整合
│   ├── hs_test/             # 华山测试
│   ├── test/                # 通用测试
│   ├── update_doc/          # 文档审计
│   └── skill-sync/          # 同步工具
├── scripts/
└── README.md
```

---

## License

MIT
