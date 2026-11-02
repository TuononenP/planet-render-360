# Ultra review p5–p8 — 2026-11-02 (rainy nights, skyglow, regional lamps, landmark floodlighting)

`tools/capture_presets.gd --preset=3 --places=paris,new_york,tokyo,london --weather=61 --times=golden,late`
(this folder), then `--places=london,new_york --times=late` in `../ultra-p7d-2026-11-02/` for the final
floodlight spacing. `--weather=61` forces light rain under a full deck.

**Use `--times=late` for night shots, not `night`.** The `night` shot jumps to moonrise. On these dates that
lands with the sun still up (`night_amount` 0 in Paris), so `*_vantage_night.jpg` is a grey dusk and tells
nothing about night lighting. `late` is two hours after sunset.

## Changes

- **City skyglow** (`AtmosphereRig`):
  - **Problem:** an overcast night over a city was blue-grey, or pure black at full dark.
  - **Fix:** the night deck now takes a warm orange-grey (`CITY_DECK`), plus an added `CITY_SKYGLOW` on the
    cloud base and the low sky. Both scale with `city_glow`: mapped buildings / 1500, so countryside stays
    dark. Strongest under full cover.
- **Regional road markings** (`RoadSurface`, all tiers, a material parameter only):
  - Yellow centre lines in North and Latin America, Norway and Finland, chosen by ISO country.
  - With no known country, by longitude (the Americas).
  - Lane dividers, edge lines and zebras stay white.
- **Regional lamps** (`StreetProps.lamp_family`, `StreetLights.HEADS`). Main roads keep the modern arm
  luminaire, except in North America and Paris.
  - North America: galvanised cobra-heads on every road, smaller on side streets.
  - British and Irish side streets: black heritage lantern posts.
  - Japanese, Korean and Taiwanese side streets: concrete utility poles with a crossarm, insulators and a
    bracket lamp at 5.5 m.
  - Ultra street lights sit at each style's own lamp head.
- **Landmark floodlighting** (`LandmarkLights`, desktop Ultra, registry heroes):
  - **Eiffel Tower and Tokyo Tower** glow in their lamp colour (gold, orange) at night, through per-instance
    surface overrides. The shared mesh is not touched; `CityLights.apply` now reads overrides too.
  - **Square landmarks** get 4 shadowless ground spots around the base.
  - **Long landmarks** (footprint longer than 2× its width): paired spots along both long sides, one per
    ~70 m and at most 6 per side. Each stands back from the face by half the depth and is aimed at it, with
    wide soft-edged cones that overlap.
  - **Example:** the Palace of Westminster gets light on the Victoria and Elizabeth Towers, not just its
    middle. The Brooklyn Bridge towers are lit.
- **Road decals** (`RoadDecals`, desktop Ultra): cast-iron manhole covers in the lanes (one per ~38 m) and
  gutter grates at the kerbs (one per 24 m, alternating sides). They are on lit urban streets within 300 m,
  nearest 700 kept, faded out from 140 m. Decals project onto the draped ribbon, so they add no geometry.
  Captured in `../ultra-p7e-2026-11-02/` (golden close-ups). At the close-up framing they are a few pixels
  each; a street-level shot is still needed to judge them.
- `WorldCache.BUILD_VERSION` 43.

## Seen

- **Paris (late):** the Eiffel Tower is gold against a brown-orange deck, and the Trocadéro pavement shines
  wet. Before this pass the same frame was black (luma 0.000); it is now 0.050, saturation 0.57. The deck
  was 0.69 before `CITY_DECK` was desaturated.
- **New York (late):** towers lit floor by floor (the Phase 4 firewall fix), reflections in the East River,
  and the Brooklyn Bridge tower floodlit.
- **Tokyo (late):** signs, shopfront pools on wet streets, utility-pole lamps on the side streets.
- **London (late, p7d):** the palace front is washed, with Victoria Tower, the central spire and the
  Elizabeth Tower lit, and Big Ben's dials glowing. Faint cone scallops remain along the river front.
- **Build times** at Ultra: 15–21 s per place (London 52–85 s when not cached).

## Open

- **Floodlight scallops** on the long palace front: try a per-landmark aim, or a few more, weaker spots.
- **Golden-hour rain** showed a hard sun glint on the water under a full deck (`new_york_close1.jpg`).
  Fixed after this capture: the sun's specular now fades to 0.12 under full overcast (`sky_test`). Not yet
  re-shot.
- **Palm-like trees** on the Manhattan shore in `new_york_close1.jpg`, about 800 m out. NYC resolves to the
  temperate mix, which has no palms, so this is probably the far-tree LOD silhouette. Needs a closer check.
- **Moonrise shot:** `--times=night` should probably clamp to after dusk, or be replaced by `late`.
