# Landmark silhouette checklist — T5.3 (2026-10-28, @D/landmarks)

Every registry landmark and OSM archetype was rebuilt as procedural, merged
geometry in **true metres** under a `Model` node scaled by
`WorldScale.metres_to_units()` (currently 1.0 after the T7.0 cutover), with
calibrated photographic PBR materials (`LandmarkMaterials`, CC0 sets from
`assets/textures`) — no flat colours. Each part merges every member that
shares a material, so the 3000-member Eiffel lattice is 10 draw calls.

Captures in `visual-plan/reviews/landmarks-2026-10-28/` (isolated orbit scene:
landmark alone on a grass plane, golden-hour sun, no network; `_0/_1/_2` are
orbit views and `_3` is a close-up). `app-paris-*.jpg` is the real app: Paris
centre, High preset, with the camera aimed at the Eiffel Tower at its true
distance of 4.2 km.

Sign-off column is for F (validation role).

| Landmark | Real reference (m) | Model (measured) | Silhouette checks | Parts / tris | Capture | F |
|---|---|---|---|---|---|---|
| Eiffel Tower | 330 (antenna), base 125 sq, floors 57.6 / 115.7 / 276 | 330.0 m; pier half-base 62.5 | [x] 4 curved lattice piers with exponential flare, merging above ~200 m [x] 4 great arches [x] arcaded 1st-floor frieze, 2nd floor, 3rd-floor cabin, campanile, antenna [x] continuous taper with no stacked cylinders or cones [x] matte bronze-brown #6B4A2F (rough 0.72, metal 0.2) [x] piers N/E/S/W, faces square to Champ de Mars | 10 / 29.7k | eiffel_0/1/3, app-paris-zoom | [ ] |
| Tokyo Tower | 332.9; Main Deck 145/150, Top Deck 250 | 332.9 m | [x] 4 splayed lattice legs merging at 48 m [x] base arches [x] international orange #E8501E and white bands on the shaft and antenna [x] 2 glazed octagonal decks [x] Foot Town between the legs | 12 / ~16k | tokyo_1/3 | [ ] |
| Big Ben (Elizabeth Tower) + Palace | 96; 12 m sq; dials 7 m at ~55 m | 96 m tower (palace Victoria Tower 98.5) | [x] panelled limestone shaft [x] 4 gilt-framed opal dials with hands and hour marks (emissive) [x] gabled clock stage, corner pinnacles, arcaded belfry, steep iron spire, Ayrton lantern [x] 265 m river range with pinnacles and window bays, Central Tower spire, Victoria Tower | 7 / ~8k | big_ben_0/1/3 | [ ] |
| Colosseum | 189 x 156 ellipse, 48 high, 80 bays | 189 x 156 x 48 | [x] 3 arcaded tiers with real round-headed arches, half-columns and entablatures, plus windowed attic [x] broken outer ring (north side intact, stepping down at both ends) [x] brick buttress wedges [x] exposed inner ring to the south [x] ruined cavea of radial walls, hypogeum maze, part-rebuilt floor | 6 / 24.8k | colosseum_1/2 | [ ] |
| Sagrada Família | Jesus 172.5 (topped out 2026), Mary 138, Evangelists 135, façade towers 98–112 | 172.5 m | [x] 4 Nativity and 4 Passion bell towers (parabolic taper, spiralling louvres, mosaic mitre pinnacles) [x] 4 Evangelist towers, Mary star, Jesus four-armed cross [x] apse ring with pinnacles, nave, Passion bone columns, Glory portals [ ] the sculpted Nativity façade is only a mass with portals (gap) | 7 / ~13k | sagrada_0/1 | [ ] |
| Giza (pyramid) | Khufu 230.3 base / 138.5; Khafre 215.3 / 136.4; Menkaure 103.4 / 61 | 138.5 m, field ~1 km | [x] three pyramids at surveyed offsets, sides on the compass [x] stepped stripped courses [x] Khafre casing cap [x] queens' pyramids [x] Sphinx facing east | 3 / 3.1k | pyramid_1/3 | [ ] |
| Statue of Liberty | 93 ground to torch; pedestal top 47 | 93.8 m | [x] 11-point Fort Wood star [x] stepped foundation, granite pedestal with loggia [x] verdigris figure with fluted robe, 7-ray crown, raised torch arm, gilded flame, tablet [ ] figure is coarse at close range (gap) | 6 / 1.4k | statue_liberty_0/3 | [ ] |
| Sydney Opera House | crest 67 a.s.l.; site ~183 x 120 | 67 m | [x] 2 hall shell files plus the restaurant shells [x] doubly curved lancet sails, chevron-tile outside, ribbed concrete inside [x] mouth glazing [x] podium and Monumental Steps | 4 / 13.1k | sydney_opera_0/2 | [ ] |
| Turku Cathedral | tower 86 above ground (101 a.s.l.) | 86.1 m | [x] brick nave with steep roof, side chapels, polygonal choir [x] massive square west tower, Engel clock stage with white trim, octagonal spire, ball and cross | 7 / 1.4k | turku_cathedral_1 | [ ] |
| Helsinki Cathedral | 62 to the cross | 62.0 m | [x] white Greek cross on its platform plus stair to Senate Square [x] 4 hexastyle porticos with pediments and apostles [x] colonnaded drum, green dome, lantern [x] 4 corner domes | 5 / 6.7k | helsinki_cathedral_0 | [ ] |

## OSM archetypes (`LandmarkBuilder.build_archetype`)

These are built in metres from the feature's real height (clamped to 20–184 m)
and footprint (24–240 m). They use the regional look from
`ArchitectureStyle.profile/religious_look`: wall set (brick, render, wood,
concrete; stone maps to dressed limestone), stone and roof colours, and tower
style.

| Archetype | Checks | Capture |
|---|---|---|
| church / cathedral | [x] nave + aisles + buttresses + windows + apse [x] single / twin west towers [x] tower styles: spire (pinnacles), bell, onion (gilded, plus crossing dome), pagoda/minaret fall back to bell | archetypes_arch1.jpg (nordic brick, central-Europe twin spires, eastern-Europe onion) |
| castle | [x] crenellated curtain wall, 4 round towers with conical roofs, gatehouse, keep with turrets | archetypes_arch1.jpg |
| lighthouse | [x] red and white banded taper, gallery and railing, glazed lantern with lit lamp, cap, keeper's house | archetypes_arch1.jpg |
| stadium | [x] elliptical facade with glazed band, ribs, double-sided canopy ring, raked seating, grass pitch | archetype_stadium.jpg |
| mosque | [x] prayer hall, windowed drum and dome, semi-domes, 2 or 4 pencil minarets with balconies | archetypes_arch2.jpg |
| temple | [x] pagoda (East Asia) [x] shikhara with amalaka and kalasha (South Asia) [x] classical peristyle elsewhere | archetypes_arch2.jpg |
| windmill | [x] tapered octagonal tower mill, stage, cap, 4 lattice sails | archetypes_arch2.jpg |
| tower | [x] >=100 m: telecom tower (shaft, glazed pod, mast) [x] smaller: masonry tower with a pyramid roof | archetypes_arch2.jpg |

## Gaps / notes

- **Placement (T5.2):** this is not part of T5.3. The T5.2 owner has updated
  the placement assertions in `tests/landmark_test.gd`, and the full test
  passes. `TerrainBuilder._landmark` still has the Eiffel `material_override`
  block. It now does nothing, because the parts sit under `Model`, but the
  T5.2 owner should delete it.
- **Viewpoint at a site:** with true placement, a camera that spawns at the
  site starts inside the model (for example, Eiffel at 48.8584, 2.2945). The
  T5.2 spawn logic must handle this.
- **Giza:** the field is 1 km across. On the old 220-unit world it would have
  overflowed the terrain; at true metres it fits the 2.4 km extent.
- **`assets/eiffel.glb`:** the Blender asset is no longer used. The procedural
  lattice beats its silhouette, which was a tube mast, and uses the project
  PBR textures. Blender 5.2 is installed at
  `/Applications/Blender.app` but is not on PATH, and `build_eiffel.py`
  imports a helper from an external skill path. The asset and its script are
  left in place for the owner to delete or keep.
- **Colour:** the `stone` (old sandstone) set is too saturated to tint toward
  light neutral stone, so landmarks use `limestone`, `concrete` or `render`
  for light stone.
- **Detail gaps:** the Statue of Liberty figure and the Sagrada Nativity
  sculpture are coarse at close range. A GLB pass would help if close
  viewpoints matter.
