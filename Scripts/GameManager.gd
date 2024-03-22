extends Control
class_name GameManager

static var cycleTimer: Timer
static var cycleLabel: Label

# Column 0 is the frontline
static var playerUnitMatrix
static var enemyUnitMatrix

static var playerReserves = []
static var enemyReserves = []

static var playerDamageMatrix
static var enemyDamageMatrix

static var playerAttackTargetMatrix
static var enemyAttackTargetMatrix

static var playerEffectMatrix
static var enemyEffectMatrix

# temporary value for the size of the matrix
static var matrixWidth: int = 3
static var matrixHeight: int = 4

static var playerEditor: UnitMatrixEditor
static var enemyEditor: UnitMatrixEditor

static var cycleCount: int = 0


static func _static_init():
	InitializeMatrix()


func _ready():
	cycleTimer = $CycleTimer
	cycleLabel = $CycleCountLabel
	$AutoToggleButton.pressed.connect(_on_cycle_timer_timeout)
	
	GameManager.cycleTimer.timeout.connect(CycleProcess)
	GameManager.cycleTimer.timeout.connect(_on_cycle_timer_timeout)
	
	$ProcessSingleCycleButton.pressed.connect(CycleProcess)
	
	playerEditor = $PlayerUnitMatrixEditor
	enemyEditor = $EnemyUnitMatrixEditor
	
	

func _on_cycle_timer_timeout():
	print("cycle")
	# auto cycle mode is true
	if $AutoToggleButton.button_pressed:
		if cycleTimer.is_stopped():
			cycleTimer.start()
	else:
		if !cycleTimer.is_stopped():
			cycleTimer.stop()
	
	if UnitCount(playerUnitMatrix) == 0 or UnitCount(enemyUnitMatrix) == 0:
		if !cycleTimer.is_stopped():
			cycleTimer.stop()
		
		
# first index is the column, second index is the row
static func Make2DArray(h, w):
	var output = []
	output.resize(w)
	for i in range(w):
		var newlist = []
		newlist.resize(h)
		output[i] = newlist
	
	return output


static func InitializeMatrix():
	playerUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyUnitMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyEffectMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	playerAttackTargetMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyAttackTargetMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	
# calculate one cycle of the battle
# 1. generate effect matrix
# 2. apply effect matrix
# 3. generate damage matrix
# 4. apply effect matrix
# 5. process movement
# stop cycle timer if one side wins
static func CycleProcess():
	# 1. generate effect matrix
	
	# 2. apply effect matrix
	
	# 3. generate damage matrix
	playerDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	enemyDamageMatrix = Make2DArray(matrixHeight, matrixWidth)
	
	# initialize to zero
	for col in playerDamageMatrix:
		col.fill(0)
	for col in enemyDamageMatrix:
		col.fill(0)
		
	# go through all units and set damage matrix
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrix[col][row] != null:
				var targetCoord = FindAttackTarget(true, row, playerUnitMatrix[col][row].data.attackRange - col)
				if targetCoord != null:
					if playerUnitMatrix[col][row].attackCyclesLeft == 0:
						print(playerUnitMatrix[col][row].name + " attacked: " + str(targetCoord))
						enemyDamageMatrix[targetCoord.x][targetCoord.y] += playerUnitMatrix[col][row].data.attackDamage
						playerAttackTargetMatrix[col][row] = targetCoord
						playerUnitMatrix[col][row].attackCyclesLeft = playerUnitMatrix[col][row].data.attackCost
					else:
						playerUnitMatrix[col][row].attackCyclesLeft -= 1
				else:
					playerUnitMatrix[col][row].attackCyclesLeft = playerUnitMatrix[col][row].data.attackCost
					
			if enemyUnitMatrix[col][row] != null:
				var targetCoord = FindAttackTarget(false, row, enemyUnitMatrix[col][row].data.attackRange - col)
				if targetCoord != null:
					if enemyUnitMatrix[col][row].attackCyclesLeft == 0:
						print(enemyUnitMatrix[col][row].name + " attacked: " + str(targetCoord))
						playerDamageMatrix[targetCoord.x][targetCoord.y] += enemyUnitMatrix[col][row].data.attackDamage
						enemyAttackTargetMatrix[col][row] = targetCoord
						enemyUnitMatrix[col][row].attackCyclesLeft = enemyUnitMatrix[col][row].data.attackCost
					else:
						enemyUnitMatrix[col][row].attackCyclesLeft -= 1
				else:
					enemyUnitMatrix[col][row].attackCyclesLeft = enemyUnitMatrix[col][row].data.attackCost
					
	# 4. apply damage matrix
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrix[col][row] != null:
				playerUnitMatrix[col][row].ReceiveHit(playerDamageMatrix[col][row])
			if enemyUnitMatrix[col][row] != null:
				enemyUnitMatrix[col][row].ReceiveHit(enemyDamageMatrix[col][row])
	
	ClearDeadUnits(playerUnitMatrix)
	ClearDeadUnits(enemyUnitMatrix)
	
	# 5. process movement
	# check to see if slot directly in front is free
	# if it is, reduce movement cost
	# if it isnt, set movement cost to max
	# if movement cost is zero, move it forward
	# skip first col since nowhere to move
	for col in range(1, matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrix[col][row] != null:
				if playerUnitMatrix[col - 1][row] != null:
					playerUnitMatrix[col][row].movementCyclesLeft = playerUnitMatrix[col][row].data.movementCost
					print("here")
				else:
					if playerUnitMatrix[col][row].movementCyclesLeft == 0:
						# move forward
						playerUnitMatrix[col - 1][row] = playerUnitMatrix[col][row]
						playerUnitMatrix[col][row] = null
						playerUnitMatrix[col - 1][row].movementCyclesLeft = playerUnitMatrix[col - 1][row].data.movementCost
						print("unit advanced!")
					else:
						playerUnitMatrix[col][row].movementCyclesLeft -= 1
						print("unit advancing in " + str(playerUnitMatrix[col][row].movementCyclesLeft) + " cycles.")
			if enemyUnitMatrix[col][row] != null:
				if enemyUnitMatrix[col - 1][row] != null:
					enemyUnitMatrix[col][row].movementCyclesLeft = enemyUnitMatrix[col][row].data.movementCost
				else:
					if enemyUnitMatrix[col][row].movementCyclesLeft == 0:
						# move forward
						enemyUnitMatrix[col - 1][row] = enemyUnitMatrix[col][row]
						enemyUnitMatrix[col][row] = null
						enemyUnitMatrix[col - 1][row].movementCyclesLeft = enemyUnitMatrix[col - 1][row].data.movementCost
					else:
						enemyUnitMatrix[col][row].movementCyclesLeft -= 1
	
	playerEditor.ImportUnitMatrix()
	enemyEditor.ImportUnitMatrix()
	
	playerEditor.UpdateAttackLines()
	enemyEditor.UpdateAttackLines()
	
	# stop cycle timer if one side wins
	cycleCount += 1
	cycleLabel.text = "Cycle: " + str(cycleCount)
	print("cycle " + str(cycleCount) + " done\n")
	
	if UnitCount(playerUnitMatrix) == 0 or UnitCount(enemyUnitMatrix) == 0:
		print("Battle over! stopping cycle.")
		if !cycleTimer.is_stopped():
			cycleTimer.stop()


# TODO This needs fixing! Edge cases not working
# when inputted a position on the matrix
# returns a vector containing the row col position of an attack target
# returns null if no units are found
# checkCols means how many columns it can search away from itself
static func FindAttackTarget(isPlayer: bool, curRow, checkCols: int = 1):
	var checkingMatrix = enemyUnitMatrix
	if !isPlayer:
		checkingMatrix = playerUnitMatrix
		
	for col_offset in range(checkCols):
		var checkingColumn = checkingMatrix[col_offset]
		for i in range(len(checkingColumn)):
			var upper: Unit = null
			var lower: Unit = null
			
			if curRow + i < len(checkingColumn):
				upper = checkingColumn[curRow + i]
			if curRow - i >= 0:
				lower = checkingColumn[curRow - i]
			
			# both exists return the one that has lower HP
			if upper != null and lower != null:
				if upper.currentHealthPoints < lower.currentHealthPoints:
					return Vector2(col_offset, curRow + i)
				elif upper.currentHealthPoints > lower.currentHealthPoints:
					return Vector2(col_offset, curRow - i)
				else:
					# return random one
					var rng = randi()
					if rng%2 == 0:
						return Vector2(col_offset, curRow + i)
					else:
						return Vector2(col_offset, curRow - i)
			else:
				if upper != null:
					return Vector2(col_offset, curRow + i)
				if lower != null:
					return Vector2(col_offset, curRow - i)
	
	return null


static func AddReserveUnit(data: UnitData, isPlayer: bool):
	if isPlayer:
		playerReserves.append(Unit.new(data))
	else:
		enemyReserves.append(Unit.new(data))


static func UnitCount(unitMatrix):
	var output = 0
	for i in range(unitMatrix.size()):
		for j in range(unitMatrix[i].size()):
			if unitMatrix[i][j] != null:
				output += 1
	
	return output


# go through the unit matrix and unassign dead units
static func ClearDeadUnits(unitMatrix):
	for i in range(unitMatrix.size()):
		for j in range(unitMatrix[i].size()):
			if unitMatrix[i][j] != null:
				if unitMatrix[i][j].isDead:
					unitMatrix[i][j] = null
