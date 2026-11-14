extends Control
## Small vector symbols shared by resource cards and progression nodes.
var kind := "energia"
var tint := Color("#ffc64f")
var disc := true

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var radius := minf(size.x, size.y) * 0.5
    var c := size * 0.5
    if disc:
        draw_circle(c, radius, tint)
    var ink := Color("#071b32") if disc else tint
    var scale_factor := radius / 24.0
    draw_set_transform(c, 0, Vector2.ONE * scale_factor)
    match kind:
        "energia":
            draw_colored_polygon(PackedVector2Array([Vector2(2,-17),Vector2(-11,2),Vector2(-2,2),Vector2(-6,17),Vector2(12,-5),Vector2(3,-5)]), ink)
        "vida":
            draw_circle(Vector2(-6,-5),8,ink)
            draw_circle(Vector2(6,-5),8,ink)
            draw_colored_polygon(PackedVector2Array([Vector2(-13,-2),Vector2(13,-2),Vector2(0,15)]),ink)
        "escudo":
            draw_colored_polygon(PackedVector2Array([Vector2(-13,-12),Vector2(0,-17),Vector2(13,-12),Vector2(11,5),Vector2(0,17),Vector2(-11,5)]),ink)
        "agua", "oxigeno":
            if kind == "agua":
                draw_circle(Vector2(0,5),10,ink)
                draw_colored_polygon(PackedVector2Array([Vector2(-9,1),Vector2(0,-16),Vector2(9,1)]),ink)
            else:
                draw_arc(Vector2.ZERO,13,0,TAU,32,ink,4,true)
                draw_circle(Vector2(15,13),3,ink)
        "lock":
            draw_arc(Vector2(0,-5),7,PI,TAU,20,ink,3,true)
            draw_style_box(_box(ink,4),Rect2(-11,-5,22,20))
        "check":
            draw_polyline(PackedVector2Array([Vector2(-11,0),Vector2(-3,9),Vector2(13,-10)]),ink,4,true)
        "menu":
            for y in [-10, 0, 10]: draw_line(Vector2(-14,y),Vector2(14,y),ink,3,true)
        "ice":
            draw_colored_polygon(PackedVector2Array([Vector2(0,-17),Vector2(13,-7),Vector2(13,9),Vector2(0,17),Vector2(-13,9),Vector2(-13,-7)]),ink)
            draw_line(Vector2(0,-10),Vector2(0,11),Color("#daffff"),2,true)
        "repair":
            draw_line(Vector2(-11,13),Vector2(9,-9),ink,7,true)
            draw_arc(Vector2(8,-9),8,0.1,PI*1.6,18,ink,5,true)
        "pin":
            draw_line(Vector2(-5,-9),Vector2(9,15),ink,3,true)
            draw_circle(Vector2(-5,-9),8,ink)
            draw_line(Vector2(-11,-6),Vector2(1,-13),ink,4,true)
        "science":
            draw_rect(Rect2(-13,-14,26,29),ink,false,3)
            draw_line(Vector2(-7,-5),Vector2(7,-5),ink,2,true)
            draw_line(Vector2(-7,3),Vector2(7,3),ink,2,true)
            draw_circle(Vector2(0,-16),4,ink)
        "base":
            draw_arc(Vector2(0,7),15,PI,TAU,24,ink,3,true)
            draw_line(Vector2(-15,7),Vector2(15,7),ink,3,true)
            draw_rect(Rect2(-4,-2,8,9),ink)
            draw_line(Vector2(0,-8),Vector2(0,-18),ink,2,true)
            draw_line(Vector2(0,-18),Vector2(10,-13),ink,2,true)
    draw_set_transform(Vector2.ZERO)

func _box(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    return style
