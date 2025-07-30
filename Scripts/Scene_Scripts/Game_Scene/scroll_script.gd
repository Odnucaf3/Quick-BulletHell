extends TextureRect
#-------------------------------------------------------------------------------
@export var scroll_y: float = 2.0
var deltaTimeScale: float = 1.0
var limit: Vector2
#-------------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	deltaTimeScale = Engine.time_scale
	position.y += scroll_y * deltaTimeScale
	if(position.y > 648):
		position.y = -size.y
#-------------------------------------------------------------------------------
