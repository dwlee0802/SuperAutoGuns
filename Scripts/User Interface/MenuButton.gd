extends AnimatedButton
class_name SideMenuButton

@export var buttonType: Enums.MenuType

signal menu_button_pressed(type)


func _ready():
	super._ready()
	
	
func _pressed():
	menu_button_pressed.emit(buttonType)
	
	super._pressed()
