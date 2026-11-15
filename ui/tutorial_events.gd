extends Control
signal completed()
signal narration_requested(text: String)
signal recovery_requested()
const UI = preload("res://ui/ui_kit.gd")
var scenario := "messages"
var mode := "cadete"
var reader: Control
var action_button: Button
var provider: Node
func _ready() -> void:
	if scenario in ["messages","letters"]:
		provider = preload("res://ui/tutorial_mailbox.gd").new()
		add_child(provider)
		reader = preload("res://ui/notification_center.gd").new()
		reader.game = provider
		reader._page = "history" if scenario == "letters" else "attention"
		reader.size = size
		reader.message_opened.connect(func(_item): completed.emit())
		reader.guide_requested.connect(func(_task,_module): completed.emit())
		reader.narration_requested.connect(narration_requested.emit)
		add_child(reader)
		return
	var art = preload("res://ui/outcome_art.gd").new()
	art.size = size
	art.kind = "victory" if scenario == "ending" else "checkpoint"
	add_child(art)
	UI.label(self,tr("flow.practice"),Rect2(0,0,size.x,32),16,UI.CYAN,true)
	var icon = preload("res://ui/ui_icon.gd").new()
	icon.kind = "star" if scenario == "ending" else "help"
	icon.tint = UI.GOLD if scenario == "ending" else UI.CYAN
	icon.position = Vector2(24,98)
	icon.size = Vector2(136,136)
	add_child(icon)
	var key: String = "tutorial.ending_demo" if scenario == "ending" else "tutorial.recovery_demo"
	UI.label(self,tr(key),Rect2(200,92,size.x-224,216),29,UI.WHITE,true)
	action_button = UI.button(self,tr("live.continue"),Rect2(200,size.y-80,size.x-224,58),func():
		if scenario == "ending": completed.emit()
		else: recovery_requested.emit()
	,true)
