extends Control

@onready var radialUI: RadialProgress = $RadialUI/RadialProgress

@onready var timeLabel: Label = $RadialUI/Label

@onready var timer: Timer = $TurnTimer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !timer.is_stopped():
		timeLabel.text = str(int(timer.time_left))
		radialUI.progress = timer.time_left / timer.wait_time * 100
