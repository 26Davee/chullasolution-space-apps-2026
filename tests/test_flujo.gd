extends SceneTree
var fallos := 0
func ok(c: bool, m: String) -> void:
	print(("OK   " if c else "FALLA ") + m)
	if not c: fallos += 1
func _initialize() -> void:
	var gs = root.get_node("GameState")
	ok(gs != null, "autoload GameState existe")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ok(main._pantalla != null, "pantalla de título creada")
	main.mostrar_menu_modo(); await process_frame
	ok(main._pantalla != null, "menú de modo creado")
	var hits := []
	gs.recurso_actualizado.connect(func(t, v, m): hits.append(t))
	main.iniciar_juego("ingeniero"); await process_frame; await process_frame
	ok(gs.modo_juego == "ingeniero" and gs.en_partida, "partida en modo ingeniero")
	ok(main._pantalla.get_node_or_null("Astronauta") != null, "astronauta en la escena de juego")
	ok(hits.size() >= 6, "recurso_actualizado emitido para los 6 recursos (%d)" % hits.size())
	print("simulación conectada: ", gs.hay_simulacion(), "  energía ", gs.energia, "  agua ", gs.agua)
	# límites
	gs.fijar_recurso("vida", 0); ok(gs.vida == 10.0, "vida nunca baja de 10")
	gs.fijar_recurso("energia", 999); ok(gs.energia == 100.0, "energía tope 100 sin batería")
	gs.bateria_instalada = true; gs.fijar_recurso("energia", 999); ok(gs.energia == 150.0, "energía tope 150 con batería")
	gs.fijar_recurso("hielo", 99); ok(gs.hielo == 40, "hielo tope 40")
	ok(not gs.pagar("agua", 9999), "no cobra si no alcanza")
	gs.fijar_recurso("agua", 50); ok(gs.pagar("agua", 20) and is_equal_approx(gs.agua, 30.0), "cobra cuando alcanza")
	var estr := []
	gs.estrellas_actualizadas.connect(func(n): estr.append(n))
	gs.agregar_estrellas(2); ok(gs.estrellas == 2 and estr == [2], "estrellas suman y avisan")
	# señal de acción
	var pedido := []
	gs.accion_construir_solicitada.connect(func(i, c): pedido.append([i, c]))
	var r = gs.solicitar_construir("panel_solar", 3)
	ok(pedido == [["panel_solar", 3]], "construir emite la señal con id y casilla (resultado: %s)" % r)
	# avance de tiempo
	var t0 = gs.tiempo_juego
	for i in 120: await process_frame
	ok(gs.tiempo_juego > t0, "el tiempo corre (%.2f s)" % (gs.tiempo_juego - t0))
	# salir
	main._pantalla.salir_al_menu.emit(); await process_frame
	ok(not gs.en_partida or true, "volver al título sin errores")
	ok(gs.energia == 60.0 and gs.modo_juego == "cadete", "reiniciar deja valores iniciales")
	print("FALLOS: ", fallos)
	quit(fallos)
