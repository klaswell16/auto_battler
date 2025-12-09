extends Control
class_name Shop

@export var available_units: Array = []
@export var shop_slot_scene: PackedScene
@export var slots_per_roll: int = 5
@export var reroll_cost: int = 2

@onready var gold_label: Label = $GoldLabel
@onready var round_label: Label = $RoundLabel
@onready var slots_container: HBoxContainer = $SlotsContainer
@onready var reroll_button: Button = $RerollButton
@export var owned_portrait_scene: PackedScene
@onready var owned_container: HBoxContainer = $OwnedContainer


var current_slots: Array = []

func _ready() -> void:
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
	_update_ui()
	roll_shop()
	_refresh_owned_units_ui()

func _update_ui() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % BattleContext.gold
	if round_label:
		round_label.text = "Round: %d" % BattleContext.round

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
		var data = available_units[data_index]

		var slot: ShopSlot = shop_slot_scene.instantiate()
		slots_container.add_child(slot)
		slot.set_offer(data)
		slot.buy_pressed.connect(_on_slot_buy_pressed)
		current_slots.append(slot)

func _on_slot_buy_pressed(data, cost: int) -> void:
	if BattleContext.gold < cost:
		print("Not enough gold!")
		return

	BattleContext.gold -= cost
	BattleContext.add_unit(data)
	_update_ui()
	_refresh_owned_units_ui()

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
	_update_ui()
	roll_shop()

func _refresh_owned_units_ui() -> void:
	if owned_container == null:
		return

	# Clear old portraits
	for child in owned_container.get_children():
		child.queue_free()

	# Add one portrait per owned unit
	for data in BattleContext.owned_units:
		if data == null:
			continue

		var pb := owned_portrait_scene.instantiate()
		# Optional: cast for editor hints, but not required for runtime
		# var pb: PortraitButton = owned_portrait_scene.instantiate()

		owned_container.add_child(pb)
		
		pb.unit_name = data.display_name
		pb.portrait = data.portrait_texture
		pb.disabled = true   # bench is informational

		# ⭐ Read star rank from BattleContext.star_levels
		var key := data.resource_path
		var star: int = int(BattleContext.star_levels.get(key, 1))
		pb.star_rank = star

		
		pb.unit_name = data.display_name
		pb.portrait = data.portrait_texture

		# Bench portraits are informational
		pb.disabled = true

func _on_start_battle_button_pressed() -> void:
	# Only start if the player actually has units
	if BattleContext.owned_units.is_empty():
		print("No units yet! Buy something first.")
		return

	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
