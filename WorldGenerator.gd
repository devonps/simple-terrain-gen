extends Node2D

export var width = 17
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
var number_of_towns = 20

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


func generate_map(per, oct):
	randomize()
	openSimplexNoise.seed = 369495614
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
	place_towns(number_of_towns)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

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
			if town_not_on_edge_of_map(px, py):
				pos = Vector2(px, py)
				if !town_allready_placed_here(town_locations, pos):
					if town_not_near_another(town_locations, pos):
						valid_town_location = true
						town_locations.append(pos)
						townsMap.set_cellv(pos, 17)
# towns cannot be placed within 2 squares of another town
# The spread of towns looks poor - so maybe I should split the map up into quadrants
# and place a certain amount of towns in each quadrant

	for x in town_locations.size():
		print(town_locations[x])

func town_not_on_edge_of_map(px, py):
	if (px > 0 and px < width - 1) and (py > 0 and py < height - 1):
		return true
	return false

func town_allready_placed_here(town_locations, pos):
	for x in town_locations.size():
		if pos == town_locations[x]:
			return true
	return false

func town_not_near_another(town_locations, pos):
	var tx = false
	var ty = false
	var found_safe_loc = false
	if town_locations.size() > 1:
		for x in town_locations.size():
			var ex = town_locations[x].x
			var ey = town_locations[x].y
			if abs(pos.x - ex) > 1:
				tx = true
			if abs(pos.y - ey) > 1:
				ty = true
			if tx == true and ty == true:
				print("found safe location")
				found_safe_loc = true
		if found_safe_loc:
			return true
		else:
			return false
	else:
		return true




func set_tile(width, height):
	var ground_tile_count = 0
	var non_ground_tile_count = 0
	var desert_tile_count = 0
	var plains_tile_count = 0
	var water_tile_count = 0
	var forest_tile_count = 0
	var hills_tile_count = 0
	var mountains_tile_count = 0
	var snow_tile_count = 0

	for x in width:
		for y in height:
			var pos = Vector2(x, y)
			var alt = altitude[pos]
			var temp = temperature[pos]
			var moist = moisture[pos]

			# ground terrain comes first
			if between(alt, 0.0, 0.3):
				ground_tile_count += 1
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
				non_ground_tile_count += 1
			# then anything above ground level
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

	seedlabel.text = "Seed:" + str(openSimplexNoise.seed)
	if plains_tile_count > 0:
		plainslabel.visible = true
		plainslabel.text = "Plains Count:" + str(plains_tile_count)
	if desert_tile_count > 0:
		desertlabel.visible = true
		desertlabel.text = "Desert Count:" + str(desert_tile_count)
	if water_tile_count > 0:
		waterlabel.visible = true
		waterlabel.text = "Water Count:" + str(water_tile_count)
	if forest_tile_count > 0:
		forestlabel.visible = true
		forestlabel.text = "Forest Count:" + str(forest_tile_count)
	if hills_tile_count > 0:
		hillslabel.visible = true
		hillslabel.text = "Hills Count:" + str(hills_tile_count)
	if mountains_tile_count > 0:
		mountlabel.visible = true
		mountlabel.text = "Mountains Count:" + str(mountains_tile_count)
	if snow_tile_count > 0:
		snowlabel.visible = true
		snowlabel.text = "Snow Count:" + str(snow_tile_count)

func updateBiomeCount(biomeType):
	var counter = biomeCounts.get(biomeType)
	counter += 1
	biomeCounts[biomeType] = counter

func between(val, start, end):
	if start <= val and val < end:
		return true

func random_tile(data, biome):
	var current_biome = data[biome]
	var rand_num = rand_range(0,1)
	var running_total = 0

	for tile in current_biome:
		running_total = running_total+current_biome[tile]
		if rand_num <= running_total:
			return int(tiles.get(tile))


