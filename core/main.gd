extends Node
## Main — flujo de pantallas: título → elección de modo → juego. Dueño: puesto 1.
##
## Las pantallas de título y de modo son PROVISIONALES (texto fijo, sin i18n):
## el puesto 6 las reemplaza por las suyas. Mientras tanto dejan el recorrido
## completo de F5 funcionando. Para cambiarlas basta con sustituir
## _crear_titulo() y _crear_menu_modo(); el resto del flujo no se toca.

const ESCENA_JUEGO := "res://scenes/juego.tscn"

var _pantalla: Node = null


func _ready() -> void:
	mostrar_titulo()


func mostrar_titulo() -> void:
	GameState.reiniciar()
	_cambiar_pantalla(_crear_titulo())


func mostrar_menu_modo() -> void:
	_cambiar_pantalla(_crear_menu_modo())


func iniciar_juego(modo: String) -> void:
	var escena: PackedScene = load(ESCENA_JUEGO)
	var juego := escena.instantiate()
	if juego.has_signal("salir_al_menu"):
		juego.salir_al_menu.connect(mostrar_titulo)
	_cambiar_pantalla(juego)
	GameState.iniciar_partida(modo)


func _cambiar_pantalla(nueva: Node) -> void:
	if _pantalla != null:
		_pantalla.queue_free()
	_pantalla = nueva
	add_child(nueva)


# ───────────────────────── Pantallas provisionales ─────────────────────────

func _fondo_con_columna() -> Array:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.027, 0.082, 0.188)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	centro.add_child(col)
	return [capa, col]


func _etiqueta(texto: String, tamano: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	return l


func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(320, 52)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(accion)
	return b


func _crear_titulo() -> Node:
	var partes := _fondo_con_columna()
	var col: VBoxContainer = partes[1]
	col.add_child(_etiqueta("KILLAWASI", 72, Color(0.949, 0.710, 0.267)))
	col.add_child(_etiqueta("Casa de la Luna", 26, Color(0.957, 0.937, 0.902)))
	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, 30)
	col.add_child(espacio)
	var jugar := _boton("Jugar", mostrar_menu_modo)
	col.add_child(jugar)
	col.add_child(_etiqueta("ChullaSolution · ESPOCH · NASA Space Apps 2026", 14, Color(0.2, 0.78, 0.84)))
	jugar.call_deferred("grab_focus")
	return partes[0]


func _crear_menu_modo() -> Node:
	var partes := _fondo_con_columna()
	var col: VBoxContainer = partes[1]
	col.add_child(_etiqueta("Elige tu modo", 44, Color(0.957, 0.937, 0.902)))
	var cadete := _boton("Cadete · más tranquilo", func(): iniciar_juego(GameState.MODO_CADETE))
	col.add_child(cadete)
	col.add_child(_boton("Ingeniero · más exigente", func(): iniciar_juego(GameState.MODO_INGENIERO)))
	col.add_child(_boton("Volver", mostrar_titulo))
	cadete.call_deferred("grab_focus")
	return partes[0]
