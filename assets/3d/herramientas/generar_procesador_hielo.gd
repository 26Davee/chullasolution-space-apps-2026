extends SceneTree
## Ejecutar con Godot Standard y --headless --path . --script este archivo.

const LowPoly = preload("res://assets/3d/herramientas/lowpoly.gd")
const ASSET := "res://assets/3d/procesador_hielo.tscn"
const GLB := "res://assets/3d/glb/procesador_hielo.glb"
const BONE := Color("#E9E2DA")
const TEAL := Color("#2AA3B0")
const DARK := Color("#122B3D")
const CYAN := Color("#33C7D6")
const GOLD := Color("#F2B544")
const ICE := Color("#BDEBFF")
const GLASS := Color(0.20, 0.78, 0.92, 0.23)
const CENTER := Vector3(0.36, 0, 0)
const OUTLET := Vector3(-1.61, 0.65, -0.10)
var asset: Node3D
var geometry: Node3D
var materials := {}


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	asset = Node3D.new()
	asset.name = "ProcesadorHielo"
	geometry = Node3D.new()
	_add(asset, geometry, "Geometria", CENTER)
	_body()
	_window()
	_hopper()
	_outlet()
	_collision("Volumen", Vector3(0, 1.12, 0), Vector3(2.12, 2.24, 1.61))
	_collision("Bandeja", Vector3(OUTLET.x, 0.17, OUTLET.z), Vector3(0.62, 0.34, 0.60))
	_add(asset, Marker3D.new(), "MarcadorEntrada", CENTER + Vector3(0, 2.55, 0))
	_add(asset, Marker3D.new(), "MarcadorSalida", CENTER + OUTLET - Vector3.UP * 0.055)
	var scene := PackedScene.new()
	if scene.pack(asset) != OK or ResourceSaver.save(scene, ASSET) != OK:
		push_error("No se pudo guardar el procesador")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(GLB.get_base_dir())
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var error := gltf.append_from_scene(asset, state)
	if error == OK:
		error = gltf.write_to_filesystem(state, GLB)
	asset.free()
	quit(error)


func _add(parent: Node3D, node: Node3D, label: String, position: Vector3) -> void:
	node.name = label
	node.position = position
	parent.add_child(node, true)
	node.owner = asset


func _material(color: Color, emission: float) -> StandardMaterial3D:
	var key := [color, emission]
	if not materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.66
		if emission > 0.0:
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = emission
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.15
		materials[key] = material
	return materials[key]


func _mesh(name: String, at: Vector3, mesh: Mesh, color: Color, emission := 0.0) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = _material(color, emission)
	if color.a < 1.0 or emission > 0.0:
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(geometry, piece, name, at)
	return piece


func _box(name: String, at: Vector3, size: Vector3, radius: float, color: Color, emission := 0.0, segments := 2) -> void:
	_mesh(name, at, LowPoly.caja_biselada(size, radius, segments), color, emission)


func _drum(name: String, at: Vector3, radius: float, height: float, color: Color, axis := Vector3.UP) -> void:
	var shape := LowPoly.cilindro_biselado(radius, height, 12, minf(height * .25, radius * .20))
	var piece := _mesh(name, at, shape, color)
	piece.quaternion = Quaternion(Vector3.UP, axis)


func _surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface


func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var cross := (b - a).cross(c - a)
	if cross.length_squared() < 0.00000001:
		return
	surface.add_vertex(a)
	surface.add_vertex(c if cross.dot(normal) > 0 else b)
	surface.add_vertex(b if cross.dot(normal) > 0 else c)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_tri(surface, a, b, c, normal)
	_tri(surface, a, c, d, normal)


func _finish(surface: SurfaceTool) -> ArrayMesh:
	surface.generate_normals()
	surface.index()
	return surface.commit()


func _outline(half_size: Vector2, corner: float) -> Array[Vector2]:
	var w := half_size.x
	var h := half_size.y
	return [Vector2(-w + corner, -h), Vector2(w - corner, -h), Vector2(w, -h + corner),
		Vector2(w, h - corner), Vector2(w - corner, h), Vector2(-w + corner, h),
		Vector2(-w, h - corner), Vector2(-w, -h + corner)]


func _xy_ring(half_size: Vector2, corner: float, z: float) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for p in _outline(half_size, corner):
		ring.append(Vector3(p.x, p.y, z))
	return ring


func _join(surface: SurfaceTool, first: PackedVector3Array, second: PackedVector3Array, normal: Vector3) -> void:
	for i in range(first.size()):
		var next := (i + 1) % first.size()
		_quad(surface, first[i], first[next], second[next], second[i], normal)


func _body() -> void:
	_box("Zocalo", Vector3(0, .34, 0), Vector3(2.15,.39,1.56), .15, TEAL)
	for x in [-.76, .76]:
		for z in [-.52, .52]:
			_drum("Apoyo", Vector3(x, .077, z), .225, .154, DARK)
			_drum("CollarApoyo", Vector3(x, .176, z), .175, .105, TEAL)
	_box("MonturaLuzBase", Vector3(0,.34,-.787), Vector3(.71,.195,.08), .035, DARK, 0, 1)
	_box("LuzBase", Vector3(0,.342,-.837), Vector3(.55,.093,.063), .04, GOLD, 1.55)
	_box("TapaTrasera", Vector3(0,1.16,.768), Vector3(1.37,.96,.12), .052, BONE, 0, 1)
	for y in [.99, 1.17]:
		_box("Rejilla", Vector3(0,y,.833), Vector3(.58,.057,.040), .020, DARK, 0, 1)
	for x in [-.55,.55]:
		for y in [.84,1.47]:
			_drum("RemacheTrasero", Vector3(x,y,.837), .035,.021,DARK,Vector3.BACK)


func _window() -> void:
	var at := Vector3(0,1.17,0)
	var s := _surface()
	var back := _xy_ring(Vector2(.98,.76),.20,.76)
	var middle := _xy_ring(Vector2(1.12,.84),.21,-.55)
	var slope := _xy_ring(Vector2(1.09,.81),.238,-.66)
	var front := _xy_ring(Vector2(.971,.724),.236,-.824)
	var opening := _xy_ring(Vector2(.695,.545),.163,-.829)
	for i in range(8):
		var k := (i + 1) % 8
		var side := (middle[i] + middle[k]) * .5
		side.z = 0
		_quad(s, back[i], back[k], middle[k], middle[i], side)
		_quad(s, middle[i], middle[k], slope[k], slope[i], side.normalized() + Vector3.FORWARD * .36)
		_quad(s, slope[i], slope[k], front[k], front[i], side.normalized() + Vector3.FORWARD)
		_tri(s, Vector3(0,0,.76), back[i], back[k], Vector3.BACK)
	_join(s, front, opening, Vector3.FORWARD)
	_mesh("CarcasaConAbertura", at, _finish(s), BONE)

	var frame := _surface()
	var face := _xy_ring(Vector2(.668,.52),.155,-.875)
	var inner := _xy_ring(Vector2(.577,.423),.134,-.89)
	_join(frame, opening, face, Vector3.FORWARD)
	_join(frame, face, inner, Vector3.FORWARD)
	_mesh("MarcoOctogonal", at, _finish(frame), TEAL)
	var chamber := _surface()
	var cavity := _xy_ring(Vector2(.53,.376),.11,-.38)
	for i in range(8):
		var k := (i + 1) % 8
		var inward := -(inner[i] + inner[k])
		inward.z = -.50
		_quad(chamber, inner[i], inner[k], cavity[k], cavity[i], inward)
		_tri(chamber, Vector3(0,0,-.38), cavity[i], cavity[k], Vector3.FORWARD)
	_mesh("CamaraHundida", at, _finish(chamber), DARK)
	var glass := _surface()
	for i in range(8):
		_tri(glass, Vector3(0,0,-.892), inner[i], inner[(i + 1) % 8], Vector3.FORWARD)
	_mesh("CristalCamara", at, _finish(glass), GLASS)
	_box("LuzInterior", Vector3(0,.798,-.65),Vector3(.91,.046,.25),.019,CYAN,.65,1)
	_crystal("HieloInterior", Vector3(.052, .808, -.63), .55, .215, -.24, CYAN)
	_crystal("HieloInterior", Vector3(-.33,.797,-.67),.27,.125,.31,ICE)
	_crystal("HieloInterior", Vector3(.34,.803,-.67),.25,.115,-.31,ICE)
	for x in [-.538,.538]:
		for y in [.795,1.53]:
			_drum("RemacheMarco",Vector3(x,y,-.88),.039,.032,GOLD,Vector3.FORWARD)
	_box("SelloEstado",Vector3(.873,1.46,-.803),Vector3(.221,.515,.124),.059,DARK,0,1)
	_box("LuzEstado",Vector3(.873,1.47,-.873),Vector3(.113,.377,.068),.030,GOLD,1.45)
	for x in [-.827,.827]:
		_drum("RemacheCarcasa",Vector3(x,.583,-.825),.049,.032,TEAL,Vector3.FORWARD)


func _hopper_ring(width: float, depth: float, height: float) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for point in _outline(Vector2(width, depth), minf(width,depth)*.265):
		ring.append(Vector3(point.x,height,point.y))
	return ring


func _hopper() -> void:
	var shell := _surface()
	var bottom := _hopper_ring(.49,.40,1.99)
	var belly := _hopper_ring(.59,.47,2.075)
	var lip := _hopper_ring(.97,.71,2.46)
	var top := _hopper_ring(.94,.685,2.52)
	var inner_top := _hopper_ring(.831,.583,2.52)
	var inner_bottom := _hopper_ring(.52,.395,2.11)
	for i in range(8):
		var n := (i + 1) % 8
		var direction := (lip[i] + lip[n]) * .5
		direction.y = 0
		_quad(shell,bottom[i],bottom[n],belly[n],belly[i],direction)
		_quad(shell,belly[i],belly[n],lip[n],lip[i],direction)
		_quad(shell,lip[i],lip[n],top[n],top[i],direction + Vector3.UP)
		_quad(shell,inner_top[i],inner_top[n],inner_bottom[n],inner_bottom[i],Vector3.UP - direction * 2.0)
		_tri(shell,Vector3(0,2.11,0),inner_bottom[i],inner_bottom[n],Vector3.UP)
	_mesh("Tolva",Vector3.ZERO,_finish(shell),TEAL)
	var edge := _surface()
	_join(edge, top, inner_top, Vector3.UP)
	_mesh("LabioTolva",Vector3.ZERO,_finish(edge),TEAL.lightened(.26))
	_box("SeguroTolva",Vector3(0,2.07,-.495),Vector3(.55,.118,.093),.043,GOLD,.18,1)
	_crystal("CargaCentral",Vector3(-.015,2.16,.08),.73,.35,.18,CYAN)
	_crystal("CargaFrontal",Vector3(.33,2.17,-.19),.56,.24,-.26,ICE)
	_crystal("CargaLateral",Vector3(-.43,2.15,.03),.45,.22,.29,TEAL.lightened(.32))
	_crystal("CargaTrasera",Vector3(.34,2.17,.31),.44,.23,.17,ICE)


func _crystal(label: String, at: Vector3, h: float, r: float, tilt: float, color: Color) -> void:
	var surface := _surface()
	var rows: Array[PackedVector3Array] = []
	for row in range(3):
		var ring := PackedVector3Array()
		for i in range(5):
			var angle := i * TAU / 5.0 + .30
			var height: float = h * [.07,.39,.73][row] + h * .104 * sin(angle * 2.0 + row)
			var radius: float = r * [.55,1.0,.71][row] * (1.0 + .13 * cos(angle * 2.0 + row))
			ring.append(Vector3(cos(angle)*radius,height,sin(angle)*radius))
		rows.append(ring)
	for i in range(5):
		var next := (i + 1) % 5
		var outward := rows[1][i] + rows[1][next]
		outward.y = 0
		_tri(surface,Vector3.ZERO,rows[0][i],rows[0][next],Vector3.DOWN)
		for row in range(2):
			_quad(surface,rows[row][i],rows[row][next],rows[row+1][next],rows[row+1][i],outward)
		_tri(surface,rows[2][i],rows[2][next],Vector3(-r*.19,h,r*.13),outward + Vector3.UP)
	var crystal := _mesh(label, at, _finish(surface), color, .16)
	crystal.rotation.z = tilt


func _outlet() -> void:
	_drum("BridaTurquesa",Vector3(-1.069,1.16,-.10),.237,.19,TEAL,Vector3.LEFT)
	_drum("AcopleAmbar",Vector3(-1.185,1.16,-.10),.194,.151,GOLD,Vector3.LEFT)
	var tube := _surface()
	var last := PackedVector3Array()
	for step in range(9):
		var angle := step * PI / 16.0
		var center := Vector3(-1.30 - .31 * sin(angle), .85 + .31 * cos(angle), OUTLET.z)
		var tangent := Vector3(-cos(angle), -sin(angle),0)
		var radial := Vector3(-sin(angle), cos(angle),0)
		if step == 8:
			center += tangent * .19
		var ring := PackedVector3Array()
		for side in range(12):
			var turn := side * TAU / 12.0
			ring.append(center + .116 * (radial*cos(turn) + Vector3.BACK*sin(turn)))
		if step > 0:
			for side in range(12):
				var next := (side + 1) % 12
				_quad(tube,last[side],last[next],ring[next],ring[side],ring[side]+ring[next]-2.0*center)
		last = ring
	_mesh("CodoSalida",Vector3.ZERO,_finish(tube),TEAL)
	_drum("Boquilla",OUTLET,.151,.106,GOLD)
	_drum("ZapataColector",Vector3(OUTLET.x,.052,OUTLET.z),.277,.104,DARK)
	_drum("Colector",Vector3(OUTLET.x,.188,OUTLET.z),.314,.235,TEAL.darkened(.19))
	_drum("AroColector",Vector3(OUTLET.x,.308,OUTLET.z),.309,.052,BONE)
	_drum("Agua",Vector3(OUTLET.x,.337,OUTLET.z),.252,.023,CYAN)
	_box("IndicadorColector",Vector3(OUTLET.x,.175,OUTLET.z-.318),Vector3(.265,.065,.029),.014,GOLD,1.45,1)
	var droplet := _mesh("Gota", OUTLET - Vector3.UP * .162, _drop_mesh(), ICE, .24)
	var player := AnimationPlayer.new()
	asset.add_child(player)
	player.name = "AnimationPlayer"
	player.owner = asset
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	clip.length = .66
	var track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(track, asset.get_path_to(droplet))
	clip.position_track_insert_key(track,0,OUTLET - Vector3.UP * .102)
	clip.position_track_insert_key(track,.51,OUTLET - Vector3.UP * .253)
	clip.position_track_insert_key(track,.66,droplet.position)
	library.add_animation("procesar", clip)
	player.add_animation_library("", library)


func _collision(name: String, at: Vector3, size: Vector3) -> void:
	var body := asset.get_node_or_null("Colision") as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		_add(asset, body, "Colision", Vector3.ZERO)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	_add(body, collision, name, CENTER + at)


func _drop_mesh() -> ArrayMesh:
	var surface := _surface()
	var radii := [0.0, .049, .075, .068, .042, .019, 0.0]
	var heights := [-.122, -.107, -.065, -.022, .018, .055, .094]
	for i in range(12):
		var a := Vector3(cos(TAU * i / 12.0), 0, sin(TAU * i / 12.0))
		var b := Vector3(cos(TAU * (i+1) / 12.0), 0, sin(TAU * (i+1) / 12.0))
		for row in range(6):
			_quad(surface, a * radii[row] + Vector3.UP * heights[row],
				b * radii[row] + Vector3.UP * heights[row],
				b * radii[row+1] + Vector3.UP * heights[row+1],
				a * radii[row+1] + Vector3.UP * heights[row+1], a + b)
	return _finish(surface)