# Bundled OpenStreetMap snapshots

These gzip files are OpenStreetMap data © OpenStreetMap contributors,
available under the [ODbL](https://www.openstreetmap.org/copyright). The
app's existing OSM attribution applies. They cover only the preset origins,
not the cities as a whole. The timestamps below are the Overpass
`timestamp_osm_base` in UTC on 2026-11-04; query and integrity metadata is
in `scripts/data/bundled_osm.gd`.

| Preset | Coordinates | Layer / query | OSM timestamp UTC | Compressed bytes |
| --- | --- | --- | --- | ---: |
| New York | 40.7060, -74.0040 | detailed / q12 | 13:18:25 | 2,182,136 |
| San Francisco | 37.8040, -122.4195 | detailed / q12 | 13:16:20 | 1,384,265 |
| Helsinki | 60.1680, 24.9530 | far city / q3 | 14:47:51 | 3,012,547 |
| Stockholm | 59.3207, 18.0604 | far city / q3 | 14:07:04 | 2,273,021 |

The remaining detailed, far-city, ring and POI layers are not bundled: no
complete current-query response was available when these files were prepared.
Those layers retain the normal live fetch and fallback behavior. This is not
complete offline city coverage.

To replace one of these files, obtain a complete current-query response from
the app's cache at the exact preset origin, then run, for example:

```sh
python3 tools/prepare_osm_snapshot.py detailed /path/to/current-cache.json assets/osm_snapshots/new_york_detailed.json.gz
```

Use `far` for a far-city response. The tool rejects Overpass errors, missing
buildings and missing expected layers and prints the timestamp, uncompressed
length and SHA-256. Update the corresponding `BundledOsm.ENTRIES` row and this
record with those values and the current query version. Check layer coverage,
counts and coordinates against the query and source cache before committing;
the JSON does not itself prove which coordinates or query produced it. Run
`tests/bundled_osm_test.gd` and the OSM tests. Adding ring or POI snapshots
also requires wiring those fetch phases and tests; simply adding a file does
not enable them.
