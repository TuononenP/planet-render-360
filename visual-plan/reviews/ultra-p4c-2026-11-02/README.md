# Ultra review p4 — 2026-11-02 (Phase 4: rooftop clutter, building cap, floating parts)

`tools/capture_presets.gd --preset=3 --places=tokyo,new_york,dubai --times=golden,roofs`.
`--times=roofs` is new: the opening look from 140 m higher, pitched down, because street-level shots never
show a roof. Tokyo is first in the run on purpose. Since the settle fix (`_settle` forces 240 draws) the
first place is lit correctly; see `../ultra-p3b-2026-11-02/README.md`.

## Changes

- **`RoofClutter`** (desktop Ultra, flat roofs, inside the 700 m detail ring). Each city or region gets
  its own mix:
  - New York: cedar water towers on steel legs.
  - East Asia: banks of 3–6 AC condensers, one bank per ~250 m² of roof up to 5, with steel tanks and
    sign frames.
  - Gulf, Cairo and South Asia: white and black water tanks and dishes.
  - Greece, Cyprus and Israel: solar water heaters.
  - Elsewhere: skylights, plus solar arrays on big roofs.
  - Every region: a concrete stair or lift overrun on most roofs over 150 m², hatches and masts.
- **Building cap** on desktop Ultra raised from 6000 to 10000.
- **Rooftop-only parts.** 375 Pearl Street, New York, maps its outline at 155 m and only two penthouse
  `building:part`s, both lifted to 155 m. The builder draws parts instead of the outline, so the penthouses
  floated as a dark slab beside the Brooklyn Bridge. When every part of a building is lifted, its outline
  now stands from the ground to the lowest part (`BuildingMasses._missing_base`). Skybridges, canopies and
  lifted outlines keep their gap.
- `WorldCache.BUILD_VERSION` 40.

## Seen

- **New York:** the slab is gone. 375 Pearl stands as a full tower right of the bridge
  (`new_york_vantage.jpg`).
- **Tokyo from above:**
  - Every mid-rise block carries an overrun.
  - The condenser banks read as rows of light dashes. At 140 m they are a few pixels each, so they add
    texture rather than objects.
  - The roofs themselves are membrane-flat, as `architecture_cities_asia` says. The diagonal seams in the
    membrane texture look like hips from above.
- **Dubai:** the roofs shot lands among the Downtown towers, looking down on the fountain lake, so no
  low-rise roofs are in frame. Dubai's tanks still need a vantage over Deira or Bur Dubai.
- **Build times** at Ultra: Tokyo 21 s, New York 20 s, Dubai 12 s (buildings 11.7 / 10.7 / 6.0 s). That is
  far inside the longer first build.

## Open

- Condensers and tanks are untextured primitives. A grille or fin normal map would help them read at
  street distance.
- `fidelity_scorecard_test` fails Turku's DEM check (a), with ground 5–13 m low at 4 of 9 points. This is
  not from these changes, which touch only building masses. The terrain and underpass work in progress is
  the likelier cause.
