extends EnemyAI
class_name EnemyAI_MinMax

var unitsByPriority = []

static var lostLastBattle: bool = false

var unitMatrix
var reserve
var editor


func InitializeUnitPriorityList():
	unitsByPriority = []
	for i in range(Enums.unitTypeCount):
		var list = []
		unitsByPriority.append(list)
	
	
func ImportUnits():
	InitializeUnitPriorityList()
	
	# this makes it so the order is kept
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			if unitMatrix[col][row] != null:
				var unit: Unit = unitMatrix[col][row]
				unitsByPriority[unit.data.type].append(unit)


func AddReserveUnits():
	# keep adding units as long as we have space
	for item: Unit in reserve:
		unitsByPriority[item.data.type].append(item)
	

# place the units leftover into reserve
func ExportReserve():
	for type in range(unitsByPriority.size()):
		for unit: Unit in unitsByPriority[type]:
			GameManager.enemyReserves.append(unit)
			
			
# returns a 2D array of units
func GenerateUnitMatrix():
	print("***Starting Enemy AI Process***\n")
	
	# pick reinforcement option
	print("Enemy AI: Picking reinforcement options\n")
	ChooseReinforcementOption()
	
	print("Enemy AI: Getting current unit matrix\n")
	ImportUnits()
	
	# reset enemy unit matrix
	unitMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth)
	
	print("Enemy AI: Generating unit matrix\n")
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
			
			if col >= GameManager.matrixHeight:
				break
			if unitPlacedCount >= GameManager.matrixHeight * GameManager.matrixWidth:
				break
				
			unitMatrix[col][row] = unit
			unit.coords = Vector2(col, row)
			
			var index = reserve.find(unit)
			if index >= 0:
				reserve.remove_at(index)
			
			unitPlacedCount += 1
				
	# repeat this for set number of times and return best option
	
	print("***Finished Enemy AI Process***\n\n")
	
	return unitMatrix


# randomizes the units inside each priority level list
func ShuffleUnits():
	if unitsByPriority == null:
		print("ERROR! Unit priority list empty but calling shuffle.")
		return
		
	for i in range(len(unitsByPriority)):
		unitsByPriority[i].shuffle()


# just pick a random unit
func ChooseReinforcementOption():
	var options = editor.GetReinforcementOptions()
	options.shuffle()
	
	for item: ReinforcementOptionButton in options:
		if !item.PurchseUnit():
			return


# TODO need to account for flanking
# flanking stats should be saved to separate variable
# calculate the effect of flanking.
static func CalculateCTK(attackerMatrix, defenderMatrix):
	var totalCTK = 0
	
	for row in range(attackerMatrix[0].size()):
		var totalHP: float = 0
		var totalDPC: float = 0
		for col in range(attackerMatrix.size()):
			if defenderMatrix[col][row] != null:
				totalHP += defenderMatrix[col][row].currentHealthPoints
			if attackerMatrix[col][row] != null:
				totalDPC += attackerMatrix[col][row].GetDPC()
		
		if totalDPC != 0 and totalHP != 0:
			totalCTK += totalHP / totalDPC
	
	return totalCTK


static func CalculateWholeCTK(attackerMatrix, defenderMatrix):
	var totalHP: float = 0
	var totalDPC: float = 0
	
	for row in range(attackerMatrix[0].size()):
		for col in range(attackerMatrix.size()):
			if defenderMatrix[col][row] != null:
				totalHP += defenderMatrix[col][row].currentHealthPoints
			if attackerMatrix[col][row] != null:
				totalDPC += attackerMatrix[col][row].GetDPC()
	
	if totalDPC != 0:
		return totalHP / totalDPC
	else:
		return 10000


# TODO
# Damage Leak means the amount of unnecessary damage used to kill a unit
# Indicator of inefficient placement of units
static func CalculateDamageLeakage(attackerMatrix, defenderMatrix):
	var totalLeakage: float = 0
	
	# dictionary that holds (unit, incoming damage amount) pairs
	var attackerDict = {}
	for row in range(attackerMatrix[0].size()):
		for col in range(attackerMatrix.size()):
			if attackerMatrix[col][row] != null:
				var currentUnit: Unit = attackerMatrix[col][row]
				if attackerDict.has(currentUnit.attackTarget):
					attackerDict[currentUnit.attackTarget] += currentUnit.GetAttackDamage()
				else:
					attackerDict[currentUnit.attackTarget] = currentUnit.GetAttackDamage()
	
	for key: Unit in attackerDict.keys():
		totalLeakage += key.currentHealthPoints / attackerDict[key]
