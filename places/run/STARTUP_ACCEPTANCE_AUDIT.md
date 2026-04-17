# Run Startup Acceptance Audit

> audited-on: 2026-04-16
> live-instance: `roblox-experience-run` (`placeId=97218919641911`)
> related-pr: [#265](https://github.com/Gazerrr03/roblox_experience/pull/265) `feat(run): remove Lobby place, add host-based in-ship start system`

This audit keeps two baselines in view:

- Baseline A: current repo feature contract in `places/run/FEATURES.md`
- Baseline B: target startup UX for this fix series

## Acceptance Matrix

| Item | Current doc promise | Live instance / current code reality | Covered by PR #265 |
|------|---------------------|--------------------------------------|--------------------|
| `spawn-points` | Active; `Spawn/Return/MazeReturn` all available | Live MCP audit found `ReturnMarker` and `MazeReturnMarker` at `(0,0,0)`, which is a blocker against the documented contract. Source `default.project.json` also left both return markers at default origin before this fix. | No. PR #265 changes host startup flow, not return-marker authoring or validation. |
| `start-menu` | Previously documented as active fullscreen `Enter the Temple` menu | Repo code previously still rendered the fullscreen page. This fix removes the blocking fullscreen entry page and replaces it with a small informational sync banner. | Partial only. PR #265 disables the launch click path, but it keeps the fullscreen menu shell and does not count as removing the page. |
| `ship-doors` | Active ship-door interaction and gate opening | Runtime still exposes `GateSwitch` and ship-door prompts. No blocker found in this audit. | Yes, indirectly. PR #265 leans on world-prompt startup, which is compatible with ship-door driven flow. |
| `run→maze-transition` | Active ReserveServer + TeleportAsync path | Code path remains intact in `RunToMazeTransition.luau`; no direct regression found in this audit. | No direct change. |
| `maze-portal` | Active in-world prompt after gate open | Live instance still exposes `MazeGateMarker.Prompt`; no direct regression found in this audit. | No direct change. |

## Target-Baseline Conclusions

### Startup / spawn quality

- Players should not visibly free-fall from an obviously wrong startup location before settling.
- Players returning from maze must not land at default origin or any un-authored fallback shell.
- `RunStaticWorldValidator` now treats all three markers as floor-backed spawn markers, and explicitly rejects `ReturnMarker` / `MazeReturnMarker` left at default origin.
- Source authoring now places all three markers on the ship-deck cluster instead of leaving return markers at the Rojo default.

### UI / flow quality

- `Enter the Temple` is no longer accepted as a fullscreen startup page.
- Startup may show read-only sync status, but that status must not masquerade as a clickable “enter” step.
- PR #265 is still useful as a host-start direction, but it is not sufficient evidence that the fullscreen startup page was removed.

## Immediate Follow-Ups Worth Tracking

- Re-audit the live Studio place after Rojo/source sync to confirm the updated return-marker coordinates have propagated out of source.
- If host-start from PR #265 lands, verify the world-prompt path remains the only startup entry and no fullscreen entry UI returns.
- If players still report a visible first-frame drop after these marker and pivot fixes, inspect the ship deck collision shell versus authored marker height in Studio and tighten the spawn timing again.
