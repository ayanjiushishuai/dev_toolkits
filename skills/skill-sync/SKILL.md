---
name: skill-sync
description: "同步用户全局 skills 到 Git 仓库并发布。当用户说"同步skills"、"发布skills"、"更新skills到github"、"sync skills"时触发。**本 skill 只同步用户全局 skills（~/.claude/skills/），不同步项目内的 skills（项目 .claude/skills/ 目录）。**负责将全局 skills 同步到 dev_toolkits 仓库，并打包 .skill 文件发布 Release。"
---

# Skill Sync

★ Insight ─────────────────────────────────────
这个 skill 的核心功能：
1. 将 `~/.claude/skills/` 的内容同步到本地 git 仓库
2. 自动提交并 push 到 GitHub
3. 打包 .skill 文件到 Release
─────────────────────────────────────────────────

---

## 使用场景

当你完成了以下操作后，使用本 skill：
- 修改了用户全局 skill 的内容
- 新增了用户全局 skill
- 删除了用户全局 skill
- 想要发布新版本的 skills

**⚠️ 注意：本 skill 只同步用户全局 skills（`~/.claude/skills/`），不同步项目内的 skills（项目根目录下 `.claude/skills/`）。**

---

## 同步流程

### Step 1: 确定同步范围

**输入：** 无需用户输入

**任务：** 检查 `~/.claude/skills/` 下有哪些 skills（用户全局 skills）

```
# 检查全局 skills 目录
ls -la ~/.claude/skills/
```

**⚠️ 重要：不要访问项目内的 skills 目录（如 `./.claude/skills/` 或 `项目根目录/.claude/skills/`），只操作用户全局目录。**

---

### Step 2: 同步到本地 git 仓库

**本地仓库路径：** `D:\02_code\dev_toolkits`

**任务：**
1. 将 `~/.claude/skills/` 下的所有内容**复制**到 `D:\02_code\dev_toolkits\skills\`
2. 覆盖原有内容（保留 skill-sync 本身）
3. 删除 git 仓库中已不存在的 skills

**同步命令：**
```bash
# 假设本地仓库路径
LOCAL_REPO="D:/02_code/dev_toolkits"
SKILLS_DIR="$HOME/.claude/skills"

# 1. 删除旧的 skills 目录内容（保留 skill-sync itself）
rm -rf "$LOCAL_REPO/skills/"*

# 2. 复制所有 skills（除了 skill-sync 自身，避免循环）
for skill in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill")
    if [ "$skill_name" != "skill-sync" ]; then
        cp -r "$skill" "$LOCAL_REPO/skills/"
        echo "同步: $skill_name"
    fi
done

# 3. 保留 skill-sync 自身（从 git 仓库复制回去）
if [ ! -d "$LOCAL_REPO/skills/skill-sync" ]; then
    mkdir -p "$LOCAL_REPO/skills/skill-sync"
fi
cp -r "$LOCAL_REPO/skills/skill-sync/"* "$LOCAL_REPO/skills/skill-sync/" 2>/dev/null || true
```

---

### Step 3: 提交到 GitHub

**任务：**
1. 进入 git 仓库
2. 检查变更（哪些 skills 有变化）
3. 自动生成 commit message
4. push 到 GitHub

**执行命令：**
```bash
cd "D:/02_code/dev_toolkits"

# 检查变更
git status

# 添加所有变更
git add .

# 生成 commit message（包含时间戳和变更列表）
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
CHANGES=$(git diff --cached --stat | tail -1)
git commit -m "Sync skills - $TIMESTAMP

$CHANGES"

# push 到 GitHub
git push origin main
```

---

### Step 4: 打包 .skill 文件（可选）

**任务：** 使用 package_skill.py 打包每个 skill 为 .skill 文件

**前提：** 需要有 skill-creator 的 package_skill.py 脚本

```bash
# 打包所有 skills
SKILL_CREATOR_PATH="$HOME/.claude/plugins/cache/claude-plugins-official/skill-creator/104d39be10b7/skills/skill-creator/scripts"

for skill_dir in skills/*/; do
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        echo "打包: $skill_name"
        python "$SKILL_CREATOR_PATH/package_skill.py" "$skill_dir" "releases/"
    fi
done
```

---

## 完整脚本

### sync_and_release.sh

```bash
#!/bin/bash
# sync_and_release.sh - 同步 skills 到 git 并打包发布

set -e

LOCAL_REPO="D:/02_code/dev_toolkits"
SKILLS_DIR="$HOME/.claude/skills"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

echo "=========================================="
echo "Skill Sync - $TIMESTAMP"
echo "=========================================="

# Step 1: 同步 skills
echo ""
echo "[1/3] 同步 skills 到本地仓库..."
cd "$LOCAL_REPO"

# 保留 skills 目录结构，删除旧内容
rm -rf "$LOCAL_REPO/skills/"*
mkdir -p "$LOCAL_REPO/skills"

# 复制所有 skills
for skill in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill")
    echo "  - 同步: $skill_name"
    cp -r "$skill" "$LOCAL_REPO/skills/"
done

# Step 2: Git 提交
echo ""
echo "[2/3] 提交到 GitHub..."

# 检查变更
CHANGES=$(git diff --stat 2>/dev/null | tail -1 || echo "无变更")
if [ -z "$CHANGES" ]; then
    echo "  无变更，跳过提交"
else
    git add .
    git commit -m "Sync skills - $TIMESTAMP

$CHANGES"
    git push origin main
    echo "  已推送: $CHANGES"
fi

# Step 3: 打包 .skill 文件
echo ""
echo "[3/3] 打包 .skill 文件..."

# 创建 release 目录
mkdir -p "$LOCAL_REPO/releases"

# 打包每个 skill
SKILL_CREATOR="$HOME/.claude/plugins/cache/claude-plugins-official/skill-creator/104d39be10b7/skills/skill-creator/scripts/package_skill.py"

for skill_dir in "$LOCAL_REPO/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
        echo "  - 打包: $skill_name.skill"
        python "$SKILL_CREATOR" "$skill_dir" "$LOCAL_REPO/releases/"
    fi
done

echo ""
echo "=========================================="
echo "同步完成！"
echo "=========================================="
echo ""
echo "Release 文件位置: $LOCAL_REPO/releases/"
ls -la "$LOCAL_REPO/releases/"
```

---

## 阶段声明

**同步开始：**
```
🔄 进入 Skill Sync: 同步流程
正在检查 skills 目录...
正在同步到本地仓库...
正在提交到 GitHub...
正在打包 .skill 文件...
```

**同步完成：**
```
✅ Skill Sync 完成！
已同步 X 个 skills 到 GitHub
Release 文件位置: D:/02_code/dev_toolkits/releases/
```

---

## 注意事项

1. **skill-sync 自身处理**：skill-sync skill 本身也在同步范围内，需要从 git 仓库读取（避免复制自身导致的循环）
2. **git 状态检查**：如果 git status 显示 clean（无变更），跳过 commit 和 push
3. **错误处理**：如果 push 失败，提示用户检查网络或 git 认证状态
4. **打包依赖**：打包 .skill 文件需要 skill-creator 的 package_skill.py 脚本
