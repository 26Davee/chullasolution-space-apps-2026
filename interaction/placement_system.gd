## Sistema de selección y colocación de piezas sobre el terreno lunar.
##
## Flujo:
##   1. Otro sistema (UI/catálogo) llama a start_placement(piece_id).
##   2. Cada frame de física se lanza un rayo desde la cámara (posición del mouse)
##      hacia el terreno. La pieza se previsualiza como holograma en el punto de impacto,
##      ajustada a la grilla.
##   3. El holograma se pinta de color "válido" (cian/verde) o "inválido" (rojo) según
##      si choca con otra pieza o si la pendiente es demasiado fuerte.
##   4. Clic izquierdo confirma (si es válido) -> emite piece_placed(piece_id, position).
##      Clic derecho / Esc cancela. R rota la pieza.
class_name PlacementSystem
extends Node3D

# --- Señales ---------------------------------------------------------------
signal piece_placed(piece_id: StringName, position: Vector3)
signal placement_started(piece_id: StringName)
signal placement_cancelled(piece_id: StringName)
signal placement_rejected(piece_id: StringName, reason: String)
signal placement_validity_changed(is_valid: bool)

enum State { IDLE, PLACING }

# --- Referencias -----------------------------------------------------------
@export var camera: Camera3D
## Nodo donde se instancian las piezas confirmadas (si spawn_on_confirm = true).
@export var placed_parent: Node3D
## Catálogo opcional: { &"modulo_habitacional": preload("res://...tscn"), ... }
@export var piece_catalog: Dictionary = {}

# --- Física ----------------------------------------------------------------
@export_group("Física")
## Capa(s) del terreno lunar.
@export_flags_3d_physics var terrain_mask: int = 1
## Capa(s) donde viven las piezas ya colocadas (para detectar choques).
@export_flags_3d_physics var pieces_mask: int = 2
@export var ray_length: float = 2000.0
## Cuánto se encogen las formas de colisión al comprobar choques, para que dos
## piezas que solo se tocan (adyacentes en la grilla) no cuenten como choque.
@export var overlap_tolerance: float = 0.02

# --- Grilla / orientación --------------------------------------------------
@export_group("Grilla")
## Tamaño de celda en metros. 0 = colocación libre.
@export var grid_size: float = 2.0
@export var grid_offset: Vector3 = Vector3.ZERO
@export var rotation_step_deg: float = 90.0
## Pendiente máxima permitida (grados respecto a la vertical).
@export var max_slope_deg: float = 25.0
## Si es true la pieza se inclina según la normal del terreno.
@export var align_to_normal: bool = false

# --- Aspecto del holograma -------------------------------------------------
@export_group("Holograma")
@export var valid_color: Color = Color(0.2, 0.95, 0.85, 0.45)
@export var invalid_color: Color = Color(1.0, 0.15, 0.15, 0.55)
@export var hologram_shader: Shader = preload("hologram.gdshader")

# --- Comportamiento --------------------------------------------------------
@export_group("Comportamiento")
## Instanciar la pieza real al confirmar. Pon false si otro sistema
## (por ejemplo, el de construcción) escucha piece_placed y la crea él.
@export var spawn_on_confirm: bool = true
## Mantener Shift al confirmar para seguir colocando la misma pieza.
@export var keep_placing_with_shift: bool = true

# --- Estado interno --------------------------------------------------------
var state: State = State.IDLE
var current_piece_id: StringName = &""
var _current_scene: PackedScene
var _ghost: GhostPreview
var _ghost_material: Material
var _yaw: float = 0.0
var _has_target: bool = false
var _is_valid: bool = false
var _reject_reason: String = ""


func _ready() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if placed_parent == null:
		placed_parent = self


# ===========================================================================
# API pública
# ===========================================================================

## Entra en modo colocación. Si no se pasa escena se busca en piece_catalog.
func start_placement(piece_id: StringName, scene: PackedScene = null) -> void:
	if state == State.PLACING:
		_clear_ghost()

	if scene == null:
		scene = piece_catalog.get(piece_id) as PackedScene
	if scene == null:
		push_error("PlacementSystem: no hay escena para la pieza '%s'" % piece_id)
		return

	current_piece_id = piece_id
	_current_scene = scene
	_yaw = 0.0
	_has_target = false
	_is_valid = false

	_ghost_material = _make_ghost_material()
	_ghost = GhostPreview.new()
	_ghost.name = "GhostPreview"
	add_child(_ghost)
	_ghost.build(scene, _ghost_material, overlap_tolerance)
	_ghost.visible = false

	state = State.PLACING
	placement_started.emit(piece_id)


func cancel_placement() -> void:
	if state != State.PLACING:
		return
	var id := current_piece_id
	_clear_ghost()
	placement_cancelled.emit(id)


func is_placing() -> bool:
	return state == State.PLACING


func rotate_piece(steps: int = 1) -> void:
	_yaw = wrapf(_yaw + deg_to_rad(rotation_step_deg) * steps, 0.0, TAU)


# ===========================================================================
# Bucle
# ===========================================================================

func _physics_process(_delta: float) -> void:
	if state == State.PLACING:
		_update_preview()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLACING:
		return

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_try_confirm(event.shift_pressed)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				cancel_placement()
				get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("ui_cancel"):
			cancel_placement()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			rotate_piece(-1 if event.shift_pressed else 1)
			get_viewport().set_input_as_handled()


# ===========================================================================
# Previsualización
# ===========================================================================

func _update_preview() -> void:
	if camera == null or _ghost == null:
		return

	var space := get_world_3d().direct_space_state
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var to := from + camera.project_ray_normal(mouse) * ray_length

	var hit := _raycast(space, from, to, terrain_mask)
	if hit.is_empty():
		_has_target = false
		_ghost.visible = false
		return

	var point: Vector3 = hit.position
	var normal: Vector3 = hit.normal

	# Ajuste a la grilla (XZ) y nuevo rayo vertical para obtener la altura real
	# del terreno en la celda ajustada.
	if grid_size > 0.0:
		var local := point - grid_offset
		point.x = snappedf(local.x, grid_size) + grid_offset.x
		point.z = snappedf(local.z, grid_size) + grid_offset.z
		var down := _raycast(space, point + Vector3.UP * 500.0, point + Vector3.DOWN * 500.0, terrain_mask)
		if not down.is_empty():
			point = down.position
			normal = down.normal

	# Orientación
	var basis := Basis(Vector3.UP, _yaw)
	if align_to_normal and not normal.is_equal_approx(Vector3.UP):
		var tilt := Quaternion(Vector3.UP, normal.normalized())
		basis = Basis(tilt) * basis
	_ghost.global_transform = Transform3D(basis, point)
	_ghost.visible = true
	_has_target = true

	# Validación
	var valid := true
	_reject_reason = ""
	var slope := rad_to_deg(normal.angle_to(Vector3.UP))
	if slope > max_slope_deg:
		valid = false
		_reject_reason = "Pendiente demasiado pronunciada (%.0f°)" % slope
	elif _ghost.overlaps(space, pieces_mask):
		valid = false
		_reject_reason = "Choca con otra pieza"

	_set_valid(valid)


func _raycast(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = false
	return space.intersect_ray(query)


func _set_valid(valid: bool) -> void:
	if valid == _is_valid:
		return
	_is_valid = valid
	_apply_color(valid_color if valid else invalid_color)
	placement_validity_changed.emit(valid)


# ===========================================================================
# Confirmación
# ===========================================================================

func _try_confirm(shift_held: bool) -> void:
	if not _has_target:
		placement_rejected.emit(current_piece_id, "Apunta al terreno")
		return
	if not _is_valid:
		placement_rejected.emit(current_piece_id, _reject_reason)
		return

	var xform := _ghost.global_transform
	var id := current_piece_id

	if spawn_on_confirm:
		var piece := _current_scene.instantiate() as Node3D
		if piece:
			placed_parent.add_child(piece)
			piece.global_transform = xform
			piece.add_to_group(&"placed_pieces")
			piece.set_meta(&"piece_id", id)

	piece_placed.emit(id, xform.origin)

	if keep_placing_with_shift and shift_held:
		# Seguimos en modo colocación; el próximo frame de física marcará
		# rojo la misma celda porque ya está ocupada.
		_is_valid = false
		_apply_color(invalid_color)
	else:
		_clear_ghost()


# ===========================================================================
# Utilidades
# ===========================================================================

func _make_ghost_material() -> Material:
	if hologram_shader:
		var mat := ShaderMaterial.new()
		mat.shader = hologram_shader
		mat.set_shader_parameter(&"tint", invalid_color)
		return mat
	# Respaldo sin shader
	var std := StandardMaterial3D.new()
	std.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	std.cull_mode = BaseMaterial3D.CULL_DISABLED
	std.albedo_color = invalid_color
	return std


func _apply_color(color: Color) -> void:
	if _ghost_material is ShaderMaterial:
		(_ghost_material as ShaderMaterial).set_shader_parameter(&"tint", color)
	elif _ghost_material is StandardMaterial3D:
		(_ghost_material as StandardMaterial3D).albedo_color = color


func _clear_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
	_ghost = null
	_ghost_material = null
	_current_scene = null
	current_piece_id = &""
	_has_target = false
	_is_valid = false
	state = State.IDLE
