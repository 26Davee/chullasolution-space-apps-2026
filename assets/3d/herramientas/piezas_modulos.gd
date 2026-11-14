extends RefCounted
## Módulos de Killawasi: generador de oxígeno, reciclador de agua, jardín lunar, batería y rover.
## Se modelan con el frente hacia +Z; el generador de escenas los gira hacia −Z.

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")


static func piezas() -> Dictionary:
	return {
		"generador": ["generador_oxigeno", generador, true],
		"reciclador": ["reciclador_agua", reciclador, true],
		"jardin": ["jardin_lunar", jardin, true],
		"bateria": ["bateria_lunar", bateria, true],
		"rover": ["rover_lunar", rover, true],
	}


static func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


# ------------------------------------------------------------------ generador de oxígeno

static func generador() -> Node3D:
	var root := StaticBody3D.new()
	root.name = "GeneradorOxigeno"
	K.part(root, "Plataforma", K.rbox(Vector3(2.5, 0.34, 1.36), 0.11), "turquesa", Vector3(0.38, 0.17, 0))
	K.part(root, "Faldon", K.rbox(Vector3(2.3, 0.12, 1.2), 0.04), "turquesa_osc", Vector3(0.38, 0.06, 0))
	K.led(root, "LuzPlataforma", Vector3(0.38, 0.17, 0.685), 0.6, 0.11)
	var xs := [-0.22, 0.86]
	for i in 2:
		var tanque := K.node(root, "Deposito%d" % (i + 1), Vector3(xs[i], 0.32, 0))
		K.part(tanque, "Cuerpo", K.lathe([V(0, 0), V(0.5, 0), V(0.56, 0.1), V(0.56, 1.42), V(0.36, 1.82), V(0, 1.82)], 12, 30.0, 0.45), "hueso")
		K.part(tanque, "Faja", K.lathe([V(0.57, 0.0), V(0.6, 0.04), V(0.6, 0.2), V(0.57, 0.24)], 12, 30.0, 0.45), "turquesa")
		K.part(tanque, "Tapa", K.drum(0.33, 0.2, 14, 0.06), "turquesa", Vector3(0, 1.9, 0))
		var luz := K.led(tanque, "Estado", Vector3(0, 0.82, 0.525), 0.17, 0.62)
		luz.name = "Estado"
	# puente de tubería
	K.part(root, "Puente", K.tube([Vector3(-0.22, 2.3, 0), Vector3(-0.22, 2.92, 0), Vector3(1.56, 2.92, 0), Vector3(1.56, 0.3, 0)], 0.135, 12, 0.34), "turquesa")
	K.part(root, "Bajada", K.tube([Vector3(0.86, 2.3, 0), Vector3(0.86, 2.9, 0)], 0.135, 12), "turquesa")
	K.part(root, "AbrazaderaPuente", K.drum(0.2, 0.24, 14, 0.04), "ambar_mate", Vector3(0.32, 2.92, 0), Vector3(0, 0, 90))
	K.part(root, "AbrazaderaBajada", K.drum(0.18, 0.14, 14, 0.03), "ambar_mate", Vector3(1.56, 1.25, 0))
	K.part(root, "BridaBase", K.drum(0.2, 0.12, 14, 0.03), "turquesa_osc", Vector3(1.56, 0.4, 0))
	# caja de control
	var caja := K.node(root, "Control", Vector3(-1.5, 0, 0.12))
	for sx in [-1.0, 1.0]:
		K.part(caja, "Zapata", K.rbox(Vector3(0.2, 0.14, 0.62), 0.05), "turquesa", Vector3(sx * 0.22, 0.07, 0))
	K.part(caja, "Caja", K.rbox(Vector3(0.66, 0.56, 0.66), 0.12), "hueso", Vector3(0, 0.42, 0))
	K.part(caja, "Pantalla", K.plate(0.5, 0.3, 0.05, 0.08, 0.012), "marino_osc", Vector3(0, 0.42, 0.325))
	for lx in [-0.14, 0.0, 0.14]:
		K.part(caja, "Luz", K.plate(0.085, 0.18, 0.05, 0.04, 0.01), "ambar", Vector3(lx, 0.42, 0.34))
	K.part(root, "TuboControl", K.tube([Vector3(-1.5, 0.66, 0.12), Vector3(-1.5, 0.98, 0.12), Vector3(-0.72, 0.98, 0.12)], 0.095, 10, 0.2), "turquesa")
	K.part(root, "BridaControl", K.drum(0.14, 0.1, 12, 0.03), "turquesa_osc", Vector3(-0.78, 0.98, 0.12), Vector3(0, 0, 90))
	K.collision(root, Vector3(0.1, 1.5, 0), Vector3(3.5, 3.0, 1.4), "")
	return root


# ------------------------------------------------------------------ reciclador de agua

static func reciclador() -> Node3D:
	var root := Node3D.new()
	root.name = "RecicladorAgua"
	K.part(root, "Base", K.rbox(Vector3(2.36, 0.34, 1.36), 0.11), "turquesa", Vector3(0, 0.17, 0))
	for lx in [-0.6, 0.6]:
		K.led(root, "LuzBase", Vector3(lx, 0.17, 0.685), 0.4, 0.1)
	K.part(root, "Columna", K.rbox(Vector3(0.6, 1.56, 1.22), 0.16), "hueso", Vector3(-0.82, 1.08, 0))
	K.part(root, "Respaldo", K.rbox(Vector3(2.12, 1.56, 0.56), 0.16), "hueso", Vector3(0, 1.08, -0.33))
	K.part(root, "Techo", K.rbox(Vector3(2.12, 0.36, 1.22), 0.14), "hueso", Vector3(0, 1.7, 0))
	K.part(root, "Fondo", K.rbox(Vector3(1.5, 1.14, 0.05), 0.02, 1), "marino_osc", Vector3(0.28, 0.94, -0.04))
	K.led(root, "Estado", Vector3(-0.82, 1.08, 0.615), 0.15, 0.56)
	# tapa de mantenimiento con rejilla
	K.part(root, "AroTapa", K.rbox(Vector3(1.06, 0.12, 0.78), 0.05), "turquesa", Vector3(-0.05, 1.92, 0))
	K.part(root, "Tapa", K.rbox(Vector3(0.94, 0.12, 0.66), 0.05), "hueso", Vector3(-0.05, 1.99, 0))
	for i in 5:
		K.part(root, "Rejilla", K.rbox(Vector3(0.09, 0.03, 0.44), 0.012, 1), "ambar_suave", Vector3(-0.33 + i * 0.14, 2.055, 0))
	# cámaras horizontales
	var alturas := [1.22, 0.66]
	var radios := [0.27, 0.23]
	for i in 2:
		var camara := K.node(root, "Camara%d" % (i + 1), Vector3(0.3, alturas[i], 0.28))
		K.part(camara, "Agua", K.drum(radios[i] * 0.8, 1.2, 14, 0.04), "agua", Vector3.ZERO, Vector3(0, 0, 90))
		K.part(camara, "Vidrio", K.drum(radios[i], 1.26, 16, 0.06), "vidrio", Vector3.ZERO, Vector3(0, 0, 90))
		for sx in [-1.0, 1.0]:
			K.part(camara, "Tapa", K.drum(radios[i] + 0.035, 0.16, 16, 0.04), "acero_osc", Vector3(sx * 0.68, 0, 0), Vector3(0, 0, 90))
		for b in 4:
			K.part(camara, "Burbuja", K.sphere(0.03 + 0.008 * (b % 2), 8, 4), "blanco", Vector3(-0.42 + b * 0.27, 0.06 - 0.05 * (b % 3), 0.1))
	# tubo de retorno en U
	K.part(root, "Retorno", K.tube([Vector3(1.04, 1.22, 0.28), Vector3(1.62, 1.22, 0.28), Vector3(1.62, 0.66, 0.28), Vector3(1.04, 0.66, 0.28)], 0.12, 12, 0.26), "turquesa")
	K.part(root, "AbrazaderaRetorno", K.drum(0.165, 0.13, 14, 0.03), "ambar_mate", Vector3(1.62, 0.94, 0.28))
	K.part(root, "BridaSuperior", K.drum(0.165, 0.13, 14, 0.03), "ambar_mate", Vector3(1.2, 1.22, 0.28), Vector3(0, 0, 90))
	K.part(root, "BridaInferior", K.drum(0.165, 0.13, 14, 0.03), "ambar_mate", Vector3(1.2, 0.66, 0.28), Vector3(0, 0, 90))
	K.marker(root, "MarcadorEntrada", Vector3(-1.2, 0.7, 0))
	K.marker(root, "MarcadorRetorno", Vector3(1.75, 0.94, 0.28))
	K.collision(root, Vector3(0.25, 1.05, 0), Vector3(2.9, 2.1, 1.4))
	return root


# ------------------------------------------------------------------ jardín lunar

static func jardin() -> Node3D:
	var root := Node3D.new()
	root.name = "JardinLunar"
	K.part(root, "Bandeja", K.rbox(Vector3(2.8, 0.5, 1.62), 0.13, 3, Vector2(0.84, 0.78)), "turquesa", Vector3(0, 0.27, 0), Vector3(180, 0, 0))
	K.part(root, "Borde", K.rbox(Vector3(2.88, 0.11, 1.7), 0.05), "hueso", Vector3(0, 0.53, 0))
	K.part(root, "Tierra", K.rbox(Vector3(2.62, 0.08, 1.44), 0.03), "tierra", Vector3(0, 0.57, 0))
	for lx in [-0.8, 0.0, 0.8]:
		K.led(root, "LuzBandeja", Vector3(lx, 0.25, 0.73), 0.46, 0.1, Vector3(14, 0, 0))
	K.led(root, "LuzLateral", Vector3(1.3, 0.25, 0.0), 0.5, 0.1, Vector3(14, 90, 0))
	# plantas: dos filas, dos tamaños
	var hoja := K.crystal(0.44, 0.12, 4)
	var n := 0
	for fila in 2:
		for col in 4:
			n += 1
			var escala := 1.0 if (fila + col) % 2 == 0 else 0.78
			var planta := K.node(root, "Planta%d" % n, Vector3(-0.96 + col * 0.64, 0.6, -0.34 + fila * 0.68))
			planta.scale = Vector3.ONE * escala
			K.part(planta, "Brote", hoja, "hoja", Vector3.ZERO, Vector3(0, 0, 0), Vector3(0.8, 0.9, 0.5))
			for h in 5:
				var giro := h * 72.0 + n * 23.0
				var eje := K.node(planta, "Eje", Vector3.ZERO, Vector3(0, giro, 0))
				K.part(eje, "Hoja", hoja, "hoja" if h % 2 == 0 else "hoja_osc", Vector3(0, 0, 0.03), Vector3(48, 0, 0), Vector3(1.0, 1.0, 0.4))
	# cubierta translúcida con arcos
	var radio := 0.76
	var cubierta := K.part(root, "Cubierta", K.lathe([V(radio, -1.36), V(radio, 1.36)], 24, 80.0), "vidrio", Vector3(0, 0.58, 0), Vector3(0, 0, 90))
	cubierta.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for sx in [-1.0, 1.0]:
		var tapa := K.part(root, "Testero", K.drum(radio, 0.03, 24, 0.008), "vidrio", Vector3(sx * 1.36, 0.58, 0), Vector3(0, 0, 90))
		tapa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for ax in [-1.36, -0.45, 0.45, 1.36]:
		K.part(root, "Arco", K.torus(radio + 0.01, 0.032, 28, 8), "hueso", Vector3(ax, 0.58, 0), Vector3(0, 0, 90))
	for lx in [-0.9, 0.0, 0.9]:
		K.part(root, "LuzCultivo", K.rbox(Vector3(0.62, 0.05, 0.13), 0.02, 2), "ambar", Vector3(lx, 0.58 + radio - 0.07, 0))
	K.collision(root, Vector3(0, 0.7, 0), Vector3(2.9, 1.4, 1.7))
	return root


# ------------------------------------------------------------------ batería

static func bateria() -> Node3D:
	var root := Node3D.new()
	root.name = "BateriaLunar"
	K.part(root, "Bandeja", K.rbox(Vector3(3.0, 0.56, 1.12), 0.15), "marino", Vector3(0, 0.3, 0))
	K.part(root, "Franja", K.rbox(Vector3(2.3, 0.2, 0.05), 0.02, 2), "hueso", Vector3(0, 0.28, 0.565))
	for lx in [-0.72, 0.72]:
		K.led(root, "LuzBandeja", Vector3(lx, 0.28, 0.59), 0.42, 0.09)
	for sx in [-1.0, 1.0]:
		K.part(root, "Tope", K.rbox(Vector3(0.34, 0.86, 1.2), 0.13), "marino", Vector3(sx * 1.52, 0.45, 0))
		K.part(root, "PlacaTope", K.plate(0.5, 0.42, 0.05, 0.1, 0.012), "hueso", Vector3(sx * 1.7, 0.5, 0), Vector3(0, sx * 90.0, 0))
		K.led(root, "LuzTope", Vector3(sx * 1.6, 0.45, 0.6), 0.07, 0.34)
	for i in 4:
		var celda := K.node(root, "Celda%d" % (i + 1), Vector3(-0.99 + i * 0.66, 0.5, 0))
		K.part(celda, "Cuerpo", K.rbox(Vector3(0.58, 1.14, 0.74), 0.15, 3, Vector2(0.9, 0.9)), "hueso", Vector3(0, 0.57, 0))
		K.part(celda, "Ventana", K.plate(0.36, 0.64, 0.05, 0.07, 0.012), "marino_osc", Vector3(0, 0.55, 0.36))
		for s in 4:
			K.part(celda, "Segmento%d" % (s + 1), K.plate(0.27, 0.1, 0.05, 0.03, 0.01), "cian_luz", Vector3(0, 0.34 + s * 0.14, 0.372))
		K.part(celda, "Collar", K.rbox(Vector3(0.38, 0.1, 0.48), 0.04), "turquesa", Vector3(0, 1.17, 0))
		K.part(celda, "Borne", K.rbox(Vector3(0.32, 0.13, 0.4), 0.05), "ambar_mate", Vector3(0, 1.27, 0))
	K.collision(root, Vector3(0, 0.9, 0), Vector3(3.4, 1.8, 1.2))
	return root


# ------------------------------------------------------------------ rover

static func rover() -> Node3D:
	var root := Node3D.new()
	root.name = "RoverLunar"
	var zs := [0.98, 0.0, -0.98]
	for lado in [1.0, -1.0]:
		for i in 3:
			# con el frente en +Z, la izquierda del rover queda en +X (se invierte al girarlo a −Z)
			var nombre := ("RuedaIzq%d" if lado > 0.0 else "RuedaDer%d") % (i + 1)
			var rueda := K.node(root, nombre, Vector3(lado * 0.98, 0.44, zs[i]))
			K.part(rueda, "Neumatico", K.drum(0.44, 0.38, 18, 0.13), "goma", Vector3.ZERO, Vector3(0, 0, 90))
			for t in 9:
				var giro := K.node(rueda, "Taco", Vector3.ZERO, Vector3(t * 40.0, 0, 0))
				K.part(giro, "Bloque", K.rbox(Vector3(0.34, 0.07, 0.15), 0.025, 2), "goma", Vector3(0, 0.44, 0))
			K.part(rueda, "Llanta", K.drum(0.26, 0.4, 16, 0.05), "acero_osc", Vector3.ZERO, Vector3(0, 0, 90))
			K.part(rueda, "Cubo", K.drum(0.15, 0.46, 14, 0.05), "ambar_mate", Vector3.ZERO, Vector3(0, 0, 90))
			K.part(root, "Brazo", K.tube([Vector3(lado * 0.46, 0.84, zs[i] * 0.86), Vector3(lado * 0.74, 0.5, zs[i])], 0.075, 8), "hueso")
			K.part(root, "Articulacion", K.sphere(0.11, 10, 5), "ambar_mate", Vector3(lado * 0.46, 0.84, zs[i] * 0.86))
	K.part(root, "Chasis", K.rbox(Vector3(1.26, 0.42, 2.6), 0.15), "turquesa", Vector3(0, 0.9, 0))
	# cabina
	K.part(root, "Cabina", K.rbox(Vector3(1.34, 0.8, 1.2), 0.27, 4), "hueso", Vector3(0, 1.38, 0.72))
	K.part(root, "Visera", K.plate(0.98, 0.46, 0.1, 0.21, 0.02), "marino_osc", Vector3(0, 1.42, 1.29))
	for sx in [-1.0, 1.0]:
		var ojo := K.node(root, "Sensor", Vector3(sx * 0.23, 1.42, 1.33))
		K.part(ojo, "Aro", K.drum(0.185, 0.1, 16, 0.03), "acero_osc", Vector3.ZERO, Vector3(90, 0, 0))
		K.part(ojo, "Lente", K.sphere(0.135, 14, 7), "cian_luz", Vector3(0, 0, 0.02), Vector3.ZERO, Vector3(1, 1, 0.55))
		K.part(ojo, "Pupila", K.sphere(0.07, 10, 5), "marino_osc", Vector3(0, 0, 0.07), Vector3.ZERO, Vector3(1, 1, 0.5))
		K.led(root, "LuzCostado", Vector3(sx * 0.675, 1.34, 0.55), 0.3, 0.13, Vector3(0, sx * 90.0, 0))
		for r in 2:
			K.part(root, "Raya", K.rbox(Vector3(0.03, 0.26, 0.055), 0.012, 1), "marino_osc", Vector3(sx * 0.675, 1.5, 0.98 - r * 0.12), Vector3(sx * 24.0, 0, 0))
	K.led(root, "LuzFrontal", Vector3(0, 0.95, 1.305), 0.34, 0.1)
	K.part(root, "BaseBaliza", K.drum(0.22, 0.09, 14, 0.03), "turquesa_osc", Vector3(0, 1.82, 0.62))
	K.part(root, "Baliza", K.capsule(0.17, 0.4, 14), "ambar", Vector3(0, 1.9, 0.62))
	# caja de carga
	K.part(root, "Caja", K.rbox(Vector3(1.4, 0.52, 1.36), 0.13), "hueso", Vector3(0, 1.3, -0.6))
	K.part(root, "FondoCaja", K.rbox(Vector3(1.18, 0.1, 1.14), 0.04), "turquesa_osc", Vector3(0, 1.54, -0.6))
	K.part(root, "FranjaCaja", K.rbox(Vector3(1.43, 0.16, 1.1), 0.05), "turquesa", Vector3(0, 1.16, -0.6))
	for sx in [-1.0, 1.0]:
		K.led(root, "LuzTrasera", Vector3(sx * 0.42, 1.3, -1.285), 0.26, 0.14, Vector3(0, 180, 0))
	var hielo := K.node(root, "HieloCarga", Vector3(0, 1.58, -0.6))
	var trozos := [[Vector3(-0.3, 0.14, 0.2), 0.3, 3], [Vector3(0.28, 0.16, 0.24), 0.28, 5], [Vector3(0.0, 0.26, -0.1), 0.34, 7], [Vector3(-0.32, 0.12, -0.32), 0.26, 9], [Vector3(0.34, 0.12, -0.3), 0.26, 11]]
	for d in trozos:
		K.part(hielo, "Trozo", K.rock(d[1], d[2], Vector3(1, 1.05, 1), 0.2), "hielo" if int(d[2]) % 4 == 3 else "hielo_osc", d[0], Vector3(d[2] * 11.0, d[2] * 29.0, 0))
	K.marker(root, "Carga", Vector3(0, 1.6, -0.6))
	K.collision(root, Vector3(0, 1.0, 0), Vector3(2.3, 2.0, 2.9))
	return root
