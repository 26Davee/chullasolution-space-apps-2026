extends RefCounted
## Compatibility entry point. All visual demos share visual_activity.gd.
static func populate(parent: Control, section: String) -> Array[Control]:
    var view := preload("res://ui/visual_activity.gd").new()
    view.section = section
    view.size = parent.size
    parent.add_child(view)
    var focusables: Array[Control] = []
    for control in view.find_children("*", "Control", true, false):
        if control.focus_mode != Control.FOCUS_NONE: focusables.append(control)
    return focusables
