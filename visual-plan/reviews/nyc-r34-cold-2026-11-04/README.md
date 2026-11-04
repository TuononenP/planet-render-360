# New York r34 — empty-cache retry

Ultra, clear summer at 08:00, opening bearing 295°, isolated empty data
and world caches. [Opening](new_york_vantage.jpg) took 103 s; parallel
generation took 5.945 s. The far-city fetch exceeded the pipeline wait
budget and the rendered scene contains no far towers. The POI request
timed out. This is not a complete-data performance or fidelity pass.

The [response audit](data-completeness.json) records detailed, ring and
far-city responses with no runtime remarks. The far response was cached
after the rendering budget expired, so its presence on disk does not mean
its towers were used in this capture. The isolated capture cache was removed
after recording counts and hashes. [Capture log](capture.log).
