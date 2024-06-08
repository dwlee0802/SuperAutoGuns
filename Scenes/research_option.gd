extends Control
class_name ResearchOption

var data

@onready var selectButton: Button = $SelectButton


func SetData(_data: UnitData, purchased: bool):
	data = _data
	$SelectButton.disabled = purchased
	$Icon.self_modulate = data.color
	$NameLabel.text = data.name
	
	var stats = "HP: {hq} | ATK: {atk} | AS: {as} | MS: {ms}"
	stats = stats.format({
		"hq": data.maxHealthPoints,
		"atk": data.attackDamage,
		"as": data.attackCost,
		"ms": data.movementCost
		})
	
	$StatsLabel.text = stats
	$DescriptionLabel.text = data.description
