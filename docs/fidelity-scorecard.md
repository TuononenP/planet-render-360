# Fidelity Scorecard — Real-Location Fidelity Redesign

> Owner: role F (Validation) · Plan task: T0.2 · Date: 2026-10-28
> Purpose: the measurable ruler for "looks like the real place", used in Phase 8 (T8.1–T8.3).
> The visual target remains `visual-plan/PRD.md` AC-01…AC-18; this doc defines *how each AC is measured*.
> No AC is left unmapped — see §5.

Golden locations (same 5 as plan T0.1): Paris (48.8566, 2.3522) · Interlaken (46.6863, 7.8632) ·
Zermatt (46.0207, 7.7491) · Big Sur (36.2704, −121.8081) · Turku (60.4518, 22.2666).

## 1. How scoring works

- Every check below is run **per golden location** (except Paris-only checks, marked).
- Each check yields **pass / fail** against its threshold, plus the raw measured values.
- A location **passes a check** when its measured value meets the threshold for the *tested tier*.
- Phase 8 gate (T8.3): AC-01…AC-17 pass or carry a user-accepted waiver; AC-18 is recorded
  per location with the rater named (never auto-passed).
- Automated checks (a–e) are implemented in T8.1 (`tests/fidelity_scorecard_test.gd` or a `tools/` script);
  check (f) is always a signed human checklist.
- When live data (Overpass/DEM/satellite) is unreachable during a scoring run, the run is recorded as
  `data-unavailable — geometry-only scoring` for the affected checks, never as a silent pass.

## 2. Tier names and thresholds

Tier naming is still open (plan Open Q2). Thresholds are given per **quality tier** using both names:

| PRD fidelity | Shipping preset | Generation budget (plan §3.1) |
|---|---|---|
| Fidelity 1 | Fast | ≤ 20 s cold / ≤ 3 s cached |
| Fidelity 2 (default) | Balanced / High | ≤ 45–75 s cold / ≤ 5 s cached |
| Fidelity 3 | Ultra | 60–120 s cold (cap 150 s) / ≤ 8 s cached |

Per PRD §3.4 / plan invariant 5, tier switches must not move any object or shift any hue >2% —
so **geometry checks (a–e) share one threshold across tiers**, while **appearance checks** and the
human rating (f) are tier-graded (a lower tier may score "recognisable" where Ultra must score
"photographic"). Where a check is tier-graded, the per-tier bar is stated explicitly.

Known ceiling (plan R2): free zoom-14 DEM and zoom-17/18 satellite cap near-field detail;
narrow streets (<3 m), roof furniture, and watercourses <5 m wide remain approximate at every tier.

### Measured against the budget (2026-11-15, desktop)

`tools/perf_baseline.gd`, one run per preset, each in an empty isolated cache
(results in `visual-plan/reviews/perf-2026-11-15/`). Machine: Apple M5 Ultra, macOS,
Forward+, 1280×800. Overpass was failing its status check during the run, so cold opens
used the OSM API and vector-map fallbacks.

- **Cold:** fetch and build with nothing cached.
- **Warm build:** data cached, world not.
- **Cached:** reopen from the world cache.
- **Fly:** 90 s east at 40 m/s, 120 m up, streaming on.
- **Peak:** OS footprint, which includes GPU memory on Apple Silicon.

Every cached reopen loaded its saved world. Before the 2026-11-15 world-key fix, the first
revisit of each new place rebuilt instead.

| Preset | Place | Cold s | Warm build s | Cached s | Save s | Mesh nodes | Fly p95 / max ms | Peak MB |
|---|---|---|---|---|---|---|---|---|
| Fast | Helsinki | 10.9 | 7.8 | **3.8** | 9.2 | 1279 | 9.4 / 235 | 4,834 |
| Fast | New York | **29.2** | 24.1 | 2.6 | 7.1 | 1302 | 9.4 / 266 | 4,678 |
| Fast | Paris | 10.8 | 8.0 | 2.4 | 6.0 | 1204 | 9.4 / **3,834** | 4,836 |
| Fast | Turku | 14.0 | 6.1 | 2.3 | 6.2 | 1300 | 9.2 / 120 | 4,192 |
| High | Helsinki | 25.6 | 11.4 | 4.2 | 15.3 | 2071 | 21.3 / 265 | 7,584 |
| High | New York | 39.9 | 28.5 | 3.1 | 13.6 | 1836 | 14.7 / **2,395** | 8,350 |
| High | Paris | 22.0 | 11.4 | 2.9 | 11.8 | 1751 | 14.7 / 320 | 8,967 |
| High | Turku | 16.9 | 7.9 | 2.9 | 12.0 | 1941 | 11.8 / 559 | 8,093 |
| Ultra | Helsinki | 26.7 | 11.0 | 4.5 | 29.8 | 3183 | 23.4 / 204 | 12,452 |
| Ultra | New York | 45.2 | 29.5 | 3.5 | 24.0 | 2418 | **47.1** / 379 | 15,405 |
| Ultra | Paris | 14.8 | 10.3 | 3.0 | **70.4** | 3213 | 32.2 / **3,124** | 15,093 |
| Ultra | Turku | 18.9 | 10.4 | 6.5 | 20.9 | 2700 | 35.3 / 469 | 13,293 |

**Over budget:**
- New York Fast cold: its "Roads & landmarks" stage takes 17–21 s on every preset.
- Helsinki Fast cached.
- Streaming frames of several seconds in Paris and New York. These follow the vector-map
  fallback after a slow Overpass, and are not script time.
- Ultra fly p95 is above 30 fps.

**Memory:** peaks are well past a phone's limit. `MemoryBudget` and `MemoryGuard` now plan and
shed against each device's own limit. No phone numbers are recorded yet.

## 3. The six checks

### (a) DEM spot-height error — terrain matches the real relief

- **Method:** at 9 sample points per location (centre + 8 compass points at 1/3 and 2/3 of the
  detailed-extent radius — see T0.1 baseline pack for the point set), compare the rendered
  `GroundTruth` height (metres, post-Phase-1 identity mapping) against the source DEM tile value
  bilinearly sampled at the same lat/lon.
- **Metric:** max absolute error over the 9 points; also record mean error.
- **Pass (all tiers, true-metre mode):** max error ≤ **3 m** in flat terrain (Paris, Turku),
  ≤ **8 m** in alpine/coastal terrain (Interlaken, Zermatt, Big Sur). The legacy-squash A/B mode
  (plan T1.3) is expected to fail; the comparison is recorded as evidence that true-metre wins.
- **Pre-Phase-1 note:** before T1.3 the heights are adaptively remapped, so (a) is recorded as
  *baseline-only* (values logged, no pass/fail) until the identity mapping lands.

### (b) Footprint-area agreement — buildings sit on their real outlines

- **Method:** sample 20 buildings per urban location (Paris, Turku; 10 for Interlaken/Zermatt/Big Sur
  where fewer exist) from OSM footprints inside the detailed extent, stratified near/mid/far.
  For each, compute `placed polygon area / OSM footprint area` (post-T4.1: true polygon overlap IoU;
  pre-T4.1: placed-AABB area vs. OSM polygon area as a proxy) and the centroid offset in metres.
- **Metric:** median area ratio and median centroid offset over the sample.
- **Pass (all tiers, post-T4.1):** median IoU ≥ **0.85** (urban) / ≥ 0.75 (rural); median centroid
  offset ≤ **2 m**. Pre-T4.1 proxy pass: median area ratio within **0.7–1.3** and offset ≤ 5 m.
- **Fail-closed rule:** a sampled OSM building with no rendered building within 10 m counts as IoU 0.

### (c) Height error vs. OSM height/levels — buildings rise to their real height

- **Method:** sample up to the (b) count from only the buildings where OSM carries `height` or
  `building:levels`, with the same near/mid/far rule (sample rules v2, 2026-10-31: a sparsely
  tagged town such as Banff, 90 of 1329 tagged, had no tag in its (b) sample and stayed BLOCKED).
  Convert levels × regional floor height per T4.2, never a global default, and compare rendered
  building height against it. BLOCKED only when no building in the extent is tagged.
- **Metric:** median absolute error in metres (or storeys where only levels exist).
- **Pass (all tiers):** median error ≤ **1 storey** (≈3 m); coverage is reported, not gated,
  except that a live Paris fetch must show ≥30% of buildings carrying explicit height/levels (T2.3).
- **Neighbour guard (PRD §4.2, automated in T4.2):** no non-landmark building >2.0× its neighbours'
  height unless OSM data says so — 0 violations per location.

### (d) Water/road presence — rivers, lakes, coasts, and streets exist where they should

- **Method (water):** for each location with real water (Paris/Seine, Interlaken/lakes, Big Sur/coast,
  Turku/archipelago; Zermatt/river), take 5 centreline/shoreline sample points from OSM water
  polygons/waterways; a point passes if rendered water exists within **10 m**.
  Locations with no OSM water must render **no** river/lake (absence check — plan D9).
- **Method (roads):** take 5 known road junctions from OSM per location; a junction passes if the
  rendered road ribbon centreline passes within **3 m** (tiers F2/F3) or **5 m** (F1, coarser grid),
  sits flush (offset ≤0.05 m, PRD §4.4), and does not cut a building footprint.
- **Pass (all tiers):** water 5/5 (or correct absence: 0 rendered water polygons where OSM has none);
  roads 4/5 junctions within tolerance, 0 floating/cutting segments in the sample.
- **Paris extras:** Seine centreline within 10 m at all 5 samples; ≥3 bridges land on real bridge ways.

### (e) Landmark bearing error + apparent-height ratio — the icon sits right (Paris + registry)

- **Method (bearing):** from the PRD §4.1 spawn camera, measure the landmark centreline bearing error
  in degrees vs. its true bearing (Eiffel Tower for Paris; registry landmark or OSM archetype where
  one exists for other locations — otherwise `n/a — no landmark`, explicitly noted).
- **Method (apparent height):** measure the landmark's apparent height in the spawn frame (fraction of
  viewport height) vs. the true geometric value at that spawn: Paris target **0.23 H** (spire 0.28 H,
  base 0.51 H, centreline 0.36 W ± tolerances per AC-01).
- **Pass (all tiers):** bearing error ≤ **1.0°**; apparent-height ratio within **±15%** of true geometry
  (Paris: 0.195–0.265 H); silhouette checklist (AC-06: 4-leg lattice, 2 platforms, continuous taper,
  haze blend ≤20%) signed by F per landmark.
- **Anti-framing rule:** any landmark scaled/moved for framing (plan D10) fails (e) automatically,
  even if the numbers coincidentally pass — placement must be true-position (T5.2).

### (f) Human side-by-side rating — does it read as the real place (per AC-18)

- **Method:** rater compares the F3/Ultra spawn capture (+ 4 yaw quadrants) side-by-side with the
  golden-hour reference photo of the same spawn (T0.5; Paris: `visual-plan/refs/view360-paris.jpg`),
  and grades each location on the three-point scale:
  - **stylised** — layout roughly right but materials/light read as game/CG, not photographic;
  - **recognisable** — a viewer names the place and its landmark/river/blocks sit right, but a
    photo side-by-side still shows clear CG tells;
  - **photographic** — a viewer calls it photorealistic scenery (real stone/slate/water/foliage)
    with the reference layout still recognisable (AC-18 bar).
- **Recording:** one signed line per location per tier: rater name, date, capture paths, grade,
  and the single biggest remaining tell (e.g. "ground streak", "tower lattice thin at distance").
- **Pass bar:** Paris at Fidelity 3 must reach **photographic** for T8.3; all other locations at F3
  must reach at least **recognisable** (photographic where a reference photo exists); Fidelity 1
  must reach at least **recognisable** on layout (materials may read simpler — only §3.4 columns change).
- **Locations without a reference photo** (see T0.5) score geometry-only: checks (a–e) gate them,
  and (f) is recorded as `no-reference — geometry-only scoring` with the rater naming the closest
  available comparison instead of a grade.

## 4. Sampling and fixture rules (shared by all checks)

1. The 9 DEM points (a), 20/10 buildings (b/c), 5+5 water/road points (d), and landmark spawns (e)
   are fixed per location once T8.1 lands; the point sets live with the scorecard automation and are
   versioned with it — resampling per run is forbidden (no cherry-picking).
2. Every scored run records: tier/preset, seed, data versions (cache keys v2), live-vs-cached fetch
   per layer, and generation stage times against the plan §3.1 budget.
3. A check that cannot run (missing data, missing reference, headless display limits per T0.1) is
   recorded **blocked with reason**, never auto-passed and never silently skipped.
4. Per-phase regression captures (T8.2) re-run the automated checks and attach the report to the
   review folder; a regression without a diff note blocks the phase exit tick.

## 5. AC → scorecard mapping (every AC-01…AC-18 mapped, none unmapped)

| AC | PRD §8 summary | Scorecard check(s) | How it is measured |
|---|---|---|---|
| AC-01 | Spawn framing (horizon, Eiffel, sun positions) | **(e)** landmark spawn geometry | Bearing ≤1°, centreline 0.36 W ±0.02, spire 0.28 H ±0.02, base 0.51 H ±0.02, sun 0.62 W/0.37 H ±0.03 sampled from the spawn capture |
| AC-02 | Seine S-curve + ≥3 bridges + quay trees | **(d)** water/roads + (b) quay alignment | River entry/exit ±0.04 vs. real OSM path within 10 m at 5 samples; bridge count on real ways; tree rows where OSM trees exist |
| AC-03 | 0 low-poly/flat surfaces at F2–F3 | **(f)** human rating + material audit | Rater confirms PBR on every wall/roof/ground plane in all 5 captures; automated: 0 untextured-primitive materials in F2/F3 builds (T4.3 material-count assert) |
| AC-04 | Photoreal Haussmann fabric, 4–7 storeys, mansards | **(b)** footprints + **(c)** heights/storeys | 20-building sample: storey count, mansard angle 45–60°, dormers; neighbour-guard 0 violations |
| AC-05 | Facade/roof albedo reads (limestone/slate) | **(f)** + colour sampling | Sampled facade/roof colours within ΔE tolerance of PRD §3.2 bases (#D6C5A3/#46525E) under §3.3 light; rater confirms not orange/white/grey-plastic |
| AC-06 | Eiffel 4-leg lattice, taper, sharpest distant object | **(e)** silhouette checklist | Checklist signed by F: 4 legs, 2 platforms, continuous taper, 0 stacked-cylinder segments, haze blend ≤20% |
| AC-07 | Golden-hour grade, haze, no void/edge at any yaw | **(f)** + sky/horizon sampling | Sky/sun/haze colour samples within tolerance at Paris 17:00 state; 4-yaw captures show no void band or hard terrain edge (far-ring geometry via (a) far checks) |
| AC-08 | Photoreal water + sun glint | **(d)** presence + **(f)** material read | Water within 10 m of real path; rater confirms PBR + moving micro-normals + glint path (F3 sparkle, F1–F2 sheen), not a flat polygon |
| AC-09 | Ground never bleaches, slope shading | **(f)** + luminance sampling + **(a)** slopes | Max urban-ground luminance ≤0.85 sampled; pavement/grass base reads; DEM slope shading visible on horizon hills |
| AC-10 | 2 textured tree species, quay spacing | **(d)** tree presence + **(f)** species read | Quay/street rows at 8–12 m where OSM trees exist; 0 trees inside footprints/water (automated, T5.1); rater confirms broadleaf+pine, canopy Ø 4–7 m, ±10% variance, 0 bare cones |
| AC-11 | Photographic clouds, 28–40% H band | **(f)** sky review | Rater confirms photographic/volumetric-look clouds with #E8C9A0 undersides at Paris state; 0 faceted slabs at any tier; coverage responds to weather (T6.4) |
| AC-12 | 3 tiers exist, F2 default, switch ≤2 s, 0 moves/shifts | **(f)** + automated tier-diff | Transform diff = 0 and hue ΔE ≤2% across a tier switch (T7.1 assert); switch timed ≤2 s; F2 confirmed default in settings. Relaxed 2026-11-01 for desktop Ultra only: it may add decorative extras (shader facades with interiors and per-pane night lights, relief / trim / roof detail to 700 m) that lower tiers never build. Relaxed 2026-11-10 for desktop Balanced and High (Forward+): a facade shader may light night windows per bay and storey where the Standard material lit a whole column; by day it must match Standard within the 2% hue bar. Real buildings, roads and landmarks still never move (lod_test footprint checks) |
| AC-13 | Visible tier separation (textures/shadows/bloom/props) | **(f)** side-by-side tier review | Rater compares F1/F2/F3 captures: texture/shadow/reflection/bloom/prop columns per PRD §3.4 verified present and tier-separated |
| AC-14 | F1 ≥30 fps, ≤400 draws, ≤6 shared materials | Performance counters (with checks) | fps + draw-call + material-instance counts recorded per location/tier in every scored run; F1 bar: ≥30 fps target profile, ≤400 draws, ≤6 distant materials |
| AC-15 | Picker geometry ±2%, launches spawn view | **(f)** picker review | Layout sampled against §4.6 (title/search/map/pin/card/button geometry, teal #3E8F88); tap-through opens the (e)-verified spawn view |
| AC-16 | In-360 chips ±2%, teal, ≤8% frame | **(f)** HUD review | Chip positions sampled ±2% W/H, teal #42948E, total coverage ≤8% measured from capture |
| AC-17 | Drag look 360°×±60°, zoom, continuous off-frame fabric | **(f)** interaction review + **(b–d)** off-frame | Input ranges verified (yaw/pitch/damping/FOV); 4-yaw captures scored by (b–d) sampling so no style change hides off-frame |
| AC-18 | Side-by-side with photo reads photorealistic (F3) | **(f)** human rating (primary) | The (f) grade itself: Paris F3 must reach photographic; layout (§4.1–4.3) recognisable; no major landmark/river/block placement difference |

AC-14 has no geometry component, so it rides on the performance counters recorded by every scored
run (check §4 rule 2) rather than on checks (a–f) — it is still gated, not waived.

## 6. Scorecard report format (for T8.1)

One Markdown report per scored run, stored next to the captures it judges
(`visual-plan/reviews/<phase>-<date>/scorecard-<location>-<tier>.md`):

```text
# Scorecard — <location> — <tier> — <date>
- Run: seed …, data v…, live/cached per layer …, gen time … (budget …)
- (a) DEM: max … m / mean … m → PASS|FAIL|BLOCKED(reason)
- (b) footprints: median IoU …, offset … m → PASS|FAIL|BLOCKED
- (c) heights: median err …, coverage …%, neighbour violations … → PASS|FAIL|BLOCKED
- (d) water …/5, absence-ok? …, roads …/5, float/cut … → PASS|FAIL|BLOCKED
- (e) bearing …°, apparent-height …, silhouette … → PASS|FAIL|N-A|BLOCKED
- (f) rater …, grade …, biggest tell … → PASS|FAIL|NO-REFERENCE
- AC-14 counters: fps …, draws …, distant materials …
- Captures: <paths>
```

### Automation (T8.1, 2026-10-29)

`godot --headless --script tests/fidelity_scorecard_test.gd` runs checks
(a)–(e) on all five golden locations and writes the §6 report per
location to `SCORECARD_OUT` (default `user://scorecard`;
`SCORECARD_PRESET` 0–3, `SCORECARD_ONLY` one location key). Rendered
output is measured, not builder bookkeeping: (a) GroundTruth vs an
independent bilinear z14 sample at the 9 points (points in mapped water
are carved on purpose and listed, not scored; fewer than 6 land points
blocks); (b/c) roof triangles attributed by centroid-in-footprint on a
1 m grid — IoU, area-centroid offset, top above the lowest footprint
ground; (d) visible water within 10 m, 3 m inside the nearest water
triangle; road junctions inside OSM footprints (passages) excluded and
counted; a failed OSM fetch blocks (d); (e) model vs geodesic bearing.
The fixed sample sets are the rules in the test header (`SAMPLE_RULES`),
versioned with it. Apparent height, AC-06 and AC-14 stay BLOCKED
headless; (f) stays the signed checklist. First run:
`visual-plan/reviews/scorecard-2026-10-29/`.

## 7. Validation of this doc (T0.2 gate)

- [x] Reviewed against PRD AC-01…AC-18: every AC maps to ≥1 scorecard check (§5 table, 18/18 rows).
- [x] Checks (a–f) defined with method, metric, and per-tier pass thresholds (§2–§3).
- [x] Sampling/fixture rules prevent cherry-picking (§4); blocked/missing-data behaviour is fail-closed.

## 8. Reference coverage (T0.5, 2026-10-28)

Audit of `visual-plan/refs/` (contains only `view360-paris.jpg` + `picker.png`, both
user-provided per PRD §2): no usable external reference photo exists for any golden
location other than Paris, and per the T0.5 rule no random images were downloaded.
PRD §2 gains no new rows until a reference with a verifiable source/licence is added.

| Golden location | Reference | Source / licence | Check (f) scoring |
|---|---|---|---|
| Paris (48.8566, 2.3522) | `visual-plan/refs/view360-paris.jpg` | user-provided (PRD §2) | Full (f) human rating vs. reference |
| Interlaken (46.6863, 7.8632) | none | — | `no-reference — geometry-only scoring` |
| Zermatt (46.0207, 7.7491) | none | — | `no-reference — geometry-only scoring` |
| Big Sur (36.2704, −121.8081) | none | — | `no-reference — geometry-only scoring` |
| Turku (60.4518, 22.2666) | `visual-plan/refs/turku/` (13 open-space views + `README.md`) | Wikimedia Commons CC BY / CC BY-SA / PD (T-0.2, 2026-11-20) | Full (f) human rating vs. reference |

Geometry-only locations are gated by checks (a–e) only; (f) is recorded as
`no-reference — geometry-only scoring` with the rater naming the closest available
comparison instead of a grade (see §3(f) and §6 report format `NO-REFERENCE`).
`visual-plan/baseline/2026-10-28/` captures are current-state renders, not reference
photos, and must never be scored against as references. Plan Open Q3 stays open:
adding a CC-licensed or user-provided photo for a listed location upgrades it to
full (f) scoring; the PRD §2 row and this table are updated together in that task.

## 9. Preset vantage ratings — realism v3 (R-1.1)

Each quick-pick preset now has CC-licensed reference photos, listed with licence and source in
`visual-plan/refs/<id>/README.md` (the photos themselves are gitignored and kept locally). That upgrades all 14 preset vantages to full (f) scoring (San Francisco joined on 2026-11-03).
The renders are the curated opening views (`PresetViews`). One row per preset per round. A grade
from an agent is a pre-rating; the human gate (plan §Verification 5) re-rates it.

Round r4, 2026-11-01:
- Captures: `visual-plan/reviews/vantage-r4-2026-11-01/` (Venice:
  `vantage-r4-venice-2026-11-01/`).
- Conditions: High preset, local golden hour, clear summer.
- Rater: Claude (agent pre-rating).

| preset | grade | biggest remaining tell |
|---|---|---|
| Paris | recognisable | Grass tufts on the Trocadéro paving; plaza too bright |
| Alps | recognisable | Lakes and peaks right; valley floor reads flat green, no rock band on the far peaks |
| Banff | stylised | No Banff Springs Hotel model (generic blocks); woods uniform |
| Big Sur | stylised | No Bixby arch; coast and creek right; dry hills too yellow |
| Tokyo | stylised | Scramble and plazas render as lawn; uniform pale towers, no signs |
| New York | recognisable | Skyline layout right; far towers are flat prisms; water too cyan |
| Stockholm | recognisable | Gamla stan reads as generic blocks; no Riddarholmen spire |
| Monaco | recognisable | Harbour and Monte-Carlo right; marina without boats |
| Dubai | recognisable | Burj Khalifa centred but stepped grey prism; far towers flat |
| London | recognisable | Palace, Big Ben and the Eye placed right; facades too clean |
| Rome | recognisable | Colosseum framed as in the photo; Oppio slope reads as lawn |
| Venice | recognisable | Canal and Salute right; grassy banks where there are fondamenta |
| Seoul | stylised | No Gwanghwamun gate model; square reads as a park |

Round ultra-p8, 2026-11-03 (Ultra pass, Phases 5–8):
- Captures, Ultra preset, local golden hour, clear summer:
  - Paris, New York, Tokyo: `visual-plan/reviews/ultra-p7f-2026-11-02/`.
  - Stockholm, London: `ultra-p8a-2026-11-02/`.
  - Banff, Seoul: `ultra-p8b-2026-11-02/`.
  - Venice: `ultra-p8d-2026-11-02/`.
  - Big Sur, Monaco, Rome: `ultra-p8h-2026-11-03/`.
  - Dubai: `ultra-p8i-2026-11-03/`, after the low-rise height fix.
  - Alps: `ultra-p8g-2026-11-02/`, shot in winter (no summer Ultra capture yet).
- Rater: Claude (agent pre-rating).

| preset | grade | change since r4 | biggest remaining tell |
|---|---|---|---|
| Paris | recognisable | ↑ terrace paving bare | Dry basins, no fountains; empty terrace (no people) |
| Alps | recognisable | — | (Winter shot.) Snowy peaks and lake right; valley roofs read as dots |
| Banff | recognisable | ↑ hotel model | Mount Rundle reads as a rounded green hill, no rock faces |
| Big Sur | recognisable | ↑ camera moved | Hillsides read as smooth grass; no rock faces under the arch, no surf at the beach |
| Tokyo | stylised | ↑ zebra crossings, screens | Screens only on some tall fronts, none in the opening frame; no crowd; plaza patches still read as lawn; crossings short, not the diagonal scramble |
| New York | recognisable | far towers windowed | Water too cyan; backlit sun glare |
| Stockholm | recognisable | ↑ Riddarholmen spire, cliff eye | Gamla stan reads as low generic blocks; foreground waterfront blocks sit in the frame |
| Monaco | recognisable | ↑ marina boats, harbour carved | Yachts generic and unevenly spread; vantage lower than the photo; no Casino terraces |
| Dubai | recognisable | Burj Y-plan | Desert and lagoon ground drape as green and blue patches |
| London | recognisable | ↑ bridge arches | Palace reads flat and dark from the low eye; backlit golden shot; bridge is plain stone, not green-and-red iron |
| Rome | recognisable | ↑ tufts off the paving | Two tufts left on unmapped dark ground; no stone pines framing the Colosseum |
| Venice | recognisable | ↑ exposed water-class bank and adjacent unmapped slope use land shading | Salute only a speck down the canal; some foreground terrain remains green and the bank geometry slopes into the canal; modern block in the foreground. The submerged bed retains its previous colour; see `venice-bank-before` and `venice-bank-r2` captures. |
| Seoul | recognisable | ↑ gate modelled, camera moved | Gate small and dark at 240 m; plaza is bare paving and lawns, no columns |

Round nyc-r1, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r1-2026-11-03/`, Ultra, clear summer, 08:00 local.
- Agent pre-rating: recognisable; human gate pending. Morning light removes the direct backlight, but blue foamy water and warm blocky towers remain the main tells. This capture predates the Oculus integration.

Round nyc-r2 / nyc-r3, 2026-11-03 (New York hero work in progress):
- Captures: `visual-plan/reviews/nyc-r2-2026-11-03/` and `nyc-r3-2026-11-03/` (Ultra, clear summer, 08:00 local).
- Agent pre-rating: recognisable; human gate pending. Waterfront railing and bridge are present; r3 water is grey-green with reduced foam. Warm blocky skyline and pale near-tree polygons remain prominent tells.

Round sf-r6, 2026-11-03 (San Francisco hero pass, `.agents/plans/2026-11-03-san-francisco-hero.md`):
- Captures: `visual-plan/reviews/sf-r6-2026-11-03/` (Ultra, local golden hour, clear summer) and
  `sf-r6-fog-2026-11-03/` (WMO 45).
- Rater: Claude (agent pre-rating).

| preset | grade | change | biggest remaining tell |
|---|---|---|---|
| San Francisco | recognisable | new preset | No street trees on Hyde St (4 mapped); Alcatraz a green lump under the far drape |

San Francisco's fabric now comes from the following, each with its test:
- Data rows and district circles (`sf_stucco`, `sf_prewar`, `sf_chinatown`, the district cue in `BuildingEra`).
- Painted bays and cornices on painted fronts (`FacadeRelief.oriel_paint`, `StreetFront._cornice`, `_garage`).
- Sidewalk paving from `sidewalk` tags (`GroundMaterial._sidewalks`).
- Kerb widths measured between mapped sidewalks (`RoadWidths`).
- Parked cars (`ParkedCars`, desktop Ultra).
- Cable-car beds and slots (`RailBuilder`, `cable_tram` / `electrified=no` trams).
- Pacific-coast trees (`TreeSpecies`, `dry_coast`).
- A marine layer in coastal fog (`MarineLayer`).

The generic parts apply wherever their data occurs.

Round ts-r3, 2026-11-11 (Tokyo and Seoul hero pass, `.agents/plans/2026-11-11-tokyo-seoul-hero.md`):
- Captures: `visual-plan/reviews/tokyo-seoul-r3-2026-11-11/` (local golden hour, noon and night, clear summer;
  r2 in `tokyo-seoul-r2-2026-11-11/` also has the roof views).
- Rater: Claude (agent pre-rating).

| preset | grade | change since ultra-p8 | biggest remaining tell |
|---|---|---|---|
| Tokyo | recognisable | ↑ zakkyo sign columns and boards, QFRONT poster screen, Scramble Square / Hikarie / Stream / 109 models, utility poles and cables | No crowd; the eye stands on a bare station roof deck; neighbours of QFRONT carry no screens |
| Seoul | recognisable | ↑ Gyeongbokgung behind the gate, Sejong and Yi statues, officetels and towers by tag | Gate still small at 240 m; square paving reads uniform grey; the core gate stands about 10 m off its OSM outline |

Tokyo's and Seoul's fabric now comes from the following, each with its test:
- Data rows, district circles and per-city rules (`ArchitectureCitiesEastAsia`; architecture_test).
- Slab-end block numbers, per-storey sign boards and full-height sign columns (`AsiaFronts`; asia_fronts_test).
- Concrete utility poles and cables on JP and KR side streets (`UtilityPoles`; utility_poles_test).
- The `tokyo_seoul` landmark batch (tokyo_seoul_landmarks_test).

Cameras moved after rating (`ultra-p8j-2026-11-03/`; candidates were shot with the new
`--looks=` option): Big Sur from the hillside east of the bridge's north end (30 m up, 200°), Seoul 120 m
up the plaza axis, Stockholm held at 32 m ASL on the Mariaberget cliff (the smoothed DEM put it at the
waterfront road).

Big screens (`StreetFront._screen`, desktop Ultra): a poster panel (up to 18 m wide) above the third storey on
the longest street front of tall commercial buildings in the `tokyo`, `tokyo_tower` and `hong_kong` styles
(profile key `screens`, 0.5–0.7), from a procedural 8-poster atlas, lit day and night like an LED wall
(`street_screens_test`). One shows on a tower in `ultra-p8p-2026-11-03/` (earlier run, south view); the
nearest buildings to the preset eye roll none, so the opening frame is unchanged.

Westminster Bridge was a flat slab: `RoadBuilder` drew every bridge as a 0.9 m plank with parapets. `BridgeArches`
(all tiers) now adds piers every ~32 m, arched spandrel openings and a soffit to any deck with 45+ m of water
under it (`bridge_arches_test`; `ultra-p8n-2026-11-03/london_vantage.jpg`). It applies to every long river
crossing, not just London; short bridges stay slabs.

Port Hercule's pontoons (`man_made=pier`, `floating=yes`) were mapped but never read. `MarinaBuilder` (desktop
Ultra) now draws their decks and moors motor yachts and sailboats (7–29 m) stern-to along both sides, 120
boats in Monaco (`marina_test`). Monaco's detected sea level is −66 m ASL (the DEM's sea floor), so its harbour
is flat terrain at sea level with the satellite photo's blue sea on it, and `water_at` is 0 there; berths
count as wet on terrain within 5 m of the pier's height that no building or road covers. Close up it reads
as a marina (`ultra-p8m-2026-11-03/`), but from the preset eye 550 m away the main basin is still mostly the
photo's boats. A look from over the basin (`--looks`) showed why: the harbour was a terraced slope of terrain
(the smoothed DEM reads quay height, +3 m, across the basin, above the 0.5 m sea plane) with the photo's sea
painted on it, so berths there failed the 2.5 m terrain spread rule. Fixed at the source: `leisure=marina`
polygons (Port Hercule is one relation) are now `water` land cover, so `GroundTruth` carves the basin and the
sea shows (`osm_test`; `ultra-p9a-2026-11-03/`). (An earlier version of this note blamed the water plane
sitting at −66 m ASL: that is `GroundTruth.water_level_m`, which only my `water_at` berth check read; the
sea plane itself is drawn at true 0 m.) The map query gained piers (`QUERY_MARK` q5): cached places refetch once.

Marked crossings were mapped but invisible: Shibuya's `footway=crossing` ways are rank 0, so they drew at
depth layer 2, under the carriageway's 4, with no markings anyway. They now get their own "crossing" finish
(at least 4 m wide), a depth layer above every carriageway and zebra bars (`RoadSurface.crossing_material`,
`crossing_test`; every tier, since road markings are on all of them). `ultra-p8l-2026-11-03/`.

Grass tufts (`GroundCover`) grew on mapped squares and footpaths: `VegetationMask` marks them `ROAD_EDGE`
only, which the cover never checked, so the Trocadéro terrace (a square mapped over a grass polygon) wore
tufts. Fixed (`render_upgrade_test`; 199 of 2,498 test tufts landed on a square and a footpath before);
`ultra-p8k-2026-11-03/` shows Paris bare.

Found while rating: Dubai's curved wall at the camera was an untagged mall block that inherited the
neighbouring towers' median height (61 m). Low-rise uses now cap an inferred height at four storeys
(`BuildingHeights.LOW_RISE_USES`).


Round Helsinki/Espoo R8 summer / R9 January, 2026-11-03:
- Captures and validation: [hero review](../visual-plan/reviews/helsinki-espoo-hero-2026-11-03/README.md).
- Rater: agent pre-rating; human gate pending. Photographic target remains open.

| preset | grade | change | biggest remaining tell |
|---|---|---|---|
| Helsinki, summer | recognisable | Finland districts, landmarks, Baltic water, corrected coastal DEM registration | Bright simplified waterfront facades and quay edges |
| Helsinki, winter | recognisable | January 8.75° sun, snow and partial fast ice | Procedural shoreline/ice transition; excessive colourfulness against winter reference |
| Espoo, summer | recognisable | Tapiola preset, Keskustorni, modernist fabric, calm pool | Simplified surrounding blocks and pool perimeter |
| Espoo, winter | recognisable | January 8.69° sun and snowy pool/streets | Winter saturation and brightness exceed the reference; coarse bank geometry |


Helsinki/Espoo roof-metal refinement, 2026-11-03 (shared G-5):
- [Summer/winter captures, material gallery and validation](../visual-plan/reviews/helsinki-espoo-roof-metals-2026-11-03/README.md).
- Agent pre-ratings only; human gate pending. New copper patina, painted sheet metal and standing folds; no photographic claim.

| preset | grade | change | biggest remaining tell |
|---|---|---|---|
| Helsinki, summer | recognisable | Patina and painted sheet finishes replace clay/slate surrogates | Mapped ships now lofted hulls (passenger/yacht/liner models, pending re-capture); oversized foreground mass masks Uspenski; bright opening |
| Helsinki, winter | recognisable | Metal roofs retain existing snow overlay; 8.75° sun | Simplified facades, ship masses and excessive colourfulness against winter reference |
| Espoo, summer | recognisable | Nordic pitched defaults now use sheet metal | Coarse pool perimeter and repetitive facade detail |
| Espoo, winter | recognisable | Metal/snow compatibility verified; 8.69° sun | Pool banks and winter brightness/saturation differ from reference |

Helsinki/Espoo harbour refinement, 2026-11-03 (shared G-6):
- [Summer/winter views, budgets and validation](../visual-plan/reviews/helsinki-espoo-harbour-2026-11-03/README.md).
- Agent pre-ratings; human gate pending. Regional quay stone, bollards, alongside dressing and mapped vessel hulls are verified. Photographic target remains open.

| preset | grade | change | biggest remaining tell |
|---|---|---|---|
| Helsinki, summer | recognisable | Mapped hull/deckhouse and quay bollards; wheel clearance retained | Yellow Enso office masks Uspenski; marina boats now lofted yachts, sailboats and day boats (pending re-capture) |
| Helsinki, winter | recognisable | Vessel decks retain snow; local water datum verified | Bright, colourful winter waterfront and simplified boat silhouettes |
| Espoo, summer | recognisable | Harbour dressing correctly excluded from ornamental pool | Coarse pool banks and repetitive surrounding masses |
| Espoo, winter | recognisable | Pool exclusion retained; 8.69° sun | Winter tone and pool perimeter still differ from reference |

Helsinki/Espoo Mint and Enso refinement, 2026-11-03:
- [Summer/winter views, ground probe, budgets and validation](../visual-plan/reviews/helsinki-espoo-mint-enso-2026-11-03/README.md).
- Agent pre-ratings; human gate pending. Source-backed Mint dimensions and the Enso office's inherited pale marble are visible; photographic target remains open.

| preset | grade | change | biggest remaining tell |
|---|---|---|---|
| Helsinki, summer | recognisable | Mint reduced to two storeys; Enso office renders pale | Office still masks Uspenski; repetitive windows and simplified boats |
| Helsinki, winter | recognisable | Mint and office corrections retain snow | Bright snow, colourful water and procedural facades |
| Espoo, summer | recognisable | Fresh control after facade changes | Coarse pool banks and repetitive surrounding masses |
| Espoo, winter | recognisable | Fresh control at 8.69° sun | Winter brightness and pool edge differ from reference |

Keilaniemi, Tapiola and Lauttasaari, 2026-11-12 (landmark search views, summer noon, 21 June):
- Captures: `visual-plan/reviews/west-metro-2026-11-12/` and the Finago recolour in `west-metro-r2-2026-11-12/`.
- Agent pre-ratings; human gate pending. Eight OSM-outline landmarks (`LandmarkRegistryWestMetro`), a Keilaniemi Espoo zone row and Lauttasaari/Vattuniemi districts; sources in docs/espoo-landmark-sources.md and docs/helsinki-landmark-sources.md.

| view | grade | change | biggest remaining tell |
|---|---|---|---|
| Keilaniemi (Finago Tower) | recognisable | Finago Tower's white piers and KONE's dark glass at OSM heights on the shore; Keilalampi glass cone | Opening eye stands in shore forest, towers small in frame; Life Science Center and Portti stay generic |
| Tapiola (Cultural Centre) | recognisable | Cultural Centre wings and hall block beside Keskustorni and the pool; Mäntytorni and hip-flask houses | Cultural Centre cladding and hall heights are estimates; the demolished swimming hall still extrudes from OSM |
| Lauttasaari (church) | recognisable from above | 61 m bell tower marks the island; 1950s functionalist district fabric | Ground opening lands in trees; church halls and manor colours are estimates |

Niittykumpu, 2026-11-12 (landmark search views, summer noon, 21 June):
- Captures: `visual-plan/reviews/niittykumpu-2026-11-12/` and the lighter tower bands in `niittykumpu-r2-2026-11-12/`.
- Agent pre-ratings; human gate pending. Five OSM-outline landmarks and a 0.6 km `espoo_modern` metro-centre district; sources in docs/espoo-landmark-sources.md.

| view | grade | change | biggest remaining tell |
|---|---|---|---|
| Niittykumpu (Niittyhuippu) | recognisable | 90 m white Niittyhuippu and Niittytori rise from the Niitty mall podium; dark Niittytaival tower; modern blocks round the station | Opening eye stands on the Länsiväylä ramps with the tower distant; tower balcony and facade detail are estimates |
| Olari (church) | recognisable from above | Red-brick Olari Church with pilasters and slit windows beside the metro-centre towers | Opening eye stands over a neighbouring roof; heights estimated |

Inner Helsinki and the western islands, 2026-11-12 (model sheets, four bearings, flat ground):
- Captures: `visual-plan/reviews/helsinki-areas-2026-11-12/` (model sheets from `tools/capture_landmarks.gd`, not in-world landmark views).
- Agent pre-ratings; human gate pending; in-world views not yet captured. 19 OSM-outline landmarks (`LandmarkRegistryInnerHelsinki`, `LandmarkRegistryWestMetro`), split Katajanokka, Torkkelinmäki, Ruoholahti, Sompasaari and Munkkiniemen puistotie districts, and a new `helsinki_villa` era for Vanha Munkkiniemi, Kuusisaari and Lehtisaari; sources in docs/helsinki-landmark-sources.md and docs/espoo-landmark-sources.md.

| area | grade | change | biggest remaining tell |
|---|---|---|---|
| Katajanokka | recognisable (model) | Aalto's white marble Enso HQ replaces the generic block in front of Uspenski; Merikasarmi's ochre Empire wings and porticos; brick ferry terminal | Casino and the prison hotel stay generic; Merikasarmi storey heights estimated |
| Kallio | recognisable (model) | Linnanmäki's timber coaster and Kingi, Raketti and Panoraama towers replace generic 53–75 m boxes; Kallio Library; Siren office slab | Coaster track profile estimated; Taiga coaster not modelled |
| Jätkäsaari / Ruoholahti | recognisable (model) | Clarion's chequered towers; the Salmisaari chimneys (114 m, 150 m) replace generic tall boxes; the Cable Factory | Second Clarion tower height estimated from a photograph; West Terminal 2 roof simplified |
| Munkkiniemi / Kuusisaari / Lehtisaari | recognisable at close range (model) | Aalto House, Studio Aalto, Didrichsen, Villa Gyllenberg; villa and functionalist district fabric | Small low buildings among trees; Kalastajatorppa and the manor not modelled |
| Otaniemi | recognisable (model) | Aalto's campus: the 1971 water tower (twelve-sided tank on blade columns), Otahalli and his library (entrance canopy, framed window bands) beside the existing main building; Dipoli's leaning copper fascias over timber-framed glass and boulder heaps; the chapel; the Väre block (with the School of Business and A Bloc) as brick-and-silver-glass blocks, tall brick blocks, dark glass halls and the black stair wedge from the OSM parts; the metro station's main entrance canopy and its Tietotie pavilion; the power plant's 75 m chimney replaces a generic box | The 1971 Otahalli annexe stays generic; Väre's block heights and Dipoli's boulder layout are estimates |

Round sto-r1, 2026-11-03 (Stockholm hero work in progress):
- Captures: `visual-plan/reviews/sto-r1-2026-11-03/` and `sto-r1-winter-2026-11-03/`, Ultra, clear golden hour. The images predate the Tyska kyrkan and street/bridge changes.
- Agent pre-rating: recognisable; human gate pending. Foreground road and waterfront blocks obscure the cliff view, the island shoreline is too bare, and moored ships are absent. See the review README for capture limitations.

Round realism-v3-safe-group, 2026-11-03 (interrupted Ultra review):
- Rater: Codex, provisional visual pre-rating; the human review gate remains open.
- [Images and recovered statistics](../visual-plan/reviews/realism-v3-safe-group-2026-11-03/). Fifteen presets completed; the Metal renderer stalled during Espoo, before any Espoo shot, and the six controls were not reached. The tree changed during the run, so these images are not a frozen-build acceptance set. The recovered JPEG statistics are approximate and lack the original camera and draw-call metadata.
- All completed locations include golden-hour, noon and night opening frames; ratings below judge the golden-hour reference sheets. The new temperate-sea adjustment postdates New York's shot.

| preset | provisional grade | principal difference from reference |
|---|---|---|
| Paris | recognisable | Tower and gardens align, but the terrace, fountains and street life are sparse. |
| Alps | recognisable | Valley and lakes read correctly; foreground trees and mountain tones remain simplified. |
| Banff | stylised | Hotel is very small and the distinctive mountain face reads as a smooth green ridge. |
| Big Sur | recognisable | Arch and coast are visible; hills and shoreline are smooth and lack rocky surf detail. |
| Tokyo | stylised | Crossing layout is visible, but the key signage, crowds and surrounding frontage are missing. |
| New York | recognisable | Skyline reads as Manhattan; the water is overly turquoise and bright, and towers remain simplified. |
| Stockholm | recognisable | Waterfront and spires read as the city; the foreground and quays differ considerably. |
| Monaco | stylised | The harbour layout is broad but the densely packed marina and distinctive waterfront are not legible. |
| Dubai | recognisable | The Burj is on axis; foreground buildings and road terrain are simplified. |
| London | recognisable | Westminster and bridge identify the scene; the river colour and building massing remain simplified. |
| Rome | recognisable | Colosseum is clear; the foreground, vegetation and material detail differ. |
| Venice | stylised | Modern foreground block and absent/obscured Salute dominate the canal view. |
| Seoul | stylised | The gate is too small and dark, with the plaza's prominent features and people absent. |
| San Francisco | recognisable | Steep street and bay read correctly; facades, trees and cable tracks are simplified. |
| Helsinki | recognisable | Cathedral and waterfront read correctly; ships and waterfront buildings are simplified. |
| Espoo | not rated in this run | Renderer stalled before the first frame; the earlier Helsinki/Espoo round remains separate evidence. |

Recovered golden-frame statistics flag New York's luma, saturation and colourfulness above its reference range; Venice's luma is below and saturation above. These measures are diagnostic, not proof of recognition or photographic quality. Paris, Tokyo and New York have not reached the photographic target in this review.

Round sto-r2, 2026-11-03 (Stockholm hero work in progress):
- Capture: `visual-plan/reviews/sto-r2-2026-11-03/`, Ultra, clear summer golden hour. This predates the newest landmark batch and marina placement fix.
- Agent pre-rating: recognisable; human gate pending. The mapped ship has a hull and the foreground lamellas are reduced, but the pale angular island shore, simplified city blocks and foreground road remain visible. Candidate forward eyes were off the mapped path and do not establish a valid preset.

Round sto-r3, 2026-11-03 (Stockholm hero work in progress):
- Captures: `visual-plan/reviews/sto-r3-2026-11-03/` and `visual-plan/reviews/sto-r3-winter-2026-11-03/`, Ultra, golden hour. Agent pre-rating: recognisable; human gate pending.
- City Hall and the island spire read clearly, but the pale angular bank, simplified blocks and exposed foreground road still fall short of the photographic target. On-path trials trade the foreground obstruction for the loss of City Hall. Concurrent changes limit direct comparison between these captures; see the review.

Round sto-r4, 2026-11-03 (Stockholm hero work in progress):
- Capture: `visual-plan/reviews/sto-r4-2026-11-03/`, Ultra summer golden hour. Agent pre-rating: recognisable; human gate pending.
- Island buildings and waterfront remain simplified, and the road and grass dominate the foreground. The 206 s time to view exceeds the 150 s target under concurrent load; an isolated timing remains necessary.

Round sto-r6, 2026-11-20 (Stockholm hero loop S-6):
- Captures: `visual-plan/reviews/sto-r6-2026-11-20/` (golden, noon, night, 15 looks) with `sto-r6-redo-`, `sto-r6-winter-` and `sto-r6-cold-` folders beside it, Ultra. Agent pre-rating: recognisable; human gate pending.
- The Monteliusvägen eye now stands on the cliff top (38 m over Riddarfjärden, hero-plan B-3 closed). Remaining tells: pale flat Riddarholmen and Slussen banks, a tilted paved slab and smooth grass instead of granite on the cliffs, a repeated moored-ship model, dark olive render walls, no moving water traffic. Cold-cache time to view 23 s against the 150 s target, on a machine with other Godot processes running.

Rounds sto-r7…sto-r19-final, 2026-11-20 & 2026-11-23 (Stockholm hero acceptance + bridge regression fix):
- Captures: `visual-plan/reviews/sto-r10-final-2026-11-20/`, `sto-r14-final-2026-11-20/`, `sto-r16-final-2026-11-20/`, `sto-r18-final-2026-11-20/`, and `sto-r19-final-2026-11-20/` (Ultra golden, noon, night, 7 open-space looks) plus 77-landmark reference comparison pages in `visual-plan/captures/sto_final/compare/`.
- **Human gate (AC-18): accepted as `photographic` by the user on 2026-11-20 at `WorldCache.BUILD_VERSION = 318`** (`PLAN_Stockholm_super_realistic.md:194`). Closed across Rounds 7–12: Riddarholmen ashlar quay wall & flattened plinth, Slussen battered ashlar lock panes/gates/sills & island caps, Mariaberget switchback granite stair, six distinct Mälaren moored hull models with rigging/sails & fenders, travelling Riddarfjärden/Saltsjön route boats, twin-track Djurgårdslinjen tram with catenary, warmed Stockholm plaster palette & stone glare cap, translucent Sergels torg/Kulturhuset sky-band glass, smooth-bronze Gustav II Adolf equestrian statue, ornate Strömbron balustrades/candelabra,gaussian night street-lamp bloom, and thread-safe native `ShoreClassifier` (`std::vector<uint8_t>`).
- Follow-up verification (2026-11-23, `BUILD_VERSION = 321`): `sto_bridge_stromsbron.gd` pier bands clamped to `y >= 0.0` and fitted mesh trimmed below 18,000 triangles (`bridge_specs_test`, `stockholm_bridges_test`, `stockholm_hero_landmarks_test`, `world_cache_test`, `screenshot_test` all PASS).

Round nyc-r4, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r4-2026-11-03/`, Ultra, clear summer, 08:00 local. Agent pre-rating: recognisable; human gate pending.
- Grey-green water and the bridge read clearly, but the skyline remains simplified, nearby foliage has pale angular patches, and the promenade has repeated benches. The truncated OSM response omitted mapped furniture, so this round does not validate it. See the review README for timings and reference limitations.

Round nyc-r5, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r5-2026-11-03-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Eye-centred map furniture arrived before the server ran out of memory later in the response. The near foliage and simplified skyline still fall short of photographic quality. See the review README for counts, timing and limits.

Round nyc-r6, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r6-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Planned construction towers are excluded. The simplified skyline and pale close foliage still fall short of photographic quality; the Oculus alignment change postdates this capture. The review README records timing and incomplete-data limitations.

Round nyc-r7, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r7-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The bridge close-up shows the suspension model; the proposed Oculus eye landed inside a building and does not validate the model. Skyline simplification and foliage artifacts remain. See the review README for timing and data limitations.

Round nyc-r8, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r8-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- One Manhattan Square now reads as glass behind the bridge. Elevated close views show the Oculus replacement, though one eye intersects a facade. The skyline, trees and foreground remain stylized; see the review README for measurement limits.

Round nyc-r9, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r9-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Eye-centred tree LOD removes the large nearby billboard triangles, but introduces very dark foliage and strong shadows over the waterfront. The skyline and water remain simplified. See the review README for measurement limits.

Round nyc-r10, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r10-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Disabling received leaf shadows did not resolve the dark canopy and made pale patches more visible; the experiment was reverted. See the review README for reference limitations.

Round nyc-r11, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r11-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- A terminal-based procedural ferry appears as a small orange silhouette near Whitehall; close validation is pending. The canopy remains too dark and the skyline simplified.

Round nyc-r12, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r12-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- An elevated view confirms the orange ferry, with shoreline geometry intruding near the vessel. A wider water-clearance search postdates this capture. The skyline and dark canopy still fall short of photographic quality.

Round nyc-r13, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r13-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- A wider water-clearance search places the orange ferry clear of the shoreline intrusion visible in r12. Shoreline geometry, the simplified skyline and dark canopy still fall short of photographic quality.

Round nyc-r14, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r14-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Mapped copper survives the distant roof path, and elevated views show historic stepped and pointed masses. Individual hero crown detailing remains unverified; the skyline and foreground are still stylized.

Round nyc-r15, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r15-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- Explicitly historic prewar towers retain their selected facade material at distance. Their individual crown details remain unverified; the skyline, water and dark canopy are still stylized.

Round nyc-r16, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r16-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The mapped 70 Pine observatory parts use a source-backed glass default, although this view is too distant to judge the detail. The Municipal Building's subsequent figure is not in this capture; the scene remains stylized.

Round nyc-r17, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r17-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The Municipal Building's mapped crown and small gold Civic Fame replacement are visible in the elevated close view. Its figure is simplified, and the 70 Pine lantern remains too small to assess. Skyline, shoreline and tree canopy are still stylized.

Round nyc-r18, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r18-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The Manhattan Bridge approach reaches the portal, but its opening is rectangular in this capture. A curved opening was added afterwards and requires visual review; skyline, shoreline and canopy remain stylized.

Round nyc-r19, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r19-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The entrance opening is curved; gaps above it prompted a subsequent masonry infill. The bridge, skyline and foreground remain simplified.

Round nyc-r20, 2026-11-03 (New York hero work in progress):
- Capture: `visual-plan/reviews/nyc-r20-2026-11-03/`, Ultra, clear summer, 08:00. Agent pre-rating: recognisable; human gate pending.
- The entrance has a continuous curved arch connected to the approach. The model and scene remain simplified, including a broad plain deck and conspicuous nearby vegetation.

### Shared shoreline candidate, 2026-11-03

The shared water-domain and surface-patch implementation has been exercised
on Venice, Amsterdam, Paris, Stockholm, Monaco, Helsinki, Dubai and Big Sur at
all four presets. Opening and tilted-bank captures are in
[`shoreline-accepted-2026-11-03`](../visual-plan/reviews/shoreline-accepted-2026-11-03/).
The name identifies the capture run; **visual acceptance remains open**. These
images predate the latest paved-area batching optimization, which has a native
versus script geometry regression test. Some tilted-bank images do not place
the actual bank close to the camera; additional inspection views are needed.

The 32 captured models reported zero `patch_failure` diagnostics. Big Sur
had no hard-bank segments at any preset. Stockholm retained its dry peninsula
and islands, and Dubai retained mapped lawn and water domains. Venice's water
uses its own water material and bed colour; its foreground still has a sloped
or green land-side stretch that lacks sufficient mapped support for inferred
masonry under the selected policy. The Venice visual gate therefore fails;
adding a city-specific quay or widening the evidence thresholds would conceal
the missing evidence rather than satisfy this plan.

An intermediate same-machine frozen-input comparison is recorded in the
[cases and budget table](../visual-plan/reviews/shoreline-accepted-2026-11-03/measurements-v3.md).
It measured 558.13 s → 520.93 s total cold geometry time across 32 cases
(−6.7%), and static peak 2414.2 → 2421.6 MiB (+0.3%). The matching process
peak resident sizes were 4671225856 → 4362649600 bytes (−6.6%). Sixteen
individual gates failed, including per-case relative-time regressions and Fast
Helsinki/Amsterdam exceeding 20 s; those two also exceeded that cold budget in
the control. Concurrent local builds can affect wall-clock measurements, and
the frozen control incorporates the earlier pre-shoreline integration while
other shared workspace features evolved. A clean, final same-source rerun is
still required; the later native paved-area and terrain packing optimizations
have not yet been measured across the full matrix.

A subsequent isolated Helsinki Fast stage profile reduced total time from
22.67 s to 4.68 s after indexing repeated tram-to-road coverage queries.
This is a diagnostic measurement, not a replacement for the full budget
comparison. Focused Venice and Helsinki edge views are in
[`shoreline-edge-check-2026-11-03`](../visual-plan/reviews/shoreline-edge-check-2026-11-03/);
the remaining cities and presets still need equivalent close-up review.

The offline shoreline fixture, OSM, scenery, terrain-scale, coastal-water,
coastal-DEM, render-upgrade, world-cache-key, serial/parallel, far-city,
landmark-placement and smoke checks passed on the frozen validation copy. A
windowed world-cache test passed the cold/revisit comparison, and the windowed
screenshot test completed. The class-size check passed at 806/1000 lines for
the largest script. Re-run the relevant checks against the final workspace
and final native libraries before considering the implementation accepted.


### Central Park, 2026-11-14

Provisional agent rating: **recognisable** from the park and from Top of the Rock; the human gate stays open.
Review: `visual-plan/reviews/central-park-final-2026-11-14/` and `central-park-final2-2026-11-14/` (Bethesda vantage, Midtown north from 270 m over 50th Street, both New York presets).

| Change | Result |
| --- | --- |
| Preset | `central_park` on Bethesda Terrace's lower terrace, bundled (detailed, rings, POI, far, transit, horizon). |
| Landmarks | Bethesda Fountain, Bow Bridge, Gapstow Bridge, Belvedere Castle and Cleopatra's Needle (`LandmarkCentralPark`), ahead of the towers in the icon budget. |
| Trees | `nyc_park` mix in a Central Park zone (elm form, oak, plane, maple, linden, honey locust); OSM `ulmus` now draws in the elm form everywhere. |
| Rock | Mapped bare rock of park size stands up as low schist mounds (`RockOutcrops`). |
| Far canopy | `FarCanopy` plants trees where the far drape shows canopy past the detailed extent, each its species' impostor (the near trees' crossed cards) in stands of varied size; Central Park reads as woodland with open lawns from Midtown (80000 trees on Ultra, `far-trees-2026-11-14`). |
| Fixes | Ramps and viaducts no longer climb to a skyscraper's or a bridge's top (`LandmarkRoofs`): the frames over Grand Central, the FDR by 55 Water Street and the FDR under the Brooklyn Bridge's Manhattan end are gone. Slender tower setbacks keep their facade. |

The Lake had dropped to sea level: OSM maps its coves (Bank Rock Bay) as natural=bay, which counted as tidal and pulled the whole lake down 11 m into a trench of grassy cones. A bare bay is now tidal only where it joins real sea water (`OsmTags.bay`, `ShoreDomains._merge_levels`), so park lakes keep their bank level. Cleopatra's Needle keeps a treeless clearing; from the Great Lawn the knoll's trees still hide it, as they do on site.

### New York skyline towers, 2026-11-14

Provisional agent rating: unchanged (**recognisable** on Ultra); the human gate stays open.
Review: `visual-plan/reviews/nyc-towers-2026-11-14/` (both presets, plus looks from the Hudson, Brooklyn Bridge Park, Central Park, the East River and Bryant Park).

| Change | Result |
| --- | --- |
| Spec towers | 98 `TowerSpec` rows (`NycTowerSpecs*`): Downtown 24, Midtown 47, West Side 11, Jersey City 8, Brooklyn and Queens 8. |
| Massing | Each tower's mapped OSM parts in its own frame; pyramid, hip and dome crowns from `roof:height`, `roof:colour` and `roof:material`. |
| Finishes | Set by hand per tower; new `pink_granite`, `white_granite`, `warm_concrete`, `waffle_bronze`, `red_granite`, `steinway_terracotta`, plus `ceramic_rods` and `black_glass` glazing. |
| Newer than the snapshots | 99 Hudson, Brooklyn Tower, Trump World Tower, One Court Square and Skyline Tower use parts from live OSM (2026-11-14). |
| Budget | `LandmarkSites.MAX_SKYLINE_BY_PRESET` 12/30/60/110, ranked by height over distance; the icons keep their slots. |

Still generic: anonymous residential slabs, and towers whose look is only massing at preset distance (Hudson Yards from the river). The Lipstick Building is mapped only in part and stays generic.

### New York towers, 2026-11-10

Provisional agent rating: **recognisable** on Ultra, with towers no longer flat prisms; the human gate stays open.
Reviews: `visual-plan/reviews/nyc-p0-2026-11-10/` (before) and `nyc-signoff-2026-11-10/` (after, from the committed tree), with `before_after.jpg` for the sign-off. The Midtown "before" there is a pinned camera, since the preset did not exist yet.

| Change | Result |
| --- | --- |
| Window scale | Raised parts count their own storeys; distant and far glass tile by real bay and storey. |
| Blank walls | Curtain walls and a building's own lower parts no longer leave blank firewall bands. |
| Tower types | `NycTowerLooks` picks one of nine finishes; `TowerLooks` gives other cities a regional glazing mix. |
| Massing and tops | 1916 setback profile, plant floors, penthouses and parapets scaled to height. |
| Icons | 22 new `SkyKit` towers; Empire State about 70k to 12.4k triangles. |
| Cold load | Ultra New York build 9.2 s before, 9.5 s after. |

Midtown is bundled (five `new_york_midtown_*` layers, about 7 MB gzipped) and opens offline. `BundledOsm.MAX_BYTES` rose from 32 to 48 MB for its 39 MB far layer.

### New York continuation, 2026-11-04

Provisional rating: **recognisable** on Ultra; photographic target not met and human gate pending.
Opening retained at 08:00 and moved from 298° to 295° after six bearing comparisons.
[Combined review, tests and remaining gates](../visual-plan/reviews/nyc-validation-2026-11-04/README.md).

| Round | Conditions | Review / remaining tell |
| --- | --- | --- |
| r21 | Clear summer, 08:00 | Baseline from partial detailed data; generic orange towers. |
| r22 | Clear summer, 08:00 | Complete detailed data, distant facade correction and refined Manhattan entrance; approach and Oculus still under review. |
| r23 | Clear summer, 08:00 | Glazed Oculus sides and bridge vegetation clearance; clear-morning reference subset avoids treating overcast saturation as the opening target. |
| r24 | Overcast summer, 08:00 | Colourfulness 0.0665 against overcast refs 0.026–0.039; photographic target still unmet. |
| r25 | Clear summer, 08:00 | Exact-ID edge-part completion and duplicate far-building suppression; 200 Vesey retains eight parts. |
| r26 | Clear summer, 08:00 | Pale Woolworth cladding, mapped crown ornament, street Oculus and Pier 1 rail/bench checked. Vantage colourfulness 0.1290 vs clear-morning photo 0.1780; single-photo range is diagnostic. |
| r27 | Clear summer, 08:00 | Whitehall steel/glass defaults and separate Brooklyn Tower look; shoreline and terminal remain simplified. |
| r28 | Clear summer, 08:00 | Targeted crown inspection. Fine landmark and skyline fidelity remain below the photographic goal. |

Healthy cached opening 14 s, parallel generation 7.840 s, far city 530 ms / 276,362 triangles.
The isolated 53 s cold opening had HTTP 403 fallbacks and missing far towers, so it cannot certify
complete-data cold loading within 150 s. A complete live detailed response separately took 43.73 s.
Fast/High captures and both windowed cache/screenshot checks pass; the focused Turku scorecard
retains its previously recorded DEM (a) failure. A verified golden-hour Pier 1 Commons photo and
an acceptable in-world subway entrance close-up remain open.


r29/r30 crown detail follow-up: close views exposed a full-tower storey count on raised one-metre
parts. Storeys now follow the part's occupied height, and glazed parts shed inherited masonry relief.
[The r30 close view](../visual-plan/reviews/nyc-r30-lantern-2026-11-04/new_york_look0.jpg) resolves
70 Pine's glass lantern; focused crown, building-fabric and architecture tests pass. Overall rating
remains recognisable; this does not close the photographic or cold-network gates.

[r31 isolated cold capture](../visual-plan/reviews/nyc-r31-cold-2026-11-04/README.md):
after removing the whitelist-only mirror, complete detailed/far responses
produced the opening in 90 s. Generation took 8.176 s; far-city network/parse
took 73.792 s. The optional ring and POIs failed, keeping the strict all-layer
cold-load gate open. The skyline remains recognisable; photographic quality
and human approval remain pending.

[r32/r33 High Street inspection](../visual-plan/reviews/nyc-r33-high-street-2026-11-04/README.md):
three close views show mapped entrance node `219785432` on dry pavement.
Diffused white/green globes and vertical railing infill improve the kit;
street-furniture checks pass. The separate subway-view requirement is now
evidenced. A true descending terrain opening remains unimplemented; this
does not improve the overall provisional grade beyond recognisable.

r34/r35 continuation: an isolated cold opening took 103 s, with 5.945 s
generation, but missed far-city geometry and POIs. The subway globes now
meet their support posts; a true descending stairwell remains open. A
licensed 06:39 golden-hour skyline photo at nearby Fulton Ferry Landing is
documented as context; it does not establish the requested Pier 1 reference.

### Helsinki round hel-r6 (2026-11-20)

Frames in `visual-plan/reviews/hel-r6-final-2026-11-20/` (Ultra, twelve open-space eyes plus the
opening look at golden hour, noon and night). Agent pre-rating only; the "photographic" call is the
user's. Landmark models rebuilt in the same pass (about 120 types, refs in
`visual-plan/refs/landmarks/`, per-group sections in `docs/helsinki-landmark-sources.md`).

- **Reads as Helsinki:** the Senate Square view (cathedral on its steps, Government Palace and
  University ochre fronts), the harbour from the water (Uspenski beside the Enso-Gutzeit block,
  moored boats), Rautatientori (station tower and arch in granite) and the night view.
- **Biggest remaining tell:** black masses in the drone view (top right, probably the
  Kalasatama glass towers, and a ship hull at left), then window grids that stay flat black
  rectangles, then bright, near-white plaza paving on the Market Square side.
- **Performance (Helsinki, `tools/perf_baseline.gd`, one run per preset, 60 s fly, cold cache;
  against 2026-11-15):** cold 10.7 / 16.0 / 19.6 s on Fast / High / Ultra (was 10.9 / 25.6 / 26.7);
  cached 1.4 / 1.5 / 2.0 s (was 3.8 / 4.2 / 4.5); fly p95 9.3 / 9.5 / 26.2 ms (was 9.4 / 21.3 /
  23.4), fly max 62 / 83 / 64 ms (was 235 / 265 / 204); mesh nodes 1417 / 2211 / 3500 (was 1279 /
  2071 / 3183); peak 5.2 / 8.0 / 12.2 GB (was 4.8 / 7.6 / 12.5). Ultra save 40.0 s against 29.8 s
  is the one number that got worse. The fly runs differ in length (60 s against 90 s), so p95 is
  indicative only.

### Turku round tku-r3 (2026-11-20)

Frames in `visual-plan/reviews/tku-r3-2026-11-20/` (Ultra, opening Aurajoki quay view at golden hour,
noon, and night plus 5 open-space `--looks`: Kauppatori, Aurajoki quay, Qwensel/City Hall, TYKS
Hospital Area, and Föri/Kakola). Agent pre-rating only; the "photographic" call is the user's.
78 bespoke Turku landmarks, 12 bridges, 180 `TurkuNotable` rows, 26,540 enriched `turku_lod2`
buildings, 23 districts, Aurajoki restaurant ships, Viking/Silja ferries, animated Föri ferry, and
City of Turku 2025 z19 orthophoto (`docs/turku-landmark-sources.md`, 13 city refs in
`visual-plan/refs/turku/`, 34 landmark ref sets, 38 side-by-side compare sheets). The earlier DEM
check (a) failure is closed against bare-earth `GroundModel` `"mml"` (`fidelity_scorecard_test.gd`
PASS).

- **Reads as Turku:** Kauppatori with Taivassalo red-granite paving and rebuilt Sokos Wiklund
  (travertine podium, Prisma banner, Walo glass crown), red *punamulta* Qwensel House beside
  yellow-ochre Turku City Hall, moored *jokilaivat* restaurant ships along Aurajoki, TYKS T-sairaala
  linked by its glazed skybridge to Majakkasairaala, and the animated orange-and-white Föri crossing
  below Kakolanmäki.
- **Remaining tells:** minor near-foreground linden trunk in `turku_look1` and vessel edge in
  `turku_look2`; human photographic gate (AC-18) pending user sign-off.
- **Performance (Turku Ultra, Preset 3, `WorldCache.BUILD_VERSION = 311`):** cold Ultra build **13 s**
  (`8.505 s` parallel generation; 2,625 real + 9,701 far buildings, 38 landmarks in frame) against the
  ≤ 150 s Ultra budget; cached reopen **64–96 ms**; memory **7.4 GB** at build completion / **10.1 GB**
  active render (63.6 GB headroom on T3). All Turku headless suites and windowed `world_cache_test` /
  `screenshot_test` pass.

### Miami & Miami Beach round miami-r1 (2026-11-23)

Frames in `visual-plan/reviews/miami-r1-2026-11-23/` and `miami-r1-night-2026-11-23/` (Ultra, 20 frozen
open-space eyes across Centres A–F: Downtown/Bayfront `A1..A6`, Brickell `B1..B4`, MacArthur Causeway
`M1..M2`, South Beach & Ocean Drive `C1..C5`, Mid-Beach `D1`, Vizcaya `E1`, Biltmore `F1`; `stats.json`
0 flags), plus 51 4-view studio sheets (`visual-plan/captures/miami_r1/` and `miami_r1_night/`) and baked
preset thumbnails (`assets/preset_thumbs/miami.jpg`, `miami_beach.jpg`). Agent pre-rating only; the
"photographic" call (AC-18) is the user's.
51 bespoke Miami landmarks, 114 `MiamiTowerSpecs` skyline towers, 13 `BridgeSpecsNorthAmerica` rows
(incl. bespoke Brickell Ave bascule + late-2026 4-arch I-395 Signature Bridge), 37 `MiamiDecoFronts`
Ocean Drive 3D relief fronts (`DecoFront`), 129 `MiamiNotable` rows, 12 `ArchitectureCitiesFlorida` rows
across 28 districts, concrete Metromover/Metrorail guideways (`RailViaductLook`), 8 Miami tree species
(`TreeSpecies`), `BeachDressing` (pale sand, sea-oat dunes, 8 lifeguard towers, resort umbrellas, Lummus
wall), Biscayne/Atlantic/Government Cut/Miami River colour boxes, PortMiami cruise berths, Miami transit
liveries, and Miami Tower cyan night glow (`docs/miami-landmark-sources.md`).

- **Reads as Miami & Miami Beach:** turquoise Biscayne Bay with Waldorf Astoria, One Thousand Museum
  exoskeleton, Kaseya Center, Skyviews wheel, Aston Martin sail, One Miami twin balcony towers, and cyan
  Miami Tower night wash; pale Miami Beach sand with turquoise umbrellas, sea-oat dunes, Lummus Park
  palms, Ocean Drive Art Deco eyebrows/awnings/neon, South Pointe Pier light poles, Fontainebleau's curved
  Chateau slab beside Eden Roc, Vizcaya with its Stone Barge and anchored yachts, and Biltmore's Giralda
  tower over the Coral Gables fairway.
- **Remaining tells:** eye `A5` (`25.78000, -80.18850, 3 m`) stands inside a Biscayne Blvd median tree
  crown; an OSM clubhouse mass in front of the Biltmore sits outside its `clear_m`; human photographic
  gate (AC-18) pending user sign-off.
- **Performance (`tools/perf_baseline.gd`, before `miami-perf-before-2026-11-23` vs after
  `miami-perf-after-2026-11-23`, 20 s fly, macOS Apple M5 Ultra Forward+):**
  - High (`p2`) `miami`: cold 11.83 → **16.42 s**, build 7.29 → **10.10 s**, cached 0.84 → **1.15 s**,
    settle p95 8.7 → **9.3 ms**, fly p95 **15.7 ms**, meshes 881 → **1,420**, peak 5,069 → **6,372 MB**.
  - High (`p2`) `miami_beach`: cold 6.24 → **10.99 s**, build 4.08 → **5.02 s**, cached 0.67 → **0.97 s**,
    settle p95 8.9 → **9.4 ms**, fly p95 **14.8 ms**, meshes 843 → **1,223**, peak 6,035 → **6,591 MB**.
  - Ultra (`p3`) `miami`: cold 12.16 → **22.91 s** (≤ 150 s budget), settle p95 9.0 → **10.3 ms**,
    fly p95 **12.2 ms**, peak 9,348 → **7,342 MB**.
  - Ultra (`p3`) `miami_beach`: cold 7.76 → **32.37 s** (≤ 150 s budget), settle p95 9.5 → **9.8 ms**,
    fly p95 **10.0 ms**, peak 10,287 → **7,261 MB**.

### Helsinki round hel-r10 (2026-11-23)

Frames in `visual-plan/reviews/hel-r10-2026-11-23/` (`--preset=3 --look_ahead=100`, golden hour, noon,
night, and 12 validated open-space `--looks`) and `visual-plan/reviews/hel-r10-winter-2026-11-23/`
(`--season=winter --weather=73`), plus day/night studio & reference comparison pages for 22 upgraded
or newly added landmarks in `visual-plan/captures/{hel_r2_upgrades,hel_r2_night}/` (`BUILD_VERSION = 321`).
Agent pre-rating: **recognisable** (approaching photographic on central views); **the human
"photographic" gate (AC-18) remains open for user sign-off**.

- **Upgrades since `hel-r6`:** street reflection probes hidden above 50 m AGL and re-captured at
  each `--looks` eye (`stk-f2`), white-lit gull normals from above (`hel-smear-after`), 3 new Market
  Square / Esplanadi landmarks (`swedish_embassy_helsinki`, `supreme_court_helsinki`, `runeberg_statue`),
  18 rebuilt/upgraded models (`kiasma`, `bank_of_finland`, `amos_rex`, `kamppi_chapel`, `lasipalatsi`
  24 m clock tower + Bio Rex neon, `old_market_hall_helsinki`, `market_square_helsinki`, `havis_amanda`,
  `uspenski_cathedral`, `kappeli` + Espa Stage, `helsinki_ice_hall`, `linnanmaki`, `suomenlinna_dry_dock`,
  `lonna_island`, `kustaanmiekka_bastions`, `hotel_kalastajatorppa`, `kallio_library`,
  `lauttasaari_manor`), night `FLOOD_META` across 19 previously unlit landmarks, 25 verified
  `HelsinkiNotable` central OSM buildings, `"helsinki"` in `FAR_DISTRICT_CITIES`, and 16 regional/inner
  landmark Commons CC/PD reference sets populated/topped up.
- **Biggest remaining tell:** procedural window grids on uncurated background blocks outside the
  25 `HelsinkiNotable` facades and bright winter snow/paving contrast on broad open squares; human
  photographic gate (AC-18) pending user review.

### Turku round tku-r4 & tku-perf-final (2026-11-23)

Frames in `visual-plan/reviews/tku-r4-2026-11-23/` (`--preset=3`, golden hour, noon, night, and all
13 open-space `--looks` matching `visual-plan/refs/turku/`) and
`visual-plan/reviews/tku-r4-winter-2026-11-23/` (`--season=winter --weather=73`), studio & 14-page
compare sheets for all 79 Turku landmarks in `visual-plan/captures/{tku_t3_complete,tku_t3_night}/`,
and multi-preset performance baseline in `visual-plan/reviews/tku-perf-final-2026-11-23/`
(`BUILD_VERSION = 321`). Agent pre-rating: **recognisable**; **the human "photographic" gate (AC-18)
remains open for user sign-off**.

- **Upgrades since `tku-r3`:** `meyer_gantry_cranes` (twin 105 m & 97.5 m Perno Goliath cranes on
  Turku's western skyline, 79 bespoke landmarks total), `Auransilta` / `Kirjastosilta` / `Teatterisilta`
  fitted to `BridgeSpec` + `BridgeCamber.apply` with `y >= 0.0` footings and Array-typed `FLOOD_META`
  (plus `FtKakolaFunicular`), `"turku"` in `FAR_DISTRICT_CITIES` for 12 km horizon district continuity,
  and 44 newly populated Wikimedia Commons CC/PD landmark reference sets (`78/79` documented sets on
  disk; `chappe_art_house` lacks a free-licensed exterior photo under Finnish FOP).
- **Remaining tells:** near-foreground riverside linden trunks in `turku_look5`–`look7` along the
  narrow Aurajoki promenade; human photographic gate (AC-18) pending user sign-off.
- **Performance (`tools/perf_baseline.gd`, 20 s fly, isolated empty cache per preset):**
  - **Fast (`p0`):** cold **19.7 s** (≤ 20 s budget), cached **7.3 s**, save **0.13 s**, fly p95 **9.0 ms** / max **145.4 ms**, 1,853 mesh nodes, peak **2,037 MB**.
  - **High (`p2`):** cold **23.8 s** (≤ 45–75 s budget), cached **7.3 s**, save **0.15 s**, fly p95 **9.2 ms** / max **129.6 ms**, 2,511 mesh nodes, peak **3,265 MB**.
  - **Ultra (`p3`):** cold **23.6 s** (≤ 150 s cap), cached **7.2 s** (≤ 8 s budget), save **0.20 s**, fly p95 **15.9 ms** / max **186.3 ms**, 3,717 mesh nodes, peak **5,395 MB**.
  All headless Nordic suites and windowed `world_cache_test` / `screenshot_test` pass.

### Bangkok rounds `bangkok-r0` → `bangkok-r1` → `bangkok-r2` (2026-11-23)

Frames in `visual-plan/reviews/bangkok-r0-2026-11-23/` (baseline), `bangkok-r1-2026-11-23-2026-11-23/` (old-town fabric),
`bangkok-r2-2026-11-23/` (City Hall plaza `13.75398, 100.50144`, `E1`–`E9`, golden/noon/night, Ultra), and
`bangkok-r2-river-2026-11-23/` (streamed Chao Phraya river world `13.7455, 100.4905`, `E10`–`E12`, golden/night, Ultra),
plus day/night 4-view studio & reference comparison pages for all 36 Bangkok landmarks, 4 river bridges, and 9 skyline
towers in `visual-plan/captures/{bk_bk2,bk_bk2_night,bk_bk456,bk_bk456_night,bk_bk11,bk_bk11_night}/` (`BUILD_VERSION = 322`).
Agent pre-rating: **recognisable** (approaching photographic on Ratchadamnoen, Bamrung Mueang, Sanam Luang, and Chao Phraya
river panoramas); **the human "photographic" gate (AC-18) remains open for user sign-off**.

- **Delivered:** 36 bespoke/upgraded Bangkok landmarks (`LandmarkRegistryThailandBangkok` + 4 upgraded existing heroes:
  `grand_palace_bangkok`, `wat_pho`, `wat_arun`, `hua_lamphong`), 9 `BkTowerSpecs` skyline towers (`State Tower` gold dome,
  `ICONSIAM` Magnolias, `Baiyoke II`, `Sathorn Unique`, etc.), 4 river bridges (bespoke `Rama VIII` 160 m inverted-Y pylon,
  emerald `Memorial Bridge`, planted `Phra Pok Klao` Sky Park, `Phra Pinklao`) + generic `BangkokCanalBridges` for khlongs,
  16 districts & 11 Bangkok style rows (`bangkok_oldtown`, `bangkok_civic`, `bangkok_ratchadamnoen`, `bangkok_wat`,
  `bangkok_khaosan`, `bangkok_shophouse`, `bangkok_yaowarat`, `bangkok_timber`, `bangkok_mall`, `bangkok_hotel_river`,
  `bangkok_condo`), `16/20 m` Rattanakosin height caps, 433 Thai tiered-roof temple halls (`building=temple`), 64 mapped
  `man_made=stupa` chedis (`StupaBuilder`), silty olive-brown Chao Phraya & khlong water with masonry floodwalls, floating
  pitched-roof piers, and Thai river vessels (`longtail`, `chao_phraya_express`, `cross_river_ferry`, `saen_saep_boat`,
  `dinner_cruise`, `rice_barge`), `bangkok_mix` broadleaf street trees (`<= 4%` palms) & open Sanam Luang lawn with tamarind
  ring, humid tropical sky/haze, Thai fleet (`TukTukModel`, 5 Bangkok taxi liveries, 5 BMTA/Thai Smile bus liveries,
  square TH concrete utility poles with buried-cable exclusions on Ratchadamnoen & Grand Palace, `BangkokStreetLife`),
  and night `FLOOD_META` + Yaowarat/Khao San neon (`docs/bangkok-landmark-sources.md`).
- **Remaining tells:** plaza eye `E2` (`13.75398, 100.50144`) sits close to City Hall's west wall (open plaza centre is
  `13.7536, 100.5011`); canal eyes `E5`/`E6` at `1.7 m` sit low near water/bridge decks; human photographic gate (AC-18)
  pending user sign-off.
- **Performance (`tools/build_bench.gd`, parallel, Apple M5 Ultra, Forward+):**
  - **High (`bangkok_p2`):** ground **590 ms**, world **7.87 s** (`1,490` children; ≤ 45–75 s budget).
  - **Ultra (`bangkok_p3`):** ground **587 ms**, world **9.31 s** (`2,771` children; ≤ 150 s cap).
  All Bangkok, bridge, water, vegetation, vehicle, architecture, and host-policy headless suites, `tools/check_class_size.sh`
  (max `996/1000`), and windowed `world_cache_test` / `screenshot_test` pass.

### London rounds `london-r0` → `london-r1` → `london-r2` (2026-11-24)

Frames in `visual-plan/reviews/london-r0-2026-11-23/` (baseline), `london-r1-2026-11-24/` (initial batch), and
`london-r2-2026-11-24/` (Queen's Walk preset vantage `51.5018, -0.1196`, golden/night + Westminster Bridge, Golden
Jubilee Bridge, and roof-height Thames panorama, Ultra), plus day/night 4-view studio sheets in
`visual-plan/captures/{ln_lm_base,ln_lm_base_night,ln_lm_r1,ln_lm_r1_night}/`.
Agent pre-rating: **recognisable** (major leap across Westminster, South Bank, City skyline, Thames bridges, and
night lighting; human "photographic" gate remains open for user sign-off).

- **Delivered:** 65 London landmarks verified in `tests/london_landmarks_test.gd` — 10 upgraded existing heroes
  (`big_ben` warmed limestone, glowing Ayrton Light & 10 paired night uplights; `london_eye` LED rim glow;
  `buckingham_palace` + Queen Victoria Memorial; `shard` crown uplights & aviation beacon; `st_mary_axe` night glow;
  plus `tower_bridge`, `st_pauls`, `westminster_abbey`, `tower_of_london`, `waterloo_station`), 30 new bespoke
  landmarks & Thames bridges (`county_hall`, `westminster_bridge` 7-arch Parliament-green Gothic iron,
  `hungerford_golden_jubilee`, `millennium_bridge`, `portcullis_house`, `whitehall_horse_guards`, `whitehall_court`,
  `admiralty_arch`, `trafalgar_square`, `royal_festival_hall`, `national_theatre` fixing OSM `h=6.5`,
  `somerset_house` fixing `lv=2`, `oxo_tower`, `methodist_central_hall`, `lambeth_palace`, `cleopatras_needle`,
  `tate_modern`, `shakespeares_globe`, `bank_junction`, `monument_london`, `lloyds_building`, `st_pancras_station`,
  `british_museum`, `westminster_cathedral`, `battersea_power_station`, `bt_tower`, `royal_albert_hall`,
  `natural_history_museum`, `marble_wellington_arches`, `o2_arena`), and 25 `LnTowerSpecs` skyline towers across the
  City of London (22 Bishopsgate, Leadenhall/Cheesegrater, Walkie-Talkie, Heron, Scalpel, 8 Bishopsgate, Tower 42,
  Willis, Barbican), South Bank/Nine Elms, and Canary Wharf (One Canada Square + flashing red beacon).
- **City fabric, river & transport:** expanded London districts (6 → 16) with new `london_portland` (Whitehall,
  Strand, Regent St) and `london_warehouse` (Southwark, Shad Thames, Clerkenwell) rows, added `"london"` to
  `CityDetail.CITIES`, tuned silty olive-brown tidal Thames water, blocked ocean cruise liners/ro-pax ferries from
  spawning upstream of Tower Bridge (`QuayMoorings` / `QuayFleet`), added the red double-decker London bus
  (`bus_double`), and added the London Underground `roundel` to UK `StreetFurniture`.
- **Verification:** `london_landmarks_test`, `landmark_lights_test`, `bridge_specs_test`, `bridge_select_test`,
  `architecture_test`, `city_detail_test`, `street_furniture_test`, `bus_stop_test`, `car_fleet_test`,
  `coastal_water_test`, `landmark_list_test`, `host_policy_test`, and `tools/check_class_size.sh` (996/1000) all pass.
