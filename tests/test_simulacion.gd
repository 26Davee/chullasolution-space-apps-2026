extends SceneTree
## Prueba completa de la simulación, en modo Cadete e Ingeniero.
## Cada comprobación imprime OK o FALLO. Al final dice cuántas fallaron.

const SimulacionScript = preload("res://simulation/simulacion.gd")

var _total := 0
var _fallos := 0


func _initialize() -> void:
	for modo in ["cadete", "ingeniero"]:
		_probar_modo(modo)
	_comparar_modos()

	print("\n======================================")
	print("RESULTADO: %d comprobaciones, %d fallos" % [_total, _fallos])
	print("======================================")
	quit(1 if _fallos > 0 else 0)


func _probar_modo(modo: String) -> void:
	print("\n######################################")
	print("# MODO: ", modo.to_upper())
	print("######################################")
	var sim = _nuevo(modo)
	if sim.cfg.is_empty():
		_titulo("CARGA")
		_chequear(false, "no se pudo cargar el JSON de " + modo)
		return

	_t_carga(modo)
	_t_consumo(modo)
	_t_ciclo(modo)
	_t_costos(modo)
	_t_niveles(modo)
	_t_generador(modo)
	_t_procesador(modo)
	_t_viaje(modo)
	_t_nube(modo)
	_t_escudo(modo)
	_t_vida(modo)
	_t_topes_y_mejoras(modo)
	_t_partida_larga(modo)


# ---------- Ayudas ----------

func _nuevo(modo: String, aislar := true):
	var sim = SimulacionScript.new(modo)
	if aislar and not sim.cfg.is_empty():
		sim.estado.proxima_nube = 1.0e9  # que no llegue ninguna nube
	return sim


func _avanzar(sim, segundos: float, dt := 0.1) -> void:
	var pasos := int(round(segundos / dt))
	for i in pasos:
		sim.tick(dt)


func _hasta(sim, t: float, dt := 0.1) -> void:
	while sim.estado.tiempo_juego < t:
		sim.tick(dt)


func _titulo(texto: String) -> void:
	print("\n[ %s ]" % texto)


func _chequear(cond: bool, nombre: String) -> void:
	_total += 1
	if cond:
		print("  OK     ", nombre)
	else:
		_fallos += 1
		print("  FALLO  ", nombre)


func _igual(real: float, esperado: float, nombre: String, tol := 0.05) -> void:
	_total += 1
	if absf(real - esperado) <= tol:
		print("  OK     %s (%.2f)" % [nombre, real])
	else:
		_fallos += 1
		print("  FALLO  %s: salió %.3f y se esperaba %.3f" % [nombre, real, esperado])


func _llenar_energia(sim) -> void:
	sim.estado.energia = 100.0


# ---------- 1. Carga ----------

func _t_carga(modo: String) -> void:
	_titulo("1. CARGA Y VALORES INICIALES")
	var sim = _nuevo(modo)
	_chequear(sim.estado.modo == modo, "el modo guardado es " + modo)
	_igual(sim.estado.energia, 60.0, "energía inicial 60")
	_igual(sim.estado.agua, 20.0, "agua inicial 20")
	_igual(sim.estado.oxigeno, 60.0, "oxígeno inicial 60")
	_igual(sim.estado.vida, 100.0, "Vida inicial 100")
	_igual(sim.estado.escudo, 100.0, "escudo inicial 100")
	_chequear(sim.estado.hielo == 0, "hielo inicial 0")
	_chequear(sim.estado.paneles == 0, "paneles instalados al inicio: 0")
	_chequear(sim.estado.nivel_base == 1, "nivel de base 1")
	_chequear(sim.estado.herramienta_nivel == 1, "empieza con la pala")


# ---------- 2. Consumo ----------

func _t_consumo(modo: String) -> void:
	_titulo("2. CONSUMO BASE (10 s sin piezas)")
	var sim = _nuevo(modo)
	_avanzar(sim, 10.0)
	_igual(sim.estado.energia, 59.5, "energía baja 0,05 por s")
	_igual(sim.estado.oxigeno, 58.5, "oxígeno baja 0,15 por s")
	_igual(sim.estado.agua, 20.0, "el agua no cambia sin generador")
	_igual(sim.estado.vida, 100.0, "la Vida sigue en 100")


# ---------- 3. Día y noche ----------

func _t_ciclo(modo: String) -> void:
	_titulo("3. CICLO DE DÍA Y NOCHE")
	var sim = _nuevo(modo)
	var cambios := {"n": 0}
	sim.ciclo_solar_cambiado.connect(func(_d): cambios.n += 1)
	_chequear(sim.estado.es_dia, "empieza de día")
	_hasta(sim, 299.0)
	_chequear(sim.estado.es_dia, "segundo 299: día")
	_hasta(sim, 301.0)
	_chequear(not sim.estado.es_dia, "segundo 301: noche")
	_hasta(sim, 479.0)
	_chequear(not sim.estado.es_dia, "segundo 479: noche")
	_hasta(sim, 481.0)
	_chequear(sim.estado.es_dia, "segundo 481: día otra vez")
	_chequear(cambios.n == 2, "la señal de ciclo solar salió 2 veces")

	var s2 = _nuevo(modo)
	_llenar_energia(s2)
	s2.estado.energia = 60.0
	_chequear(s2.construir("panel_solar") == "ok", "instalar panel")
	_avanzar(s2, 10.0)
	_igual(s2.estado.energia, 65.5, "un panel de día: +0,6 por s menos la base")

	var s3 = _nuevo(modo)
	s3.construir("panel_solar")
	s3.estado.tiempo_juego = 310.0
	s3.estado.energia = 60.0
	_avanzar(s3, 10.0)
	_igual(s3.estado.energia, 59.5, "de noche el panel no produce")


# ---------- 4. Costos y cupos ----------

func _t_costos(modo: String) -> void:
	_titulo("4. COSTOS, CUPOS Y PIEZAS")
	var sim = _nuevo(modo)
	var c = sim.cfg.costos

	_llenar_energia(sim)
	_chequear(sim.construir("panel_solar") == "ok", "primer panel")
	_igual(sim.estado.energia, 100.0, "el primer panel es gratis")

	_llenar_energia(sim)
	_chequear(sim.construir("panel_solar") == "ok", "segundo panel")
	_igual(sim.estado.energia, 100.0 - c.panel_solar, "el segundo panel cuesta su precio")

	_llenar_energia(sim)
	_chequear(sim.construir("panel_solar") == "sin_cupo", "tercer panel: sin cupo en nivel 1")
	_igual(sim.estado.energia, 100.0, "un intento sin cupo no cobra")

	_llenar_energia(sim)
	_chequear(sim.construir("procesador_hielo") == "ok", "procesador")
	_igual(sim.estado.energia, 100.0 - c.procesador_hielo, "costo del procesador")
	_chequear(sim.estado.procesador_instalado, "procesador marcado como instalado")
	_llenar_energia(sim)
	_chequear(sim.construir("procesador_hielo") == "sin_cupo", "segundo procesador: sin cupo en nivel 1")

	_llenar_energia(sim)
	_chequear(sim.construir("generador_oxigeno") == "ok", "generador")
	_igual(sim.estado.energia, 100.0 - c.generador_oxigeno, "costo del generador")
	_llenar_energia(sim)
	_chequear(sim.construir("generador_oxigeno") == "sin_cupo", "segundo generador: no se puede")

	_chequear(sim.construir("tanque_agua") == "sin_cupo", "tanque: no hasta el nivel 2")
	_chequear(sim.construir("reciclador_agua") == "sin_cupo", "reciclador: no hasta el nivel 4")
	_chequear(sim.construir("jardin") == "bloqueado", "jardín: bloqueado sin la mejora")
	_chequear(sim.construir("nave") == "id_desconocido", "id desconocido")

	var s2 = _nuevo(modo)
	s2.estado.energia = 5.0
	_chequear(s2.construir("procesador_hielo") == "sin_energia", "sin energía suficiente")
	_chequear(s2.estado.procesadores == 0, "si no alcanza la energía no se construye")
	_igual(s2.estado.energia, 5.0, "y tampoco se cobra")


# ---------- 5. Niveles de la base ----------

func _t_niveles(modo: String) -> void:
	_titulo("5. NIVELES DE LA BASE")
	var tabla := [[0, 1], [2, 1], [3, 2], [5, 2], [6, 3], [9, 3], [10, 4], [14, 5]]
	for fila in tabla:
		var sim = _nuevo(modo)
		sim.estado.estrellas_ganadas = fila[0]
		sim.tick(0.1)
		_chequear(sim.estado.nivel_base == fila[1],
			"%d estrellas ganadas -> nivel %d (salió %d)" % [fila[0], fila[1], sim.estado.nivel_base])

	var s2 = _nuevo(modo)
	s2.estado.estrellas_ganadas = 3
	s2.tick(0.1)
	_llenar_energia(s2)
	_chequear(s2.construir("tanque_agua") == "ok", "nivel 2: se puede construir el tanque")
	_igual(s2.tope_agua(), 110.0, "con un tanque el agua máxima es 110")

	var s3 = _nuevo(modo)
	s3.estado.estrellas_ganadas = 10
	s3.tick(0.1)
	_llenar_energia(s3)
	_chequear(s3.construir("reciclador_agua") == "ok", "nivel 4: se puede construir el reciclador")
	_chequear(s3.construir("reciclador_agua") == "sin_cupo", "solo 1 reciclador")


# ---------- 6. Generador ----------

func _t_generador(modo: String) -> void:
	_titulo("6. GENERADOR DE OXÍGENO")
	var sim = _nuevo(modo)
	_llenar_energia(sim)
	sim.construir("generador_oxigeno")
	_llenar_energia(sim)
	sim.estado.oxigeno = 85.0
	var agua0: float = sim.estado.agua
	_avanzar(sim, 1.0)
	_chequear(sim.generador_activo, "se enciende con oxígeno por debajo de 90")
	_igual(sim.estado.oxigeno, 85.3, "oxígeno: +0,45 menos 0,15 de la tripulación")
	_igual(sim.estado.agua, agua0 - 0.15, "gasta 0,15 de agua por s")
	_igual(sim.estado.energia, 99.65, "gasta 0,3 de energía y 0,05 de la base")

	sim.estado.oxigeno = 95.0
	sim.tick(0.1)
	_chequear(sim.generador_activo, "entre 90 y 100 sigue encendido")
	sim.estado.oxigeno = 100.0
	sim.tick(0.1)
	_chequear(not sim.generador_activo, "se apaga al llegar a 100")

	var s2 = _nuevo(modo)
	_llenar_energia(s2)
	s2.construir("generador_oxigeno")
	s2.estado.agua = 0.0
	s2.estado.oxigeno = 80.0
	_avanzar(s2, 1.0)
	_igual(s2.estado.oxigeno, 79.85, "sin agua el generador no produce")

	var s3 = _nuevo(modo)
	s3.estado.oxigeno = 80.0
	_avanzar(s3, 1.0)
	_igual(s3.estado.oxigeno, 79.85, "sin generador instalado no produce")


# ---------- 7. Procesador de hielo ----------

func _t_procesador(modo: String) -> void:
	_titulo("7. PROCESADOR DE HIELO")
	var sim = _nuevo(modo)
	_llenar_energia(sim)
	sim.construir("procesador_hielo")
	_llenar_energia(sim)
	sim.estado.hielo = 1
	_avanzar(sim, 2.5)
	_igual(sim.estado.agua, 20.0, "a los 2,5 s todavía no hay agua nueva")
	_avanzar(sim, 3.1)
	_igual(sim.estado.agua, 30.0, "1 hielo da +10 agua en 5 s")
	_chequear(sim.estado.hielo == 0, "el hielo se gastó")

	var s2 = _nuevo(modo)
	_llenar_energia(s2)
	s2.construir("procesador_hielo")
	_llenar_energia(s2)
	s2.estado.agua = 55.0
	s2.estado.hielo = 1
	_avanzar(s2, 3.0)
	_chequear(s2.estado.hielo == 1, "espera si el agua no cabe: no gasta el hielo")
	_igual(s2.estado.agua, 55.0, "el agua no cambia")

	var s3 = _nuevo(modo)
	s3.aplicar_mejora("vida_procesar_rapido")
	_llenar_energia(s3)
	s3.construir("procesador_hielo")
	_llenar_energia(s3)
	s3.estado.hielo = 1
	_avanzar(s3, 3.5)
	_igual(s3.estado.agua, 30.0, "con Procesar más rápido tarda 3 s")

	var s4 = _nuevo(modo)
	_llenar_energia(s4)
	s4.construir("procesador_hielo")
	s4.estado.energia = 0.0
	s4.estado.hielo = 1
	_avanzar(s4, 6.0)
	_chequear(s4.estado.hielo == 1, "sin energía el procesador no arranca")


# ---------- 8. Viaje por hielo ----------

func _t_viaje(modo: String) -> void:
	_titulo("8. VIAJE POR HIELO")
	var sim = _nuevo(modo)
	var pala = sim.cfg.herramientas[0]
	var costo: float = pala.vida
	_chequear(sim.iniciar_viaje_hielo() == "ok", "salir con la pala")
	_igual(sim.estado.vida, 100.0 - costo, "la Vida baja al salir: -%d" % int(costo))
	_chequear(sim.iniciar_viaje_hielo() == "en_viaje", "no se puede salir dos veces")
	_avanzar(sim, 30.0)
	_igual(sim.estado.vida, 100.0 - costo, "en viaje la Vida no se recupera")
	_chequear(sim.estado.en_viaje_hielo, "sigue de viaje a los 30 s")
	_avanzar(sim, 31.0)
	_chequear(not sim.estado.en_viaje_hielo, "el viaje termina a los 60 s")
	_chequear(sim.estado.hielo == int(pala.hielo), "la pala trae %d de hielo" % int(pala.hielo))
	var v1: float = sim.estado.vida
	_avanzar(sim, 10.0)
	_igual(sim.estado.vida, v1 + 2.0, "de vuelta en la base la Vida sube 0,2 por s")

	var s2 = _nuevo(modo)
	s2.estado.vida = costo + 9.9
	_chequear(s2.iniciar_viaje_hielo() == "descansa_primero", "bloqueo: Vida menor que costo + 10")
	_igual(s2.estado.vida, costo + 9.9, "el bloqueo no quita Vida")
	s2.estado.vida = costo + 10.0
	_chequear(s2.iniciar_viaje_hielo() == "ok", "con Vida = costo + 10 sí se puede salir")

	var s3 = _nuevo(modo)
	s3.estado.nube_activa = true
	s3.iniciar_viaje_hielo()
	_igual(s3.estado.vida, 100.0 - costo * 1.5, "durante la nube la Vida perdida es ×1,5")

	var s4 = _nuevo(modo)
	s4.aplicar_mejora("herramientas_pico")
	_chequear(s4.estado.herramienta_nivel == 2, "el pico sube la herramienta a nivel 2")
	s4.iniciar_viaje_hielo()
	_avanzar(s4, 55.0)
	_chequear(s4.estado.hielo == 4, "el pico trae 4 de hielo en 54 s")
	s4.aplicar_mejora("herramientas_taladro_mochila")
	s4.aplicar_mejora("herramientas_pico")
	_chequear(s4.estado.herramienta_nivel == 4, "una herramienta peor no baja el nivel")


# ---------- 9. La nube ----------

func _t_nube(modo: String) -> void:
	_titulo("9. NUBE DE RADIACIÓN (calendario)")
	var sim = _nuevo(modo, false)
	var cont := {"aviso": 0, "impacto": 0, "fin": 0}
	sim.advertencia_nube_iniciada.connect(func(_t): cont.aviso += 1)
	sim.nube_impacto.connect(func(_a, _b): cont.impacto += 1)
	sim.nube_finalizada.connect(func(): cont.fin += 1)
	var primera: float = sim.cfg.nube.primera_s
	var cada: float = sim.cfg.nube.cada_s
	var aviso: float = sim.cfg.nube.aviso_s
	var dur: float = sim.cfg.nube.duracion_s
	var golpe: float = sim.cfg.nube.golpe

	_hasta(sim, primera - aviso - 1.0)
	_chequear(not sim.estado.alerta_nube, "sin aviso antes de tiempo")
	_hasta(sim, primera - aviso + 1.0)
	_chequear(sim.estado.alerta_nube, "el aviso empieza %d s antes" % int(aviso))
	_chequear(cont.aviso == 1, "el aviso sale una sola vez")
	_hasta(sim, primera + 0.5)
	_chequear(cont.impacto == 1, "la primera nube llega a los %d s" % int(primera))
	_igual(sim.estado.escudo, 100.0 - golpe, "el golpe baja el escudo")
	_chequear(sim.estado.nube_activa, "la nube queda activa")
	_chequear(not sim.estado.alerta_nube, "el aviso se apaga con el golpe")
	_hasta(sim, primera + dur + 0.5)
	_chequear(not sim.estado.nube_activa, "la nube termina a los %d s" % int(dur))
	_chequear(cont.fin == 1, "la señal de fin sale una vez")
	_hasta(sim, primera + cada + 0.5)
	_chequear(cont.impacto == 2, "la segunda nube llega %d s después" % int(cada))
	_igual(sim.estado.escudo, maxf(100.0 - 2.0 * golpe, 0.0), "el escudo baja otra vez")
	_chequear(cont.aviso == 2, "segundo aviso")

	var s2 = _nuevo(modo)
	s2.aplicar_mejora("escudo_alerta_temprana")
	_igual(s2.aviso_nube_s(), 40.0, "Alerta temprana: aviso de 40 s")


# ---------- 10. Escudo ----------

func _t_escudo(modo: String) -> void:
	_titulo("10. ESCUDO: GOLPES, SOBRANTE Y REPARACIÓN")
	var sim = _nuevo(modo)
	var golpe: float = sim.cfg.nube.golpe
	var factor: float = sim.cfg.nube.sobrante_a_vida
	var esc := 100.0
	var vida := 100.0
	for n in range(1, 5):
		var sobra := maxf(golpe - esc, 0.0)
		esc = maxf(esc - golpe, 0.0)
		vida = maxf(vida - sobra * factor, 10.0)
		sim.golpe_de_nube()
		_igual(sim.estado.escudo, esc, "golpe %d: escudo" % n)
		_igual(sim.estado.vida, vida, "golpe %d: Vida (lo que sobra ×%.2f)" % [n, factor])
	if modo == "cadete":
		_igual(sim.estado.escudo, 0.0, "Cadete: tras 4 golpes el escudo está en 0")
		_igual(sim.estado.vida, 90.0, "Cadete: el cuarto golpe quita 10 de Vida")

	var s2 = _nuevo(modo)
	s2.estado.escudo = 10.0
	_llenar_energia(s2)
	var valor: float = s2.cfg.escudo.reparar_valor
	var costo: float = s2.cfg.escudo.reparar_energia
	_chequear(s2.reparar_escudo() == "ok", "reparar")
	_igual(s2.estado.escudo, minf(10.0 + valor, 100.0), "reparar devuelve +%d" % int(valor))
	_igual(s2.estado.energia, 100.0 - costo, "reparar cuesta %d de energía" % int(costo))
	s2.estado.escudo = 100.0
	_chequear(s2.reparar_escudo() == "escudo_lleno", "con el escudo lleno no se repara")
	s2.estado.escudo = 10.0
	s2.estado.energia = 0.0
	_chequear(s2.reparar_escudo() == "sin_energia", "reparar sin energía")

	var s3 = _nuevo(modo)
	s3.aplicar_mejora("escudo_reparar_barato")
	s3.estado.escudo = 10.0
	_llenar_energia(s3)
	s3.reparar_escudo()
	_igual(s3.estado.energia, 100.0 - s3.cfg.escudo.reparar_energia_barato, "Reparar más barato")

	var s4 = _nuevo(modo)
	s4.aplicar_mejora("escudo_resistencia")
	s4.golpe_de_nube()
	_igual(s4.estado.escudo, 100.0 - s4.cfg.nube.golpe_resistente, "Más resistencia: golpe menor")

	# Escudo en cero: el generador se pausa 10 s
	var s5 = _nuevo(modo)
	_llenar_energia(s5)
	s5.construir("generador_oxigeno")
	_llenar_energia(s5)
	s5.estado.oxigeno = 50.0
	s5.estado.escudo = 5.0
	s5.golpe_de_nube()
	var agua0: float = s5.estado.agua
	_avanzar(s5, 5.0)
	_igual(s5.estado.agua, agua0, "escudo en 0: el generador está en pausa")
	_hasta(s5, 11.0)
	_avanzar(s5, 5.0)
	_chequear(s5.estado.agua < agua0 - 0.3, "pasados 10 s el generador vuelve a trabajar")


# ---------- 11. Vida ----------

func _t_vida(modo: String) -> void:
	_titulo("11. VIDA")
	var sim = _nuevo(modo)
	sim.estado.vida = 50.0
	_avanzar(sim, 10.0)
	_igual(sim.estado.vida, 52.0, "cerca de la base sube 0,2 por s")

	var s2 = _nuevo(modo)
	s2.estado.vida = 50.0
	s2.estado.cerca_de_base = false
	_avanzar(s2, 10.0)
	_igual(s2.estado.vida, 50.0, "lejos de la base no se recupera")

	var s3 = _nuevo(modo)
	s3.estado.vida = 50.0
	s3.estado.oxigeno = 10.0
	_avanzar(s3, 1.0)
	_igual(s3.estado.vida, 50.0, "con oxígeno menor que 20 no se recupera")

	var s4 = _nuevo(modo)
	s4.estado.vida = 50.0
	s4.estado.oxigeno = 0.0
	_avanzar(s4, 1.0)
	_igual(s4.estado.vida, 49.5, "con oxígeno 0 la Vida baja 0,5 por s")

	var s5 = _nuevo(modo)
	s5.estado.vida = 10.2
	s5.estado.oxigeno = 0.0
	_avanzar(s5, 5.0)
	_igual(s5.estado.vida, 10.0, "la Vida nunca baja de 10")

	var s6 = _nuevo(modo)
	s6.aplicar_mejora("vida_jardin")
	_llenar_energia(s6)
	_chequear(s6.construir("jardin") == "ok", "jardín con la mejora")
	s6.estado.vida = 50.0
	_avanzar(s6, 10.0)
	_igual(s6.estado.vida, 54.0, "con jardín la Vida sube 0,4 por s")
	_igual(s6.estado.agua, 19.5, "el jardín gasta 0,05 de agua por s")


# ---------- 12. Topes y mejoras ----------

func _t_topes_y_mejoras(modo: String) -> void:
	_titulo("12. TOPES Y MEJORAS")
	var sim = _nuevo(modo)
	_llenar_energia(sim)
	sim.construir("panel_solar")
	sim.construir("panel_solar")
	sim.estado.energia = 99.9
	_avanzar(sim, 10.0)
	_igual(sim.estado.energia, 100.0, "la energía no pasa de 100")

	var s2 = _nuevo(modo)
	s2.construir("panel_solar")
	s2.estado.energia = 100.0
	s2.construir("panel_solar")
	s2.aplicar_mejora("energia_bateria")
	_igual(s2.energia_maxima(), 150.0, "Batería: máximo 150")
	s2.estado.energia = 149.0
	_avanzar(s2, 10.0)
	_igual(s2.estado.energia, 150.0, "con Batería la energía llega a 150")

	var s3 = _nuevo(modo)
	_igual(s3.panel_por_s(), 0.6, "panel base: 0,6")
	s3.aplicar_mejora("energia_panel_extra")
	_igual(s3.panel_por_s(), 0.72, "primera mejora de energía: 0,72")
	s3.aplicar_mejora("energia_produccion")
	_igual(s3.panel_por_s(), 0.9, "segunda mejora de energía: 0,9")

	var s4 = _nuevo(modo)
	_igual(s4.generador_energia_por_s(), 0.3, "generador base: 0,3 de energía")
	_igual(s4.generador_agua_por_s(), 0.15, "generador base: 0,15 de agua")
	s4.aplicar_mejora("vida_generador_eficiente")
	_igual(s4.generador_energia_por_s(), 0.225, "Generador eficiente: energía ×0,75", 0.001)
	_igual(s4.generador_agua_por_s(), 0.1125, "Generador eficiente: agua ×0,75", 0.001)
	s4.estado.reciclador_instalado = true
	_igual(s4.generador_agua_por_s(), 0.07875, "con reciclador: agua ×0,7 más", 0.001)

	var s5 = _nuevo(modo)
	s5.estado.hielo = 39
	s5.iniciar_viaje_hielo()
	_avanzar(s5, 61.0)
	_chequear(s5.estado.hielo == 40, "el hielo no pasa de 40 en el depósito")


# ---------- 13. Partida larga ----------

func _t_partida_larga(modo: String) -> void:
	_titulo("13. PARTIDA COMPLETA DE 30 MINUTOS")
	var sim = _nuevo(modo, false)
	var cont := {"impactos": 0}
	sim.nube_impacto.connect(func(_a, _b): cont.impactos += 1)
	var rota := false
	var instante := 0.0
	for paso in 18000:
		sim.tick(0.1)
		if paso % 10 == 0:
			_jugar(sim)
		if not _estado_valido(sim):
			rota = true
			instante = sim.estado.tiempo_juego
			break
	_chequear(not rota, "durante 30 min ninguna barra sale de sus límites (falló en t=%.1f)" % instante if rota else "durante 30 min ninguna barra sale de sus límites")
	_chequear(cont.impactos == 7, "en 30 minutos llegan 7 nubes (llegaron %d)" % cont.impactos)
	var e = sim.estado
	print("  Estado final: energía %.0f, agua %.0f, oxígeno %.0f, Vida %.0f, escudo %.0f, hielo %d" % [
		e.energia, e.agua, e.oxigeno, e.vida, e.escudo, e.hielo])


func _jugar(sim) -> void:
	for id in ["panel_solar", "procesador_hielo", "generador_oxigeno", "panel_solar"]:
		sim.construir(id)
	if sim.estado.escudo < 100.0:
		sim.reparar_escudo()
	if not sim.estado.en_viaje_hielo:
		sim.iniciar_viaje_hielo()


func _estado_valido(sim) -> bool:
	var e = sim.estado
	for k in ["energia", "agua", "oxigeno", "vida", "escudo"]:
		if is_nan(e[k]):
			return false
	return e.energia >= 0.0 and e.energia <= sim.energia_maxima() \
		and e.agua >= 0.0 and e.agua <= sim.tope_agua() \
		and e.oxigeno >= 0.0 and e.oxigeno <= 100.0 \
		and e.escudo >= 0.0 and e.escudo <= 100.0 \
		and e.vida >= 10.0 and e.vida <= 100.0 \
		and e.hielo >= 0 and e.hielo <= 40


# ---------- Cadete frente a Ingeniero ----------

func _comparar_modos() -> void:
	print("\n######################################")
	print("# CADETE FRENTE A INGENIERO")
	print("######################################")
	var c = _nuevo("cadete").cfg
	var i = _nuevo("ingeniero").cfg
	if c.is_empty() or i.is_empty():
		_chequear(false, "no se pudieron cargar los dos modos")
		return
	for id in c.costos.keys():
		_chequear(absf(c.costos[id] * 1.5 - i.costos[id]) <= 1.0,
			"costo de %s: Ingeniero ≈ Cadete ×1,5 (%s y %s)" % [id, str(c.costos[id]), str(i.costos[id])])
	_chequear(i.nube.golpe > c.nube.golpe, "la nube pega más fuerte en Ingeniero")
	_chequear(i.nube.sobrante_a_vida > c.nube.sobrante_a_vida, "pasa más daño a la Vida en Ingeniero")
	_chequear(i.escudo.reparar_energia > c.escudo.reparar_energia, "reparar cuesta más en Ingeniero")
	_chequear(i.escudo.reparar_valor < c.escudo.reparar_valor, "reparar devuelve menos en Ingeniero")
	for n in range(4):
		_chequear(i.herramientas[n].vida > c.herramientas[n].vida,
			"herramienta %d quita más Vida en Ingeniero" % (n + 1))
		_chequear(i.herramientas[n].hielo == c.herramientas[n].hielo,
			"herramienta %d trae el mismo hielo en los dos modos" % (n + 1))
	_chequear(i.panel.energia_por_s_dia == c.panel.energia_por_s_dia, "producen lo mismo")
	_chequear(c.costos.panel_solar == 15 and c.costos.procesador_hielo == 25 and c.costos.generador_oxigeno == 30,
		"costos de Cadete: 15, 25 y 30")
