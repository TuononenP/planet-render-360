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
| AC-12 | 3 tiers exist, F2 default, switch ≤2 s, 0 moves/shifts | **(f)** + automated tier-diff | Transform diff = 0 and hue ΔE ≤2% across a tier switch (T7.1 assert); switch timed ≤2 s; F2 confirmed default in settings. Relaxed 2026-11-01 for desktop Ultra only: it may add decorative extras (shader facades with interiors and per-pane night lights, relief / trim / roof detail to 700 m) that lower tiers never build; real buildings, roads and landmarks still never move (lod_test footprint checks) |
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
| Turku (60.4518, 22.2666) | none | — | `no-reference — geometry-only scoring` |

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
