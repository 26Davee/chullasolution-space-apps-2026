extends Control
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
var cards: Array = []
var _detail: Label
var _source: Label
var _selected = 0
var _buttons: Array[Button] = []
func _ready() -> void:
	UI.label(self, tr("live.choose_card"), Rect2(0, 0, size.x, 32), 20, UI.CYAN, true)
	if cards.is_empty():
		UI.label(self, tr("live.empty_science"), Rect2(90, 150, size.x - 180, 160), 26, UI.WHITE)
		return
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 48)
	scroll.size = Vector2(size.x * 0.52, size.y - 48)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	for i in cards.size():
		var button = UI.button(grid, "", Rect2(0, 0, 256, 222), _select.bind(i))
		button.custom_minimum_size = Vector2(256, 222)
		var picture = TextureRect.new()
		picture.texture = load("res://assets/ui/activities/"+str(cards[i].get("art","solar"))+"-v1.png")
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.position = Vector2(8,8)
		picture.size = Vector2(240,132)
		button.add_child(picture)
		var icon = Icon.new()
		icon.kind = "pin"
		icon.tint = UI.GOLD
		icon.disc = false
		icon.position = Vector2(112, 4)
		icon.size = Vector2(32, 32)
		button.add_child(icon)
		UI.label(button, str(cards[i].titulo), Rect2(16, 150, 224, 64), 21, UI.WHITE, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_buttons.append(button)
	var x = size.x * 0.56
	var panel = UI.panel(self, Rect2(x, 48, size.x - x, size.y - 48), Color("#193750"), 20)
	var detail_scroll = ScrollContainer.new()
	detail_scroll.position = Vector2(22, 22)
	detail_scroll.size = Vector2(panel.size.x - 44, panel.size.y - 112)
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(detail_scroll)
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 24)
	detail_scroll.add_child(col)
	_detail = UI.label(col, "", Rect2(0, 0, panel.size.x - 56, 300), 23, UI.WHITE)
	_detail.custom_minimum_size.x = panel.size.x - 64
	_source = UI.label(col, "", Rect2(0, 0, panel.size.x - 56, 80), 15, UI.CYAN)
	_source.custom_minimum_size.x = panel.size.x - 64
	var button = UI.button(panel, tr("live.repeat"), Rect2(22, panel.size.y - 72, panel.size.x - 44, 48), func(): narration_requested.emit(_detail.text), true)
	button.add_theme_font_size_override("font_size", 19)
	_select(0)
func _select(index: int) -> void:
	_selected = index
	for i in _buttons.size():
		UI.paint(_buttons[i])
		if i == index: _buttons[i].add_theme_stylebox_override("normal",UI.style(Color("#193750"),UI.GOLD,3))
	_detail.text = str(cards[index].titulo) + "\n\n" + str(cards[index].dato)
	_source.text = tr("live.source").format({"source": cards[index].get("fuente", "")})
