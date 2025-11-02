extends Control

# Referencias a los botones
@onready var btn_single_player = $VBoxContainer/BtnSinglePlayer
@onready var btn_multiplayer = $VBoxContainer/BtnMultiplayer
@onready var btn_quit = $VBoxContainer/BtnQuit
@onready var title_label = $Title

# Variable global para el modo de juego
var game_mode: String = "single"  # "single" o "multiplayer"

func _ready():
	# Conectar señales de los botones
	btn_single_player.pressed.connect(_on_single_player_pressed)
	btn_multiplayer.pressed.connect(_on_multiplayer_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	print("Menú Principal cargado")

func _on_single_player_pressed():
	"""Inicia el juego en modo un jugador"""
	print("Modo: Un Jugador")
	game_mode = "single"
	
	# Guardar el modo de juego en una variable global/autoload
	GameManager.game_mode = "single"
	
	# Cambiar a la escena del nivel
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_multiplayer_pressed():
	"""Inicia el juego en modo multijugador"""
	print("Modo: Multijugador")
	game_mode = "multiplayer"
	
	# Guardar el modo de juego
	GameManager.game_mode = "multiplayer"
	
	# Cambiar a la escena del nivel
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_quit_pressed():
	"""Cierra el juego"""
	print("Saliendo del juego...")
	get_tree().quit()
