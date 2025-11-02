extends Node2D

@onready var player = $player
@onready var trap_master = $TrapMaster

func _ready():
	setup_multiplayer()

func setup_multiplayer():
	"""Configura el nivel según el modo de juego"""
	
	if not GameManager.is_multiplayer_online():
		# Modo local o single player - todo funciona normal
		return
	
	# Modo multijugador online
	if multiplayer.is_server():
		# HOST: Controla al jugador (Runner)
		print("Nivel: Configurado como HOST (Runner)")
		
		# Desactivar el TrapMaster local si existe
		if trap_master:
			trap_master.queue_free()
		
		# El player funciona normalmente
		
	else:
		# CLIENT: Es el Trap Master
		print("Nivel: Configurado como CLIENT (Trap Master)")
		
		# Desactivar el control del jugador
		if player:
			# El jugador existe visualmente pero no se controla
			player.set_physics_process(false)
			# Opcional: hacer el jugador semi-transparente para indicar que no es local
			# player.modulate = Color(1, 1, 1, 0.7)
		
		# El TrapMaster funciona normalmente
