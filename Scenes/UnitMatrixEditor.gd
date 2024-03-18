extends VBoxContainer
class_name UnitMatrixEditor

@onready var reinforcementUI = $Reinforcement/HBoxContainer
var reinforcementOptionButton = load("res://Scenes/reinforcement_option.tscn")


func _ready():
	GenerateReinforcementOptions(Enums.Nation.Germany, 5)
	
	
# reads the unit matrix in Game and shows it in the UI
func ImportUnitMatrix():
	pass
	

# returns the state of the unit matrix
func ExportUnitMatrix():
	pass


# populate reinforcement option buttons
func GenerateReinforcementOptions(nation: Enums.Nation, count: int):
	for i in range(count):
		var newOption: ReinforcementOptionButton = reinforcementOptionButton.instantiate()
		newOption.SetData(DataManager.unitDict[nation].pick_random())
		reinforcementUI.add_child(newOption)
