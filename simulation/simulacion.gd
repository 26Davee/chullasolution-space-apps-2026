class_name Simulacion
extends RefCounted
## Simulación de Killawasi. No depende de ninguna escena.
## Todos los números salen de res://data/Balance/<modo>.json
## y el calendario de nubes de res://data/nasa/tormentas_juego.json.

signal recurso_actualizado(tipo: String, valor: float, maximo: float)
signal ciclo_solar_cambiado(es_dia: bool)
signal noche_iniciada()
signal advertencia_nube_iniciada(tiempo_restante: float)
signal nube_impacto(fuerza_dano: float, paso_a_vida: float)
signal nube_finalizada()
signal viaje_hielo_terminado(hielo_traido: int)
signal hielo_entregado(cantidad: int)
signal estructura_construida(id: String)
signal escudo_reparado()
signal nivel_subio(nivel: int)

var cfg: Dictionary
var estado: Dictionary = {}
var generador_activo := false
var calendario: Array = []

var _idx_nube := 0
var _generador_pausa_hasta := -1.0
var _aviso_emitido := false
var _dia_anterior := true
var _reparando := false
var _reparar_termina := 0.0
var _acum_emision := 0.0


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
		"paneles": 0,
		"tanques": 0,
		"modo": modo, "tiempo_juego": 0.0,
		"proxima_nube": cfg.nube.primera_s,
		"procesadores": 0,
		"procesador_instalado": false,
		"generador_instalado": false,
		"reciclador_instalado": false,
		"jardin_instalado": false,
		"bateria_instalada": false,
		"mejoras": {},
		"es_dia": true,
		"alerta_nube": false,
		"nube_activa": false,
		"tiempo_para_nube": cfg.nube.primera_s,
		"en_viaje_hielo": false,
		"cerca_de_base": true,
		"ciclos_hielo": [],
		"viaje_t": 0.0,
		"viaje_duracion": 0.0,
		"nube_termina": -1.0,
	}
	_dia_anterior = true
	cargar_calendario()


## Lee las tormentas reales (CRaTER) y fija la primera nube.
func cargar_calendario() -> void:
	var f := FileAccess.open("res://data/nasa/tormentas_juego.json", FileAccess.READ)
	if f == null:
		push_warning("Sin tormentas_juego.json: uso nubes fijas")
		return
	var datos = JSON.parse_string(f.get_as_text())
	if datos == null or not datos.has("eventos") or datos.eventos.is_empty():
		push_warning("tormentas_juego.json vacío: uso nubes fijas")
		return
	calendario = datos.eventos
	estado.proxima_nube = float(calendario[0].t_juego_s)
	estado.tiempo_para_nube = estado.proxima_nube


func _evento_actual() -> Dictionary:
	if calendario.is_empty():
		return {"intensidad": 1.0, "duracion_s": cfg.nube.duracion_s}
	return calendario[_idx_nube % calendario.size()]


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

func max_paneles() -> int:
	return cfg.panel.maximo + (1 if tiene_mejora("energia_panel_extra") else 0)

func panel_por_s() -> float:
	if tiene_mejora("energia_produccion"):
		return cfg.mejoras.energia_produccion.panel_energia
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

func golpe_base() -> float:
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
	if tiene_mejora("escudo_alerta_temprana"):
		return cfg.escudo.reparar_s_radar
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
	if estado.nube_activa or estado.alerta_nube:
		c *= cfg.viaje.multiplicador_nube
	return c

func generador_pausado() -> bool:
	return estado.tiempo_juego < _generador_pausa_hasta


# ---------- Simulación ----------

func tick(dt: float) -> void:
	estado.tiempo_juego += dt
	_actualizar_nivel_base()

	estado.es_dia = es_de_dia()
	if estado.es_dia != _dia_anterior:
		_dia_anterior = estado.es_dia
		ciclo_solar_cambiado.emit(estado.es_dia)
		if not estado.es_dia:
			noche_iniciada.emit()

	var e: float = -cfg.base.consumo_energia_por_s
	if estado.es_dia:
		e += panel_por_s() * estado.paneles

	if estado.oxigeno < cfg.generador.enciende_bajo:
		generador_activo = true
	elif estado.oxigeno >= cfg.generador.apaga_en:
		generador_activo = false
	var puede: bool = estado.generador_instalado and generador_activo \
		and not generador_pausado() and estado.energia > 0 and estado.agua > 0
	if puede:
		e -= generador_energia_por_s()
		estado.agua -= generador_agua_por_s() * dt
		estado.oxigeno += cfg.generador.oxigeno_por_s * dt

	e -= _tick_procesadores(dt)

	if estado.jardin_instalado and estado.agua > 0:
		estado.agua -= cfg.jardin.agua_por_s * dt

	estado.oxigeno -= cfg.base.oxigeno_tripulacion_por_s * dt
	estado.energia += e * dt

	_tick_vida(dt)
	_tick_viaje(dt)
	_tick_nube()
	_tick_reparacion()
	_aplicar_topes()

	_acum_emision += dt
	if _acum_emision >= 0.25:
		_acum_emision = 0.0
		_emitir_recursos()


func _emitir_recursos() -> void:
	recurso_actualizado.emit("energia", estado.energia, energia_maxima())
	recurso_actualizado.emit("agua", estado.agua, tope_agua())
	recurso_actualizado.emit("oxigeno", estado.oxigeno, 100.0)
	recurso_actualizado.emit("vida", estado.vida, cfg.vida.maxima)
	recurso_actualizado.emit("escudo", estado.escudo, 100.0)
	recurso_actualizado.emit("hielo", float(estado.hielo), float(cfg.hielo_maximo))


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
	if estado.oxigeno <= 0.0:
		estado.vida -= cfg.vida.sin_oxigeno_por_s * dt
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
		var entregado: int = mini(traido, cabe)
		estado.hielo += entregado
		viaje_hielo_terminado.emit(traido)
		hielo_entregado.emit(entregado)


func _tick_nube() -> void:
	estado.tiempo_para_nube = maxf(estado.proxima_nube - estado.tiempo_juego, 0.0)
	if not _aviso_emitido and estado.tiempo_para_nube <= aviso_nube_s():
		_aviso_emitido = true
		estado.alerta_nube = true
		advertencia_nube_iniciada.emit(estado.tiempo_para_nube)
	if estado.tiempo_juego >= estado.proxima_nube:
		golpe_de_nube()
		_idx_nube += 1
		if _idx_nube < calendario.size():
			estado.proxima_nube = float(calendario[_idx_nube].t_juego_s)
		else:
			estado.proxima_nube += cfg.nube.cada_s
		_aviso_emitido = false
	if estado.nube_activa and estado.tiempo_juego >= estado.nube_termina:
		estado.nube_activa = false
		nube_finalizada.emit()


func _tick_reparacion() -> void:
	if _reparando and estado.tiempo_juego >= _reparar_termina:
		_reparando = false
		estado.escudo = minf(estado.escudo + cfg.escudo.reparar_valor, 100.0)
		escudo_reparado.emit()


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
	if nivel > estado.nivel_base:
		estado.nivel_base = nivel
		nivel_subio.emit(nivel)
	estado.nivel_base = nivel


func golpe_de_nube() -> void:
	var ev := _evento_actual()
	var golpe := roundf(golpe_base() * float(ev.intensidad))
	var sobra := maxf(golpe - estado.escudo, 0.0)
	estado.escudo = maxf(estado.escudo - golpe, 0.0)
	var a_vida: float = sobra * cfg.nube.sobrante_a_vida
	estado.vida = maxf(estado.vida - a_vida, cfg.vida.minima)
	estado.alerta_nube = false
	estado.nube_activa = true
	estado.nube_termina = estado.tiempo_juego + float(ev.duracion_s)
	if estado.escudo <= 0.0:
		_generador_pausa_hasta = estado.tiempo_juego + cfg.nube.pausa_generador_s
	nube_impacto.emit(golpe, a_vida)


# ---------- Acciones del jugador ----------

func construir(id: String) -> String:
	var c := cupos()
	match id:
		"panel_solar":
			if estado.paneles >= max_paneles():
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
		costo = 0.0
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
	estructura_construida.emit(id)
	return "ok"

func instalar_panel() -> String:
	return construir("panel_solar")

func instalar_procesador() -> String:
	return construir("procesador_hielo")

func instalar_generador() -> String:
	return construir("generador_oxigeno")


func reparar_escudo() -> String:
	if _reparando:
		return "reparando"
	if estado.escudo >= 100.0:
		return "escudo_lleno"
	var costo := costo_reparar_energia()
	if estado.energia < costo:
		return "sin_energia"
	estado.energia -= costo
	_reparando = true
	_reparar_termina = estado.tiempo_juego + tiempo_reparar_s()
	return "ok"


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
