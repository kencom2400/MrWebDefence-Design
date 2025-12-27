# MrWebDefence-Design

MrWebDefenceプロジェクトの設計・ドキュメント管理リポジトリです。

## 📋 リポジトリの役割

このリポジトリは、MrWebDefenceプロジェクト全体の設計ドキュメントと開発プロセス管理を担当します。

### 主な責務

- **設計ドキュメント管理**: システム全体のアーキテクチャ、データベース、APIなどの設計ドキュメントを一元管理
- **プロジェクト管理**: Epic・タスク設計、要件定義、意思決定ポイントの記録
- **開発プロセス支援**: Jira/GitHub統合スクリプトによる開発ワークフロー自動化
- **設定管理**: プロジェクト設定のSingle Source of Truthとして機能

### 関連リポジトリ

MrWebDefenceプロジェクトは以下のリポジトリで構成されています：

| リポジトリ名 | 言語 | 主な責務 |
|------------|------|---------|
| **MrWebDefence-Design** | shell | 設計・ドキュメント管理（このリポジトリ） |
| MrWebDefence-Engine | shell | WAFエンジン（OpenAppSec統合） |
| MrWebDefence-Console | typescript | 管理画面（フロントエンド・バックエンド） |
| MrWebDefence-SignatureCollector | typescript | シグニチャ収集・検証機能 |
| MrWebDefence-LogServer | ruby | ログ管理サーバ |

## 📚 成果物（ドキュメント）

すべての設計ドキュメントは [`docs/`](./docs/) ディレクトリに配置されています。

### 設計ドキュメント

- **[詳細設計書](./docs/DESIGN.md)** (`docs/DESIGN.md`)
  - システム全体アーキテクチャ
  - コンポーネント構成と責務
  - データフロー設計
  - 通信プロトコル定義
  - セキュリティ境界定義
  - データベース設計
  - API設計
  - その他詳細設計

- **[Epic・タスク設計書](./docs/EPIC_TASK_DESIGN.md)** (`docs/EPIC_TASK_DESIGN.md`)
  - Epic一覧と詳細
  - タスク一覧と詳細
  - 受け入れ条件
  - 実装順序の推奨

### 要件・仕様ドキュメント

- **[要件定義書](./docs/SPECIFICATION.md)** (`docs/SPECIFICATION.md`)
  - システム概要
  - 機能要件
  - 非機能要件
  - ユーザーストーリー

- **[要件定義書（詳細版）](./docs/REQUIREMENT.md)** (`docs/REQUIREMENT.md`)
  - 詳細な要件定義

- **[OpenAppSec仕様書](./docs/OPENAPPSEC_SPECIFICATION.md)** (`docs/OPENAPPSEC_SPECIFICATION.md`)
  - OpenAppSecの基本アーキテクチャ
  - 機械学習モデル
  - 機能詳細
  - 設定管理

### 意思決定・設定ドキュメント

- **[意思決定ポイント](./docs/DECISION_POINTS.md)** (`docs/DECISION_POINTS.md`)
  - アーキテクチャの意思決定
  - 技術選定の理由
  - 設計判断の記録

- **[Jira統合設定ガイド](./docs/JIRA_SETUP.md)** (`docs/JIRA_SETUP.md`)
  - Jira統合の設定手順
  - プロジェクト設定
  - Issueトラッキングの使用方法

## 🛠️ 開発プロセス支援

### Issueトラッキング

このリポジトリは **Jira** を使用してIssue管理を行います。

- **プロジェクトキー**: `MWD`
- **Jira URL**: https://kencom2400.atlassian.net

### スクリプト

開発ワークフローを支援するスクリプトが `scripts/` ディレクトリに配置されています。

#### Jira統合スクリプト

- **`scripts/jira/workflow/start-task.sh`**: タスク開始（Issue選択、ブランチ作成、ステータス更新）
- **`scripts/jira/issues/create-issue.sh`**: Issue作成
- **`scripts/jira/issues/get-issue.sh`**: Issue情報取得
- **`scripts/jira/projects/set-issue-done.sh`**: Issue完了処理

詳細は [Jira統合設定ガイド](./docs/JIRA_SETUP.md) を参照してください。

#### GitHub統合スクリプト

- **`scripts/github/issues/create-issue-graphql.sh`**: GitHub Issue作成
- **`scripts/github/pr-linking/link-pr-to-issues.sh`**: PRとIssueの紐づけ

### 設定ファイル

- **`config/projects/mrwebdefence-design.yaml`**: プロジェクト設定（Single Source of Truth）
  - Issueトラッカー設定
  - Jira設定
  - リポジトリ情報

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/kencom2400/MrWebDefence-Design.git
cd MrWebDefence-Design
```

### 2. 設定ファイルの準備

```bash
# Jira認証情報の設定（初回のみ）
cp scripts/jira/config.local.sh.example scripts/jira/config.local.sh
# scripts/jira/config.local.sh を編集して認証情報を設定
```

### 3. タスクの開始

```bash
# 最優先のタスクを選択して開始
bash scripts/jira/workflow/start-task.sh

# 特定のIssueを指定して開始
bash scripts/jira/workflow/start-task.sh MWD-XX
```

## 📖 ドキュメントの読み方

### 設計を理解したい場合

1. [要件定義書](./docs/SPECIFICATION.md) でシステムの全体像を把握
2. [詳細設計書](./docs/DESIGN.md) でアーキテクチャと設計詳細を確認
3. [意思決定ポイント](./docs/DECISION_POINTS.md) で技術選定の理由を理解

### 開発タスクを開始したい場合

1. [Epic・タスク設計書](./docs/EPIC_TASK_DESIGN.md) でタスクの詳細を確認
2. `@start-task` コマンドでタスクを開始
3. 関連する設計ドキュメントを参照しながら実装

### プロジェクト管理を理解したい場合

1. [Epic・タスク設計書](./docs/EPIC_TASK_DESIGN.md) でプロジェクト全体の構成を把握
2. [Jira統合設定ガイド](./docs/JIRA_SETUP.md) でIssue管理の方法を確認

## 📁 ディレクトリ構成

```
MrWebDefence-Design/
├── docs/                    # 設計ドキュメント
│   ├── DESIGN.md            # 詳細設計書
│   ├── EPIC_TASK_DESIGN.md  # Epic・タスク設計書
│   ├── SPECIFICATION.md     # 要件定義書
│   ├── REQUIREMENT.md       # 要件定義書（詳細版）
│   ├── OPENAPPSEC_SPECIFICATION.md  # OpenAppSec仕様書
│   ├── DECISION_POINTS.md   # 意思決定ポイント
│   └── JIRA_SETUP.md        # Jira統合設定ガイド
├── scripts/                 # 開発支援スクリプト
│   ├── jira/               # Jira統合スクリプト
│   └── github/             # GitHub統合スクリプト
├── config/                  # 設定ファイル
│   └── projects/           # プロジェクト設定（SSOT）
├── .cursor/                # Cursor IDE設定
│   └── rules/              # 開発ルール・ワークフロー定義
└── README.md               # このファイル
```

## 🔗 関連リンク

- **Jiraプロジェクト**: https://kencom2400.atlassian.net/browse/MWD
- **GitHubリポジトリ**: https://github.com/kencom2400/MrWebDefence-Design

## 📝 ライセンス

（ライセンス情報を記載）

## 👥 コントリビューション

（コントリビューションガイドラインを記載）

---

**最終更新**: 2024年
