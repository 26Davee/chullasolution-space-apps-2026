extends Control
signal completed()
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const MODULES := ["panel_solar","procesador_hielo","generador_oxigeno","jardin"]
var _module_buttons: Array[Button] = []
var _selected_module := -1
var _placed_module := -1
var _feedback: Label
var world_view: SubViewportContainer
var placement: Node3D
var placed: Node3D
func _ready() -> void:
	UI.label(self,tr("flow.build_practice"),Rect2(0,0,size.x,32),17,UI.CYAN,true)
	world_view = preload("res://ui/world_backdrop.gd").new()
	world_view.position = Vector2(216,48)
	add_child(world_view)
	world_view.set_process(false)
	world_view.size = Vector2(size.x-216,size.y-104)
	world_view.viewport.handle_input_locally = true
	world_view.mouse_filter = MOUSE_FILTER_STOP
	world_view.camera.position = Vector3(8,18,25)
	world_view.camera.look_at(Vector3(-3,0,8))
	placed = Node3D.new()
	world_view.scene.add_child(placed)
	placement = preload("res://interaction/placement_system.gd").new()
	placement.camera = world_view.camera
	placement.placed_parent = placed
	placement.keep_placing_with_shift = false
	placement.piece_catalog = preload("res://core/juego.gd").PIECE_SCENES.duplicate()
	world_view.scene.add_child(placement)
	placement.piece_placed.connect(_placed)
	placement.placement_rejected.connect(func(_id,_reason): _feedback.text = tr("live.blocked"))
	var card_height := minf(96,(size.y-120)/4-8)
	for i in MODULES.size():
		var button = UI.button(self,"",Rect2(0,50+i*(card_height+8),196,card_height),_choose_module.bind(i))
		button.name = "PracticeModule_"+MODULES[i]
		var picture = TextureRect.new()
		picture.texture = load("res://assets/ui/activities/"+["solar","processor","oxygen","garden"][i]+"-v1.png")
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.position = Vector2(6,6)
		picture.size = Vector2(84,card_height-12)
		picture.mouse_filter = MOUSE_FILTER_IGNORE
		button.add_child(picture)
		var title = UI.label(button,tr("structures."+MODULES[i]),Rect2(98,6,92,card_height-12),16,UI.WHITE,true)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.tooltip_text = title.text
		_module_buttons.append(button)
	_feedback = UI.label(self,tr("flow.build_choose"),Rect2(216,size.y-48,size.x-216,44),18,UI.GOLD,true)
	UI.button(self,tr("visual.try_again"),Rect2(0,size.y-64,196,48),_reset)
func _choose_module(index: int, narrate := true) -> void:
	_selected_module = index
	for i in _module_buttons.size():
		UI.paint(_module_buttons[i])
		if i == index:
			_module_buttons[i].add_theme_stylebox_override("normal",UI.style(Color("#16344d"),UI.GOLD,3))
			_module_buttons[i].add_theme_stylebox_override("hover",UI.style(Color("#20465f"),UI.GOLD,3))
	placement.start_placement(StringName(MODULES[index]))
	_feedback.text = tr("flow.build_place")
	if narrate: narration_requested.emit(_feedback.text)
func _placed(_id: StringName, _point: Vector3) -> void:
	_placed_module = _selected_module
	_feedback.text = tr("flow.build_done")
	narration_requested.emit(_feedback.text)
	completed.emit()
func _reset() -> void:
	placement.cancel_placement()
	for child in placed.get_children(): child.queue_free()
	_placed_module = -1
	_feedback.text = tr("flow.build_choose")
