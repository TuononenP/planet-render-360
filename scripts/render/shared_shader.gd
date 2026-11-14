class_name SharedShader
extends RefCounted

## One Shader per distinct source code, for the session. The renderer
## compiles pipelines per Shader object, not per code: a builder making a
## fresh Shader for every world had each streamed stretch compile them all
## again on its first frames on screen (Metal stalls of ~0.5 s). Thread-safe:
## worlds are built on worker threads.

static var _by_code := {}
static var _mutex := Mutex.new()

static func of(code: String) -> Shader:
	_mutex.lock()
	var sh: Shader = _by_code.get(code)
	if sh == null:
		sh = Shader.new()
		sh.code = code
		_by_code[code] = sh
	_mutex.unlock()
	return sh
