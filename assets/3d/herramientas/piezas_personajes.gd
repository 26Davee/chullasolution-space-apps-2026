extends RefCounted
## Personajes de Killawasi: astronauta (lámina A2) y vicuña guía (lámina A1).
## Miran hacia −Z. Cada articulación es un nodo propio para poder animarla.
## Los nombres de pivotes, anclas y poses son los mismos de la primera versión.

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")


static func piezas() -> Dictionary:
	return {
		"astronauta": ["astronauta", astronauta, false],
		"vicuna": ["vicuna", vicuna, false],
	}


# ------------------------------------------------------------------ astronauta

static func astronauta() -> Node3D:
	var root := Node3D.new()
	root.name = "Astronauta"
	var cadera := K.node(root, "Cadera", Vector3(0, 0.62, 0))
	var torso := K.node(cadera, "Torso", Vector3(0, 0.1, 0))
	K.part(torso, "Cuerpo", K.rbox(Vector3(0.62, 0.52, 0.44), 0.19, 4), "hueso", Vector3(0, 0.27, 0))
	K.part(torso, "PanelPecho", K.rbox(Vector3(0.27, 0.16, 0.06), 0.03, 2), "marino", Vector3(0, 0.33, -0.21))
	K.part(torso, "Indicador", K.rbox(Vector3(0.075, 0.065, 0.03), 0.012, 1), "ambar", Vector3(-0.055, 0.335, -0.238))
	K.part(torso, "IndicadorTurquesa", K.rbox(Vector3(0.075, 0.065, 0.03), 0.012, 1), "cian_luz", Vector3(0.055, 0.335, -0.238))
	for sx in [-1.0, 1.0]:
		K.part(torso, "Tirante", K.rbox(Vector3(0.07, 0.34, 0.47), 0.03, 2), "marino", Vector3(sx * 0.2, 0.36, 0.0))
	# mochila octogonal con dos tanques
	K.part(torso, "Mochila", K.plate_shape(K.octagon(0.46, 0.54, 0.13), 0.22, 0.04), "hueso", Vector3(0, 0.3, 0.31))
	K.part(torso, "CubiertaMochila", K.plate_shape(K.octagon(0.32, 0.38, 0.09), 0.05, 0.012), "hueso_sombra", Vector3(0, 0.3, 0.43))
	for i in 3:
		K.part(torso, "Ventila%d" % (i + 1), K.rbox(Vector3(0.16, 0.035, 0.03), 0.012, 1), "marino", Vector3(0, 0.22 + i * 0.08, 0.455))
	K.part(torso, "TanqueIzquierdo", K.capsule(0.095, 0.46, 12), "hueso", Vector3(-0.29, 0.3, 0.27))
	K.part(torso, "TanqueDerecho", K.capsule(0.095, 0.46, 12), "hueso", Vector3(0.29, 0.3, 0.27))
	K.part(torso, "ParcheMision", K.rbox(Vector3(0.09, 0.09, 0.02), 0.02, 1), "marino", Vector3(0.14, 0.14, 0.425))
	K.part(torso, "LunaParche", K.sphere(0.028, 8, 4), "ambar_mate", Vector3(0.14, 0.14, 0.437), Vector3.ZERO, Vector3(1, 1, 0.3))
	K.marker(torso, "AnclaCarga", Vector3(0, 0.2, -0.46))
	K.marker(torso, "AnclaMochila", Vector3(0, 0.3, 0.46))

	# cabeza: casco grande, visor oscuro sin rostro
	var cabeza := K.node(torso, "Cabeza", Vector3(0, 0.5, 0))
	K.part(cabeza, "Cuello", K.drum(0.21, 0.11, 16, 0.04), "cian", Vector3(0, 0.03, 0))
	K.part(cabeza, "Casco", K.sphere(0.4, 28, 14), "hueso", Vector3(0, 0.37, 0))
	K.part(cabeza, "MarcoVisor", K.sphere(0.345, 24, 12), "hueso_sombra", Vector3(0, 0.36, -0.09), Vector3.ZERO, Vector3(1.0, 0.93, 1.0))
	K.part(cabeza, "Visor", K.sphere(0.33, 24, 12), "visor", Vector3(0, 0.36, -0.125), Vector3.ZERO, Vector3(0.98, 0.9, 1.0))
	K.part(cabeza, "BrilloVisor", K.sphere(0.03, 8, 4), "blanco", Vector3(-0.09, 0.47, -0.425), Vector3.ZERO, Vector3(1.4, 1, 0.4))
	K.part(cabeza, "ComunicadorIzq", K.drum(0.13, 0.11, 16, 0.04), "cian", Vector3(-0.385, 0.35, 0.02), Vector3(0, 0, 90))
	K.part(cabeza, "ComunicadorDer", K.drum(0.13, 0.11, 16, 0.04), "cian", Vector3(0.385, 0.35, 0.02), Vector3(0, 0, 90))
	K.part(cabeza, "SoporteLampara", K.rbox(Vector3(0.24, 0.05, 0.14), 0.02, 2), "hueso_sombra", Vector3(0, 0.755, -0.06))
	K.part(cabeza, "LamparaAmbar", K.rbox(Vector3(0.2, 0.06, 0.11), 0.025, 2), "ambar", Vector3(0, 0.79, -0.06))

	# brazos
	for lado in [-1.0, 1.0]:
		var sufijo := "Izq" if lado < 0.0 else "Der"
		var hombro := K.node(torso, "Hombro" + sufijo, Vector3(lado * 0.345, 0.42, 0), Vector3(0, 0, lado * 24.0))
		K.part(hombro, "Hombrera", K.sphere(0.155, 16, 8), "cian", Vector3(0, 0.0, 0), Vector3.ZERO, Vector3(1.0, 0.82, 1.0))
		K.part(hombro, "Brazo", K.capsule(0.118, 0.34, 14), "hueso", Vector3(0, -0.13, 0))
		var codo := K.node(hombro, "Codo", Vector3(0, -0.26, 0))
		K.part(codo, "Union", K.drum(0.125, 0.045, 14, 0.015), "cian", Vector3(0, 0.0, 0))
		K.part(codo, "Antebrazo", K.capsule(0.112, 0.3, 14), "hueso", Vector3(0, -0.11, 0))
		var mano := K.node(codo, "Mano", Vector3(0, -0.24, 0))
		K.part(mano, "Puno", K.drum(0.12, 0.05, 14, 0.015), "turquesa_osc", Vector3(0, 0.03, 0))
		K.part(mano, "Guante", K.sphere(0.135, 16, 8), "cian", Vector3(0, -0.07, 0), Vector3.ZERO, Vector3(0.95, 1.1, 1.0))
		K.part(mano, "Pulgar", K.sphere(0.058, 10, 5), "cian", Vector3(lado * -0.03, -0.05, -0.12))
		K.marker(mano, "AnclaHerramienta", Vector3(0, -0.09, -0.06))

	# cintura y piernas
	K.part(cadera, "PelvisTraje", K.rbox(Vector3(0.52, 0.26, 0.38), 0.12, 3), "hueso", Vector3(0, 0.0, 0))
	K.part(cadera, "Cinturon", K.rbox(Vector3(0.57, 0.085, 0.43), 0.035, 2), "marino", Vector3(0, 0.11, 0))
	K.part(cadera, "Hebilla", K.rbox(Vector3(0.11, 0.1, 0.04), 0.02, 1), "marino_osc", Vector3(0, 0.11, -0.215))
	for lado in [-1.0, 1.0]:
		var sufijo := "Izq" if lado < 0.0 else "Der"
		var muslo := K.node(cadera, "Muslo" + sufijo, Vector3(lado * 0.155, -0.04, 0))
		K.part(muslo, "Pantalon", K.capsule(0.148, 0.34, 14), "hueso", Vector3(0, -0.09, 0))
		var rodilla := K.node(muslo, "Rodilla", Vector3(0, -0.19, 0))
		K.part(rodilla, "Rodillera", K.sphere(0.095, 14, 7), "cian", Vector3(0, -0.01, -0.115), Vector3.ZERO, Vector3(1, 1, 0.55))
		K.part(rodilla, "Pierna", K.capsule(0.146, 0.34, 14), "hueso", Vector3(0, -0.09, 0))
		var tobillo := K.node(rodilla, "Tobillo", Vector3(0, -0.19, 0))
		K.part(tobillo, "Bota", K.rbox(Vector3(0.29, 0.21, 0.42), 0.1, 3), "marino", Vector3(0, -0.085, -0.045))
		K.part(tobillo, "Suela", K.rbox(Vector3(0.31, 0.07, 0.45), 0.03, 2), "marino_osc", Vector3(0, -0.165, -0.045))
	_poses_astronauta(root)
	return root


# ------------------------------------------------------------------ vicuña guía

static func vicuna() -> Node3D:
	var root := Node3D.new()
	root.name = "Vicuna"
	var cuerpo := K.node(root, "Cuerpo", Vector3(0, 0.84, 0))
	K.part(cuerpo, "Tronco", K.capsule(0.33, 1.12, 18), "canela", Vector3(0, 0, 0.02), Vector3(90, 0, 0))
	K.part(cuerpo, "Pecho", K.sphere(0.3, 18, 9), "crema", Vector3(0, -0.03, -0.36), Vector3.ZERO, Vector3(0.85, 0.95, 0.8))
	# traje turquesa con parche de media luna
	K.part(cuerpo, "Traje", K.capsule(0.365, 0.86, 18), "turquesa", Vector3(0, 0.01, 0.1), Vector3(90, 0, 0))
	K.part(cuerpo, "RibeteDelantero", K.torus(0.345, 0.04, 22, 8), "turquesa_osc", Vector3(0, 0.01, -0.2), Vector3(90, 0, 0))
	K.part(cuerpo, "RibeteTrasero", K.torus(0.345, 0.04, 22, 8), "turquesa_osc", Vector3(0, 0.01, 0.4), Vector3(90, 0, 0))
	for sx in [-1.0, 1.0]:
		var parche := K.node(cuerpo, "Parche", Vector3(sx * 0.352, 0.0, 0.1), Vector3(0, sx * 90.0, 0))
		K.part(parche, "Fondo", K.drum(0.13, 0.03, 16, 0.01), "marino", Vector3.ZERO, Vector3(90, 0, 0))
		K.part(parche, "Luna", K.drum(0.085, 0.03, 16, 0.01), "ambar_mate", Vector3(0, 0, 0.008), Vector3(90, 0, 0))
		K.part(parche, "Sombra", K.drum(0.07, 0.03, 16, 0.01), "marino", Vector3(0.035, 0.02, 0.016), Vector3(90, 0, 0))
	# dos tanques sobre el lomo
	for sx in [-1.0, 1.0]:
		K.part(cuerpo, "Tanque", K.capsule(0.13, 0.56, 14), "hueso", Vector3(sx * 0.15, 0.4, 0.14), Vector3(90, 0, 0))
		K.part(cuerpo, "LuzTanque", K.sphere(0.035, 8, 4), "ambar", Vector3(sx * 0.15, 0.4, -0.15))
	K.part(cuerpo, "CorreaTanques", K.rbox(Vector3(0.6, 0.1, 0.14), 0.04, 2), "turquesa_osc", Vector3(0, 0.36, 0.14))
	var cola := K.node(cuerpo, "Cola", Vector3(0, 0.12, 0.58))
	K.part(cola, "Pompon", K.sphere(0.15, 14, 7), "canela", Vector3(0, 0.02, 0.06))
	K.part(cola, "Punta", K.sphere(0.09, 12, 6), "crema", Vector3(0, 0.06, 0.15))

	# cuello y cabeza
	var cuello := K.node(cuerpo, "Cuello", Vector3(0, 0.16, -0.38), Vector3(-14, 0, 0))
	K.part(cuello, "Cuello", K.capsule(0.17, 0.56, 14), "canela", Vector3(0, 0.16, 0))
	K.part(cuello, "Pechera", K.sphere(0.5, 14, 8), "crema", Vector3(0, 0.1, -0.075), Vector3.ZERO, Vector3(0.27, 0.52, 0.24))
	K.part(cuello, "AroCasco", K.torus(0.25, 0.065, 24, 10), "turquesa", Vector3(0, 0.36, 0))
	for sx in [-1.0, 1.0]:
		K.part(cuello, "Auricular", K.drum(0.09, 0.07, 14, 0.02), "cian", Vector3(sx * 0.3, 0.36, 0), Vector3(0, 0, 90))
	var cabeza := K.node(cuello, "Cabeza", Vector3(0, 0.42, 0), Vector3(14, 0, 0))
	K.part(cabeza, "Craneo", K.sphere(0.3, 22, 11), "canela", Vector3(0, 0.22, 0), Vector3.ZERO, Vector3(1.0, 0.95, 1.02))
	K.part(cabeza, "Hocico", K.sphere(0.17, 16, 8), "crema", Vector3(0, 0.13, -0.26), Vector3.ZERO, Vector3(1.0, 0.8, 1.0))
	K.part(cabeza, "Nariz", K.sphere(0.045, 10, 5), "negro", Vector3(0, 0.17, -0.42), Vector3.ZERO, Vector3(1.2, 0.8, 0.7))
	K.part(cabeza, "Flequillo", K.sphere(0.12, 12, 6), "canela_osc", Vector3(0, 0.49, -0.1), Vector3.ZERO, Vector3(1.1, 0.6, 1.0))
	for sx in [-1.0, 1.0]:
		K.part(cabeza, "Ojo", K.sphere(0.075, 14, 7), "negro", Vector3(sx * 0.165, 0.27, -0.235), Vector3.ZERO, Vector3(0.8, 1.05, 0.7))
		K.part(cabeza, "BrilloOjo", K.sphere(0.024, 8, 4), "blanco", Vector3(sx * 0.15, 0.3, -0.285))
		K.part(cabeza, "Mejilla", K.sphere(0.05, 10, 5), "rosa", Vector3(sx * 0.2, 0.15, -0.21), Vector3.ZERO, Vector3(1, 0.7, 0.5))
		var oreja := K.node(cabeza, "Oreja" + ("Izq" if sx < 0.0 else "Der"), Vector3(sx * 0.15, 0.43, 0.03), Vector3(-6, 0, sx * -14.0))
		K.part(oreja, "Pabellon", K.sphere(0.5, 14, 8), "canela", Vector3(0, 0.2, 0), Vector3.ZERO, Vector3(0.2, 0.46, 0.13))
		K.part(oreja, "Interior", K.sphere(0.5, 12, 6), "rosa", Vector3(0, 0.19, -0.035), Vector3.ZERO, Vector3(0.12, 0.34, 0.07))
	var burbuja := K.part(cabeza, "Burbuja", K.sphere(0.63, 32, 16), "burbuja", Vector3(0, 0.32, -0.02))
	burbuja.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	K.part(cabeza, "ReflejoBurbuja", K.sphere(0.07, 10, 5), "blanco", Vector3(-0.3, 0.72, -0.4), Vector3(0, 0, 40), Vector3(1.6, 0.5, 0.2))
	K.marker(cabeza, "AnclaGuia", Vector3(0, 1.05, 0))

	# patas
	var patas := {"PataDelanteraIzq": Vector3(-0.19, -0.2, -0.32), "PataDelanteraDer": Vector3(0.19, -0.2, -0.32),
		"PataTraseraIzq": Vector3(-0.19, -0.2, 0.42), "PataTraseraDer": Vector3(0.19, -0.2, 0.42)}
	for nombre in patas:
		var pata := K.node(cuerpo, nombre, patas[nombre])
		K.part(pata, "Muslo", K.capsule(0.11, 0.44, 12), "canela", Vector3(0, -0.1, 0))
		var rodilla := K.node(pata, "Rodilla", Vector3(0, -0.28, 0))
		K.part(rodilla, "Cana", K.capsule(0.088, 0.38, 12), "crema", Vector3(0, -0.12, 0))
		var pezuna := K.node(rodilla, "Pezuna", Vector3(0, -0.3, 0))
		K.part(pezuna, "Casco", K.drum(0.1, 0.13, 12, 0.035), "canela_osc", Vector3(0, 0.005, -0.01))
	_poses_vicuna(root)
	return root


# ------------------------------------------------------------------ poses

static func _clip(root: Node3D, library: AnimationLibrary, label: String, frames: Array, duration: float, loop: bool) -> void:
	var clip := Animation.new()
	clip.length = duration
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var paths := {}
	for frame in frames:
		for path in frame:
			paths[path] = true
	for path in paths:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath(path))
		var baseline: Quaternion = (root.get_node(path) as Node3D).quaternion
		for i in frames.size():
			var angles: Vector3 = frames[i].get(path, Vector3.ZERO)
			var pose := Quaternion.from_euler(angles * (PI / 180.0))
			clip.rotation_track_insert_key(track, duration * i / maxi(1, frames.size() - 1), baseline * pose)
	library.add_animation(label, clip)


static func _player(root: Node3D) -> AnimationLibrary:
	var player := AnimationPlayer.new()
	player.name = "Poses"
	root.add_child(player, true)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)
	return library


static func _poses_astronauta(root: Node3D) -> void:
	var library := _player(root)
	var left := "Cadera/Torso/HombroIzq"
	var right := "Cadera/Torso/HombroDer"
	var paths := [left, right, left + "/Codo", right + "/Codo", "Cadera/MusloIzq", "Cadera/MusloDer",
		"Cadera/MusloIzq/Rodilla", "Cadera/MusloDer/Rodilla", "Cadera/Torso", "Cadera/Torso/Cabeza"]
	var rest := {}
	for path in paths:
		rest[path] = Vector3.ZERO
	_clip(root, library, "reposo", [rest, rest], 1.0, true)
	var walk: Array = []
	for i in 5:
		var sweep := cos(i * PI * 0.5) * 24.0
		var step := rest.duplicate()
		step[left] = Vector3(sweep * 0.9, 0, 0)
		step[right] = Vector3(-sweep * 0.9, 0, 0)
		step[left + "/Codo"] = Vector3(18, 0, 0)
		step[right + "/Codo"] = Vector3(18, 0, 0)
		step["Cadera/MusloIzq"] = Vector3(-sweep, 0, 0)
		step["Cadera/MusloDer"] = Vector3(sweep, 0, 0)
		step["Cadera/MusloIzq/Rodilla"] = Vector3(-maxf(0.0, -sweep) * 1.2, 0, 0)
		step["Cadera/MusloDer/Rodilla"] = Vector3(-maxf(0.0, sweep) * 1.2, 0, 0)
		walk.append(step)
	_clip(root, library, "caminar", walk, 0.92, true)
	var dig := rest.duplicate()
	dig["Cadera/Torso"] = Vector3(23, 0, 0)
	dig[left] = Vector3(52, 0, 22)
	dig[right] = Vector3(46, 0, -22)
	dig[left + "/Codo"] = Vector3(38, 0, 0)
	dig[right + "/Codo"] = Vector3(34, 0, 0)
	dig["Cadera/Torso/Cabeza"] = Vector3(8, 0, 0)
	var dig_up := dig.duplicate()
	dig_up["Cadera/Torso"] = Vector3(10, 0, 0)
	dig_up[left] = Vector3(78, 0, 22)
	dig_up[right] = Vector3(72, 0, -22)
	var carry := rest.duplicate()
	carry[left] = Vector3(40, 0, 24)
	carry[right] = Vector3(40, 0, -24)
	carry[left + "/Codo"] = Vector3(56, 0, 0)
	carry[right + "/Codo"] = Vector3(56, 0, 0)
	var touch := rest.duplicate()
	touch[right] = Vector3(84, 0, -20)
	touch[right + "/Codo"] = Vector3(14, 0, 0)
	touch["Cadera/Torso/Cabeza"] = Vector3(-8, 0, 0)
	_clip(root, library, "cavar", [dig_up, dig, dig_up], 1.24, true)
	_clip(root, library, "cargar_hielo", [carry, carry], 1.0, false)
	_clip(root, library, "tocar_domo", [rest, touch, touch], 1.2, false)


static func _poses_vicuna(root: Node3D) -> void:
	var library := _player(root)
	var neck := "Cuerpo/Cuello"
	var head := neck + "/Cabeza"
	var ear_l := head + "/OrejaIzq"
	var ear_r := head + "/OrejaDer"
	var leg := "Cuerpo/PataDelanteraDer"
	var knee := leg + "/Rodilla"
	var tail := "Cuerpo/Cola"
	var rest := {neck: Vector3.ZERO, head: Vector3.ZERO, ear_l: Vector3.ZERO, ear_r: Vector3.ZERO, leg: Vector3.ZERO, knee: Vector3.ZERO, tail: Vector3.ZERO}
	_clip(root, library, "respirar", [rest, {neck: Vector3(-3, 0, 0), tail: Vector3(0, 12, 0)}, rest], 2.2, true)
	_clip(root, library, "hablar", [rest, {head: Vector3(6, 5, 0), ear_l: Vector3(0, 0, -6)}, {head: Vector3(-4, -5, 0), ear_r: Vector3(0, 0, 6)}, rest], 0.76, true)
	_clip(root, library, "senal", [rest, {leg: Vector3(64, 0, -8), knee: Vector3(-24, 0, 0), head: Vector3(-3, 12, -5)}, rest], 1.5, false)
	_clip(root, library, "aviso", [rest, {head: Vector3(7, 0, -9), ear_l: Vector3(-16, 0, -14), ear_r: Vector3(-14, 0, 14)}, rest], 1.4, false)
	_clip(root, library, "celebrar", [rest, {neck: Vector3(10, 0, 0), leg: Vector3(46, 0, -9), head: Vector3(-10, -6, 0), tail: Vector3(0, 25, 0)}, {head: Vector3(-8, 8, 0), leg: Vector3(30, 0, 0), tail: Vector3(0, -25, 0)}, rest], 1.2, false)
