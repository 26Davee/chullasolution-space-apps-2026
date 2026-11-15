extends Control
signal recharge_requested()
signal return_requested()
signal completed()
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
var training := false
var near_dome := true
var battery := 35.0
var _busy := false
var _value: Label
var _bar: ProgressBar
var _status: Label
var _return: Button
var _charge: Button
func _ready() -> void:
	var model = preload("res://ui/astronaut_preview.gd").new()
	model.model_path = "res://assets/3d/robot_humanoide.tscn"
	model.position = Vector2(0,0)
	model.size = Vector2(118,164)
	add_child(model)
	UI.label(self,tr("hud.energia_robot.nombre"),Rect2(136,22,size.x-136,30),20,UI.CYAN,true)
	_value = UI.label(self,"",Rect2(136,66,size.x-136,44),30,UI.GOLD,true)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.position = Vector2(136,122)
	_bar.size = Vector2(size.x-136,14)
	_bar.add_theme_stylebox_override("background",UI.style(Color("#34445d")))
	_bar.add_theme_stylebox_override("fill",UI.style(Color("#b4a4ff")))
	add_child(_bar)
	_status = UI.label(self,"",Rect2(0,184,size.x,72),19,UI.WHITE)
	_return = UI.button(self,tr("live.return_dome"),Rect2(0,280,size.x,48),_go_home)
	_charge = UI.button(self,tr("live.rest"),Rect2(0,344,size.x,50),_recharge,true)
	_refresh()
func _refresh() -> void:
	_value.text = "%d %%" % roundi(battery)
	_bar.value = battery
	_status.text = tr("tutorial.charge_ready" if near_dome else "tutorial.charge_return")
	_return.disabled = near_dome or _busy
	_charge.disabled = not near_dome or _busy
func _go_home() -> void:
	if training:
		near_dome = true
		_refresh()
		narration_requested.emit(_status.text)
	else: return_requested.emit()
func _recharge() -> void:
	if not near_dome or _busy: return
	if not training: recharge_requested.emit(); return
	_busy = true
	_refresh()
	var charge = create_tween()
	charge.tween_method(func(value: float): battery = value; _value.text = "%d %%" % roundi(value); _bar.value = value,battery,100.0,1.0)
	charge.tween_callback(func():
		_status.text = tr("task.finish.recharge")
		narration_requested.emit(_status.text)
		completed.emit()
	)
