extends Node

# Configuración de red
const DEFAULT_PORT = 7777
const MAX_PLAYERS = 2

# Estado de la conexión
var peer = null
var is_host = false
var player_role = ""  # "runner" o "trap_master"

# Señales
signal player_connected(id)
signal player_disconnected(id)
signal connection_failed
signal connection_succeeded
signal server_started

func _ready():
	# Conectar señales de multijugador
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# === HOST: Crear servidor ===
func create_server(port = DEFAULT_PORT):
	"""Crea un servidor (Host)"""
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		print("Error al crear servidor: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	player_role = "runner"  # El host es el Runner
	
	print("Servidor creado en puerto: ", port)
	server_started.emit()
	return true

# === CLIENT: Conectar a servidor ===
func join_server(address = "127.0.0.1", port = DEFAULT_PORT):
	"""Conecta a un servidor existente"""
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		print("Error al conectar: ", error)
		connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	player_role = "trap_master"  # El cliente es el Trap Master
	
	print("Conectando a: ", address, ":", port)
	return true

# === Callbacks de red ===
func _on_player_connected(id):
	"""Cuando otro jugador se conecta"""
	print("Jugador conectado: ", id)
	player_connected.emit()

func _on_player_disconnected(id):
	"""Cuando otro jugador se desconecta"""
	print("Jugador desconectado: ", id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	"""Cliente: conexión exitosa al servidor"""
	print("Conectado al servidor!")
	connection_succeeded.emit()

func _on_connection_failed():
	"""Cliente: falló la conexión"""
	print("Falló la conexión al servidor")
	connection_failed.emit()

func _on_server_disconnected():
	"""Cliente: el servidor se desconectó"""
	print("Servidor desconectado")
	multiplayer.multiplayer_peer = null

# === Utilidades ===
func is_multiplayer_active():
	"""Verifica si hay una sesión multijugador activa"""
	return multiplayer.multiplayer_peer != null

func get_player_id():
	"""Retorna el ID único del jugador"""
	return multiplayer.get_unique_id()

func is_server():
	"""Verifica si este peer es el servidor"""
	return multiplayer.is_server()

func disconnect_from_game():
	"""Desconecta del juego multijugador"""
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	player_role = ""
