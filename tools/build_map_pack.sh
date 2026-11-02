#!/bin/bash
# Builds the bundled map packs (assets/map/*.tilepack, read by MapPack):
# OpenFreeMap vector tiles and Terrarium DEM for the zoomed-out picker
# levels, and the globe's z2 OSM world tiles. Deeper zooms stream at run
# time. Downloads are kept in SRC and skipped when already there, so a
# rerun resumes; delete SRC to refresh against a new planet build.
#
#   tools/build_map_pack.sh [SRC]       default SRC: $TMPDIR/planet-render-map-src
#   OMT_MAX=6 DEM_MAX=5 tools/build_map_pack.sh
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:-${TMPDIR:-/tmp}/planet-render-map-src}"
OMT_MAX="${OMT_MAX:-6}"
DEM_MAX="${DEM_MAX:-5}"
GLOBE_ZOOM=2  # GlobeView.ZOOM
GODOT="${GODOT:-godot}"
UA="PlanetRender360-mapbuild (+https://github.com/petri-tuononen/planet-render-360)"
mkdir -p "$SRC/omt" "$SRC/dem" "$SRC/osm" assets/map

omt_base=$(curl -sf https://tiles.openfreemap.org/planet \
	| python3 -c 'import sys, json; print(json.load(sys.stdin)["tiles"][0].split("/{z}")[0])')
echo "vector tiles: $omt_base"

python3 - "$SRC" "$omt_base" "$OMT_MAX" "$DEM_MAX" "$GLOBE_ZOOM" > "$SRC/jobs.txt" <<'EOF'
import sys
src, omt, omt_max, dem_max, globe = sys.argv[1], sys.argv[2], *map(int, sys.argv[3:])
def tiles(z):
	return ((x, y) for x in range(1 << z) for y in range(1 << z))
for z in range(omt_max + 1):
	for x, y in tiles(z):
		print(f"{omt}/{z}/{x}/{y}.pbf {src}/omt/{z}_{x}_{y}")
for z in range(dem_max + 1):
	for x, y in tiles(z):
		print(f"https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png {src}/dem/{z}_{x}_{y}")
for x, y in tiles(globe):
	print(f"https://tile.openstreetmap.org/{globe}/{x}/{y}.png {src}/osm/{globe}_{x}_{y}")
EOF

# Kept only on 200 or 204 (an empty body is a sea tile); vector tiles stay
# gzipped, as the fetcher asks for them.
export UA
xargs -P 6 -n 2 sh -c '[ -e "$1" ] && exit 0
	code=$(curl -s --retry 3 -A "$UA" -H "Accept-Encoding: gzip" -o "$1.part" -w "%{http_code}" "$0")
	case $code in
		200|204) touch "$1.part"; mv "$1.part" "$1" ;;
		*) rm -f "$1.part"; echo "failed ($code): $0" >&2 ;;
	esac' < "$SRC/jobs.txt"

"$GODOT" --headless --path . --script tools/pack_map_tiles.gd -- "$SRC" "$OMT_MAX" "$DEM_MAX" "$GLOBE_ZOOM"
ls -l assets/map
