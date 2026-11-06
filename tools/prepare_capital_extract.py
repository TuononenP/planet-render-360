#!/usr/bin/env python3
"""Validate and bundle five OSM layers for a capital from a complete PBF.

Run with pyosmium installed. The caller must verify that the source covers the
entire 12 km disc, including neighboring countries and referenced geometry.
Use the actual coordinates exported by export_capital_points.gd.
"""
import argparse
import fcntl
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pbf', type=Path)
parser.add_argument('identifier', help='unique lowercase snapshot identifier')
parser.add_argument('timestamp', help='OSM replication timestamp in UTC')
parser.add_argument('--point', required=True, nargs=2, type=float, metavar=('LAT', 'LON'))
parser.add_argument('--country', required=True)
parser.add_argument('--source', required=True, help='URL identifying the complete source extract')
parser.add_argument('--coverage', required=True, nargs=4, type=float, metavar=('WEST', 'SOUTH', 'EAST', 'NORTH'))
parser.add_argument('--allow-sparse', action='store_true', help='accept empty optional layers from a verified complete extract')
args = parser.parse_args()
if not re.fullmatch(r'capital_[a-z0-9_]+', args.identifier):
    parser.error('identifier must start with capital_ and contain lowercase letters, numbers and underscores')
if not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', args.timestamp):
    parser.error('timestamp must be in UTC, e.g. 2026-11-04T00:00:00Z')
assets = root / 'assets/osm_snapshots'
manifest_path = assets / 'capital_manifest.json'
layer_kinds = {'detailed': ('detailed-extract', 12), 'ring1600': ('ring', 1),
               'ring2500': ('ring', 1), 'poi': ('poi', 1), 'far': ('far', 3)}
with tempfile.TemporaryDirectory(prefix='pr360-capital-') as temp_name:
    temp = Path(temp_name)
    cmd = [sys.executable, str(root / 'tools/prepare_osm_extract.py'), str(args.pbf),
           args.identifier, args.timestamp, str(temp), '--detailed', '--point',
           *(str(x) for x in args.point), '--country', args.country, '--coverage',
           *(str(x) for x in args.coverage)]
    subprocess.run(cmd, check=True)
    entries = {}
    for layer, (kind, version) in layer_kinds.items():
        key = args.identifier + '_' + layer
        raw_path = temp / (key + '.json')
        gzip_path = temp / (key + '.json.gz')
        raw = raw_path.read_bytes()
        if len(raw) > 32 * 1024 * 1024:
            raise SystemExit(f'{key}: payload exceeds the runtime size limit')
        cmd = [sys.executable, str(root / 'tools/prepare_osm_snapshot.py'), kind,
               str(raw_path), str(gzip_path)]
        if args.allow_sparse and layer != 'detailed':
            cmd.append('--allow-sparse')
        subprocess.run(cmd, check=True)
        entries[key] = [*args.point, 'detailed_extract' if layer == 'detailed' else layer,
                        version, args.timestamp.removesuffix('Z'), len(raw), hashlib.sha256(raw).hexdigest()]
    # Publish only after every layer has validated. Existing entries are not
    # removed when an attempt fails.
    lock_path = root / '.godot' / 'capital-snapshots.lock'
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
        if not isinstance(manifest, dict):
            raise SystemExit('manifest must be a JSON object')
        manifest.update(entries)
        temporary_manifest = manifest_path.with_suffix('.json.tmp')
        temporary_manifest.write_text(json.dumps(manifest, indent=2, ensure_ascii=False, sort_keys=True) + '\n', encoding='utf-8')
        provenance_path = assets / 'capital_provenance.json'
        provenance = json.loads(provenance_path.read_text(encoding='utf-8')) if provenance_path.exists() else {}
        if not isinstance(provenance, dict):
            raise SystemExit('provenance must be a JSON object')
        provenance[args.identifier] = {'coordinates': args.point, 'country': args.country,
            'source': args.source, 'source_timestamp': args.timestamp,
            'captured_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
            'coverage': args.coverage, 'query_versions': {'detailed_extract': 12, 'ring': 1, 'poi': 1, 'far': 3},
            'attribution': '© OpenStreetMap contributors, ODbL'}
        temporary_provenance = provenance_path.with_suffix('.json.tmp')
        temporary_provenance.write_text(json.dumps(provenance, indent=2, ensure_ascii=False, sort_keys=True) + '\n', encoding='utf-8')
        for key in entries:
            shutil.copyfile(temp / (key + '.json.gz'), assets / (key + '.json.gz'))
        temporary_provenance.replace(provenance_path)
        temporary_manifest.replace(manifest_path)
print(f'Bundled five validated layers for {args.identifier}')
