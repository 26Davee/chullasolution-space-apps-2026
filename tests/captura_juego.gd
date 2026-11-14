extends SceneTree
func _initialize():
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var img0 = root.get_texture().get_image(); img0.save_png("/tmp/captura_intro.png")
	main._perfil = {"mode": "cadet", "nickname": "Ángel"}
	main.mostrar_juego()
	for i in 90: await process_frame
	root.get_texture().get_image().save_png("/tmp/captura_juego.png")
	print("juego listo. astronauta en ", main._pantalla.astronauta.global_position, " energia ", root.get_node("GameState").energia, " sim ", root.get_node("GameState").hay_simulacion())
	quit()
