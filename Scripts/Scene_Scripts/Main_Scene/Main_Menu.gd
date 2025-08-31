extends Control
class_name Main_Menu
#region VARIABLES
@export var mainScene: Main_Scene
var singleton: Singleton
#-------------------------------------------------------------------------------
@export var title: Label
@export var button: Array[Button]
@export var gameInfo: RichTextLabel
@export var picture: TextureRect
#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region STATE MACHINE
func Start() -> void:
	singleton = get_node("/root/singleton")
	#-------------------------------------------------------------------------------
	singleton.SetButton(button[0], singleton.CommonSelected, StartButton_Subited, AnyButton_Canceled)
	singleton.SetButton(button[1], singleton.CommonSelected, PlayerButton_Submited, AnyButton_Canceled)
	singleton.SetButton(button[2], singleton.CommonSelected, DifficultyButton_Submited, AnyButton_Canceled)
	singleton.SetButton(button[3], singleton.CommonSelected, OptionsButton_Subited, AnyButton_Canceled)
	singleton.SetButton(button[4], singleton.CommonSelected, QuitButton_Subited, AnyButton_Canceled)
	#-------------------------------------------------------------------------------
	OptionMenu_BackButton_Set()
	#-------------------------------------------------------------------------------
	show()
#endregion
#-------------------------------------------------------------------------------
#region BUTTON FUNCTIONS
func StartButton_Subited() -> void:
	hide()
	mainScene.stageMenu.UpdateStageButtons()
	mainScene.stageMenu.show()
	singleton.MoveToButton(mainScene.stageMenu.button[0])
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func PlayerButton_Submited() -> void:
	hide()
	mainScene.playerMenu.show()
	#-------------------------------------------------------------------------------
	var _index: int = singleton.currentSaveData_Json["playerIndex"]
	singleton.MoveToButton(mainScene.playerMenu.button[_index])
	mainScene.playerMenu.scrollContainer.scroll_horizontal = int(mainScene.playerMenu.buttonSize.x + mainScene.playerMenu.container.get_theme_constant("separation")) * _index	#NOTA IMPORTANTE: Por alguna razon el boton no se alinea con el container la primera vez, hay que ayudarlo
	#-------------------------------------------------------------------------------
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func DifficultyButton_Submited() -> void:
	hide()
	mainScene.difficultyMenu.show()
	singleton.MoveToButton(mainScene.difficultyMenu.button[singleton.currentSaveData_Json["difficultyIndex"]])
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func OptionsButton_Subited() -> void:
	mainScene.mainMenu.hide()
	mainScene.hide()
	singleton.MoveToButton(singleton.optionMenu.back)
	singleton.optionMenu.show()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func QuitButton_Subited() -> void:
	singleton.CommonSubmited()
	singleton.currentSaveData_Json = {}
	get_tree().change_scene_to_file(singleton.titleScene_Path)
#-------------------------------------------------------------------------------
func AnyButton_Canceled() -> void:
	singleton.MoveToLastButton(button)
	singleton.CommonCanceled()
#endregion
#-------------------------------------------------------------------------------
#region OPTION MENU BACK BUTTON
func OptionMenu_BackButton_Set() -> void:
	singleton.DisconnectButton(singleton.optionMenu.back)
	singleton.SetButton(singleton.optionMenu.back,  singleton.CommonSelected, OptionMenu_BackButton_Subited, OptionMenu_BackButton_Canceled)
#-------------------------------------------------------------------------------
func OptionMenu_BackButton_Subited() -> void:
	OptionMenu_BackButton_Common()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func OptionMenu_BackButton_Canceled() -> void:
	OptionMenu_BackButton_Common()
	singleton.CommonCanceled()
#-------------------------------------------------------------------------------
func OptionMenu_BackButton_Common() -> void:
	singleton.optionMenu.Save_OptionSaveData_Json()
	singleton.optionMenu.hide()
	mainScene.mainMenu.show()
	mainScene.show()
	singleton.MoveToButton(button[3])
#endregion
#-------------------------------------------------------------------------------
#region IDIOME FUNCTIONS
func SetIdiome():
	SetGameInfo()
	for _i in button.size():
		button[_i].text = tr("mainMenu_button"+str(_i))
#-------------------------------------------------------------------------------
func SetGameInfo():
	var _saveData: Dictionary = singleton.currentSaveData_Json
	#-------------------------------------------------------------------------------
	var _playerIndex: int = _saveData.get("playerIndex", 0)
	var _difficultyIndex: int = _saveData.get("difficultyIndex", 0)
	var _stageIndex: int = _saveData.get("stageIndex", 0)
	#-------------------------------------------------------------------------------
	SetGameInfo2(_playerIndex, _difficultyIndex, _stageIndex)
#-------------------------------------------------------------------------------
func SetGameInfo2(_playerIndex: int, _difficultyIndex: int, _stageIndex: int):
	var _saveData: Dictionary = singleton.currentSaveData_Json
	#-------------------------------------------------------------------------------
	var _playerIndex_string: StringName = str(_playerIndex)
	var _difficultyIndex_string: StringName = str(_difficultyIndex)
	var _stageIndex_string: StringName = str(_stageIndex)
	#-------------------------------------------------------------------------------
	gameInfo.text = "[center]"
	gameInfo.text += "[font_size=90]"
	#gameInfo.text = tr("playerMenu_button"+_playerIndex_string)+"\n"
	gameInfo.text +=  tr("difficultyMenu_button"+_difficultyIndex_string)+"\n"
	#gameInfo.text += tr("stageMenu_button"+_stageIndex_string)+"\n"
	picture.texture = singleton.playerResource[_playerIndex].picture
	#-------------------------------------------------------------------------------
	gameInfo.text += "[font_size=30]"
	gameInfo.text += "-"
	var _stage: Dictionary = _saveData["saveData"][_playerIndex_string][_difficultyIndex_string]
	for _i in _stage.size():
		gameInfo.text += str(int(_stage[str(_i)].get("value", 0)))+"-"
#endregion
#-------------------------------------------------------------------------------
