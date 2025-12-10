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

@onready var unit_info_panel: PanelContainer = $UnitInfoPanel
@onready var info_name_label: Label = $UnitInfoPanel/VBoxContainer/NameLabel
@onready var info_star_label: Label = $UnitInfoPanel/VBoxContainer/StarLabel
@onready var info_hp_label: Label = $UnitInfoPanel/VBoxContainer/HpLabel
@onready var info_power_label: Label = $UnitInfoPanel/VBoxContainer/PowerLabel
@onready var info_armor_label: Label = $UnitInfoPanel/VBoxContainer/ArmorLabel
@onready var info_speed_label: Label = $UnitInfoPanel/VBoxContainer/SpeedLabel

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
		var data: ChampionData = available_units[data_index]

		var slot: ShopSlot = shop_slot_scene.instantiate()
		slots_container.add_child(slot)
		slot.set_offer(data)

		
		slot.buy_pressed.connect(_on_slot_buy_pressed)

		slot.mouse_entered.connect(_on_shop_slot_mouse_entered.bind(data))
		slot.mouse_exited.connect(_on_shop_slot_mouse_exited)

		current_slots.append(slot)



func _on_shop_slot_mouse_entered(data: ChampionData) -> void:
	_show_unit_info(data, 1)

func _on_shop_slot_mouse_exited() -> void:
	_clear_unit_info()

func _on_slot_buy_pressed(slot: ShopSlot, data: ChampionData, cost: int) -> void:
	if BattleContext.gold < cost:
		print("Not enough gold!")
		return

	# Take payment + add unit
	BattleContext.gold -= cost
	BattleContext.add_unit(data)
	_update_ui()
	_refresh_owned_units_ui()

	# Consume this shop slot: gray it out + disable
	if is_instance_valid(slot):
		slot.modulate = Color(0.5, 0.5, 0.5, 1.0)
		if slot.buy_button:
			slot.buy_button.disabled = true

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

		# star rank from BattleContext.star_levels
		var key := data.resource_path
		var star: int = int(BattleContext.star_levels.get(key, 1))
		pb.star_rank = star
		
		pb.mouse_entered.connect(_on_owned_portrait_mouse_entered.bind(data, star))
		pb.mouse_exited.connect(_on_owned_portrait_mouse_exited)
		
		pb.unit_name = data.display_name
		pb.portrait = data.portrait_texture

		# Bench portraits are informational
		pb.disabled = true
func _on_owned_portrait_mouse_entered(data: ChampionData, star: int) -> void:
	_show_unit_info(data, star)

func _on_owned_portrait_mouse_exited() -> void:
	_clear_unit_info()

		
func _show_unit_info(data: ChampionData, star: int = 1) -> void:
	if data == null:
		return

	unit_info_panel.visible = true

	info_name_label.text = data.display_name
	info_star_label.text = "Stars: %d" % star
	info_hp_label.text = "HP: %d" % data.max_hp
	info_power_label.text = "Power: %d" % data.power
	info_armor_label.text = "Armor: %d" % data.armor
	info_speed_label.text = "Speed: %d" % data.speed

func _clear_unit_info() -> void:
	unit_info_panel.visible = false


func _on_start_battle_button_pressed() -> void:
	# Only start if the player actually has units
	if BattleContext.owned_units.is_empty():
		print("No units yet! Buy something first.")
		return

	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
