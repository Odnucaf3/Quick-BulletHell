extends Node2D
class_name Enemy
#-------------------------------------------------------------------------------
enum MOVING_STATE{IDLE, RIGHT, LEFT}
#region VARIABLES
@export var label: Label
@export var sprite: Sprite2D
@export var animationTree: AnimationTree
#-------------------------------------------------------------------------------
var velocity: Vector2 = Vector2.ZERO
var dir: float = 0
var vel: float = 0
var radius: float = 30
#-------------------------------------------------------------------------------
var hp: int
var maxHp: int
var canBeHit: bool = true
#-------------------------------------------------------------------------------
var playback: AnimationNodeStateMachinePlayback
var myMOVING_STATE: MOVING_STATE = MOVING_STATE.IDLE
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
#	draw_circle(Vector2.ZERO, radius, Color.RED)
#-------------------------------------------------------------------------------
