extends TextureButton
class_name SideMenuButton

var mouseAnimPlayer: AnimationPlayer

@export var buttonType: Enums.MenuType

signal menu_button_pressed(type)


func _ready():
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	mouseAnimPlayer = $ButtonAnimationPlayer
	
	
func _pressed():
	menu_button_pressed.emit(buttonType)
	

func _mouse_entered():
	if buttonType == Enums.MenuType.UnitMenu:
		mouseAnimPlayer.play("unit_button_mouse_hover_anim")
	if buttonType == Enums.MenuType.ScienceMenu:
		mouseAnimPlayer.play("science_button_mouse_hover_anim")
	if buttonType == Enums.MenuType.StatsMenu:
		mouseAnimPlayer.play("stats_button_mouse_hover_anim")


func _mouse_exited():
	if buttonType == Enums.MenuType.UnitMenu:
		mouseAnimPlayer.play("unit_button_mouse_exit_anim")
	if buttonType == Enums.MenuType.ScienceMenu:
		mouseAnimPlayer.play("science_button_mouse_exit_anim")
	if buttonType == Enums.MenuType.StatsMenu:
		mouseAnimPlayer.play("stats_button_mouse_exit_anim")
