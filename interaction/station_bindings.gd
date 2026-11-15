extends RefCounted
## Separate pick volumes do not affect character/placement collision layers.
static func bind(root: Node3D, section: String) -> void:
	root.set_meta("station_section",section)
	if root.has_node("StationPick"): return
	var bounds := AABB()
	var first := true
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null: continue
		var local: AABB = (root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	if first: bounds = AABB(Vector3(-1,0,-1),Vector3(2,2,2))
	var area := Area3D.new()
	area.name = "StationPick"
	area.collision_layer = 16
	area.collision_mask = 0
	root.add_child(area)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = bounds.size.max(Vector3(0.8,1.0,0.8))
	shape.shape = box
	shape.position = bounds.get_center()
	area.add_child(shape)
