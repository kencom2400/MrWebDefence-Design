#!/bin/bash

# DB関連リソース配信スクリプト
# MrWebDefence-Designリポジトリから、DB接続アプリケーションリポジトリにDB関連リソースを配信します。

set -euo pipefail

# カラー出力用の定義
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# デフォルトの配信先
DEFAULT_TARGET_REPO="../MrWebDefence-Console"

# ヘルプメッセージ
show_help() {
    cat << EOF
DB関連リソース配信スクリプト

使用方法:
  $0 [配信先リポジトリパス]

引数:
  配信先リポジトリパス    配信先リポジトリのパス（デフォルト: ${DEFAULT_TARGET_REPO}）

例:
  # デフォルトの配信先（../MrWebDefence-Console）に配信
  $0

  # カスタム配信先を指定
  $0 /path/to/target/repo

配信対象:
  - データベース初期化スクリプト（scripts/database/init-database.sh）
  - Flywayマイグレーションファイル（db-resources/migration/、db-resources/seed/）

注意:
  - このスクリプトはMrWebDefence-Designリポジトリのルートディレクトリから実行してください
  - 配信先リポジトリが存在することを確認してください
EOF
}

# ログ出力関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 引数解析
TARGET_REPO="${1:-${DEFAULT_TARGET_REPO}}"

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# スクリプトの実行場所確認
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ ! -f "${REPO_ROOT}/scripts/database/init-database.sh" ]; then
    log_error "このスクリプトはMrWebDefence-Designリポジトリのルートディレクトリから実行してください"
    exit 1
fi

# 配信先リポジトリの確認
if [ ! -d "${TARGET_REPO}" ]; then
    log_error "配信先リポジトリが見つかりません: ${TARGET_REPO}"
    log_info "配信先リポジトリのパスを確認してください"
    exit 1
fi

log_info "DB関連リソースを配信中..."
log_info "配信先: ${TARGET_REPO}"

# データベース初期化スクリプトの配信
log_info "データベース初期化スクリプトを配信中..."
mkdir -p "${TARGET_REPO}/scripts/database"
if [ -f "${REPO_ROOT}/scripts/database/init-database.sh" ]; then
    cp "${REPO_ROOT}/scripts/database/init-database.sh" "${TARGET_REPO}/scripts/database/"
    chmod +x "${TARGET_REPO}/scripts/database/init-database.sh"
    log_info "✅ データベース初期化スクリプトを配信しました"
else
    log_warn "データベース初期化スクリプトが見つかりません: ${REPO_ROOT}/scripts/database/init-database.sh"
fi

# Flywayマイグレーションファイルの配信
if [ -d "${REPO_ROOT}/db-resources/migration" ] && [ "$(ls -A "${REPO_ROOT}/db-resources/migration" 2>/dev/null)" ]; then
    log_info "Flywayマイグレーションファイル（Versioned Migrations）を配信中..."
    mkdir -p "${TARGET_REPO}/src/main/resources/db/migration"
    cp -r "${REPO_ROOT}/db-resources/migration"/* "${TARGET_REPO}/src/main/resources/db/migration/"
    log_info "✅ Flywayマイグレーションファイル（Versioned Migrations）を配信しました"
else
    log_info "Flywayマイグレーションファイル（Versioned Migrations）はまだ実装されていません"
fi

if [ -d "${REPO_ROOT}/db-resources/seed" ] && [ "$(ls -A "${REPO_ROOT}/db-resources/seed" 2>/dev/null)" ]; then
    log_info "Flywayマイグレーションファイル（Repeatable Migrations）を配信中..."
    mkdir -p "${TARGET_REPO}/src/main/resources/db/seed"
    cp -r "${REPO_ROOT}/db-resources/seed"/* "${TARGET_REPO}/src/main/resources/db/seed/"
    log_info "✅ Flywayマイグレーションファイル（Repeatable Migrations）を配信しました"
else
    log_info "Flywayマイグレーションファイル（Repeatable Migrations）はまだ実装されていません"
fi

log_info "配信完了: ${TARGET_REPO}"
log_info ""
log_info "次のステップ:"
log_info "  1. 配信先リポジトリでファイルの存在を確認してください"
log_info "  2. データベース初期化スクリプトの動作確認を行ってください"
log_info "  3. 開発環境でのデータベース初期化をテストしてください"

