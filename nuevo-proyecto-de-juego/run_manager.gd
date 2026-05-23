extends Node

## Señal emitida al subir de nivel en la run.
signal nivel_subido(nuevo_nivel: int)


## Nivel actual alcanzado por el jugador en la run.
var nivel_actual: int = 1

## Experiencia acumulada en el nivel actual.
var xp_actual: float = 0.0

## Experiencia requerida para subir al siguiente nivel.
var xp_requerida: float = 35.0

## Experiencia base inicial necesaria para nivel 2.
const XP_BASE: float = 35.0

## Exponente que rige el crecimiento exponencial de la curva de XP.
const EXPONENTE_CURVA: float = 1.2

## Cronómetro de la partida en segundos.
var tiempo_transcurrido: float = 0.0

## Instancia dinámica del Label del cronómetro en el HUD.
var label_tiempo: Label = null

func _ready() -> void:
	# Inicializar la interfaz del HUD al arrancar la partida
	_actualizar_hud()
	
	# Crear dinámicamente el cronómetro para el HUD (Seguridad UI/UX y modularidad)
	_crear_cronometro_dinamico()

func _process(delta: float) -> void:
	# El cronómetro corre síncronamente con la simulación del juego (escala a 0 en menús/pausa)
	tiempo_transcurrido += delta
	_actualizar_cronometro_ui()

## Configura e inyecta dinámicamente el Label del cronómetro con crecimiento elástico en la esquina superior derecha
func _crear_cronometro_dinamico() -> void:
	var hud = get_node_or_null("/root/Main/UI/HUD")
	if not hud:
		print("RunManager: ADVERTENCIA - No se pudo encontrar el nodo HUD en /root/Main/UI/HUD.")
		return
		
	label_tiempo = Label.new()
	label_tiempo.name = "TimeCounter"
	
	# Anclar a la esquina superior derecha
	label_tiempo.anchor_left = 1.0
	label_tiempo.anchor_top = 0.0
	label_tiempo.anchor_right = 1.0
	label_tiempo.anchor_bottom = 0.0
	
	# REDIRECCIÓN ELÁSTICA: El texto crece hacia la izquierda para evitar desbordes en pantalla completa
	label_tiempo.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	# Configurar offsets de posición e interpolación elástica
	label_tiempo.offset_left = -220
	label_tiempo.offset_top = 20
	label_tiempo.offset_right = -20
	label_tiempo.offset_bottom = 50
	
	# Formato estético y Cyberpunk
	label_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_tiempo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_tiempo.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0)) # Cian Neón
	label_tiempo.add_theme_font_size_override("font_size", 22)
	
	# Agregar al HUD de manera formal
	hud.add_child(label_tiempo)
	_actualizar_cronometro_ui()
	print("RunManager: Cronómetro dinámico Neón inyectado exitosamente en el HUD.")

## Formatea el tiempo transcurrido a MM:SS y actualiza el texto del Label
func _actualizar_cronometro_ui() -> void:
	if label_tiempo:
		var minutos: int = int(tiempo_transcurrido) / 60
		var segundos: int = int(tiempo_transcurrido) % 60
		label_tiempo.text = "%02d:%02d" % [minutos, segundos]


## Acumula experiencia y procesa la subida de niveles.
func añadir_xp(cantidad: float) -> void:
	xp_actual += cantidad
	
	# Bucle síncrono para soportar múltiples subidas de nivel en el mismo frame
	# si el golpe de experiencia recibido es masivo (ej: derrotar a un boss)
	while xp_actual >= xp_requerida:
		subir_de_nivel()
		
	_actualizar_hud()

## Ejecuta la lógica matemática estricta para la subida de nivel.
func subir_de_nivel() -> void:
	# ORDEN ESTRICTO DE OPERACIÓN PARA EL ARRASTRE DE EXCEDENTES:
	# 1. Restar la meta anterior para preservar el sobrante de XP acumulada.
	xp_actual -= xp_requerida
	
	# 2. Incrementar el nivel de juego.
	nivel_actual += 1
	
	# 3. Recalcular la nueva meta requerida utilizando la curva exponencial de progresión.
	xp_requerida = XP_BASE * (pow(nivel_actual, EXPONENTE_CURVA))
	
	print("¡SUBIÓ DE NIVEL! Nuevo Nivel: ", nivel_actual, ". Próxima meta: ", xp_requerida, " XP.")
	
	# Emitir la señal de subida de nivel para pausar el juego y mostrar el menú
	nivel_subido.emit(nivel_actual)


## Sincroniza las propiedades del HUD con las variables internas del RunManager.
func _actualizar_hud() -> void:
	var xp_bar = get_node_or_null("/root/Main/UI/HUD/XpBar")
	if xp_bar and xp_bar is ProgressBar:
		xp_bar.max_value = xp_requerida
		xp_bar.value = xp_actual
