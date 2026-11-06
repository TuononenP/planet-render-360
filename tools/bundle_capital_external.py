#!/usr/bin/env python3
"""Bundle a capital from a source other than one GeoFabrik region.

Use this where no single GeoFabrik region (or synchronized union, see
bundle_capital_union.py) covers the padded view without an oversized
download. Each mode verifies coverage, provenance and timestamps before
tools/prepare_capital_extract.py validates and publishes the five layers:

  bbbike    BBBike city extract; its published .poly must cover the view.
  osmfr     Two or more OpenStreetMap France extracts. Older extracts are
            advanced with their own minutely replication diffs to the newest
            sequence before merging.
  osmapi    A bounded OSM map API response, for a small island outside any
            practical extract. Its timestamp is the HTTP response date.
  relation  A GeoFabrik extract supplemented with one complete OSM relation
            (e.g. a maritime boundary the regional cut leaves incomplete).

Requires curl, osmium-tool, pyosmium and shapely. PLAN is the output of
plan_capital_extracts.py; IDENTIFIER selects the place in it.
"""
import argparse
import email.utils
import gzip
import hashlib
import json
import math
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from shapely.geometry import box
from capital_snapshot_io import annotate_provenance, download, parse_poly

root = Path(__file__).resolve().parent.parent
BBBIKE = 'https://download.bbbike.org/osm/bbbike/'
OSMFR = 'https://download.openstreetmap.fr/'
OSM_API = 'https://api.openstreetmap.org/api/0.6/'
# The OSM map API rejects larger requests.
OSM_API_MAX_AREA = 0.25
# One day of minutely diffs; extracts further apart are not aligned.
MAX_ALIGNMENT_DIFFS = 1440


def fetch(url, path):
    subprocess.run(['curl', '-fsSL', '--retry', '3', '--max-time', '600', '-o', str(path), url], check=True)
    return path


def remote_size(url):
    headers = subprocess.check_output(['curl', '-fsSIL', '--max-time', '60', url], text=True)
    lengths = re.findall(r'^content-length:\s*(\d+)', headers, flags=re.I | re.M)
    if not lengths:
        raise SystemExit('source did not provide a download size: ' + url)
    return int(lengths[-1])


def md5_of(path):
    digest = hashlib.md5()
    with path.open('rb') as f:
        while chunk := f.read(4 * 1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def download_verified(url, path, md5=None):
    size = remote_size(url)
    if path.exists() and path.stat().st_size != size:
        raise SystemExit(f'unexpected existing file size: {path}')
    if not path.exists():
        download(url, path, size)
    if md5 is not None and md5_of(path) != md5.lower():
        raise SystemExit('source checksum mismatch: ' + url)
    return path


def header(path):
    return json.loads(subprocess.check_output(['osmium', 'fileinfo', '-j', str(path)]))['header']['option']


def view_box(place, metres=12000.0):
    """Bounds of the 12 km far-city disc around the viewpoint."""
    dy = metres / 111195.0
    dx = dy / math.cos(math.radians(place['lat']))
    return box(place['lon'] - dx, place['lat'] - dy, place['lon'] + dx, place['lat'] + dy)


def merge_checked(files, output):
    subprocess.run(['osmium', 'merge', '-o', str(output), *map(str, files)], check=True)
    multiple = subprocess.check_output(['osmium', 'fileinfo', '-e', '-g', 'data.multiple_versions',
                                        str(output)], text=True).strip()
    if multiple != 'no':
        raise SystemExit('merged source has multiple object versions')


def prepare(place, pbf, stamp, source, coverage, temp):
    cropped = temp / 'cropped.osm.pbf'
    subprocess.run(['osmium', 'extract', '--strategy', 'smart', '--set-bounds', '--overwrite',
                    '--bbox', ','.join(str(x) for x in coverage), '-o', str(cropped), str(pbf)], check=True)
    subprocess.run([sys.executable, str(root / 'tools/prepare_capital_extract.py'), str(cropped),
                    place['identifier'], stamp, '--point', str(place['lat']), str(place['lon']),
                    '--country', place['code'], '--source', source,
                    '--coverage', *(str(x) for x in coverage), '--allow-sparse'], check=True)


def sequence_path(sequence):
    """Replication file path for a sequence number, e.g. 7358940 -> 007/358/940."""
    text = '%09d' % sequence
    return f'{text[0:3]}/{text[3:6]}/{text[6:9]}'


def bbbike(place, args, temp):
    if not re.fullmatch(r'[A-Za-z]+', args.city):
        raise SystemExit('BBBike city names are letters only, e.g. WashingtonDC')
    base = f'{BBBIKE}{args.city}/'
    url, poly_url = base + args.city + '.osm.pbf', base + args.city + '.poly'
    polygon = parse_poly(fetch(poly_url, temp / 'source.poly').read_text(encoding='utf-8'))
    if not polygon.covers(view_box(place)):
        raise SystemExit('BBBike boundary does not cover the view')
    checksums = fetch(base + 'CHECKSUM.txt', temp / 'CHECKSUM.txt').read_text(encoding='utf-8')
    md5 = next((line.split()[0] for line in checksums.splitlines()
                if line.endswith(' ' + args.city + '.osm.pbf')), None)
    if md5 is None:
        raise SystemExit('BBBike checksum not published for ' + args.city)
    pbf = download_verified(url, args.workdir / (args.city + '.osm.pbf'), md5)
    # BBBike cuts from planet data; its header carries that data timestamp.
    stamp = header(pbf).get('osmosis_replication_timestamp', '')
    if not stamp:
        raise SystemExit('BBBike source timestamp missing')
    prepare(place, pbf, stamp, url, list(polygon.bounds), temp)
    return {'coverage_source': poly_url}


def osmfr(place, args, temp):
    sources = []
    for extract in args.extract:
        if not re.fullmatch(r'[a-z0-9_-]+(?:/[a-z0-9_-]+)*', extract):
            raise SystemExit('invalid OpenStreetMap France extract path: ' + extract)
        url = f'{OSMFR}extracts/{extract}-latest.osm.pbf'
        # The checksum is published for the current file's own name only; a
        # mismatch means the extract was replaced mid-download, so retry later.
        md5 = fetch(f'{OSMFR}extracts/{extract}.osm.pbf.md5', temp / 'source.md5') \
            .read_text(encoding='utf-8').split()[0]
        pbf = download_verified(url, args.workdir / (extract.replace('/', '_') + '.osm.pbf'), md5)
        options = header(pbf)
        sequence = int(options.get('osmosis_replication_sequence_number', 0))
        # Headers name e.g. http://download.openstreetmap.fr/replication/./x/minute
        base = options.get('osmosis_replication_base_url', '').rstrip('/') \
            .replace('http://', 'https://', 1).replace('/./', '/')
        if sequence <= 0 or not base.startswith(OSMFR + 'replication/'):
            raise SystemExit('missing replication header: ' + extract)
        poly_url = f'{OSMFR}polygons/{extract}.poly'
        polygon = parse_poly(fetch(poly_url, temp / 'source.poly').read_text(encoding='utf-8'))
        sources.append({'url': url, 'poly': poly_url, 'polygon': polygon, 'pbf': pbf,
                        'sequence': sequence, 'base': base})
    from shapely.ops import unary_union
    if not unary_union([s['polygon'] for s in sources]).covers(box(*place['coverage'])):
        raise SystemExit('source polygons do not cover the complete padded area')
    target = max(s['sequence'] for s in sources)
    behind = target - min(s['sequence'] for s in sources)
    if behind > MAX_ALIGNMENT_DIFFS:
        raise SystemExit(f'extracts are {behind} minutely diffs apart; retry when both have updated')
    alignment = None
    files = []
    for s in sources:
        if s['sequence'] == target:
            files.append(s['pbf'])
            continue
        diffs = []
        for sequence in range(s['sequence'] + 1, target + 1):
            diffs.append(fetch(f"{s['base']}/{sequence_path(sequence)}.osc.gz",
                               temp / f'{len(files)}-{sequence}.osc.gz'))
        state = fetch(f"{s['base']}/{sequence_path(target)}.state.txt", temp / 'state.txt').read_text()
        stamp = re.search(r'^timestamp=(.+)$', state, flags=re.M).group(1).replace('\\:', ':')
        advanced = temp / f'advanced-{len(files)}.osm.pbf'
        subprocess.run(['osmium', 'apply-changes', '-o', str(advanced), str(s['pbf']), *map(str, diffs),
                        '--output-header', f'osmosis_replication_sequence_number={target}',
                        '--output-header', f'osmosis_replication_timestamp={stamp}'], check=True)
        files.append(advanced)
        alignment = {'source': s['base'] + '/', 'from_sequence': s['sequence'], 'to_sequence': target}
    stamps = {header(f).get('osmosis_replication_timestamp', '') for f in files}
    if len(stamps) != 1 or '' in stamps:
        raise SystemExit('sources did not align to one replication timestamp: ' + ', '.join(sorted(stamps)))
    merged = temp / 'merged.osm.pbf'
    merge_checked(files, merged)
    prepare(place, merged, stamps.pop(), ' + '.join(s['url'] for s in sources), place['coverage'], temp)
    extra = {'coverage_sources': [s['poly'] for s in sources]}
    if alignment:
        extra['replication_alignment'] = alignment
    return extra


def osmapi(place, args, temp):
    west, south, east, north = place['coverage']
    if (east - west) * (north - south) > OSM_API_MAX_AREA:
        raise SystemExit('view is too large for the OSM map API; use an extract')
    url = f'{OSM_API}map?bbox={west},{south},{east},{north}'
    response = temp / 'map.osm'
    headers = subprocess.check_output(['curl', '-fsSL', '--max-time', '600', '-D', '-',
                                       '-o', str(response), url], text=True)
    date = re.findall(r'^date:\s*(.+?)\s*$', headers, flags=re.I | re.M)
    if not date:
        raise SystemExit('OSM map API response has no Date header')
    stamp = email.utils.parsedate_to_datetime(date[-1]).strftime('%Y-%m-%dT%H:%M:%SZ')
    pbf = temp / 'map.osm.pbf'
    subprocess.run(['osmium', 'cat', '-o', str(pbf), str(response)], check=True)
    prepare(place, pbf, stamp, url, place['coverage'], temp)
    return {'source_timestamp_kind': 'HTTP response Date (live OSM map API; not a replication timestamp)'}


def relation(place, args, temp):
    url = place['url']
    if not url.startswith('https://download.geofabrik.de/'):
        raise SystemExit('relation mode supplements a GeoFabrik extract from the plan')
    md5 = fetch(url + '.md5', temp / 'source.md5').read_text(encoding='utf-8').split()[0]
    pbf = download_verified(url, args.workdir / Path(url).name, md5)
    options = header(pbf)
    stamp = options.get('osmosis_replication_timestamp', '')
    if not stamp or options.get('osmosis_replication_base_url', '').rstrip('/') != \
            url.removesuffix('-latest.osm.pbf') + '-updates':
        raise SystemExit('GeoFabrik provenance mismatch')
    supplement = fetch(f'{OSM_API}relation/{args.relation}/full', temp / 'relation.osm')
    stamps = [e.get('timestamp', '') for e in ET.parse(supplement).getroot() if e.tag in ('node', 'way', 'relation')]
    if not stamps or '' in stamps:
        raise SystemExit('relation response has objects without timestamps')
    if max(stamps) > stamp:
        raise SystemExit(f'relation has objects newer than the extract ({max(stamps)} > {stamp})')
    supplement_pbf = temp / 'relation.osm.pbf'
    subprocess.run(['osmium', 'cat', '-o', str(supplement_pbf), str(supplement)], check=True)
    merged = temp / 'merged.osm.pbf'
    merge_checked([pbf, supplement_pbf], merged)
    prepare(place, merged, stamp, f'{url} + {OSM_API}relation/{args.relation}/full', place['coverage'], temp)
    fetched = subprocess.check_output(['date', '-u', '+%Y-%m-%d'], text=True).strip()
    return {'geometry_supplement': f'OSM relation {args.relation} full, fetched {fetched}; '
                                   f'latest object timestamp {max(stamps)}; merged without multiple object versions'}


parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument('plan', type=Path)
parser.add_argument('identifier')
parser.add_argument('--workdir', type=Path, required=True, help='directory for source downloads')
modes = parser.add_subparsers(dest='mode', required=True)
modes.add_parser('bbbike').add_argument('city', help='BBBike city directory, e.g. WashingtonDC')
modes.add_parser('osmfr').add_argument('--extract', action='append', required=True,
    help='extract path under extracts/, without -latest.osm.pbf (repeat for each source)')
modes.add_parser('osmapi')
modes.add_parser('relation').add_argument('--relation', type=int, required=True, help='OSM relation ID')

if __name__ == '__main__':
    args = parser.parse_args()
    if args.mode == 'osmfr' and len(args.extract) < 2:
        parser.error('osmfr needs at least two --extract sources; use bundle_capital_region.py otherwise')
    plan = json.loads(args.plan.read_text(encoding='utf-8'))
    place = next((p for p in plan if p['identifier'] == args.identifier), None)
    if place is None:
        raise SystemExit('location not found in plan')
    args.workdir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='pr360-external-') as tmp:
        extra = {'bbbike': bbbike, 'osmfr': osmfr, 'osmapi': osmapi, 'relation': relation}[args.mode](
            place, args, Path(tmp))
    annotate_provenance(root, place['identifier'], extra)
    print(f'Bundled {place["identifier"]} from {args.mode} source')
