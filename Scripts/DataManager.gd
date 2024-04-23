extends Node

static var unit_resources_path: String = "res://Data/Units/"

# index is the country
static var unitDict = {}


# Called when the node enters the scene tree for the first time.
static func _static_init():
	print("***Start data import***\n")
	
	var germany_path = unit_resources_path + "/" + Enums.NationToString(Enums.Nation.Germany) + "/"
	var dir = DirAccess.open(germany_path)
	dir.list_dir_begin()
	var filename = dir.get_next()
	var germany_units = []
	
	while filename != "":
		var fullpath = germany_path + filename
		var newthing = load(fullpath)
		germany_units.append(newthing)
		filename = dir.get_next()
		
	unitDict[Enums.Nation.Germany] = germany_units
	
	print("Imported " + str(unitDict[Enums.Nation.Germany].size()) + " units for " + Enums.NationToString(Enums.Nation.Germany))
	
	
	for item in unitDict[Enums.Nation.Germany]:
		print(item.name)
	
	
	var ussr_path = unit_resources_path + "/" + Enums.NationToString(Enums.Nation.USSR) + "/"
	dir = DirAccess.open(ussr_path)
	dir.list_dir_begin()
	filename = dir.get_next()
	var ussr_units = []
	
	while filename != "":
		var fullpath = ussr_path + filename
		var newthing = load(fullpath)
		ussr_units.append(newthing)
		filename = dir.get_next()
		
	unitDict[Enums.Nation.USSR] = ussr_units
	
	print("Imported " + str(unitDict[Enums.Nation.USSR].size()) + " units for " + Enums.NationToString(Enums.Nation.USSR))
	
	for item in unitDict[Enums.Nation.USSR]:
		print(item.name)
	
	ImportUnits(Enums.Nation.Generic)
	
	print("\n***End of data import***\n\n")


static func ImportUnits(nation: Enums.Nation):
	var path = unit_resources_path + "/" + Enums.NationToString(nation) + "/"
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var filename = dir.get_next()
	var germany_units = []
	
	while filename != "":
		var fullpath = path + filename
		var newthing = load(fullpath)
		if !newthing.disabled:
			germany_units.append(newthing)
		filename = dir.get_next()
		
	unitDict[nation] = germany_units
	
	print("Imported " + str(unitDict[nation].size()) + " units for " + Enums.NationToString(nation))
	
	
	for item in unitDict[nation]:
		print(item.name)
