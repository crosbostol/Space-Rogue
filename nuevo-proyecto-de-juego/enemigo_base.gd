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

func _ready() -> void:
	# Inicializar la barra de salud de depuración si existe en la escena
	var health_bar = get_node_or_null("HealthBarDebug")
	if health_bar and health_bar is ProgressBar:
		health_bar.max_value = vida
		health_bar.value = vida

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
