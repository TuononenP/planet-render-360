extends SceneTree

## Native image kernels: godot --headless --path . --script tests/image_kernels_test.gd
## ImageKernels.fix_alpha_edges (native/, tools/build_native.sh) must give
## exactly Image.fix_alpha_edges' bytes: on random images of every density
## and size, with mipmaps, in a format it hands back to the engine, and on
## a composed facade's paint layer. Skips, passing, when the library is
## not built.

func _init() -> void:
	if not ClassDB.class_exists("ImageKernels"):
		print("IMAGE_KERNELS SKIP: ImageKernels is not loaded (tools/build_native.sh)")
		quit(0)
		return
	var failures: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for t in 200:
		var w := rng.randi_range(1, 40)
		var h := rng.randi_range(1, 40)
		var img := Image.create(w, h, false, Image.FORMAT_RGB8 if t % 10 == 9 else Image.FORMAT_RGBA8)
		var density := rng.randf()
		for y in h:
			for x in w:
				var a := rng.randf() if rng.randf() < density else rng.randf_range(0.0, 0.1)
				img.set_pixel(x, y, Color(rng.randf(), rng.randf(), rng.randf(), a))
		if t % 7 == 3:
			img.generate_mipmaps()
		if not _same(img):
			failures.append("random image %d (%dx%d)" % [t, w, h])
	# A facade's paint layer: clear wall with frames and glass painted on.
	var paint := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	paint.fill(Color(0.4, 0.38, 0.35, 0.0))
	for k in 12:
		paint.fill_rect(Rect2i(20 + k * 40, 60 + (k % 3) * 120, 24, 50), Color(0.85, 0.83, 0.78))
		paint.fill_rect(Rect2i(24 + k * 40, 64 + (k % 3) * 120, 16, 42), Color(0.1, 0.12, 0.14, 0.5))
	if not _same(paint):
		failures.append("paint layer")
	if failures.is_empty():
		print("IMAGE_KERNELS PASS")
		quit(0)
	else:
		for f in failures:
			push_error("IMAGE_KERNELS FAIL: " + f)
		quit(1)

func _same(img: Image) -> bool:
	var engine := img.duplicate() as Image
	engine.fix_alpha_edges()
	ClassDB.class_call_static("ImageKernels", "fix_alpha_edges", img)
	return engine.get_data() == img.get_data() and engine.has_mipmaps() == img.has_mipmaps() \
		and engine.get_format() == img.get_format()
