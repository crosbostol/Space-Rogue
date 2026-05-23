extends Area2D

const DAMAGE_NUMBER_SCENE = preload("res://DamageNumber.tscn")
const EXPLOSION_PARTICLES_SCENE = preload("res://ExplosionParticles.tscn")

## Señal emitida al morir el enemigo, enviando el tipo de enemigo de forma fuertemente tipada.
signal enemigo_muerto(posicion_global: Vector2, tipo_fallecido: Enums.TipoEnemigo)

## Salud actual del enemigo. Se destruye al llegar a cero.
@export var vida: float = 20.0

## Velocidad de movimiento del enemigo en píxeles por segundo.
@export var velocidad: float = 320.0

## Daño que inflige al colisionar con el Player.
@export var dano_impacto: float = 20.0

## Script que implementa la estrategia de movimiento (debe poseer el método estático `obtener_direccion`).
@export var comportamiento_trayectoria: Script = null

## Tipo de enemigo asignado mediante el Enum global (Aparecerá como lista desplegable en el Inspector)
@export var tipo_enemigo: Enums.TipoEnemigo = Enums.TipoEnemigo.KAMIKAZE

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
		Enums.TipoEnemigo.KAMIKAZE:
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
			
		Enums.TipoEnemigo.TANQUE:
			vida = 100.0
			velocidad = velocidad * 0.5
			visual.width = 4.5
			visual.default_color = Color(0.2, 1.0, 0.2)
			
			# Hexágono Neón Masivo
			var vertices: Array[Vector2] = []
			var radio: float = 16.0
			for i in range(6):
				var angulo: float = i * (TAU / 6.0) - PI / 2.0
				vertices.append(Vector2(cos(angulo), sin(angulo)) * radio)
			vertices.append(vertices[0])
			visual.points = PackedVector2Array(vertices)
			
		Enums.TipoEnemigo.RANGO:
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
	if vida <= 0.0:
		return
		
	var dmg_label = DAMAGE_NUMBER_SCENE.instantiate()
	dmg_label.dano_mostrar = cantidad
	dmg_label.global_position = global_position
	var proyectiles_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
	if proyectiles_container:
		proyectiles_container.add_child(dmg_label)
		
	vida -= cantidad
	
	var health_bar = get_node_or_null("HealthBarDebug")
	if health_bar and health_bar is ProgressBar:
		health_bar.value = vida

	if vida <= 0.0:
		enemigo_muerto.emit(global_position, tipo_enemigo)
		
		var explosion = EXPLOSION_PARTICLES_SCENE.instantiate()
		explosion.global_position = global_position
		var visual = get_node_or_null("Visual")
		if visual and visual is Line2D:
			explosion.color = visual.default_color
			explosion.modulate = visual.default_color
			
		var proj_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
		if proj_container:
			proj_container.add_child(explosion)
			
		# Hit Stun condicionado mediante evaluación numérica del Enum global
		if tipo_enemigo == Enums.TipoEnemigo.TANQUE:
			Engine.time_scale = 0.01
			get_tree().create_timer(0.1, true, false, true).timeout.connect(func():
				if Engine.time_scale == 0.01:
					Engine.time_scale = 1.0
			)
		
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		queue_free()

func _physics_process(delta: float) -> void:
	if comportamiento_trayectoria:
		var direccion: Vector2 = Vector2.ZERO
		if comportamiento_trayectoria.has_method("obtener_direccion"):
			direccion = comportamiento_trayectoria.obtener_direccion(global_position, self )
		
		position += direccion * velocidad * delta
		
	# Lógica condicional optimizada con Enum entero global
	if tipo_enemigo == Enums.TipoEnemigo.RANGO:
		tiempo_ultimo_disparo += delta
		if tiempo_ultimo_disparo >= cadencia_disparo_enemigo:
			tiempo_ultimo_disparo = 0.0
			disparar_al_player()

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
			
			var visual_bala = nueva_bala.get_node_or_null("Line2D")
			if visual_bala and visual_bala is Line2D:
				visual_bala.default_color = Color(0.0, 1.0, 1.0)
			
			nueva_bala.global_position = global_position + dir * 16.0
			
			var proyectiles_container = get_node_or_null("/root/Main/World/ProjectilesContainer")
			if proyectiles_container:
				proyectiles_container.add_child(nueva_bala)
