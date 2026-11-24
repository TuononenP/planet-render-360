# Debug_19.11.2026.txt: status and plan for the open issues

## Context
The log is a Helsinki streaming session (`godot --path .`, gens 2 to 10 and beyond). Commit 98b0f51a ("Stop streamed stretches dying after a swap…") landed after the log was captured. I checked each issue against the current code. I did not re-run the game, so "fixed" below means the code change is present, not that it was seen working.

## Status
| # | Log issue | Status |
|---|---|---|
| 1 | `filter` "Cannot convert argument 1 from Object to Object" plus "assign Array to Array[GenerationPipeline]" at `world_streamer.gd:928` (`_on_finished`). Every stretch after a swap was dropped. | **Fixed in code.** `_retire_pipe` now prunes by `is_instance_valid` (`world_streamer.gd:511`). Needs runtime confirmation. |
| 2 | "Lambda capture at index 0 was freed" at `world_handoff.gd:90` (`pump`), repeated 4+ times. | **Fixed in code.** The commit makes the night-lights callback capture an instance id instead of the node. Needs runtime confirmation. |
| 3 | `WARNING: BuildingBuilder: N of M real buildings used the AABB fallback` (1 of 946, 2 of 1122), and "BUILDINGS N masses failed to build". | **Not fixed.** `_extrude_masses` still fails on some footprints (`building_builder.gd:290-344`). The fallback hides the cause and nothing identifies the OSM ids. |
| 4 | "BUILDINGS 18-50 outlines under 90% covered by their parts, 16-50k m² unbuilt" on every build. | **Not fixed.** Diagnostic only (`building_builder.gd:109`, counted in `building_masses.gd:253`). It is visible as holes in building footprints. |
| 5 | "Orthophoto: part 0 / part 2 unreadable or blank; inner imagery falls back" (`ortho_fetcher.gd:153,202`). | **Not fixed.** This is a fetch or decode failure. It falls back gracefully but the inner imagery is lower quality. |
| 6 | Exit leaks: 51 RIDs, 88 Texture RIDs, 11,671 ObjectDB instances, 8 resources in use, PagedAllocator pages. | **Not fixed.** Teardown does not free everything (likely caches, staged worlds or parked worlds). |
| 7 | `TREE REGISTER … 0 matched` (gens at lines 79 and 374). | **Unclear.** It may be legitimate (no register rows in range) or a bug in the matching bounds. Needs a look. |
| 8 | Slow or uncached `FAR-CITY fetch` (16 to 28 s, cached:false). The stream expects 17 to 20 s and often exceeds it. | **Partly addressed** (commit makes fetch-ahead wait up to 60 s). Needs confirmation in a new log. |

## Plan
Work in this order. Each step is a separate, minimal change.

1. **Confirm 1 and 2 at runtime.** Run an editor-binary Ultra flight (see the stream-flight-verification memory) and grep the log for "Lambda capture", "Cannot convert argument" and "Trying to assign". Expect zero. Run the streamer and handoff tests headless in the background.
2. **AABB fallback and failed masses (#3).**
   - Extend the warning in `building_builder.gd` to log the OSM id, footprint point count and failure reason of each failing building (capped at about 5 per build).
   - Reproduce with the cached Helsinki tile, find the failing footprints, and fix the cause in `BuildingMasses` (typically self-intersecting or degenerate rings, or duplicate points). Prefer a footprint clean-up step before extrusion over a special case.
   - Add a unit test with one such ring.
3. **Under-covered outlines (#4).** Log the worst 5 outlines with their ids and coverage. Check whether the parts come from building:part data that doesn't tile the outline. If so, fill the gap with the outline's own mass, not leave it unbuilt. Make sure the total unbuilt area drops (the log baseline is 50k m² on the first build).
4. **Orthophoto parts (#5).** Log the HTTP status, byte count and image decode result for parts 0 and 2 to see whether the cause is a bad tile, a decode error or an empty response. Then either retry once or reject cleanly. Check `HostPolicy` and `tests/host_policy_test.gd` (no Russian hosts).
5. **Exit leaks (#6).** Run `--verbose` at exit to list the leaked classes. Free the parked and staged worlds, `StreamDetail` jobs and texture caches in the teardown path. Treat this as low priority because it only appears at exit.
6. **Tree register (#7).** Check why 0 of 4151 and 0 of 7287 rows match. Compare the register's bounds to the stretch bounds for those gens. Fix only if a bug is found.
7. **Fetch timing (#8).** Re-capture a log after steps 1 to 4 and compare the "STREAM gen N: … total" against "expect next".

## Constraints from AGENTS.md
- Keep changes minimal. No AI attribution in commits. Commit only if asked.
- Keep every class at or under 1000 lines; run `tools/check_class_size.sh` (`building_builder.gd` and `world_streamer.gd` are the likely candidates).
- Launch Godot only via `tools/godot_bg.sh`, headless, in the background. Skip the network tests (tiles_test, exit_tile_test).

## Verification
- Headless tests for buildings, streamer and handoff via `tools/godot_bg.sh --headless`.
- One Ultra flight, then a grep of the log for the error strings above.
- `tools/check_class_size.sh`.
