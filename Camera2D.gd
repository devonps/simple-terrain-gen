extends Camera2D

var zoomFactor: float = 0.1
var zoomMin: float = 0.5
var zoomMax: float = 2.0
var dragSensitivity: float = 1.0
var zoom_level :=1.0 setget _set_zoom_level

onready var cellLabel = get_parent().get_node("debug/HBoxContainer/cell/cellLabel")
onready var biomeLabel = get_parent().get_node("debug/HBoxContainer/cell/biomeLabel")
onready var worldData = get_parent().biome

func _input(event):

	if event is InputEventMouseMotion:
		_update_world_cell_info()

	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		_update_cell_biome_data()

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

func _update_cell_biome_data():
		var mousePosition = get_cell()
		var cell = worldData[mousePosition]
		var biomeData = cell['biome']
		biomeLabel.text = "Biome: "  + biomeData


func _update_world_cell_info():
	var mousePosition = get_cell()
	if mouse_is_inside_game_world(mousePosition):
		cellLabel.text = "World Cell (X/Y): " + str(mousePosition)

func mouse_is_inside_game_world(mousePosition):
	return (mousePosition.x > -1) and (mousePosition.x < 30) and (mousePosition.y > -1) and (mousePosition.y < 30)

func get_cell():
	return get_parent().get_node("TileMap").world_to_map(get_global_mouse_position())
