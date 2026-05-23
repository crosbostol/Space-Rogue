extends Node

## Escena del enemigo a instanciar.
@export var enemigo_escena: PackedScene = preload("res://EnemigoBase.tscn")

## Intervalo de tiempo en segundos entre cada oleada/generación de enemigos.
@export var tiempo_spawn: float = 1.5

## Contador interno de bajas/enemigos eliminados.
var muertes: int = 0

## Nodo Timer interno creado por código para gestionar los intervalos de spawn.
var _timer_spawn: Timer = null

func _ready() -> void:
	# Inicializar y configurar el Timer dinámicamente
	_timer_spawn = Timer.new()
	_timer_spawn.wait_time = tiempo_spawn
	_timer_spawn.autostart = true
	_timer_spawn.one_shot = false
	_timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	add_child(_timer_spawn)

## Calcula una posición de spawn a una distancia aleatoria y ángulo de 360 grados alrededor del Player.
func obtener_posicion_spawn_aleatoria(posicion_player: Vector2) -> Vector2:
	# Radio aleatorio fuera de la vista estándar (por ejemplo, entre 750 y 950 píxeles)
	var radio: float = randf_range(750.0, 950.0)
	var angulo: float = randf_range(0.0, TAU) # TAU representa 2 * PI (360 grados)
	var offset: Vector2 = Vector2(cos(angulo), sin(angulo)) * radio
	return posicion_player + offset

func _on_timer_spawn_timeout() -> void:
	# Búsqueda segura del nodo Player en el árbol de escenas
	var player: Node = get_node_or_null("/root/Main/World/Player")
	if not player or not player is Node2D:
		# Si el jugador no existe o no ha sido instanciado, abortamos el spawn para evitar un crash
		return
	
	if not enemigo_escena:
		return
		
	# Calcular la posición de spawn
	var posicion_spawn: Vector2 = obtener_posicion_spawn_aleatoria(player.global_position)
	
	# Instanciar el enemigo
	var nuevo_enemigo = enemigo_escena.instantiate()
	if nuevo_enemigo is Node2D:
		# Posicionar al enemigo
		nuevo_enemigo.global_position = posicion_spawn
		
		# Inyectar la estrategia Kamikaze asignando el script path_kamikaze.gd
		var script_kamikaze: Script = preload("res://path_kamikaze.gd")
		if "comportamiento_trayectoria" in nuevo_enemigo:
			nuevo_enemigo.comportamiento_trayectoria = script_kamikaze
		
		# Conectar la señal de muerte formal para gestionar loot/XP e interfaz
		if nuevo_enemigo.has_signal("enemigo_muerto"):
			nuevo_enemigo.enemigo_muerto.connect(_on_enemigo_muerto)
		
		# Inyectar el nuevo enemigo como hijo del contenedor global EnemiesContainer
		var enemies_container: Node = get_node_or_null("/root/Main/World/EnemiesContainer")
		if enemies_container:
			enemies_container.add_child(nuevo_enemigo)

func _on_enemigo_muerto(posicion: Vector2, valor_xp: int = 5) -> void:
	muertes += 1
	print("Enemigo murió en: ", posicion)
	
	# Actualizar el KillsCounter HUD
	var kills_counter = get_node_or_null("/root/Main/UI/HUD/KillsCounter")
	if kills_counter and kills_counter is Label:
		kills_counter.text = "Enemigos Eliminados: " + str(muertes)

	# Instanciar el orbe de XP en la posición del fallecimiento del enemigo
	var xp_orb_scene = preload("res://XpOrb.tscn")
	if xp_orb_scene:
		var nuevo_orbe = xp_orb_scene.instantiate()
		if nuevo_orbe is Node2D:
			# Inyectar el valor de experiencia (polimorfismo por tipo)
			if "valor_xp" in nuevo_orbe:
				nuevo_orbe.valor_xp = valor_xp
			nuevo_orbe.global_position = posicion
			
			# Inyectar el orbe en el contenedor global de forma diferida para evitar conflictos con el Physics Server (flushing queries)
			var projectiles_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
			if projectiles_container:
				projectiles_container.call_deferred("add_child", nuevo_orbe)
