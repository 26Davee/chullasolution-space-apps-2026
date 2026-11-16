class_name MissionManager
extends Node
## Controla la campaña de 16 misiones de Killawasi.
##
## Carga missions.json, escucha eventos del juego y evalúa el estado de la simulación
## para determinar misiones cumplidas o fallos amables, otorgando estrellas a través de SaveManager.

signal mision_cumplida(id: String, puntos: int)
signal mision_completada(id_mision: String, estrellas: int, carta_nasa: Dictionary)
signal mision_fallida(id_mision: String, reporte_fallo: String)
signal mision_activa_cambiada(mision_data: Dictionary)
signal progreso_objetivo_actualizado(id_mision: String, triggers_cumplidos: Array, total_triggers: int)
signal simulacro_supertormenta_solicitado(id_mision: String)

const DEFAULT_MISSIONS_PATH := "res://data/missions/missions.json"
const FALLO_COOLDOWN_S := 12.0
const SaveManagerScript := preload("res://progression/save_manager.gd")

@export var missions_path: String = DEFAULT_MISSIONS_PATH
@export var save_manager: Node

var _misiones: Array = []
var _misiones_por_id: Dictionary = {}
var _mision_activa_id: String = ""
var _modo_juego: String = "cadete"

var _triggers_cumplidos_actual: Dictionary = {}
var _eventos_registrados: Dictionary = {}
var _ultimo_fallo_timestamp: float = -999.0

# Contadores auxiliares para objetivos continuos o acumulativos.
var _tiempo_en_noche_s: float = 0.0
var _tiempo_riego_jardin_s: float = 0.0
var _energia_min_noche: float = 100.0
var _viajes_hielo_m11: int = 0
var _nubes_superadas_total: int = 0
# M16 cuenta desde que se activa, no desde el inicio de la partida.
var _m16_inicio_t: float = -1.0
var _m16_nubes_inicio: int = 0


func _ready() -> void:
	_asegurar_save_manager()
	if cargar_misiones():
		_seleccionar_primera_mision_pendiente()


func set_save_manager(manager: Node) -> void:
	save_manager = manager
	if is_instance_valid(save_manager) and save_manager.has_signal("progreso_cargado"):
		if not save_manager.progreso_cargado.is_connected(_on_progreso_cargado):
			save_manager.progreso_cargado.connect(_on_progreso_cargado)


func _on_progreso_cargado(_datos: Dictionary) -> void:
	_triggers_cumplidos_actual.clear()
	_eventos_registrados.clear()
	_tiempo_en_noche_s = 0.0
	_tiempo_riego_jardin_s = 0.0
	_energia_min_noche = 100.0
	_viajes_hielo_m11 = 0
	_nubes_superadas_total = 0
	if not _misiones.is_empty():
		_seleccionar_primera_mision_pendiente()


func establecer_modo_juego(modo: String) -> void:
	match modo:
		"cadet", "cadete":
			_modo_juego = "cadete"
		"engineer", "ingeniero":
			_modo_juego = "ingeniero"


static func _es_espanol(idioma: String = "") -> bool:
	var loc := idioma if not idioma.is_empty() else TranslationServer.get_locale()
	return loc.to_lower().begins_with("es")


static func _localizar_carta(carta: Dictionary, es_lang: bool) -> Dictionary:
	if carta.is_empty():
		return {}
	var res := carta.duplicate(true)
	if es_lang:
		res["titulo"] = str(carta.get("titulo_es", carta.get("titulo", "")))
		res["dato"] = str(carta.get("dato_es", carta.get("dato", "")))
		res["fuente"] = str(carta.get("fuente_es", carta.get("fuente", "")))
	return res


func obtener_mision_localizada(mision: Dictionary, idioma: String = "") -> Dictionary:
	if mision.is_empty():
		return {}
	var es_lang := _es_espanol(idioma)
	var out := mision.duplicate(true)
	if es_lang:
		out["mision"] = str(mision.get("mision_es", mision.get("mision", "")))
		out["objetivo"] = mision.get("objetivo_es", mision.get("objetivo", []))
		out["reporte_fallo"] = str(mision.get("reporte_fallo_es", mision.get("reporte_fallo", "")))
	out["carta_nasa"] = _localizar_carta(mision.get("carta_nasa", {}), es_lang)
	return out


func obtener_mision_activa_localizada(idioma: String = "") -> Dictionary:
	return obtener_mision_localizada(obtener_mision_activa(), idioma)


## Carga todas las misiones desde missions.json.
func cargar_misiones(ruta: String = missions_path) -> bool:
	_misiones.clear()
	_misiones_por_id.clear()

	if not FileAccess.file_exists(ruta):
		push_error("MissionManager: No se encontró el archivo %s." % ruta)
		return false

	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("MissionManager: No se pudo abrir %s." % ruta)
		return false

	var json := JSON.new()
	var err := json.parse(archivo.get_as_text())
	archivo.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("MissionManager: JSON inválido en %s." % ruta)
		return false

	var lista: Variant = json.data.get("misiones", [])
	if typeof(lista) != TYPE_ARRAY:
		return false

	_misiones = lista
	for mision in _misiones:
		if typeof(mision) != TYPE_DICTIONARY:
			continue
		var id_mision := str(mision.get("id", ""))
		if not id_mision.is_empty():
			_misiones_por_id[id_mision] = mision

	return not _misiones.is_empty()


func obtener_mision_activa() -> Dictionary:
	if _mision_activa_id.is_empty() or not _misiones_por_id.has(_mision_activa_id):
		return {}
	return (_misiones_por_id[_mision_activa_id] as Dictionary).duplicate(true)


func obtener_todas_las_misiones() -> Array:
	return _misiones.duplicate(true)


func obtener_triggers_cumplidos() -> Array:
	return _triggers_cumplidos_actual.keys()


## Activa manualmente una misión específica (reiniciando sus triggers en curso).
func activar_mision(id_mision: String) -> bool:
	if not _misiones_por_id.has(id_mision):
		return false

	_mision_activa_id = id_mision
	_triggers_cumplidos_actual.clear()
	_m16_inicio_t = -1.0
	_reiniciar_contadores_mision()

	var datos := obtener_mision_activa()
	mision_activa_cambiada.emit(datos)

	# Si la misión activa incluye partida_iniciada y ya fue emitida, la marca al instante.
	if _eventos_registrados.has("partida_iniciada"):
		_marcar_trigger_si_aplica("partida_iniciada")

	if id_mision == "mision_14":
		simulacro_supertormenta_solicitado.emit("mision_14")

	return true


## Recibe un evento puntual desde Puesto 2, Puesto 3, Puesto 4 o Puesto 1.
func notificar_evento(nombre_evento: String, datos: Dictionary = {}) -> void:
	if nombre_evento.is_empty():
		return

	_eventos_registrados[nombre_evento] = true

	# Contadores históricos útiles entre misiones.
	if nombre_evento == "retorno_domo_completado" or nombre_evento == "viaje_hielo_completado":
		if _mision_activa_id == "mision_11":
			_viajes_hielo_m11 += 1
			if _viajes_hielo_m11 >= 2:
				_marcar_trigger_si_aplica("dos_viajes_hielo_completados")
	elif nombre_evento == "nube_superada" or nombre_evento == "nube_finalizada":
		_nubes_superadas_total += 1
		_procesar_nube_superada_en_mision()

	if _mision_activa_id.is_empty():
		return

	# Mapeos directos de eventos de juego a triggers de misión.
	_mapear_evento_a_triggers(nombre_evento, datos)
	_marcar_trigger_si_aplica(nombre_evento)
	_verificar_cumplimiento_mision_activa()


## Evalúa de forma continua las variables de GameState / Simulación (Puesto 2).
func evaluar_estado_simulacion(estado: Dictionary, delta_s: float = 0.0) -> void:
	if _mision_activa_id.is_empty() or not _misiones_por_id.has(_mision_activa_id):
		return

	_evaluar_triggers_por_estado(_mision_activa_id, estado, delta_s)
	_evaluar_condiciones_fallo(_mision_activa_id, estado)
	_verificar_cumplimiento_mision_activa()


func _mapear_evento_a_triggers(nombre_evento: String, datos: Dictionary) -> void:
	match nombre_evento:
		"estructura_construida":
			var tipo := str(datos.get("id_estructura", ""))
			match tipo:
				"panel_solar":
					_marcar_trigger_si_aplica("panel_solar_construido")
					if int(datos.get("total_paneles", 0)) >= 2:
						_marcar_trigger_si_aplica("segundo_panel_construido")
				"procesador_hielo":
					_marcar_trigger_si_aplica("procesador_hielo_construido")
				"generador_oxigeno":
					_marcar_trigger_si_aplica("generador_oxigeno_construido")
				"jardin":
					_marcar_trigger_si_aplica("jardin_construido")
		"viaje_hielo_iniciado":
			_marcar_trigger_si_aplica("salida_domo_detectada")
		"hielo_extraido_crater":
			_marcar_trigger_si_aplica("hielo_extraido_crater")
		"viaje_hielo_completado":
			_marcar_trigger_si_aplica("hielo_extraido_crater")
			_marcar_trigger_si_aplica("retorno_domo_completado")
			if bool(datos.get("en_alerta_nube", false)):
				_marcar_trigger_si_aplica("retorno_de_emergencia_exitoso")
		"hielo_procesado":
			_marcar_trigger_si_aplica("hielo_ingresado_procesador")
			if bool(datos.get("es_noche", false)):
				_marcar_trigger_si_aplica("procesamiento_nocturno_hielo")
		"reparar_escudo_iniciado":
			_marcar_trigger_si_aplica("clic_domo_detectado")
			_marcar_trigger_si_aplica("accion_reparar_ejecutada")
		"escudo_reparado":
			_marcar_trigger_si_aplica("accion_reparar_ejecutada")
			if _mision_activa_id == "mision_12" and _triggers_cumplidos_actual.has("primera_nube_superada"):
				_marcar_trigger_si_aplica("reparacion_intermedia_completada")
		"advertencia_nube_iniciada":
			_marcar_trigger_si_aplica("alerta_cuenta_atras_20s")
			if bool(datos.get("en_viaje_hielo", false)):
				_marcar_trigger_si_aplica("alerta_nube_mientras_viaje")
		"nube_impacto":
			if int(datos.get("minuto_aprox", 0)) <= 3 or not _triggers_cumplidos_actual.has("primera_nube_minuto_3"):
				_marcar_trigger_si_aplica("primera_nube_minuto_3")
			_marcar_trigger_si_aplica("golpe_escudo_absorbido")
			if float(datos.get("escudo_restante", 100.0)) <= 0.0:
				_marcar_trigger_si_aplica("escudo_llego_cero")
		"tormenta_maxima_resistida":
			# Ruta anti-bloqueo para Misión 14: si el jugador resiste intacto el simulacro o tormenta máxima.
			if _mision_activa_id == "mision_14":
				_marcar_trigger_si_aplica("escudo_llego_cero")
				_marcar_trigger_si_aplica("generador_pausado_10s")


func _evaluar_triggers_por_estado(id_mision: String, estado: Dictionary, delta_s: float) -> void:
	var energia := float(estado.get("energia", 0.0))
	var hielo := int(estado.get("hielo", 0))
	var agua := float(estado.get("agua", 0.0))
	var oxigeno := float(estado.get("oxigeno", 0.0))
	var escudo := float(estado.get("escudo", 100.0))
	var es_dia := bool(estado.get("es_dia", true))
	var en_viaje := bool(estado.get("en_viaje_hielo", false))
	var paneles := int(estado.get("paneles_instalados", 0))
	var tiempo_juego := float(estado.get("tiempo_juego", 0.0))
	var tiempo_ciclo := float(estado.get("tiempo_ciclo_solar", 0.0))

	match id_mision:
		"mision_01":
			_marcar_trigger_si_aplica("partida_iniciada")
			if paneles >= 1:
				_marcar_trigger_si_aplica("panel_solar_construido")
			if energia > 70.0:
				_marcar_trigger_si_aplica("energia_mayor_70")
		"mision_02":
			if en_viaje:
				_marcar_trigger_si_aplica("salida_domo_detectada")
			if hielo >= 2:
				_marcar_trigger_si_aplica("hielo_extraido_crater")
			if not en_viaje and bool(estado.get("robot_en_domo",false)) and _triggers_cumplidos_actual.has("hielo_extraido_crater"):
				_marcar_trigger_si_aplica("retorno_domo_completado")
		"mision_03":
			if bool(estado.get("procesador_instalado", false)):
				_marcar_trigger_si_aplica("procesador_hielo_construido")
			if agua >= 20.0 and _triggers_cumplidos_actual.has("hielo_ingresado_procesador"):
				_marcar_trigger_si_aplica("agua_obtenida_20")
		"mision_04":
			if bool(estado.get("generador_instalado", false)):
				_marcar_trigger_si_aplica("generador_oxigeno_construido")
				if agua > 0.0 and energia > 0.0:
					_marcar_trigger_si_aplica("electrolisis_iniciada")
			if oxigeno > 85.0:
				_marcar_trigger_si_aplica("oxigeno_mayor_85")
		"mision_05":
			if bool(estado.get("robot_en_domo",false)):
				_marcar_trigger_si_aplica("robot_dentro_domo")
			if bool(estado.get("descansando_en_domo",false)):
				_marcar_trigger_si_aplica("recarga_bateria_activa")
			if float(estado.get("energia_robot",0)) >= 90.0 and _triggers_cumplidos_actual.has("recarga_bateria_activa"):
				_marcar_trigger_si_aplica("energia_alcanzada_90")
		"mision_06":
			if paneles >= 2:
				_marcar_trigger_si_aplica("segundo_panel_construido")
			if energia >= 90.0:
				_marcar_trigger_si_aplica("energia_acumulada_90")
			if (es_dia and tiempo_ciclo >= 180.0) or not es_dia:
				_marcar_trigger_si_aplica("aviso_ocaso_recibido")
		"mision_07":
			if not es_dia:
				_marcar_trigger_si_aplica("puesta_de_sol_iniciada")
				_tiempo_en_noche_s += delta_s
				_energia_min_noche = minf(_energia_min_noche, energia)
				if _tiempo_en_noche_s >= 180.0 and _energia_min_noche > 15.0:
					_marcar_trigger_si_aplica("noche_3_minutos_transcurrida")
			elif _triggers_cumplidos_actual.has("noche_3_minutos_transcurrida") and oxigeno >= 50.0:
				_marcar_trigger_si_aplica("amanecer_alcanzado")
		"mision_08":
			if tiempo_juego >= 180.0:
				_marcar_trigger_si_aplica("primera_nube_minuto_3")
			if bool(estado.get("alerta_nube", false)):
				_marcar_trigger_si_aplica("alerta_cuenta_atras_20s")
		"mision_09":
			if escudo >= 99.5 and _triggers_cumplidos_actual.has("accion_reparar_ejecutada"):
				_marcar_trigger_si_aplica("escudo_restaurado_100")
		"mision_10":
			if en_viaje and bool(estado.get("alerta_nube", false)):
				_marcar_trigger_si_aplica("alerta_nube_mientras_viaje")
			if _triggers_cumplidos_actual.has("retorno_de_emergencia_exitoso") and not bool(estado.get("nube_activa", false)):
				_marcar_trigger_si_aplica("escudo_resistio_sin_dano_robot")
		"mision_11":
			if agua <= 10.0:
				_marcar_trigger_si_aplica("reserva_agua_baja_detectada")
			if _triggers_cumplidos_actual.has("dos_viajes_hielo_completados") and oxigeno >= 50.0 and agua > 0.0:
				_marcar_trigger_si_aplica("oxigeno_recuperado_estable")
		"mision_13":
			if not es_dia:
				_marcar_trigger_si_aplica("noche_iniciada")
			elif _triggers_cumplidos_actual.has("procesamiento_nocturno_hielo") and energia > 10.0:
				_marcar_trigger_si_aplica("energia_sostenida_sobre_10")
		"mision_14":
			if escudo <= 0.0:
				_marcar_trigger_si_aplica("escudo_llego_cero")
			if bool(estado.get("generador_pausado", false)):
				_marcar_trigger_si_aplica("generador_pausado_10s")
			if _triggers_cumplidos_actual.has("generador_pausado_10s") and escudo >= 40.0 and oxigeno >= 50.0 and energia >= 20.0:
				_marcar_trigger_si_aplica("base_estabilizada_reparada")
		"mision_15":
			if bool(estado.get("jardin_instalado", false)):
				_marcar_trigger_si_aplica("jardin_construido")
				if agua > 0.0:
					_tiempo_riego_jardin_s += delta_s
					_marcar_trigger_si_aplica("soporte_oxigeno_jardin_activo")
					if _tiempo_riego_jardin_s >= 120.0:
						_marcar_trigger_si_aplica("riego_continuo_2_minutos")
		"mision_16":
			if _m16_inicio_t < 0.0:
				_m16_inicio_t = tiempo_juego
				_m16_nubes_inicio = _nubes_superadas_total
			if tiempo_juego - _m16_inicio_t >= 480.0:
				_marcar_trigger_si_aplica("ocho_minutos_superados")
			if _nubes_superadas_total - _m16_nubes_inicio >= 2:
				_marcar_trigger_si_aplica("dos_nubes_sobrevividas")
			if energia > 30.0 and agua > 30.0 and oxigeno > 60.0 and escudo > 40.0:
				_marcar_trigger_si_aplica("todos_recursos_estables")


func _evaluar_condiciones_fallo(id_mision: String, estado: Dictionary) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - _ultimo_fallo_timestamp < FALLO_COOLDOWN_S:
		return

	var energia := float(estado.get("energia", 60.0))
	var agua := float(estado.get("agua", 20.0))
	var oxigeno := float(estado.get("oxigeno", 60.0))
	var escudo := float(estado.get("escudo", 100.0))
	var en_viaje := bool(estado.get("en_viaje_hielo", false))
	var nube_activa := bool(estado.get("nube_activa", false))

	var fallo := false
	match id_mision:
		"mision_01", "mision_05", "mision_07", "mision_13":
			fallo = energia <= 0.0 or oxigeno <= 0.0
		"mision_02":
			fallo = en_viaje and energia <= 0.0
		"mision_03", "mision_15":
			fallo = agua <= 0.0
		"mision_04", "mision_11":
			fallo = oxigeno < 20.0 or agua <= 0.0
		"mision_08", "mision_10":
			fallo = en_viaje and nube_activa
		"mision_14":
			fallo = energia <= 0.0 or oxigeno <= 0.0
		"mision_16":
			fallo = energia <= 0.0 or agua <= 0.0 or oxigeno <= 0.0 or escudo <= 0.0

	if fallo:
		_ultimo_fallo_timestamp = ahora
		var mision: Dictionary = obtener_mision_localizada(_misiones_por_id[id_mision])
		mision_fallida.emit(id_mision, str(mision.get("reporte_fallo", "")))


func _procesar_nube_superada_en_mision() -> void:
	if _mision_activa_id == "mision_08":
		_marcar_trigger_si_aplica("golpe_escudo_absorbido")
	elif _mision_activa_id == "mision_12":
		if not _triggers_cumplidos_actual.has("primera_nube_superada"):
			_marcar_trigger_si_aplica("primera_nube_superada")
		elif _triggers_cumplidos_actual.has("reparacion_intermedia_completada"):
			_marcar_trigger_si_aplica("segunda_nube_superada")


func _marcar_trigger_si_aplica(nombre_trigger: String) -> void:
	if _mision_activa_id.is_empty() or not _misiones_por_id.has(_mision_activa_id):
		return
	var mision: Dictionary = _misiones_por_id[_mision_activa_id]
	var triggers_requeridos: Array = mision.get("trigger", [])
	if not triggers_requeridos.has(nombre_trigger):
		return
	if _triggers_cumplidos_actual.has(nombre_trigger):
		return

	_triggers_cumplidos_actual[nombre_trigger] = true
	progreso_objetivo_actualizado.emit(
		_mision_activa_id,
		_triggers_cumplidos_actual.keys(),
		triggers_requeridos.size()
	)


func _verificar_cumplimiento_mision_activa() -> void:
	if _mision_activa_id.is_empty() or not _misiones_por_id.has(_mision_activa_id):
		return

	var mision: Dictionary = _misiones_por_id[_mision_activa_id]
	var triggers_requeridos: Array = mision.get("trigger", [])
	if triggers_requeridos.is_empty():
		return

	for t in triggers_requeridos:
		if not _triggers_cumplidos_actual.has(str(t)):
			return

	_completar_mision_activa(mision)


func _completar_mision_activa(mision: Dictionary) -> void:
	var id_mision := str(mision.get("id", ""))
	var puntos_dict: Dictionary = mision.get("puntos", {})
	var estrellas := int(puntos_dict.get(_modo_juego, 1))
	var mision_loc := obtener_mision_localizada(mision)
	var carta_nasa: Dictionary = mision_loc.get("carta_nasa", {})
	var id_carta := "carta_%s" % id_mision

	_asegurar_save_manager()
	if not save_manager.registrar_mision_completada(id_mision, estrellas, id_carta):
		return

	mision_cumplida.emit(id_mision, estrellas)
	mision_completada.emit(id_mision, estrellas, carta_nasa)

	var desbloquea: Dictionary = mision.get("desbloquea", {})
	var siguiente: Variant = desbloquea.get("mision_siguiente", null)
	if siguiente != null and not str(siguiente).is_empty():
		activar_mision(str(siguiente))
	else:
		_mision_activa_id = ""
		mision_activa_cambiada.emit({})


func _seleccionar_primera_mision_pendiente() -> void:
	_asegurar_save_manager()
	for mision in _misiones:
		if typeof(mision) != TYPE_DICTIONARY:
			continue
		var id_mision := str(mision.get("id", ""))
		if not save_manager.esta_mision_completada(id_mision):
			activar_mision(id_mision)
			return
	_mision_activa_id = ""


func _reiniciar_contadores_mision() -> void:
	_tiempo_en_noche_s = 0.0
	_tiempo_riego_jardin_s = 0.0
	_energia_min_noche = 100.0
	_viajes_hielo_m11 = 0


func _asegurar_save_manager() -> void:
	if is_instance_valid(save_manager):
		return
	var padre := get_parent()
	if padre != null:
		for hijo in padre.get_children():
			if hijo is SaveManagerScript:
				set_save_manager(hijo)
				return
	var nuevo_sm := SaveManagerScript.new()
	nuevo_sm.name = "SaveManagerFallback"
	add_child(nuevo_sm)
	nuevo_sm.cargar_progreso()
	set_save_manager(nuevo_sm)


func capturar_estado() -> Dictionary:
	return {"active": _mision_activa_id, "mode": _modo_juego, "triggers": _triggers_cumplidos_actual.duplicate(true), "events": _eventos_registrados.duplicate(true), "night": _tiempo_en_noche_s, "garden": _tiempo_riego_jardin_s, "min_energy": _energia_min_noche, "trips": _viajes_hielo_m11, "storms": _nubes_superadas_total, "m16_t": _m16_inicio_t, "m16_storms": _m16_nubes_inicio}


func restaurar_estado(state: Dictionary) -> void:
	_modo_juego = str(state.get("mode", "cadete"))
	_mision_activa_id = str(state.get("active", ""))
	_triggers_cumplidos_actual = state.get("triggers", {}).duplicate(true)
	_eventos_registrados = state.get("events", {}).duplicate(true)
	_tiempo_en_noche_s = float(state.get("night", 0))
	_tiempo_riego_jardin_s = float(state.get("garden", 0))
	_energia_min_noche = float(state.get("min_energy", 100))
	_viajes_hielo_m11 = int(state.get("trips", 0))
	_nubes_superadas_total = int(state.get("storms", 0))
	_m16_inicio_t = float(state.get("m16_t", -1.0))
	_m16_nubes_inicio = int(state.get("m16_storms", 0))
	_ultimo_fallo_timestamp = -999.0
	mision_activa_cambiada.emit(obtener_mision_activa())
