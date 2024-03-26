extends EnemyAI
class_name EnemyAI_Randomizer

var unitsByPriority = []

static var lostLastBattle: bool = false


func InitializeUnitPriorityList():
	for i in range(Enums.unitTypeCount):
		var list = []
		unitsByPriority.append(list)
	
	
func ImportUnits(unitMatrix):
	InitializeUnitPriorityList()
	
	# this makes it so the order is kept
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			if unitMatrix[col][row] != null:
				var unit: Unit = unitMatrix[col][row]
				unitsByPriority[unit.data.type].append(unit)


func AddReserveUnits():
	# keep adding units as long as we have space
	var reserve = GameManager.enemyReserves
	
	for item: Unit in reserve:
		unitsByPriority[item.data.type].append(item)
		
		
# returns a 2D array of units
func GenerateUnitMatrix():
	# pick reinforcement option
	ChooseReinforcementOption()
	
	ImportUnits(GameManager.enemyUnitMatrix)
	
	# reset enemy unit matrix
	GameManager.enemyUnitMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth)
	
	# if lost last time, add new units and shuffle list
	AddReserveUnits()
	
	if lostLastBattle:
		ShuffleUnits()
	
	var unitPlacedCount: int = 0
	# if won last time, keep unit list and add new units at the back
	for type in range(unitsByPriority.size()):
		for unit: Unit in unitsByPriority[type]:
			var col: int = unitPlacedCount / GameManager.matrixHeight
			var row: int = unitPlacedCount % GameManager.matrixHeight
			
			GameManager.enemyUnitMatrix[col][row] = unit
			
			unitPlacedCount += 1
		
	# repeat this for set number of times and return best option
	
	return


# randomizes the units inside each priority level list
func ShuffleUnits():
	if unitsByPriority == null:
		print("ERROR! Unit priority list empty but calling shuffle.")
		return
		
	for i in range(len(unitsByPriority)):
		unitsByPriority[i].shuffle()


# just pick a random unit
func ChooseReinforcementOption():
	var options = GameManager.enemyEditor.GetReinforcementOptions()
	options.shuffle()
	var count = options.size()
	
	for item: ReinforcementOptionButton in options:
		if !item.PurchseUnit():
			return
