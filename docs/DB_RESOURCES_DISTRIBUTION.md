# DB関連リソース配信手順

このドキュメントでは、MrWebDefence-Designリポジトリで管理されているDB関連リソースを、DB接続アプリケーションリポジトリ（主にMrWebDefence-Console）に配信する手順を説明します。

## 概要

**管理リポジトリ**: MrWebDefence-Design
**配信先リポジトリ**: MrWebDefence-Console（その他のDB接続アプリケーション）

DB関連リソースは、設計リポジトリ（MrWebDefence-Design）で一元管理し、必要に応じてアプリケーションリポジトリに配信します。

## 配信対象リソース

以下のリソースが配信対象です：

1. **データベース初期化スクリプト**
   - `scripts/database/init-database.sh`

2. **Flywayマイグレーションファイル**（将来実装予定）
   - `db-resources/migration/` 内のVersioned Migrations
   - `db-resources/seed/` 内のRepeatable Migrations

## フェーズ1: 手動コピーによる配信

現在は**手動コピー**で配信します。これは初期段階の配信方法です。

### 前提条件

- MrWebDefence-DesignリポジトリとMrWebDefence-Consoleリポジトリが同じディレクトリ階層にあること
- または、両方のリポジトリへのアクセス権限があること

### 配信手順

#### 1. データベース初期化スクリプトの配信

```bash
# MrWebDefence-Designリポジトリのルートディレクトリから実行
# MrWebDefence-Consoleリポジトリに移動
cd ../MrWebDefence-Console

# scripts/databaseディレクトリが存在しない場合は作成
mkdir -p scripts/database

# データベース初期化スクリプトをコピー
cp ../MrWebDefence-Design/scripts/database/init-database.sh scripts/database/

# 実行権限を付与
chmod +x scripts/database/init-database.sh

# 動作確認
./scripts/database/init-database.sh --help
```

#### 2. Flywayマイグレーションファイルの配信（将来実装予定）

Flywayマイグレーションファイルが実装されたら、以下の手順で配信します：

```bash
# MrWebDefence-Consoleリポジトリに移動
cd ../MrWebDefence-Console

# src/main/resources/dbディレクトリが存在しない場合は作成
mkdir -p src/main/resources/db/migration
mkdir -p src/main/resources/db/seed

# マイグレーションファイルをコピー
cp -r ../MrWebDefence-Design/db-resources/migration/* src/main/resources/db/migration/
cp -r ../MrWebDefence-Design/db-resources/seed/* src/main/resources/db/seed/

# ファイルの確認
ls -la src/main/resources/db/migration/
ls -la src/main/resources/db/seed/
```

### 配信後の確認事項

1. **ファイルの存在確認**
   ```bash
   # データベース初期化スクリプト
   ls -la scripts/database/init-database.sh
   
   # Flywayマイグレーションファイル（将来実装予定）
   ls -la src/main/resources/db/migration/
   ls -la src/main/resources/db/seed/
   ```

2. **動作確認**
   ```bash
   # データベース初期化スクリプトのヘルプ表示
   ./scripts/database/init-database.sh --help
   ```

3. **開発環境での動作確認**
   - データベース初期化スクリプトが正常に実行できることを確認
   - データベースが正常に作成されることを確認
   - utf8mb4文字コードが正しく設定されることを確認

### 配信スクリプト（オプション）

手動コピーを支援するスクリプトを作成することもできます：

```bash
#!/bin/bash
# scripts/database/distribute-resources.sh

set -euo pipefail

TARGET_REPO="${1:-../MrWebDefence-Console}"

if [ ! -d "${TARGET_REPO}" ]; then
    echo "エラー: 配信先リポジトリが見つかりません: ${TARGET_REPO}"
    exit 1
fi

echo "DB関連リソースを配信中..."

# データベース初期化スクリプトの配信
mkdir -p "${TARGET_REPO}/scripts/database"
cp scripts/database/init-database.sh "${TARGET_REPO}/scripts/database/"
chmod +x "${TARGET_REPO}/scripts/database/init-database.sh"

# Flywayマイグレーションファイルの配信（将来実装予定）
if [ -d "db-resources/migration" ] && [ "$(ls -A db-resources/migration 2>/dev/null)" ]; then
    mkdir -p "${TARGET_REPO}/src/main/resources/db/migration"
    cp -r db-resources/migration/* "${TARGET_REPO}/src/main/resources/db/migration/"
fi

if [ -d "db-resources/seed" ] && [ "$(ls -A db-resources/seed 2>/dev/null)" ]; then
    mkdir -p "${TARGET_REPO}/src/main/resources/db/seed"
    cp -r db-resources/seed/* "${TARGET_REPO}/src/main/resources/db/seed/"
fi

echo "配信完了: ${TARGET_REPO}"
```

使用方法：
```bash
# デフォルトの配信先（../MrWebDefence-Console）に配信
./scripts/database/distribute-resources.sh

# カスタム配信先を指定
./scripts/database/distribute-resources.sh /path/to/target/repo
```

## フェーズ2以降: 自動配信（将来実装予定）

将来的には、以下の方法で自動配信を実装する予定です：

1. **Gitサブモジュール**: バージョン管理が明確、本番環境での使用
2. **CI/CD自動コピー**: 自動化、複数アプリケーション対応
3. **パッケージ化**: npmパッケージなど、依存関係管理が明確

詳細は `docs/DESIGN.md` の `3.2.10.9 実装計画` を参照してください。

## トラブルシューティング

### 問題: 配信先リポジトリが見つからない

**解決方法**:
- 配信先リポジトリのパスを確認してください
- 相対パスではなく絶対パスを使用することもできます

### 問題: コピーしたファイルに実行権限がない

**解決方法**:
```bash
chmod +x scripts/database/init-database.sh
```

### 問題: マイグレーションファイルが配信先で認識されない

**解決方法**:
- ファイルの配置場所を確認してください（`src/main/resources/db/migration/`、`src/main/resources/db/seed/`）
- Flywayの設定で`locations`が正しく指定されているか確認してください

## 関連ドキュメント

- `docs/DESIGN.md` - データベース設計、Flywayマイグレーション設計、リポジトリ管理方針
- `db-resources/README.md` - DB関連リソースの説明

