# Ultra review p1 — 2026-11-01 (Ultra pass, Phase 1 quick corrections)

`tools/capture_presets.gd --audit --preset=3 --places=new_york,dubai,london,paris,rome --times=golden,night`,
compared with the full Ultra baseline `../ultra-base-2026-11-01/` (all 13 presets + 5 controls, same code
before this phase).

## Changes

- Curtain-wall glass albedo down from ~0.27 to ~0.14 (`FacadeComposer.SKY_GLASS*`, `SPANDREL`, `MULLION`),
  metallic 0.45 → 0.6 so the brightness comes from the reflection; legacy full-wall glass panes 12 % darker.
- Relief stone (sills, string courses, balconies) calibrated to per-finish targets instead of the bare photo
  (`ReliefKit.STONE_TARGETS`); chimney and gable brick, plant-room concrete to `MaterialLibrary.PRD_BRICK` /
  `PRD_CONCRETE`.
- Relief meshes carry tangents (`ReliefKit._tangents`), so their stone normal maps shade correctly.
- Shop signs are dark by day and glow from dusk with the lit windows (`CityLights.mark_glow`).

## Audit (5 places, uses-weighted mean linear albedo)

| material | base | p1 | range |
|---|---|---|---|
| `facade:glass` (curtain walls) | 0.263 | 0.142 | 0.08–0.15 |
| `glass:1` (legacy full-wall glass) | 0.293 | 0.163 | 0.08–0.15 (panes darkened again after this run) |
| `pbr:limestone` | 0.348 | 0.429 | 0.45–0.60 |
| `pbr:concrete` | 0.283 | 0.309 | 0.30–0.45 |
| `pbr:brick` | 0.085 | 0.232 | 0.20–0.35 |

Left as is: terracotta roofs (0.12–0.16 vs 0.25–0.40). A red clay tile at luma ≥ 0.25 turns tan, and the Rome
roofs read as terracotta in the frames, so the range itself looks wrong for red materials (it reads like a
broadband albedo, not Rec.709 luma). Needs a decision before changing either.

## Seen

- Dubai: the glass podium under the Burj now reads as dark reflective glass, not render; no black slabs.
- Paris and London: no regressions; London dusk lights come on.
- Ultra baseline New York (`../ultra-base-2026-11-01/new_york_vantage.jpg`) rendered the East River as lawn and
  the foreground pure black. The p1 run of the same code paths draws the river and lit ground, so it is
  intermittent — the same "pure black shadowed ground at golden hour" r3 logged once. Still open (lighting pass).
