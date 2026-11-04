# Bundled OpenStreetMap snapshots

These gzip files are OpenStreetMap data © OpenStreetMap contributors,
available under the [ODbL](https://www.openstreetmap.org/copyright). The
app's existing OSM attribution applies. They cover only the preset origins,
not the cities as a whole. The query and integrity metadata is in `scripts/data/bundled_osm.gd`.
Timestamps are the Overpass `timestamp_osm_base` in UTC.

| Preset | Coordinates | Layer / query | OSM timestamp UTC | Compressed bytes |
| --- | --- | --- | --- | ---: |
| New York | 40.7060, -74.0040 | detailed / q12 | 2026-11-04 13:18:25 | 2,182,136 |
| San Francisco | 37.8040, -122.4195 | detailed / q12 | 2026-11-04 13:16:20 | 1,384,265 |
| Helsinki | 60.1680, 24.9530 | far city / q3 | 2026-11-04 14:47:51 | 3,012,547 |
| Stockholm | 59.3207, 18.0604 | far city / q3 | 2026-11-04 14:07:04 | 2,273,021 |
| Helsinki | 60.1680, 24.9530 | detailed / q12 | 2026-11-02 21:21:26 | 2,087,998 |
| Helsinki | 60.1680, 24.9530 | ring 1600 m / q1 | 2026-11-02 21:21:26 | 140,562 |
| Helsinki | 60.1680, 24.9530 | ring 2500 m / q1 | 2026-11-02 21:21:26 | 197,580 |
| Helsinki | 60.1680, 24.9530 | POI / q1 | 2026-11-02 21:21:26 | 128,922 |
| Stockholm | 59.3207, 18.0604 | detailed / q12 | 2026-11-02 21:21:26 | 1,794,330 |
| Stockholm | 59.3207, 18.0604 | ring 1600 m / q1 | 2026-11-02 21:21:26 | 71,040 |
| Stockholm | 59.3207, 18.0604 | ring 2500 m / q1 | 2026-11-02 21:21:26 | 119,405 |
| Stockholm | 59.3207, 18.0604 | POI / q1 | 2026-11-02 21:21:26 | 72,530 |

The November 2 Helsinki and Stockholm responses came from the Europe
Overpass instance at `https://ovp.dresel.systems/api/interpreter` on
2026-11-04. They have no runtime error and match the current queries, but
retain the queries' per-layer output caps: both Helsinki rings and the
Stockholm 2500 m ring reached the highway cap, and Helsinki's 2500 m ring
also reached the waterway cap. Those layers may omit mapped features.

New York and San Francisco still lack bundled far-city, ring and POI data;
the global Overpass instances were unavailable when queried. Those layers
retain the normal live fetch and fallback behavior.

To replace one of these files, obtain a complete current-query response from
the app's cache at the exact preset origin, then run, for example:

```sh
python3 tools/prepare_osm_snapshot.py detailed /path/to/current-cache.json assets/osm_snapshots/new_york_detailed.json.gz
```

Use `far`, `ring`, or `poi` for the other layer types. The tool rejects Overpass errors, missing
buildings and missing expected layers and prints the timestamp, uncompressed
length and SHA-256. Update the corresponding `BundledOsm.ENTRIES` row and this
record with those values and the current query version. Check layer coverage,
counts and coordinates against the query and source cache before committing;
the JSON does not itself prove which coordinates or query produced it. Run
`tests/bundled_osm_test.gd` and the OSM tests. Ring and POI query version constants must be bumped when those query shapes
change. Include and test both ring radii separately.
