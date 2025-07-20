## Player Resource.
## 
## A resource that hold all the player Select Stats.
extends Resource
class_name PlayerResource
#region VARIABLES
@export var picture: Texture2D
@export var texture: Texture2D
#-------------------------------------------------------------------------------
@export var normalSpeed: float = 7.0
@export var focusSpeed: float = 3.5
#-------------------------------------------------------------------------------
@export var hitBox_Scale: float = 1.0
@export var grazeBox_Scale: float = 1.0
@export var magnetBox_Scale: float = 1.0
#-------------------------------------------------------------------------------
@export var maxLives: int
@export var maxPower: int
@export var maxMoney: int
#endregion
