extends SceneTree
## UI regressions from the team's screenshots; practice state stays isolated.
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error(message)
func frames(n := 6) -> void:
    for i in n: await process_frame
func contrast(a: Color, b: Color) -> float:
    var x := a.srgb_to_linear().get_luminance()
    var y := b.srgb_to_linear().get_luminance()
    return (maxf(x,y)+0.05)/(minf(x,y)+0.05)
func check_dialogue(lesson: Control) -> void:
    var label: Label = lesson.dialogue_label
    var footer_y: float = lesson.primary_button.position.y
    check(label.position.y+label.size.y <= footer_y-8,"Timmy text stays above buttons: "+lesson.language+" "+lesson.step)
    check(label.get_minimum_size().y <= label.size.y+1,"Full paragraph fits: "+lesson.language+" "+lesson.step)
    if lesson.game._toast_panel.visible:
        check(not lesson.game._toast_panel.get_global_rect().intersects(lesson.bubble.get_global_rect()),"Game feedback does not appear behind Timmy")
    check(lesson.bubble.position.y >= 190 and lesson.bubble.get_rect().end.y <= 630,"Dialogue leaves the resource card and dock visible")
func check_drawer(drawer: Panel, locale: String) -> void:
    var edge := drawer.get_global_rect().end.x
    check(edge <= 1265,"Drawer stays inside the screen: "+locale+" "+drawer.kind)
    check(drawer._footer.get_global_rect().end.x <= edge-8,"Footer fits in its drawer: "+locale+" "+drawer.kind)
    for button in drawer._footer.get_children():
        if button is Button:
            var rect: Rect2 = button.get_global_rect()
            check(rect.position.x >= drawer.global_position.x+8 and rect.end.x <= edge-8,"Footer button is fully inside: "+locale+" "+button.text)
            check(rect.end.y <= drawer.get_global_rect().end.y-2,"Footer button fits vertically: "+locale+" "+button.text)
    for node in drawer._content.find_children("*","Control",true,false):
        if not node.is_visible_in_tree(): continue
        if node is ScrollBar: continue
        var rect: Rect2 = node.get_global_rect()
        check(rect.end.x <= edge-8,"Content does not overflow horizontally: "+locale+" "+drawer.kind+" "+node.get_class())
    if drawer.kind == "upgrades":
        var branch: String = drawer.Catalog.text("branches."+drawer._selected_branch,drawer._selected_branch)
        for button in drawer._content.find_children("*","Button",true,false):
            if button.text != branch: continue
            var color: Color = button.get_theme_color("font_color")
            var box = button.get_theme_stylebox("normal")
            check(contrast(color,box.bg_color) >= 4.5,"Selected upgrade text remains legible: "+locale)
func run() -> void:
    root.size = Vector2i(1280,720)
    await frames()
    root.get_node("GameState").preferencias["voice_enabled"] = false
    for locale in ["en","es"]:
        var lesson = load("res://ui/intro.tscn").instantiate()
        lesson.language = locale
        root.add_child(lesson)
        await frames(10)
        lesson.voice.muted = true
        for id in lesson.STEPS:
            lesson.index = lesson.STEPS.find(id)
            lesson._show_step()
            await frames(2)
            check_dialogue(lesson)
        lesson.index = lesson.STEPS.find("construction")
        lesson._show_step()
        lesson.game._start_build("panel_solar")
        lesson.game._refresh_world_callouts()
        check(lesson.game.placement_system.is_placing() and not lesson.game._place_callout.visible,"Training hides redundant Place/Cancel while preserving the hologram")
        lesson.game.placement_system.cancel_placement()
        lesson.game.ice.discovered = ["crater","ridge","basin"]
        var sm = lesson.state.obtener_save_manager()
        sm.registrar_mision_completada("mision_01",3,"carta_mision_01")
        lesson.game.session.add_message("visual:water","resource",{"resource":"agua"})
        var message: String = lesson.game.message_text({"kind":"resource","data":{"resource":"agua"}})
        check(not message.contains("live.") and message.contains(tr("hud.agua.nombre")),"Resource notice has a translated, meaningful caption")
        # Wide-to-narrow and long-to-short transitions previously retained old minimum widths.
        for section in ["construction","messages","processing","expedition","more","upgrades","settings:language","settings:audio","missions","science","timmy","settings:controls","settings:exit","expedition","processing"]:
            lesson.game._open_section_drawer(section)
            await frames()
            check_drawer(lesson.game._drawer,locale)
        lesson.game._close_drawer()
        for id in ["supplies","recovery","ending"]:
            lesson.index = lesson.STEPS.find(id)
            lesson._show_step()
            await create_timer(1.15).timeout
            await frames()
            check_dialogue(lesson)
            if is_instance_valid(lesson.game._modal_layer):
                var panel: Control = lesson.game._modal_layer.get_child(1)
                for node in lesson.game._modal_layer.get_children():
                    if node is Panel: panel = node; break
                check(not lesson.bubble.get_global_rect().intersects(panel.get_global_rect()),"Timmy leaves the automatic notice clear: "+locale+" "+id)
        lesson.queue_free()
        await frames()
    print("VISUAL FAILURES: ",failures)
    quit(0 if failures.is_empty() else 1)
