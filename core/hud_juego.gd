extends CanvasLayer
## HUD provisional del juego (puesto 1). Lo reemplaza el puesto 6 cuando tenga el suyo.
## Solo LEE GameState y avisa con señales; no cambia el estado por su cuenta.

signal construir_pedido(id_estructura: String)
signal ir_por_hielo_pedido()
signal procesar_hielo_pedido()
signal reparar_escudo_pedido()
signal salir_pedido()
signal carta_cerrada()

const AZUL := Color("#0E2347")
const HUESO := Color("#F4EFE6")
const AMBAR := Color("#F2B544")
const TURQUESA := Color("#33C7D6")
const CORAL := Color("#FF6F61")

const BARRAS := [
	["energia", "Energía", Color("#F2B544")],
	["agua", "Agua", Color("#4FB3F0")],
	["oxigeno", "Oxígeno", Color("#33C7D6")],
	["vida", "Vida", Color("#6FD39A")],
	["escudo", "Escudo", Color("#B28CFF")],
	["hielo", "Hielo", Color("#CDEBFF")],
]

var _barras: Dictionary = {}
var _valores: Dictionary = {}
var _reloj: Label
var _estrellas: Label
var _mision_titulo: Label
var _mision_texto: Label
var _aviso: Label
var _aviso_panel: PanelContainer
var _viaje: Label
var _carta: PanelContainer
var _carta_texto: RichTextLabel
var _aviso_tween: Tween


func _ready() -> void:
	layer = 10
	_construir_barras()
	_construir_centro()
	_construir_mision()
	_construir_acciones()
	_construir_carta()


func _process(_delta: float) -> void:
	var g := GameState
	for clave in _barras:
		var barra: ProgressBar = _barras[clave]
		var maximo := g.maximo_de(clave)
		barra.max_value = maximo
		barra.value = g.valor_de(clave)
		(_valores[clave] as Label).text = "%d / %d" % [int(g.valor_de(clave)), int(maximo)]
	var ciclo := int(g.tiempo_juego) % int(g.TIEMPO_CICLO_SOLAR)
	_reloj.text = "%s  ·  %d:%02d" % ["☀ DÍA" if g.es_dia else "☾ NOCHE", int(g.tiempo_juego) / 60, int(g.tiempo_juego) % 60]
	_reloj.add_theme_color_override("font_color", AMBAR if g.es_dia else Color("#9DB4FF"))
	_estrellas.text = "★ %d" % g.estrellas
	var v := g.progreso_viaje()
	_viaje.visible = g.en_viaje_hielo
	if g.en_viaje_hielo:
		_viaje.text = "⛏ Viaje al cráter: %d / %d s" % [int(v.x), int(v.y)]
	if g.alerta_nube and not g.nube_activa:
		_reloj.text += "   ⚠ NUBE EN %d s" % int(g.tiempo_para_nube)
	elif g.nube_activa:
		_reloj.text += "   ☄ NUBE SOLAR"


# ───────────────────────── API pública ─────────────────────────

func aviso(texto: String, color: Color = HUESO) -> void:
	_aviso.text = texto
	_aviso.add_theme_color_override("font_color", color)
	_aviso_panel.visible = true
	_aviso_panel.modulate.a = 1.0
	if _aviso_tween:
		_aviso_tween.kill()
	_aviso_tween = create_tween()
	_aviso_tween.tween_interval(3.5)
	_aviso_tween.tween_property(_aviso_panel, "modulate:a", 0.0, 0.6)
	_aviso_tween.tween_callback(func(): _aviso_panel.visible = false)


func actualizar_mision(datos: Dictionary) -> void:
	if datos.is_empty():
		_mision_titulo.text = "¡Misiones completadas!"
		_mision_texto.text = "Has terminado todas las misiones disponibles."
		return
	_mision_titulo.text = "Misión: %s" % str(datos.get("mision", ""))
	var lineas: Array[String] = []
	for o in datos.get("objetivo", []):
		lineas.append("• " + str(o))
	_mision_texto.text = "\n".join(lineas)


func mostrar_carta(titulo_mision: String, estrellas: int, carta: Dictionary) -> void:
	var t := "[center][color=#F2B544][b]¡Misión cumplida!  +%d ★[/b][/color]\n%s[/center]\n\n" % [estrellas, titulo_mision]
	if not carta.is_empty():
		t += "[color=#33C7D6][b]%s[/b][/color]\n%s" % [str(carta.get("titulo", "")), str(carta.get("dato", ""))]
	_carta_texto.text = t
	_carta.visible = true


# ───────────────────────── Construcción de la interfaz ─────────────────────────

func _estilo(color: Color, radio: int = 14, borde: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if borde.a > 0.0:
		s.border_color = borde
		s.set_border_width_all(2)
	return s


func _etiqueta(texto: String, tam: int = 16, color: Color = HUESO) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


func _panel(ancla: int, ancho: float) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _estilo(Color(AZUL, 0.82)))
	add_child(p)
	p.set_anchors_preset(ancla)
	p.custom_minimum_size.x = ancho
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	p.add_child(col)
	return col


func _construir_barras() -> void:
	var col := _panel(Control.PRESET_TOP_LEFT, 290)
	col.get_parent().position = Vector2(14, 14)
	for b in BARRAS:
		var fila := HBoxContainer.new()
		col.add_child(fila)
		var nombre := _etiqueta(b[1], 15)
		nombre.custom_minimum_size.x = 74
		fila.add_child(nombre)
		var barra := ProgressBar.new()
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(120, 16)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barra.add_theme_stylebox_override("background", _estilo(Color(0, 0, 0, 0.4), 8))
		barra.add_theme_stylebox_override("fill", _estilo(b[2], 8))
		fila.add_child(barra)
		var valor := _etiqueta("", 13, Color("#B9C9DC"))
		valor.custom_minimum_size.x = 64
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(valor)
		_barras[b[0]] = barra
		_valores[b[0]] = valor


func _construir_centro() -> void:
	var col := _panel(Control.PRESET_CENTER_TOP, 0)
	col.get_parent().position = Vector2(500, 14)
	_reloj = _etiqueta("", 18)
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_reloj)
	_estrellas = _etiqueta("", 18, AMBAR)
	_estrellas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_estrellas)
	_viaje = _etiqueta("", 16, TURQUESA)
	_viaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_viaje)
	_aviso_panel = PanelContainer.new()
	_aviso_panel.add_theme_stylebox_override("panel", _estilo(Color(0.03, 0.07, 0.15, 0.92), 14, TURQUESA))
	_aviso_panel.visible = false
	add_child(_aviso_panel)
	_aviso_panel.position = Vector2(340, 118)
	_aviso_panel.custom_minimum_size = Vector2(600, 0)
	_aviso = _etiqueta("", 18)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_panel.add_child(_aviso)


func _construir_mision() -> void:
	var col := _panel(Control.PRESET_TOP_RIGHT, 360)
	col.get_parent().position = Vector2(906, 14)
	_mision_titulo = _etiqueta("", 18, AMBAR)
	_mision_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_mision_titulo)
	_mision_texto = _etiqueta("", 14)
	_mision_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mision_texto.custom_minimum_size.x = 330
	col.add_child(_mision_texto)


func _boton(texto: String, color: Color, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("#071530"))
	b.add_theme_color_override("font_hover_color", Color("#071530"))
	b.add_theme_stylebox_override("normal", _estilo(color, 12))
	b.add_theme_stylebox_override("hover", _estilo(color.lightened(0.2), 12))
	b.add_theme_stylebox_override("pressed", _estilo(color.darkened(0.2), 12))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(accion)
	return b


func _construir_acciones() -> void:
	var fondo := PanelContainer.new()
	fondo.add_theme_stylebox_override("panel", _estilo(Color(AZUL, 0.82)))
	add_child(fondo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fondo.add_child(fila)
	var construibles := [["panel_solar", "☀ Panel"], ["procesador_hielo", "❄ Procesador"], ["generador_oxigeno", "O₂ Generador"], ["tanque_agua", "💧 Tanque"]]
	for c in construibles:
		var id: String = c[0]
		var etiqueta: String = c[1]
		var b := _boton("%s (%d)" % [etiqueta, int(GameState.costo_de(id))], AMBAR, func(): construir_pedido.emit(id))
		fila.add_child(b)
	fila.add_child(VSeparator.new())
	fila.add_child(_boton("⛏ Ir por hielo", TURQUESA, func(): ir_por_hielo_pedido.emit()))
	fila.add_child(_boton("⚙ Procesar hielo", TURQUESA, func(): procesar_hielo_pedido.emit()))
	fila.add_child(_boton("◈ Reparar escudo", Color("#B28CFF"), func(): reparar_escudo_pedido.emit()))
	fila.add_child(VSeparator.new())
	fila.add_child(_boton("Salir", CORAL, func(): salir_pedido.emit()))
	fondo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	fondo.position = Vector2(112, 650)
	var ayuda := _etiqueta("Clic: caminar  ·  Clic derecho + arrastrar: girar cámara  ·  Rueda: zoom  ·  R: girar pieza  ·  Esc: cancelar", 13, Color("#B9C9DC"))
	add_child(ayuda)
	ayuda.position = Vector2(14, 696)


func _construir_carta() -> void:
	_carta = PanelContainer.new()
	_carta.visible = false
	_carta.add_theme_stylebox_override("panel", _estilo(Color(0.03, 0.07, 0.15, 0.97), 18, AMBAR))
	add_child(_carta)
	_carta.position = Vector2(300, 150)
	_carta.custom_minimum_size = Vector2(680, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	_carta.add_child(col)
	_carta_texto = RichTextLabel.new()
	_carta_texto.bbcode_enabled = true
	_carta_texto.fit_content = true
	_carta_texto.custom_minimum_size = Vector2(640, 0)
	_carta_texto.add_theme_font_size_override("normal_font_size", 18)
	_carta_texto.add_theme_font_size_override("bold_font_size", 20)
	col.add_child(_carta_texto)
	col.add_child(_boton("Continuar", AMBAR, func():
		_carta.visible = false
		carta_cerrada.emit()))
