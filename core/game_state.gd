extends Node
## GameState — estado central y bus de señales (autoload). Dueño: puesto 1.
##
## Qué es: el único sitio donde viven los números de la partida y por donde
## pasan las señales entre puestos. Las variables y señales son EXACTAMENTE las
## del diccionario del equipo (variables_sistema.json). Para añadir o renombrar
## algo hay que avisar en el grupo y que acepten los dos lados.
##
## Cómo se usa desde otro script (no hace falta importar nada):
##     GameState.energia                      # leer
##     GameState.recurso_actualizado.connect(_al_cambiar)   # escuchar
##     GameState.accion_construir_solicitada.emit("panel_solar", 3)   # pedir
##
## Todas las cifras son UNIDADES DE JUEGO (ficticias), no datos de NASA.

# ─────────────────────────── Señales (12) ───────────────────────────
# Emitidas por la simulación (puesto 2)
signal recurso_actualizado(tipo_recurso: String, valor_actual: float, valor_maximo: float)
signal ciclo_solar_cambiado(es_dia: bool)
signal advertencia_nube_iniciada(tiempo_restante: float)
signal nube_impacto(fuerza_dano: float, dano_sobrecarga: float)
signal nube_finalizada()
# Emitidas por la interacción (puesto 4)
signal accion_construir_solicitada(id_estructura: String, casilla_id: int)
signal accion_viaje_hielo_solicitada()
signal accion_reparar_escudo_solicitada()
# Emitidas por misiones y progresión (puesto 5)
signal mision_completada(id_mision: String, estrellas: int, carta_nasa: Dictionary)
signal mejora_desbloqueada(id_mejora: String, rama: String, nivel: int)
signal estrellas_actualizadas(total_estrellas: int)
# Batería independiente del robot (5.42 kWh VIPER, separada de la Energía Total de la Base)
signal robot_energia_actualizada(valor_actual: float, valor_maximo: float)
# Emitida por interfaz y tutorial (puesto 6)
signal vicuna_mensaje_mostrado(paso_tutorial: int, texto_clave: String)

# Señales propias del puesto 1 (ciclo de vida de la partida; no están en el diccionario)
signal partida_iniciada(modo: String)
signal partida_terminada()

# ─────────────────────────── Constantes ───────────────────────────
const MODO_CADETE := "cadete"
const MODO_INGENIERO := "ingeniero"
const MODOS := [MODO_CADETE, MODO_INGENIERO]

const ENERGIA_MAX_BASE := 100.0
const ENERGIA_MAX_BATERIA := 150.0
const ROBOT_ENERGIA_MAX := 100.0     # 100% = 5.42 kWh (batería rover NASA VIPER)
const HIELO_MAX := 40                # bloques (1 bloque = 10 kg = 10 L de agua)
const AGUA_MAX_POR_DEFECTO := 100.0
const OXIGENO_MAX := 100.0
const ESCUDO_MAX := 100.0
const TIEMPO_CICLO_SOLAR := 480.0    # 240 s (4 min) de día + 240 s (4 min) de noche ≈ 29.53 días terrestres
const TIEMPO_DIA_SOLAR := 240.0
const DIAS_TERRESTRES_POR_CICLO := 29.53
const PRIMERA_NUBE_S := 180.0

## Anclas físicas documentadas en docs/DATOS_NASA.md y docs/CALCULOS_SISTEMA.md
const TRIPULACION_DOMO := 4
const BASE_KWH_MAX := 2000.0         # 100% Base = 2,000 kWh (150% = 3,000 kWh con batería extra)
const ROBOT_KWH_MAX := 5.42          # 100% Robot = 5.42 kWh
const AGUA_LITROS_MAX := 200.0       # 100% Agua = 200 Litros
const OXIGENO_KG_MAX := 50.0         # 100% Oxígeno = 50 kg (~14.7 días de reserva para 4 humanos)
const HIELO_KG_POR_BLOQUE := 10.0    # 1 bloque de hielo = 10 kg = 10 Litros de agua

## Recursos que viajan por recurso_actualizado (los que pintan barras en el HUD).
const RECURSOS := ["energia", "hielo", "agua", "oxigeno", "escudo"]

## Ruta de la simulación de Anahi. Si el archivo no existe, GameState funciona
## igual (solo guarda estado) y la simulación se enchufa cuando llegue.
const RUTA_SIMULACION := "res://simulation/simulacion.gd"
const RUTA_BALANCE := "res://data/balance/%s.json"
const RUTA_SAVE_MANAGER := "res://progression/save_manager.gd"
const RUTA_MISSION_MANAGER := "res://progression/mission_manager.gd"
const RUTA_TECH_TREE := "res://progression/tech_tree.gd"

# ─────────────────────────── Variables de estado ───────────────────────────
var energia: float = 60.0
var energia_robot: float = ROBOT_ENERGIA_MAX
var descansando_en_domo: bool = false
var hielo: int = 0
var agua: float = 20.0
var oxigeno: float = 45.0
var escudo: float = 100.0
var estrellas: int = 0
var modo_juego: String = MODO_CADETE
var tiempo_juego: float = 0.0
var es_dia: bool = true
var tiempo_ciclo_solar: float = 0.0
var alerta_nube: bool = false
var tiempo_para_nube: float = PRIMERA_NUBE_S
var nube_activa: bool = false
var en_viaje_hielo: bool = false
var herramienta_nivel: int = 1
var paneles_instalados: int = 0
var generador_pausado: bool = false
var robot_en_domo: bool = false
var procesador_instalado: bool = false
var generador_instalado: bool = false
var jardin_instalado: bool = false
var bateria_instalada: bool = false

## Máximos que cambian con mejoras (los ajusta la simulación o el puesto 5).
var agua_max: float = AGUA_MAX_POR_DEFECTO

## Perfil elegido en la intro de Puesto 6 (ui/intro.gd).
var nombre_astronauta: String = "Commander"
var idioma: String = "en"
var voz_activa: bool = true

## true mientras hay una partida en curso (el tiempo solo corre entonces).
var preferencias: Dictionary = {}
var en_partida: bool = false

var _sim = null          # instancia de Simulacion (RefCounted) si está disponible
var _ultimo_emitido: Dictionary = {}
var _save_manager: Node = null
var _mission_manager: Node = null
var _tech_tree: Node = null


# ─────────────────────────── Ciclo de vida ───────────────────────────

func _ready() -> void:
	_registrar_idiomas()
	TranslationServer.set_locale(idioma)
	_inicializar_progresion()


func _registrar_idiomas() -> void:
	var catalogs := {
		"en": "res://i18n/en.gd",
		"es": "res://i18n/es.gd",
	}
	for locale in catalogs:
		var path: String = catalogs[locale]
		if not ResourceLoader.exists(path):
			continue
		var script = load(path)
		if script == null or not ("MESSAGES" in script):
			continue
		var translation := Translation.new()
		translation.locale = locale
		for key in script.MESSAGES:
			translation.add_message(key, script.MESSAGES[key])
		TranslationServer.add_translation(translation)


func _process(delta: float) -> void:
	if not en_partida:
		return
	if _sim != null:
		_sim.tick(delta)
		_copiar_desde_simulacion()
	else:
		tiempo_juego += delta
	if _mission_manager != null:
		_mission_manager.evaluar_estado_simulacion(obtener_estado_diccionario(), delta)


func normalizar_modo(modo: String) -> String:
	match modo:
		"engineer", MODO_INGENIERO:
			return MODO_INGENIERO
		_:
			return MODO_CADETE


func aplicar_perfil(perfil: Dictionary) -> String:
	preferencias = perfil.duplicate(true)
	var nombre := str(perfil.get("nickname", "")).strip_edges()
	nombre_astronauta = nombre if not nombre.is_empty() else tr("v2.default_name")
	var lang := str(perfil.get("language", "en"))
	idioma = "es" if lang.to_lower().begins_with("es") else "en"
	voz_activa = bool(perfil.get("voice_enabled", true))
	TranslationServer.set_locale(idioma)
	return normalizar_modo(str(perfil.get("mode", MODO_CADETE)))


## Empieza una partida desde cero con el modo elegido ("cadete"/"cadet" o "ingeniero"/"engineer").
func iniciar_partida(modo: String = MODO_CADETE) -> void:
	reiniciar()
	modo_juego = normalizar_modo(modo)
	_sim = _crear_simulacion(modo_juego)
	if _sim != null:
		_copiar_desde_simulacion()
	en_partida = true
	_emitir_todos_los_recursos(true)
	_emitir_energia_robot(true)
	if _save_manager != null:
		estrellas = _save_manager.obtener_estrellas_disponibles()
	estrellas_actualizadas.emit(estrellas)
	if _mission_manager != null:
		_mission_manager.establecer_modo_juego(modo_juego)
		_mission_manager.notificar_evento("partida_iniciada", {"modo": modo_juego})
	partida_iniciada.emit(modo_juego)


## Aplica las mejoras persistentes guardadas en El Legado (SaveManager).
func aplicar_legado() -> void:
	if _tech_tree != null:
		_tech_tree.aplicar_todas_las_mejoras_guardadas(modo_juego)


func terminar_partida() -> void:
	en_partida = false
	partida_terminada.emit()


## Deja todas las variables en su valor inicial del diccionario.
func reiniciar() -> void:
	en_partida = false
	_sim = null
	_ultimo_emitido.clear()
	energia = 60.0
	energia_robot = ROBOT_ENERGIA_MAX
	descansando_en_domo = false
	hielo = 0
	agua = 20.0
	oxigeno = 45.0
	escudo = 100.0
	estrellas = 0
	modo_juego = MODO_CADETE
	tiempo_juego = 0.0
	es_dia = true
	tiempo_ciclo_solar = 0.0
	alerta_nube = false
	tiempo_para_nube = PRIMERA_NUBE_S
	nube_activa = false
	en_viaje_hielo = false
	herramienta_nivel = 1
	paneles_instalados = 0
	generador_pausado = false
	robot_en_domo = false
	procesador_instalado = false
	generador_instalado = false
	jardin_instalado = false
	bateria_instalada = false
	agua_max = AGUA_MAX_POR_DEFECTO


# ─────────────────────────── Recursos (lectura y escritura segura) ───────────────────────────

## Máximo de un recurso ("energia", "agua"...). 0 si el nombre no existe.
func maximo_de(tipo: String) -> float:
	match tipo:
		"energia": return ENERGIA_MAX_BATERIA if bateria_instalada else ENERGIA_MAX_BASE
		"hielo": return float(HIELO_MAX)
		"agua": return agua_max
		"oxigeno": return OXIGENO_MAX
		"escudo": return ESCUDO_MAX
	return 0.0


func minimo_de(_tipo: String) -> float:
	return 0.0


## Valor actual de un recurso por nombre.
func valor_de(tipo: String) -> float:
	if tipo in RECURSOS:
		return float(get(tipo))
	return 0.0


## Fija un recurso respetando sus límites y avisa a la interfaz.
## Devuelve el valor final (ya recortado).
func fijar_recurso(tipo: String, valor: float) -> float:
	if not (tipo in RECURSOS):
		push_warning("GameState: recurso desconocido '%s'" % tipo)
		return 0.0
	var v := clampf(valor, minimo_de(tipo), maximo_de(tipo))
	if tipo == "hielo":
		hielo = int(round(v))
	else:
		set(tipo, v)
	_emitir_recurso(tipo)
	return v


## Suma (o resta, si es negativo) a un recurso. Devuelve el valor final.
func cambiar_recurso(tipo: String, delta: float) -> float:
	return fijar_recurso(tipo, valor_de(tipo) + delta)


## ¿Alcanza el recurso para pagar `costo`? (no cobra)
func puede_pagar(tipo: String, costo: float) -> bool:
	return valor_de(tipo) >= costo


## Cobra si alcanza. Devuelve true si cobró.
func pagar(tipo: String, costo: float) -> bool:
	if not puede_pagar(tipo, costo):
		return false
	cambiar_recurso(tipo, -costo)
	return true


## Fija la batería propia del robot (0..100%) y notifica a la interfaz.
func fijar_energia_robot(valor: float) -> float:
	energia_robot = clampf(valor, 0.0, ROBOT_ENERGIA_MAX)
	_emitir_energia_robot()
	return energia_robot


## Suma o resta energía de la batería propia del robot.
func cambiar_energia_robot(delta: float) -> float:
	return fijar_energia_robot(energia_robot + delta)


## Cobra de la batería propia del robot si alcanza.
func pagar_robot(costo: float) -> bool:
	if energia_robot < costo:
		return false
	cambiar_energia_robot(-costo)
	return true


func agregar_estrellas(cantidad: int) -> void:
	estrellas = maxi(0, estrellas + cantidad)
	estrellas_actualizadas.emit(estrellas)


# ─────────────────────────── Acciones (atajos para el puesto 4) ───────────────────────────
# Emiten la señal del diccionario. Si la simulación está conectada, además la
# ejecutan y devuelven su resultado ("ok" o un código de motivo).

func solicitar_construir(id_estructura: String, casilla_id: int = -1) -> String:
	accion_construir_solicitada.emit(id_estructura, casilla_id)
	if _sim == null:
		return "sin_simulacion"
	var r: String = _sim.construir(id_estructura)
	_copiar_desde_simulacion()
	return r


func solicitar_viaje_hielo() -> String:
	accion_viaje_hielo_solicitada.emit()
	if _sim == null:
		return "sin_simulacion"
	var r: String = _sim.iniciar_viaje_hielo()
	_copiar_desde_simulacion()
	return r


func solicitar_reparar_escudo() -> String:
	accion_reparar_escudo_solicitada.emit()
	if _sim == null:
		return "sin_simulacion"
	var r: String = _sim.reparar_escudo()
	_copiar_desde_simulacion()
	return r


## ¿Hay una simulación enchufada? (útil para pruebas y para el HUD de depuración)
func hay_simulacion() -> bool:
	return _sim != null


func obtener_estado_diccionario() -> Dictionary:
	return {
		"energia": energia,
		"energia_robot": energia_robot,
		"descansando_en_domo": descansando_en_domo,
		"hielo": hielo,
		"agua": agua,
		"oxigeno": oxigeno,
		"escudo": escudo,
		"estrellas": estrellas,
		"modo_juego": modo_juego,
		"tiempo_juego": tiempo_juego,
		"es_dia": es_dia,
		"tiempo_ciclo_solar": tiempo_ciclo_solar,
		"alerta_nube": alerta_nube,
		"tiempo_para_nube": tiempo_para_nube,
		"nube_activa": nube_activa,
		"en_viaje_hielo": en_viaje_hielo,
		"herramienta_nivel": herramienta_nivel,
		"paneles_instalados": paneles_instalados,
		"generador_pausado": generador_pausado,
		"robot_en_domo": robot_en_domo,
		"procesador_instalado": procesador_instalado,
		"generador_instalado": generador_instalado,
		"jardin_instalado": jardin_instalado,
		"bateria_instalada": bateria_instalada,
	}


func obtener_mission_manager() -> Node:
	return _mission_manager


func obtener_tech_tree() -> Node:
	return _tech_tree


func obtener_save_manager() -> Node:
	return _save_manager


func obtener_mision_activa_localizada() -> Dictionary:
	if _mission_manager == null:
		return {}
	return _mission_manager.obtener_mision_activa_localizada(idioma)


func obtener_ramas_mejoras_localizadas() -> Array:
	if _tech_tree == null:
		return []
	return _tech_tree.obtener_ramas_localizadas(idioma)


func comprar_mejora(id_mejora: String) -> bool:
	if _tech_tree == null:
		return false
	return _tech_tree.comprar_mejora(id_mejora, modo_juego)


func notificar_evento_mision(nombre_evento: String, datos: Dictionary = {}) -> void:
	if _mission_manager != null:
		_mission_manager.notificar_evento(nombre_evento, datos)


func _inicializar_progresion() -> void:
	if not (ResourceLoader.exists(RUTA_SAVE_MANAGER) and ResourceLoader.exists(RUTA_MISSION_MANAGER) and ResourceLoader.exists(RUTA_TECH_TREE)):
		return
	var save_script = load(RUTA_SAVE_MANAGER)
	var mission_script = load(RUTA_MISSION_MANAGER)
	var tree_script = load(RUTA_TECH_TREE)
	if save_script == null or mission_script == null or tree_script == null:
		return

	_save_manager = save_script.new()
	_save_manager.name = "SaveManager"
	add_child(_save_manager)

	_mission_manager = mission_script.new()
	_mission_manager.name = "MissionManager"
	_mission_manager.set_save_manager(_save_manager)
	add_child(_mission_manager)

	_tech_tree = tree_script.new()
	_tech_tree.name = "TechTree"
	_tech_tree.set_save_manager(_save_manager)
	add_child(_tech_tree)

	_mission_manager.mision_completada.connect(func(id_m: String, pts: int, carta: Dictionary):
		_sincronizar_estrellas(_save_manager.obtener_estrellas_disponibles(), _save_manager.obtener_estrellas_totales())
		mision_completada.emit(id_m, pts, carta)
	)
	_tech_tree.mejora_desbloqueada.connect(func(id_u: String, rama: String, nivel: int):
		mejora_desbloqueada.emit(id_u, rama, nivel)
	)
	_save_manager.estrellas_cambiadas.connect(_sincronizar_estrellas)
	_sincronizar_estrellas(_save_manager.obtener_estrellas_disponibles(), _save_manager.obtener_estrellas_totales())
	_tech_tree.efecto_simulacion_aplicado.connect(_al_aplicar_efecto_mejora)

	advertencia_nube_iniciada.connect(func(_t: float): notificar_evento_mision("advertencia_nube_iniciada", {"en_viaje_hielo": en_viaje_hielo}))
	nube_impacto.connect(func(_f: float, _p: float): notificar_evento_mision("nube_impacto", {"escudo_restante": escudo}))
	nube_finalizada.connect(func(): notificar_evento_mision("nube_finalizada"))
	accion_reparar_escudo_solicitada.connect(func(): notificar_evento_mision("reparar_escudo_iniciado"))


func _al_aplicar_efecto_mejora(tipo: String, datos: Dictionary) -> void:
	match tipo:
		"energia_maxima":
			bateria_instalada = true
			_emitir_recurso("energia", true)
		"herramienta_hielo":
			herramienta_nivel = int(datos.get("herramienta_nivel", herramienta_nivel))
		"desbloqueo_jardin":
			jardin_instalado = true


# ─────────────────────────── Puente con la simulación (puesto 2) ───────────────────────────

func _crear_simulacion(modo: String):
	if not ResourceLoader.exists(RUTA_SIMULACION):
		return null
	if not FileAccess.file_exists(RUTA_BALANCE % modo):
		push_warning("GameState: falta %s; la simulación no se activa." % (RUTA_BALANCE % modo))
		return null
	var script = load(RUTA_SIMULACION)
	if script == null:
		return null
	var sim = script.new(modo)
	if sim.estado.is_empty():
		return null
	# Reenviar las señales de la simulación por el bus global.
	sim.ciclo_solar_cambiado.connect(func(dia: bool): ciclo_solar_cambiado.emit(dia))
	sim.advertencia_nube_iniciada.connect(func(t: float): advertencia_nube_iniciada.emit(t))
	sim.nube_impacto.connect(func(f: float, p: float): nube_impacto.emit(f, p))
	sim.nube_finalizada.connect(func(): nube_finalizada.emit())
	return sim


## Copia el estado interno de la simulación a las variables del diccionario.
## Traducciones de nombre: paneles → paneles_instalados.
func _copiar_desde_simulacion() -> void:
	var e: Dictionary = _sim.estado
	tiempo_juego = e.get("tiempo_juego", tiempo_juego)
	es_dia = e.get("es_dia", es_dia)
	alerta_nube = e.get("alerta_nube", alerta_nube)
	nube_activa = e.get("nube_activa", nube_activa)
	tiempo_para_nube = e.get("tiempo_para_nube", tiempo_para_nube)
	en_viaje_hielo = e.get("en_viaje_hielo", en_viaje_hielo)
	herramienta_nivel = int(e.get("herramienta_nivel", herramienta_nivel))
	paneles_instalados = int(e.get("paneles", paneles_instalados))
	procesador_instalado = e.get("procesador_instalado", procesador_instalado)
	generador_instalado = e.get("generador_instalado", generador_instalado)
	jardin_instalado = e.get("jardin_instalado", jardin_instalado)
	bateria_instalada = e.get("bateria_instalada", bateria_instalada)
	tiempo_ciclo_solar = fmod(tiempo_juego, TIEMPO_CICLO_SOLAR)
	if _sim.has_method("tope_agua"):
		agua_max = _sim.tope_agua()
	energia = e.get("energia", energia)
	agua = e.get("agua", agua)
	oxigeno = e.get("oxigeno", oxigeno)
	escudo = e.get("escudo", escudo)
	hielo = int(e.get("hielo", hielo))
	for tipo in RECURSOS:
		_emitir_recurso(tipo)


# ─────────────────────────── Internos ───────────────────────────

func _emitir_todos_los_recursos(forzar: bool = false) -> void:
	for tipo in RECURSOS:
		_emitir_recurso(tipo, forzar)


## Emite recurso_actualizado solo si el valor cambió de verdad (evita saturar el HUD).
func _emitir_recurso(tipo: String, forzar: bool = false) -> void:
	var v := valor_de(tipo)
	var m := maximo_de(tipo)
	var anterior = _ultimo_emitido.get(tipo, null)
	if not forzar and anterior != null and absf(anterior[0] - v) < 0.05 and anterior[1] == m:
		return
	_ultimo_emitido[tipo] = [v, m]
	recurso_actualizado.emit(tipo, v, m)


func _emitir_energia_robot(forzar: bool = false) -> void:
	var anterior = _ultimo_emitido.get("energia_robot", null)
	if not forzar and anterior != null and absf(anterior[0] - energia_robot) < 0.05 and anterior[1] == ROBOT_ENERGIA_MAX:
		return
	_ultimo_emitido["energia_robot"] = [energia_robot, ROBOT_ENERGIA_MAX]
	robot_energia_actualizada.emit(energia_robot, ROBOT_ENERGIA_MAX)


func _sincronizar_estrellas(disponibles: int, _totales: int) -> void:
	estrellas = disponibles
	estrellas_actualizadas.emit(estrellas)
