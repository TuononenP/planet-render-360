#!/usr/bin/env python3
"""Bundle a planned region from an already downloaded GeoFabrik PBF.

Run with pyosmium and osmium-tool installed. The plan must come from
plan_capital_extracts.py using GeoFabrik's published region polygons.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from capital_snapshot_io import complete

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('plan', type=Path)
parser.add_argument('region', help='GeoFabrik region ID in the plan')
parser.add_argument('pbf', type=Path)
parser.add_argument('--dry-run', action='store_true')
parser.add_argument('--batch-size', type=int, default=1, choices=range(1, 5),
                    help='extract up to this many nearby views per PBF scan (uses more memory)')
args = parser.parse_args()
plan = json.loads(args.plan.read_text(encoding='utf-8'))
places = [p for p in plan if p['region'] == args.region]
if not places:
    raise SystemExit('region has no locations in plan')
info = json.loads(subprocess.check_output(['osmium', 'fileinfo', '-j', str(args.pbf)]))
options = info['header']['option']
stamp = options.get('osmosis_replication_timestamp', '')
base = options.get('osmosis_replication_base_url', '').rstrip('/')
expected_base = places[0]['url'].removesuffix('-latest.osm.pbf') + '-updates'
if not stamp or base != expected_base:
    raise SystemExit(f'PBF provenance mismatch: expected {expected_base}, got {base}; timestamp {stamp}')
manifest_path = root / 'assets/osm_snapshots/capital_manifest.json'
failures = []
pending = []
for place in places:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
    provenance_path = manifest_path.parent / 'capital_provenance.json'
    provenance = json.loads(provenance_path.read_text(encoding='utf-8')) if provenance_path.exists() else {}
    if complete(place, manifest, manifest_path.parent, provenance):
        print('Already bundled:', place['name'], flush=True)
    else:
        pending.append(place)

for start in range(0, len(pending), args.batch_size):
    group = pending[start:start + args.batch_size]
    for place in group:
        print('Preparing:', place['name'], 'from', args.region, stamp, flush=True)
    if args.dry_run:
        continue
    with tempfile.TemporaryDirectory(prefix='pr360-pbf-') as tmp:
        temp = Path(tmp)
        config = {'extracts': [{'output': p['identifier'] + '.osm.pbf',
                                'bbox': p['coverage']} for p in group]}
        config_path = temp / 'extracts.json'
        config_path.write_text(json.dumps(config), encoding='utf-8')
        try:
            subprocess.run(['osmium', 'extract', '--strategy', 'smart', '--set-bounds',
                            '--config', str(config_path), '--directory', str(temp), str(args.pbf)], check=True)
        except subprocess.CalledProcessError:
            print('Batch extraction failed; retrying views individually', flush=True)
            for place in group:
                output = temp / (place['identifier'] + '.osm.pbf')
                output.unlink(missing_ok=True)
                try:
                    subprocess.run(['osmium', 'extract', '--strategy', 'smart', '--set-bounds',
                                    '--bbox', ','.join(str(n) for n in place['coverage']),
                                    '-o', str(output), str(args.pbf)], check=True)
                except subprocess.CalledProcessError:
                    failures.append(place['name'])
                    print('FAILED extraction:', place['name'], flush=True)
        for place in group:
            if place['name'] in failures:
                continue
            try:
                output = temp / (place['identifier'] + '.osm.pbf')
                subprocess.run([sys.executable, str(root / 'tools/prepare_capital_extract.py'), str(output),
                                place['identifier'], stamp, '--point', str(place['lat']), str(place['lon']),
                                '--country', place['code'], '--source', place['url'],
                                '--coverage', *(str(n) for n in place['coverage']),
                                '--allow-sparse'], check=True)
            except subprocess.CalledProcessError:
                failures.append(place['name'])
                print('FAILED:', place['name'], flush=True)
if failures:
    raise SystemExit('Failed to prepare: ' + ', '.join(failures))
