extends Control
class_name UserInterface

var unitCardScene = load("res://Scenes/unit_card.tscn")

var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")


func SetFundsLabel(fundsAmount: int):
	$Root/MiddleScreen/MidLeftScreen/FundsLabel.text = "Funds: " + str(fundsAmount)


func ImportReserve(reserveUnits):
	# clear children
	var reserveContainer: ReserveContainer = $Root/MiddleScreen/MidLeftScreen/ReserveUI/Reserve/HBoxContainer
	var children = reserveContainer.get_children()
	for item in children:
		item.queue_free()
		
	for unit: Unit in reserveUnits:
		var newCard: UnitCard = _InstantiateUnitCard()
		newCard.SetUnit(unit)
		reserveContainer.add_child(newCard)
	
	# free reference
	if UnitCard.selected != null:
		UnitCard.selected.selectionIndicator.visible = false
	UnitCard.selected = null
	
	
# make new card and connect signals
func _InstantiateUnitCard() -> UnitCard:
	var newCard: UnitCard = unitCardScene.instantiate()
	
	# connect signals
	
	return newCard
	
	
# populate reinforcement option buttons
func GenerateReinforcementOptions(isPlayer: bool, optionCount: int, nation: Enums.Nation = Enums.Nation.Generic):
	# clear children
	var reinforcementContainer = $Root/BottomScreen/Reinforcement/HBoxContainer
	var children = reinforcementContainer.get_children()
	for item in children:
		item.queue_free()
		
	for i in range(optionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		
		# who's turn is it
		newOption.isPlayer = isPlayer
		
		newOption.SetData(DataManager.unitDict[nation].pick_random())
		reinforcementContainer.add_child(newOption)
		
		# connect signals
		#newOption.pressed.connect(ImportReserve)
		#newOption.pressed.connect(UpdateFundsLabel)


# include middle
# -1: middle col is owned by right side
# 0: leave middle col empty
# 1: middle col is owned by left side
func ImportUnitMatrix(leftUnitMatrix, rightUnitMatrix, includeMiddle: int):
	var unitMatrix = $Root/MiddleScreen/CombinedUnitMatrixEditor/UnitMatrix/HBoxContainer
	var frontLineUI
	print("importing unit matrix")
	# clear unit cards
	for col in unitMatrix.get_children():
		if col is TextureRect:
			frontLineUI = col
			continue
		for slot in col.get_children():
			for i in range(slot.get_child_count()):
				var target = slot.get_child(i)
				if !(target is TextureRect):
					target.queue_free()
	
	var currentMatrix = leftUnitMatrix
	var invertY: bool = true
	
	var colCount = unitMatrix.get_child_count()
	
	var leftMatrixColCount = int((colCount + 1) / 2) + includeMiddle
	var rightMatrixColCount = int((colCount + 1) / 2) - includeMiddle
	
	# column index
	# goes over the full combined matrix
	# 0 1 2  3  4 5 6
	for col in range(unitMatrix.get_child_count()):
		if col < leftMatrixColCount:
			currentMatrix = leftUnitMatrix
			invertY = true
		elif col >= colCount - rightMatrixColCount:
			currentMatrix = rightUnitMatrix
			invertY = false
		else:
			continue
			
		# row index
		for row in range(unitMatrix.get_child(col).get_child_count()):
			if currentMatrix[col][row] != null:
				var newCard: UnitCard = _InstantiateUnitCard()
				# add from back if y inverted
				if invertY:
					unitMatrix.get_child(unitMatrix.get_child_count() - 1 - col).get_child(row).add_child(newCard)
					newCard.reparent(unitMatrix.get_child(unitMatrix.get_child_count() - 1 - col).get_child(row))
					newCard.SetUnit(currentMatrix[col][row])
				else:
					unitMatrix.get_child(col).get_child(row).add_child(newCard)
					newCard.reparent(unitMatrix.get_child(col).get_child(row))
					newCard.SetUnit(currentMatrix[col][row])
					

# returns the state of the unit matrix
# start from the right most column
func ExportUnitMatrix(currentMatrix, includeMiddle: bool = false):
	var unitMatrix = $Root/MiddleScreen/CombinedUnitMatrixEditor/UnitMatrix/HBoxContainer
	
	var colCount: int = int(unitMatrix.get_child_count() / 2)
	if includeMiddle:
		colCount += 1
	
	var invertY: bool = true
	
	# column index
	for offset in range(colCount):
		# row index
		for row in range(unitMatrix.get_child(colCount - offset).get_child_count()):
			if unitMatrix.get_child(colCount - offset).get_child(row).get_child_count() == 2:
				var unit_there = unitMatrix.get_child(colCount - offset).get_child(row).get_child(-1)
				if invertY:
					currentMatrix[offset][row] = unit_there.unit
				else:
					currentMatrix[colCount - offset][row] = unit_there.unit
			else:
				if invertY:
					currentMatrix[offset][row] = null
				else:
					currentMatrix[colCount - offset][row] = null
