class_name LayerRequest
extends Node

## One map layer from both live OSM services: Postpass first, then Overpass.
## With no Overpass instance to ask (MapSources.overpass_endpoints: none on
## iOS and Android) only Postpass is asked. Emits OverpassRequest's signals,
## so a fetcher swaps one for this.

signal answered(text: String)
signal exhausted(reason: String, attempts: int)

## The Overpass side, for its first_byte_timeout.
var overpass: OverpassRequest
var _postpass: PostpassRequest
var _postpass_body := ""
var _overpass_body := ""
var _check: Callable
var _endpoints: Array[String] = []
var _overpass_tried := false
var _reason := ""

func _init(timeout_s: float, postpass_timeout_s: float = PostpassFallback.TIMEOUT_S) -> void:
	overpass = OverpassRequest.new(timeout_s)
	add_child(overpass)
	_postpass = PostpassRequest.new(postpass_timeout_s)
	add_child(_postpass)
	overpass.answered.connect(func(text: String) -> void: answered.emit(text))
	overpass.exhausted.connect(_on_overpass_exhausted)
	_postpass.answered.connect(func(text: String) -> void: answered.emit(text))
	_postpass.failed.connect(_on_postpass_failed)

## `postpass_body` is a PostpassFallback/PostpassLayers body, `overpass_body`
## the urlencoded Overpass POST; `check` returns "" for a usable payload.
func run(postpass_body: String, overpass_body: String, check: Callable, endpoints: Array[String]) -> void:
	cancel()
	_postpass_body = postpass_body
	_overpass_body = overpass_body
	_check = check
	_endpoints = endpoints
	_overpass_tried = false
	_reason = ""
	_run_postpass()

func cancel() -> void:
	overpass.cancel()
	_postpass.cancel()

func _run_postpass() -> void:
	_postpass.run(_postpass_body, _check)

func _run_overpass() -> void:
	_overpass_tried = true
	overpass.run(_overpass_body, _check, _endpoints)

func _on_postpass_failed(why: String) -> void:
	_reason = why if _reason == "" else "%s; %s" % [_reason, why]
	if not _overpass_tried and not _endpoints.is_empty():
		print("LayerRequest: %s; asking Overpass" % why)
		_run_overpass()
	else:
		exhausted.emit(_reason, 0)

func _on_overpass_exhausted(reason: String, attempts: int) -> void:
	_reason = reason if _reason == "" else "%s; %s" % [_reason, reason]
	exhausted.emit(_reason, attempts)
