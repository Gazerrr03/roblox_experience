# Claude Entry

This repository uses a cross-agent "vibe" framework for multi-place work.

- Start with `AGENTS.md` for repo-wide engineering guardrails.
- Start with `references/place-parallel-development.md` for the multi-place delivery model.
- Treat code domains as the primary boundary. Branches, worktrees, issues, and PRs are coordination tools around those domains.
- When you enter `places/lobby`, `places/run`, `places/maze`, or `packages/shared`, read the local `VIBE.md` first and the local `NOW.md` second.
- Local `AGENTS.md` and `CLAUDE.md` files are intentionally thin adapters. The durable source of truth lives in `VIBE.md` and `NOW.md`.
