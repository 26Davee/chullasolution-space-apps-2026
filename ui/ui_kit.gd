extends RefCounted
## Shared palette and controls for the intro, HUD and panel previews.
const INK := Color("#071b32")
const GOLD := Color("#ffc64f")
const CYAN := Color("#59e0dc")
const WHITE := Color("#f3f7fc")
static var _bold: FontVariation
static var _translations_registered := false

static func style(color: Color, border := Color.TRANSPARENT, width := 0, radius := 14) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    box.border_color = border
    box.set_border_width_all(width)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 16
    box.content_margin_right = 16
    return box

static func paint(button: Button, active := false) -> void:
    button.add_theme_stylebox_override("normal", style(GOLD if active else Color("#102b46"), Color("#536e87"), 0 if active else 1))
    button.add_theme_stylebox_override("hover", style(Color("#ffdb85") if active else Color("#20465f"), CYAN, 2))
    button.add_theme_stylebox_override("pressed", style(GOLD if active else Color("#295873"), CYAN, 2))
    button.add_theme_stylebox_override("disabled", style(Color("#173047"), Color("#536e87"), 1))
    button.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, CYAN, 3))
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
        button.add_theme_color_override(state, INK if active else WHITE)
    button.add_theme_color_override("font_disabled_color", Color("#a4b7c9"))

static func button(parent: Node, text: String, rect: Rect2, callback: Callable, active := false) -> Button:
    var item := Button.new()
    item.text = text
    item.position = rect.position
    item.size = rect.size
    item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paint(item, active)
    item.pressed.connect(callback)
    parent.add_child(item)
    return item

static func label(parent: Node, text: String, rect: Rect2, font_size := 22, color := WHITE, bold := false) -> Label:
    var item := Label.new()
    item.text = text
    item.position = rect.position
    item.size = rect.size
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    item.add_theme_font_size_override("font_size", font_size)
    item.add_theme_color_override("font_color", color)
    if bold:
        if _bold == null:
            _bold = FontVariation.new()
            _bold.base_font = ThemeDB.fallback_font
            _bold.variation_embolden = 0.6
        item.add_theme_font_override("font", _bold)
    parent.add_child(item)
    item.size = rect.size
    return item

static func panel(parent: Node, rect: Rect2, color: Color, radius := 22) -> Panel:
    var item := Panel.new()
    item.position = rect.position
    item.size = rect.size
    item.mouse_filter = Control.MOUSE_FILTER_IGNORE
    item.add_theme_stylebox_override("panel", style(color, Color(0.48, 0.77, 0.84, 0.38), 1, radius))
    parent.add_child(item)
    return item

static func register_translations() -> void:
    if _translations_registered:
        return
    var catalogs := {
        "en": preload("res://i18n/en.gd").MESSAGES,
        "es": preload("res://i18n/es.gd").MESSAGES
    }
    for locale in catalogs:
        var translation := Translation.new()
        translation.locale = locale
        for key in catalogs[locale]:
            translation.add_message(key, catalogs[locale][key])
        TranslationServer.add_translation(translation)
    _translations_registered = true
