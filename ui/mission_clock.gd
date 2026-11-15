extends RefCounted
## Mission clock projection: 480 s real = 1 full lunar solar cycle (~29.53 Earth days),
## split into 240 s (4 min) daylight and 240 s (4 min) night (~14.77 Earth days each).
## Rolls over at 30 days -> +1 month, and at 12 months -> +1 year.
const SOLAR_CYCLE_SECONDS := 480.0
const SOLAR_DAY_SECONDS := 240.0
const EARTH_DAYS_PER_SOLAR_CYCLE := 29.53
const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12

static func snapshot(state: Dictionary) -> Dictionary:
    if state.has("dia_mision") and state.has("minutos_mision"):
        var total_override_days := maxi(0, int(state.dia_mision) - 1)
        var override_months := total_override_days / DAYS_PER_MONTH
        var year := maxi(1, int(state.get("anio_mision", (override_months / MONTHS_PER_YEAR) + 1)))
        var month := maxi(1, int(state.get("mes_mision", (override_months % MONTHS_PER_YEAR) + 1)))
        return {
            "year": year,
            "month": month,
            "day": (total_override_days % DAYS_PER_MONTH) + 1,
            "minutes": posmod(int(state.minutos_mision), 1440),
            "total_days": total_override_days,
        }
    var seconds := maxf(0.0, float(state.get("tiempo_juego", 0.0)))
    var total_earth_minutes := int(floor(seconds * (EARTH_DAYS_PER_SOLAR_CYCLE * 1440.0 / SOLAR_CYCLE_SECONDS)))
    var total_days := total_earth_minutes / 1440
    var minutes := total_earth_minutes % 1440
    var total_months := total_days / DAYS_PER_MONTH
    return {
        "year": (total_months / MONTHS_PER_YEAR) + 1,
        "month": (total_months % MONTHS_PER_YEAR) + 1,
        "day": (total_days % DAYS_PER_MONTH) + 1,
        "minutes": minutes,
        "total_days": total_days,
    }

static func display(state: Dictionary) -> Dictionary:
    var value := snapshot(state)
    var minutes := int(value.minutes)
    return {
        "year": value.year,
        "month": value.month,
        "day": value.day,
        "time": "%02d:%02d" % [minutes / 60, minutes % 60],
    }
