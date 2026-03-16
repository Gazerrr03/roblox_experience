## Summary

- What changed?
- Why is this change needed?
- Any prototype-only exceptions or follow-up work?

## Roblox Integration Checklist

- [ ] The change updates the active runtime source under `packages/**`, or I explained why another source path had to change.
- [ ] If Studio tree structure changed, I updated the relevant `default.project.json` in the same PR.
- [ ] If I changed Remote names, replicated schema, or visibility behavior, I updated all linked producers/consumers/tests in the same PR.
- [ ] If I changed non-trivial shared/gameplay behavior, I added or updated deterministic coverage under `tests/src/Shared`, or I explained why no test change was needed.
- [ ] If I touched `SessionConfig.PlaceIds` or any other real-environment configuration, I documented the required rollout or environment follow-up.
- [ ] If this PR includes `.rbxl`, generated output, or other non-source artifacts, I explained why they are required.

## Validation

- [ ] `stylua --check .`
- [ ] `selene .`
- [ ] Additional verification steps are listed below if this PR needs more than static checks.

## Notes

- Manual test notes:
- Risks / follow-ups:
