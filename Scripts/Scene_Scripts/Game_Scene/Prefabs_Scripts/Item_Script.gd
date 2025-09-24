extends Sprite2D
class_name Item
#-------------------------------------------------------------------------------
enum ITEM_STATE{SPIN, FALL, IMANTED}
#region VARIABLES
var dir: float
var vel: float
var vel_X: float
var vel_Y: float
#-------------------------------------------------------------------------------
var radius: float
#-------------------------------------------------------------------------------
var myITEM_STATE: ITEM_STATE
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
#endregion
#-------------------------------------------------------------------------------
#func _draw() -> void:
#	draw_circle(Vector2.ZERO, radius/scale.x, Color.GREEN, false)
#-------------------------------------------------------------------------------
