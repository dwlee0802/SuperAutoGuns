extends VBoxContainer
class_name UnitMatrixEditor

var unitCardScene = load("res://Scenes/unit_card.tscn")

@onready var reinforcementUI = $Reinforcement/HBoxContainer
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")
var reinforcementOptionCount: int = 5

@onready var reserveUI = $Reserve/HBoxContainer


func _ready():
	$Reinforcement/RerollButton.pressed.connect(GenerateReinforcementOptions.bind(Enums.Nation.Germany))
	GenerateReinforcementOptions(Enums.Nation.Germany)
	
	
# reads the unit matrix in Game and shows it in the UI
func ImportUnitMatrix():
	pass
	

# returns the state of the unit matrix
func ExportUnitMatrix():
	pass


# make unit icons based on player's reserves
func ImportReserve():
	# clear children
	while reserveUI.get_child_count() > 0:
		reserveUI.remove_child(reserveUI.get_child(0))
		
	for unit: Unit in GameManager.playerReserves:
		var newCard: UnitCard = unitCardScene.instantiate()
		newCard.SetUnit(unit)
		reserveUI.add_child(newCard)
		

func ExportReserve():
	var newReserve = []
	for child in reserveUI.get_children():
		newReserve.append(child)
	GameManager.playerReserves = newReserve
	

# populate reinforcement option buttons
func GenerateReinforcementOptions(nation: Enums.Nation):
	# clear children
	while reinforcementUI.get_child_count() > 0:
		reinforcementUI.remove_child(reinforcementUI.get_child(0))
		
	for i in range(reinforcementOptionCount):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		newOption.SetData(DataManager.unitDict[nation].pick_random())
		reinforcementUI.add_child(newOption)
		newOption.pressed.connect(ImportReserve)
