extends Control
signal confirmed(nickname: String, age_group: String)
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
var model_path := "res://assets/3d/robot_humanoide.tscn"
var name_field: LineEdit
var age_buttons: Dictionary = {}
var continue_button: Button
var avatar: Control
var _age := ""
var _hint: Label
func _ready() -> void:
	size = Vector2(1280,720)
	add_child(preload("res://ui/world_backdrop.gd").new())
	var timmy = TextureRect.new()
	timmy.texture = load("res://assets/ui/timmy.png")
	timmy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	timmy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	timmy.position = Vector2(64,250)
	timmy.size = Vector2(280,390)
	timmy.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(timmy)
	UI.panel(self,Rect2(384,84,832,602),Color("#071b32f7"),24)
	UI.label(self,tr("setup.title"),Rect2(416,110,768,52),34,UI.GOLD,true)
	UI.label(self,tr("setup.body"),Rect2(416,170,516,72),21,UI.WHITE)
	UI.label(self,tr("setup.name"),Rect2(416,250,444,26),18,UI.CYAN,true)
	name_field = LineEdit.new()
	name_field.position = Vector2(416,286)
	name_field.size = Vector2(444,50)
	name_field.max_length = 18
	name_field.placeholder_text = tr("v2.name_placeholder")
	name_field.add_theme_font_size_override("font_size",21)
	name_field.add_theme_stylebox_override("normal",UI.style(Color("#16354f"),Color("#7b9fb9"),1))
	name_field.add_theme_stylebox_override("focus",UI.style(Color("#16354f"),UI.CYAN,2))
	add_child(name_field)
	name_field.text_changed.connect(func(_text): _refresh())
	name_field.text_submitted.connect(func(_text): _confirm())
	avatar = preload("res://ui/astronaut_preview.gd").new()
	avatar.model_path = model_path
	avatar.position = Vector2(956,180)
	avatar.size = Vector2(208,160)
	add_child(avatar)
	UI.label(self,tr("setup.age"),Rect2(416,354,768,30),21,UI.CYAN,true)
	for i in 2:
		var id: String = ["7_9","10_12"][i]
		var button = UI.button(self,"",Rect2(416+i*392,394,376,150),_choose_age.bind(id))
		button.name = "Age_"+id
		UI.label(button,"7–9" if i == 0 else "10–12",Rect2(16,8,344,36),29,UI.GOLD,true)
		UI.label(button,tr("mode.cadete" if i == 0 else "mode.ingeniero"),Rect2(16,50,344,32),23,UI.CYAN,true)
		UI.label(button,tr("setup.cadet" if i == 0 else "setup.engineer"),Rect2(16,92,344,48),16,UI.WHITE)
		age_buttons[id] = button
	continue_button = UI.button(self,tr("setup.continue"),Rect2(416,578,768,56),_confirm,true)
	_hint = UI.label(self,"",Rect2(416,646,768,26),15,UI.CYAN)
	var controls: Array[Control] = [name_field,age_buttons["7_9"],age_buttons["10_12"],continue_button]
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i+1)%controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i-1,controls.size())])
	_refresh()
	name_field.grab_focus()
func _choose_age(id: String) -> void:
	_age = id
	_refresh()
	narration_requested.emit(tr("setup.cadet" if id == "7_9" else "setup.engineer"))
func _refresh() -> void:
	var valid_name := not name_field.text.replace("<","").replace(">","").replace("&","").strip_edges().is_empty()
	continue_button.disabled = not valid_name or _age.is_empty()
	_hint.text = tr("setup.hint") if continue_button.disabled else tr("setup.ready")
	for id in age_buttons:
		UI.paint(age_buttons[id])
		if id == _age:
			age_buttons[id].add_theme_stylebox_override("normal",UI.style(Color("#234359"),UI.GOLD,3))
			age_buttons[id].add_theme_stylebox_override("hover",UI.style(Color("#2c5369"),UI.GOLD,3))
			age_buttons[id].add_theme_stylebox_override("focus",UI.style(Color.TRANSPARENT,UI.GOLD,3))
func _confirm() -> void:
	if continue_button.disabled: return
	confirmed.emit(name_field.text,_age)
