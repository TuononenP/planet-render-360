# City models

Per-building facts reduced offline from city 3D models, bundled so the app
needs no extra download.

## helsinki_lod2/

Measured heights and roof forms from the City of Helsinki's LoD2 building
model (3D city model; © City of Helsinki, CC BY 4.0), as served to the
city's 3D viewer (https://kartta.hel.fi/3d/) in 3D Tiles. Built by
`tools/prepare_helsinki_lod2.py`, which walks the tileset to its z16 tiles,
classifies each building's roof triangles and writes one row per building:

    [vtj_prt, e, n, area_m2, height_m, roof_h_m, pitch_deg, ridge_az_deg, shape, storeys]

(e, n in ETRS-GK25 / EPSG:3879; ridge_az is a skillion's downslope bearing).
Rows are grouped into 1 km GK25 cells, `<E km>_<N km>.lod2`: zstd-compressed
JSON. `manifest.json` pins each payload's uncompressed size and SHA-256 (and
row count); `HelsinkiLod2` refuses a cell that does not match.

Coverage is the tool's `--box` (default central Helsinki, GK25
25 492 000–25 500 000 E, 6 668 000–6 676 000 N). Re-run the tool with a wider
box to add cells; existing manifest rows are kept. Raw tiles are cached in
`build/lod2_tiles/` (not committed).
