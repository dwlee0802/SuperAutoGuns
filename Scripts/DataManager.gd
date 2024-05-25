extends Node

static var unit_resources_path: String = "res://Data/Units/"

# index is the country
static var unitDict = {}


# Called when the node enters the scene tree for the first time.
static func _static_init():
	print("***Start data import***\n")
	
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
		
		if '.tres.remap' in fullpath: # <---- NEW
			fullpath = fullpath.trim_suffix('.remap') # <---- NEW
			
		var newthing = load(fullpath)
		if !newthing.disabled:
			germany_units.append(newthing)
		filename = dir.get_next()
		
	unitDict[nation] = germany_units
	
	print("Imported " + str(unitDict[nation].size()) + " units for " + Enums.NationToString(nation))
	
	
	for item in unitDict[nation]:
		print(item.name)
