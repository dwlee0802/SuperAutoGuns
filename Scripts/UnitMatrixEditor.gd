extends VBoxContainer
class_name UnitMatrixEditor

@export var isPlayer: bool

@export var invertY: bool = false

@onready var unitMatrix = $UnitMatrix/HBoxContainer

var unitCardScene = load("res://Scenes/unit_card.tscn")
var slotScene = load("res://Scenes/unit_slot.tscn")

@onready var reinforcementUI = $Reinforcement/HBoxContainer
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var reinforcementOptionCount: int = 5

@onready var reserveUI = $Reserve/HBoxContainer


func _ready():
	$Reinforcement/RerollButton.pressed.connect(GenerateReinforcementOptions.bind(Enums.Nation.Germany))
	GenerateGrid(GameManager.matrixWidth, GameManager.matrixHeight)
	GenerateReinforcementOptions(Enums.Nation.Germany)
	UpdateFundsLabel()
	
	$Reserve/HBoxContainer.dropped.connect(ExportReserve)
	$Reserve/HBoxContainer.dropped.connect(ExportUnitMatrix)
	
	if isPlayer:
		$UnitMatrix/Label.text = "Player Army Layout"
	else:
		$UnitMatrix/Label.text = "Enemy Army Layout"
		

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
			newCol.add_child(newSlot)
			newSlot.reparent(newCol)
			newSlot.dropped.connect(ExportReserve)
			newSlot.dropped.connect(ExportUnitMatrix)
		unitMatrix.add_child(newCol)
		newCol.reparent(unitMatrix)
		
	
# reads the unit matrix in Game and shows it in the UI
# untested!
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
				var newCard = unitCardScene.instantiate()
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
				var unit_there = unitMatrix.get_child(col).get_child(row).get_child(1)
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
		var newCard: UnitCard = unitCardScene.instantiate()
		newCard.SetUnit(unit)
		reserveUI.add_child(newCard)
		

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
	var children = reinforcementUI.get_child_count()
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
	var label = $Reinforcement/FundsLabel
	if isPlayer:
		label.text = "Funds: " + str(GameManager.playerFunds)
	else:
		label.text = "Funds: " + str(GameManager.enemyFunds)
