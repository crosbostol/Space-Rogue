extends Node

## Escena del enemigo a instanciar.
@export var enemigo_escena: PackedScene = preload("res://EnemigoBase.tscn")

## Intervalo de tiempo en segundos entre cada oleada/generación de enemigos.
@export var tiempo_spawn: float = 1.0

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

func seleccionar_tipo_por_tiempo(tiempo: float) -> Enums.TipoEnemigo:
	var rand: float = randf()
	
	if tiempo < 20.0:
		# Fase 1: Solo Kamikazes para calentamiento (0s - 20s)
		return Enums.TipoEnemigo.KAMIKAZE
	elif tiempo < 50.0:
		# Fase 2: Introducir enemigos de Rango (25% probabilidad) (20s - 50s)
		if rand < 0.75:
			return Enums.TipoEnemigo.KAMIKAZE
		else:
			return Enums.TipoEnemigo.RANGO
	elif tiempo < 90.0:
		# Fase 3: Introducir Tanques pesados (10%) y Rangos (30%) (50s - 90s)
		if rand < 0.60:
			return Enums.TipoEnemigo.KAMIKAZE
		elif rand < 0.90:
			return Enums.TipoEnemigo.RANGO
		else:
			return Enums.TipoEnemigo.TANQUE
	else:
		# Fase 4: Caos Total de final de partida (40% Kamikaze, 40% Rango, 20% Tanque) (90s+)
		if rand < 0.40:
			return Enums.TipoEnemigo.KAMIKAZE
		elif rand < 0.80:
			return Enums.TipoEnemigo.RANGO
		else:
			return Enums.TipoEnemigo.TANQUE

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
		# Obtener síncronamente el tiempo transcurrido de la run
		var run_manager = get_node_or_null("/root/Main/Managers/RunManager")
		var tiempo: float = 0.0
		if run_manager and "tiempo_transcurrido" in run_manager:
			tiempo = run_manager.tiempo_transcurrido
			
		# Seleccionar el tipo de enemigo según la progresión del tiempo
		var tipo_actual: Enums.TipoEnemigo = seleccionar_tipo_por_tiempo(tiempo)
		
		# Inyectar el tipo de enemigo de forma explícita mapeándolo al Enum de la clase (Polimorfismo síncrono)
		if "tipo_enemigo" in nuevo_enemigo:
			nuevo_enemigo.tipo_enemigo = tipo_actual
		
		# Ejecutar la configuración visual inmediatamente después de la asignación numérica
		if nuevo_enemigo.has_method("configurar_visual_por_tipo"):
			nuevo_enemigo.configurar_visual_por_tipo()
		
		# PRIORITARIO: Inyectar la estrategia de movimiento inmediatamente tras instanciarse para blindar la física inicial
		var script_movimiento: Script = null
		match tipo_actual:
			Enums.TipoEnemigo.RANGO:
				script_movimiento = preload("res://path_rango.gd")
			_:
				script_movimiento = preload("res://path_kamikaze.gd")
			
		if "comportamiento_trayectoria" in nuevo_enemigo:
			nuevo_enemigo.comportamiento_trayectoria = script_movimiento
			
		# Posicionar al enemigo
		nuevo_enemigo.global_position = posicion_spawn




		
		# Conectar la señal de muerte formal para gestionar loot/XP e interfaz
		if nuevo_enemigo.has_signal("enemigo_muerto"):
			nuevo_enemigo.enemigo_muerto.connect(_on_enemigo_muerto)
		
		# Inyectar el nuevo enemigo como hijo del contenedor global EnemiesContainer
		var enemies_container: Node = get_node_or_null("/root/Main/World/EnemiesContainer")
		if enemies_container:
			enemies_container.add_child(nuevo_enemigo)

func _on_enemigo_muerto(posicion: Vector2, puntos_xp: int) -> void:
	muertes += 1
	
	# Mapeo síncrono y elástico de puntos de XP al Enum global de rareza del orbe
	var tipo_orb_seleccionado: Enums.TipoOrb = Enums.TipoOrb.CHICO
	if puntos_xp == 50:
		tipo_orb_seleccionado = Enums.TipoOrb.GRANDE
	else:
		tipo_orb_seleccionado = Enums.TipoOrb.CHICO
		
	print("SpawnManager: Enemigo muerto en ", posicion, ". Otorgando ", puntos_xp, " XP.")
	
	# Actualizar el KillsCounter HUD
	var kills_counter = get_node_or_null("/root/Main/UI/HUD/KillsCounter")
	if kills_counter and kills_counter is Label:
		kills_counter.text = "Enemigos Eliminados: " + str(muertes)

	# Instanciar el orbe de XP en la posición del fallecimiento del enemigo
	var xp_orb_scene = preload("res://XpOrb.tscn")
	if xp_orb_scene:
		var nuevo_orbe = xp_orb_scene.instantiate()
		if nuevo_orbe is Node2D:
			# Inyectar síncronamente los parámetros económicos y visuales
			if "valor_xp" in nuevo_orbe:
				nuevo_orbe.valor_xp = puntos_xp
			if "tipo_orbe" in nuevo_orbe:
				nuevo_orbe.tipo_orbe = tipo_orb_seleccionado
				
			nuevo_orbe.global_position = posicion
			
			# Inyectar el orbe en el contenedor global de forma diferida para evitar conflictos con el Physics Server
			var projectiles_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
			if projectiles_container:
				projectiles_container.call_deferred("add_child", nuevo_orbe)
