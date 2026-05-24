extends Node2D

# Array fuertemente tipado de líneas de fractura vectoriales
var lineas_fractura: Array[PackedVector2Array] = []

## Genera procedimentalmente una nueva estructura de grieta desde los bordes hacia el centro (adaptativo a la resolución de pantalla)
func registrar_impacto_vidrio(factor_dano: float, porcentaje_salud: float) -> void:
	# Obtener dinámicamente la resolución actual del Viewport para respuesta responsiva
	var tamano_pantalla: Vector2 = get_viewport_rect().size
	var centro_pantalla: Vector2 = tamano_pantalla / 2.0
	
	var punto_inicio: Vector2 = _obtener_punto_borde(tamano_pantalla)
	var dir_hacia_centro: Vector2 = punto_inicio.direction_to(centro_pantalla)
	
	# Calcular la agonía del jugador (a menor salud, más largo es el quiebre hacia el centro)
	var factor_agonica: float = 1.0 - porcentaje_salud
	var multiplicador_largo: float = lerp(1.0, 4.5, factor_agonica)
	
	# Escalar la agresividad y longitud del agrietamiento proporcionalmente al factor_dano
	var mult_escala: float = clamp(factor_dano * 10.0, 0.4, 3.0)
	
	# Generar de 2 a 4 ramificaciones (escalado sutilmente por el daño)
	var base_ramas: int = randi_range(2, 4)
	var num_ramas: int = clamp(int(base_ramas * clamp(mult_escala, 0.5, 1.5)), 1, 6)
	
	for r in range(num_ramas):
		var puntos_rama: Array[Vector2] = [punto_inicio]
		var punto_actual: Vector2 = punto_inicio
		
		# Ángulo principal de la rama con una desviación aleatoria
		var dir_rama: Vector2 = dir_hacia_centro.rotated(randf_range(-PI / 6.0, PI / 6.0))
		
		# Cada rama posee de 2 a 4 segmentos continuos
		var num_segmentos: int = randi_range(2, 4)
		for s in range(num_segmentos):
			# La longitud escala con el viewport, el daño del impacto, y la agonía acumulada
			var longitud: float = randf_range(tamano_pantalla.y * 0.03, tamano_pantalla.y * 0.06) * mult_escala * multiplicador_largo
			
			# Desviación sutil en cada tramo para simular astillado fractal orgánico
			var dir_segmento: Vector2 = dir_rama.rotated(randf_range(-PI / 12.0, PI / 12.0))
			punto_actual = punto_actual + dir_segmento * longitud
			puntos_rama.append(punto_actual)
			
		lineas_fractura.append(PackedVector2Array(puntos_rama))
		
	queue_redraw()

## Método de compatibilidad para disparar grietas básicas sin factor de daño explícito
func generar_grieta() -> void:
	registrar_impacto_vidrio(0.1, 1.0)

## Limpia todas las grietas (autoreparación de nanobots)
func limpiar_grietas() -> void:
	lineas_fractura.clear()
	queue_redraw()

## Dibuja vectorialmente cada grieta en pantalla con opacidad sutil translúcida
func _draw() -> void:
	var color_cristal: Color = Color(0.8, 0.9, 1.0, 0.35) # Blanco/cian translúcido sutil para visibilidad del gameplay
	for rama in lineas_fractura:
		if rama.size() > 1:
			draw_polyline(rama, color_cristal, 1.25, true)

## Calcula un punto de inicio pseudoaleatorio sobre los bordes dinámicos de la pantalla
func _obtener_punto_borde(limites: Vector2) -> Vector2:
	var lado: int = randi() % 4
	match lado:
		0: # Borde Superior
			return Vector2(randf_range(0.0, limites.x), 0.0)
		1: # Borde Inferior
			return Vector2(randf_range(0.0, limites.x), limites.y)
		2: # Borde Izquierdo
			return Vector2(0.0, randf_range(0.0, limites.y))
		_: # Borde Derecho
			return Vector2(limites.x, randf_range(0.0, limites.y))
