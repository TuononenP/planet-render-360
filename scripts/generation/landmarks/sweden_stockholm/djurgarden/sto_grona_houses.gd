class_name StoGronaHouses
extends RefCounted

## The old timber buildings of Gröna Lund for grona_lund_park: the red
## board-clad houses with white corner boards, white-framed windows and red
## tile roofs along Allmänna gränd and inside the park (photo houses.jpg of
## the Låga längan wall and the Tyrol / theatre street photo in
## visual-plan/refs/landmarks/grona_lund_park/), each standing on the OSM
## footprint it replaces (minimum-area rectangle of the mapped polygon,
## frame of StoGronaCoasters.ORIGIN):
## - 221564531, 15.9 x 14.9 m, 2 levels: red house with a hipped tile roof.
## - 221564541, 21.2 x 26.8 m, 2 levels, beside the Teatern Gröna Lund node:
##   the theatre block, white plastered ground floor with shop windows and a
##   red board upper floor under a low grey hipped roof (which OSM polygon
##   is the theatre is inferred from the node, unverified).
## - 182668066 Mjölnargården, 16.8 x 10.7 m, 2 levels, gabled.
## - 221564530 Järnvågshuset, 12.2 x 6.3 m, 1 level, gabled.

## [centre x, centre z (Eclipse OSM frame), long side, short side,
## rectangle angle deg, levels, kind]
const HOUSES := [
	[46.8, -159.1, 15.9, 14.9, 67.3, 2, "hip"],
	[22.9, -143.5, 21.2, 26.8, -21.2, 2, "theatre"],
	[35.7, -111.7, 16.8, 10.7, 69.2, 2, "gable"],
	[24.1, -126.5, 12.2, 6.3, -19.2, 1, "gable"],
]

static func add(lm: LandmarkMesh, mats: Dictionary) -> void:
	for raw in HOUSES:
		var h: Array = raw
		var u := LandmarkMesh.new()
		StoGronaPark.use_all(u, mats)
		_house(u, mats, float(h[2]), float(h[3]), int(h[5]), str(h[6]))
		var c := Vector2(float(h[0]), float(h[1])) - StoGronaCoasters.ORIGIN
		lm.merge(u, Transform3D(Basis(Vector3.UP, -deg_to_rad(float(h[4]))), Vector3(c.x, 0.0, c.y)))

static func _win(mats: Dictionary, w: float, h: float) -> LandmarkMesh:
	var u := LandmarkMesh.new()
	StoGronaPark.use_all(u, mats)
	LandmarkDetail.window(u, "Cream", "Glass", Vector3(0, h * 0.5, 0), Vector3.BACK, w, h, false, 0.2)
	return u

static func _house(lm: LandmarkMesh, mats: Dictionary, w: float, d: float, levels: int, kind: String) -> void:
	var eave := 3.3 * float(levels) + 0.5
	var theatre := kind == "theatre"
	lm.box("RoofGrey", Vector3(0, 0.25, 0), Vector3(w + 0.3, 0.5, d + 0.3), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Cream" if theatre else "RedWall", 0.0, 0.5, 0.0, w, eave - 0.5, d)
	if theatre:
		# Red board upper floor over the white ground floor.
		LandmarkFhUtil.blk(lm, "RedWall", 0.0, 4.2, 0.0, w + 0.08, eave - 4.2, d + 0.08)
		lm.box("Cream", Vector3(0, 4.2, 0), Vector3(w + 0.5, 0.3, d + 0.5), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Cream", Vector3(float(sx) * w * 0.5, eave * 0.5 + 0.25, float(sz) * d * 0.5),
				Vector3(0.28, eave - 0.5, 0.28), Basis(), 0.0)
	match kind:
		"hip":
			LandmarkFhUtil.hip(lm, "RoofRed", Vector3(0, eave, 0), w + 1.0, d + 1.0, 3.6, 0.1)
		"theatre":
			lm.box("RoofGrey", Vector3(0, eave + 0.15, 0), Vector3(w + 0.8, 0.3, d + 0.8), Basis(), 0.0)
			LandmarkFhUtil.hip(lm, "RoofGrey", Vector3(0, eave + 0.3, 0), w + 0.6, d + 0.6, 2.0, 0.55)
		_:
			LandmarkFhUtil.ridge_x(lm, "RoofRed", "RedWall", Vector3(0, eave, 0), w, d, 0.34 * d, 0.5)
	var small := _win(mats, 0.9, 1.4)
	var shop := _win(mats, 1.8, 1.8)
	var nl := maxi(int(w / 3.4), 1)
	var ns := maxi(int(d / 3.4), 1)
	for lv in levels:
		var y := 0.5 + 3.3 * float(lv) + 0.8
		var unit := shop if theatre and lv == 0 else small
		var yy := 0.9 if theatre and lv == 0 else y
		for sg in [-1.0, 1.0]:
			var s: float = sg
			for i in nl:
				var x := lerpf(-w * 0.5 + 1.4, w * 0.5 - 1.4, (float(i) + 0.5) / float(nl))
				StoChurchKit.place(lm, unit, Vector3(x, yy, s * d * 0.5), Vector3(0, 0, s))
			for k in ns:
				var z := lerpf(-d * 0.5 + 1.4, d * 0.5 - 1.4, (float(k) + 0.5) / float(ns))
				StoChurchKit.place(lm, small, Vector3(s * w * 0.5, y, z), Vector3(s, 0, 0))
