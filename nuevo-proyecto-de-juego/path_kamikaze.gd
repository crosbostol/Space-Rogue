class_name PathKamikaze
extends RefCounted

## Calcula el vector de dirección normalizado hacia el nodo Player.
## Si el Player no existe o no está en el árbol, retorna Vector2.ZERO.
static func obtener_direccion(posicion_actual: Vector2, nodo_referencia: Node) -> Vector2:
	if not nodo_referencia or not nodo_referencia.is_inside_tree():
		return Vector2.ZERO
	
	var player: Node = nodo_referencia.get_node_or_null("/root/Main/World/Player")
	if player and player is Node2D:
		return posicion_actual.direction_to(player.global_position)
	
	return Vector2.ZERO
