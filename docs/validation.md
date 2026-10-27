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

## 中央配置の更新版

`2.1.2-akiyan.2` は upstream dev の `870ab9dc5f2eb97c82024f56278f168353a0b068` を親にした独自コミット1つ。タグを基点にすると dev にない release コミットまで ahead に含まれたため、基点を修正した。GitHub compare API でも ahead が1であることを確認した。upstream の更新により behind の数は変化する。

- 入力欄の外側中央に、リポジトリとパス、その下に実行統計と使用量を配置する。新規セッションにも表示する。
- `bun run check`: 全34パッケージ成功。
- app の型チェック成功。
- core の対象テスト39件、server の対象テスト3件、client の VCS 対象テスト1件成功。
- Web UI を同梱した Linux x64 ビルド成功。バイナリの版番号は `2.1.2-akiyan.2`。
- 最終修正後の composer ブラウザテスト2件成功。新規セッション、既存セッション、日本語の指定値、再読み込み、セッション切替、390px幅、未計測・API失敗時を確認した。
- 添付画像と desktop・mobile・footer拡大・draft のキャプチャを同時に目視比較。最初の比較で発見した SVG mask URL の引用符不足を修正し、再キャプチャで3つのアイコンが描画されることを確認した。文字色は二次情報用のテーマトークンに揃えた。
- 最終バイナリの隔離起動でも、同梱 UI・認証・セッション作成・統計 API・Git 情報を確認した。

変更前後の production benchmark は各1回成功。firstCorrectObservedMs は 599.2 → 647.0、stableObservedMs は 621.7 → 658.7、wrongDestinationSamples は両方0。各1回のため性能の改善・悪化は断定しない。変更後測定は中央配置実装後、アイコンの描画と文字色の最終修正前に行った。

## 中央配置版の本番切替（2026-10-22 06:47 JST）

`2.1.2-akiyan.2` / `e5db476fcd319194b93aba0077f40395054e65e3` に切り替えた。systemd user service は active/running、切替後の自動再起動回数0。既存の全1セッション、DB、認証情報、URLとポートを保持し、同梱 Web UI のエントリーファイルが新版に変わったことを確認した。停止中に整合性確認済みの DB バックアップと旧バイナリ・設定を公開リポジトリ外へ保存した。

ユーザー指定の Tailscale HTTPS URL を新しい Chromium コンテキストで開き、既存の認証情報でログインして実セッションを表示した。入力欄下の footer、3つのアイコン、統計表示、編集可能な入力欄を確認し、page error は0。実セッションのキャプチャはローカルだけに保存し、公開していない。利用中の旧タブ／PWA のキャッシュ状態は別なので、全ウィンドウを閉じて開き直す必要がある場合がある。

[リリース v2.1.2-akiyan.2](https://github.com/akiyan/opencode/releases/tag/v2.1.2-akiyan.2) のアーカイブ digest はローカルと一致: `f435dc03c9b099b5de4890e6fe6f28ca3daf0d7153d423c8383e8a5e8ac2b0cb`。運用リポジトリの releases と保存済み Actions artifacts は、どちらも0であることを確認した。

[中央配置版の GitHub Actions](https://github.com/akiyan/opencode-fork-ops/actions/runs/39681327919) も成功した。固定ソースを別 runner で標準チェック、対象テスト、composer ブラウザテスト2件、Web UI 同梱バイナリのビルドまで確認した。成果物のアップロードは行っていない。

## tok/s の修正と Web チャンネル（2026-10-22 07:06 JST）

`2.1.2-akiyan.3` / `e72081dae3f51edc6c5fd6581cf734630c94e88b` に切り替えた。初版の速度集計は event テーブルの開始イベントを参照したが、通常運用では `Bus.persist` が既定で false のためイベントログが空で、速度が常に null になっていた。全く同じ条件のテストを初版で確認できていなかった。

修正版は投影済みメッセージを使う。今後の text/reasoning/tool-input の開始時刻を optional な `time.firstOutput` に保存し、再試行でリセットする。既存履歴では最初の reasoning/tool の保存時刻を使い、復元できない text-only の旧履歴は未計測として残す。イベントログが空でも速度が計算できる回帰テストを追加した。

Web ビルド設定は未認識のチャンネル名を dev にしていた。独自チャンネル akiyan の Web UI は prod としてビルドし、CLI とサービスのチャンネル名は引き続き akiyan とする。左下の TPS/TTFT/TTFA/E2E は本家の debug extension の統計バー。開発サーバーで実行されていたわけではない。prod では左上にデバッグ切替アイコンを出さない。

- 標準 `bun run check`: 全34パッケージ成功。
- core の stats/projector/VCS: 56件成功。server の対象テスト: 3件成功。
- client の再生成、Web UI 同梱 Linux x64 ビルド、隔離環境での認証付き API・セッション作成・統計 API の確認成功。
- 実行中セッションの終了を待ち、旧バイナリ・設定・DB を非公開領域へバックアップして切替。全2セッション、既存 DB・認証・接続先を保持した。
- 本番統計 API の既存2セッションで数値の速度を確認。Tailscale HTTPS URL の新規 Chromium コンテキストでも数値の tok/s、編集可能な入力欄、開発チャンネルのバッジがないことを確認した。page error 0、systemd active/running、NRestarts 0。
- アーカイブ SHA-256: `f2075dea579a1def9edfe7eea1a1f735aa170329a4eff4f74990178750f1c85f`。

本家 debug extension の TPS は直近の応答に対する output の速度で、今回のセッション全体・reasoning 込みの加重平均とは一致しない。

## カスタムモデルの表示（2.1.2-akiyan.4）

DGX は設定とモデル API に存在し enabled/active でも、発売日未設定のモデルが Web UI の候補に表示されなかった。catalog の `time.released=0` が `1970-01-01` に変換され、モデル選択の「古いモデルを既定で隠す」規則に入っていた。

`normalizeProviderList` で未設定の日付を空文字のまま扱い、既存の「発売日不明のモデルは表示する」規則を適用する。実在する発売日を捏造せず、利用者が明示的に非表示にした設定は維持する。

- catalog 変換の既存テストに unknown date の回帰アサーションを追加。修正前は `1970-01-01` で失敗し、修正後は対象9件成功。既知の日付の変換と deprecated model の除外も維持した。
- 標準 `bun run check`: 全34パッケージ成功。
- Web UI 同梱ビルドと隔離環境での native smoke 成功。2026-10-22 16:47 JST、実行中セッションがないことを確認し、旧バイナリ・設定・整合性を確認した DB を非公開領域へ保存して切替。全2セッションと既存の認証・接続先を保持した。
- Tailscale HTTPS URL を新規 Chromium コンテキストで開き、実セッションのモデル選択メニューに DGX / GLM-5.3-Flash-EXL3 が自動表示されることを確認。前版では同じメニューに OpenCode の無料モデルだけが表示されていた。
- [リリース v2.1.2-akiyan.4](https://github.com/akiyan/opencode/releases/tag/v2.1.2-akiyan.4) の SHA-256 はローカルと一致: `d34966ae44eb5d31c2eac8cf2fc311c4aebc2a68327c280602144305194ea15c`。
- 設定済みモデルの通信先はユーザーのローカル設定で管理する。接続先や実セッションの画面は運用リポジトリへ追加しない。

## upstream dev 追従（2026-10-23）

取得時点の本家 dev `7a62a466959bb49838b666bf5ba6222fb14b55cd`（v2.1.3 系）を採用。旧基点 `870ab9dc5f2eb97c82024f56278f168353a0b068` から76コミットを取り込み、独自変更を1コミット `68aae1c6d2504ae1826d3957500b89aa9c870954` に載せ直した。競合はなかった。統計 API・投影済み firstOutput・中央配置・カスタムモデルの未知発売日・akiyan の Web prod チャンネル設定を維持した。

- Bun を本家の指定に合わせて1.4.4へ更新。旧1.4.2の実行ファイルはローカルに保持した。
- 本家で追加された OpenAPI 整合性チェックに対応し、独自 API の仕様書も再生成。client 再生成後の差分なし、protocol の `check:generated` 成功。
- 標準 `bun run check`: 全34パッケージ成功。公式 TypeScript 7.1 による `bun run typecheck:tsc` も全34パッケージ成功。
- core の stats/projector/VCS/V1 migration: 92件成功。server 対象3件、client VCS対象1件、app catalog対象9件成功。
- production build の composer ブラウザテスト2件成功。既存・新規セッション、指定値、狭い幅、再読込、切替、APIエラーを確認。
- production benchmark（各1回）: firstCorrectObservedMs は 681.4 → 403.4、stableObservedMs は 693.5 → 427.4、wrongDestinationSamples は両方0。測定回数が少なく、静的サーバーも異なるため改善率は主張しない。
- DB の差分は V1 import 処理と型定義の更新で、テーブル構造を変える migration はない。隔離した新規 DB と実 DB の online backup コピーの両方で、候補バイナリを起動して確認した。コピーの実行 claim と待機入力だけを無効にし、実処理を再開しない条件で2セッション・数値速度・SQLite quick_check を確認した。
- 2026-10-23 09:09 JST に本番切替。実行中セッションがないことを再確認し、旧バイナリ・設定・DB と更新前後の source.lock を公開リポジトリ外へ保存した。全2セッション、認証、URL/ポートを保持。プロバイダー設定ファイルの切替前後のハッシュも一致した。
- Tailscale HTTPS の実画面で数値の tok/s、編集可能な入力欄、prod のバッジ状態を確認。page error 0。DGX の GLM/DeepSeek がモデル選択に表示されることも確認した。systemd は active/running、NRestarts 0。
- [リリース v2.1.3-akiyan.1](https://github.com/akiyan/opencode/releases/tag/v2.1.3-akiyan.1) のアーカイブ digest はローカルと一致: `8635516fd965824432a03b3d6799e6bd10635a6789014e646dfbdce654e58a98`。
- 公開後の compare API は ahead 1 / behind 1。検証中に進んだ dev の追加1コミットは今回の採用点には含めていない。運用リポジトリの releases と保存済み Actions artifacts はどちらも0。


## upstream dev 追従（2026-10-27）

取得時点の本家 dev `6aedf36ca307f97919f39d655de13b3ad5ccd24f`（v2.1.4 系）を採用。前回の基点から693コミットを取り込み、独自変更を1コミット `c0bab13272c9412fe962eb030fda1195d3e87a52` に載せ直した。入力欄・新規セッション・VCS同期・生成clientなどの競合を解消し、本家の音声入力・location選択・VCS再取得を維持した。

- Bun は本家と同じ1.4.4。client・protocol再生成、protocol `check:generated` 成功。
- 標準 `bun run check` 全35パッケージ、公式 `bun run typecheck:tsc` 全34パッケージ成功。
- core の stats/projector/VCS/V1 migration/database migration は125件成功。server対象3件、client VCS対象1件、app catalog対象9件成功。
- production fixture の composer 2件と本家 timeline geometry 1件、計3件成功。指定統計・中央配置・新規・狭幅・再読込・APIエラーに加え、入力欄が伸びてもtimeline末尾が正しい位置に保たれることを確認。
- 性能測定ヘルパーは、本家がtimelineを入力欄の背後まで拡張した変更に未対応だった。旧計算では実際に末尾にいても152pxの差を返したため、可視領域の下端から `data-timeline-inset` を差し引くよう修正した。許容誤差は1pxのまま。
- production benchmark は各1回。firstCorrectObservedMs 442.0 → 523.4、stableObservedMs 461.7 → 564.7、wrongDestinationSamples は両方0。単回測定・測定ヘルパーの変更があり、性能改善を主張しない。
- 今回は blob/blob_ref の追加、allowanceの追加と削除、session_pendingの削除を含むDB migrationがある。旧版への復旧ではバイナリと移行前DBを組にして戻す。

- Web UI 同梱 Linux x64 ビルドと新規DB native smoke成功。実DBのonline backupコピーでmigration・blob/blob_ref追加・全5セッション・数値速度・SQLite quick_checkを確認。移行前コピーを戻して、まだインストールされていた旧2.1.3版で再起動する復旧リハーサルも成功した。コピーの実行claimと待機入力だけを無効にし、ユーザーの実処理は開始していない。
- 2026-10-27 16:35 JST、実行中セッションがないことを確認して本番を停止・バックアップ・切替・再起動した。旧バイナリ・設定・移行前DB・更新前後lockは非公開領域へ保存し、失敗時にはDBも旧版と組で戻す手順を用意した。既存5セッション、認証、URL/ポートを保持し、プロバイダー設定ファイルのハッシュも一致した。
- Tailscale HTTPS の新規 Chromium で数値tok/s・編集可能な入力欄・開発バッジなしを確認、page error 0。モデル選択が本家でmenuからdialog/comboboxへ変わったため確認スクリプトを合わせ、DGXのGLM/DeepSeek両方の表示を確認した。モデルの推論やvision通信は今回の更新では再実行していない。systemd active/running、NRestarts 0。
- [リリース v2.1.4-akiyan.1](https://github.com/akiyan/opencode/releases/tag/v2.1.4-akiyan.1) にカスタマイズ説明と合成データのスクリーンショット3枚を掲載し、GitHub上で全画像の描画を確認した。アーカイブSHA-256はローカル・公開assetで一致: `51e8254a38be257a72fce4e2ff290d74d4b3126732f4f0859dbcd60440edd1f9`。
- 公開後compareは ahead 1 / behind 1。検証中に進んだ本家の追加1コミットは今回の採用点には含めない。運用リポジトリのreleases・保存済みActions artifactsはどちらも0。CI定義へDB migration対象テストを追加したが、今回はGitHub Actionsの手動実行はしておらず、上記はローカル実行の結果である。
