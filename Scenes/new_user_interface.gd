extends Control
class_name UserInterface

var unitCardScene = load("res://Scenes/unit_card.tscn")
var slotScene = load("res://Scenes/unit_slot.tscn")
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var popupScene = load("res://Scenes/damage_popup.tscn")

@export var attackColor = Color.RED
@export var defendColor = Color.BLUE
@export var middleColor = Color.DARK_RED

var menuDict = {}

@onready var unitMatrixEditor = $EditorBackground/UnitMatrixEditor/HBoxContainer

@onready var unitMenu = $EditorBackground/UnitMenu
@onready var scienceMenu = $EditorBackground/ScienceMenu
@onready var statsMenu = $EditorBackground/StatisticsMenu

@onready var reserveContainer = $EditorBackground/UnitMenu/HBoxContainer/Reserve/ReserveContainer
@onready var reinforcementContainer = $EditorBackground/UnitMenu/HBoxContainer/Reinforcement/ReinforcementContainer

@onready var fundsLabel = $EditorBackground/FundsLabel
@onready var battleCountLabel = $TopScreen/BattleCountLabel


func _ready():
	# make menu dict
	menuDict[Enums.MenuType.UnitMenu] = $EditorBackground/UnitMenu
	menuDict[Enums.MenuType.ScienceMenu] = $EditorBackground/ScienceMenu
	menuDict[Enums.MenuType.StatsMenu] = $EditorBackground/StatisticsMenu
	
	# connect menu button signals
	$SideMenu/Buttons/MenuButtonsContainer/UnitMenuButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/ResearchButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/StatsButton.menu_button_pressed.connect(_on_menu_button_pressed)
	
	# testing
	

func _on_menu_button_pressed(menuType: Enums.MenuType):
	# hide all of them
	for key in menuDict.keys():
		if key == menuType:
			if menuDict[key].visible == false:
				menuDict[key].visible = true
			else:
				menuDict[key].visible = false
		else:
			menuDict[key].visible = false
	

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
	
	
# make new card and connect signals
func _InstantiateUnitCard() -> UnitCard:
	var newCard: UnitCard = unitCardScene.instantiate()
	
	# connect signals
	#newCard.was_right_clicked.connect(UpdateControlButtons)
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
func GenerateReinforcementOptions(isPlayer: bool, optionCount: int, _nation: Enums.Nation = Enums.Nation.Generic):
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
		
		# TODO
		# connect signals
		newOption.pressed.connect(SetFundsLabel.bind(GameManager.isPlayerTurn))


func SetFundsLabel(amount: int):
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

func MakeFundsPopup(amount):
	var newpopup = popupScene.instantiate()
	if amount >= 0:
		amount = "+" + str(amount)
		newpopup.get_node("Label").self_modulate = Color.GREEN
		
	newpopup.get_node("Label").text = str(amount)
	
	newpopup.global_position = fundsLabel.global_position
	newpopup.get_node("AnimationPlayer").speed_scale = 0.5
	add_child(newpopup)
	
	
func ExportReserve():
	var newReserve = []
	for child in reserveContainer.get_children():
		newReserve.append(child.unit)
		
	print("current reserve count: " + str(newReserve.size()))
	
	return newReserve
	
	
# makes a grid with specified width and height slots
func GenerateGrid(colCount: int, rowCount: int):
	# clear preexisting grid
	var cols = unitMatrixEditor.get_children()
	
	for item in cols:
		item.queue_free()
	
	for i in range(colCount):
		var newCol = VBoxContainer.new()
		newCol.add_theme_constant_override("separation", 20)
		newCol.alignment = BoxContainer.ALIGNMENT_CENTER
		
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			
			newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			
			# connect signals
			#newSlot.dropped.connect(OnUnitCardDropped)
			
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
