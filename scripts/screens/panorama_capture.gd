class_name PanoramaCapture
extends RefCounted

## The 360 view as one picture you can look around in: six 90° faces are
## rendered from the eye (each in its own viewport inside the view's 3D
## world, so the screen is not disturbed), and a small shader projects them
## to a 2:1 equirectangular image centred on the way you are facing. Saved
## as a JPEG with Google's GPano metadata, which photo viewers, Facebook
## and Google Photos read to show it as a panorama.
##
## The shader is given each face's own basis, so it makes no assumption
## about cube-map face order or handedness.

const FACE_PX_DESKTOP := 2048
const FACE_PX_MOBILE := 1024
const JPEG_QUALITY := 0.92
## Frames drawn before a face is read. See first_settle_frames.
const GI_SETTLE_FRAMES := 48
const BASIC_SETTLE_FRAMES := 6
## After the camera turns to the next face.
const TURN_SETTLE_FRAMES := 3
## The whole capture (six faces and the projection) gives up after this
## long, e.g. when the window is hidden or not drawing.
const CAPTURE_BUDGET_MS := 30000
## Faces are rendered wider than 90° so neighbours overlap, and the
## overlap is cross-faded: BLEND_IN to BLEND_OUT is the range of tan(angle)
## from a face's axis over which its weight falls from 1 to 0 (the 90°
## edge is at 1.0). View-dependent effects, such as water reflections,
## differ slightly between cameras; without the fade they show as a faint
## step at every face edge.
const BLEND_IN := 0.8
const BLEND_OUT := 1.2
## And this many pixels more, so the filter never samples past a face.
const EDGE_PAD_PX := 2.0

const SHADER := """
shader_type canvas_item;
uniform sampler2D face0 : filter_linear, repeat_disable;
uniform sampler2D face1 : filter_linear, repeat_disable;
uniform sampler2D face2 : filter_linear, repeat_disable;
uniform sampler2D face3 : filter_linear, repeat_disable;
uniform sampler2D face4 : filter_linear, repeat_disable;
uniform sampler2D face5 : filter_linear, repeat_disable;
uniform vec3 fwd[6];
uniform vec3 rgt[6];
uniform vec3 upv[6];
uniform vec3 f0;
uniform vec3 r0;
uniform float shrink = 1.0;
uniform float blend_in = 0.8;
uniform float blend_out = 1.2;

vec3 sample_face(int i, vec2 uv) {
	if (i == 0) { return textureLod(face0, uv, 0.0).rgb; }
	if (i == 1) { return textureLod(face1, uv, 0.0).rgb; }
	if (i == 2) { return textureLod(face2, uv, 0.0).rgb; }
	if (i == 3) { return textureLod(face3, uv, 0.0).rgb; }
	if (i == 4) { return textureLod(face4, uv, 0.0).rgb; }
	return textureLod(face5, uv, 0.0).rgb;
}

void fragment() {
	float h = (UV.x - 0.5) * TAU;
	float lat = (0.5 - UV.y) * PI;
	vec3 d = cos(lat) * (sin(h) * r0 + cos(h) * f0) + sin(lat) * vec3(0.0, 1.0, 0.0);
	vec3 sum = vec3(0.0);
	float weight = 0.0;
	for (int i = 0; i < 6; i++) {
		float t = dot(d, fwd[i]);
		if (t <= 0.0) { continue; }
		vec2 p = vec2(dot(d, rgt[i]), dot(d, upv[i])) / t;
		float w = 1.0 - smoothstep(blend_in, blend_out, max(abs(p.x), abs(p.y)));
		if (w <= 0.0) { continue; }
		vec2 uv = vec2(p.x * shrink * 0.5 + 0.5, 0.5 - p.y * shrink * 0.5);
		sum += w * sample_face(i, uv);
		weight += w;
	}
	COLOR = vec4(sum / weight, 1.0);
}
"""

static func face_px() -> int:
	return FACE_PX_MOBILE if OS.has_feature("mobile") else FACE_PX_DESKTOP

## The picture's width: four faces round the horizon.
static func width_for(face: int) -> int:
	return face * 4

## "planet-render-360_paris-france_360_20261101-1730.jpg"; `when` is a
## {year, month, day, hour, minute} dictionary.
static func file_name(place: String, when: Dictionary) -> String:
	var s := PhotoMode.slug(place)
	return "%s_%s%s_360_%04d%02d%02d-%02d%02d.jpg" % [PhotoMode.PREFIX, s, "" if s != "" else "view",
		int(when.get("year", 2026)), int(when.get("month", 1)), int(when.get("day", 1)),
		int(when.get("hour", 0)), int(when.get("minute", 0))]

# --- Geometry ---

## The horizontal direction of a camera's look (`forward`) and the
## direction to its right, both unit length. A look straight up or down
## falls back to world -Z.
static func horizontal_basis(forward: Vector3) -> Array[Vector3]:
	var f := Vector3(forward.x, 0.0, forward.z)
	f = Vector3(0.0, 0.0, -1.0) if f.length() < 1e-4 else f.normalized()
	return [f, f.cross(Vector3.UP).normalized()]

## The six faces as bases: [forward, right, up] each, orthonormal. Four
## round the horizon starting at `f0`, then straight up and straight down
## (their "up" is `f0`).
static func face_bases(f0: Vector3, r0: Vector3) -> Array:
	var out: Array = []
	for fwd in [f0, r0, -f0, -r0]:
		out.append([fwd, fwd.cross(Vector3.UP).normalized(), Vector3.UP])
	out.append([Vector3.UP, Vector3.UP.cross(f0).normalized(), f0])
	out.append([Vector3.DOWN, Vector3.DOWN.cross(f0).normalized(), f0])
	return out

## Half the face's width in tan units: out to BLEND_OUT, plus the pad.
static func reach_for(face: int) -> float:
	return BLEND_OUT + EDGE_PAD_PX / float(face)

static func fov_for(face: int) -> float:
	return rad_to_deg(2.0 * atan(reach_for(face)))

## Maps a tan-unit offset on the face to its [-0.5, 0.5] picture position.
static func shrink_for(face: int) -> float:
	return 1.0 / reach_for(face)

# --- Metadata and file ---

## Google's GPano XMP for a full-sphere equirectangular picture whose
## centre faces compass `heading_deg`.
static func xmp(width: int, height: int, heading_deg: float) -> String:
	return ('<?xpacket begin="﻿" id="W5M0MpCehiHzreSzNTczkc9d"?>'
		+ '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
		+ '<rdf:Description rdf:about="" xmlns:GPano="http://ns.google.com/photos/1.0/panorama/">'
		+ '<GPano:UsePanoramaViewer>True</GPano:UsePanoramaViewer>'
		+ '<GPano:ProjectionType>equirectangular</GPano:ProjectionType>'
		+ '<GPano:StitchingSoftware>Planet Render 360</GPano:StitchingSoftware>'
		+ '<GPano:PoseHeadingDegrees>%.1f</GPano:PoseHeadingDegrees>' % fposmod(heading_deg, 360.0)
		+ '<GPano:CroppedAreaImageWidthPixels>%d</GPano:CroppedAreaImageWidthPixels>' % width
		+ '<GPano:CroppedAreaImageHeightPixels>%d</GPano:CroppedAreaImageHeightPixels>' % height
		+ '<GPano:FullPanoWidthPixels>%d</GPano:FullPanoWidthPixels>' % width
		+ '<GPano:FullPanoHeightPixels>%d</GPano:FullPanoHeightPixels>' % height
		+ '<GPano:CroppedAreaLeftPixels>0</GPano:CroppedAreaLeftPixels>'
		+ '<GPano:CroppedAreaTopPixels>0</GPano:CroppedAreaTopPixels>'
		+ '</rdf:Description></rdf:RDF></x:xmpmeta><?xpacket end="w"?>')

const XMP_NAMESPACE := "http://ns.adobe.com/xap/1.0/"

## The APP1 header that marks an XMP packet: the namespace and a NUL byte.
## (A GDScript string cannot hold the NUL, so it is appended as a byte.)
static func xmp_header() -> PackedByteArray:
	var header := XMP_NAMESPACE.to_ascii_buffer()
	header.append(0)
	return header

## `jpeg` with an XMP packet inserted as an APP1 segment, after the JFIF
## header when there is one. Returns `jpeg` unchanged if it is not a JPEG
## or the packet would not fit a segment (64 KB).
static func with_xmp(jpeg: PackedByteArray, packet: String) -> PackedByteArray:
	if jpeg.size() < 4 or jpeg[0] != 0xFF or jpeg[1] != 0xD8:
		return jpeg
	var body := xmp_header()
	body.append_array(packet.to_utf8_buffer())
	var length := body.size() + 2
	if length > 0xFFFF:
		return jpeg
	var at := 2
	if jpeg[2] == 0xFF and jpeg[3] == 0xE0 and jpeg.size() >= 6:  # keep JFIF first
		at = 4 + (jpeg[4] << 8 | jpeg[5])
	var out := jpeg.slice(0, at)
	out.append(0xFF)
	out.append(0xE1)
	out.append(length >> 8)
	out.append(length & 0xFF)
	out.append_array(body)
	out.append_array(jpeg.slice(at))
	return out

# --- Rendering (needs a window) ---

## Renders the panorama from `cam`'s position, centred on its heading.
## `world` is the viewport that holds the scene (the new viewports become
## its children and share its 3D world). `stamp` is optional caption lines
## drawn at the bottom of the picture, which is the ground under the
## viewer. Returns null if nothing could be drawn (no window).
static func capture(world: Viewport, cam: Camera3D, preset: int, face: int,
		stamp: Array[String] = [], settle_first: int = -1,
		settle_turn: int = TURN_SETTLE_FRAMES) -> Image:
	if DisplayServer.get_name() == "headless" or world == null or cam == null or not _alive(world):
		return null
	var deadline := Time.get_ticks_msec() + CAPTURE_BUDGET_MS
	var eye := cam.global_position
	var bases := horizontal_basis(-cam.global_transform.basis.z)
	var f0: Vector3 = bases[0]
	var r0: Vector3 = bases[1]
	var faces: Array = face_bases(f0, r0)
	# One viewport for all six faces. Lighting that builds up over many
	# frames (SDFGI) settles once, on the first face; turning the camera
	# afterwards needs only a few frames. A fresh viewport per face would
	# have to settle six times, and drew each face darker than the view.
	var vp := SubViewport.new()
	vp.size = Vector2i(face, face)
	vp.transparent_bg = false
	vp.handle_input_locally = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	RenderQuality.apply_viewport(vp, preset)
	vp.use_taa = false  # a viewport that has never drawn has no history to blend
	var c := Camera3D.new()
	c.fov = fov_for(face)
	c.near = cam.near
	c.far = cam.far
	c.cull_mask = cam.cull_mask
	c.environment = cam.environment
	c.attributes = cam.attributes
	vp.add_child(c)
	world.add_child(vp)
	c.make_current()
	var first := settle_first if settle_first >= 0 else first_settle_frames(preset)
	var images: Array[Image] = []
	for i in faces.size():
		var b: Array = faces[i]
		c.transform = Transform3D(Basis(b[1], b[2], -(b[0] as Vector3)), eye)
		var ok := await _wait_draws(world, first if i == 0 else settle_turn, deadline)
		var img: Image = vp.get_texture().get_image() if ok else null
		if img == null or img.is_empty():
			vp.queue_free()
			return null
		img.convert(Image.FORMAT_RGB8)
		images.append(img)
	vp.queue_free()
	return await _project(world, images, faces, f0, r0, face, stamp, deadline)

## Frames the first face renders before it is read: many where the preset
## has SDFGI (Forward+ Ultra), whose light builds up over dozens of frames
## (measured on a 1024 px face: 3 frames read 21% too dark, 12 frames 7%,
## 48 frames 1.5%); a few elsewhere.
static func first_settle_frames(preset: int, forward_plus: bool = RenderQuality.is_forward_plus()) -> int:
	return GI_SETTLE_FRAMES if bool(RenderQuality.features_for(preset, forward_plus)["sdfgi"]) \
		else BASIC_SETTLE_FRAMES

## The compass heading (degrees, 0 north, clockwise) of the picture's
## centre, from the same horizontal direction `capture` centres on, so the
## metadata and the pixels cannot disagree. The view's yaw is the negative
## of this heading.
static func heading_deg(cam: Camera3D) -> float:
	var f0: Vector3 = horizontal_basis(-cam.global_transform.basis.z)[0]
	return fposmod(rad_to_deg(atan2(f0.x, -f0.z)), 360.0)

static func _project(host: Viewport, images: Array[Image], faces: Array, f0: Vector3,
		r0: Vector3, face: int, stamp: Array[String], deadline: int) -> Image:
	if not _alive(host):
		return null
	var w := width_for(face)
	var h := w / 2
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var shader := Shader.new()
	shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var fwd := PackedVector3Array()
	var rgt := PackedVector3Array()
	var upv := PackedVector3Array()
	for i in 6:
		mat.set_shader_parameter("face%d" % i, ImageTexture.create_from_image(images[i]))
		fwd.append((faces[i] as Array)[0])
		rgt.append((faces[i] as Array)[1])
		upv.append((faces[i] as Array)[2])
	mat.set_shader_parameter("fwd", fwd)
	mat.set_shader_parameter("rgt", rgt)
	mat.set_shader_parameter("upv", upv)
	mat.set_shader_parameter("f0", f0)
	mat.set_shader_parameter("r0", r0)
	mat.set_shader_parameter("shrink", shrink_for(face))
	mat.set_shader_parameter("blend_in", BLEND_IN)
	mat.set_shader_parameter("blend_out", BLEND_OUT)
	var rect := ColorRect.new()
	rect.size = Vector2(w, h)
	rect.material = mat
	vp.add_child(rect)
	if not stamp.is_empty():
		vp.add_child(_caption(stamp, w, h))
	host.add_child(vp)
	var ok := await _wait_draws(host, 2, deadline)
	var out: Image = vp.get_texture().get_image() if ok else null
	# The faces (six images and their textures, ~100 MB at 2048 px) go
	# before the picture is converted, so they do not add to its peak.
	images.clear()
	for i in 6:
		mat.set_shader_parameter("face%d" % i, null)
	vp.queue_free()
	if out == null or out.is_empty() or out.get_size() != Vector2i(w, h):
		return null
	out.convert(Image.FORMAT_RGB8)
	return out

## The stamp's lines, centred at the foot of the picture.
static func _caption(lines: Array[String], w: int, h: int) -> Control:
	var u := float(w) / 110.0
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", int(u * 0.1))
	col.size = Vector2(w, u * 7.0)
	col.position = Vector2(0, h - u * 8.0)
	var white := Color(1, 1, 1, 0.96)
	for i in lines.size():
		var l: Label
		if i == 0:
			l = UiTheme.display_label(lines[i], int(u * 1.9), white)
		elif i == 1:
			l = UiTheme.data_label(lines[i], int(u * 0.95), Color(white, 0.92), true)
		else:
			l = UiTheme.label(lines[i], int(u * 0.7), Color(white, 0.7))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	return col

## Whether `host` is still a live viewport in the tree (a view that was
## closed or freed while the capture ran takes the capture with it).
static func _alive(host: Viewport) -> bool:
	return is_instance_valid(host) and host.is_inside_tree()

## Waits until `frames` frames have been drawn; false if the window is not
## drawing (hidden, minimised), `host` has left the tree, or the capture's
## overall `deadline` (a Time.get_ticks_msec() value) has passed.
static func _wait_draws(host: Viewport, frames: int, deadline: int) -> bool:
	var drawn := [0]
	var on_draw := func() -> void: drawn[0] += 1
	RenderingServer.frame_post_draw.connect(on_draw)
	var tree := host.get_tree()
	while drawn[0] < frames and Time.get_ticks_msec() < deadline and _alive(host):
		await tree.process_frame
	RenderingServer.frame_post_draw.disconnect(on_draw)
	return drawn[0] >= frames and _alive(host)

## The finished picture as JPEG bytes carrying the panorama metadata.
static func encode(img: Image, heading_deg: float) -> PackedByteArray:
	return with_xmp(img.save_jpg_to_buffer(JPEG_QUALITY), xmp(img.get_width(), img.get_height(), heading_deg))

## `encode` on a worker thread, a frame at a time: encoding a full-size
## picture (8192×4096 on desktop) is the one long stretch of pure CPU
## work in the save, and on the main thread it freezes the app (the
## macOS beachball). `img` is only read by the worker; the caller must
## not modify it meanwhile.
static func encode_async(img: Image, heading_deg: float, tree: SceneTree) -> PackedByteArray:
	var box: Array = [PackedByteArray()]
	var task := WorkerThreadPool.add_task(func() -> void: box[0] = encode(img, heading_deg),
		false, "PanoramaEncode")
	while not WorkerThreadPool.is_task_completed(task):
		await tree.process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	return box[0]
