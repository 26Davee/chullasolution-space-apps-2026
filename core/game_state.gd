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
signal nube_impacto(fuerza_dano: float, paso_a_vida: float)
signal nube_finalizada()
# Emitidas por la interacción (puesto 4)
signal accion_construir_solicitada(id_estructura: String, casilla_id: int)
signal accion_viaje_hielo_solicitada()
signal accion_reparar_escudo_solicitada()
# Emitidas por misiones y progresión (puesto 5)
signal mision_completada(id_mision: String, estrellas: int, carta_nasa: Dictionary)
signal mejora_desbloqueada(id_mejora: String, rama: String, nivel: int)
signal estrellas_actualizadas(total_estrellas: int)
# Emitida por interfaz y tutorial (puesto 6)
signal vicuna_mensaje_mostrado(paso_tutorial: int, texto_clave: String)

# Señales propias del puesto 1 (ciclo de vida de la partida; no están en el diccionario)
signal partida_iniciada(modo: String)
signal partida_terminada()
signal viaje_hielo_terminado(hielo_traido: int)

# ─────────────────────────── Constantes ───────────────────────────
const MODO_CADETE := "cadete"
const MODO_INGENIERO := "ingeniero"
const MODOS := [MODO_CADETE, MODO_INGENIERO]

const ENERGIA_MAX_BASE := 100.0
const ENERGIA_MAX_BATERIA := 150.0
const HIELO_MAX := 40
const AGUA_MAX_POR_DEFECTO := 100.0  # POR DECIDIR: el doc dice 60 + 50 por tanque
const OXIGENO_MAX := 100.0
const VIDA_MIN := 10.0               # la vida nunca baja de 10
const VIDA_MAX := 100.0
const ESCUDO_MAX := 100.0
const TIEMPO_CICLO_SOLAR := 480.0    # 300 s de día + 180 s de noche
const PRIMERA_NUBE_S := 180.0

## Recursos que viajan por recurso_actualizado (los que pintan barras en el HUD).
const RECURSOS := ["energia", "hielo", "agua", "oxigeno", "vida", "escudo"]

## Ruta de la simulación de Anahi. Si el archivo no existe, GameState funciona
## igual (solo guarda estado) y la simulación se enchufa cuando llegue.
const RUTA_SIMULACION := "res://simulation/simulacion.gd"
const RUTA_BALANCE := "res://data/balance/%s.json"

# ─────────────────────────── Variables de estado (21) ───────────────────────────
var energia: float = 60.0
var hielo: int = 0
var agua: float = 20.0
var oxigeno: float = 60.0
var vida: float = 100.0
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
var procesador_instalado: bool = false
var generador_instalado: bool = false
var jardin_instalado: bool = false
var bateria_instalada: bool = false

## Máximos que cambian con mejoras (los ajusta la simulación o el puesto 5).
var agua_max: float = AGUA_MAX_POR_DEFECTO

## true mientras hay una partida en curso (el tiempo solo corre entonces).
var en_partida: bool = false

var _sim = null          # instancia de Simulacion (RefCounted) si está disponible
var _ultimo_emitido: Dictionary = {}


# ─────────────────────────── Ciclo de vida ───────────────────────────

func _process(delta: float) -> void:
	if not en_partida:
		return
	if _sim != null:
		_sim.tick(delta)
		_copiar_desde_simulacion()
	else:
		tiempo_juego += delta


## Empieza una partida desde cero con el modo elegido ("cadete" o "ingeniero").
func iniciar_partida(modo: String = MODO_CADETE) -> void:
	reiniciar()
	modo_juego = modo if modo in MODOS else MODO_CADETE
	_sim = _crear_simulacion(modo_juego)
	if _sim != null:
		_copiar_desde_simulacion()
	en_partida = true
	_emitir_todos_los_recursos(true)
	estrellas_actualizadas.emit(estrellas)
	partida_iniciada.emit(modo_juego)


func terminar_partida() -> void:
	en_partida = false
	partida_terminada.emit()


## Deja todas las variables en su valor inicial del diccionario.
func reiniciar() -> void:
	en_partida = false
	_sim = null
	_ultimo_emitido.clear()
	energia = 60.0
	hielo = 0
	agua = 20.0
	oxigeno = 60.0
	vida = 100.0
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
		"vida": return VIDA_MAX
		"escudo": return ESCUDO_MAX
	return 0.0


func minimo_de(tipo: String) -> float:
	return VIDA_MIN if tipo == "vida" else 0.0


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
	if _sim != null:  # la simulación manda: se escribe también allí para que no lo pise
		_sim.estado[tipo] = hielo if tipo == "hielo" else v
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


func agregar_estrellas(cantidad: int) -> void:
	estrellas = maxi(0, estrellas + cantidad)
	if _sim != null:
		_sim.estado["estrellas_ganadas"] = _sim.estado.get("estrellas_ganadas", 0) + maxi(cantidad, 0)
		_sim._actualizar_nivel_base()
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


func solicitar_procesar_hielo() -> String:
	if _sim == null:
		return "sin_simulacion"
	var r: String = _sim.procesar_hielo()
	_copiar_desde_simulacion()
	return r


## Avisa a la simulación si el astronauta está cerca de la base (la Vida solo se recupera ahí).
func fijar_cerca_de_base(valor: bool) -> void:
	if _sim != null:
		_sim.estado["cerca_de_base"] = valor


## Segundos que lleva y que dura el viaje por hielo actual (0 si no hay viaje).
func progreso_viaje() -> Vector2:
	if _sim == null or not en_viaje_hielo:
		return Vector2.ZERO
	return Vector2(_sim.estado.get("viaje_t", 0.0), _sim.estado.get("viaje_duracion", 0.0))


## Foto de las variables del diccionario (la usa el puesto 5 para evaluar misiones).
func instantanea() -> Dictionary:
	return {
		"energia": energia, "hielo": hielo, "agua": agua, "oxigeno": oxigeno, "vida": vida,
		"escudo": escudo, "estrellas": estrellas, "modo_juego": modo_juego, "tiempo_juego": tiempo_juego,
		"es_dia": es_dia, "tiempo_ciclo_solar": tiempo_ciclo_solar, "alerta_nube": alerta_nube,
		"tiempo_para_nube": tiempo_para_nube, "nube_activa": nube_activa, "en_viaje_hielo": en_viaje_hielo,
		"herramienta_nivel": herramienta_nivel, "paneles_instalados": paneles_instalados,
		"procesador_instalado": procesador_instalado, "generador_instalado": generador_instalado,
		"jardin_instalado": jardin_instalado, "bateria_instalada": bateria_instalada,
	}


## Costo en energía de una estructura (0 si no hay simulación o no existe).
func costo_de(id_estructura: String) -> float:
	if _sim == null:
		return 0.0
	return float(_sim.cfg.get("costos", {}).get(id_estructura, 0.0))


## ¿Hay una simulación enchufada? (útil para pruebas y para el HUD de depuración)
func hay_simulacion() -> bool:
	return _sim != null


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
	sim.viaje_hielo_terminado.connect(func(n: int): viaje_hielo_terminado.emit(n))
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
	vida = e.get("vida", vida)
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
