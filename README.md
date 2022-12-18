# Simple World Builder

## Introduction
	My world builder is based on the excellent [SlothInTheHats Godot Terrain Generation repo](https://github.com/SlothInTheHat/godot_terrain_generation).

	It's a tool I'm using to help me understand:
	- Godot 4.0 better
	- How I can build and use an overworld in my roguelike RogueCowby

	My code and Godot project structure is pretty ugly!

### An overview of how it works
	There are 3 steps...

	Step 1: Uses Simplexnoise to generate temperature, moisture, and height (aka altitude in code) maps
	Step 2: For each cell in the world (my world is currently 30x30 cells) I assign a type of terrain based on its height, moisture, and temperature values.
	Step 3: I add a mixture of large, medium, and small towns across the world

	The world is then displayed and when the mouse hovers over a world cell debug information is displayed.

	Pressing the spacebar will generate a new world.

### In more detail
	There are currently 7 different biomes a world cell can choose from:
		1. Grass Plains
		2. Desert
		3. Water
		4. Forest
		5. Hills
		6. Mountains
		7. Snow

	I've disabled the selection of the water and snow biomes in the current version, but they're still in the code if you want to use them.

	Each of the above biomes are then broken down into 1 or more types of terrain such as:
		- Plains (biome)
			1. light grass (type of terrain)
			2. dark grass (type of terrain)
	
	Each type of terrain has a percentage chance of being selected.

	I've done this so that when applying this world cell to the actual game I can use the type of terrain to provide greater local variety.

	I've also setup the notion of using altitude pre-determined settings. These plans allow me to influence the overall biome selection for the world, in other words if I don't want any/many hills or mountains in the world I can just select an altitude plan to make it happen.

	As with ALL the biome types, terrain types, and altitude plans I've made everything configurable.

### Controls
	When the map is visible...
	-Drag the map around by holding the Right Mouse Button down
	-Zoom in and out using the Mouse Scroll Wheel

### Looking ahead
	1. Increasing the number of terrain types and/or biome types
	2. Exporting the world data to other formats, currently supports JSON only
