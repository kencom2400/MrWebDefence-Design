# Jira統合設定ガイド

このドキュメントは、MrWebDefence-DesignプロジェクトでJiraを使用するための設定手順を説明します。

## 設定状況

### ✅ 完了済み設定

1. **プロジェクト設定ファイル（Single Source of Truth）** (`config/projects/mrwebdefence-design.yaml`)
   - Issueトラッカー: `jira`
   - Jiraプロジェクトキー: `MWD`
   - JiraベースURL: `https://kencom2400.atlassian.net`
   - ⭐ このファイルが設定の唯一の情報源です

2. **基本設定スクリプト** (`scripts/jira/config.sh`)
   - YAMLファイルから設定を自動読み込み
   - 環境変数との統合を管理
   - 設定の優先順位を制御

3. **認証情報** (`scripts/jira/config.local.sh`)
   - Jira Email: 設定済み
   - Jira API Token: 設定済み
   - ⚠️ このファイルは`.gitignore`に追加されているため、Gitにpushされません

4. **Jira接続テスト**
   - ✅ プロジェクト情報取得: 成功
   - ✅ Issue種別取得: 成功（5種類）
   - ✅ ユーザー認証: 成功

## プロジェクト情報

- **プロジェクト名**: Mr. Web Defense
- **プロジェクトキー**: MWD
- **プロジェクトID**: 10000

## Issue種別

以下のIssue種別が利用可能です：

| ID   | 名前     | 説明                                   |
| ---- | -------- | -------------------------------------- |
| 10001 | タスク   | さまざまな小規模作業。                 |
| 10002 | バグ     | 問題またはエラー。                     |
| 10003 | ストーリー | ユーザー目標として表明された機能。   |
| 10004 | エピック | 一連の関連するバグ、ストーリー、タスクを追跡。 |
| 10005 | サブタスク | 大規模なタスク内の小さな作業を追跡。 |

## 使用方法

### Issue作成

```bash
# 対話型モード
./scripts/jira/issues/create-issue.sh

# バッチモード
./scripts/jira/issues/create-issue.sh \
  --title "[bug] E2Eテストエラー" \
  --body "## 概要\n\nE2Eテストが失敗します" \
  --issue-type Bug \
  --status ToDo
```

### Issue情報取得

```bash
# Issue情報を取得
./scripts/jira/get-issue.sh MWD-123

# JSON形式で取得
./scripts/jira/get-issue.sh MWD-123 --json
```

### ステータス遷移

```bash
# In Progressに変更
./scripts/jira/projects/set-issue-in-progress.sh MWD-123

# Doneに変更
./scripts/jira/projects/set-issue-done.sh MWD-123

# 任意のステータスに変更
./scripts/jira/transition-issue.sh MWD-123 "To Do"
```

### @start-taskコマンド（Jira版）

```bash
# 最優先Issueを自動選択
./scripts/jira/workflow/start-task.sh

# 特定のIssueを開始
./scripts/jira/workflow/start-task.sh MWD-123
```

## ステータス遷移フロー

```
Backlog → To Do → In Progress → Done
                ↑                ↓
                └────────────────┘
              （戻り遷移）
```

### ステータス遷移のタイミング

- **Backlog**: チケット作成時（自動設定）
- **To Do**: 次に取り組むチケットとして選択した時
- **In Progress**: 実際の作業を開始した時（`@start-task`実行時）
- **Done**: 作業が完了し、PRがマージされた時

## 設定ファイルの場所

- **プロジェクト設定（Single Source of Truth）**: `config/projects/mrwebdefence-design.yaml`
  - このファイルが設定の唯一の情報源です
  - プロジェクトキー、ベースURL、Issueトラッカー種別を定義
- **基本設定スクリプト**: `scripts/jira/config.sh`
  - YAMLファイルから設定を読み込む
  - 環境変数やデフォルト値との統合を管理
- **認証情報**: `scripts/jira/config.local.sh`（`.gitignore`に追加）
  - Jira Email と API Token を設定
  - ローカル環境専用（Gitにpushされません）
- **共通関数**: `scripts/jira/common.sh`
  - Jira API呼び出しの共通関数

## 設定の優先順位

設定値は以下の優先順位で適用されます（高い順）：

1. **環境変数**（最優先）
   - `JIRA_PROJECT_KEY`, `JIRA_BASE_URL`, `ISSUE_TRACKER` など
   - CI/CD環境や一時的な設定変更に使用

2. **プロジェクト設定ファイル**（`config/projects/mrwebdefence-design.yaml`）
   - **Single Source of Truth**: このファイルが設定の唯一の情報源です
   - プロジェクト全体で共有される設定
   - 変更時はGitで管理され、レビューが必要

3. **ローカル設定ファイル**（`scripts/jira/config.local.sh`）
   - 認証情報（`JIRA_EMAIL`, `JIRA_API_TOKEN`）のみ
   - 個人環境専用（Gitにpushされません）

4. **デフォルト値**
   - `config.sh`内で定義されたフォールバック値

### Single Source of Truthについて

`config/projects/mrwebdefence-design.yaml`は、プロジェクト設定の**Single Source of Truth**（唯一の情報源）として設計されています。

**メリット:**
- 設定の重複を排除
- 設定変更時の影響範囲が明確
- バージョン管理とレビューが容易
- 複数環境での設定管理が統一

**注意事項:**
- `scripts/jira/config.sh`内のハードコードされた値は、YAMLファイルから読み込まれる値で上書きされます
- 環境変数が設定されている場合は、環境変数が最優先されます

## トラブルシューティング

### 認証エラー

```
❌ エラー: 環境変数 JIRA_EMAIL と JIRA_API_TOKEN が設定されていません。
```

**対処方法**:
1. `scripts/jira/config.local.sh`が存在するか確認
2. 認証情報が正しく設定されているか確認
3. Jira API Tokenが有効か確認

### プロジェクト未検出

```
❌ エラー: プロジェクト情報の取得に失敗しました
```

**対処方法**:
1. プロジェクトキー（`MWD`）が正しいか確認
2. プロジェクトへのアクセス権限を確認
3. JiraインスタンスのURLが正しいか確認

## 参考資料

- `.cursor/rules/04-github-integration.d/05-jira-integration.md` - Jira統合ルール
- `scripts/jira/` - Jira操作スクリプト

