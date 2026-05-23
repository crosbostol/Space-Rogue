extends Label

## Cantidad de daño a mostrar en pantalla
@export var dano_mostrar: float = 0.0

## Velocidad de arco horizontal aleatoria
var velocidad_x: float = 0.0

## Velocidad vertical inicial (simulando un salto/arco)
var velocidad_y: float = -120.0

## Gravedad simulada para el arco de caída
var gravedad: float = 240.0

func _ready() -> void:
	# Formatear el texto para mostrar solo enteros o un decimal limpio
	text = str(int(dano_mostrar))
	
	# Establecer un desplazamiento lateral aleatorio para simular rebotes elásticos
	velocidad_x = randf_range(-60.0, 60.0)
	
	# Configurar el color a Amarillo/Naranja Neón vibrante
	add_theme_color_override("font_color", Color(1.0, 0.6, 0.0)) # Naranja/Amarillo Neón
	add_theme_font_size_override("font_size", 20)
	
	# Asegurar que el centrado sea correcto desde su pivote
	pivot_offset = size / 2.0

func _process(delta: float) -> void:
	# 1. Aplicar velocidad y gravedad al arco
	velocidad_y += gravedad * delta
	position.x += velocidad_x * delta
	position.y += velocidad_y * delta
	
	# 2. Encogimiento paulatino de escala (elástica)
	scale = lerp(scale, Vector2.ZERO, 3.0 * delta)
	
	# 3. Desvanecimiento progresivo
	modulate.a -= 1.8 * delta
	
	# 4. Liberación segura de memoria
	if modulate.a <= 0.0 or scale.x <= 0.01:
		queue_free()
