# Alcatraz placement and exterior verification

**Waterfront follow-up:** the original `from_sf.jpg` failed review because
ordinary pier buildings were partly submerged. The refreshed capture and
[placement audit](../placement-audit-2026-11-03/README.md) supersede that
acceptance claim. Floors, ground-storey splits, party-wall heights and roof
jobs now share the water-aware datum.

Live DEM/OSM reproduced an island origin at **-48.60 m ASL** and an
opening camera at **-20.60 m ASL**. The visible ocean is at 0 m ASL.
The authored island was submerged and covered by the DEM/drape.

The island now uses an explicit sea-level base. Nearby and distant
terrain triangles yield to its footprint, with ocean under the distant
opening. Camera movement and saved views share the authored ground and
visible water level. The same placement works for a primary island visit
and a secondary landmark viewed from San Francisco.

The exterior has continuous coastal relief, graded building terraces,
PBR slope transitions between cliff/grass/gravel, concrete/stucco walls,
steel window sashes, roof monitors, lighthouse, water tower, industrial
buildings, dock, recreation yard and open ruin shells. Terrace elevations
are approximations. The lighthouse is modeled at 29 m above a 40 m terrace.

Reference sources:

- [NPS island layout](https://www.nps.gov/goga/planyourvisit/upload/Alcatraz-map-Access-508.pdf)
- [NPS lighthouse description: 95 feet](https://www.nps.gov/places/000/alcatraz-lighthouse.htm)
- [NPS cellhouse description](https://www.nps.gov/places/000/alcatraz-cellhouse.htm)

## Validation

- Current shared workspace: `alcatraz_test`, `preset_views_test`,
  `viewer_tools_test`, `world_cache_key_test` and `tools/check_class_size.sh` pass.
- An isolated checkout of `4cae994` plus the Alcatraz changes also passes
  `landmark_test`, `landmark_catalog_test` (445 landmarks), the four tests
  above, and the earlier `scenery_test` run.
- The island has **71,425 triangles**, below the 150,000 landmark limit.
- Live opening eye: **30 m ASL**; island origin: **0 m ASL**.
- Six initial off-screen captures were produced, including the real
  terrain/OSM visit and a separate mainland build where Alcatraz is a
  secondary landmark. No script or shader compilation errors in that run.
- Existing capture exit warnings remain: 7 texture RIDs and 5 objects.
  The mainland reports one unrelated OSM building using its AABB fallback.

## Captures

- [Arrival](arrival.jpg)
- [Dock and barracks](dock.jpg)
- [Cellhouse and recreation yard](prison.jpg)
- [Aerial overview](aerial.jpg)
- [Distant view](distant.jpg)
- [From San Francisco](from_sf.jpg)

Detailed output: `workspace-tests.log`, `isolated-tests.log`, `captures.log`.
