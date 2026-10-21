# 検証記録

初版の記録: 2026-10-22 JST、upstream v2.1.2 + 独自コミット1つ。以下の初版の結果と、末尾の更新候補の結果は区別する。現在の固定 SHA は source.lock.json を参照。

## 成功した確認

[GitHub Actions の最終実行](https://github.com/akiyan/opencode-fork-ops/actions/runs/39623793126)も成功。固定した `4c41195577cab90f12e93a5b858270dbdfe0e464` を別の Linux runner へ checkout し、標準チェック、core/server/client の対象テスト、実ブラウザテスト、Web UI 同梱ビルド、成果物のアップロードを確認した。

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

## 初版の本番切替と成果物の保管先

ユーザーの指示により、既存の systemd user service を `2.1.2-akiyan.1` に切り替えた。既存 DB、認証情報、ポート4096、Tailscale Serve の接続先を維持し、セッション一覧と統計 API の応答を確認した。独自 channel の既定 DB は別名になるため、service の `OPENCODE_DB` で既存 DB を明示している。切替前のバイナリ、設定、整合性を確認した DB バックアップは、公開リポジトリ外の保護されたディレクトリに保存した。

初版の GitHub Actions は成果物をアップロードしたが、その運用は廃止した。リリースと保存済み Actions artifact はこの運用リポジトリから削除済み。初版のリリースは [akiyan/opencode](https://github.com/akiyan/opencode/releases/tag/v2.1.2-akiyan.1) へ移し、チェックサムを照合した。今後もビルド成果物は `akiyan/opencode` に置く。

## 中央配置の更新候補（本番反映前）

`2.1.2-akiyan.2` は upstream dev の `870ab9dc5f2eb97c82024f56278f168353a0b068` を親にした独自コミット1つ。タグを基点にすると dev にない release コミットまで ahead に含まれたため、基点を修正した。GitHub compare API でも ahead が1であることを確認した。upstream の更新により behind の数は変化する。

- 入力欄の外側中央に、リポジトリとパス、その下に実行統計と使用量を配置する。新規セッションにも表示する。
- `bun run check`: 全34パッケージ成功。
- app の型チェック成功。
- core の対象テスト39件、server の対象テスト3件、client の VCS 対象テスト1件成功。
- Web UI を同梱した Linux x64 ビルド成功。バイナリの版番号は `2.1.2-akiyan.2`。
- 最終修正後の composer ブラウザテスト2件成功。新規セッション、既存セッション、日本語の指定値、再読み込み、セッション切替、390px幅、未計測・API失敗時を確認した。
- 添付画像と desktop・mobile・footer拡大・draft のキャプチャを同時に目視比較。最初の比較で発見した SVG mask URL の引用符不足を修正し、再キャプチャで3つのアイコンが描画されることを確認した。文字色は二次情報用のテーマトークンに揃えた。
- 本番への切替は、以下の切替記録を追記するまで未実施。

変更前後の production benchmark は各1回成功。firstCorrectObservedMs は 599.2 → 647.0、stableObservedMs は 621.7 → 658.7、wrongDestinationSamples は両方0。各1回のため性能の改善・悪化は断定しない。変更後測定は中央配置実装後、アイコンの描画と文字色の最終修正前に行った。
