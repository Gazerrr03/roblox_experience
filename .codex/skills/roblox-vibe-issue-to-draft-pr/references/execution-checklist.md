# Execution Checklist

## Order Of Work

1. Read the repo guardrails in `AGENTS.md`.
2. Read `references/place-parallel-development.md`.
3. Route the issue before coding.
4. Read the owning `VIBE.md` first and `NOW.md` second.
5. Create a feature branch.
6. Implement the smallest end-to-end slice that satisfies the issue.
7. Update shared contract producers, consumers, and tests together when shared meaning changes.
8. Run validation.
9. Push the branch.
10. Open a draft PR to `main`.

## Validation Matrix

- Always:
  - `stylua --check` on touched files
  - `selene .`
- For affected places:
  - `rojo build places/<place>/default.project.json -o .\\tmp\\<place>.rbxlx`
- For shared or gameplay logic:
  - `rojo build tests/default.project.json -o .\\tmp\\roblox_experience-tests.rbxlx`
  - `run-in-roblox --place .\\tmp\\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua`

## Draft PR Body Template

- `Summary`
- `Why This Lives In <vibe or cross-vibe>`
- `Scope`
- `Validation`
- `Risks / Follow-Up`
- final line: `Closes #<issue-number>`

## Merge Story Rule

The draft PR lands on `main`. The long-lived vibe branches are synced from `main` after merge; they are not co-target branches of the PR.
