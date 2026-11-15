extends RefCounted
## Readable mission clock: 480 real seconds = 1 displayed day, starting at 06:00.
## The simulation keeps its compressed lunar balance; this clock follows the light.
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
            "completed_months": override_months,
            "day": (total_override_days % DAYS_PER_MONTH) + 1,
            "minutes": posmod(int(state.minutos_mision), 1440),
            "total_days": total_override_days,
        }
    # Solar cycle (480s) maps ~29.53 Earth days for calendar progression while keeping
    # the 24h solar-phase clock (sunrise 06:00 at t=0, sunset 18:00 at t=240s) for lighting/HUD phase.
    var seconds := maxf(0.0, float(state.get("tiempo_juego", 0.0)))
    var solar_minutes := (int(floor(seconds * 1440.0 / SOLAR_CYCLE_SECONDS)) + 360) % 1440
    var total_days := int(floor(seconds * EARTH_DAYS_PER_SOLAR_CYCLE / SOLAR_CYCLE_SECONDS))
    var total_months := total_days / DAYS_PER_MONTH
    return {
        "year": (total_months / MONTHS_PER_YEAR) + 1,
        "month": (total_months % MONTHS_PER_YEAR) + 1,
        "completed_months": total_months,
        "day": (total_days % DAYS_PER_MONTH) + 1,
        "minutes": solar_minutes,
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

static func format_calendar(clock: Dictionary) -> String:
    var completed_months := int(clock.get("completed_months", 0))
    if completed_months >= 1:
        return TranslationServer.translate("live.months_days").format({"month": completed_months, "day": int(clock.get("day", 1))})
    return TranslationServer.translate("live.days_only").format({"day": int(clock.get("total_days", 0)) + 1})

static func is_day(state: Dictionary) -> bool:
    if state.has("dia_mision") and state.has("minutos_mision"):
        var minutes := posmod(int(state.minutos_mision),1440)
        return minutes >= 360 and minutes < 1080
    return fposmod(float(state.get("tiempo_juego",0)),SOLAR_CYCLE_SECONDS) < SOLAR_DAY_SECONDS
