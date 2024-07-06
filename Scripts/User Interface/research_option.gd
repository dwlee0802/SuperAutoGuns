extends TextureButton
class_name ResearchOption

var data

var isPlayer: bool


func SetData(_data: UnitData, purchased: bool, _player):
	data = _data
	isPlayer = _player
	
	$HBoxContainer/Icon.self_modulate = data.color
	$HBoxContainer/NameLabel.text = tr(data.name)
	
	var stats = "HP: {hq} | ATK: {atk} | AS: {as} | MS: {ms}"
	stats = stats.format({
		"hq": data.maxHealthPoints,
		"atk": data.attackDamage,
		"as": data.attackCost,
		"ms": data.movementCost
		})
	
	$HBoxContainer/DescriptionLabel.text = tr(data.description) + "\n" + tr("COST") + ": " + str(data.researchCost)
	
	self.pressed.connect(OnSelected)
	
	if purchased:
		modulate = modulate.darkened(0.5)
		disabled = true
		
		
func OnSelected():
	if isPlayer:
		if GameManager.playerFunds >= data.researchCost:
			GameManager.ChangeFunds(-data.researchCost, isPlayer)
			DataManager.ResearchUnit(isPlayer, data)
			modulate = modulate.darkened(0.5)
			disabled = true
	else:
		if GameManager.enemyFunds >= data.researchCost:
			GameManager.ChangeFunds(-data.researchCost, isPlayer)
			DataManager.ResearchUnit(isPlayer, data)
			modulate = modulate.darkened(0.5)
			disabled = true
