extends Control
class_name NewUserInterface

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
	var tempReserve = []
	tempReserve.append(Unit.new(true, load("res://Data/Units/Generic/RF.tres"), null))
	
	ImportReserve(tempReserve)
	GenerateReinforcementOptions(true, 3)
	
	GenerateGrid(7,5)
	

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


func SetFundsLabel(isPlayerTurn: bool = GameManager.isPlayerTurn):
	print("player funds: " + str(GameManager.playerFunds))
	print("enemy funds: " + str(GameManager.enemyFunds))
	if isPlayerTurn:
		fundsLabel.text = tr("FUNDS") + ": " + str(GameManager.playerFunds)
	else:
		fundsLabel.text = tr("FUNDS") + ": " + str(GameManager.enemyFunds)


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
		newCol.add_theme_constant_override("separation", 10)
		newCol.begin
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			
			newSlot.coords = Vector2(i, j)
				
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			
			# connect signals
			#newSlot.dropped.connect(OnUnitCardDropped)
			
		unitMatrixEditor.add_child(newCol)
		newCol.reparent(unitMatrixEditor)
	
