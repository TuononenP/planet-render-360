# Diag 2026-10-28 — first headed capture of the redesign tree + terrain Y-scale finding

Source: `godot --script /tmp/paris_now.gd` (throwaway probe, Paris 48.8566,2.3522,
High preset, warm v2 cache — view visible after 3.3 s, HUD 95 fps).

- [paris_now_desktop.png](paris_now_desktop.png) — 1280×800
- [paris_now_phone.png](paris_now_phone.png) — 390×844

Finding: flat Paris renders with ~4× vertical exaggeration — rolling mounds
bury city blocks. GroundTruth Y is true metres (T1.3) while XZ is 0.25× units
under the T1.2 equivalence flag, and `_terrain_mesh` uses `h` unscaled
(`scripts/generation/terrain_builder.gd:228`, no `× metres_to_units()`).
Data-level probes all pass because they check metres and self-consistent
hashes, never composed proportions. Full note in the plan §13 session log
(`parent / render-check`, 2026-10-28).

Known-gaps visible, already tracked: no road ribbons (T4.4 not started),
Eiffel is a bare mast (T5.3), landmark framing rescale still active (T5.2).
