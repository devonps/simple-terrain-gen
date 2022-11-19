extends Camera2D

var zoomFactor: float = 0.1
var zoomMin: float = 0.5
var zoomMax: float = 2.0
var dragSensitivity: float = 1.0
var zoom_level :=1.0 setget _set_zoom_level

func _input(event):
	# drag the map around
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_RIGHT):
		position -= event.relative * dragSensitivity / zoom
	# zoom into the world map
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(zoom_level - zoomFactor)

	# zoom out of the world map
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(zoom_level + zoomFactor)

func _set_zoom_level(value: float):
	zoom_level = clamp(value, zoomMin, zoomMax)
	zoom = Vector2(zoom_level, zoom_level)
