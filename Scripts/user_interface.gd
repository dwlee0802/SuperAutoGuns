extends Control
class_name UserInterface

var unitCardScene = load("res://Scenes/unit_card.tscn")

var slotScene = load("res://Scenes/unit_slot.tscn")

var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")

@onready var unitMatrix = $Root/MiddleScreen/CombinedUnitMatrixEditor/UnitMatrix/HBoxContainer


# makes a grid with specified width and height slots
func GenerateGrid(colCount: int, rowCount: int):
	# clear preexisting grid
	var cols = unitMatrix.get_children()
	
	for item in cols:
		item.queue_free()
	
	for i in range(colCount):
		var newCol = VBoxContainer.new()
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			
			newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			
			# connect signals
			newSlot.dropped.connect(OnUnitCardDropped)
			
		unitMatrix.add_child(newCol)
		newCol.reparent(unitMatrix)
	
	
		
func SetFundsLabel(isPlayerTurn: bool):
	if isPlayerTurn:
		$Root/MiddleScreen/MidLeftScreen/FundsLabel.text = "Funds: " + str(GameManager.playerFunds)
	else:
		$Root/MiddleScreen/MidLeftScreen/FundsLabel.text = "Funds: " + str(GameManager.enemyFunds)


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
	
	
func ExportReserve():
	var reserveContainer: ReserveContainer = $Root/MiddleScreen/MidLeftScreen/ReserveUI/Reserve/HBoxContainer
	var newReserve = []
	for child in reserveContainer.get_children():
		newReserve.append(child.unit)
		
	print("current reserve count: " + str(newReserve.size()))
	
	return newReserve
	
	
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
		newOption.pressed.connect(SetFundsLabel.bind(GameManager.isPlayerTurn))


# include middle
# -1: middle col is owned by right side
# 0: leave middle col empty
# 1: middle col is owned by left side
func ImportUnitMatrix(leftUnitMatrix, rightUnitMatrix, includeMiddle: int):
	var _frontLineUI
	print("importing unit matrix")
	# clear unit cards
	for col in unitMatrix.get_children():
		if col is TextureRect:
			_frontLineUI = col
			continue
		for slot in col.get_children():
			for i in range(slot.get_child_count()):
				var target = slot.get_child(i)
				if !(target is TextureRect):
					target.queue_free()

	var colCount = unitMatrix.get_child_count()
	
	# 0 1 2 |3| 4 5 6
	var leftMatrixColCount = int((colCount) / 2) + includeMiddle
	var leftStartingColIndex = int((colCount) / 2) + includeMiddle - 1
	
	var rightMatrixColCount = int((colCount) / 2) - includeMiddle
	var rightStartingColIndex = colCount - int((colCount) / 2) - includeMiddle
	
	if includeMiddle == 0:
		leftMatrixColCount = int((colCount) / 2) #3
		rightMatrixColCount = int((colCount) / 2) #3
		leftStartingColIndex = leftMatrixColCount - 1 #2
		rightStartingColIndex = colCount - int((colCount) / 2) #4
	elif includeMiddle == -1:
		leftMatrixColCount = int((colCount) / 2) #3
		rightMatrixColCount = int((colCount) / 2) + 1 #4
		leftStartingColIndex = leftMatrixColCount - 1 #2
		rightStartingColIndex = colCount - int((colCount) / 2) - 1 #3
	elif includeMiddle == 1:
		leftMatrixColCount = int((colCount) / 2) + 1 #4
		rightMatrixColCount = int((colCount) / 2) #3
		leftStartingColIndex = leftMatrixColCount #3
		rightStartingColIndex = colCount - int((colCount) / 2) #4
		
	GameManager.PrintUnitMatrix(leftUnitMatrix)
	GameManager.PrintUnitMatrix(rightUnitMatrix)
	
	# fill in from middle column and go backwards
	for col in range(min(leftUnitMatrix.size(), leftMatrixColCount)):
		for row in range(leftUnitMatrix[col].size()):
			if leftUnitMatrix[col][row] != null:
				var newCard: UnitCard = _InstantiateUnitCard()
				var slot: UnitSlot
				if includeMiddle == 1:
					slot = unitMatrix.get_child(leftStartingColIndex - col - 1).get_child(row)
				elif includeMiddle == -1:
					slot = unitMatrix.get_child(leftStartingColIndex - col).get_child(row)
				else:
					slot = unitMatrix.get_child(leftStartingColIndex - col).get_child(row)
					
				slot.add_child(newCard)
				newCard.reparent(slot)
				newCard.SetUnit(leftUnitMatrix[col][row])
				
	for col in range(min(rightUnitMatrix.size(), rightMatrixColCount)):
		for row in range(rightUnitMatrix[col].size()):
			if rightUnitMatrix[col][row] != null:
				var newCard: UnitCard = _InstantiateUnitCard()
				var slot: UnitSlot
				if includeMiddle == 1:
					slot = unitMatrix.get_child(rightStartingColIndex - col - 1).get_child(row)
				elif includeMiddle == -1:
					slot = unitMatrix.get_child(leftStartingColIndex - col).get_child(row)
				else:
					slot = unitMatrix.get_child(leftStartingColIndex - col).get_child(row)
					
				unitMatrix.get_child(rightStartingColIndex + col).get_child(row).add_child(newCard)
				newCard.reparent(unitMatrix.get_child(rightStartingColIndex + col).get_child(row))
				newCard.SetUnit(rightUnitMatrix[col][row])

					
# returns the state of the unit matrix
# start from the right most column
func ExportUnitMatrix(currentMatrix, includeMiddle: bool = false):
	var colCount: int = int(unitMatrix.get_child_count() / 2)
	if includeMiddle:
		colCount += 1
	
	var invertY: bool = true
	
	# column index
	for offset in range(colCount):
		# row index
		for row in range(unitMatrix.get_child(colCount - offset - 1).get_child_count()):
			if unitMatrix.get_child(colCount - offset - 1).get_child(row).get_child_count() == 2:
				var unit_there = unitMatrix.get_child(colCount - offset - 1).get_child(row).get_child(-1)
				if invertY:
					currentMatrix[offset][row] = unit_there.unit
				else:
					currentMatrix[colCount - offset - 1][row] = unit_there.unit
			else:
				if invertY:
					currentMatrix[offset][row] = null
				else:
					currentMatrix[colCount - offset - 1][row] = null


func HideControlButtons():
	$ControlButtons.visible = false


func OnUnitCardDropped():
	HideControlButtons()
	
	if GameManager.isPlayerTurn:
		ExportUnitMatrix(GameManager.playerUnitMatrix, false)
		GameManager.playerReserves = ExportReserve()
	else:
		ExportUnitMatrix(GameManager.enemyUnitMatrix, false)
		GameManager.enemyReserves = ExportReserve()


func SetTurnLabel(isPlayerTurn):
	var label = $Root/MiddleScreen/MidLeftScreen/TurnLabel
	if isPlayerTurn:
		label.text = "Player's Turn"
		if GameManager.playerAttacking:
			label.text += " - Offensive"
		else:
			label.text += " - Defensive."
	else:
		label.text = "Enemy's Turn"
		if !GameManager.playerAttacking:
			label.text += " - Offensive"
		else:
			label.text += " - Defensive."
		
