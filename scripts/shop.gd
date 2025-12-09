extends Control
class_name Shop

@export var available_units: Array[ChampionData] = []
@export var shop_slot_scene: PackedScene
@export var slots_per_roll: int = 5
@export var reroll_cost: int = 2

@onready var gold_label: Label = $GoldLabel
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var reroll_button: Button = $RerollButton

var current_slots: Array[ShopSlot] = []

func _ready() -> void:
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	_update_gold_label()
	roll_shop()

func _update_gold_label() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % BattleContext.gold

func clear_slots() -> void:
	for slot in current_slots:
		if is_instance_valid(slot):
			slot.queue_free()
	current_slots.clear()

func roll_shop() -> void:
	clear_slots()
	if available_units.is_empty():
		return

	var count: int = min(slots_per_roll, available_units.size())
	for i in count:
		var data_index: int = randi() % available_units.size()
		var data: ChampionData = available_units[data_index]

		var slot: ShopSlot = shop_slot_scene.instantiate()
		slots_container.add_child(slot)
		slot.set_offer(data)
		slot.buy_pressed.connect(_on_slot_buy_pressed)
		current_slots.append(slot)

func _on_slot_buy_pressed(data: ChampionData, cost: int) -> void:
	if BattleContext.gold < cost:
		print("Not enough gold!")
		# You could flash the cost in red here
		return

	BattleContext.gold -= cost
	BattleContext.add_unit(data)
	_update_gold_label()

	# Optionally remove or gray-out the bought slot
	for slot in current_slots:
		if slot.data == data:
			slot.modulate = Color(0.5, 0.5, 0.5, 1.0)
			if slot.buy_button:
				slot.buy_button.disabled = true
			break

	print("Bought ", data.display_name)

func _on_reroll_pressed() -> void:
	if BattleContext.gold < reroll_cost:
		print("Not enough gold to reroll!")
		return

	BattleContext.gold -= reroll_cost
	_update_gold_label()
	roll_shop()


func _on_start_battle_button_pressed() -> void:
	# Only start if the player actually has units
	if BattleContext.owned_units.is_empty():
		print("No units yet! Buy something first.")
		return

	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
