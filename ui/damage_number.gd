extends Node2D
class_name DamageNumber

@onready var label: Label = $Label

func show_value(amount: int) -> void:
	label.text = str(amount)

func _ready() -> void:
	# Float up slowly
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	
	tween.tween_property(self, "position:y", position.y - 40, 1.2)

	# Fade out 
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)

	tween.finished.connect(queue_free)
