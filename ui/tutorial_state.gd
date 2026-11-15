extends "res://core/game_state.gd"
## Independent state/services for practising the actual game.
func _registrar_idiomas() -> void: pass
func _crear_save_manager() -> Node:
    return preload("res://ui/tutorial_save.gd").new()
func _process(_delta: float) -> void: pass
