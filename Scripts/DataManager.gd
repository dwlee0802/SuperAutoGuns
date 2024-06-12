extends Node
class_name DataManager

static var unit_resources_path: String = "res://Data/Units/"

# index is the country
static var unitDict = {}

# key is unit type and value is a bool for purchased
static var playerPurchasedDict = {}
static var enemyPurchasedDict = {}

static var waitOrderData


# Called when the node enters the scene tree for the first time.
static func _static_init():
	print("***Start data import***\n")
	
	ImportUnits(Enums.Nation.Generic)
	
	waitOrderData = load("res://Data/Units/Generic/wait_order.tres")
	
	print("\n***End of data import***\n\n")


static func ImportUnits(nation: Enums.Nation):
	var path = unit_resources_path + "/" + Enums.NationToString(nation) + "/"
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var filename = dir.get_next()
	var germany_units = []
	
	while filename != "":
		var fullpath = path + filename
		
		if '.tres.remap' in fullpath:
			fullpath = fullpath.trim_suffix('.remap')
			
		var newthing: UnitData = load(fullpath)
		if !newthing.disabled:
			germany_units.append(newthing)
			playerPurchasedDict[newthing] = newthing.startingUnit
			enemyPurchasedDict[newthing] = newthing.startingUnit
			
		filename = dir.get_next()
		
	unitDict[nation] = germany_units
	
	print("Imported " + str(unitDict[nation].size()) + " units for " + Enums.NationToString(nation))
	
	
	for item in unitDict[nation]:
		print(item.name)


static func GetPurchasedUnits(player: bool):
	var output = []
	var targetDict = playerPurchasedDict
	if !player:
		targetDict = enemyPurchasedDict
	
	for key in targetDict.keys():
		if targetDict[key]:
			output.append(key)
	
	return output


static func ResearchUnit(player: bool, unit: UnitData):
	var targetDict = playerPurchasedDict
	if !player:
		targetDict = enemyPurchasedDict
	
	targetDict[unit] = true
	
	if player:
		print("Player Researched " + unit.name)
	else:
		print("Enemy Researched " + unit.name)


static func ResetResearch():
	playerPurchasedDict = {}
	enemyPurchasedDict = {}
