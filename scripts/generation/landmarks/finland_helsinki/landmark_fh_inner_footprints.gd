class_name LandmarkFhInnerFootprints
extends RefCounted

## Outlines of the inner-Helsinki district landmarks (Katajanokka, Kallio,
## Jätkäsaari, Ruoholahti) from OpenStreetMap (2026-11-12, read through
## the OSM API; ways in docs/helsinki-landmark-sources.md), Douglas-Peucker
## simplified to 0.5–1 m. Flat x, z pairs in metres about the registry
## entry's lat/lon: +X east, +Z south, the entry's yaw_deg 0. The facade
## helpers live in LandmarkFhWestFootprints.

const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const OUTLINES := {
	"enso_gutzeit_hq": [-11.7, -27.7, 11.4, -12.6, 4.7, -2.5, 17.1, 5.6, 23.8, -4.5, 32.1, 0.9, 14.8, 26.9, -28.9, -1.7],
	"merikasarmi": [
		-51.7, 38.5, -57.0, 28.5, -45.4, 22.3, -50.2, 13.3, -61.9, 19.5, -67.2, 9.4, -51.4, 1.1, -43.3, 16.3,
		37.1, -26.0, 29.7, -40.0, 45.8, -48.5, 50.9, -39.0, 39.2, -32.9, 43.6, -24.5, 55.4, -30.7, 61.8, -18.8,
		58.8, -17.2, 58.2, -18.3, 45.8, -11.7, 46.3, -10.7, -36.9, 33.1, -37.9, 31.3],
	"katajanokka_terminal": [
		-19.7, -29.3, -7.3, -22.4, 2.7, -18.3, 14.3, -14.1, 35.0, -9.6, 29.0, 22.3, 7.4, 17.3, 5.0, 25.3,
		-9.6, 19.6, -29.8, 13.2, -24.8, 3.1, -34.9, -2.0],
	"kallio_library": [
		-0.8, -15.0, 0.8, -14.7, 1.3, -13.5, 5.2, -14.1, 8.9, -12.9, 11.6, -10.1, 12.6, -5.0, 14.1, -4.8,
		14.7, -3.7, 13.7, -2.1, 14.9, -1.2, 1.4, 16.6, -3.7, 12.8, -4.9, 14.4, -8.7, 11.5, -12.5, 8.6,
		-11.3, 7.0, -16.5, 3.2, -3.0, -14.6, -1.8, -13.7],
	"kallio_virastotalo": [
		-48.3, -7.5, -49.1, -27.9, -1.8, -29.6, -1.9, -31.7, 18.7, -32.5, 18.8, -30.3, 51.5, -31.6, 52.3, -11.1,
		19.8, -9.8, 22.0, 45.8, 1.2, 46.6, 0.8, 36.7, -50.2, 38.7, -50.7, 25.8, 0.4, 24.3, -1.0, -9.4],
	"clarion_hotel": [
		9.6, -34.4, -13.7, -18.5, -11.5, -15.4, -10.8, 1.5, -20.9, 2.0, -20.1, 16.8, -10.2, 16.3, -6.9, 51.3,
		3.3, 50.3, 1.8, 32.6, 7.7, 32.1, 6.5, 15.4, 11.8, 15.1, 11.0, 0.3, 6.2, 0.5, 5.5, -14.4, 17.7, -22.7],
	"west_terminal_2": [
		18.8, 68.8, 33.9, 41.8, 20.7, -3.7, 25.1, -15.1, 51.6, -64.3, 25.6, -78.2, -5.5, -23.2, -14.8, -15.9,
		-54.6, -4.0, -68.7, 22.0, -67.5, 22.2, -68.0, 23.3, -36.4, 29.1, -21.8, 33.1, -11.0, 39.3, 17.0, 69.1,
		17.8, 67.7],
	"cable_factory": [
		-60.2, 51.8, -62.5, 44.4, -64.9, 45.2, -67.5, 37.1, -70.3, 38.0, -73.0, 29.3, -77.3, 30.7, -79.8, 22.6,
		-81.8, 23.2, -84.5, 14.6, -87.5, 15.5, -89.6, 8.6, -92.1, 9.4, -94.3, 2.6, -96.9, 3.4, -98.9, -3.2,
		68.9, -55.8, 75.5, -35.0, -50.0, 4.4, -45.0, 20.3, 97.0, -24.3, 104.8, 0.1],
	"salmisaari_power_plant": [
		-15.8, 42.7, -26.4, 29.0, -29.6, 31.4, -30.8, 29.8, -32.3, 30.9, -37.4, 24.2, -28.6, 17.5, -45.2, -4.0,
		12.0, -47.4, 28.6, -25.9, 30.2, -27.1, 36.6, -18.8, 35.0, -17.6, 44.7, -5.0, 31.7, 4.8, 43.4, 20.1,
		40.8, 22.1, 33.1, 12.1, 31.6, 13.2, 27.6, 7.9, 19.7, 13.9, 25.6, 21.6, -4.3, 44.3, -9.3, 37.8],
}

## Clarion Hotel's two 16-storey towers on its podium (building:part ways
## 458878736 and 458878737) about the hotel entry (way 441505566).
const CLARION_SOUTH := [-20.9, 2.0, 11.0, 0.3, 11.8, 15.1, -20.1, 16.8]
const CLARION_NORTH := [-13.7, -18.5, 9.6, -34.4, 17.7, -22.7, -5.6, -6.8]
## The glazed atrium between them.
const CLARION_ATRIUM := [-10.8, 1.5, -11.5, -15.4, -5.6, -6.8, 5.5, -14.4, 6.2, 0.5]

## Salmisaari about the Salmisaari A boiler house (way 14829857): its
## 11- and 9-storey parts (ways 445475459, 445475464), the 1953 brick
## chimney (349596089, 114 m), the 150 m chimney (349596091) and the two
## Lämpöakku heat-storage tanks (349596073, 349596077).
const SALMISAARI_HIGH := [36.6, -18.8, 30.2, -27.1, -37.4, 24.2, -32.3, 30.9, -26.4, 29.0]
const SALMISAARI_MID := [12.0, -47.4, -45.2, -4.0, -28.6, 17.5, 28.6, -25.9]
const BRICK_CHIMNEY := Vector2(-23.8, -38.5)
const TALL_CHIMNEY := Vector2(56.2, -153.4)
const TANKS := [Vector2(-26.4, -73.4), Vector2(-14.1, -57.5)]
const CHIMNEY_RADII := {"brick": 5.0, "tall": 4.3}
const TANK_RADIUS_M := 9.7

## Linnanmäki about its entry (the Vuoristorata, OSM way 12118154): the
## wooden coaster's mapped centreline and the drop and observation towers
## Kingi (way 988146105, 75 m), Panoraama (988146106, 53 m) and Raketti
## (988146107, 60 m).
const COASTER_LINE := [
	-40.4, -37.9, -43.1, -45.9, -39.9, -53.9, -29.8, -57.5, -23.1, -55.9, -19.2, -53.1, 27.4, 16.1,
	30.8, 24.5, 28.4, 31.7, 24.3, 35.0, 19.7, 35.5, 13.8, 34.2, 8.0, 30.7]
## Half the width of the coaster's timber structure about its centreline.
const COASTER_HALF_M := 7.0
const KINGI := Vector2(-5.4, 90.2)
const PANORAAMA := Vector2(-31.4, 115.5)
const RAKETTI := Vector2(-63.9, -26.3)
const TOWER_RADII := {"kingi": 2.2, "panoraama": 1.6, "raketti": 1.7}

## Every footprint polygon of `type` (one, or several for a group).
static func outlines(type: String) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if type == "linnanmaki":
		var band := Geometry2D.offset_polyline(coaster_line(), COASTER_HALF_M,
			Geometry2D.JOIN_MITER, Geometry2D.END_BUTT)
		if not band.is_empty():
			out.append(band[0])
		out.append(circle(KINGI, TOWER_RADII["kingi"]))
		out.append(circle(PANORAAMA, TOWER_RADII["panoraama"]))
		out.append(circle(RAKETTI, TOWER_RADII["raketti"]))
	elif type == "salmisaari_power_plant":
		out.append(W._poly(OUTLINES[type]))
		out.append(circle(BRICK_CHIMNEY, CHIMNEY_RADII["brick"]))
		out.append(circle(TALL_CHIMNEY, CHIMNEY_RADII["tall"]))
		for t: Vector2 in TANKS:
			out.append(circle(t, TANK_RADIUS_M))
	elif OUTLINES.has(type):
		out.append(W._poly(OUTLINES[type]))
	return out

static func outline(type: String) -> PackedVector2Array:
	var all := outlines(type)
	return all[0] if all.size() == 1 else PackedVector2Array()

static func coaster_line() -> PackedVector2Array:
	return W._poly(COASTER_LINE)

static func circle(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 12:
		var a := TAU * float(k) / 12.0
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out
