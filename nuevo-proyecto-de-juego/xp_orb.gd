extends Area2D

## Valor de experiencia que otorga el orbe.
@export var valor_xp: int = 5

## Distancia máxima en píxeles a la que el orbe es atraído por el Player (como respaldo).
@export var rango_atraccion: float = 150.0

## Velocidad de partida del orbe cuando inicia la atracción.
@export var velocidad_inicial: float = 100.0

## Aceleración constante aplicada al orbe durante la atracción.
@export var aceleracion: float = 400.0

## Velocidad en tiempo real del orbe.
var velocidad_actual: float = 0.0

## Referencia al nodo del jugador.
var objetivo_player: Node2D = null

## Controla si el orbe se encuentra en modo de persecución activa.
var esta_atrayendo: bool = false

func _ready() -> void:
	# Buscar de forma segura al Player al instanciarse el orbe
	var player = get_node_or_null("/root/Main/World/Player")
	if player and player is Node2D:
		objetivo_player = player
		
	# Polimorfismo visual elástico y escalado de rareza según el valor de XP
	var visual = get_node_or_null("Visual")
	if visual and visual is Line2D:
		if valor_xp == 50:
			# Tanque: Recompensa legendaria masiva
			scale = Vector2(2.0, 2.0)
			visual.default_color = Color(1.0, 0.85, 0.0) # Amarillo / Dorado Neón Puro
			visual.width = 3.0 # Grosor de línea mayor
		elif valor_xp == 15:
			# Rango: Recompensa media a juego con la identidad del enemigo
			scale = Vector2(1.5, 1.5)
			visual.default_color = Color(0.0, 1.0, 1.0) # Cian Neón
			visual.width = 2.0
		else:
			# Kamikaze / Estándar: Orbe base cian
			scale = Vector2(1.0, 1.0)
			visual.default_color = Color(0.0, 0.8, 1.0) # Cian base
			visual.width = 1.5


func _physics_process(delta: float) -> void:
	# Búsqueda de seguridad por si el jugador resucita o es inyectado posteriormente
	if not is_instance_valid(objetivo_player) or not objetivo_player.is_inside_tree():
		var player = get_node_or_null("/root/Main/World/Player")
		if player and player is Node2D:
			objetivo_player = player
		else:
			return # No hay jugador activo, no procesamos física
	
	# Si no ha empezado la atracción, vigilamos la distancia consumiendo la propiedad dinámica del Player
	if not esta_atrayendo:
		var distancia: float = global_position.distance_to(objetivo_player.global_position)
		var rango_iman = objetivo_player.get("rango_iman_actual") if "rango_iman_actual" in objetivo_player else rango_atraccion
		if distancia < rango_iman:
			esta_atrayendo = true
			velocidad_actual = velocidad_inicial
	
	# Lógica activa del Imán
	if esta_atrayendo:
		var distancia: float = global_position.distance_to(objetivo_player.global_position)
		
		# MITIGACIÓN DE LA FLECHA DE ZENÓN:
		# Si el orbe está sumamente cerca del jugador, forzamos recolección inmediata y destruimos 
		# el nodo para evitar que entre en un bucle orbital infinito.
		if distancia < 15.0:
			if objetivo_player.has_method("recibir_xp"):
				objetivo_player.recibir_xp(valor_xp)
			else:
				print("Orbe XP recolectado. Puntos: ", valor_xp)
			queue_free()
			return
		
		# Dirección y movimiento acelerado
		var direccion: Vector2 = global_position.direction_to(objetivo_player.global_position)
		velocidad_actual += aceleracion * delta
		global_position += direccion * velocidad_actual * delta
