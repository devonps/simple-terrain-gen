extends Node2D

export var width = 17
export var height = 30

onready var tilemap = $TileMap

var temperature = {}
var moisture = {}
var altitude = {}
var biome = {}
var openSimplexNoise = OpenSimplexNoise.new()

var tiles = {
	"desert_dark": 0,
	"desert_light": 1,
	"desert_lightest": 2,
	"forest_dark": 3,
	"forest_light": 4,
	"grass_dark": 5,
	"grass_light": 6,
	"hills_dark": 7,
	"hills_light": 8,
	"lake_dark": 9,
	"lake_light": 10,
	"mountains_dark": 11,
	"mountains_light": 12,
	"river_dark": 13,
	"riverbank_light": 14,
	"snow": 15,
	"snow_cap": 16
}

var biome_data = {
	"plains": {"grass_light": 0.90, "grass_dark": 0.10},
	"desert": {"desert_dark": 0.98, "mountains_light": 0.02},
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
	print(openSimplexNoise.seed)
	set_tile(width, height)


func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func set_tile(width, height):

	var ground_tile_count = 0
	var non_ground_tile_count = 0

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
				#plains
				elif between(moist, 0.05, 0.4):
					biome[pos] = "plains"
					tilemap.set_cellv(pos, random_tile(biome_data,"plains"))
					updateBiomeCount("plains")
					#forests
				elif between(moist, 0.4, 0.85):
					biome[pos] = "forest"
					tilemap.set_cellv(pos, random_tile(biome_data,"forest"))
					updateBiomeCount("forest")
				#lake/body of water
				elif between(moist, 0.85, 1.0):
					biome[pos] = "water"
					tilemap.set_cellv(pos, random_tile(biome_data,"water"))
					updateBiomeCount("water")
			else:
				non_ground_tile_count += 1
			# then anything above ground level
				#hills
				if between(alt, 0.3, 0.8):
					if between(moist, 0.01, 0.09):
						biome[pos] = "snow"
						tilemap.set_cellv(pos, random_tile(biome_data,"snow"))
						updateBiomeCount("snow")
					else:
						biome[pos] = "hills"
						tilemap.set_cellv(pos, random_tile(biome_data,"hills"))
						updateBiomeCount("hills")
				#mountains
				elif between(alt, 0.8, 1.0):
					biome[pos] = "mountains"
					tilemap.set_cellv(pos, random_tile(biome_data,"mountains"))
					updateBiomeCount("mountains")
	print("Total tile count: ", ground_tile_count + non_ground_tile_count)
	print("Total ground tile count: ", ground_tile_count)
	print("Total hills/mountain tile count: ", non_ground_tile_count)

	for biome in biomeCounts:
		print("Count of ", biome, " : ", biomeCounts[biome])

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


