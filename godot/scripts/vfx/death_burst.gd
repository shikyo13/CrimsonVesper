extends AnimatedSprite2D
## Death burst VFX — plays the explosion animation once then frees itself.

func _ready() -> void:
	play("burst")
	animation_finished.connect(func(): queue_free())
