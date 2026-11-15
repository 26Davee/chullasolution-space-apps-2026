# res://interaction/visor_astronauta.gd
extends Node3D

signal astronauta_listo(nodo_astronauta: Node3D)

const RUTA_ASTRONAUTA := "res://assets/3d/astronauta.tscn"

func _ready() -> void:
	var camara := _buscar_camara(self)
	var astronauta := find_child("Astronauta", true, false) as Node3D
	if astronauta == null:
		var escena := load(RUTA_ASTRONAUTA) as PackedScene
		if escena == null:
			push_error("[P4] No se pudo cargar " + RUTA_ASTRONAUTA)
			return
		astronauta = escena.instantiate() as Node3D
		add_child(astronauta)
		astronauta.position = Vector3.ZERO

	if camara:
		camara.objetivo = astronauta
	else:
		push_warning("[P4] No se encontró un nodo con la propiedad 'objetivo' (CamaraOrbital).")

	_asegurar_luz()
	_asegurar_entorno()
	astronauta_listo.emit(astronauta)
	print("[P4] Astronauta listo")

func _buscar_camara(raiz: Node) -> Node:
	for hijo in raiz.get_children():
		if "objetivo" in hijo:
			return hijo
		var r := _buscar_camara(hijo)
		if r:
			return r
	return null

func _asegurar_luz() -> void:
	if not find_children("*", "DirectionalLight3D", true, false).is_empty():
		return
	var luz := DirectionalLight3D.new()
	luz.name = "LuzSol"
	luz.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	luz.light_energy = 1.2
	luz.shadow_enabled = true
	add_child(luz)

func _asegurar_entorno() -> void:
	if not find_children("*", "WorldEnvironment", true, false).is_empty():
		return
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.03, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.9)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.name = "EntornoBasico"
	we.environment = env
	add_child(we)
