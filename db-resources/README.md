# DB関連リソース

このディレクトリには、MrWebDefenceプロジェクトのDB関連リソースが配置されます。

## ディレクトリ構成

```
db-resources/
├── migration/          # Flywayマイグレーションファイル（Versioned Migrations）
├── seed/              # Flywayマイグレーションファイル（Repeatable Migrations）
└── README.md          # このファイル
```

## 配置場所の説明

### migration/

FlywayのVersioned Migrations（バージョン付きマイグレーション）を配置します。

**命名規則**: `V{version}__{description}.sql`

**例**:
- `V1__create_users_table.sql`
- `V2__create_roles_table.sql`
- `V3__create_user_roles_table.sql`

詳細は `docs/DESIGN.md` の `3.2.8 Flywayマイグレーション設計` を参照してください。

### seed/

FlywayのRepeatable Migrations（繰り返し可能なマイグレーション）を配置します。
初期データ投入用のSQLファイルを配置します。

**命名規則**: `R__{description}.sql`

**例**:
- `R__insert_initial_roles.sql`
- `R__insert_initial_password_policy.sql`
- `R__insert_initial_batch_schedules.sql`

詳細は `docs/DESIGN.md` の `3.2.8.7 初期データ投入（Repeatable Migrations）` を参照してください。

## 配信先リポジトリ

これらのリソースは、以下のリポジトリに配信されます：

- **MrWebDefence-Console**: 管理画面（フロントエンド・バックエンド）

配信先では、以下のパスに配置されます：

```
src/main/resources/db/
├── migration/      # migration/ の内容がコピーされる
└── seed/           # seed/ の内容がコピーされる
```

## 配信方法

現在は**手動コピー**で配信します。将来的にはGitサブモジュールやCI/CD自動配信を検討します。

詳細な配信手順は `docs/DB_RESOURCES_DISTRIBUTION.md` を参照してください。

## 注意事項

- マイグレーションファイルの命名規則に従ってください
- ファイルの文字コードはUTF-8（BOMなし）を使用してください
- マイグレーションファイルの変更は、設計ドキュメント（`docs/DESIGN.md`）と整合性を保つようにしてください

