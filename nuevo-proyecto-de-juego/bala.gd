extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO # El vector hacia donde viaja

## Indica si el proyectil fue disparado por un enemigo
@export var es_bala_enemiga: bool = false

## Daño que inflige el proyectil
@export var dano_impacto: float = 10.0

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

func recibir_dano(_cantidad: float) -> void:
	# Si recibe daño (por ejemplo, al colisionar con la Hitbox del Player), se destruye
	queue_free()

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
				queue_free()

