# Jira統合設定ガイド

このドキュメントは、MrWebDefence-DesignプロジェクトでJiraを使用するための設定手順を説明します。

## 設定状況

### ✅ 完了済み設定

1. **Jira基本設定** (`scripts/jira/config.sh`)
   - プロジェクトキー: `MWD`
   - ベースURL: `https://kencom2400.atlassian.net`
   - Issueトラッカー: `jira`

2. **認証情報** (`scripts/jira/config.local.sh`)
   - Jira Email: 設定済み
   - Jira API Token: 設定済み
   - ⚠️ このファイルは`.gitignore`に追加されているため、Gitにpushされません

3. **プロジェクト設定ファイル** (`config/projects/mrwebdefence-design.yaml`)
   - Issueトラッカー: `jira`
   - Jiraプロジェクトキー: `MWD`

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

- **基本設定**: `scripts/jira/config.sh`
- **認証情報**: `scripts/jira/config.local.sh`（`.gitignore`に追加）
- **プロジェクト設定**: `config/projects/mrwebdefence-design.yaml`
- **共通関数**: `scripts/jira/common.sh`

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

