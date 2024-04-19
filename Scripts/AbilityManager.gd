class_name AbilityManager

static var abilities = {}

static func ChangeStatOfNeighbor(unitMatrix, selfCoord: Vector2, neighborDirection: Vector2, amount: int, statType: Enums.StatType):
	if selfCoord == null:
		return
		
	var targetCoord: Vector2 = selfCoord + neighborDirection
	
	if GameManager.CheckCoordInsideBounds(targetCoord):
		var targetUnit: Unit = unitMatrix[targetCoord.x][targetCoord.y]
		if targetUnit != null:
			targetUnit.ChangeStats(statType, amount)
			print("added " + str(amount) + " defense to " + str(targetUnit) + "\n")
