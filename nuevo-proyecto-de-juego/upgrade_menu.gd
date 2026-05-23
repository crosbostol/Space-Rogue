extends Control

## Pool de mejoras disponibles (MVP) con tipado estricto
const POOL_MEJORAS: Array[Dictionary] = [
	{
		"id": "iman",
		"nombre": "Modo Imán",
		"descripcion": "Aumenta el rango de atracción de orbes en +40px."
	},
	{
		"id": "coraza",
		"nombre": "Modo Coraza",
		"descripcion": "Suma +25 a la Vida Máxima y repara la nave por completo."
	},
	{
		"id": "helice",
		"nombre": "Modo Hélice",
		"descripcion": "Evoluciona el sistema de armas a un eje de disparo en Cruz (4 proyectiles)."
	}
]

## Opciones de cartas seleccionadas para el nivel actual (estado del menú)
var opciones_actuales: Array[Dictionary] = []

func _ready() -> void:
	# Conectar dinámicamente con la señal de subida de nivel del RunManager
	var run_manager: Node = get_node_or_null("/root/Main/Managers/RunManager")
	if run_manager:
		if run_manager.has_signal("nivel_subido"):
			run_manager.nivel_subido.connect(_on_nivel_subido)
			print("UpgradeMenu: Conexión exitosa a la señal 'nivel_subido' de RunManager.")
		else:
			print("UpgradeMenu: ERROR - RunManager no tiene la señal 'nivel_subido'.")
	else:
		print("UpgradeMenu: ERROR - No se pudo encontrar el nodo RunManager.")

func _on_nivel_subido(nuevo_nivel: int) -> void:
	# 1. Pausar el motor de juego
	Engine.time_scale = 0.0
	
	# 2. Algoritmo de Selección Aleatoria (No-Repeat Shuffle)
	var pool_temporal: Array[Dictionary] = POOL_MEJORAS.duplicate()
	pool_temporal.shuffle()
	
	# Vaciar opciones anteriores y rellenar con las primeras 3 mezcladas sin repetir
	opciones_actuales.clear()
	for i in range(min(3, pool_temporal.size())):
		opciones_actuales.append(pool_temporal[i])
	
	# 3. Inyectar dinámicamente el texto en los botones visuales del Frontend
	var button1 = get_node_or_null("MarginContainer/VBoxContainer/CardsContainer/CardButton1")
	var button2 = get_node_or_null("MarginContainer/VBoxContainer/CardsContainer/CardButton2")
	var button3 = get_node_or_null("MarginContainer/VBoxContainer/CardsContainer/CardButton3")
	
	if button1 and opciones_actuales.size() > 0:
		button1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button1.text = opciones_actuales[0]["nombre"] + "\n\n" + opciones_actuales[0]["descripcion"]
	if button2 and opciones_actuales.size() > 1:
		button2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button2.text = opciones_actuales[1]["nombre"] + "\n\n" + opciones_actuales[1]["descripcion"]
	if button3 and opciones_actuales.size() > 2:
		button3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button3.text = opciones_actuales[2]["nombre"] + "\n\n" + opciones_actuales[2]["descripcion"]
	
	# 4. Hacer visible el menú de upgrades
	visible = true
	
	# 5. Logs de validación de pausa y selección de cartas
	print("UpgradeMenu: ¡Interrupción de Subida de Nivel! Nuevo nivel: ", nuevo_nivel)
	print("UpgradeMenu: Engine.time_scale modificado a: ", Engine.time_scale, " (Juego pausado formalmente).")
	print("UpgradeMenu: Cartas seleccionadas aleatoriamente (sin duplicados):")
	for opcion in opciones_actuales:
		print("  - [", opcion["id"], "] ", opcion["nombre"], ": ", opcion["descripcion"])

## Callback para el primer botón
func _on_card_button_1_pressed() -> void:
	_seleccionar_opcion(0)

## Callback para el segundo botón
func _on_card_button_2_pressed() -> void:
	_seleccionar_opcion(1)

## Callback para el tercer botón
func _on_card_button_3_pressed() -> void:
	_seleccionar_opcion(2)

## Procesa de forma unificada la selección de una mejora, reanuda el tiempo y prepara los TODOs físicos
func _seleccionar_opcion(indice: int) -> void:
	if indice < 0 or indice >= opciones_actuales.size():
		return
		
	var seleccion: Dictionary = opciones_actuales[indice]
	print("Módulo seleccionado: ", seleccion["id"])
	
	# Ocultar el menú de mejoras y reanudar el tiempo de simulación
	visible = false
	Engine.time_scale = 1.0
	print("UpgradeMenu: Engine.time_scale restaurado a: ", Engine.time_scale, " (Juego reanudado).")
	
	# Bloque condicional para inyectar los efectos físicos reales (Hito 4.4)
	var player: CharacterBody2D = get_node_or_null("/root/Main/World/Player")
	if player:
		match seleccion["id"]:
			"iman":
				player.rango_iman_actual += 40.0
				print("UpgradeMenu: ¡Efecto Modo Imán aplicado! Nuevo rango: ", player.rango_iman_actual)
			"coraza":
				player.vida_max += 25.0
				player.vida = player.vida_max
				print("UpgradeMenu: ¡Efecto Modo Coraza aplicado! Nueva vida max: ", player.vida_max)
				
				# Sincronizar con el HUD
				var health_bar = get_node_or_null("/root/Main/UI/HUD/HealthBar")
				if health_bar and health_bar is ProgressBar:
					health_bar.max_value = player.vida_max
					health_bar.value = player.vida
					print("UpgradeMenu: HUD HealthBar actualizado. Max: ", health_bar.max_value, ", Valor: ", health_bar.value)
			"helice":
				var weapon_system = player.get_node_or_null("WeaponSystem")
				if weapon_system and "disparo_en_cruz" in weapon_system:
					weapon_system.disparo_en_cruz = true
					print("UpgradeMenu: ¡Efecto Modo Hélice aplicado! Disparo en cruz activado.")
				else:
					print("UpgradeMenu: ERROR - No se encontró WeaponSystem o la variable disparo_en_cruz.")
	else:
		print("UpgradeMenu: ERROR - Nodo Player no encontrado al aplicar mejora.")
