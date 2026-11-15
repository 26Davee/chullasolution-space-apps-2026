extends Control
var kind := "victory"
var _time := 0.0
func _ready() -> void: mouse_filter = MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
func _draw() -> void:
	var color := Color("#ffc64f") if kind == "victory" else (Color("#59e0dc") if kind == "checkpoint" else Color("#ff927a"))
	for i in 44:
		var point := Vector2(fposmod(i*83.0+sin(_time+i)*24,maxf(size.x,1)),fposmod(i*57.0+_time*(20+i%5*9),maxf(size.y,1)))
		color.a = 0.22 if kind != "victory" else 0.5
		draw_circle(point,2.0+i%3,color)
	if kind != "victory":
		color.a = 0.15+sin(_time*2)*0.05
		draw_arc(size/2,minf(size.x,size.y)*0.36,0,TAU,80,color,3,true)
