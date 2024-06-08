extends Control
class_name ResearchManager

@onready var optionsContainer = $ScrollContainer/VBoxContainer

var optionScene = load("res://Scenes/research_option.tscn")


# reads in unit data from data manager
# makes research options for each of them
# sets their bought status
func ImportResearchOptions():
	pass
