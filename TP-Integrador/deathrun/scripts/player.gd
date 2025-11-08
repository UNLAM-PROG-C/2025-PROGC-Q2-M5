extends CharacterBody2D

# ===== Constantes de movimiento =====
const SPEED: float = 180.0
const JUMP_VELOCITY: float = -250.0
const MAX_JUMPS: int = 2
# Umbral para considerar "quieto" (evita ruido/velocidad residual)
const IDLE_EPS: float = 5.0

# ===== Estado =====
var is_alive: bool = true
var respawn_position: Vector2 = Vector2.ZERO
var jumps_remaining: int = MAX_JUMPS

# ===== Animación =====
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Collider (puede ser null si el nodo no existe)
@onready var collider: CollisionShape2D = get_node_or_null("CollisionShape2D")

# ===== Señales =====
signal player_died
signal player_reached_checkpoint

func _ready() -> void:
	respawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Caída al vacío → muerte
	if global_position.y > 700.0:
		die()
		return

	# Gravedad y reset de saltos en suelo
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_remaining = MAX_JUMPS

	# Salto
	if Input.is_action_just_pressed("move_up") and jumps_remaining > 0:
		velocity.y = JUMP_VELOCITY
		jumps_remaining -= 1

	# Movimiento horizontal con deadzone para axis/ruido
	var direction: float = Input.get_axis("move_left", "move_right")
	if abs(direction) > 0.1:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()

	# ===== Animaciones basadas en estado físico =====
	var on_floor: bool = is_on_floor()
	var moving_h: bool = abs(velocity.x) > IDLE_EPS

	# Girar sprite según movimiento real
	if moving_h:
		anim_sprite.flip_h = velocity.x < 0.0

	# Cambiar anim solo cuando hace falta (no reiniciar por frame)
	if on_floor and moving_h:
		if anim_sprite.animation != "Running":
			anim_sprite.play("Running")
	elif on_floor and not moving_h:
		if anim_sprite.animation != "Default":
			anim_sprite.play("Default")
	# (Si querés, después sumamos "Jump"/"Fall" en el aire)

	# ===== Sincronización multijugador =====
	if multiplayer.is_server() and NetworkManager.is_multiplayer_active():
		rpc("sync_position", global_position, velocity)

@rpc("authority", "unreliable")
func sync_position(pos: Vector2, vel: Vector2) -> void:
	# Los clientes aplican la posición/velocidad del servidor
	if not multiplayer.is_server():
		global_position = pos
		velocity = vel

func die() -> void:
	if not is_alive:
		return

	is_alive = false
	player_died.emit()

	# Detener movimiento y desactivar colisión mientras "muere"
	velocity = Vector2.ZERO
	if collider:
		collider.disabled = true

	# Animación de muerte si existe
	if "Death" in anim_sprite.sprite_frames.get_animation_names():
		anim_sprite.play("Death")
	else:
		anim_sprite.play("Default")

	# ==== Efecto "irse al cielo" (sin desvanecer) ====
	var rise_height: float = 80.0      # cuánto sube en píxeles
	var rise_duration: float = 0.8      # duración de la subida en segundos
	var start_pos := global_position
	var end_pos := start_pos + Vector2(0, -rise_height)

	var tween := get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", end_pos, rise_duration)

	# Espera a que termine la subida
	await tween.finished

	respawn()

func respawn() -> void:
	# Volver a animación base
	anim_sprite.play("default")
	global_position = respawn_position
	velocity = Vector2.ZERO
	is_alive = true
	modulate = Color(1, 1, 1, 1)
	jumps_remaining = MAX_JUMPS

	# Reactivar colisión
	if collider:
		collider.disabled = false



func set_checkpoint(new_position: Vector2) -> void:
	respawn_position = new_position
	player_reached_checkpoint.emit()

func _on_trap_area_entered(area: Node) -> void:
	if area.is_in_group("traps"):
		die()
