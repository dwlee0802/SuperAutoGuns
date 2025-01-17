extends HBoxContainer
class_name BattleSpeedUI

# time between cycles
static var cycleSpeed: float = 0.6

static var cyclePaused: bool = false

static var currentCycleRatio: float = 0

@onready var radialProcess = $Control/RadialProgress

# time for each cycle in seconds
static var cycleSpeeds = [0.5, 0.3, 0.01]


func _process(_delta):
	if !GameManager.cycleTimer.is_stopped():
		radialProcess.visible = true
		SetRadialProcess(100 - GameManager.cycleTimer.time_left / GameManager.cycleTimer.wait_time * 100)
		BattleSpeedUI.currentCycleRatio = radialProcess.progress / 100.0
	else:
		radialProcess.visible = false
		SetRadialProcess(0)
		BattleSpeedUI.currentCycleRatio = 0
		
	

func _on_pause_button_toggled(toggled_on):
	cyclePaused = toggled_on


func _on_speed_button_pressed(extra_arg_0):
	cycleSpeed = cycleSpeeds[extra_arg_0]
	print("speed: " + str(extra_arg_0))


func SetRadialProcess(num):
	radialProcess.progress = num
	

func _on_single_button_pressed():
	cyclePaused = true
	$ControlButtons/PauseButton.button_pressed = cyclePaused
