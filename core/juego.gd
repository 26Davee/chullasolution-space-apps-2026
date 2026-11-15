extends Node3D

## Escena principal de juego 3D (Killawasi / Base Lunar).
## Une:
## - Cinemática 3D de llegada (world/landing_intro.tscn)
## - Mundo lunar 3D (world/moon_world.tscn) + Robot humanoide + Timmy
## - Cámara orbital (clic derecho), ClickToMove (clic izquierdo) y PlacementSystem 3D
## - Interfaz viva (HUD, misiones, árbol de mejoras, acciones de base, audio e idioma)

signal salir_al_menu

const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const BridgeScript = preload("res://ui/game_bridge.gd")
const CatalogScript = preload("res://ui/progression_catalog.gd")
const VoiceScript = preload("res://ui/timmy_voice.gd")
const SectionMenuScript = preload("res://ui/section_menu.gd")
const MissionListScript = preload("res://ui/mission_list.gd")
const UpgradeTreeScript = preload("res://ui/upgrade_tree.gd")
const VisualActivityScript = preload("res://ui/visual_activity.gd")
const LandingIntroScene = preload("res://world/landing_intro.tscn")

const PIECE_SCENES := {
	&"panel_solar": preload("res://assets/3d/panel_solar.tscn"),
	&"procesador_hielo": preload("res://assets/3d/procesador_hielo.tscn"),
	&"generador_oxigeno": preload("res://assets/3d/generador_oxigeno.tscn"),
	&"jardin": preload("res://assets/3d/jardin_lunar.tscn"),
}

const STRUCTURE_COST := {
	"panel_solar": 10.0,
	"procesador_hielo": 12.0,
	"generador_oxigeno": 15.0,
	"jardin": 18.0,
}
const STRUCTURE_LIMITS := {
	"panel_solar": 2,
	"procesador_hielo": 1,
	"generador_oxigeno": 1,
	"jardin": 1,
}
const EXPEDITION_ICE_CAP := 10
const SPE_STORM_PROFILES := [
	{"id": "moderada", "es": "MODERADA", "en": "MODERATE", "rate": 0.45, "robot_extra": 0.50, "force": 1.0},
	{"id": "fuerte", "es": "FUERTE", "en": "STRONG", "rate": 0.85, "robot_extra": 0.90, "force": 1.4},
	{"id": "severa", "es": "SEVERA", "en": "SEVERE", "rate": 1.40, "robot_extra": 1.40, "force": 2.0},
]

const DAY_CYCLE_SECONDS := 480.0
const DAY_LIGHT_SECONDS := 240.0
const DOME_CENTER := Vector3.ZERO
const DOME_BASE_SCALE := 3.0
const DOME_BASE_INNER_RADIUS := 16.8
const DOME_RECHARGE_RADIUS := 16.0
const EXPANSION_UPGRADES := ["panel_extra", "jardin_lunar"]
const ROBOT_RECHARGE_RATE_PCT_S := 12.5
const BASE_RECHARGE_DRAIN_PCT_S := 0.03764
const SPE_FIRST_STORM_S := 180.0
const SPE_NEXT_INTERVAL_S := 210.0
const SPE_STORM_DURATION_S := 25.0

@onready var mundo: Node3D = $Mundo
@onready var robot: Node3D = $Astronauta
@onready var vicuna: Node3D = $Vicuna
@onready var tormenta: Node3D = $Tormenta
@onready var estructuras_colocadas: Node3D = $EstructurasColocadas
@onready var camara: Camera3D = $Camara
@onready var click_to_move: Node = $ClickToMove
@onready var placement_system: Node = $PlacementSystem
@onready var interfaz: CanvasLayer = $Interfaz

var _bridge: Node
var _catalog: RefCounted
var _voice: Node
var _ui_root: Control
var _hud: Control
var _landing: Node
var _landing_overlay: Control
var _mission_panel: Panel
var _mission_title: Label
var _mission_desc: Label
var _mission_reward: Label
var _storm_badge: Panel
var _storm_label: Label
var _build_tray: Control
var _placement_banner: Panel
var _placement_label: Label
var _toast_panel: Panel
var _toast_label: Label
var _toast_timer: float = 0.0
var _controls_hint: Label
var _cam_button: Button
var _menu_button: Button
var _lang_button: Button
var _audio_button: Button
var _dock_buttons: Dictionary = {}
var _build_buttons: Dictionary = {}
var _modal_layer: Control
var _modal_kind: String = ""
var _progression_view: Control
var _voice_choice: OptionButton
var _audio_status: Label

var _camera_on_robot: bool = true
var _landing_active: bool = false
var _expedition_pending: bool = false
var _expedition_timer: float = 0.0
var _eval_accumulator: float = 0.0
var _pending_build_id: String = ""
var _was_placing: bool = false
var _storm_remaining: float = 0.0
var _storm_count: int = 0
var _storm_warning_emitted: bool = false
var _last_storm_badge_sec: int = -1
var _storm_profile: Dictionary = SPE_STORM_PROFILES[0]
var _next_storm_profile: Dictionary = SPE_STORM_PROFILES[0]
var _gen_overload_timer: float = 0.0
var _gen_overload_cooldown: float = 0.0
var _storm_unlocked_mission_id: String = ""


func _ready() -> void:
	UI.register_translations()
	_sync_locale_from_state()
	_setup_world_and_controls()
	_setup_bridge_and_ui()
	_connect_game_state()
	call_deferred("_post_ready_init")


func _post_ready_init() -> void:
	var gs := _gs()
	if gs != null and not gs.en_partida and DisplayServer.get_name() != "headless":
		gs.iniciar_partida("cadete")
	_sync_all_from_state()
	if DisplayServer.get_name() != "headless":
		_start_landing_cinematic()
	else:
		_activar_camara_juego()


func _sync_locale_from_state() -> void:
	var gs := _gs()
	var lang := str(gs.idioma) if gs != null and "idioma" in gs else "es"
	if lang.is_empty():
		lang = "es"
	TranslationServer.set_locale(lang)


func _setup_world_and_controls() -> void:
	if is_instance_valid(click_to_move):
		click_to_move.set("camara", camara)
		click_to_move.set("placement_system", placement_system)
		var ground := mundo.get_node_or_null("Terreno/Ground")
		if ground != null:
			click_to_move.set("suelo", ground)
		if click_to_move.has_signal("destino_alcanzado"):
			click_to_move.connect("destino_alcanzado", _on_robot_arrived)
		if click_to_move.has_signal("destino_fijado"):
			click_to_move.connect("destino_fijado", _on_robot_started_walk)

	if is_instance_valid(placement_system):
		placement_system.set("camera", camara)
		placement_system.set("placed_parent", estructuras_colocadas)
		var catalog_dict: Dictionary = {}
		for key in PIECE_SCENES:
			catalog_dict[key] = PIECE_SCENES[key]
		placement_system.set("piece_catalog", catalog_dict)
		if placement_system.has_signal("piece_placed"):
			placement_system.connect("piece_placed", _on_piece_placed)
		if placement_system.has_signal("placement_cancelled"):
			placement_system.connect("placement_cancelled", _on_placement_cancelled)

	var vic_poses := vicuna.get_node_or_null("Poses") as AnimationPlayer
	if vic_poses != null and vic_poses.has_animation("respirar"):
		vic_poses.play("respirar")

	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"reposo")


func _setup_bridge_and_ui() -> void:
	_catalog = CatalogScript.new()

	_bridge = BridgeScript.new()
	add_child(_bridge)

	_voice = VoiceScript.new()
	_voice.name = "TimmyVoice"
	add_child(_voice)

	var gs := _gs()
	if gs != null:
		_bridge.bind_state(gs)
		var profile := {
			"name": gs.nombre_astronauta if "nombre_astronauta" in gs else tr("v2.default_name"),
			"mode": gs.modo_juego if "modo_juego" in gs else "cadete",
			"age_group": "7_9" if (gs.modo_juego if "modo_juego" in gs else "cadete") == "cadete" else "10_12",
		}
		_bridge.begin_live(profile)
		if "voz_activa" in gs:
			_voice.muted = not bool(gs.voz_activa)
	else:
		_bridge.begin_live({"name": tr("v2.default_name"), "mode": "cadete", "age_group": "7_9"})

	_bridge.state_changed.connect(_on_bridge_state_changed)
	_bridge.content_changed.connect(_on_bridge_content_changed)
	_bridge.upgrade_requested.connect(_on_upgrade_requested)
	_bridge.recovery_requested.connect(_on_recovery_requested)

	_ui_root = Control.new()
	_ui_root.name = "GameOverlay"
	_ui_root.position = Vector2.ZERO
	_ui_root.size = Vector2(1280, 720)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(_ui_root)

	_build_placement_and_toast()


func _build_side_mission_card() -> void:
	_mission_panel = UI.panel(_ui_root, Rect2(30, 184, 344, 134), Color("#071b32e6"), 16)
	_mission_title = UI.label(_mission_panel, "", Rect2(14, 10, 316, 26), 16, UI.GOLD, true)
	_mission_desc = UI.label(_mission_panel, "", Rect2(14, 38, 316, 62), 14, UI.WHITE)
	_mission_reward = UI.label(_mission_panel, "", Rect2(14, 102, 316, 24), 14, UI.CYAN, true)

	_storm_badge = UI.panel(_ui_root, Rect2(30, 326, 344, 40), Color("#631b1bee"), 12)
	_storm_badge.visible = false
	_storm_label = UI.label(_storm_badge, "", Rect2(12, 6, 320, 28), 15, Color("#ffd1b8"), true)


func _build_top_toolbar() -> void:
	_menu_button = UI.button(_ui_root, tr("menu.title"), Rect2(1078, 184, 172, 42), _open_section_menu, true)
	_menu_button.add_theme_font_size_override("font_size", 16)

	_cam_button = UI.button(_ui_root, "", Rect2(910, 184, 158, 42), _toggle_camera_target)
	_cam_button.add_theme_font_size_override("font_size", 15)

	_audio_button = UI.button(_ui_root, tr("v2.settings"), Rect2(812, 184, 88, 42), _open_audio_modal)
	_audio_button.add_theme_font_size_override("font_size", 15)

	_lang_button = UI.button(_ui_root, _lang_label(), Rect2(738, 184, 64, 42), _toggle_language)
	_lang_button.add_theme_font_size_override("font_size", 15)

	_update_cam_button_label()


func _build_bottom_dock() -> void:
	_build_tray = UI.panel(_ui_root, Rect2(160, 578, 960, 56), Color("#071b32f0"), 14)
	_build_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_tray.visible = false
	_build_buttons.clear()
	var modules := ["panel_solar", "procesador_hielo", "generador_oxigeno", "jardin"]
	for i in range(modules.size()):
		var mid: String = modules[i]
		var btn := UI.button(_build_tray, "", Rect2(12 + i * 235, 8, 226, 40), _start_build.bind(mid))
		btn.add_theme_font_size_override("font_size", 12)
		_build_buttons[mid] = btn
	_refresh_build_tray_labels()

	var dock := UI.panel(_ui_root, Rect2(60, 644, 1160, 58), Color("#071b32eb"), 16)
	dock.mouse_filter = Control.MOUSE_FILTER_STOP
	var items := [
		["construction", "actions.construction"],
		["expedition", "actions.expedition"],
		["rest", "actions.rest"],
		["processing", "actions.processing"],
		["repair", "actions.repair"],
		["missions", "actions.missions"],
		["upgrades", "actions.upgrades"],
		["science", "actions.science"],
	]
	var width := 133
	var gap := 8
	for i in range(items.size()):
		var id: String = items[i][0]
		var key: String = items[i][1]
		var btn := UI.button(dock, tr(key), Rect2(10 + i * (width + gap), 8, width, 42), _on_dock_action.bind(id), i == 0)
		btn.add_theme_font_size_override("font_size", 14)
		_dock_buttons[id] = btn

	_controls_hint = UI.label(_ui_root, "", Rect2(30, 616, 1220, 22), 13, Color("#c7dce9"))
	_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refresh_controls_hint()


func _build_placement_and_toast() -> void:
	_placement_banner = UI.panel(_ui_root, Rect2(320, 184, 640, 42), Color("#0a2946f2"), 12)
	_placement_banner.visible = false
	_placement_label = UI.label(_placement_banner, "", Rect2(14, 7, 612, 28), 15, UI.GOLD, true)
	_placement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_toast_panel = UI.panel(_ui_root, Rect2(370, 520, 540, 48), Color("#09213af2"), 14)
	_toast_panel.visible = false
	_toast_label = UI.label(_toast_panel, "", Rect2(14, 8, 512, 32), 15, UI.WHITE, true)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _connect_game_state() -> void:
	var gs := _gs()
	if gs == null:
		return
	_connect_if_missing(gs, "partida_iniciada", _on_partida_iniciada)
	_connect_if_missing(gs, "ciclo_solar_cambiado", _on_ciclo_solar_cambiado)
	_connect_if_missing(gs, "advertencia_nube_iniciada", _on_advertencia_nube)
	_connect_if_missing(gs, "nube_impacto", _on_nube_impacto)
	_connect_if_missing(gs, "nube_finalizada", _on_nube_finalizada)
	_connect_if_missing(gs, "mision_completada", _on_mision_completada)
	_connect_if_missing(gs, "mejora_desbloqueada", _on_mejora_desbloqueada)
	_connect_if_missing(gs, "recurso_actualizado", _on_recurso_actualizado)


func _connect_if_missing(obj: Object, sig: StringName, cb: Callable) -> void:
	if obj.has_signal(sig) and not obj.is_connected(sig, cb):
		obj.connect(sig, cb)


func _start_landing_cinematic() -> void:
	if _landing_active or LandingIntroScene == null:
		_activar_camara_juego()
		return
	_landing_active = true
	_set_gameplay_input_enabled(false)
	_set_world_nodes_visible(false)
	_ui_root.visible = false

	_landing = LandingIntroScene.instantiate()
	add_child(_landing)
	if _landing.has_signal("completed"):
		_landing.connect("completed", _on_landing_completed)

	_landing_overlay = Control.new()
	_landing_overlay.size = Vector2(1280, 720)
	_landing_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(_landing_overlay)

	var pill := UI.panel(_landing_overlay, Rect2(320, 620, 640, 68), Color("#071b32eb"), 18)
	pill.mouse_filter = Control.MOUSE_FILTER_STOP
	UI.label(pill, tr("v2.landing"), Rect2(20, 10, 380, 26), 18, UI.GOLD, true)
	UI.label(pill, tr("intro.landing"), Rect2(20, 36, 380, 22), 14, UI.WHITE)
	var skip_btn := UI.button(pill, tr("v2.skip"), Rect2(420, 12, 200, 44), _skip_landing, true)
	skip_btn.add_theme_font_size_override("font_size", 15)


func _skip_landing() -> void:
	if is_instance_valid(_landing):
		if _landing.has_method("_finish"):
			_landing.call("_finish")
		else:
			_on_landing_completed()


func _on_landing_completed() -> void:
	if not _landing_active:
		return
	_landing_active = false
	if is_instance_valid(_landing):
		_landing.queue_free()
		_landing = null
	if is_instance_valid(_landing_overlay):
		_landing_overlay.queue_free()
		_landing_overlay = null

	_set_world_nodes_visible(true)
	_ui_root.visible = true
	_activar_camara_juego()
	_set_gameplay_input_enabled(true)

	var acceso := mundo.get_node_or_null("Capsula/Acceso") as AnimationPlayer
	if acceso != null and acceso.has_animation("abrir"):
		acceso.play("abrir")

	_show_toast(tr("v2.arrival"), 3.2)


func _set_world_nodes_visible(flag: bool) -> void:
	if is_instance_valid(mundo):
		mundo.visible = flag
	if is_instance_valid(robot):
		robot.visible = flag
	if is_instance_valid(vicuna):
		vicuna.visible = flag
	if is_instance_valid(estructuras_colocadas):
		estructuras_colocadas.visible = flag
	if is_instance_valid(tormenta) and not flag:
		tormenta.visible = false


func _set_gameplay_input_enabled(enabled: bool) -> void:
	if is_instance_valid(camara):
		camara.set_process_unhandled_input(enabled)
		camara.set_process(enabled)
	if is_instance_valid(click_to_move):
		click_to_move.set_process_unhandled_input(enabled)
		click_to_move.set_physics_process(enabled)


func _activar_camara_juego() -> void:
	if is_instance_valid(camara):
		camara.make_current()
		if camara.has_method("reiniciar"):
			camara.call("reiniciar")


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and is_instance_valid(_toast_panel):
			_toast_panel.visible = false

	if _landing_active:
		return

	var placing: bool = is_instance_valid(placement_system) and placement_system.has_method("is_placing") and bool(placement_system.call("is_placing"))
	if placing != _was_placing:
		_was_placing = placing
		_update_placement_banner(placing)

	if DisplayServer.get_name() == "headless":
		return

	_tick_fallback_simulation(delta)
	_tick_expedition(delta)


var _dome_tween: Tween
var _dome_target_scale: float = DOME_BASE_SCALE


func _dome_world_pos() -> Vector3:
	if is_instance_valid(mundo):
		var domo := mundo.get_node_or_null("Domo") as Node3D
		if domo != null:
			return domo.global_position
	return DOME_CENTER


func _dome_expansion_steps() -> int:
	var steps := 0
	for uid in EXPANSION_UPGRADES:
		if _has_upgrade(uid):
			steps += 1
	return steps


func _dome_expansion_scale() -> float:
	var s := DOME_BASE_SCALE
	for _i in range(_dome_expansion_steps()):
		s = s + (s * 1.25)
	return s


func _dome_factor() -> float:
	return _dome_expansion_scale() / DOME_BASE_SCALE


func _dome_recharge_radius() -> float:
	return DOME_RECHARGE_RADIUS * _dome_factor()


func _sync_dome_scale(animate: bool = false) -> void:
	var target_scale := _dome_expansion_scale()
	var factor := target_scale / DOME_BASE_SCALE
	if is_instance_valid(placement_system):
		placement_system.set("dome_inner_radius", DOME_BASE_INNER_RADIUS * factor)
	if is_instance_valid(camara):
		camara.set("distancia_max", maxf(62.0, 62.0 * factor))
	if is_instance_valid(tormenta):
		tormenta.scale = Vector3.ONE * factor
	if is_instance_valid(mundo):
		var terreno := mundo.get_node_or_null("Terreno") as Node3D
		if terreno != null:
			terreno.scale = Vector3(factor, 1.0, factor)
		var crater := mundo.get_node_or_null("CraterHielo") as Node3D
		if crater != null:
			crater.position = Vector3(-21.0, 0.0, 14.0) * factor
		var ice_node: Node = get("ice") as Node
		if ice_node != null and ice_node.has_method("sync_zone_positions"):
			ice_node.call("sync_zone_positions")
		var domo := mundo.get_node_or_null("Domo") as Node3D
		if domo != null:
			var target_vec := Vector3.ONE * target_scale
			if animate and is_inside_tree() and not is_equal_approx(_dome_target_scale, target_scale):
				_dome_target_scale = target_scale
				if is_instance_valid(_dome_tween):
					_dome_tween.kill()
				_dome_tween = create_tween()
				_dome_tween.tween_property(domo, "scale", target_vec, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			elif not (is_instance_valid(_dome_tween) and _dome_tween.is_running() and is_equal_approx(_dome_target_scale, target_scale)):
				_dome_target_scale = target_scale
				domo.scale = target_vec


func _robot_distance_to_dome() -> float:
	if not is_instance_valid(robot):
		return _dome_recharge_radius() + 1.0
	var r := robot.global_position
	var d := _dome_world_pos()
	return Vector2(r.x, r.z).distance_to(Vector2(d.x, d.z))


func _set_robot_resting(gs: Node, active: bool) -> void:
	if gs == null:
		return
	if gs.has_method("fijar_descanso_domo"):
		gs.call("fijar_descanso_domo", active)
	else:
		gs.descansando_en_domo = active


func _sync_bridge_telemetry(gs: Node) -> void:
	if is_instance_valid(_bridge) and gs != null:
		_bridge.call("_read_snapshot")


func _tick_fallback_simulation(delta: float) -> void:
	var gs := _gs()
	if gs == null or not gs.en_partida or is_instance_valid(_modal_layer):
		return
	if gs.has_method("hay_simulacion") and gs.call("hay_simulacion"):
		return

	if float(gs.tiempo_juego) < 0.05 and float(gs.tiempo_para_nube) <= 0.0 and not gs.nube_activa:
		gs.tiempo_para_nube = SPE_FIRST_STORM_S

	var prev_day := bool(gs.es_dia)
	var phase := fmod(gs.tiempo_juego, DAY_CYCLE_SECONDS)
	gs.tiempo_ciclo_solar = phase
	var now_day := phase < DAY_LIGHT_SECONDS
	if now_day != prev_day:
		gs.es_dia = now_day
		gs.ciclo_solar_cambiado.emit(now_day)

	if is_instance_valid(_bridge) and int(floor(gs.tiempo_juego * 4.0)) != int(floor((gs.tiempo_juego - delta) * 4.0)):
		_bridge.call("receive_clock", gs.tiempo_juego)

	var diff := 0.75 if str(gs.modo_juego) == "cadete" else 1.0
	var gen_eff := 0.70 if _has_upgrade("generador_eficiente") else 1.0
	var moving := is_instance_valid(click_to_move) and bool(click_to_move.get("_moviendo"))
	var near_dome := _robot_distance_to_dome() <= _dome_recharge_radius()

	# --- 1. Base Total Energy (2,000 kWh = 100%) ---
	var base_energy_delta := (-0.2339 if gs.es_dia else -0.3483) * diff
	if gs.es_dia and int(gs.paneles_instalados) > 0:
		var boost := 1.25 if _has_upgrade("celulas_optimizadas") else 1.0
		# Cada módulo solar de 25 m² (9.87 kW NASA) aporta 14.569 kWh/s = +0.7285 %/s al banco de 2,000 kWh.
		base_energy_delta += 0.7285 * float(gs.paneles_instalados) * boost

	# OGA cyclic operation + Garden LED + 4-human O2 (50 kg = 100%) / 200 L H2O balance
	if _gen_overload_timer > 0.0:
		_gen_overload_timer = maxf(0.0, _gen_overload_timer - delta)
	if _gen_overload_cooldown > 0.0:
		_gen_overload_cooldown = maxf(0.0, _gen_overload_cooldown - delta)
	if gs.generador_instalado and float(gs.escudo) <= 0.0 and _gen_overload_timer <= 0.0 and _gen_overload_cooldown <= 0.0:
		_gen_overload_timer = 10.0
		_gen_overload_cooldown = 25.0
		_show_toast(_msg(
			"¡Sobrecarga por escudo roto! Generador de O₂ pausado 10s.",
			"Shield failure overload! Oxygen Generator paused 10s."
		), 3.2)

	var o2_delta := -0.4184 * diff
	var water_delta := -0.1846 * diff
	if float(gs.escudo) <= 10.0:
		o2_delta -= 0.25 * diff
	if gs.generador_instalado and _gen_overload_timer <= 0.0 and float(gs.agua) > 0.0 and float(gs.oxigeno) < 99.5:
		base_energy_delta -= 0.2144 * gen_eff * diff
		water_delta -= 0.3204 * gen_eff * diff
		o2_delta += 1.1382
	if gs.jardin_instalado and float(gs.agua) > 0.0:
		base_energy_delta -= 0.1846 * diff
		water_delta -= 0.020 * diff
		o2_delta += 0.0370

	gs.cambiar_recurso("energia", base_energy_delta * delta)
	gs.cambiar_recurso("agua", water_delta * delta)
	gs.cambiar_recurso("oxigeno", o2_delta * delta)

	# --- 2. Robot Own Battery (5.42 kWh = 100%) & Dome Recharge ---
	if bool(gs.descansando_en_domo):
		if not near_dome or moving:
			_set_robot_resting(gs, false)
			_refresh_dock_states()
			_sync_bridge_telemetry(gs)
		elif float(gs.energia_robot) >= 99.95 or float(gs.energia) <= 0.05:
			var full := float(gs.energia_robot) >= 99.95
			_set_robot_resting(gs, false)
			_refresh_dock_states()
			_sync_bridge_telemetry(gs)
			if full:
				_show_toast(_msg("Batería del robot al 100% ✓", "Robot battery charged to 100% ✓"), 2.4)
		else:
			var gain := minf(ROBOT_RECHARGE_RATE_PCT_S * delta, 100.0 - float(gs.energia_robot))
			var base_cost := BASE_RECHARGE_DRAIN_PCT_S * (gain / ROBOT_RECHARGE_RATE_PCT_S)
			gs.cambiar_energia_robot(gain)
			gs.cambiar_recurso("energia", -base_cost)
	else:
		var tool_lvl := int(gs.herramienta_nivel)
		var move_drain := 3.5
		if tool_lvl >= 4:
			move_drain = 1.6
		elif tool_lvl == 3:
			move_drain = 2.2
		elif tool_lvl == 2:
			move_drain = 2.8
		if moving:
			var storm_extra := float(_storm_profile.get("robot_extra", 0.8)) if (bool(gs.nube_activa) and not near_dome) else 0.0
			gs.cambiar_energia_robot(-(move_drain + storm_extra) * delta)
			if float(gs.energia_robot) <= 0.0 and is_instance_valid(click_to_move):
				click_to_move.set("_moviendo", false)
				_refresh_dock_states()
				_show_toast(_msg(
					"¡Batería del robot agotada! Recarga con el sol o en el Domo.",
					"Robot battery empty! Recharge via sunlight or at the Dome."
				), 3.0)
		else:
			var idle_delta := -0.05 if not near_dome else 0.0
			if gs.es_dia and float(gs.energia_robot) < 100.0:
				idle_delta += 0.60
			if not is_zero_approx(idle_delta):
				gs.cambiar_energia_robot(idle_delta * delta)

	# --- 3. Solar Storms (SPE / LRO CRaTER) & Dome Shield (desde mision_08+) ---
	var shield_res := 0.72 if _has_upgrade("mas_resistencia") else 1.0
	var storms_unlocked := _storms_unlocked_for_mission(gs)
	if not storms_unlocked and not bool(gs.nube_activa):
		if bool(gs.alerta_nube):
			gs.alerta_nube = false
			_storm_warning_emitted = false
			_sync_bridge_telemetry(gs)
		if is_instance_valid(_storm_badge):
			_storm_badge.visible = false
	elif bool(gs.nube_activa):
		_storm_remaining -= delta
		var storm_drain := float(_storm_profile.get("rate", 0.45)) * diff * shield_res
		gs.cambiar_recurso("escudo", -storm_drain * delta)
		var sec_rem := maxi(0, int(ceil(_storm_remaining)))
		if is_instance_valid(_storm_badge) and sec_rem != _last_storm_badge_sec:
			_last_storm_badge_sec = sec_rem
			_storm_badge.visible = true
			var sev_name := str(_storm_profile.get("es" if TranslationServer.get_locale().begins_with("es") else "en", "MODERADA"))
			_storm_label.text = _msg(
				"⚠ Tormenta %s (%ds) · Escudo %d%%" % [sev_name, sec_rem, int(round(gs.escudo))],
				"⚠ %s storm (%ds) · Shield %d%%" % [sev_name, sec_rem, int(round(gs.escudo))]
			)
		if _storm_remaining <= 0.0:
			gs.nube_activa = false
			gs.alerta_nube = false
			gs.tiempo_para_nube = SPE_NEXT_INTERVAL_S
			_storm_warning_emitted = false
			_last_storm_badge_sec = -1
			if is_instance_valid(_storm_badge):
				_storm_badge.visible = false
			gs.nube_finalizada.emit()
			_sync_bridge_telemetry(gs)
	else:
		gs.cambiar_recurso("escudo", -0.015 * diff * delta)
		gs.tiempo_para_nube = maxf(0.0, float(gs.tiempo_para_nube) - delta)
		if float(gs.tiempo_para_nube) <= 25.0 and float(gs.tiempo_para_nube) > 0.0:
			if not _storm_warning_emitted:
				_next_storm_profile = _pick_storm_profile(_storm_count)
				_storm_warning_emitted = true
				gs.advertencia_nube_iniciada.emit(float(gs.tiempo_para_nube))
			if not bool(gs.alerta_nube):
				gs.alerta_nube = true
				_sync_bridge_telemetry(gs)
			var sec_warn := maxi(1, int(ceil(gs.tiempo_para_nube)))
			if is_instance_valid(_storm_badge) and sec_warn != _last_storm_badge_sec:
				_last_storm_badge_sec = sec_warn
				_storm_badge.visible = true
				var next_sev := str(_next_storm_profile.get("es" if TranslationServer.get_locale().begins_with("es") else "en", "MODERADA"))
				_storm_label.text = _msg(
					"⚠ Alerta tormenta %s en %ds" % [next_sev, sec_warn],
					"⚠ %s storm alert in %ds" % [next_sev, sec_warn]
				)
		elif float(gs.tiempo_para_nube) <= 0.0:
			gs.alerta_nube = false
			gs.nube_activa = true
			_storm_profile = _next_storm_profile
			_storm_count += 1
			_storm_remaining = SPE_STORM_DURATION_S
			_last_storm_badge_sec = -1
			var fuerza := float(_storm_profile.get("force", 1.0))
			gs.nube_impacto.emit(fuerza, float(gs.escudo))
			_sync_bridge_telemetry(gs)
		else:
			if bool(gs.alerta_nube):
				gs.alerta_nube = false
				_sync_bridge_telemetry(gs)
			_storm_warning_emitted = false
			_last_storm_badge_sec = -1
			if is_instance_valid(_storm_badge):
				_storm_badge.visible = false


func _reset_storm_ui_state() -> void:
	_storm_remaining = 0.0
	_storm_warning_emitted = false
	_last_storm_badge_sec = -1
	if is_instance_valid(_storm_badge):
		_storm_badge.visible = false
	if is_instance_valid(_storm_label):
		_storm_label.text = ""
	if is_instance_valid(_bridge) and _gs() != null:
		_sync_bridge_telemetry(_gs())



func _tick_expedition(delta: float) -> void:
	if not _expedition_pending or _gs() == null or not _gs().en_partida:
		return
	_expedition_timer -= delta
	if _expedition_timer > 0.0:
		return
	_expedition_pending = false
	_finish_local_expedition()


func _unhandled_input(event: InputEvent) -> void:
	if _landing_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_toggle_camera_target()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if is_instance_valid(_modal_layer):
				_close_modal()
			elif is_instance_valid(_build_tray) and _build_tray.visible:
				_build_tray.visible = false
				_refresh_dock_states()
			else:
				_open_section_menu()
			get_viewport().set_input_as_handled()


func _toggle_camera_target() -> void:
	_camera_on_robot = not _camera_on_robot
	if not is_instance_valid(camara):
		return
	var domo := mundo.get_node_or_null("Domo") as Node3D
	camara.set("objetivo", robot if (_camera_on_robot or domo == null) else domo)
	if camara.has_method("reiniciar"):
		camara.call("reiniciar")
	_update_cam_button_label()


func _update_cam_button_label() -> void:
	if not is_instance_valid(_cam_button):
		return
	var is_es := TranslationServer.get_locale().begins_with("es")
	if _camera_on_robot:
		_cam_button.text = "Cam: Robot (C)"
	else:
		_cam_button.text = "Cam: Base (C)" if is_es else "Cam: Base (C)"


func _structure_limit(id_estructura: String) -> int:
	if id_estructura == "panel_solar":
		return 3 if _has_upgrade("panel_extra") else int(STRUCTURE_LIMITS.get("panel_solar", 2))
	return int(STRUCTURE_LIMITS.get(id_estructura, 1))


func _structure_count(gs: Node, id_estructura: String) -> int:
	if gs == null:
		return 0
	match id_estructura:
		"panel_solar":
			return int(gs.paneles_instalados)
		"procesador_hielo":
			return 1 if bool(gs.procesador_instalado) else 0
		"generador_oxigeno":
			return 1 if bool(gs.generador_instalado) else 0
		"jardin":
			return 1 if bool(gs.jardin_instalado) else 0
	return 0


func _refresh_build_tray_labels() -> void:
	var gs := _gs()
	for mid in _build_buttons:
		var btn := _build_buttons[mid] as Button
		if not is_instance_valid(btn):
			continue
		var count := _structure_count(gs, mid)
		var limit := _structure_limit(mid)
		var cost := int(STRUCTURE_COST.get(mid, 25))
		btn.text = "%s %d/%d (%d⚡)" % [tr("structures." + mid), count, limit, cost]


func _pick_storm_profile(storm_idx: int) -> Dictionary:
	if storm_idx <= 0:
		return SPE_STORM_PROFILES[0]
	var roll := randf()
	if roll < 0.30:
		return SPE_STORM_PROFILES[0]
	if roll < 0.70:
		return SPE_STORM_PROFILES[1]
	return SPE_STORM_PROFILES[2]


func _storms_unlocked_for_mission(gs: Node) -> bool:
	if gs == null:
		return false
	var mm: Node = gs.obtener_mission_manager() if gs.has_method("obtener_mission_manager") else null
	if mm == null or not mm.has_method("obtener_mision_activa"):
		return true
	var active: Dictionary = mm.call("obtener_mision_activa")
	if active.is_empty():
		return true
	var id_str := str(active.get("id", "mision_01"))
	var num := int(id_str.trim_prefix("mision_")) if id_str.begins_with("mision_") else 1
	var unlocked := num >= 8
	if unlocked and _storm_unlocked_mission_id != id_str:
		_storm_unlocked_mission_id = id_str
		if num == 8 and not bool(gs.nube_activa) and not bool(gs.alerta_nube) and float(gs.tiempo_para_nube) > 35.0:
			gs.tiempo_para_nube = 35.0
	return unlocked


func _on_dock_action(id: String) -> void:
	match id:
		"construction":
			_refresh_build_tray_labels()
			_build_tray.visible = not _build_tray.visible
		"expedition":
			_build_tray.visible = false
			_run_expedition()
		"rest":
			_build_tray.visible = false
			_run_rest()
		"processing":
			_build_tray.visible = false
			_run_processing()
		"repair":
			_build_tray.visible = false
			_run_repair()
		"missions", "upgrades", "science":
			_build_tray.visible = false
			_open_section_modal(id)
	_refresh_dock_states()


func _start_build(id_estructura: String) -> void:
	_build_tray.visible = false
	_refresh_dock_states()
	var gs := _gs()
	if gs == null:
		return
	if id_estructura == "jardin" and not _has_upgrade("jardin_lunar"):
		_show_toast(tr("structures.jardin.help"), 3.0)
		return
	var limit := _structure_limit(id_estructura)
	if _structure_count(gs, id_estructura) >= limit:
		_show_toast(_msg(
			"Límite de %s alcanzado (%d/%d)." % [tr("structures." + id_estructura), limit, limit],
			"%s limit reached (%d/%d)." % [tr("structures." + id_estructura), limit, limit]
		), 2.8)
		return
	var cost := float(STRUCTURE_COST.get(id_estructura, 25.0))
	if gs.energia < cost:
		_show_toast(_msg("Energía insuficiente (necesitas %d)." % int(cost), "Not enough energy (need %d)." % int(cost)), 2.8)
		return
	if is_instance_valid(placement_system) and placement_system.has_method("start_placement"):
		if "keep_placing_with_shift" in placement_system:
			placement_system.set("keep_placing_with_shift", false)
		_pending_build_id = id_estructura
		placement_system.call("start_placement", StringName(id_estructura))


func _on_piece_placed(piece_id: StringName, _pos: Vector3) -> void:
	var id := str(piece_id)
	_pending_build_id = ""
	var gs := _gs()
	if gs == null:
		return
	var limit := _structure_limit(id)
	if _structure_count(gs, id) >= limit:
		if is_instance_valid(estructuras_colocadas) and estructuras_colocadas.get_child_count() > 0:
			var last := estructuras_colocadas.get_child(estructuras_colocadas.get_child_count() - 1)
			if str(last.get_meta(&"piece_id", &"")) == id:
				last.queue_free()
		_show_toast(_msg(
			"Límite de %s alcanzado (%d/%d)." % [tr("structures." + id), limit, limit],
			"%s limit reached (%d/%d)." % [tr("structures." + id), limit, limit]
		), 2.8)
		return
	var cost := float(STRUCTURE_COST.get(id, 25.0))
	if not gs.pagar("energia", cost):
		return
	if gs.has_method("hay_simulacion") and gs.call("hay_simulacion"):
		gs.solicitar_construir(id, -1)
	else:
		match id:
			"panel_solar":
				gs.paneles_instalados += 1
			"procesador_hielo":
				gs.procesador_instalado = true
			"generador_oxigeno":
				gs.generador_instalado = true
			"jardin":
				gs.jardin_instalado = true
		gs.notificar_evento_mision("estructura_construida", {
			"id_estructura": id,
			"total_paneles": gs.paneles_instalados,
		})
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"trabajo")
	_show_toast("%s ✓ (-%d⚡)" % [tr("structures." + id), int(cost)], 2.6)
	_sync_all_from_state()


func _on_placement_cancelled(_piece_id: StringName) -> void:
	_pending_build_id = ""


func _run_rest() -> void:
	var gs := _gs()
	if gs == null:
		return
	if bool(gs.descansando_en_domo):
		_set_robot_resting(gs, false)
		_refresh_dock_states()
		_sync_bridge_telemetry(gs)
		_show_toast(_msg("Descanso finalizado.", "Rest ended."), 2.0)
		return
	var dist := _robot_distance_to_dome()
	var recharge_r := _dome_recharge_radius()
	if dist > recharge_r:
		_show_toast(_msg(
			"Acércate al Domo para descansar y recargar (estás a %.1f m; máx. %.1f m)." % [dist, recharge_r],
			"Move closer to the Dome to rest & recharge (%.1f m away; max %.1f m)." % [dist, recharge_r]
		), 3.2)
		return
	if float(gs.energia_robot) >= 99.5:
		_show_toast(_msg("La batería del robot ya está al 100%.", "Robot battery is already at 100%."), 2.4)
		return
	if float(gs.energia) <= 0.1:
		_show_toast(_msg("La Base no tiene energía para recargar al robot.", "Base has no energy left to recharge the robot."), 2.8)
		return
	if is_instance_valid(click_to_move):
		click_to_move.set("_moviendo", false)
	_set_robot_resting(gs, true)
	gs.notificar_evento_mision("robot_dentro_domo", {"distancia": dist})
	gs.notificar_evento_mision("recarga_bateria_activa", {"energia_robot": gs.energia_robot})
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"reposo")
	_refresh_dock_states()
	_sync_bridge_telemetry(gs)
	_show_toast(_msg(
		"Descansando en el Domo: recargando robot desde la Base ⚡→🔋",
		"Resting at Dome: recharging robot from Base ⚡→🔋"
	), 2.8)


func _run_expedition() -> void:
	var gs := _gs()
	if gs == null:
		return
	if gs.has_method("hay_simulacion") and gs.call("hay_simulacion"):
		var msg: String = gs.solicitar_viaje_hielo()
		if not msg.is_empty():
			_show_toast(msg, 2.8)
		return
	if gs.en_viaje_hielo or _expedition_pending:
		_show_toast(_msg("Expedición ya en curso...", "Expedition already in progress..."), 2.0)
		return
	if int(gs.hielo) >= EXPEDITION_ICE_CAP:
		_show_toast(_msg(
			"Carga máxima de hielo alcanzada (%d/%d). Regresa a la Base y procesa el hielo primero." % [int(gs.hielo), EXPEDITION_ICE_CAP],
			"Max ice load reached (%d/%d). Return to Base and process ice first." % [int(gs.hielo), EXPEDITION_ICE_CAP]
		), 3.0)
		return
	if float(gs.energia_robot) < 15.0:
		_show_toast(_msg(
			"Batería del robot muy baja (<15%). Acércate al Domo y pulsa Descansar.",
			"Robot battery too low (<15%). Move to the Dome and press Rest."
		), 3.0)
		return

	_set_robot_resting(gs, false)
	var crater := mundo.get_node_or_null("CraterHielo") as Node3D
	if crater != null and is_instance_valid(click_to_move):
		click_to_move.set("_destino", crater.global_position)
		click_to_move.set("_moviendo", true)
		click_to_move.set("_tiempo_atascado", 0.0)

	gs.en_viaje_hielo = true
	_expedition_pending = true
	_expedition_timer = 3.0
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"trabajo")
	gs.notificar_evento_mision("viaje_hielo_iniciado", {})
	_refresh_dock_states()
	_show_toast(_msg("Robot en camino al cráter helado...", "Robot heading to ice crater..."), 2.8)


func _finish_local_expedition() -> void:
	var gs := _gs()
	if gs == null:
		return
	gs.en_viaje_hielo = false
	var yield_ice := 3
	var drill_cost := 16.0
	if int(gs.herramienta_nivel) >= 3:
		yield_ice = 8
		drill_cost = 10.0
	elif int(gs.herramienta_nivel) == 2:
		yield_ice = 5
		drill_cost = 13.0
	var space_left := maxi(0, EXPEDITION_ICE_CAP - int(gs.hielo))
	var gained := mini(yield_ice, space_left)
	gs.cambiar_recurso("hielo", gained)
	gs.pagar_robot(drill_cost)
	gs.notificar_evento_mision("viaje_hielo_completado", {
		"en_alerta_nube": gs.nube_activa,
		"hielo_obtenido": gained,
	})
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"exito")
	_show_toast(_msg(
		"+%d bloques de hielo (%d/%d · %d L potenciales)!" % [gained, int(gs.hielo), EXPEDITION_ICE_CAP, gained * 10],
		"+%d ice blocks (%d/%d · %d L potential)!" % [gained, int(gs.hielo), EXPEDITION_ICE_CAP, gained * 10]
	), 3.0)
	_sync_all_from_state()


func _robot_distance_to_processing_zone() -> float:
	var best := _robot_distance_to_dome()
	if is_instance_valid(robot) and is_instance_valid(estructuras_colocadas):
		var r := robot.global_position
		for child in estructuras_colocadas.get_children():
			if str(child.get_meta(&"piece_id", &"")) == "procesador_hielo" or "ProcesadorHielo" in child.name:
				var p := (child as Node3D).global_position
				best = minf(best, Vector2(r.x, r.z).distance_to(Vector2(p.x, p.z)))
	return best


func _run_processing() -> void:
	var gs := _gs()
	if gs == null:
		return
	if not bool(gs.procesador_instalado):
		_show_toast(_msg(
			"Instala el Procesador de Hielo desde Construir primero.",
			"Install the Ice Processor from Build first."
		), 2.8)
		return
	var base_dist := _robot_distance_to_processing_zone()
	var recharge_r := _dome_recharge_radius()
	if base_dist > recharge_r:
		_show_toast(_msg(
			"Debes estar en la Base para procesar hielo (estás a %.1f m; máx. %.1f m)." % [base_dist, recharge_r],
			"Move back to the Base to process ice (%.1f m away; max %.1f m)." % [base_dist, recharge_r]
		), 3.0)
		return
	if int(gs.hielo) <= 0:
		_show_toast(_msg("No hay hielo. Ve de Expedición primero.", "No ice available. Start an Expedition first."), 2.8)
		return
	var free_blocks := floori((float(gs.agua_max) - float(gs.agua)) / 5.0)
	if free_blocks <= 0:
		_show_toast(_msg("El tanque está lleno. Usa agua antes de procesar más hielo.", "The tank is full. Use some water before processing more ice."), 3.0)
		return
	var blocks := mini(mini(int(gs.hielo), _processor_capacity()), free_blocks)
	var base_cost := float(blocks) * 0.5
	if not gs.pagar("energia", base_cost):
		_show_toast(_msg(
			"Falta energía de Base (%.1f%%) para procesar hielo." % base_cost,
			"Need %.1f%% Base energy to process ice." % base_cost
		), 2.8)
		return
	var liters := float(blocks) * 10.0
	var water_pct := (liters / 200.0) * 100.0
	gs.cambiar_recurso("hielo", -blocks)
	gs.cambiar_recurso("agua", water_pct)
	var proc_anim := _find_placed_processor_anim()
	if proc_anim != null and proc_anim.has_animation("procesar"):
		proc_anim.play("procesar")
	gs.notificar_evento_mision("hielo_ingresado_procesador", {"bloques": blocks, "litros": liters})
	gs.notificar_evento_mision("hielo_procesado", {"es_noche": not gs.es_dia, "litros": liters})
	_show_toast(_msg(
		"%d bloques (%d kg) → +%d Litros de Agua ✓" % [blocks, blocks * 10, int(liters)],
		"%d blocks (%d kg) → +%d Liters of Water ✓" % [blocks, blocks * 10, int(liters)]
	), 2.8)
	_sync_all_from_state()


func _find_placed_processor_anim() -> AnimationPlayer:
	if is_instance_valid(estructuras_colocadas):
		for child in estructuras_colocadas.get_children():
			if str(child.get_meta(&"piece_id", &"")) == "procesador_hielo" or "ProcesadorHielo" in child.name:
				var anim := child.get_node_or_null("AnimationPlayer") as AnimationPlayer
				if anim != null:
					return anim
	return mundo.get_node_or_null("ProcesadorHielo/AnimationPlayer") as AnimationPlayer


func _run_repair() -> void:
	var gs := _gs()
	if gs == null:
		return
	if gs.has_method("hay_simulacion") and gs.call("hay_simulacion"):
		var msg: String = gs.solicitar_reparar_escudo()
		if not msg.is_empty():
			_show_toast(msg, 2.8)
		return
	if gs.escudo >= 99.5:
		_show_toast(_msg("El escudo del domo ya está al 100%.", "Dome shield is already at 100%."), 2.4)
		return
	var cost := 8.0 if _has_upgrade("reparar_barato") else 12.0
	if not gs.pagar("energia", cost):
		_show_toast(_msg("Falta energía (%d⚡) para reparar escudo." % int(cost), "Need %d⚡ to repair shield." % int(cost)), 2.8)
		return
	gs.notificar_evento_mision("reparar_escudo_iniciado", {})
	gs.cambiar_recurso("escudo", 25.0)
	gs.notificar_evento_mision("escudo_reparado", {})
	_show_toast(_msg("Escudo reparado +25% ✓", "Shield repaired +25% ✓"), 2.6)
	_sync_all_from_state()


func _open_section_menu() -> void:
	_open_modal("menu", tr("menu.title"), Vector2(440, 520))
	var menu := SectionMenuScript.new()
	menu.position = Vector2(28, 72)
	menu.size = Vector2(384, 420)
	menu.section_requested.connect(func(sec: String):
		_close_modal()
		_on_dock_action(sec)
	)
	_modal_content().add_child(menu)


func _open_section_modal(section: String) -> void:
	_open_modal("section:" + section, tr("actions." + section), Vector2(1060, 570))
	var holder := Control.new()
	holder.position = Vector2(28, 78)
	holder.size = Vector2(1004, 466)
	_modal_content().add_child(holder)

	var gs := _gs()
	var mode: String = str(gs.modo_juego) if gs != null else "cadete"
	if section == "missions" or section == "upgrades":
		var items: Array[Dictionary] = _catalog.upgrades(false) if section == "upgrades" else _catalog.missions(false)
		var view: Control = (UpgradeTreeScript if section == "upgrades" else MissionListScript).new()
		view.size = holder.size
		view.call("configure", items, _build_progression_dict(), false, mode)
		holder.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if view.has_signal("purchase_requested"):
			view.connect("purchase_requested", _bridge.request_upgrade)
		_progression_view = view
	elif section == "science":
		var science := VisualActivityScript.new()
		science.section = "science"
		science.size = holder.size
		holder.add_child(science)
		if science.has_signal("narration_requested"):
			science.connect("narration_requested", func(text: String): _voice.call("speak", text, TranslationServer.get_locale()))


func _open_audio_modal() -> void:
	_open_modal("audio", tr("v2.audio_title"), Vector2(560, 380))
	var box := _modal_content()
	var muted := bool(_voice.get("muted")) if _voice != null else false

	var toggle_btn := UI.button(box, tr("intro.voice_off" if muted else "intro.voice_on"), Rect2(28, 86, 240, 46), func():
		_voice.muted = not _voice.muted
		if not _voice.muted:
			_voice.call("speak", tr("v2.test_phrase").format({"name": _player_name()}), TranslationServer.get_locale())
		_close_modal()
		_open_audio_modal()
	, not muted)
	toggle_btn.add_theme_font_size_override("font_size", 16)

	var test_btn := UI.button(box, tr("v2.test"), Rect2(286, 86, 246, 46), func():
		_voice.call("speak", tr("v2.test_phrase").format({"name": _player_name()}), TranslationServer.get_locale())
	)
	test_btn.add_theme_font_size_override("font_size", 16)

	_audio_status = UI.label(box, tr("v2.audio_muted" if muted else "v2.audio_ready"), Rect2(28, 152, 504, 54), 16, UI.WHITE)
	var exit_btn := UI.button(box, tr("preview.exit"), Rect2(28, 296, 240, 48), func():
		_close_modal()
		salir_al_menu.emit()
	)
	exit_btn.add_theme_font_size_override("font_size", 16)


func _open_modal(kind: String, title: String, panel_size: Vector2) -> Control:
	_close_modal()
	_modal_kind = kind

	_modal_layer = Control.new()
	_modal_layer.size = Vector2(1280, 720)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	interfaz.add_child(_modal_layer)

	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.02, 0.06, 0.12, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(shade)

	var pos := (Vector2(1280, 720) - panel_size) * 0.5
	var panel := UI.panel(_modal_layer, Rect2(pos, panel_size), Color("#071b32f7"), 20)
	panel.name = "ModalPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	UI.label(panel, title, Rect2(28, 18, panel_size.x - 160, 40), 26, UI.GOLD, true)
	var close_btn := UI.button(panel, tr("v2.close"), Rect2(panel_size.x - 126, 16, 102, 40), _close_modal)
	close_btn.add_theme_font_size_override("font_size", 15)
	return panel


func _modal_content() -> Control:
	return _modal_layer.get_node("ModalPanel") as Control


func _close_modal() -> void:
	if is_instance_valid(_modal_layer):
		_modal_layer.queue_free()
	_modal_layer = null
	_modal_kind = ""
	_progression_view = null
	_voice_choice = null
	_audio_status = null


func _on_resource_pressed(id: String) -> void:
	_show_toast("%s: %s" % [tr("hud." + id + ".nombre"), tr("hud." + id + ".help")], 3.4)


func _on_upgrade_requested(id_mejora: String) -> void:
	var gs := _gs()
	if gs == null:
		return
	var ok := bool(gs.comprar_mejora(id_mejora))
	if ok:
		_show_toast("%s ✓" % _catalog.text("upgrades." + id_mejora + ".nombre", id_mejora), 2.8)
		_sync_all_from_state()
	else:
		_show_toast(_msg("No se pudo desbloquear la mejora.", "Could not unlock upgrade."), 2.4)


func _on_recovery_requested(policy: String, _profile: Dictionary) -> void:
	if is_instance_valid(_modal_layer) and _modal_kind == "recovery":
		return
	_open_modal("recovery", tr("mission.failed_title"), Vector2(560, 310))
	var panel := _modal_content()
	var gs := _gs()
	var key := "tutorial.recovery.ingeniero" if policy == "restart" else "tutorial.recovery.cadete"
	UI.label(panel, tr(key), Rect2(28, 76, 504, 120), 17, UI.WHITE)
	UI.button(panel, tr("home.play"), Rect2(28, 224, 240, 48), func():
		_close_modal()
		if gs != null:
			var mode := "ingeniero" if policy == "restart" else str(gs.modo_juego)
			if policy == "restart":
				var sm: Node = gs.obtener_save_manager()
				if sm != null and sm.has_method("reiniciar_legado"):
					sm.call("reiniciar_legado")
			gs.iniciar_partida(mode)
			_sync_all_from_state()
	, true)
	UI.button(panel, tr("preview.exit"), Rect2(292, 224, 240, 48), func():
		_close_modal()
		salir_al_menu.emit()
	)


func _on_robot_started_walk(_destino: Vector3) -> void:
	var gs := _gs()
	if gs != null and gs.has_method("fijar_descanso_domo"):
		gs.call("fijar_descanso_domo", false)
	elif gs != null:
		gs.descansando_en_domo = false
	_refresh_dock_states()
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"escaneo")


func _on_robot_arrived(_destino: Vector3) -> void:
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"reposo")


func _on_partida_iniciada(modo: String) -> void:
	if is_instance_valid(_hud):
		_hud.call("set_mode", modo)
	_sync_all_from_state()


func _on_ciclo_solar_cambiado(es_dia: bool) -> void:
	_sync_world_visuals(es_dia)


func _on_advertencia_nube(segundos: float) -> void:
	if is_instance_valid(_storm_badge):
		_storm_badge.visible = true
		_storm_label.text = _msg("⚠ Alerta tormenta solar en %ds" % int(segundos), "⚠ Solar storm alert in %ds" % int(segundos))
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"alerta")


func _on_nube_impacto(_fuerza: float, _escudo_restante: float) -> void:
	if is_instance_valid(tormenta):
		tormenta.visible = true
	_sync_world_visuals(_gs().es_dia if _gs() != null else true)


func _on_nube_finalizada() -> void:
	if is_instance_valid(tormenta):
		tormenta.visible = false
	if is_instance_valid(_storm_badge):
		_storm_badge.visible = false
	if is_instance_valid(robot) and robot.has_method("cambiar_expresion"):
		robot.call("cambiar_expresion", &"reposo")


func _on_mision_completada(id_mision: String, puntos: int, _carta: Dictionary) -> void:
	var title: String = CatalogScript.text("missions." + id_mision + ".titulo", id_mision)
	_show_toast("%s (+%d★) ✓" % [title, puntos], 3.8)
	_sync_all_from_state()


func _on_mejora_desbloqueada(_id: String, _rama: String, _nivel: int) -> void:
	_sync_dome_scale(true)
	_sync_all_from_state()


func _on_recurso_actualizado(_tipo: String, _valor: float, _maximo: float) -> void:
	_sync_world_visuals(_gs().es_dia if _gs() != null else true)


func _on_bridge_state_changed(state: Dictionary) -> void:
	if is_instance_valid(_hud):
		_hud.call("set_state", state)


func _on_bridge_content_changed() -> void:
	_refresh_active_mission_panel()
	if is_instance_valid(_progression_view) and _progression_view.has_method("set_progression_state"):
		_progression_view.call("set_progression_state", _build_progression_dict())


func _sync_all_from_state() -> void:
	var gs := _gs()
	if gs == null:
		return
	var prog := _build_progression_dict()
	if is_instance_valid(_bridge):
		_bridge.call("_read_snapshot")
		_bridge.call("set_progression_state", prog)
	_refresh_build_tray_labels()
	_refresh_active_mission_panel()
	_sync_dome_scale(false)
	_sync_world_visuals(gs.es_dia)
	_refresh_dock_states()


func _build_progression_dict() -> Dictionary:
	var gs := _gs()
	var current_id := "mision_01"
	var completed: Array = []
	var unlocked: Array = []
	var stars := 0
	if gs != null:
		stars = int(gs.estrellas)
		var mm: Node = gs.obtener_mission_manager() if gs.has_method("obtener_mission_manager") else null
		if mm != null and mm.has_method("obtener_mision_activa"):
			var active: Dictionary = mm.call("obtener_mision_activa")
			current_id = str(active.get("id", ""))
		var sm: Node = gs.obtener_save_manager() if gs.has_method("obtener_save_manager") else null
		if sm != null:
			if sm.has_method("obtener_misiones_completadas"):
				completed = Array(sm.call("obtener_misiones_completadas"))
			if sm.has_method("obtener_mejoras_compradas"):
				unlocked = Array(sm.call("obtener_mejoras_compradas"))
	return {
		"current_mission": current_id,
		"completed_missions": completed,
		"unlocked_upgrades": unlocked,
		"stars": stars,
	}


func _refresh_active_mission_panel() -> void:
	if not is_instance_valid(_mission_title):
		return
	var gs := _gs()
	if gs == null:
		return
	var m: Dictionary = gs.obtener_mision_activa_localizada() if gs.has_method("obtener_mision_activa_localizada") else {}
	if m.is_empty():
		_mission_title.text = tr("mission.active")
		_mission_desc.text = tr("mission.none")
		_mission_reward.text = ""
	else:
		_mission_title.text = "%s · %s" % [tr("mission.active"), str(m.get("titulo", ""))]
		_mission_desc.text = str(m.get("descripcion", ""))
		_mission_reward.text = "★ +%d" % int(m.get("recompensa_estrellas", 1))


func _sync_world_visuals(es_dia: bool) -> void:
	if not is_instance_valid(mundo):
		return
	var ambiente := mundo.get_node_or_null("Ambiente")
	if ambiente != null and ambiente.has_method("set_noche"):
		ambiente.call("set_noche", not es_dia)
	var domo := mundo.get_node_or_null("Domo")
	var gs := _gs()
	if domo != null and domo.has_method("set_escudo") and gs != null:
		domo.call("set_escudo", gs.escudo)
	var nivel_agua := mundo.get_node_or_null("TanqueAgua/NivelAgua") as Node3D
	if nivel_agua != null and gs != null:
		var water_ratio := clampf(float(gs.agua) / maxf(float(gs.agua_max), 1.0), 0.0, 1.0)
		nivel_agua.visible = water_ratio > 0.01
		nivel_agua.scale.y = lerpf(0.25, 1.85, water_ratio)
	if is_instance_valid(tormenta) and gs != null:
		tormenta.visible = bool(gs.nube_activa)


func _refresh_dock_states() -> void:
	if _dock_buttons.has("construction"):
		var btn: Button = _dock_buttons["construction"]
		UI.paint(btn, is_instance_valid(_build_tray) and _build_tray.visible)
	if _dock_buttons.has("rest"):
		var gs := _gs()
		var rest_btn: Button = _dock_buttons["rest"]
		UI.paint(rest_btn, gs != null and bool(gs.get("descansando_en_domo")))


func _toggle_language() -> void:
	var current := TranslationServer.get_locale()
	var next := "en" if current.begins_with("es") else "es"
	TranslationServer.set_locale(next)
	var gs := _gs()
	if gs != null and "idioma" in gs:
		gs.idioma = next
	if is_instance_valid(_lang_button):
		_lang_button.text = _lang_label()
	if is_instance_valid(_menu_button):
		_menu_button.text = tr("menu.title")
	if is_instance_valid(_audio_button):
		_audio_button.text = tr("v2.settings")
	for key in _dock_buttons:
		(_dock_buttons[key] as Button).text = tr("actions." + key)
	_refresh_build_tray_labels()
	_update_cam_button_label()
	_refresh_controls_hint()
	_refresh_active_mission_panel()
	if is_instance_valid(_hud):
		_hud.call("refresh")


func _lang_label() -> String:
	return "ES" if TranslationServer.get_locale().begins_with("es") else "EN"


func _refresh_controls_hint() -> void:
	if not is_instance_valid(_controls_hint):
		return
	_controls_hint.text = _msg(
		"Clic izq: mover robot · Arrastrar clic der / Q,E: rotar cámara · Rueda: zoom · C: cambiar cámara · Esc: menú",
		"Left click: move robot · Right drag / Q,E: orbit camera · Wheel: zoom · C: toggle camera · Esc: menu"
	)


func _update_placement_banner(placing: bool) -> void:
	if not is_instance_valid(_placement_banner):
		return
	_placement_banner.visible = placing
	if placing:
		var name_text := tr("structures." + _pending_build_id) if not _pending_build_id.is_empty() else ""
		_placement_label.text = _msg(
			"Colocando %s · Clic izq: confirmar · R: rotar · Clic der / Esc: cancelar" % name_text,
			"Placing %s · Left click: confirm · R: rotate · Right click / Esc: cancel" % name_text
		)


func _show_toast(message: String, seconds: float = 2.6) -> void:
	if not is_instance_valid(_toast_panel):
		return
	_toast_label.text = message
	_toast_panel.visible = true
	_toast_timer = seconds


func _has_upgrade(id_mejora: String) -> bool:
	var gs := _gs()
	if gs == null:
		return false
	var sm: Node = gs.obtener_save_manager() if gs.has_method("obtener_save_manager") else null
	return sm != null and sm.has_method("esta_mejora_comprada") and bool(sm.call("esta_mejora_comprada", id_mejora))


func _player_name() -> String:
	var gs := _gs()
	if gs != null and "nombre_astronauta" in gs and not str(gs.nombre_astronauta).is_empty():
		return str(gs.nombre_astronauta)
	return tr("v2.default_name")


func _msg(es_text: String, en_text: String) -> String:
	return es_text if TranslationServer.get_locale().begins_with("es") else en_text


func _gs() -> Node:
	return get_node_or_null("/root/GameState")


func _processor_capacity() -> int:
	return 3
