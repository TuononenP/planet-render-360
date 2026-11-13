#!/usr/bin/env python3
"""Check that the batch does not skip missing, stale or corrupt snapshots."""
import hashlib
import http.server
import json
import socketserver
import subprocess
import sys
import tempfile
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'tools'))
from capital_snapshot_io import LAYERS, annotate_provenance, complete, download, parse_poly
import osmb

place = {'identifier': 'capital_test', 'lat': 12.0, 'lon': 34.0}
provenance = {place['identifier']: {'coordinates': [12.0, 34.0], 'country': 'XX', 'source': 'fixture',
              'source_timestamp': '2026-11-03T00:00:00Z', 'captured_at': '2026-11-05',
              'coverage': [1, 2, 3, 4],
              'query_versions': {'detailed_extract': 12, 'ring': 1, 'poi': 1, 'far': 3}, 'attribution': 'OSM'}}
payload = osmb.encode({'elements': []})
raw = osmb.compress(payload)
with tempfile.TemporaryDirectory() as directory:
    assets = Path(directory)
    manifest = {}
    for layer, (kind, version) in LAYERS.items():
        key = place['identifier'] + '_' + layer
        (assets / (key + '.osmb')).write_bytes(raw)
        manifest[key] = [place['lat'], place['lon'], kind, version, '2026-11-03T00:00:00',
                         len(payload), hashlib.sha256(payload).hexdigest()]
    assert complete(place, manifest, assets, provenance)
    assert not complete(place, manifest, assets, {})
    key = place['identifier'] + '_poi'
    (assets / (key + '.osmb')).write_bytes(osmb.compress(b'corrupt'))
    assert not complete(place, manifest, assets, provenance)
    (assets / (key + '.osmb')).write_bytes(raw)
    manifest[key][3] += 1
    assert not complete(place, manifest, assets, provenance)
    manifest[key][3] -= 1
    (assets / (key + '.osmb')).unlink()
    assert not complete(place, manifest, assets, provenance)

class RangeServer(http.server.BaseHTTPRequestHandler):
    content = b'complete source payload'

    def do_GET(self):
        value = self.headers.get('Range', '')
        # Force the open-ended resume to fail; bounded ranges must recover.
        if not value.startswith('bytes=') or value.endswith('-'):
            self.send_error(400)
            return
        start, end = (int(x) for x in value.removeprefix('bytes=').split('-'))
        body = self.content[start:end + 1]
        self.send_response(206)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Content-Range', f'bytes {start}-{end}/{len(self.content)}')
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


class LocalServer(http.server.ThreadingHTTPServer):
    def server_bind(self):
        socketserver.TCPServer.server_bind(self)
        self.server_name = 'localhost'
        self.server_port = self.socket.getsockname()[1]


server = LocalServer(('127.0.0.1', 0), RangeServer)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / 'source.pbf'
        path.write_bytes(RangeServer.content[:5])
        download(f'http://127.0.0.1:{server.server_port}/source', path, len(RangeServer.content))
        assert path.read_bytes() == RangeServer.content
finally:
    server.shutdown()
    server.server_close()
    thread.join()

# A bad source must not prevent subsequent regions from being attempted.
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory)
    plan = path / 'plan.json'
    plan.write_text(json.dumps([{**place, 'region': region} for region in ('bad$', 'bad!')]))
    result = subprocess.run([sys.executable, str(Path(__file__).resolve().parent.parent /
                            'tools/bundle_capital_plan.py'), str(plan), '--workdir', str(path / 'work')],
                            capture_output=True, text=True)
    assert result.returncode != 0
    assert 'FAILED: bad$' in result.stdout and 'FAILED: bad!' in result.stdout

# Source-specific provenance is added to the published record only.
with tempfile.TemporaryDirectory() as directory:
    fake_root = Path(directory)
    (fake_root / 'assets/osm_snapshots').mkdir(parents=True)
    record = fake_root / 'assets/osm_snapshots/capital_provenance.json'
    record.write_text(json.dumps(provenance))
    annotate_provenance(fake_root, place['identifier'], {'coverage_source': 'https://example.test/x.poly'})
    assert json.loads(record.read_text())[place['identifier']]['coverage_source'] == 'https://example.test/x.poly'
    try:
        annotate_provenance(fake_root, 'capital_unpublished', {'x': 1})
        raise AssertionError('annotating an unpublished snapshot must fail')
    except KeyError:
        pass

try:
    import shapely  # noqa: F401 (the external-source tools require it)
except ImportError:
    shapely = None
if shapely is None:
    print('SKIPPED .poly and replication checks: shapely is not installed')
else:
    from shapely.geometry import box
    import bundle_capital_external as external
    from bundle_capital_external import rectangular, sequence_path
    poly = parse_poly('city\n1\n 0 0\n 10 0\n 10 10\n 0 10\nEND\n!2\n 4 4\n 6 4\n 6 6\n 4 6\nEND\nEND\n')
    assert poly.covers(box(1, 1, 3, 3)) and not poly.covers(box(4.5, 4.5, 5.5, 5.5))
    for broken in ('city\n1\n 0 0\n 1 0\nEND\nEND\n', 'city\n1\n 0 0\n 1 0\n 1 1\n'):
        try:
            parse_poly(broken)
            raise AssertionError('a broken .poly file must be rejected')
        except ValueError:
            pass
    assert sequence_path(7358940) == '007/358/940' and sequence_path(5) == '000/000/005'
    assert rectangular(parse_poly('r\n1\n 0 0\n 4 0\n 4 2\n 0 2\nEND\nEND\n'))
    assert not rectangular(parse_poly('l\n1\n 0 0\n 4 0\n 4 2\n 2 2\n 2 4\n 0 4\nEND\nEND\n'))
    # An interrupted download resumes only when the source is unchanged.
    signature = {'url': 'u', 'size': 10, 'etag': 'a', 'last_modified': ''}
    calls = []
    external.remote_signature = lambda _url: dict(signature)
    external.download = lambda _url, target, _size: (calls.append(target), target.write_bytes(b'0123456789'))
    with tempfile.TemporaryDirectory() as directory:
        partial = Path(directory) / 'x.osm.pbf'
        checksum = hashlib.md5(b'0123456789').hexdigest()
        partial.write_bytes(b'012')
        try:
            external.download_verified('u', partial, checksum)
            raise AssertionError('a partial file without a matching marker must not resume')
        except SystemExit:
            pass
        assert not calls
        (Path(directory) / 'x.osm.pbf.source.json').write_text(json.dumps(signature))
        external.download_verified('u', partial, checksum)
        assert len(calls) == 1 and partial.read_bytes() == b'0123456789'
        external.download_verified('u', partial, checksum)
        assert len(calls) == 1
print('CAPITAL SNAPSHOT TOOLS OK: valid, corrupt, stale, missing, range retry, batch failures, '
      'provenance and source polygons')
