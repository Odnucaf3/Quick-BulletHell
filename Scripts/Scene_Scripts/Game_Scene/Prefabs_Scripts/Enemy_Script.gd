extends Node2D
class_name Enemy

#region VARIABLES
@export var label: Label
@export var sprite: Sprite2D
#-------------------------------------------------------------------------------
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
var distance_squared_to_hitbox: float
#-------------------------------------------------------------------------------
var hp: int
var maxHp: int
var canBeHit: bool = true
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
var tween_Array: Array[Tween] = []
signal death_signal
#endregion
#-------------------------------------------------------------------------------
func Death_Signal():
	death_signal.emit()
#-------------------------------------------------------------------------------
#func _draw() -> void:
#	draw_circle(Vector2.ZERO, radius, Color.RED, false)
#-------------------------------------------------------------------------------
