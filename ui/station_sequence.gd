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
var _busy := false
func _ready() -> void:
	UI.label(self,tr("flow.practice" if training else "flow.real"),Rect2(0,0,size.x,30),16,UI.CYAN,true)
	var left_width := size.x*0.56
	_picture = TextureRect.new()
	_picture.texture = load("res://assets/ui/activities/"+("processor" if section == "processing" else "repair")+"-v1.png")
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.position = Vector2(0,46)
	_picture.size = Vector2(left_width,size.y-100)
	_picture.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_picture)
	var side := left_width+24
	var width := size.x-side
	UI.panel(self,Rect2(side,46,width,size.y-46),Color("#102b46"),18)
	UI.label(self,tr("live."+section),Rect2(side+18,62,width-36,48),26,UI.GOLD,true)
	if section == "processing":
		for i in 3:
			var button = UI.button(self,"",Rect2(side+18,124+i*68,width-36,54),_process_action.bind(i))
			button.add_theme_font_size_override("font_size",18)
			_process_buttons.append(button)
		_feedback = UI.label(self,"",Rect2(side+18,336,width-36,size.y-400),18,UI.WHITE)
		_refresh_processing()
	else:
		for i in 3:
			var point := Vector2(left_width*(0.45+0.13*i),134+i*82)
			var button = UI.button(self,str(i+1),Rect2(point,Vector2(58,58)),_patch.bind(i),true)
			_patch_buttons.append(button)
		_feedback = UI.label(self,tr("flow.repair_order"),Rect2(side+18,124,width-36,110),22,UI.WHITE)
		_shield_value = UI.label(self,"",Rect2(side+18,260,width-36,40),26,UI.CYAN,true)
		_shield_bar = ProgressBar.new()
		_shield_bar.show_percentage = false
		add_child(_shield_bar)
		_shield_bar.position = Vector2(side+18,310)
		_shield_bar.size = Vector2(width-36,20)
		_refresh_repair()
	if not allowed: _feedback.text = blocked_reason
	if training: UI.button(self,tr("visual.try_again"),Rect2(side+18,size.y-56,width-36,42),_reset)
func _refresh_processing() -> void:
	for i in _process_buttons.size():
		_process_buttons[i].text = (tr("flow.done")+"  " if i < _process_step else str(i+1)+"  ")+tr("visual.process.step."+str(i))
		_process_buttons[i].disabled = not allowed or _busy or i != _process_step
		UI.paint(_process_buttons[i],i == _process_step)
	if allowed:
		_feedback.text = tr("visual.process.start") if _process_step == 0 else tr("visual.process.result."+str(_process_step-1))
func _process_action(index: int) -> void:
	if not allowed or _busy or index != _process_step: return
	_process_step += 1
	_refresh_processing()
	step_performed.emit(section,index)
	narration_requested.emit(_feedback.text)
	if _process_step == 3: completed.emit()
func _refresh_repair() -> void:
	for i in _patch_buttons.size():
		_patch_buttons[i].disabled = not allowed or i != _patched.size()
		_patch_buttons[i].text = tr("flow.done") if _patched.has(i) else str(i+1)
		UI.paint(_patch_buttons[i],i == _patched.size())
	var amount := minf(25.0,100.0-initial_shield)
	var value := initial_shield+amount*_patched.size()/3.0
	_shield_bar.value = value
	_shield_value.text = "%d %% → %d %%" % [roundi(initial_shield),roundi(minf(100,initial_shield+25))]
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
