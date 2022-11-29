extends Node2D

export var width = 30
export var height = 30
export var biome = {}

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

var temperature = {}
var moisture = {}
var altitude = {}
var openSimplexNoise = OpenSimplexNoise.new()
var number_of_towns = 30
var number_towns_too_close = 0
var max_tiles:float = 900.0
var worldCells = {}
#
# position in world - Vector 2D
# moisture value: float
# temperature value: float
# altitude value: float
# biome: string
# terrain: detailed biome info: dark-forest, dark-hills
# {position: (2,2), biome:plains, moisture:0.01, temperature:0.01, altitude:0.01}

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
var biome_water_start:float
var biome_water_end:float

var altitudePlans = {
	1: {"ws":0.00, "we":0.01, "ps":0.04, "pe":0.80, "hs":0.81, "he":0.90, "ms":0.91, "me":1.0},
	2: {"ws":0.00, "we":0.09, "ps":0.10, "pe":0.30, "hs":0.31, "he":0.75, "ms":0.76, "me":1.0},
	3: {"ws":0.00, "we":0.09, "ps":0.16, "pe":0.70, "hs":0.10, "he":0.15, "ms":0.71, "me":1.0}
	}

var biomePlan = 1

func generate_map(per, oct):
	openSimplexNoise.seed = randi()
	openSimplexNoise.period = per
	openSimplexNoise.octaves = oct

	var gridName = {}
	for x in width:
		for y in height:
			var rand := 2*(abs(openSimplexNoise.get_noise_2d(x,y)))
			gridName[Vector2(x,y)] = rand
	return gridName

func _ready():
	temperature = generate_map(150,5)
	moisture = generate_map(150,5)
	altitude = generate_map(150,5)
	set_tile(width, height)
#	place_towns(number_of_towns)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		var _x = get_tree().reload_current_scene()

func place_towns(max_towns):
	var town_locations = []
	for town in max_towns:
		var px = 0
		var py = 0
		var pos = Vector2(px, py)
		var valid_town_location = false
		while !valid_town_location:
			px = int(rand_range(0, width))
			py = int(rand_range(0, height))
			pos = Vector2(px, py)
			if town_not_on_edge_of_map(pos):
				if !town_allready_placed_here(town_locations, pos):
					if town_not_near_another(town_locations, pos):
						valid_town_location = true
						town_locations.append(pos)
						townsMap.set_cellv(pos, 17)

	print("Towns too close to each other is: ", number_towns_too_close)
#	for x in town_locations.size():
#		print(town_locations[x])

func town_not_on_edge_of_map(pos):
	if (pos.x > 0 and pos.x < width - 1) and (pos.y > 0 and pos.y < height - 1):
		return true
	return false

func town_allready_placed_here(town_locations, pos):
	for x in town_locations.size():
		if pos == town_locations[x]:
			return true
	return false

func town_not_near_another(town_locations, pos):
	var found_safe_loc = true
	var nx = pos.x
	if town_locations.size() > 1:
		for x in town_locations.size():
			var ex = town_locations[x].x
			if abs(nx - ex) < 2:
				found_safe_loc = false
	return found_safe_loc


func set_tile(map_width, map_height):
	_get_biome_plan(biomePlan)
	for x in map_width:
		for y in map_height:
			var pos = Vector2(x, y)
			var alt = altitude[pos]
			var temp = temperature[pos]
			var moist = moisture[pos]
			# do we need a body of water
			if between(alt, biome_water_start, biome_water_end):
				add_water_biome(pos, moist, temp, alt)
			# ground terrain comes next
			elif between(alt, biome_plains_start, biome_plains_end):
				add_ground_biome(pos, moist, temp, alt)
			elif between(alt, biome_hills_start, biome_hills_end):
				add_hills_biome(pos, moist, temp, alt)
			else:
			# then anything above ground level
				add_mountains_biome(pos, moist, temp, alt)
	update_debug_terrain_labels()


func update_debug_terrain_labels():
	seedlabel.text = "Seed:" + str(openSimplexNoise.seed)
	if plains_tile_count > 0:
		plainslabel.visible = true
		plainslabel.text = format_coverage_string("Plains", plains_tile_count)
	if desert_tile_count > 0:
		desertlabel.visible = true
		desertlabel.text = format_coverage_string("Desert", desert_tile_count)
	if water_tile_count > 0:
		waterlabel.visible = true
		waterlabel.text = format_coverage_string("Water", water_tile_count)
	if forest_tile_count > 0:
		forestlabel.visible = true
		forestlabel.text = format_coverage_string("Forest", forest_tile_count)
	if hills_tile_count > 0:
		hillslabel.visible = true
		hillslabel.text = format_coverage_string("Hills", hills_tile_count)
	if mountains_tile_count > 0:
		mountlabel.visible = true
		mountlabel.text = format_coverage_string("Mountains", mountains_tile_count)
	if snow_tile_count > 0:
		snowlabel.visible = true
		snowlabel.text = format_coverage_string("Snow", snow_tile_count)


func add_water_biome(pos, moist:float, temp:float, alt:float):
	var terrain_id = random_tile("water")
	var terrain_name = get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	biome[pos] = {"biome":"water", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	updateBiomeCount("water")
	water_tile_count += 1

func add_ground_biome(pos, moist:float, temp:float, alt:float):
	#desert
	if between(moist, 0.0, 0.05):
		var terrain_id = random_tile("desert")
		var terrain_name = get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		biome[pos] = {"biome":"desert", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		updateBiomeCount("desert")
		desert_tile_count += 1
	#plains
	elif between(moist, 0.05, 0.4):
		var terrain_id = random_tile("plains")
		var terrain_name = get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		biome[pos] = {"biome":"plains", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		updateBiomeCount("plains")
		plains_tile_count += 1
		#forests
	elif between(moist, 0.4, 0.85):
		var terrain_id = random_tile("forest")
		var terrain_name = get_terrain_name_from_biome(terrain_id)
		tilemap.set_cellv(pos, terrain_id)
		biome[pos] = {"biome":"forest", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
		updateBiomeCount("forest")
		forest_tile_count += 1


func add_hills_biome(pos, moist, temp, alt):
	var terrain_id = random_tile("hills")
	var terrain_name = get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	biome[pos] = {"biome":"hills", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	updateBiomeCount("hills")
	hills_tile_count += 1


func add_mountains_biome(pos, moist, temp, alt):
	var terrain_id = random_tile("mountains")
	var terrain_name = get_terrain_name_from_biome(terrain_id)
	tilemap.set_cellv(pos, terrain_id)
	biome[pos] = {"biome":"mountains", "terrain": terrain_name, "moist": moist, "temp": temp, "alt": alt}
	updateBiomeCount("mountains")
	mountains_tile_count += 1


func _get_biome_plan(plan_id) -> void:
	biome_plains_start = altitudePlans[plan_id]["ps"]
	biome_plains_end = altitudePlans[plan_id]["pe"]
	biome_hills_start = altitudePlans[plan_id]["hs"]
	biome_hills_end = altitudePlans[plan_id]["he"]
	biome_mountains_start = altitudePlans[plan_id]["ms"]
	biome_mountains_end = altitudePlans[plan_id]["me"]
	biome_water_start = altitudePlans[plan_id]["ws"]
	biome_water_end = altitudePlans[plan_id]["we"]


func get_terrain_name_from_biome(terrain_id):
	var terrain_tiles_keys = tiles.keys()
	var terrain_name = terrain_tiles_keys[terrain_id]
	return terrain_name


func format_coverage_string(biomeString, biomeCount) -> String:
	var percent_string = " (%d%%)"
	var base_percent:float = (biomeCount / max_tiles) * 100
	var base_percentage = percent_string % base_percent
	return biomeString + " Count: %s %s" % [biomeCount, base_percentage]


func updateBiomeCount(biomeType):
	var counter = biomeCounts.get(biomeType)
	counter += 1
	biomeCounts[biomeType] = counter


func between(val, start, end):
	if start <= val and val < end:
		return true


func random_tile(this_biome):
	var current_biome = biome_data[this_biome]
	var rand_num = rand_range(0,1)
	var running_total = 0

	for tile in current_biome:
		running_total = running_total+current_biome[tile]
		if rand_num <= running_total:
			return int(tiles.get(tile))
