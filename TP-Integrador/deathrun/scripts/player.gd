extends CharacterBody2D

# Constantes de movimiento
const SPEED = 180.0
const JUMP_VELOCITY = -250.0
const MAX_JUMPS = 2  # Número de saltos permitidos

# Variables de estado
var is_alive = true
var respawn_position = Vector2.ZERO
var jumps_remaining = MAX_JUMPS  # Contador de saltos disponibles

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
	else:
		# Resetear saltos cuando toca el suelo
		jumps_remaining = MAX_JUMPS
		
		# Manejo del salto (con doble salto)
	if Input.is_action_just_pressed("ui_up") and jumps_remaining > 0:
		velocity.y = JUMP_VELOCITY
		jumps_remaining -= 1
	
	# Obtener dirección de movimiento (izquierda/derecha)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Mover el personaje
	move_and_slide()
	
	# Sincronizar posición en multijugador
	if multiplayer.is_server() and NetworkManager.is_multiplayer_active():
		rpc("sync_position", global_position, velocity)

@rpc("authority", "unreliable")
func sync_position(pos: Vector2, vel: Vector2):
	"""Sincroniza la posición del jugador desde el servidor"""
	if not multiplayer.is_server():
		global_position = pos
		velocity = vel

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
	jumps_remaining = MAX_JUMPS  # Resetear saltos

func set_checkpoint(new_position: Vector2):
	"""Establece un nuevo punto de respawn"""
	respawn_position = new_position
	player_reached_checkpoint.emit()

func _on_trap_area_entered(area):
	"""Detecta cuando entra en un área de trampa"""
	if area.is_in_group("traps"):
		die()
