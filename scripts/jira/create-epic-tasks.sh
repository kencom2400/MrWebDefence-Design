#!/bin/bash

# Epicのタスクを一括作成するスクリプト
# 使用方法: ./scripts/jira/create-epic-tasks.sh <epic_num>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ $# -lt 1 ]; then
    echo "使用方法: $0 <epic_num>" >&2
    echo "例: $0 2" >&2
    exit 1
fi

EPIC_NUM=$1
EPIC_KEY="MWD-${EPIC_NUM}"
EPIC_TASK_DESIGN="${REPO_ROOT}/EPIC_TASK_DESIGN.md"

if [ ! -f "$EPIC_TASK_DESIGN" ]; then
    echo "❌ エラー: EPIC_TASK_DESIGN.md が見つかりません" >&2
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Epic ${EPIC_NUM} のタスク作成"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Pythonスクリプトでタスク情報を抽出して本文ファイルを作成
python3 << PYTHON_SCRIPT
import re
import sys

epic_num = ${EPIC_NUM}

# EPIC_TASK_DESIGN.mdを読み込む
with open('${EPIC_TASK_DESIGN}', 'r', encoding='utf-8') as f:
    content = f.read()

# このEpicのタスクを抽出
task_pattern = rf'##### Task {epic_num}\.(\d+): (.+?)\n\*\*リポジトリ\*\*: (.+?)\n\n\*\*なぜやるか\*\*\n(.+?)\n\n\*\*何をやるか（概要）\*\*\n(.+?)\n\n\*\*受け入れ条件\*\*\n(.+?)(?=\n\n##### Task|\n---|\Z)'
tasks = re.finditer(task_pattern, content, re.DOTALL)

for task in tasks:
    task_num = task.group(1)
    task_title = task.group(2).strip()
    repo = task.group(3).strip()
    why = task.group(4).strip()
    what = task.group(5).strip()
    acceptance = task.group(6).strip()
    
    # 本文ファイルを作成
    body_file = f"/tmp/task{epic_num}_{task_num}_body.md"
    with open(body_file, 'w', encoding='utf-8') as f:
        f.write(f"""## なぜやるか

{why}

## 何をやるか（概要）

{what}

## 受け入れ条件

{acceptance}

## リポジトリ

- {repo}
""")
    
    print(f"Task {epic_num}.{task_num}: {task_title}")
    print(f"  本文ファイル: {body_file}")

PYTHON_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Jiraにタスクを作成中..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# タスクを作成
CREATED_TASKS=()

for task_file in /tmp/task${EPIC_NUM}_*_body.md; do
    if [ ! -f "$task_file" ]; then
        continue
    fi
    
    # タスク番号を抽出
    task_num=$(basename "$task_file" | sed "s/task${EPIC_NUM}_\(.*\)_body.md/\1/")
    
    # タイトルを取得
    title_line=$(grep -A 1 "##### Task ${EPIC_NUM}.${task_num}:" "$EPIC_TASK_DESIGN" | head -1)
    title=$(echo "$title_line" | sed "s/##### Task [0-9.]*: //")
    
    echo "作成中: Task ${EPIC_NUM}.${task_num}: ${title}"
    
    # Jiraに作成
    OUTPUT=$(bash "${REPO_ROOT}/scripts/jira/issues/create-issue.sh" \
        --project-key MWD \
        --title "Task ${EPIC_NUM}.${task_num}: ${title}" \
        --issue-type タスク \
        --body-file "$task_file" \
        --status ToDo 2>&1)
    
    # Issueキーを抽出
    ISSUE_KEY=$(echo "$OUTPUT" | grep "Issueキー:" | sed 's/.*Issueキー: //' | head -1)
    
    if [ -n "$ISSUE_KEY" ]; then
        CREATED_TASKS+=("$ISSUE_KEY")
        echo "  ✅ 作成成功: $ISSUE_KEY"
    else
        echo "  ❌ 作成失敗"
        echo "$OUTPUT" | grep -E "(エラー|error|Error)" | head -3
    fi
    
    echo ""
    sleep 1
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Epic ${EPIC_NUM} にタスクを紐づけ中..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Epicに紐づけ
for task_key in "${CREATED_TASKS[@]}"; do
    echo "紐づけ中: ${task_key} → ${EPIC_KEY}"
    bash "${REPO_ROOT}/scripts/jira/issues/link-task-to-epic.sh" "$task_key" "$EPIC_KEY" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "  ✅ 紐づけ成功"
    else
        echo "  ❌ 紐づけ失敗"
    fi
    sleep 1
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Epic ${EPIC_NUM} のタスク作成完了"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "作成されたタスク: ${#CREATED_TASKS[@]} 個"
for task_key in "${CREATED_TASKS[@]}"; do
    echo "  - ${task_key}"
done

