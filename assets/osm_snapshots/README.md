# Bundled OpenStreetMap snapshots

These gzip files are OpenStreetMap data © OpenStreetMap contributors,
available under the [ODbL](https://www.openstreetmap.org/copyright). The
app's existing OSM attribution applies. They cover only the preset origins,
not the cities as a whole. The query and integrity metadata is in `scripts/data/bundled_osm.gd`.
Timestamps are the source replication time in UTC (Overpass `timestamp_osm_base`
for live responses).

| Preset | Coordinates | Layer / query | OSM timestamp UTC | Compressed bytes |
| --- | --- | --- | --- | ---: |
| New York | 40.7060, -74.0040 | detailed / q12 | 2026-11-04 13:18:25 | 2,182,136 |
| San Francisco | 37.8040, -122.4195 | far city / q3-compatible | 2026-11-02 21:21:26 | 534,698 |
| San Francisco | 37.8040, -122.4195 | detailed / q12 | 2026-11-04 13:16:20 | 1,384,265 |
| New York | 40.7060, -74.0040 | far city / q3-compatible | 2026-10-31 00:00:00 | 2,623,092 |
| New York | 40.7060, -74.0040 | ring 1600 m / q1-compatible | 2026-10-31 00:00:00 | 65,896 |
| New York | 40.7060, -74.0040 | ring 2500 m / q1-compatible | 2026-10-31 00:00:00 | 89,225 |
| New York | 40.7060, -74.0040 | POI / q1-compatible | 2026-10-31 00:00:00 | 73,593 |
| San Francisco | 37.8040, -122.4195 | ring 1600 m / q1-compatible | 2026-10-31 00:00:00 | 33,828 |
| San Francisco | 37.8040, -122.4195 | ring 2500 m / q1-compatible | 2026-10-31 00:00:00 | 62,009 |
| San Francisco | 37.8040, -122.4195 | POI / q1-compatible | 2026-10-31 00:00:00 | 27,320 |
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

The New York far-city, ring and POI layers and San Francisco ring and POI
layers were generated from BBBike's 2026-10-31 [New York](https://download.bbbike.org/osm/bbbike/NewYork/)
and [San Francisco](https://download.bbbike.org/osm/bbbike/SanFrancisco/) city
extracts; the San Francisco far-city layer comes from [Geofabrik's California
extract](https://download.geofabrik.de/north-america/us/california.html) dated
2026-11-02 21:21:26 UTC. They use the app's Overpass JSON format and query
caps, but are reconstructed from OSM
extracts using a local projected distance calculation; they are not literal
Overpass responses. The New York and San Francisco 2500 m rings hit the
800-highway cap. Missing or damaged snapshots still use the normal fetch and
fallback path.

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

## Regenerating extract-derived layers

Install `osmium-tool` and the Python `osmium` package, obtain a dated OSM PBF
whose bounds fully cover the required radius, and make a `smart` extract with
`osmium extract`. The conversion checks the supplied extract bounds and rejects
nearby relations with missing member geometry. It uses a local projected
point/segment distance and the current q1/q3 tag filters and caps, so results
may differ from Overpass at boundaries or when source geometries are missing.
For example, for the New York snapshot:

```sh
osmium extract -s smart -b -74.150,40.595,-73.858,40.817 NewYork.osm.pbf -o new_york_local.osm.pbf
python3 tools/prepare_osm_extract.py new_york_local.osm.pbf new_york 2026-10-31T00:00:00Z /tmp/pr360_extract --coverage -74.150 40.595 -73.858 40.817
python3 tools/prepare_osm_snapshot.py far /tmp/pr360_extract/new_york_far.json assets/osm_snapshots/new_york_far.json.gz
```

Pass the source extract's actual replication timestamp, not the conversion
date. Use `--near-only` for a source that covers the 2.5 km ring but not the
12 km far layer. Update metadata and run the bundled snapshot test as above.
