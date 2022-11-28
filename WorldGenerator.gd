extends Node2D

export var width = 30
export var height = 30

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
var biome = {}
var openSimplexNoise = OpenSimplexNoise.new()
var number_of_towns = 30
var number_towns_too_close = 0
var max_tiles:float = 900.0

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
	"snow": {"snow": 0.95, "mountains_light": 0.03, "grass_light": 0.02}
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


func generate_map(per, oct):
	randomize()
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
	for x in map_width:
		for y in map_height:
			var pos = Vector2(x, y)
			var alt = altitude[pos]
			var temp = temperature[pos]
			var moist = moisture[pos]

			# ground terrain comes first
			if between(alt, 0.0, 0.3):
#				add_ground_biome(moist, pos)
				#desert
				if between(moist, 0.0, 0.05):
					biome[pos] = "desert"
					tilemap.set_cellv(pos, random_tile(biome_data,"desert"))
					updateBiomeCount("desert")
					desert_tile_count += 1
				#plains
				elif between(moist, 0.05, 0.4):
					biome[pos] = "plains"
					tilemap.set_cellv(pos, random_tile(biome_data,"plains"))
					updateBiomeCount("plains")
					plains_tile_count += 1
					#forests
				elif between(moist, 0.4, 0.85):
					biome[pos] = "forest"
					tilemap.set_cellv(pos, random_tile(biome_data,"forest"))
					updateBiomeCount("forest")
					forest_tile_count += 1
				#lake/body of water
				elif between(moist, 0.85, 1.0):
					biome[pos] = "water"
					tilemap.set_cellv(pos, random_tile(biome_data,"water"))
					updateBiomeCount("water")
					water_tile_count += 1
			else:
			# then anything above ground level
#				add_non_ground_biome(moist, pos, alt)
					#hills
				if between(alt, 0.3, 0.8):
					if between(moist, 0.01, 0.09):
						biome[pos] = "snow"
						tilemap.set_cellv(pos, random_tile(biome_data,"snow"))
						updateBiomeCount("snow")
						snow_tile_count += 1
					else:
						biome[pos] = "hills"
						tilemap.set_cellv(pos, random_tile(biome_data,"hills"))
						updateBiomeCount("hills")
						hills_tile_count += 1
				#mountains
				elif between(alt, 0.8, 1.0):
					biome[pos] = "mountains"
					tilemap.set_cellv(pos, random_tile(biome_data,"mountains"))
					updateBiomeCount("mountains")
					mountains_tile_count += 1
	print("Tiles placed")
	print(plains_tile_count)
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

func add_ground_biome(moist, pos):
	#desert
	if between(moist, 0.0, 0.05):
		biome[pos] = "desert"
		tilemap.set_cellv(pos, random_tile(biome_data,"desert"))
		updateBiomeCount("desert")
		desert_tile_count += 1
	#plains
	elif between(moist, 0.05, 0.4):
		biome[pos] = "plains"
		tilemap.set_cellv(pos, random_tile(biome_data,"plains"))
		updateBiomeCount("plains")
		plains_tile_count += 1
		#forests
	elif between(moist, 0.4, 0.85):
		biome[pos] = "forest"
		tilemap.set_cellv(pos, random_tile(biome_data,"forest"))
		updateBiomeCount("forest")
		forest_tile_count += 1
	#lake/body of water
	elif between(moist, 0.85, 1.0):
		biome[pos] = "water"
		tilemap.set_cellv(pos, random_tile(biome_data,"water"))
		updateBiomeCount("water")
		water_tile_count += 1

func add_non_ground_biome(moist, pos, alt):
		#hills
	if between(alt, 0.3, 0.8):
		if between(moist, 0.01, 0.09):
			biome[pos] = "snow"
			tilemap.set_cellv(pos, random_tile(biome_data,"snow"))
			updateBiomeCount("snow")
			snow_tile_count += 1
		else:
			biome[pos] = "hills"
			tilemap.set_cellv(pos, random_tile(biome_data,"hills"))
			updateBiomeCount("hills")
			hills_tile_count += 1
	#mountains
	elif between(alt, 0.8, 1.0):
		biome[pos] = "mountains"
		tilemap.set_cellv(pos, random_tile(biome_data,"mountains"))
		updateBiomeCount("mountains")
		mountains_tile_count += 1

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

func random_tile(data, this_biome):
	var current_biome = data[this_biome]
	var rand_num = rand_range(0,1)
	var running_total = 0

	for tile in current_biome:
		running_total = running_total+current_biome[tile]
		if rand_num <= running_total:
			return int(tiles.get(tile))


