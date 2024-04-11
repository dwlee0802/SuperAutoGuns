extends Control
class_name GameManager

static var cycleTimer: Timer
static var cycleLabel: Label

static var cycleTime: float = 1
static var cycleCount: int = 0

static var battleCount: int = 0

# Column 0 is the frontline
static var playerUnitMatrix
static var enemyUnitMatrix

static var playerUnitMatrixBackup
static var enemyUnitMatrixBackup

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
static var matrixHeight: int = 6

static var playerEditor: UnitMatrixEditor
static var enemyEditor: UnitMatrixEditor

static var captureStatusUI: CaptureStatusUI

static var totalSectorsCount: int = 10

static var playerCapturedSectorsCount: int = 5

# economy stuff
static var playerFunds: int = 10
static var enemyFunds: int = 0

static var baseIncomeAmount: int = 10

static var autoHealRatio: float = 0.1
static var autoHealAmount: int = 1

static var enemyAI


static func _static_init():
	InitializeMatrix()
	enemyAI = EnemyAI_Randomizer.new()


func _ready():
	cycleTimer = $CycleTimer
	cycleLabel = $CycleCountLabel
	
	GameManager.cycleTimer.timeout.connect(_on_cycle_timer_timeout)
	
	$ProcessBattleButton.pressed.connect(_on_battle_process_button_pressed)
	
	playerEditor = $PlayerUnitMatrixEditor
	enemyEditor = $EnemyUnitMatrixEditor
	
	captureStatusUI = $CaptureStatusUI
	

func _on_cycle_timer_timeout():
	# if battle is finished, stop timer
	if GameManager.CycleProcess():
		print("\n***End Battle Process***\n\n")
		cycleTimer.stop()
		$ProcessBattleButton/InProcessLabel.visible = false
		GameManager.ImportUnitMatrixBackup()
		GameManager.HealUnits()
		playerEditor.ImportUnitMatrix()
		enemyEditor.ImportUnitMatrix()
		cycleCount = 0
	else:
		if cycleTimer.is_stopped():
			cycleTimer.start(GameManager.cycleTime)
			$ProcessBattleButton/InProcessLabel.visible = true
		

# called when player ends preparation phase and presses process battle button
func _on_battle_process_button_pressed():
	# add funds to both sides
	GameManager.AddIncome()
	
	# process enemy AI
	if enemyAI != null:
		enemyAI.GenerateUnitMatrix()
		enemyEditor.ImportReserve()
	
	# back up unit matrix
	playerUnitMatrixBackup = playerUnitMatrix.duplicate(true)
	enemyUnitMatrixBackup = enemyUnitMatrix.duplicate(true)
	
	# deep copy units
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrixBackup[col][row] != null:
				playerUnitMatrixBackup[col][row] = playerUnitMatrixBackup[col][row].Duplicate()
			if enemyUnitMatrixBackup[col][row] != null:
				enemyUnitMatrixBackup[col][row] = enemyUnitMatrixBackup[col][row].Duplicate()
	
	# process first cycle
	print("***Starting Battle Process***\n")
	GameManager.battleCount+= 1
	$BattleCountLabel.text = "Battle: " + str(GameManager.battleCount)
	print("Battle #" + str(GameManager.battleCount))
	if cycleTimer.is_stopped():
		cycleTimer.start(0)
		$ProcessBattleButton/InProcessLabel.visible = true
	

static func ImportUnitMatrixBackup():
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if playerUnitMatrixBackup[col][row] != null:
				# the unit was routed last battle
				if playerUnitMatrix[col][row] == null:
					playerUnitMatrixBackup[col][row].currentHealthPoints = 0
				else:
					playerUnitMatrixBackup[col][row].currentHealthPoints = playerUnitMatrix[col][row].currentHealthPoints
			if enemyUnitMatrixBackup[col][row] != null:
				if enemyUnitMatrix[col][row] == null:
					enemyUnitMatrixBackup[col][row].currentHealthPoints = 0
				else:
					enemyUnitMatrixBackup[col][row].currentHealthPoints = enemyUnitMatrix[col][row].currentHealthPoints
	
	# assign backup to unit matrix
	enemyUnitMatrix = enemyUnitMatrixBackup
	playerUnitMatrix = playerUnitMatrixBackup
	
	print("Imported backup unit matrix")
	
	
static func HealUnits():
	print("\nUnit Auto Heal\n")
	for col in range(matrixWidth):
		for row in range(matrixHeight):
			if enemyUnitMatrix[col][row] != null:
				enemyUnitMatrix[col][row].Heal(autoHealAmount)
			if playerUnitMatrix[col][row] != null:
				playerUnitMatrix[col][row].Heal(autoHealAmount)
	
	
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
	

# returns true if battle is over
static func CycleProcess():
	# stop cycle timer if one side wins
	cycleCount += 1
	cycleLabel.text = "Cycle: " + str(cycleCount)
	
	# update unit attack and movement costs
	UnitBehaviorProcess(playerUnitMatrix)
	UnitBehaviorProcess(enemyUnitMatrix)
	
	# modify grid according to unit movement
	ApplyUnitMovement(playerUnitMatrix)
	ApplyUnitMovement(enemyUnitMatrix)
	
	# generate damage matrix
	playerDamageMatrix = GenerateDamageMatrix(enemyUnitMatrix)
	enemyDamageMatrix = GenerateDamageMatrix(playerUnitMatrix)
	
	print("\nCycle #" + str(cycleCount))
	
	# reload editor UI to apply unit movement
	# unit cards on instantiation play unit attack animations if appropriate
	# when units' attack animation ends, their attack function is called
	# need to disable player messing with the editor while animations are playing
	# units get removed themselves when they die
	playerEditor.ImportUnitMatrix()
	enemyEditor.ImportUnitMatrix()
	
	var playerCount = UnitCount(playerUnitMatrix)
	var enemyCount = UnitCount(enemyUnitMatrix)
	
	EnemyAI_Randomizer.lostLastBattle = false
	
	if playerCount == 0 or enemyCount == 0:
		if playerCount == 0 and enemyCount == 0:
			print("Draw. Defender wins.")
		if playerCount == 0 and enemyCount != 0:
			print("enemy wins battle.")
			playerCapturedSectorsCount -= 1
		if playerCount != 0 and enemyCount == 0:
			print("player wins battle.")
			playerCapturedSectorsCount += 1
			EnemyAI_Randomizer.lostLastBattle = true
		
		captureStatusUI.ReloadUI(playerCapturedSectorsCount)
		
		print("Capture status: " + str(playerCapturedSectorsCount) + " / " + str(totalSectorsCount - playerCapturedSectorsCount))
		if playerCapturedSectorsCount == totalSectorsCount:
			print("player wins game!")
		if playerCapturedSectorsCount == 0:
			print("enemy wins game!")
		
		return true
	
	return false

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
					var target = FindAttackTarget(unitMatrix[col][row].isPlayer, row, unitMatrix[col][row].data.attackRange - col)
					
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

	
# TODO This needs fixing! Returning value when there isnt anything!!
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
		for i in range(matrixHeight):
			var upper: Unit = null
			var lower: Unit = null
			
			if curRow + i < matrixHeight:
				lower = checkingColumn[curRow + i]
			if curRow - i >= 0:
				upper = checkingColumn[curRow - i]
			
			# both exists return the one that has lower HP
			if upper != null and lower != null:
				if upper.currentHealthPoints < lower.currentHealthPoints:
					return Vector2(col_offset, curRow - i)
				elif upper.currentHealthPoints > lower.currentHealthPoints:
					return Vector2(col_offset, curRow + i)
				else:
					# return random one
					var rng = randi()
					if rng%2 == 0:
						return Vector2(col_offset, curRow + i)
					else:
						return Vector2(col_offset, curRow - i)
			else:
				if upper != null:
					return Vector2(col_offset, curRow - i)
				if lower != null:
					return Vector2(col_offset, curRow + i)
	
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


static func ResetFunds():
	playerFunds = 0
	enemyFunds = 0
	
	
static func AddIncome():
	var _playerDist = playerCapturedSectorsCount
	var _enemyDist = totalSectorsCount - playerCapturedSectorsCount
	
	playerFunds += baseIncomeAmount
	enemyFunds += baseIncomeAmount


static func ChangeFunds(amount, isPlayer: bool = true):
	if isPlayer:
		playerFunds += amount
		print("changed player funds by " + str(amount))
		print("New value: " + str(playerFunds) + "\n")
	else:
		enemyFunds += amount
		print("changed enemy funds by " + str(amount))
		print("New value: " + str(enemyFunds) + "\n")
