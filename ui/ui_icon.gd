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
        "sun":
            draw_circle(Vector2.ZERO,8,ink)
            for i in 8:
                var d := Vector2(cos(i*TAU/8),sin(i*TAU/8))
                draw_line(d*12,d*19,ink,3,true)
        "moon":
            draw_arc(Vector2.ZERO,15,PI*0.2,PI*1.8,32,ink,6,true)
            draw_line(Vector2(11,-9),Vector2(3,-4),ink,3,true)
            draw_line(Vector2(3,-4),Vector2(3,5),ink,3,true)
            draw_line(Vector2(3,5),Vector2(11,9),ink,3,true)
        "energia":
            draw_colored_polygon(PackedVector2Array([Vector2(2,-17),Vector2(-11,2),Vector2(-2,2),Vector2(-6,17),Vector2(12,-5),Vector2(3,-5)]), ink)
        "robot_battery":
            draw_rect(Rect2(-12,-10,22,20), ink, false, 3)
            draw_rect(Rect2(10,-5,4,10), ink)
            draw_rect(Rect2(-8,-6,13,12), ink)
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
        "checkpoint":
            draw_arc(Vector2.ZERO,15,PI*0.2,TAU,32,ink,4,true)
            draw_colored_polygon(PackedVector2Array([Vector2(15,-13),Vector2(3,-14),Vector2(12,-3)]),ink)
            draw_polyline(PackedVector2Array([Vector2(-8,0),Vector2(-2,7),Vector2(9,-6)]),ink,3,true)
        "close":
            draw_line(Vector2(-11,-11),Vector2(11,11),ink,3,true)
            draw_line(Vector2(-11,11),Vector2(11,-11),ink,3,true)
        "more":
            for x in [-12,0,12]: draw_circle(Vector2(x,0),3,ink)
        "language":
            draw_arc(Vector2.ZERO,16,0,TAU,40,ink,2,true)
            draw_arc(Vector2.ZERO,8,0,TAU,30,ink,2,true)
            draw_line(Vector2(-16,0),Vector2(16,0),ink,2,true)
        "audio":
            draw_colored_polygon(PackedVector2Array([Vector2(-15,-6),Vector2(-7,-6),Vector2(3,-14),Vector2(3,14),Vector2(-7,6),Vector2(-15,6)]),ink)
            draw_arc(Vector2(3,0),12,-PI/3,PI/3,20,ink,3,true)
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
        "construction":
            draw_line(Vector2(-12, 13), Vector2(8, -7), ink, 6, true)
            draw_rect(Rect2(0, -15, 18, 9), ink)
        "camera":
            draw_rect(Rect2(-16, -10, 32, 24), ink, false, 3)
            draw_arc(Vector2.ZERO, 7, 0, TAU, 24, ink, 3, true)
            draw_rect(Rect2(-8, -16, 16, 6), ink)
        "messages":
            draw_rect(Rect2(-17, -12, 34, 25), ink, false, 3)
            draw_polyline(PackedVector2Array([Vector2(-16,-10),Vector2(0,2),Vector2(16,-10)]), ink, 3, true)
        "settings":
            for i in 3:
                var y := -11.0 + i * 11.0
                draw_line(Vector2(-16,y), Vector2(16,y), ink, 3, true)
                draw_circle(Vector2(-7 if i % 2 == 0 else 7,y), 5, ink)
        "missions":
            draw_rect(Rect2(-14,-16,28,32), ink, false, 3)
            for y in [-8, 1, 10]:
                draw_circle(Vector2(-7,y), 2, ink)
                draw_line(Vector2(-1,y), Vector2(8,y), ink, 2, true)
        "upgrades":
            draw_polyline(PackedVector2Array([Vector2(-14,13),Vector2(0,-10),Vector2(14,13)]), ink, 3, true)
            for p in [Vector2(-14,13), Vector2(0,-10), Vector2(14,13)]: draw_circle(p, 5, ink)
        "help", "timmy":
            draw_arc(Vector2(0,-4), 9, PI, TAU + 0.6, 24, ink, 3, true)
            draw_line(Vector2(6,3),Vector2(0,9),ink,3,true)
            draw_circle(Vector2(0,16),2,ink)
        "home":
            draw_polyline(PackedVector2Array([Vector2(-17,-1),Vector2(0,-16),Vector2(17,-1)]),ink,3,true)
            draw_rect(Rect2(-12,-2,24,18),ink,false,3)
        "star":
            var points := PackedVector2Array()
            for i in 10:
                var a := -PI/2 + i * TAU/10
                points.append(Vector2(cos(a),sin(a)) * (18 if i % 2 == 0 else 8))
            draw_colored_polygon(points, ink)
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
