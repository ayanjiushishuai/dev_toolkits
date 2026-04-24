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
if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
    echo "  无变更，跳过提交"
else
    CHANGES=$(git diff --stat 2>/dev/null | tail -1 || echo "")
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
