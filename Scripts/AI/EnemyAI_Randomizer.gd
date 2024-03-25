extends EnemyAI

var unitsByPriority = []


func _init(cols, rows):
	super._init(cols, rows)


# returns a 2D array of units
func GenerateUnitMatrix():
	# pick reinforcement option
	
	# if lost last time, add new units and shuffle list
	
	# if won last time, keep unit list and add new units at the back
	
	# repeat this for set number of times and return best option
	
	return


# randomizes the units inside each priority level list
func ShuffleUnits():
	if unitsByPriority == null:
		print("ERROR! Unit priority list empty but calling shuffle.")
		return
		
	for i in range(len(unitsByPriority)):
		unitsByPriority[i].shuffle()


# just pick a random unit
func ChooseReinforcementOption():
	return
