extends RefCounted
const Profile = preload("res://ui/player_profile.gd")
const Steps = preload("res://ui/tutorial_steps.gd")
var player = Profile.new()
var step_id := "start"
var completed_actions: Dictionary = {}
var completed := false

func definition() -> Dictionary:
    return Steps.DEFINITIONS.get(step_id, {})

func dialogue_key() -> String:
    return str(definition().get("text", "")).replace("{mode}", player.mode_id())

func target() -> String:
    return str(definition().get("target", ""))

func needs_hud() -> bool:
    return bool(definition().get("hud", false))

func record_action(action: String) -> void:
    completed_actions[action] = true

func can_advance() -> bool:
    if step_id == "age" and player.age_group.is_empty():
        return false
    var required := target()
    return required.is_empty() or completed_actions.has(required)

func advance() -> bool:
    if not can_advance() or not step_id in Steps.IDS:
        return false
    if step_id == "ready":
        completed = true
        step_id = "done"
    else:
        step_id = Steps.IDS[Steps.IDS.find(step_id) + 1]
    return true

func back() -> void:
    if completed:
        return
    var index := Steps.IDS.find(step_id)
    if index > 0:
        step_id = Steps.IDS[index - 1]

func reset() -> void:
    player = Profile.new()
    completed_actions.clear()
    completed = false
    step_id = "start"
