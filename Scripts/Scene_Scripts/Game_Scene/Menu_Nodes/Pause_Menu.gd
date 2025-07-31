extends Panel
class_name Pause_Menu
#region VARIABLES
var singleton: Singleton
@export var gameScene: Game_Scene
#-------------------------------------------------------------------------------
@export var title: Label
@export var continuar: Button
@export var retry: Button
@export var options: Button
@export var goToTitle: Button
@export var quitGame: Button
#-------------------------------------------------------------------------------
var inOption: bool = false
#endregion
#-------------------------------------------------------------------------------
#region STATE MACHINE
func Start() -> void:
	singleton = get_node("/root/singleton")
	#-------------------------------------------------------------------------------
	SetAllButtons()
	OptionMenu_BackButton_Set()
	hide()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	if(inOption or gameScene.myGAME_STATE == gameScene.GAME_STATE.IN_GAMEOVER):
		return
	if(Input.is_action_just_pressed("input_Pause")):
		gameScene.Pause_Off()
		singleton.CommonCanceled()
#endregion
#-------------------------------------------------------------------------------
#region BUTTON FUNCTIONS
func SetAllButtons() -> void:
	singleton.SetButton(continuar, singleton.CommonSelected, ContinueButton_Subited, AnyButton_Canceled)
	singleton.SetButton(retry, singleton.CommonSelected, RetryButton_Subited, AnyButton_Canceled)
	singleton.SetButton(options, singleton.CommonSelected, OptionButton_Subited, AnyButton_Canceled)
	singleton.SetButton(goToTitle, singleton.CommonSelected, GoToTitleButton_Subited, AnyButton_Canceled)
	singleton.SetButton(quitGame, singleton.CommonSelected, QuitGameButton_Subited, AnyButton_Canceled)
#-------------------------------------------------------------------------------
func ContinueButton_Subited() -> void:
	gameScene.Pause_Off()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func RetryButton_Subited() -> void:
	singleton.CommonSubmited()
	get_tree().reload_current_scene()
#-------------------------------------------------------------------------------
func OptionButton_Subited() -> void:
	gameScene.currentLayer.hide()
	inOption = true
	singleton.MoveToButton(singleton.optionMenu.back)
	singleton.optionMenu.show()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func GoToTitleButton_Subited() -> void:
	singleton.CommonSubmited()
	gameScene.GoToMainScene()
#-------------------------------------------------------------------------------
func QuitGameButton_Subited() -> void:
	singleton.CommonSubmited()
	get_tree().quit()
#-------------------------------------------------------------------------------
func AnyButton_Canceled() -> void:
	singleton.MoveToButton(goToTitle)
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
	gameScene.currentLayer.show()
	inOption = false
	singleton.MoveToButton(options)
#endregion
#-------------------------------------------------------------------------------
#region IDIOME FUNCTIONS
func SetIdiome():
	title.text = tr("pauseMenu_title")
	continuar.text = tr("pauseMenu_button0")
	retry.text = tr("pauseMenu_button1")
	options.text = tr("pauseMenu_button2")
	goToTitle.text = tr("pauseMenu_button3")
	quitGame.text = tr("pauseMenu_button4")
#endregion
