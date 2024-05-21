extends Control


func _on_kor_button_toggled(toggled_on):
	print("toggle")
	$KORTutorial.visible = toggled_on
