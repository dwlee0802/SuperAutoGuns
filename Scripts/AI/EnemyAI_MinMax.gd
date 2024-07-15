extends EnemyAI
class_name EnemyAI_MinMax

var units = []
var unitsByType = []

var unitsByTypeTemp = []

static var lostLastBattle: bool = false

	
func InitializeUnitTypeList():
	unitsByType = []
	for i in range(Enums.unitTypeCount):
		var list = []
		unitsByType.append(list)
		
	unitsByTypeTemp = []
	for i in range(Enums.unitTypeCount):
		var list = []
		unitsByTypeTemp.append(list)
		
		
func ImportUnits():
	InitializeUnitTypeList()
	
	# this makes it so the order is kept
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			if unitMatrix[col][row] != null:
				var unit: Unit = unitMatrix[col][row]
				unitsByType[unit.data.type].append(unit)
				units.append(unit)


func AddReserveUnits():
	# keep adding units as long as we have space
	for item: Unit in reserve:
		unitsByType[item.data.type].append(item)
		

# place the units leftover into reserve
func ExportReserve():
	reserve.append_array(units)
			
			
# returns the best unit matrix among the randomly generated options
func GenerateUnitMatrix(tryCount: int = 10):
	print("***Starting Enemy AI MinMax Process***\n")
	
	# pick reinforcement option
	print("Enemy AI: Picking reinforcement options\n")
	ChooseReinforcementOption()
	
	print("Enemy AI: Getting units\n")
	ImportUnits()
	AddReserveUnits()

	# reset enemy unit matrix
	unitMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth)
	reserve = []
	
	print("Enemy AI: Generating unit matrix\n")
	var bestScore: float = 0
	var bestLayout
	
	# for all units starting from armor, randomly pick a row and place them there
	# if a unit that is the same type already is there, merge
	for i in range(tryCount):
		# array to keep track of number of units in row
		var currentMatrix = GameManager.Make2DArray(GameManager.matrixHeight, GameManager.matrixWidth)
		
		# initialize array
		unitsByTypeTemp = []
		for ty in range(Enums.unitTypeCount):
			var list = []
			unitsByTypeTemp.append(list)
			
		# make deep copy of unit array
		for type in range(Enums.unitTypeCount):
			for unit in unitsByType[type]:
				unitsByTypeTemp[type].append(unit.Duplicate())
		
		var rowUnitCount = []
		rowUnitCount.resize(GameManager.matrixHeight)
		rowUnitCount.fill(0)
		
		var finishPlacingUnits: bool = false
		
		for type in range(Enums.unitTypeCount):
			if finishPlacingUnits:
				break
					
			while unitsByTypeTemp[type].size() > 0:
				if finishPlacingUnits:
					break
					
				var unit: Unit = unitsByTypeTemp[type].pop_back()
				
				# pick random row
				var randomRow = randi_range(0, GameManager.matrixHeight - 1)
				# if randomRow's unitCount is above the limit, pick again
				if rowUnitCount[randomRow] >= GameManager.matrixWidth:
					var fullRowCount: int = 1
					while true:
						randomRow += 1
						randomRow = randomRow % GameManager.matrixHeight
						# check if new random row is full
						if rowUnitCount[randomRow] >= GameManager.matrixWidth:
							# its full
							fullRowCount += 1
							# we reached our max row limit. all rows are full.
							if fullRowCount >= GameManager.matrixHeight:
								# cant place stuff anymore so finish placing units
								finishPlacingUnits = true
								break
						else:
							# not full. choose that row
							break
					
				if finishPlacingUnits:
					break
					
				# check if unit in front is same type
				# if empty, just place it there
				if rowUnitCount[randomRow] == 0:
					currentMatrix[rowUnitCount[randomRow]][randomRow] = unit
					rowUnitCount[randomRow] += 1
				# if not empty, check type
				elif currentMatrix[rowUnitCount[randomRow] - 1][randomRow].data == unit.data:
					# same type. merge
					currentMatrix[rowUnitCount[randomRow] - 1][randomRow].Merge(unit)
				else:
					# different type. place behind
					currentMatrix[rowUnitCount[randomRow]][randomRow] = unit
					rowUnitCount[randomRow] += 1
				
		# assess their value and update bestScore if needed
		
		GameManager.PrintUnitMatrix(currentMatrix)
	
	print("***Finished Enemy AI Process***\n\n")
	
	return unitMatrix


# randomizes the units inside each priority level list
func ShuffleUnits():
	pass


# just pick a random unit
func ChooseReinforcementOption():
	var options = editor.GetReinforcementOptions()
	options.shuffle()
	
	# buy until out of money or out of options
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


static func CalculateTotalCTK(attackerMatrix, defenderMatrix):
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
