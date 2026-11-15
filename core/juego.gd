extends Node3D
## Escena de juego (puesto 1): junta el mundo de Carlos, el astronauta, la cámara y el
## movimiento de Nicolás, la simulación de Anahi, las misiones de Gael y el HUD de Andrea.
## Todo se arma por código para que cada puesto pueda cambiar su pieza sin tocar las demás.

signal salir_al_menu

const MUNDO := preload("res://world/moon_world.tscn")
const ASTRONAUTA := preload("res://assets/3d/astronauta.tscn")
const ANIMADOR := preload("res://interaction/animador_astronauta.gd")
const CAMARA := preload("res://camera/camara_orbital.gd")
const CLICK := preload("res://interaction/click_to_move.gd")
const COLOCACION := preload("res://interaction/placement_system.gd")
const HUD := preload("res://core/hud_juego.gd")
const SAVE := preload("res://progression/save_manager.gd")
const MISIONES := preload("res://progression/mission_manager.gd")
const TORMENTA := preload("res://assets/3d/efecto_tormenta.tscn")

const PIEZAS := {
	&"panel_solar": preload("res://assets/3d/panel_solar.tscn"),
	&"procesador_hielo": preload("res://assets/3d/procesador_hielo.tscn"),
	&"generador_oxigeno": preload("res://assets/3d/generador_oxigeno.tscn"),
	&"tanque_agua": preload("res://assets/3d/tanque_agua.tscn"),
}
## Piezas que el mundo trae ya puestas y que aquí construye el jugador.
const QUITAR := ["PanelSolar", "PanelSolar2", "ProcesadorHielo", "TanqueAgua", "GeneradorOxigeno", "TuberiaAgua", "AbrazaderaAgua"]
const POS_INICIO := Vector3(3.2, 0.0, 4.2)
const RADIO_BASE := 8.0

const MOTIVOS := {
	"sin_energia": "No alcanza la energía. Espera a que los paneles la carguen.",
	"sin_cupo": "Ya no hay cupo para esa pieza. Gana estrellas para subir de nivel la base.",
	"bloqueado": "Esa pieza aún está bloqueada.",
	"sin_hielo": "No tienes hielo. Ve al cráter a buscarlo.",
	"agua_llena": "El depósito de agua está lleno.",
	"sin_procesador_libre": "Necesitas un procesador de hielo libre.",
	"escudo_lleno": "El escudo ya está al 100 %.",
	"descansa_primero": "Tu Vida está baja. Descansa dentro del domo antes de salir.",
	"en_viaje": "Ya estás de viaje por hielo.",
	"sin_simulacion": "Falta la simulación (simulation/simulacion.gd).",
}

var mundo: Node3D
var astronauta: Node3D
var camara: Camera3D
var click: Node3D
var colocacion: Node3D
var hud: CanvasLayer
var misiones: Node
var guardado: Node
var domo: Node3D
var ambiente: Node3D
var punto_crater: Vector3
var _acc_misiones := 0.0
var _perfil: Dictionary = {}


func configurar(perfil: Dictionary) -> void:
	_perfil = perfil


func _ready() -> void:
	_crear_mundo()
	_crear_astronauta()
	_crear_camara_e_interaccion()
	_crear_progresion()
	_crear_hud()
	_conectar_estado()
	misiones.notificar_evento("partida_iniciada")
	hud.actualizar_mision(misiones.obtener_mision_activa())
	var nombre: String = str(_perfil.get("nickname", ""))
	hud.aviso("¡Aterrizaste%s! Misión 1: construye tu primer panel solar (gratis)." % ((", " + nombre) if nombre != "" else ""), Color("#33C7D6"))


func _process(delta: float) -> void:
	if not is_instance_valid(astronauta):
		return
	var cerca := astronauta.global_position.distance_to(domo.global_position) < RADIO_BASE
	GameState.fijar_cerca_de_base(cerca)
	domo.set("escudo", GameState.escudo)
	_acc_misiones += delta
	if _acc_misiones >= 1.0 and GameState.en_partida:
		misiones.evaluar_estado_simulacion(GameState.instantanea(), _acc_misiones)
		_acc_misiones = 0.0


# ───────────────────────── Armado de la escena ─────────────────────────

func _crear_mundo() -> void:
	mundo = MUNDO.instantiate()
	add_child(mundo)
	for nombre in QUITAR:
		var n := mundo.get_node_or_null(nombre)
		if n:
			n.get_parent().remove_child(n)
			n.queue_free()
	domo = mundo.get_node("Domo")
	ambiente = mundo.get_node("Ambiente")
	var crater := mundo.get_node_or_null("CraterHielo") as Node3D
	punto_crater = (crater.global_position + Vector3(2.5, 0, -2.0)) if crater else Vector3(-11, 0, 8)


func _crear_astronauta() -> void:
	astronauta = ASTRONAUTA.instantiate()
	astronauta.set_script(ANIMADOR)
	astronauta.set("imprimir_articulaciones", false)
	astronauta.add_to_group(&"astronauta")
	astronauta.position = POS_INICIO
	add_child(astronauta)
	astronauta.rotation.y = PI * 0.75


func _crear_camara_e_interaccion() -> void:
	camara = Camera3D.new()
	camara.set_script(CAMARA)
	camara.set("objetivo", astronauta)
	camara.set("boton_arrastre", MOUSE_BUTTON_RIGHT)
	camara.set("distancia", 13.0)
	camara.far = 3000.0
	add_child(camara)
	camara.make_current()

	colocacion = COLOCACION.new()
	colocacion.name = "Colocacion"
	colocacion.set("camera", camara)
	colocacion.set("placed_parent", self)
	colocacion.set("piece_catalog", PIEZAS)
	colocacion.set("spawn_on_confirm", false)
	add_child(colocacion)
	colocacion.connect("piece_placed", _al_colocar)
	colocacion.connect("placement_rejected", func(_id, motivo): hud.aviso(motivo, Color("#FF6F61")))

	click = CLICK.new()
	click.name = "ClickMove"
	click.set("camara", camara)
	click.set("astronauta", astronauta)
	click.set("suelo", mundo.get_node("Terreno/Ground"))
	click.set("placement_system", colocacion)
	click.set("modelo_mira_hacia_z_positivo", false)
	add_child(click)


func _crear_progresion() -> void:
	guardado = SAVE.new()
	guardado.name = "Guardado"
	add_child(guardado)
	guardado.reiniciar_legado()
	misiones = MISIONES.new()
	misiones.name = "Misiones"
	misiones.set("save_manager", guardado)
	add_child(misiones)
	misiones.establecer_modo_juego(GameState.modo_juego)
	misiones.mision_completada.connect(_al_completar_mision)
	misiones.mision_fallida.connect(func(_id, reporte): hud.aviso("⚠ " + reporte, Color("#FF6F61")))
	misiones.mision_activa_cambiada.connect(func(datos): hud.actualizar_mision(datos))


func _crear_hud() -> void:
	hud = HUD.new()
	add_child(hud)
	hud.construir_pedido.connect(func(id): colocacion.call("start_placement", StringName(id)))
	hud.ir_por_hielo_pedido.connect(_ir_por_hielo)
	hud.procesar_hielo_pedido.connect(_procesar_hielo)
	hud.reparar_escudo_pedido.connect(_reparar_escudo)
	hud.salir_pedido.connect(func(): salir_al_menu.emit())
	hud.carta_cerrada.connect(func(): GameState.en_partida = true)


func _conectar_estado() -> void:
	GameState.ciclo_solar_cambiado.connect(func(dia: bool):
		ambiente.call("set_noche", not dia)
		hud.aviso("☀ Amanece: los paneles vuelven a producir." if dia else "☾ Anochece: los paneles dejan de producir.", Color("#9DB4FF")))
	GameState.advertencia_nube_iniciada.connect(func(t: float):
		hud.aviso("⚠ ¡Nube solar en %d s! Vuelve al domo." % int(t), Color("#FF6F61"))
		misiones.notificar_evento("advertencia_nube_iniciada", {"en_viaje_hielo": GameState.en_viaje_hielo}))
	GameState.nube_impacto.connect(_al_impactar_nube)
	GameState.nube_finalizada.connect(func(): misiones.notificar_evento("nube_finalizada"))
	GameState.viaje_hielo_terminado.connect(_al_terminar_viaje)


# ───────────────────────── Acciones del jugador ─────────────────────────

func _al_colocar(id: StringName, _posicion: Vector3) -> void:
	var resultado := GameState.solicitar_construir(String(id))
	if resultado != "ok":
		hud.aviso(MOTIVOS.get(resultado, resultado), Color("#FF6F61"))
		return
	var fantasma = colocacion.get("_ghost")
	var transformacion: Transform3D = (fantasma as Node3D).global_transform if fantasma else Transform3D(Basis(), _posicion)
	var pieza := (PIEZAS[id] as PackedScene).instantiate() as Node3D
	add_child(pieza)
	pieza.global_transform = transformacion
	pieza.add_to_group(&"placed_pieces")
	pieza.set_meta(&"piece_id", id)
	_poner_en_capa_de_piezas(pieza)
	misiones.notificar_evento("estructura_construida", {"id_estructura": String(id), "total_paneles": GameState.paneles_instalados})
	hud.aviso("✔ Construido: %s" % String(id).replace("_", " "), Color("#6FD39A"))


func _poner_en_capa_de_piezas(nodo: Node) -> void:
	if nodo is CollisionObject3D:
		(nodo as CollisionObject3D).collision_layer |= 2
	for hijo in nodo.get_children():
		_poner_en_capa_de_piezas(hijo)


func _ir_por_hielo() -> void:
	var r := GameState.solicitar_viaje_hielo()
	if r != "ok":
		hud.aviso(MOTIVOS.get(r, r), Color("#FF6F61"))
		return
	misiones.notificar_evento("viaje_hielo_iniciado")
	click.set_process_unhandled_input(false)
	click.call("ir_a", punto_crater)
	hud.aviso("⛏ Vas camino al cráter de hielo…", Color("#33C7D6"))


func _al_terminar_viaje(hielo_traido: int) -> void:
	click.set_process_unhandled_input(true)
	click.call("ir_a", POS_INICIO)
	misiones.notificar_evento("viaje_hielo_completado", {"en_alerta_nube": GameState.alerta_nube})
	hud.aviso("❄ Volviste con %d de hielo." % hielo_traido, Color("#CDEBFF"))


func _procesar_hielo() -> void:
	var r := GameState.solicitar_procesar_hielo()
	if r != "ok":
		hud.aviso(MOTIVOS.get(r, r), Color("#FF6F61"))
		return
	misiones.notificar_evento("hielo_procesado", {"es_noche": not GameState.es_dia})
	hud.aviso("⚙ Procesando hielo: se convierte en agua.", Color("#4FB3F0"))


func _reparar_escudo() -> void:
	misiones.notificar_evento("reparar_escudo_iniciado")
	var r := GameState.solicitar_reparar_escudo()
	if r != "ok":
		hud.aviso(MOTIVOS.get(r, r), Color("#FF6F61"))
		return
	misiones.notificar_evento("escudo_reparado")
	var poses := astronauta.get_node_or_null("Poses") as AnimationPlayer
	if poses and poses.has_animation("tocar_domo"):
		poses.play("tocar_domo")
	hud.aviso("◈ Escudo reparado.", Color("#B28CFF"))


func _al_impactar_nube(fuerza: float, _a_vida: float) -> void:
	misiones.notificar_evento("nube_impacto", {"minuto_aprox": int(GameState.tiempo_juego / 60.0), "escudo_restante": GameState.escudo})
	hud.aviso("☄ ¡Nube solar! El escudo recibió %d de daño." % int(fuerza), Color("#FF6F61"))
	var efecto := TORMENTA.instantiate() as Node3D
	add_child(efecto)
	efecto.global_position = domo.global_position
	get_tree().create_timer(4.0).timeout.connect(efecto.queue_free)


func _al_completar_mision(id: String, estrellas: int, carta: Dictionary) -> void:
	GameState.agregar_estrellas(estrellas)
	GameState.mision_completada.emit(id, estrellas, carta)
	var titulo := str(misiones.call("obtener_todas_las_misiones").filter(func(m): return m.get("id") == id).front().get("mision", id))
	GameState.en_partida = false  # pausa mientras se lee la carta
	hud.mostrar_carta(titulo, estrellas, carta)
