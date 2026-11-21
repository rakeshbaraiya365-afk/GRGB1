extends Control
class_name GRBGLookArea

var player: GRBGPlayer
var last_touch_position := Vector2.ZERO
var dragging := false

func _gui_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventScreenTouch:
		dragging = event.pressed
		last_touch_position = event.position
	elif event is InputEventScreenDrag:
		player.rotate_view(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		player.rotate_view(event.relative)
