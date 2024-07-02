extends TextureButton

func _toggled(toggled_on):
	print("toggled " + str(toggled_on))
	if toggled_on:
		$AnimationPlayer.play("button_pressed_animation")
	else:
		$AnimationPlayer.play("button_unpressed_animation")
