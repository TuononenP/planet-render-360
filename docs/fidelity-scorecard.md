# Fidelity Scorecard — Real-Location Fidelity Redesign

> Owner: role F (Validation) · Plan task: T0.2 · Date: 2026-10-28
> Purpose: the measurable ruler for "looks like the real place", used in Phase 8 (T8.1–T8.3).
> The visual target remains `visual-plan/PRD.md` AC-01…AC-18; this doc defines *how each AC is measured*.
> No AC is left unmapped — see §5.

Golden locations (same 5 as plan T0.1): Paris (48.8566, 2.3522) · Interlaken (46.6863, 7.8632) ·
Banff (51.1789, −115.5708) · Big Sur (36.2704, −121.8081) · Turku (60.4518, 22.2666).

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
  ≤ **8 m** in alpine/coastal terrain (Interlaken, Banff, Big Sur). The legacy-squash A/B mode
  (plan T1.3) is expected to fail; the comparison is recorded as evidence that true-metre wins.
- **Pre-Phase-1 note:** before T1.3 the heights are adaptively remapped, so (a) is recorded as
  *baseline-only* (values logged, no pass/fail) until the identity mapping lands.

### (b) Footprint-area agreement — buildings sit on their real outlines

- **Method:** sample 20 buildings per urban location (Paris, Turku; 10 for Interlaken/Banff/Big Sur
  where fewer exist) from OSM footprints inside the detailed extent, stratified near/mid/far.
  For each, compute `placed polygon area / OSM footprint area` (post-T4.1: true polygon overlap IoU;
  pre-T4.1: placed-AABB area vs. OSM polygon area as a proxy) and the centroid offset in metres.
- **Metric:** median area ratio and median centroid offset over the sample.
- **Pass (all tiers, post-T4.1):** median IoU ≥ **0.85** (urban) / ≥ 0.75 (rural); median centroid
  offset ≤ **2 m**. Pre-T4.1 proxy pass: median area ratio within **0.7–1.3** and offset ≤ 5 m.
- **Fail-closed rule:** a sampled OSM building with no rendered building within 10 m counts as IoU 0.

### (c) Height error vs. OSM height/levels — buildings rise to their real height

- **Method:** on the same sample as (b), where OSM carries `height` or `building:levels`
  (convert levels × regional floor height per T4.2, never a global default), compare rendered
  building height against it. Buildings with neither tag are excluded from the error stat but
  counted separately (coverage: % of sample with explicit height data).
- **Metric:** median absolute error in metres (or storeys where only levels exist).
- **Pass (all tiers):** median error ≤ **1 storey** (≈3 m); coverage is reported, not gated,
  except that a live Paris fetch must show ≥30% of buildings carrying explicit height/levels (T2.3).
- **Neighbour guard (PRD §4.2, automated in T4.2):** no non-landmark building >2.0× its neighbours'
  height unless OSM data says so — 0 violations per location.

### (d) Water/road presence — rivers, lakes, coasts, and streets exist where they should

- **Method (water):** for each location with real water (Paris/Seine, Interlaken/lakes, Big Sur/coast,
  Turku/archipelago; Banff/river), take 5 centreline/shoreline sample points from OSM water
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
| AC-12 | 3 tiers exist, F2 default, switch ≤2 s, 0 moves/shifts | **(f)** + automated tier-diff | Transform diff = 0 and hue ΔE ≤2% across a tier switch (T7.1 assert); switch timed ≤2 s; F2 confirmed default in settings |
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
| Banff (51.1789, −115.5708) | none | — | `no-reference — geometry-only scoring` |
| Big Sur (36.2704, −121.8081) | none | — | `no-reference — geometry-only scoring` |
| Turku (60.4518, 22.2666) | none | — | `no-reference — geometry-only scoring` |

Geometry-only locations are gated by checks (a–e) only; (f) is recorded as
`no-reference — geometry-only scoring` with the rater naming the closest available
comparison instead of a grade (see §3(f) and §6 report format `NO-REFERENCE`).
`visual-plan/baseline/2026-10-28/` captures are current-state renders, not reference
photos, and must never be scored against as references. Plan Open Q3 stays open:
adding a CC-licensed or user-provided photo for a listed location upgrades it to
full (f) scoring; the PRD §2 row and this table are updated together in that task.
