class_name ShipMooring
extends RefCounted

## Mooring dressing for a ship alongside a quay, written into the ship's
## own LandmarkMesh (metres, +X bow, waterline y = 0) so it shares the
## ship's transform. `berth` comes from QuayMoorings.berth_info: the quay
## edge at local z = quay_z, its top quay_top above the water, the quay
## run's ends `along` in ship x, and an optional ballast `lift` (the ship
## rides that much higher, so the water and quay sit lower in its frame).
## - head, breast, spring and stern lines, two ropes per station, from
##   fairleads under the sheer to mushroom bitts on the quay;
## - floating rubber fenders between the hull and the quay;
## - a railed gangway from a shell door (passenger ships) or an
##   accommodation ladder from the main deck aft (cargo ships).
## Lines sag but never touch the water.
const STATIONS := [[0.46, 0.12], [0.37, 0.0], [0.3, -0.16], [-0.3, 0.16], [-0.37, 0.0], [-0.46, -0.12]]
const BITT_INSET_M := 1.5

static func register(lm: LandmarkMesh, maps: bool) -> void:
	lm.use("Rope", VesselMaterials.paint("#3d4652", maps, 0.9, 0.0))
	lm.use("Bitt", VesselMaterials.paint("#1d1f21", maps, 0.6, 0.3))
	lm.use("Fender", VesselMaterials.paint("#141516", maps, 0.95, 0.0))

## Adds the mooring to `lm` for a ship of hull `spec`; `passenger` picks
## the shell-door gangway over the accommodation ladder.
static func add(lm: LandmarkMesh, spec: Dictionary, berth: Dictionary, passenger: bool, maps: bool = true) -> void:
	if berth.is_empty():
		return
	register(lm, maps)
	var length: float = spec["length"]
	var lift := float(berth.get("lift", 0.0))
	var water := -lift
	var quay_z: float = berth["quay_z"]
	var s := signf(quay_z)
	var top: float = float(berth["quay_top"]) - lift
	var along: Vector2 = berth.get("along", Vector2(-length, length))
	for st in STATIONS:
		var x := length * float(st[0])
		var bx := clampf(x + length * float(st[1]), along.x + 2.0, along.y - 2.0)
		var bitt := Vector3(bx, top, quay_z + s * BITT_INSET_M)
		_bitt(lm, bitt)
		for k in 2:
			var fx := x + (float(k) - 0.5) * 0.8
			var fy := HullLoft.sheer(spec, fx) - 0.9
			var fair := Vector3(fx, fy, s * (HullLoft.side_z(spec, fx, fy) + 0.05))
			line(lm, fair, bitt + Vector3(0, 0.55 + 0.1 * float(k), 0), water + 0.3)
	for fx in [-0.3, -0.1, 0.1, 0.3]:
		var x := length * float(fx)
		var z := quay_z - s * 1.0
		HullLoft.tube(lm, "Fender", [Vector3(x - 1.75, water + 0.6, z), Vector3(x + 1.75, water + 0.6, z)], 0.95, 12, true)
		HullLoft.tube(lm, "Rope", [Vector3(x, water + 1.5, z), Vector3(x, top + 0.2, quay_z + s * 0.3)], 0.04, 4)
	var gx := clampf(-length * 0.12 if passenger else -length * 0.3, along.x + 6.0, along.y - 6.0)
	var gy := float(spec["freeboard"]) * 0.3 if passenger else HullLoft.sheer(spec, gx)
	var from := Vector3(gx, gy, s * (HullLoft.side_z(spec, gx, gy) + 0.1))
	gangway(lm, from, Vector3(gx - 7.0, top + 0.05, quay_z + s * 3.0))

## A sagging rope from `a` to `b`, its lowest point kept above `floor_y`.
static func line(lm: LandmarkMesh, a: Vector3, b: Vector3, floor_y: float) -> void:
	var sag := minf(a.distance_to(b) * 0.04, minf(a.y, b.y) - floor_y)
	var path: Array = []
	for i in 9:
		var t := float(i) / 8.0
		path.append(a.lerp(b, t) - Vector3.UP * sin(PI * t) * maxf(sag, 0.0))
	HullLoft.tube(lm, "Rope", path, 0.045, 5)

## A double-headed mooring bitt on the quay top at `at`.
static func _bitt(lm: LandmarkMesh, at: Vector3) -> void:
	lm.box("Bitt", at + Vector3(0, 0.08, 0), Vector3(1.4, 0.16, 0.7), Basis(), 0.03)
	for dx in [-0.4, 0.4]:
		lm.lathe("Bitt", at + Vector3(float(dx), 0.16, 0), PackedVector2Array([Vector2(0.22, 0), Vector2(0.2, 0.55),
			Vector2(0.32, 0.62), Vector2(0.32, 0.72), Vector2(0.01, 0.74)]), 10)

## A railed gangway (floor, side rails, stanchions) from `a` down to `b`.
static func gangway(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var side := d.cross(Vector3.UP).normalized() * 0.55
	lm.beam("Steel", a, b, 1.1, 0.15)
	var n := maxi(int(d.length() / 1.5), 2)
	for s in [-1.0, 1.0]:
		var rail: Array = []
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n)) + side * float(s)
			HullLoft.tube(lm, "White", [p, p + Vector3(0, 1.0, 0)], 0.025, 4)
			rail.append(p + Vector3(0, 1.0, 0))
		HullLoft.tube(lm, "White", rail, 0.03, 6)
