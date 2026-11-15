extends SubViewportContainer
## Menu/tutorial backdrop uses the same scenes and materials as the playable world.
var viewport: SubViewport
var scene: Node3D
var camera: Camera3D
var pilot: Node3D
var _time := 0.0
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	stretch = true
	size = Vector2(1280,720)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280,720)
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	scene = Node3D.new()
	viewport.add_child(scene)
	var world = load("res://world/moon_world.tscn").instantiate()
	scene.add_child(world)
	pilot = load("res://assets/3d/robot_humanoide.tscn").instantiate()
	scene.add_child(pilot)
	pilot.position = Vector3(-3.6,0,9.6)
	var timmy = load("res://assets/3d/vicuna.tscn").instantiate()
	scene.add_child(timmy)
	timmy.position = Vector3(-5.6,0,10)
	camera = Camera3D.new()
	camera.fov = 52
	scene.add_child(camera)
	camera.position = Vector3(19,15,28)
	camera.look_at(Vector3(-2,1,4))
func _process(delta: float) -> void:
	if is_instance_valid(viewport): viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	_time += delta
	if is_instance_valid(camera):
		camera.position.x = 19 + sin(_time*0.12)*1.8
		camera.look_at(Vector3(-2,1,4))
