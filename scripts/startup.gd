extends Control

# Keep this shader cached before the background loader compiles car models.
# Loading it for the first time on that thread fails with the Metal renderer.
const CAR_PAINT_SHADER = preload("res://scripts/generation/car_paint.gdshader")
const MAIN_SCENE := "res://scenes/main.tscn"
const SERIF = preload("res://assets/fonts/InstrumentSerif-Regular.ttf")
const MONO = preload("res://assets/fonts/IBMPlexMono-Medium.ttf")
const MARK = preload("res://assets/brand/pr360-mark-dark.svg")
const ORBIT = preload("res://assets/brand/splash-orbit.png")

var _elapsed := 0.0
var _progress := 0.0

func _ready() -> void:
	var err := ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene")
	if err != OK:
		push_error("Could not start loading the main scene: %s" % err)
		set_process(false)

func _process(delta: float) -> void:
	_elapsed += delta
	var progress: Array = []
	match ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress):
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			var scene := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
			get_tree().change_scene_to_packed(scene)
			return
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			push_error("Could not load the main scene")
	if not progress.is_empty():
		_progress = progress[0]
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var unit := minf(w, h)
	# Cover the viewport while keeping the sunrise in view on narrow screens.
	var image_size := Vector2(ORBIT.get_size())
	var scale_factor := maxf(w / image_size.x, h / image_size.y)
	var visible := size / scale_factor
	var crop_x := clampf(image_size.x * 0.68 - visible.x * 0.5, 0.0, image_size.x - visible.x)
	var drift := minf(_elapsed * 0.35, 8.0)
	crop_x = clampf(crop_x + drift, 0.0, image_size.x - visible.x)
	draw_texture_rect_region(ORBIT, Rect2(Vector2.ZERO, size), Rect2(Vector2(crop_x, (image_size.y - visible.y) * 0.5), visible))
	# Darken the image just enough to keep the lettering legible.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.035, 0.07, 0.25))
	var mark_size := clampf(unit * 0.085, 32.0, 48.0)
	draw_texture_rect(MARK, Rect2(Vector2((w - mark_size) * 0.5, h * 0.075), Vector2.ONE * mark_size), false)
	var title_size := int(clampf(unit * 0.105, 34.0, 62.0))
	var title_y := h * 0.28
	draw_string(SERIF, Vector2(0, title_y), "Planet Render 360", HORIZONTAL_ALIGNMENT_CENTER, w, title_size, Color("edf1f6"))
	draw_string(MONO, Vector2(0, title_y + 29.0), "THE WORLD, FROM HERE", HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color("edf1f6"))
	var bar_width := minf(150.0, w * 0.38)
	var start := Vector2((w - bar_width) * 0.5, h * 0.88)
	draw_line(start, start + Vector2(bar_width, 0), Color(0.93, 0.95, 0.97, 0.28), 2.0)
	draw_line(start, start + Vector2(bar_width * clampf(_progress, 0.0, 1.0), 0), Color("f0b06a"), 2.0)
