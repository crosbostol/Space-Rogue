extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO # El vector hacia donde viaja

func _ready() -> void:
	# Conectar la señal de colisión por código
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Mover la bala en la dirección asignada de forma constante
	position += direccion * velocidad * delta

# Este evento lo da el nodo "VisibleOnScreenNotifier2D"
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Si la bala sale del espacio gris visible, se destruye para liberar RAM
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("recibir_dano"):
		area.recibir_dano(10.0) # 10.0 de daño base por impacto
		queue_free() # Disolver proyectil tras impacto
