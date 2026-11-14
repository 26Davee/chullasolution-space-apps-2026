extends RefCounted
## Piezas de la base de Killawasi: cápsula, domo, panel solar, procesador de hielo y tanque de agua.
## Cada función devuelve la raíz lista para guardar como escena. Se modela con el frente hacia +Z;
## el generador gira los módulos para que queden con el frente hacia −Z.

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")

const LEG_ANGLE := 0.594
const LEG_LENGTH := 1.75
const BRACE_START := Vector3(0.05, 0.42, 0.0)
const BRACE_AT := Vector3(0.0, -0.8, 0.0)


static func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


# ------------------------------------------------------------------ cápsula

static func capsula() -> Node3D:
	var root := Node3D.new()
	root.name = "Lander"
	var casco := K.node(root, "Casco")
	K.part(casco, "Tobera", K.drum(0.62, 0.34, 16, 0.06, 0.5), "acero_osc", Vector3(0, 0.92, 0))
	K.part(casco, "Base", K.lathe([V(0, 1.04), V(0.95, 1.04), V(1.62, 1.24), V(1.99, 1.64), V(2.07, 2.0), V(2.07, 2.13), V(1.9, 2.16)], 14, 35.0, 0.35), "turquesa")
	K.part(casco, "Cupula", K.lathe([V(2.0, 2.1), V(1.97, 2.6), V(1.78, 3.15), V(1.42, 3.62), V(0.92, 3.95), V(0.5, 4.08), V(0, 4.1)], 14, 60.0, 0.55), "hueso")
	K.part(casco, "Tapa", K.drum(0.64, 0.26, 16, 0.08), "turquesa", Vector3(0, 4.14, 0))
	K.part(casco, "Collar", K.drum(0.27, 0.14, 14, 0.04), "ambar_mate", Vector3(0, 4.32, 0))
	K.part(casco, "Mastil", K.tube([Vector3(0, 4.3, 0), Vector3(0, 5.05, 0)], 0.045, 8), "acero")
	K.part(casco, "Rotula", K.sphere(0.09, 12, 6), "acero_osc", Vector3(0, 4.78, 0))
	var plato := K.node(casco, "Antena", Vector3(0.26, 4.86, 0.0), Vector3(0, 0, -52))
	K.part(plato, "Plato", K.lathe([V(0, 0), V(0.16, 0.02), V(0.3, 0.1), V(0.34, 0.17), V(0.3, 0.16), V(0.15, 0.07), V(0, 0.05)], 14, 50.0), "hueso")
	K.part(plato, "Receptor", K.sphere(0.045, 8, 4), "ambar_mate", Vector3(0, 0.2, 0))
	K.part(casco, "Baliza", K.sphere(0.2, 16, 8), "ambar", Vector3(0, 5.22, 0))

	# ventanillas: centradas en las facetas del casco (14 lados)
	var i := 0
	for ang in [38.57, 141.43, -12.86, 192.86, 218.57, 321.43]:
		i += 1
		var w := K.node(casco, "Ventanilla%d" % i)
		K.on_ring(w, ang, 1.845, 2.86, 19.0)
		K.part(w, "Marco", K.drum(0.37, 0.12, 18, 0.04), "naranja_marco", Vector3.ZERO, Vector3(90, 0, 0))
		K.part(w, "Luz", K.drum(0.275, 0.12, 18, 0.03), "ambar_suave", Vector3(0, 0, 0.03), Vector3(90, 0, 0))

	# puerta y escalerilla
	K.part(casco, "MarcoPuerta", K.plate_shape(K.arch(1.0, 1.36), 0.34, 0.04), "turquesa", Vector3(0, 2.1, 1.9))
	var puerta := K.node(root, "PivotePuerta", Vector3(-0.36, 2.06, 2.05))
	K.part(puerta, "Puerta", K.plate_shape(K.arch(0.72, 1.08), 0.1, 0.03), "ambar_suave", Vector3(0.36, 0, 0.02))
	K.part(puerta, "Pomo", K.sphere(0.045, 8, 4), "naranja_marco", Vector3(0.6, -0.05, 0.09))
	var rampa := K.node(root, "PivoteEscalerilla", Vector3(0, 1.48, 2.12), Vector3(39.0, 0, 0))
	K.part(rampa, "Tablero", K.rbox(Vector3(0.84, 0.07, 2.32), 0.03), "hueso", Vector3(0, 0, 1.17))
	for lado in [-1.0, 1.0]:
		K.part(rampa, "Baranda", K.rbox(Vector3(0.12, 0.17, 2.4), 0.05), "turquesa", Vector3(lado * 0.47, 0.03, 1.17))
	for s in 5:
		K.part(rampa, "Peldano", K.rbox(Vector3(0.74, 0.07, 0.24), 0.03), "ambar_suave", Vector3(0, 0.045, 0.3 + s * 0.44))

	# patas (el aterrizaje anima Arm y Foot)
	for leg_i in 4:
		var ang := deg_to_rad(45.0 + leg_i * 90.0)
		var leg := K.node(root, "Leg%d" % leg_i, Vector3(cos(ang) * 1.5, 1.55, sin(ang) * 1.5))
		leg.rotation.y = -ang
		K.part(leg, "Hinge", K.sphere(0.22, 14, 7), "turquesa_osc")
		var arm := K.node(leg, "Arm")
		arm.rotation.z = LEG_ANGLE
		K.part(arm, "Puntal", K.lathe([V(0, -1.7), V(0.1, -1.7), V(0.125, -0.95), V(0.19, -0.12), V(0.19, 0.0), V(0, 0.0)], 12, 50.0), "hueso")
		K.part(arm, "Brillo", K.drum(0.128, 0.52, 12, 0.03), "ambar_suave", Vector3(0, -1.22, 0))
		K.part(arm, "Piston", K.drum(0.07, 0.2, 10, 0.02), "acero", Vector3(0, -1.72, 0))
		var foot := K.node(arm, "Foot", Vector3(0, -LEG_LENGTH, 0))
		foot.rotation.z = -LEG_ANGLE
		K.part(foot, "Footpad", K.drum(0.38, 0.14, 16, 0.05), "turquesa", Vector3(0, -0.03, 0))
		K.part(foot, "Tobillo", K.drum(0.2, 0.12, 12, 0.04), "turquesa_osc", Vector3(0, 0.07, 0))
		var brace := K.part(leg, "Brace", K.drum(0.045, 1.0, 8, 0.01), "acero")
		align_link(brace, BRACE_START, arm.transform * BRACE_AT)

	var plume := K.node(root, "BrakingPlume", Vector3(0, 0.8, 0))
	plume.visible = false
	K.part(plume, "Llama", K.lathe([V(0, -2.2), V(0.3, -1.2), V(0.44, -0.35), V(0.34, 0.0), V(0, 0.0)], 12, 60.0), "llama")
	K.part(plume, "Nucleo", K.lathe([V(0, -1.3), V(0.16, -0.5), V(0.2, 0.0), V(0, 0.0)], 10, 60.0), "blanco")
	var light := OmniLight3D.new()
	light.name = "EngineBayLight"
	light.position = Vector3(0, 0.75, 0)
	light.light_color = Color("#FFC06A")
	light.light_energy = 0.9
	light.omni_range = 4.5
	root.add_child(light, true)
	var door_light := OmniLight3D.new()
	door_light.name = "LuzPuerta"
	door_light.position = Vector3(0, 1.6, 2.9)
	door_light.light_color = Color("#FFC06A")
	door_light.light_energy = 0.7
	door_light.omni_range = 3.2
	root.add_child(door_light, true)

	var acceso := AnimationPlayer.new()
	acceso.name = "Acceso"
	root.add_child(acceso, true)
	var lib := AnimationLibrary.new()
	lib.add_animation("abrir", _acceso_clip(true))
	lib.add_animation("cerrar", _acceso_clip(false))
	acceso.add_animation_library("", lib)
	K.collision(root, Vector3(0, 2.4, 0), Vector3(3.6, 3.4, 3.6))
	return root


static func _acceso_clip(abrir: bool) -> Animation:
	var clip := Animation.new()
	clip.length = 1.4
	var door_closed := Quaternion.IDENTITY
	var door_open := Quaternion.from_euler(Vector3(0, deg_to_rad(-105.0), 0))
	var ramp_open := Quaternion.from_euler(Vector3(deg_to_rad(39.0), 0, 0))
	var ramp_closed := Quaternion.from_euler(Vector3(deg_to_rad(-84.0), 0, 0))
	var t := clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(t, NodePath("PivoteEscalerilla"))
	clip.rotation_track_insert_key(t, 0.0, ramp_closed if abrir else ramp_open)
	clip.rotation_track_insert_key(t, 0.9, ramp_open if abrir else ramp_closed)
	t = clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(t, NodePath("PivotePuerta"))
	clip.rotation_track_insert_key(t, 0.0, door_closed if abrir else door_open)
	clip.rotation_track_insert_key(t, 0.5, door_closed if abrir else door_closed)
	clip.rotation_track_insert_key(t, 1.4, door_open if abrir else door_closed)
	return clip


## Coloca un puntal de 1 u de largo entre dos puntos del plano XY local (igual que `landing_intro.gd`).
static func align_link(link: Node3D, start: Vector3, end: Vector3) -> void:
	var direction := end - start
	link.transform = Transform3D(
		Basis(Vector3.FORWARD, atan2(direction.x, direction.y)).scaled_local(Vector3(1.0, direction.length(), 1.0)),
		(start + end) * 0.5)


# ------------------------------------------------------------------ domo

static func domo() -> Node3D:
	var root := Node3D.new()
	root.name = "DomoLunar"
	root.set_script(load("res://assets/3d/domo_lunar.gd"))
	var perfil: Array = []
	for i in 13:
		var a := PI * 0.5 * i / 12.0
		perfil.append(Vector2(cos(a) * 5.8, sin(a) * 5.8))
	var escudo := MeshInstance3D.new()
	escudo.name = "Escudo"
	escudo.mesh = K.lathe(perfil, 48, 80.0)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/3d/domo_escudo.gdshader")
	escudo.material_override = sm
	escudo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(escudo, true)
	var borde := K.part(root, "Borde", K.lathe([V(5.66, 0.0), V(5.94, 0.0), V(5.9, 0.07), V(5.7, 0.07), V(5.66, 0.0)], 64, 30.0), "cian_luz")
	borde.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


# ------------------------------------------------------------------ panel solar

static func panel_solar() -> Node3D:
	var root := StaticBody3D.new()
	root.name = "PanelSolar"
	var base := K.node(root, "Base")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pata := K.node(base, "Pata", Vector3(sx * 0.5, 0.2, sz * 0.36))
			pata.rotation_degrees = Vector3(0, 0, sx * -24.0)
			K.part(pata, "Brazo", K.rbox(Vector3(0.52, 0.17, 0.26), 0.07), "hueso")
			K.part(base, "Zapata", K.rbox(Vector3(0.4, 0.15, 0.34), 0.06), "turquesa", Vector3(sx * 0.78, 0.075, sz * 0.4))
	K.part(base, "Bloque", K.rbox(Vector3(1.1, 0.46, 0.92), 0.1, 3, Vector2(0.58, 0.66)), "hueso", Vector3(0, 0.45, 0))
	K.part(base, "Cuello", K.drum(0.22, 0.16, 14, 0.05), "turquesa", Vector3(0, 0.74, 0))
	K.part(base, "Poste", K.lathe([V(0, 0.78), V(0.18, 0.78), V(0.13, 1.5), V(0.13, 1.62), V(0, 1.62)], 12, 50.0), "hueso")
	var ind := K.led(root, "Indicador", Vector3(0, 0.44, 0.405), 0.34, 0.12, Vector3(-18, 0, 0))
	ind.name = "Indicador"

	var ala := K.node(root, "Ala", Vector3(0, 1.62, 0), Vector3(-30, 0, 0))
	K.part(ala, "Barril", K.drum(0.16, 0.66, 14, 0.05), "turquesa", Vector3.ZERO, Vector3(0, 0, 90))
	for sx in [-1.0, 1.0]:
		K.part(ala, "Anillo", K.drum(0.185, 0.1, 14, 0.03), "ambar_mate", Vector3(sx * 0.2, 0, 0), Vector3(0, 0, 90))
		var hoja := K.node(ala, "Hoja", Vector3(sx * 0.8, 0.42, 0.13), Vector3(0, sx * -6.0, 0))
		K.part(hoja, "Marco", K.plate(1.36, 1.76, 0.1, 0.13, 0.025), "hueso")
		K.part(hoja, "Celdas", K.plate(1.16, 1.56, 0.03, 0.05, 0.008), "panel_azul", Vector3(0, 0, 0.05))
		for lx in [-0.193, 0.193]:
			K.part(hoja, "Linea", K.rbox(Vector3(0.024, 1.54, 0.012), 0.004, 1), "panel_linea", Vector3(lx, 0, 0.068))
		for ly in [-0.39, 0.0, 0.39]:
			K.part(hoja, "Linea", K.rbox(Vector3(1.14, 0.024, 0.012), 0.004, 1), "panel_linea", Vector3(0, ly, 0.068))
		K.part(hoja, "Espalda", K.plate(1.06, 1.46, 0.03, 0.1, 0.01), "hueso_sombra", Vector3(0, 0, -0.045))
		for cy in [-1.0, 1.0]:
			K.part(hoja, "Esquina", K.plate(0.22, 0.22, 0.14, 0.07, 0.02), "ambar_mate", Vector3(sx * 0.6, cy * 0.8, 0))
			K.part(hoja, "Esquina", K.plate(0.18, 0.18, 0.13, 0.06, 0.02), "turquesa", Vector3(sx * -0.615, cy * 0.815, 0))
	K.collision(root, Vector3(0, 1.45, 0), Vector3(2.9, 2.9, 1.5), "")
	return root


# ------------------------------------------------------------------ procesador de hielo

static func procesador() -> Node3D:
	var root := Node3D.new()
	root.name = "ProcesadorHielo"
	var g := K.node(root, "Geometria")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.part(g, "Pie", K.drum(0.22, 0.16, 14, 0.05), "marino_osc", Vector3(sx * 0.72, 0.08, sz * 0.52))
	K.part(g, "Zocalo", K.rbox(Vector3(2.12, 0.46, 1.68), 0.13), "turquesa", Vector3(0, 0.36, 0))
	K.led(g, "LuzFrontal", Vector3(0, 0.34, 0.845), 0.62, 0.13)
	K.part(g, "Cuerpo", K.rbox(Vector3(1.98, 1.44, 1.54), 0.3, 4), "hueso", Vector3(0, 1.24, 0))

	# ventana frontal con cristales
	K.part(g, "MarcoVentana", K.plate_shape(K.octagon(1.24, 1.08, 0.22), 0.3, 0.04), "turquesa", Vector3(0, 1.26, 0.73))
	K.part(g, "FondoVentana", K.plate_shape(K.octagon(0.98, 0.82, 0.16), 0.1, 0.01), "cian_fondo", Vector3(0, 1.26, 0.8))
	K.part(g, "CristalA", K.crystal(0.66, 0.26), "hielo", Vector3(-0.02, 0.9, 0.86), Vector3(0, 20, -6), Vector3(1, 1, 0.25))
	K.part(g, "CristalB", K.crystal(0.46, 0.2), "hielo_osc", Vector3(0.27, 0.9, 0.86), Vector3(0, 0, -22), Vector3(1, 1, 0.25))
	K.part(g, "CristalC", K.crystal(0.4, 0.18), "hielo_osc", Vector3(-0.29, 0.9, 0.86), Vector3(0, 0, 24), Vector3(1, 1, 0.25))
	K.part(g, "Vidrio", K.plate_shape(K.octagon(0.98, 0.82, 0.16), 0.02, 0.004), "vidrio", Vector3(0, 1.26, 0.885))
	for bx in [-1.0, 1.0]:
		for by in [-1.0, 1.0]:
			K.part(g, "Perno", K.sphere(0.04, 8, 4), "acero", Vector3(bx * 0.53, 1.26 + by * 0.45, 0.885))

	# luz lateral izquierda
	K.led(g, "LuzLateral", Vector3(-0.995, 1.32, 0.12), 0.16, 0.5, Vector3(0, -90, 0))

	# salida de agua a la derecha
	var sy := 1.28
	var sz2 := 0.18
	K.part(g, "PanelSalida", K.plate_shape(K.octagon(0.9, 0.9, 0.2), 0.05, 0.012), "hueso_sombra", Vector3(0.985, 1.3, 0.0), Vector3(0, 90, 0))
	K.part(g, "BridaSalida", K.drum(0.24, 0.18, 16, 0.05), "ambar_mate", Vector3(1.03, sy, sz2), Vector3(0, 0, 90))
	K.part(g, "Codo", K.tube([Vector3(1.0, sy, sz2), Vector3(1.52, sy, sz2), Vector3(1.52, sy - 0.36, sz2)], 0.135, 12, 0.24), "turquesa")
	K.part(g, "AnilloGrifo", K.drum(0.175, 0.1, 14, 0.03), "ambar_mate", Vector3(1.52, sy - 0.36, sz2))
	K.part(g, "Gota", K.lathe([V(0, -0.11), V(0.07, -0.09), V(0.1, -0.03), V(0.065, 0.06), V(0, 0.2)], 12, 70.0), "agua", Vector3(1.52, 0.7, sz2))
	K.part(g, "Bandeja", K.lathe([V(0, 0.04), V(0.32, 0.04), V(0.38, 0.12), V(0.38, 0.3), V(0.33, 0.33), V(0.3, 0.27), V(0, 0.27)], 16, 40.0), "acero_osc", Vector3(1.52, 0, sz2))
	K.part(g, "AguaBandeja", K.drum(0.3, 0.04, 16, 0.01), "agua", Vector3(1.52, 0.29, sz2))
	K.led(g, "LuzBandeja", Vector3(1.52, 0.17, sz2 + 0.375), 0.26, 0.08)

	# tolva con hielo
	K.part(g, "Garganta", K.rbox(Vector3(1.05, 0.2, 0.9), 0.07), "turquesa_osc", Vector3(0, 2.0, 0))
	var tolva := K.node(g, "Tolva", Vector3(0, 0, 0), Vector3(0, 22.5, 0))
	tolva.scale = Vector3(1.14, 1.0, 0.92)
	K.part(tolva, "Embudo", K.lathe([V(0.5, 2.04), V(0.56, 2.06), V(1.02, 2.62), V(1.06, 2.74), V(0.95, 2.76), V(0.9, 2.66), V(0.5, 2.2), V(0, 2.2)], 8, 0.0, 1.0), "turquesa")
	K.led(g, "LuzTolva", Vector3(0, 2.02, 0.46), 0.5, 0.11, Vector3(0, 0, 0), "ambar_mate")
	var semillas := [[Vector3(-0.3, 2.62, 0.05), 0.33, 3], [Vector3(0.3, 2.6, -0.1), 0.3, 7], [Vector3(0.02, 2.74, 0.12), 0.34, 11], [Vector3(0.05, 2.6, -0.32), 0.26, 5], [Vector3(-0.55, 2.66, -0.2), 0.2, 9], [Vector3(0.55, 2.68, 0.2), 0.2, 13]]
	for d in semillas:
		K.part(g, "Hielo", K.rock(d[1], d[2], Vector3(1, 0.95, 1), 0.2), "hielo" if int(d[2]) % 2 == 1 else "hielo_osc", d[0], Vector3(d[2] * 9.0, d[2] * 31.0, 0))

	# espalda
	K.part(g, "PanelTrasero", K.plate(1.3, 0.9, 0.05, 0.12, 0.012), "hueso_sombra", Vector3(0, 1.3, -0.775))
	for ry in [1.2, 1.4]:
		K.part(g, "Rejilla", K.rbox(Vector3(0.62, 0.07, 0.03), 0.02, 2), "marino", Vector3(0, ry, -0.8))
	for rx in [-0.3, 0.3]:
		K.led(g, "LuzTrasera", Vector3(rx, 0.36, -0.845), 0.3, 0.1, Vector3(0, 180, 0))

	K.marker(root, "MarcadorEntrada", Vector3(0, 2.95, 0))
	K.marker(root, "MarcadorSalida", Vector3(1.52, 0.7, sz2))
	var anim := AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	root.add_child(anim, true)
	var clip := Animation.new()
	clip.length = 1.2
	clip.loop_mode = Animation.LOOP_LINEAR
	var t := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(t, NodePath("Geometria/Gota"))
	clip.position_track_insert_key(t, 0.0, Vector3(1.52, 0.78, sz2))
	clip.position_track_insert_key(t, 0.35, Vector3(1.52, 0.72, sz2))
	clip.position_track_insert_key(t, 0.9, Vector3(1.52, 0.36, sz2))
	clip.position_track_insert_key(t, 1.2, Vector3(1.52, 0.36, sz2))
	t = clip.add_track(Animation.TYPE_SCALE_3D)
	clip.track_set_path(t, NodePath("Geometria/Gota"))
	clip.scale_track_insert_key(t, 0.0, Vector3(0.3, 0.3, 0.3))
	clip.scale_track_insert_key(t, 0.35, Vector3.ONE)
	clip.scale_track_insert_key(t, 0.9, Vector3.ONE)
	clip.scale_track_insert_key(t, 1.0, Vector3(1.6, 0.1, 1.6))
	clip.scale_track_insert_key(t, 1.2, Vector3(0.01, 0.01, 0.01))
	var lib := AnimationLibrary.new()
	lib.add_animation("procesar", clip)
	anim.add_animation_library("", lib)
	K.collision(root, Vector3(0.2, 1.4, 0), Vector3(2.6, 2.8, 1.7))
	return root


# ------------------------------------------------------------------ tanque de agua

static func tanque() -> Node3D:
	var root := Node3D.new()
	root.name = "TanqueAgua"
	for ang in [90.0, 210.0, 330.0]:
		var pata := K.node(root, "Pata")
		K.on_ring(pata, ang, 0.74, 0.0)
		K.part(pata, "Bloque", K.rbox(Vector3(0.5, 0.62, 0.5), 0.11, 3, Vector2(0.7, 0.7)), "marino_osc", Vector3(0, 0.31, 0), Vector3(-10, 0, 0))
		K.led(pata, "IndicadorPata", Vector3(0, 0.25, 0.245), 0.14, 0.18, Vector3(-18, 0, 0))
	K.part(root, "FajaInferior", K.lathe([V(0, 0.44), V(0.6, 0.44), V(0.99, 0.66), V(1.02, 1.04), V(0.98, 1.09), V(0.9, 1.09)], 10, 35.0, 0.5), "turquesa")
	K.part(root, "CuerpoAcorazado", K.lathe([V(0.96, 1.06), V(0.96, 2.36), V(0.72, 2.8), V(0, 2.8)], 10, 30.0, 0.5), "hueso")
	K.part(root, "TapaServicio", K.lathe([V(0.7, 2.78), V(0.6, 2.98), V(0, 2.98)], 10, 30.0, 0.5), "turquesa")
	K.part(root, "CierreSuperior", K.drum(0.32, 0.1, 16, 0.03), "ambar_mate", Vector3(0, 3.02, 0))
	K.part(root, "ValvulaSuperior", K.drum(0.25, 0.18, 16, 0.05), "acero", Vector3(0, 3.14, 0))

	# mirilla frontal (faceta a 90°; el apotema del cuerpo es 0,913)
	K.part(root, "MarcoMirilla", K.plate_shape(K.octagon(0.66, 1.56, 0.16), 0.2, 0.04), "turquesa", Vector3(0, 1.72, 0.9))
	K.part(root, "FondoMirilla", K.plate_shape(K.octagon(0.44, 1.34, 0.11), 0.04, 0.008), "cian_fondo", Vector3(0, 1.72, 0.985))
	var nivel := K.node(root, "NivelAgua", Vector3(0, 1.08, 1.012))
	K.part(nivel, "Agua", K.rbox(Vector3(0.42, 0.62, 0.02), 0.008, 1), "agua", Vector3(0, 0.31, 0))
	K.part(nivel, "SuperficieHorizontal", K.rbox(Vector3(0.42, 0.035, 0.03), 0.01, 1), "cian_luz", Vector3(0, 0.62, 0))
	K.part(root, "CristalMirilla", K.plate_shape(K.octagon(0.44, 1.34, 0.11), 0.02, 0.004), "vidrio", Vector3(0, 1.72, 1.03))

	# paneles laterales con luz (facetas a 18° y 162°)
	for ang in [18.0, 162.0]:
		var panel := K.node(root, "Protector")
		K.on_ring(panel, ang, 0.915, 1.72)
		K.part(panel, "Placa", K.plate_shape(K.octagon(0.5, 1.02, 0.1), 0.07, 0.015), "hueso_sombra")
		K.led(panel, "Estado", Vector3(0, 0, 0.035), 0.1, 0.36)
		for bx in [-1.0, 1.0]:
			for by in [-1.0, 1.0]:
				K.part(panel, "Perno", K.sphere(0.03, 8, 4), "acero_osc", Vector3(bx * 0.17, by * 0.42, 0.04))

	# acople lateral
	var acople := K.node(root, "Acople")
	K.on_ring(acople, 162.0, 0.97, 0.84)
	K.part(acople, "BridaAcople", K.drum(0.2, 0.16, 14, 0.04), "ambar_mate", Vector3(0, 0, 0.06), Vector3(90, 0, 0))
	K.part(acople, "Boca", K.drum(0.14, 0.2, 14, 0.04), "acero", Vector3(0, 0, 0.2), Vector3(90, 0, 0))
	var marca := K.marker(root, "MarcadorAcople")
	marca.position = acople.position + acople.basis.z * 0.32

	# tubería trasera
	K.part(root, "TuberiaTrasera", K.tube([Vector3(0, 2.92, -0.3), Vector3(0, 2.92, -1.1), Vector3(0, 0.86, -1.1), Vector3(0, 0.86, -0.85)], 0.115, 12, 0.26), "turquesa")
	for cy in [1.35, 2.1]:
		K.part(root, "AbrazaderaTrasera", K.drum(0.15, 0.14, 12, 0.03), "ambar_mate", Vector3(0, cy, -1.1))
	K.collision(root, Vector3(0, 1.6, 0), Vector3(2.1, 3.2, 2.3))
	return root
