extends HBoxContainer
class_name BattleSpeedUI

# time between cycles
static var cycleSpeed: float = 1

static var cyclePaused: bool = false

@onready var radialProcess = $CycleProcessUI/RadialProgress


func _process(delta):
	if !GameManager.cycleTimer.is_stopped():
		radialProcess.visible = true
		SetRadialProcess(100 - GameManager.cycleTimer.time_left / GameManager.cycleTimer.wait_time * 100)
	else:
		radialProcess.visible = false
		SetRadialProcess(0)


func _on_pause_button_toggled(toggled_on):
	cyclePaused = !toggled_on


func _on_speed_button_pressed(extra_arg_0):
	cycleSpeed = extra_arg_0


func SetRadialProcess(num):
	radialProcess.progress = num
