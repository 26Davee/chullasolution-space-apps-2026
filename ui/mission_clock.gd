extends RefCounted
## Mission clock projection only; P2 remains the owner of simulation time.
## A 300 s day and 180 s night map to a readable 06:00–18:00 cycle.
static func snapshot(state: Dictionary) -> Dictionary:
    if state.has("dia_mision") and state.has("minutos_mision"):
        return {"day": maxi(1, int(state.dia_mision)), "minutes": posmod(int(state.minutos_mision), 1440)}
    var seconds := maxf(0, float(state.get("tiempo_juego", 0)))
    var phase := fmod(seconds, 480.0)
    var minutes := 360.0 + phase / 300.0 * 720.0 if phase < 300.0 else 1080.0 + (phase - 300.0) / 180.0 * 720.0
    return {"day": int(floor(seconds / 480.0)) + 1, "minutes": posmod(int(floor(minutes)), 1440)}

static func display(state: Dictionary) -> Dictionary:
    var value := snapshot(state)
    var minutes := int(value.minutes)
    return {"day": value.day, "time": "%02d:%02d" % [minutes / 60, minutes % 60]}
