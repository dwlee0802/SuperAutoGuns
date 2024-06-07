extends Unit
class_name WaitOrder

var waitCycles: int = 1

func Merge(otherUnit: Unit):
	if otherUnit != WaitOrder:
		print("ERROR! Shouldn't try to merge normal unit with WaitOrder")
		return
		
	waitCycles += otherUnit.waitCycles
	stackCount += 1
	print("\n" + "Increased wait order" + "\n")


func _init(_player, _data, _coord, _stack: int = 1):
	super._init(_player, _data, _coord, _stack)
	
	waitCycles = _stack
