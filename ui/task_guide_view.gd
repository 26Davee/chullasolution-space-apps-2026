extends Control
signal repeat_requested()
signal stop_requested()
const UI = preload("res://ui/ui_kit.gd")
var _portrait: TextureRect
var _title: Label
var _speech: Label
var _repeat: Button
var _stop: Button
var _panel: Panel
var _compact := false
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 90
	_panel = UI.panel(self,Rect2(0,0,408,174),Color("#071b32f7"),18)
	_panel.mouse_filter = MOUSE_FILTER_STOP
	_portrait = TextureRect.new()
	_portrait.texture = load("res://assets/ui/timmy.png")
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_title = UI.label(self,"",Rect2(106,10,290,24),16,UI.GOLD,true)
	_speech = UI.label(self,"",Rect2(106,40,290,90),17,UI.WHITE)
	_repeat = UI.button(self,tr("v2.repeat"),Rect2(106,136,136,28),repeat_requested.emit)
	_stop = UI.button(self,tr("flow.stop_guide"),Rect2(254,136,140,28),stop_requested.emit)
	_repeat.add_theme_font_size_override("font_size",13)
	_stop.add_theme_font_size_override("font_size",13)
	set_compact(false,408)
	hide()
func set_compact(compact: bool, width: float) -> void:
	_compact = compact
	_stop.text = tr("live.close" if compact else "flow.stop_guide")
	if compact:
		size = Vector2(width,66)
		_panel.size = size
		_portrait.position = Vector2(4,0)
		_portrait.size = Vector2(64,66)
		_title.position = Vector2(76,3)
		_title.size = Vector2(width-220,22)
		_speech.position = Vector2(76,27)
		_speech.size = Vector2(width-220,36)
		_speech.add_theme_font_size_override("font_size",16)
		_repeat.position = Vector2(width-132,6)
		_repeat.size = Vector2(120,24)
		_stop.position = Vector2(width-132,36)
		_stop.size = Vector2(120,24)
	else:
		size = Vector2(408,174)
		_panel.size = size
		_portrait.position = Vector2(0,16)
		_portrait.size = Vector2(100,154)
		_title.position = Vector2(106,10)
		_title.size = Vector2(290,24)
		_speech.position = Vector2(106,40)
		_speech.size = Vector2(290,90)
		_speech.add_theme_font_size_override("font_size",17)
		_repeat.position = Vector2(106,136)
		_repeat.size = Vector2(136,28)
		_stop.position = Vector2(254,136)
		_stop.size = Vector2(140,28)
func present(title: String, speech: String) -> void:
	_title.text = title
	_speech.text = speech
	_repeat.text = tr("v2.repeat")
	_stop.text = tr("live.close" if _compact else "flow.stop_guide")
	show()
