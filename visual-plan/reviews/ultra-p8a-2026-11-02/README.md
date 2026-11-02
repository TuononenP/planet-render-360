# Ultra review p6–p8 — 2026-11-02 (2K terrain, z18 imagery, street furniture, kerbs, landmarks)

Captures:
- `../ultra-p7f-2026-11-02/`: `--places=paris,new_york,tokyo --times=golden`.
- This folder: `--places=stockholm,new_york,london --times=golden,late`.
- `../ultra-p8b-2026-11-02/`: `--places=banff,seoul,dubai --times=golden,late`.

All at `--preset=3`. Earlier rounds of this pass are in `../ultra-p7c-2026-11-02/README.md`.

## Phase 6: desktop-Ultra assets

- **2K terrain layers:**
  - Lawn, rock, cliff, forest, gravel, sand and snow were downloaded at 2k from Poly Haven (CC0, 21 files,
    ≈75 MB, each verified as a 2048² JPEG).
  - `TerrainTextures` builds desktop Ultra's layer arrays at 2048 px from them. The arrays are
    block-compressed (BC1 albedo, BC3 normal + roughness), about 60 MB for the pair instead of about 400 MB
    raw.
  - Other tiers keep 1024 / 512.
- **z18 inner imagery:**
  - Desktop Ultra fetches a second 7×7 mosaic at z18 round the viewpoint (≈700 m in Paris) beside the main
    z17 mosaic.
  - It only sharpens the photo's fine detail (`hf`). The low-frequency class signal stays the main photo's,
    so ground classification is unchanged across tiers.
  - The UV is exact, not fitted: a z18 pixel is the main zoom's pixel × 2^dz. A world-space linear fit was
    off by up to 3.7 px, which is why it is computed this way (`satellite_inner_test`).
  - The first run fetched 147 z18 tiles (3 places × 49).
- **CC0 models → procedural kits.** The furniture, kerbs and decals are own-work, true-metre procedural
  meshes and textures (see the data register). Regional variants cost nothing, and nothing needs importing.
- **More looks on Ultra.** Five looks per era and kind instead of two, so Paris apartments show 4 distinct
  wall/roof/shutter looks instead of 2. Geometry picks are unchanged (`ultra_looks_test`, `lod_test` T7.2).

## Phase 7: street dressing (desktop Ultra)

- **OSM furniture:**
  - Benches, waste baskets, bollards, traffic signals and bus stops come from the detailed query, within
    450 m. That statement is printed last, so a server timeout drops it first.
  - Cached payloads predate it. Places get furniture nodes on their next live fetch and use the fill until
    then.
- **`StreetFurniture`:**
  - A signal node gets a pole on each kerb. A stop gets a shelter (`shelter=yes`) or a sign pole on its own
    kerb. A bench or bin mapped in the road moves to the kerb and faces it.
  - Regional kit:
    - North America: mast-arm signals and drum bins.
    - Japan, Korea, Taiwan: horizontal heads on arms.
    - UK and Ireland: black bins.
    - Netherlands: red-brown bollards.
    - Elsewhere: European post bins.
  - Unmapped places get a sparse fill: a bin every 70 m on lit urban streets (none in Japan), and signals
    where two main roads meet.
- **`KerbBuilder`:**
  - A 13 cm stone kerb on both edges of urban streets within 400 m. It sits over the painted kerb band and
    stops 9 m short of junctions.
  - Granite in Europe and most places, concrete in North America. The painted band on lower tiers follows
    the same colour.
- **Leaf litter decals** under mapped street trees within 250 m, thickest in autumn.
- (Earlier this pass: yellow centre lines, regional lamps, manhole and grate decals.)

## Phase 8: landmarks

- **New landmarks.** The other agent's regional batches already cover almost all of the plan's list. The
  one missing r4 tell was added: **Riddarholmen Church**.
  - Gothic brick nave, copper-domed royal chapels, polygonal choir, and the cast-iron openwork spire of 1841
    as X-braced lattice faces to 90 m.
  - It is in the regional tier, so Monteliusvägen still opens on City Hall, with Riddarholmen beside it as
    an extra.
  - Fitted to its OSM outline (62.7 × 39.9 m, nave 7.8° north of east): model ≈64.7 × 40.4 m, yaw −7.8°,
    centre on the outline's.
- **Night lamps.** Every hero's own "Lamp" part (bridge necklaces, lanterns, beacons) is now dark by day and
  1.4× brighter at night. Before, `LandmarkMaterials.lit` glowed at noon.
- **Eiffel sparkle.** 1,500 white billboard flashes over the iron for the first 5 minutes of each night
  hour, driven by the `city_hour` and `night_energy` that `CityLights` already sends.
- **Supertalls.** The Burj Khalifa and One WTC now glow a faint cool white from their own frame at night,
  like the lattice towers. Four ground spots cannot reach 828 m, and the real towers are lit by façade LEDs.
  `../ultra-p8c-2026-11-02/dubai_vantage_late.jpg` shows the Burj as a silver stepped silhouette; before, it
  was black.
- **Denser LOD0 on Ultra.** Every round landmark form (domes, drums, lathed towers: smooth lathes of 10+
  segments) takes twice the segments on desktop Ultra. The Salute goes from 233k to 325k vertices with the
  same true bounds. Faceted forms (square spires, octagons) keep their sides, and lower tiers are unchanged
  (`landmark_ultra_lod_test`, `lod_test`). Venice built in 128 s uncached (`../ultra-p8d-2026-11-02/`).
- Floodlights and lattice glow are in the earlier review.

## Seen

- **Stockholm (golden):**
  - Riddarholmen's openwork spire reads as a dark lattice beyond the water, right of City Hall's tower.
  - Red and green signal heads stand at the junction on the right.
- **Stockholm (late):** a clear night (stars and the Milky Way, no city deck, as it should be), with City
  Hall and Riddarholmen both floodlit.
- **Paris (golden close-up):** a green post bin on the Trocadéro terrace.
- **Banff:** the hotel stands in the vantage frame over the Bow River. **Seoul:** Gwanghwamun is the gate at
  the far end of the plaza under Bugaksan. Both reach their frames, as the plan asked.
- **Build times** at Ultra: 15–27 s per cached place. Stockholm took 57 s with fresh z18 tiles. That is
  inside the longer first build.

## Open

- **Ultra hero LOD0:** only the curve density is done. Per-landmark extra ornament (real mullions, tracery,
  cornices in geometry) is not. The other agent's `LandmarkShader` gives Ultra landmark surfaces weathering,
  ashlar coursing and rust. The Eiffel Tower's night-glow overrides keep its iron on the standard material,
  so it misses that shader.
- **Furniture from OSM:** needs a live refetch of a cached place to see mapped benches and signals instead of
  the fill.
- **Leaf litter:** added after these captures (`road_decals_test`), not yet seen in a render.
- From the earlier review: floodlight scallops on the Westminster river front.

## Resolved after these captures (`../ultra-p8e-2026-11-02/`)

- **Sparkle seen** (`paris_vantage_sparkle.jpg`, new `--times=sparkle`: a minute past the first full hour
  an hour after sunset). At first it was invisible: the 0.9 m flashes were under a pixel 1.4 km away. Now
  3000 flashes, each kept about 4 px wide at any distance, 30% lit per tick, scatter white over the gold
  tower.
- **`--times=night`** now falls back to 90 minutes after sunset when moonrise lands with the sun up. Paris
  and New York night shots are luma 0.03–0.07, where they were a grey 0.28 dusk.
- **The "palms" in New York** are broadleaf street trees with high crowns. In the backlit rain haze of
  `ultra-p7c` only the thin trunk and crown top showed. The p7f golden close-up reads correctly; NYC resolves
  to the temperate mix.
