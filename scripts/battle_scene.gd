extends Control

@onready var player_row: HBoxContainer = $Board/PlayerRow
@onready var enemy_row: HBoxContainer = $Board/EnemyRow

var champion_scene: PackedScene = preload("res://scenes/Champion.tscn")

var player_team := [
	{"name":"Shieldbearer","hp":40,"pwr":8,"armor":3},
	{"name":"Archer","hp":25,"pwr":12,"armor":1},
	{"name":"Priest","hp":30,"pwr":4,"armor":1}
]

var enemy_team := [
	{"name":"Bandit","hp":28,"pwr":10,"armor":1},
	{"name":"Wizard","hp":22,"pwr":14,"armor":0},
	{"name":"Brute","hp":50,"pwr":6,"armor":4}
]

var player_slots: Array[ChampionSlot] = []
var enemy_slots: Array[ChampionSlot] = []

func _ready() -> void:
	_spawn_row(player_row, player_team)
	_spawn_row(enemy_row, enemy_team)
	_cache_slots()
	# tiny delay so everything finishes instancing
	await get_tree().create_timer(0.4).timeout
	await _battle_loop()

func _spawn_row(row: HBoxContainer, team: Array) -> void:
	var count : int = min(team.size(), row.get_child_count())
	for i in count:
		var slot = row.get_child(i)
		if slot.has_method("place_champion"):
			slot.place_champion(champion_scene, team[i])

func _cache_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()

	for child in player_row.get_children():
		if child is ChampionSlot:
			player_slots.append(child)

	for child in enemy_row.get_children():
		if child is ChampionSlot:
			enemy_slots.append(child)

func _battle_loop() -> void:
	var current_side := "player"

	while true:
		if _is_team_defeated(player_slots):
			_on_battle_end("enemy")
			break
		if _is_team_defeated(enemy_slots):
			_on_battle_end("player")
			break

		if current_side == "player":
			await _team_attack(player_slots, enemy_slots)
			current_side = "enemy"
		else:
			await _team_attack(enemy_slots, player_slots)
			current_side = "player"

func _is_team_defeated(slots: Array[ChampionSlot]) -> bool:
	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			return false
	return true

func _get_first_living_champion(slots: Array[ChampionSlot]) -> Champion:
	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			return slot.champion
	return null

func _team_attack(attacking_slots: Array[ChampionSlot], defending_slots: Array[ChampionSlot]) -> void:
	for slot in attacking_slots:
		var attacker: Champion = slot.champion
		if attacker == null or attacker.is_dead():
			continue

		var target: Champion = _get_first_living_champion(defending_slots)
		if target == null:
			return # other team is dead mid-turn

		# TODO: Add animations, SFX, etc.
		attacker.attack(target)

		# Small pause between attacks so you can see it happen
		await get_tree().create_timer(0.4).timeout

func _on_battle_end(winner: String) -> void:
	print("Battle over! Winner: ", winner)
	# Later: show a label, button to return to menu, rewards, etc.
