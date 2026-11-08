"""Shared checks for capital snapshot preparation tools."""
import gzip
import hashlib
import re
import shutil
import subprocess
from pathlib import Path

LAYERS = {'detailed': ('detailed_extract', 12), 'ring1600': ('ring1600', 1),
          'ring2500': ('ring2500', 1), 'poi': ('poi', 1), 'far': ('far', 3)}
MAX_BYTES = 32 * 1024 * 1024


def complete(place, manifest, assets: Path, provenance):
    meta = provenance.get(place['identifier'])
    if not isinstance(meta, dict) or meta.get('coordinates') != [place['lat'], place['lon']]:
        return False
    if not all(meta.get(k) for k in ('country', 'source', 'source_timestamp', 'captured_at',
                                     'coverage', 'query_versions', 'attribution')):
        return False
    if place.get('code') and meta['country'] != place['code']:
        return False
    if meta['query_versions'] != {'detailed_extract': 12, 'ring': 1, 'poi': 1, 'far': 3}:
        return False
    for layer, (kind, version) in LAYERS.items():
        key = place['identifier'] + '_' + layer
        row = manifest.get(key)
        if not isinstance(row, list) or len(row) != 7:
            return False
        if row[:4] != [place['lat'], place['lon'], kind, version] or not isinstance(row[5], int):
            return False
        if not isinstance(row[4], str) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}', row[4]):
            return False
        if str(meta['source_timestamp']).removesuffix('Z') != row[4]:
            return False
        if not isinstance(row[6], str) or not re.fullmatch(r'[0-9a-f]{64}', row[6]):
            return False
        if row[5] <= 0 or row[5] > MAX_BYTES:
            return False
        try:
            with gzip.open(assets / (key + '.json.gz'), 'rb') as data:
                raw = data.read(MAX_BYTES + 1)
            if len(raw) != row[5] or hashlib.sha256(raw).hexdigest() != row[6]:
                return False
        except (OSError, EOFError):
            return False
    return True

def merge_checked(files, output):
    """Merge synchronized extracts, rejecting conflicting object versions."""
    subprocess.run(['osmium', 'merge', '-o', str(output), *map(str, files)], check=True)
    multiple = subprocess.check_output(['osmium', 'fileinfo', '-e', '-g', 'data.multiple_versions',
                                        str(output)], text=True).strip()
    if multiple != 'no':
        raise SystemExit('merged source has multiple object versions')


def parse_poly(text):
    """Shapely geometry of an Osmosis .poly file; '!' sections are holes."""
    from shapely.geometry import Polygon
    from shapely.ops import unary_union
    lines = [line.strip() for line in text.splitlines()]
    outers, holes, ring, name = [], [], None, None
    for line in lines[1:]:
        if not line:
            continue
        if ring is None:
            if line == 'END':
                break
            ring, name = [], line
        elif line == 'END':
            if len(ring) < 3:
                raise ValueError('polygon ring has fewer than three points: ' + name)
            (holes if name.startswith('!') else outers).append(Polygon(ring))
            ring = None
        else:
            lon, lat = (float(x) for x in line.split()[:2])
            ring.append((lon, lat))
    if ring is not None or not outers:
        raise ValueError('incomplete .poly file')
    shape = unary_union(outers)
    return shape.difference(unary_union(holes)) if holes else shape


def annotate_provenance(root: Path, identifier, fields):
    """Add source-specific fields to a published provenance record."""
    if not fields:
        return
    import fcntl
    import json
    lock_path = root / '.godot' / 'capital-snapshots.lock'
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    path = root / 'assets/osm_snapshots/capital_provenance.json'
    with lock_path.open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        data = json.loads(path.read_text(encoding='utf-8'))
        if identifier not in data:
            raise KeyError('no published provenance for ' + identifier)
        data[identifier].update(fields)
        temp = path.with_suffix('.json.tmp')
        temp.write_text(json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + '\n', encoding='utf-8')
        temp.replace(path)


def download(url, path, size):
    """Resume a source; fall back to bounded ranges if a proxy closes it."""
    try:
        subprocess.run(['curl', '-fsSL', '--retry', '3', '--max-time', '43200',
                        '-C', '-', '-o', str(path), url], check=True)
        return
    except subprocess.CalledProcessError:
        print('Long transfer failed; retrying in verified ranges:', path.name, flush=True)
    path.touch(exist_ok=True)
    chunk_path = path.with_suffix(path.suffix + '.part')
    chunk_size = 16 * 1024 * 1024
    while path.stat().st_size < size:
        start = path.stat().st_size
        end = min(size - 1, start + chunk_size - 1)
        length = end - start + 1
        status = subprocess.check_output(['curl', '-fsSL', '--retry', '10', '--retry-all-errors',
            '--retry-delay', '3', '--max-time', '180', '--max-filesize', str(length),
            '--range', f'{start}-{end}', '-w', '%{http_code}', '-o', str(chunk_path), url], text=True)
        if status.strip() != '206' or chunk_path.stat().st_size != length:
            raise RuntimeError('incomplete range for ' + path.name)
        with path.open('ab') as output, chunk_path.open('rb') as part:
            shutil.copyfileobj(part, output)
        chunk_path.unlink()
        if start // (512 * 1024 * 1024) != (end + 1) // (512 * 1024 * 1024):
            print(f'{path.name}: {end + 1} / {size} bytes', flush=True)

