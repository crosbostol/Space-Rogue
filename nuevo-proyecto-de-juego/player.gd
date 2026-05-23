extends CharacterBody2D

# Atributos de nuestra clase Player (GDD)
@export var velocidad: float = 300.0
@export var vida_max: float = 100.0
@export var vida: float = 100.0
@export var rango_iman_actual: float = 60.0

## Nivel acumulativo de evolución de armas para maquetación procedimental
var nivel_evolucion_armas: int = 1

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
		
	# Conectar de forma dinámica el botón de reinicio de la interfaz del HUD (Seguridad de UI/UX)
	var restart_button = get_node_or_null("/root/Main/UI/HUD/GameOverScreen/CenterContainer/VBoxContainer/RestartButton")
	if restart_button and restart_button is Button:
		restart_button.pressed.connect(_on_restart_button_pressed)
		print("Player: Conexión dinámica exitosa a 'pressed' de RestartButton.")

	# Inicializar la geometría procedimental de la nave
	actualizar_geometria_nave()

func _physics_process(_delta: float) -> void:
	# 1. Capturar el input del jugador en 360° (Teclado WASD o Stick Izquierdo)
	var direccion: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Aplicar la velocidad al vector de movimiento integrado de Godot
	velocity = direccion * velocidad
	
	# 3. Función nativa de Godot que mueve la nave manejando colisiones automáticamente
	move_and_slide()
	
	# 4. Efecto Estético Avanzado de Inclinación por Inercia (Lean Effect)
	# Calculamos la proporción de velocidad actual respecto al máximo
	var ratio_x: float = abs(velocity.x) / velocidad
	var ratio_y: float = abs(velocity.y) / velocidad
	
	# Objetivos de escala elástica: contracción lateral en X y sutil cabeceo en Y
	var objetivo_escala_x: float = 1.0 - (ratio_x * 0.15)
	var objetivo_escala_y: float = 1.0 - (ratio_y * 0.10)
	
	# Aplicar interpolación lineal suave (lerp) para deformación visual fluida y orgánica
	var visual = get_node_or_null("Visual")
	if visual and visual is Line2D:
		visual.scale.x = lerp(visual.scale.x, objetivo_escala_x, 10.0 * _delta)
		visual.scale.y = lerp(visual.scale.y, objetivo_escala_y, 10.0 * _delta)

## Genera procedimentalmente la forma geométrica de la nave en base al nivel de evolución de armas
func actualizar_geometria_nave() -> void:
	var visual = get_node_or_null("Visual")
	if not visual or not visual is Line2D:
		print("Player: ADVERTENCIA - No se pudo encontrar el nodo visual Line2D llamado 'Visual'.")
		return
		
	if nivel_evolucion_armas == 1:
		# Caza estelar base en forma de triángulo agresivo apuntando al frente (eje X positivo)
		var vertices: Array[Vector2] = [
			Vector2(15, 0),
			Vector2(-12, 10),
			Vector2(-6, 0),
			Vector2(-12, -10),
			Vector2(15, 0)
		]
		visual.points = PackedVector2Array(vertices)
		print("Player: Geometría de nave base (Caza Estelar) dibujada procedimentalmente.")
	else:
		# Círculo estrella trigonométrica adaptativa
		var vertices: Array[Vector2] = []
		var total_puntas: int = nivel_evolucion_armas * 2
		var r_outer: float = 16.0
		var r_inner: float = 8.0
		
		for i in range(total_puntas):
			# Vértice exterior (Punta del cañón de disparo)
			var angle_outer: float = i * (2.0 * PI / total_puntas)
			vertices.append(Vector2(cos(angle_outer) * r_outer, sin(angle_outer) * r_outer))
			
			# Vértice interior (Valle de la estrella)
			var angle_inner: float = (i + 0.5) * (2.0 * PI / total_puntas)
			vertices.append(Vector2(cos(angle_inner) * r_inner, sin(angle_inner) * r_inner))
			
		# Cerrar el polígono repitiendo el primer vértice
		vertices.append(vertices[0])
		visual.points = PackedVector2Array(vertices)
		print("Player: Geometría procedimental adaptada con ", total_puntas, " puntas (Nivel armas: ", nivel_evolucion_armas, ").")

## Recibe daño de proyectiles o enemigos.
func recibir_dano(cantidad: float) -> void:
	# Evitar procesamiento de daño si ya está destruido
	if vida <= 0.0:
		return
		
	vida = max(0.0, vida - cantidad)
	print("¡Player recibió daño! Vida restante: ", vida)
	
	# Actualizar el ProgressBar del HUD
	var health_bar = get_node_or_null("/root/Main/UI/HUD/HealthBar")
	if health_bar and health_bar is ProgressBar:
		health_bar.value = vida
		
	if vida <= 0.0:
		print("GAME OVER - El jugador ha sido destruido")
		# Congelar el tiempo del juego por completo
		Engine.time_scale = 0.0
		# Mostrar la pantalla de fin de partida en la interfaz
		var game_over_screen = get_node_or_null("/root/Main/UI/HUD/GameOverScreen")
		if game_over_screen:
			game_over_screen.visible = true
			print("Player: GameOverScreen revelado exitosamente. Flujo pausado.")
			
			# Forzar foco inicial en RestartButton para permitir confirmación inmediata con Enter/Space/Joystick (UI/UX)
			var restart_btn = game_over_screen.get_node_or_null("CenterContainer/VBoxContainer/RestartButton")
			if restart_btn and restart_btn is Button:
				restart_btn.grab_focus()
				print("Player: Foco de entrada inyectado en el botón de reinicio.")

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

## Callback de reinicio de la run (limpieza segura)
func _on_restart_button_pressed() -> void:
	# 1. Restablecer la velocidad del motor de juego
	Engine.time_scale = 1.0
	print("Player: Engine.time_scale restaurado a 1.0.")
	
	# 2. Recargar de forma síncrona el universo de juego
	print("Player: Recargando escena actual de la run.")
	get_tree().reload_current_scene()

## Intercepta inputs globales para forzar reinicio con ui_accept (Enter/Space) o Botón A del mando cuando GameOver está activo (Hito 4.12)
func _input(event: InputEvent) -> void:
	var game_over_screen = get_node_or_null("/root/Main/UI/HUD/GameOverScreen")
	if game_over_screen and game_over_screen.visible:
		var es_boton_a_mando = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A
		if event.is_action_pressed("ui_accept") or es_boton_a_mando:
			# Consumir el evento primero mientras el nodo sigue en el árbol
			get_viewport().set_input_as_handled()
			
			# Simular el clic en el botón de reinicio (remueve el nodo y recarga)
			_on_restart_button_pressed()
