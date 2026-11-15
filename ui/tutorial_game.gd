extends "res://ui/live_game.gd"
## Reuses the real world, HUD, drawers, placement, ice routing and timed actions.
signal lesson_action(action: String, payload: Dictionary)
var lesson_state: Node
var training_alert := false
func _gs() -> Node: return lesson_state
func _offer_tour() -> void: pass
func _show_coach(id: String) -> void: _perform_station(id)
func _check_resource_alerts() -> void: pass
func _maybe_show_reward() -> void: pass
func _tick_fallback_simulation(_delta: float) -> void:
    if lesson_state.en_partida: _tick_robot_energy(lesson_state,_delta)
    var environment := mundo.get_node_or_null("Ambiente")
    if environment != null and environment.has_method("set_solar_time"):
        environment.set_solar_time(lesson_state.tiempo_juego)
func _on_drawer_action(target: String, payload: Dictionary) -> void:
    if target == "guide_alert":
        lesson_action.emit(target,payload)
        return
    if target == "return_home":
        lesson_action.emit("leave",{})
        return
    super._on_drawer_action(target,payload)
    lesson_action.emit(target,payload)
func _on_dock_action(id: String) -> void:
    super._on_dock_action(id)
    lesson_action.emit("dock",{"id":id})
func _on_resource_pressed(_id: String) -> void: pass

func _refresh_storm_banner() -> void:
    if training_alert: _hud.set_storm_alert(true,tr("hud.agua.nombre"),tr("tutorial.alert_body"))
    else: super._refresh_storm_banner()

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(_toast_panel):
        _toast_label.position = Vector2(16,8)
        _toast_label.size.x = 420
        var text_height := maxf(40,_toast_label.get_minimum_size().y)
        _toast_label.size.y = text_height
        _toast_panel.position = Vector2(414,132)
        _toast_panel.size = Vector2(452,text_height+16)
    if DisplayServer.get_name() == "headless" and _session_ready and not _landing_active:
        _tick_fallback_simulation(delta)
        _tick_expedition(delta)

func _refresh_world_callouts() -> void:
    super._refresh_world_callouts()
    # Timmy already explains click-to-place and right-click/Esc cancellation.
    # Keep the expedition interface unchanged; hide this duplicate card only in training.
    if is_instance_valid(_place_callout): _place_callout.hide()
