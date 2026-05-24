extends CharacterBody2D

# Atributos de nuestra clase Player (GDD)
@export var velocidad: float = 300.0
@export var vida_max: float = 100.0
@export var vida: float = 100.0
@export var rango_iman_actual: float = 60.0

## Nivel acumulativo de evolución de armas para maquetación procedimental
var nivel_evolucion_armas: int = 1

## Indica si el jugador es invulnerable (Modo Trucos / DevMode)
var es_invulnerable: bool = false

## Indica si el jugador es invulnerable de forma temporal tras elegir una mejora
var es_invulnerable_temporal: bool = false

## Determina si el efecto de borde rojo por daño (Vignette) está habilitado en los ajustes
var usar_vignette_dano: bool = true

## Temporizador para bloquear la respiración de la viñeta tras un impacto y permitir que el flash decaiga
var tiempo_bloqueo_respiracion: float = 0.0

## Array de umbrales cruzados para generación procedimental de grietas de cabina: [0.75, 0.50, 0.25]
var umbrales_cruzados: Array[bool] = [false, false, false]

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

	# Buscar y configurar el Menú de Desarrollador (DevMenu) dinámicamente
	var dev_menu = get_node_or_null("/root/Main/UI/DevMenu")
	if dev_menu:
		var btn_helice = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/CheatHelice")
		var btn_coraza = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/CheatCoraza")
		var btn_iman = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/CheatIman")
		var btn_inv = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/CheatInvulnerabilidad")
		var btn_vig = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/ToggleVignette")
		
		if btn_helice: btn_helice.pressed.connect(_on_cheat_helice_pressed)
		if btn_coraza: btn_coraza.pressed.connect(_on_cheat_coraza_pressed)
		if btn_iman: btn_iman.pressed.connect(_on_cheat_iman_pressed)
		if btn_inv: btn_inv.pressed.connect(_on_cheat_invulnerabilidad_pressed)
		if btn_vig: btn_vig.pressed.connect(_on_toggle_vignette_pressed)
		print("Player: Conexiones de señales del DevMenu inicializadas síncronamente.")

	# Inicializar la geometría procedimental de la nave
	actualizar_geometria_nave()
	
	# Inicializar la viñeta de daño al 100% de salud de forma transparente
	actualizar_vignette_dano_por_salud(false)

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

func _process(delta: float) -> void:
	if tiempo_bloqueo_respiracion > 0.0:
		tiempo_bloqueo_respiracion -= delta
		
	var vignette = get_node_or_null("/root/Main/UI/HUD/VignetteDano")
	if vignette and vignette.visible:
		if not usar_vignette_dano:
			vignette.modulate.a = 0.0
			return
			
		var porcentaje_salud: float = clamp(vida / vida_max, 0.0, 1.0)
		
		if porcentaje_salud > 0.7:
			if tiempo_bloqueo_respiracion <= 0.0:
				vignette.modulate.a = 0.0
		else:
			if tiempo_bloqueo_respiracion <= 0.0:
				# A menor vida, más rápido respira el sistema (frecuencia)
				var factor_tension: float = 1.0 - porcentaje_salud
				var frecuencia: float = lerp(2.0, 8.0, factor_tension)
				
				# La opacidad base oscila suavemente usando una función seno
				var oscilacion: float = (sin(Time.get_ticks_msec() * 0.001 * frecuencia) + 1.0) / 2.0
				
				# Establecer un techo de opacidad sutil (máximo 0.35 en peligro crítico)
				var opacidad_maxima: float = lerp(0.05, 0.35, factor_tension)
				vignette.modulate.a = oscilacion * opacidad_maxima

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
	# Freno absoluto de Invulnerabilidad para pruebas de control de calidad o temporal por menú
	if es_invulnerable or es_invulnerable_temporal:
		return
		
	# Evitar procesamiento de daño si ya está destruido
	if vida <= 0.0:
		return
		
	vida = max(0.0, vida - cantidad)
	print("¡Player recibió daño! Vida restante: ", vida)
	
	# Animación y recalculo de Tensión Dinámica del Red Splash / Vignette
	actualizar_vignette_dano_por_salud(true)
	
	# Disparar impacto dinámico y acumulativo en el parabrisas
	var selector_grietas = get_node_or_null("/root/Main/UI/HUD/GrietasCabina")
	if selector_grietas and selector_grietas.has_method("registrar_impacto_vidrio"):
		var porcentaje_salud: float = clamp(vida / vida_max, 0.0, 1.0)
		var factor_dano: float = cantidad / vida_max
		selector_grietas.registrar_impacto_vidrio(factor_dano, porcentaje_salud)
	
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

## Activa un tiempo de invulnerabilidad temporal en segundos con feedback visual (transparencia fantasma)
func hacer_invulnerable_temporal(duracion: float) -> void:
	es_invulnerable_temporal = true
	
	var visual = get_node_or_null("Visual")
	if visual:
		visual.modulate.a = 0.4
		
		# Usar Tween para restaurar modulate de forma segura (se limpia automáticamente si el jugador es liberado)
		var inv_tween = create_tween()
		inv_tween.tween_property(visual, "modulate:a", 1.0, 0.0).set_delay(duracion)
		inv_tween.tween_callback(func():
			es_invulnerable_temporal = false
			print("Player: Invulnerabilidad temporal finalizada.")
		)

## Restablece los umbrales de fractura de cabina y limpia las grietas visuales (autoreparación de nanobots)
func reparar_cabina_completa() -> void:
	umbrales_cruzados = [false, false, false]
	var grietas = get_node_or_null("/root/Main/UI/HUD/GrietasCabina")
	if grietas and grietas.has_method("limpiar_grietas"):
		grietas.limpiar_grietas()

## Recalcula el offset y la opacidad de la viñeta de daño en base a la salud actual del jugador (Tensión Dinámica)
func actualizar_vignette_dano_por_salud(es_impacto: bool = false) -> void:
	if not usar_vignette_dano:
		return
		
	var vignette = get_node_or_null("/root/Main/UI/HUD/VignetteDano")
	if vignette and vignette.texture and vignette.texture is GradientTexture2D:
		var g_texture = vignette.texture as GradientTexture2D
		var gradient = g_texture.gradient
		if gradient:
			# Forzar los offsets y colores fijos para mantener el centro limpio (96% de la pantalla)
			gradient.offsets = PackedFloat32Array([0.96, 1.0])
			gradient.colors = PackedColorArray([Color(1, 0, 0, 0), Color(1, 0, 0, 0.25)])
			
			# 1. Calcular el porcentaje de salud actual (rango 0.0 a 1.0)
			var porcentaje_salud: float = clamp(vida / vida_max, 0.0, 1.0)
			var factor_tension: float = 1.0 - porcentaje_salud
			
			var opacidad_base: float = 0.0
			if porcentaje_salud <= 0.7:
				opacidad_base = lerp(0.05, 0.35, factor_tension)
				
			if es_impacto:
				# Pico de opacidad instantáneo
				vignette.modulate.a = 0.5
				tiempo_bloqueo_respiracion = 0.2
				
				# Decaimiento suave usando Tween
				var tween = create_tween()
				tween.tween_property(vignette, "modulate:a", opacidad_base, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				# Actualización suave sin impacto (para curación o carga inicial)
				var tween = create_tween()
				tween.tween_property(vignette, "modulate:a", opacidad_base, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
	# Mapeo de Alt + 1 para conmutar el Menú de Desarrollo (DevMenu) con pausa síncrona
	if event is InputEventKey and event.pressed:
		if Input.is_key_pressed(KEY_ALT) and event.keycode == KEY_1:
			var dev_menu = get_node_or_null("/root/Main/UI/DevMenu")
			if dev_menu:
				dev_menu.visible = not dev_menu.visible
				if dev_menu.visible:
					Engine.time_scale = 0.0
					print("Player: DevMenu activado. Tiempo congelado.")
				else:
					Engine.time_scale = 1.0
					print("Player: DevMenu desactivado. Tiempo reanudado.")
				
				get_viewport().set_input_as_handled()
				return
				
	var game_over_screen = get_node_or_null("/root/Main/UI/HUD/GameOverScreen")
	if game_over_screen and game_over_screen.visible:
		var es_boton_a_mando = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A
		if event.is_action_pressed("ui_accept") or es_boton_a_mando:
			# Consumir el evento primero mientras el nodo sigue en el árbol
			get_viewport().set_input_as_handled()
			
			# Simular el clic en el botón de reinicio (remueve el nodo y recarga)
			_on_restart_button_pressed()

## Callback: Incrementa el nivel de la hélice procedimentalmente
func _on_cheat_helice_pressed() -> void:
	nivel_evolucion_armas += 1
	actualizar_geometria_nave()
	
	var weapon_system = get_node_or_null("WeaponSystem")
	if weapon_system and "cantidad_helices" in weapon_system:
		weapon_system.cantidad_helices += 1
		print("Cheat Dev: Modo Hélice incrementado. Cantidad: ", weapon_system.cantidad_helices)

## Callback: Incrementa vida máxima en 25 y cura por completo al jugador
func _on_cheat_coraza_pressed() -> void:
	vida_max += 25.0
	vida = vida_max
	print("Cheat Dev: Modo Coraza aplicado. Vida Máx: ", vida_max)
	
	# Sincronizar HUD
	var health_bar = get_node_or_null("/root/Main/UI/HUD/HealthBar")
	if health_bar and health_bar is ProgressBar:
		health_bar.max_value = vida_max
		health_bar.value = vida
		
	# Sincronizar y limpiar la viñeta de tensión y las grietas de cabina
	actualizar_vignette_dano_por_salud(false)
	reparar_cabina_completa()

## Callback: Incrementa el rango de atracción del imán en 40px
func _on_cheat_iman_pressed() -> void:
	rango_iman_actual += 40.0
	print("Cheat Dev: Modo Imán aplicado. Rango Imán: ", rango_iman_actual)

## Callback: Alterna la invulnerabilidad total
func _on_cheat_invulnerabilidad_pressed() -> void:
	es_invulnerable = not es_invulnerable
	print("Cheat Dev: Invulnerabilidad conmutada: ", es_invulnerable)
	
	var dev_menu = get_node_or_null("/root/Main/UI/DevMenu")
	if dev_menu:
		var btn_inv = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/CheatInvulnerabilidad")
		if btn_inv:
			if es_invulnerable:
				btn_inv.text = "Cheat Invulnerabilidad: Activo"
			else:
				btn_inv.text = "Cheat Invulnerabilidad: Inactivo"

## Callback: Alterna el efecto de borde rojo por daño (Vignette)
func _on_toggle_vignette_pressed() -> void:
	usar_vignette_dano = not usar_vignette_dano
	print("Settings Dev: Usar Vignette Daño conmutado: ", usar_vignette_dano)
	
	var dev_menu = get_node_or_null("/root/Main/UI/DevMenu")
	if dev_menu:
		var btn_vig = dev_menu.get_node_or_null("Panel/MarginContainer/VBoxContainer/ToggleVignette")
		if btn_vig:
			if usar_vignette_dano:
				btn_vig.text = "Efecto Daño Rojo: Activo"
			else:
				btn_vig.text = "Efecto Daño Rojo: Inactivo"
