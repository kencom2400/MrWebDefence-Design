#!/bin/bash

# Jira設定ファイル
# このファイルはJira操作スクリプト全般から参照されます
#
# 設定の優先順位:
# 1. 環境変数（最優先）
# 2. config/projects/*.yaml（Single Source of Truth）
# 3. config.local.sh（認証情報のみ）
# 4. デフォルト値

# ローカル設定ファイルの読み込み（存在する場合）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/config.local.sh" ]; then
  source "${SCRIPT_DIR}/config.local.sh"
fi

# プロジェクト設定ファイル（YAML）から設定を読み込む関数
# Single Source of Truth: config/projects/*.yaml
load_project_config() {
  local repo_root
  # リポジトリルートを検出（.gitディレクトリまたはconfigディレクトリを探す）
  repo_root="${SCRIPT_DIR}"
  while [ "$repo_root" != "/" ]; do
    if [ -d "${repo_root}/.git" ] || [ -d "${repo_root}/config" ]; then
      break
    fi
    repo_root="$(dirname "$repo_root")"
  done
  
  local project_config_file="${repo_root}/config/projects/mrwebdefence-design.yaml"
  
  # yqコマンドの確認
  if ! command -v yq &> /dev/null; then
    echo "⚠️  警告: yqコマンドが見つかりません。YAML設定ファイルから設定を読み込めません。" >&2
    echo "   デフォルト値または環境変数を使用します。" >&2
    echo "   インストール方法: brew install yq (macOS) または snap install yq (Linux)" >&2
    return 1
  fi
  
  # プロジェクト設定ファイルの存在確認
  if [ ! -f "$project_config_file" ]; then
    echo "⚠️  警告: プロジェクト設定ファイルが見つかりません: $project_config_file" >&2
    echo "   デフォルト値または環境変数を使用します。" >&2
    return 1
  fi
  
  # YAMLファイルから設定を読み込む
  # 環境変数が設定されていない場合のみ、YAMLファイルの値を設定
  # 注意: 関数内では変数に設定するのみ（exportは呼び出し元で行う）
  
  # ヘルパー関数: YAML値が有効で環境変数が未設定の場合に設定
  set_config_if_unset() {
    local yaml_value="$1"
    local env_var_name="$2"
    
    # yqの"null"文字列と空文字をチェック（yqはnullを"null"文字列として返すことがある）
    if [ -n "$yaml_value" ] && [ "$yaml_value" != "null" ] && [ -z "${!env_var_name:-}" ]; then
      eval "$env_var_name=\"\$yaml_value\""
    fi
  }
  
  # 各設定を読み込んで設定
  set_config_if_unset "$(yq eval '.issue_tracker // ""' "$project_config_file" 2>/dev/null)" "ISSUE_TRACKER"
  set_config_if_unset "$(yq eval '.jira.project_key // ""' "$project_config_file" 2>/dev/null)" "JIRA_PROJECT_KEY"
  set_config_if_unset "$(yq eval '.jira.base_url // ""' "$project_config_file" 2>/dev/null)" "JIRA_BASE_URL"
}

# プロジェクト設定ファイルから設定を読み込む（readonly定義前に実行）
load_project_config

# Issueトラッカー設定（環境変数 > YAML > デフォルト）
# readonlyは最後に定義
ISSUE_TRACKER="${ISSUE_TRACKER:-jira}"
export ISSUE_TRACKER
readonly ISSUE_TRACKER

# Jira設定（環境変数 > YAML > デフォルト）
JIRA_PROJECT_KEY="${JIRA_PROJECT_KEY:-MWD}"
JIRA_BASE_URL="${JIRA_BASE_URL:-https://kencom2400.atlassian.net}"
export JIRA_PROJECT_KEY JIRA_BASE_URL
readonly JIRA_PROJECT_KEY JIRA_BASE_URL

# 認証情報（環境変数またはconfig.local.shから取得）
# 注意: これらの値は環境変数またはconfig.local.shで設定する必要があります
# config.local.sh.exampleをコピーしてconfig.local.shを作成してください
readonly JIRA_EMAIL="${JIRA_EMAIL:-}"
readonly JIRA_API_TOKEN="${JIRA_API_TOKEN:-}"
export JIRA_EMAIL JIRA_API_TOKEN

# API Rate Limit対策
readonly API_RATE_LIMIT_WAIT="${API_RATE_LIMIT_WAIT:-1}"  # API rate limit対策の基本待機時間（秒）
export API_RATE_LIMIT_WAIT

# リトライ処理の設定
readonly MAX_RETRIES="${MAX_RETRIES:-5}"  # API反映待機のリトライ最大回数
readonly RETRY_INTERVAL="${RETRY_INTERVAL:-3}"  # リトライ間隔（秒）
export MAX_RETRIES RETRY_INTERVAL

