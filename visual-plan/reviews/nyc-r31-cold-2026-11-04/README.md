# New York r31 — isolated cold load

Fresh empty data and world caches, Ultra, clear summer 08:00, 295° opening.
World caching disabled for this measurement. [Opening](new_york_vantage.jpg)
and [foreground](new_york_bank.jpg) retain the skyline and Pier 1 rail.
Facades, shoreline, foliage and reflections remain visibly procedural;
agent pre-rating stays **recognisable**.

After removing the whitelist-only OSM-FR mirror, the opening took **90 s**.
The parallel generation phase took **8.176 s**; the far-city network/parse
phase took **73.792 s**, independently of generation. The opening time
also includes other network requests, parsing and pipeline coordination;
subtracting generation would not isolate HTTP time.

[Response audit](data-completeness.json): detailed q12 returned 22,883
elements / 16,752,051 bytes, including its query marker; far q3 returned
34,651 elements / 36,898,090 bytes. Neither response contains a runtime
remark. Far fetch reports `partial=false`, 1,173 landuse areas and 3,000
selected towers. Rendered far city: 549 ms, 276,362 triangles / 302 meshes.

The optional ring exceeded its 10 s grace period; POIs returned HTTP 502.
Thus detailed and far data are complete within their query caps, but the
strict all-layer cold-load gate remains open despite the sub-150 s opening.
The subsequent POI mirror correction is not part of this measurement.

[Capture log](capture.log). Nonfatal exit leak warnings remain.
All Godot runs used the background wrapper and the capture ran off-screen.
