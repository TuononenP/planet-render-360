# Shoreline validation measurements

Cold geometry builds use frozen LocationData, disabled world caches, and the same machine. Source fetch time is excluded. Individual failures remain acceptance failures even when the aggregate improves.

| Case | Before (s) | After (s) | Change | Patch failures |
|---|---:|---:|---:|---:|
| amsterdam_p0 | 29.70 | 32.63 | +9.9% | 0 |
| amsterdam_p1 | 30.62 | 35.87 | +17.1% | 0 |
| amsterdam_p2 | 31.42 | 34.03 | +8.3% | 0 |
| amsterdam_p3 | 50.47 | 40.42 | -19.9% | 0 |
| big_sur_p0 | 0.89 | 1.52 | +71.5% | 0 |
| big_sur_p1 | 0.63 | 1.71 | +172.7% | 0 |
| big_sur_p2 | 0.80 | 1.99 | +149.9% | 0 |
| big_sur_p3 | 1.05 | 1.86 | +77.3% | 0 |
| dubai_p0 | 9.33 | 9.03 | -3.1% | 0 |
| dubai_p1 | 9.84 | 9.43 | -4.1% | 0 |
| dubai_p2 | 10.55 | 11.03 | +4.5% | 0 |
| dubai_p3 | 10.82 | 10.35 | -4.3% | 0 |
| helsinki_p0 | 27.94 | 31.33 | +12.1% | 0 |
| helsinki_p1 | 27.67 | 32.63 | +17.9% | 0 |
| helsinki_p2 | 29.50 | 33.78 | +14.5% | 0 |
| helsinki_p3 | 29.69 | 34.49 | +16.2% | 0 |
| monaco_p0 | 2.17 | 2.97 | +36.5% | 0 |
| monaco_p1 | 2.68 | 3.54 | +32.2% | 0 |
| monaco_p2 | 2.92 | 4.79 | +64.1% | 0 |
| monaco_p3 | 3.95 | 4.90 | +23.9% | 0 |
| paris_p0 | 4.68 | 6.07 | +29.6% | 0 |
| paris_p1 | 5.35 | 6.70 | +25.2% | 0 |
| paris_p2 | 5.72 | 8.39 | +46.6% | 0 |
| paris_p3 | 8.87 | 10.84 | +22.1% | 0 |
| stockholm_p0 | 24.64 | 5.12 | -79.2% | 0 |
| stockholm_p1 | 4.36 | 5.75 | +32.0% | 0 |
| stockholm_p2 | 4.63 | 7.79 | +68.1% | 0 |
| stockholm_p3 | 6.93 | 7.78 | +12.3% | 0 |
| venice_p0 | 43.15 | 18.43 | -57.3% | 0 |
| venice_p1 | 44.02 | 24.39 | -44.6% | 0 |
| venice_p2 | 47.40 | 37.38 | -21.1% | 0 |
| venice_p3 | 45.73 | 43.97 | -3.8% | 0 |

Total geometry time: 558.13s → 520.93s (-6.7%).

Godot static peak: 2414.2 → 2421.6 MiB (+0.3%). Native/driver resident peak must be checked separately with `/usr/bin/time -l`.

## Acceptance failures

- amsterdam_p0: geometry build 32.63s exceeds cold budget 20s
- big_sur_p0: build time +71.5% exceeds +20%
- big_sur_p1: build time +172.7% exceeds +20%
- big_sur_p2: build time +149.9% exceeds +20%
- big_sur_p3: build time +77.3% exceeds +20%
- helsinki_p0: geometry build 31.33s exceeds cold budget 20s
- monaco_p0: build time +36.5% exceeds +20%
- monaco_p1: build time +32.2% exceeds +20%
- monaco_p2: build time +64.1% exceeds +20%
- monaco_p3: build time +23.9% exceeds +20%
- paris_p0: build time +29.6% exceeds +20%
- paris_p1: build time +25.2% exceeds +20%
- paris_p2: build time +46.6% exceeds +20%
- paris_p3: build time +22.1% exceeds +20%
- stockholm_p1: build time +32.0% exceeds +20%
- stockholm_p2: build time +68.1% exceeds +20%
