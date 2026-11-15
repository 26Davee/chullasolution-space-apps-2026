extends RefCounted
## Session-only player preferences. Gameplay saves belong to P1/P5.
const AGE_GROUPS := {
    "7_9": {"mode": "cadete", "recovery": "checkpoint"},
    "10_12": {"mode": "ingeniero", "recovery": "restart"}
}
var nickname := ""
var age_group := ""
var locked := false

func choose_age(group: String) -> bool:
    if locked or not AGE_GROUPS.has(group):
        return false
    age_group = group
    return true

func mode_id() -> String:
    return str(AGE_GROUPS.get(age_group, {}).get("mode", ""))

static func recovery_for(mode: String) -> String:
    for rule in AGE_GROUPS.values():
        if rule["mode"] == mode:
            return rule["recovery"]
    return ""

func display_name() -> String:
    var clean := nickname.replace("<", "").replace(">", "").replace("&", " ").strip_edges().left(18)
    return clean if not clean.is_empty() else tr("v2.default_name")

func export_profile(language: String, voice_enabled: bool, completed: bool) -> Dictionary:
    return {
        "nickname": display_name(), "age_group": age_group,
        "mode": mode_id(), "language": language,
        "voice_enabled": voice_enabled, "tutorial_completed": completed
    }
