extends AnimatableBody2D

# ---------- Config ----------
@export var trap_id: int = 0
@export var drop_distance: float = 180.0
@export var drop_time: float = 0.7
@export var hold_time: float = 0.60
@export var rise_time: float = 0.35
@export var cooldown_time: float = 1.20

# Single vs Multi
@export var auto_activate_singleplayer: bool = true   # en single se activa sola por trigger
@export var mp_requires_master: bool = true           # en multi, SOLO Trap Master

# ---------- Estado ----------
enum TrapState { INACTIVE, DROPPING, HOLDING, RAISING, COOLDOWN, DISABLED }
var state: TrapState = TrapState.INACTIVE
var busy: bool = false
var original_y: float

# ---------- Nodos ----------
@onready var solid_col: CollisionShape2D = $CollisionShape2D
@onready var kill_zone: Area2D          = $KillZone
@onready var trigger_zone: Area2D       = $TriggerZone
@onready var sprite: Sprite2D           = get_node_or_null("Sprite2D")

# Señales p/TrapManager
signal trap_activated(trap_id)
signal trap_deactivated(trap_id)
signal player_hit(trap_id)

func _ready() -> void:
	add_to_group("traps")
	original_y = global_position.y

	# conexiones
	trigger_zone.body_entered.connect(_on_trigger_enter)
	trigger_zone.body_exited.connect(_on_trigger_exit)
	kill_zone.body_entered.connect(_on_kill_enter)

	# La zona que mata solo se usa durante la caída/hold
	_set_kill_enabled(false)

func _on_trigger_enter(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if NetworkManager.is_multiplayer_active() and not multiplayer.is_server():
		return
		
	_try_start_cycle_server()

	# Multiplayer: NO auto-activar si requiere Trap Master
	# (solo se activará cuando el server llame force_activate() vía TrapManager)
	if not mp_requires_master:
		_try_start_cycle_server()


func _on_trigger_exit() -> void:
	# solo usamos esto para saber si hay alguien debajo (opcional)
	pass

func _on_kill_enter(body: Node) -> void:
	# Consideramos "server" si hay peer y somos server; en single siempre seguimos
	var is_mp: bool = multiplayer.has_multiplayer_peer()
	if is_mp and not multiplayer.is_server():
		return

	# Debug rápido (eliminá cuando funcione)
	# print("KZ enter: body=", body.name, " monitoring=", kill_zone.monitoring)

	if body.is_in_group("player") and (state == TrapState.DROPPING or state == TrapState.HOLDING):
		if body.has_method("die"):
			body.die()
			player_hit.emit(trap_id)


# =============== API para Trap Master / TrapManager =================
func force_activate() -> void:
	# Solo el server inicia
	if NetworkManager.is_multiplayer_active() and not multiplayer.is_server():
		return
	_try_start_cycle_server()

# =============== Lógica server-authoritative ========================
func _try_start_cycle_server() -> void:
	if busy or state == TrapState.DISABLED:
		return
	if NetworkManager.is_multiplayer_active() and not multiplayer.is_server():
		return
	_start_cycle_server()

func _start_cycle_server() -> void:
	busy = true
	trap_activated.emit(trap_id)

	# 1) DROPPING
	state = TrapState.DROPPING
	_set_kill_enabled(true)
	_update_visual()
	await _tween_y(original_y + drop_distance, drop_time, Tween.TRANS_QUAD, Tween.EASE_IN)

	# 2) HOLDING
	state = TrapState.HOLDING
	_set_kill_enabled(true)
	_update_visual()
	await get_tree().create_timer(hold_time).timeout

	# 3) RAISING
	state = TrapState.RAISING
	_set_kill_enabled(true)
	_update_visual()
	await _tween_y(original_y, rise_time, Tween.TRANS_SINE, Tween.EASE_OUT)

	trap_deactivated.emit(trap_id)

	# 4) COOLDOWN
	state = TrapState.COOLDOWN
	_update_visual()
	await get_tree().create_timer(cooldown_time).timeout

	state = TrapState.INACTIVE
	_update_visual()
	busy = false

func _tween_y(target_y: float, t: float, trans := Tween.TRANS_SINE, ease := Tween.EASE_IN_OUT) -> void:
	var tw := create_tween().set_trans(trans).set_ease(ease)
	tw.tween_property(self, "global_position:y", target_y, max(t, 0.0))
	await tw.finished
	# sync de posición y estado a clientes
	if NetworkManager.is_multiplayer_active() and multiplayer.is_server():
		rpc("sync_state", int(state), global_position.y)

# =============== Sync clientes ========================
@rpc("authority", "reliable", "call_remote")
func sync_state(state_i: int, y_now: float) -> void:
	if multiplayer.is_server():
		return
	state = state_i as TrapState
	global_position.y = y_now
	_update_visual()

# =============== Utilidades ===========================
func _set_kill_enabled(enabled: bool) -> void:
	var col := kill_zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.disabled = not enabled
	kill_zone.monitoring = enabled
	kill_zone.monitorable = true


func _update_visual() -> void:
	match state:
		TrapState.INACTIVE:
			if sprite: sprite.modulate = Color(0.6, 0.6, 0.6)
		TrapState.DROPPING, TrapState.HOLDING:
			if sprite: sprite.modulate = Color(1.0, 0.2, 0.2)
		TrapState.RAISING:
			if sprite: sprite.modulate = Color(0.2, 0.6, 1.0)
		TrapState.COOLDOWN:
			if sprite: sprite.modulate = Color(0.6, 0.6, 1.0)

# Debug opcional:
# func _unhandled_input(e): if e.is_action_pressed("ui_accept"): force_activate()
