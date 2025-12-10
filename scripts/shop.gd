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

var _selected_bench_index: int = -1

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

	for child in owned_container.get_children():
		child.queue_free()

	for i in BattleContext.owned_units.size():
		var inst = BattleContext.owned_units[i]
		var data: ChampionData = inst.data
		var star: int = inst.star

		if data == null:
			continue

		var pb: PortraitButton = owned_portrait_scene.instantiate()
		owned_container.add_child(pb)

		pb.unit_name = data.display_name
		pb.portrait = data.portrait_texture
		pb.star_rank = star
		pb.disabled = false

		# Hover → show effective stats for THIS star level
		pb.mouse_entered.connect(_on_owned_portrait_mouse_entered.bind(data, star))
		pb.mouse_exited.connect(_on_owned_portrait_mouse_exited)

		# Click → select / swap
		pb.pressed.connect(_on_owned_portrait_pressed.bind(i))

		
func _on_owned_portrait_pressed(index: int) -> void:
	# First click: select a slot
	if _selected_bench_index == -1:
		_selected_bench_index = index
		_highlight_bench_index(index, true)
		return

	# Clicking the same slot again: cancel selection
	if _selected_bench_index == index:
		_highlight_bench_index(index, false)
		_selected_bench_index = -1
		return

	# Second different slot: swap the two units in BattleContext
	_swap_owned_units(_selected_bench_index, index)

	# Clear visual selection
	_clear_all_bench_highlights()
	_selected_bench_index = -1

	# Rebuild UI to reflect new order
	_refresh_owned_units_ui()

func _swap_owned_units(a: int, b: int) -> void:
	if a < 0 or b < 0:
		return
	if a >= BattleContext.owned_units.size() or b >= BattleContext.owned_units.size():
		return

	var tmp := BattleContext.owned_units[a]
	BattleContext.owned_units[a] = BattleContext.owned_units[b]
	BattleContext.owned_units[b] = tmp

func _highlight_bench_index(index: int, active: bool) -> void:
	if owned_container == null:
		return
	if index < 0 or index >= owned_container.get_child_count():
		return

	var child = owned_container.get_child(index)
	if child is PortraitButton:
		child.set_active(active)  # uses your existing border highlight logic

func _clear_all_bench_highlights() -> void:
	if owned_container == null:
		return
	for child in owned_container.get_children():
		if child is PortraitButton:
			child.set_active(false)


func _on_owned_portrait_mouse_entered(data: ChampionData, star: int) -> void:
	_show_unit_info(data, star)

func _on_owned_portrait_mouse_exited() -> void:
	_clear_unit_info()

		
func _show_unit_info(data: ChampionData, star: int = 1) -> void:
	if data == null:
		return

	unit_info_panel.visible = true

	var star_level :int = max(1, star)
	var star_mult: float = 1.0 + 0.5 * float(star_level - 1)

	var effective_hp: int = int(data.max_hp * star_mult)
	var effective_power: int = int(data.power * star_mult)
	# Armor / speed don’t scale with stars
	var effective_armor: int = data.armor
	var effective_speed: int = data.speed

	info_name_label.text = data.display_name
	info_star_label.text = "Stars: %d" % star_level

	# Show effective stats 
	info_hp_label.text = "HP: %d" % effective_hp
	info_power_label.text = "Power: %d" % effective_power
	info_armor_label.text = "Armor: %d" % effective_armor
	info_speed_label.text = "Speed: %d" % effective_speed


func _clear_unit_info() -> void:
	unit_info_panel.visible = false


func _on_start_battle_button_pressed() -> void:
	# Only start if the player actually has units
	if BattleContext.owned_units.is_empty():
		print("No units yet! Buy something first.")
		return

	get_tree().change_scene_to_file("res://scenes/battle_scene.tscn")
