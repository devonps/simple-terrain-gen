extends Camera2D

var zoomFactor: float = 0.1
var zoomMin: float = 0.5
var zoomMax: float = 2.0
var dragSensitivity: float = 1.0
var zoom_level :=1.0 setget _set_zoom_level

onready var cellLabel = get_parent().get_node("debug/HBoxContainer/cell/cellLabel")
onready var biomeLabel = get_parent().get_node("debug/HBoxContainer/cell/biomeLabel")
onready var terrainLabel = get_parent().get_node("debug/HBoxContainer/cell/terrainLabel")
onready var altitudeLabel = get_parent().get_node("debug/HBoxContainer/cell/altitudeLabel")
onready var moistureLabel = get_parent().get_node("debug/HBoxContainer/cell/moistureLabel")
onready var temperatureLabel = get_parent().get_node("debug/HBoxContainer/cell/temperatureLabel")
onready var worldData = get_parent().biome

func _input(event):

	if event is InputEventMouseMotion:
		_update_world_cell_info()

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

func _update_cell_biome_data(mousePosition):
#		var mousePosition = get_cell()
		var cell = worldData[mousePosition]
		var biomeData = cell['biome']
		var terrainData = cell['terrain']
		var moistData = cell['moist']
		var tempData = cell['temp']
		var altData = cell['alt']
		biomeLabel.text = "Biome: "  + biomeData
		terrainLabel.text = "Terrain: " + terrainData
		altitudeLabel.text = "Altitude: " + str(altData)
		moistureLabel.text = "Moisture: "  + str(moistData)
		temperatureLabel.text = "Temperature: " + str(tempData)

func _update_world_cell_info():
	var mousePosition = get_cell()
	if mouse_is_inside_game_world(mousePosition):
		cellLabel.text = "World Cell (X/Y): " + str(mousePosition)
		_update_cell_biome_data(mousePosition)

func mouse_is_inside_game_world(mousePosition):
	return (mousePosition.x > -1) and (mousePosition.x < 30) and (mousePosition.y > -1) and (mousePosition.y < 30)

func get_cell():
	return get_parent().get_node("TileMap").world_to_map(get_global_mouse_position())
