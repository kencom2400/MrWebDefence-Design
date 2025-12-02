# OpenAppSec 仕様書

## 1. 概要

### 1.1 OpenAppSecとは
[OpenAppSec](https://github.com/openappsec/openappsec)は、機械学習を基盤としたWebアプリケーションおよびAPIに対する脅威を先制的に自動防御するセキュリティエンジンです。OWASP Top 10やゼロデイ攻撃に対する保護を提供します。

### 1.2 基本アーキテクチャ
OpenAppSecは以下の4つの主要リポジトリで構成されています：

1. **openappsec/openappsec** - メインコードとロジック（C++で開発）
2. **openappsec/attachment** - HTTPデータを提供するプロセス（NGINX等）とOpenAppSecエージェントのセキュリティロジックを接続（Cで開発）
3. **openappsec/smartsync** - 複数のエージェントインスタンスからの学習データを相関させ、各アセットに統一された学習モデルを提供（Golangで開発）
4. **openappsec/smartsync-shared-files** - smartsyncサービスが学習データを保存するための物理ストレージへのインターフェース（Golangで開発）

### 1.3 デプロイメント環境
- **Linux**: NGINX、Kong、APISIX
- **Docker**: コンテナベースのデプロイメント
- **Kubernetes**: NGINX Ingress、Kong、APISIX、Istio
- **Envoy**: プロキシとして使用

## 2. 機械学習モデル

### 2.1 二段階の検知プロセス

OpenAppSecは各HTTPリクエストに対して2段階の検知プロセスを実行します：

#### フェーズ1: 教師ありモデルによる検知
- HTTPリクエストから直接抽出、またはペイロードの異なる部分からデコードされた複数の変数を機械学習エンジンに投入
- 変数には以下が含まれる：
  - 攻撃インジケーター
  - IPアドレス
  - User-Agent
  - フィンガープリント
  - その他多くの考慮事項
- 教師ありモデルは、これらの変数を使用してリクエストを世界中で見つかった多くの一般的な攻撃パターンと比較

#### フェーズ2: 教師なしモデルによる最終判定
- リクエストが有効で正当と識別された場合：許可され、アプリケーションに転送
- リクエストが疑わしい、または高リスクと判断された場合：
  - 環境固有で訓練された教師なしモデルによって評価
  - URLや関連ユーザーなどの情報を使用して最終的な信頼度スコアを作成
  - リクエストを許可するかブロックするかを決定

### 2.2 機械学習モデルの種類

#### 基本モデル（Basic Model）
- このリポジトリに含まれる
- Apache 2.0ライセンス
- Monitor-Only環境とテスト環境での使用を推奨

#### 高度モデル（Advanced Model）
- より正確で、本番環境での使用を推奨
- [open-appsecポータル](https://my.openappsec.io)からダウンロード可能
- 定期的に更新され、更新時にはメール通知
- Machine Learning Modelライセンス

### 2.3 教師なしモデル
- 保護対象環境でリアルタイムに構築される
- 環境固有のトラフィックパターンを使用
- 環境ごとに最適化された検知を提供

## 3. 主要機能

### 3.1 WAF（Web Application Firewall）機能

#### 3.1.1 Web攻撃検知
- **OWASP Top 10攻撃の検知**：
  - SQLインジェクション
  - XSS（Cross-Site Scripting）
  - コマンドインジェクション
  - パストラバーサル
  - その他の一般的なWeb攻撃
- **設定可能なパラメータ**：
  - `max-body-size-kb`: 最大ボディサイズ（デフォルト: 10000KB = 10MB）
  - `max-header-size-bytes`: 最大ヘッダーサイズ（デフォルト: 102400バイト）
  - `max-object-depth`: 最大オブジェクト深度（デフォルト: 40）
  - `max-url-size-bytes`: 最大URLサイズ（デフォルト: 32768バイト）
  - `minimum-confidence`: 最小信頼度レベル（critical, high, medium, low）
- **保護機能**：
  - CSRF保護（設定可能）
  - エラー開示保護（設定可能）
  - 無効なHTTPメソッドの検知
  - オープンリダイレクト保護（設定可能）

#### 3.1.2 モード設定
- **prevent-learn**: ブロックし、学習も行う（推奨）
- **detect-learn**: 検知のみ（ログ記録）、学習も行う
- **prevent**: ブロックのみ（学習なし）
- **detect**: 検知のみ（ログ記録、学習なし）
- **inactive**: 無効化

### 3.2 WAAP（Web Application API Protection）機能

#### 3.2.1 OpenAPIスキーマ検証
- OpenAPI/Swaggerスキーマに基づくAPIリクエストの検証
- ConfigMapからのスキーマ読み込み
- スキーマ違反の検知とブロック
- オーバーライドモードの設定可能

#### 3.2.2 APIセキュリティ
- REST API、GraphQL等のAPIエンドポイント保護
- JSON/XMLペイロードの解析
- APIレート制限（後述）
- API認証・認可の検証

### 3.3 RateLimit機能

#### 3.3.1 実装詳細
- **実装言語**: C++
- **ストレージ**: Redis（分散環境対応）
- **アルゴリズム**: スライディングウィンドウ、トークンバケット等
- **URIマッチング**: 
  - 完全一致
  - プレフィックス一致
  - ワイルドカード一致（`*`使用可能）

#### 3.3.2 設定可能な項目
- IPアドレス単位のレート制限
- URI/エンドポイント単位のレート制限
- 時間ウィンドウの設定
- レート制限超過時のアクション（ブロック、ログ記録等）

#### 3.3.3 分散環境対応
- Redisを使用した複数インスタンス間でのレート制限の共有
- スケールアウト環境での一貫したレート制限

### 3.4 GeoIP Base Protection機能

#### 3.4.1 実装詳細
- **コンポーネント**: `http_geo_filter`
- **データベース**: MaxMindDB
- **IP検証**: ソースIP、X-Forwarded-Forヘッダーの両方をサポート

#### 3.4.2 機能
- **IP/CIDRブロック**：
  - ホワイトリスト/ブラックリストの設定
  - 複数IP/CIDRの一括登録
  - 信頼できるIPの除外設定
- **国単位のアクセス制御**：
  - 国コード（ISO 3166-1 alpha-2）ベースの許可/拒否
  - 複数国の一括設定
  - デフォルトアクションの設定
- **X-Forwarded-For対応**：
  - プロキシ経由のリクエストに対応
  - 信頼できるプロキシIPの設定可能

#### 3.4.3 設定
- デフォルトアクション（許可/拒否/無関係）の設定
- ソースIP無視オプション（SaaSプロファイル設定）

### 3.5 Anti-Bot機能

#### 3.5.1 機能
- ボット検知（User-Agent解析、行動パターン分析）
- 注入URIの設定（JavaScriptチャレンジ等）
- 検証済みURIの設定
- オーバーライドモードの設定

#### 3.5.2 設定
- `injected-URIs`: ボット検知用のJavaScriptを注入するURI
- `validated-URIs`: 検証済みURIのリスト
- `override-mode`: モード設定（prevent-learn, detect-learn等）

### 3.6 IPS（Intrusion Prevention System）機能

#### 3.6.1 Snortシグニチャ
- Snortベースのシグニチャ検知
- ConfigMapからのシグニチャ読み込み
- カスタムシグニチャの追加可能
- オーバーライドモードの設定

#### 3.6.2 ネットワーク層保護
- ネットワーク層での攻撃検知
- DDoS攻撃の検知・緩和
- 異常トラフィックパターンの検知

### 3.7 Layer 7 Access Control機能

#### 3.7.1 機能
- レイヤー7でのアクセス制御
- IPレピュテーション機能（CrowdSec統合）
- 外部ベンダー推奨アクションの適用
- 非同期のインテリジェンスクエリ

#### 3.7.2 CrowdSec統合
- CrowdSecデータクラウドとの統合
- IPアドレスのレピュテーション評価
- 悪意のあるIPの自動ブロック

## 4. 設定管理

### 4.1 設定方法

OpenAppSecは以下の3つの方法で管理できます：

1. **宣言的設定ファイル**（YAML形式）
2. **Kubernetes Helm Chartsとアノテーション**
3. **SaaS Web管理UI**

### 4.2 ポリシー設定構造

#### 4.2.1 ポリシー（Policy）
```yaml
policies:
  default:
    triggers:
    - appsec-default-log-trigger
    mode: prevent-learn
    practices:
    - webapp-default-practice
    custom-response: appsec-default-web-user-response
  specific-rules: []
```

#### 4.2.2 プラクティス（Practice）
```yaml
practices:
  - name: webapp-default-practice
    openapi-schema-validation:
      configmap: []
      override-mode: prevent-learn
    snort-signatures:
      configmap: []
      override-mode: prevent-learn
    web-attacks:
      max-body-size-kb: 1000000
      max-header-size-bytes: 102400
      max-object-depth: 40
      max-url-size-bytes: 32768
      minimum-confidence: critical
      override-mode: prevent-learn
      protections:
        csrf-protection: inactive
        error-disclosure: inactive
        non-valid-http-methods: false
        open-redirect: inactive
    anti-bot:
      injected-URIs: []
      validated-URIs: []
      override-mode: prevent-learn
```

#### 4.2.3 ログトリガー（Log Trigger）
```yaml
log-triggers:
  - name: appsec-default-log-trigger
    access-control-logging:
      allow-events: false
      drop-events: true
    additional-suspicious-events-logging:
      enabled: true
      minimum-severity: high
      response-body: false
    appsec-logging:
      all-web-requests: false
      detect-events: true
      prevent-events: true
    extended-logging:
      http-headers: false
      request-body: false
      url-path: false
      url-query: false
    log-destination:
      cloud: true
      stdout:
        format: json
```

#### 4.2.4 カスタムレスポンス
```yaml
custom-responses:
  - name: appsec-default-web-user-response
    mode: response-code-only
    http-response-code: 403
```

### 4.3 Kubernetes CRD

OpenAppSecはKubernetes Custom Resource Definition（CRD）を提供：

- **Policy CRD**: `policies.openappsec.io`
- **Practice CRD**: `practices.openappsec.io`
- **LogTrigger CRD**: `logtriggers.openappsec.io`

## 5. ログ機能

### 5.1 ログタイプ

#### 5.1.1 アクセス制御ログ
- 許可イベントのログ記録（設定可能）
- ドロップイベントのログ記録（設定可能）

#### 5.1.2 AppSecログ
- すべてのWebリクエストのログ記録（設定可能）
- 検知イベントのログ記録
- 防止イベントのログ記録

#### 5.1.3 追加の疑わしいイベントログ
- 有効化/無効化の設定
- 最小重要度レベルの設定（high, medium, low等）
- レスポンスボディのログ記録（設定可能）

#### 5.1.4 拡張ログ
- HTTPヘッダーのログ記録
- リクエストボディのログ記録
- URLパスのログ記録
- URLクエリのログ記録

### 5.2 ログ出力先

- **Cloud**: クラウド管理UIへの送信
- **stdout**: 標準出力（JSON形式、テキスト形式）
- **ファイル**: ローカルファイルへの出力

### 5.3 ログ形式

- **JSON形式**: 構造化ログ（推奨）
- **テキスト形式**: 人間が読みやすい形式

## 6. 監視・メトリクス

### 6.1 Prometheus統合

- Prometheus形式のメトリクスを提供
- カスタムメトリクスの追加可能
- ヘルスチェックエンドポイント

### 6.2 メトリクス種類

- リクエスト数
- ブロック数
- 検知イベント数
- レート制限超過数
- エラー数
- パフォーマンスメトリクス

## 7. デプロイメント

### 7.1 Linux環境

#### 7.1.1 インストーラーを使用
```bash
wget https://downloads.openappsec.io/open-appsec-install && chmod +x open-appsec-install
./open-appsec-install --auto
```

#### 7.1.2 手動インストール
```bash
install-cp-nano-agent.sh --install --hybrid_mode
install-cp-nano-service-http-transaction-handler.sh --install
install-cp-nano-attachment-registration-manager.sh --install
```

### 7.2 Docker環境

```bash
docker run -d --name=agent-container --ipc=host \
  -v=/path/to/conf:/etc/cp/conf \
  -v=/path/to/data:/etc/cp/data \
  -v=/path/to/logs:/var/log/nano_agent \
  -it <agent-image> /cp-nano-agent [--token <token> | --standalone]
```

**重要なパラメータ**：
- `--ipc=host`: NGINXサーバーとの共有メモリアクセスのために必須
- `--token`: 管理ポータルからのトークン（オプション）
- `--standalone`: ローカル管理モード

### 7.3 Kubernetes環境

- Helm Chartsを使用したデプロイメント
- NGINX Ingress Controllerとの統合
- Kong、APISIX、Istioとの統合

## 8. 依存関係

### 8.1 外部ライブラリ

- **Boost**: C++ライブラリ
- **OpenSSL**: 暗号化ライブラリ
- **PCRE2**: 正規表現ライブラリ
- **libxml2**: XML解析ライブラリ
- **GTest/GMock**: テストフレームワーク
- **cURL**: HTTPクライアント
- **Redis/Hiredis**: キャッシュ・レート制限用
- **MaxmindDB**: GeoIPデータベース
- **yq**: YAML処理ツール

### 8.2 ビルド要件

- CMake
- C++コンパイラ（C++17以上）
- Make

## 9. セキュリティ

### 9.1 セキュリティ監査

- 2022年9月-10月に独立した第三者によるセキュリティ監査を実施
- [監査レポート](https://github.com/openappsec/openappsec/blob/main/LEXFO-CHP20221014-Report-Code_audit-OPEN-APPSEC-v1.2.pdf)が公開されている

### 9.2 脆弱性報告

- セキュリティ脆弱性は `security-alert@openappsec.io` に報告
- 24時間以内に確認メールを送信
- 問題の特定後、追加のメールを送信

## 10. ライセンス

- **OpenAppSec本体**: Apache 2.0ライセンス
- **基本MLモデル**: Apache 2.0ライセンス
- **高度MLモデル**: Machine Learning Modelライセンス（ダウンロード時に提供）

## 11. 主要コンポーネント

### 11.1 コアコンポーネント

- **core/**: エージェントコアユーティリティ
- **components/**: セキュリティアプリケーションコンポーネント
- **nodes/**: サービスノード
- **attachments/**: NGINX等との接続

### 11.2 セキュリティアプリケーション

- **waap/**: WAAP機能の実装
- **rate_limit/**: レート制限機能
- **http_geo_filter/**: GeoIPフィルタリング
- **ips/**: IPS機能
- **layer_7_access_control/**: レイヤー7アクセス制御
- **anti-bot/**: ボット対策（WAAP内に実装）
- **orchestration/**: オーケストレーション機能
- **prometheus/**: Prometheusメトリクス

### 11.3 ユーティリティ

- **generic_rulebase/**: 汎用ルールベース
- **geo_location/**: 地理的位置情報
- **http_transaction_data/**: HTTPトランザクションデータ
- **ip_utilities/**: IPユーティリティ

## 12. 設定の拡張性

### 12.1 カスタムシグニチャ

- Snortシグニチャの追加
- ConfigMapからの読み込み
- カスタムルールの定義

### 12.2 例外設定

- 特定のURI、IP、ユーザーエージェント等に対する例外設定
- 誤検知の回避

### 12.3 信頼できるソース

- 信頼できるIPアドレスの設定
- 信頼できるソースからのリクエストの優先処理

### 12.4 ソース識別子

- カスタムソース識別子の設定
- ユーザー、セッション等の識別

## 13. パフォーマンス

### 13.1 最適化

- C++による高性能実装
- 共有メモリを使用したプロセス間通信
- 非同期処理によるレイテンシの最小化

### 13.2 スケーラビリティ

- 水平スケーリング対応
- 分散レート制限（Redis使用）
- 複数インスタンス間での学習データの同期（smartsync）

## 14. 参考資料

- **公式サイト**: https://openappsec.io
- **公式ドキュメント**: https://docs.openappsec.io/
- **ビデオチュートリアル**: https://www.openappsec.io/tutorials
- **GitHubリポジトリ**: https://github.com/openappsec/openappsec
- **Playground**: https://www.openappsec.io/playground

## 15. まとめ

OpenAppSecは、機械学習を基盤とした包括的なWebアプリケーションおよびAPI保護ソリューションです。以下の特徴を持ちます：

1. **機械学習ベースの検知**: 教師ありモデルと教師なしモデルの組み合わせ
2. **包括的な保護**: WAF、WAAP、RateLimit、GeoIP、Anti-Bot、IPS機能
3. **柔軟なデプロイメント**: Linux、Docker、Kubernetes対応
4. **多様な管理方法**: 宣言的設定、Kubernetes CRD、Web UI
5. **拡張性**: カスタムシグニチャ、例外設定、信頼できるソース設定
6. **監視・ログ**: Prometheus統合、構造化ログ、詳細なログ設定
7. **オープンソース**: Apache 2.0ライセンス（基本モデル含む）

MrWebDefenceプロジェクトでは、このOpenAppSecをベースとして、管理画面、ログ管理サーバ、シグニチャ収集機能を追加することで、より包括的なWAFサービスを構築することができます。




