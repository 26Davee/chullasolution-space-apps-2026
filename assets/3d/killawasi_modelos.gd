extends SceneTree
## Ejecutar con Godot Standard desde el proyecto:
## godot --headless --path . --script res://assets/3d/killawasi_modelos.gd -- first
## "first" genera el tanque. El procesador se genera en herramientas/generar_procesador_hielo.gd.
## y "export" exporta las escenas existentes. Sin argumento genera los modelos nuevos.

const OUTPUT := "res://assets/3d/"
const BONE := Color("#E9E2DA")
const TEAL := Color("#2AA3B0")
const DARK := Color("#122B3D")
const GOLD := Color("#F2B544")
const ICE := Color("#BDEBFF")
const CYAN := Color("#33C7D6")
const STEEL := Color("#85939F")
const GLASS := Color(0.25, 0.78, 0.91, 0.23)
var model: Node3D
var materials := {}


func _initialize() -> void:
	call_deferred("_generate")


func _generate() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or "first" in args:
		_save("tanque_agua", _water_tank())
	if args.is_empty() or "rest" in args:
		_save("pala", _shovel())
		_save("pico", _pick())
		_save("taladro_manual", _drill(false))
		_save("taladro_mochila", _drill(true))
		_save("domo_lunar", _dome())
		_save("reciclador_agua", _recycler())
		_save("jardin_lunar", _garden())
		_save("bateria_lunar", _battery())
		_save("rover_lunar", _rover())
		_save("cristales_hielo", _ice_cluster())
		_save("crater_hielo", _crater())
		_save("efecto_tormenta", _storm())
	if "refine" in args and not _already_refined():
		_refine()
	if "access" in args:
		_add_capsule_access()
	if "finish_lander" in args:
		_finish_lander()
	if "poses" in args:
		_save_character_poses()
	if "export" in args:
		for name in ["astronauta", "vicuna", "lunar_lander", "habitat_lunar", "panel_solar", "generador_oxigeno", "moon_world", "lunar_earth", "lunar_sun", "lunar_stars"]:
			var scene: PackedScene = load(OUTPUT + name + ".tscn")
			var instance := scene.instantiate() as Node3D
			_export_glb(name, instance)
			instance.free()
	quit()


func _start(label: String) -> Node3D:
	model = Node3D.new()
	model.name = label
	return model


func _save(file: String, item: Node3D) -> void:
	var scene := PackedScene.new()
	assert(scene.pack(item) == OK)
	assert(ResourceSaver.save(scene, OUTPUT + file + ".tscn") == OK)
	_export_glb(file, item)
	item.free()


func _export_glb(file: String, item: Node3D) -> void:
	var path := OUTPUT + "glb/"
	DirAccess.make_dir_recursive_absolute(path)
	for child in item.find_children("*", "MeshInstance3D", true, false):
		var piece := child as MeshInstance3D
		if piece.material_override is ShaderMaterial:
			var shader_path := (piece.material_override as ShaderMaterial).shader.resource_path
			if shader_path.ends_with("vicuna_visor.gdshader"):
				piece.material_override = _material(GLASS)
			elif shader_path.ends_with("vicuna_traje.gdshader"):
				piece.material_override = _material(TEAL)
			elif shader_path.ends_with("landing_intro_sun.gdshader"):
				var solar_disc := SphereMesh.new()
				solar_disc.radius = 1.404
				solar_disc.height = 2.808
				piece.mesh = solar_disc
				piece.material_override = _material(GOLD)
			elif shader_path.ends_with("landing_intro_earth.gdshader"):
				piece.material_override = _material(Color("#2381C1"))
	var state := GLTFState.new()
	var document := GLTFDocument.new()
	assert(document.append_from_scene(item, state) == OK, file)
	assert(document.write_to_filesystem(state, path + file + ".glb") == OK, file)
	print("GLB: ", file)


func _add(parent: Node3D, node: Node3D, label: String, at: Vector3) -> void:
	node.name = label
	node.position = at
	parent.add_child(node)
	node.owner = model


func _pivot(parent: Node3D, label: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	_add(parent, node, label, at)
	return node


func _mark(parent: Node3D, label: String, at: Vector3) -> void:
	_add(parent, Marker3D.new(), label, at)


func _material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.68
		if color == GOLD or color == CYAN:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 0.32
		if color.a < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.3
		materials[color] = mat
	return materials[color]


func _piece(parent: Node3D, label: String, at: Vector3, shape: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = _material(color)
	if color.a < 1.0:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(parent, node, label, at)
	return node


func _vertices(surface: SurfaceTool, points: Array[Vector3]) -> void:
	for point in points:
		surface.add_vertex(point)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_vertices(surface, [a, b, c, a, c, d])


func _surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface


func _finish_mesh(surface: SurfaceTool) -> ArrayMesh:
	surface.generate_normals()
	surface.index()
	return surface.commit()


# Maps an eight-sided outline to a horizontal ring.
func _outline(x: float, z: float, cut: float, y: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(x - cut, y, z), Vector3(x, y, z - cut), Vector3(x, y, -z + cut),
		Vector3(x - cut, y, -z), Vector3(-x + cut, y, -z), Vector3(-x, y, -z + cut),
		Vector3(-x, y, z - cut), Vector3(-x + cut, y, z),
	])


func _bevel(size: Vector3, cut: float) -> ArrayMesh:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var z := size.z * 0.5
	var edge := minf(cut, minf(x, minf(y, z)) * 0.46)
	var rings := [
		_outline(x - edge, z - edge, edge * 0.65, -y),
		_outline(x, z, edge, -y + edge),
		_outline(x, z, edge, y - edge),
		_outline(x - edge, z - edge, edge * 0.65, y),
	]
	var surface := _surface()
	for side in range(8):
		var next := (side + 1) % 8
		for layer in range(3):
			var lower: PackedVector3Array = rings[layer]
			var upper: PackedVector3Array = rings[layer + 1]
			_quad(surface, lower[next], lower[side], upper[side], upper[next])
		_vertices(surface, [Vector3(0, -y, 0), rings[0][side], rings[0][next]])
		_vertices(surface, [Vector3(0, y, 0), rings[3][next], rings[3][side]])
	return _finish_mesh(surface)


func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, color: Color, cut := 0.12) -> MeshInstance3D:
	return _piece(parent, label, at, _bevel(size, cut), color)


func _radial(profile: Array[Vector2], sides: int, cap := true) -> ArrayMesh:
	var surface := _surface()
	for side in range(sides):
		var a := TAU * side / sides
		var b := TAU * (side + 1) / sides
		var dir_a := Vector3(cos(a), 0, sin(a))
		var dir_b := Vector3(cos(b), 0, sin(b))
		for row in range(profile.size() - 1):
			var low := profile[row]
			var high := profile[row + 1]
			_quad(surface, dir_a * low.y + Vector3.UP * low.x,
				dir_b * low.y + Vector3.UP * low.x, dir_b * high.y + Vector3.UP * high.x,
				dir_a * high.y + Vector3.UP * high.x)
		if cap:
			var low := profile.front() as Vector2
			var high := profile.back() as Vector2
			_vertices(surface, [Vector3.UP * low.x, Vector3.UP * low.x + dir_b * low.y, Vector3.UP * low.x + dir_a * low.y])
			_vertices(surface, [Vector3.UP * high.x, Vector3.UP * high.x + dir_a * high.y, Vector3.UP * high.x + dir_b * high.y])
	return _finish_mesh(surface)


func _drum(parent: Node3D, label: String, at: Vector3, radius: float, height: float, color: Color, sides := 12) -> MeshInstance3D:
	var bevel := minf(radius * 0.19, height * 0.24)
	var shape := _radial([
		Vector2(-height * 0.5, radius - bevel), Vector2(-height * 0.5 + bevel, radius),
		Vector2(height * 0.5 - bevel, radius), Vector2(height * 0.5, radius - bevel),
	], sides)
	return _piece(parent, label, at, shape, color)


func _tube(parent: Node3D, label: String, points: Array[Vector3], radius: float, color: Color) -> void:
	var path := Curve3D.new()
	path.bake_interval = 0.065
	for i in range(points.size()):
		var tangent := Vector3.ZERO
		if i > 0 and i < points.size() - 1:
			tangent = (points[i + 1] - points[i - 1]) * 0.18
		path.add_point(points[i], -tangent, tangent)
	var samples := path.get_baked_points()
	var surface := _surface()
	var last := PackedVector3Array()
	var initial := (points[1] - points[0]).normalized()
	var plane_normal := initial.cross(points.back() - points[0]).normalized()
	if plane_normal.is_zero_approx():
		plane_normal = Vector3.FORWARD if absf(initial.z) < 0.9 else Vector3.UP
	for i in range(samples.size()):
		var tangent := (samples[mini(i + 1, samples.size() - 1)] - samples[maxi(i - 1, 0)]).normalized()
		var right := tangent.cross(plane_normal).normalized()
		var up := right.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for side in range(10):
			var angle := side * TAU / 10.0
			ring.append(samples[i] + radius * (right * cos(angle) + up * sin(angle)))
		if i > 0:
			for side in range(10):
				var next := (side + 1) % 10
				_quad(surface, last[side], last[next], ring[next], ring[side])
		last = ring
	_piece(parent, label, Vector3.ZERO, _finish_mesh(surface), color)


func _beam(parent: Node3D, label: String, from: Vector3, to: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := _drum(parent, label, (from + to) * 0.5, radius, from.distance_to(to), color, 10)
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return node


func _crystal(parent: Node3D, label: String, at: Vector3, height: float, radius: float, tilt: float, color := ICE) -> void:
	var stone := _piece(parent, label, at, _radial([
		Vector2.ZERO, Vector2(0.12 * height, radius), Vector2(0.70 * height, 0.83 * radius),
		Vector2(height, 0.018 * radius),
	], 5), color)
	stone.rotation.z = tilt


func _collision(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	_add(parent, body, "Colision", Vector3.ZERO)
	var bounds := BoxShape3D.new()
	bounds.size = size
	var shape := CollisionShape3D.new()
	shape.shape = bounds
	_add(body, shape, "Volumen", at)


func _water_tank() -> Node3D:
	var root := _start("TanqueAgua")
	for i in range(3):
		var angle := PI / 2.0 + i * TAU / 3.0
		var position := Vector3(cos(angle) * 0.60, 0.19, sin(angle) * 0.60)
		var foot := _box(root, "Pata", position, Vector3(0.42, 0.38, 0.49), DARK, 0.10)
		foot.rotation.y = -angle + PI / 2.0
		_box(root, "IndicadorPata", position + Vector3(cos(angle) * 0.23, 0.025, sin(angle) * 0.23), Vector3(0.13, 0.09, 0.12), GOLD)
	_piece(root, "FajaInferior", Vector3.ZERO, _radial([Vector2(0.30, 0.62), Vector2(0.44, 0.80), Vector2(0.74, 0.85)], 12), TEAL)
	_piece(root, "CuerpoAcorazado", Vector3.ZERO, _radial([Vector2(0.69, 0.85), Vector2(2.03, 0.85), Vector2(2.28, 0.66), Vector2(2.35, 0.53)], 12), BONE)
	_drum(root, "TapaServicio", Vector3(0, 2.39, 0), 0.42, 0.16, TEAL)
	_drum(root, "ValvulaSuperior", Vector3(0, 2.525, 0), 0.19, 0.17, GOLD)
	_drum(root, "CierreSuperior", Vector3(0, 2.63, 0), 0.16, 0.08, STEEL)
	_box(root, "MarcoMirilla", Vector3(0, 1.39, 0.83), Vector3(0.65, 1.49, 0.185), TEAL, 0.13)
	_box(root, "FondoMirilla", Vector3(0, 1.39, 0.936), Vector3(0.484, 1.30, 0.052), DARK)
	var water := _pivot(root, "NivelAgua", Vector3(0, 0.763, 0.978))
	_box(water, "Agua", Vector3(0, 0.335, 0), Vector3(0.427, 0.67, 0.047), Color("#159BAF"))
	_box(water, "SuperficieHorizontal", Vector3(0, 0.67, 0.01), Vector3(0.43, 0.026, 0.055), CYAN)
	_box(root, "CristalMirilla", Vector3(0, 1.39, 1.023), Vector3(0.474, 1.30, 0.027), GLASS)
	for side in [-1.0, 1.0]:
		var panel := _box(root, "Protector", Vector3(side * 0.55, 1.37, 0.618), Vector3(0.35, 0.98, 0.10), Color("#D0C7C3"), 0.05)
		panel.rotation.y = side * PI / 6.0
		var lamp := _box(root, "Estado", Vector3(side * 0.59, 1.42, 0.68), Vector3(0.085, 0.34, 0.075), GOLD)
		lamp.rotation.y = panel.rotation.y
	_tube(root, "TuberiaTrasera", [Vector3(0, 2.54, -0.10), Vector3(0, 2.52, -0.67), Vector3(0, 2.32, -0.99), Vector3(0, 0.79, -0.99), Vector3(0, 0.60, -0.71)], 0.118, TEAL)
	for height in [1.02, 1.89]:
		_drum(root, "AbrazaderaTrasera", Vector3(0, height, -0.99), 0.138, 0.105, GOLD)
	_beam(root, "BridaAcople", Vector3(0.70, 0.60, 0), Vector3(0.93, 0.60, 0), 0.188, GOLD)
	_beam(root, "Acople", Vector3(0.91, 0.60, 0), Vector3(1.06, 0.60, 0), 0.139, DARK)
	_mark(root, "MarcadorAcople", Vector3(1.065, 0.60, 0))
	_collision(root, Vector3(0, 1.42, 0), Vector3(1.7, 2.40, 1.7))
	return root


func _shovel() -> Node3D:
	var root := _start("Pala")
	var bowl := _surface()
	var border := PackedVector3Array([
		Vector3(-0.16, 0.026, -0.44), Vector3(0.16, 0.026, -0.44),
		Vector3(0.25, 0.038, -0.60), Vector3(0.24, 0.12, -0.86),
		Vector3(0.15, 0.146, -0.96), Vector3(-0.15, 0.146, -0.96),
		Vector3(-0.24, 0.12, -0.86), Vector3(-0.25, 0.038, -0.60),
	])
	var center := Vector3(0, -0.04, -0.71)
	for i in range(border.size()):
		var a := border[i]
		var b := border[(i + 1) % border.size()]
		_vertices(bowl, [center, b, a, center - Vector3.UP * 0.024, a - Vector3.UP * 0.024, b - Vector3.UP * 0.024])
		_beam(root, "Canto", a, b, 0.021, TEAL)
	_piece(root, "Cazo", Vector3.ZERO, _finish_mesh(bowl), BONE)
	_beam(root, "Asta", Vector3(0, 0.082, 0.014), Vector3(0, 0, -0.52), 0.048, DARK)
	_beam(root, "Collar", Vector3(0, 0.012, -0.44), Vector3(0, 0.002, -0.54), 0.075, GOLD)
	var grip: Array[Vector3] = [Vector3(0, 0.076, 0), Vector3(-0.095, 0.085, 0.09), Vector3(-0.10, 0.086, 0.20),
		Vector3(0.10, 0.086, 0.20), Vector3(0.095, 0.085, 0.09), Vector3(0, 0.076, 0)]
	for i in range(grip.size() - 1):
		_beam(root, "AgarreD", grip[i], grip[i + 1], 0.032, TEAL)
	_mark(root, "AgarrePrincipal", Vector3(0, 0.086, 0.20))
	_mark(root, "AgarreSecundario", Vector3(0, 0.027, -0.31))
	_mark(root, "Contacto", Vector3(0, .146, -.96))
	return root


func _pick() -> Node3D:
	var root := _start("Pico")
	_beam(root, "Mango", Vector3(0, -0.09, 0), Vector3(0, 0.74, 0), 0.05, DARK)
	_beam(root, "Empunadura", Vector3(0, -0.12, 0), Vector3(0, 0.18, 0), 0.068, BONE)
	_box(root, "Union", Vector3(0, 0.75, 0), Vector3(0.24, 0.17, 0.19), TEAL, 0.05)
	_box(root, "Remache", Vector3(0, 0.754, 0.103), Vector3(0.11, 0.065, 0.045), GOLD)
	var point: Array[Vector3] = [Vector3(-0.06, .75, 0), Vector3(-.20, .755, 0), Vector3(-.39, .72, 0), Vector3(-.51, .63, 0)]
	for i in range(point.size() - 1):
		_beam(root, "Punta", point[i], point[i + 1], 0.067 - i * 0.016, STEEL)
	var chisel := _box(root, "Cincel", Vector3(.265, .718, 0), Vector3(.35, .079, .155), BONE, 0.035)
	chisel.rotation.z = -0.18
	_mark(root, "AgarrePrincipal", Vector3.ZERO)
	_mark(root, "AgarreSecundario", Vector3(0, .39, 0))
	_mark(root, "Contacto", point.back())
	return root


func _drill(backpack: bool) -> Node3D:
	var root := _start("TaladroMochila" if backpack else "TaladroManual")
	_box(root, "Carcasa", Vector3(0, 0.19, -0.20), Vector3(0.29, 0.31, 0.53), BONE, 0.065)
	_beam(root, "CollarMotor", Vector3(0, 0.19, -0.43), Vector3(0, 0.19, -0.59), 0.131, TEAL)
	_box(root, "Indicador", Vector3(.147, .206, -.15), Vector3(.044, .096, .148), GOLD)
	var top := _box(root, "Mango", Vector3(0, 0.008, .008), Vector3(0.123, 0.31, 0.139), DARK, 0.03)
	top.rotation.x = -0.22
	_box(root, "Bateria", Vector3(0, -.135, .0), Vector3(.27, .099, .25), TEAL)
	var bit := _pivot(root, "Broca", Vector3(0, .19, -.58))
	var length := .66 if backpack else .33
	_beam(bit, "Eje", Vector3.ZERO, Vector3(0, 0, -length), 0.051, STEEL)
	var spiral: Array[Vector3] = []
	for i in range(31):
		var t := i / 30.0
		var angle := t * TAU * (3.3 if backpack else 2.2)
		var radius := lerpf(.087, .038, t)
		spiral.append(Vector3(cos(angle) * radius, sin(angle) * radius, -t * length))
	_tube(bit, "Helice", spiral, 0.025, BONE)
	_mark(root, "AgarrePrincipal", Vector3(0, .01, .015))
	_mark(root, "AgarreSecundario", Vector3(0, .20, -.32))
	_mark(bit, "Contacto", Vector3(0, 0, -length))
	if backpack:
		_box(root, "AgarreEstabilizador", Vector3(-.24, .225, -.30), Vector3(.24, .11, .10), TEAL)
		_box(root, "MangoSecundario", Vector3(-.33, .15, -.30), Vector3(.09, .23, .12), DARK)
		root.get_node("AgarreSecundario").position = Vector3(-.33, .15, -.30)
		var pack := _pivot(root, "Mochila", Vector3(.65, .21, .49))
		_box(pack, "Bastidor", Vector3.ZERO, Vector3(.49, .54, .13), TEAL)
		for x in [-.126, .126]:
			_box(pack, "Celda", Vector3(x, 0, .125), Vector3(.225, .48, .17), BONE)
			_box(pack, "Carga", Vector3(x, .142, .218), Vector3(.12, .069, .04), GOLD)
			for y in [-.084, -.13, -.176]:
				_box(pack, "Rejilla", Vector3(x, y, .218), Vector3(.13, .025, .032), DARK)
		_mark(pack, "AnclaMochila", Vector3(0, 0, -.081))
		_mark(pack, "ConectorCable", Vector3(-.12, -.24, .115))
		_mark(root, "ConectorCable", Vector3(.06, -.11, .1))
		_tube(root, "Cable", [Vector3(.53,-.03,.605), Vector3(.48,-.31,.59), Vector3(.30,-.34,.33), Vector3(.06,-.11,.10)], .045, DARK)
	return root


func _dome() -> Node3D:
	var root := _start("DomoLunar")
	var rows: Array[Vector2] = []
	for i in range(10):
		var angle := (PI / 2.0) * i / 9.0
		rows.append(Vector2(sin(angle) * 4.9, cos(angle) * 5.8))
	var shield := _piece(root, "Escudo", Vector3.ZERO, _radial(rows, 36, false), Color(0.21, 0.74, 0.83, 0.13))
	shield.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(36):
		var a := i * TAU / 36.0
		var b := (i + 1) * TAU / 36.0
		_beam(root, "Borde", Vector3(cos(a) * 5.8, .025, sin(a) * 5.8), Vector3(cos(b) * 5.8, .025, sin(b) * 5.8), 0.045, TEAL)
	return root


func _recycler() -> Node3D:
	var root := _start("RecicladorAgua")
	_box(root, "Base", Vector3(0,.17,0), Vector3(2.55,.34,1.42), TEAL)
	_box(root, "Bastidor", Vector3(-.36,.88,-.13), Vector3(1.51,1.36,1.04), BONE, .24)
	for i in range(2):
		var y := .56 + i * .48
		var radius := .188 + i * .025
		_beam(root, "Camara", Vector3(-.67,y,.56), Vector3(.99,y,.56), radius, Color("#54D7E3"))
		_beam(root, "Acople", Vector3(.76,y,.56), Vector3(1.02,y,.56), radius * 1.13, TEAL)
		for x in [-.41, -.06, .29, .58]:
			_drum(root, "Burbuja", Vector3(x, y, .56 + radius * .96), .036, .051, ICE, 8)
	_tube(root, "Retorno", [Vector3(1.0,1.04,.56), Vector3(1.23,1.02,.56), Vector3(1.25,.61,.56), Vector3(1.02,.56,.56)], .107, TEAL)
	_box(root, "Estado", Vector3(-.91,.89,.48), Vector3(.10,.38,.065), GOLD)
	for x in [-.9, .86]:
		_box(root, "LuzBase", Vector3(x,.17,.715), Vector3(.36,.079,.05), GOLD)
	_mark(root, "MarcadorEntrada", Vector3(-1.11,.56,.53))
	_mark(root, "MarcadorRetorno", Vector3(1.26,1.03,.56))
	_collision(root, Vector3(0,.77,0), Vector3(2.57,1.54,1.50))
	return root


func _garden() -> Node3D:
	var root := _start("JardinLunar")
	_box(root, "Bandeja", Vector3(0,.22,0), Vector3(2.8,.44,1.63), TEAL)
	_box(root, "Sustrato", Vector3(0,.448,0), Vector3(2.57,.075,1.46), Color("#51434A"))
	for i in range(5):
		for j in range(2):
			var at := Vector3((i - 2) * .48, .48, (j - .5) * .52)
			var height := .29 + .12 * ((i + j) % 2)
			for side in [-1.0, 1.0]:
				var leaf := _piece(root, "Hoja", at + Vector3(side * .071, height * .46, 0), _radial([Vector2(-.12,.018),Vector2(0,.096),Vector2(.185,.002)], 5), Color("#7AB450") if side > 0 else Color("#45955B"))
				leaf.rotation.z = -side * .44
	for x in [-1.26, -.43, .43, 1.26]:
		var points: Array[Vector3] = []
		for i in range(13):
			var angle := PI * i / 12.0
			points.append(Vector3(x, .48 + .63 * sin(angle), .745 * cos(angle)))
		_tube(root, "Arco", points, .022, BONE)
	var cover := _surface()
	for i in range(12):
		var a := i * PI / 12.0
		var b := (i + 1) * PI / 12.0
		_quad(cover, Vector3(-1.28,.48 + .63 * sin(a), .75 * cos(a)),
			Vector3(1.28,.48 + .63 * sin(a), .75 * cos(a)),
			Vector3(1.28,.48 + .63 * sin(b), .75 * cos(b)),
			Vector3(-1.28,.48 + .63 * sin(b), .75 * cos(b)))
	var lid := _piece(root, "Cubierta", Vector3.ZERO, _finish_mesh(cover), Color(.50,.84,.88,.15))
	lid.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	for x in [-.75, .75]:
		_box(root, "LuzCultivo", Vector3(x,.23,.819), Vector3(.69,.079,.041), GOLD)
	_collision(root, Vector3(0,.55,0), Vector3(2.8,1.1,1.61))
	return root


func _battery() -> Node3D:
	var root := _start("BateriaLunar")
	_box(root, "Bastidor", Vector3(0,.16,0), Vector3(2.53,.32,.95), DARK)
	for x in [-.87,-.29,.29,.87]:
		_box(root, "Celda", Vector3(x,.64,0), Vector3(.515,.98,.71), BONE)
		_box(root, "Bornes", Vector3(x,1.16,0), Vector3(.32,.11,.41), GOLD)
		_box(root, "MarcoCarga", Vector3(x,.63,.36), Vector3(.29,.55,.08), DARK)
		for y in [.45,.56,.67,.78]:
			_box(root, "SegmentoCarga", Vector3(x,y,.415), Vector3(.189,.065,.027), CYAN)
	_collision(root, Vector3(0,.57,0), Vector3(2.53,1.14,.95))
	return root


func _rover() -> Node3D:
	var root := _start("RoverLunar")
	_box(root, "Chasis", Vector3(0,.55,0), Vector3(1.45,.36,2.68), DARK)
	_box(root, "CabinaSensores", Vector3(0,.95,.55), Vector3(1.65,.72,1.51), BONE,.24)
	_box(root, "DefensaFrontal", Vector3(0,.57,1.28), Vector3(1.67,.23,.35), TEAL)
	_box(root, "CarcasaSensores", Vector3(0,1.02,1.31), Vector3(1.07,.36,.15), DARK)
	for x in [-.252,.252]:
		_beam(root, "Sensor", Vector3(x,1.02,1.34), Vector3(x,1.02,1.45), .135, TEAL)
		_beam(root, "Lente", Vector3(x,1.02,1.445), Vector3(x,1.02,1.48), .077, CYAN)
	_drum(root, "Baliza", Vector3(0,1.39,.49), .14,.16,GOLD)
	_box(root, "Bandeja", Vector3(0,.85,-.84), Vector3(1.52,.21,1.33), TEAL)
	for x in [-.69,.69]:
		_box(root, "BordeBandeja", Vector3(x,1.0,-.83), Vector3(.13,.18,1.2), BONE)
	_box(root, "CierreBandeja", Vector3(0,1.0,-1.42), Vector3(1.5,.18,.15), BONE)
	for side in [-1.0,1.0]:
		for i in range(3):
			var z := (i - 1) * .96
			var at := Vector3(side * .92,.39,z)
			_beam(root, "Suspension", Vector3(side * .57,.70,z + .26), at, .074, STEEL)
			_beam(root, "Amortiguador", Vector3(side * .58,.61,z - .27), at, .069, GOLD)
			var wheel := _pivot(root, "Rueda%s%d" % ["Izq" if side < 0 else "Der",i+1], at)
			_drum(wheel, "Neumatico", Vector3.ZERO,.39,.315,DARK,16).rotation.z = PI * .5
			_drum(wheel, "Llanta", Vector3(side*.169,0,0),.25,.055,STEEL,12).rotation.z = PI * .5
			_drum(wheel, "Cubo", Vector3(side*.204,0,0),.136,.046,GOLD).rotation.z = PI * .5
			for tooth in range(12):
				var angle := tooth * TAU / 12.0
				_box(wheel,"Taco",Vector3(0,cos(angle)*.364,sin(angle)*.364),Vector3(.31,.049,.095),Color("#253445")).rotation.x = angle
	_mark(root, "Carga", Vector3(0,1,-.81))
	_collision(root, Vector3(0,.59,0), Vector3(2.15,1.18,2.72))
	return root


func _ice_cluster() -> Node3D:
	var root := _start("CristalesHielo")
	_plant_ice(root, Vector3.ZERO)
	return root


func _plant_ice(root: Node3D, at: Vector3) -> void:
	_crystal(root,"CristalPrincipal",at,.91,.20,-.12)
	_crystal(root,"CristalLateral",at + Vector3(-.23,0,.08),.59,.15,.23,CYAN)
	_crystal(root,"CristalPequeno",at + Vector3(.26,0,-.12),.48,.12,-.28)


func _crater() -> Node3D:
	var root := _start("CraterHielo")
	var mesh := _surface()
	var rings := [Vector2(0, 0),Vector2(0, 1.6),Vector2(.47, 2.40),Vector2(.66,2.69),Vector2(.045,3.25)]
	for side in range(16):
		var a := TAU * side / 16.0
		var b := TAU * (side + 1) / 16.0
		for row in range(rings.size() - 1):
			var low: Vector2 = rings[row]
			var high: Vector2 = rings[row+1]
			var va := Vector3(cos(a),0,sin(a))
			var vb := Vector3(cos(b),0,sin(b))
			_quad(mesh, vb * low.y + Vector3.UP*low.x, va*low.y + Vector3.UP*low.x,
				va * high.y + Vector3.UP*(high.x + .11*sin(3*a)), vb * high.y + Vector3.UP*(high.x + .11*sin(3*b)))
	var crater := _piece(root,"Regolito",Vector3.ZERO,_finish_mesh(mesh),Color("#7C7890"))
	var body := StaticBody3D.new()
	_add(root, body, "Colision", Vector3.ZERO)
	var shape := CollisionShape3D.new()
	shape.shape = crater.mesh.create_trimesh_shape()
	_add(body, shape, "Forma", Vector3.ZERO)
	_plant_ice(root,Vector3(-.90,0,-.67))
	_plant_ice(root,Vector3(.82,0,.43))
	return root


func _storm() -> Node3D:
	var root := _start("EfectoTormenta")
	var points := [Vector3(-.74,.53,.06),Vector3(.02,.76,0),Vector3(.7,.52,.11),
		Vector3(-.27,.38,.34),Vector3(.28,.45,.3)]
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 4
	for at in points:
		_piece(root, "Nube", at, sphere, Color(1.0,.435,.38,.24)).scale = Vector3(1.38, .71, .89)
	return root


func _refine() -> void:
	var path := OUTPUT + "astronauta.tscn"
	var astronaut := (load(path) as PackedScene).instantiate() as Node3D
	model = astronaut
	var torso := astronaut.get_node("Cadera/Torso") as Node3D
	var head := torso.get_node("Cabeza") as Node3D
	var pack := torso.get_node("CubiertaMochila") as MeshInstance3D
	pack.mesh = _bevel(Vector3(.41,.46,.17),.085)
	pack.scale = Vector3.ONE
	pack.position.z = .402
	pack.material_override = _material(BONE)
	(torso.get_node("Mochila") as MeshInstance3D).mesh = _bevel(Vector3(.47,.50,.24),.10)
	(torso.get_node("Mochila") as Node3D).scale = Vector3.ONE
	for i in range(1,4):
		var vent := torso.get_node("Ventila%d" % i) as Node3D
		vent.position.z = .496
	(head.get_node("Visor") as MeshInstance3D).material_override = _material(DARK)
	_box(head,"SoporteLampara",Vector3(0,.494,-.119),Vector3(.21,.087,.10),DARK,.03)
	_box(head,"LamparaAmbar",Vector3(0,.513,-.172),Vector3(.151,.056,.029),GOLD,.015)
	for suffix in ["Izq","Der"]:
		var hand := torso.get_node("Hombro%s/Codo/Mano" % suffix) as Node3D
		_mark(hand, "AnclaHerramienta", Vector3(0,-.036,-.063))
	_mark(torso,"AnclaCarga",Vector3(0,.16,-.40))
	_mark(torso,"AnclaMochila",Vector3(0,.235,.49))
	_save("astronauta", astronaut)

	path = OUTPUT + "vicuna.tscn"
	var vicuna := (load(path) as PackedScene).instantiate() as Node3D
	model = vicuna
	var vicuna_head := vicuna.get_node("Cuerpo/Cuello/Cabeza") as Node3D
	_mark(vicuna_head,"AnclaGuia",Vector3(0,.67,0))
	_save("vicuna", vicuna)

	path = OUTPUT + "panel_solar.tscn"
	var panel := (load(path) as PackedScene).instantiate() as Node3D
	model = panel
	var wing := panel.get_node("Ala") as Node3D
	var tray := wing.get_node("Bandeja") as MeshInstance3D
	tray.mesh = _bevel(Vector3(2.26,.151,2.42),.055)
	tray.position.x = -1.24
	tray.material_override = _material(BONE)
	_box(wing,"PlacaDerecha",Vector3(1.24,0,0),Vector3(2.26,.151,2.42),BONE,.055)
	for child in wing.get_children():
		if String(child.name).begins_with("Celda") or String(child.name).begins_with("Conductor"):
			child.position.x += signf(child.position.x) * .136
	_box(wing,"EjeEntrePlacas",Vector3(0,0,0),Vector3(.19,.15,2.09),TEAL)
	for i in range(2):
		(panel.get_node("Pie%d" % i) as MeshInstance3D).material_override = _material(BONE)
	_save("panel_solar", panel)

	path = OUTPUT + "generador_oxigeno.tscn"
	var oxygen := (load(path) as PackedScene).instantiate() as Node3D
	model = oxygen
	_tube(oxygen,"PuenteColector",[Vector3(.64,2.06,-.50),Vector3(.64,2.42,-.50),Vector3(.64,2.49,.43),Vector3(.64,2.06,.50)],.115,TEAL)
	_beam(oxygen,"AnilloPuente",Vector3(.64,2.465,-.071),Vector3(.64,2.465,.075),.146,GOLD)
	_save("generador_oxigeno", oxygen)

	path = OUTPUT + "lunar_lander.tscn"
	var capsule := (load(path) as PackedScene).instantiate() as Node3D
	model = capsule
	var shell := capsule.get_node("Cabin") as MeshInstance3D
	fit_lander_shell(shell)
	capsule.get_node("Shoulders").visible = false
	var door := _pivot(capsule,"PivotePuerta",Vector3(-.21,2.56,1.115))
	for label in ["Hatch","HatchPanel","StatusLight"]:
		_reparent_for_scene(capsule.get_node(label) as Node3D, door)
	var ladder := _pivot(capsule,"PivoteEscalerilla",Vector3(0,2.16,1.43))
	for child in capsule.get_children():
		if String(child.name).begins_with("Ladder"):
			_reparent_for_scene(child, ladder)
	_save("lunar_lander", capsule)


func _reparent_for_scene(part: Node3D, target: Node3D) -> void:
	part.position -= target.position
	part.owner = null
	part.reparent(target, false)
	part.owner = model


func fit_lander_shell(shell: MeshInstance3D) -> void:
	shell.position = Vector3.ZERO
	shell.mesh = _radial([Vector2(2.18,1.36),Vector2(2.50,1.35),Vector2(2.89,1.19),
		Vector2(3.25,1.07),Vector2(3.58,.86),Vector2(3.76,.57)], 12)


func _already_refined() -> bool:
	var character := (load(OUTPUT + "astronauta.tscn") as PackedScene).instantiate()
	var refined := character.has_node("Cadera/Torso/Cabeza/LamparaAmbar")
	character.free()
	return refined
func _pose_clip(player: AnimationPlayer, library: AnimationLibrary, label: String, frames: Array[Dictionary], duration: float, loop: bool) -> void:
	var clip := Animation.new()
	clip.length = duration
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var paths := {}
	for frame in frames:
		for path in frame:
			paths[path] = true
	var root := player.get_parent()
	for path in paths:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath(path))
		var baseline: Quaternion = root.get_node(path).quaternion
		for i in range(frames.size()):
			var angles: Vector3 = frames[i].get(path, Vector3.ZERO)
			var pose := Quaternion.from_euler(angles * (PI / 180.0))
			clip.rotation_track_insert_key(track, duration * i / maxi(1, frames.size() - 1), baseline * pose)
	library.add_animation(label, clip)


func _pose_player(item: Node3D) -> AnimationPlayer:
	var player := AnimationPlayer.new()
	item.add_child(player)
	player.name = "Poses"
	player.owner = item
	player.add_animation_library("", AnimationLibrary.new())
	return player


func _astronaut_poses(item: Node3D) -> void:
	var player := _pose_player(item)
	var library := player.get_animation_library("")
	var left := "Cadera/Torso/HombroIzq"
	var right := "Cadera/Torso/HombroDer"
	var paths := [left, right, left + "/Codo", right + "/Codo", "Cadera/MusloIzq", "Cadera/MusloDer",
		"Cadera/MusloIzq/Rodilla", "Cadera/MusloDer/Rodilla", "Cadera/Torso", "Cadera/Torso/Cabeza"]
	var rest := {}
	for path in paths:
		rest[path] = Vector3.ZERO
	_pose_clip(player, library, "reposo", [rest, rest], 1, true)
	var walk: Array[Dictionary] = []
	for i in range(5):
		var sweep := cos(i * PI * .5) * 18
		var step := rest.duplicate()
		step[left] = Vector3(sweep * .8,0,0)
		step[right] = Vector3(-sweep * .8,0,0)
		step["Cadera/MusloIzq"] = Vector3(-sweep,0,0)
		step["Cadera/MusloDer"] = Vector3(sweep,0,0)
		step["Cadera/MusloIzq/Rodilla"] = Vector3(maxf(0.0,-sweep),0,0)
		step["Cadera/MusloDer/Rodilla"] = Vector3(maxf(0.0,sweep),0,0)
		walk.append(step)
	_pose_clip(player,library,"caminar",walk,.92,true)
	var dig := rest.duplicate()
	dig["Cadera/Torso"] = Vector3(-23,0,0)
	dig[left] = Vector3(47,-9,10)
	dig[right] = Vector3(43,12,-10)
	dig[left + "/Codo"] = Vector3(35,0,0)
	dig[right + "/Codo"] = Vector3(31,0,0)
	var carry := rest.duplicate()
	carry[left] = Vector3(35,-12,7)
	carry[right] = Vector3(35,12,-7)
	carry[left + "/Codo"] = Vector3(48,0,0)
	carry[right + "/Codo"] = Vector3(48,0,0)
	var touch := rest.duplicate()
	touch[right] = Vector3(72,0,-9)
	touch[right + "/Codo"] = Vector3(18,0,0)
	_pose_clip(player,library,"cavar",[rest,dig,rest],1.24,true)
	_pose_clip(player,library,"cargar_hielo",[carry,carry],1,false)
	_pose_clip(player,library,"tocar_domo",[rest,touch,touch],1.2,false)


func _vicuna_poses(item: Node3D) -> void:
	var player := _pose_player(item)
	var library := player.get_animation_library("")
	var neck := "Cuerpo/Cuello"
	var head := neck + "/Cabeza"
	var ear_l := head + "/OrejaIzq"
	var ear_r := head + "/OrejaDer"
	var leg := "Cuerpo/PataDelanteraDer"
	var knee := leg + "/Rodilla"
	var rest := {neck: Vector3.ZERO, head: Vector3.ZERO, ear_l: Vector3.ZERO, ear_r: Vector3.ZERO, leg: Vector3.ZERO, knee: Vector3.ZERO}
	_pose_clip(player,library,"respirar",[rest,{neck: Vector3(2,0,0)},rest],2.2,true)
	_pose_clip(player,library,"hablar",[rest,{head: Vector3(5,4,0)},{head: Vector3(-3,-4,0)},rest],.76,true)
	_pose_clip(player,library,"senal",[rest,{leg: Vector3(61,0,-8),knee: Vector3(20,0,0),head: Vector3(-3,10,-5)},rest],1.5,false)
	_pose_clip(player,library,"aviso",[rest,{head: Vector3(6,0,-9),ear_l: Vector3(-15,0,-11),ear_r:Vector3(-13,0,9)},rest],1.4,false)
	_pose_clip(player,library,"celebrar",[rest,{neck:Vector3(-9,0,0),leg:Vector3(42,0,-9),head:Vector3(-9,-6,0)},{head:Vector3(-7,7,0),leg:Vector3(29,0,0)},rest],1.2,false)


func _save_character_poses() -> void:
	for name in ["astronauta", "vicuna"]:
		var item := (load(OUTPUT + name + ".tscn") as PackedScene).instantiate() as Node3D
		if not item.has_node("Poses"):
			if name == "astronauta":
				_astronaut_poses(item)
			else:
				_vicuna_poses(item)
			_save(name, item)
		else:
			item.free()

func _finish_lander() -> void:
	var capsule := (load(OUTPUT + "lunar_lander.tscn") as PackedScene).instantiate() as Node3D
	model = capsule
	if not capsule.has_node("MarcoCircular1"):
		for i in range(2):
			var old_mount := capsule.get_node("WindowMount%d" % (i + 1)) as Node3D
			var yaw := old_mount.rotation.y
			old_mount.free()
			var forward := Vector3(sin(yaw),0,cos(yaw))
			var position := forward * 1.132 + Vector3.UP * 3.05
			_beam(capsule,"MarcoCircular%d" % (i + 1),position - forward * .025,position + forward * .13,.235,TEAL)
			_beam(capsule,"Ventanilla%d" % (i + 1),position + forward * .13,position + forward * .165,.167,GOLD)
		var door := capsule.get_node("PivotePuerta") as Node3D
		door.position.z += .144
		(door.get_node("HatchPanel") as MeshInstance3D).material_override = _material(GOLD)
		capsule.get_node("PivoteEscalerilla").position.z += .09
		_save("lunar_lander", capsule)
	else:
		capsule.free()


func _add_capsule_access() -> void:
	var capsule := (load(OUTPUT + "lunar_lander.tscn") as PackedScene).instantiate() as Node3D
	model = capsule
	if capsule.has_node("Acceso"):
		capsule.get_node("Acceso").free()
	var ladder := capsule.get_node("PivoteEscalerilla") as Node3D
	# Keep the access clear of the four diagonal landing pads.
	ladder.position = Vector3(0,2.18,1.58)
	ladder.rotation = Vector3.ZERO
	var angle := deg_to_rad(-28.0)
	var rail_length := 2.18 / cos(angle)
	for item in ladder.get_children():
		(item as Node3D).free()
	for x in [-.18,.18]:
		_box(ladder,"Pasamanos",Vector3(x,-rail_length*.5,0),Vector3(.056,rail_length-.07,.061),STEEL,.018)
	for i in range(9):
		var height := -.19 - i * (rail_length - .30) / 8.0
		_box(ladder,"Peldano",Vector3(0,height,0),Vector3(.38,.053,.086),GOLD,.015)
	var player := _pose_player(capsule)
	player.name = "Acceso"
	var library := player.get_animation_library("")
	var door := "PivotePuerta"
	var pivot := "PivoteEscalerilla"
	var closed := {door: Vector3.ZERO, pivot: Vector3(-160, 0, 0)}
	var opened := {door: Vector3(0,78,0), pivot: Vector3(-28,0,0)}
	_pose_clip(player,library,"abrir",[closed,opened],1.05,false)
	_pose_clip(player,library,"cerrar",[opened,closed],1.05,false)
	# Store the deployed presentation pose and retain explicit keys for both poses.
	ladder.rotation.x = angle
	_save("lunar_lander",capsule)