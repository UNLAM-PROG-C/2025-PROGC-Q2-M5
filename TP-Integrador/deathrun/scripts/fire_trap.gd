extends Area2D

# ===== Config =====
@export var detection_range: float = 110.0      # distancia para iniciar por proximidad
@export var activando_duration: float = 0.8     # cuánto dura la carga ("activando")
@export var activado_duration: float = 3.0      # cuánto tiempo queda dañina ("activado")
@export var apagar_duration: float = 0.6        # duración de "apagar"
@export var cooldown_duration: float = 5.0      # espera para poder re-activar

# ===== Nodos =====
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D   # anims: "IDLE","activando","activado","apagar"
@onready var hit_shape: CollisionShape2D = $CollisionShape2D

# ===== Estado =====
enum TrapState { INACTIVE, ACTIVANDO, ACTIVADO, APAGANDO, COOLDOWN }
var state: TrapState = TrapState.INACTIVE
var _cycle_running: bool = false
var _next_allowed_time: float = 0.0
var player: Node = null

# (opcional) estadística de golpes
signal player_hit()

func _ready() -> void:
	add_to_group("traps")
	monitoring = true
	monitorable = true

	hit_shape.disabled = true
	sprite.play("idle")

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Si el jugador entra mientras está "activado", lo mata
	body_entered.connect(func (body: Node) -> void:
		if state == TrapState.ACTIVADO and body.is_in_group("player") and body.has_method("die"):
			body.die()
			player_hit.emit()
	)

func _physics_process(_delta: float) -> void:
	# Arranca el ciclo solo si: está inactiva, no hay ciclo corriendo, se cumplió el cooldown y el player está cerca
	if state == TrapState.INACTIVE and not _cycle_running and _time_now() >= _next_allowed_time and _player_near():
		_run_cycle()

# ===== Secuencia: activando -> activado -> apagar -> IDLE (cooldown) =====
func _run_cycle() -> void:
	_cycle_running = true

	# 1) ACTIVANDO (cargando, no daña)
	state = TrapState.ACTIVANDO
	sprite.play("activando")
	hit_shape.disabled = true
	await get_tree().create_timer(activando_duration).timeout

	# 2) ACTIVADO (daña durante X segundos)
	state = TrapState.ACTIVADO
	sprite.play("activado")
	hit_shape.disabled = false
	await get_tree().create_timer(activado_duration).timeout

	# 3) APAGANDO (ya no daña)
	state = TrapState.APAGANDO
	hit_shape.disabled = true
	sprite.play("apagar")
	await get_tree().create_timer(apagar_duration).timeout

	# 4) COOLDOWN visual en IDLE, bloqueada por cooldown_duration
	state = TrapState.COOLDOWN
	sprite.play("idle")
	_next_allowed_time = _time_now() + cooldown_duration
	await get_tree().create_timer(cooldown_duration).timeout

	# 5) Lista para re-activar
	state = TrapState.INACTIVE
	_cycle_running = false

# ===== Helpers =====
func _player_near() -> bool:
	return player != null and global_position.distance_to(player.global_position) <= detection_range

func _time_now() -> float:
	return Time.get_ticks_msec() * 0.001
