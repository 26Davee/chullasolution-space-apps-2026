extends RefCounted
## Simulación de Killawasi. No depende de ninguna escena.
## Todos los números salen de res://data/balance/<modo>.json.
## Las acciones devuelven "ok" o un código de motivo ("sin_energia", "sin_cupo", ...).

signal ciclo_solar_cambiado(es_dia: bool)
signal advertencia_nube_iniciada(tiempo_restante: float)
signal nube_impacto(fuerza_dano: float, paso_a_vida: float)
signal nube_finalizada()
signal viaje_hielo_terminado(hielo_traido: int)

var cfg: Dictionary
var estado: Dictionary = {}
var generador_activo := false

var _generador_pausa_hasta := -1.0
var _aviso_emitido := false
var _dia_anterior := true


func _init(modo: String = "cadete") -> void:
	var ruta := "res://data/Balance/%s.json" % modo
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("No se encontró " + ruta)
		return
	cfg = JSON.parse_string(archivo.get_as_text())
	estado = {
		"energia": cfg.inicio.energia, "agua": cfg.inicio.agua,
		"oxigeno": cfg.inicio.oxigeno, "vida": cfg.inicio.vida,
		"escudo": cfg.inicio.escudo, "hielo": 0,
		"estrellas": 0, "estrellas_ganadas": 0, "nivel_base": 1,
		"herramienta_nivel": 1,
		"paneles": 0,            # el primer panel es gratis
		"tanques": 0,
		"modo": modo, "tiempo_juego": 0.0,
		"proxima_nube": cfg.nube.primera_s,
		# Piezas
		"procesadores": 0,
		"procesador_instalado": false,
		"generador_instalado": false,
		"reciclador_instalado": false,
		"jardin_instalado": false,
		"bateria_instalada": false,
		"mejoras": {},           # id_mejora -> true
		# Estados del contrato
		"es_dia": true,
		"alerta_nube": false,
		"nube_activa": false,
		"tiempo_para_nube": cfg.nube.primera_s,
		"en_viaje_hielo": false,
		"cerca_de_base": true,   # lo actualiza el puesto 4 según la posición
		# Internos
		"ciclos_hielo": [],      # un temporizador por procesador; -1 = libre
		"viaje_t": 0.0,
		"viaje_duracion": 0.0,
		"nube_termina": -1.0,
	}
	_dia_anterior = true


# ---------- Valores derivados (con mejoras) ----------

func tiene_mejora(id: String) -> bool:
	return estado.mejoras.has(id)

func es_de_dia() -> bool:
	return fmod(estado.tiempo_juego, cfg.dia_segundos) < cfg.dia_luz_segundos

func energia_maxima() -> float:
	if estado.bateria_instalada:
		return cfg.energia_maxima_bateria
	return cfg.energia_maxima

func tope_agua() -> float:
	return cfg.tanque.agua_base + cfg.tanque.agua_por_tanque * estado.tanques

func panel_por_s() -> float:
	if tiene_mejora("energia_produccion"):
		return cfg.mejoras.energia_produccion.panel_energia
	if tiene_mejora("energia_panel_extra"):
		return cfg.mejoras.energia_panel_extra.panel_energia
	return cfg.panel.energia_por_s_dia

func generador_energia_por_s() -> float:
	var v: float = cfg.generador.energia_por_s
	if tiene_mejora("vida_generador_eficiente"):
		v *= cfg.generador.factor_eficiente
	return v

func generador_agua_por_s() -> float:
	var v: float = cfg.generador.agua_por_s
	if tiene_mejora("vida_generador_eficiente"):
		v *= cfg.generador.factor_eficiente
	if estado.reciclador_instalado:
		v *= cfg.generador.factor_reciclador_agua
	return v

func tiempo_proceso_hielo() -> float:
	if tiene_mejora("vida_procesar_rapido"):
		return cfg.procesador.tiempo_rapido_s
	return cfg.procesador.tiempo_s

func golpe_nube() -> float:
	if tiene_mejora("escudo_resistencia"):
		return cfg.nube.golpe_resistente
	return cfg.nube.golpe

func aviso_nube_s() -> float:
	if tiene_mejora("escudo_alerta_temprana"):
		return cfg.nube.aviso_largo_s
	return cfg.nube.aviso_s

func costo_reparar_energia() -> float:
	if tiene_mejora("escudo_reparar_barato"):
		return cfg.escudo.reparar_energia_barato
	return cfg.escudo.reparar_energia

func tiempo_reparar_s() -> float:
	if tiene_mejora("escudo_reparar_barato"):
		return cfg.escudo.reparar_s_barato
	return cfg.escudo.reparar_s

func vida_recupera_por_s() -> float:
	var v: float = cfg.vida.recupera_por_s
	if estado.jardin_instalado:
		v += cfg.jardin.vida_extra_por_s
	return v

func cupos() -> Dictionary:
	return cfg.niveles[estado.nivel_base - 1].cupos

func herramienta_actual() -> Dictionary:
	return cfg.herramientas[estado.herramienta_nivel - 1]

func costo_viaje_vida() -> float:
	var c: float = herramienta_actual().vida
	if estado.nube_activa:
		c *= cfg.viaje.multiplicador_nube
	return c


# ---------- Simulación ----------

func tick(dt: float) -> void:
	estado.tiempo_juego += dt
	_actualizar_nivel_base()

	# Ciclo día/noche
	estado.es_dia = es_de_dia()
	if estado.es_dia != _dia_anterior:
		_dia_anterior = estado.es_dia
		ciclo_solar_cambiado.emit(estado.es_dia)

	# Energía
	var e: float = -cfg.base.consumo_energia_por_s
	if estado.es_dia:
		e += panel_por_s() * estado.paneles

	# Generador: se enciende con O2 < 90 y se apaga en 100
	if estado.oxigeno < cfg.generador.enciende_bajo:
		generador_activo = true
	elif estado.oxigeno >= cfg.generador.apaga_en:
		generador_activo = false
	var pausado: bool = estado.tiempo_juego < _generador_pausa_hasta
	var puede: bool = estado.generador_instalado and generador_activo and not pausado \
		and estado.energia > 0 and estado.agua > 0
	if puede:
		e -= generador_energia_por_s()
		estado.agua -= generador_agua_por_s() * dt
		estado.oxigeno += cfg.generador.oxigeno_por_s * dt

	# Procesadores de hielo
	e -= _tick_procesadores(dt)

	# Jardín gasta agua
	if estado.jardin_instalado and estado.agua > 0:
		estado.agua -= cfg.jardin.agua_por_s * dt

	estado.oxigeno -= cfg.base.oxigeno_tripulacion_por_s * dt
	estado.energia += e * dt

	_tick_vida(dt)
	_tick_viaje(dt)
	_tick_nube()
	_aplicar_topes()


## Devuelve el consumo de energía por s de los procesadores que trabajan.
func _tick_procesadores(dt: float) -> float:
	if estado.procesadores == 0:
		return 0.0
	var ciclos: Array = estado.ciclos_hielo
	var por_hielo: float = cfg.procesador.agua_por_hielo
	var activos := 0
	for t in ciclos:
		if t >= 0.0:
			activos += 1
	var consumo := 0.0
	for i in ciclos.size():
		if ciclos[i] < 0.0:
			# Libre: arranca si hay hielo, energía y el agua cabe (cuenta lo que ya viene en camino)
			if estado.hielo >= 1 and estado.energia > 0 \
					and estado.agua + por_hielo * (activos + 1) <= tope_agua():
				estado.hielo -= 1
				ciclos[i] = 0.0
				activos += 1
		elif estado.energia > 0:
			ciclos[i] += dt
			consumo += cfg.procesador.energia_por_s
			if ciclos[i] >= tiempo_proceso_hielo():
				estado.agua += por_hielo
				ciclos[i] = -1.0
				activos -= 1
	return consumo


func _tick_vida(dt: float) -> void:
	# Sin oxígeno la Vida baja
	if estado.oxigeno <= 0.0:
		estado.vida -= cfg.vida.sin_oxigeno_por_s * dt
	# Descansar cerca de la base (no en viaje)
	elif estado.cerca_de_base and not estado.en_viaje_hielo \
			and estado.oxigeno >= cfg.vida.recupera_oxigeno_min:
		estado.vida += vida_recupera_por_s() * dt


func _tick_viaje(dt: float) -> void:
	if not estado.en_viaje_hielo:
		return
	estado.viaje_t += dt
	if estado.viaje_t >= estado.viaje_duracion:
		estado.en_viaje_hielo = false
		var traido: int = herramienta_actual().hielo
		var cabe: int = int(cfg.hielo_maximo) - int(estado.hielo)
		estado.hielo += mini(traido, cabe)
		viaje_hielo_terminado.emit(traido)


func _tick_nube() -> void:
	estado.tiempo_para_nube = maxf(estado.proxima_nube - estado.tiempo_juego, 0.0)
	# Aviso con cuenta atrás
	if not _aviso_emitido and estado.tiempo_para_nube <= aviso_nube_s():
		_aviso_emitido = true
		estado.alerta_nube = true
		advertencia_nube_iniciada.emit(estado.tiempo_para_nube)
	# Golpe
	if estado.tiempo_juego >= estado.proxima_nube:
		golpe_de_nube()
		estado.proxima_nube += cfg.nube.cada_s
		_aviso_emitido = false
	# Fin de la nube
	if estado.nube_activa and estado.tiempo_juego >= estado.nube_termina:
		estado.nube_activa = false
		nube_finalizada.emit()


func _aplicar_topes() -> void:
	estado.energia = clampf(estado.energia, 0.0, energia_maxima())
	estado.agua = clampf(estado.agua, 0.0, tope_agua())
	estado.oxigeno = clampf(estado.oxigeno, 0.0, 100.0)
	estado.escudo = clampf(estado.escudo, 0.0, 100.0)
	estado.hielo = clampi(estado.hielo, 0, int(cfg.hielo_maximo))
	estado.vida = clampf(estado.vida, cfg.vida.minima, cfg.vida.maxima)


func _actualizar_nivel_base() -> void:
	var nivel := 1
	for i in cfg.niveles.size():
		if estado.estrellas_ganadas >= cfg.niveles[i].estrellas:
			nivel = i + 1
	estado.nivel_base = nivel


func golpe_de_nube() -> void:
	var golpe := golpe_nube()
	var sobra := maxf(golpe - estado.escudo, 0.0)
	estado.escudo = maxf(estado.escudo - golpe, 0.0)
	var a_vida: float = sobra * cfg.nube.sobrante_a_vida
	estado.vida = maxf(estado.vida - a_vida, cfg.vida.minima)
	estado.alerta_nube = false
	estado.nube_activa = true
	estado.nube_termina = estado.tiempo_juego + cfg.nube.duracion_s
	# Escudo en cero: el generador se pausa
	if estado.escudo <= 0.0:
		_generador_pausa_hasta = estado.tiempo_juego + cfg.nube.pausa_generador_s
	nube_impacto.emit(golpe, a_vida)


# ---------- Acciones del jugador ----------

## Construye una pieza. id: panel_solar, procesador_hielo, generador_oxigeno,
## tanque_agua, reciclador_agua o jardin.
func construir(id: String) -> String:
	var c := cupos()
	match id:
		"panel_solar":
			if estado.paneles >= c.paneles:
				return "sin_cupo"
		"procesador_hielo":
			if estado.procesadores >= c.procesadores:
				return "sin_cupo"
		"generador_oxigeno":
			if estado.generador_instalado:
				return "sin_cupo"
		"tanque_agua":
			if estado.tanques >= c.tanques:
				return "sin_cupo"
		"reciclador_agua":
			if estado.reciclador_instalado or c.recicladores < 1:
				return "sin_cupo"
		"jardin":
			if estado.jardin_instalado or not tiene_mejora("vida_jardin"):
				return "bloqueado"
		_:
			return "id_desconocido"

	var costo: float = cfg.costos[id]
	if id == "panel_solar" and estado.paneles == 0:
		costo = 0.0  # el primero es gratis
	if estado.energia < costo:
		return "sin_energia"
	estado.energia -= costo

	match id:
		"panel_solar":
			estado.paneles += 1
		"procesador_hielo":
			estado.procesadores += 1
			estado.procesador_instalado = true
			estado.ciclos_hielo.append(-1.0)
		"generador_oxigeno":
			estado.generador_instalado = true
		"tanque_agua":
			estado.tanques += 1
		"reciclador_agua":
			estado.reciclador_instalado = true
		"jardin":
			estado.jardin_instalado = true
	return "ok"

func instalar_panel() -> String:
	return construir("panel_solar")

func instalar_procesador() -> String:
	return construir("procesador_hielo")

func instalar_generador() -> String:
	return construir("generador_oxigeno")


func reparar_escudo() -> String:
	if estado.escudo >= 100.0:
		return "escudo_lleno"
	var costo := costo_reparar_energia()
	if estado.energia < costo:
		return "sin_energia"
	estado.energia -= costo
	estado.escudo = minf(estado.escudo + cfg.escudo.reparar_valor, 100.0)
	return "ok"


## Sale a buscar hielo. Quita la Vida al salir; el hielo llega al terminar el viaje.
func iniciar_viaje_hielo() -> String:
	if estado.en_viaje_hielo:
		return "en_viaje"
	var costo := costo_viaje_vida()
	if estado.vida < costo + cfg.viaje.margen_bloqueo:
		return "descansa_primero"
	estado.vida = maxf(estado.vida - costo, cfg.vida.minima)
	estado.en_viaje_hielo = true
	estado.viaje_t = 0.0
	estado.viaje_duracion = cfg.viaje.caminar_s + herramienta_actual().excavar_s
	return "ok"


## Inicia un proceso de hielo a mano (el tick también los inicia solo).
func procesar_hielo() -> String:
	var ciclos: Array = estado.ciclos_hielo
	var por_hielo: float = cfg.procesador.agua_por_hielo
	var activos := 0
	for t in ciclos:
		if t >= 0.0:
			activos += 1
	for i in ciclos.size():
		if ciclos[i] < 0.0:
			if estado.hielo < 1:
				return "sin_hielo"
			if estado.agua + por_hielo * (activos + 1) > tope_agua():
				return "agua_llena"
			estado.hielo -= 1
			ciclos[i] = 0.0
			return "ok"
	return "sin_procesador_libre"


## Lo llama el puesto 5 al comprar una mejora del árbol (ids del contrato).
func aplicar_mejora(id: String) -> void:
	estado.mejoras[id] = true
	match id:
		"energia_bateria":
			estado.bateria_instalada = true
		"herramientas_pico":
			estado.herramienta_nivel = maxi(estado.herramienta_nivel, 2)
		"herramientas_taladro_manual":
			estado.herramienta_nivel = maxi(estado.herramienta_nivel, 3)
		"herramientas_taladro_mochila":
			estado.herramienta_nivel = maxi(estado.herramienta_nivel, 4)
