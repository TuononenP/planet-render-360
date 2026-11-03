# Landmark placement audit — 2026-11-03

The original Alcatraz mainland capture and temporary-checkout Itsukushima
capture failed visual review: ordinary buildings were partly underwater.
A landmark root at sea level alone did not protect the surrounding buildings.
The first shrine close-up also failed: floors still coincided with static
water, walls sank another 0.6 m, and platform supports were absent. That
rejected view is retained as `itsukushima_shrine_waterfront_before_platforms.jpg`.
The earlier Alcatraz review is superseded by the waterfront captures here.

## Coverage

- Built and measured all **483** registry models: `catalog.tsv`.
- Ran live DEM-only placement probes for **31** vulnerable sites:
  `dem-before.tsv` / `dem-after.tsv`. These deliberately omit OSM to exercise
  missing-water-data fallback; they are not full-scene water validation.
- Inspected real DEM/OSM arrival and overview captures for Golden Gate,
  Itsukushima, Mont-Saint-Michel, Edinburgh Castle, Hoover Dam, Monks Mound,
  Burj Al Arab and Allas Sea Pool, plus Alcatraz from San Francisco.
- The final waterfront capture script is `capture_waterfront.gd`. Launch it
  in the background through `tools/godot_bg.sh --position 4000,4000`.
  The images are game renders, not edited reference images.

## Reviewed waterfront captures

- [Alcatraz from San Francisco](from_sf.jpg)
- [Pier 45 waterline close-up](sf_pier45_waterline.jpg)
- [Shed D and its platform](sf_shed_d_clearance.jpg)
- [Itsukushima arrival](itsukushima_torii_arrival.jpg)
- [Itsukushima shrine overview](itsukushima_shrine_waterfront.jpg)
- [Low view of raised shrine platform and supports](itsukushima_shrine_platform.jpg)
- [Allas Sea Pool and Helsinki waterfront](allas_sea_pool_overview.jpg)

`waterfront-captures.log` and `coastal-captures.log` completed without script
or shader compilation errors. Exit still reports seven leaked texture RIDs
and three objects; the captures are complete.

## Shared corrections

Twenty coastal sites use an explicit sea datum; five inland river bridges
retain bank-levelled water, falling back to local site DEM when water data
is missing. Primary and secondary landmarks use the same full registry
metadata. Camera height, focus and saved-view height share those datums.

Accepted waterfront buildings whose sampled ground is below the required
wave clearance use an estimated floor at least 1.5 m above the static surface, clearing the shader
crest (1.13 m) plus its surface lift. Legacy grids add their 1.3 m upward
swell bias to that clearance. This freeboard is an inferred fallback, not a
surveyed shrine floor or a tide simulation. Walls on raised floors no longer
sink 0.6 m below their floor. Platforms and timber/concrete pilings provide
visible support while preserving courtyard holes. Low pier footprints with
at most 4 m of sampled relief also clear their highest sampled dry corner;
a steep bank does not lift an entire overwater building to the bank top.
The coastal fallback now uses the renderer's 0.5 m sea surface, rather than
the authored landmark origin at zero. Ground-storey splits,
facade relief, roof jobs and party-wall heights use the same floor. Carved shoreline water no longer adds the legacy 1.3 m upward swell
bias. Distant authored island terrain openings retain their sea underlay
when the canonical shoreline builder is used.

Itsukushima's former coordinate was inside the main shrine. The gate now
uses the centroid and approximately 49.65° orientation of
[OSM way 555763409](https://www.openstreetmap.org/way/555763409):
34.297297 N, 132.318135 E. Its 180 m arrival framing keeps the small gate
readable. The [Prefectural University of Hiroshima's guide](https://www.pu-hiroshima.ac.jp/uploaded/attachment/20890.pdf)
places the gate offshore from the shrine and gives its 16.6 m height.

Authored crags and mounds replace covered DEM triangles and join the
surrounding terrain with skirts. Their base offsets are preserved for both
primary visits and secondary landmarks.

| Site | Previous origin ASL (m) | Corrected origin ASL (m) |
| --- | ---: | ---: |
| Golden Gate | -173.33 | 0.00 |
| Itsukushima torii | -5876.16 | 0.00 |
| Sydney Harbour Bridge | -970.18 | 0.00 |
| Mont-Saint-Michel | 26.50 | 71.50 |
| Edinburgh Castle | 81.51 | 119.73 |
| Hoover Dam crest | 545.88 | 375.50 |
| Monks Mound base | 138.10 | 130.00 |
| Burj Al Arab | -0.32 | 0.00 |

The torii before/after also changes the horizontal site coordinate.
These DEM-only origins can differ slightly from the final OSM-ground build.
Hoover uses the [US Bureau of Reclamation crest elevation](https://www.usbr.gov/projects/index.php?id=122).
Monks Mound uses [Cahokia's 130 m base contour](https://cahokiamounds.org/mound/mound-38-monks-mound/).

## Pier 45 clearance follow-up

The previous rule missed dry pier ground just above static water. Its
coastal fallback also used 0 m although rendered coastal water uses 0.5 m.
Shed D's old 1.50 m floor could be reached by the 1.66 m maximum water
surface (0.50 m datum + 0.03 m surface lift + 1.13 m swell). Sheds A/B
also had occupied walls sunk into their low pier ground.

| Mapped building | Previous floor ASL (m) | New floor ASL (m) |
| --- | ---: | ---: |
| Shed A | 1.22 | 2.98 |
| Shed B | 0.67 | 2.49 |
| Shed D | 1.50 | 2.49 |

These are generated scene measurements, not surveyed building elevations.
`sf-pier-clearance.json` records the current floor and water datums. New
regressions cover ground exactly at sea level, slightly above it, and an
uneven low pier slab. The close-up shows the supported platform clearing
the water; the distant overview alone is insufficient evidence.

## Verification and limits

`tests.log`: all ten headless suites pass: landmark placement, Alcatraz,
coastal water, coastal DEM, shoreline geometry, building fabric, far city,
preset views, viewer tools and world-cache keys. The class-size check passes. `parallel-build.log` also verifies that serial
and parallel builds have identical 102 top-level children.
The placement test also extrudes waterfront walls above a deliberately deep
bed, checks occupied wall vertices clear the wave envelope and that the
raised building has a platform and pilings, checks distant island sea fill
and zero upward swell bias, and preserves
dry depressions without invented water levels.

The scoped commit was also checked in a scratch snapshot of the committed
baseline: placement, Alcatraz, landmark fidelity, landmark models, the full
483-entry catalog, building fabric, scenery, preset views, viewer tools,
world-cache keys and OSM parsing pass, together with the class-size check.
The separate in-progress canonical shoreline generator is not included.
The captures and numeric pier measurements above use that generator in the
shared workspace; the committed legacy path retains the additional 1.3 m
swell allowance documented above. Both placement paths are regression-tested.

This is a placement audit, not visual certification of every registry site.
The captures still expose separate fidelity problems: overly steep shore
terraces at Miyajima, access paths drawn over tidal water, simplified shrine
architecture, coarse far-water seams, and Hoover terrain intersecting parts
of its downstream face. Those views are not photorealism acceptance passes.
The temporary `/tmp/planet-placement-check` images use an older water pipeline
and are retained as failed diagnostic evidence, not current acceptance shots.
