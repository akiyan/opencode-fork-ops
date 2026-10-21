# 検証記録

初版: 2026-10-22 JST、upstream v2.1.2 + 独自コミット1つ。正確な SHA は source.lock.json を参照。

## 成功した確認

- ルートの `bun run check`: lint と全34パッケージの型チェック成功。既存の lint warning は残る。
- `packages/core`: `bun test test/session-stats.test.ts test/vcs.test.ts`、39件成功。
- `packages/server`: `bun test test/session-update.test.ts`、3件成功。
- `packages/app`: composer の追加 Playwright ケース成功。日本語の指定値、入力欄の下の配置、再読み込み、セッション切替、未計測速度、入力0、390px幅、API失敗時のフォールバックを検証。
- 全履歴集計: 63件の assistant と1件の user を含むセッションで確認。子セッションは加算しない。
- Git remote: 認証情報・クエリを持つ HTTPS、SCP 形式、ローカル remote の扱いを実際の Git リポジトリで確認。
- `packages/client`: VCS 更新の既存テストを拡張し、起動直後とブランチ切替後の repository 情報の取得・保持を確認。変更前には追加アサーションが失敗し、修正後には成功。
- CLI の Web UI 同梱ビルド、Linux x64 バイナリの版番号確認。
- 生成したバイナリを隔離した XDG データ領域とポート4496で実行し、同梱HTML、認証、セッション作成、統計API、実際の Git リポジトリ名とブランチを確認。試験用プロセスは確認後に終了。
- デスクトップとスマートフォン幅のスクリーンショットを目視確認。画像は合成したテスト用セッション。

## 性能の参考値

既存の production benchmark `entry: cold session from Home` を変更前後に各1回実行し、両方成功。

| 指標 | 変更前 | 変更後 |
| --- | ---: | ---: |
| firstCorrectObservedMs | 601.5 | 632.9 |
| stableObservedMs | 621.0 | 655.8 |
| wrongDestinationSamples | 0 | 0 |

1回ずつの観測で、静的ファイルのサーバーも異なるため、性能の改善・悪化を断定できる比較ではない。セッション全体をブラウザに取得せず、SQLで集計した小さい応答のみを追加する設計。

## upstream 由来の制約

`packages/app` の追加コマンド `bun run typecheck:e2e` は9件の既存エラーで失敗する。独自変更を含まない v2.1.2 を別 worktree でインストールし、同じ9件を再現した。今回の変更による追加エラーはない。ルートの標準 `bun run check` と、今回の実ブラウザテストは成功。

既存エラーの位置:

- `e2e/performance/terminals/probe.ts:61`
- `e2e/performance/timeline/session-timeline-stream-probe.ts:148`
- `e2e/regression/composer.spec.ts:21`
- `e2e/regression/review.spec.ts:396`
- `e2e/regression/timeline-stream.spec.ts:1413,1445,1508,1822,1825`

追加で `packages/client` の `bun test --conditions=browser test/solid-data.test.ts` を実行すると29件成功・1件失敗となる。失敗する `projects background user shell metadata from durable shell data` は未変更の v2.1.2 でも同じく失敗する。今回拡張した VCS ケースを指定した実行は成功。

ローカルの Ubuntu 26.04 は使用中の Playwright のサポート対象外のため、ブラウザのインストール・実行時だけ `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64` を使用した。

## 本番への影響

既存の opencode/opencode2 のバイナリ、サービス、設定、実セッション DB は切り替えていない。独自版の起動確認は別ポートと隔離データで行う。自動更新は運用スクリプトで無効にする。
