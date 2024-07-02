extends TextureButton
class_name AnimatedButton

var player: AnimationPlayer

var mouseInsideAfterUntoggle: bool = false


func _ready():
	player = $AnimationPlayer
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)
	
	
func _mouse_entered():
	if toggle_mode and button_pressed:
		return
		
	player.play("mouse_entered_animation")
	
	
func _mouse_exited():
	if toggle_mode and button_pressed:
		return
		
	if mouseInsideAfterUntoggle:
		mouseInsideAfterUntoggle = false
		return
		
	player.play("mouse_exited_animation")


func _pressed():
	if toggle_mode:
		if button_pressed == false:
			mouseInsideAfterUntoggle = true
		return
	else:
		player.play("mouse_entered_animation")


func _toggled(toggled_on):
	if toggled_on:
		player.play("mouse_entered_animation")
	else:
		player.play("mouse_exited_animation")
		
