## Copia visual ("holograma") de una pieza, usada solo para previsualizar.
## - Quita scripts y colisiones de la copia para que no interactúe con el mundo.
## - Aplica el material de holograma a todas sus mallas.
## - Guarda las formas de colisión de la pieza (ligeramente encogidas) para
##   comprobar si se superpone con piezas ya colocadas.
class_name GhostPreview
extends Node3D

## Pares { node: CollisionShape3D, shape: Shape3D } para las consultas de choque.
var _shapes: Array[Dictionary] = []


func build(source: PackedScene, material: Material, shrink: float) -> void:
	var inst := source.instantiate()
	_sanitize(inst)
	add_child(inst)
	_collect_shapes(inst, shrink)
	_apply_material(inst, material)


## Devuelve true si alguna forma de la pieza se superpone con algo en `mask`.
func overlaps(space: PhysicsDirectSpaceState3D, mask: int) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.collision_mask = mask
	params.collide_with_areas = false
	params.collide_with_bodies = true
	for entry in _shapes:
		var cs: CollisionShape3D = entry.node
		params.shape = entry.shape
		params.transform = cs.global_transform
		if not space.intersect_shape(params, 1).is_empty():
			return true
	return false


# ---------------------------------------------------------------------------

func _sanitize(node: Node) -> void:
	# El holograma no debe ejecutar la lógica de la pieza ni chocar con nada.
	node.set_script(null)
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	if node is RigidBody3D:
		node.freeze = true
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_sanitize(child)


func _collect_shapes(node: Node, shrink: float) -> void:
	if node is CollisionShape3D and node.shape and not node.disabled:
		_shapes.append({ "node": node, "shape": _shrunk(node.shape, shrink) })
	for child in node.get_children():
		_collect_shapes(child, shrink)


func _apply_material(node: Node, material: Material) -> void:
	if node is GeometryInstance3D:
		node.material_override = material
	for child in node.get_children():
		_apply_material(child, material)


## Copia de la forma, encogida `t` metros para tolerar piezas que solo se tocan.
static func _shrunk(shape: Shape3D, t: float) -> Shape3D:
	if t <= 0.0:
		return shape
	var s := shape.duplicate() as Shape3D
	if s is BoxShape3D:
		var sz: Vector3 = s.size
		s.size = Vector3(maxf(sz.x - 2.0 * t, 0.01), maxf(sz.y - 2.0 * t, 0.01), maxf(sz.z - 2.0 * t, 0.01))
	elif s is SphereShape3D:
		s.radius = maxf(s.radius - t, 0.01)
	elif s is CapsuleShape3D:
		s.radius = maxf(s.radius - t, 0.01)
		s.height = maxf(s.height - 2.0 * t, s.radius * 2.0)
	elif s is CylinderShape3D:
		s.radius = maxf(s.radius - t, 0.01)
		s.height = maxf(s.height - 2.0 * t, 0.01)
	# ConvexPolygon / ConcavePolygon se usan tal cual.
	return s
