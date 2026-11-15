extends Control
## Mouse and key diagrams, drawn without font-dependent emoji.
var action := "move"
const GOLD := Color("#ffc64f")
func _ready() -> void: mouse_filter = MOUSE_FILTER_IGNORE
func _draw() -> void:
    var center := size * 0.5
    if action in ["move","orbit","zoom"]:
        var box := Rect2(center-Vector2(16,22),Vector2(32,44))
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#172f46")
        style.border_color = Color("#59e0dc")
        style.set_border_width_all(2)
        style.set_corner_radius_all(12)
        draw_style_box(style,box)
        draw_line(center-Vector2(0,20),center,Color("#59e0dc"),1.5)
        draw_line(center-Vector2(14,2),center+Vector2(14,-2),Color("#59e0dc"),1.5)
        if action == "move": draw_circle(center+Vector2(-8,-11),5,GOLD)
        elif action == "orbit":
            draw_circle(center+Vector2(8,-11),5,GOLD)
            draw_line(center+Vector2(21,5),center+Vector2(30,5),GOLD,2)
            draw_line(center+Vector2(30,5),center+Vector2(26,1),GOLD,2)
        else:
            draw_line(center+Vector2(0,-15),center+Vector2(0,-6),GOLD,4)
            draw_line(center+Vector2(23,-13),center+Vector2(23,13),GOLD,2)
            draw_line(center+Vector2(23,-13),center+Vector2(19,-9),GOLD,2)
            draw_line(center+Vector2(23,13),center+Vector2(27,9),GOLD,2)
    else:
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#172f46")
        style.border_color = GOLD
        style.set_border_width_all(2)
        style.set_corner_radius_all(8)
        draw_style_box(style,Rect2(center-Vector2(26,20),Vector2(52,40)))
        var text: String = {"follow":"C","rotate":"R","cancel":"Esc"}.get(action,"")
        var font := ThemeDB.fallback_font
        var text_size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20)
        draw_string(font,center+Vector2(-text_size.x/2,7),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,GOLD)
