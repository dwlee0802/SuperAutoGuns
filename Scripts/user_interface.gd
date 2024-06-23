extends Control
class_name UserInterface

var unitCardScene = load("res://Scenes/unit_card.tscn")

var slotScene = load("res://Scenes/unit_slot.tscn")

var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")

@onready var unitMatrix = $Root/MiddleScreen/CombinedUnitMatrixEditor/UnitMatrix/HBoxContainer

@onready var controlButtons = $ControlButtons
@onready var swapButton: Button = controlButtons.get_node("SwapButton")
@onready var mergeButton: Button = controlButtons.get_node("MergeButton")

@export var attackColor = Color.RED
@export var defendColor = Color.BLUE
@export var middleColor = Color.DARK_RED

@onready var turnTimer: Timer = $Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/TurnTimer/TurnTimer

var popupScene = load("res://Scenes/damage_popup.tscn")


func _ready():
	$Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/HealButton.pressed.connect(HealButtonPressed)
	$Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/SellButton.pressed.connect(SellButtonPressed)
	
	$ControlButtons/SwapButton.pressed.connect(HideControlButtons)
	$ControlButtons/MergeButton.pressed.connect(HideControlButtons)
	
	# dropped unit into reserve container
	# export reserve
	$Root/MiddleScreen/MidLeftScreen/ReserveUI/Reserve/HBoxContainer.dropped.connect(DroppedIntoReserve)
	
	$Root/BottomScreen/RerollButton.pressed.connect(RerollButtonPressed)
	
	# defender goes first set attack dir ui to left
	SetAttackDirectionUI(true)
	

func DroppedIntoReserve():
	if GameManager.isPlayerTurn:
		GameManager.playerReserves = ExportReserve()
	else:
		GameManager.enemyReserves = ExportReserve()
		
	
# makes a grid with specified width and height slots
func GenerateGrid(colCount: int, rowCount: int):
	# clear preexisting grid
	var cols = unitMatrix.get_children()
	
	for item in cols:
		item.queue_free()
	
	for i in range(colCount):
		var newCol = VBoxContainer.new()
		newCol.add_theme_constant_override("separation", 10)
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			
			newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			
			# connect signals
			newSlot.dropped.connect(OnUnitCardDropped)
			
		unitMatrix.add_child(newCol)
		newCol.reparent(unitMatrix)
	
		
func SetFundsLabel(isPlayerTurn: bool = GameManager.isPlayerTurn):
	print("player: " + str(GameManager.playerFunds))
	print("enemy: " + str(GameManager.enemyFunds))
	if isPlayerTurn:
		$Root/MiddleScreen/MidLeftScreen/FundsLabel.text = tr("FUNDS") + ": " + str(GameManager.playerFunds)
	else:
		$Root/MiddleScreen/MidLeftScreen/FundsLabel.text = tr("FUNDS") + ": " + str(GameManager.enemyFunds)


func SetLastIncomeLabel(amount):
	var label = $Root/MiddleScreen/MidLeftScreen/FundsLabel/LastIncomeLabel
	label.text = str(amount)
	

func ImportReserve(reserveUnits):
	print("import reserve")
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
	newCard.was_right_clicked.connect(UpdateControlButtons)
	newCard.clicked.connect(HideControlButtons)
	newCard.merged.connect(HideControlButtons)
	
	newCard.clicked.connect(UpdateHealButtonLabel)
	newCard.clicked.connect(UpdateSellButtonLabel)
	
	newCard.merged.connect(OnCardMerged)
	
	#newCard.merged.connect(ImportUnitMatrix)
	#newCard.merged.connect(ImportReserve)
	
	return newCard


func OnCardMerged():
	if GameManager.isPlayerTurn:
		GameManager.playerReserves = ExportReserve()
	else:
		GameManager.enemyReserves = ExportReserve()
		
	
# populate reinforcement option buttons
# TODO need to make this consider bought status for each side
func GenerateReinforcementOptions(isPlayer: bool, optionCount: int, _nation: Enums.Nation = Enums.Nation.Generic):
	# clear children
	isPlayer = GameManager.isPlayerTurn
	
	var reinforcementContainer = $Root/BottomScreen/Reinforcement/HBoxContainer
	var children = reinforcementContainer.get_children()
	for item in children:
		item.queue_free()
		
	for i in range(optionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		
		# who's turn is it
		newOption.isPlayer = isPlayer
		
		newOption.SetData(DataManager.GetPurchasedUnits(isPlayer).pick_random())
		reinforcementContainer.add_child(newOption)
		
		# connect signals
		newOption.pressed.connect(SetFundsLabel.bind(GameManager.isPlayerTurn))


# checks if player has reroll cost
func RerollButtonPressed():
	var isPlayer = GameManager.isPlayerTurn
	
	# check if theres enough funds
	if isPlayer:
		if GameManager.playerFunds < GameManager.rerollCost:
			print("player has not enough funds!\n")
			return false
	else:
		if GameManager.enemyFunds < GameManager.rerollCost:
			print("enemy has not enough funds!\n")
			return false
			
	GenerateReinforcementOptions(GameManager.isPlayerTurn, GameManager.reinforcementCount)
	GameManager.ChangeFunds(-GameManager.rerollCost, isPlayer)
	
	
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
				if target is UnitCard:
					target.queue_free()

	var colCount = unitMatrix.get_child_count()
	
	var leftMatrixColCount = int((colCount) / 2) + includeMiddle
	var leftStartingColIndex = int((colCount) / 2) + includeMiddle - 1
	
	var rightMatrixColCount = int((colCount) / 2) - includeMiddle
	var rightStartingColIndex = colCount - int((colCount) / 2) - includeMiddle
	
	# 0 1 2 |3| 4 5 6
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
	
	SetSlotAvailability(0, leftMatrixColCount)
	
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
					slot = unitMatrix.get_child(rightStartingColIndex + col).get_child(row)
				elif includeMiddle == -1:
					slot = unitMatrix.get_child(rightStartingColIndex + col).get_child(row)
				else:
					slot = unitMatrix.get_child(rightStartingColIndex + col).get_child(row)
					
				slot.add_child(newCard)
				newCard.reparent(slot)
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
			var unit_there = unitMatrix.get_child(colCount - offset - 1).get_child(row).GetUnitHere()
			if unit_there != null:
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
		label.text = tr("GENERIC_PLAYER_NAME") + " " + tr("TURN")
		if GameManager.playerAttacking:
			label.text += " - " + tr("OFFENSIVE")
		else:
			label.text += " - " + tr("DEFENSIVE")
		#label.self_modulate = GameManager.playerColor
	else:
		label.text = tr("GENERIC_ENEMY_NAME") + " " + tr("TURN")
		if !GameManager.playerAttacking:
			label.text += " - " + tr("OFFENSIVE")
		else:
			label.text += " - " + tr("DEFENSIVE")
		#label.self_modulate = GameManager.enemyColor


func HealButtonPressed(unitCard = UnitCard.selected):
	if unitCard == null:
		print("heal button no selected")
		return
		
	print("heal button pressed")
	
	var amount = GameManager.healCostPerStackCount * unitCard.unit.stackCount
	
	if unitCard.unit.IsFullHealth():
		print("unit full health!")
		return
		
	if unitCard.unit.isPlayer:
		if GameManager.playerFunds >= amount:
			GameManager.ChangeFunds(-amount, unitCard.unit.isPlayer)
			unitCard.unit.RatioHeal(1)
			unitCard.UpdateHealthLabel(0)
		else:
			print("ERROR! Shouldn't be able to press Heal button when not enough funds.")
	else:
		if GameManager.enemyFunds >= amount:
			GameManager.ChangeFunds(-amount, unitCard.unit.isPlayer)
			unitCard.unit.RatioHeal(1)
			unitCard.UpdateHealthLabel(0)
		else:
			print("ERROR! Shouldn't be able to press Heal button when not enough funds.")

	SetFundsLabel()
	UpdateHealButtonLabel()
	UpdateSellButtonLabel()
		

func SellButtonPressed(unitCard = UnitCard.selected):
	if unitCard == null:
		print("sell button no selected")
		return
	else:
		var isPlayer : bool = unitCard.unit.isPlayer
		
		var refundAmount: int = int(unitCard.unit.data.purchaseCost * unitCard.unit.stackCount)
		if unitCard.unit.boughtThisTurn == false:
			refundAmount = int(GameManager.refundRatio * refundAmount)
			
		if unitCard.get_parent() is ReserveContainer:
			GameManager.RemoveUnitFromReserve(unitCard.unit)
			unitCard.queue_free()
		elif unitCard.get_parent() is UnitSlot:
			GameManager.RemoveUnit(unitCard.unit)
			unitCard.queue_free()
		
		UnitCard.selected = null
		
		GameManager.ChangeFunds(refundAmount, isPlayer)
		
		SetFundsLabel(isPlayer)
			
		print("Sold unit. " + str(refundAmount) + " refunded.\n")
	
	UpdateSellButtonLabel()
	UpdateHealButtonLabel()
		
		
func SetSlotAvailability(_startIndex: int = 0, endIndex: int = 2):
	for col in range(unitMatrix.get_child_count()):
		for row in range(unitMatrix.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrix.get_child(col).get_child(row)
			slot.SetCanBeDropped(col < endIndex)
				

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
			

func SetSlotColor(isPlayerTurn, isPlayerAttacking):
	if isPlayerAttacking:
		attackColor = GameManager.playerColor
		defendColor = GameManager.enemyColor
		middleColor = attackColor.darkened(0.5)
	else:
		attackColor = GameManager.enemyColor
		defendColor = GameManager.playerColor
		middleColor = attackColor.darkened(0.5)
	
	for col in range(unitMatrix.get_child_count()):
		for row in range(unitMatrix.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrix.get_child(col).get_child(row)
			# current turn side
			if col <= int(unitMatrix.get_child_count() / 2):
				if (isPlayerTurn and isPlayerAttacking) or (!isPlayerTurn and !isPlayerAttacking):
					# attacking. set slot to red
					slot.get_node("SideIndicator").self_modulate = attackColor
				else:
					# defending. set slot to blue
					slot.get_node("SideIndicator").self_modulate = defendColor
			else:
				if (isPlayerTurn and isPlayerAttacking) or (!isPlayerTurn and !isPlayerAttacking):
					# defending side set slot to blue
					slot.get_node("SideIndicator").self_modulate = defendColor
				else:
					# attacking side. set slot to red
					slot.get_node("SideIndicator").self_modulate = attackColor
				
	
	SetMiddleColumnColor(true)
	

func SetMiddleColumnColor(attackingTurn):
	var midCol = unitMatrix.get_child((unitMatrix.get_child_count()) / 2)
	if attackingTurn:
		# set red
		for slot in midCol.get_children():
			slot.get_node("SideIndicator").self_modulate = middleColor
	else:
		# set blue
		for slot in midCol.get_children():
			slot.get_node("SideIndicator").self_modulate = middleColor
			
			
func SetMiddleColumnAvailability(available: bool):
	var midCol = unitMatrix.get_child((unitMatrix.get_child_count()) / 2)
	# set blue
	for slot: UnitSlot in midCol.get_children():
		slot.SetCanWaitOrder(available)
			

# returns the wait times of the middle column as a list
func ExportWaitTimes():
	var output = []
	
	var midCol = unitMatrix.get_child((unitMatrix.get_child_count()) / 2)
	# set blue
	for slot : UnitSlot in midCol.get_children():
		output.append(slot.waitcount)
		
	return output


func ImportWaitTimes(waitTimes):
	var midCol = unitMatrix.get_child((unitMatrix.get_child_count()) / 2)
	# set blue
	for i in range(waitTimes.size()):
		midCol.get_child(i).waitcount = waitTimes[i]
	
	
# looks for the unit card with unit set to input
# might need optimization later on
func FindUnitCard(unit: Unit):
	for column in unitMatrix.get_children():
		for slot in column.get_children():
			var unitCard = slot.get_child(-1)
			if unitCard is UnitCard:
				if unitCard.unit == unit:
					return unitCard
	
	return null


func SetAttackDirectionUI(toLeft: bool):
	var animPlayer: AnimationPlayer = $Root/MiddleScreen/CombinedUnitMatrixEditor/UnitMatrix/AttackDirectionUI/AnimationPlayer
	if toLeft:
		animPlayer.play("attack_left_arrow_animation")
	else:
		animPlayer.play("attack_right_arrow_animation")
		
		
func UpdateHealButtonLabel():
	var button = $Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/HealButton
	var label = button.get_node("CostLabel")
	
	button.disabled = true
	
	var funds = GameManager.playerFunds
	if !GameManager.isPlayerTurn:
		funds = GameManager.enemyFunds
	
	if UnitCard.selected != null:
		var amount = GameManager.healCostPerStackCount * UnitCard.selected.unit.stackCount
		var text = "Cost: {num}"
		label.text = text.format({"num": amount})
		if UnitCard.selected.unit.currentHealthPoints >= UnitCard.selected.unit.data.maxHealthPoints * UnitCard.selected.unit.stackCount:
			label.text = "Full Health"
		elif amount > funds:
			label.text = "Not Enough Funds"
		else:
			button.disabled = false
	else:
		label.text = ""
		

func UpdateSellButtonLabel():
	var button = $Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/SellButton
	var label = $Root/MiddleScreen/MidLeftScreen/ReserveUI/UnitManagementButtons/SellButton/CostLabel
	button.disabled = true
	
	if UnitCard.selected != null:
		var amount = UnitCard.selected.unit.data.purchaseCost * UnitCard.selected.unit.stackCount
		if UnitCard.selected.unit.boughtThisTurn == false:
			amount = int(amount * GameManager.refundRatio)
			
		var text = tr("INCOME") + ": {num}"
		label.text = text.format({"num": amount})
		button.disabled = false
	else:
		label.text = ""


func MakeFundsPopup(amount):
	var newpopup = popupScene.instantiate()
	if amount >= 0:
		amount = "+" + str(amount)
		newpopup.get_node("Label").self_modulate = Color.GREEN
		
	newpopup.get_node("Label").text = str(amount)
	
	newpopup.global_position = $Root/MiddleScreen/MidLeftScreen/FundsLabel/LastIncomeLabel.global_position
	newpopup.get_node("AnimationPlayer").speed_scale = 0.5
	add_child(newpopup)


func UpdateSlotTerrain(isPlayerTurn):
	var currentTerrainMatrix = GameManager.enemyTerrainMatrix
	if isPlayerTurn:
		currentTerrainMatrix = GameManager.playerTerrainMatrix
	
	var offset = 0
	
	for col in range(unitMatrix.get_child_count()):
		# skip middle column
		if col == int(unitMatrix.get_child_count() / 2):
			continue
			
		# if past middle column, flip terrain matrices
		if col > int(unitMatrix.get_child_count() / 2):
			offset = int(unitMatrix.get_child_count() / 2) + 1
			if isPlayerTurn:
				currentTerrainMatrix = GameManager.enemyTerrainMatrix
			else:
				currentTerrainMatrix = GameManager.playerTerrainMatrix
			
		for row in range(unitMatrix.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrix.get_child(col).get_child(row)
			
			if offset == 0:
				slot.SetTerrain(currentTerrainMatrix[int(unitMatrix.get_child_count() / 2) - 1 - col - offset][row])
			else:
				slot.SetTerrain(currentTerrainMatrix[col - offset][row])
	
	# set middle column
	var middleCol = unitMatrix.get_child(int(unitMatrix.get_child_count() / 2)).get_children()
	for i in range(middleCol.size()):
		middleCol[i].SetTerrain(GameManager.middleTerrainList[i])
