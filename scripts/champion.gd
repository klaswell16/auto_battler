extends Node2D
class_name Champion

@export var display_name := "Unit"
@export var max_hp := 30
@export var power := 8
@export var armor := 2

var hp: int

@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var name_label: Label = $UI/NameLabel

func _ready():
	hp = max_hp
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	name_label.text = display_name

# Called by ChampionSlot.place_champion
func apply_data(d: Dictionary) -> void:
	display_name = d.get("name", display_name)
	max_hp = d.get("hp", max_hp)
	power = d.get("pwr", power)
	armor = d.get("armor", armor)
	hp = max_hp
	if is_instance_valid(hp_bar):
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if is_instance_valid(name_label):
		name_label.text = display_name
