extends Control

const LANDER = preload("res://assets/ui/lander.png")

var landing_progress := 0.0
var show_ship := false
var _time := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    _time += delta
    if show_ship and landing_progress < 1.0:
        queue_redraw()

func _draw() -> void:
    var points := PackedVector2Array([Vector2.ZERO, Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)])
    draw_polygon(points, PackedColorArray([
        Color(0.015, 0.03, 0.075, 0.58), Color(0.015, 0.03, 0.075, 0.04),
        Color(0.015, 0.03, 0.075, 0.16), Color(0.015, 0.03, 0.075, 0.66)
    ]))
    if show_ship:
        _draw_ship()

func _draw_ship() -> void:
    draw_set_transform(Vector2(790, 442), 0, Vector2(1, 0.24))
    draw_circle(Vector2.ZERO, 72, Color(0, 0, 0, 0.25 * landing_progress))
    draw_set_transform(Vector2(790, lerpf(-120.0, 340.0, landing_progress)))
    if landing_progress < 0.99:
        var flame := 30.0 + sin(_time * 24.0) * 7.0
        draw_colored_polygon(PackedVector2Array([
            Vector2(-12, 58), Vector2(0, 68 + flame), Vector2(12, 58)
        ]), Color("ffc44f"))
    draw_texture_rect(LANDER, Rect2(-100, -100, 200, 200), false)
    draw_set_transform(Vector2.ZERO)
