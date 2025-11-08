extends AnimatableBody2D

@onready var col_shape = $CollisionShape2D
@onready var sprite = $Sprite2D
@onready var area = $Area2D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Baja con tween
		var start_y = global_position.y
		var end_y = start_y + 120  # cuánto baja
		var tween = get_tree().create_tween()
		tween.tween_property(self, "global_position:y", end_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		
		# Se desactiva para que el jugador pase
		col_shape.disabled = true
		await get_tree().create_timer(1.0).timeout
		# Vuelve a subir
		var tween2 = get_tree().create_tween()
		tween2.tween_property(self, "global_position:y", start_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween2.finished
		col_shape.disabled = false
