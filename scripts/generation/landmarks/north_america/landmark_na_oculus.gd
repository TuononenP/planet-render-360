class_name LandmarkNaOculus
extends RefCounted

## World Trade Center Transportation Hub, in true metres. The above-ground
## hall is about 107 m long, 35 m wide, and 29 m high. Its glass shell and
## white structural ribs follow the elliptical footprint; the ribs extend
## beyond the shell as the distinctive upturned wings.
## Dimensions: https://www.archdaily.com/783965/
const HALF_LENGTH := 53.5
const HALF_WIDTH := 17.5
const HEIGHT := 29.3
const RIBS := 40
const SECTIONS := 10

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#A8BCC3"))
	lm.use("Panels", LandmarkMaterials.paint("#DADDDC", 0.78, 0.0))
	lm.use("Ribs", LandmarkMaterials.paint("#E5E7E4", 0.5, 0.0))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#BFC0BA", 4.0))
	# Fine tessellation preserves the curved glazing between ribs.
	for i in RIBS:
		var x0 := -HALF_LENGTH + 2.0 * HALF_LENGTH * i / RIBS
		var x1 := -HALF_LENGTH + 2.0 * HALF_LENGTH * (i + 1) / RIBS
		for j in SECTIONS:
			var t0 := -1.0 + 2.0 * j / SECTIONS
			var t1 := -1.0 + 2.0 * (j + 1) / SECTIONS
			var surface := "Glass" if absf((t0 + t1) * 0.5) < 0.11 else "Panels"
			lm.quad(surface, _shell(x0, t0), _shell(x1, t0), _shell(x1, t1), _shell(x0, t1),
				Vector3(0, 1, (t0 + t1) * 0.5).normalized())
		for side in [-1.0, 1.0]:
			var a := _shell(x0, side)
			var b := _shell(x1, side)
			lm.quad("Panels", Vector3(a.x, 1.0, a.z), Vector3(b.x, 1.0, b.z), b, a,
				Vector3(0, 0, side))
	# The main ridge and each pair of projecting white ribs.
	for i in RIBS:
		var x0 := -HALF_LENGTH + 2.0 * HALF_LENGTH * i / RIBS
		var x1 := -HALF_LENGTH + 2.0 * HALF_LENGTH * (i + 1) / RIBS
		lm.beam("Ribs", _shell(x0, 0.0), _shell(x1, 0.0), 0.9, 0.9)
	for i in range(1, RIBS):
		var x := -HALF_LENGTH + 2.0 * HALF_LENGTH * i / RIBS
		for side in [-1.0, 1.0]:
			for j in SECTIONS / 2:
				var a := _shell(x, side * float(j) / (SECTIONS / 2))
				var b := _shell(x, side * float(j + 1) / (SECTIONS / 2))
				lm.beam("Ribs", a, b, 0.72, 0.72)
			var edge := _shell(x, side)
			var f := _ellipse(x)
			var tip := edge + Vector3(0, 0.3 * f, side * 6.0 * f)
			lm.beam("Ribs", edge, tip, 0.8, 0.8)
	lm.commit(model)

static func _ellipse(x: float) -> float:
	return sqrt(maxf(0.0, 1.0 - pow(x / HALF_LENGTH, 2.0)))

static func _shell(x: float, t: float) -> Vector3:
	var f := _ellipse(x)
	# The skylight sits between wings that rise outwards.
	var rise := lerpf(12.0, HEIGHT - 1.3, pow(absf(t), 1.2))
	return Vector3(x, 1.0 + rise * f,
		HALF_WIDTH * f * t)
