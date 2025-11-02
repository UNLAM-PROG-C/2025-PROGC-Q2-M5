extends Node

# Sistema de gestión centralizada de trampas
# Demuestra: COMUNICACIÓN entre objetos y CONCURRENCIA en la gestión de múltiples trampas

# Diccionario para trackear todas las trampas registradas
# Key: trap_id, Value: referencia al nodo de la trampa
var registered_traps: Dictionary = {}

# Estadísticas del juego (CONCURRENCIA - múltiples trampas actualizando datos)
var stats = {
	"total_traps": 0,
	"active_traps": 0,
	"total_activations": 0,
	"total_hits": 0
}

# Señales para comunicación con otros sistemas
signal trap_registered(trap_id, trap_node)
signal all_traps_registered(count)
signal trap_state_changed(trap_id, state_name)
signal player_hit_trap(trap_id)

func _ready():
	# Esperar un frame para que todas las trampas se creen
	await get_tree().process_frame
	
	# Registrar todas las trampas existentes en el nivel
	register_all_traps()

func register_all_traps():
	"""Encuentra y registra todas las trampas del nivel"""
	var traps = get_tree().get_nodes_in_group("traps")
	
	for trap in traps:
		register_trap(trap)
	
	stats.total_traps = registered_traps.size()
	all_traps_registered.emit(stats.total_traps)
	
	print("TrapManager: Registradas %d trampas" % stats.total_traps)

func register_trap(trap_node):
	"""Registra una trampa y conecta sus señales (COMUNICACIÓN)"""
	if not trap_node.has_method("get_state_name"):
		return  # No es una trampa válida
	
	var trap_id = trap_node.trap_id
	
	if trap_id in registered_traps:
		print("TrapManager: Advertencia - Trampa ID %d ya registrada" % trap_id)
		return
	
	# Guardar referencia
	registered_traps[trap_id] = trap_node
	
	# Conectar señales de la trampa (COMUNICACIÓN entre objetos)
	if not trap_node.trap_activated.is_connected(_on_trap_activated):
		trap_node.trap_activated.connect(_on_trap_activated)
	
	if not trap_node.trap_deactivated.is_connected(_on_trap_deactivated):
		trap_node.trap_deactivated.connect(_on_trap_deactivated)
	
	if not trap_node.player_hit.is_connected(_on_player_hit):
		trap_node.player_hit.connect(_on_player_hit)
	
	trap_registered.emit(trap_id, trap_node)

func _on_trap_activated(trap_id):
	"""Callback cuando una trampa se activa"""
	stats.active_traps += 1
	stats.total_activations += 1
	
	var trap = get_trap(trap_id)
	if trap:
		var state = trap.get_state_name()
		trap_state_changed.emit(trap_id, state)
		print("Trampa %d ACTIVADA (Total activas: %d)" % [trap_id, stats.active_traps])

func _on_trap_deactivated(trap_id):
	"""Callback cuando una trampa se desactiva"""
	stats.active_traps = max(0, stats.active_traps - 1)
	
	var trap = get_trap(trap_id)
	if trap:
		var state = trap.get_state_name()
		trap_state_changed.emit(trap_id, state)
		print("Trampa %d DESACTIVADA (Total activas: %d)" % [trap_id, stats.active_traps])

func _on_player_hit(trap_id):
	"""Callback cuando una trampa golpea al jugador"""
	stats.total_hits += 1
	player_hit_trap.emit(trap_id)
	print("¡Jugador golpeado por trampa %d! (Total hits: %d)" % [trap_id, stats.total_hits])

# === API Pública para el Trap Master ===

func activate_trap(trap_id: int) -> bool:
	"""Activa manualmente una trampa específica (usado por Trap Master)"""
	var trap = get_trap(trap_id)
	
	if trap and trap.has_method("force_activate"):
		trap.force_activate()
		return true
	
	return false

func get_trap(trap_id: int):
	"""Obtiene la referencia a una trampa por su ID"""
	return registered_traps.get(trap_id, null)

func get_all_trap_ids() -> Array:
	"""Retorna array con todos los IDs de trampas registradas"""
	return registered_traps.keys()

func get_trap_state(trap_id: int) -> String:
	"""Obtiene el estado actual de una trampa"""
	var trap = get_trap(trap_id)
	if trap and trap.has_method("get_state_name"):
		return trap.get_state_name()
	return "Desconocido"

func get_available_traps() -> Array:
	"""Retorna array de IDs de trampas que están inactivas (pueden activarse)"""
	var available = []
	
	for trap_id in registered_traps:
		var trap = registered_traps[trap_id]
		if trap.current_state == 0:  # TrapState.INACTIVE = 0
			available.append(trap_id)
	
	return available

func get_stats() -> Dictionary:
	"""Retorna las estadísticas actuales"""
	return stats.duplicate()

func print_status():
	"""Debug: imprime el estado de todas las trampas"""
	print("\n=== TRAP MANAGER STATUS ===")
	print("Total trampas: %d" % stats.total_traps)
	print("Trampas activas: %d" % stats.active_traps)
	print("Total activaciones: %d" % stats.total_activations)
	print("Total hits: %d" % stats.total_hits)
	print("\nEstado individual:")
	
	for trap_id in registered_traps:
		var trap = registered_traps[trap_id]
		print("  Trampa %d: %s" % [trap_id, trap.get_state_name()])
	
	print("===========================\n")

# Debug: presiona F12 para ver el estado
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		print_status()
