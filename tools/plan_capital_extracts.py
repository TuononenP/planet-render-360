#!/usr/bin/env python3
"""Plan complete capital extracts from GeoFabrik's published region polygons.

Requires shapely. Run export_capital_points.gd first and download the GeoFabrik
index-v1.json. Every source polygon must cover the entire padded bounding box,
so a capital near a country boundary is assigned to a larger region.
"""
import argparse
import json
import math
from pathlib import Path
from shapely.geometry import box, shape

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('points', type=Path)
parser.add_argument('index', type=Path)
parser.add_argument('output', type=Path)
parser.add_argument('--continental', action='store_true',
                    help='group into continental extracts to reduce the number of downloads')
parser.add_argument('--include-bundled', action='store_true',
                    help='also plan locations that already have snapshots, to refresh them')
args = parser.parse_args()
points = json.loads(args.points.read_text(encoding='utf-8'))
index = json.loads(args.index.read_text(encoding='utf-8'))
regions = []
for feature in index['features']:
    props = feature['properties']
    if feature.get('geometry') and props.get('urls', {}).get('pbf'):
        # Top-level extracts may contain neighboring countries; polygon coverage
        # below, not country membership, decides whether a region is safe.
        if args.continental and props['id'] not in {'africa', 'europe', 'asia', 'north-america',
                'south-america', 'central-america', 'australia-oceania', 'russia'}:
            continue
        polygon = shape(feature['geometry'])
        regions.append((polygon.area, props['id'], props['urls']['pbf'], polygon))
regions.sort(key=lambda x: x[0])
plans = []
missing = []
for point in points:
    if point.get('bundled') and not args.include_bundled:
        continue
    lat, lon = float(point['lat']), float(point['lon'])
    # 14.5 km in latitude, padded also in longitude for a 12 km disc.
    dy = 0.13
    dx = dy / max(0.05, math.cos(math.radians(lat)))
    bounds = [lon - dx, lat - dy, lon + dx, lat + dy]
    if bounds[0] < -180 or bounds[2] > 180 or bounds[1] < -90 or bounds[3] > 90:
        missing.append(point['name'])
        continue
    extent = box(*bounds)
    region = next((r for r in regions if r[3].covers(extent)), None)
    if region is None:
        missing.append(point['name'])
        continue
    ident = 'capital_%s_%s_%s' % (point['code'].lower(),
        str(round((lat + 90) * 100000)), str(round((lon + 180) * 100000)))
    plans.append({**point, 'identifier': ident, 'region': region[1],
                  'url': region[2], 'coverage': bounds})
if missing:
    raise SystemExit('No complete source region for: ' + ', '.join(missing))
args.output.write_text(json.dumps(plans, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(f'Planned {len(plans)} locations from {len({p["region"] for p in plans})} complete source regions')
