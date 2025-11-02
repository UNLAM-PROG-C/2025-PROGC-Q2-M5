extends Node

# Singleton para gestionar el estado global del juego

# Modo de juego actual
var game_mode: String = "single"  # "single" o "multiplayer"

# Estadísticas globales
var total_deaths: int = 0
var total_games: int = 0

func _ready():
	print("GameManager iniciado")

func is_multiplayer() -> bool:
	"""Retorna true si el modo es multijugador"""
	return game_mode == "multiplayer"

func is_single_player() -> bool:
	"""Retorna true si el modo es un jugador"""
	return game_mode == "single"

func reset_stats():
	"""Reinicia las estadísticas"""
	total_deaths = 0
	total_games = 0

func register_death():
	"""Registra una muerte del jugador"""
	total_deaths += 1

func start_new_game():
	"""Inicia un nuevo juego"""
	total_games += 1
	print("Nuevo juego iniciado - Modo: %s" % game_mode)
