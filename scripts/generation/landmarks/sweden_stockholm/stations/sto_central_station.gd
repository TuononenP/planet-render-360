extends RefCounted

## Stockholm Central (Stockholms centralstation): Adolf W. Edelsvard's 1871
## station building on Vasagatan, extended in the 1920s, in the registry frame
## of data/stockholm/sto_reg_inner.gd (see sto_cs_plan.gd): the long pale plastered
## range with its taller central block and end pavilions (sto_cs_front.gd), the
## black slate mansards, dormers and the flag (sto_cs_roofs.gd), the lower rear
## mass, the central hall vault and the platform canopies over the tracks
## (sto_cs_rear.gd). The modern Stockholm Waterfront / new concourse is a
## separate building and is not modelled here.
## Sources: visual-plan/refs/landmarks/stockholm_central_station (front,
## quarter, side) and the OSM outline of way 35473137 (docs/
## stockholm-landmark-sources.md). The 33 m model top is the flagpole; the
## highest roof is the 24.3 m crown over the central hall.

const P = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_plan.gd")
const Front = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_front.gd")
const Roofs = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_roofs.gd")
const Rear = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_rear.gd")

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.materials(lm)
	Rear.build(lm)
	Front.build(lm)
	Roofs.build(lm)
	lm.commit(model)
