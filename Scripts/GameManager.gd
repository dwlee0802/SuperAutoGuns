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
	
	if GameManager.UnitCount(playerUnitMatrix) == 0 or GameManager.UnitCount(enemyUnitMatrix) == 0:
		if !cycleTimer.is_stopped():
			cycleTimer.stop()
			$AutoToggleButton.button_pressed = false
		
		
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
	
	
static func CycleProcess():
	# update unit attack and movement costs
	UnitBehaviorProcess(playerUnitMatrix)
	UnitBehaviorProcess(enemyUnitMatrix)
	
	# modify grid according to unit movement
	ApplyUnitMovement(playerUnitMatrix)
	ApplyUnitMovement(enemyUnitMatrix)
	
	# generate damage matrix
	playerDamageMatrix = GenerateDamageMatrix(enemyUnitMatrix)
	enemyDamageMatrix = GenerateDamageMatrix(playerUnitMatrix)
	
	# reload editor UI to apply unit movement
	# unit cards on instantiation play unit attack animations if appropriate
	# when units' attack animation ends, their attack function is called
	# need to disable player messing with the editor while animations are playing
	# units get removed themselves when they die
	playerEditor.ImportUnitMatrix()
	enemyEditor.ImportUnitMatrix()
	
	# stop cycle timer if one side wins
	cycleCount += 1
	cycleLabel.text = "Cycle: " + str(cycleCount)
	print("cycle " + str(cycleCount) + " done\n")
	
	if UnitCount(playerUnitMatrix) == 0 or UnitCount(enemyUnitMatrix) == 0:
		print("Battle over! stopping cycle.")
		if !cycleTimer.is_stopped():
			cycleTimer.stop()


# go through all units and determine if unit is attacking or moving
# units prioritizing movement
# move forward if front slot exists and is empty
# if not, check for attack targets
# if attack target exists, start reducing attack cycle cost
# if none exists, do nothing this turn
static func UnitBehaviorProcess(unitMatrix):
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			# check movement
			if unitMatrix[col][row] != null:
				# dont move if: is front column or front slot is occupied
				if col == 0 or unitMatrix[col - 1][row] != null:
					# reset movement cost
					unitMatrix[col][row].movementCyclesLeft = unitMatrix[col][row].data.movementCost
					
					# check if able to attack
					var target = FindAttackTarget(true, row, unitMatrix[col][row].data.attackRange - col)
					
					# valid attack target exists
					if target != null:
						unitMatrix[col][row].attackTargetCoord = target
						unitMatrix[col][row].attackCyclesLeft -= 1
					# no target. reset value
					else:
						unitMatrix[col][row].attackCyclesLeft = unitMatrix[col][row].data.attackCost
				# can move
				else:
					unitMatrix[col][row].movementCyclesLeft -= 1
	

static func ApplyUnitMovement(unitMatrix):
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			if unitMatrix[col][row] != null:
				if unitMatrix[col][row].movementCyclesLeft < 0:
					# make sure
					if col != 0 and unitMatrix[col - 1][row] == null:
						# move forward
						unitMatrix[col - 1][row] = unitMatrix[col][row]
						unitMatrix[col][row] = null
						unitMatrix[col - 1][row].movementCyclesLeft = unitMatrix[col - 1][row].data.movementCost
					else:
						print("ERROR! Unit movement cycle is below zero even though it cannot move.")
				
				
static func GenerateDamageMatrix(unitMatrix):
	var output = Make2DArray(matrixHeight, matrixWidth)
	
	for col in range(len(unitMatrix)):
		for row in range(len(unitMatrix[col])):
			output[col][row] = 0
			if unitMatrix[col][row] != null:
				if unitMatrix[col][row].attackCyclesLeft < 0:
					# make sure
					output[col][row] = unitMatrix[col][row].data.attackDamage
	
	return output

	
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
		playerReserves.append(Unit.new(isPlayer, data))
	else:
		enemyReserves.append(Unit.new(isPlayer, data))


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


static func RemoveUnit(unit: Unit):
	var mat = playerUnitMatrix
	if !unit.isPlayer:
		mat = enemyUnitMatrix
	
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if mat[col][row] == unit:
				mat[col][row] = null
				return
