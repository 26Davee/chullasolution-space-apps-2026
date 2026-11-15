extends Node3D

## Collectible supply pod dropped from orbit when dome expansion upgrades unlock new modules.
const StationBindings := preload("res://interaction/station_bindings.gd")

var drop_id: String = ""
var piece_id: String = ""
var landed: bool = false
var target_position: Vector3 = Vector3.ZERO

var _built: bool = false
var _pending_animate: bool = false
var _pod: Node3D
var _chute: MeshInstance3D
var _label: Label3D
var _ring: MeshInstance3D
var _bob_t: float = 0.0


func _ready() -> void:
	_ensure_visuals()
	if _pending_animate:
		_pending_animate = false
		_play_drop_tween()


func _ensure_visuals() -> void:
	if _built:
		return
	_built = true
	_pod = Node3D.new()
	_pod.name = "PodBody"
	add_child(_pod)

	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.62
	cyl.bottom_radius = 0.78
	cyl.height = 1.25
	body.mesh = cyl
	body.position.y = 0.65
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.95, 1.0)
	mat.metallic = 0.35
	mat.roughness = 0.35
	body.material_override = mat
	_pod.add_child(body)

	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.42
	cap_mesh.bottom_radius = 0.64
	cap_mesh.height = 0.35
	cap.mesh = cap_mesh
	cap.position.y = 1.42
	var accent := StandardMaterial3D.new()
	accent.albedo_color = Color(0.24, 0.84, 0.95)
	accent.emission_enabled = true
	accent.emission = Color(0.18, 0.72, 0.92)
	accent.emission_energy_multiplier = 1.6
	cap.material_override = accent
	_pod.add_child(cap)

	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.1
	_ring.mesh = torus
	_ring.position.y = 0.1
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.28, 0.92, 0.78)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.24, 0.9, 0.75)
	ring_mat.emission_energy_multiplier = 2.0
	_ring.material_override = ring_mat
	add_child(_ring)

	_chute = MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 1.55
	dome.height = 1.4
	dome.is_hemisphere = true
	_chute.mesh = dome
	_chute.position.y = 2.9
	var chute_mat := StandardMaterial3D.new()
	chute_mat.albedo_color = Color(0.96, 0.54, 0.2)
	chute_mat.roughness = 0.6
	_chute.material_override = chute_mat
	add_child(_chute)

	var light := OmniLight3D.new()
	light.light_color = Color(0.35, 0.9, 1.0)
	light.light_energy = 1.8
	light.omni_range = 6.5
	light.position.y = 1.6
	add_child(light)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 2.35, 0.0)
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 38
	_label.outline_size = 8
	_label.modulate = Color(0.75, 0.98, 1.0)
	add_child(_label)

	StationBindings.bind(self, "supply_drop")


func start_drop(target_pos: Vector3, id: String, piece: String, label_text: String, immediate_landed: bool = false) -> void:
	_ensure_visuals()
	drop_id = id
	piece_id = piece
	target_position = target_pos
	set_meta("drop_id", drop_id)
	set_meta("piece_id", piece_id)
	set_meta("supply_drop_node", self)
	if is_instance_valid(_label):
		_label.text = label_text
	if immediate_landed:
		position = target_pos
		landed = true
		_pending_animate = false
		if is_instance_valid(_chute):
			_chute.visible = false
		return
	landed = false
	position = Vector3(target_pos.x, 26.0, target_pos.z)
	if is_instance_valid(_chute):
		_chute.visible = true
	if is_inside_tree():
		_play_drop_tween()
	else:
		_pending_animate = true


func _play_drop_tween() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		landed = true
		if is_instance_valid(_chute):
			_chute.visible = false
		var pulse := create_tween()
		pulse.tween_property(_pod, "scale", Vector3(1.18, 0.88, 1.18), 0.14)
		pulse.tween_property(_pod, "scale", Vector3.ONE, 0.18)
	)


func _process(delta: float) -> void:
	_bob_t += delta * 2.6
	if is_instance_valid(_label):
		_label.position.y = 2.35 + sin(_bob_t) * 0.14
	if landed and is_instance_valid(_pod):
		_pod.rotation.y += delta * 0.65
