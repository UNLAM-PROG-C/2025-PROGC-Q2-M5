extends Node

# --- tu config actual ---
@export var victory_ui_scene: PackedScene = null  # (ya no lo usamos en single)

var game_mode: String = "single"
var total_deaths: int = 0
var total_games: int = 0

# --- stats de la run actual ---
var level_running: bool = false
var level_started_at: float = 0.0
var run_deaths: int = 0

# --- stats de la última victoria (para que WinMenu las lea) ---
var last_run_time: float = 0.0
var last_run_deaths: int = 0

func _ready() -> void:
	print("GameManager iniciado")

func start_level_stats() -> void:
	level_started_at = Time.get_ticks_msec() * 0.001
	run_deaths = 0
	level_running = true

func register_death() -> void:
	total_deaths += 1
	if level_running:
		run_deaths += 1

func get_elapsed_time() -> float:
	return max(0.0, (Time.get_ticks_msec() * 0.001) - level_started_at)

# === NUEVO: terminar nivel cambiando de escena al WinMenu ===
func finish_level() -> void:
	if not level_running:
		return
	level_running = false

	# Guardar stats para que el WinMenu las lea
	last_run_time = get_elapsed_time()
	last_run_deaths = run_deaths

	var tree := get_tree()
	if tree == null:
		push_error("SceneTree es null: no puedo cambiar al WinMenu.")
		return

	# Cambiar de escena (tu ruta)
	tree.change_scene_to_file("res://scenes/WinMenu.tscn")
