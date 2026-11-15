extends "res://progression/save_manager.gd"
## Training progress exists only in memory. Never opens a player save file.
func _ready() -> void:
    _datos = _crear_estructura_por_defecto()
func guardar_progreso() -> bool:
    progreso_guardado.emit(true)
    return true
func _guardar_meta() -> void: pass
func cargar_progreso() -> Dictionary:
    return _datos.duplicate(true)
