class_name StoFotografiska
extends RefCounted

## Fotografiska, the Stora Tullhuset (Ferdinand Boberg, 1906-10) on
## Stadsgårdshamnen. Origin at the centre of OSM way 40153273 (129.2 x
## 18.2 m, bearing 100.5, registry yaw 10.5), +X east along the quay, the
## water and the quay front at -Z (north), the Södermalm cliff behind.
## National-Romantic red brick with granite and limestone dressings and
## black sheet roofs, three parts in a row (visual-plan/refs/landmarks/
## fotografiska/, the side view scaled by the 129 m length):
## - West block x -64.6..-30, 4 storeys, eaves 19.6 m: arched and square
##   windows in rows 4.4 m apart (large paired ground-floor openings),
##   a granite string course over the ground floor, a plain attic and a
##   projecting black eave under a low hipped black roof to 22.6 m.
## - The long hall x -30..41.5, two storeys to 11.7 m: ground floor with
##   tall square multi-pane windows 6 m apart, a row of small windows
##   above, a long black pent roof with a glazed clerestory band along
##   the whole ridge, ridge 16.4 m.
## - The east block x 41.5..64.6, eaves 12.1 m: three big round-arched
##   windows on each long side over the ground floor, a frieze of
##   recessed brick panels in limestone frames, a hipped black roof to
##   15.4 m; on it the 23.5 m square brick chimney with a stone cap and a
##   small brick stair turret with two stone pinnacles.
## - A black pent canopy 1.4 m deep runs along the whole quay front over
##   the ground floor at 4.2 m.
## Registry height is the chimney top (the west roof peaks at 22.6 m).

const X0 := -64.6
const X1 := 64.6
const XA := -30.0
const XB := 41.5
const HZ := 9.1
const TOP := 23.5

static func build(model: Node3D) -> void:
	var mats := StoChurchKit.materials("brick", "#A2603F", "#C3B292")
	mats["Roof"] = LandmarkMaterials.pbr("sheet_metal", "#2A2D32", 3.0, 0.45, 0.5)
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_west(lm, mats)
	_hall(lm, mats)
	_east(lm, mats)
	_canopy(lm)
	lm.commit(model)

## A row of `n` units along z = `z` from x0 to x1 facing `out`, base at y.
static func _row(lm: LandmarkMesh, unit: LandmarkMesh, x0: float, x1: float, z: float, out: Vector3,
		y: float, n: int) -> void:
	for i in n:
		var x := lerpf(x0, x1, (float(i) + 0.5) / float(n))
		StoChurchKit.place(lm, unit, Vector3(x, y, z), out)

static func _rect_unit(mats: Dictionary, w: float, h: float) -> LandmarkMesh:
	var u := LandmarkMesh.new()
	StoChurchKit.use_all(u, mats)
	LandmarkDetail.window(u, "Trim", "Glass", Vector3(0, h * 0.5, 0), Vector3.BACK, w, h, false, 0.25)
	return u

static func _band(lm: LandmarkMesh, x0: float, x1: float, y: float, h: float, key: String = "Trim", proj: float = 0.2) -> void:
	for z in [-HZ, HZ]:
		lm.box(key, Vector3((x0 + x1) * 0.5, y + h * 0.5, float(z) + (proj * 0.5 if z > 0.0 else -proj * 0.5)),
			Vector3(x1 - x0 + proj * 2.0, h, proj), Basis(), 0.0)

static func _west(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := (X0 + XA) * 0.5
	var eave := 19.6
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, 0.0, XA - X0, eave, HZ * 2.0)
	lm.box("Trim", Vector3(cx, 0.4, 0), Vector3(XA - X0 + 0.5, 0.8, HZ * 2.0 + 0.5), Basis(), 0.0)
	_band(lm, X0, XA, 4.3, 0.45)
	_band(lm, X0, XA, 18.0, 0.7, "Trim", 0.3)
	lm.box("Roof", Vector3(cx, eave + 0.15, 0), Vector3(XA - X0 + 1.4, 0.45, HZ * 2.0 + 1.4), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, eave + 0.35, 0), XA - X0 + 1.0, HZ * 2.0 + 1.0, 3.0, 0.5)
	var big := _rect_unit(mats, 1.9, 2.8)
	var sq := _rect_unit(mats, 1.3, 2.2)
	var arch := StoChurchKit.round_unit(mats, 1.3, 2.4)
	var arch2 := StoChurchKit.round_unit(mats, 1.1, 2.0, 0.25)
	for s in [-1.0, 1.0]:
		var z: float = s * HZ
		var out := Vector3(0, 0, s)
		_row(lm, big, X0 + 2.0, XA - 2.0, z, out, 0.8, 9)
		_row(lm, arch, X0 + 2.0, XA - 2.0, z, out, 5.4, 9)
		_row(lm, sq, X0 + 2.0, XA - 2.0, z, out, 9.8, 9)
		_row(lm, arch2, X0 + 2.0, XA - 2.0, z, out, 14.2, 9)
	for k in 3:
		var z := lerpf(-HZ + 2.5, HZ - 2.5, float(k) / 2.0)
		StoChurchKit.place(lm, big, Vector3(X0, 0.8, z), Vector3.LEFT)
		StoChurchKit.place(lm, arch, Vector3(X0, 5.4, z), Vector3.LEFT)
		StoChurchKit.place(lm, sq, Vector3(X0, 9.8, z), Vector3.LEFT)
		StoChurchKit.place(lm, arch2, Vector3(X0, 14.2, z), Vector3.LEFT)

static func _hall(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := (XA + XB) * 0.5
	var span := XB - XA
	var eave := 11.7
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, 0.0, span, eave, HZ * 2.0)
	lm.box("Trim", Vector3(cx, 0.4, 0), Vector3(span + 0.1, 0.8, HZ * 2.0 + 0.5), Basis(), 0.0)
	_band(lm, XA, XB, 4.5, 0.4)
	_band(lm, XA, XB, eave - 0.6, 0.6, "Trim", 0.25)
	# Pent roof skirts, glazed clerestory band and the upper black roof.
	for s in [-1.0, 1.0]:
		var sg: float = s
		var n := Vector3(0, 1.0, sg * 0.9).normalized()
		lm.quad("Roof", Vector3(XA, eave, sg * (HZ + 0.4)), Vector3(XB, eave, sg * (HZ + 0.4)),
			Vector3(XB, eave + 2.4, sg * 5.8), Vector3(XA, eave + 2.4, sg * 5.8), n)
	lm.box("Wall", Vector3(cx, eave + 2.4 + 0.9, 0), Vector3(span, 1.8, 11.6), Basis(), 0.0)
	LandmarkFhUtil.ridge_x(lm, "Roof", "Roof", Vector3(cx, eave + 4.2, 0), span, 11.6, 0.9, 0.2)
	var lite := _rect_unit(mats, 2.6, 1.2)
	var sq := _rect_unit(mats, 2.3, 2.4)
	var small := _rect_unit(mats, 1.4, 1.5)
	var n_bays := 12
	for s in [-1.0, 1.0]:
		var sg: float = s
		_row(lm, lite, XA + 3.0, XB - 3.0, sg * 5.95, Vector3(0, 0, sg), eave + 2.9, n_bays)
		_row(lm, sq, XA + 3.0, XB - 3.0, sg * HZ, Vector3(0, 0, sg), 1.2, n_bays)
		_row(lm, small, XA + 3.0, XB - 3.0, sg * HZ, Vector3(0, 0, sg), 6.4, n_bays)

static func _east(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := (XB + X1) * 0.5
	var w := X1 - XB
	var eave := 12.1
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, 0.0, w, eave, HZ * 2.0)
	lm.box("Trim", Vector3(cx, 0.4, 0), Vector3(w + 0.5, 0.8, HZ * 2.0 + 0.5), Basis(), 0.0)
	_band(lm, XB, X1, 4.6, 0.45)
	# Frieze of recessed brick panels in limestone frames under the cornice.
	_band(lm, XB, X1, 10.0, 0.4)
	_band(lm, XB, X1, eave - 0.7, 0.7, "Trim", 0.3)
	for s in [-1.0, 1.0]:
		var sg: float = s
		for i in 4:
			var x := lerpf(XB + 3.5, X1 - 3.5, float(i) / 3.0)
			lm.box("Trim", Vector3(x, 10.9, sg * (HZ + 0.1)), Vector3(4.2, 1.2, 0.18), Basis(), 0.0)
			lm.box("Wall", Vector3(x, 10.9, sg * (HZ + 0.2)), Vector3(3.6, 0.8, 0.12), Basis(), 0.0)
	lm.box("Roof", Vector3(cx, eave + 0.15, 0), Vector3(w + 1.8, 0.45, HZ * 2.0 + 1.8), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, eave + 0.35, 0), w + 1.2, HZ * 2.0 + 1.2, 3.2, 0.45)
	var lite := _rect_unit(mats, 2.0, 1.1)
	for s in [-1.0, 1.0]:
		var sg: float = s
		_row(lm, lite, XB + 3.0, X1 - 3.0, sg * (HZ * 0.42), Vector3(0, 0, sg), eave + 1.0, 4)
	var arch := StoChurchKit.round_unit(mats, 1.8, 4.4)
	var big := _rect_unit(mats, 2.4, 3.2)
	var low := _rect_unit(mats, 1.3, 1.8)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(0, 0, sg)
		_row(lm, arch, XB + 2.5, X1 - 2.5, sg * HZ, out, 5.8, 4)
		_row(lm, big, XB + 2.5, X1 - 2.5, sg * HZ, out, 1.0, 4)
	for z in [-3.5, 3.5]:
		StoChurchKit.place(lm, arch, Vector3(X1, 5.8, float(z)), Vector3.RIGHT)
		StoChurchKit.place(lm, low, Vector3(X1, 1.6, float(z)), Vector3.RIGHT)
	# Chimney (square, tapered, two limestone bands, capped) and the stair turret.
	var ch := Vector3(56.0, 0.0, -3.0)
	StoChurchKit.tapered_shaft(lm, "Wall", ch.x, ch.z, 0.0, TOP - 0.9, 1.4, 1.05)
	for y in [15.0, 20.5]:
		StoChurchKit.tower_band(lm, "Trim", ch.x, ch.z, 1.2, y, 0.4, 0.15)
	lm.box("Trim", Vector3(ch.x, TOP - 0.45, ch.z), Vector3(2.9, 0.9, 2.9), Basis(), 0.0)
	var st := Vector3(48.0, 0.0, -4.5)
	LandmarkFhUtil.blk(lm, "Wall", st.x, eave, st.z, 4.4, 5.6, 3.8)
	lm.box("Roof", Vector3(st.x, eave + 5.7, st.z), Vector3(5.2, 0.3, 4.6), Basis(), 0.0)
	for dz in [-1.8, 1.8]:
		lm.box("Trim", Vector3(st.x, eave + 6.3, st.z + float(dz)), Vector3(0.7, 1.2, 0.7), Basis(), 0.0)
		lm.lathe("Trim", Vector3(st.x, eave + 6.9, st.z + float(dz)), LandmarkFhUtil.ball(0.3), 8)

## The black pent canopy along the quay front above the ground floor.
static func _canopy(lm: LandmarkMesh) -> void:
	lm.quad("Roof", Vector3(X0, 4.2, -HZ - 1.5), Vector3(X1, 4.2, -HZ - 1.5), Vector3(X1, 5.0, -HZ - 0.05),
		Vector3(X0, 5.0, -HZ - 0.05), Vector3(0, 0.9, -0.4).normalized())
	lm.box("Roof", Vector3(0, 4.1, -HZ - 1.5), Vector3(X1 - X0, 0.25, 0.2), Basis(), 0.0)
	for i in 14:
		var x := lerpf(X0 + 4.0, X1 - 4.0, float(i) / 13.0)
		lm.box("Roof", Vector3(x, 2.0, -HZ - 1.4), Vector3(0.2, 4.0, 0.2), Basis(), 0.0)
