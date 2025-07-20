extends Resource
##A resource that hold all the information of the enemy bullets.
class_name BulletResource
##Name of the card.
@export var texture: Texture2D
#-------------------------------------------------------------------------------
@export var radius: float = 2
@export var h_frames: int = 16
@export var v_frames: int = 1
@export var maxFrame: int = 16
@export var offset: Vector2 = Vector2(0, 0)
#-------------------------------------------------------------------------------
