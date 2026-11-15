extends Control
signal section_requested(section: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const ITEMS := [["construction","construction"],["expedition","ice"],["processing","agua"],["repair","repair"],["rest","robot_battery"],["missions","missions"],["upgrades","upgrades"],["science","science"],["messages","messages"]]
const COLORS := {"construction":Color("#ffc64f"),"expedition":Color("#68b9ff"),"processing":Color("#68b9ff"),"repair":Color("#ff927a"),"rest":Color("#b4a4ff"),"missions":Color("#ffc64f"),"upgrades":Color("#b4a4ff"),"science":Color("#7fe7bf"),"messages":Color("#59e0dc")}
var buttons: Dictionary = {}
var _attention := ""
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(148,477)
	for i in ITEMS.size():
		var id: String = ITEMS[i][0]
		var button = UI.button(self,"",Rect2(0,i*53,148,46),section_requested.emit.bind(id))
		button.name = "Station_"+id
		var icon = Icon.new()
		icon.kind = ITEMS[i][1]
		icon.disc = false
		icon.tint = COLORS.get(id,UI.CYAN)
		icon.size = Vector2(24,24)
		icon.position = Vector2(10,11)
		button.add_child(icon)
		var label = UI.label(button,"",Rect2(42,4,98,38),14,UI.WHITE,true)
		label.name = "Caption"
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		buttons[id] = button
	refresh()
func refresh() -> void:
	for id in buttons:
		buttons[id].get_node("Caption").text = tr("live."+id)
		buttons[id].tooltip_text = tr("guide."+id)
		UI.paint(buttons[id])
		if id == _attention: buttons[id].add_theme_stylebox_override("normal",UI.style(Color("#22475d"),UI.GOLD,3))
func set_attention(id: String) -> void:
	_attention = id
	if is_node_ready(): refresh()
