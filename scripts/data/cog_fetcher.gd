class_name CogFetcher
extends Node

## Bounded HTTP-range reader for one pixel's tiled COG. The result carries
## the chosen overview and the decoded tile; callers can reuse it for every
## pixel in that tile. A superseded request never emits a stale result.
signal finished(result: Dictionary)

const HEADER_BYTES := 262144
const IFD_BYTES := 65536
const MAX_IFDS := 32
const MAX_TILE_BYTES := 4 * 1024 * 1024
const REQUEST_TIMEOUT_S := 15.0

var _generation := 0
var _requests: Array[HTTPRequest] = []
var _tasks: Array[int] = []
var _metadata := {}

func cancel() -> void:
	_generation += 1
	for req in _requests:
		if is_instance_valid(req):
			req.cancel_request()
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		cancel()

## x/y are pixels in the full-resolution image. A reduction of 4 selects
## the finest available overview no coarser than four source pixels.
func fetch_tile(url: String, x: int, y: int, reduction: float = 1.0) -> void:
	cancel()
	_fetch(url, x, y, reduction, _generation)

func _fetch(url: String, x: int, y: int, reduction: float, gen: int) -> void:
	var record: Dictionary = _metadata.get(url, {})
	if record.is_empty():
		var fetched_header := await _range(url, 0, HEADER_BYTES - 1, gen)
		if gen != _generation:
			return
		var first := CogReader.first_ifd(fetched_header)
		if first < 0:
			finished.emit({})
			return
		var chain := CogReader.parse_ifds(fetched_header, 0, first)
		var found: Array = chain["ifds"]
		var next := int(chain["next"])
		while next > 0 and found.size() < MAX_IFDS:
			var extra := await _range(url, next, next + IFD_BYTES - 1, gen)
			if gen != _generation:
				return
			var tail := CogReader.parse_ifds(extra, next, next)
			if (tail["ifds"] as Array).is_empty():
				finished.emit({})
				return
			found.append_array(tail["ifds"])
			next = int(tail["next"])
		if next != 0 or found.size() > MAX_IFDS:
			finished.emit({})
			return
		record = {"header": fetched_header, "ifds": found}
		_metadata[url] = record
	var header: PackedByteArray = record["header"]
	var ifds: Array = record["ifds"]
	var base := CogReader.overview(ifds, 1.0)
	var ifd := CogReader.overview(ifds, reduction)
	if base.is_empty() or ifd.is_empty() or x < 0 or y < 0 \
			or x >= int(base["width"]) or y >= int(base["height"]):
		finished.emit({})
		return
	var px := floori(float(x) * float(ifd["width"]) / float(base["width"]))
	var py := floori(float(y) * float(ifd["height"]) / float(base["height"]))
	var tile := CogReader.tile_index(ifd, px, py)
	var offset := await _table_entry(url, ifd["offsets"], tile, header, gen)
	var length := await _table_entry(url, ifd["sizes"], tile, header, gen)
	if gen != _generation:
		return
	if offset <= 0 or length <= 0 or length > MAX_TILE_BYTES:
		finished.emit({})
		return
	var compressed := await _range(url, offset, offset + length - 1, gen)
	if gen != _generation:
		return
	var box := {}
	var width := int(ifd["tile_width"])
	var height := int(ifd["tile_height"])
	var predictor := int(ifd.get("predictor", 1))
	var task := WorkerThreadPool.add_task(func() -> void:
		box["pixels"] = CogReader.decode_tile(compressed, width, height, predictor))
	_tasks.append(task)
	while _tasks.has(task) and not WorkerThreadPool.is_task_completed(task):
		await get_tree().process_frame
	if _tasks.has(task):
		WorkerThreadPool.wait_for_task_completion(task)
		_tasks.erase(task)
	if gen != _generation:
		return
	var pixels: PackedByteArray = box.get("pixels", PackedByteArray())
	if pixels.is_empty():
		finished.emit({})
		return
	finished.emit({"ifd": ifd, "index": tile, "pixel": Vector2i(px % width, py % height),
		"pixels": pixels})

func _table_entry(url: String, table: Dictionary, index: int,
		header: PackedByteArray, gen: int) -> int:
	var value := CogReader.table_value(table, index, header, 0)
	if value >= 0 or int(table.get("count", 0)) <= 1:
		return value
	var offset := int(table.get("value", 0)) + index * 4
	var bytes := await _range(url, offset, offset + 3, gen)
	return CogReader.table_value(table, index, bytes, offset)

func _range(url: String, first: int, last: int, gen: int) -> PackedByteArray:
	if gen != _generation or first < 0 or last < first:
		return PackedByteArray()
	var req := HTTPRequest.new()
	req.timeout = REQUEST_TIMEOUT_S
	add_child(req)
	_requests.append(req)
	var state := {"done": false, "result": -1, "code": 0, "headers": PackedStringArray(), "body": PackedByteArray()}
	req.request_completed.connect(func(result: int, code: int, headers: PackedStringArray,
			body: PackedByteArray) -> void:
		state.merge({"done": true, "result": result, "code": code, "headers": headers, "body": body}, true))
	var err := req.request(url, ["User-Agent: " + Brand.USER_AGENT,
		"Range: bytes=%d-%d" % [first, last]])
	var deadline := Time.get_ticks_msec() + int(REQUEST_TIMEOUT_S * 1000.0)
	while err == OK and not state["done"] and gen == _generation and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not state["done"]:
		req.cancel_request()
	_requests.erase(req)
	req.queue_free()
	if gen != _generation or not state["done"] or state["result"] != HTTPRequest.RESULT_SUCCESS \
			or state["code"] != 206 or (state["body"] as PackedByteArray).size() != last - first + 1:
		return PackedByteArray()
	var expected := "content-range: bytes %d-%d/" % [first, last]
	var valid_range := false
	for line in state["headers"]:
		if str(line).strip_edges().to_lower().begins_with(expected):
			valid_range = true
			break
	if not valid_range:
		return PackedByteArray()
	return state["body"]
