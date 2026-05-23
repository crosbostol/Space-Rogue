extends CharacterBody2D

# Atributos de nuestra clase Player (GDD)
@export var velocidad: float = 300.0
@export var vida_max: float = 100.0
@export var vida: float = 100.0
@export var rango_iman_actual: float = 60.0

func _ready() -> void:
	# Conectar dinámicamente la señal area_entered de la Hitbox
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	# Inicializar la barra de vida en el HUD
	var health_bar = get_node_or_null("/root/Main/UI/HUD/HealthBar")
	if health_bar and health_bar is ProgressBar:
		health_bar.max_value = vida_max
		health_bar.value = vida

func _physics_process(_delta: float) -> void:
	# 1. Capturar el input del jugador en 360° (Teclado WASD o Stick Izquierdo)
	var direccion: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Aplicar la velocidad al vector de movimiento integrado de Godot
	velocity = direccion * velocidad
	
	# 3. Función nativa de Godot que mueve la nave manejando colisiones automáticamente
	move_and_slide()

## Recibe daño de proyectiles o enemigos.
func recibir_dano(cantidad: float) -> void:
	vida = max(0.0, vida - cantidad)
	print("¡Player recibió daño! Vida restante: ", vida)
	
	# Actualizar el ProgressBar del HUD
	var health_bar = get_node_or_null("/root/Main/UI/HUD/HealthBar")
	if health_bar and health_bar is ProgressBar:
		health_bar.value = vida
		
	if vida <= 0.0:
		print("GAME OVER - El jugador ha sido destruido")

## Recibe experiencia de los orbes recolectados.
func recibir_xp(cantidad: int) -> void:
	var run_manager = get_node_or_null("/root/Main/Managers/RunManager")
	if run_manager and run_manager.has_method("añadir_xp"):
		run_manager.añadir_xp(cantidad)

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Comprobar si el objeto colisionado inflige daño
	if "dano_impacto" in area:
		recibir_dano(area.dano_impacto)
		
		# Destruir al enemigo de forma formal para gatillar su señal de muerte
		if area.has_method("recibir_dano"):
			var vida_enemigo = area.get("vida")
			if vida_enemigo != null:
				area.recibir_dano(vida_enemigo)
			else:
				area.recibir_dano(9999.0)
