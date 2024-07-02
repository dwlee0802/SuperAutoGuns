extends AnimatedButton

func _toggled(toggled_on):
	if toggled_on:
		$AnimationPlayer.play("button_pressed_animation")
	else:
		$AnimationPlayer.play("button_unpressed_animation")


func _mouse_exited():
	# don't play anim if pressed
	if button_pressed:
		return
	
	super._mouse_exited()
	
