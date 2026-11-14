extends RefCounted
## Entorno de Killawasi: suelo lunar facetado, rocas, montañas, cráteres, cristales de hielo,
## nube de tormenta, Tierra, Sol, estrellas, ambiente (luz y cielo) y la escena lunar montada.

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")

const BASE := Color("#7C7890")
const CLARO := Color("#9A96AE")
const SOMBRA := Color("#5E5A73")
const LADO := 85.0
const PLANO := 30.0
const PROFUNDIDAD_CIELO := 300.0
const DIR_TIERRA := Vector3(0.40, 0.185, -0.9)
const DIR_SOL := Vector3(-0.37, 0.105, -0.92)


static func piezas() -> Dictionary:
	return {
		"cristales": ["cristales_hielo", cristales, false],
		"crater": ["crater_hielo", crater_hielo, false],
		"tormenta": ["efecto_tormenta", tormenta, false],
		"tierra": ["lunar_earth", tierra, false],
		"sol": ["lunar_sun", sol, false],
		"estrellas": ["lunar_stars", estrellas, false],
		"terreno": ["moon_world", terreno, false],
		"ambiente": ["res://world/ambiente_lunar.tscn", ambiente, false],
		"mundo": ["res://world/moon_world.tscn", mundo, false],
		"revision": ["res://world/killawasi_revision.tscn", revision, false],
	}


static func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


# ------------------------------------------------------------------ hielo, cráter y tormenta

static func cristales() -> Node3D:
	var root := Node3D.new()
	root.name = "CristalesHielo"
	K.part(root, "CristalPrincipal", K.crystal(0.92, 0.17), "hielo", Vector3(0, 0, 0), Vector3(0, 12, 4))
	K.part(root, "CristalIzquierdo", K.crystal(0.6, 0.13), "hielo_osc", Vector3(-0.17, 0, 0.04), Vector3(0, 40, 24))
	K.part(root, "CristalDerecho", K.crystal(0.5, 0.12), "hielo_osc", Vector3(0.16, 0, -0.03), Vector3(0, 70, -26))
	K.part(root, "CristalFrontal", K.crystal(0.34, 0.1), "hielo", Vector3(0.03, 0, 0.16), Vector3(28, 0, -6))
	return root


static func _anillo_crater(parent: Node3D, radio: float, alto: float) -> void:
	K.part(parent, "Regolito", K.lathe([V(radio * 1.32, 0.0), V(radio, alto * 0.82), V(radio * 0.9, alto), V(radio * 0.8, alto * 0.78), V(radio * 0.56, 0.035)], 18, 25.0, 0.7), "crater_borde")
	K.part(parent, "Fondo", K.lathe([V(radio * 0.58, 0.04), V(radio * 0.3, 0.03), V(0, 0.04)], 18, 0.0, 0.6), "crater_fondo")


static func crater_hielo() -> Node3D:
	var root := Node3D.new()
	root.name = "CraterHielo"
	_anillo_crater(root, 2.5, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(2.3, 3.0)
		var s := rng.randf_range(0.22, 0.5)
		K.part(root, "Borde%d" % (i + 1), K.rock(1.0, 30 + i % 4), "roca", Vector3(cos(a) * r, s * 0.3, sin(a) * r), Vector3(0, i * 53.0, 0), Vector3(s, s, s))
	var grupos := [[Vector3(0.5, 0.04, -0.45), 1.45], [Vector3(-0.35, 0.04, 0.25), 1.0], [Vector3(0.95, 0.04, 0.5), 0.8]]
	var n := 0
	for g in grupos:
		n += 1
		var grupo := K.node(root, "Veta%d" % n, g[0], Vector3(0, n * 47.0, 0))
		grupo.scale = Vector3.ONE * float(g[1])
		K.part(grupo, "Cristal", K.crystal(0.92, 0.17), "hielo", Vector3.ZERO, Vector3(0, 12, 6))
		K.part(grupo, "Cristal", K.crystal(0.6, 0.13), "hielo_osc", Vector3(-0.17, 0, 0.04), Vector3(0, 40, 26))
		K.part(grupo, "Cristal", K.crystal(0.5, 0.12), "hielo_osc", Vector3(0.16, 0, -0.03), Vector3(0, 70, -28))
	var luz := OmniLight3D.new()
	luz.name = "BrilloHielo"
	luz.position = Vector3(0.3, 0.8, 0)
	luz.light_color = Color("#6FD8FF")
	luz.light_energy = 0.8
	luz.omni_range = 3.4
	root.add_child(luz, true)
	var body := StaticBody3D.new()
	body.name = "Colision"
	root.add_child(body, true)
	var forma := CollisionShape3D.new()
	forma.name = "Forma"
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 3.0
	cilindro.height = 1.0
	forma.shape = cilindro
	forma.position = Vector3(0, 0.5, 0)
	body.add_child(forma, true)
	K.marker(root, "MarcadorExcavacion", Vector3(0, 0.05, 2.9))
	return root


static func tormenta() -> Node3D:
	var root := Node3D.new()
	root.name = "EfectoTormenta"
	var bolas := [[Vector3(0, 0, 0), 0.36], [Vector3(-0.32, -0.05, 0.02), 0.27], [Vector3(0.33, -0.04, -0.02), 0.29], [Vector3(-0.12, 0.17, 0), 0.26], [Vector3(0.16, 0.16, 0.03), 0.24]]
	var n := 0
	for b in bolas:
		n += 1
		var nube := K.part(root, "Nube" if n == 1 else "Nube%d" % n, K.rock(b[1], 40 + n, Vector3(1.05, 0.85, 0.9), 0.1), "coral", b[0], Vector3(0, n * 61.0, 0))
		nube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 7:
		var chispa := K.part(root, "Chispa%d" % (i + 1), K.crystal(0.09, 0.03, 4), "coral", Vector3(-0.3 + i * 0.1, -0.42 - 0.07 * (i % 3), 0.05 * ((i % 2) * 2 - 1)), Vector3(0, i * 40.0, 0))
		chispa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


# ------------------------------------------------------------------ cielo

static func tierra() -> Node3D:
	var root := MeshInstance3D.new()
	root.name = "Earth"
	root.mesh = K.sphere(22.0, 48, 24)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/3d/tierra_killawasi.gdshader")
	root.material_override = sm
	root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.rotation_degrees = Vector3(0, 47, 0)
	return root


static func sol() -> Node3D:
	var root := MeshInstance3D.new()
	root.name = "DistantSun"
	var quad := QuadMesh.new()
	quad.size = Vector2(150, 150)
	root.mesh = quad
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/3d/sol_killawasi.gdshader")
	root.material_override = sm
	root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func estrellas() -> Node3D:
	var root := MeshInstance3D.new()
	root.name = "Stars"
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261115
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 900:
		var y := rng.randf_range(0.03, 1.0)
		var a := rng.randf() * TAU
		var radial := sqrt(maxf(0.0, 1.0 - y * y))
		var dir := Vector3(cos(a) * radial, y, sin(a) * radial)
		var size := rng.randf_range(0.7, 1.5) * (1.9 if rng.randf() < 0.1 else 1.0)
		var brillo := rng.randf_range(0.5, 1.0)
		var tono := Color(1, 1, 1).lerp(Color("#BFD4FF") if rng.randf() < 0.5 else Color("#FFE9C4"), rng.randf() * 0.6) * brillo
		var c := dir * 420.0
		var right := dir.cross(Vector3.UP).normalized() * size
		var up := right.cross(dir).normalized() * size
		st.set_color(tono)
		# rombo de cuatro puntas: se lee como estrella incluso muy pequeño
		K._tri(st, [c + up, c + right, c - up], [-dir, -dir, -dir])
		K._tri(st, [c + up, c - up, c - right], [-dir, -dir, -dir])
	root.mesh = st.commit()
	root.material_override = K.mat("estrella")
	root.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## Luz, cielo y entorno listos para instanciar: `world/ambiente_lunar.tscn`.
static func ambiente() -> Node3D:
	var root := Node3D.new()
	root.name = "AmbienteLunar"
	root.set_script(load("res://world/ambiente_lunar.gd"))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#010409")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9D9BC6")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = env
	root.add_child(we, true)
	var key := DirectionalLight3D.new()
	key.name = "Sol"
	key.rotation_degrees = Vector3(-38, -52, 0)
	key.light_color = Color("#FFE2BD")
	key.light_energy = 1.05
	key.shadow_enabled = true
	key.shadow_blur = 1.6
	key.shadow_opacity = 0.8
	key.directional_shadow_max_distance = 70.0
	root.add_child(key, true)
	var fill := DirectionalLight3D.new()
	fill.name = "Relleno"
	fill.rotation_degrees = Vector3(-25, 125, 0)
	fill.light_color = Color("#A9B6F5")
	fill.light_energy = 0.22
	root.add_child(fill, true)
	var cielo := K.node(root, "Cielo")
	var boveda := MeshInstance3D.new()
	boveda.name = "Boveda"
	boveda.mesh = K.sphere(600.0, 32, 16)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/3d/cielo_killawasi.gdshader")
	boveda.material_override = sm
	boveda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cielo.add_child(boveda, true)
	var stars := (load("res://assets/3d/lunar_stars.tscn") as PackedScene).instantiate() as Node3D
	cielo.add_child(stars, true)
	var earth := (load("res://assets/3d/lunar_earth.tscn") as PackedScene).instantiate() as Node3D
	cielo.add_child(earth, true)
	earth.position = DIR_TIERRA.normalized() * PROFUNDIDAD_CIELO
	earth.rotation = Vector3(0.25, atan2(-DIR_TIERRA.x, -DIR_TIERRA.z) + 0.1, 0.0)
	var sun := (load("res://assets/3d/lunar_sun.tscn") as PackedScene).instantiate() as Node3D
	cielo.add_child(sun, true)
	sun.position = DIR_SOL.normalized() * PROFUNDIDAD_CIELO
	sun.rotation.y = atan2(DIR_SOL.x, DIR_SOL.z)
	return root


# ------------------------------------------------------------------ terreno

static func _altura(noise: FastNoiseLite, x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var h := noise.get_noise_2d(x * 4.0, z * 4.0) * 0.03
	if r > PLANO:
		var t := clampf((r - PLANO) / 26.0, 0.0, 1.0)
		h += noise.get_noise_2d(x, z) * 2.6 * t
		h += pow(maxf(r - 50.0, 0.0) / 35.0, 2.0) * 5.0
	return h


static func _pico(semilla: int, radio: float, alto: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var lados := 9
	var base: Array[Vector3] = []
	var medio: Array[Vector3] = []
	for i in lados:
		var a := TAU * i / lados
		var rb := radio * rng.randf_range(0.82, 1.18)
		base.append(Vector3(cos(a) * rb, -1.5, sin(a) * rb))
		var am := a + TAU / lados * 0.5
		var rm := radio * rng.randf_range(0.42, 0.62)
		medio.append(Vector3(cos(am) * rm, alto * rng.randf_range(0.34, 0.56), sin(am) * rm))
	var cima := Vector3(rng.randf_range(-0.12, 0.12) * radio, alto, rng.randf_range(-0.12, 0.12) * radio)
	var centro := Vector3(0, alto * 0.3, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caras: Array = []
	for i in lados:
		var j := (i + 1) % lados
		caras.append([base[i], base[j], medio[i]])
		caras.append([medio[i], base[j], medio[j]])
		caras.append([medio[i], medio[j], cima])
	for cara in caras:
		var a: Vector3 = cara[0]
		var b: Vector3 = cara[1]
		var c: Vector3 = cara[2]
		var fn := (b - a).cross(c - a).normalized()
		if fn.dot((a + b + c) / 3.0 - centro) < 0.0:
			fn = -fn
		var tono := Color("#77729A")
		tono = tono.lightened(rng.randf_range(0.04, 0.18)) if fn.y > 0.45 else tono.darkened(rng.randf_range(0.0, 0.16))
		st.set_color(tono)
		K._tri(st, [a, b, c], [fn, fn, fn])
	return st.commit()


## Suelo lunar con rocas, montañas y cráteres: `assets/3d/moon_world.tscn`.
static func terreno() -> Node3D:
	var root := Node3D.new()
	root.name = "MoonWorld"
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261114
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.035
	var tono := FastNoiseLite.new()
	tono.seed = 21
	tono.frequency = 0.03
	var n := 96
	var pts: Array[Vector3] = []
	for j in n + 1:
		for i in n + 1:
			var x := -LADO + 2.0 * LADO * i / n
			var z := -LADO + 2.0 * LADO * j / n
			if i > 0 and i < n and j > 0 and j < n:
				x += rng.randf_range(-0.62, 0.62)
				z += rng.randf_range(-0.62, 0.62)
			pts.append(Vector3(x, _altura(noise, x, z), z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n:
		for i in n:
			var a := pts[j * (n + 1) + i]
			var b := pts[j * (n + 1) + i + 1]
			var c := pts[(j + 1) * (n + 1) + i + 1]
			var d := pts[(j + 1) * (n + 1) + i]
			var tris := [[a, b, c], [a, c, d]] if rng.randf() < 0.5 else [[a, b, d], [b, c, d]]
			for tri in tris:
				var p0: Vector3 = tri[0]
				var p1: Vector3 = tri[1]
				var p2: Vector3 = tri[2]
				var fn := (p1 - p0).cross(p2 - p0).normalized()
				if fn.y < 0.0:
					fn = -fn
				var mid := (p0 + p1 + p2) / 3.0
				var v := tono.get_noise_2d(mid.x, mid.z) * 0.5 + rng.randf_range(-0.42, 0.42)
				st.set_color(BASE.lerp(CLARO, clampf(v, 0.0, 1.0)) if v > 0.0 else BASE.lerp(SOMBRA, clampf(-v, 0.0, 1.0)))
				K._tri(st, [p0, p1, p2], [fn, fn, fn])
	var surface := MeshInstance3D.new()
	surface.name = "Surface"
	surface.mesh = st.commit()
	surface.material_override = K.mat("regolito")
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(surface, true)

	# rocas: ocho mallas distintas repetidas con giro y tamaño
	var rocks := K.node(root, "Rocks")
	var variantes: Array[ArrayMesh] = []
	for k in 8:
		variantes.append(K.rock(1.0, 100 + k, Vector3(1.0, 0.62 + 0.06 * (k % 3), 0.88), 0.25, Color("#8580A0") if k % 2 == 0 else Color("#716C8E")))
	var fijas := [[Vector3(-19, 0, 17), 3.4], [Vector3(-14.5, 0, 20), 1.7], [Vector3(17, 0, 18.5), 3.8], [Vector3(11, 0, 20.5), 1.5],
		[Vector3(-3, 0, 21), 1.9], [Vector3(-24, 0, 4), 2.3], [Vector3(26, 0, 9), 2.0], [Vector3(-9, 0, -12), 1.1], [Vector3(22, 0, -10), 1.6],
		[Vector3(4.5, 0, 13.5), 0.55], [Vector3(-6.5, 0, 12.5), 0.5], [Vector3(-4, 0, 6.6), 0.32], [Vector3(8.5, 0, 11.5), 0.42], [Vector3(-10, 0, 3.5), 0.4]]
	var count := 0
	for f in fijas:
		count += 1
		_roca(rocks, variantes[count % 8], f[0], f[1], count * 47.0, noise)
	while count < 78:
		var ang := rng.randf() * TAU
		var dist := lerpf(12.0, 74.0, sqrt(rng.randf()))
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		if pos.x > 5.0 and pos.x < 22.0 and pos.z > -9.0 and pos.z < 10.5:
			continue
		if absf(pos.z - 8.0) < 2.6 and pos.x > -14.0 and pos.x < 22.0:
			continue
		if pos.distance_to(Vector3(-13.5, 0, 9.5)) < 5.0:
			continue
		count += 1
		var tam := rng.randf_range(0.25, 0.6)
		if rng.randf() < 0.3:
			tam = rng.randf_range(0.7, 1.3)
		if dist > 34.0 and rng.randf() < 0.3:
			tam = rng.randf_range(1.6, 3.2)
		_roca(rocks, variantes[count % 8], pos, tam, rng.randf() * 360.0, noise)

	# montañas del horizonte
	var montes := K.node(root, "Mountains")
	for k in 40:
		var lejos := k < 20
		var ang := TAU * k / 20.0 + rng.randf_range(-0.1, 0.1) + (0.0 if lejos else 0.16)
		var dist := rng.randf_range(70.0, 82.0) if lejos else rng.randf_range(57.0, 64.0)
		var radio := rng.randf_range(10.0, 16.0) if lejos else rng.randf_range(5.0, 8.0)
		var alto := rng.randf_range(8.0, 17.0) if lejos else rng.randf_range(2.5, 5.5)
		var monte := MeshInstance3D.new()
		monte.name = "Monte%d" % (k + 1)
		monte.mesh = _pico(500 + k, radio, alto)
		monte.material_override = K.mat("roca")
		monte.position = Vector3(cos(ang) * dist, 2.5, sin(ang) * dist)
		monte.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		montes.add_child(monte, true)

	# cráteres decorativos
	var crateres := K.node(root, "Craters")
	var lista := [[Vector3(-21, 0, -15), 3.2], [Vector3(15, 0, -19), 4.2], [Vector3(-5, 0, -27), 2.6], [Vector3(27, 0, 16), 3.0], [Vector3(-27, 0, 13), 2.4], [Vector3(6, 0, 24), 3.4]]
	var ci := 0
	for c in lista:
		ci += 1
		var crater := K.node(crateres, "Crater%d" % ci, c[0], Vector3(0, ci * 37.0, 0))
		_anillo_crater(crater, c[1], c[1] * 0.14)

	var ground := StaticBody3D.new()
	ground.name = "Ground"
	root.add_child(ground, true)
	var shape := CollisionShape3D.new()
	shape.name = "SurfaceCollision"
	var box := BoxShape3D.new()
	box.size = Vector3(LADO * 2.0, 1.0, LADO * 2.0)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	ground.add_child(shape, true)
	return root


static func _roca(parent: Node3D, malla: ArrayMesh, pos: Vector3, tam: float, giro: float, noise: FastNoiseLite) -> void:
	var roca := MeshInstance3D.new()
	roca.name = "Roca"
	roca.mesh = malla
	roca.material_override = K.mat("roca")
	roca.position = Vector3(pos.x, _altura(noise, pos.x, pos.z) + tam * 0.22, pos.z)
	roca.rotation_degrees = Vector3(0, giro, 0)
	roca.scale = Vector3.ONE * tam
	parent.add_child(roca, true)


# ------------------------------------------------------------------ camino y mundo montado

## Camino redondeado con luces ámbar cada 1,5 u.
static func camino(parent: Node3D, nombre: String, puntos: Array, ancho: float = 1.3) -> Node3D:
	var root := K.node(parent, nombre)
	var cinta := K.part(root, "Borde", K.tube(puntos, ancho * 0.5 + 0.14, 12, 2.2), "camino_borde", Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1, 0.045, 1))
	cinta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var losa := K.part(root, "Losa", K.tube(puntos, ancho * 0.5, 12, 2.2), "camino", Vector3(0, 0.02, 0), Vector3.ZERO, Vector3(1, 0.06, 1))
	losa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var luz := K.plate(0.5, 0.14, 0.03, 0.07, 0.008)
	var resto := 0.75
	var n := 0
	for i in puntos.size() - 1:
		var a: Vector3 = puntos[i]
		var b: Vector3 = puntos[i + 1]
		var largo := a.distance_to(b)
		var dir := (b - a).normalized()
		var s := resto
		while s < largo:
			n += 1
			var p := a + dir * s
			var baliza := K.part(root, "LuzCamino%d" % n, luz, "ambar", Vector3(p.x, 0.065, p.z), Vector3(-90, 0, 0))
			baliza.rotation.y = atan2(dir.x, dir.z) + PI * 0.5
			baliza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			s += 1.5
		resto = s - largo
	return root


static func _inst(parent: Node3D, ruta: String, nombre: String, pos: Vector3, giro: float = 0.0) -> Node3D:
	var nodo := (load(ruta) as PackedScene).instantiate() as Node3D
	parent.add_child(nodo, true)
	nodo.name = nombre
	nodo.position = pos
	nodo.rotation_degrees.y = giro
	return nodo


## Escena de integración del puesto 3: `world/moon_world.tscn`.
static func mundo() -> Node3D:
	var root := Node3D.new()
	root.name = "MoonWorld"
	var arte := "res://assets/3d/"
	_inst(root, "res://world/ambiente_lunar.tscn", "Ambiente", Vector3.ZERO)
	_inst(root, arte + "moon_world.tscn", "Terreno", Vector3.ZERO)
	_inst(root, arte + "lunar_lander.tscn", "Capsula", Vector3.ZERO)
	_inst(root, arte + "domo_lunar.tscn", "Domo", Vector3.ZERO)
	_inst(root, arte + "panel_solar.tscn", "PanelSolar", Vector3(-9.2, 0, 1.0), 196.0)
	_inst(root, arte + "panel_solar.tscn", "PanelSolar2", Vector3(8.2, 0, -1.6), 168.0)
	_inst(root, arte + "procesador_hielo.tscn", "ProcesadorHielo", Vector3(12.6, 0, 3.2), 180.0)
	_inst(root, arte + "tanque_agua.tscn", "TanqueAgua", Vector3(17.2, 0, 3.4), 180.0)
	_inst(root, arte + "generador_oxigeno.tscn", "GeneradorOxigeno", Vector3(14.2, 0, -4.6), 184.0)
	_inst(root, arte + "crater_hielo.tscn", "CraterHielo", Vector3(-13.5, 0, 9.5), 20.0)
	_inst(root, arte + "rover_lunar.tscn", "RoverLunar", Vector3(5.2, 0.07, 8.1), 118.0)
	camino(root, "Camino", [Vector3(0, 0, 4.4), Vector3(0, 0, 8.0), Vector3(9.5, 0, 8.0), Vector3(11.0, 0, 6.3), Vector3(19.6, 0, 6.3)])
	camino(root, "CaminoCrater", [Vector3(-0.2, 0, 8.0), Vector3(-9.6, 0, 8.6)])
	# tubería entre el procesador y el tanque
	K.part(root, "TuberiaAgua", K.tube([Vector3(14.46, 0.2, 3.38), Vector3(15.25, 0.2, 3.38), Vector3(15.25, 0.84, 3.7), Vector3(16.05, 0.84, 3.7)], 0.12, 10, 0.3), "turquesa")
	K.part(root, "AbrazaderaAgua", K.drum(0.165, 0.13, 12, 0.03), "ambar_mate", Vector3(15.25, 0.5, 3.54), Vector3(26, 0, 0))
	return root


## Escena de revisión con todas las piezas: `world/killawasi_revision.tscn` (F6).
static func revision() -> Node3D:
	var root := Node3D.new()
	root.name = "KillawasiRevision"
	root.set_script(load("res://world/killawasi_revision.gd"))
	var arte := "res://assets/3d/"
	_inst(root, "res://world/moon_world.tscn", "Mundo", Vector3.ZERO)
	_inst(root, arte + "astronauta.tscn", "Astronauta", Vector3(-3.6, 0, 9.6), 150.0)
	_inst(root, arte + "vicuna.tscn", "Vicuna", Vector3(-5.6, 0, 10.0), 160.0)
	_inst(root, arte + "reciclador_agua.tscn", "RecicladorAgua", Vector3(-15.5, 0, -2.6), 190.0)
	_inst(root, arte + "jardin_lunar.tscn", "JardinLunar", Vector3(-11.6, 0, -6.4), 186.0)
	_inst(root, arte + "bateria_lunar.tscn", "BateriaLunar", Vector3(-16.4, 0, 2.6), 196.0)
	_inst(root, arte + "pala.tscn", "Pala", Vector3(-2.2, 0.08, 11.6), 40.0)
	var pico := _inst(root, arte + "pico.tscn", "Pico", Vector3(-1.2, 0.12, 11.9), 0.0)
	pico.rotation_degrees = Vector3(0, 30, 90)
	_inst(root, arte + "taladro_manual.tscn", "TaladroManual", Vector3(-0.2, 0.3, 11.6), 120.0)
	_inst(root, arte + "taladro_mochila.tscn", "TaladroMochila", Vector3(1.2, 0.3, 11.9), 110.0)
	_inst(root, arte + "cristales_hielo.tscn", "CristalesHielo", Vector3(-6.8, 0, 11.4), 0.0)
	var nube := _inst(root, arte + "efecto_tormenta.tscn", "Tormenta", Vector3(0, 9.4, 0), 0.0)
	nube.scale = Vector3.ONE * 4.5
	nube.visible = false
	var cam := Camera3D.new()
	cam.name = "Camara"
	cam.current = true
	cam.far = 900.0
	root.add_child(cam, true)
	return root
