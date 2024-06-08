extends Control
class_name ResearchManager

@onready var optionsContainer = $ScrollContainer/VBoxContainer

var optionScene = load("res://Scenes/research_option.tscn")


func _ready():
	ImportResearchOptions(true)


# reads in unit data from data manager
# makes research options for each of them
# sets their bought status
func ImportResearchOptions(isPlayer):
	var unitDict = DataManager.playerPurchasedDict
	if !isPlayer:
		unitDict = DataManager.enemyPurchasedDict
	
	for unit in unitDict.keys():
		# make new option entry
		# set its state. bought or not
		var newOption: ResearchOption = optionScene.instantiate()
		newOption.SetData(unit, unitDict[unit])
		optionsContainer.add_child(newOption)
