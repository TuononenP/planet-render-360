# Trafalgar Square, Trevi Fountain & Helsinki 3D+ Reality Mesh Monuments — Super-Realistic Plan

> **Goal:** Elevate **Trafalgar Square** (`trafalgar_square`, London) and **Trevi Fountain** (`trevi_fountain`, Rome) to architectural-visualization realism using bespoke Blender 5.3 sculpted `.glb` hero components + faithful classical/Baroque geometry, and build a reusable **Helsinki 3D+ City Reality Mesh** (`CC-BY-4.0`, `kartta.hel.fi/3d/mesh/Helsinki_2024`) extraction pipeline to harvest, clean, and ship realistic central Helsinki monuments directly from the city's open-access photogrammetry mesh.

## Tracker

Status legend: `[ ]` pending · `[~]` in progress · `[x]` done

| ID | Phase / Workstream | Deliverable | Verification | Status |
|---|---|---|---|---|
| **P0.1** | Shared infrastructure | Textured-GLB & multi-material asset loader (`RealityMeshKit` + `SculptureKit` directory support for `assets/landmarks/{trafalgar,trevi,helsinki_3d}/`) | Headless `landmark_test.gd` + `landmark_shader_test.gd` | `[x]` |
| **TS-1** | Trafalgar Square — Blender Hero Sculpt Pipeline | `tools/build_trafalgar_assets.py` → `assets/landmarks/trafalgar/*.glb` (true reclining Landseer bronze lion, Admiral Nelson naval statue, fluted bronze Corinthian capital, 4 Trafalgar battle bas-relief panels, Lutyens fountain dolphin/mermaid/triton groups, George IV equestrian statue, corner bronze lamp lanterns) | Blender headless build + triangle/bounds audit (`<= 45k` tris total) | `[x]` |
| **TS-2** | Trafalgar Square — Nelson's Column & Plaza Terraces | Fluted Dartmoor granite shaft, moulded Attic base, stepped octagonal/square plinth, bronze battle reliefs, 4 curved Landseer lion plinths, stepped Yorkstone square floor, Fourth Plinth & 3 sibling corner plinths (`ln_trafalgar_square.gd`) | `london_landmarks_test.gd` (`51.6 m`, `<= 150k` tris) | `[x]` |
| **TS-3** | Trafalgar Square — Lutyens Twin Fountains | Four-lobed cruciform/octagonal Portland-granite basins, tiered scalloped bronze bowls, McMillan & Wheeler dolphin/mermaid/triton sculptures, multi-ring converging `FountainKit` water plumes + central spire jets | `fountain_water_test.gd` + close-up capture | `[x]` |
| **TS-4** | Trafalgar Square — William Wilkins National Gallery | Dedicated `ln_trafalgar_gallery.gd`: North Terrace balustraded retaining wall & twin grand staircases, double-row octastyle Corinthian portico + sculpted pediment, rusticated ground storey, recessed arched/pedimented windows & blind niches, full roof balustrade, authentic ribbed central drum & lantern dome, Victorian arched pepper-pot turrets | `london_landmarks_test.gd` + `check_class_size.sh` | `[x]` |
| **TS-5** | Trafalgar Square — Lighting & Visual Verification | Warm architectural floodlighting + Victorian globe lamps (`LandmarkLights`), `1920×1200` lossless PNG multi-angle day + dusk captures (Landseer lion close-up, Lutyens fountain, National Gallery facade, full square overview) | All London tests + visual sign-off | `[x]` |
| **TF-1** | Trevi Fountain — Blender Baroque Sculpt Pipeline | `tools/build_trevi_assets.py` → `assets/landmarks/trevi/*.glb` (true semicircular coffered exedra apse & rosette half-dome, sculpted Baroque travertine cliff & waterfall grotto reef, pedestal-trimmed Calm vs. Rough Sea horses, scalloped cockleshell chariot, Agrippa & Aqua Virgo bas-relief panels, Clement XII papal coat of arms with tiara/keys & reclining winged Fames, corner lion/mask spouts) | Blender headless build + triangle/bounds audit (`<= 60k` tris total) | `[x]` |
| **TF-2** | Trevi Fountain — Palazzo Poli Facade Rebuild | Extract Trevi into dedicated `scripts/generation/landmarks/south_europe/landmark_rome_trevi.gd` (`< 450` lines): Baroque rusticated basement merging into reef, fluted Corinthian pilasters & capitals, recessed piano-nobile windows with scrolled corbels, balustrades & alternating triangular/segmental pediments, carved Latin attic frieze (`CLEMENS XII PONT MAX...`), full balustrade + 4 Season statues | `landmark_test.gd` (`26.3 m`, `2..16` parts) + `check_class_size.sh` | `[x]` |
| **TF-3** | Trevi Fountain — Basin, Steps & Aligned Cascades | Sunken Piazza di Trevi curved travertine seating steps, curved-cheek basin rim with carved stone bollards & wrought-iron chains, sculpted reef lips seamlessly mated to `FountainKit` turquoise water, multi-tier waterfall sheets, arched spouts & plunge foam (zero clipping/floating/buried statues) | `fountain_water_test.gd` + `landmark_shader_test.gd` | `[x]` |
| **TF-4** | Trevi Fountain — Lighting & Visual Verification | Warm golden Roman uplighting on exedra, Oceanus, horses & turquoise water glow; `1920×1200` day + dusk close-up & piazza-wide captures | All Rome/fountain tests + visual sign-off | `[x]` |
| **H3D-1** | Helsinki 3D+ — Live 3D Tiles Harvester | `tools/fetch_helsinki_3d_tiles.py`: walks `https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json` (fallback `Helsinki_2017/tileset.json`), intersects WGS84 `region` / ECEF `sphere` bounding volumes for target lat/lon/radius, downloads leaf `.b3dm` tiles into `build/helsinki_3d_cache/`, strips `b3dm` header + applies `RTC_CENTER` & tile transforms into local ENU metres | Verified tile fetch for Senate Square, Esplanadi, Market Square, Stockmann & Kiasma | `[x]` |
| **H3D-2** | Helsinki 3D+ — Blender Photogrammetry Cleanup & Bake Pipeline | `tools/extract_helsinki_3d_monuments.py` + `tools/helsinki_3d_monuments.json`: crops cylindrical/box ROI around each monument, strips ground skirt/trees/pedestrians via connected-component + elevation filter, caps bottom, decimates to `4k–18k` tris, de-lights baked harsh shadows & repacks single `512–1024 px` atlas (Path A) OR exports clean geometry for hybrid bronze/granite `LandmarkMaterials` (Path B) → `assets/landmarks/helsinki_3d/*.glb` | Blender batch run + mesh manifold/size/atlas audit | `[x]` |
| **H3D-3** | Helsinki 3D+ — Upgrade Existing Central Monuments | Wire extracted models into **Alexander II** (`landmark_fh_senate_front.gd`), **J. L. Runeberg** (`landmark_fh_runeberg_statue.gd`), **Keisarinnankivi** (`landmark_fh_market_square.gd`), and **Aleksis Kivi** (`landmark_fh_national_theatre.gd`) using hybrid crisp granite bases + extracted sculptures | `helsinki_hero_landmarks_test.gd` + `landmark_test.gd` | `[x]` |
| **H3D-4** | Helsinki 3D+ — Add New Central Helsinki Monuments | Register & build standalone files in `landmark_fh_centre_models.gd` for **Three Smiths (*Kolmen sepän patsas*)**, **Marshal Mannerheim Equestrian Statue**, **Eino Leino Statue**, **Topelius (*Taru ja totuus*)**, **Elias Lönnrot Monument**, and **Paasikivi Monument** | Registry lookup, clearance, height & PBR tests | `[x]` |
| **H3D-5** | Helsinki 3D+ — Attribution, Docs & Visual Verification | Update `docs/data-source-register.md`, `docs/helsinki-landmark-sources.md` and `assets/landmarks/helsinki_3d/README.md` with `© City of Helsinki, 3D city model (CC BY 4.0)`; `1920×1200` eye-level verification captures across Senate Square, Esplanadi, Market Square, Stockmann & Kiasma | `host_policy_test.gd`, `helsinki_hero_landmarks_test.gd`, visual sign-off | `[x]` |

---

## Context & Diagnosis

### Why Trafalgar Square Currently Falls Short (`ln_trafalgar_square.gd`, 130 lines)
Current implementation gaps identified from code inspection and `1920×1200` captures (`trafalgar_lion_closeup.png`):
1. **Nelson's Column & Landseer Lions:**
   - The 46 m shaft is an unfluted 16-segment frustum with a plain box-and-cone capital instead of a **fluted Dartmoor granite Corinthian column** with moulded Attic base rings and an ornate bronze acanthus-and-volute capital.
   - The pedestal carries 4 plain dark-green boxes instead of **sculpted bronze Trafalgar battle bas-relief plaques** (Cape St Vincent, Nile, Copenhagen, Death of Nelson).
   - The 4 corner lions currently reuse a *seated heraldic* lion scan (`Lion.stl` via `couchant_lion.glb`), whereas Sir Edwin Landseer's iconic Trafalgar lions are **6 m reclining (couchant) bronze lions** with massive forepaws stretched straight forward along stepped curved granite plinths.
   - Admiral Nelson atop the column reuses the generic draped female *Zenobia* mesh (`classical_draped.glb`) instead of a 19th-century naval officer silhouette (bicorne hat, boat cloak, empty right sleeve, rope coil).
2. **National Gallery (`_national_gallery`, 34 lines):**
   - Currently a bare `134 × 17.4 × 28 m` grey slab with 18 floating flat blue glass rectangles (`lm.box("Glass", ...)`) stuck to the front.
   - Missing William Wilkins' defining architecture: the raised **North Terrace balustraded retaining wall & twin grand staircases**, recessed **double-row octastyle Corinthian portico** with steps and tympanum sculpture, rusticated basement storey, recessed pedimented windows & alternating blind arched niches, continuous roof balustrade, **ribbed cylindrical central drum & lantern dome**, and **Victorian arched-drum pepper-pot turrets**.
3. **Lutyens Twin Fountains (`_fountains`, 34 lines):**
   - Currently plain circular bowls with generic Tritons, missing Sir Edwin Lutyens' **four-lobed scalloped cruciform Portland-stone basins**, tiered cascading fluted bronze bowls, McMillan & Wheeler's sculpted **dolphins, mermaids, and tritons**, and dense multi-ring converging water arcs + central spire jets.
4. **Square Terraces, Plinths & Street Furniture:**
   - Completely missing the **Yorkstone stepped plaza deck**, the **Fourth Plinth** (NW) and its 3 sibling corner plinths (**George IV equestrian** NE, **Havelock** SE, **Napier** SW), and the iconic **Trafalgar Square Victorian bronze lantern standards**.

### Why Trevi Fountain Still Falls Short (`landmark_rome_civic.gd`)
Current implementation gaps identified from `trevi_piazza_eye.png` and `trevi_oceanus_closeup.png`:
1. **Flat Exedra Instead of Semicircular Coffered Apse:**
   - `SEuParts.niche()` creates a flat rectangular recess with 7 blocky stone slabs stuck around it, rather than Nicola Salvi's **deep semicircular concave triumphal exedra** crowned by a **coffered half-dome with carved rosettes** and curved attic entablature.
2. **Palazzo Poli Facade Fidelity:**
   - Wings use basic `LandmarkDetail.window` rectangles and coarse `lm.gable` triangles without Baroque rusticated ground stonework, fluted Corinthian pilasters/capitals, scrolled window corbels, miniature window balustrades, alternating segmental/triangular pediments, deeply carved **Agrippa & Aqua Virgo marble bas-relief panels** (currently two small standing figures glued to a flat slab), an authentic **Latin inscription attic frieze**, or a sculpted **Clement XII papal coat of arms (escutcheon, tiara, crossed keys) flanked by reclining winged Fames**.
3. **Blobby Reef & Turntable-Disc Horses:**
   - `trevi_reef.glb` is 15 overlapping displaced icospheres (too soft/blobby instead of chiseled Roman travertine ledges and waterfall grottoes).
   - `rearing_horse.glb` (from Poly Haven `horse_statue_01`) retains a circular tabletop figurine disc under the hooves; both horses share identical pose instead of **Calm Sea (right, placid/trotting)** vs. **Rough Sea (left, violently rearing)** guided by Tritons.
4. **Basin & Piazza di Trevi Steps:**
   - Currently a stark `48 × 22 m` rectangular box. The real fountain has **curved semicircular corner cheeks**, wide **curved travertine amphitheatre steps** descending into the sunken piazza bowl, sculpted water-spouting corner masks, and travertine bollards linked by iron chains.

### Why Helsinki 3D+ City Reality Mesh Is a Game-Changer
Verified live against City of Helsinki's VC Map 6.x production config (`https://kartta.hel.fi/3d/configs/c4f95e20-bb50-44ec-b175-c6724b354d68.json`):
- **Primary dataset:** `https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json` (`HTTP 200 OK`, CORS `*`, no API key, **CC BY 4.0 — © City of Helsinki, 3D city model**). Covers `60.125°–60.299° N, 24.829°–25.257° E` (all of central Helsinki including Senate Square, Esplanadi, Market Square, Stockmann/Three Smiths, Mannerheimintie/Kiasma, Rautatientori, Kamppi, and Töölö).
- **Fallback dataset:** `https://kartta.hel.fi/3d/mesh/Helsinki_2017/tileset.json` (3D Tiles 1.0 `.b3dm` with ECEF sphere bounds).
- **Current Helsinki monument inventory gap:**
  - *Existing procedural stubs to upgrade:* **Alexander II** (`landmark_fh_senate_front.gd` — currently 5 generic `statue_figure` clones + 4 bronze cubes for Lex/Pax/Lux/Labor), **J. L. Runeberg** (`landmark_fh_runeberg_statue.gd` — generic Zenobia/Neptune statues), **Keisarinnankivi / Czarina's Stone** (`landmark_fh_market_square.gd` — beams & spheres for the gilt double-headed eagle), and **Aleksis Kivi** (`landmark_fh_national_theatre.gd`).
  - *Iconic central monuments completely missing from the registry:* **Three Smiths Statue (*Kolmen sepän patsas*)**, **Marshal Mannerheim Equestrian Statue**, **Eino Leino Statue**, **Topelius (*Taru ja totuus*)**, **Elias Lönnrot Monument**, and **J. K. Paasikivi Monument**.

---

## Architecture & Shared Infrastructure (`P0.1`)

### Asset Layout
Keep offline-baked hero `.glb` assets neatly grouped under `assets/landmarks/` (separate from generic reusable `assets/statues/`):
- `assets/landmarks/trafalgar/*.glb` — generated deterministically by `tools/build_trafalgar_assets.py` (Blender 5.3)
- `assets/landmarks/trevi/*.glb` — generated deterministically by `tools/build_trevi_assets.py` (Blender 5.3)
- `assets/landmarks/helsinki_3d/*.glb` — harvested & cleaned from `kartta.hel.fi/3d/mesh/Helsinki_2024` by `tools/fetch_helsinki_3d_tiles.py` + `tools/extract_helsinki_3d_monuments.py`

### Dual Material Strategy for Photogrammetry & Sculpted `.glb`
Extend `SculptureKit` (keeping it `<= 400` lines) with path-flexible asset loading (`stamp_path(lm, key, res_path, ...)`), and add a compact **`scripts/generation/reality_mesh_kit.gd`** (`< 220` lines) supporting **two explicit rendering modes** so every monument looks sharp up close and passes every test contract (`2..16` parts, `albedo_texture != null`, `<= 150k` tris):

1. **Mode A — Textured Photogrammetry Surface (`RealityMeshKit.add_textured_glb()`):**
   - Loads a cleaned, single-atlas `.glb` (with embedded `512×512` or `1024×1024` shadow-neutralized PNG/WebP albedo + generated roughness/normal texture) directly as a `MeshInstance3D` child of `Model` with a cached `StandardMaterial3D` (`albedo_texture` set, `roughness_texture` / `normal_texture` optional, tuned specular/roughness `0.65–0.85`).
   - Best for monuments with distinctive multi-tone stonework, carved inscriptions, gilding, or weathered rock reliefs (e.g., **Keisarinnankivi**, **Paasikivi Monument**, ornate pedestals, or full photogrammetry ensembles where texture fidelity is high).
2. **Mode B — Hybrid Crisp Pedestal + Extracted/Sculpted Bronze (`SculptureKit.stamp_path()`):**
   - Aerial photogrammetry has ~3–8 cm GSD, so sharp granite steps, iron fences, and smooth bronze patinas can show wavy edges or baked sky/foliage tints if left raw.
   - Mode B builds razor-sharp granite steps, plinths, iron railings, and lamp standards in `LandmarkMesh` using `LandmarkMaterials`, and stamps the cleaned, high-resolution Blender/Helsinki-3D+ bronze sculpture directly onto the pedestal with calibrated patinated bronze PBR (`LandmarkMaterials.paint` / `LandmarkMaterials.pbr` + Desktop Ultra `LandmarkShader`).
   - Every Helsinki monument in `tools/helsinki_3d_monuments.json` explicitly declares `"mode": "textured"` or `"mode": "hybrid"` based on visual inspection of the extracted `Helsinki_2024` mesh quality!

---

## Workstream 1: Trafalgar Square Super-Realistic Overhaul (`TS-1..TS-5`)

### Budgets & Contracts (`tests/london_landmarks_test.gd`)
- Registry entry: `trafalgar_square` (`51.5080, -0.1281`, `yaw_deg: -10.0`, `height_m: 51.6`).
- Hard test caps: **height `51.6 ± 2.0 m`**, **`2..16` merged MeshInstance3D parts**, **`<= 150,000` triangles total**, **`lowest_y >= -1.5 m`**, every surface textured (`albedo_texture != null`).
- Target triangle budget: **~95,000–125,000 tris** (leaving generous headroom under the 150k ceiling):
  - Nelson's Column + 4 Landseer Lions + Admiral Nelson + reliefs + capital: ~34,000 tris
  - Twin Lutyens Fountains + dolphin/mermaid/triton sculptures + water plumes: ~26,000 tris
  - William Wilkins National Gallery + North Terrace stairs & balustrades: ~38,000 tris
  - Fourth Plinth, George IV equestrian & corner plinths, Victorian lamps, Yorkstone deck: ~18,000 tris
- Class-size compliance: split National Gallery into `scripts/generation/landmarks/london/ln_trafalgar_gallery.gd` (`< 400` lines) called by `ln_trafalgar_square.gd` (`< 450` lines).

### `TS-1` — Blender 5.3 Hero Sculpt Pipeline (`tools/build_trafalgar_assets.py`)
Exports normalized, outward-normal, clean-UV `.glb` meshes into `assets/landmarks/trafalgar/`:
1. **`landseer_lion.glb`** (~4,200 tris, stamped ×4 = ~16.8k tris): True Edwin Landseer reclining bronze lion — heavy outstretched forelegs & paws resting flat on the plinth, proud raised head with layered sculpted mane, muscular flanks, tucked hind haunches, and curved tail resting along the right flank. Replaces the incorrect seated heraldic `Lion.stl`.
2. **`nelson_statue.glb`** (~3,200 tris): 5.5 m Craigleith-sandstone Admiral Horatio Nelson — contrapposto naval stance, long boat-cloak draped over left shoulder, pinned-up empty right sleeve, bicorne hat, sword hilt, and coiled mooring rope support behind legs.
3. **`corinthian_capital_bronze.glb`** (~3,600 tris): Authentic sculpted cast-bronze Corinthian capital (from melted French cannon) with two staggered tiers of curled acanthus leaves, corner volute scrolls, fleuron rosettes, and concave moulded abacus.
4. **`nelson_relief_panel.glb`** (~1,800 tris, stamped ×4 = ~7.2k tris): Deep high-relief bronze naval battle frieze framed in a recessed egg-and-dart moulding (ships, sails, cannon, grouped officers in relief) sized for the 4 pedestal faces.
5. **`lutyens_fountain_group.glb`** (~4,800 tris, stamped ×2 = ~9.6k tris): McMillan & Wheeler's baroque bronze fountain sculpture cluster — arched leaping dolphins, tritons blowing shells, and mermaids arranged radially around the central tiered bowl stem.
6. **`george_iv_equestrian.glb`** (~4,500 tris): Francis Chantrey's bronze equestrian King George IV (riding bareback in Roman toga on a standing charger) for the NE plinth, plus a crisp classical standing general (`general_plinth_statue.glb`, ~2,200 tris) for the SE/SW plinths and a contemporary bronze plinth sculpture (`fourth_plinth_sculpture.glb`, ~2,200 tris) for the NW Fourth Plinth.
7. **`trafalgar_lantern.glb`** (~750 tris, stamped ×8 = ~6k tris): Iconic Trafalgar Square octagonal bronze lamp standard with stepped plinth, fluted shaft, ornate bracket scroll collar, and faceted lantern cage.

### `TS-2` — Nelson's Column, Plinths & Square Floor (`ln_trafalgar_square.gd`)
- **Yorkstone Stepped Square Deck:** Subtle multi-level paved plaza (`y = 0.0..0.45 m`) linking Nelson's Column, the twin fountains, and the base of the North Terrace stairs with granite kerbs and bronze drainage grilles.
- **Nelson's Column (total height exact `51.6 m`):**
  - 3-step octagonal/square Dartmoor granite platform (`12.2 m → 9.4 m`) with 4 radially projecting **curved/chamfered Landseer lion plinths** (`6.4 m` long, moulded capping cornices) aligned diagonally at `±45°`.
  - Tall rusticated pedestal (`y = 2.0..12.2 m`) with moulded base plinth, recessed bronze battle relief panels on all 4 faces, and overhanging dentilled cornice.
  - **24-flute tapered Dartmoor granite shaft** (`y = 12.2..42.4 m`, built with true sinusoidal fluted cross-section rings, subtle entasis, and Attic torus-scotia-torus base).
  - Sculpted `corinthian_capital_bronze.glb` (`y = 42.4..45.2 m`), circular stone drum (`45.2..46.1 m`), and `nelson_statue.glb` (`46.1..51.6 m`).
- **Four Corner Plinths:**
  - NE Plinth (`x = +34, z = -34`): Tall Portland-stone moulded plinth + `george_iv_equestrian.glb`.
  - NW Fourth Plinth (`x = -34, z = -34`): Matching Portland-stone plinth + `fourth_plinth_sculpture.glb`.
  - SE & SW Plinths (`x = ±28, z = +18`): Havelock & Napier plinths with `general_plinth_statue.glb`.

### `TS-3` — Lutyens Twin Fountains (`ln_trafalgar_square.gd`)
- Two monumental fountains at `x = ±22.5, z = -22.0`:
  - **Four-lobed scalloped octagonal-cruciform Portland granite outer basin** (custom contoured wall + rounded coping lip + stepped apron, `~15.5 m` across) instead of a plain circle.
  - Inner bronze-clad stepped plinth supporting two **fluted cantilevered bronze/stone cascading saucer bowls** (`r = 3.2 m` and `r = 1.6 m`) topped by a bronze finial nozzle.
  - Stamped `lutyens_fountain_group.glb` dolphins/tritons/mermaids mounted around the inner basin pedestal with mouth spout targets.
  - **`FountainKit` hydraulic choreography:** turquoise pool surface with subtle ripples, tall central spire jet (`8.5 m`), 8 inward-arching perimeter dolphin jets, cascading waterfall curtains spilling over both tiered saucers, and white foam rings around impact zones.

### `TS-4` — William Wilkins National Gallery (`ln_trafalgar_gallery.gd`)
- Positioned on the north side (`z = -84 m`, total width `134 m`), elevated on the iconic **North Terrace**:
  - **North Terrace Retaining Wall & Grand Staircase (`z = -54..-62 m`):** Rusticated Portland granite retaining wall (`h = 3.6 m`) spanning the width of the square, crowned with a classical stone balustrade (`SEuParts.rail`-style), pierced by the **wide central ceremonial stair flight** descending to the square plus flanking stair ramps and stone piers with bronze globe lamps.
  - **Double-Row Octastyle Corinthian Portico:** Wide ceremonial entrance steps, 8 front + 4 return fluted Corinthian columns (reusing Carlton House granite/Portland columns with sculpted capitals), deep coffered portico soffit, carved architrave/frieze/dentil cornice, and recessed triangular pediment with sculpted relief tympanum & rooftop acroteria.
  - **Articulated 134 m Portland Stone Facade:**
    - Rusticated ashlar ground floor with deeply recessed arched blind arcades & entrance doors.
    - Piano nobile with **recessed multi-pane sash windows** (`LandmarkDetail` frames + dark reflective glazing + moulded sills) alternating with **pedimented blind statue niches** framed by paired Corinthian pilasters and recessed classical urns/statues.
    - Flanking recessed pavilions + projecting end wings with tetrastyle porticoes and pediments.
    - Continuous rooftop stone balustrade along the entire 134 m parapet.
  - **Authentic Central Dome & Pepper-Pot Turrets:**
    - Square attic drum → **octagonal/cylindrical colonnaded drum** with arched clerestory windows → **ribbed lead-grey cupola dome** topped by a glazed cupola lantern and gilt finial.
    - Twin flanking **Victorian pepper-pot turrets** with square rusticated bases, **open-arched columned drums** (8 slender columns + round arches), and ogee lead cupolas with urn finials.

### `TS-5` — Lighting & Verification
- Architectural `LandmarkLights.FLOOD_META` uplighting on Nelson's Column shaft/capital, the 4 Landseer lions, National Gallery portico & central dome, turquoise underwater glow in both Lutyens basins, and warm glowing lantern glass (`LandmarkMaterials.lit`) on the 8 Victorian lamp standards.
- Verification: `tests/london_landmarks_test.gd`, `tests/fountain_water_test.gd`, `tests/landmark_shader_test.gd`, `tools/check_class_size.sh`, plus `1920×1200` day + dusk captures from open plaza sightlines (never inside geometry).

---

## Workstream 2: Trevi Fountain Super-Realistic Overhaul (`TF-1..TF-4`)

### Budgets & Contracts (`tests/landmark_test.gd`, `tests/fountain_water_test.gd`)
- Registry entry: `trevi_fountain` (`41.90093, 12.48331`, `height_m: 26.3`, `clear_m: 40.0`).
- Hard test caps: **height `26.3 ± 2.0 m`**, **`2..16` merged MeshInstance3D parts**, every material must have non-null `albedo_texture`, **`<= 150,000` tris**.
- Target triangle budget: **~80,000–110,000 tris** in **10–12 merged material surfaces** (Travertine, WarmStone, Marble, DarkRecess, Glass, Gold, Iron, Water, WaterFoam, Lamp, RockWet).
- Class-size compliance: split `trevi()` out of `landmark_rome_civic.gd` into **`scripts/generation/landmarks/south_europe/landmark_rome_trevi.gd`** (`< 450` lines).

### `TF-1` — Blender 5.3 Baroque Sculpt Pipeline (`tools/build_trevi_assets.py`)
Exports normalized, sculpted `.glb` meshes into `assets/landmarks/trevi/`:
1. **`trevi_exedra_apse.glb`** (~7,500 tris): True deep semicircular concave triumphal arch recess (`r = 4.5 m`, `h = 12.2 m`) with **5×7 sunken octagonal/square coffers** across the curved half-dome vault, each coffer containing a raised **carved Baroque rosette**, plus moulded semicircular archivolt, keystone, and inner engaged ionic columns!
2. **`trevi_baroque_reef.glb`** (~14,000 tris): Hand-authored rocky cliff composition built in Blender via sculpted stratified travertine slabs + Voronoi-chiseled rock ledges + carved grotto caves + explicit **flat sculptural pedestals** for Oceanus's chariot, the 2 sea-horses, and the 2 Tritons + **concave waterfall spill channels** at exact documented `(x, y, z)` coordinates so `FountainKit` sheets lock cleanly onto the stone with zero gaps or buried ankles!
3. **`trevi_horse_wild.glb`** & **`trevi_horse_calm.glb`** (~4,500 tris each): Derived from CC0 `horse_statue_01` with the **circular tabletop figurine pedestal completely sliced away in Blender**, hooves cleanly sculpted to meet the rocky shelf, and two distinct Baroque poses:
   - Left (`Rough Sea`): dramatic rearing pitch (`+24°`), tossing head, flaring tail, surging out of the reef.
   - Right (`Calm Sea`): docile forward-stepping trot, lowered tranquil head, guided smoothly by its Triton.
4. **`trevi_shell_chariot.glb`** (~3,200 tris): Ornate deeply-fluted Baroque scalloped cockleshell chariot with curled scroll rim, carved volute undercarriage, and foaming stone wave crest supporting Oceanus (`classical_hero.glb`).
5. **`trevi_relief_agrippa.glb`** & **`trevi_relief_virgo.glb`** (~3,400 tris each): High-relief framed marble panels depicting *Agrippa approving the Aqua Virgo aqueduct* (left bay) and *the Roman maiden showing the spring to soldiers* (right bay), complete with recessed architectural moulding frame so they read as true carved reliefs instead of floating figures.
6. **`trevi_papal_crest.glb`** (~5,800 tris): Monumental Baroque **Clement XII Corsini coat of arms** crowning the attic — scrolled Baroque escutcheon shield, papal triple tiara, crossed Keys of St Peter, draped festoon garlands, flanked by **two sculpted reclining winged Fames** holding trumpets/wreaths.
7. **`trevi_corner_mask.glb`** (~1,200 tris, stamped ×4): Carved travertine Baroque lion/water-mask spouts mounted at the reef/basin transition.

### `TF-2` — Palazzo Poli Facade Rebuild (`landmark_rome_trevi.gd`)
- Exact classical proportions (`width = 49.15 m`, `height = 26.3 m` to top of papal crest):
  - **Rusticated Travertine Basement (`y = 0.0..5.2 m`):** Deeply coursed vermiculated ashlar stonework on the outer bays, organically overgrown by `trevi_baroque_reef.glb` across the central 36 m width.
  - **Triumphal Arch Centerpiece (`x = -11.5..+11.5 m`):**
    - Stamped `trevi_exedra_apse.glb` recessed cleanly behind a projecting Corinthian triumphal arch frame.
    - **Four giant fluted Corinthian columns** (`r = 0.68 m`, `h = 13.8 m`) on tall carved plinths, with sculpted capitals and **projecting ressaut (break-forward) entablature blocks** over every column!
    - Flanking side niches with recessed shell-hood arches housing **Abundance** (left, pouring fruit/cornucopia) and **Salubrity** (right, holding cup/serpent), with `trevi_relief_agrippa.glb` and `trevi_relief_virgo.glb` set into moulded panels directly above them.
  - **Palazzo Poli Flanking Wings (`x = ±11.5..±24.6 m`):**
    - Giant-order **fluted Corinthian pilasters** dividing 3 bays per wing (`6` bays total).
    - **Three articulated window storeys** per bay:
      - Lower mezzanine windows with moulded stone frames & iron grilles.
      - Piano nobile tall recessed windows with **scrolled corbel brackets, miniature projecting stone balustrades, recessed dark multi-pane glazing, and alternating triangular & segmental Baroque pediments**.
      - Upper attic square windows with carved lugged architrave frames and sill consoles.
  - **Dedication Attic & Roofline (`y = 19.4..26.3 m`):**
    - Continuous deep modillion cornice with overhanging shadow line.
    - Central inscribed attic tablet (`CLEMENS XII PONT MAX AQVAM VIRGINEM...`) framed by moulded marble panels and crowned by `trevi_papal_crest.glb` reaching `26.3 m`.
    - Four allegorical **Season statues** standing on projecting attic pedestals directly aligned over the four giant Corinthian columns.
    - Continuous Baroque roof balustrade with stone urns along both wings.

### `TF-3` — Sunken Basin, Curved Steps & Aligned Water (`landmark_rome_trevi.gd`)
- **Authentic Trevi Basin (`w = 48.0 m`, `d = 21.0 m`):**
  - Curved semicircular corner cheeks (`r = 5.5 m` quarter-round corners) + overhanging moulded travertine rim (`y = 0.95 m`) and wet inner travertine liner (`RockWet` material darkened near waterline).
  - **Descending Piazza di Trevi Seating Steps:** Three wide curved/stepped travertine amphitheatre tiers wrapping the front and sides of the basin rim, plus carved **stone bollards** linked by sagging wrought-iron chains along the outer piazza perimeter.
- **Zero-Gap Hydraulic Alignment (`FountainKit`):**
  - Turquoise mineral-blue water plane (`#2C9E9A`) with gentle concentric ripple shading inside the curved basin.
  - Three stepped central **sheet waterfalls** pouring directly from the sculpted rock lips beneath Oceanus's chariot into intermediate catch pools and down into the main basin.
  - 6 lateral **grotto cascade spouts** + 4 `trevi_corner_mask.glb` arched water jets feeding directly from carved channel mouths into dense white foam plunge rings (`FountainKit` spray/foam).

### `TF-4` — Lighting & Verification
- Warm golden Roman architectural floodlights (`2800K`) raking the coffered apse dome, Oceanus, the sea-horses, and Corinthian columns, paired with soft emerald-turquoise submerged basin glow (`LandmarkLights.FLOOD_META`).
- Verification: `tests/fountain_water_test.gd`, `tests/landmark_shader_test.gd`, `tests/landmark_test.gd`, `tools/check_class_size.sh`, and `1920×1200` day + dusk captures (piazza wide shot, Oceanus + coffered exedra close-up, left/right horse & reef waterfall close-ups).

---

## Workstream 3: Helsinki 3D+ City Reality Mesh Monument Extraction Pipeline (`H3D-1..H3D-5`)

### Verified Data Source & Legal Compliance
- **Source:** City of Helsinki 3D City Model — **Helsinki 3D+ Reality Mesh (`Mesh 2024`)**
- **Verified Live Root Endpoint:** `https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json` (`HTTP 200 OK`, no key, CORS enabled)
- **Fallback Endpoint:** `https://kartta.hel.fi/3d/mesh/Helsinki_2017/tileset.json`
- **License:** **CC BY 4.0** — attribution required: `"© City of Helsinki, 3D city model"` (already established in `docs/data-source-register.md` and in-app credits).
- **HostPolicy compliance:** Strictly Finnish municipal domain (`kartta.hel.fi`, `.fi`), zero restricted domains.
- **Offline-only harvest:** Just like `tools/prepare_helsinki_lod2.py`, all tile fetching, cropping, and `.glb` baking happens offline via reproducible Python + Blender 5.3 scripts; the Godot app bundles only the compact final `.glb` assets (`~150–600 KB` per monument) with zero runtime dependency on `kartta.hel.fi`.

### `H3D-1` — Live 3D Tiles Harvester (`tools/fetch_helsinki_3d_tiles.py`)
Reuses the proven ECEF/LLA/GK25 math from `tools/prepare_helsinki_lod2.py`:
1. Reads `tools/helsinki_3d_monuments.json` (each entry specifies `id`, `name`, `lat`, `lon`, `radius_m`, `z_min_rel`, `z_max_rel`, `yaw_deg`, `mode`, `target_tris`).
2. Recursively traverses `Helsinki_2024/tileset.json` (handling both external sub-tileset `.json` nodes like `1/tileset.json` and leaf `.b3dm` / `.glb` tiles):
   - Tests intersection between the monument's `(lat, lon, radius_m)` bounding box and each node's `boundingVolume.region` (WGS84 radians `[w, s, e, n, minH, maxH]`) or `boundingVolume.sphere` (ECEF `[x, y, z, r]`).
   - Descends to the finest `geometricError` leaf tiles (`refine: "REPLACE"`), caching raw tiles under `build/helsinki_3d_cache/` (gitignored).
3. Parses each leaf `.b3dm` binary header (`magic="b3dm"`, `featureTableJSONByteLength`, `batchTableJSONByteLength`), extracts `RTC_CENTER` from the Feature Table JSON, strips the `.b3dm` prefix to yield a standard `.glb`, and computes the exact **ECEF → local East-North-Up (ENU) metre transform** centered on the monument's `(lat, lon)` (converting Y-up glTF + tile `transform` + `RTC_CENTER` to Godot's `+X east, +Y up, +Z south` frame!).

### `H3D-2` — Blender 5.3 Cleanup, De-Lighting & Export Pipeline (`tools/extract_helsinki_3d_monuments.py`)
Runs headless Blender 5.3 (`/Applications/Blender.app/Contents/MacOS/Blender --background --python ...`) per monument:
1. **Multi-Tile Merge & Spatial Crop:** Imports all intersecting leaf `.glb` tiles, applies the ENU transform, joins meshes, and clips triangles cleanly inside the monument's target cylinder/box (`radius_m`, `y_min..y_max`) via Blender `bmesh` plane bisection so boundary seams are crisp.
2. **Ground & Clutter Removal:**
   - Detects the local ground plane elevation (`z_ground`) from the ring of vertices immediately outside the pedestal footprint and shifts the monument so `min_y = 0.0`.
   - Removes disconnected floating foliage/pedestrian/lamp-wire islands via connected-component area filtering (retaining only the main monument mass + deliberate companion figures).
   - Caps the underside cleanly so no open bottom edge leaks light.
3. **Topology & Silhouette Refinement:**
   - Optional mild Laplacian/taubin smoothing ONLY on flat photogrammetry noise (preserving sharp statue silhouettes via angle threshold) + `DECIMATE` (`COLLAPSE`) to the monument's target budget (`4,000–16,000` tris depending on hero importance).
   - Recalculates smooth/weighted normals (`angle = 40°`) and verifies outward winding.
4. **Texture Re-Bake & Shadow De-Lighting (Mode A — `textured`):**
   - Because photogrammetry textures often span 2–4 raw tiles with 2K textures and baked aerial sunlight shadows:
   - Smart-UV-unwraps the decimated monument onto a single clean `[0, 1]` UV layout and bakes the original multi-tile diffuse textures onto a single compact **`512×512` or `1024×1024` texture atlas**.
   - Runs a lightweight highlight/shadow compression pass (lifting deep baked ambient shadows slightly while keeping natural stone/bronze patina tones) so Godot's real-time directional sun + shadows light the monument naturally without muddy double-shadows.
   - Generates a matching **subtle normal/roughness variation map** from luminance micro-detail and packs everything into a single self-contained `.glb` (`assets/landmarks/helsinki_3d/<id>.glb`, target `<= 500 KB` per monument).
5. **Hybrid Bronze/Sculpture Split (Mode B — `hybrid`):**
   - For tall pedestal bronze statues where aerial photogrammetry captures accurate bronze proportions/drapery while blurring sharp rectangular granite steps or iron railings:
   - Slices at `pedestal_cut_y` to isolate the bronze sculpture(s), cleans & decimates to `4,000–8,000` tris, exports clean untextured/UV-mapped `.glb` for `SculptureKit.stamp_path()`, while the GDScript builder renders razor-sharp granite steps, moulded plinths, inscriptions, and iron railings via `LandmarkMesh` + `LandmarkMaterials`.

### `H3D-3` & `H3D-4` — Curated Central Helsinki Monument Roster (10 Monuments)

| Monument | Location (`lat, lon`) | Height | Status in Repo | Extraction Mode | Target Asset |
|---|---|---|---|---|---|
| **Alexander II Monument** (*Walter Runeberg, 1894*) | Senate Square (`60.16950, 24.95224`) | `10.7 m` | Upgrade procedural stub in `landmark_fh_senate_front.gd` | **Hybrid** (crisp granite platform, candelabra & steps + extracted Emperor & Lex/Pax/Lux/Labor bronze groups) | `alexander_ii_emperor.glb` + `alexander_ii_groups.glb` |
| **J. L. Runeberg Monument** (*Walter Runeberg, 1885*) | Esplanadi (`60.16750, 24.94760`) | `8.0 m` | Upgrade generic statues in `landmark_fh_runeberg_statue.gd` | **Hybrid** (crisp octagonal steps, iron fence & red-granite plinth + extracted Runeberg & Suomi-neito bronzes) | `runeberg_ensemble.glb` |
| **Keisarinnankivi (Czarina's Stone)** (*C. L. Engel, 1835*) | Market Square (`60.16766, 24.95444`) | `9.0 m` | Upgrade beam/ball eagle in `landmark_fh_market_square.gd` | **Hybrid / Textured** (crisp obelisk + extracted sculpted bronze/gilt globe & double-headed eagle) | `keisarinnankivi_crown.glb` |
| **Aleksis Kivi Statue** (*Wäinö Aaltonen, 1939*) | Rautatientori (`60.17185, 24.94402`) | `4.6 m` | Upgrade stub in `landmark_fh_national_theatre.gd` | **Textured / Hybrid** (seated bronze writer on stepped granite plinth) | `aleksis_kivi.glb` |
| **Three Smiths Statue (*Kolmen sepän patsas*)** (*Felix Nylund, 1932*) | Kolmensepänaukio (`60.16867, 24.94083`) | `4.8 m` | **NEW** (`landmark_fh_three_smiths.gd`) | **Hybrid** (crisp cylindrical granite pedestal + extracted 3 bronze smiths & anvil) | `three_smiths.glb` |
| **Marshal Mannerheim Equestrian Statue** (*Aimo Tukiainen, 1960*) | Mannerheiminaukio (`60.17173, 24.93632`) | `11.1 m` | **NEW** (`landmark_fh_mannerheim_statue.gd`) | **Hybrid** (tall red-granite monolith plinth + extracted bronze equestrian Mannerheim) | `mannerheim_equestrian.glb` |
| **Eino Leino Statue** (*Lauri Leppänen, 1953*) | Esplanadi (`60.16745, 24.94425`) | `5.2 m` | **NEW** (`landmark_fh_eino_leino.gd`) | **Hybrid** (granite plinth + extracted cloak-draped bronze poet) | `eino_leino.glb` |
| **Topelius (*Taru ja totuus*)** (*Ville Vallgren, 1932*) | Esplanadi (`60.16746, 24.94590`) | `4.5 m` | **NEW** (`landmark_fh_topelius_statue.gd`) | **Hybrid** (granite pedestal + extracted twin allegorical bronze maidens) | `topelius_statue.glb` |
| **Elias Lönnrot Monument** (*Emil Wikström, 1902*) | Lönnrotinpuistikko (`60.16670, 24.93830`) | `6.5 m` | **NEW** (`landmark_fh_lonnrot_monument.gd`) | **Hybrid / Textured** (granite pedestal + seated Lönnrot & Väinämöinen/Impi bronze figures) | `lonnrot_monument.glb` |
| **J. K. Paasikivi Monument (*Itä ja länsi*)** (*Harry Kivijärvi, 1980*) | Paasikivenaukio (`60.17045, 24.93555`) | `5.5 m` | **NEW** (`landmark_fh_paasikivi_monument.gd`) | **Textured** (twin sculpted black-granite monoliths — ideal for textured photogrammetry!) | `paasikivi_monument.glb` |

> **Quality Fallback Guardrail:** During `H3D-2`, every extracted Helsinki_2024 mesh is automatically inspected (vertex density, bounding-box completeness, silhouette fidelity via Blender clay render previews). If any small bronze figure (e.g. a narrow thin statue tucked under Esplanadi tree canopy in 2024 leaf-on flights) suffers occlusion or canopy merge in the aerial mesh, the pipeline either (a) cross-falls back to `Helsinki_2017` (leaf-off spring flight!) or (b) applies a Blender sculptural refinement pass anchored to the real extracted proportions so *every single shipped monument* looks genuinely realistic up close!

### `H3D-5` — Attribution, Docs & Visual Verification
- Add `Helsinki 3D+ Reality Mesh (2024)` entry to `docs/data-source-register.md` (`CC BY 4.0 — © City of Helsinki, 3D city model`).
- Document coordinates, heights, and extraction provenance per monument in `docs/helsinki-landmark-sources.md` and `assets/landmarks/helsinki_3d/README.md`.
- Run `tests/host_policy_test.gd`, `tests/helsinki_hero_landmarks_test.gd`, `tests/landmark_test.gd`, `tools/check_class_size.sh`, and capture `1920×1200` eye-level verification PNGs in open squares/streets (Senate Square, Esplanadi, Market Square, Kolmensepänaukio, Mannerheiminaukio).

---

## Verification & Release Gates

Every workstream must pass **all** of the following before marking `[x]`:
1. **Automated headless tests** (run via `tools/godot_bg.sh --headless`):
   - `tests/london_landmarks_test.gd` (Trafalgar Square: `51.6 m`, `2..16` parts, `<= 150k` tris, `min_y >= -1.5 m`)
   - `tests/fountain_water_test.gd` (Trafalgar & Trevi water surfaces, cascades, nozzles)
   - `tests/landmark_shader_test.gd` (Desktop Ultra weathering compatibility on all materials)
   - `tests/landmark_test.gd` (Trevi Fountain & Helsinki monuments: `2..16` parts, non-null `albedo_texture`, height tolerances)
   - `tests/helsinki_hero_landmarks_test.gd` (all Helsinki registry entries, extents, clearances)
   - `tests/host_policy_test.gd` (zero forbidden domains)
   - `tools/check_class_size.sh` (every new/modified `.gd` file strictly `<= 1000` lines)
2. **Visual quality gates** (`1920×1200` lossless PNG captures via `tools/godot_bg.sh ... --position 4000,4000`, eyes strictly in open space outside footprints):
   - **Trafalgar Square:** (1) Landseer lion + Nelson's Column bronze relief close-up, (2) Lutyens four-lobed fountain & dolphin/triton water plumes, (3) National Gallery portico + North Terrace stairs + dome/turrets, (4) full square overview (day + dusk).
   - **Trevi Fountain:** (1) Oceanus + coffered semicircular exedra + papal crest close-up, (2) left Rough Sea vs. right Calm Sea horse & reef cascade close-ups (verifying zero buried limbs / zero floating sheets), (3) full Piazza di Trevi curved basin & steps (day + dusk).
   - **Helsinki 3D+ Monuments:** eye-level inspection shots of Senate Square (Alexander II), Three Smiths, Mannerheim, Esplanadi (Runeberg + Eino Leino + Topelius), Market Square (Keisarinnankivi), and Paasikivi Monument.
3. **Asset footprint budget:** Total new `.glb` assets across all three workstreams kept lean (`<= 12 MB` combined repo footprint) through disciplined decimation and `512–1024 px` compressed atlases.
