# Render upgrade — 2026-10-30

Left: `main` at fbcebac. Right: branch `ccr-1725986f-rq7lik`. High preset,
Forward+, cached data, the place's own golden hour (yaw 0/90/180/270 at
pitch −0.10; `down` at −0.35; `noon` at 13:00), live weather replaced by
fair weather (code 1, 25% cover), governor off. These are **software
Vulkan (lavapipe) under Xvfb**: the shading is real, but timings are
CPU-bound and fps on a real GPU and on phones was not measured.

**Not in these captures:** captures ran from a snapshot taken before
three late changes. Those are: cloud shadows on far terrain, per-building
tints on the batched distant city, and the ground-cover tuning (tufts
brighter, flared, only within half the radius; the first version reads
as dark specks on the Interlaken meadow here). The changes went through
the tests and a shader compile check, but no capture shows them.

| Area | What changed (see the sheets) |
|---|---|
| Light / grade | ACES white point 6: sunlit stone and the sky near the sun roll off instead of clipping. Glow comes from HDR highlights only (the 0.10 bloom made the frame look milky). Ambient comes fully from the sky. High and Ultra skies get a cirrus veil, eroded cloud edges and a short light march toward the sun. |
| Buildings | Frames, glass and cornices are painted over the building's tint instead of multiplied by it (white frames had albedo > 1, which washed the facades out). Limestone sits 10% lower. Rain streaks run down from sills. Each building gets its own wall tint and darkens toward the street. Near buildings get a stone cornice under pitched roofs and a parapet with coping on flat roofs (`banff-*`). Roof tiles follow the eave at real size, and roof normal maps now have tangents. |
| Night | Lit windows are an emission map that switches on through dusk (`paris-p2-night-after.jpg`). Before, they were orange paint, visible at noon and dark at night. |
| Terrain & mountains | Six new CC0 terrain sets (cliff, forest floor, lawn, gravel, sand, snow) are packed into texture arrays and sampled without visible repetition. Steep ground turns to biplanar cliff rock with strata. Noise-gradient crag relief appears in the lighting on near and far slopes (`banff-p2-yaw000`: ribs and gullies instead of smooth domes). Far rings show rock on steep faces, and on High and Ultra get photographic detail out to about 7 km. Satellite imagery is dehazed, so slopes are less mint. |
| Water | Waves at three scales; far water keeps reflection streaks. High and Ultra get Gerstner swell on the sea. Rivers flow downstream with foam streaks (`bigsur-p2-yaw090`). An animated shore foam band follows the coast. The sea is a grid carrying distance to land. Far lakes and sea are glossy water. Quay stone was ~1.6× too bright because of a double sRGB decode. |
| Roads | One shader paints, on every tier: centre lines, lane dividers from the OSM lane count, edge lines on main roads, zebra crossings near junctions on urban streets, kerb and gutter, tyre tracks, cracks and patches, puddles in rain, and snow except in the tracks (`paris-p2-down`, `interlaken-p2-yaw090`). |
| Parks | MultiMesh grass tufts, wildflowers and shrubs on mapped green land. None on Fast; radius 90 / 170 / 260 m on Balanced / High / Ultra. |

**Other tiers:** `fast/` holds Fast (Mobile renderer) before/after sheets
for Paris and Interlaken; Interlaken was re-captured after the
ground-roughness fix (the lawn map's own gloss had put a sun-facing sheen
on the meadows). Fast reads paler than the old grade, because it has no
shadows or SSAO under the new exposure. `ultra/` holds after-only Ultra
shots: the baseline Ultra run built Paris and then never wrote its frames,
so no before set exists.

**Tests:** full headless suite PASS, except `fidelity_scorecard` Turku (a)
3.19 m vs the 3 m bar, which fails the same way on `main`. The new
`tests/render_upgrade_test.gd` passes. `tools/check_class_size.sh` OK
(largest file is 500/500).

**AC-12:** layout, heights and hues are tier-independent. Trims sit on
every tier inside a fixed 320 m radius and never raise a top. Wall and
roof tints average 1. Tiers change only costs: detail variation, cliff
projection, far detail, swell, cover radius and texture size.
