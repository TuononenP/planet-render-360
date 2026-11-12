# Bridge structures, not bridge ways — plan

> Follow-up to the Niittykumpu overpass fix (RoadBridgeDecks). Written 2026-11-12.

## Status (2026-11-12, second pass)

- **Step 0: done.** The `niittyhuippu_close2` view is Länsiväylä crossing a creek on short parallel bridge ways. A layer-0 cycleway bridge ran along the creek under it at nearly the same height, so its parapets cut through the motorway deck.
- **B: done.** `Index.members_of` builds union-find groups of side-by-side ways once per world, under a mutex. Every member reads the widest ways' cached profiles, so chains share one level.
- **C: done.**
  - On another layer, the lower way dips under the upper one by CLEAR_PATH_M (3.4 m) or CLEAR_ROAD_M (5.4 m), down to its floor. A path's floor may sit 0.5 m over water. If it can't dip that far, the upper way rises to hide it (HIDE_M, 2 m) and eases in at the road grade.
  - On the same layer, a narrower way running onto a wider deck takes its height and leaves its parapets off there.
  - Every road bridge now goes through `RoadBridgeDecks.build`.
- **D: decided.** Rail stays separate unless A finds a shared structure.
- **E: done.** `WorldCache.BUILD_VERSION` went from 249 to 250. The OSM cache stores raw responses and re-parses them, so the unbuilt-road filter applies without a refetch.
- **F: done.** Glazed stacks are seeded per face, never in a face's end bays, and a glazed face of 3 or more bays always gets at least one stack.
- **A: open.** `osm_query.gd` and `postpass_fallback.gd` don't fetch `man_made=bridge`. Adding it changes the query (and with it the cached and bundled preset layers), which needs a decision on refetch cost.
- **Still visible at the creek:**
  - short parapet stubs where the mapped pieces end at different points along the motorway;
  - 0.2–0.3 m steps between neighbouring pieces.

  Building the deck once from the `man_made=bridge` outline (A) removes both.

## Context

OSM maps one overpass as several bridge ways: each carriageway, cycleway and footway, plus links that cross it. It often also draws the structure itself as a `man_made=bridge` area. RoadBuilder builds every way on its own.

`RoadBridgeDecks` now merges ways by a geometric heuristic. Ways that are parallel, road-only and within 8 m edge to edge share one level, drop the parapets that face each other, and fill the gap between them. That fixes the Haukilahdenkatu overpass, but it leaves these gaps:

1. **Ways crossing the structure keep their parapets.** The diagonal cycleway and short links get walls across the deck.
2. **Separate bridges can merge.** Twin river bridges up to 8 m apart become one deck, even when they are separate structures.
3. **Road beside rail is never merged.** Some structures really are shared, and those keep a gap and two parapets.
4. **The level is approximate.** Each way levels against its neighbours' raw lines, profiled one way at a time. This has three effects:
   - groups are not transitive (A–B–C);
   - a neighbour's BridgeLandings extension is ignored;
   - easing only smooths each way's own ends.
5. **Fill strips are single upward-facing sheets.** From below or from the side, the gap between decks is still see-through.
6. **Cached worlds and data keep proposed roads.** They stay until the parsed OSM cache is rebuilt.
7. **Glazed-balcony layout is crude.** Every face of a block repeats the same column pattern. A face with few bays often gets no stacks. The `glazed_balcony` weights are effectively halved.

### Still open from the Niittykumpu fix

The probe now shows both Haukilahdenkatu overpasses levelled in the real data:
- the north one, four ways, at about 4–5.5 m above the local ground;
- the south one, a road way plus a cycleway, at about 6.3–9 m.

But the `niittyhuippu_close2` capture taken from Niittyhuippu's 84 m eye still shows parallel walls across the bridge. The wall layout looks almost the same as before the fix.

**Step 0:** before A–F:
- Find which overpass that view shows, and which batch each wall comes from: `Road_deck` fascia on an open edge, parapet, or a `man_made=bridge` or other mesh. One way is a capture with the deck batch tinted.
- Check whether the open-edge fascias, which drop to `deck - 0.9 m`, read as walls where a fill strip sits above a lower deck.
- The scratch probe used this session (deck heights per way at any pin) should become `tools/probe_bridges.gd`.

## Approach

### A. Use the mapped structure: `man_made=bridge` areas (fixes 2, 3, 5 and most of 1)
- **Parse:** keep closed `man_made=bridge` ways and multipolygons in a new `data.bridge_areas` list, with `[ring, layer, bridge:structure]`. Today `OsmParser.parse_features` drops them.
- **Group:** every road, path and rail bridge way whose span lies more than 60% inside one area belongs to that structure. Ways with no area fall back to the current parallel heuristic.
- **Deck:** build the structure's deck once from its outline. That gives the slab, the underside and outer fascias along the outline, and parapets only on outline edges. The ways on it draw their surfaces (lanes, markings, cycleway paint) on that deck with no parapets of their own. Rail tracks on a shared structure keep their ballast bed.
- Code goes in a new `BridgeStructures` class, not in `road_builder.gd`, which is already at 983 of 1000 lines.

### B. Two passes: plan the decks, then build them (fixes 4)
- **Pass 1:** collect every bridge way's landed pieces (BridgeLandings plus `outside_spans`).
  - Profile each piece with its own width and layer.
  - Form groups with union-find over shared structures (A) or parallel pairs (fallback).
  - Give each group one level profile along its axis: the widest road's deck, and the highest one if several are equally wide.
  - Ease the ends at the road ramp grade.
- **Pass 2:** build each way with its group's level (`fit["deck"]`).
- This also replaces the per-way neighbour re-profiling, so cost becomes linear in the number of bridge ways.

### C. Ways crossing a structure (fixes 1 without an outline)
- A bridge way whose segment lies inside another group's deck footprint (the polygon unioned from its decks and fill) takes that group's level along the segment.
- Its parapets are open there and closed where it leaves the footprint.
- Links whose two ends both land on other decks get no parapets.

### D. Road beside rail (fixes 3)
- With A, a shared `man_made=bridge` decides.
- Without one, keep them separate. Today's behaviour is right for twin road and rail bridges such as Hakaniemi.

### E. Caches (fixes 6)
- Bump the parsed-OSM cache version so places re-parse once and drop proposed and demolished roads.
- Check that `WorldCache` invalidates saved worlds whose road batch predates the change.

### F. Glazed balconies (fixes 7)
- Seed the column pattern per building face (stretch index), not only per bay index.
- Guarantee at least one stack on a glazed face of 3 or more bays.
- Re-tune the `glazed_balcony` weights in `architecture_cities_finland.gd` to the intended share.
- Leave a reflex corner flat by checking the neighbouring stretch's angle, not only the end bays.

## Verification

- **OSM fixtures:** add trimmed fixtures in the style of `tests/fixtures/helsinki_skywheel.json`:
  - the Haukilahdenkatu overpass (four ways and two `man_made=bridge` areas);
  - twin separate road bridges;
  - a road bridge beside a rail bridge;
  - a switchback footbridge.

  Test each fixture's groups, its single level, that it has no interior parapets, and that separate structures stay separate.
- **Probe:** extend the scratch probe from this session into `tools/probe_bridges.gd`. It prints deck and ground heights per way and group for any pin.
- **Captures:** one batched off-screen run covering Niittykumpu, Kalasatama, Hakaniemi and Lauttasaari bridge. Then `bridge_arches_test`, `bridge_joint_test`, `rail_viaduct_test`, `scenery_test`, `train_test` and `road_bridge_decks_test`.
