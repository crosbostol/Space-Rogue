extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO # El vector hacia donde viaja

## Indica si el proyectil fue disparado por un enemigo
@export var es_bala_enemiga: bool = false

## Daño que inflige el proyectil
@export var dano_impacto: float = 10.0

## Propiedades polimórficas de munición (Hito 8.1)
@export var tipo_bala: Enums.TipoBala = Enums.TipoBala.ESTANDAR
@export var capacidad_perforacion: int = 1

# Historial de posiciones globales para dibujar la estela
var historial_posiciones: Array[Vector2] = []

func _ready() -> void:
	# Configurar las particularidades visuales y físicas según su tipo de bala
	var visual = get_node_or_null("Line2D")
	
	if tipo_bala == Enums.TipoBala.PERFORANTE:
		capacidad_perforacion = 3
		velocidad = 750.0
		if visual and visual is Line2D:
			visual.default_color = Color(0.2, 1.0, 0.4) # Verde Eléctrico Neón
	elif tipo_bala == Enums.TipoBala.EXPANSIVA:
		if visual and visual is Line2D:
			visual.default_color = Color(1.0, 0.5, 0.0) # Naranja/Fuego Neón

	# Alinear la rotación del nodo raíz de la bala con su dirección de viaje (0 radianes es X positivo)
	rotation = direccion.angle()
	
	# Conectar la señal de colisión por código
	area_entered.connect(_on_area_entered)
	
	# Configurar visualmente la estela heredando el color de la bala con transparencia
	var estela = get_node_or_null("Estela")
	if estela and visual and estela is Line2D and visual is Line2D:
		var color_trail: Color = visual.default_color
		color_trail.a = 0.35 # Opacidad reducida para un brillo sutil
		estela.default_color = color_trail
		estela.clear_points()

func _physics_process(delta: float) -> void:
	# Mover la bala en la dirección asignada de forma constante
	position += direccion * velocidad * delta
	
	# Acumular la posición global actual
	historial_posiciones.append(global_position)
	if historial_posiciones.size() > 5:
		historial_posiciones.pop_front()
		
	# Redibujar la estela localizando las coordenadas
	var estela = get_node_or_null("Estela")
	if estela and estela is Line2D:
		estela.clear_points()
		# Recorrer a la inversa (desde más reciente a más antigua) para que el grosor decrezca desde la bala
		for i in range(historial_posiciones.size() - 1, -1, -1):
			estela.add_point(to_local(historial_posiciones[i]))

# Este evento lo da el nodo "VisibleOnScreenNotifier2D"
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Si la bala sale del espacio gris visible, se destruye para liberar RAM
	queue_free()

func recibir_dano(_cantidad: float) -> void:
	# Si recibe daño (por ejemplo, al colisionar con la Hitbox del Player), se destruye
	queue_free()

func _fragmentar_proyectil() -> void:
	var bala_escena = load(scene_file_path) if scene_file_path else load("res://Bala.tscn")
	if not bala_escena:
		return
		
	var parent = get_parent()
	if not parent:
		return
		
	var angulos: Array[float] = [-30.0, 0.0, 30.0]
	var direccion_madre: Vector2 = Vector2.RIGHT.rotated(rotation)
	var posicion_segura: Vector2 = global_position + (direccion_madre * 35.0)
	
	for angulo in angulos:
		var mini = bala_escena.instantiate()
		if mini:
			mini.tipo_bala = Enums.TipoBala.ESTANDAR
			mini.es_bala_enemiga = false
			mini.dano_impacto = dano_impacto * 0.5
			mini.velocidad = velocidad * 0.7
			var angulo_rad: float = rotation + deg_to_rad(angulo)
			mini.direccion = Vector2(cos(angulo_rad), sin(angulo_rad))
			mini.global_position = posicion_segura
			parent.call_deferred("add_child", mini)

func _on_area_entered(area: Area2D) -> void:
	if es_bala_enemiga:
		# Las balas enemigas solo dañan la Hitbox del Player
		if area.name == "Hitbox":
			var player = area.get_parent()
			if player and player.has_method("recibir_dano"):
				player.recibir_dano(dano_impacto)
			queue_free()
	else:
		# Las balas del jugador solo dañan a los enemigos (evitando fuego amigo con proyectiles u orbes)
		if area.has_method("recibir_dano") and area.name != "Hitbox":
			# Evitamos colisionar con otras balas o XP Orbs
			if not ("direccion" in area) and not ("valor_xp" in area):
				area.recibir_dano(dano_impacto)
				capacidad_perforacion -= 1
				if capacidad_perforacion <= 0:
					if tipo_bala == Enums.TipoBala.EXPANSIVA:
						_fragmentar_proyectil()
					queue_free()
