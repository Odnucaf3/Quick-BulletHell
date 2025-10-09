extends Node
class_name Singleton
#-------------------------------------------------------------------------------
enum STAGE_STATE{DISABLED, ENABLED, COMPLETED}
enum DIFFICULTY{EASY, NORMAL, HARD, LUNATIC}
enum STAGE{STAGE_1, STAGE_2, STAGE_3, STAGE_4, STAGE_5, STAGE_6, STAGE_7, ROGUELIKE_MODE, BOSSRUSH_MODE}
#region VARIABLES
#-------------------------------------------------------------------------------
@export var optionMenu: Option_Menu
#-------------------------------------------------------------------------------
@export_group("Audio and SFXs")
@export var sfx_Selected : AudioStreamPlayer
@export var sfx_Submited : AudioStreamPlayer
@export var sfx_Canceled : AudioStreamPlayer
@export var bgmPlayer : AudioStreamPlayer
var playPosition: float = 0.0
@export var bgmStage1 : AudioStreamOggVorbis
@export var bgmStage1_mp3 : AudioStreamMP3
@export var bgmBoss1 : AudioStreamOggVorbis
@export var bgmBoss1_mp3 : AudioStreamMP3
@export var bgmTitle : AudioStreamOggVorbis
@export var bgmTitle_mp3 : AudioStreamMP3
#-------------------------------------------------------------------------------
const submitInput: String = "ui_accept"
const cancelInput: String = "ui_cancel"
#-------------------------------------------------------------------------------
const saveData_name : String = "Save"
const saveData_path : String = "user://Save/"
var currentSaveData_Json: Dictionary;
#-------------------------------------------------------------------------------
@export var playerResource: Array[PlayerResource]
var mySTAGE: STAGE
var myDIFFICULTY: DIFFICULTY
#-------------------------------------------------------------------------------
var currentFocus: Control
#-------------------------------------------------------------------------------
const titleScene_Path: StringName = "res://Nodes/Scenes/title_scene.tscn"
const mainScene_Path: StringName = "res://Nodes/Scenes/main_scene.tscn"
const gameScene_Path: StringName = "res://Nodes/Scenes/game_scene.tscn"
#-------------------------------------------------------------------------------
@export var fps: Label
#-------------------------------------------------------------------------------
var maxSave: int = 9
var maxPlayer: int = 0
@export var useCustomButton: bool = true
#endregion
#-------------------------------------------------------------------------------
#region MONOBEHAVIOUR
func _ready():
	optionMenu.Start()
#-------------------------------------------------------------------------------
func _process(_delta:float):
	#Set_FullScreen()
	#Set_Vsync()
	#Set_MouseMode()
	#ResetGame()
	fps.text = PlayerInfo()
#endregion
#-------------------------------------------------------------------------------
#region PLAYER DATA SAVE SYSTEM
#-------------------------------------------------------------------------------
func SaveCurrent_SaveData_Json():
	Save_SaveData_Json(optionMenu.optionSaveData_Json["saveIndex"])
#-------------------------------------------------------------------------------
func Save_SaveData_Json(_index:int):
	DirAccess.make_dir_absolute(saveData_path)
	var _jsonString :String = JSON.stringify(currentSaveData_Json)
	var _jsonFile: FileAccess = FileAccess.open(Get_SaveDataPath_Json(_index),FileAccess.WRITE)
	_jsonFile.store_line(_jsonString)
	_jsonFile.close()
#-------------------------------------------------------------------------------
func Delete_SaveData_Json(_i:int) -> void:
	var _path: String = Get_SaveDataPath_Json(_i)
	if(ResourceLoader.exists(_path)):
		DirAccess.remove_absolute(_path)
#-------------------------------------------------------------------------------
func Load_SaveData_Json(_i:int) -> Dictionary:
	var _path: String = Get_SaveDataPath_Json(_i)
	#-------------------------------------------------------------------------------
	if(ResourceLoader.exists(_path)):
		var _jsonFile: FileAccess = FileAccess.open(_path, FileAccess.READ)
		var _jsonString: String = _jsonFile.get_as_text()
		_jsonFile.close()
		var _saveData: Dictionary = JSON.parse_string(_jsonString)
		return _saveData
	#-------------------------------------------------------------------------------
	else:
		return CreateNew_SaveData_Json()
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func CreateNew_SaveData_Json() -> Dictionary:
	var _saveData: Dictionary = {}
	_saveData["playerIndex"] = int(0)
	_saveData["difficultyIndex"] = int(0)
	_saveData["stageIndex"] = int(0)
	var _playerData: Dictionary
	#-------------------------------------------------------------------------------
	for _i in playerResource.size():
		var _difficultyData: Dictionary
		#-------------------------------------------------------------------------------
		for _j in DIFFICULTY.size():
			var _stageData: Dictionary
			#-------------------------------------------------------------------------------
			for _k in STAGE.size():
				#Aqui viene toda la data de cada nivel.
				var _clearData: Dictionary
				_clearData["value"] = STAGE_STATE.DISABLED
				_stageData[str(_k)] = _clearData
			#-------------------------------------------------------------------------------
			_stageData["0"]["value"] = STAGE_STATE.ENABLED
			_difficultyData[str(_j)] = _stageData
		#-------------------------------------------------------------------------------
		_playerData[str(_i)] = _difficultyData
	#-------------------------------------------------------------------------------
	_saveData["saveData"] = _playerData
	#-------------------------------------------------------------------------------
	return _saveData
#-------------------------------------------------------------------------------
func Get_SaveDataPath_Json(_i:int) -> String:
	var _path: String = saveData_path+saveData_name+str(_i)+".json"
	return _path
#-------------------------------------------------------------------------------
func Copy_CurrentPlayer() -> PlayerResource:
	var _i: int = currentSaveData_Json["playerIndex"]
	var _new_playerResource: PlayerResource = playerResource[_i].duplicate(true)
	return _new_playerResource
#endregion
#-------------------------------------------------------------------------------
#region UI FUNCTIONS
func PlayerInfo() -> String:
	var _s: String = ""
	_s += str(Engine.get_frames_per_second()) + " fps."
	return _s
#endregion
#-------------------------------------------------------------------------------
#region SET THE BUTTONS SIGNALS
func SetButton(_b:Button, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	if(useCustomButton):
		SetButton_New(_b, _selected, _submited, _canceled)
	else:
		SetButton_Old(_b, _selected, _submited, _canceled)
#-------------------------------------------------------------------------------
func SetButton_New(_b:Button, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_b.focus_entered.connect(_selected)
	_b.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
			elif(_event.is_action_pressed(submitInput)):
				currentFocus = _b
				await _b.pressed
				_submited.call()
			elif(_event is InputEventMouseButton):
				await _b.pressed
				if(_event.button_index==1 and _event.is_pressed()):
					if(currentFocus == _b):
						_submited.call()
					else:
						currentFocus = _b
	)
#-------------------------------------------------------------------------------
func SetButton_Old(_b:Button, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_b.focus_entered.connect(_selected)
	_b.pressed.connect(_submited)
	_b.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func DisconnectButton(_b:Button) -> void:
	if(useCustomButton):
		DisconnectButton_New(_b)
	else:
		DisconnectButton_Old(_b)
#-------------------------------------------------------------------------------
func DisconnectButton_New(_b:Button) -> void:
	DisconnectAll(_b.focus_entered)
	DisconnectAll(_b.gui_input)
#-------------------------------------------------------------------------------
func DisconnectButton_Old(_b:Button) -> void:
	DisconnectAll(_b.focus_entered)
	DisconnectAll(_b.pressed)
	DisconnectAll(_b.gui_input)
#-------------------------------------------------------------------------------
func DisconnectAll(_signal:Signal):
	var _dictionaryArray : Array = _signal.get_connections()
	for _dictionary in _dictionaryArray:
		_signal.disconnect(_dictionary["callable"])
#-------------------------------------------------------------------------------
func SetOptionButtons(_ob:OptionButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	if(useCustomButton):
		SetOptionButtons_New(_ob, _selected, _submited, _canceled)
	else:
		SetOptionButtons_Old(_ob, _selected, _submited, _canceled)
#-------------------------------------------------------------------------------
func SetOptionButtons_New(_ob:OptionButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_ob.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_ob.focus_entered.connect(
		func():
			currentFocus = _ob
			_selected.call()
	)
	_ob.item_selected.connect(_submited)
	_ob.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func SetOptionButtons_Old(_ob:OptionButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_ob.focus_entered.connect(_selected)
	_ob.item_selected.connect(_submited)
	_ob.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func OptionButtons_AddSubmited(_ob:OptionButton, _submited:Callable):
	_ob.item_selected.connect(_submited)
#-------------------------------------------------------------------------------
func SetCheckButton(_cb:CheckButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	if(useCustomButton):
		SetCheckButton_New(_cb, _selected, _submited, _canceled)
	else:
		SetCheckButton_Old(_cb, _selected, _submited, _canceled)
#-------------------------------------------------------------------------------
func SetCheckButton_New(_cb:CheckButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_cb.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_cb.focus_entered.connect(
		func():
			currentFocus = _cb
			_selected.call()
	)
	_cb.toggled.connect(_submited)
	_cb.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func SetCheckButton_Old(_cb:CheckButton, _selected:Callable, _submited:Callable, _canceled:Callable) -> void:
	_cb.focus_entered.connect(_selected)
	_cb.toggled.connect(_submited)
	_cb.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func SetSlider(_sl:Slider,  _selected:Callable,  _submited:Callable,  _canceled:Callable) -> void:
	if(useCustomButton):
		SetSlider_New(_sl,  _selected,  _submited,  _canceled)
	else:
		SetSlider_Old(_sl,  _selected,  _submited,  _canceled)
#-------------------------------------------------------------------------------
func SetSlider_New(_sl:Slider,  _selected:Callable,  _submited:Callable,  _canceled:Callable) -> void:
	_sl.focus_entered.connect(
		func():
			currentFocus = _sl
			_selected.call()
	)
	_sl.value_changed.connect(_submited)
	_sl.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#-------------------------------------------------------------------------------
func SetSlider_Old(_sl:Slider,  _selected:Callable,  _submited:Callable,  _canceled:Callable) -> void:
	_sl.focus_entered.connect(_selected)
	_sl.value_changed.connect(_submited)
	_sl.gui_input.connect(
		func(_event:InputEvent):
			if(_event.is_action_pressed(cancelInput)):
				_canceled.call()
	)
#endregion
#-------------------------------------------------------------------------------
#region UI COMMON FUNCTIONALITY
func MoveToButton(_b:Button) -> void:
	currentFocus = _b
	_b.grab_focus()
#-------------------------------------------------------------------------------
func MoveToLastButton(_b:Array[Button]) -> void:
	MoveToButton(_b[_b.size()-1])
#-------------------------------------------------------------------------------
func MoveToFirstButton(_b:Array[Button]) -> void:
	MoveToButton(_b[0])
#-------------------------------------------------------------------------------
func PlayBGM_OGG(_bgm:AudioStreamOggVorbis) -> void:
	bgmPlayer.stream = _bgm
	bgmPlayer.play()
#-------------------------------------------------------------------------------
func PlayBGM_MP3(_bgm:AudioStreamMP3) -> void:
	bgmPlayer.stream = _bgm
	bgmPlayer.play()
#-------------------------------------------------------------------------------
func CommonSelected() -> void:
	sfx_Selected.play()
#-------------------------------------------------------------------------------
func CommonSubmited() -> void:
	sfx_Submited.play()
#-------------------------------------------------------------------------------
func CommonCanceled() -> void:
	sfx_Canceled.play()
#endregion
#-------------------------------------------------------------------------------
#region DEBUG INPUTS
func Set_FullScreen() -> void:
	if(Input.is_action_just_pressed("debug_Fullscreen")):
		var _wm: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if(_wm == DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#-------------------------------------------------------------------------------
func Set_Vsync() -> void:
	if(Input.is_action_just_pressed("debug_Vsync")):
		var _vs: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
		if(_vs == DisplayServer.VSYNC_DISABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		elif(_vs == DisplayServer.VSYNC_ENABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#-------------------------------------------------------------------------------
func Set_MouseMode() -> void:
	if(Input.is_action_just_pressed("debug_MouseMode")):
		var _mm: Input.MouseMode = Input.mouse_mode
		if(_mm == Input.MOUSE_MODE_VISIBLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif(_mm == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#-------------------------------------------------------------------------------
func ResetGame() -> void:
	if(Input.is_action_just_pressed("debug_Reset")):
		get_tree().reload_current_scene()
#endregion
#-------------------------------------------------------------------------------
