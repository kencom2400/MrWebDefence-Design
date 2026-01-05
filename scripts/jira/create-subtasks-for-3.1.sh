#!/bin/bash
set -eo pipefail

REPO_ROOT="/Users/kencom/github/MrWebDefence-Design"
cd "$REPO_ROOT"

if [ -f "scripts/jira/config.local.sh" ]; then
    source scripts/jira/config.local.sh
fi

source scripts/jira/common.sh

PARENT_KEY="MWD-27"
PROJECT_KEY="MWD"

# Issue Type一覧を取得
echo "🔄 Issue Type一覧を取得中..."
RESPONSE=$(jira_api_call "GET" "issue/createmeta?projectKeys=${PROJECT_KEY}&expand=projects.issuetypes" 2>&1)
if [ $? -ne 0 ]; then
    echo "❌ エラー: Issue Type一覧の取得に失敗しました"
    echo "$RESPONSE"
    exit 1
fi

# Sub-taskのIssue Type IDを取得（日本語名も確認）
SUBTASK_TYPE_ID=$(echo "$RESPONSE" | jq -r '.projects[0].issuetypes[] | select(.name | test("Sub-task|サブタスク|Subtask"; "i")) | .id' | head -1)

if [ -z "$SUBTASK_TYPE_ID" ] || [ "$SUBTASK_TYPE_ID" = "null" ]; then
    echo "❌ エラー: Sub-taskのIssue Type IDを取得できませんでした"
    echo "利用可能なIssue Type:"
    echo "$RESPONSE" | jq -r '.projects[0].issuetypes[] | "  - \(.name) (ID: \(.id))"'
    exit 1
fi

echo "✅ Sub-task Issue Type ID: $SUBTASK_TYPE_ID"
echo ""

# サブタスクを作成する関数
create_subtask_direct() {
    local task_num=$1
    local repo=$2
    local why_do=$3
    shift 3
    local what_do_items=("$@")
    
    local title="Task ${task_num}: ユーザー認証機能実装（${repo}）"
    
    # ADF形式のdescriptionを作成
    local what_do_list="["
    local first=true
    for item in "${what_do_items[@]}"; do
        if [ -n "$item" ]; then
            if [ "$first" = false ]; then
                what_do_list="${what_do_list},"
            fi
            first=false
            local escaped=$(echo "$item" | jq -Rs .)
            what_do_list="${what_do_list}{\"type\":\"listItem\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":${escaped}}]}]}"
        fi
    done
    what_do_list="${what_do_list}]"
    
    local description=$(jq -n \
        --arg why_do "$why_do" \
        --arg repo "$repo" \
        --argjson what_do_list "$what_do_list" \
        '{
            type: "doc",
            version: 1,
            content: [
                {type: "heading", attrs: {level: 2}, content: [{type: "text", text: "なぜやるか"}]},
                {type: "paragraph", content: [{type: "text", text: $why_do}]},
                {type: "heading", attrs: {level: 2}, content: [{type: "text", text: "何をやるか（概要）"}]},
                {type: "bulletList", content: $what_do_list},
                {type: "heading", attrs: {level: 2}, content: [{type: "text", text: "リポジトリ"}]},
                {type: "paragraph", content: [{type: "text", text: $repo}]}
            ]
        }')
    
    local issue_data=$(jq -n \
        --arg project_key "$PROJECT_KEY" \
        --arg issue_type_id "$SUBTASK_TYPE_ID" \
        --arg title "$title" \
        --argjson description "$description" \
        --arg parent_key "$PARENT_KEY" \
        '{
            fields: {
                project: {key: $project_key},
                issuetype: {id: $issue_type_id},
                summary: $title,
                description: $description,
                parent: {key: $parent_key}
            }
        }')
    
    echo "🔄 サブタスクを作成中: $title"
    local response=$(jira_api_call "POST" "issue" "$issue_data" 2>&1)
    
    if [ $? -eq 0 ] && echo "$response" | jq -e . >/dev/null 2>&1; then
        local issue_key=$(echo "$response" | jq -r '.key')
        echo "✅ 作成成功: $issue_key"
        echo ""
        return 0
    else
        echo "❌ 作成失敗"
        echo "$response" | jq -r '.errors // .errorMessages // .' 2>/dev/null || echo "$response"
        echo ""
        return 1
    fi
}

# サブタスクを作成
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  サブタスク作成開始"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

create_subtask_direct "3.1.1" "MrWebDefence-Design" "設計リポジトリとして、ユーザー認証機能の設計ドキュメントを整備する必要がある。" \
    "認証APIの詳細設計の追加・明確化" \
    "セッション管理の実装詳細設計の追加" \
    "パスワードハッシュ化の実装詳細設計の追加" \
    "実装手順のドキュメント化"

create_subtask_direct "3.1.2" "MrWebDefence-Console" "ユーザーが安全にログインし、セッションを管理できるようにする必要がある。" \
    "ログインAPI実装（POST /api/v1/auth/login）" \
    "ログアウトAPI実装（POST /api/v1/auth/logout）" \
    "セッション管理実装（Redis使用）" \
    "セッションクッキー設定（HttpOnly, Secure, SameSite）" \
    "パスワードハッシュ化実装（bcrypt）"

create_subtask_direct "3.1.3" "MrWebDefence-Engine" "WAFエンジンが管理APIと通信する際の認証機能を実装する必要がある。" \
    "APIトークン認証の実装（管理APIとの通信）" \
    "設定取得時の認証処理" \
    "トークン検証機能の実装"

create_subtask_direct "3.1.4" "MrWebDefence-SignatureCollector" "シグニチャ収集機能が管理APIと通信する際の認証機能を実装する必要がある。" \
    "APIトークン認証の実装（管理APIとの通信）" \
    "シグニチャ送信時の認証処理" \
    "トークン検証機能の実装"

create_subtask_direct "3.1.5" "MrWebDefence-LogServer" "ログ管理サーバが管理APIと通信する際の認証機能を実装する必要がある。" \
    "APIトークン認証の実装（管理APIとの通信）" \
    "ログ送信時の認証処理" \
    "トークン検証機能の実装"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ すべてのサブタスクの作成が完了しました"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
