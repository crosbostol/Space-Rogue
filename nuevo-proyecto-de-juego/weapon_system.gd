extends Node2D

# 1. Cargamos el molde (la escena) de la bala en memoria
const BALA_ESCENA = preload("res://Bala.tscn")

@export var cadencia_disparo: float = 0.25 # Segundos entre disparos
var tiempo_ultimo_disparo: float = 0.0
var angulo_actual: float = 0.0

## Estado de disparo en Cruz de 4 proyectiles (mejora 'helice')
var disparo_en_cruz: bool = false

func _process(delta: float) -> void:
	# Actualizar el temporizador de la cadencia
	tiempo_ultimo_disparo += delta
	
	# 2. Capturar tu nuevo mapeo del Stick R / Flechas
	var direccion_apuntado: Vector2 = Input.get_vector("weapon_left", "weapon_right", "weapon_up", "weapon_down")
	
	# 3. Si estás apuntando a alguna dirección...
	if direccion_apuntado.length() > 0.1:
		angulo_actual = direccion_apuntado.angle()
		rotation = angulo_actual # Visualmente rota el pivote
		
		# ¿Ha pasado suficiente tiempo para el siguiente disparo?
		if tiempo_ultimo_disparo >= cadencia_disparo:
			disparar_eje_espejo()
			tiempo_ultimo_disparo = 0.0 # Resetear cronómetro

func disparar_eje_espejo() -> void:
	# --- BALA ORIGINAL (Ángulo theta) ---
	crear_instancia_bala(angulo_actual)
	
	# --- BALA ESPEJO (Ángulo theta + PI) ---
	# En radianes, PI equivale a 180 grados. El opuesto perfecto.
	crear_instancia_bala(angulo_actual + PI)
	
	# --- DISPARO EN CRUZ (Hito 4.4 - Modo Hélice) ---
	if disparo_en_cruz:
		# Eje perpendicular positivo (Ángulo theta + PI/2) -> 90 grados
		crear_instancia_bala(angulo_actual + (PI / 2.0))
		# Eje perpendicular negativo (Ángulo theta + 3*PI/2) -> 270 grados
		crear_instancia_bala(angulo_actual + (3.0 * PI / 2.0))

func crear_instancia_bala(angulo: float) -> void:
	# Clonamos la escena de la bala
	var nueva_bala = BALA_ESCENA.instantiate()
	
	# Definimos su vector de dirección usando el coseno y seno del ángulo
	nueva_bala.direccion = Vector2(cos(angulo), sin(angulo))
	
	# Posicionamos la bala justo donde está la nave actualmente
	nueva_bala.global_position = global_position
	
	# ¡SÚPER IMPORTANTE! Inyectamos la bala en el contenedor global del mundo,
	# no dentro de la nave, para que se mueva de forma independiente en el espacio.
	var proyectiles_container = get_node("/root/Main/World/ProjectilesContainer")
	proyectiles_container.add_child(nueva_bala)
