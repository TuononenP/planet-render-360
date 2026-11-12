class_name KruunuvuorensiltaLine
extends RefCounted

## Plan of Kruunuvuorensilta (Crown Bridge, Helsinki), shared by its
## registry entry (the curved clearance, `clear_path_m`) and its model
## (LandmarkFhCrownBridge). Metres about the registry site 60.1736 N,
## 25.0022 E, x east and z south (yaw 0), measured from OpenStreetMap:
## the deck centre is the midline of the man_made=bridge outline (way
## 1119395118, bridge:structure=cable-stayed) every 24 m, `w` its
## half-width (16 m wide on the approaches, 21 m round the pylon), with
## the Palosaari underpass span (way 1315670052) at its western end.
## The pylon stands on Kruunuvuorensillan tekosaari (way 1033592478),
## the artificial islet between Nimismies and Emäntä.
## Sources: OpenStreetMap (ODbL); fi Wikipedia "Kruunuvuorensilta" and
## kruunusillat.fi (1191 m, 135 m pylon, 17 stay pairs, longest stay
## 257 m, 20 m navigation clearance, tram, cycle and footpaths, the paths
## on the south edge behind a wind screen); ASCE Civil Engineering Source
## 2026-04 (diamond-shaped pylon, about 250 m cable-stayed spans each way).

## Deck centre (x, z) and half-width (as the third component), west to east.
const CENTRE: PackedVector3Array = [
	Vector3(-485.0, -289.5, 8.5), Vector3(-466.7, -288.1, 7.9), Vector3(-443.2, -283.3, 8.0), Vector3(-419.6, -278.5, 8.2),
	Vector3(-396.3, -273.0, 8.3), Vector3(-373.1, -266.8, 8.4), Vector3(-350.2, -259.7, 8.7), Vector3(-327.5, -251.7, 8.6),
	Vector3(-305.2, -242.8, 8.4), Vector3(-283.1, -233.5, 8.1), Vector3(-261.5, -223.0, 8.1), Vector3(-240.1, -212.2, 8.1),
	Vector3(-218.9, -200.8, 8.3), Vector3(-198.0, -189.1, 8.3), Vector3(-177.3, -176.9, 8.6), Vector3(-156.8, -164.3, 8.9),
	Vector3(-136.4, -151.7, 9.2), Vector3(-116.1, -138.9, 9.2), Vector3(-95.9, -125.9, 9.4), Vector3(-75.9, -112.6, 9.8),
	Vector3(-55.9, -99.3, 10.2), Vector3(-36.0, -85.9, 10.5), Vector3(-16.1, -72.4, 10.6), Vector3(3.7, -58.8, 10.5),
	Vector3(23.5, -45.3, 10.4), Vector3(43.4, -31.8, 10.3), Vector3(63.2, -18.3, 10.3), Vector3(82.5, -4.0, 9.9),
	Vector3(101.6, 10.6, 9.6), Vector3(120.7, 25.1, 9.4), Vector3(139.8, 39.7, 9.1), Vector3(158.6, 54.6, 8.9),
	Vector3(177.2, 69.8, 8.8), Vector3(195.5, 85.3, 8.7), Vector3(213.7, 101.0, 8.9), Vector3(231.3, 117.3, 8.3),
	Vector3(248.7, 133.9, 7.9), Vector3(265.9, 150.7, 7.9), Vector3(283.1, 167.4, 8.0), Vector3(299.9, 184.5, 8.0),
	Vector3(316.6, 201.9, 8.3), Vector3(333.1, 219.3, 8.5), Vector3(348.7, 237.5, 8.2), Vector3(364.2, 255.9, 8.1),
	Vector3(379.4, 274.4, 8.1), Vector3(394.4, 293.2, 8.2), Vector3(409.0, 312.2, 8.3), Vector3(423.4, 331.4, 8.6),
	Vector3(437.4, 350.9, 8.6), Vector3(451.8, 370.2, 8.3), Vector3(466.9, 388.8, 8.2),
]
## Pylon foot on the deck centreline, on the artificial islet.
const PYLON_XZ := Vector2(-44.0, -91.3)

## The registry clearance: every other centre point (chords within a
## metre of the curve), [x, z] pairs as LandmarkSites reads them.
static func clear_path() -> Array:
	var out: Array = []
	for i in CENTRE.size():
		if i % 2 == 0 or i == CENTRE.size() - 1:
			out.append([CENTRE[i].x, CENTRE[i].y])
	return out
