extends Control
## Non-intercepting focus ring and Timmy's next instruction.
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
var target: Control
var _hint: Panel
var _caption: Label
var _key := ""
var _pulse := 0.0
func _ready() -> void:
    mouse_filter = MOUSE_FILTER_IGNORE
    size = Vector2(1280,720)
    z_index = 60
    _hint = UI.panel(self,Rect2(78,548,1124,58),Color("#071b32fa"),14)
    var portrait := TextureRect.new()
    portrait.texture = load("res://assets/ui/timmy.png")
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.position = Vector2(4,2)
    portrait.size = Vector2(52,54)
    portrait.mouse_filter = MOUSE_FILTER_IGNORE
    _hint.add_child(portrait)
    UI.label(_hint,"Timmy",Rect2(62,7,76,26),17,UI.GOLD,true)
    _caption = UI.label(_hint,"",Rect2(144,7,960,46),18,UI.WHITE,true)
    _hint.hide()
func point_at(control: Control, text: String, compact := false, show_hint := true) -> void:
    target = control
    _hint.visible = show_hint
    _hint.position = Vector2(280,276) if compact else Vector2(78,548)
    _hint.size = Vector2(550,112) if compact else Vector2(1124,58)
    _caption.position = Vector2(144,10)
    _caption.size = Vector2(386,92) if compact else Vector2(960,46)
    _caption.text = text
    if _key != text:
        _key = text
        if show_hint and not text.is_empty(): narration_requested.emit(text)
    queue_redraw()
func clear() -> void:
    target = null
    _hint.hide()
    _key = ""
    queue_redraw()
func _process(delta: float) -> void:
    _pulse += delta
    queue_redraw()
func _draw() -> void:
    if not is_instance_valid(target) or not target.is_visible_in_tree(): return
    var rect := Rect2(get_global_transform().affine_inverse()*target.global_position,target.size*target.get_global_transform().get_scale()/get_global_transform().get_scale())
    rect = rect.grow(4+sin(_pulse*4)*1.5)
    var style := UI.style(Color.TRANSPARENT,UI.GOLD,3,12)
    draw_style_box(style,rect)
    var x := rect.position.x+rect.size.x/2
    var y := rect.position.y-10
    if y > 12:
        draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x-8,y-10),Vector2(x+8,y-10)]),UI.GOLD)
