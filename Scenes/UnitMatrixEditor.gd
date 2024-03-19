extends VBoxContainer
class_name UnitMatrixEditor

@export var isPlayer: bool

@onready var unitMatrix = $UnitMatrix/HBoxContainer

var unitCardScene = load("res://Scenes/unit_card.tscn")
var slotScene = load("res://Scenes/unit_slot.tscn")

@onready var reinforcementUI = $Reinforcement/HBoxContainer
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var reinforcementOptionCount: int = 5

@onready var reserveUI = $Reserve/HBoxContainer


func _ready():
	$Reinforcement/RerollButton.pressed.connect(GenerateReinforcementOptions.bind(Enums.Nation.Germany))
	GenerateReinforcementOptions(Enums.Nation.Germany)
	GenerateGrid(GameManager.matrixWidth, GameManager.matrixHeight)


# makes a grid with specified width and height slots
func GenerateGrid(colCount: int, rowCount: int):
	# clear preexisting grid
	while unitMatrix.get_child_count() > 0:
		unitMatrix.remove_child(unitMatrix.get_child(0))
	
	for i in range(colCount):
		var newCol = VBoxContainer.new()
		for j in range(rowCount):
			var newSlot: UnitSlot = slotScene.instantiate()
			newCol.add_child(newSlot)
			newSlot.dropped.connect(ExportReserve)
			newSlot.dropped.connect(ExportUnitMatrix)
		unitMatrix.add_child(newCol)
		
	
# reads the unit matrix in Game and shows it in the UI
# untested!
func ImportUnitMatrix():
	var currentMatrix
	if isPlayer:
		currentMatrix = GameManager.playerUnitMatrix
	else:
		currentMatrix = GameManager.enemyUnitMatrix
		
	# column index
	for col in range(unitMatrix.get_child_count()):
		# row index
		for row in range(unitMatrix.get_child(col).get_child_count()):
			if isPlayer:
				if currentMatrix[col][row] != null:
					var newCard = unitCardScene.instantiate()
					newCard.SetUnit(currentMatrix[col][row])
					unitMatrix.get_child(col).get_child(row).add_child(newCard)
	
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
				var unit_there = unitMatrix.get_child(col).get_child(row).get_child(1)
				currentMatrix[col][row] = unit_there.unit
			else:
				currentMatrix[col][row] = null
						
	if isPlayer:
		print("Current player unit count: " + str(GameManager.UnitCount(GameManager.playerUnitMatrix)))
	else:
		print("Current enemy unit count: " + str(GameManager.UnitCount(GameManager.enemyUnitMatrix)))


# make unit icons based on player's reserves
func ImportReserve():
	# clear children
	while reserveUI.get_child_count() > 0:
		reserveUI.remove_child(reserveUI.get_child(0))
	
	var reserve
	if isPlayer:
		reserve = GameManager.playerReserves
	else:
		reserve = GameManager.enemyReserves
		
	for unit: Unit in reserve:
		var newCard: UnitCard = unitCardScene.instantiate()
		newCard.SetUnit(unit)
		reserveUI.add_child(newCard)
		

func ExportReserve():
	var newReserve = []
	for child in reserveUI.get_children():
		newReserve.append(child)
	
	if isPlayer:
		GameManager.playerReserves = newReserve
	else:
		GameManager.enemyReserves = newReserve
		
	print("current reserve count: " + str(newReserve.size()))
	

# populate reinforcement option buttons
func GenerateReinforcementOptions(nation: Enums.Nation):
	# clear children
	while reinforcementUI.get_child_count() > 0:
		reinforcementUI.remove_child(reinforcementUI.get_child(0))
		
	for i in range(reinforcementOptionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		newOption.isPlayer = isPlayer
		newOption.SetData(DataManager.unitDict[nation].pick_random())
		reinforcementUI.add_child(newOption)
		newOption.pressed.connect(ImportReserve)


func GetUnitCardAt(col, row):
	var slot = unitMatrix.get_child(col).get_child(row)
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
						return
					
					unitCard.attackLine.set_point_position(1, targetCard.global_position - unitCard.global_position + Vector2(32, 32))
					unitCard.attackLine.visible = true
