extends Control
signal solve_requested(task: String)
signal center_requested()
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
var _queue: Array = []
var current: Dictionary = {}
var _remaining := 0.0
var _panel: Panel
var _icon: Control
var _title: Label
var _body: Label
var _solve: Button
var blocked := false
func _ready() -> void:
	position = Vector2(430,146)
	size = Vector2(666,100)
	mouse_filter = MOUSE_FILTER_IGNORE
	_panel = UI.panel(self,Rect2(Vector2.ZERO,size),Color("#322518f7"),16)
	_panel.mouse_filter = MOUSE_FILTER_STOP
	_icon = Icon.new()
	_icon.position = Vector2(14,24)
	_icon.size = Vector2(48,48)
	_icon.tint = UI.GOLD
	add_child(_icon)
	_title = UI.label(self,"",Rect2(78,10,392,28),21,UI.GOLD,true)
	_body = UI.label(self,"",Rect2(78,44,392,44),16,UI.WHITE)
	_solve = UI.button(self,tr("flow.fix_now"),Rect2(488,26,142,48),func(): solve_requested.emit(str(current.get("task","water"))),true)
	_solve.add_theme_font_size_override("font_size",17)
	var close = UI.button(self,"",Rect2(626,8,32,32),dismiss_current)
	close.tooltip_text = tr("live.close")
	for state in ["normal","hover","pressed","focus"]:
		var box = close.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 4
		box.content_margin_right = 4
		close.add_theme_stylebox_override(state,box)
	var cross = Icon.new()
	cross.kind = "close"
	cross.disc = false
	cross.tint = UI.WHITE
	cross.position = Vector2(6,6)
	cross.size = Vector2(20,20)
	close.add_child(cross)
	hide()
func publish(id: String, title: String, text: String, icon: String, task: String, urgent := false) -> void:
	if str(current.get("id","")) == id: return
	for item in _queue:
		if str(item.id) == id: return
	var item := {"id":id,"title":title,"text":text,"icon":icon,"task":task,"urgent":urgent}
	if urgent:
		if not current.is_empty() and not bool(current.get("urgent",false)):
			_queue.append(current.duplicate())
			dismiss_current()
		_queue.push_front(item)
	else: _queue.append(item)
func dismiss(id: String) -> void:
	_queue = _queue.filter(func(item): return str(item.id) != id)
	if str(current.get("id","")) == id: dismiss_current()
func dismiss_current() -> void:
	current = {}
	_remaining = 0
	hide()
func _process(delta: float) -> void:
	if blocked: hide(); return
	if current.is_empty() and not _queue.is_empty():
		current = _queue.pop_front()
		_remaining = 10
		_title.text = str(current.title)
		_body.text = str(current.text)
		_solve.visible = not str(current.task).is_empty()
		_icon.kind = str(current.icon)
		_icon.tint = Color("#ff927a") if current.urgent else (UI.CYAN if current.icon == "checkpoint" else UI.GOLD)
		_icon.queue_redraw()
		_panel.add_theme_stylebox_override("panel",UI.style(Color("#32231bf7"),_icon.tint,3,16))
		modulate.a = 0
		create_tween().tween_property(self,"modulate:a",1.0,0.25)
	if not current.is_empty():
		show()
		_remaining -= delta
		if _remaining <= 0: dismiss_current()

func clear() -> void:
	_queue.clear()
	dismiss_current()
