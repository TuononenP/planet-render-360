class_name MapFacts
extends RefCounted

## The selected place's real data on the map home (design system MapHome:
## Readouts for elevation, local time and weather). One
## Open-Meteo request per selection, after a short pause so panning and
## typing send nothing; it carries the point's elevation, its UTC offset
## and current weather. Until real values arrive the same slots hold
## ink-muted "—" placeholders so the panel doesn't jump when they land
## (never a guessed value); a failed request hides them. A connection failure puts
## the picker in its offline state. Operates on the picker via `p`.

const PAUSE_S := 0.6
const FACTS_SIZE := 20

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

	# One strip under the coordinates: elevation, local time and weather
	# side by side (the flow wraps the last one only if the panel is too
	# narrow), set apart from the coordinates by a clear gap.
	p._facts_box = MarginContainer.new()
	p._facts_box.add_theme_constant_override("margin_top", 14)
	p._facts_box.visible = false
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	flow.add_theme_constant_override("v_separation", 12)
	p._facts_box.add_child(flow)
	p._elev_readout = Readout.new("Elevation", true, FACTS_SIZE)
	flow.add_child(p._elev_readout)
	p._time_readout = Readout.new("Local time", true, FACTS_SIZE)
	flow.add_child(p._time_readout)
	p._weather_readout = Readout.new("Weather", true, FACTS_SIZE)
	p._weather_readout.visible = false
	flow.add_child(p._weather_readout)

## A new point: swap the old values for placeholders and ask again after
## the pause.
static func request(p: MapPicker) -> void:
	if p._facts_timer == null:
		return
	show_placeholders(p)
	p._facts_timer.start()

## Reserve the readouts' and chip's space with "—" until real data lands.
static func show_placeholders(p: MapPicker) -> void:
	p._facts_offset_s = -1
	p._elev_readout.visible = true
	p._elev_readout.set_pending()
	p._time_readout.visible = true
	p._time_readout.set_pending()
	p._facts_box.visible = true
	p._weather_readout.set_label("Weather")
	p._weather_readout.set_icon("cloud")
	p._weather_readout.set_pending()
	p._weather_readout.visible = true

static func hide_facts(p: MapPicker) -> void:
	p._facts_box.visible = false
	p._weather_readout.visible = false
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
	p._weather_readout.set_label(label)
	p._weather_readout.set_icon(HudParts.weather_icon(code))
	p._weather_readout.set_value("%d °C" % roundi(temp_c))
	p._weather_readout.visible = true

static func _refresh_clock(p: MapPicker) -> void:
	if p._facts_offset_s == -1 or p._time_readout == null:
		return
	var local := Time.get_unix_time_from_system() + float(p._facts_offset_s)
	var t := Time.get_datetime_dict_from_unix_time(int(local))
	p._time_readout.set_value(UiTheme.clock(float(t["hour"]) + float(t["minute"]) / 60.0),
		UiTheme.utc_label(p._facts_offset_s))
