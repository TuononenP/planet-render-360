class_name MapFacts
extends RefCounted

## The selected place's real data on the map home (design system MapHome:
## Readouts for elevation and local time, weather as a HudChip). One
## Open-Meteo request per selection, after a short pause so panning and
## typing send nothing; it carries the point's elevation, its UTC offset
## and current weather. Nothing is shown until real values arrive, and a
## failed request hides them (never a guess). A connection failure puts
## the picker in its offline state. Operates on the picker via `p`.

const PAUSE_S := 0.6

static func build(p: MapPicker) -> void:
	p._facts_fetcher = WeatherFetcher.new()
	p.add_child(p._facts_fetcher)
	p._facts_fetcher.succeeded.connect(func(temp_c: float, label: String, _cover: float, code: int) -> void:
		_on_facts(p, temp_c, label, code))
	p._facts_fetcher.failed.connect(func(_r: String) -> void:
		hide_facts(p)
		if p._facts_fetcher.offline:
			p.set_offline(true))
	p._facts_timer = Timer.new()
	p._facts_timer.one_shot = true
	p._facts_timer.wait_time = PAUSE_S
	p._facts_timer.timeout.connect(func() -> void:
		p._facts_fetcher.fetch(p._lat, p._lon))
	p.add_child(p._facts_timer)
	var clock := Timer.new()
	clock.wait_time = 30.0
	clock.autostart = true
	clock.timeout.connect(func() -> void: _refresh_clock(p))
	p.add_child(clock)

	p._facts_box = HBoxContainer.new()
	p._facts_box.add_theme_constant_override("separation", 24)
	p._facts_box.visible = false
	p._elev_readout = Readout.new("Elevation", true)
	p._facts_box.add_child(p._elev_readout)
	p._time_readout = Readout.new("Local time", true)
	p._facts_box.add_child(p._time_readout)
	var chip := HudParts.hud_chip()
	p._weather_chip = chip[0]
	p._weather_parts = chip
	p._weather_chip.visible = false

## A new point: clear the old values and ask again after the pause.
static func request(p: MapPicker) -> void:
	if p._facts_timer == null:
		return
	hide_facts(p)
	p._facts_timer.start()

static func hide_facts(p: MapPicker) -> void:
	p._facts_box.visible = false
	p._weather_chip.visible = false
	p._facts_offset_s = -1

static func _on_facts(p: MapPicker, temp_c: float, label: String, code: int) -> void:
	p.set_offline(false)
	var f := p._facts_fetcher
	p._elev_readout.visible = f.has_elevation
	if f.has_elevation:
		p._elev_readout.set_value(UiTheme.elevation(f.elevation_m))
	p._facts_offset_s = f.utc_offset_s if f.has_utc_offset else -1
	p._time_readout.visible = f.has_utc_offset
	_refresh_clock(p)
	p._facts_box.visible = f.has_elevation or f.has_utc_offset
	var parts: Array = p._weather_parts
	(parts[1] as TextureRect).texture = UiIcon.texture(HudParts.weather_icon(code), 18)
	(parts[2] as Label).text = "%d °C" % roundi(temp_c)
	(parts[3] as Label).text = label
	p._weather_chip.visible = true

static func _refresh_clock(p: MapPicker) -> void:
	if p._facts_offset_s == -1 or p._time_readout == null:
		return
	var local := Time.get_unix_time_from_system() + float(p._facts_offset_s)
	var t := Time.get_datetime_dict_from_unix_time(int(local))
	p._time_readout.set_value(UiTheme.clock(float(t["hour"]) + float(t["minute"]) / 60.0),
		UiTheme.utc_label(p._facts_offset_s))
