extends Control
## Nueva HUD principal en partida (reposo, telemetría y accesos principales).
signal resource_pressed(id: String)
signal dock_pressed(id: String)
signal settings_pressed()
signal timmy_pressed()
signal mission_pressed()
signal storm_notice_pressed()

const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Clock = preload("res://ui/mission_clock.gd")

const IDS := ["energia", "agua", "oxigeno", "escudo", "energia_robot"]
const COLORS := [Color("#ffc64f"), Color("#68b9ff"), Color("#7fe7bf"), Color("#ff927a"), Color("#b4a4ff")]
const DOCK_TABS := [
	["construction", "construction", "live.construction"],
	["expedition", "ice", "live.hud_ice_tab"],
	["repair", "repair", "live.hud_repair_tab"],
	["missions", "missions", "live.missions"],
	["more", "more", "live.hud_more_tab"],
]

var resource_buttons: Dictionary = {}
var bars: Dictionary = {}
var values: Dictionary = {}
var dock_buttons: Dictionary = {}
var _labels: Dictionary = {}
var _dock_labels: Dictionary = {}
var _state: Dictionary = {}
var _mode := "cadete"
var _active_tab := ""
var _unread_count := 0

var _phase_icon: Control
var _clock: Label
var _ice_label: Label
var _stars_label: Label
var _settings_btn: Button
var _timmy_btn: Button
var _more_badge: Panel

var mission_card: Button
var _mission_label: Label
var _mission_count: Label
var _mission_bar: ProgressBar

var storm_banner: Panel
var _storm_title: Label
var _storm_sub: Label
var _storm_btn: Button


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(1280, 720)
	_build_resource_card()
	_build_top_pill()
	_build_storm_banner()
	_build_settings_button()
	_build_mission_pill()
	_build_bottom_dock()
	_build_timmy_button()
	refresh()


func _build_resource_card() -> void:
	var card := UI.panel(self, Rect2(16, 16, 260, 174), Color("#0c1c31de"), 16)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	for i in IDS.size():
		var id: String = IDS[i]
		var btn := Button.new()
		btn.name = "Resource_" + id
		btn.position = Vector2(8, 10 + i * 31)
		btn.size = Vector2(244, 29)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(resource_pressed.emit.bind(id))
		_style_row_button(btn, false)
		card.add_child(btn)
		resource_buttons[id] = btn

		var icon := Icon.new()
		icon.kind = "robot_battery" if id == "energia_robot" else id
		icon.disc = false
		icon.tint = COLORS[i]
		icon.position = Vector2(8, 6)
		icon.size = Vector2(16, 16)
		btn.add_child(icon)

		var lbl := UI.label(btn, "", Rect2(30, 3, 98, 22), 13, UI.WHITE, false)
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_labels[id] = lbl

		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_font_size_override("font_size", 1)
		bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 3))
		bar.add_theme_stylebox_override("fill", UI.style(COLORS[i], Color.TRANSPARENT, 0, 3))
		bar.position = Vector2(132, 11)
		bar.size = Vector2(64, 6)
		btn.add_child(bar)
		bars[id] = bar

		var val := UI.label(btn, "0%", Rect2(196, 3, 42, 22), 13, UI.WHITE, true)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		values[id] = val


func _build_top_pill() -> void:
	var pill := UI.panel(self, Rect2(442, 16, 396, 40), Color("#0c1c31de"), 14)
	pill.mouse_filter = Control.MOUSE_FILTER_STOP

	_phase_icon = Icon.new()
	_phase_icon.kind = "sun"
	_phase_icon.disc = false
	_phase_icon.tint = UI.GOLD
	_phase_icon.position = Vector2(14, 11)
	_phase_icon.size = Vector2(18, 18)
	pill.add_child(_phase_icon)

	_clock = UI.label(pill, "", Rect2(38, 8, 116, 24), 14, UI.WHITE, true)
	_clock.autowrap_mode = TextServer.AUTOWRAP_OFF

	_add_divider(pill, 160)

	var ice_icon := Icon.new()
	ice_icon.kind = "ice"
	ice_icon.disc = false
	ice_icon.tint = Color("#68b9ff")
	ice_icon.position = Vector2(174, 11)
	ice_icon.size = Vector2(18, 18)
	pill.add_child(ice_icon)

	_ice_label = UI.label(pill, "", Rect2(198, 8, 84, 24), 14, UI.WHITE, true)
	_ice_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	_add_divider(pill, 286)

	var star_icon := Icon.new()
	star_icon.kind = "star"
	star_icon.disc = false
	star_icon.tint = UI.GOLD
	star_icon.position = Vector2(300, 11)
	star_icon.size = Vector2(18, 18)
	pill.add_child(star_icon)

	_stars_label = UI.label(pill, "", Rect2(324, 8, 66, 24), 14, UI.WHITE, true)
	_stars_label.autowrap_mode = TextServer.AUTOWRAP_OFF


func _build_storm_banner() -> void:
	storm_banner = UI.panel(self, Rect2(436, 66, 408, 56), Color("#152031eb"), 14)
	storm_banner.add_theme_stylebox_override("panel", UI.style(Color("#152031eb"), Color("#ff927a"), 1, 14))
	storm_banner.mouse_filter = Control.MOUSE_FILTER_STOP
	storm_banner.hide()

	var warn_icon := Icon.new()
	warn_icon.kind = "warning"
	warn_icon.disc = false
	warn_icon.tint = Color("#ff927a")
	warn_icon.position = Vector2(14, 18)
	warn_icon.size = Vector2(20, 20)
	storm_banner.add_child(warn_icon)

	_storm_title = UI.label(storm_banner, "", Rect2(44, 7, 232, 22), 14, UI.WHITE, true)
	_storm_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_storm_sub = UI.label(storm_banner, "", Rect2(44, 29, 232, 18), 12, Color("#c7d6e6"))
	_storm_sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	_storm_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_storm_btn = UI.button(storm_banner, "", Rect2(284, 11, 112, 34), storm_notice_pressed.emit)
	_storm_btn.add_theme_font_size_override("font_size", 13)
	_storm_btn.add_theme_stylebox_override("normal", UI.style(Color("#1e3148"), Color("#536e87"), 1, 10))


func _build_settings_button() -> void:
	_settings_btn = Button.new()
	_settings_btn.name = "SettingsButton"
	_settings_btn.position = Vector2(1118, 16)
	_settings_btn.size = Vector2(146, 40)
	_settings_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_settings_btn.pressed.connect(settings_pressed.emit)
	_paint_pill_button(_settings_btn, false, 14)
	add_child(_settings_btn)

	var icon := Icon.new()
	icon.kind = "settings"
	icon.disc = false
	icon.tint = Color("#c7d6e6")
	icon.position = Vector2(14, 11)
	icon.size = Vector2(18, 18)
	_settings_btn.add_child(icon)

	var lbl := UI.label(_settings_btn, "", Rect2(38, 8, 100, 24), 14, UI.WHITE, true)
	lbl.name = "Caption"
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF


func _build_mission_pill() -> void:
	mission_card = Button.new()
	mission_card.name = "ActiveMissionPill"
	mission_card.position = Vector2(16, 654)
	mission_card.size = Vector2(296, 50)
	mission_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mission_card.pressed.connect(mission_pressed.emit)
	_paint_pill_button(mission_card, false, 14)
	add_child(mission_card)

	var icon := Icon.new()
	icon.kind = "missions"
	icon.disc = false
	icon.tint = UI.GOLD
	icon.position = Vector2(14, 11)
	icon.size = Vector2(18, 18)
	mission_card.add_child(icon)

	_mission_label = UI.label(mission_card, "", Rect2(40, 9, 206, 22), 14, UI.WHITE, true)
	_mission_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_mission_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_mission_count = UI.label(mission_card, "0/1", Rect2(246, 9, 38, 22), 13, Color("#68b9ff"), true)
	_mission_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_mission_bar = ProgressBar.new()
	_mission_bar.show_percentage = false
	_mission_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_bar.add_theme_font_size_override("font_size", 1)
	_mission_bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 3))
	_mission_bar.add_theme_stylebox_override("fill", UI.style(UI.CYAN, Color.TRANSPARENT, 0, 3))
	_mission_bar.position = Vector2(14, 37)
	_mission_bar.size = Vector2(268, 4)
	mission_card.add_child(_mission_bar)


func _build_bottom_dock() -> void:
	var dock := UI.panel(self, Rect2(414, 636, 452, 68), Color("#0c1c31e6"), 18)
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	for i in DOCK_TABS.size():
		var tab_id: String = DOCK_TABS[i][0]
		var icon_kind: String = DOCK_TABS[i][1]
		var btn := Button.new()
		btn.name = "Dock_" + tab_id
		btn.position = Vector2(8 + i * 88, 6)
		btn.size = Vector2(82, 56)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(dock_pressed.emit.bind(tab_id))
		dock.add_child(btn)
		dock_buttons[tab_id] = btn

		var icon := Icon.new()
		icon.name = "Icon"
		icon.kind = icon_kind
		icon.disc = false
		icon.tint = UI.WHITE
		icon.position = Vector2(30, 8)
		icon.size = Vector2(22, 22)
		btn.add_child(icon)

		var lbl := UI.label(btn, "", Rect2(4, 33, 74, 20), 13, UI.WHITE, true)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		_dock_labels[tab_id] = lbl

		if tab_id == "more":
			_more_badge = UI.panel(btn, Rect2(58, 6, 10, 10), UI.GOLD, 5)
			_more_badge.hide()


func _build_timmy_button() -> void:
	_timmy_btn = Button.new()
	_timmy_btn.name = "TimmyButton"
	_timmy_btn.position = Vector2(1148, 654)
	_timmy_btn.size = Vector2(116, 48)
	_timmy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_timmy_btn.pressed.connect(timmy_pressed.emit)
	UI.paint(_timmy_btn, true)
	_timmy_btn.add_theme_stylebox_override("normal", UI.style(UI.GOLD, Color.TRANSPARENT, 0, 14))
	_timmy_btn.add_theme_stylebox_override("hover", UI.style(Color("#ffdb85"), UI.WHITE, 2, 14))
	add_child(_timmy_btn)

	var icon := Icon.new()
	icon.kind = "audio"
	icon.disc = false
	icon.tint = UI.INK
	icon.position = Vector2(16, 14)
	icon.size = Vector2(20, 20)
	_timmy_btn.add_child(icon)

	var lbl := UI.label(_timmy_btn, "Timmy", Rect2(42, 11, 64, 24), 15, UI.INK, true)
	lbl.name = "Caption"
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF


func _add_divider(parent: Control, x: float) -> void:
	var line := ColorRect.new()
	line.color = Color(0.48, 0.77, 0.84, 0.25)
	line.position = Vector2(x, 10)
	line.size = Vector2(1, 20)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


func _style_row_button(btn: Button, low: bool) -> void:
	var border := Color("#ff927a") if low else Color.TRANSPARENT
	var width := 1 if low else 0
	btn.add_theme_stylebox_override("normal", UI.style(Color("#1a2b4266") if low else Color.TRANSPARENT, border, width, 8))
	btn.add_theme_stylebox_override("hover", UI.style(Color("#203854cc"), Color(0.48, 0.77, 0.84, 0.45), 1, 8))
	btn.add_theme_stylebox_override("pressed", UI.style(Color("#29476ae0"), UI.CYAN, 1, 8))
	btn.add_theme_stylebox_override("focus", UI.style(Color.TRANSPARENT, UI.CYAN, 2, 8))


func _paint_pill_button(btn: Button, active: bool, radius: int) -> void:
	var bg := Color("#17324be6") if active else Color("#0c1c31de")
	var border := UI.GOLD if active else Color(0.48, 0.77, 0.84, 0.35)
	btn.add_theme_stylebox_override("normal", UI.style(bg, border, 2 if active else 1, radius))
	btn.add_theme_stylebox_override("hover", UI.style(Color("#1b3854f0"), UI.GOLD if active else UI.CYAN, 2, radius))
	btn.add_theme_stylebox_override("pressed", UI.style(Color("#24496af5"), UI.GOLD, 2, radius))
	btn.add_theme_stylebox_override("focus", UI.style(bg, UI.CYAN, 2, radius))


func set_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	if is_node_ready():
		refresh()


func set_mode(value: String) -> void:
	_mode = value
	if is_node_ready():
		refresh()


func set_active_tab(tab_id: String) -> void:
	_active_tab = tab_id
	if is_node_ready():
		refresh()


func set_unread_count(count: int) -> void:
	_unread_count = count
	if is_instance_valid(_more_badge):
		_more_badge.visible = _unread_count > 0


func set_mission_summary(text: String, done: int, total: int, tooltip := "") -> void:
	if not is_node_ready():
		return
	_mission_label.text = text
	_mission_count.text = "%d/%d" % [done, maxi(1, total)]
	_mission_bar.max_value = maxi(1, total)
	_mission_bar.value = clampi(done, 0, maxi(1, total))
	mission_card.tooltip_text = tooltip


func set_storm_alert(visible_flag: bool, title: String = "", subtitle: String = "") -> void:
	if not is_instance_valid(storm_banner):
		return
	storm_banner.visible = visible_flag
	if visible_flag:
		_storm_title.text = title
		_storm_sub.text = subtitle


func refresh() -> void:
	if not is_node_ready():
		return
	for i in IDS.size():
		var id: String = IDS[i]
		var entry: Dictionary = _state.get(id, {"value": 0, "max": 100})
		var ratio := clampf(float(entry.get("value", 0)) / maxf(float(entry.get("max", 100)), 1.0), 0.0, 1.0)
		bars[id].value = ratio * 100.0
		var label_text := tr("hud." + id + ".nombre")
		if id == "oxigeno":
			label_text = label_text.replace(" (4)", "")
		_labels[id].text = label_text
		var pct_text := "%d%%" % roundi(ratio * 100.0)
		values[id].text = pct_text
		values[id].add_theme_color_override("font_color", Color("#ff927a") if ratio <= 0.2 else UI.WHITE)
		resource_buttons[id].tooltip_text = tr("hud." + id + ".help")
		_style_row_button(resource_buttons[id], ratio <= 0.2)

	var clock_data := Clock.display(_state)
	var is_day := Clock.is_day(_state)
	var day_text := tr("live.days_only").format({"day": int(clock_data.day)})
	_clock.text = "%s · %s" % [day_text, str(clock_data.time)]
	_clock.tooltip_text = "%s · %s" % [day_text, tr("guide.dayphase" if is_day else "guide.nightphase")]
	_phase_icon.kind = "sun" if is_day else "moon"
	_phase_icon.tint = UI.GOLD if is_day else UI.CYAN
	_phase_icon.queue_redraw()

	_ice_label.text = "%s %d/10" % [tr("live.ice"), int(_state.get("hielo", 0))]
	_stars_label.text = "%s %d" % [tr("live.stars"), int(_state.get("estrellas", 0))]

	_settings_btn.get_node("Caption").text = tr("live.hud_settings")
	_storm_btn.text = tr("live.view_notice")
	_timmy_btn.get_node("Caption").text = tr("live.hud_timmy_tab")
	_timmy_btn.tooltip_text = tr("live.timmy")

	for item in DOCK_TABS:
		var tab_id: String = item[0]
		var key: String = item[2]
		var btn: Button = dock_buttons[tab_id]
		var active := (_active_tab == tab_id)
		_paint_pill_button(btn, active, 12)
		_dock_labels[tab_id].text = tr(key)
		_dock_labels[tab_id].add_theme_color_override("font_color", UI.GOLD if active else UI.WHITE)
		var icon := btn.get_node("Icon") as Icon
		icon.tint = UI.GOLD if active else UI.WHITE
		icon.queue_redraw()
