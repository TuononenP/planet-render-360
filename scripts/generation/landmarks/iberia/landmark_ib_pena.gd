class_name LandmarkIbPena
extends RefCounted

## The Pena Palace on its Sintra crag in true metres, the long axis along
## Z with the New Palace to the north (-Z); the registry yaw_deg turns it
## onto the real bearing.

const PENA_TOP := 36.0

## Ferdinand II's Romantic palace (1842-1854, Eschwege) on the hilltop
## above Sintra, origin at the middle of the 120 m ridge: the yellow New
## Palace with its great cylindrical bastion under the Moorish dome, the
## domed square tower whose corners carry round sentry boxes with
## conical caps, and the Triton portico (a coral-ribbed arch under the
## bow window with the Triton); the Arches Yard wall of horseshoe arches
## before the Manueline chapel; the old Hieronymite convent with its
## battlements and the red Clock Tower (1843, 36 m, the one tower
## without a dome); the Queen's terrace; the gate with its twin round
## towers. Every wall is crowned with Moorish stepped merlons. The rock
## itself is the terrain: the terrace walls stand on it from y = 0.
static func pena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Yellow", LandmarkMaterials.pbr("render", "#E3B136", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#B93A32", 3.0))
	lm.use("Purple", LandmarkMaterials.pbr("render", "#A27294", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE7D5", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A6503A", 2.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7E6F5C", 5.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3329", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass())
	# Terrace walls round the ridge with their merlons.
	LandmarkIbUtil.ring_walls(lm, "Rock", Vector3(0, 0, 2.0), 31.0, 64.0, 2.0, 0.0, 2.0)
	for s in [-1.0, 1.0]:
		LandmarkIbParts.stepped_merlons(lm, "Rock", Vector3(s * 31.0 - s, 2.0, -61.0), Vector3(s * 31.0 - s, 2.0, 65.0), 1.1, 1.4, 1.2)
	lm.box("Rock", Vector3(0, 0.3, 2.0), Vector3(60.0, 0.6, 126.0))
	_new_palace(lm)
	_arches_yard(lm)
	_convent(lm)
	_gate(lm)
	lm.commit(model)

## The yellow New Palace, the domed square tower, the round bastion and
## the Triton portico.
static func _new_palace(lm: LandmarkMesh) -> void:
	var pc := Vector3(-6.0, 0, -40.0)
	lm.box("Yellow", pc + Vector3(0, 10.0, 0), Vector3(32.0, 20.0, 32.0))
	LandmarkCeParts.hip(lm, "Tile", pc + Vector3(0, 20.0, 0), 31.0, 31.0, 4.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := pc + out * 16.0
		LandmarkIbParts.stepped_merlons(lm, "Trim", f - right * 16.0 + Vector3(0, 20.0, 0) - out * 0.4,
			f + right * 16.0 + Vector3(0, 20.0, 0) - out * 0.4, 1.0, 1.5, 0.8)
		LandmarkIbParts.band(lm, "Trim", f, right, out, 32.4, 19.4, 0.8, 0.5)
		LandmarkIbParts.band(lm, "Trim", f, right, out, 32.4, 10.2, 0.4, 0.3)
		for i in 4:
			var s := (float(i) - 1.5) * 7.0
			if k == 0 and absf(s) < 4.0:
				continue
			LandmarkIbParts.portal(lm, "Trim", "Glass", f + right * s + Vector3(0, 4.0, 0), right, out, 1.8, 4.0, 2, 0.3)
			LandmarkIbParts.portal(lm, "Trim", "Glass", f + right * s + Vector3(0, 12.4, 0), right, out, 1.8, 4.0, 2, 0.3)
		_sentry(lm, pc + (out + right) * 16.0 + Vector3(0, 17.0, 0), 1.1, "Yellow")
	_triton(lm, pc + Vector3(0, 0, 16.0))
	# Square tower with its sentry boxes and dome.
	var tc := Vector3(-20.0, 0, -52.0)
	lm.box("Yellow", tc + Vector3(0, 15.0, 0), Vector3(9.0, 30.0, 9.0))
	lm.box("Trim", tc + Vector3(0, 29.0, 0), Vector3(10.2, 0.8, 10.2))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkIbParts.stepped_merlons(lm, "Trim", tc + out * 4.8 - right * 4.0 + Vector3(0, 29.4, 0),
			tc + out * 4.8 + right * 4.0 + Vector3(0, 29.4, 0), 0.8, 1.3, 0.6)
		LandmarkIbParts.portal(lm, "Trim", "Glass", tc + out * 4.5 + Vector3(0, 22.0, 0), right, out, 1.6, 3.6, 2, 0.3)
		_sentry(lm, tc + (out + right) * 4.8 + Vector3(0, 26.5, 0), 0.9, "Yellow")
	lm.frustum("Yellow", tc + Vector3(0, 29.4, 0), 3.0, 3.0, 1.6, 12)
	lm.lathe("Tile", tc + Vector3(0, 31.0, 0), SEuUtil.dome(3.1, 2.8, 6), 12)
	LandmarkCeParts.cross(lm, "Gilt", tc + Vector3(0, 33.8, 0), 1.4)
	# The round bastion: windows, corbelled gallery, merlons, Moorish dome.
	var bc := Vector3(14.0, 0, -36.0)
	lm.frustum("Yellow", bc, 8.6, 8.0, 24.0, 24)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var rt := Vector3.UP.cross(d)
		LandmarkIbParts.portal(lm, "Trim", "Glass", bc + d * 8.15 + Vector3(0, 12.0, 0), rt, d, 1.6, 3.8, 2, 0.3)
		LandmarkIbParts.portal(lm, "Trim", "Glass", bc + d * 8.4 + Vector3(0, 4.0, 0), rt, d, 1.6, 3.6, 2, 0.3)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", bc + d * 7.9 + Vector3(0, 21.6, 0), bc + d * 8.8 + Vector3(0, 23.0, 0), 0.5, 0.4, d.cross(Vector3.UP))
		var p := bc + d * 8.7 + Vector3(0, 24.4, 0)
		lm.box("Trim", p + Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.5), Basis.looking_at(d), 0.0)
		lm.spire("Trim", p + Vector3(0, 0.9, 0), 0.22, 0.5)
	lm.frustum("Trim", bc + Vector3(0, 23.6, 0), 9.0, 9.0, 0.8, 24)
	lm.frustum("Yellow", bc + Vector3(0, 24.0, 0), 6.0, 6.0, 1.0, 16)
	LandmarkCeParts.onion(lm, "Gilt", bc + Vector3(0, 25.0, 0), 6.6, 8.6, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gilt", bc + d * 3.7 + Vector3(0, 25.0, 0), bc + d * 6.6 + Vector3(0, 27.1, 0), 0.25, 0.2)
	lm.frustum("Gilt", bc + Vector3(0, 33.6, 0), 0.2, 0.1, 1.6, 6)
	lm.lathe("Gilt", bc + Vector3(0, 35.0, 0), SEuUtil.dome(0.3, 0.4, 3), 8)

## The Triton portico on the New Palace's south front (wall foot at f):
## a coral-ribbed arch between two turrets, the Triton figure bearing
## the bow window above.
static func _triton(lm: LandmarkMesh, f: Vector3) -> void:
	var zn := Vector3(0, 0, 1)
	lm.box("Yellow", f + Vector3(0, 6.0, 1.0), Vector3(9.0, 12.0, 2.0))
	LandmarkIbParts.portal(lm, "Trim", "Shadow", f + Vector3(0, 0, 2.0), Vector3.RIGHT, zn, 4.4, 7.2, 1, 0.8)
	for i in 9:
		var a := PI * float(i) / 8.0
		var d := Vector3(cos(a), sin(a), 0)
		lm.beam("Trim", f + Vector3(0, 5.0, 2.8) + d * 2.9, f + Vector3(0, 5.0, 3.4) + d * 3.6, 0.35, 0.35)
	lm.box("Trim", f + Vector3(0, 9.2, 2.6), Vector3(5.0, 1.2, 1.4))
	LandmarkKits.statue_figure(lm, "Trim", f + Vector3(0, 7.4, 3.0), 1.9, true)
	lm.box("Yellow", f + Vector3(0, 11.6, 3.0), Vector3(4.4, 3.6, 2.2))
	LandmarkDetail.window(lm, "Trim", "Glass", f + Vector3(0, 11.6, 4.1), zn, 2.4, 2.6, true)
	for s in [-1.0, 1.0]:
		var tp := f + Vector3(float(s) * 4.8, 0, 2.0)
		lm.frustum("Yellow", tp, 1.6, 1.5, 14.0, 12)
		lm.frustum("Trim", tp + Vector3(0, 14.0, 0), 1.8, 1.8, 0.4, 12)
		lm.lathe("Tile", tp + Vector3(0, 14.4, 0), SEuUtil.dome(1.6, 1.8, 5), 12)

## Round sentry box (guarita) at a wall corner: corbel cone, shaft with
## slits, a conical cap.
static func _sentry(lm: LandmarkMesh, base: Vector3, r: float, wall: String) -> void:
	lm.lathe(wall, base - Vector3(0, r * 1.6, 0), PackedVector2Array([Vector2(r * 0.1, 0),
		Vector2(r * 0.6, r * 0.7), Vector2(r * 1.0, r * 1.6)]), 10)
	lm.frustum(wall, base, r, r, r * 2.4, 10)
	lm.frustum("Trim", base + Vector3(0, r * 2.4, 0), r * 1.12, r * 1.12, r * 0.25, 10)
	lm.frustum("Tile", base + Vector3(0, r * 2.65, 0), r * 1.15, 0.05, r * 1.8, 10)

## The Arches Yard wall of horseshoe arches and the Manueline chapel.
static func _arches_yard(lm: LandmarkMesh) -> void:
	lm.box("Yellow", Vector3(-6.0, 7.0, -12.0), Vector3(40.0, 14.0, 2.4))
	LandmarkIbParts.stepped_merlons(lm, "Trim", Vector3(-26, 14.0, -12), Vector3(14, 14.0, -12), 1.0, 1.5, 1.2)
	for s in [-1.0, 1.0]:
		var out := Vector3(0, 0, s)
		var right := Vector3.UP.cross(out)
		for i in 7:
			var hx := -6.0 + (float(i) - 3.0) * 5.4
			LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(hx, 0.6, -12.0 + s * 1.2), right, out, 2.8, 8.0, 2, 0.4)
			LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(hx, 9.6, -12.0 + s * 1.2), right, out, 1.4, 2.8, 2, 0.25)
	var cc := Vector3(22.0, 0, -6.0)
	lm.box("Trim", cc + Vector3(0, 6.0, 0), Vector3(14.0, 12.0, 22.0))
	lm.gable("Tile", cc + Vector3(0, 12.0, 0), 14.0, 22.0, 4.0, Basis(), 0.6)
	var xn := Vector3(-1, 0, 0)
	LandmarkIbParts.portal(lm, "Trim", "Shadow", cc + Vector3(-7.0, 0.6, 0), Vector3(0, 0, 1), xn, 3.0, 6.0, 3, 0.6)
	for z in [-7.5, 7.5]:
		LandmarkDetail.window(lm, "Trim", "Glass", cc + Vector3(-7.0, 7.0, z), xn, 1.6, 4.2, true)
		LandmarkDetail.window(lm, "Trim", "Glass", cc + Vector3(7.0, 7.0, z), -xn, 1.6, 4.2, true)
	for z in [-11.0, -3.7, 3.7, 11.0]:
		for sx in [-1.0, 1.0]:
			LandmarkIbParts.buttress(lm, "Trim", cc + Vector3(float(sx) * 7.0, 0, z), Vector3(sx, 0, 0), 0.9, 1.0, 11.0)
			LandmarkCeParts.pinnacle(lm, "Trim", cc + Vector3(float(sx) * 7.3, 12.0, z), 0.6, 2.6)
	# Bell turret at the chapel's west end.
	var bt := cc + Vector3(0, 0, 11.0)
	lm.box("Trim", bt + Vector3(0, 14.0, 0), Vector3(3.0, 4.0, 3.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		LandmarkIbParts.portal(lm, "Trim", "Shadow", bt + out * 1.5 + Vector3(0, 13.0, 0), r * Vector3(1, 0, 0), out, 1.2, 2.4, 1, 0.2)
	lm.lathe("Tile", bt + Vector3(0, 16.0, 0), SEuUtil.dome(1.8, 2.0, 5), 12)

## The old convent: battlemented block with its windows and sentry
## boxes, the Queen's terrace and the red Clock Tower.
static func _convent(lm: LandmarkMesh) -> void:
	var c := Vector3(4.0, 0, 30.0)
	lm.box("Purple", c + Vector3(0, 8.0, 0), Vector3(40.0, 16.0, 38.0))
	LandmarkCeParts.hip(lm, "Tile", c + Vector3(0, 16.0, 0), 39.0, 37.0, 4.2)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var half := 19.0 if k % 2 == 0 else 20.0
		var length := 40.0 if k % 2 == 0 else 38.0
		var f := c + out * half
		LandmarkIbParts.stepped_merlons(lm, "Trim", f - right * (length * 0.5) + Vector3(0, 16.0, 0) - out * 0.4,
			f + right * (length * 0.5) + Vector3(0, 16.0, 0) - out * 0.4, 1.0, 1.4, 0.8)
		LandmarkIbParts.band(lm, "Trim", f, right, out, length + 0.4, 15.6, 0.6, 0.4)
		for i in 5:
			var s := (float(i) - 2.0) * 7.0
			LandmarkIbParts.portal(lm, "Trim", "Glass", f + right * s + Vector3(0, 2.6, 0), right, out, 1.6, 3.6, 1, 0.3)
			LandmarkDetail.window(lm, "Trim", "Glass", f + right * s + Vector3(0, 11.0, 0), out, 1.6, 3.4, true)
		_sentry(lm, c + out * half + right * (length * 0.5) + Vector3(0, 13.4, 0), 1.0, "Purple")
	# Queen's terrace: the walled platform south of the convent.
	lm.box("Rock", Vector3(2.0, 1.0, 58.0), Vector3(54.0, 2.0, 10.0))
	lm.box("Trim", Vector3(2.0, 2.3, 58.0), Vector3(54.0, 0.6, 10.0))
	LandmarkIbParts.stepped_merlons(lm, "Trim", Vector3(-25.0, 2.6, 63.0), Vector3(29.0, 2.6, 63.0), 1.0, 1.3, 0.8)
	lm.box("Shadow", Vector3(20.0, 3.1, 60.0), Vector3(0.6, 0.4, 2.0))
	# Clock Tower: red shaft, clock, belfry, battlements and spire.
	var ct := Vector3(-14.0, 0, 52.0)
	lm.box("Red", ct + Vector3(0, 13.5, 0), Vector3(8.4, 27.0, 8.4))
	lm.box("Trim", ct + Vector3(0, 27.4, 0), Vector3(10.4, 0.8, 10.4))
	lm.box("Red", ct + Vector3(0, 29.0, 0), Vector3(8.8, 2.4, 8.8))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkIbParts.stepped_merlons(lm, "Trim", ct + out * 5.0 - right * 5.0 + Vector3(0, 30.2, 0),
			ct + out * 5.0 + right * 5.0 + Vector3(0, 30.2, 0), 0.9, 1.3, 0.6)
		LandmarkIbParts.portal(lm, "Trim", "Shadow", ct + out * 4.2 + Vector3(0, 22.6, 0), right, out, 2.0, 4.0, 1, 0.3)
		lm.disc("Trim", ct + out * 4.25 + Vector3(0, 19.0, 0), out, 1.5, 20)
		lm.disc("Shadow", ct + out * 4.28 + Vector3(0, 19.0, 0), out, 0.25, 8)
		for i in 3:
			LandmarkIbParts.portal(lm, "Trim", "Glass", ct + out * 4.2 + Vector3(0, 4.0 + 5.0 * float(i), 0), right, out,
				1.0, 2.4, 1, 0.2)
		for i in 13:
			lm.box("Trim", ct + out * 4.25 + right * 4.0 + Vector3(0, 1.0 + 2.0 * float(i), 0), Vector3(0.9, 1.0, 0.12), r, 0.0)
	lm.spire("Red", ct + Vector3(0, 30.4, 0), 2.6, PENA_TOP - 30.4 - 0.8, 0.0, 8)
	lm.lathe("Gilt", ct + Vector3(0, PENA_TOP - 1.0, 0), SEuUtil.dome(0.3, 0.4, 3), 8)
	lm.box("Gilt", ct + Vector3(0, PENA_TOP - 0.3, 0), Vector3(0.1, 0.6, 0.1), Basis(), 0.0)

## The gate with its twin round towers, battlements and the arch.
static func _gate(lm: LandmarkMesh) -> void:
	for x in [8.0, 18.0]:
		var tp := Vector3(x, 0, 66.0)
		lm.frustum("Red", tp, 3.3, 3.0, 15.0, 16)
		for i in 4:
			var a := TAU * float(i) / 4.0 + 0.4
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkIbParts.portal(lm, "Trim", "Shadow", tp + d * 3.1 + Vector3(0, 9.0, 0), Vector3.UP.cross(d), d, 0.7, 1.8, 1, 0.2)
		for i in 12:
			var a := TAU * float(i) / 12.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Trim", tp + d * 2.9 + Vector3(0, 14.0, 0), tp + d * 3.6 + Vector3(0, 15.0, 0), 0.4, 0.3, d.cross(Vector3.UP))
		lm.frustum("Yellow", tp + Vector3(0, 15.0, 0), 3.7, 3.7, 1.2, 16)
		lm.frustum("Tile", tp + Vector3(0, 16.2, 0), 3.9, 0.3, 4.6, 16)
	lm.box("Yellow", Vector3(13.0, 5.5, 66.0), Vector3(7.0, 11.0, 5.0))
	LandmarkIbParts.stepped_merlons(lm, "Trim", Vector3(9.8, 11.0, 68.2), Vector3(16.2, 11.0, 68.2), 0.9, 1.3, 0.6)
	LandmarkIbParts.portal(lm, "Trim", "Shadow", Vector3(13.0, 0.6, 68.5), Vector3.RIGHT, Vector3(0, 0, 1), 4.0, 7.5, 2, 0.5, true)
