extends Control
signal section_requested(section: String)
signal utility_requested(action: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const ITEMS := [["construction","construction"],["expedition","ice"],["processing","agua"],["repair","repair"],["rest","robot_battery"],["missions","missions"],["upgrades","upgrades"],["science","science"],["messages","messages"]]
const PRIMARY := ["construction","expedition","repair","missions"]
var buttons: Dictionary = {}
var utility_buttons: Dictionary = {}
var _attention := ""
var _current := ""
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(452,68)
	UI.panel(self,Rect2(Vector2.ZERO,size),Color("#101e34ed"),18).mouse_filter = MOUSE_FILTER_STOP
	for i in 5:
		var id: String = PRIMARY[i] if i < 4 else "more"
		var button = UI.button(self,"",Rect2(6+i*88,5,86,58),section_requested.emit.bind(id) if i < 4 else utility_requested.emit.bind("more"))
		button.name = "Station_"+id
		var icon = Icon.new()
		icon.kind = {"construction":"construction","expedition":"ice","repair":"repair","missions":"missions"}.get(id,"more")
		icon.disc = false
		icon.tint = UI.CYAN
		icon.size = Vector2(24,24)
		icon.position = Vector2(31,6)
		button.add_child(icon)
		var caption = UI.label(button,"",Rect2(2,32,82,22),13,UI.WHITE,true)
		caption.name = "Caption"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if i < 4: buttons[id] = button
		else: utility_buttons.more = button
	refresh()
func refresh() -> void:
	var selected: String = _attention if not _attention.is_empty() else _current
	for id in buttons:
		buttons[id].get_node("Caption").text = tr("nav.dock."+id)
		_paint(buttons[id],id == selected)
	if utility_buttons.has("more"):
		utility_buttons.more.get_node("Caption").text = tr("nav.more")
		_paint(utility_buttons.more,not selected.is_empty() and not PRIMARY.has(selected))
func _paint(button: Button, selected: bool) -> void:
	UI.paint(button)
	button.add_theme_stylebox_override("normal",UI.style(Color("#243a50a0") if selected else Color.TRANSPARENT,UI.GOLD if selected else Color.TRANSPARENT,2 if selected else 0,12))
	button.get_child(0).tint = UI.GOLD if selected else UI.CYAN
	button.get_child(0).queue_redraw()
func set_attention(id: String) -> void:
	_attention = id
	if is_node_ready(): refresh()

func set_current(id: String) -> void:
	_current = id
	if is_node_ready(): refresh()
