extends TextureButton

@export var buttonType: Enums.MenuType

signal menu_button_pressed(type)


func _pressed():
	menu_button_pressed.emit(buttonType)
