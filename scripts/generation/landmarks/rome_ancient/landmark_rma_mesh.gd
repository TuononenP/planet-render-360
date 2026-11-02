class_name RmAMesh
extends LandmarkMesh

## LandmarkMesh with a placement transform for the ancient Rome models:
## every triangle emitted after place() is moved and turned by `xf`, so
## one model (the Roman Forum, the Baths of Caracalla) can hold many
## monuments, each built in its own frame (front toward +Z) and set down
## at its true spot and compass bearing.

var xf := Transform3D.IDENTITY

## Frame of the next primitives: origin at (x, y, z) metres, local +Z
## (the front) facing compass bearing `facing_deg` (0 north, 90 east).
func place(x: float, z: float, facing_deg: float = 180.0, y: float = 0.0) -> void:
	xf = Transform3D(Basis(Vector3.UP, deg_to_rad(180.0 - facing_deg)), Vector3(x, y, z))

## Back to the model frame.
func home() -> void:
	xf = Transform3D.IDENTITY

func tri(key: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3,
		nc: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	super.tri(key, xf * a, xf * b, xf * c, xf.basis * na, xf.basis * nb, xf.basis * nc,
		ua, ub, uc)
