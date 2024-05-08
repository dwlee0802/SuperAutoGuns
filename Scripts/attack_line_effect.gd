extends Line2D
class_name AttackLineEffect


func SetValues(startPos: Vector2, endPos: Vector2, color: Color):
	set_point_position(0, startPos)
	set_point_position(1, endPos)
	default_color = color
	
	print(startPos)
	print(endPos)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("attack_animation")
