extends Control
class_name Title_Scene
#region VARIABLES
var singleton: Singleton
#-------------------------------------------------------------------------------
@export var titleMenu: Title_Menu
@export var saveMenu: Save_Menu
@export var saveMenu2: Save_Menu2
#endregion
#-------------------------------------------------------------------------------
#region STATE MACHINE
func _ready() -> void:
	singleton = get_node("/root/singleton")
	#-------------------------------------------------------------------------------
	titleMenu.Start()
	saveMenu.Start()
	saveMenu2.Start()
	#-------------------------------------------------------------------------------
	SetIdiome()
	#-------------------------------------------------------------------------------
	singleton.MoveToButton(titleMenu.button[0])
	#singleton.PlayBGM_OGG(singleton.bgmTitle)
	singleton.PlayBGM_MP3(singleton.bgmTitle_mp3)
	show()
#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
func SetIdiome():
	singleton.DisconnectAll(singleton.optionMenu.idiomeChange)
	#-------------------------------------------------------------------------------
	singleton.optionMenu.idiomeChange.connect(titleMenu.SetIdiome)
	singleton.optionMenu.idiomeChange.connect(saveMenu.SetIdiome)
	singleton.optionMenu.idiomeChange.connect(saveMenu2.SetIdiome)
	#-------------------------------------------------------------------------------
	titleMenu.SetIdiome()
	saveMenu.SetIdiome()
	saveMenu2.SetIdiome()
