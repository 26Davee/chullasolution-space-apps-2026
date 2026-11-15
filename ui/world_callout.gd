extends Panel
## Tarjeta flotante anclada a una posición 3D en el mundo lunar.
signal closed()

const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")

var world_pos := Vector3.ZERO
var tracking := false
var card_width := 256.0

var _icon: Icon
var _title: Label
var _body: Label
var _bar: ProgressBar
var _buttons_row: HBoxContainer
var _close_btn: Button
var _body_box: VBoxContainer
var _content_ready := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_theme_stylebox_override("panel", UI.style(Color("#0c1c31f0"), Color(0.48, 0.77, 0.84, 0.42), 1, 14))
	_build_shell()


func _build_shell() -> void:
	_body_box = VBoxContainer.new()
	_body_box.position = Vector2(14, 12)
	_body_box.size = Vector2(card_width - 28, 10)
	_body_box.add_theme_constant_override("separation", 7)
	add_child(_body_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	_body_box.add_child(header)

	_icon = Icon.new()
	_icon.disc = false
	_icon.tint = UI.CYAN
	_icon.custom_minimum_size = Vector2(18, 18)
	_icon.size = Vector2(18, 18)
	header.add_child(_icon)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", UI.WHITE)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(_title)

	_close_btn = Button.new()
	_close_btn.text = "×"
	_close_btn.custom_minimum_size = Vector2(22, 22)
	_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_btn.add_theme_font_size_override("font_size", 14)
	_close_btn.add_theme_stylebox_override("normal", UI.style(Color("#193048"), Color("#536e87"), 1, 6))
	_close_btn.pressed.connect(func():
		hide()
		closed.emit()
	)
	header.add_child(_close_btn)

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 13)
	_body.add_theme_color_override("font_color", Color("#d3e1ee"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_box.add_child(_body)

	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.custom_minimum_size = Vector2(card_width - 28, 6)
	_bar.add_theme_font_size_override("font_size", 1)
	_bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 3))
	_bar.add_theme_stylebox_override("fill", UI.style(UI.CYAN, Color.TRANSPARENT, 0, 3))
	_body_box.add_child(_bar)

	_buttons_row = HBoxContainer.new()
	_buttons_row.add_theme_constant_override("separation", 8)
	_body_box.add_child(_buttons_row)
	_content_ready = true


func configure(cfg: Dictionary) -> void:
	if not _content_ready:
		return
	card_width = float(cfg.get("width", 256.0))
	_body_box.custom_minimum_size.x = card_width - 28
	_body_box.size.x = card_width - 28

	_icon.kind = str(cfg.get("icon", "base"))
	_icon.tint = cfg.get("tint", UI.CYAN)
	_icon.queue_redraw()
	_title.text = str(cfg.get("title", ""))

	var body_text := str(cfg.get("body", ""))
	_body.visible = not body_text.is_empty()
	_body.text = body_text
	_body.add_theme_color_override("font_color", cfg.get("body_color", Color("#d3e1ee")))

	var show_bar := bool(cfg.get("show_bar", false))
	_bar.visible = show_bar
	if show_bar:
		_bar.max_value = 100.0
		_bar.value = clampf(float(cfg.get("progress", 0.0)), 0.0, 100.0)
		_bar.add_theme_stylebox_override("fill", UI.style(cfg.get("bar_color", UI.CYAN), Color.TRANSPARENT, 0, 3))

	_close_btn.visible = bool(cfg.get("closable", false))

	for child in _buttons_row.get_children():
		child.queue_free()
	var actions: Array = cfg.get("actions", [])
	_buttons_row.visible = not actions.is_empty()
	for action in actions:
		var btn := Button.new()
		btn.text = str(action.get("text", ""))
		btn.disabled = bool(action.get("disabled", false))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if actions.size() > 1 or bool(action.get("expand", true)) else Control.SIZE_SHRINK_BEGIN
		btn.add_theme_font_size_override("font_size", 13)
		var is_primary := bool(action.get("primary", false))
		if is_primary:
			UI.paint(btn, true)
			btn.add_theme_stylebox_override("normal", UI.style(UI.GOLD, Color.TRANSPARENT, 0, 10))
		else:
			UI.paint(btn, false)
			btn.add_theme_stylebox_override("normal", UI.style(Color("#152a42"), Color("#536e87"), 1, 10))
		var cb: Callable = action.get("callback", Callable())
		if cb.is_valid():
			btn.pressed.connect(cb)
		_buttons_row.add_child(btn)

	world_pos = cfg.get("world_pos", Vector3.ZERO)
	tracking = true
	var min_size := _body_box.get_combined_minimum_size()
	size = Vector2(card_width, min_size.y + 24.0)
	visible = true


func update_screen_position(camera: Camera3D, y_offset: float = -18.0) -> void:
	if not visible or not tracking or camera == null or not is_instance_valid(camera):
		return
	if camera.is_position_behind(world_pos):
		return
	var projected := camera.unproject_position(world_pos)
	var min_size := _body_box.get_combined_minimum_size()
	size = Vector2(card_width, min_size.y + 24.0)
	var x := clampf(projected.x - size.x * 0.5, 16.0, 1280.0 - size.x - 16.0)
	var y := clampf(projected.y - size.y + y_offset, 68.0, 622.0 - size.y)
	position = Vector2(x, y)
