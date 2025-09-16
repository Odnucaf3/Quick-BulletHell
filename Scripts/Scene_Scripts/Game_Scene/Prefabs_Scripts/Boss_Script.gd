extends Node2D
class_name Boss

#region VARIABLES
@export var label: Label
@export var sprite: Sprite2D
@export var animationTree: AnimationTree
#-------------------------------------------------------------------------------
var dir: float
var vel: float
var vel_X: float
var vel_Y: float
#-------------------------------------------------------------------------------
var hitbox_radius: float
var hurtbox_radius: float
#-------------------------------------------------------------------------------
var hp: int
var maxHp: int
var canBeHit: bool = true
var canMove: bool = true
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
var tween_Array: Array[Tween] = []
signal death_signal
#endregion
#-------------------------------------------------------------------------------
func Death_Signal():
	death_signal.emit()
#-------------------------------------------------------------------------------
func _draw() -> void:
	draw_circle(Vector2.ZERO, hitbox_radius, Color.RED, false)
	draw_circle(Vector2.ZERO, hurtbox_radius, Color.GREEN, false)
#-------------------------------------------------------------------------------
