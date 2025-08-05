extends Control
class_name Dialogue_Menu
#region VARIABLES
var singleton: Singleton
#-------------------------------------------------------------------------------
@export var gameScene: Game_Scene
@export var dialogueLabel: RichTextLabel
@export var speaker1: Control
@export var speaker2: Control
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
func ReadDialogue(_s:String, _start:int, _end:int):
	for _i in range(_start, _end):
		dialogueLabel.text = tr(_s+str(_i))
		await dialogueNext_signal
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
