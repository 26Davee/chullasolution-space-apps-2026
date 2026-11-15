extends RefCounted
## Plans a short route around actual solid modules, never through pick volumes.
static func plan(world: Node3D, origin: Vector3, destination: Vector3, exclude: Array[RID]) -> Array[Vector3]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-26,-26,53,53)
	grid.cell_size = Vector2(1.5,1.5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.46
	query.shape = sphere
	query.collision_mask = 3
	query.exclude = exclude
	query.collide_with_areas = false
	var space := world.get_world_3d().direct_space_state
	for x in range(-26,27):
		for z in range(-26,27):
			query.transform = Transform3D(Basis.IDENTITY,Vector3(x*1.5,0.65,z*1.5))
			if not space.intersect_shape(query,1).is_empty(): grid.set_point_solid(Vector2i(x,z))
	var start := Vector2i(roundi(origin.x/1.5),roundi(origin.z/1.5))
	var end := Vector2i(roundi(destination.x/1.5),roundi(destination.z/1.5))
	var result: Array[Vector3] = []
	if not grid.is_in_boundsv(start) or not grid.is_in_boundsv(end): return result
	grid.set_point_solid(start,false)
	grid.set_point_solid(end,false)
	var path := grid.get_id_path(start,end)
	for i in range(1,path.size()): result.append(Vector3(path[i].x*1.5,origin.y,path[i].y*1.5))
	if not path.is_empty(): result.append(destination)
	return result
