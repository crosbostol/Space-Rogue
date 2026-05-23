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

func _ready() -> void:
	# Inicializar la interfaz del HUD al arrancar la partida
	_actualizar_hud()

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
