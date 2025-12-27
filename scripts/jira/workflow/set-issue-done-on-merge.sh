#!/bin/bash

# PRマージ時にJiraチケットのステータスを"Done"に変更するスクリプト
# PRのタイトルまたはブランチ名からIssueキーを抽出して、ステータスをDoneに変更

set -e

# 使い方
if [ $# -lt 1 ]; then
  echo "使い方: $0 <PR_NUMBER> [ISSUE_KEY]"
  echo "例: $0 27"
  echo "例: $0 27 MWD-20"
  exit 1
fi

PR_NUMBER=$1
ISSUE_KEY="${2:-}"

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JIRA_SCRIPT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 設定ファイルの読み込み
if [ -f "${JIRA_SCRIPT_DIR}/config.sh" ]; then
  source "${JIRA_SCRIPT_DIR}/config.sh" 2>/dev/null || true
fi

# 共通関数の読み込み
if [ -f "${JIRA_SCRIPT_DIR}/common.sh" ]; then
  source "${JIRA_SCRIPT_DIR}/common.sh" 2>/dev/null || true
fi

# Issueキーが指定されていない場合、PRから抽出
if [ -z "$ISSUE_KEY" ]; then
  # PR情報を取得
  PR_INFO=$(gh pr view "$PR_NUMBER" --json title,headRefName 2>/dev/null || echo "")
  
  if [ -z "$PR_INFO" ]; then
    echo "⚠️  警告: PR #${PR_NUMBER} の情報を取得できませんでした" >&2
    exit 0
  fi
  
  PR_TITLE=$(echo "$PR_INFO" | jq -r '.title // ""')
  BRANCH_NAME=$(echo "$PR_INFO" | jq -r '.headRefName // ""')
  
  # PRタイトルからIssueキーを抽出（例: feat(MWD-20): ...）
  if echo "$PR_TITLE" | grep -qE '\([A-Z]+-[0-9]+\)'; then
    ISSUE_KEY=$(echo "$PR_TITLE" | grep -oE '\([A-Z]+-[0-9]+\)' | tr -d '()')
  # ブランチ名からIssueキーを抽出（例: feature/MWD-20-task-1-3）
  elif echo "$BRANCH_NAME" | grep -qE '[A-Z]+-[0-9]+'; then
    ISSUE_KEY=$(echo "$BRANCH_NAME" | grep -oE '[A-Z]+-[0-9]+' | head -1)
  fi
fi

# Issueキーが抽出できなかった場合
if [ -z "$ISSUE_KEY" ]; then
  echo "⚠️  警告: PR #${PR_NUMBER} からIssueキーを抽出できませんでした" >&2
  echo "   タイトル: ${PR_TITLE}" >&2
  echo "   ブランチ: ${BRANCH_NAME}" >&2
  echo "   手動でIssueキーを指定してください: $0 $PR_NUMBER <ISSUE_KEY>" >&2
  exit 0
fi

# Issueキーの形式チェック
if ! [[ "$ISSUE_KEY" =~ ^[A-Z]+-[0-9]+$ ]]; then
  echo "⚠️  警告: 無効なIssueキー形式です: ${ISSUE_KEY}" >&2
  exit 0
fi

# Issueが存在するか確認
ISSUE_INFO=$(jira_api_call "GET" "issue/${ISSUE_KEY}" 2>/dev/null || echo "")
if [ -z "$ISSUE_INFO" ] || ! echo "$ISSUE_INFO" | jq -e '.key' > /dev/null 2>&1; then
  echo "⚠️  警告: Issue ${ISSUE_KEY} が見つかりませんでした" >&2
  exit 0
fi

# 現在のステータスを確認
CURRENT_STATUS=$(echo "$ISSUE_INFO" | jq -r '.fields.status.name // ""')
echo "📋 現在のステータス: ${CURRENT_STATUS}"

# ステータスをDoneに変更
echo "🔄 Issue ${ISSUE_KEY} のステータスを 'Done' に変更中..."

# まず遷移可能なステータスを取得
TRANSITIONS_DATA=$(jira_api_call "GET" "issue/${ISSUE_KEY}/transitions" 2>/dev/null || echo "")

if [ -z "$TRANSITIONS_DATA" ] || ! echo "$TRANSITIONS_DATA" | jq -e '.transitions' > /dev/null 2>&1; then
  echo "⚠️  警告: 遷移可能なステータスを取得できませんでした" >&2
  exit 0
fi

# 「Done」または「完了」への遷移が可能か確認
DONE_TRANSITION=$(echo "$TRANSITIONS_DATA" | jq -r '.transitions[] | select(.name == "Done" or .name == "完了" or .to.name == "Done" or .to.name == "完了") | .id' | head -1)

if [ -z "$DONE_TRANSITION" ] || [ "$DONE_TRANSITION" = "null" ]; then
  # 「Done」への直接遷移ができない場合、「In Progress」を経由
  IN_PROGRESS_TRANSITION=$(echo "$TRANSITIONS_DATA" | jq -r '.transitions[] | select(.name == "開始" or .name == "In Progress" or .to.name == "In Progress" or .to.name == "進行中") | .id' | head -1)
  
  if [ -n "$IN_PROGRESS_TRANSITION" ] && [ "$IN_PROGRESS_TRANSITION" != "null" ]; then
    echo "   → まず 'In Progress' に遷移中..."
    TRANSITION_DATA=$(jq -n --arg transition_id "$IN_PROGRESS_TRANSITION" '{transition: {id: $transition_id}}')
    jira_api_call "POST" "issue/${ISSUE_KEY}/transitions" "$TRANSITION_DATA" > /dev/null 2>&1 || true
    
    # 遷移可能なステータスを再取得
    sleep 1
    TRANSITIONS_DATA=$(jira_api_call "GET" "issue/${ISSUE_KEY}/transitions" 2>/dev/null || echo "")
    DONE_TRANSITION=$(echo "$TRANSITIONS_DATA" | jq -r '.transitions[] | select(.name == "Done" or .name == "完了" or .to.name == "Done" or .to.name == "完了") | .id' | head -1)
  fi
fi

# 「Done」または「完了」への遷移を実行
if [ -n "$DONE_TRANSITION" ] && [ "$DONE_TRANSITION" != "null" ]; then
  TRANSITION_DATA=$(jq -n --arg transition_id "$DONE_TRANSITION" '{transition: {id: $transition_id}}')
  jira_api_call "POST" "issue/${ISSUE_KEY}/transitions" "$TRANSITION_DATA" > /dev/null 2>&1 || {
    echo "⚠️  警告: ステータス変更に失敗しました（続行します）" >&2
    exit 0
  }
  echo "✅ Issue ${ISSUE_KEY} のステータスを 'Done' に変更しました"
else
  echo "⚠️  警告: 'Done' または '完了' への遷移が見つかりませんでした" >&2
  echo "   利用可能な遷移:" >&2
  echo "$TRANSITIONS_DATA" | jq -r '.transitions[] | "  - \(.name)"' >&2
  exit 0
fi

