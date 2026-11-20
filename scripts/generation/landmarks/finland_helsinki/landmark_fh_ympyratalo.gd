extends RefCounted

## Ympyrätalo ("Circle House", 1970), Siltasaarenkatu 18-20 at the head of
## Eläintarhanlahti, Hakaniemi. Origin at the centre of the OSM outline (way
## 140493080 and its 2-level base part, 60.18034 N 24.9489 E), yaw 0.
##
## From the photographs (visual-plan/refs/landmarks/ympyratalo/): a round
## nine-storey office block, every storey a continuous glazed ribbon between
## spandrels of dark green patinated copper; the ground floor is a recessed
## glazed arcade on slender columns with orange awnings on the street side;
## a flat roof with a thin parapet and a plant room.
##
## Measured: the outline is a circle of 38.5 m radius (OSM, 76 m across) and
## carries 10 mapped levels. The registry's earlier point and 25 m height
## were guesses 320 m away from the building; this class moves the entry onto
## the way. Estimated: the 32.4 m parapet (34.6 m with the roof plant; ground arcade 5.2 m, nine storeys
## of 2.95 m, parapet), the spandrel/glass split, the awning positions.

const ENTRY := {"type": "ympyratalo", "name": "Ympyrätalo", "lat": 60.180335, "lon": 24.948931,
	"radius_m": 1500.0, "wiki_title": "Ympyrätalo", "height_m": 34.5, "clear_m": 42.0,
	"kind": "Office", "aliases": ["ympyrätalo", "round house hakaniemi", "rundhuset hagnäs"]}

const R := 38.5
const BASE_H := 5.2
const STOREY := 2.95
const STOREYS := 9

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6A8A76", 2.0, 0.45, 0.35))
	lm.use("Glass", LandmarkMaterials.paint("#7C98A4", 0.2, 0.3))
	lm.use("Frame", LandmarkMaterials.paint("#3A423E", 0.5, 0.4))
	lm.use("Awning", LandmarkMaterials.paint("#D9692A", 0.8, 0.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#7A746C", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#585C5C", 0.7))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 1.2))
	# Ground floor: recessed glazing behind slender columns, a plinth at the foot.
	lm.frustum("Base", Vector3.ZERO, R + 0.5, R + 0.5, 0.5, 64)
	lm.frustum("Glass", Vector3(0, 0.4, 0), R - 2.6, R - 2.6, BASE_H - 0.4, 64)
	lm.frustum("Frame", Vector3(0, 0.4, 0), R - 2.5, R - 2.5, 0.25, 64)
	lm.frustum("Frame", Vector3(0, BASE_H - 1.0, 0), R - 2.5, R - 2.5, 0.2, 64)
	for k in 72:
		var a := TAU * float(k) / 72.0
		lm.frustum("Frame", Vector3(cos(a) * (R - 0.6), 0.4, sin(a) * (R - 0.6)), 0.28, 0.22, BASE_H - 0.4, 8)
	# Storeys: copper spandrel, then the glazed ribbon with mullions.
	lm.frustum("Copper", Vector3(0, BASE_H - 0.6, 0), R + 0.2, R + 0.2, 0.9, 64)
	for s in STOREYS:
		var y0 := BASE_H + STOREY * float(s)
		lm.frustum("Glass", Vector3(0, y0, 0), R - 0.15, R - 0.15, 1.95, 64)
		lm.frustum("Copper", Vector3(0, y0 + 1.95, 0), R + 0.2, R + 0.2, 1.0, 64)
	for k in 96:
		var a := TAU * (float(k) + 0.5) / 96.0
		var p := Vector3(cos(a) * (R - 0.1), BASE_H, sin(a) * (R - 0.1))
		lm.beam("Frame", p, p + Vector3(0, STOREY * float(STOREYS) - 1.0, 0), 0.1)
	var top := BASE_H + STOREY * float(STOREYS)
	lm.frustum("Copper", Vector3(0, top - 0.6, 0), R + 0.35, R + 0.35, 1.2, 64)
	lm.frustum("Roof", Vector3(0, top + 0.5, 0), R - 0.2, R - 0.2, 0.25, 64)
	# Roof plant room and lift core.
	lm.box("Roof", Vector3(-6.0, top + 1.6, 4.0), Vector3(14.0, 2.6, 9.0))
	lm.box("Roof", Vector3(14.0, top + 1.2, -8.0), Vector3(6.0, 1.8, 6.0))
	# Orange awnings over the shopfronts on the street side (south-west).
	for k in 6:
		var a := deg_to_rad(112.0 + 9.0 * float(k))
		var p := Vector3(cos(a) * (R + 1.3), 3.7, sin(a) * (R + 1.3))
		lm.box("Awning", p, Vector3(5.8, 0.2, 3.2), Basis(Vector3.UP, -a + PI * 0.5))
	# Lit lobby behind the arcade.
	lm.frustum("Lamp", Vector3(0, 0.5, 0), R - 2.7, R - 2.7, 0.2, 64)
	lm.commit(model)
