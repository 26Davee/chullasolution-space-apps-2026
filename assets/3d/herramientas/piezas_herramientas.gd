extends RefCounted
## Herramientas de Killawasi: pala, pico, taladro manual y taladro con mochila.
## Pivote en el agarre principal. La pala y los taladros apuntan hacia −Z; el pico sube por +Y.
## Marcadores: AgarrePrincipal, AgarreSecundario y Contacto (igual que en la primera versión).

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")


static func piezas() -> Dictionary:
	return {
		"pala": ["pala", pala, false],
		"pico": ["pico", pico, false],
		"taladro_manual": ["taladro_manual", taladro_manual, false],
		"taladro_mochila": ["taladro_mochila", taladro_mochila, false],
	}


static func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


static func pala() -> Node3D:
	var root := Node3D.new()
	root.name = "Pala"
	K.part(root, "AgarreD", K.tube([Vector3(0, 0, 0.02), Vector3(-0.12, 0, 0.09), Vector3(-0.12, 0, 0.25), Vector3(0.12, 0, 0.25), Vector3(0.12, 0, 0.09), Vector3(0, 0, 0.02)], 0.042, 10, 0.05), "cian")
	K.part(root, "CollarAgarre", K.drum(0.065, 0.08, 12, 0.02), "ambar_mate", Vector3(0, 0, -0.03), Vector3(90, 0, 0))
	K.part(root, "Asta", K.tube([Vector3(0, 0, 0), Vector3(0, 0, -0.56)], 0.046, 10), "marino")
	K.part(root, "Collar", K.drum(0.075, 0.11, 12, 0.025), "ambar_mate", Vector3(0, 0, -0.56), Vector3(90, 0, 0))
	var cazo := K.node(root, "Cuchara", Vector3(0, -0.02, -0.82), Vector3(78, 0, 0))
	var forma := PackedVector2Array([V(0.21, 0.24), V(-0.21, 0.24), V(-0.25, -0.02), V(-0.13, -0.25), V(0.13, -0.25), V(0.25, -0.02)])
	var canto := PackedVector2Array()
	var hueco := PackedVector2Array()
	for p in forma:
		canto.append(p * 1.12)
		hueco.append(p * 0.72)
	K.part(cazo, "Canto", K.plate_shape(canto, 0.045, 0.012), "cian")
	K.part(cazo, "Cazo", K.plate_shape(forma, 0.06, 0.012), "hueso", Vector3(0, 0, 0.005))
	K.part(cazo, "Fondo", K.plate_shape(hueco, 0.06, 0.012), "hueso_sombra", Vector3(0, -0.01, 0.012))
	K.part(cazo, "Zocalo", K.rbox(Vector3(0.14, 0.2, 0.09), 0.03, 2), "hueso", Vector3(0, 0.2, 0.04))
	K.marker(root, "AgarrePrincipal", Vector3(0, 0, 0.2))
	K.marker(root, "AgarreSecundario", Vector3(0, 0, -0.31))
	K.marker(root, "Contacto", Vector3(0, -0.08, -1.08))
	return root


static func pico() -> Node3D:
	var root := Node3D.new()
	root.name = "Pico"
	K.part(root, "Pomo", K.drum(0.07, 0.08, 12, 0.025), "cian", Vector3(0, -0.14, 0))
	K.part(root, "Mango", K.capsule(0.062, 0.34, 12), "hueso", Vector3(0, 0.05, 0))
	K.part(root, "AnilloMango", K.drum(0.07, 0.06, 12, 0.02), "cian", Vector3(0, 0.24, 0))
	K.part(root, "Asta", K.tube([Vector3(0, 0.22, 0), Vector3(0, 0.76, 0)], 0.042, 10), "marino")
	K.part(root, "Cabezal", K.rbox(Vector3(0.24, 0.18, 0.15), 0.05, 3), "hueso", Vector3(0, 0.8, 0))
	K.part(root, "Refuerzo", K.rbox(Vector3(0.16, 0.07, 0.13), 0.03, 2), "turquesa", Vector3(0.02, 0.91, 0))
	for sz in [-1.0, 1.0]:
		K.part(root, "Luz", K.plate(0.09, 0.07, 0.03, 0.025, 0.008), "ambar", Vector3(0, 0.8, sz * 0.07))
	K.part(root, "Punta", K.lathe([V(0, 0), V(0.062, 0), V(0.05, 0.2), V(0, 0.56)], 6, 0.0, 1.0), "acero", Vector3(-0.1, 0.81, 0), Vector3(0, 0, 104), Vector3(1, 1, 0.6))
	K.part(root, "Cincel", K.rbox(Vector3(0.34, 0.1, 0.05), 0.02, 2, Vector2(1.0, 1.0)), "acero", Vector3(0.27, 0.77, 0), Vector3(0, 0, -16))
	K.part(root, "FiloCincel", K.rbox(Vector3(0.07, 0.14, 0.055), 0.02, 2), "cian", Vector3(0.44, 0.72, 0), Vector3(0, 0, -16))
	K.marker(root, "AgarrePrincipal", Vector3.ZERO)
	K.marker(root, "AgarreSecundario", Vector3(0, 0.39, 0))
	K.marker(root, "Contacto", Vector3(-0.64, 0.68, 0))
	return root


static func _broca(parent: Node3D, largo: float, radio: float) -> Node3D:
	var broca := K.node(parent, "Broca")
	K.part(broca, "Eje", K.tube([Vector3(0, 0, 0.05), Vector3(0, 0, -largo * 0.8)], radio * 0.38, 8), "acero_osc")
	var pasos := 5
	for i in pasos:
		var t := float(i) / pasos
		var r := lerpf(radio, radio * 0.35, t)
		K.part(broca, "Espira", K.lathe([V(0, 0), V(r, 0), V(r * 0.55, largo / pasos * 1.05), V(0, largo / pasos * 1.05)], 10, 30.0), "acero", Vector3(0, 0, -t * largo), Vector3(-90, 0, 0))
	K.marker(broca, "Contacto", Vector3(0, 0, -largo))
	return broca


static func _cuerpo_taladro(root: Node3D, grande: bool) -> void:
	var largo := 0.52 if grande else 0.42
	K.part(root, "Carcasa", K.rbox(Vector3(0.27, 0.27, largo), 0.09, 3), "hueso", Vector3(0, 0.2, -0.1))
	K.part(root, "Tapa", K.rbox(Vector3(0.19, 0.07, largo * 0.7), 0.03, 2), "marino", Vector3(0, 0.35, -0.08))
	K.part(root, "Motor", K.drum(0.155, 0.11, 14, 0.035), "turquesa", Vector3(0, 0.2, -0.1 - largo * 0.5 - 0.02), Vector3(90, 0, 0))
	K.part(root, "Mandril", K.drum(0.1 if not grande else 0.12, 0.12, 12, 0.03), "acero_osc", Vector3(0, 0.2, -0.1 - largo * 0.5 - 0.12), Vector3(90, 0, 0))
	for sx in [-1.0, 1.0]:
		K.part(root, "Luz", K.plate(0.11, 0.08, 0.03, 0.03, 0.008), "ambar", Vector3(sx * 0.135, 0.22, 0.0), Vector3(0, sx * 90.0, 0))
	K.part(root, "Empunadura", K.rbox(Vector3(0.115, 0.32, 0.15), 0.05, 3), "marino", Vector3(0, -0.02, 0.03), Vector3(12, 0, 0))
	K.part(root, "Gatillo", K.rbox(Vector3(0.06, 0.09, 0.06), 0.02, 2), "cian", Vector3(0, 0.05, -0.07))
	K.part(root, "Seguro", K.sphere(0.03, 8, 4), "ambar_mate", Vector3(0.062, 0.09, 0.03))
	K.marker(root, "AgarrePrincipal", Vector3(0, 0.01, 0.015))


static func taladro_manual() -> Node3D:
	var root := Node3D.new()
	root.name = "TaladroManual"
	_cuerpo_taladro(root, false)
	K.part(root, "Bateria", K.rbox(Vector3(0.26, 0.13, 0.34), 0.05, 3), "hueso", Vector3(0, -0.22, 0.06))
	K.part(root, "FranjaBateria", K.rbox(Vector3(0.275, 0.05, 0.24), 0.02, 2), "turquesa", Vector3(0, -0.23, 0.06))
	var broca := _broca(root, 0.34, 0.085)
	broca.position = Vector3(0, 0.2, -0.5)
	K.marker(root, "AgarreSecundario", Vector3(0, 0.2, -0.32))
	return root


static func taladro_mochila() -> Node3D:
	var root := Node3D.new()
	root.name = "TaladroMochila"
	_cuerpo_taladro(root, true)
	K.part(root, "Barril", K.drum(0.14, 0.2, 14, 0.03), "acero_osc", Vector3(0, 0.2, -0.5), Vector3(90, 0, 0))
	K.part(root, "AnilloBarril", K.drum(0.155, 0.06, 14, 0.02), "ambar_mate", Vector3(0, 0.2, -0.42), Vector3(90, 0, 0))
	K.part(root, "AsaLateral", K.tube([Vector3(-0.12, 0.2, -0.22), Vector3(-0.36, 0.2, -0.22), Vector3(-0.36, 0.2, -0.4), Vector3(-0.12, 0.2, -0.4)], 0.036, 8, 0.06), "marino")
	K.part(root, "GomaAsa", K.tube([Vector3(-0.36, 0.2, -0.25), Vector3(-0.36, 0.2, -0.37)], 0.05, 10), "cian")
	var broca := _broca(root, 0.66, 0.12)
	broca.position = Vector3(0, 0.2, -0.6)
	K.marker(root, "AgarreSecundario", Vector3(-0.36, 0.2, -0.31))
	# mochila de potencia: dos celdas sobre un bastidor
	var mochila := K.node(root, "Mochila", Vector3(0.65, 0.21, 0.49))
	K.part(mochila, "Bastidor", K.rbox(Vector3(0.62, 0.5, 0.1), 0.045, 2), "turquesa", Vector3(0, 0, -0.03))
	for sx in [-1.0, 1.0]:
		K.part(mochila, "Celda", K.rbox(Vector3(0.28, 0.46, 0.22), 0.07, 3), "hueso", Vector3(sx * 0.155, 0, 0.1))
		K.part(mochila, "Luz", K.plate(0.13, 0.07, 0.03, 0.025, 0.008), "ambar", Vector3(sx * 0.155, 0.12, 0.215))
		for r in 3:
			K.part(mochila, "Ranura", K.rbox(Vector3(0.15, 0.028, 0.02), 0.008, 1), "marino", Vector3(sx * 0.155, -0.03 - r * 0.055, 0.213))
		K.part(mochila, "Correa", K.tube([Vector3(sx * 0.2, 0.2, -0.06), Vector3(sx * 0.2, 0.26, -0.26), Vector3(sx * 0.2, -0.16, -0.26), Vector3(sx * 0.2, -0.2, -0.06)], 0.028, 8, 0.07), "marino")
	K.part(mochila, "Asa", K.tube([Vector3(-0.1, 0.23, 0.08), Vector3(-0.1, 0.34, 0.08), Vector3(0.1, 0.34, 0.08), Vector3(0.1, 0.23, 0.08)], 0.026, 8, 0.05), "hueso_sombra")
	K.marker(mochila, "AnclaMochila", Vector3(0, 0, -0.081))
	K.part(root, "Cable", K.tube([Vector3(0, 0.12, 0.14), Vector3(0, 0.0, 0.42), Vector3(0.3, -0.16, 0.56), Vector3(0.62, -0.1, 0.5), Vector3(0.65, 0.0, 0.5)], 0.034, 8, 0.14), "marino_osc")
	K.marker(root, "CableInicio", Vector3(0, 0.12, 0.14))
	K.marker(root, "CableFin", Vector3(0.65, 0.0, 0.5))
	return root
