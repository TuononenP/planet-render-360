#!/usr/bin/env python3
"""Compare frozen-input cold geometry runs; keep failing cases visible."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--before', type=Path, required=True)
parser.add_argument('--after', type=Path, required=True)
parser.add_argument('--captures', type=Path)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
before = json.loads(args.before.read_text())
after = json.loads(args.after.read_text())
captures = json.loads(args.captures.read_text()) if args.captures else {}
rows = []
failures = []
for key, baseline in before.items():
    if 'build_ms' not in baseline:
        continue
    candidate = after.get(key)
    if not candidate or 'build_ms' not in candidate:
        failures.append(f'Missing benchmark: {key}')
        continue
    old, new = baseline['build_ms'], candidate['build_ms']
    delta = (new / old - 1) * 100
    if delta > 20:
        failures.append(f'{key}: build time +{delta:.1f}% exceeds +20%')
    preset = int(key.rsplit('_p', 1)[1])
    budget = [20000, 75000, 75000, 150000][preset]
    if new > budget:
        failures.append(f'{key}: geometry build {new / 1000:.2f}s exceeds cold budget {budget / 1000:.0f}s')
    metrics = captures.get(key + '_vantage', {}).get('build_metrics', {})
    patch_failures = sum(d.get('kind') == 'patch_failure' for d in metrics.get('diagnostics', []))
    if patch_failures:
        failures.append(f'{key}: {patch_failures} failed correction patches')
    rows.append((key, old, new, delta, patch_failures))
old_peak = max((v.get('static_peak_bytes', 0) for v in before.values()), default=0)
new_peak = max((v.get('static_peak_bytes', 0) for v in after.values()), default=0)
memory_delta = (new_peak / old_peak - 1) * 100 if old_peak else None
if memory_delta is not None and memory_delta > 25:
    failures.append(f'Static peak memory +{memory_delta:.1f}% exceeds +25%')
lines = ['# Shoreline validation measurements', '',
         'Cold geometry builds use frozen LocationData, disabled world caches, and the same machine. '
         'Source fetch time is excluded. Individual failures remain acceptance failures even when the aggregate improves.', '',
         '| Case | Before (s) | After (s) | Change | Patch failures |',
         '|---|---:|---:|---:|---:|']
for key, old, new, delta, patches in rows:
    lines.append(f'| {key} | {old / 1000:.2f} | {new / 1000:.2f} | {delta:+.1f}% | {patches} |')
if rows:
    old_sum = sum(r[1] for r in rows)
    new_sum = sum(r[2] for r in rows)
    lines += ['', f'Total geometry time: {old_sum / 1000:.2f}s → {new_sum / 1000:.2f}s '
                  f'({(new_sum / old_sum - 1) * 100:+.1f}%).']
if memory_delta is not None:
    lines += ['', f'Godot static peak: {old_peak / 2**20:.1f} → {new_peak / 2**20:.1f} MiB '
                  f'({memory_delta:+.1f}%). Native/driver resident peak must be checked separately with `/usr/bin/time -l`.']
lines += ['', '## Acceptance failures', '']
lines += ['- ' + item for item in failures] if failures else ['No automated budget or patch failures in these measurements. Visual gates remain separate.']
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text('\n'.join(lines) + '\n')
print(f'{len(rows)} cases, {len(failures)} failures → {args.output}')
