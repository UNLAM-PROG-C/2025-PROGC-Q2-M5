extends CharacterBody2D

# Constantes de movimiento
const SPEED = 300.0
const JUMP_VELOCITY = -500.0

# Variables de estado
var is_alive = true
var respawn_position = Vector2.ZERO

# Señales para comunicación (concepto de IPC/Comunicación)
signal player_died
signal player_reached_checkpoint

func _ready():
	# Guardar posición inicial como punto de respawn
	respawn_position = global_position

func _physics_process(delta):
	if not is_alive:
		return
	
	# Verificar si cayó al vacío
	if global_position.y > 700:
		die()
		return
	
	# Agregar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	# ... resto del código
	if not is_alive:
		return
	
	# Agregar gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Manejo del salto
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Obtener dirección de movimiento (izquierda/derecha)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Mover el personaje
	move_and_slide()

func die():
	"""Mata al jugador y emite señal"""
	if not is_alive:
		return
	
	is_alive = false
	player_died.emit()
	
	# Efecto visual de muerte
	modulate = Color(1, 0, 0, 0.5)  # Rojo semi-transparente
	
	# Esperar 1 segundo y respawnear
	await get_tree().create_timer(1.0).timeout
	respawn()

func respawn():
	"""Reaparece en el punto de respawn"""
	global_position = respawn_position
	velocity = Vector2.ZERO
	is_alive = true
	modulate = Color(1, 1, 1, 1)  # Color normal

func set_checkpoint(new_position: Vector2):
	"""Establece un nuevo punto de respawn"""
	respawn_position = new_position
	player_reached_checkpoint.emit()

func _on_trap_area_entered(area):
	"""Detecta cuando entra en un área de trampa"""
	if area.is_in_group("traps"):
		die()


func _on_trap_detector_area_entered() -> void:
	pass # Replace with function body.
