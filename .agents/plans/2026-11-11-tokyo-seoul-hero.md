# Tokyo & Seoul hero pass: tracker

> Approved plan 2026-11-11 (user: make Tokyo and Seoul look more realistic, especially building styles and the different
> areas of each city; full scope including streets and landmarks; keep the existing vantages). Both were already presets
> (Shibuya Crossing, Gwanghwamun Square) with bundled layers, so this is a realism pass in the shape of the SF one
> (`2026-11-03-san-francisco-hero.md`). Same rules: claim a task, tick it when its validation passes, one evidence line.

## Tasks

### Phase 1: baseline
- [~] **TS-1.1** Baseline captures
  > SKIPPED as a separate round: the first capture (`tokyo-seoul-r2-2026-11-11/`) already included the Phase 2–4 changes.
- [x] **TS-1.2** `visual-plan/refs/{tokyo,seoul}/` reference photos with licences — @claude/refs 2026-11-11
  > DONE: Tokyo 01–06, Seoul 01–05 (Commons, CC BY / BY-SA / CC0 / PD); the photos are gitignored. Missing: a daytime
  > elevated Shibuya shot and a danji with clearly painted block numbers.

### Phase 2: building styles and districts
- [x] **TS-2.1** New rows in `ArchitectureCitiesEastAsia`: `tokyo_zakkyo`, `tokyo_mansion`, `tokyo_house_modern`, `tokyo_mokuchin`,
  `seoul_danji`, `seoul_shopping`, `seoul_officetel` — @claude/tokyo-seoul 2026-11-11
  > DONE: rows plus BASE links; the Tokyo and Seoul era lists moved from `BuildingEra.CITY_ERAS` into the same file.
- [x] **TS-2.2** Structural rules `tokyo_rule` / `seoul_rule`, reading the most local district circle — @claude/tokyo-seoul 2026-11-11
  > DONE: architecture_test pins 12 Tokyo and 13 Seoul cases (by levels, roof, date, arch tag and district); ARCHITECTURE OK.
- [x] **TS-2.3** District circles: Shibuya (Center Gai, Dogenzaka, station east), Kabukicho, Ginza, Akihabara, Ikebukuro, Ebisu,
  Meguro, Aoyama, Nakano, Setagaya, Suginami; Seoul shopping streets, Gangnam/Mapo officetels, six danji areas, two villa belts
  — @claude/tokyo-seoul 2026-11-11

### Phase 3: facade relief and street cues
- [x] **TS-3.1** `AsiaFronts`: `danji_number` (seven-segment block number from the mapped "NNN동" name, else 101–130, under an
  accent band, on slab ends), `sign_bands` (a board per lower storey), `sign_stack` (full-height sign column) — @claude/tokyo-seoul 2026-11-11
  > DONE: `tests/asia_fronts_test.gd` PASS; keys in the `ArchitectureData` legend and `RELIEF_KEYS`.
- [x] **TS-3.2** `UtilityPoles`: JP/KR concrete poles every 30 m on one kerb with crossarms, transformers and bracket lamps (High+), and
  3–6 sagging cables plus service drops (Ultra desktop), at most 9 draw calls — @claude/poles 2026-11-11
  > DONE: `tests/utility_poles_test.gd` PASS. StreetProps' older "utility" lamp poles now skip the roads UtilityPoles carries.
- [x] **TS-3.3** Seoul villa and shop-street roofs get a water tank (`RoofClutter`) — @claude/tokyo-seoul 2026-11-11

### Phase 4: landmarks (batch `tokyo_seoul`)
- [x] **TS-4.1** Shibuya: Scramble Square (229.7 m), Hikarie (182.5 m), Stream (180 m), 109, QFRONT — @claude/landmarks 2026-11-11
  > DONE: sites from OSM ways (`docs/tokyo-seoul-landmark-sources.md`); the QFRONT screen uses the street-screen poster atlas (lit at night, r3).
- [x] **TS-4.2** Gyeongbokgung (Heungnyemun, Geunjeongjeon, walls, cloister), King Sejong and Admiral Yi statues; `LandmarkKoreanRoof` shared with Gwanghwamun — @claude/landmarks 2026-11-11
  > DONE: Gwanghwamun's vertices are unchanged against HEAD. Geunjeongjeon is 133.5k triangles, under the 150k catalog limit.
- [x] **TS-4.3** `tests/tokyo_seoul_landmarks_test.gd`, `docs/tokyo-seoul-landmark-sources.md` — @claude/landmarks 2026-11-11
  > DONE: TOKYO SEOUL LANDMARKS OK (10 models); catalog, fidelity and placement tests OK.

### Phase 5: review
- [x] **TS-5.1** Capture rounds r2 and r3 in `visual-plan/reviews/tokyo-seoul-r{2,3}-2026-11-11/`; scorecard §9 round ts-r3 (both recognisable, agent pre-rating)
  > r2 found Sejong-daero offices turned into danji. Fix: danji need an apartments or residential tag, a "NNN동" name, or a danji
  > district; untyped tall blocks within 2.5 km of a core become towers; "오피스텔" names become officetels.
- [x] **TS-5.2** Re-bake the preset thumbnails (tokyo.jpg, seoul.jpg) — @claude/tokyo-seoul 2026-11-11
- [x] **TS-5.3** `docs/architecture-styles.md` updated with the new rows, rules and keys — @claude/tokyo-seoul 2026-11-11

## Findings
- Fixed 2026-11-12: the core Gwanghwamun model now stands on the OSM gatehouse centre (37.575928,126.976817), and the palace walls
  end at their OSM ends inside its platform (r4 close-up). Large mall blocks in zakkyo districts (footprint > 900 m²) keep the
  general Tokyo fabric (`ZAKKYO_MAX_M2`).
- Code review 2026-11-12, all fixed: mirrored danji digits on counter-clockwise rings; telecom cables not scaled with the pole;
  pole spots checked before the radius test; a regex compiled per call; side-street lamps dropped beyond the pole cap (lamps now
  give way only within 15 m of a planned pole, and the plan is shared with the build); wooden rental flats within 2 km of a core;
  copied kind lists and MODERN pinned against BuildingEra by architecture_test.
- Most Tokyo buildings near Shibuya are `building=yes`. Those with ≥4 levels resolve to the "apartments" kind, so `tokyo_zakkyo`
  carries an apartments profile as well as a commercial one.
- Seoul OSM names some danji blocks "파크팰리스 103동"; AsiaFronts paints that number instead of a seeded one.
