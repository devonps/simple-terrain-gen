extends Node2D

export var width = 30
export var height = 30
export var townDetails = {}
export var worldData = {}

onready var tilemap = $TileMap
onready var townsMap = $towns
onready var plainslabel = $debug/HBoxContainer/Test1/PlainsLabel
onready var desertlabel = $debug/HBoxContainer/Test1/DesertLabel
onready var waterlabel = $debug/HBoxContainer/Test1/WaterLabel
onready var forestlabel = $debug/HBoxContainer/Test1/ForestLabel
onready var hillslabel = $debug/HBoxContainer/Test1/HillsLabel
onready var mountlabel = $debug/HBoxContainer/Test1/MountainsLabel
onready var snowlabel = $debug/HBoxContainer/Test1/SnowLabel
onready var seedlabel = $debug/HBoxContainer/Test1/seedlabel
onready var townnamelabel = $debug/HBoxContainer/town/nameLabel
onready var townsizelabel = $debug/HBoxContainer/town/sizeLabel

# biome parameters
var temperature = {}
var moisture = {}
var altitude = {}
var openSimplexNoise = OpenSimplexNoise.new()

# town parameters
var number_of_towns = 30
var number_towns_too_close = 0
var max_tiles:float = 900.0
var town_locations = []
var next_town_id = 0
var all_first_words = _read_json_file("location_first_word")
var all_second_words = _read_json_file("location_second_word")

var tiles = {
	"grass_light": 0,
	"grass_dark": 1,
	"mountains_dark": 2,
	"mountains_light": 3,
	"hills_light": 4,
	"hills_dark": 5,
	"snow_cap": 6,
	"snow": 7,
	"river_dark": 8,
	"riverbank_light": 9,
	"lake_light": 10,
	"lake_dark": 11,
	"desert_light": 12,
	"desert_lightest": 13,
	"desert_dark": 14,
	"forest_light": 15,
	"forest_dark": 16,
	"town": 17
}

var biome_data = {
	"plains": {"grass_light": 0.90, "grass_dark": 0.10},
	"desert": {"desert_dark": 0.15, "desert_light": 0.80, "desert_lightest": 0.05},
	"water": {"lake_dark": 1},
	"forest": {"forest_dark": 0.30, "forest_light": 0.70},
	"hills": {"hills_light": 0.5, "hills_dark": 0.5},
	"mountains": {"mountains_dark": 0.98, "grass_dark":0.02},
	"snow": {"snow": 0.95, "mountains_light": 0.04, "grass_light": 0.01}
}

var biomeCounts = {
	"plains": 0,
	"desert": 0,
	"water": 0,
	"forest": 0,
	"hills": 0,
	"snow": 0,
	"mountains": 0
}

var desert_tile_count = 0
var plains_tile_count = 0
var water_tile_count = 0
var forest_tile_count = 0
var hills_tile_count = 0
var mountains_tile_count = 0
var snow_tile_count = 0

#
# biome plans
#
# These allow for basic alterations in how the actual biomes are selected.
# biome selection follows these rules:
# 	1. The altitude of the world cell determines the base biome (ground, hills, mountains)
#	2. After that the temperature and moisture are compared to determine the biome detail (plains, desert)
#	3. Finer granular selection is made (dark_grass, light_grass, snow_caps)
#
#Plans
# 1. Is plains heavy, ie 80% of terrain will be plains
# 2. Is light on the plains and a good mix of hills and mountains
# 3. Is plains and mountains heavy


var biome_plains_start:float
var biome_plains_end:float
var biome_hills_start:float
var biome_hills_end:float
var biome_mountains_start:float
var biome_mountains_end:float

var altitudePlans = {
	1: {"plains_start":0.00, "plains_end":0.30, "hills_start":0.30, "hills_end":0.40, "mountains_start":0.40, "mountains_end":1.0},
	2: {"plains_start":0.10, "plains_end":0.30, "hills_start":0.31, "hills_end":0.75, "mountains_start":0.76, "mountains_end":1.0},
	3: {"plains_start":0.16, "plains_end":0.70, "hills_start":0.10, "hills_end":0.15, "mountains_start":0.71, "mountains_end":1.0}
	}

var biomePlan = 1

func _ready():
	randomize()
	_initialise_world(width, height)
	temperature = generate_map(150,5)
	moisture = generate_map(150,5)
	altitude = generate_map(150,5)
	build_world(width, height)
	place_towns()
	save_world_to_disk()


func _input(event):
	if event.is_action_pressed("ui_accept"):
		var _x = get_tree().reload_current_scene()

func save_world_to_disk() -> void:
	_save_json_to_disk("townData", townDetails)
	_save_json_to_disk("worldData", worldData)


func generate_map(per, oct) -> Dictionary:
	openSimplexNoise.seed = randi()
	openSimplexNoise.period = per
	openSimplexNoise.octaves = oct
	openSimplexNoise.persistence = 1.0
	openSimplexNoise.lacunarity = 2.0

	var lowestrand = 0.00
	var highestrand = 0.00

	var cellData = {}
	for x in width:
		for y in height:
			var rand := 2*(abs(openSimplexNoise.get_noise_2d(x,y)))
			if rand == 0:
				rand += rand_range(0.01, 0.05)
			if rand < lowestrand:
				lowestrand = rand
			if rand > highestrand:
				highestrand = rand
			cellData[Vector2(x,y)] = rand
	return cellData


func build_world(map_width, map_height) -> void:
	_get_biome_plan(biomePlan)
	for x in map_width:
		for y in map_height:
			var pos = Vector2(x, y)
			var alt = altitude[pos]
			var temp = temperature[pos]
			var moist = moisture[pos]
			# do we need a body of water
#			if between(alt, biome_water_start, biome_water_end):
#				add_water_biome(pos, moist, temp, alt)
			# ground terrain comes next
			if _between(alt, biome_plains_start, biome_plains_end):
				add_ground_biome(pos, moist, temp, alt)
			elif _between(alt, biome_hills_start, biome_hills_end):
				add_hills_biome(pos, moist, temp, alt)
			elif _between(alt, biome_mountains_start, biome_mountains_end):
			# then anything above ground level
				add_mountains_biome(pos, moist, temp, alt)
			else:
				print_debug("ALTITUDE NOT CATERED FOR: ", str(alt))
	_update_debug_terrain_labels()


#
# Biome functions
#

func add_ground_biome(pos, moist:float, temp:float, alt:float) -> void:
	#desert
	if _between(moist, 0.0, 0.05):
		var terrain_id = _random_tile("desert")
		var terrain_name = _get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		worldData[pos] = {"biome":"desert", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		_updateBiomeCount("desert")
		desert_tile_count += 1
	#plains
	elif _between(moist, 0.05, 0.4):
		var terrain_id = _random_tile("plains")
		var terrain_name = _get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		worldData[pos] = {"biome":"plains", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		_updateBiomeCount("plains")
		plains_tile_count += 1
	#forests
	elif _between(moist, 0.4, 1.0):
		var terrain_id = _random_tile("forest")
		var terrain_name = _get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		worldData[pos] = {"biome":"forest", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		_updateBiomeCount("forest")
		forest_tile_count += 1


func add_hills_biome(pos, moist, temp, alt) -> void:
	var terrain_id = _random_tile("hills")
	var terrain_name = _get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	worldData[pos] = {"biome":"hills", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	_updateBiomeCount("hills")
	hills_tile_count += 1


func add_mountains_biome(pos, moist, temp, alt) -> void:
	var terrain_id = _random_tile("mountains")
	var terrain_name = _get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	worldData[pos] = {"biome":"mountains", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	_updateBiomeCount("mountains")
	mountains_tile_count += 1


func add_water_biome(pos, moist:float, temp:float, alt:float) -> void:
	var terrain_id = _random_tile("water")
	var terrain_name = _get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	worldData[pos] = {"biome":"water", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	_updateBiomeCount("water")
	water_tile_count += 1


func add_snow_biome(pos, moist, temp, alt) -> void:
	var terrain_id = _random_tile("snow")
	var terrain_name = _get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	worldData[pos] = {"biome":"snow", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	_updateBiomeCount("desert")
	desert_tile_count += 1


func _get_biome_plan(plan_id) -> void:
	biome_plains_start = altitudePlans[plan_id]["plains_start"]
	biome_plains_end = altitudePlans[plan_id]["plains_end"]
	biome_hills_start = altitudePlans[plan_id]["hills_start"]
	biome_hills_end = altitudePlans[plan_id]["hills_end"]
	biome_mountains_start = altitudePlans[plan_id]["mountains_start"]
	biome_mountains_end = altitudePlans[plan_id]["mountains_end"]


func _get_terrain_name_from_biome(terrain_id) -> String:
	var terrain_tiles_keys = tiles.keys()
	var terrain_name = terrain_tiles_keys[terrain_id]
	return terrain_name


func _updateBiomeCount(biomeType) -> void:
	var counter = biomeCounts.get(biomeType)
	counter += 1
	biomeCounts[biomeType] = counter

func _initialise_world(map_width, map_height):
	for x in map_width:
		for y in map_height:
			var pos = Vector2(x, y)
			worldData[pos] = null

#
# Town functions
#

func place_towns() -> void:

	place_large_towns()
	place_medium_towns()
	place_small_towns()


func place_large_towns() -> void:
	var large_town_image_id = 19
	var max_large_towns = 3
	var large_town_map_edge_buffer = 2
	var large_town_buffer = 4

	for large_town in max_large_towns:
		var px = 0
		var py = 0
		var pos = Vector2(px, py)
		var valid_town_location = false
		while !valid_town_location:
			px = int(rand_range(0, width - 1))
			py = int(rand_range(0, height - 1))
			pos = Vector2(px, py)
			if town_not_on_edge_of_map(pos, large_town_map_edge_buffer):
				if !town_allready_placed_here(pos):
					if town_not_near_another(pos, large_town_buffer):
						valid_town_location = true
						town_locations.append(pos)
						townsMap.set_cellv(pos, large_town_image_id)
						populate_town("large", pos)

func place_medium_towns() -> void:
	var medium_town_image_id = 18
	var max_medium_towns = 7
	var medium_town_map_edge_buffer = 2
	var medium_town_buffer = 1

	for medium_town in max_medium_towns:
		var px = 0
		var py = 0
		var pos = Vector2(px, py)
		var valid_town_location = false
		while !valid_town_location:
			px = int(rand_range(0, width - 1))
			py = int(rand_range(0, height - 1))
			pos = Vector2(px, py)
			if town_not_on_edge_of_map(pos, medium_town_map_edge_buffer):
				if !town_allready_placed_here(pos):
					if town_not_near_another(pos, medium_town_buffer):
						valid_town_location = true
						town_locations.append(pos)
						townsMap.set_cellv(pos, medium_town_image_id)
						populate_town("medium", pos)


func place_small_towns() -> void:
	var small_town_image_id = 17
	var max_small_towns = 17
	var small_town_map_edge_buffer = 1
	var small_town_buffer = 1

	for small_town in max_small_towns:
		var px = 0
		var py = 0
		var pos = Vector2(px, py)
		var valid_town_location = false
		while !valid_town_location:
			px = int(rand_range(0, width))
			py = int(rand_range(0, height))
			pos = Vector2(px, py)
			if town_not_on_edge_of_map(pos, small_town_map_edge_buffer):
				if !town_allready_placed_here(pos):
					if town_not_near_another(pos, small_town_buffer):
						valid_town_location = true
						town_locations.append(pos)
						townsMap.set_cellv(pos, small_town_image_id)
						populate_town("small", pos)


func town_not_on_edge_of_map(pos, buffer) -> bool:
	if (pos.x > buffer and pos.x < (width - buffer)) and (pos.y > buffer and pos.y < (height - buffer)):
		return true
	return false


func town_allready_placed_here(pos) -> bool:
	for x in town_locations.size():
		if pos == town_locations[x]:
			return true
	return false


func town_not_near_another(pos, town_buffer) -> bool:
	var found_safe_loc = true
	var town_loc_is_good = true
	var nx = pos.x
	var ny = pos.y
	if town_locations.size() > 1:
		for x in town_locations.size():
			var ex = town_locations[x].x
			var ey = town_locations[x].y
			if abs(nx - ex) < town_buffer or abs(ny - ey) < town_buffer:
				town_loc_is_good = false
		if !town_loc_is_good:
			found_safe_loc = false
	return found_safe_loc

func populate_town(size, pos) -> void:
	var town_name = _generate_town_name()
	var array_of_buildings = _generate_town_buildings(size)
	var town_population_size = _calculate_town_population(size)

	next_town_id = _get_town_id()
	print("next town:", next_town_id)

	townDetails[next_town_id] = {"id":next_town_id, "name": town_name, "size": size, "population": town_population_size, "buildings": array_of_buildings}
	worldData[pos]["townID"] = next_town_id

	_set_town_id()

func _get_town_id():
	return next_town_id

func _set_town_id():
	next_town_id += 1

func _generate_town_name() -> String:
	var valid_first_words = []
	var valid_second_words = []

	for word in all_first_words:
		if word["can be location"]:
			valid_first_words.append(word["location first word"])

	for word in all_second_words:
		if word["Split meta"]  == "location":
			valid_second_words.append(word["Splits"])

	var town_first_word = valid_first_words[randi() % valid_first_words.size()]
	var town_second_word = valid_second_words[randi() % valid_second_words.size()]

	return town_first_word + " " + town_second_word


func _generate_town_buildings(size) -> Array:
	var all_buildings = _read_json_file("town_buildings")
	var buildings_for_this_town = []

	for building in all_buildings:
		if building["town_size"] == size or building["town_size"] == "all":
			buildings_for_this_town.append(building["display_name"])
	return buildings_for_this_town


func _calculate_town_population(size) -> int:
	var town_population = 0

	match size:
		"small":
			town_population = 20 + int(rand_range(45, 100))
		"medium":
			town_population = 50 + int(rand_range(60, 100))
		"large":
			town_population = 100 + int(rand_range(100, 200))

	return town_population

#
# utility functions
#

func _read_json_file(file_path) -> JSONParseResult:
	var file = File.new()
	file.open(file_path + ".json", File.READ)
	var content_as_text = file.get_as_text()

	return parse_json(content_as_text)


func _save_json_to_disk(filename, contents) -> void:
	var file = File.new()
	file.open("res://" + filename + ".json", File.WRITE)
	file.store_line(to_json(contents))
	file.close()


func _format_coverage_string(biomeString, biomeCount) -> String:
	var percent_string = " (%d%%)"
	var base_percent:float = (biomeCount / max_tiles) * 100
	var base_percentage = percent_string % base_percent
	return biomeString + " Count: %s %s" % [biomeCount, base_percentage]


func _update_debug_terrain_labels() -> void:
	seedlabel.text = "Seed:" + str(openSimplexNoise.seed)
	if plains_tile_count > 0:
		plainslabel.visible = true
		plainslabel.text = _format_coverage_string("Plains", plains_tile_count)
	if desert_tile_count > 0:
		desertlabel.visible = true
		desertlabel.text = _format_coverage_string("Desert", desert_tile_count)
	if water_tile_count > 0:
		waterlabel.visible = true
		waterlabel.text = _format_coverage_string("Water", water_tile_count)
	if forest_tile_count > 0:
		forestlabel.visible = true
		forestlabel.text = _format_coverage_string("Forest", forest_tile_count)
	if hills_tile_count > 0:
		hillslabel.visible = true
		hillslabel.text = _format_coverage_string("Hills", hills_tile_count)
	if mountains_tile_count > 0:
		mountlabel.visible = true
		mountlabel.text = _format_coverage_string("Mountains", mountains_tile_count)
	if snow_tile_count > 0:
		snowlabel.visible = true
		snowlabel.text = _format_coverage_string("Snow", snow_tile_count)


func _update_town_details() -> void:
	townnamelabel.text = "Town Name: New Vale"
	townsizelabel.text = "Town Size: Small"


func _between(val, start, end) -> bool:
	if stepify(start, 0.01) <= val and val < stepify(end, 0.01):
		return true
	return false


func _random_tile(this_biome) -> int:
	var current_biome = biome_data[this_biome]
	var rand_num = rand_range(0,1)
	var running_total = 0

	for tile in current_biome:
		running_total = running_total+current_biome[tile]
		if rand_num <= running_total:
			return int(tiles.get(tile))
	return 99
