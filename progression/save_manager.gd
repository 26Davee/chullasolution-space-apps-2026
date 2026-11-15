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

@export var save_path: String = DEFAULT_SAVE_PATH

var _datos: Dictionary = {}
var ultimo_error := ""
var respaldo_recuperado := false


func _ready() -> void:
	cargar_progreso()


## Carga el archivo de guardado desde disco o inicializa una partida limpia.
func cargar_progreso() -> Dictionary:
	ultimo_error = ""
	respaldo_recuperado = false
	_datos = _crear_estructura_por_defecto()

	if not FileAccess.file_exists(save_path):
		guardar_progreso()
		progreso_cargado.emit(_datos.duplicate(true))
		return _datos.duplicate(true)

	var archivo := FileAccess.open(save_path, FileAccess.READ)
	if archivo == null:
		ultimo_error = "read"
		push_warning("SaveManager: No se pudo abrir %s. Usando valores por defecto." % save_path)
		progreso_cargado.emit(_datos.duplicate(true))
		return _datos.duplicate(true)

	var texto := archivo.get_as_text()
	archivo.close()

	var json := JSON.new()
	var err := json.parse(texto)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		ultimo_error = "corrupt"
		# Preserve the unreadable file; a valid backup is preferred to a fresh run.
		DirAccess.copy_absolute(save_path, save_path + ".invalid")
		var backup := JSON.new()
		if FileAccess.file_exists(save_path + ".bak") and backup.parse(FileAccess.get_file_as_string(save_path + ".bak")) == OK and backup.data is Dictionary:
			_combinar_con_defecto(backup.data)
			respaldo_recuperado = true
		push_warning("SaveManager: Archivo inválido preservado; se usó el respaldo si estaba disponible.")
		progreso_cargado.emit(_datos.duplicate(true))
		return _datos.duplicate(true)

	_combinar_con_defecto(json.data)
	progreso_cargado.emit(_datos.duplicate(true))
	estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
	return _datos.duplicate(true)


## Escribe el estado actual del progreso en disco en formato JSON.
func guardar_progreso() -> bool:
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
	if result != OK:
		ultimo_error = "write"
		progreso_guardado.emit(false)
		return false
	if FileAccess.file_exists(save_path):
		var existing := JSON.new()
		if existing.parse(FileAccess.get_file_as_string(save_path)) == OK and existing.data is Dictionary:
			DirAccess.copy_absolute(save_path, save_path + ".bak")
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
	return guardar_progreso()


func restaurar_progreso(datos: Dictionary) -> void:
	_datos = _crear_estructura_por_defecto()
	_combinar_con_defecto(datos)
	progreso_cargado.emit(_datos.duplicate(true))
	estrellas_cambiadas.emit(obtener_estrellas_disponibles(), obtener_estrellas_totales())
