extends Camera2D

var zoomFactor: float = 0.1
var zoomMin: float = 0.5
var zoomMax: float = 2.0
var dragSensitivity: float = 1.0
var zoom_level :=1.0 setget _set_zoom_level

onready var biomeDataLabel = get_parent().get_node("debug/HBoxContainer/Test1")

onready var cellLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/cellLabel")
onready var biomeLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/biomeLabel")
onready var terrainLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/terrainLabel")
onready var altitudeLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/altitudeLabel")
onready var moistureLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/moistureLabel")
onready var temperatureLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/temperatureLabel")
onready var worldData = get_parent().worldData
onready var TownData = get_parent().townDetails
onready var townNameLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/town/nameLabel")
onready var townSizeLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/town/sizeLabel")
onready var townbuildingsLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/town/buildingsLabel")
onready var townPopulationLabel = get_parent().get_node("debug/HBoxContainer/Test1/cell/town/populationLabel")


func _input(event):

	if event is InputEventMouseMotion:
		_update_world_cell_info()
		_update_town_data()

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


func _update_town_data():
	var mousePosition = get_cell()
	if mouse_is_inside_game_world(mousePosition):
		var cell = worldData[mousePosition]
		if cell.has("townID"):
			var town_id = worldData[mousePosition]["townID"]
			var townName = TownData[town_id]['name']
			var townSize = TownData[town_id]['size']
			var townPop = TownData[town_id]['population']
			var townBuildings = TownData[town_id]['buildings']

			townNameLabel.text = "Town Name: " + townName
			townSizeLabel.text = "Town Size: " + townSize
			townPopulationLabel.text = "Population: " + str(townPop)
			townbuildingsLabel.text = "Buildings: " + _array_to_string(townBuildings)

func _array_to_string(arr: Array) -> String:
	var s = ""
	for i in arr:
		s += String(i) + " "
	return s


func _update_world_cell_info():
	var mousePosition = get_cell()
	if mouse_is_inside_game_world(mousePosition):
		cellLabel.text = "World Cell (X/Y): " + str(mousePosition)
		_update_cell_biome_data(mousePosition)

func mouse_is_inside_game_world(mousePosition):
	return (mousePosition.x > -1) and (mousePosition.x < 30) and (mousePosition.y > -1) and (mousePosition.y < 30)


func get_cell():
	return get_parent().get_node("TileMap").world_to_map(get_global_mouse_position())
