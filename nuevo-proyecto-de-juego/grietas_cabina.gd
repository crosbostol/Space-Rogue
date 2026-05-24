extends Node2D

# Array fuertemente tipado de líneas de fractura vectoriales
var lineas_fractura: Array[PackedVector2Array] = []

func _ready() -> void:
	var mat = ShaderMaterial.new()
	mat.shader = load("res://parabrisas_roto.gdshader")
	material = mat

func _process(_delta: float) -> void:
	# Seguir la posición de la cámara para que el parabrisas se mueva con ella y quede fijo en la pantalla
	var camera = get_viewport().get_camera_2d()
	if camera:
		global_position = camera.get_screen_center_position() - get_viewport_rect().size / 2.0

## Genera procedimentalmente una nueva estructura de grieta desde los bordes hacia el centro (adaptativo a la resolución de pantalla)
func registrar_impacto_vidrio(factor_dano: float, porcentaje_salud: float) -> void:
	# Obtener dinámicamente la resolución actual del Viewport para respuesta responsiva
	var tamano_pantalla: Vector2 = get_viewport_rect().size
	var centro_pantalla: Vector2 = tamano_pantalla / 2.0
	
	var punto_inicio: Vector2 = _obtener_punto_borde(tamano_pantalla)
	var dir_hacia_centro: Vector2 = punto_inicio.direction_to(centro_pantalla)
	
	# Calcular la agonía del jugador (a menor salud, más largo es el quiebre hacia el centro)
	var factor_agonica: float = 1.0 - porcentaje_salud
	var multiplicador_largo: float = lerp(1.0, 3.5, factor_agonica)
	
	# Escalar la agresividad y longitud del agrietamiento proporcionalmente al factor_dano
	var mult_escala: float = clamp(factor_dano * 10.0, 0.4, 3.0)
	
	# Generar un rango estricto de 2 a 3 líneas principales por impacto (limpio y inorgánico)
	var num_ramas: int = randi_range(2, 3)
	
	for r in range(num_ramas):
		var puntos_rama: Array[Vector2] = [punto_inicio]
		var punto_actual: Vector2 = punto_inicio
		
		# Trayectoria base apuntando hacia la zona general del centro
		var dir_rama: Vector2 = dir_hacia_centro.rotated(randf_range(-PI / 12.0, PI / 12.0))
		
		# Cada línea principal tendrá un máximo estricto de 3 segmentos continuos (zigzag rígido inorgánico)
		var num_segmentos: int = 3
		for s in range(num_segmentos):
			# La longitud base del tramo escala con el viewport, el daño y la agonía acumulada
			var longitud: float = randf_range(tamano_pantalla.y * 0.02, tamano_pantalla.y * 0.04) * mult_escala * multiplicador_largo
			
			# Desviaciones bruscas tipo zigzag (usa solo ángulos secos aleatorios de entre 30 y 45 grados)
			var signo: float = 1.0 if randf() < 0.5 else -1.0
			var desvio_angulo: float = signo * randf_range(deg_to_rad(30.0), deg_to_rad(45.0))
			var dir_segmento: Vector2 = dir_rama.rotated(desvio_angulo)
			
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

## Dibuja vectorialmente cada grieta en pantalla utilizando mapa de refracción para el shader
func _draw() -> void:
	# Recorrer las grietas almacenadas
	for rama in lineas_fractura:
		if rama.size() > 1:
			# R y G controlan la dirección de la refracción en la GPU, B controla el brillo neón del cristal (1.0), A le da la presencia visual necesaria (0.4)
			var color_deformacion_brillante = Color(0.75, 0.25, 1.0, 0.4)
			draw_polyline(rama, color_deformacion_brillante, 1.5, true)

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
