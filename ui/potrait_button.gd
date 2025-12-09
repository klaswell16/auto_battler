extends Button
class_name PortraitButton

@export var portrait: Texture2D:
	set(value):
		portrait = value
		if is_inside_tree():
			$Portrait.texture = portrait

@export var unit_name: String = "":
	set(value):
		unit_name = value
		if is_inside_tree() and has_node("NameLabel"):
			$NameLabel.text = unit_name
			
@export var star_rank: int = 1:
	set(value):
		star_rank = max(1, value)
		if is_inside_tree() and has_node("StarLabel"):
			# Either "★", "★★", "★★★" or "★2" style — pick one
			$StarLabel.text = "★" + str(star_rank)
			# or: $StarLabel.text = "★".repeat(star_rank)

@export var border_active_color: Color = Color(1.0, 0.85, 0.2, 1.0)
@export var border_inactive_color: Color = Color(1, 1, 1, 0.0)
@export var dead_dim_color: Color = Color(0, 0, 0, 0.45)
@export var acted_dim_color: Color = Color(0, 0, 0, 0.22)

var _is_active: bool = false
var _is_dead: bool = false
var _has_acted: bool = false

func _ready() -> void:
	focus_mode = FOCUS_ALL
	if has_node("NameLabel"):
		$NameLabel.text = unit_name
	if has_node("StarLabel"):
		$StarLabel.text = "★" + str(star_rank)
	_apply_visuals()

func _on_pressed() -> void:
	print("Portrait button pressed!")
	pulse_active()

func _on_mouse_entered() -> void:
	print("Hovering over portrait button!")

func set_active(state: bool) -> void:
	_is_active = state
	_apply_visuals()

func set_dead(state: bool) -> void:
	_is_dead = state
	if state:
		_has_acted = true
	_apply_visuals()

func set_has_acted(state: bool) -> void:
	_has_acted = state
	_apply_visuals()

func _apply_visuals() -> void:
	$Border.color = border_active_color if _is_active else border_inactive_color

	if _is_dead:
		$Mask.color = dead_dim_color
	elif _has_acted:
		$Mask.color = acted_dim_color
	else:
		$Mask.color = Color(0, 0, 0, 0)

func pulse_active() -> void:
	if not is_inside_tree():
		return
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12).from(Vector2.ONE)
	t.tween_property(self, "scale", Vector2.ONE, 0.12).set_delay(0.04)
