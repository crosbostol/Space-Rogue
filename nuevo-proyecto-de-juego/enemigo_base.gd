extends Area2D

## Señal emitida al morir el enemigo.
signal enemigo_muerto(posicion_global: Vector2)

## Salud actual del enemigo. Se destruye al llegar a cero.
@export var vida: float = 20.0

## Velocidad de movimiento del enemigo en píxeles por segundo.
@export var velocidad: float = 320.0

## Daño que inflige al colisionar con el Player.
@export var dano_impacto: float = 20.0

## Script que implementa la estrategia de movimiento (debe poseer el método estático `obtener_direccion`).
@export var comportamiento_trayectoria: Script = null

## Tipo de enemigo para polimorfismo dinámico ("kamikaze", "tanque", "rango").
@export var tipo_enemigo: String = "kamikaze"

## Cadencia de disparo para el enemigo de Rango en segundos
@export var cadencia_disparo_enemigo: float = 1.8
var tiempo_ultimo_disparo: float = 0.0

func _ready() -> void:
	# Configurar el aspecto visual y estadísticas según el tipo de enemigo
	configurar_visual_por_tipo()
	
	# Inicializar la barra de salud de depuración si existe en la escena
	var health_bar = get_node_or_null("HealthBarDebug")
	if health_bar and health_bar is ProgressBar:
		health_bar.max_value = vida
		health_bar.value = vida

## Configura la geometría visual del Line2D y ajusta las estadísticas físicas por tipo de enemigo
func configurar_visual_por_tipo() -> void:
	var visual = get_node_or_null("Visual")
	if not visual or not visual is Line2D:
		return
		
	match tipo_enemigo:
		"kamikaze":
			vida = 20.0
			visual.points = PackedVector2Array([
				Vector2(0, -12),
				Vector2(10, 10),
				Vector2(0, 4),
				Vector2(-10, 10),
				Vector2(0, -12)
			])
			visual.default_color = Color(1.0, 0.2, 0.3)
			visual.width = 2.0
		"tanque":
			vida = 100.0
			velocidad = velocidad * 0.5
			visual.width = 4.5
			visual.default_color = Color(0.2, 1.0, 0.2)
			
			# Hexágono Neón Masivo
			var vertices: Array[Vector2] = []
			var radio: float = 16.0
			for i in range(6):
				var angulo: float = i * (TAU / 6.0) - PI/2.0
				vertices.append(Vector2(cos(angulo), sin(angulo)) * radio)
			vertices.append(vertices[0])
			visual.points = PackedVector2Array(vertices)
		"rango":
			vida = 25.0
			velocidad = velocidad * 0.8
			visual.width = 2.0
			visual.default_color = Color(0.0, 1.0, 1.0)
			
			# Rombo Estilizado / Antena
			var vertices: Array[Vector2] = [
				Vector2(0, -18),
				Vector2(8, 0),
				Vector2(0, 12),
				Vector2(-8, 0),
				Vector2(0, -18)
			]
			visual.points = PackedVector2Array(vertices)


## Aplica daño al enemigo restando de su vida. Se auto-destruye si la vida llega a cero.
func recibir_dano(cantidad: float) -> void:
	# Seguro de concurrencia para evitar doble muerte en el mismo frame
	if vida <= 0.0:
		return
		
	vida -= cantidad
	
	# Actualizar la barra de salud de depuración
	var health_bar = get_node_or_null("HealthBarDebug")
	if health_bar and health_bar is ProgressBar:
		health_bar.value = vida

	if vida <= 0.0:
		# Emitir señal de muerte formal para futuras recompensas/loot
		enemigo_muerto.emit(global_position)
		
		# Desactivar colisiones mediante llamadas diferidas seguras para evitar impactos fantasma
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		queue_free()

func _physics_process(delta: float) -> void:
	if comportamiento_trayectoria:
		var direccion: Vector2 = Vector2.ZERO
		if comportamiento_trayectoria.has_method("obtener_direccion"):
			direccion = comportamiento_trayectoria.obtener_direccion(global_position, self)
		
		# Avanzar hacia la dirección calculada por la estrategia de movimiento
		position += direccion * velocidad * delta
		
	# Lógica de ataque a distancia para el enemigo de Rango
	if tipo_enemigo == "rango":
		tiempo_ultimo_disparo += delta
		if tiempo_ultimo_disparo >= cadencia_disparo_enemigo:
			tiempo_ultimo_disparo = 0.0
			disparar_al_player()

## Instancia y dispara una bala hacia el jugador con estética Neón Cian
func disparar_al_player() -> void:
	var player = get_node_or_null("/root/Main/World/Player")
	if player and player is Node2D:
		var dir: Vector2 = global_position.direction_to(player.global_position)
		var bala_escena = preload("res://Bala.tscn")
		if bala_escena:
			var nueva_bala = bala_escena.instantiate()
			nueva_bala.direccion = dir
			nueva_bala.es_bala_enemiga = true
			nueva_bala.dano_impacto = dano_impacto
			
			# Pintar la bala enemiga de color cian neón para que el jugador la distinga!
			var visual_bala = nueva_bala.get_node_or_null("Visual")
			if visual_bala and visual_bala is Line2D:
				visual_bala.default_color = Color(0.0, 1.0, 1.0) # Cian Neón
			
			# Compensar posición de salida
			nueva_bala.global_position = global_position + dir * 16.0
			
			var proyectiles_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
			if proyectiles_container:
				proyectiles_container.add_child(nueva_bala)
