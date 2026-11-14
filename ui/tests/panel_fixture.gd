extends Control
var training := false
var ready_saw_training := false

func set_tutorial_mode(value: bool) -> void:
    training = value

func _ready() -> void:
    ready_saw_training = training
    name = "ProgressionPanelFixture"
