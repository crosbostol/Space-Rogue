extends Node2D

@export var cantidad_estrellas: int = 100
@export var tamano_max_estrella: float = 1.5
@export var color_base: Color = Color(1.0, 1.0, 1.0)
@export var velocidad_parpadeo: float = 2.0

# Pool interno de estrellas fuertemente tipado
var posiciones: Array[Vector2] = []
var desfases: Array[float] = []
var tamanos: Array[float] = []

# Dimensiones de la capa
const ANCHO_BASE: float = 1920.0
const ALTO_BASE: float = 1080.0

func _ready() -> void:
	# Generar posiciones aleatorias y desfases
	posiciones.resize(cantidad_estrellas)
	desfases.resize(cantidad_estrellas)
	tamanos.resize(cantidad_estrellas)
	
	for i in range(cantidad_estrellas):
		posiciones[i] = Vector2(
			randf_range(0.0, ANCHO_BASE),
			randf_range(0.0, ALTO_BASE)
		)
		desfases[i] = randf_range(0.0, PI * 2.0)
		tamanos[i] = randf_range(0.5, tamano_max_estrella)
		
	queue_redraw()

func _process(_delta: float) -> void:
	# Redibujar cada frame para el efecto de parpadeo de forma fluida
	queue_redraw()

func _draw() -> void:
	var tiempo: float = Time.get_ticks_msec() * 0.001
	for i in range(cantidad_estrellas):
		# Calcular opacidad con la función senoidal
		var valor_seno: float = sin(tiempo * velocidad_parpadeo + desfases[i])
		# Mapear valor para asegurar canal alfa válido entre [0.1, 1.0] para estética cósmica
		var alpha: float = clamp((valor_seno + 1.0) * 0.5, 0.1, 1.0)
		
		var color_estrella: Color = color_base
		color_estrella.a = alpha
		
		draw_circle(posiciones[i], tamanos[i], color_estrella)
