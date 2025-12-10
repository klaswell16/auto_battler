extends Node2D
class_name Champion

@export var display_name := "Unit"
@export var max_hp := 30
@export var power := 8
@export var armor := 2
@export var speed :=1
@export var star_level: int = 1

@export var attack_sounds: Array[AudioStream] = []

var hp: int
@onready var body_sprite: Sprite2D = $Body

@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var name_label: Label = $UI/NameLabel
@onready var attack_player: AudioStreamPlayer = $AttackPlayer
const DAMAGE_NUMBER_SCENE := preload("res://ui/DamageNumber.tscn")


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
		
func flip_sprite(is_enemy: bool) -> void:
	if is_enemy:
		body_sprite.flip_h = true
	else:
		body_sprite.flip_h = false

# Called by ChampionSlot.place_champion
func apply_data(d: ChampionData, stat_mult: float = 1.0, star_level_in: int = 1) -> void:
	if d is ChampionData:
		display_name = d.display_name
		star_level = max(1, star_level_in)

		# Star multiplier: 1★ = 1.0, 2★ = 1.5, 3★ = 2.0
		var star_mult: float = 1.0 + 0.5 * float(star_level - 1)

		max_hp = int(d.max_hp * stat_mult * star_mult)
		power  = int(d.power  * stat_mult * star_mult)
		armor  = d.armor      
		speed  = d.speed      

		if is_instance_valid(body_sprite) and d.body_texture:
			body_sprite.texture = d.body_texture

		hp = max_hp
		_refresh_ui()
	else:
		
		pass

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
	_spawn_damage_number(reduced)
	set_hp(hp - reduced)

func heal(amount: int) -> void:
	if hp <= 0:
		return
	set_hp(hp + amount)

func is_dead() -> bool:
	return hp <= 0
	
func _play_random_attack_sound() -> void:
	if attack_sounds.is_empty() or attack_player == null:
		return
	var sfx := attack_sounds[randi() % attack_sounds.size()]
	attack_player.stream = sfx
	attack_player.play()
	
func _spawn_damage_number(amount: int) -> void:
	if amount <= 0:
		return

	var dn: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position + Vector2(0, -10)
	dn.show_value(amount)


	
func attack(target: Champion) -> void:
	if target == null:
		return
	if is_dead() or target.is_dead():
		return
		
	_play_random_attack_sound()
	
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
	
