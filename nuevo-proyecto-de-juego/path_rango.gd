class_name PathRango
extends RefCounted

## Calcula el vector de dirección normalizado para enemigos de Rango.
## Mantiene una distancia óptima (órbita) respecto al Player para hostigarlo.
static func obtener_direccion(posicion_actual: Vector2, nodo_referencia: Node) -> Vector2:
	if not nodo_referencia or not nodo_referencia.is_inside_tree():
		return Vector2.ZERO
	
	var player: Node = nodo_referencia.get_node_or_null("/root/Main/World/Player")
	if player and player is Node2D:
		var distancia: float = posicion_actual.distance_to(player.global_position)
		var direccion_al_player: Vector2 = posicion_actual.direction_to(player.global_position)
		
		# Rango óptimo de disparo y seguridad (ej: 280px con margen de 40px)
		var distancia_ideal: float = 280.0
		var margen: float = 40.0
		
		if distancia > distancia_ideal + margen:
			# Muy lejos: Avanzar directamente hacia el jugador
			return direccion_al_player
		elif distancia < distancia_ideal - margen:
			# Muy cerca: Retroceder para mantener la distancia de seguridad
			return -direccion_al_player
		else:
			# Distancia dulce: Orbitar lateralmente para esquivar proyectiles
			# Rotación trigonométrica de 90 grados
			return Vector2(-direccion_al_player.y, direccion_al_player.x)
			
	return Vector2.ZERO
