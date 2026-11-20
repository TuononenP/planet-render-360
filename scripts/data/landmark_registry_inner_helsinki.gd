class_name LandmarkRegistryInnerHelsinki
extends RefCounted

## Katajanokka, Kallio, Jätkäsaari and Ruoholahti landmarks, extruded
## from OSM outlines (LandmarkFhInnerFootprints). Entry lat/lon is the
## outline origin; outline-built models clear their footprint through
## clear_offsets_m ([x east, z south] about the entry, yaw 0). Sources:
## docs/helsinki-landmark-sources.md.
static func entries() -> Array:
	return [
	]
