# Fork operations

- This repository owns operational rules; application changes belong in akiyan/opencode.
- Keep akiyan-stats exactly one commit ahead of the SHA in config/source.lock.json. Never rewrite official upstream refs.
- Use the user-approved Japanese labels: ターン, ステップ, キャッシュヒット.
- Keep runtime data, credentials, logs, generated binaries, and local paths out of commits. Public examples must be fictional or explicitly supplied by the user.
- Before publishing a new lock, verify the actual parent SHA, clean worktree, checks, tests, and binary build. Record limitations honestly.
- Upstream updates are explicit candidates. Preserve the previous lock, code commit, artifact, and a consistent database backup before a production switch.
- Do not replace or restart the existing live service as part of development or validation.
- Do not create a Codex recurring automation unless requested.
