extends Node2D

# 1. Cargamos el molde (la escena) de la bala en memoria
const BALA_ESCENA = preload("res://Bala.tscn")

@export var cadencia_disparo: float = 0.25 # Segundos entre disparos
var tiempo_ultimo_disparo: float = 0.0
var angulo_actual: float = 0.0

## Cantidad acumulativa de hélices de disparo (Evolución infinita para pruebas de estrés)
var cantidad_helices: int = 1

## Tipo de munición activa (Hito 8.1)
@export var tipo_bala_actual: Enums.TipoBala = Enums.TipoBala.ESTANDAR

func _process(delta: float) -> void:
	# Actualizar el temporizador de la cadencia
	tiempo_ultimo_disparo += delta
	
	# 2. Capturar tu nuevo mapeo del Stick R / Flechas
	var direccion_apuntado: Vector2 = Input.get_vector("weapon_left", "weapon_right", "weapon_up", "weapon_down")
	
	# 3. Si estás apuntando a alguna dirección...
	if direccion_apuntado.length() > 0.1:
		angulo_actual = direccion_apuntado.angle()
		rotation = 0.0 # Reiniciar rotación local ya que rotamos directamente al Player
		
		# Rotar síncronamente al nodo padre (el Player) en el eje Z
		var player = get_parent()
		if player and player is Node2D:
			player.rotation = angulo_actual
		
		# ¿Ha pasado suficiente tiempo para el siguiente disparo?
		if tiempo_ultimo_disparo >= cadencia_disparo:
			disparar_eje_espejo()
			tiempo_ultimo_disparo = 0.0 # Resetear cronómetro

## Lógica refactorizada para dividir el círculo en base a hélices acumulativas infinitas
func disparar_eje_espejo() -> void:
	# El total de proyectiles a instanciar en el mismo frame
	var total_proyectiles: int = cantidad_helices * 2
	
	# Distribución trigonométrica uniforme en 360 grados (2*PI radianes)
	for i in range(total_proyectiles):
		var angulo_disparo: float = angulo_actual + (i * (2.0 * PI / total_proyectiles))
		crear_instancia_bala(angulo_disparo)

func crear_instancia_bala(angulo: float) -> void:
	# Clonamos la escena de la bala
	var nueva_bala = BALA_ESCENA.instantiate()
	nueva_bala.tipo_bala = tipo_bala_actual
	
	# Definimos su vector de dirección usando el coseno y seno del ángulo
	nueva_bala.direccion = Vector2(cos(angulo), sin(angulo))
	
	# Posicionamos la bala en el extremo de la punta de la nave (mitigación de inercia visual a 16px)
	var offset_canon: Vector2 = Vector2(cos(angulo), sin(angulo)) * 16.0
	nueva_bala.global_position = global_position + offset_canon
	
	# ¡SÚPER IMPORTANTE! Inyectamos la bala en el contenedor global del mundo
	var proyectiles_container = get_node("/root/Main/World/ProjectilesContainer")
	if proyectiles_container:
		proyectiles_container.add_child(nueva_bala)
