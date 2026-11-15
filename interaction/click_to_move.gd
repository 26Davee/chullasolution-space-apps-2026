## Mueve al astronauta hasta el punto del suelo donde se hace clic.
##
## - Lanza un rayo desde la Camera3D hasta el suelo (StaticBody3D) para obtener el destino.
## - Busca solo al astronauta instanciado por visor_astronauta.gd (grupo, nombre o
##   primer CharacterBody3D), aunque se cree después de este nodo.
## - Lo mueve suavemente y lo gira hacia donde avanza. Si es un CharacterBody3D usa
##   move_and_slide (respeta colisiones); si no, mueve el Node3D directamente.
## - Reproduce Walk/Run al caminar e Idle al llegar, si existen en su AnimationPlayer.
## - Muestra un aro temporal en el suelo donde se hizo clic.
## - No hace nada mientras el PlacementSystem está en modo colocación.
class_name ClickToMove
extends Node3D

signal station_clicked(section: String, station: Node3D)

signal destino_fijado(posicion: Vector3)
signal destino_alcanzado(posicion: Vector3)

enum BotonClic { IZQUIERDO, DERECHO }

# --- Referencias -----------------------------------------------------------
@export_group("Referencias")
## Si se deja vacía se usa la cámara activa del viewport.
@export var camara: Camera3D
## Si se deja vacío se busca automáticamente (ver grupo/nombre abajo).
@export var astronauta: Node3D
## Grupo donde buscar al astronauta (recomendado añadirlo desde visor_astronauta.gd).
@export var grupo_astronauta: StringName = &"astronauta"
## Si no está en el grupo, se busca un nodo cuyo nombre contenga este texto.
@export var nombre_astronauta: String = "astronaut"
## Opcional: solo se aceptan clics sobre este cuerpo (tu StaticBody3D del suelo).
@export var suelo: CollisionObject3D
## Opcional: nodo con placement_system.gd. Si se deja vacío se busca entre los hermanos.
@export var placement_system: Node

# --- Entrada ---------------------------------------------------------------
@export_group("Entrada")
@export var boton_clic: BotonClic = BotonClic.IZQUIERDO
## Capa(s) de colisión del suelo (por defecto la capa 1, la del StaticBody3D).
@export_flags_3d_physics var mascara_suelo: int = 1
@export var largo_rayo: float = 1000.0

# --- Movimiento ------------------------------------------------------------
@export_group("Movimiento")
@export var velocidad: float = 3.0
@export var velocidad_giro: float = 10.0
@export var distancia_parada: float = 0.1
## La mayoría de modelos .glb/.gltf miran hacia +Z. Si el astronauta camina
## de espaldas, desactiva esta opción.
@export var modelo_mira_hacia_z_positivo: bool = true
## Solo aplica si el astronauta es un CharacterBody3D.
@export var usar_gravedad: bool = true

# --- Animaciones -----------------------------------------------------------
@export_group("Animaciones")
## Se prueba en orden; la comparación ignora mayúsculas y prefijos como "Armature|".
@export var nombres_caminar: PackedStringArray = ["Walk", "Walking", "Run", "Caminar", "Correr"]
@export var nombres_idle: PackedStringArray = ["Idle", "Reposo", "Quieto"]
@export var mezcla_animacion: float = 0.2

# --- Indicador -------------------------------------------------------------
@export_group("Indicador")
@export var mostrar_indicador: bool = true
@export var color_indicador: Color = Color(0.3, 0.9, 1.0, 0.9)
@export var radio_indicador: float = 0.4
## Segundos que permanece visible. 0 = hasta que el astronauta llegue.
@export var duracion_indicador: float = 1.2

# --- Estado interno --------------------------------------------------------
var _destino: Vector3
var _moviendo: bool = false
var _clic_pendiente: bool = false
var _pos_clic: Vector2
var _frames_hasta_busqueda: int = 0
var _tiempo_atascado: float = 0.0

var _anim: AnimationPlayer
var _anim_caminar: StringName = &""
var _anim_idle: StringName = &""

var _indicador: MeshInstance3D
var _mat_indicador: StandardMaterial3D
var _tween: Tween

@onready var _gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	if camara == null:
		camara = get_viewport().get_camera_3d()
	if placement_system == null and get_parent():
		for hermano in get_parent().get_children():
			if hermano != self and hermano.has_method("is_placing"):
				placement_system = hermano
				break
	_crear_indicador()
	# El astronauta lo instancia el nodo raíz, cuyo _ready() corre DESPUÉS del
	# nuestro; por eso se busca de forma diferida y también en _physics_process.
	if astronauta:
		_preparar_animaciones()
	else:
		_buscar_astronauta.call_deferred()


# ===========================================================================
# Entrada
# ===========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var boton := MOUSE_BUTTON_LEFT if boton_clic == BotonClic.IZQUIERDO else MOUSE_BUTTON_RIGHT
	if event.button_index != boton:
		return
	if _colocando_pieza():
		return
	_pos_clic = event.position
	_clic_pendiente = true   # el rayo se lanza en _physics_process
	get_viewport().set_input_as_handled()


func _colocando_pieza() -> bool:
	return placement_system != null \
		and placement_system.has_method("is_placing") \
		and placement_system.is_placing()


# ===========================================================================
# Bucle de física
# ===========================================================================

func _physics_process(delta: float) -> void:
	if astronauta == null or not is_instance_valid(astronauta):
		astronauta = null
		_frames_hasta_busqueda -= 1
		if _frames_hasta_busqueda <= 0:
			_frames_hasta_busqueda = 15
			_buscar_astronauta()

	if _clic_pendiente:
		_clic_pendiente = false
		_procesar_clic()

	if astronauta:
		_mover(delta)


func _procesar_clic() -> void:
	if camara == null:
		camara = get_viewport().get_camera_3d()
		if camara == null:
			push_warning("ClickToMove: no hay Camera3D asignada ni activa.")
			return
	if astronauta == null:
		_buscar_astronauta()
		if astronauta == null:
			push_warning("ClickToMove: no se encontró al astronauta (asígnalo o añádelo al grupo '%s')." % grupo_astronauta)
			return

	var origen := camara.project_ray_origin(_pos_clic)
	var fin := origen + camara.project_ray_normal(_pos_clic) * largo_rayo
	var consulta := PhysicsRayQueryParameters3D.create(origen, fin, mascara_suelo | 16)
	consulta.collide_with_areas = true
	consulta.exclude = _rids_de(astronauta)
	var hit := get_world_3d().direct_space_state.intersect_ray(consulta)
	if hit.is_empty():
		return
	var target: Node = hit.collider
	while target != null:
		if target.has_meta("station_section"):
			station_clicked.emit(str(target.get_meta("station_section")),target as Node3D)
			return
		target = target.get_parent()
	if suelo and hit.collider != suelo:
		return

	_destino = hit.position
	_moviendo = true
	_tiempo_atascado = 0.0
	_mostrar_indicador(hit.position, hit.normal)
	_reproducir(_anim_caminar)
	destino_fijado.emit(_destino)


func _mover(delta: float) -> void:
	var cuerpo := astronauta as CharacterBody3D

	if not _moviendo:
		if cuerpo and usar_gravedad:
			cuerpo.velocity.x = 0.0
			cuerpo.velocity.z = 0.0
			if not cuerpo.is_on_floor():
				cuerpo.velocity.y -= _gravedad * delta
			cuerpo.move_and_slide()
		return

	var pos := astronauta.global_position
	var hacia := _destino - pos
	hacia.y = 0.0
	var distancia := hacia.length()
	if distancia <= distancia_parada:
		_llegar()
		return

	var dir := hacia / distancia

	# Giro suave hacia la dirección de avance
	var yaw := atan2(dir.x, dir.z)
	if not modelo_mira_hacia_z_positivo:
		yaw += PI
	astronauta.rotation.y = lerp_angle(astronauta.rotation.y, yaw, clampf(velocidad_giro * delta, 0.0, 1.0))

	if cuerpo:
		var rapidez := minf(velocidad, distancia / delta)   # evita pasarse del destino
		cuerpo.velocity.x = dir.x * rapidez
		cuerpo.velocity.z = dir.z * rapidez
		if usar_gravedad:
			cuerpo.velocity.y = 0.0 if cuerpo.is_on_floor() else cuerpo.velocity.y - _gravedad * delta
		cuerpo.move_and_slide()
		# Si algo lo bloquea (p. ej. un módulo), se detiene tras medio segundo.
		var avance := Vector2(cuerpo.get_real_velocity().x, cuerpo.get_real_velocity().z).length()
		_tiempo_atascado = _tiempo_atascado + delta if avance < velocidad * 0.1 else 0.0
		if _tiempo_atascado > 0.5:
			_llegar()
	else:
		astronauta.global_position = pos + dir * minf(velocidad * delta, distancia)


func _llegar() -> void:
	_moviendo = false
	_tiempo_atascado = 0.0
	if astronauta is CharacterBody3D:
		(astronauta as CharacterBody3D).velocity = Vector3.ZERO
	_reproducir(_anim_idle)
	_ocultar_indicador()
	destino_alcanzado.emit(_destino)


# ===========================================================================
# Búsqueda del astronauta
# ===========================================================================

func _buscar_astronauta() -> void:
	if astronauta and is_instance_valid(astronauta):
		return
	var escena := get_tree().current_scene
	if escena == null:
		escena = get_parent()
	if escena == null:
		return

	# 1) Por grupo
	var por_grupo := get_tree().get_first_node_in_group(grupo_astronauta)
	if por_grupo is Node3D:
		_asignar_astronauta(por_grupo)
		return

	# 2) Por nombre (contiene, sin distinguir mayúsculas)
	if nombre_astronauta != "":
		var buscado := nombre_astronauta.to_lower()
		for n in escena.find_children("*", "Node3D", true, false):
			if not _excluido(n) and String(n.name).to_lower().contains(buscado):
				_asignar_astronauta(n)
				return

	# 3) Primer CharacterBody3D de la escena
	for n in escena.find_children("*", "CharacterBody3D", true, false):
		if not _excluido(n):
			_asignar_astronauta(n)
			return


func _excluido(n: Node) -> bool:
	if n == self or is_ancestor_of(n) or n is Camera3D:
		return true
	if placement_system and (n == placement_system or placement_system.is_ancestor_of(n)):
		return true
	return false


func _asignar_astronauta(n: Node3D) -> void:
	astronauta = n
	_preparar_animaciones()


func _rids_de(nodo: Node) -> Array[RID]:
	var rids: Array[RID] = []
	if nodo is CollisionObject3D:
		rids.append(nodo.get_rid())
	for c in nodo.find_children("*", "CollisionObject3D", true, false):
		rids.append((c as CollisionObject3D).get_rid())
	return rids


# ===========================================================================
# Animaciones (todo opcional: sin AnimationPlayer o sin nombres, no hace nada)
# ===========================================================================

func _preparar_animaciones() -> void:
	_anim = null
	_anim_caminar = &""
	_anim_idle = &""
	if astronauta == null:
		return
	var players := astronauta.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	_anim = players[0]
	var lista := _anim.get_animation_list()
	_anim_caminar = _elegir_animacion(lista, nombres_caminar)
	_anim_idle = _elegir_animacion(lista, nombres_idle)

	for nombre in [_anim_caminar, _anim_idle]:
		if nombre != &"":
			var a := _anim.get_animation(nombre)
			if a and a.loop_mode == Animation.LOOP_NONE:
				a.loop_mode = Animation.LOOP_LINEAR

	_reproducir(_anim_caminar if _moviendo else _anim_idle)


func _elegir_animacion(lista: PackedStringArray, candidatos: PackedStringArray) -> StringName:
	# Primero coincidencia exacta del nombre "corto", luego que lo contenga.
	for exacta in [true, false]:
		for cand in candidatos:
			var c := cand.to_lower()
			for nombre in lista:
				var corto := _nombre_corto(nombre)
				if (exacta and corto == c) or (not exacta and corto.contains(c)):
					return StringName(nombre)
	return &""


func _nombre_corto(nombre: String) -> String:
	# "libreria/Armature|Walk" -> "walk"
	var partes := nombre.split("/")
	var s := partes[partes.size() - 1]
	partes = s.split("|")
	return partes[partes.size() - 1].to_lower()


func _reproducir(nombre: StringName) -> void:
	if _anim == null or nombre == &"":
		return
	if _anim.current_animation != nombre or not _anim.is_playing():
		_anim.play(nombre, mezcla_animacion)


# ===========================================================================
# Indicador en el suelo
# ===========================================================================

func _crear_indicador() -> void:
	var toro := TorusMesh.new()
	toro.inner_radius = radio_indicador * 0.75
	toro.outer_radius = radio_indicador
	toro.rings = 32
	toro.ring_segments = 8

	_mat_indicador = StandardMaterial3D.new()
	_mat_indicador.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_indicador.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_indicador.albedo_color = color_indicador

	_indicador = MeshInstance3D.new()
	_indicador.name = "IndicadorDestino"
	_indicador.mesh = toro
	_indicador.material_override = _mat_indicador
	_indicador.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_indicador.top_level = true
	_indicador.visible = false
	add_child(_indicador)


func _mostrar_indicador(punto: Vector3, normal: Vector3) -> void:
	if not mostrar_indicador or _indicador == null:
		return
	if _tween:
		_tween.kill()
	_indicador.global_position = punto + normal * 0.02
	_indicador.scale = Vector3(0.3, 0.3, 0.3)
	_mat_indicador.albedo_color = color_indicador
	_indicador.visible = true

	_tween = create_tween()
	_tween.tween_property(_indicador, "scale", Vector3(1.0, 0.3, 1.0), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if duracion_indicador > 0.0:
		_tween.tween_interval(maxf(duracion_indicador - 0.6, 0.0))
		_tween.tween_property(_mat_indicador, "albedo_color:a", 0.0, 0.35)
		_tween.tween_callback(func(): _indicador.visible = false)


func _ocultar_indicador() -> void:
	if _indicador == null or not _indicador.visible:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_mat_indicador, "albedo_color:a", 0.0, 0.2)
	_tween.tween_callback(func(): _indicador.visible = false)


func ordenar_destino(position: Vector3) -> void:
	_destino = position
	_moviendo = true
	_tiempo_atascado = 0.0
	_mostrar_indicador(position,Vector3.UP)
	_reproducir(_anim_caminar)
	destino_fijado.emit(position)
