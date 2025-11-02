extends Control

# Referencias UI
@onready var btn_host = $VBoxContainer/BtnHost
@onready var btn_join = $VBoxContainer/BtnJoin
@onready var btn_back = $VBoxContainer/BtnBack
@onready var input_ip = $VBoxContainer/InputIP
@onready var label_status = $LabelStatus

func _ready():
	# Conectar botones
	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	
	# Conectar señales de NetworkManager
	NetworkManager.server_started.connect(_on_server_started)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_connected.connect(_on_player_connected)
	
	# IP por defecto
	input_ip.text = "127.0.0.1"
	label_status.text = "Esperando..."

func _on_host_pressed():
	"""Crear servidor (Host)"""
	label_status.text = "Creando servidor..."
	
	if NetworkManager.create_server():
		label_status.text = "Servidor creado. Esperando jugador..."
		btn_host.disabled = true
		btn_join.disabled = true
	else:
		label_status.text = "Error al crear servidor"

func _on_join_pressed():
	"""Unirse a servidor"""
	var ip = input_ip.text
	label_status.text = "Conectando a " + ip + "..."
	
	if NetworkManager.join_server(ip):
		btn_host.disabled = true
		btn_join.disabled = true
	else:
		label_status.text = "Error al conectar"

func _on_back_pressed():
	"""Volver al menú principal"""
	NetworkManager.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# === Callbacks de red ===
func _on_server_started():
	"""Servidor creado exitosamente"""
	label_status.text = "Servidor activo. Esperando jugador..."

func _on_connection_succeeded():
	"""Cliente conectado al servidor"""
	label_status.text = "Conectado! Iniciando juego..."
	await get_tree().create_timer(1.0).timeout
	start_game()

func _on_connection_failed():
	"""Falló la conexión"""
	label_status.text = "Error: No se pudo conectar"
	btn_host.disabled = false
	btn_join.disabled = false

func _on_player_connected():
	"""Otro jugador se conectó (solo host recibe esto)"""
	label_status.text = "Jugador conectado! Iniciando juego..."
	await get_tree().create_timer(1.0).timeout
	start_game()

func start_game():
	"""Iniciar el juego"""
	# Configurar el modo como multijugador online
	GameManager.game_mode = "multiplayer_online"
	
	# Cambiar a la escena del nivel
	get_tree().change_scene_to_file("res://scenes/levels/Level_01.tscn")
