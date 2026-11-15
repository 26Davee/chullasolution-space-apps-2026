extends SubViewportContainer
## UI preview only: instances P3's scene without editing it or adding gameplay.
@export_file("*.tscn", "*.glb", "*.gltf") var model_path := "res://assets/3d/astronauta.tscn"
@export_range(0.01, 5.0) var model_scale := 1.0
var _model: Node3D
@export_range(0.0, 180.0) var rotation_speed := 55.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    stretch = true
    var viewport := SubViewport.new()
    viewport.size = Vector2i(maxi(int(size.x), 2), maxi(int(size.y), 2))
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    viewport.handle_input_locally = false
    add_child(viewport)
    var world := Node3D.new()
    viewport.add_child(world)
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_CLEAR_COLOR
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("#b8d5f1")
    settings.ambient_light_energy = 0.8
    environment.environment = settings
    world.add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -35, 0)
    light.light_energy = 1.7
    world.add_child(light)
    if not ResourceLoader.exists(model_path):
        push_warning("Astronaut model not found: " + model_path)
        return
    var scene := load(model_path) as PackedScene
    if scene == null:
        return
    var instance := scene.instantiate()
    if not instance is Node3D:
        instance.free()
        push_warning("Astronaut scene needs a Node3D root: " + model_path)
        return
    _model = instance as Node3D
    _model.scale *= model_scale
    world.add_child(_model)
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.position = Vector3(0.1, 1.15, -3.4)
    camera.look_at(Vector3(0, 0.95, 0))
    camera.fov = 34

func _process(delta: float) -> void:
    if is_instance_valid(_model):
        _model.rotate_y(deg_to_rad(rotation_speed) * delta)
