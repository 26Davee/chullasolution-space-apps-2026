extends Control
signal resource_pressed(id: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Clock = preload("res://ui/mission_clock.gd")
const IDS := ["energia", "agua", "oxigeno", "escudo", "energia_robot"]
const COLORS := [Color("#ffc64f"), Color("#68b9ff"), Color("#7fe7bf"), Color("#ff927a"), Color("#b4a4ff")]
var tutorial_layout := false
var _target := ""
var values: Dictionary
var bars: Dictionary = {}
var resource_buttons: Dictionary = {}
var _labels: Dictionary = {}
var _values: Dictionary = {}
var _state: Dictionary = {}
var _phase_icon: Control
var _clock: Label
var _cargo: Label
var _mode = "cadete"
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(1248,190)
	UI.panel(self,Rect2(0,0,240,190),Color("#101e34ec"),16).mouse_filter = MOUSE_FILTER_STOP
	UI.panel(self,Rect2(358,0,500,36),Color("#101e34ec"),14)
	_phase_icon = Icon.new()
	_phase_icon.kind = "sun"
	_phase_icon.disc = false
	_phase_icon.tint = UI.GOLD
	_phase_icon.position = Vector2(370,7)
	_phase_icon.size = Vector2(22,22)
	add_child(_phase_icon)
	_clock = UI.label(self,"",Rect2(402,7,176,24),15,UI.WHITE,true)
	_cargo = UI.label(self,"",Rect2(576,7,270,24),14,UI.GOLD,true)
	_cargo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	values = _values
	for i in IDS.size():
		var id: String = IDS[i]
		var card = UI.button(self, "", Rect2(6,10+i*34,228,30), resource_pressed.emit.bind(id))
		card.name = "Resource_" + id
		resource_buttons[id] = card
		var icon = Icon.new()
		icon.kind = "robot_battery" if id == "energia_robot" else id
		icon.tint = COLORS[i]
		icon.position = Vector2(6,5)
		icon.size = Vector2(20,20)
		card.add_child(icon)
		_labels[id] = UI.label(card, "", Rect2(34,4,104,24),14, UI.WHITE, true)
		_values[id] = UI.label(card, "", Rect2(184,4,42,22),14, UI.WHITE, true)
		_values[id].autowrap_mode = TextServer.AUTOWRAP_OFF
		var bar = ProgressBar.new()
		bar.show_percentage = false
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		bar.add_theme_font_size_override("font_size", 1)
		bar.add_theme_stylebox_override("background", UI.style(Color("#34445e"), Color.TRANSPARENT, 0, 7))
		bar.add_theme_stylebox_override("fill", UI.style(COLORS[i], Color.TRANSPARENT, 0, 7))
		card.add_child(bar)
		bar.position = Vector2(136,13)
		bar.size = Vector2(46,6)
		bars[id] = bar
	values = _values
	refresh()
func set_state(state: Dictionary) -> void:
	_state = state.duplicate(true)
	if is_node_ready(): refresh()
func set_practice(_value: bool) -> void: pass
func set_show_robot_bar(_value: bool) -> void: pass
func set_mode(value: String) -> void:
	_mode = value
	if is_node_ready(): refresh()
func refresh() -> void:
	for id in IDS:
		var value: Dictionary = _state.get(id, {"value": 0, "max": 100})
		var ratio = clampf(float(value.value) / maxf(float(value.max), 1.0), 0, 1)
		bars[id].value = ratio * 100
		_labels[id].text = tr("hud." + id + ".nombre")
		if id == "oxigeno": _labels[id].text = _labels[id].text.replace(" (4)","")
		_values[id].text = "%d%%" % roundi(ratio * 100)
		resource_buttons[id].tooltip_text = tr("hud." + id + ".help")
		resource_buttons[id].add_theme_stylebox_override("normal", UI.style(Color.TRANSPARENT, Color("#ff927a") if ratio <= 0.2 else Color.TRANSPARENT, 2 if ratio <= 0.2 else 0,8))
		if _target == "resource:"+id:
			resource_buttons[id].add_theme_stylebox_override("normal", UI.style(Color("#22475d"),UI.GOLD,3))
	var clock = Clock.display(_state)
	_clock.text = tr("live.hours").format(clock)
	_phase_icon.kind = "sun" if Clock.is_day(_state) else "moon"
	_phase_icon.tint = UI.GOLD if Clock.is_day(_state) else UI.CYAN
	_phase_icon.queue_redraw()
	_clock.add_theme_font_size_override("font_size",15)
	_clock.tooltip_text = "%d / %d / %d" % [int(clock.day), int(clock.month), int(clock.year)]
	if tutorial_layout:
		_cargo.text = "%s %d/10   %s %d" % [tr("live.ice"),int(_state.get("hielo",0)),tr("live.stars"),int(_state.get("estrellas",0))]
		return
	_cargo.text = "%s %d/10   %s %d   %s" % [tr("live.ice"), int(_state.get("hielo", 0)), tr("live.stars"), int(_state.get("estrellas", 0)), tr("mode." + _mode)]

func set_target(target: String) -> void:
	_target = target
	if is_node_ready(): refresh()

func focus_target() -> void:
	var id := _target.get_slice(":",1)
	if resource_buttons.has(id): resource_buttons[id].grab_focus()
