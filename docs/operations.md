# 運用手順

## 初回

1. source.lock.json の SHA を checkout し、verify.sh で親子関係と差分を確認する。
2. 本家の該当コミットにある AGENTS.md を読む。公開 API の変更後は packages/client で `bun run generate` を実行し、生成物を同じ独自コミットへ含める。
3. `bun install --frozen-lockfile`、ルートの `bun run check`、変更領域のテストを実行する。テストはパッケージ内から実行する。
4. `scripts/build.sh` で Web UI 同梱バイナリとチェックサムを作る。
5. `scripts/run.sh` による隔離環境で、長い履歴・再読込・セッション切替・狭い画面を確認する。

## upstream の更新

- 自動的に最新版を本番へ反映しない。採用したいタグ／SHA を明示する。
- fork の `akiyan` 作業ツリーがクリーンな状態で `scripts/propose-update.sh <upstream-ref>` を実行する。新しい候補ブランチへ独自コミットを cherry-pick する。
- 競合は候補ブランチ内で解決する。処理を取りやめる場合は `git cherry-pick --abort`。公開中の運用ブランチは変更されない。
- 検証後、親 SHA と独自コミット SHA、バージョンを lock に記録する。独自の追加入力が複数コミットになった場合は候補ブランチ内で1コミットへ squash する。
- 運用ブランチを更新する際は直前の remote SHA を確認し、必要な場合だけ明示した `--force-with-lease` を使う。他の人の更新を上書きしない。
- upstream ブランチ `dev` / `v2` に独自コミットを push しない。本家向け PR は今回の運用には不要。

## 本番切替

- 現行の lock・コード SHA・バイナリ・チェックサム・起動設定を保存する。
- 使用中 DB のパスを確認し、SQLite online backup またはサービス停止中のコピーで整合性のあるバックアップを取る。稼働中に DB 本体だけを単純コピーしない。
- 候補版を隔離 DB で検証する。認証情報はローカルの設定へ置き、public リポジトリには追加しない。
- 切替対象・ポート・データパスを明示した作業として切り替える。既存サービスの接続先を誤って採用しないよう確認する。
- ブラウザの再読み込み後に独自 UI と版番号を確認する。古い PWA キャッシュが残る場合は該当オリジンのサイトデータを確認する。

## ロールバック

旧バイナリと旧設定へ戻す。upstream 更新で DB migration が入った場合は対応するバックアップも戻す。新しい DB を旧バイナリでそのまま開くことを前提にしない。今回の独自変更自体は DB migration を持たない。

## 公開物

ソース・運用ルール・固定 SHA・合成データによるスクリーンショットのみを公開する。API キー、remote の資格情報、実セッション DB・会話・ログ・パスワード・バックアップは公開しない。バイナリは Git にコミットせず Actions artifact または明示した release に置く。

## 時雨堂 fork に合わせる方針

参考: [shiguredo/deepseek-harness](https://github.com/shiguredo/deepseek-harness)、[本家との差分](https://github.com/shiguredo/deepseek-harness/compare/deepseek-ai:master...shiguredo)。2026-10-22 JST の確認では、既定ブランチは所有者名の `shiguredo` で、本家 master の上に独自コミット1つ（ahead 1 / behind 0）を載せている。

こちらも所有者名の `akiyan` を運用・既定ブランチにし、本家の採用コミットの上に独自コミット1つを載せる。本家の追従元は upstream remote とし、fork 内に残る本家と同名のブランチが最新であるとは仮定しない。初版の基点は既存の利用環境に合わせた v2.1.2。変更をまとめ直す場合は独自コミットを amend / squash し、公開ブランチ更新は SHA を指定した lease で保護する。
