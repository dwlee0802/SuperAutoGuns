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

@onready var unitMenu = $EditorBackground/UnitMenu
@onready var scienceMenu = $EditorBackground/ScienceMenu
@onready var statsMenu = $EditorBackground/StatisticsMenu


func _ready():
	# make menu dict
	menuDict[Enums.MenuType.UnitMenu] = $EditorBackground/UnitMenu
	menuDict[Enums.MenuType.ScienceMenu] = $EditorBackground/ScienceMenu
	menuDict[Enums.MenuType.StatsMenu] = $EditorBackground/StatisticsMenu
	
	# connect menu button signals
	$SideMenu/Buttons/MenuButtonsContainer/UnitMenuButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/ResearchButton.menu_button_pressed.connect(_on_menu_button_pressed)
	$SideMenu/Buttons/MenuButtonsContainer/StatsButton.menu_button_pressed.connect(_on_menu_button_pressed)
	

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
	
	
	
