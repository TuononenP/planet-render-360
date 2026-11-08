#!/usr/bin/env python3
"""Bundle a border-area capital from synchronized GeoFabrik extracts.

The supplied region polygons must jointly cover the full padded area. PBFs
must be from those regions and have the same OSM replication timestamp.
Requires shapely, pyosmium and osmium-tool.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from shapely.geometry import box, shape
from shapely.ops import unary_union
from capital_snapshot_io import merge_checked

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('plan', type=Path)
parser.add_argument('index', type=Path)
parser.add_argument('identifier')
parser.add_argument('--source', nargs=2, action='append', required=True, metavar=('REGION', 'PBF'))
args = parser.parse_args()
plan = json.loads(args.plan.read_text(encoding='utf-8'))
place = next((p for p in plan if p['identifier'] == args.identifier), None)
if place is None:
    raise SystemExit('location not found in plan')
features = {f['properties']['id']: f for f in json.loads(args.index.read_text(encoding='utf-8'))['features']}
if len({region for region, _ in args.source}) != len(args.source):
    raise SystemExit('source regions must be distinct')
polygons, files, urls, timestamps = [], [], [], set()
for region, file in args.source:
    f = features.get(region)
    if not f or not f.get('geometry'):
        raise SystemExit('unknown source polygon: ' + region)
    url = f['properties']['urls']['pbf']
    info = json.loads(subprocess.check_output(['osmium', 'fileinfo', '-j', file]))
    options = info['header']['option']
    expected = url.removesuffix('-latest.osm.pbf') + '-updates'
    if options.get('osmosis_replication_base_url', '').rstrip('/') != expected:
        raise SystemExit('source provenance mismatch: ' + region)
    stamp = options.get('osmosis_replication_timestamp', '')
    if not stamp:
        raise SystemExit('missing source timestamp: ' + region)
    timestamps.add(stamp)
    polygons.append(shape(f['geometry']))
    files.append(file)
    urls.append(url)
if len(timestamps) != 1:
    raise SystemExit('sources have different replication timestamps; align them before merging')
if not unary_union(polygons).covers(box(*place['coverage'])):
    raise SystemExit('source polygons do not cover the complete padded area')
stamp = timestamps.pop()
with tempfile.TemporaryDirectory(prefix='pr360-union-') as tmp:
    merged = Path(tmp) / 'merged.osm.pbf'
    cropped = Path(tmp) / 'cropped.osm.pbf'
    merge_checked(files, merged)
    subprocess.run(['osmium', 'extract', '--strategy', 'smart', '--set-bounds',
                    '--bbox', ','.join(str(x) for x in place['coverage']),
                    '-o', str(cropped), str(merged)], check=True)
    subprocess.run([sys.executable, str(root / 'tools/prepare_capital_extract.py'), str(cropped),
        place['identifier'], stamp, '--point', str(place['lat']), str(place['lon']),
        '--country', place['code'], '--source', ' + '.join(urls),
        '--coverage', *(str(x) for x in place['coverage']), '--allow-sparse'], check=True)
print('Union source verified:', place['name'], ', '.join(r for r, _ in args.source))
