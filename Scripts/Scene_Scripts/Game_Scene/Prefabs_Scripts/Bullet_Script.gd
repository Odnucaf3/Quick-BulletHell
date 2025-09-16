extends Sprite2D
class_name Bullet

#region VARIABLES
var dir: float
var vel: float
var vel_X: float
var vel_Y: float
#-------------------------------------------------------------------------------
var rotation_offset: float
#-------------------------------------------------------------------------------
var amplitud: float
var amplitud_x: float
var amplitud_y: float
#-------------------------------------------------------------------------------
var frecuencia: float
var spin: float
#-------------------------------------------------------------------------------
var pos_X: float
var pos_Y: float
#-------------------------------------------------------------------------------
var radius: float
#-------------------------------------------------------------------------------
var bounce_counter: int
var bounce_up: bool
var bounce_down: bool
var bounce_left: bool
var bounce_right: bool
#-------------------------------------------------------------------------------
var can_Go_OffLimits: bool = false
var isGrazed: bool = false
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
var tween_Array: Array[Tween] = []
#endregion
#-------------------------------------------------------------------------------
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius/scale.x, Color.RED, false)
#-------------------------------------------------------------------------------
