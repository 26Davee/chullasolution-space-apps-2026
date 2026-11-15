extends Node
## Read-only UI adapter. P1/P2/P5 remain owners of simulation and saves.
signal state_changed(state: Dictionary)
signal recovery_requested(policy: String, profile: Dictionary)
signal panel_requested(section: String)
signal start_requested(profile: Dictionary)
signal tutorial_message(step_index: int, translation_key: String)
signal content_changed()
signal upgrade_requested(id: String)

const Profile = preload("res://ui/player_profile.gd")
const RESOURCE_IDS := ["energia", "agua", "oxigeno", "escudo"]
const INITIAL := {
    "energia": {"value": 60.0, "max": 100.0},
    "energia_robot": {"value": 100.0, "max": 100.0},
    "agua": {"value": 20.0, "max": 100.0},
    "oxigeno": {"value": 45.0, "max": 100.0},
    "escudo": {"value": 100.0, "max": 100.0},
    "hielo": 0, "estrellas": 0, "herramienta_nivel": 1, "es_dia": true, "tiempo_juego": 0.0,
    "descansando_en_domo": false, "nube_activa": false, "alerta_nube": false, "modo_juego": "cadete"
}
@export var state_path := NodePath("/root/GameState")
var training := true
var _live: Dictionary = INITIAL.duplicate(true)
var _profile: Dictionary = {}
var _panels: Dictionary = {}
var _bus: Node
var _zero_handled := false
var _progression := {"current_mission": "", "completed_missions": [], "unlocked_upgrades": []}

func _ready() -> void:
    name = "GameBridge"
    _try_bind()
    var timer := Timer.new()
    timer.wait_time = 1.0
    timer.timeout.connect(_try_bind)
    add_child(timer)
    timer.start()

func configure_profile(profile: Dictionary) -> void:
    _profile = profile.duplicate(true)

func get_state() -> Dictionary:
    return INITIAL.duplicate(true) if training else _live.duplicate(true)

func begin_live(profile: Dictionary) -> void:
    configure_profile(profile)
    training = false
    state_changed.emit(get_state())
    _check_failure()

func bind_state(bus: Node) -> void:
    if bus == _bus:
        return
    _disconnect_bus()
    _bus = bus
    if not is_instance_valid(_bus):
        return
    for signal_name in _bindings():
        if _bus.has_signal(signal_name):
            var callback: Callable = _bindings()[signal_name]
            if not _bus.is_connected(signal_name, callback):
                _bus.connect(signal_name, callback)
    _read_snapshot()

func _bindings() -> Dictionary:
    return {
        "recurso_actualizado": receive_resource,
        "robot_energia_actualizada": receive_robot_energy,
        "estrellas_actualizadas": receive_stars,
        "ciclo_solar_cambiado": receive_day,
        "mision_completada": _mission_completed,
        "mejora_desbloqueada": _upgrade_changed
    }

func _disconnect_bus() -> void:
    if is_instance_valid(_bus):
        for signal_name in _bindings():
            var callback: Callable = _bindings()[signal_name]
            if _bus.has_signal(signal_name) and _bus.is_connected(signal_name, callback):
                _bus.disconnect(signal_name, callback)
    _bus = null

func _try_bind() -> void:
    if is_instance_valid(_bus):
        if not training and "tiempo_juego" in _bus:
            receive_clock(float(_bus.get("tiempo_juego")))
        if not training and "dia_mision" in _bus and "minutos_mision" in _bus:
            receive_mission_clock(int(_bus.get("dia_mision")), int(_bus.get("minutos_mision")))
        if not training:
            for k in ["descansando_en_domo", "nube_activa", "alerta_nube", "modo_juego"]:
                if k in _bus:
                    _live[k] = _bus.get(k)
        return
    var candidate := get_node_or_null(state_path)
    if candidate == null and state_path == NodePath("/root/GameState"):
        candidate = get_node_or_null("/root/GlobalBus")
    if candidate != null:
        bind_state(candidate)

func _read_snapshot() -> void:
    for id in RESOURCE_IDS:
        if id in _bus:
            var maximum := 100.0
            if id == "energia" and "bateria_instalada" in _bus and _bus.get("bateria_instalada"):
                maximum = 150.0
            receive_resource(id, float(_bus.get(id)), maximum)
    if "energia_robot" in _bus:
        receive_robot_energy(float(_bus.get("energia_robot")), 100.0)
    for key in ["hielo", "herramienta_nivel", "estrellas", "es_dia", "tiempo_juego", "dia_mision", "minutos_mision", "descansando_en_domo", "nube_activa", "alerta_nube", "modo_juego"]:
        if key in _bus:
            _live[key] = _bus.get(key)
    if not training:
        state_changed.emit(get_state())

func receive_robot_energy(value: float, maximum: float = 100.0) -> void:
    if not is_finite(value) or not is_finite(maximum) or maximum <= 0:
        return
    _live["energia_robot"] = {"value": clampf(value, 0.0, maximum), "max": maximum}
    if not training:
        state_changed.emit(get_state())

func receive_resource(id: String, value: float, maximum: float) -> void:
    if not is_finite(value) or not is_finite(maximum) or maximum <= 0:
        return
    if id in RESOURCE_IDS:
        _live[id] = {"value": clampf(value, 0.0, maximum), "max": maximum}
    elif id == "hielo":
        _live.hielo = maxi(0, int(value))
    else:
        return
    if not training:
        state_changed.emit(get_state())
        if id == "energia" or id == "oxigeno":
            _check_failure()

func receive_stars(total: int) -> void:
    _live.estrellas = maxi(total, 0)
    if not training:
        state_changed.emit(get_state())

func receive_day(day: bool) -> void:
    _live.es_dia = day
    if not training:
        state_changed.emit(get_state())

func receive_clock(seconds: float) -> void:
    if is_finite(seconds) and seconds >= 0 and _live.tiempo_juego != seconds:
        _live.tiempo_juego = seconds
        if not training:
            state_changed.emit(get_state())

func receive_mission_clock(day: int, minutes: int) -> void:
    if day >= 1:
        _live.dia_mision = day
        _live.minutos_mision = posmod(minutes, 1440)
        if not training: state_changed.emit(get_state())

func _check_failure() -> void:
    var energy := float(_live.energia.value)
    var oxygen := float(_live.oxigeno.value)
    if energy > 0.0 and oxygen > 0.0:
        _zero_handled = false
        return
    var policy := Profile.recovery_for(str(_profile.get("mode", "")))
    if not _zero_handled and not policy.is_empty():
        _zero_handled = true
        recovery_requested.emit(policy, _profile.duplicate(true))

func register_panel(section: String, scene: PackedScene) -> void:
    if scene == null:
        _panels.erase(section)
    else:
        _panels[section] = scene

func instantiate_panel(section: String) -> Control:
    if not _panels.has(section):
        return null
    var scene: PackedScene = _panels[section]
    var instance := scene.instantiate()
    if not instance is Control:
        instance.free()
        push_warning("P6 panel must have a Control root: " + section)
        return null
    if training and not instance.has_method("set_tutorial_mode"):
        instance.free()
        push_warning("P6 practice view requires set_tutorial_mode(bool): " + section)
        return null
    if instance.has_method("set_tutorial_mode"):
        instance.call("set_tutorial_mode", training)
    return instance as Control

func request_panel(section: String) -> void:
    panel_requested.emit(section)

func request_start(profile: Dictionary) -> void:
    configure_profile(profile)
    start_requested.emit(profile.duplicate(true))
    # P1 starts/unpauses the real game. No global state is changed here.

func report_tutorial_step(index: int, key: String) -> void:
    tutorial_message.emit(index, key)
    if is_instance_valid(_bus) and _bus.has_signal("vicuna_mensaje_mostrado"):
        _bus.emit_signal("vicuna_mensaje_mostrado", index, key)

func _mission_completed(id: String, _reward: int, _card: Dictionary) -> void:
    if not id in _progression.completed_missions:
        _progression.completed_missions.append(id)
    content_changed.emit()

func _upgrade_changed(id: String, _branch: String, _level: int) -> void:
    if not id in _progression.unlocked_upgrades:
        _progression.unlocked_upgrades.append(id)
    _read_snapshot()
    content_changed.emit()

func _exit_tree() -> void:
    _disconnect_bus()

func get_progression_state() -> Dictionary:
    if training:
        return {"current_mission": "mision_01", "completed_missions": [], "unlocked_upgrades": [], "stars": 0}
    var result := _progression.duplicate(true)
    result["stars"] = int(_live.estrellas)
    return result

func set_progression_state(state: Dictionary) -> void:
    for key in ["current_mission", "completed_missions", "unlocked_upgrades"]:
        if state.has(key):
            _progression[key] = state[key].duplicate() if state[key] is Array else state[key]
    content_changed.emit()

func request_upgrade(id: String) -> void:
    if not training:
        upgrade_requested.emit(id)
