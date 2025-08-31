extends Control
class_name Dialogue_Menu
#region VARIABLES
var singleton: Singleton
#-------------------------------------------------------------------------------
@export var gameScene: Game_Scene
@export var dialogueLabel: RichTextLabel
#-------------------------------------------------------------------------------
@export var speaker1: Control
@export var speaker1_Texture: TextureRect
#-------------------------------------------------------------------------------
@export var speaker2: Control
@export var speaker2_Texture: TextureRect
#-------------------------------------------------------------------------------
var dialogue_id: String
var dialogue_index: int
#-------------------------------------------------------------------------------
signal dialogueNext_signal
#endregion
#-------------------------------------------------------------------------------
func Start():
	singleton = get_node("/root/singleton")
	hide()
#-------------------------------------------------------------------------------
#region FUNCTIONS
func OpenDialogue():
	show()
#-------------------------------------------------------------------------------
func ReadLine(_showSpeaker1:bool, _showSpeaker2:bool):
	#-------------------------------------------------------------------------------
	if(_showSpeaker1):
		speaker1_Texture.self_modulate = Color.WHITE
	#-------------------------------------------------------------------------------
	else:
		speaker1_Texture.self_modulate = Color.DIM_GRAY
	#-------------------------------------------------------------------------------
	if(_showSpeaker2):
		speaker2_Texture.self_modulate = Color.WHITE
	#-------------------------------------------------------------------------------
	else:
		speaker2_Texture.self_modulate = Color.DIM_GRAY
	#-------------------------------------------------------------------------------
	dialogueLabel.text = tr(dialogue_id+str(dialogue_index))
	#-------------------------------------------------------------------------------
	await dialogueNext_signal
	#-------------------------------------------------------------------------------
	dialogue_index += 1
#-------------------------------------------------------------------------------
func GetSubBossDialogueID(_i:int) -> String:
	var _s: String = "sub_boss_"+str(_i)+"_dialogue_line_"
	return _s
#-------------------------------------------------------------------------------
func GetBossDialogueID(_i:int) -> String:
	var _s: String = "boss_"+str(_i)+"_dialogue_line_"
	return _s
#-------------------------------------------------------------------------------
func CloseDialogue():
	hide()
#endregion
#-------------------------------------------------------------------------------
