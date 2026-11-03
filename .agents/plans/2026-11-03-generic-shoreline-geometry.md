# Generic shoreline geometry and urban waterfront fix

Replace the Venice shading workaround with one immutable shoreline model,
owned by GroundTruth and shared by terrain, water, banks, placement and cache.
Detailed terrain and its far-field boundary are in scope; remeshing the whole
far field is not. Use conservative inference, never city identity or imagery.

## Implementation and evidence

- [x] Add optional normalized `shore_structures` through OSM query, parser,
  fetcher and pipeline; preserve existing signals and old-payload defaults.
- [x] Build indexed water domains, dry-side level estimates and bank evidence
  before carving; retain island holes and directed coastlines.
- [x] Store canonical local surface triangles and query those same triangles.
  Local planar subdivision handles all edge crossings; native earcut and an
  exact hole-aware script fallback are available for polygon triangulation.
- [x] Replace hard-bank station boxes with connected vertical wall faces;
  generate water from the same subdivision and limit aprons to natural banks.
- [x] Implement terrain LOD stitching, placement-consumer integration,
  cancellation and cache persistence; validate the offline and cache fixtures.
- [ ] Confirm visual acceptance of the candidate without the Venice shader
  heuristic; the foreground has an unsupported natural/unknown stretch.
- [ ] Complete final bank close-ups and repeat the 32-case budgets after the
  latest native optimizations. The intermediate run has per-case time failures;
  see the fidelity scorecard and its linked measurement table.

## Classification and geometry contract

Explicit quay/retaining-wall/embankment geometry within 3 m with compatible
direction wins. Explicit grass, parks, beaches, wetlands and other natural
cover veto inferred masonry. Otherwise require mapped paving within 8 m and a
building footprint within 20 m on the land side, with agreement at two of
three stations over a 10 m section. Record the supporting features and reason.

Preserve a pre-carve dry sampler. Water levels are estimated once, preserving
tidal/sea datum and river profiles; nearby bounding boxes alone never join
independent lakes. Hard-bank tops use the median of at least three valid
dry-side samples at 2, 5, 10 and 20 m, excluding water and building footprints.
Uncertain shores remain natural and their reasons stay inspectable.

Clip/subdivide local cells against actual water boundaries and holes. Use
1 cm shared coordinate quantization and shoreline stations no more than 2 m
apart. Keep the wet bed at least 2 m below its local water and wall bottoms
0.6 m below water. Extent closure edges never generate walls. Corrected
surface patches and queries must agree within 0.05 m at every quality level.
Failed patches retain old geometry and report diagnostics; acceptance permits
zero patch failures in the validation set. Builders only read finalized state.

## Verification gates

- Offline fixtures: straight/diagonal/curved and reversed shores, concave
  corners, holes, narrow canals, adjacent bodies and different water levels,
  tidal/coastal domains, ponds, extent boundaries, explicit/inferred banks,
  natural-cover vetoes, missing data, cancellation, cache and native fallback.
- No exposed terrain inside mapped water, except islands/intentional
  structures; no cracks, overlapping wall runs or invented extent walls.
- Parser, polygon, terrain, scenery, coast, cache and serial/parallel checks.
  Headless Godot runs stay in the background; windowed runs use godot_bg.sh
  with --position 4000,4000 and are batched.
- Venice, Amsterdam, Paris, Stockholm, Monaco, Helsinki, Dubai and Big Sur at
  all four presets, opening view and bank close-ups. Preserve Dubai lawns,
  Stockholm islands and natural Big Sur coast; retain canal colour.
- Compare frozen inputs on the same machine: added build time <=20%, peak
  memory <=25%, and existing cold-build budget. Baseline checkout is frozen
  in /tmp/pr360-shoreline-baseline; capture inputs in /tmp/pr360-shore-inputs.

## Delivery

Persist finalized state and rebuild indexes on cache load; revise query/world
versions and content fingerprints. Update world-model contracts and fidelity
scorecard with captures, measured budgets and any failures. Keep each class
under 1000 lines. No commit or push unless explicitly requested.
