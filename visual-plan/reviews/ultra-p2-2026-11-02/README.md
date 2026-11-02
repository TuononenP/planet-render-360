# Ultra review p2 — 2026-11-02 (Ultra pass, Phase 2: styles that match the country and city)

`tools/capture_presets.gd --audit --preset=3 --places=seoul,dubai,monaco,alps,banff --times=golden,night`:
the five quick picks that had no city style before this phase. Compare with `../ultra-base-2026-11-01/`.

## Changes

- **Real country before the boxes.** The detailed Overpass query ends with an `is_in` statement that
  returns the viewpoint's `admin_level=2` area and its `ISO3166-1` code (`LocationData.country`).
  `ArchitectureStyle.country_region_for` applies a box only to the countries it lists, or where its region
  is among the country's `ArchitectureData.COUNTRIES` regions; otherwise it uses the country's own region.
  Fixed border cases (pinned in `tests/architecture_test.gd`): Kehl → German, Saint-Louis → French,
  Nice/Monaco → Mediterranean, Zagreb/Ljubljana → Central European, Turin → Italian (not the French Alps
  box), Lesbos → Greek, Vladivostok → Russian, Tijuana → Latin American, Nuuk → Nordic. Payloads cached
  before this change, the OSM API fallback and the mirror without an area database leave the code empty,
  and the boxes decide as before. Verified live on z.overpass-api.de (Kehl → `DE`); the other mirrors were
  at capacity.
- **Five quick-pick city zones**, each with era rows and cues: Seoul (apartment slabs, red-brick villas
  with green roofs, Bukchon/Ikseon/Seochon hanok, glass towers), Dubai (sand-render mid-rise, SZR /
  Downtown / Marina curtain walls, Al Fahidi coral stone, Jumeirah villas), Monaco (Belle Époque pastels,
  Le Rocher Genoese houses, Riviera terraced towers), Interlaken (Bernese chalets with half-hipped roofs,
  Höheweg grand hotels), Banff (Banff Avenue log and Rundle stone, verdigris heritage roofs, cottages).
- **34 more city zones** (Copenhagen, Oslo, Helsinki, Edinburgh, Dublin, Brussels, St Petersburg, Madrid,
  Lisbon, Milan, Florence, Istanbul, Athens, Vienna, Prague, Budapest, Munich, Kyoto, Shanghai, Beijing,
  Bangkok, Mumbai, Cairo, Cape Town, Toronto, Montreal, Boston, Washington, Los Angeles, Mexico City, Rio,
  Buenos Aires, Sydney, Melbourne), in `ArchitectureCitiesNorth/South/Central/World/NewWorld`. Their eras
  use a data-driven rule (`BuildingEra._banded`: storey band + heritage flag) instead of hand-written arms.
- The 200-building look census now covers all 66 zone cities and finds no two with the same dominant
  looks (Vienna was moved off Monaco's look to street-facing gables and stone-faced Ringstraße fronts).

## Seen

- Seoul (Gwanghwamun): white apartment slabs and a red-brick villa block now read Korean, not generic East
  Asian. Gwanghwamun gate itself is still missing from the view (landmark item, Phase 8).
- Monaco (Place du Palais): Le Rocher in the foreground is pastel Genoese stucco under hipped terracotta;
  distant Monte-Carlo is still generic far-city masses (Phase 4 far-city looks).
- Alps (Harder Kulm): the town is too small in frame to judge the chalets; needs a town-level control shot.
- Not done in this phase: regional photo-texture variants (`wv`) move to the Phase 6 asset pack, since
  they are new downloads and the plan keeps big assets desktop-only. More looks per era on Ultra and the
  regional window vocabulary belong to the Phase 3 shader.
