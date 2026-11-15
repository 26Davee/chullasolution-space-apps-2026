extends Control
var points: Array[Vector2] = []
var patched: Dictionary = {}
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _draw() -> void:
	for i in points.size():
		var c: Vector2 = points[i]
		if patched.has(i):
			draw_arc(c,37,0,TAU,32,Color("#59e0dc"),3,true)
		else:
			var color := Color("#ff927a")
			draw_polyline(PackedVector2Array([c+Vector2(-46,-32),c+Vector2(-32,-12),c+Vector2(-44,4),c+Vector2(-30,27),c+Vector2(-36,44)]),color,3,true)
			draw_polyline(PackedVector2Array([c+Vector2(31,-39),c+Vector2(42,-18),c+Vector2(32,6),c+Vector2(44,26)]),color,3,true)
