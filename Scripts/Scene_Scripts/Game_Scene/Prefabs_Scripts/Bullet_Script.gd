extends Sprite2D
class_name Bullet
#region VARIABLES
var velocity: Vector2
var dir: float
var vel: float
var radius: float
var distance_squared_to_grazebox: float
var distance_squared_to_hitbox: float
#-------------------------------------------------------------------------------
var can_Go_OffLimits: bool = false
var isGrazed: bool = false
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
var tween_Array: Array[Tween] = []
#endregion
#-------------------------------------------------------------------------------
#func _draw() -> void:
#	draw_circle(Vector2.ZERO, radius/scale.x, Color.RED)
#-------------------------------------------------------------------------------
