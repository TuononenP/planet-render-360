# Bundled OpenStreetMap snapshots

These `.osmb` files are OpenStreetMap data © OpenStreetMap contributors,
available under the [ODbL](https://www.openstreetmap.org/copyright). The
app's existing OSM attribution applies. They cover only the preset origins,
not the cities as a whole. The query and integrity metadata is in `scripts/data/bundled_osm.gd`.
Timestamps are the source replication time in UTC (Overpass `timestamp_osm_base`
for live responses).

## File format

Each file is a compact, zstd-compressed form of an Overpass JSON response
(`tools/osmb.py` documents the layout): coordinates as delta-coded integers
of 1e-7°, OSM's own precision, so they match live Overpass text exactly (a
cached live layer and a bundled ring still share their coastline nodes); one
string table for tags and roles; and no way node-id lists or bounds, which
nothing reads. The manifest rows record the
decompressed payload's size and SHA-256. `BundledOsm.read` checks both and
decodes the payload back to Overpass JSON text (`SnapshotKernels` natively,
`OsmbCodec` in GDScript), so the fetchers read it as before. The byte counts
in the tables below are the original gzip JSON sizes.

To read one as JSON:

```sh
python3 tools/osmb.py decode assets/osm_snapshots/helsinki_detailed.osmb > helsinki_detailed.json
```

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
python3 tools/prepare_osm_snapshot.py detailed /path/to/current-cache.json assets/osm_snapshots/new_york_detailed.osmb
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
python3 tools/prepare_osm_snapshot.py far /tmp/pr360_extract/new_york_far.json assets/osm_snapshots/new_york_far.osmb
```

Pass the source extract's actual replication timestamp, not the conversion
date. Use `--near-only` for a source that covers the 2.5 km ring but not the
12 km far layer. Update metadata and run the bundled snapshot test as above.

## Remaining preset snapshots

The following snapshots cover the other curated preset origins. The full
Overpass responses use the same query versions and validation as the original
four cities. Extract-derived payloads use supported OSM tags and geometry in
Overpass-shaped JSON; their detailed data is not a literal q12 response and
has a separately identified source in `BundledOsm`. Normal query-version
invalidation and live refresh still apply.

| Preset | Coordinates | Layer / compatibility | OSM timestamp UTC | Compressed bytes |
| --- | --- | --- | --- | ---: |
| paris | 48.8622, 2.2887 | detailed / q12 | 2026-11-04 15:35:21 | 1,945,572 |
| paris | 48.8622, 2.2887 | ring1600 / q1 | 2026-11-02 21:21:26 | 94,945 |
| paris | 48.8622, 2.2887 | ring2500 / q1 | 2026-11-02 21:21:26 | 151,094 |
| paris | 48.8622, 2.2887 | poi / q1 | 2026-11-02 21:21:26 | 76,363 |
| paris | 48.8622, 2.2887 | far / q3 | 2026-11-04 16:59:38 | 3,084,020 |
| monaco | 43.7310, 7.4209 | detailed / q12 | 2026-11-04 13:15:14 | 781,376 |
| monaco | 43.7310, 7.4209 | ring1600 / q1 | 2026-11-02 21:21:26 | 73,980 |
| monaco | 43.7310, 7.4209 | ring2500 / q1 | 2026-11-04 13:14:21 | 112,893 |
| monaco | 43.7310, 7.4209 | poi / q1 | 2026-11-02 21:21:26 | 40,792 |
| monaco | 43.7310, 7.4209 | far / q3 | 2026-11-02 21:21:26 | 300,639 |
| espoo | 60.1760, 24.8050 | detailed / q12 | 2026-11-02 21:21:26 | 1,058,891 |
| espoo | 60.1760, 24.8050 | ring1600 / q1 | 2026-11-02 21:21:26 | 87,413 |
| espoo | 60.1760, 24.8050 | ring2500 / q1 | 2026-11-02 21:21:26 | 151,103 |
| espoo | 60.1760, 24.8050 | poi / q1 | 2026-11-02 21:21:26 | 29,641 |
| espoo | 60.1760, 24.8050 | far / q3 | 2026-11-02 21:21:26 | 2,955,056 |
| rome | 41.8916, 12.4916 | detailed / q12 | 2026-11-02 21:21:26 | 1,822,962 |
| rome | 41.8916, 12.4916 | ring1600 / q1 | 2026-11-02 21:21:26 | 109,996 |
| rome | 41.8916, 12.4916 | ring2500 / q1 | 2026-11-02 21:21:26 | 132,533 |
| rome | 41.8916, 12.4916 | poi / q1 | 2026-11-02 21:21:26 | 52,453 |
| rome | 41.8916, 12.4916 | far / q3 | 2026-11-02 21:21:26 | 1,703,411 |
| venice | 45.4318, 12.3290 | detailed / q12 | 2026-11-02 21:21:26 | 2,535,098 |
| venice | 45.4318, 12.3290 | ring1600 / q1 | 2026-11-02 21:21:26 | 28,118 |
| venice | 45.4318, 12.3290 | ring2500 / q1 | 2026-11-02 21:21:26 | 30,835 |
| venice | 45.4318, 12.3290 | poi / q1 | 2026-11-02 21:21:26 | 65,292 |
| venice | 45.4318, 12.3290 | far / q3 | 2026-11-02 21:21:26 | 495,040 |
| alps | 46.6900, 7.8580 | detailed / q12 | 2026-11-02 21:21:26 | 765,865 |
| alps | 46.6900, 7.8580 | ring1600 / q1 | 2026-11-02 21:21:26 | 23,861 |
| alps | 46.6900, 7.8580 | ring2500 / q1 | 2026-11-02 21:21:26 | 58,926 |
| alps | 46.6900, 7.8580 | poi / q1 | 2026-11-02 21:21:26 | 21,614 |
| alps | 46.6900, 7.8580 | far / q3 | 2026-11-02 21:21:26 | 135,831 |
| seoul | 37.5728, 126.9769 | detailed / extract-compatible q12 | 2026-10-31 00:00:00 | 714,952 |
| seoul | 37.5728, 126.9769 | ring1600 / extract-compatible q1 | 2026-10-31 00:00:00 | 32,323 |
| seoul | 37.5728, 126.9769 | ring2500 / extract-compatible q1 | 2026-10-31 00:00:00 | 62,235 |
| seoul | 37.5728, 126.9769 | poi / extract-compatible q1 | 2026-10-31 00:00:00 | 71,552 |
| seoul | 37.5728, 126.9769 | far / extract-compatible q3 | 2026-10-31 00:00:00 | 1,806,677 |
| big_sur | 36.3740, -121.9022 | detailed / extract-compatible q12 | 2026-11-03 00:45:53 | 52,289 |
| big_sur | 36.3740, -121.9022 | ring1600 / extract-compatible q1 | 2026-11-03 00:45:53 | 10,297 |
| big_sur | 36.3740, -121.9022 | ring2500 / extract-compatible q1 | 2026-11-03 00:45:53 | 13,384 |
| big_sur | 36.3740, -121.9022 | poi / extract-compatible q1 | 2026-11-03 00:45:53 | 536 |
| big_sur | 36.3740, -121.9022 | far / extract-compatible q3 | 2026-11-03 00:45:53 | 2,396 |
| banff | 51.1720, -115.5640 | detailed / extract-compatible q12 | 2026-11-02 21:21:26 | 317,184 |
| banff | 51.1720, -115.5640 | ring1600 / extract-compatible q1 | 2026-11-02 21:21:26 | 22,762 |
| banff | 51.1720, -115.5640 | ring2500 / extract-compatible q1 | 2026-11-02 21:21:26 | 32,758 |
| banff | 51.1720, -115.5640 | poi / extract-compatible q1 | 2026-11-02 21:21:26 | 14,353 |
| banff | 51.1720, -115.5640 | far / extract-compatible q3 | 2026-11-02 21:21:26 | 14,772 |
| dubai | 25.1925, 55.2741 | detailed / extract-compatible q12 | 2026-11-03 21:24:23 | 324,786 |
| dubai | 25.1925, 55.2741 | ring1600 / extract-compatible q1 | 2026-11-03 21:24:23 | 60,370 |
| dubai | 25.1925, 55.2741 | ring2500 / extract-compatible q1 | 2026-11-03 21:24:23 | 82,540 |
| dubai | 25.1925, 55.2741 | poi / extract-compatible q1 | 2026-11-03 21:24:23 | 17,983 |
| dubai | 25.1925, 55.2741 | far / extract-compatible q3 | 2026-11-03 21:24:23 | 547,676 |
| london | 51.5018, -0.1196 | detailed / q12 | 2026-11-02 21:21:26 | 2,082,282 |
| london | 51.5018, -0.1196 | ring1600 / q1 | 2026-11-02 21:21:26 | 107,797 |
| london | 51.5018, -0.1196 | ring2500 / q1 | 2026-11-02 21:21:26 | 126,968 |
| london | 51.5018, -0.1196 | poi / q1 | 2026-11-02 21:21:26 | 60,901 |
| london | 51.5018, -0.1196 | far / extract-compatible q3 | 2026-10-31 00:00:00 | 2,823,637 |
| tokyo | 35.6595, 139.7005 | detailed / extract-compatible q12 | 2026-11-03 21:24:23 | 775,458 |
| tokyo | 35.6595, 139.7005 | ring1600 / extract-compatible q1 | 2026-11-03 21:24:23 | 53,426 |
| tokyo | 35.6595, 139.7005 | ring2500 / extract-compatible q1 | 2026-11-03 21:24:23 | 98,901 |
| tokyo | 35.6595, 139.7005 | poi / extract-compatible q1 | 2026-11-03 21:24:23 | 141,242 |
| tokyo | 35.6595, 139.7005 | far / extract-compatible q3 | 2026-11-03 21:24:23 | 1,745,939 |
| helsinki | 60.1680, 24.9530 | transit / OSM API map call | 2026-11-11 00:49:59 | 13,691 |
| berlin | 52.5244, 13.4105 | transit / OSM API map call | 2026-11-11 00:50:42 | 10,389 |
| tokyo | 35.6595, 139.7005 | transit / OSM API map call | 2026-11-11 00:51:14 | 9,903 |
| london | 51.5018, -0.1196 | transit / OSM API map call | 2026-11-11 00:51:49 | 19,215 |
| dubai | 25.1925, 55.2741 | transit / OSM API map call | 2026-11-11 00:52:18 | 1,996 |
| banff | 51.1720, -115.5640 | transit / OSM API map call | 2026-11-11 00:52:46 | 1,697 |
| big_sur | 36.3740, -121.9022 | transit / OSM API map call | 2026-11-11 00:53:12 | 395 |
| seoul | 37.5728, 126.9769 | transit / OSM API map call | 2026-11-11 00:53:45 | 8,348 |
| alps | 46.6900, 7.8580 | transit / OSM API map call | 2026-11-11 00:54:16 | 2,550 |
| rome | 41.8916, 12.4916 | transit / OSM API map call | 2026-11-11 00:54:53 | 6,161 |
| venice | 45.4318, 12.3290 | transit / OSM API map call | 2026-11-11 00:55:28 | 1,089 |
| paris | 48.8622, 2.2887 | transit / OSM API map call | 2026-11-11 01:12:05 | 11,627 |
| monaco | 43.7310, 7.4209 | transit / OSM API map call | 2026-11-11 01:13:29 | 4,766 |
| espoo | 60.1760, 24.8050 | transit / OSM API map call | 2026-11-11 01:14:56 | 4,797 |
| stockholm | 59.3207, 18.0604 | transit / OSM API map call | 2026-11-11 01:16:23 | 7,796 |
| new_york_midtown | 40.7535, -73.9825 | transit / OSM API map call | 2026-11-11 01:17:52 | 17,604 |
| new_york | 40.7060, -74.0040 | transit / OSM API map call | 2026-11-11 01:19:20 | 11,295 |
| san_francisco | 37.8040, -122.4195 | transit / OSM API map call | 2026-11-11 01:20:47 | 7,466 |

Paris, Monaco, Espoo, London, Rome, Venice and the Alps use cached Overpass
responses or the Europe Overpass instance; London's far layer uses BBBike's
2026-10-31 London extract. Seoul uses BBBike's 2026-10-31 Seoul extract;
Tokyo uses Geofabrik's Kanto extract dated 2026-11-03 21:24:23 UTC;
Dubai uses Geofabrik's GCC extract dated 2026-11-03 21:24:23 UTC; Banff uses
Geofabrik's Alberta extract dated 2026-11-02 21:21:26 UTC. Big Sur uses the
OSM France Monterey County extract dated 2026-11-03 00:45:53 UTC: its 12 km
far-city area extends into offshore water beyond the county extract, so that
portion is not guaranteed to be covered. The sparse Big Sur and Banff far
layers reflect the available mapped features; they do not imply tall buildings
where none are mapped.

Extract-derived detailed payloads select renderable ways, multipolygons and
nodes near the preset and use a locally projected distance calculation. They
can differ from Overpass at boundaries, in feature selection and in caps.
Their country code is supplied by the preset's known country; it is not an
Overpass `is_in` result. Ring and far-city query caps can truncate dense areas.
Use `--detailed` with `prepare_osm_extract.py` and `detailed-extract` with
`prepare_osm_snapshot.py` to regenerate these detailed layers. Sparse mode is
restricted to verified optional layers in rural extracts.

## Transit layer

`<preset>_transit.osmb` rows (layer `transit`, query version
`OsmQuery.TRANSIT_VERSION`) hold what the detailed snapshots lack: tram stops
(`railway=tram_stop`, `public_transport=stop_position` + `tram=yes`), every
`highway=bus_stop` within the 1200 m detailed radius (the detailed files keep
only those within 450 m of the eye), `railway=station|halt` nodes and
`railway=platform` or `public_transport=platform` + `train=yes` ways, with the
caps of the app's own query (1500 stops, 600 platforms). `OsmFetcher` merges
the layer only when a bundled snapshot stands in for the live detailed answer;
a live answer or a device cache already carries these elements, and elements
present in both are read once. A preset without a row loads as before.

Fetch it from the OSM API's map call (the default, `--source api`: the square
around the preset in small tiles, filtered by the tool to the same tags and
radius; the API answers 429 when asked too fast and the tool then stops), or
from the app's Overpass instances (`--source overpass`,
`OsmFetcher.ENDPOINTS`), one request per city:

```sh
python3 -I tools/prepare_transit_layer.py --all --allow-sparse
python3 -I tools/prepare_transit_layer.py helsinki san_francisco --source overpass
```

The tool validates each answer with `prepare_osm_snapshot.py transit`, writes
the `.osmb` file and prints the `BundledOsm.ENTRIES` row to add. A rural preset with no
transit at all is left without a layer (`--allow-sparse` keeps an empty one).
Run `tests/transit_layer_test.gd` and `tests/bundled_osm_test.gd` afterwards.
