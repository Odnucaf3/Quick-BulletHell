extends Node2D
class_name Player
#-------------------------------------------------------------------------------
enum PLAYER_STATE{ALIVE, DEATH, INVINCIBLE}
#region VARIABLES
var velocity: Vector2
var dir: float
var vel: float
#-------------------------------------------------------------------------------
var canBeHit: bool = true
#-------------------------------------------------------------------------------
var physics_Update: Callable = func(): pass
var tween_Array: Array[Tween] = []
#-------------------------------------------------------------------------------
@export var myPLAYER_STATE: PLAYER_STATE
#-------------------------------------------------------------------------------
@export var sprite: Sprite2D
#-------------------------------------------------------------------------------
@export var magnetBox_Sprite: Sprite2D
@export var grazeBox_Sprite: Sprite2D
@export var hitBox_Sprite: Sprite2D
#-------------------------------------------------------------------------------
var hitBox_radius: float = 6.0
var grazeBox_radius: float = 16.0
var magnetBox_radius: float = 95.0
#-------------------------------------------------------------------------------
var playerResource: PlayerResource
#endregion
#-------------------------------------------------------------------------------
#region CONSTRUCTORS
func SetPlayer(_playerResournce: PlayerResource):
	playerResource = _playerResournce
	#-------------------------------------------------------------------------------
	#sprite.texture = _playerResournce.texture
	#-------------------------------------------------------------------------------
	magnetBox_Sprite.scale.x  *= _playerResournce.magnetBox_Scale
	magnetBox_Sprite.scale.y  *= _playerResournce.magnetBox_Scale
	#-------------------------------------------------------------------------------
	grazeBox_Sprite.scale.x  *= _playerResournce.grazeBox_Scale
	grazeBox_Sprite.scale.y  *= _playerResournce.grazeBox_Scale
	#-------------------------------------------------------------------------------
	hitBox_Sprite.scale.x  *= _playerResournce.hitBox_Scale
	hitBox_Sprite.scale.y  *= _playerResournce.hitBox_Scale
#endregion
#-------------------------------------------------------------------------------
#func _draw() -> void:
#	draw_circle(Vector2.ZERO, magnetBox_radius, Color.BLUE, false)
#	draw_circle(Vector2.ZERO, grazeBox_radius, Color.GREEN, false)
#	draw_circle(Vector2.ZERO, hitBox_radius, Color.RED, false)
#-------------------------------------------------------------------------------
