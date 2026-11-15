class_name SaveManager
extends Node
## Gestiona el guardado local persistente ("El Legado") de Killawasi.
##
## Almacena en disco (user://save_data.json) las estrellas acumuladas,
## misiones completadas, mejoras compradas y cartas de NASA desbloqueadas.

signal progreso_cargado(datos: Dictionary)
signal progreso_guardado(exito: bool)
signal estrellas_cambiadas(disponibles: int, totales: int)

const DEFAULT_SAVE_PATH := "user://save_data.json"
const MAX_SLOTS := 3
const SLOTS_DIR := "user://saves"
const SLOT_PATH_FMT := "user://saves/slot_%d.json"
const META_PATH := "user://saves_meta.json"

@export var save_path: String = DEFAULT_SAVE_PATH

var active_slot: int = 1
var tutorial_seen: bool = false
var _datos: Dictionary = {}
var ultimo_error := ""
var respaldo_recuperado := false


func _ready() -> void:
	if save_path == DEFAULT_SAVE_PATH:
		_migrar_guardado_legado()
		_cargar_meta()
		save_path = ruta_slot(active_slot)
	cargar_progreso()


static func ruta_slot(slot_id: int) -> String:
	return SLOT_PATH_FMT % clampi(slot_id, 1, MAX_SLOTS)


func _es_ruta_slots() -> bool:
	return save_path.begins_with(SLOTS_DIR + "/")


## Carga el archivo de guardado desde disco o inicializa una partida limpia.
func cargar_progreso() -> Dictionary:
	ultimo_error = ""
	respaldo_recuperado = false
	_datos = _crear_estructura_por_defecto()

	if not FileAccess.file_exists(save_path):
		if _restaurar_desde_respaldo():
			ultimo_error = "corrupt"
			push_warning("SaveManager: Archivo principal ausente; se recuperó desde respaldo.")
			guardar_progreso()
		elif not _es_ruta_slots():
			guardar_progreso()
		progreso_cargado.emit(_datos.duplicate(true))
		estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
		return _datos.duplicate(true)

	var leido := _leer_json_diccionario(save_path)
	if leido.is_empty() or not _es_estructura_valida(leido):
		ultimo_error = "corrupt"
		# Preserve the unreadable file; a valid backup is preferred to a fresh run.
		DirAccess.copy_absolute(save_path, save_path + ".invalid")
		if _restaurar_desde_respaldo():
			guardar_progreso()
		push_warning("SaveManager: Archivo inválido preservado; se usó el respaldo si estaba disponible.")
		progreso_cargado.emit(_datos.duplicate(true))
		estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
		return _datos.duplicate(true)

	_combinar_con_defecto(leido)
	progreso_cargado.emit(_datos.duplicate(true))
	estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
	return _datos.duplicate(true)


func _leer_json_diccionario(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var archivo := FileAccess.open(path, FileAccess.READ)
	if archivo == null:
		return {}
	var texto := archivo.get_as_text()
	archivo.close()
	if texto.strip_edges().is_empty():
		return {}
	var json := JSON.new()
	if json.parse(texto) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary


static func _es_estructura_valida(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var dict := data as Dictionary
	var exp: Variant = dict.get("expedicion", {})
	if not (exp is Dictionary):
		return false
	var exp_dict := exp as Dictionary
	if exp_dict.is_empty():
		return true
	var cur: Variant = exp_dict.get("current", {})
	var cur_ok := cur is Dictionary and (cur as Dictionary).get("state") is Dictionary
	var cp: Variant = exp_dict.get("checkpoint", {})
	var cp_ok := cp is Dictionary and (cp as Dictionary).get("state") is Dictionary
	return cur_ok or cp_ok


func _restaurar_desde_respaldo() -> bool:
	for candidate in [save_path + ".bak", save_path + ".tmp"]:
		var parsed := _leer_json_diccionario(candidate)
		if not parsed.is_empty() and _es_estructura_valida(parsed) and (_datos_ocupados(parsed) or not _es_ruta_slots()):
			_combinar_con_defecto(parsed)
			respaldo_recuperado = true
			return true
	return false


## Escribe el estado actual del progreso en disco en formato JSON.
func guardar_progreso() -> bool:
	var dir_path := save_path.get_base_dir()
	if not dir_path.is_empty():
		DirAccess.make_dir_recursive_absolute(dir_path)
	var temporary := save_path + ".tmp"
	var archivo := FileAccess.open(temporary, FileAccess.WRITE)
	if archivo == null:
		ultimo_error = "write"
		progreso_guardado.emit(false)
		return false
	archivo.store_string(JSON.stringify(_datos, "\t"))
	archivo.flush()
	var result := archivo.get_error()
	archivo.close()
	if result != OK or not _es_estructura_valida(_leer_json_diccionario(temporary)):
		ultimo_error = "write"
		progreso_guardado.emit(false)
		return false
	var current_valid := _leer_json_diccionario(save_path)
	if not current_valid.is_empty() and _es_estructura_valida(current_valid):
		var bak_tmp := save_path + ".bak.tmp"
		if DirAccess.copy_absolute(save_path, bak_tmp) == OK:
			DirAccess.rename_absolute(bak_tmp, save_path + ".bak")
	var success := DirAccess.rename_absolute(temporary, save_path) == OK
	if not success: ultimo_error = "write"
	progreso_guardado.emit(success)
	return success

func registrar_mision_completada(id_mision: String, puntos: int, id_carta: String = "") -> bool:
	if id_mision.is_empty():
		return false

	var completadas: Array = _datos["misiones_completadas"]
	var es_primera_vez := not completadas.has(id_mision)

	if es_primera_vez:
		completadas.append(id_mision)
		_datos["estrellas_totales"] = int(_datos["estrellas_totales"]) + maxi(puntos, 0)
		_datos["estrellas_disponibles"] = int(_datos["estrellas_disponibles"]) + maxi(puntos, 0)

	if not id_carta.is_empty():
		_registrar_carta_interna(id_carta)

	var guardado := guardar_progreso()
	if es_primera_vez:
		estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
	return guardado and es_primera_vez


## Descuenta estrellas y guarda una mejora comprada en el árbol.
func registrar_mejora_comprada(id_mejora: String, costo: int, id_carta: String = "") -> bool:
	if id_mejora.is_empty() or costo < 0:
		return false
	if esta_mejora_comprada(id_mejora):
		return false
	if obtener_estrellas_disponibles() < costo:
		return false

	_datos["estrellas_disponibles"] = obtener_estrellas_disponibles() - costo
	var compradas: Array = _datos["mejoras_compradas"]
	compradas.append(id_mejora)

	if not id_carta.is_empty():
		_registrar_carta_interna(id_carta)

	var guardado := guardar_progreso()
	estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
	return guardado


## Reinicia por completo el progreso guardado (útil para pruebas o nueva partida).
func reiniciar_legado() -> void:
	ultimo_error = ""
	respaldo_recuperado = false
	_datos = _crear_estructura_por_defecto()
	guardar_progreso()
	estrellas_cambiadas.emit(0, 0)
	progreso_cargado.emit(_datos.duplicate(true))


func obtener_estrellas_disponibles() -> int:
	return int(_datos.get("estrellas_disponibles", 0))


func obtener_estrellas_totales() -> int:
	return int(_datos.get("estrellas_totales", 0))


func esta_mision_completada(id_mision: String) -> bool:
	return (_datos.get("misiones_completadas", []) as Array).has(id_mision)


func esta_mejora_comprada(id_mejora: String) -> bool:
	return (_datos.get("mejoras_compradas", []) as Array).has(id_mejora)


func obtener_misiones_completadas() -> Array[String]:
	return _convertir_a_array_string(_datos.get("misiones_completadas", []))


func obtener_mejoras_compradas() -> Array[String]:
	return _convertir_a_array_string(_datos.get("mejoras_compradas", []))


func obtener_cartas_desbloqueadas() -> Array[String]:
	return _convertir_a_array_string(_datos.get("cartas_nasa_desbloqueadas", []))


func obtener_modo_preferido() -> String:
	return str(_datos.get("modo_preferido", "cadete"))


func establecer_modo_preferido(modo: String) -> void:
	if modo != "cadete" and modo != "ingeniero":
		return
	_datos["modo_preferido"] = modo
	guardar_progreso()


func obtener_datos_completos() -> Dictionary:
	return _datos.duplicate(true)


func _registrar_carta_interna(id_carta: String) -> void:
	var cartas: Array = _datos["cartas_nasa_desbloqueadas"]
	if not cartas.has(id_carta):
		cartas.append(id_carta)


func _crear_estructura_por_defecto() -> Dictionary:
	return {
		"version": 2,
		"expedicion": {},
		"perfil": {},
		"estrellas_totales": 0,
		"estrellas_disponibles": 0,
		"misiones_completadas": [],
		"mejoras_compradas": [],
		"cartas_nasa_desbloqueadas": [],
		"modo_preferido": "cadete",
		"saved_at": 0.0,
		"saved_iso": "",
	}


func _combinar_con_defecto(leido: Dictionary) -> void:
	for key in ["expedicion", "perfil"]:
		if leido.get(key) is Dictionary:
			_datos[key] = leido[key].duplicate(true)
	_datos["estrellas_totales"] = int(leido.get("estrellas_totales", 0))
	_datos["estrellas_disponibles"] = int(leido.get("estrellas_disponibles", 0))
	_datos["misiones_completadas"] = _convertir_a_array_string(leido.get("misiones_completadas", []))
	_datos["mejoras_compradas"] = _convertir_a_array_string(leido.get("mejoras_compradas", []))
	_datos["cartas_nasa_desbloqueadas"] = _convertir_a_array_string(leido.get("cartas_nasa_desbloqueadas", []))
	var modo := str(leido.get("modo_preferido", "cadete"))
	_datos["modo_preferido"] = modo if (modo == "cadete" or modo == "ingeniero") else "cadete"
	_datos["saved_at"] = float(leido.get("saved_at", 0.0))
	_datos["saved_iso"] = str(leido.get("saved_iso", ""))


func _convertir_a_array_string(origen: Variant) -> Array[String]:
	var resultado: Array[String] = []
	if typeof(origen) != TYPE_ARRAY:
		return resultado
	for item in origen:
		var texto := str(item)
		if not texto.is_empty() and not resultado.has(texto):
			resultado.append(texto)
	return resultado


func guardar_expedicion(datos: Dictionary, perfil: Dictionary) -> bool:
	_datos["expedicion"] = datos.duplicate(true)
	_datos["perfil"] = perfil.duplicate(true)
	_datos["saved_at"] = Time.get_unix_time_from_system()
	_datos["saved_iso"] = Time.get_datetime_string_from_system(false, true)
	return guardar_progreso()


func guardar_perfil(perfil: Dictionary) -> bool:
	_datos["perfil"] = perfil.duplicate(true)
	_datos["saved_at"] = Time.get_unix_time_from_system()
	_datos["saved_iso"] = Time.get_datetime_string_from_system(false, true)
	return guardar_progreso()


func seleccionar_slot(slot_id: int) -> Dictionary:
	active_slot = clampi(slot_id, 1, MAX_SLOTS)
	_guardar_meta()
	save_path = ruta_slot(active_slot)
	return cargar_progreso()


func borrar_slot(slot_id: int) -> bool:
	var id := clampi(slot_id, 1, MAX_SLOTS)
	var target := ruta_slot(id)
	for suffix in ["", ".bak", ".bak.tmp", ".tmp", ".invalid"]:
		var fpath: String = target + str(suffix)
		if FileAccess.file_exists(fpath):
			DirAccess.remove_absolute(fpath)
	if id == active_slot:
		ultimo_error = ""
		respaldo_recuperado = false
		_datos = _crear_estructura_por_defecto()
		estrellas_cambiadas.emit(0, 0)
		progreso_cargado.emit(_datos.duplicate(true))
	return true


func listar_slots() -> Array:
	var out: Array = []
	for i in range(1, MAX_SLOTS + 1):
		out.append(leer_slot_resumen(i))
	return out


func hay_algun_slot_ocupado() -> bool:
	for info in listar_slots():
		if bool(info.get("occupied", false)):
			return true
	return false


func primer_slot_libre() -> int:
	for info in listar_slots():
		if not bool(info.get("occupied", false)):
			return int(info.get("slot", 1))
	return 1


func leer_slot_resumen(slot_id: int) -> Dictionary:
	var id := clampi(slot_id, 1, MAX_SLOTS)
	var data: Dictionary = {}
	var target := ruta_slot(id)
	if id == active_slot and save_path == target and _datos_ocupados(_datos):
		data = _datos
	else:
		var primary := _leer_json_diccionario(target)
		if not primary.is_empty() and _es_estructura_valida(primary):
			data = primary
		else:
			var backup := _leer_json_diccionario(target + ".bak")
			if not backup.is_empty() and _es_estructura_valida(backup):
				data = backup
	if data.is_empty() or not _datos_ocupados(data):
		return {
			"slot": id,
			"active": id == active_slot,
			"occupied": false,
			"nickname": "",
			"mode": "cadete",
			"tiempo_juego": 0.0,
			"missions_done": 0,
			"stars_total": 0,
			"mission_id": "",
			"saved_iso": "",
			"saved_at": 0.0,
		}
	var exp: Dictionary = data.get("expedicion", {}) if data.get("expedicion") is Dictionary else {}
	var cur: Dictionary = exp.get("current", {}) if exp.get("current") is Dictionary else {}
	var cur_state: Dictionary = cur.get("state", {}) if cur.get("state") is Dictionary else {}
	var cur_legacy: Dictionary = cur.get("legacy", {}) if cur.get("legacy") is Dictionary else {}
	var cur_missions: Dictionary = cur.get("missions", {}) if cur.get("missions") is Dictionary else {}
	var perfil: Dictionary = data.get("perfil", {}) if data.get("perfil") is Dictionary else {}
	var mode_raw := str(perfil.get("mode", cur_state.get("modo_juego", data.get("modo_preferido", "cadete"))))
	var mode_norm := "ingeniero" if (mode_raw == "engineer" or mode_raw == "ingeniero") else "cadete"
	var top_comp: Array = data.get("misiones_completadas", []) if data.get("misiones_completadas") is Array else []
	var leg_comp: Array = cur_legacy.get("misiones_completadas", []) if cur_legacy.get("misiones_completadas") is Array else []
	var stars_total := maxi(int(data.get("estrellas_totales", 0)), int(cur_legacy.get("estrellas_totales", 0)))
	return {
		"slot": id,
		"active": id == active_slot,
		"occupied": true,
		"nickname": str(perfil.get("nickname", "")).strip_edges(),
		"mode": mode_norm,
		"tiempo_juego": float(cur_state.get("tiempo_juego", 0.0)),
		"missions_done": maxi(top_comp.size(), leg_comp.size()),
		"stars_total": stars_total,
		"mission_id": str(cur_missions.get("activa_id", cur_missions.get("mision_activa_id", ""))),
		"saved_iso": str(data.get("saved_iso", "")),
		"saved_at": float(data.get("saved_at", 0.0)),
	}


static func _datos_ocupados(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	var exp = d.get("expedicion", {})
	if exp is Dictionary and not exp.is_empty():
		return true
	var perfil = d.get("perfil", {})
	if perfil is Dictionary and (bool(perfil.get("tutorial_completed", false)) or not str(perfil.get("nickname", "")).strip_edges().is_empty()):
		return true
	if int(d.get("estrellas_totales", 0)) > 0:
		return true
	var comp = d.get("misiones_completadas", [])
	return comp is Array and not comp.is_empty()


func _migrar_guardado_legado() -> void:
	if not FileAccess.file_exists(DEFAULT_SAVE_PATH) or FileAccess.file_exists(ruta_slot(1)):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(DEFAULT_SAVE_PATH)) != OK or not (json.data is Dictionary):
		return
	if not _datos_ocupados(json.data):
		return
	DirAccess.make_dir_recursive_absolute(SLOTS_DIR)
	DirAccess.copy_absolute(DEFAULT_SAVE_PATH, ruta_slot(1))


func _cargar_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(META_PATH)) == OK and json.data is Dictionary:
		active_slot = clampi(int(json.data.get("active_slot", 1)), 1, MAX_SLOTS)
		tutorial_seen = bool(json.data.get("tutorial_seen", false))


func _guardar_meta() -> void:
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"active_slot": active_slot, "tutorial_seen": tutorial_seen}, "\t"))
	f.close()


func fue_tutorial_visto() -> bool:
	if tutorial_seen:
		return true
	for i in range(1, MAX_SLOTS + 1):
		var target := ruta_slot(i)
		if FileAccess.file_exists(target):
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(target)) == OK and json.data is Dictionary:
				var perfil = json.data.get("perfil", {})
				if perfil is Dictionary and bool(perfil.get("tutorial_completed", false)):
					tutorial_seen = true
					return true
	return false


func marcar_tutorial_visto(visto: bool = true) -> void:
	tutorial_seen = visto
	_guardar_meta()


func restaurar_progreso(datos: Dictionary) -> void:
	var prev_exp: Variant = _datos.get("expedicion", {})
	var prev_profile: Variant = _datos.get("perfil", {})
	_datos = _crear_estructura_por_defecto()
	if prev_exp is Dictionary and not (prev_exp as Dictionary).is_empty():
		_datos["expedicion"] = (prev_exp as Dictionary).duplicate(true)
	if prev_profile is Dictionary and not (prev_profile as Dictionary).is_empty():
		_datos["perfil"] = (prev_profile as Dictionary).duplicate(true)
	_combinar_con_defecto(datos)
	progreso_cargado.emit(_datos.duplicate(true))
	estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
