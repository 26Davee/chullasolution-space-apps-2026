extends Control
signal midpoint()
signal finished()
const UI = preload("res://ui/ui_kit.gd")
var kind := "checkpoint"
var message := ""
func _ready() -> void:
	size = Vector2(1280,720)
	mouse_filter = MOUSE_FILTER_STOP
	z_index = 200
	var shade := ColorRect.new()
	shade.color = Color("#031122")
	shade.size = size
	add_child(shade)
	var art := preload("res://ui/outcome_art.gd").new()
	art.kind = "checkpoint"
	art.size = size
	add_child(art)
	var icon := preload("res://ui/ui_icon.gd").new()
	icon.kind = "checkpoint" if kind == "checkpoint" else "repair"
	icon.tint = UI.CYAN
	icon.position = Vector2(568,220)
	icon.size = Vector2(144,144)
	add_child(icon)
	UI.label(self,message,Rect2(240,400,800,100),36,UI.WHITE,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self,"modulate:a",1.0,0.38)
	tween.tween_callback(func(): midpoint.emit())
	tween.tween_interval(0.7)
	tween.tween_property(self,"modulate:a",0.0,0.42)
	tween.tween_callback(func(): finished.emit(); queue_free())
