extends Control
class_name UserInterface

var unitCardScene = load("res://Scenes/unit_card.tscn")
var slotScene = load("res://Scenes/unit_slot.tscn")
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var researchOptionButton = load("res://Scenes/research_option.tscn")
var popupScene = load("res://Scenes/damage_popup.tscn")

@export var attackColor = Color.RED
@export var defendColor = Color.BLUE
@export var middleColor = Color.DARK_RED

var menuDict = {}
var menuButtonsGroup: ButtonGroup
@onready var menuWindow = $EditorBackground/Menu
@onready var menuAnimPlayer: AnimationPlayer = $EditorBackground/Menu/AnimationPlayer

@onready var editorBackground = $EditorBackground
@onready var unitMatrixEditor = $EditorBackground/UnitMatrixEditor/HBoxContainer
var zoomSpeed: float = 1.5

@onready var captureStatusUI = $TopScreen/CaptureStatusUI

@onready var reserveContainer = $EditorBackground/Menu/UnitMenu/Reserve/ReserveContainer
@onready var reinforcementContainer = $EditorBackground/Menu/UnitMenu/Reinforcement/HBoxContainer/ReinforcementContainer

@onready var fundsLabel = $SideMenu/FundsLabel
@onready var battleCountLabel = $TopScreen/BattleCountLabel
@onready var cycleCountLabel = $ProcessControlMenu/CycleCountLabel

@onready var commitButton = $ProcessControlMenu/TurnButtons/CommitButton
@onready var passButton = $ProcessControlMenu/TurnButtons/PassButton

@onready var turnTimer: Timer = $ProcessControlMenu/TurnTimer
@onready var turnTimerLabel: Label = $ProcessControlMenu/TurnTimeLabel

@onready var singleCycleButton = $ProcessControlMenu/HBoxContainer/ControlButtons/SingleCycleButton
@onready var pauseCycleButton = $ProcessControlMenu/HBoxContainer/ControlButtons/PauseButton
@onready var rerollButton = $EditorBackground/Menu/UnitMenu/Reinforcement/HBoxContainer/RerollButton

@onready var unitMenu: UnitMenu = $UnitMenu


func _ready():
	# make menu dict
	menuDict[Enums.MenuType.UnitMenu] = $EditorBackground/Menu/UnitMenu
	menuDict[Enums.MenuType.ScienceMenu] = $EditorBackground/Menu/ScienceMenu
	menuDict[Enums.MenuType.StatsMenu] = $EditorBackground/Menu/StatsMenu
	
	menuButtonsGroup = $SideMenu/Buttons/MenuButtonsContainer/UnitMenuButton.button_group
	menuWindow.visible = false
	
	# connect menu button signals
	$SideMenu/Buttons/MenuButtonsContainer/UnitMenuButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/ResearchButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/StatsButton.menu_button_pressed.connect(_on_menu_button_pressed)
	
	reserveContainer.dropped.connect(DroppedIntoReserve)
	
	# reroll button signal
	rerollButton.pressed.connect(RerollButtonPressed)
	
	# connect unit menu signals
	unitMenu.pressed.connect(UnitMenuOptionSelected)
	
	# testing
	GenerateResearchOptions(GameManager.isPlayerTurn, 3)
	ImportCompletedResearches(GameManager.isPlayerTurn)
	

func _on_menu_button_pressed(menuType: Enums.MenuType):
	# no buttons pressed. hide menu
	if menuButtonsGroup.get_pressed_button() == null:
		menuAnimPlayer.play_backwards("show_menu_animation")
	else:
		# skip animation if menu is already shown
		if menuWindow.visible != true:
			menuAnimPlayer.play("show_menu_animation")
		
		for key in menuDict.keys():
			menuDict[key].visible = false
		menuDict[menuType].visible = true
		

func HideSideMenu():
	menuAnimPlayer.play_backwards("show_menu_animation")
	for button: BaseButton in menuButtonsGroup.get_buttons():
		button.button_pressed = false
	

var initialMousePosition: Vector2 = Vector2.ZERO
var initialPosition: Vector2 = Vector2.ZERO
func _process(_delta):
	# handle mouse panning
	# save mouse coords
	if Input.is_action_just_pressed("start_panning"):
		initialMousePosition = get_local_mouse_position()
		initialPosition = unitMatrixEditor.position
	if Input.is_action_pressed("start_panning"):
		var pannedAmount: Vector2 = initialMousePosition - get_local_mouse_position()
		unitMatrixEditor.position = initialPosition - pannedAmount
		
	if Input.is_action_just_pressed("close_menu"):
		if unitMenu.visible:
			HideUnitMenu()
		else:
			HideSideMenu()
	
	#if Input.is_action_just_pressed("right_click"):
		#if unitMenu.visible:
			#HideUnitMenu()
		
	if turnTimer.is_stopped():
		turnTimerLabel.visible = false
	else:
		turnTimerLabel.text = tr("TIME LEFT") + ": " + str(int(turnTimer.time_left)) + " S"
		
	
func _gui_input(event):
	# handle zoom
	if event is InputEventMouseButton:
		if event.is_pressed():
			# vector from center of screen to editor center
			# should be constant with zoom
			var prevCenter = unitMatrixEditor.global_position + (unitMatrixEditor.size * unitMatrixEditor.scale) / 2
			
			var tween = get_tree().create_tween()
			#centerOffset += (get_global_mouse_position() - centerOffset) / 2
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				tween.tween_property(unitMatrixEditor, "scale", unitMatrixEditor.scale + zoomSpeed * Vector2.ONE / 10.0, 0.1)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				tween.tween_property(unitMatrixEditor, "scale", unitMatrixEditor.scale - zoomSpeed * Vector2.ONE / 10.0, 0.1)
			
			var newCenter = unitMatrixEditor.global_position + (unitMatrixEditor.size * unitMatrixEditor.scale) / 2
			#unitMatrixEditor.global_position -= newCenter - prevCenter
			tween.tween_property(unitMatrixEditor, "global_position", unitMatrixEditor.global_position - newCenter + prevCenter, 0.1)
			
			#print("prev: " + str(prevCenter))
			#print("current: " + str(newCenter))
		
# make new card and connect signals
func _InstantiateUnitCard() -> UnitCard:
	var newCard: UnitCard = unitCardScene.instantiate()
	
	# connect signals
	newCard.was_right_clicked.connect(ShowUnitMenu)
	
	#newCard.clicked.connect(HideControlButtons)
	#newCard.merged.connect(HideControlButtons)
	#
	#newCard.clicked.connect(UpdateHealButtonLabel)
	#newCard.clicked.connect(UpdateSellButtonLabel)
	#
	#newCard.merged.connect(OnCardMerged)
	
	#newCard.merged.connect(ImportUnitMatrix)
	#newCard.merged.connect(ImportReserve)
	
	return newCard
	
	
# populate reinforcement option buttons
func GenerateReinforcementOptions(isPlayer: bool, optionCount: int):
	# clear children
	var children = reinforcementContainer.get_children()
	for item in children:
		item.queue_free()
		
	for i in range(optionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		
		# who's turn is it
		newOption.isPlayer = isPlayer
		
		newOption.SetData(DataManager.GetPurchasedUnits(isPlayer).pick_random())
		reinforcementContainer.add_child(newOption)
		

func RerollButtonPressed():
	if GameManager.CheckFunds(GameManager.rerollCost):
		GenerateReinforcementOptions(GameManager.isPlayerTurn, GameManager.reinforcementCount)
		GameManager.ChangeFunds(-GameManager.rerollCost)
	

# make research options
func GenerateResearchOptions(isPlayer: bool, optionCount: int):
	# clear children
	var researchContainer = $EditorBackground/Menu/ScienceMenu/ResearchOptions/FlowContainer
	DW_ToolBox.RemoveAllChildren(researchContainer)
	
	var options = DW_ToolBox.PickRandomNumber(DataManager.GetPurchasedUnits(isPlayer, false), optionCount, false)
	for option in options:
		var newOption: ResearchOption = researchOptionButton.instantiate()
		newOption.SetData(option, false, isPlayer)
		newOption.pressed.connect(ImportCompletedResearches.bind(GameManager.isPlayerTurn))
		researchContainer.add_child(newOption)
	
	
func ImportCompletedResearches(isPlayer: bool):
	var completedContainer = $EditorBackground/Menu/ScienceMenu/Completed/CompletedContainer
	DW_ToolBox.RemoveAllChildren(completedContainer)
	var completed = DataManager.GetPurchasedUnits(isPlayer)
	
	for item in completed:
		var newIcon = ColorRect.new()
		var icon = TextureRect.new()
		
		icon.set_anchors_preset(PRESET_FULL_RECT)
		icon.texture = item.unitTexture
		newIcon.self_modulate = item.color.darkened(0.2)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		newIcon.custom_minimum_size = Vector2(50, 50)
		newIcon.add_child(icon)
		newIcon.tooltip_text = item.description
		completedContainer.add_child(newIcon)
		
	
func SetFundsLabel(amount: int):
	if !(amount is int):
		push_error("Shouldn't try to set funds label to non int value.")
		
	fundsLabel.text = tr("FUNDS") + ": " + str(amount)
	
func SetBattleCountLabel(amount):
	battleCountLabel.text = tr("BATTLE") + ": " + str(amount)
	
func SetTurnLabel(isPlayerTurn):
	var label = $TopScreen/TurnLabel
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

func SetCycleCountLabel(count: int):
	cycleCountLabel.text = tr("CYCLE") + " " + str(count)

	
func MakeFundsPopup(amount):
	var newpopup = popupScene.instantiate()
	newpopup.get_node("Label").self_modulate = Color.RED
	if amount >= 0:
		amount = "+" + str(amount)
		newpopup.get_node("Label").self_modulate = Color.GREEN
		
	newpopup.get_node("Label").text = str(amount)
	
	newpopup.global_position = fundsLabel.global_position
	newpopup.get_node("AnimationPlayer").speed_scale = 0.5
	add_child(newpopup)
	
	
# makes a grid with specified width and height slots
func GenerateGrid(colCount: int, rowCount: int):
	# clear preexisting grid
	var cols = unitMatrixEditor.get_children()
	
	for item in cols:
		item.queue_free()
	
	for i in range(colCount):
		var newCol = VBoxContainer.new()
		newCol.add_theme_constant_override("separation", 50)
		newCol.alignment = BoxContainer.ALIGNMENT_CENTER
		
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			
			newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			
			# connect signals
			newSlot.dropped.connect(GameManager.UpdateUnitPositions)
			
		unitMatrixEditor.add_child(newCol)
		newCol.reparent(unitMatrixEditor)
	
		
func SetSlotAvailability(_startIndex: int = 0, endIndex: int = 2):
	for col in range(unitMatrixEditor.get_child_count()):
		for row in range(unitMatrixEditor.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrixEditor.get_child(col).get_child(row)
			slot.SetCanBeDropped(col < endIndex)


func SetSlotColor(isPlayerTurn, isPlayerAttacking):
	if isPlayerAttacking:
		attackColor = GameManager.playerColor
		defendColor = GameManager.enemyColor
		middleColor = attackColor.darkened(0.4)
	else:
		attackColor = GameManager.enemyColor
		defendColor = GameManager.playerColor
		middleColor = attackColor.darkened(0.4)
	
	for col in range(unitMatrixEditor.get_child_count()):
		for row in range(unitMatrixEditor.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrixEditor.get_child(col).get_child(row)
			# current turn side
			if col <= int(unitMatrixEditor.get_child_count() / 2):
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
	var midCol = unitMatrixEditor.get_child((unitMatrixEditor.get_child_count()) / 2)
	if attackingTurn:
		# set red
		for slot in midCol.get_children():
			slot.get_node("SideIndicator").self_modulate = middleColor
	else:
		# set blue
		for slot in midCol.get_children():
			slot.get_node("SideIndicator").self_modulate = middleColor

func SetMiddleColumnAvailability(available: bool):
	var midCol = unitMatrixEditor.get_child((unitMatrixEditor.get_child_count()) / 2)
	# set blue
	for slot: UnitSlot in midCol.get_children():
		slot.SetCanWaitOrder(available)
		
		
func UpdateSlotTerrain(leftTerrainMatrix, rightTerrainMatrix):
	var currentTerrainMatrix = leftTerrainMatrix
	
	var offset = 0
	
	for col in range(unitMatrixEditor.get_child_count()):
		# skip middle column
		if col == int(unitMatrixEditor.get_child_count() / 2):
			continue
			
		# if past middle column, flip terrain matrices
		if col > int(unitMatrixEditor.get_child_count() / 2):
			offset = int(unitMatrixEditor.get_child_count() / 2) + 1
			currentTerrainMatrix = rightTerrainMatrix
			
		for row in range(unitMatrixEditor.get_child(col).get_child_count()):
			var slot: UnitSlot = unitMatrixEditor.get_child(col).get_child(row)
			
			if offset == 0:
				slot.SetTerrain(currentTerrainMatrix[int(unitMatrixEditor.get_child_count() / 2) - 1 - col - offset][row])
			else:
				slot.SetTerrain(currentTerrainMatrix[col - offset][row])
	
	# set middle column
	var middleCol = unitMatrixEditor.get_child(int(unitMatrixEditor.get_child_count() / 2)).get_children()
	for i in range(middleCol.size()):
		middleCol[i].SetTerrain(GameManager.middleTerrainList[i])
		
		
func ExportReserve():
	var newReserve = []
	for child in reserveContainer.get_children():
		newReserve.append(child.unit)
		
	print("current reserve count: " + str(newReserve.size()))
	
	return newReserve
	

func DroppedIntoReserve():
	if GameManager.isPlayerTurn:
		GameManager.playerReserves = ExportReserve()
	else:
		GameManager.enemyReserves = ExportReserve()
		
		
# inserts the current unit matrix as seen in UI into currentMatrix
# start from the right most column
func ExportUnitMatrix(currentMatrix, includeMiddle: bool = false):
	var colCount: int = int(unitMatrixEditor.get_child_count() / 2)
	if includeMiddle:
		colCount += 1
	
	var invertY: bool = true
	
	# column index
	for offset in range(colCount):
		# row index
		for row in range(unitMatrixEditor.get_child(colCount - offset - 1).get_child_count()):
			var unit_there = unitMatrixEditor.get_child(colCount - offset - 1).get_child(row).GetUnitHere()
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


# returns the wait times of the middle column as a list
func ExportWaitTimes():
	var output = []
	
	var midCol = unitMatrixEditor.get_child((unitMatrixEditor.get_child_count()) / 2)
	# set blue
	for slot : UnitSlot in midCol.get_children():
		output.append(slot.waitcount)
		
	return output


# include middle
# -1: middle col is owned by right side
# 0: leave middle col empty
# 1: middle col is owned by left side
func ImportUnitMatrix(leftUnitMatrix, rightUnitMatrix, includeMiddle: int):
	var _frontLineUI
	print("importing unit matrix")
	# clear unit cards
	for col in unitMatrixEditor.get_children():
		if col is TextureRect:
			_frontLineUI = col
			continue
		for slot in col.get_children():
			for i in range(slot.get_child_count()):
				var target = slot.get_child(i)
				if target is UnitCard:
					target.queue_free()

	var colCount = unitMatrixEditor.get_child_count()
	
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
					slot = unitMatrixEditor.get_child(leftStartingColIndex - col - 1).get_child(row)
				elif includeMiddle == -1:
					slot = unitMatrixEditor.get_child(leftStartingColIndex - col).get_child(row)
				else:
					slot = unitMatrixEditor.get_child(leftStartingColIndex - col).get_child(row)
					
				slot.add_child(newCard)
				newCard.reparent(slot)
				newCard.SetUnit(leftUnitMatrix[col][row])
				newCard.SetSpriteHFlipped(false)
				
	for col in range(min(rightUnitMatrix.size(), rightMatrixColCount)):
		for row in range(rightUnitMatrix[col].size()):
			if rightUnitMatrix[col][row] != null:
				var newCard: UnitCard = _InstantiateUnitCard()
				var slot: UnitSlot
				if includeMiddle == 1:
					slot = unitMatrixEditor.get_child(rightStartingColIndex + col).get_child(row)
				elif includeMiddle == -1:
					slot = unitMatrixEditor.get_child(rightStartingColIndex + col).get_child(row)
				else:
					slot = unitMatrixEditor.get_child(rightStartingColIndex + col).get_child(row)
					
				slot.add_child(newCard)
				newCard.reparent(slot)
				newCard.SetUnit(rightUnitMatrix[col][row])
				newCard.SetSpriteHFlipped(true)


func ImportReserve(reserveUnits):
	print("Import Reserve\n")
	# clear children
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
	
	
func ImportWaitTimes(waitTimes):
	var midCol = unitMatrixEditor.get_child((unitMatrixEditor.get_child_count()) / 2)
	# set blue
	for i in range(waitTimes.size()):
		midCol.get_child(i).waitcount = waitTimes[i]
		
		
# looks for the unit card with unit set to input
# might need optimization later on
func FindUnitCard(unit: Unit):
	for column in unitMatrixEditor.get_children():
		for slot in column.get_children():
			var unitCard = slot.get_child(-1)
			if unitCard is UnitCard:
				if unitCard.unit == unit:
					return unitCard
	
	return null


func ShowUnitMenu(target: UnitCard):
	if UnitCard.selected == null or UnitCard.selected == target:
		unitMenu.ShowSelfButtons()
	else:
		unitMenu.ShowOtherUnitButtons()
	
	unitMenu.set_center_position(target.global_position + target.size / 2)
	unitMenu.visible = true


func HideUnitMenu():
	unitMenu.visible = false
	UnitCard.rightClicked = null
	

func UnitMenuOptionSelected(optionIndex: int):
	unitMenu.visible = false
	
	if UnitCard.rightClicked == null:
		push_error("Shouldn't be able to select unit menu when right clicked unit doesnt exist")
		return
		
	var unit: Unit = UnitCard.rightClicked.unit
	
	match optionIndex:
		Enums.UnitMenuType.Heal:
			print("Heal " + tr(unit.data.name))
			if GameManager.HealUnit(unit):
				UnitCard.rightClicked = null
				
		Enums.UnitMenuType.Sell:
			print("Sell " + tr(unit.data.name))
			GameManager.SellUnit(unit)
			
			UnitCard.rightClicked.queue_free()
			if UnitCard.selected == UnitCard.rightClicked:
				UnitCard.selected = null
			UnitCard.rightClicked = null
			
		Enums.UnitMenuType.Reserve:
			print("Reserve " + tr(unit.data.name))
			reserveContainer._drop_data(Vector2.ZERO, UnitCard.rightClicked)

			UnitCard.UnselectCard()
			UnitCard.rightClicked = null
		
		# swap positions between right clicked unit and selected unit
		Enums.UnitMenuType.Swap:
			print("Swap " + tr(unit.data.name))
			if UnitCard.selected == null:
				push_error("Swapping but no UnitCard selected!")
			else:
				UnitCard.rightClicked._drop_data(Vector2.ZERO, UnitCard.selected)
			UnitCard.rightClicked = null
			
		Enums.UnitMenuType.Merge:
			print("Merge " + tr(unit.data.name))
			if UnitCard.selected == null:
				push_error("Merging but no UnitCard selected!")
			else:
				UnitCard.rightClicked._merge_button_pressed()
			UnitCard.rightClicked = null
				
			

