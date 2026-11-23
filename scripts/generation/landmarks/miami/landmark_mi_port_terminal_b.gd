class_name LandmarkMiPortTerminalB
extends RefCounted

## Norwegian Cruise Line Terminal B "Pearl of Miami" - PortMiami (MI-2C).
## Site: 25.777700, -80.165600, yaw_deg -64.0, footprint 158 x 58 m, height 30.0 m.
## Architects: Bermello Ajamil & Partners.
##   - Four pearl-white nautilus shells (lathe domes with meridian ribs) stepping down
##     in a spiral from 30.0 m to 9 m along the hall, over a concrete podium.
##   - Sweeping blue-glass concourse curve on the water side and a grand drop-off canopy.
##   - Warm pearl-blue uplighting (PearlLamp base rings + floods).

const HEIGHT_M := 30.0
const BASE_Y := 0.5
## [cx, cz, rx, rz, top_y, rot]
const SHELLS := [
	[-30.0, 0.0, 34.0, 25.0, 30.0, 0.0],
	[14.0, -4.0, 28.0, 22.0, 22.0, 0.5],
	[48.0, 2.0, 22.0, 19.0, 15.0, 1.0],
	[68.0, 6.0, 14.0, 13.0, 9.0, 1.5],
]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CBC9C3", 5.0))
	lm.use("Pearl", LandmarkMaterials.pbr("render", "#F6F3EE", 6.0))
	lm.use("Rib", LandmarkMaterials.paint("#E4E8EC", 0.30, 0.55))
	lm.use("BlueGlass", LandmarkMaterials.glass("#2A6C9A"))
	lm.use("Canopy", LandmarkMaterials.paint("#F2F4F6", 0.35, 0.35))
	lm.use("PearlLamp", LandmarkMaterials.lit("#8EC8FF", 1.6))

	lm.box("Podium", Vector3(0.0, 0.15, 0.0), Vector3(158.0, 0.7, 58.0))
	for s: int in SHELLS.size():
		var sh: Array = SHELLS[s]
		var cx: float = sh[0]
		var cz: float = sh[1]
		var rx: float = sh[2]
		var rz: float = sh[3]
		var top: float = sh[4]
		var rot: float = sh[5]
		var h := top - BASE_Y
		var prof := PackedVector2Array()
		for i: int in 8:
			var a := float(i) / 8.0 * PI * 0.5
			prof.append(Vector2(cos(a), sin(a) * h))
		prof.append(Vector2(0.0, h))
		lm.lathe("Pearl", Vector3(cx, BASE_Y, cz), prof, 24, rx, rz, rot, true)
		lm.frustum("PearlLamp", Vector3(cx, BASE_Y, cz), 1.01, 1.01, 0.45, 24, rot, rx, rz)
		if s < 3:
			for r: int in 12:
				var th := rot + TAU * float(r) / 12.0 + float(s) * 0.2
				var prev := Vector3.ZERO
				for i: int in 9:
					var a := float(i) / 8.0 * PI * 0.5
					var k := 1.02
					var p := Vector3(cx + cos(a) * cos(th) * rx * k, BASE_Y + sin(a) * h * k,
						cz + cos(a) * sin(th) * rz * k)
					if i == 8:
						p = Vector3(cx, top, cz)
					if i > 0:
						lm.beam("Rib", prev, p, 0.35, 0.35)
					prev = p
	# Sweeping blue-glass concourse curve on the water side
	var bottom := PackedVector3Array()
	var upper := PackedVector3Array()
	for i: int in 17:
		var t := float(i) / 16.0
		bottom.append(Vector3(-70.0 + 140.0 * t, 0.5, 24.0 + 5.0 * sin(PI * t)))
		upper.append(Vector3(-70.0 + 140.0 * t, 11.0 + 3.0 * sin(PI * t), 19.0 + 3.0 * sin(PI * t)))
	var rows: Array = [bottom, upper]
	lm.grid("BlueGlass", rows, Vector3(0.0, 5.0, -50.0), true)
	for i: int in 17:
		if i % 2 == 0:
			lm.beam("Rib", bottom[i], upper[i], 0.35, 0.35)
	# Grand drop-off canopy
	lm.box("Canopy", Vector3(50.0, 7.6, 25.0), Vector3(46.0, 0.7, 7.0), Basis(), 0.1)
	for cx: float in [30.0, 50.0, 70.0]:
		lm.beam("Rib", Vector3(cx, 0.5, 27.5), Vector3(cx, 7.3, 27.5), 0.8, 0.8)
	lm.commit(model)

	var pearl := Color(0.62, 0.80, 1.0)
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-50.0, 3.0, 45.0), Vector3(-30.0, 20.0, 0.0), 80.0, 1.3, 70.0, pearl],
		[Vector3(10.0, 3.0, 45.0), Vector3(14.0, 14.0, -4.0), 70.0, 1.1, 70.0, pearl],
		[Vector3(50.0, 3.0, 40.0), Vector3(50.0, 7.0, 25.0), 40.0, 1.0, 80.0, warm],
	])
