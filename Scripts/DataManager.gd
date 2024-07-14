extends Node
class_name DataManager

static var unit_resources_path: String = "res://Data/Units/"

static var unit_stats_path: String = "res://Data/unit_stats.csv"

# index is the unit code
static var unitDict = {}

static var unitStats = {}

# key is unit type and value is a bool for purchased
static var playerPurchasedDict = {}
static var enemyPurchasedDict = {}

static var waitOrderData

# List that holds TerrainData
static var terrain_resources_path: String = "res://Data/Terrains/"
static var terrainData = []

static var showImportConsoleOutput: bool = false


# Called when the node enters the scene tree for the first time.
static func _static_init():
	unitStats = preload("res://Data/unit_stats.csv")
	if showImportConsoleOutput:
		print("***Start data import***\n")
	
	ImportUnits(Enums.Nation.Generic)
		
	for item in unitStats.records:
		unitDict[item.ID].ImportStats(item)
	
	ImportTerrain()
	
	waitOrderData = load("res://Data/Units/Generic/wait_order.tres")
	
	if showImportConsoleOutput:
		print("\n***End of data import***\n\n")


static func ImportUnits(nation: Enums.Nation):
	var path = unit_resources_path + "/" + Enums.NationToString(nation) + "/"
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var filename = dir.get_next()
	var germany_units = {}
	
	while filename != "":
		var fullpath = path + filename
		
		if '.tres.remap' in fullpath:
			fullpath = fullpath.trim_suffix('.remap')
			
		var newthing: UnitData = load(fullpath)
		if !newthing.disabled:
			germany_units[newthing.code] = newthing
			playerPurchasedDict[newthing] = newthing.startingUnit
			enemyPurchasedDict[newthing] = newthing.startingUnit
			
		filename = dir.get_next()
		
	unitDict = germany_units
	
	if showImportConsoleOutput:
		print("Imported " + str(unitDict.size()) + " units")
		
		for item in unitDict.keys():
			print(unitDict[item].name)


static func ImportTerrain():
	var path = terrain_resources_path
	var dir = DirAccess.open(path)
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		var fullpath = path + filename
		
		if '.tres.remap' in fullpath:
			fullpath = fullpath.trim_suffix('.remap')
			
		var newthing: TerrainData = load(fullpath)
		if !newthing.disabled:
			terrainData.append(newthing)
			
		filename = dir.get_next()
	
	if showImportConsoleOutput:
		print("Imported " + str(terrainData.size()) + " TerrainData.")
	
		for item in terrainData:
			print(item.name)
	
	
static func GetPurchasedUnits(player: bool, completed: bool = true):
	var output = []
	var targetDict = playerPurchasedDict
	if !player:
		targetDict = enemyPurchasedDict
	
	for key in targetDict.keys():
		if targetDict[key] == completed:
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
