extends Node

static var _owner_id: int = 0
var muted := false
var volume := 85
var rate := 0.95
var selected_voices: Dictionary = {}
var _pending_text := ""
var _pending_language := "en"
var _wait_time := 0.0
var _probe_time := 0.0

func status_code(language: String) -> String:
    if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
        return "disabled"
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return "unsupported"
    if voices_for(language).is_empty():
        return "loading" if not _pending_text.is_empty() else "missing"
    return "ready"

func voices_for(language: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
        return result
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return result
    var ids := DisplayServer.tts_get_voices_for_language(language)
    for item in DisplayServer.tts_get_voices():
        if str(item.get("id", "")) in ids:
            result.append(item)
    return result

func available(language: String) -> bool:
    return not voices_for(language).is_empty()

func set_voice(language: String, id: String) -> void:
    selected_voices[language] = id

func voice_id(language: String) -> String:
    return pick_voice(voices_for(language), language, str(selected_voices.get(language, "")))

static func pick_voice(voices: Array[Dictionary], language: String, chosen := "") -> String:
    if voices.is_empty(): return ""
    for item in voices:
        if not chosen.is_empty() and str(item.get("id", "")) == chosen: return chosen
    var base := language.to_lower().replace("_", "-").get_slice("-", 0)
    var preferred := "zira" if base == "en" else ("sabina" if base == "es" else "")
    if not preferred.is_empty():
        for item in voices:
            if str(item.get("name", "")).to_lower().contains(preferred): return str(item.get("id", ""))
    return str(voices[0].get("id", ""))

func speak(text: String, language: String) -> bool:
    stop()
    if muted or text.is_empty():
        return false
    var status := status_code(language)
    if status == "disabled" or status == "unsupported":
        return false
    var id := voice_id(language)
    if id.is_empty():
        _pending_text = text
        _pending_language = language
        _wait_time = 0.0
        _probe_time = 0.0
        return false
    _owner_id = get_instance_id()
    DisplayServer.tts_speak(text, id, volume, 1.03, rate, int(get_instance_id() % 2147483647), true)
    return true

func stop() -> void:
    _pending_text = ""
    if ProjectSettings.get_setting("audio/general/text_to_speech", false):
        if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) and _owner_id == get_instance_id():
            DisplayServer.tts_stop()
            _owner_id = 0

func is_speaking() -> bool:
    if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
        return false
    if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
        return false
    return DisplayServer.tts_is_speaking()

func _process(delta: float) -> void:
    if _pending_text.is_empty():
        return
    _wait_time += delta
    _probe_time += delta
    if _wait_time > 5.0:
        _pending_text = ""
        return
    if _probe_time >= 0.5:
        _probe_time = 0.0
        if available(_pending_language):
            var text := _pending_text
            var language := _pending_language
            _pending_text = ""
            speak(text, language)

func _exit_tree() -> void:
    stop()
