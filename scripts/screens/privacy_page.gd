class_name PrivacyPage
extends RefCounted

## Settings → Privacy: the privacy policy inside the app, so it reads the
## same offline as on the website. A banner and four plain figures, then
## what stays on the device, which services the app contacts and what each
## receives, what it never does, and the person's choices. The words live
## in PrivacyData; this builds the page from solid sky-200 groups like the
## other Settings pages.

const STAT_MIN_W := 150.0

static func build(_s: SettingsScreen) -> VBoxContainer:
	var page := SettingsPages._page()
	page.add_child(_hero())
	page.add_child(_glance())
	var device := SettingsRows.group()
	for line in PrivacyData.ON_DEVICE:
		SettingsRows.add(device, _line("check", UiTheme.TEAL, line))
	SettingsPages._section(page, "On this device", device, PrivacyData.ON_DEVICE_NOTE)
	var leaves := VBoxContainer.new()
	leaves.add_theme_constant_override("separation", 12)
	leaves.add_child(_callout(PrivacyData.LEAVES_NOTE))
	var services := SettingsRows.group()
	for service in PrivacyData.SERVICES:
		SettingsRows.add(services, _service(service[0], service[1], service[2]))
	leaves.add_child(services)
	SettingsPages._section(page, "What leaves your device", leaves, PrivacyData.SERVICES_NOTE)
	var never := SettingsRows.group()
	for line in PrivacyData.NEVER:
		SettingsRows.add(never, _line("minus", UiTheme.SIGNAL_ERROR, line))
	SettingsPages._section(page, "What the app does not do", never)
	var choices := SettingsRows.group()
	for line in PrivacyData.CHOICES:
		SettingsRows.add(choices, _line("check", UiTheme.TEAL, line))
	SettingsPages._section(page, "Your choices", choices)
	var more := SettingsRows.group()
	SettingsRows.add(more, SettingsRows.row("Children", null, PrivacyData.CHILDREN))
	SettingsRows.add(more, SettingsRows.row("Contact", null, PrivacyData.CONTACT))
	SettingsRows.add(more, SettingsRows.link("Read it online",
		"The same policy on the project’s website", Brand.PRIVACY_URL))
	SettingsPages._section(page, "Children and contact", more)
	return page

static func _hero() -> PanelContainer:
	var card := PanelContainer.new()
	var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
	st.set_content_margin_all(0)
	card.add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)
	col.add_child(PrivacyHero.new())
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 8)
	col.add_child(SettingsPages._pad(text, 20, 20))
	text.add_child(UiTheme.text("What you look at stays with you.", "title"))
	text.add_child(_wrapped(PrivacyData.LEDE, 15, UiTheme.INK))
	text.add_child(_wrapped(PrivacyData.BODY, 14, UiTheme.MUTED))
	text.add_child(UiTheme.data_label("Updated %s" % PrivacyData.UPDATED, 13, UiTheme.FAINT))
	return card

## The four figures: two across on a phone, four on a wider page.
static func _glance() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for stat in PrivacyData.GLANCE:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.custom_minimum_size = Vector2(STAT_MIN_W, 0)
		var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
		st.set_content_margin_all(16)
		tile.add_theme_stylebox_override("panel", st)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		tile.add_child(col)
		col.add_child(UiTheme.data_label(str(stat[0]), 32, UiTheme.TEAL, true))
		col.add_child(_wrapped(str(stat[1]), 14, UiTheme.MUTED))
		grid.add_child(tile)
	grid.resized.connect(func() -> void:
		var cols := 4 if grid.size.x >= 4.0 * (STAT_MIN_W + 12.0) * UiTheme.text_scale else 2
		if grid.columns != cols:
			grid.columns = cols)
	return grid

## An icon beside one sentence, 16 px in from the group's edge.
static func _line(icon: String, color: Color, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var mark := UiIcon.rect(icon, 18, color)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 2)
	pad.add_child(mark)
	row.add_child(pad)
	row.add_child(_wrapped(text, 15, UiTheme.INK))
	return SettingsPages._pad(row, 16, 12)

## One service: its name, the hosts it is reached at (a host to a line,
## in the data face), and what it receives.
static func _service(label: String, hosts: Array, receives: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.add_child(_wrapped(label, 15, UiTheme.INK, true))
	var host_label := UiTheme.data_label("\n".join(PackedStringArray(hosts)), 12, UiTheme.TEAL)
	host_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	host_label.custom_minimum_size = Vector2(60, 0)
	col.add_child(host_label)
	col.add_child(_wrapped(receives, 14, UiTheme.MUTED))
	return SettingsPages._pad(col, 16, 12)

## Accent-soft note: ink text, the accent only on the border and icon.
static func _callout(text: String) -> PanelContainer:
	var box := PanelContainer.new()
	var st := UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_M, UiTheme.TEAL)
	st.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var mark := UiIcon.rect("info", 20, UiTheme.TEAL)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(mark)
	row.add_child(_wrapped(text, 15, UiTheme.INK))
	return box

static func _wrapped(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := UiTheme.label(text, size, color, bold)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(60, 0)
	return l
