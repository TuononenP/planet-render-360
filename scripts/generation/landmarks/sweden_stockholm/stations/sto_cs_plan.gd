extends RefCounted

## Plan of Stockholm Central in the registry frame (origin = the OSM outline
## centroid of way 35473137, +X along the Vasagatan front, +Z out to
## Centralplan and Vasagatan, the tracks toward -Z). Every number below is
## read off the bundled OSM outline (assets/osm_snapshots/stockholm_detailed)
## turned into that frame, so the model stands on the mapped footprint.

## Centre line of the front range (the outline is symmetric about it).
const CX := 4.5
## Back of the front range: behind this line the lower rear mass begins.
const ZB := 24.5

## Front sections: [x0, x1, z of the front face, kind, bays].
## The 1871 front is a long range with a taller, deeper central block and
## an end pavilion on each side; the wings sit 4-5 m behind the centre.
const SECTIONS := [
	[-68.0, -53.0, 46.0, "pav", 3],
	[-53.0, -13.0, 42.0, "wing", 9],
	[-13.0, 22.0, 47.0, "centre", 0],
	[22.0, 62.0, 42.0, "wing", 9],
	[62.0, 79.0, 46.5, "pav", 4],
]
## Back of the central block (it runs deep into the hall behind).
const ZC_BACK := 0.0

## Storey lines: rusticated ground floor, two plastered floors, cornice.
const RUST := 5.0
const FLOOR2 := 9.6
const EAVE := 14.5
## Central block: tall piano nobile, attic frieze, cornice.
const C_NOBLE := 6.2
const C_ATTIC := 12.7
const C_EAVE := 16.0

## Rear mass (the outline behind the front range), clockwise on the map.
const REAR := [Vector2(-90, 24.5), Vector2(-68, 24.5), Vector2(63, 24.5), Vector2(63, 15), Vector2(64, -7),
	Vector2(65, -15), Vector2(42, -29), Vector2(4, -24), Vector2(-16, -22), Vector2(-89, -21)]
## Annex toward the Klarabergsviadukten end of the outline.
const TAIL := [Vector2(42, -29), Vector2(65, -15), Vector2(67, -45), Vector2(87, -58), Vector2(90, -90),
	Vector2(90, -96), Vector2(64, -95), Vector2(60, -91), Vector2(46, -76), Vector2(46, -71),
	Vector2(44, -70), Vector2(44, -47), Vector2(41, -47), Vector2(41, -41), Vector2(42, -32)]
const REAR_H := 14.5
const TAIL_H := 9.5

## Registry height: the top of the flagpole over the central roof.
const TOP := 33.0

## Materials of the model (keys <= 16): plaster, rusticated granite, pale
## stone dressings, glazing, slate, painted iron, the platform canopies'
## corrugated roofs, the lit sign, clock dial and flag.
static func materials(lm: LandmarkMesh) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D3D0C6", 3.0))
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#9B9A93", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E1DED4", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#20282D"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#34383B", 2.0, 0.6))
	lm.use("Steel", LandmarkMaterials.paint("#3F4A4D"))
	lm.use("Canopy", LandmarkMaterials.pbr("sheet_metal", "#6C5B4E", 3.0, 0.7, 0.3))
	lm.use("Sign", LandmarkMaterials.lit("#EDE8D6", 0.45))
	lm.use("Dial", LandmarkMaterials.lit("#F2EEE0", 0.35))
	lm.use("Pole", LandmarkMaterials.paint("#EDEDED", 0.5, 0.3))
