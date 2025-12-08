extends Node2D
class_name Champion

@export var display_name := "Unit"
@export var max_hp := 30
@export var power := 8
@export var armor := 2
@export var speed :=1

var hp: int

@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var name_label: Label = $UI/NameLabel

func _ready() -> void:
	hp = max_hp
	_refresh_ui()

func _refresh_ui() -> void:
	if is_instance_valid(hp_bar):
		hp_bar.min_value = 0
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if is_instance_valid(name_label):
		name_label.text = display_name

# Called by ChampionSlot.place_champion
func apply_data(d: Dictionary) -> void:
	display_name = d.get("name", display_name)
	max_hp = d.get("hp", max_hp)
	power = d.get("pwr", power)
	armor = d.get("armor", armor)
	speed = d.get("spd", speed)
	hp = max_hp
	_refresh_ui()

func set_hp(value: int) -> void:
	hp = clamp(value, 0, max_hp)
	if is_instance_valid(hp_bar):
		hp_bar.value = hp
	# Visual feedback on death (but don't free yet)
	if hp <= 0:
		modulate = Color(0.4, 0.4, 0.4) # grey them out

func take_damage(raw_amount: int) -> void:
	if hp <= 0:
		return
	var reduced : int = max(raw_amount - armor, 1) # at least 1 dmg
	set_hp(hp - reduced)

func heal(amount: int) -> void:
	if hp <= 0:
		return
	set_hp(hp + amount)

func is_dead() -> bool:
	return hp <= 0

func attack(target: Champion) -> void:
	if target == null:
		return
	if is_dead() or target.is_dead():
		return

	# --- Lunge towards the target ---
	var start_pos: Vector2 = global_position
	var dir: Vector2 = (target.global_position - start_pos).normalized()
	var lunge_pos: Vector2 = start_pos + dir * 20.0  # how far to jump

	var tween := create_tween()
	tween.tween_property(self, "global_position", lunge_pos, 0.08)
	tween.tween_property(self, "global_position", start_pos, 0.12)

	# Wait until the lunge forward + back is done
	await tween.finished

	# --- Hit flash on the target ---
	var original_modulate := target.modulate
	target.modulate = Color(1, 0.5, 0.5)  # light red
	await get_tree().create_timer(0.1).timeout
	target.modulate = original_modulate

	# --- Apply damage AFTER the animation ---
	target.take_damage(power)
