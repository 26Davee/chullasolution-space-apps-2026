extends Node3D

@onready var camera: Camera3D = $Camara
@onready var processor: Node3D = $BaseLunar/ProcesadorHielo
@onready var actor: Node3D = $Astronauta

var show_at_game_scale := false


func _ready() -> void:
	actor.global_position = processor.to_global(Vector3(2.09, 0, -0.56))
	actor.rotation.y = processor.rotation.y + 0.30
	_frame_processor()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_P:
			processor.get_node("AnimationPlayer").play("procesar")
		KEY_6:
			show_at_game_scale = not show_at_game_scale
			_frame_processor()


func _frame_processor() -> void:
	var target := processor.to_global(Vector3(0.59, 1.1, 0))
	camera.global_position = target + processor.global_basis * Vector3(-4.1, 7.2, -5.9)
	camera.look_at(target)
	camera.size = _projected_height() / 0.06 if show_at_game_scale else 5.85


func _projected_height() -> float:
	var highest := -INF
	var lowest := INF
	for child in processor.find_children("*", "MeshInstance3D", true, false):
		var piece := child as MeshInstance3D
		for index in range(piece.mesh.get_surface_count()):
			var vertices: PackedVector3Array = piece.mesh.surface_get_arrays(index)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				var projected_y := piece.to_global(vertex).dot(camera.global_basis.y)
				highest = maxf(highest, projected_y)
				lowest = minf(lowest, projected_y)
	return highest - lowest
