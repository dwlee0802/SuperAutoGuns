extends Control
class_name UnitMatrixEditor

@export var isPlayer: bool

@export var invertY: bool = false

@onready var unitMatrix = $UnitMatrixEditor/UnitMatrix/HBoxContainer

var unitCardScene = load("res://Scenes/unit_card.tscn")
var slotScene = load("res://Scenes/unit_slot.tscn")

@onready var reinforcementUI = $UnitMatrixEditor/Reinforcement/HBoxContainer
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var reinforcementOptionCount: int = 6

@onready var reserveUI = $UnitMatrixEditor/Reserve/HBoxContainer

@onready var controlButtons = $ControlButtons
@onready var swapButton: Button = controlButtons.get_node("SwapButton")
@onready var mergeButton: Button = controlButtons.get_node("MergeButton")


func _ready():
	$UnitMatrixEditor/Reinforcement/RerollButton.pressed.connect(GenerateReinforcementOptions.bind(Enums.Nation.Generic))
	GenerateGrid(GameManager.matrixWidth, GameManager.matrixHeight)
	GenerateReinforcementOptions(Enums.Nation.Generic)
	UpdateFundsLabel()
	
	$UnitMatrixEditor/Reserve/HBoxContainer.dropped.connect(ExportReserve)
	$UnitMatrixEditor/Reserve/HBoxContainer.dropped.connect(ExportUnitMatrix)
	
	if isPlayer:
		$UnitMatrixEditor/UnitMatrix/Label.text = "Player Army Layout"
	else:
		$UnitMatrixEditor/UnitMatrix/Label.text = "Enemy Army Layout"
	
	$UnitMatrixEditor/ActionButtons/HealButton.pressed.connect(_heal_unit_button_pressed)
	$UnitMatrixEditor/ActionButtons/SellButton.pressed.connect(_sell_unit_button_pressed)
	
	$ControlButtons/SwapButton.pressed.connect(HideControlButtons)
	$ControlButtons/MergeButton.pressed.connect(HideControlButtons)
	
	HideControlButtons()
	
	
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
			
			if invertY:
				newSlot.coords = Vector2(colCount - 1 - i, j)
			else:
				newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			newSlot.dropped.connect(ExportReserve)
			newSlot.dropped.connect(ExportUnitMatrix)
			newSlot.dropped.connect(HideControlButtons)
		unitMatrix.add_child(newCol)
		newCol.reparent(unitMatrix)
		
	
# reads the unit matrix in Game and shows it in the UI
func ImportUnitMatrix():
	# clear unit cards
	for col in unitMatrix.get_children():
		for slot in col.get_children():
			for i in range(slot.get_child_count()):
				var target = slot.get_child(i)
				if !(target is TextureRect):
					target.queue_free()
						
	var currentMatrix
	if isPlayer:
		currentMatrix = GameManager.playerUnitMatrix
	else:
		currentMatrix = GameManager.enemyUnitMatrix
		
	# column index
	for col in range(unitMatrix.get_child_count()):
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
					
	
	if isPlayer:
		print("Current player unit count: " + str(GameManager.UnitCount(GameManager.playerUnitMatrix)))
	else:
		print("Current enemy unit count: " + str(GameManager.UnitCount(GameManager.enemyUnitMatrix)))
	
	
# returns the state of the unit matrix
func ExportUnitMatrix():
	var currentMatrix
	if isPlayer:
		currentMatrix = GameManager.playerUnitMatrix
	else:
		currentMatrix = GameManager.enemyUnitMatrix
		
	# column index
	for col in range(unitMatrix.get_child_count()):
		# row index
		for row in range(unitMatrix.get_child(col).get_child_count()):
			if unitMatrix.get_child(col).get_child(row).get_child_count() == 2:
				var unit_there = unitMatrix.get_child(col).get_child(row).get_child(-1)
				if invertY:
					currentMatrix[unitMatrix.get_child_count() - 1 - col][row] = unit_there.unit
				else:
					currentMatrix[col][row] = unit_there.unit
			else:
				if invertY:
					currentMatrix[unitMatrix.get_child_count() - 1 - col][row] = null
				else:
					currentMatrix[col][row] = null
						
	if isPlayer:
		print("Current player unit count: " + str(GameManager.UnitCount(GameManager.playerUnitMatrix)) + "\n")
	else:
		print("Current enemy unit count: " + str(GameManager.UnitCount(GameManager.enemyUnitMatrix)) + "\n")


# make unit icons based on player's reserves
func ImportReserve():
	# clear children
	var children = reserveUI.get_children()
	for item in children:
		item.queue_free()
	
	var reserve
	if isPlayer:
		reserve = GameManager.playerReserves
	else:
		reserve = GameManager.enemyReserves
		
	for unit: Unit in reserve:
		var newCard: UnitCard = _InstantiateUnitCard()
		newCard.SetUnit(unit)
		reserveUI.add_child(newCard)
	
	# free reference
	if UnitCard.selected != null:
		UnitCard.selected.selectionIndicator.visible = false
	UnitCard.selected = null
	

func ExportReserve():
	var newReserve = []
	for child in reserveUI.get_children():
		newReserve.append(child.unit)
	
	if isPlayer:
		GameManager.playerReserves = newReserve
	else:
		GameManager.enemyReserves = newReserve
		
	print("current reserve count: " + str(newReserve.size()))
	

# populate reinforcement option buttons
func GenerateReinforcementOptions(nation: Enums.Nation):
	# clear children
	var children = reinforcementUI.get_children()
	for item in children:
		item.queue_free()
		
	for i in range(reinforcementOptionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		newOption.isPlayer = isPlayer
		newOption.SetData(DataManager.unitDict[nation].pick_random())
		reinforcementUI.add_child(newOption)
		newOption.pressed.connect(ImportReserve)
		newOption.pressed.connect(UpdateFundsLabel)
	

func GetReinforcementOptions():
	return reinforcementUI.get_children()
	
	
func GetUnitCardAt(col, row):
	var slot
	
	# count from back if inverted
	if invertY:
		slot = unitMatrix.get_child(GameManager.matrixWidth - 1 - col).get_child(row)
	else:
		slot = unitMatrix.get_child(col).get_child(row)
		
	if slot.get_child_count() > 1:
		return slot.get_child(1)
	else:
		return null


func UpdateAttackLines():
	var mat = GameManager.playerAttackTargetMatrix
	if !isPlayer:
		mat = GameManager.enemyAttackTargetMatrix
	
	for i in range(mat.size()):
		for j in range(mat[i].size()):
			var unitCard: UnitCard = GetUnitCardAt(i, j)
			if unitCard != null:
				unitCard.attackLine.visible = false
				if mat[i][j] != null:
					var attackCoord = mat[i][j]
					var targetCard
					if !isPlayer:
						targetCard = GameManager.playerEditor.GetUnitCardAt(attackCoord.x, attackCoord.y)
					else:
						targetCard = GameManager.enemyEditor.GetUnitCardAt(attackCoord.x, attackCoord.y)
					
					if targetCard == null:
						continue
					
					unitCard.SetAttackLine(targetCard.global_position + Vector2(32, 32))
					unitCard.attackLine.visible = true


func UpdateMovementLabels():
	var mat = GameManager.playerUnitMatrix
	if !isPlayer:
		mat = GameManager.enemyUnitMatrix
	
	for i in range(mat.size()):
		for j in range(mat[i].size()):
			var unitCard: UnitCard = GetUnitCardAt(i, j)
			if unitCard != null:
				unitCard.UpdateMovementLabel()
				
				
func UpdateAttackLabels():
	var mat = GameManager.playerUnitMatrix
	if !isPlayer:
		mat = GameManager.enemyUnitMatrix
	
	for i in range(mat.size()):
		for j in range(mat[i].size()):
			var unitCard: UnitCard = GetUnitCardAt(i, j)
			if unitCard != null:
				unitCard.UpdateAttackLabel()
			

func UpdateFundsLabel():
	var label = $UnitMatrixEditor/Reinforcement/FundsLabel
	if isPlayer:
		label.text = "Funds: " + str(GameManager.playerFunds)
	else:
		label.text = "Funds: " + str(GameManager.enemyFunds)


func UpdateHealCost():
	var label = $UnitMatrixEditor/ActionButtons/HealButton
	label.disabled = true
	if isPlayer:
		if UnitCard.selected != null:
			var amount = GameManager.healCostPerStackCount * UnitCard.selected.unit.stackCount
			var text = "Heal Cost: {num}"
			label.text = text.format({"num": amount})
			if amount <= GameManager.playerFunds and UnitCard.selected.unit.currentHealthPoints < UnitCard.selected.unit.data.maxHealthPoints:
				label.disabled = false
		else:
			label.text = "Heal"


func UpdateSellButton():
	var label = $UnitMatrixEditor/ActionButtons/SellButton
	label.disabled = true
	if isPlayer:
		if UnitCard.selected != null:
			var amount = UnitCard.selected.unit.data.purchaseCost * UnitCard.selected.unit.stackCount / 2
			var text = "Sell Income: {num}"
			label.text = text.format({"num": amount})
			label.disabled = false
		else:
			label.text = "Sell"
	
	
func _heal_unit_button_pressed():
	if isPlayer:
		HealUnit(UnitCard.selected)
		
		
func _sell_unit_button_pressed():
	if isPlayer:
		SellUnit(UnitCard.selected)
	
	
func HealUnit(unitCard: UnitCard):
	var amount = GameManager.healCostPerStackCount * unitCard.unit.stackCount
	if unitCard.unit.isPlayer:
		if GameManager.playerFunds >= amount:
			GameManager.ChangeFunds(-amount)
			unitCard.unit.RatioHeal(1)
		else:
			print("ERROR! Shouldn't be able to press Heal button when not enough funds.")
	
	ImportReserve()
	ImportUnitMatrix()
	UpdateHealCost()
	UpdateSellButton()


# sell selected unit and refund its cost
func SellUnit(unitCard: UnitCard):
	if unitCard != null:
		if unitCard.unit.isPlayer:
			var refundAmount: int = int(unitCard.unit.data.purchaseCost * unitCard.unit.stackCount * GameManager.refundRatio)
			if unitCard.get_parent() is ReserveContainer:
				GameManager.RemoveUnitFromReserve(unitCard.unit)
				unitCard.queue_free()
			elif unitCard.get_parent() is UnitSlot:
				GameManager.RemoveUnit(unitCard.unit)
				unitCard.queue_free()
			
			GameManager.ChangeFunds(refundAmount)
			
			print("Sold unit. " + str(refundAmount) + " refunded.\n")
	
	
# make new card and connect signals
func _InstantiateUnitCard() -> UnitCard:
	var newCard: UnitCard = unitCardScene.instantiate()
	newCard.clicked.connect(UpdateHealCost)
	newCard.clicked.connect(UpdateSellButton)
	newCard.clicked.connect(HideControlButtons)
	newCard.merged.connect(UpdateHealCost)
	newCard.merged.connect(ImportUnitMatrix)
	newCard.merged.connect(ImportReserve)
	newCard.was_right_clicked.connect(UpdateControlButtons)
	
	return newCard


func ReloadFundsRelatedUI():
	UpdateFundsLabel()
	UpdateHealCost()
	UpdateSellButton()


# handles showing control button on target
func UpdateControlButtons(rightClickTarget: UnitCard):
	if rightClickTarget != UnitCard.selected:
		# connect signals if same type
		if rightClickTarget.unit.data == UnitCard.selected.unit.data:
			controlButtons.visible = true
			controlButtons.global_position = rightClickTarget.global_position
			
			# disconnect signals
			for item in swapButton.pressed.get_connections():
				swapButton.pressed.disconnect(item.callable)
			for item in mergeButton.pressed.get_connections():
				mergeButton.pressed.disconnect(item.callable)
				
			swapButton.pressed.connect(rightClickTarget._swap_button_pressed)
			mergeButton.pressed.connect(rightClickTarget._merge_button_pressed)
			
			#print("number of subs after connecting: " + str(swapButton.pressed.get_connections().size()))
			

func HideControlButtons():
	controlButtons.visible = false
	
	# disconnect signals
	for item in mergeButton.pressed.get_connections():
		mergeButton.pressed.disconnect(item.callable)
	for item in swapButton.pressed.get_connections():
		swapButton.pressed.disconnect(item.callable)
	
	
func _unhandled_key_input(_event):
	if Input.is_action_just_pressed("left_click"):
		HideControlButtons()
		
		if UnitCard.selected != null:
			UnitCard.selected.get_node("TextureRect/SelectionIndicator").visible = false
			
		UnitCard.selected = null
	
