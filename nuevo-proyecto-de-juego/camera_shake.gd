extends Camera2D

@export var trauma_decay: float = 0.8
@export var max_offset: Vector2 = Vector2(15.0, 15.0)

var trauma: float = 0.0

func _process(delta: float) -> void:
	if trauma > 0.0:
		# Reducir el trauma linealmente
		trauma = max(trauma - trauma_decay * delta, 0.0)
		
		# Si tras la reducción sigue habiendo trauma, calcular desplazamiento cuadrático pseudoaleatorio
		if trauma > 0.0:
			var shake: float = trauma * trauma
			offset.x = max_offset.x * shake * randf_range(-1.0, 1.0)
			offset.y = max_offset.y * shake * randf_range(-1.0, 1.0)
		else:
			# Limpieza absoluta cuando el trauma llega exactamente a cero
			offset = Vector2.ZERO

## Método público para inyectar trauma acumulativo (límite superior de 1.0)
func agregar_trauma(cantidad: float) -> void:
	trauma = min(trauma + cantidad, 1.0)
