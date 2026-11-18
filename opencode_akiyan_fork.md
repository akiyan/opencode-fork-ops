# OpenCode akiyan fork 変更情報

[anomalyco/opencode の dev](https://github.com/anomalyco/opencode/tree/dev) の `fe3552441192ccbea91d117668e7f3a9eb097baf`（2.2.7 系）を基礎にしています。その上に以下の独自差分を1コミットで載せています。

本体は [akiyan/opencode の akiyan ブランチ](https://github.com/akiyan/opencode/tree/akiyan)。コミットメッセージはこのページの URL のみとし、変更の説明と運用文書はこのリポジトリで管理します。採用した親コミットと独自コミットの SHA は [config/source.lock.json](config/source.lock.json) に記録します。

## 独自変更

### 1. 入力欄の下のリポジトリ情報とセッション統計

`packages/app/src/session/composer/stats.tsx`、`stats.css`、`packages/core/src/plugin/vcs/git.ts`

- 新規・既存セッションの入力欄の下に、リポジトリ名・ブランチ・作業パスと統計を中央揃えの2段で表示する
- 統計はターン数、ステップ数、生成速度、総トークン数、キャッシュヒット率を表示する。日本語のラベルは「ターン」「ステップ」「キャッシュヒット」とする
- 認証情報やクエリを含む Git remote からはリポジトリのパスだけを取り出す。ローカル remote はリポジトリ名として扱わない
- 新規セッションでは回数と総トークンを0、未計測の生成速度とキャッシュヒット率をダッシュで表示する
- 統計APIの失敗時も入力を継続でき、狭い画面では折り返して表示する

### 2. セッション全体の回数と生成速度

`packages/core/src/session/stats.ts`、`packages/schema/src/session-stats.ts`、`packages/server/src/handlers/session.ts`

- セッション全体の保存済み履歴からユーザー入力数と論理的な LLM 呼び出し数を集計する。引き継いだ履歴は含め、待機中の入力と子セッションは含めない
- 出力・推論トークン数を、計測可能な呼び出しの生成時間で割って速度を算出する。最初のトークンまでの待ち時間とツール実行時間は除く
- 本家の `firstToken` を優先し、旧forkの `firstOutput` と保存済みの最初の部品の時刻も読めるようにする。再試行・失敗・計測情報のない呼び出しは速度の対象外とする
- 大きい会話履歴をブラウザへ転送せず、既存のSQLiteから小さい集計結果だけを返す。公開clientとOpenAPIは元の定義から生成する

### 3. Sign in with ChatGPT の戻り先URL貼り付け

`packages/core/src/oauth/redirect.ts`

- 自動認証とURL貼り付けは、本家の認証方法・GUI・TUI・`auth login` の実装を使う。「Sign in with ChatGPT」で、ブラウザの最後の戻り先URLを貼り付けて連携を完了できる
- 独自の追加は入力形式の拡張。URL全体に加え、`?` 以降のクエリ、先頭に `?` が付いたクエリ、`http://` が欠けたURLを受け付ける
- 入力されたURLを通信先として使わない。待機中の `state` を照合し、元の `redirect_uri`、PKCE、IDトークン検証を保つ
- 間違ったURLやコードの欠けた入力は、その貼り付けだけを拒否し、認証は待機を続ける。同じ試行で入力を訂正できる

### 4. さくらのAIエンジンのプロバイダー

`packages/core/src/plugin/provider/sakura.ts`、`packages/core/src/plugin/provider.ts`

- 本家の同梱カタログ（models.dev）に無いプロバイダーとして、さくらのAIエンジンを `sakura-ai-engine` の名前で追加する。本家の同梱カタログを読むプラグインと同じ形で、プロバイダー・モデル・環境変数の受け口を登録する
- 通信先は `https://api.ai.sakura.ad.jp/v1` のOpenAI互換 chat completions。アカウントトークン（`<UUID>:<シークレット>` の形のまま）をBearerトークンとして送る
- 認証は設定画面からのアカウントトークン保存、または環境変数 `SAKURA_AI_ENGINE_API_KEY`。トークンが用意されるまでプロバイダーを一覧に出さない
- 出力上限は `max_tokens` で送る。このエンドポイントは `max_completion_tokens` を無視するため、プロバイダーの互換設定で固定する
- 載せるのはtool callに対応した6モデル。エージェントは毎回ツール定義を送るため、非対応モデルへ送ると400になる。llm-jp、Phi-4-mini、Qwen3-0.6B、Qwen3-VLは載せない
- 文脈長・出力上限（いずれも32,000）・画像入力の可否はマニュアルの記載に合わせる。料金表がマニュアルに無いため、コストは0として扱い価格を捏造しない
- 推論の量はモデルごとに受け付ける値が違うため、実測した値だけを選択肢にする。`gpt-oss-120b` は `none` で400、Kimiは `none` を送ると思考が本文に混ざり、GLMは `none` でも思考が止まらない。DeepSeekは `medium` と `minimal` で400になる

## 検証と運用

- [検証記録](docs/validation.md)、[更新・切替・ロールバック](docs/operations.md)、[統計値の定義](docs/metrics.md)
- Coreの認証・統計・履歴投影・VCS・DB移行、ServerとClientの対象テスト、Chromiumによる統計表示と貼り付けフォームの回帰を確認する
- OpenAIへの通信を置き換えたテストと、実アカウントでの認証は区別する。今回、実アカウントでの認証は実施していない
- さくらのAIエンジンは、単体テストに加えて実際のAPIで確認する。確認には利用者のアカウントトークンを使い、トークン自体と実応答はリポジトリへ保存しない
- Web UI同梱Linux x64バイナリを隔離DBで検証する。稼働中サービスへの切替、公開リリースの作成、pushは別の作業として扱う
