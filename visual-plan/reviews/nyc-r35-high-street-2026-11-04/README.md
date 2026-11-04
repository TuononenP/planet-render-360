# New York r35 — lamp-post support

[High Street close view](nyc_high_street_look1.jpg) repeats the mapped
entrance inspection from r33 after extending the two front posts to meet
the lower globe halves. The [focused furniture check](street-furniture-test.log)
passes, including the relationship between the post and globe geometry.
World-cache build version 180 invalidates the preceding mesh.

This remains a stylized street fixture: its stair treads are raised above
the surface rather than descending through an excavated opening. The view
uses cached detailed data; POIs timed out and far towers were absent.
[Capture log](capture.log). Nonfatal exit leak warnings remain.

[Final validation](verification.json): the furniture test, class-size check,
world-cache test and screenshot sequence pass. The cache check used the
adjacent copy of `tests/world_cache_test.gd` with only its OSM and far-city
fetchers set to offline mode after initialization; it verified the same
world, ground and eviction with a 20.403 s first opening and 3.511 s cached
revisit. The screenshot sequence used its `--offline-osm` option, produced
16 readable images, and the Paris viewer frame was inspected. These cached
map runs are regression checks, not the complete-data cold-load measurement.
