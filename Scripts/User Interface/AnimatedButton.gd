extends TextureButton
class_name AnimatedButton

func _ready():
	self.mouse_entered.connect(_mouse_entered)
	self.mouse_exited.connect(_mouse_exited)
	
	
func _mouse_entered():
	$AnimationPlayer.play("mouse_entered_animation")
	
func _mouse_exited():
	$AnimationPlayer.play("mouse_exited_animation")

func _pressed():
	$AnimationPlayer.play("mouse_entered_animation")
	
