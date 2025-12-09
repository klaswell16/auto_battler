extends Control

@onready var player_row: HBoxContainer = $Board/PlayerRow
@onready var enemy_row: HBoxContainer = $Board/EnemyRow

var champion_scene: PackedScene = preload("res://scenes/Champion.tscn")

var player_team: Array[ChampionData] = []
@export var enemy_team: Array[ChampionData]

var player_slots: Array = []
var enemy_slots: Array = []

func _ready() -> void:
	player_team = BattleContext.owned_units.duplicate()
	_spawn_row(player_row, player_team)
	_spawn_row(enemy_row, enemy_team)
	_cache_slots()
	_start_battle()

func _start_battle() -> void:
	call_deferred("_run_battle")

func _run_battle() -> void:
	await get_tree().create_timer(0.4).timeout
	await _battle_loop_speed_based()

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
		if child.has_method("place_champion"):
			player_slots.append(child)

	for child in enemy_row.get_children():
		if child.has_method("place_champion"):
			enemy_slots.append(child)

	print("Cached slots -> player:", player_slots.size(), " enemy:", enemy_slots.size())

func _battle_loop_speed_based() -> void:
	while true:
		if _is_team_defeated(player_slots):
			_on_battle_end("enemy")
			return
		if _is_team_defeated(enemy_slots):
			_on_battle_end("player")
			return

		var actors: Array = _get_actors_in_speed_order()
		if actors.is_empty():
			print("No actors left, battle is a draw?")
			return

		for actor in actors:
			var champ: Champion = actor["champ"]
			var team: String = actor["team"]

			if champ == null or champ.is_dead():
				continue

			var defenders: Array = enemy_slots if team == "player" else player_slots

			var target: Champion = _get_first_living_champion(defenders)
			if target == null:
				if team == "player":
					_on_battle_end("player")
				else:
					_on_battle_end("enemy")
				return

			await champ.attack(target)

			await get_tree().create_timer(0.4).timeout

			if _is_team_defeated(defenders):
				if team == "player":
					_on_battle_end("player")
				else:
					_on_battle_end("enemy")
				return

func _get_actors_in_speed_order() -> Array:
	var actors: Array = []

	for slot in player_slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			actors.append({
				"champ": slot.champion,
				"team": "player"
			})

	for slot in enemy_slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			actors.append({
				"champ": slot.champion,
				"team": "enemy"
			})

	actors.sort_custom(Callable(self, "_compare_actor_speed"))
	return actors

func _compare_actor_speed(a: Dictionary, b: Dictionary) -> bool:
	var ca: Champion = a["champ"]
	var cb: Champion = b["champ"]

	if ca.speed == cb.speed:
		if a["team"] == b["team"]:
			return true
		return a["team"] == "player"

	return ca.speed > cb.speed

func _is_team_defeated(slots: Array) -> bool:
	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			return false
	return true

func _get_first_living_champion(slots: Array) -> Champion:
	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			return slot.champion
	return null

func _on_battle_end(winner: String) -> void:
	print("Battle over! Winner: ", winner)

	# Simple version: go back to the shop after each battle
	await get_tree().create_timer(1.0).timeout  # small pause so you see the result
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
