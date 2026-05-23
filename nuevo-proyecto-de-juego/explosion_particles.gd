extends CPUParticles2D

func _ready() -> void:
	# Forzar la emisión al nacer
	emitting = true
	
	# Programar autodestrucción segura al terminar (usando tiempo real para ignorar hit-stun/pausas)
	get_tree().create_timer(lifetime + 0.1, true, false, true).timeout.connect(queue_free)
