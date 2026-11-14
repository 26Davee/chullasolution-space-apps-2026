class_name TechTree
extends Node
## Gestiona el Árbol de Tecnologías y Mejoras de Killawasi.
##
## Carga upgrades.json, administra la billetera de estrellas junto a SaveManager,
## valida requisitos previos y notifica los efectos aplicados a la simulación (Puesto 2).

signal mejora_desbloqueada(id_mejora: String, rama: String, nivel: int)
signal efecto_simulacion_aplicado(tipo_efecto: String, datos_efecto: Dictionary)
signal estrellas_actualizadas(total_estrellas: int)
signal compra_rechazada(id_mejora: String, motivo: String)

const DEFAULT_UPGRADES_PATH := "res://data/missions/upgrades.json"
const SaveManagerScript := preload("res://progression/save_manager.gd")

@export var upgrades_path: String = DEFAULT_UPGRADES_PATH
@export var save_manager: Node

var _ramas: Array = []
var _mejoras_por_id: Dictionary = {}
var _rama_de_mejora: Dictionary = {}


func _ready() -> void:
	_asegurar_save_manager()
	cargar_arbol()


## Asigna manualmente un SaveManager (útil para inyección en pruebas o escenas).
func set_save_manager(manager: Node) -> void:
	save_manager = manager
	if is_instance_valid(save_manager):
		if not save_manager.estrellas_cambiadas.is_connected(_on_estrellas_cambiadas):
			save_manager.estrellas_cambiadas.connect(_on_estrellas_cambiadas)


## Carga y valida el árbol de mejoras desde el archivo JSON.
func cargar_arbol(ruta: String = upgrades_path) -> bool:
	_ramas.clear()
	_mejoras_por_id.clear()
	_rama_de_mejora.clear()

	if not FileAccess.file_exists(ruta):
		push_error("TechTree: No se encontró el archivo %s." % ruta)
		return false

	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("TechTree: No se pudo abrir %s." % ruta)
		return false

	var json := JSON.new()
	var err := json.parse(archivo.get_as_text())
	archivo.close()
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("TechTree: Error de sintaxis JSON en %s." % ruta)
		return false

	var raiz: Dictionary = json.data.get("arbol_habilidades", {})
	var ramas_leidas: Variant = raiz.get("ramas", [])
	if typeof(ramas_leidas) != TYPE_ARRAY:
		return false

	_ramas = ramas_leidas
	for rama in _ramas:
		if typeof(rama) != TYPE_DICTIONARY:
			continue
		var id_rama := str(rama.get("id", ""))
		var mejoras: Variant = rama.get("mejoras", [])
		if typeof(mejoras) != TYPE_ARRAY:
			continue
		for mejora in mejoras:
			if typeof(mejora) != TYPE_DICTIONARY:
				continue
			var id_mejora := str(mejora.get("id", ""))
			if not id_mejora.is_empty():
				_mejoras_por_id[id_mejora] = mejora
				_rama_de_mejora[id_mejora] = id_rama

	return not _mejoras_por_id.is_empty()


func obtener_ramas() -> Array:
	return _ramas.duplicate(true)


func obtener_mejora(id_mejora: String) -> Dictionary:
	if not _mejoras_por_id.has(id_mejora):
		return {}
	return (_mejoras_por_id[id_mejora] as Dictionary).duplicate(true)


func obtener_estrellas_disponibles() -> int:
	_asegurar_save_manager()
	return save_manager.obtener_estrellas_disponibles()


func tiene_estrellas(costo: int) -> bool:
	return obtener_estrellas_disponibles() >= costo


func esta_comprada(id_mejora: String) -> bool:
	_asegurar_save_manager()
	return save_manager.esta_mejora_comprada(id_mejora)


## Evalúa si una mejora puede comprarse y devuelve {"ok": bool, "motivo": String}.
func puede_comprar(id_mejora: String) -> Dictionary:
	_asegurar_save_manager()
	if not _mejoras_por_id.has(id_mejora):
		return {"ok": false, "motivo": "mejora_no_encontrada"}
	if esta_comprada(id_mejora):
		return {"ok": false, "motivo": "ya_comprada"}

	var mejora: Dictionary = _mejoras_por_id[id_mejora]
	var requisito: Variant = mejora.get("requisito", null)
	if requisito != null and not str(requisito).is_empty():
		var id_req := str(requisito)
		if not esta_comprada(id_req):
			return {"ok": false, "motivo": "falta_requisito:%s" % id_req}

	var costo := int(mejora.get("costo", 0))
	if not tiene_estrellas(costo):
		return {"ok": false, "motivo": "estrellas_insuficientes"}

	return {"ok": true, "motivo": "ok"}


## Compra una mejora válida, descuenta estrellas y notifica a la simulación (Puesto 2).
func comprar_mejora(id_mejora: String, modo_juego: String = "cadete") -> bool:
	var validacion := puede_comprar(id_mejora)
	if not bool(validacion["ok"]):
		compra_rechazada.emit(id_mejora, str(validacion["motivo"]))
		return false

	var mejora: Dictionary = _mejoras_por_id[id_mejora]
	var costo := int(mejora.get("costo", 0))
	var carta_id := "carta_%s" % id_mejora

	if not save_manager.registrar_mejora_comprada(id_mejora, costo, carta_id):
		compra_rechazada.emit(id_mejora, "error_guardado")
		return false

	var rama := str(_rama_de_mejora.get(id_mejora, ""))
	var nivel := int(mejora.get("nivel", 1))

	mejora_desbloqueada.emit(id_mejora, rama, nivel)
	_emitir_efecto_mejora(mejora, modo_juego)
	estrellas_actualizadas.emit(obtener_estrellas_disponibles())
	return true


## Reaplica en orden todas las mejoras guardadas al iniciar una nueva sesión o partida.
func aplicar_todas_las_mejoras_guardadas(modo_juego: String = "cadete") -> void:
	_asegurar_save_manager()
	for rama in _ramas:
		if typeof(rama) != TYPE_DICTIONARY:
			continue
		for mejora in rama.get("mejoras", []):
			if typeof(mejora) != TYPE_DICTIONARY:
				continue
			var id_mejora := str(mejora.get("id", ""))
			if esta_comprada(id_mejora):
				_emitir_efecto_mejora(mejora, modo_juego)


func _emitir_efecto_mejora(mejora: Dictionary, modo_juego: String) -> void:
	var efecto: Dictionary = mejora.get("efecto", {})
	var tipo := str(efecto.get("tipo", ""))
	if tipo.is_empty():
		return

	var id_mejora := str(mejora.get("id", ""))
	var datos := _construir_datos_efecto(id_mejora, tipo, efecto, modo_juego)
	efecto_simulacion_aplicado.emit(tipo, datos)


func _construir_datos_efecto(id_mejora: String, tipo: String, efecto: Dictionary, modo_juego: String) -> Dictionary:
	var es_ingeniero := modo_juego == "ingeniero"
	match tipo:
		"limite_estructura":
			return {"id_mejora": id_mejora, "max_paneles": int(efecto.get("valor", 3))}
		"energia_maxima":
			return {"id_mejora": id_mejora, "energia_maxima": float(efecto.get("valor", 150.0))}
		"produccion_solar":
			return {"id_mejora": id_mejora, "produccion_por_s": float(efecto.get("valor", 0.75)), "multiplicador": 1.25}
		"velocidad_procesador":
			return {"id_mejora": id_mejora, "tiempo_proceso_s": float(efecto.get("valor", 3.0))}
		"consumo_oxigeno":
			return {"id_mejora": id_mejora, "multiplicador_consumo": float(efecto.get("valor", 0.75)), "ahorro_pct": 25}
		"desbloqueo_jardin":
			return {"id_mejora": id_mejora, "jardin_desbloqueado": true, "regeneracion_vida_s": float(efecto.get("valor", 0.4))}
		"costo_reparacion":
			var costo_cad := int(efecto.get("valor", 15))
			var costo_ing := 22
			return {
				"id_mejora": id_mejora,
				"costo_cadete": costo_cad,
				"costo_ingeniero": costo_ing,
				"valor_activo": costo_ing if es_ingeniero else costo_cad,
			}
		"resistencia_nube":
			var dano_cad := int(efecto.get("valor", 22))
			var dano_ing := 30
			return {
				"id_mejora": id_mejora,
				"dano_cadete": dano_cad,
				"dano_ingeniero": dano_ing,
				"valor_activo": dano_ing if es_ingeniero else dano_cad,
			}
		"tiempo_alerta":
			return {
				"id_mejora": id_mejora,
				"aviso_segundos": int(efecto.get("valor", 40)),
				"tiempo_reparacion_s": int(efecto.get("tiempo_reparacion_s", 2)),
			}
		"herramienta_hielo":
			var nivel_herramienta := _obtener_nivel_herramienta(id_mejora)
			var vida_cad := float(efecto.get("vida_perdida_cadete", 8))
			var vida_ing := float(efecto.get("vida_perdida_ingeniero", 12))
			return {
				"id_mejora": id_mejora,
				"herramienta_nivel": nivel_herramienta,
				"hielo_por_viaje": int(efecto.get("hielo_por_viaje", 4)),
				"vida_perdida_cadete": vida_cad,
				"vida_perdida_ingeniero": vida_ing,
				"vida_perdida_activa": vida_ing if es_ingeniero else vida_cad,
			}
		_:
			return {"id_mejora": id_mejora, "efecto": efecto.duplicate(true)}


func _obtener_nivel_herramienta(id_mejora: String) -> int:
	match id_mejora:
		"pico_geologico":
			return 2
		"taladro_manual":
			return 3
		"taladro_mochila":
			return 4
		_:
			return 1


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


func _on_estrellas_cambiadas(disponibles: int, _totales: int) -> void:
	estrellas_actualizadas.emit(disponibles)
