#!/usr/bin/env python3
"""Download source regions sequentially and bundle a planned capital catalog.

This can transfer tens of gigabytes and take many hours. It requires a plan
from plan_capital_extracts.py, curl, osmium-tool, and pyosmium. Separate
regions may be prepared concurrently; do not download the same region twice
into the same work directory.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from capital_snapshot_io import complete, download

root = Path(__file__).resolve().parent.parent

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('plan', type=Path)
parser.add_argument('--workdir', type=Path, required=True,
                    help='directory for temporary region PBF downloads')
parser.add_argument('--keep-downloads', action='store_true', help='keep source extracts after processing')
parser.add_argument('--region', action='append', help='process only a named region (repeatable)')
parser.add_argument('--batch-size', type=int, default=1, choices=range(1, 5),
                    help='extract several views per source scan (uses more memory)')
args = parser.parse_args()
plan = json.loads(args.plan.read_text(encoding='utf-8'))
groups = defaultdict(list)
for place in plan:
    if not args.region or place['region'] in args.region:
        groups[place['region']].append(place)
if not groups:
    raise SystemExit('no matching planned regions')
args.workdir.mkdir(parents=True, exist_ok=True)
manifest_path = root / 'assets/osm_snapshots/capital_manifest.json'
failed = []

def prepare_region(region, places):
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {}
    provenance_path = manifest_path.parent / 'capital_provenance.json'
    provenance = json.loads(provenance_path.read_text(encoding='utf-8')) if provenance_path.exists() else {}
    missing = [p for p in places if not complete(p, manifest, manifest_path.parent, provenance)]
    if not missing:
        print('Already complete:', region, flush=True)
        return
    if not re.fullmatch(r'[a-z0-9-]+(?:/[a-z0-9-]+)*', region):
        raise RuntimeError('invalid region identifier: ' + region)
    url = places[0]['url']
    if not url.startswith('https://download.geofabrik.de/') or not url.endswith('-latest.osm.pbf'):
        raise RuntimeError('unexpected source URL: ' + url)
    headers = subprocess.check_output(['curl', '-fsSIL', '--max-time', '60', url], text=True)
    final_headers = [part for part in re.split(r'\r?\n\r?\n', headers) if part.strip()][-1]
    lengths = re.findall(r'^content-length:\s*(\d+)', final_headers, flags=re.I | re.M)
    if not lengths:
        raise RuntimeError('source did not provide a download size: ' + url)
    size = int(lengths[-1])
    path = args.workdir / (region.replace('/', '__') + '.osm.pbf')
    marker = path.with_suffix(path.suffix + '.source.json')
    etags = re.findall(r'^etag:\s*([^\r\n]+)', final_headers, flags=re.I | re.M)
    modified = re.findall(r'^last-modified:\s*([^\r\n]+)', final_headers, flags=re.I | re.M)
    signature = {'url': url, 'size': size, 'etag': etags[-1].strip() if etags else '',
                 'last_modified': modified[-1].strip() if modified else ''}
    # Some continental redirects host their checksum only on the final mirror.
    checksum_url = url + '.md5'
    result = subprocess.run(['curl', '-fsSL', '--max-time', '30', checksum_url],
                            capture_output=True, text=True)
    if result.returncode != 0:
        effective = subprocess.check_output(['curl', '-fsSLI', '--max-time', '60',
            '-o', '/dev/null', '-w', '%{url_effective}', url], text=True).strip()
        result = subprocess.run(['curl', '-fsSL', '--max-time', '30', effective + '.md5'],
                                capture_output=True, text=True)
    checksum = result.stdout.split()[0] if result.returncode == 0 and result.stdout.split() else ''
    if not re.fullmatch(r'[0-9a-fA-F]{32}', checksum):
        raise RuntimeError('source did not provide a valid checksum: ' + url)
    existing = path.stat().st_size if path.exists() else 0
    recorded = json.loads(marker.read_text(encoding='utf-8')) if marker.exists() else {}
    owned = not path.exists() or recorded == signature
    if path.exists() and existing != size:
        if existing > size or recorded != signature or not (signature['etag'] or signature['last_modified']):
            raise RuntimeError('cannot safely resume an unrecognized or changed source: ' + str(path))
        owned = True
    remaining = size - existing
    if shutil.disk_usage(args.workdir).free < remaining + 5 * 1024**3:
        raise SystemExit('not enough free disk space to download ' + region)
    print(f'Downloading {region}: {len(missing)} locations, {size / 1024**3:.2f} GiB source', flush=True)
    try:
        if remaining:
            if not path.exists():
                marker.write_text(json.dumps(signature) + '\n', encoding='utf-8')
            download(url, path, size)
        if path.stat().st_size != size:
            raise RuntimeError('source size does not match its published length')
        digest = hashlib.md5()
        with path.open('rb') as source:
            while block := source.read(4 * 1024 * 1024):
                digest.update(block)
        if digest.hexdigest() != checksum.lower():
            raise RuntimeError('source checksum does not match the published checksum')
        subprocess.run([sys.executable, str(root / 'tools/bundle_capital_region.py'),
                        str(args.plan), region, str(path), '--batch-size', str(args.batch_size)], check=True)
    except (subprocess.CalledProcessError, RuntimeError) as exc:
        failed.append(region)
        print('FAILED:', region, exc, flush=True)
    else:
        # Only remove downloads created by this invocation. A pre-existing PBF
        # may belong to the user and is never deleted automatically.
        if owned and not args.keep_downloads:
            path.unlink()
            marker.unlink(missing_ok=True)
for region, places in groups.items():
    try:
        prepare_region(region, places)
    except (subprocess.CalledProcessError, RuntimeError, OSError, ValueError, IndexError) as exc:
        failed.append(region)
        print('FAILED:', region, exc, flush=True)
if failed:
    raise SystemExit('Incomplete regions: ' + ', '.join(failed))
