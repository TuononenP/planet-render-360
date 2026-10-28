# Planet Render 360: visual PRD — Fidelity 3, photorealistic scenery

## 1. Goal and visual pillars

Planet Render 360 (Godot 4.7.2, GDScript, mobile-first) renders any picked place as a navigable 360° 3D view. This PRD supersedes the earlier warm low-poly target in every visual respect: the user directive is "Continue with 3 Fidelity & options. The scenery overall should look much more photorealistic." The deliverable is the in-engine 360 scenery (exemplar: Paris, 48.8566° N, 2.3522° E) plus the picker flow that launches it, at three selectable fidelity tiers (§3.4). A viewer comparing a capture to a golden-hour photograph of Paris must read real stone, slate, water, foliage and haze — never faceted low-poly geometry, flat-shaded slabs, or untextured boxes.

Pillars:
- Photoreal first: PBR textures (albedo + normal + roughness) on 100% of scenery surfaces; 0 visibly faceted/flat-shaded scenery meshes at Fidelity 2–3; no untextured primitive reads at any tier.
- True scale and fabric: buildings 4–7 storeys (12–22 m), height:width per block 0.5:1–0.9:1; no non-landmark building >2.0× its neighbours' height; landmark is the only silhouette exception.
- Golden-hour light as in `view360-paris.jpg`: low warm sun, long soft shadows, aerial haze compressing the far 30% of depth toward the horizon colour.
- Three honest fidelity options: Fidelity 1 (mobile balanced), 2 (high, default), 3 (photoreal) change texture resolution, shadow quality, vegetation/building density and reflections — never layout, scale, palette hue, or landmark identity.
- Mobile-smooth: Fidelity 1 ≥30 fps on a mid-tier phone; Fidelity 3 is opt-in, never the forced default.

## 2. Reference index

| File | Shows | Authoritative for | Source |
|---|---|---|---|
| refs/view360-paris.jpg (1920×1280) | Landscape phone (screen ≈ x 16–85%, y 23–80% of frame) showing golden-hour Paris 360 view: Eiffel Tower left-of-centre, Seine S-curve to the right, Haussmann blocks, hazy horizon, UI chips | Composition, horizon height, landmark placement/scale, river path, block massing, golden-hour palette, 360-view UI; **not** authoritative for surface style (its low-poly facets are explicitly superseded by §1) | user |
| refs/picker.png (1920×1280) | Portrait phone (screen ≈ x 34–66%, y 6–94% of frame) with "Planet Render 360" title, search field, watercolour world map centred on Europe, teal pin on Paris, bottom card "Paris, France / 48.8566° N, 2.3522° E" + teal "Render 360 View" button | Picker layout, map framing, pin position, card/button geometry and teal; not authoritative for 360 scenery | user |

Assumptions for parts no reference shows:
- The 360 view extends the Paris frame in all directions with the same fabric: Haussmann blocks, slate roofs, tree-lined quays; no new building style appears off-frame.
- Rear/occluded faces of the Eiffel Tower mirror the visible faces (4 legs, 2 platforms, tapering spire); rear block faces carry the same window grid as front faces.
- Night, rain and winter variants are out of scope; only the golden-hour condition in `view360-paris.jpg` is judged.
- The dark studio backdrop and phone hardware in both refs are presentation mockups, never rendered in-app.

## 3. Global look

### 3.1 Style
- Style: photorealistic PBR, real-world weathering (subtle grime at wall bases, roof staining), geometry bevels ≥0.05 m on block corners; 0 low-poly facets, 0 flat vertex-colour surfaces, 0 visible texture tiling repeats within any 20 m wall run at Fidelity 2–3.
- Texture sources: CC0 photographic textures (e.g. PolyHaven-class) or photogrammetry-derived; procedural noise only as micro-detail blended over photographic albedo, never as the sole albedo at Fidelity 3.

### 3.2 Palette (sampled/derived; base albedo, judged in shadow not sun glare)
| Surface | Base hex | Lit read | Shadow read |
|---|---|---|---|
| Limestone facade | #D6C5A3 | #EBDCBE | #9C8D73 |
| Slate mansard roof | #46525E | #5D6D7A | #2F3841 |
| Seine water (deep) | #2C5566 | #6FA3B5 + sun glints #FFEFC4 | #1E3D4A |
| Foliage (broadleaf) | #4C6B2E | #7A9A48 | #2E4420 |
| Urban ground/pavement | #8A8274 | #A79D8B | #5F594F |
| Sky zenith → horizon | #7FA8CC → #F0C48F | sun core #FFF3D6 | n/a |
| UI teal (both refs) | #3E8F88 | button fill in picker.png; chips in view360-paris.jpg | — |

Sample anchors from refs: warm sky wash ≈ #EBCFA0, sun glow ≈ #F9F8E6, UI teal ≈ #42948E (view360-paris.jpg); picker button/card read near-white #FCFCFC card on teal (picker.png). Final scenery colours are the photoreal bases above, graded to meet those warm reads under §3.3 light.

### 3.3 Lighting, camera, atmosphere
- Sun: 1 directional key, azimuth from frame-right (≈65° from camera forward), elevation 8–12° (sun disc centre ≈62% frame width, 37% frame height in view360-paris.jpg), colour #FFD9A3, intensity 3.0; shadows soft (radius ≥4 px at 1080p, Fidelity 2–3).
- Fill/ambient: sky ambient #B9CBD8 at 0.35–0.5; no second shadow-casting light; bounce approximated by ambient + hemisphere ground #6B6257.
- Atmosphere: exponential height fog, horizon colour #EFD2A4, far terrain/buildings at ≥800 m blended ≥70% toward horizon colour; sky gradient zenith #7FA8CC → horizon #F0C48F over the top 42% of frame; sun glare/bloom threshold 1.0, strength 0.3 (Fidelity 3 only, §3.4).
- Clouds: photographic/volumetric-look stratocumulus band at 28–40% frame height, warm-lit undersides #E8C9A0; 0 geometric low-poly cloud slabs (the ref's faceted clouds are superseded).
- Camera (360 view): eye 25–35 m above ground (≈8 m above mean roofline), pitch −4° to −8°, FOV 68–75° horizontal; horizon at 40–44% of frame height; drag-look 360° yaw × −60°/+60° pitch; landmark placed per §4.1 on the Paris spawn view.
- Ground/horizon closure: terrain + far apron extends ≥9 km; no void band, no hard disc edge at any yaw.

### 3.4 The three fidelity options (user-selectable; Fidelity 2 default)
| Option | Textures | Shadows | Density / draw | Water & sky | Target |
|---|---|---|---|---|---|
| Fidelity 1 — Balanced | ≤1024 px, no normal maps on distant blocks | 1× 1024 cascade, radius 2 px | Buildings ≤150 m radius full detail, impostors beyond; trees ≤800 instanced | Flat PBR water, gradient sky | ≥30 fps mid-tier phone |
| Fidelity 2 — High (default) | ≤2048 px + normal/roughness | 2× 2048 cascades, radius 4 px | Full detail ≤300 m; trees ≤2,500; window parallax off | Screen-space-look planar reflection, photographic clouds | ≥30 fps flagship / desktop |
| Fidelity 3 — Photoreal | ≤4096 px + normal/roughness/AO baked per block | 4096 cascades, radius 6 px, contact AO | Full detail ≤600 m; trees ≤6,000 with per-tree hue variance ±10%; cars/people-scale props (lampposts every 25 m, railings) | Reflective water with sun-glint sparkle, bloom 0.3, volumetric-look god-ray haze | Desktop / flagship opt-in; no fps promise |

Tier switches must not move any object, change any hue by >2% (ΔE), or alter the landmark silhouette; only the columns above change.

### 3.5 Render
- Engine: Godot 4.7.2 Forward+/Mobile as shipped; capture 1920×1080 (landscape) for judging; ACES/Filmic tonemapping, exposure 1.0–1.15; sRGB output; FXAA/TAA on at Fidelity 2–3.

## 4. Objects

Base unit: metres (m). Paris spawn view judged against view360-paris.jpg screen-space ratios (frame = 360 viewport, width W, height H).

### 4.1 Eiffel Tower landmark (refs: view360-paris.jpg)
- Position/scale in spawn frame: centreline at 0.36 W, base at 0.51 H, spire tip at 0.28 H → apparent height 0.23 H; real height 330 m at ≈700–900 m from spawn camera. Only structure taller than 2.0× neighbours.
- Shape: 4 curved lattice legs on a 125 m square base, arch openings between legs, platform 1 at 57 m, platform 2 at 115 m, tapering campanile/spire to 330 m; silhouette narrows continuously — 0 stacked-cylinder segments.
- Parts: legs 4 (lattice, iron-brown #4A3A30, metallic 0.6, roughness 0.55); platforms 2 + summit 1; lattice members as textured alpha/PBR truss at Fidelity 3, normal-mapped truss texture at Fidelity 1–2 (never solid cones); elevators/glass details Fidelity 3 only.
- Details: warm rim from sun on the right edges; aerial haze ≤20% blend at its distance (it must stay the sharpest distant object).

### 4.2 Haussmann city blocks (refs: view360-paris.jpg)
- Massing: perimeter blocks 18–28 m wide, 12–22 m tall (4–7 storeys, storey 2.8–3.2 m), height:width 0.5:1–0.9:1; continuous street wall, 0 detached slabs in inner Paris.
- Parts per block: limestone facade 1 (#D6C5A3, 2048 px at F2, stucco normal map); mansard roof 1 (slope 45–60°, #46525E, dormers 1 per 3–4 m of eave); windows grid (0.9×1.6 m, spacing 1.8–2.4 m horizontal, floor pitch 2.8–3.2 m, dark glass #2E3A40, roughness 0.2, shutters on ≤30%); balconies/railings Fidelity 2–3 (thin rails at floors 2 and 5); chimneys 1 per 8–12 m of ridge.
- Variation: ≥6 facade albedo variants, hue shift ≤±4%, value ±8%; grime gradient bottom 1.5 m darkened 15%; 0 repeated identical adjacent blocks.
- Roofscape fills foreground to frame bottom at spawn (nearest blocks at 0.78–1.0 H), as in the ref foreground row at ≈ y 62–78% of the phone screen.

### 4.3 Seine, bridges, embankments (refs: view360-paris.jpg)
- River path: S-curve entering at ≈0.52 W / 0.50 H, exiting bottom-left at 0.16 W / 0.73 H (viewport ratios); width 80–120 m (≈0.30 W at foreground), banks at 0 m, water level −4 m below quay.
- Water: PBR #2C5566, roughness 0.08–0.15, moving normal micro-waves; sun-glint path under the sun azimuth (sparkle #FFEFC4 at Fidelity 3, smooth sheen at F1–2); reflections of quays/trees blurred, never mirror-sharp at F1.
- Embankments: stone quay walls #8A8274 both banks full length; tree line both banks (§4.4); bridges ≥3 in view (stone arch, span = river width, deck +6 m, balustrade), first bridge at ≈0.55 W / 0.52 H.

### 4.4 Terrain, streets, vegetation (refs: view360-paris.jpg)
- Terrain: real DEM relief; gentle hills at horizon 0.40–0.44 H, far ridge height ≤0.04 H above horizon line; slope shading (grass #5A7A3C <25°, rock #6E6A62 ≥35°, forest on slopes); pavement #8A8274 in urban flat, grass #5A7A3C in parks; 0 bleached near-white ground (max ground luminance 0.85 under §3.3 light).
- Streets: asphalt #4C4C4E with pavement edges, follow block grid, sit flush (offset ≤0.05 m, 0 floating planks); crossings/lane marks Fidelity 3 only.
- Trees: 2 species (broadleaf sphere-canopy on 3–4 m trunk, pine cone-canopy), canopy Ø 4–7 m, greens #4C6B2E ±10% hue/value variance, instanced; rows along both quays at 8–12 m spacing and in every park; density per §3.4; 0 bare-cone trees (cones only as pine canopy with needle texture at F2–3).

### 4.5 Sky and distant city (refs: view360-paris.jpg)
- Distant city: block silhouettes continue to horizon, density thinning after 1.5 km, fully hazed (§3.3) by 3 km; modern towers cluster only on the ref's horizon line (≈0.48–0.55 W), height ≤0.02 H above horizon.
- Clouds/sky per §3.3; sun disc + glow at 0.62 W / 0.37 H on spawn view.

### 4.6 Picker screen (refs: picker.png) — scenery-adjacent UI, judged only for launch framing
- Portrait layout: title "Planet Render 360" at 0.17 H; search pill (full width −32 px margins, radius 16 px) at 0.21–0.26 H; map fills 0.30–0.82 H centred on Europe (France centre ≈0.46 W / 0.50 H of screen); teal pin (#3E8F88, 28×36 px) on Paris; bottom card (radius 20 px, #FFFFFF) at 0.72–0.89 H with "Paris, France" 22 px bold #1A1A1A, coords "48.8566° N, 2.3522° E" 14 px #6B7280, button "Render 360 View" (#63908C–#3E8F88 teal, radius 12 px, height 52 px). Tapping it opens §4.1 spawn view. In-360 chips (location pill top-left, compass top-right, "Drag to look around" bottom-centre, teal outline #42948E) match view360-paris.jpg positions within ±2% W/H.

## 5. Interaction (360 view, replaces games-only section)

- Core loop: pick place on map (§4.6) → generate → free-look 360° → pick next place. No score, lives, or win state.
- Controls: drag (touch/mouse) look-around, yaw 360° continuous, pitch clamped −60°/+60°, inertia damping 0.15 s; pinch/scroll zoom FOV 45–75°; compass chip re-centres north on tap.
- States: Picker → Loading (progress by generation stage) → 360 View → back to Picker. Fidelity switch (1/2/3, §3.4) in 360-view settings applies in ≤2 s without regenerating the place.
- HUD: only the chips in §4.6; no HUD element covers >8% of frame area; "Drag to look around" fades after first drag or 4 s.
- Feedback: loading progress bar teal #3E8F88; fidelity change shows a 1 s toast naming the new tier; no screen shake, particles, or game juice.
- Animation: water flow and cloud drift ≤0.5 m/s apparent; trees static (wind sway ≤2° Fidelity 3 only). No camera auto-rotation.
- Audio: none required.

## 6. Technical constraints

- Tool/engine: Godot 4.7.2 (standard build), GDScript, existing OSM/DEM generation pipeline; Blender offline only for landmark asset prep; class files under `scripts/` ≤1000 lines (`tools/check_class_size.sh` passes).
- Required outputs: in-app 360 view (no exported still required); judging captures 1920×1080 PNG from the Paris spawn view + 4 yaw quadrants (0°/90°/180°/270°).
- Data: free sources only (OSM/OpenFreeMap-class vectors, public DEM, CC0 textures) with attribution; generation ≤3 min per place, cached thereafter.
- Performance: Fidelity 1 ≥30 fps on mid-tier phone; ≤6 shared facade/roof materials for distant blocks (instancing/shared resources, no per-building unique materials beyond 150 m); draw calls ≤400 at Fidelity 1.
- Fidelity options persist per user; default Fidelity 2 (§3.4).

## 7. Work breakdown

1. Photoreal baseline: tonemapping, §3.3 sun/fog/sky rig, photographic ground/water PBR at Fidelity 2; grey-box Paris spawn framing (§4.1 ratios).
2. City fabric at true scale: §4.2 blocks (window grids, mansards, dormers), §4.3 Seine/bridges/quays, flush streets.
3. Landmark: §4.1 lattice Eiffel asset (Blender prep if needed) at true proportions; distant city + §4.5 haze closure.
4. Vegetation and terrain finish: §4.4 two-species instanced trees, DEM slope shading, park/quay rows.
5. Fidelity tiers: §3.4 texture/shadow/density/reflection switches + settings UI + persistence; Fidelity 1 impostor ring.
6. Clouds, glints, bloom (Fidelity 3), final captures at 5 yaws, acceptance pass (§8).

## 8. Acceptance criteria

- AC-01 (view360-paris.jpg): Spawn framing matches: horizon at 40–44% H, Eiffel centreline 0.36 W ±0.02, spire 0.28 H ±0.02, base 0.51 H ±0.02, sun glow 0.62 W / 0.37 H ±0.03.
- AC-02 (view360-paris.jpg): Seine follows §4.3 S-curve (entry 0.52 W/0.50 H, exit 0.16 W/0.73 H, each ±0.04) with ≥3 bridges and tree-lined stone quays on both banks.
- AC-03 (view360-paris.jpg): 0 low-poly facets or flat-shaded scenery surfaces visible at Fidelity 2–3 in any of the 5 judging captures; every wall, roof and ground plane shows PBR texture.
- AC-04 (view360-paris.jpg): Blocks read photoreal Haussmann: 4–7 storeys, window grid 1.8–2.4 m pitch, slate mansards 45–60° with dormers; no non-landmark building >2.0× neighbours.
- AC-05 (view360-paris.jpg): Facade albedo reads #D6C5A3 limestone (lit #EBDCBE / shadow #9C8D73) and roofs #46525E under §3.3 light — not orange, white, or grey-plastic.
- AC-06 (view360-paris.jpg): Eiffel Tower reads as 4-leg lattice with 2 platforms and continuous taper (§4.1); 0 stacked-cylinder or solid-cone segments; sharpest distant object (haze blend ≤20%).
- AC-07 (view360-paris.jpg): Golden-hour grade holds: sky #7FA8CC → #F0C48F, sun #FFD9A3 at 8–12° elevation, far field (≥800 m) blended ≥70% to #EFD2A4; no void band or hard terrain edge at any yaw (0°/90°/180°/270°).
- AC-08 (view360-paris.jpg): Water is photoreal: #2C5566 PBR with moving micro-normals and a sun-glint path under the sun; not a flat blue polygon (the ref's faceted river fails this).
- AC-09 (view360-paris.jpg): Ground never bleaches: max urban-ground luminance 0.85; pavement #8A8274, grass #5A7A3C, DEM slope shading visible on horizon hills.
- AC-10 (view360-paris.jpg): Trees are 2 textured species (broadleaf + pine), canopy Ø 4–7 m, quay spacing 8–12 m, hue variance ±10%; 0 bare-cone trees.
- AC-11 (view360-paris.jpg): Clouds are photographic/volumetric-look in the 28–40% H band with #E8C9A0 lit undersides; 0 faceted cloud slabs.
- AC-12 (picker.png + view360-paris.jpg): Three fidelity options exist, Fidelity 2 is default, switching applies in ≤2 s and moves 0 objects / shifts 0 hues >2% (only §3.4 columns change).
- AC-13 (picker.png): Fidelity separation is visible side-by-side: F1 ≤1024 px textures/1024 shadows, F2 2048 px/2-cascade shadows + planar reflections, F3 4096 px + bloom 0.3 + glint sparkle + props (lampposts every 25 m).
- AC-14 (picker.png): Fidelity 1 runs ≥30 fps on a mid-tier phone at ≤400 draw calls with ≤6 shared distant facade/roof materials.
- AC-15 (picker.png): Picker matches §4.6 geometry within ±2% (title 0.17 H, search 0.21–0.26 H, pin on Paris, card 0.72–0.89 H, teal #3E8F88 button "Render 360 View") and launches the §4.1 spawn view.
- AC-16 (view360-paris.jpg): In-360 chips match ref positions within ±2% W/H (location top-left, compass top-right, drag hint bottom-centre, teal #42948E) and cover ≤8% of frame in total.
- AC-17 (view360-paris.jpg): Drag look covers 360° yaw × −60°/+60° pitch with 0.15 s damping and FOV zoom 45–75°; scenery (§4.2–4.5) is continuous with no style change off-frame.
- AC-18 (view360-paris.jpg): Side-by-side with a golden-hour Paris photograph at the same spawn, a viewer calls the F3 capture photorealistic scenery (real stone/slate/water/foliage), with the ref's layout (§4.1–4.3) still recognisable and no major visible difference in landmark, river, or block placement.

## Polish round 1 — Fidelity 3 photoreal pass (implemented)
- Golden-hour rig (view_360.gd): sun #FFD9A3 floored at 8-12° elevation, ACES exposure 0.94, sky zenith #7FA8CC → horizon #F0C48F, exponential haze to #EFD2A4, bloom 0.10, soft stratocumulus puff band; every place spawns at 17:00 golden hour.
- Photoreal surfaces (terrain_builder.gd): procedural limestone facade texture (6 storeys × 6 bays, French windows, shutters ≤30%, balcony rails, cornices, base grime, 6 tint variants), slate-tile mansards, leaf-speckle canopies (3-crown broadleaf, 3-tier pine, ±10% variance), PBR Seine (#2C5566, roughness 0.10, reflective), grain detail texture on all non-satellite ground, satellite imagery toned under the 0.85 luminance cap.
- Landmark: Blender Eiffel asset (assets/eiffel.glb, 37 lattice meshes) flattened into the landmark root; procedural lattice fallback gained cross-bracing, rings, arches and iron #4A3A30 metallic 0.6.
- Verified: screenshot_test Paris + Interlaken captures; landmark/scenery/settings/smoke/flow tests pass. Remaining gap vs AC-18: satellite-draped ground still streaks over the compressed DEM and off-frame Paris fabric is procedural (OSM 502 during capture), so a golden-hour photograph side-by-side would still read as stylised-realistic, not yet photographic.

## Polish round 1

Differences from `visual-plan/reviews/accept-r1-shape.md` and `visual-plan/reviews/accept-r1-look.md` (capture `03b-view360-desktop.png` vs `visual-plan/refs/view360-paris.jpg`, phone-screen content only), major and moderate only, highest impact first. Owner is the code part that owns each item; fixes in this round were applied in `scripts/generation/terrain_builder.gd` where that file is the owner (or co-owner via `_landmark`).

### Framing, silhouette, missing parts

- [major] Camera at ground eye-level, ~0° pitch, vs elevated aerial looking slightly down over the city — owner: `View360.show_location` / `CameraRig` in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd); co-owner `TerrainBuilder.landmark_world_pos` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd).
- [major] Eiffel Tower cropped at top, only ~40% of height visible, vs 100% base-to-spire at ~38% of viewport height — owner: `TerrainBuilder._landmark` / `landmark_world_pos` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file: a landmark pulled in from its true site is scaled down (apparent-size compensation) so the whole tower fits the spawn frame.
- [major] Tower legs are thick curved single pipes vs a slender 4-leg lattice A-frame with 2 platforms and arched base — owner: `LandmarkBuilder._eiffel_asset` / `assets/eiffel.glb` (`assets_src/blender/build_eiffel.py`), fallback `LandmarkBuilder._eiffel` in [landmark_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/landmark_builder.gd).
- [major] Seine river 0 visible vs 1 wide blue river ~35% of viewport width across the middle — owner: `TerrainBuilder._water` and the water carve in `TerrainBuilder._heights` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd), fed by OSM water polygons (`OsmFetcher` / `GenerationPipeline`). Fixed in this file: the carve now cuts below the water plane (`water_level - 0.55`) instead of above it, so the water plane actually shows in the channel.
- [major] ~15 sparse building blocks vs ~300+ dense Haussmann blocks filling the midground — owner: `TerrainBuilder._buildings` (procedural fallback), `_real_buildings`, `_city_silhouette` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd), budgets in `RenderSettings`, data from `OsmFetcher`. Fixed in this file: denser procedural infill (2× count, 15–98 unit ring instead of a 38-unit hole around the camera) and the hazy silhouette ring now also runs when OSM data is absent.
- [major] Dark mottled satellite ground over ~50% of the foreground vs pale beige city/terrain ground — owner: `TerrainBuilder._terrain_mesh` and `_heights` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file: brighter warm satellite drape, stronger low-relief flattening so the city floor stops reading as dunes.
- [major] Opaque dark bottom sheet ~42% × 35% (Time/Season/fps/attribution) vs no sheet, only a translucent drag pill and a thin curved ruler — owner: `View360._ready` bottom sheet in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).

### Colour and material

- [major] Tower smooth glossy copper-orange ~#B06A32, ~0% lattice read, vs matte dark iron-brown ~#3A2A22 — owner: `assets/eiffel.glb` materials via `LandmarkBuilder._eiffel_asset` in [landmark_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/landmark_builder.gd). Fixed from [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd): `TerrainBuilder._landmark` now overrides the Eiffel meshes with dark iron (#3A2A22, metallic 0.45, roughness 0.58).
- [major] Terrain dark mottled satellite texture ~#3E4A3A/#6B6F5E with wet gloss vs matte faceted sage/beige ~#CFC39E/#A8B08A, high roughness — owner: `TerrainBuilder._terrain_mesh` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file (see above).
- [moderate] Roofs flat dark green/black ~#2E3B33 (sampled pale-green in capture) vs pitched slate blue-grey ~#6B7C8C / PRD slate #46525E with mansard form — owner: `TerrainBuilder._mansard`, `_roof_mat`, `_slate` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file: green-dominant satellite roof samples (vegetation/shadow) now fall back to the slate material.
- [moderate] Facades plain beige ~#E8D9B0 with 0 visible windows vs cream ~#EAD9B5 with dense small dark windows — owner: `TerrainBuilder._facades` / `_building` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file: darker glass, thinner sky-reflection band so the window grid reads at distance.
- [moderate] Trees oversized bright lime lollipop spheres ~#6ED43A vs small muted olive ~#7A8F5A clusters — owner: `TerrainBuilder._vegetation`, `_broadleaf`, `_leaves`, `_card_mat` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd). Fixed in this file: smaller canopies (r 0.72–1.12), smaller crown core, dimmer leaf cards.

### Lighting, shadow, background

- [major] Sky flat pale blue ~#B9D6EA over the upper 60% vs warm golden-hour peach/cream gradient ~#F7E3C2 → #F2C99A; no sun glow vs low sun with warm glow ~#FFDF9E at ~62% width / ~36% height; flat even midday light vs warm directional sunset from the right with haze — owner: `View360._build_3d`, `_apply_time`, `_build_clouds` in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [major] Clouds 4 thin flat white discs vs ~8 soft layered volumetric sunset clouds (~25% of sky) — owner: `View360._build_clouds` in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [major] Shallow empty haze to a flat plain vs layered hills and distant skyline across 100% of the width behind the city; washed pale hills with near-zero contrast vs warm beige/sage faceted hills — owner: `TerrainBuilder._far_terrain`, `_far_ground`, `_city_silhouette` in [terrain_builder.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/generation/terrain_builder.gd).
- [moderate] ~0% visible shadows under buildings/trees/tower vs soft long warm shadows cast left — owner: `View360._build_3d` sun/shadow setup and `QualityGovernor` in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).

### Detail

- [moderate] Compass a white rounded rectangle "N ↑" vs a circular teal-ring compass with filled teal needle — owner: `View360._ready` top bar in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [moderate] Two opaque white top-left pills (red pin, extra "← Map") vs 1 translucent pill with teal pin and teal outline — owner: `View360._ready` top bar in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [moderate] Drag hint as white text inside the dark panel vs a centred translucent pill with finger-drag icon, "Drag to look around" only — owner: `View360._ready` bottom sheet in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [moderate] No curved azimuth ruler vs 1 curved teal-to-white ticked ruler spanning ~55% of the bottom width; no bottom-right circular buttons vs 2 circular translucent teal-outline buttons — owner: `View360` HUD in [view_360.gd](/Users/petri.tuononen/GithubProjects/planet-render-360/scripts/screens/view_360.gd).
- [minor, not listed as fixable in-app] Reference is a landscape phone mockup on a dark backdrop; the capture is the full-bleed desktop viewport — presentation only, owner: none (reference framing, PRD §2).
