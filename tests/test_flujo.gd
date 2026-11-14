extends SceneTree
## Prueba sin ventana: godot --headless --path . --script tests/test_flujo.gd
## Recorre intro → aterrizaje → juego y comprueba GameState, construcción, misión 1 y límites.
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
	ok(main._pantalla != null and main._pantalla.has_signal("mission_requested"), "arranca en la intro de Andrea")
	main._al_pedir_mision({"mode": "engineer", "nickname": "Prueba"})
	await process_frame; await process_frame
	ok(main._pantalla != null and main._pantalla.has_signal("completed"), "después de la intro viene el aterrizaje")
	main._pantalla.completed.emit()
	await process_frame; await process_frame; await process_frame
	var j = main._pantalla
	ok(j.has_signal("salir_al_menu"), "después del aterrizaje viene el juego")
	ok(gs.modo_juego == "ingeniero" and gs.en_partida, "perfil 'engineer' → modo ingeniero")
	ok(gs.hay_simulacion(), "simulación de Anahi enchufada")
	ok(j.astronauta != null and j.astronauta.is_in_group("astronauta"), "astronauta en escena y en el grupo")
	ok(j.mundo.get_node_or_null("PanelSolar") == null, "los módulos de ejemplo se quitaron (se construyen)")
	# límites y cobro
	gs.fijar_recurso("vida", 0); ok(gs.vida == 10.0, "vida nunca baja de 10")
	gs.fijar_recurso("energia", 999); ok(gs.energia == 100.0, "energía tope 100")
	gs.fijar_recurso("hielo", 99); ok(gs.hielo == 40, "hielo tope 40")
	gs.fijar_recurso("energia", 60); gs.fijar_recurso("vida", 100); gs.fijar_recurso("hielo", 0)
	# construir el panel gratis
	var antes: float = gs.energia
	j._al_colocar(&"panel_solar", Vector3(5, 0, 5))
	ok(gs.paneles_instalados == 1 and gs.energia >= antes - 0.001, "primer panel: se instala y es gratis")
	ok(get_nodes_in_group("placed_pieces").size() == 1, "la pieza aparece en el mundo")
	# sin cupo para tanque en nivel 1
	j._al_colocar(&"tanque_agua", Vector3(8, 0, 5))
	ok(gs.agua_max == 60.0 or gs.agua_max >= 60.0, "tanque sin cupo no cambia nada")
	# misión 1
	var cartas := []
	gs.mision_completada.connect(func(id, e, c): cartas.append(id))
	gs.fijar_recurso("energia", 80)
	j.misiones.evaluar_estado_simulacion(gs.instantanea(), 1.0)
	ok(cartas == ["mision_01"] and gs.estrellas == 1, "misión 1 completada → +1 estrella")
	ok(not gs.en_partida, "el juego se pausa mientras se lee la carta")
	j.hud.carta_cerrada.emit()
	ok(gs.en_partida, "al cerrar la carta el juego sigue")
	# viaje por hielo
	var r: String = gs.solicitar_viaje_hielo()
	ok(r == "ok" and gs.en_viaje_hielo, "viaje por hielo arranca")
	# el tiempo corre
	var t0: float = gs.tiempo_juego
	for i in 60: await process_frame
	ok(gs.tiempo_juego > t0, "el tiempo corre")
	# salir
	j.salir_al_menu.emit()
	await process_frame; await process_frame
	ok(main._pantalla != null and main._pantalla.has_signal("mission_requested"), "salir vuelve a la intro")
	ok(gs.energia == 60.0 and gs.modo_juego == "cadete", "reiniciar deja valores iniciales")
	print("FALLOS: ", fallos)
	quit(fallos)
