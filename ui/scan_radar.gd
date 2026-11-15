extends Control
## Visual scan feedback; the owner commits discovery after the sweep finishes.
signal completed()
var target := Vector2.ZERO
var progress := 0.0
var scanning := false
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func start(point: Vector2) -> void:
	target = point
	progress = 0
	scanning = true
	queue_redraw()
	var sweep = create_tween()
	sweep.tween_method(func(value: float): progress = value; queue_redraw(),0.0,1.0,0.9)
	sweep.tween_callback(func(): scanning = false; queue_redraw(); completed.emit())
func _draw() -> void:
	if not scanning: return
	var color := Color(0.35,0.95,0.92,0.8)
	var radius := 28.0+progress*100
	draw_circle(target,radius,Color(0.2,0.9,0.9,0.08))
	draw_arc(target,radius,0,TAU,64,color,3,true)
	draw_arc(target,46,0,TAU,40,Color(1,0.78,0.31,0.65),2,true)
	var direction := Vector2(cos(progress*TAU),sin(progress*TAU))
	draw_line(target,target+direction*radius,color,4,true)
