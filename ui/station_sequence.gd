extends Control
## Exactly the same ordered controls are used by practice and live actions.
signal completed()
signal step_performed(section: String, index: int)
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
var section := "processing"
var training := true
var initial_shield := 35.0
var allowed := true
var blocked_reason := ""
var _process_step := 0
var _process_buttons: Array[Button] = []
var _patch_buttons: Array[Button] = []
var _patched: Dictionary = {}
var _feedback: Label
var _shield_bar: ProgressBar
var _shield_value: Label
var _picture: TextureRect
var _compact := false
var _busy := false
var _shield_tween: Tween
var _repair_marks: Control
var _patch_icons: Array[Control] = []
var _flow_icons: Array[Control] = []
func _ready() -> void:
	_compact = size.y < 400
	UI.label(self,tr("flow.practice" if training else "flow.real"),Rect2(0,0,size.x,30),16,UI.CYAN,true)
	var left_width := size.x*0.56
	_picture = TextureRect.new()
	_picture.texture = load("res://assets/ui/activities/"+("processor" if section == "processing" else "repair")+"-v1.png")
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.position = Vector2(0,46)
	_picture.size = Vector2(left_width,size.y-(148 if section == "processing" else 104) if _compact else size.y-(148 if section == "processing" else 100))
	_picture.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_picture)
	var side := left_width+24
	var width := size.x-side
	UI.panel(self,Rect2(side,46,width,size.y-46),Color("#102b46"),18)
	UI.label(self,tr("live."+section),Rect2(side+18,54,width-36,38),21 if _compact else 26,UI.GOLD,true)
	if section == "processing":
		for i in 3:
			var symbol = Icon.new()
			symbol.kind = ["ice","energia","agua"][i]
			symbol.position = Vector2(left_width*(0.15+i*0.32)-20,size.y-74)
			symbol.size = Vector2(40,40)
			add_child(symbol)
			_flow_icons.append(symbol)
			if i < 2: UI.label(self,"→",Rect2(left_width*(0.29+i*0.32),size.y-76,40,40),28,UI.GOLD,true)
		for i in 3:
			var button = UI.button(self,"",Rect2(side+18,(94 if _compact else 124)+i*(56 if _compact else 68),width-36,46 if _compact else 54),_process_action.bind(i))
			button.add_theme_font_size_override("font_size",16 if _compact else 18)
			_process_buttons.append(button)
		_feedback = UI.label(self,"",Rect2(side+18,268 if _compact else 336,width-36,54 if _compact else size.y-400),15 if _compact else 18,UI.WHITE)
		_refresh_processing()
	else:
		_repair_marks = preload("res://ui/repair_marks.gd").new()
		_repair_marks.size = _picture.size
		_repair_marks.position = _picture.position
		add_child(_repair_marks)
		for i in 3:
			var uv: Vector2 = [Vector2(0.515,0.29),Vector2(0.67,0.455),Vector2(0.476,0.63)][i]
			var button_size := 44.0 if _compact else 58.0
			var point: Vector2 = _picture.position+_picture.size*uv-Vector2.ONE*button_size/2
			_repair_marks.points.append(_picture.size*uv)
			var button = UI.button(self,str(i+1),Rect2(point,Vector2.ONE*button_size),_patch.bind(i),true)
			button.tooltip_text = tr("visual.repair.patch")+" "+str(i+1)
			_patch_buttons.append(button)
			var check = Icon.new()
			check.kind = "check"
			check.disc = false
			check.tint = UI.INK
			check.position = Vector2.ONE*(button_size-28)/2
			check.size = Vector2(28,28)
			button.add_child(check)
			_patch_icons.append(check)
		_feedback = UI.label(self,tr("flow.repair_order"),Rect2(side+18,100 if _compact else 124,width-36,90 if _compact else 110),18 if _compact else 22,UI.WHITE)
		_shield_value = UI.label(self,"",Rect2(side+18,210 if _compact else 260,width-36,34),22 if _compact else 26,UI.CYAN,true)
		_shield_bar = ProgressBar.new()
		_shield_bar.show_percentage = false
		_shield_bar.add_theme_stylebox_override("background",UI.style(Color("#34445d")))
		_shield_bar.add_theme_stylebox_override("fill",UI.style(UI.CYAN))
		add_child(_shield_bar)
		_shield_bar.position = Vector2(side+18,258 if _compact else 310)
		_shield_bar.size = Vector2(width-36,20)
		_refresh_repair(false)
	if not allowed: _feedback.text = blocked_reason
	if training: UI.button(self,tr("visual.try_again"),Rect2(side+18,size.y-56,width-36,42),_reset)
func _refresh_processing() -> void:
	for i in _process_buttons.size():
		_process_buttons[i].text = (tr("flow.done")+"  " if i < _process_step else str(i+1)+"  ")+tr("visual.process.step."+str(i))
		_process_buttons[i].disabled = not allowed or _busy or i != _process_step
		UI.paint(_process_buttons[i],i == _process_step)
		_flow_icons[i].tint = UI.CYAN if i < _process_step else Color("#52738a")
		_flow_icons[i].queue_redraw()
	if allowed:
		_feedback.text = tr("visual.process.start") if _process_step == 0 else tr("visual.process.result."+str(_process_step-1))
func _process_action(index: int) -> void:
	if not allowed or _busy or index != _process_step: return
	_process_step += 1
	_refresh_processing()
	step_performed.emit(section,index)
	narration_requested.emit(_feedback.text)
	if _process_step == 3: completed.emit()
func _refresh_repair(animate := true) -> void:
	if _shield_tween and _shield_tween.is_running(): _shield_tween.kill()
	for i in _patch_buttons.size():
		_patch_buttons[i].disabled = not allowed or i != _patched.size()
		_patch_buttons[i].text = "" if _patched.has(i) else str(i+1)
		_patch_icons[i].visible = _patched.has(i)
		UI.paint(_patch_buttons[i],i == _patched.size())
	var amount := 100.0-initial_shield if training else minf(25.0,100.0-initial_shield)
	var value := initial_shield+amount*_patched.size()/3.0
	if animate:
		_shield_tween = create_tween()
		_shield_tween.tween_property(_shield_bar,"value",value,0.3)
	else: _shield_bar.value = value
	_shield_value.text = "%d %% → %d %%" % [roundi(value),roundi(initial_shield+amount)]
	_repair_marks.patched = _patched.duplicate()
	_repair_marks.queue_redraw()
func _patch(index: int) -> void:
	if not allowed or index != _patched.size(): return
	_patched[index] = true
	_refresh_repair()
	_feedback.text = tr("visual.repair.done") if _patched.size() == 3 else tr("visual.repair.progress").format({"count":_patched.size()})
	step_performed.emit(section,index)
	narration_requested.emit(_feedback.text)
	if _patched.size() == 3: completed.emit()
func _reset() -> void:
	_process_step = 0
	_patched.clear()
	if section == "processing": _refresh_processing()
	else:
		_refresh_repair()
		_feedback.text = tr("flow.repair_order")
func _reset_processing() -> void: _reset()
func _reset_repair() -> void: _reset()
