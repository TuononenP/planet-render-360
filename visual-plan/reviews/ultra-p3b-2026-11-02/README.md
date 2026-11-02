# Ultra review p3 — 2026-11-02 (Ultra pass, Phase 3 facade shader + first Phase 4/5 pieces)

`tools/capture_presets.gd --preset=3 --places=tokyo,london,paris --times=golden,late` (`late` is new: two
hours after sunset, full dark; the moon jump can land in a bright moonlit sky with the windows barely on).
Earlier run `../ultra-p3a-2026-11-02/` (New York, Paris, Dubai at golden and moon-night) checked that the
shader compiles and nothing regresses; `../ultra-p3j-2026-11-02/` (Paris then Tokyo, golden and late) is the
final state after the fixes below.

## Changes

- **`FacadeShader`** (desktop Ultra: Ultra on Forward+, `RenderQuality.ultra_desktop`). At the end of the
  building build every facade material (meta `facade_set`) is swapped for one shared shader material that
  reads the same composed textures and adds: a traced room behind every pane (back wall, floor, ceiling,
  side walls, furniture, curtains, blinds from a per-pane hash), night windows decided per pane from the
  building's occupancy and the clock (homes peak near 21:00, offices empty after 20:00), per-room colour
  temperature and the odd TV, low-roughness glass with a fraction of a degree of tilt per pane, and
  world-space grime, hue and rain-streak noise. On tiled facades the wall photo's full 1K grain comes back
  over the composer's 64–128 px copy (the full-size photo over its own mip at the composer's scale).
  `CityLights` drives its night energy and clock (`CityLights.hour`, set by `AtmosphereRig.set_time`).
- **Wider Ultra detail rings**: facade relief to 650 m, cornices/parapets and roof detail to 700 m (inside
  `LodRing.DETAIL_M`'s 700 m). Lower tiers keep 300 / 320 / 250 m. AC-12 relaxation recorded in
  `docs/fidelity-scorecard.md`, `visual-plan/PRD.md` and `RenderSettings`' header.
- **Street-lamp light** (`StreetLights`, desktop Ultra): the nearest 320 lamps get a shadowless,
  distance-faded omni (lanterns) or downward spot (cobra heads), sodium / warm / neutral by region, on from
  dusk. Lamp glass now glows only at night on every tier (it glowed at 1.4 all day).
- **Floating slabs** (New York): a lifted `building:part` outside every outline with nothing under it now
  stands on the ground; skybridge-sized parts keep their lift (`OsmParser._ground_orphans`).

## Seen

- Tokyo late: buildings light pane by pane, the curtain-wall tower stays mostly dark (offices), vertical
  signs glow; faint lamp pools under the trees. Two faults, both fixed for p3c: the building seed came
  from the vertex colour, which the foot shade darkens toward the ground, so it interpolated across the
  wall and the pane hash turned to static (by day too); and too many rooms were lit at 21:00.
- London late: the Palace of Westminster glows window by window, the clock faces are lit, the blocks
  around it are only partly lit.
- Paris late: dark sky, but the plaza and lawns stay bright (the night exposure lift, "the eye adapts"),
  which mutes the lamp pools; the Eiffel Tower is unlit (Phase 8 landmark floodlighting).
- Build times stay well inside the Ultra budget (Tokyo 10.6 s buildings, 60 s total per place).

## Fixed after this run (final: `../ultra-p3j-2026-11-02/`)

- **Static in the panes, day and night.** The building seed hashed an interpolated value: the foot shade
  darkens a wall's lower vertices and vertex colours are 8-bit, so the chromaticity differed between
  vertices, interpolated, and hashed to a new value on every pixel. The seed is now coarsely quantized
  chromaticity in a `flat` varying. Bisected by switching tilt/specular, then emission, off.
- **Rooms alias when small.** A room's furniture and wall/floor edges are a few pixels across at street
  distance; below ~80 px a pane the room fades to its average colour (flat by ~30 px).
- Post-parallax lookups use the surface's derivatives (`textureGrad`); the combined normal is kept inside
  the unit disc (Godot rebuilds z from xy); pane roughness 0.12–0.18.

## Open: Ultra's first place renders without indirect light

With Tokyo as the first place of a session at Ultra, everything out of direct sun loses its sky/indirect
light (black shadowed ground, dark walls; Tokyo building band luma 0.13 vs 0.25). Reproducible:
Tokyo after Paris is fine (0.41), Tokyo first at High is fine (0.49), Paris first is fine. Not the facade
shader (same with it off), not SDFGI convergence (same after a 10 s settle) and not fixed by restarting
SDFGI. Likely the same fault as the black foreground in the baseline New York vantage. Captures that
need a correct first place should run another place first; to fix in the lighting pass (Phase 5).
