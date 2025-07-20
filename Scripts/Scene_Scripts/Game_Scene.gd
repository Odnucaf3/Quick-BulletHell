extends Node
class_name Game_Scene
#-------------------------------------------------------------------------------
enum GAME_STATE{IN_GAMEPLAY, IN_MARKET, IN_DIALOGUE, IN_GAMEOVER}
#region VARIABLES
var singleton: Singleton
#-------------------------------------------------------------------------------
var myGAME_STATE: GAME_STATE = GAME_STATE.IN_GAMEPLAY
var inPause: bool = false
#-------------------------------------------------------------------------------
@export var currentLayer: CanvasLayer
@export var pauseMenu: Pause_Menu
@export var gameoverMenu: GameOver_Menu
@export var marketMenu: Market_Menu
@export var dialogueMenu: Dialogue_Menu
#-------------------------------------------------------------------------------
@export var timerLabel: Label
var timer: int
var difficulty: float
@export var content: Control
@export var player: Player
var isFocus: bool = false
var cardInventory: Dictionary[CardResource, int]
#-------------------------------------------------------------------------------
@export var enemy_Prefab: PackedScene
@export var boss_Prefab: PackedScene
@export var bullet_Prefab: PackedScene
@export var item_Prefab: PackedScene
#-------------------------------------------------------------------------------
var bulletDictionary: Dictionary[String, BulletResource]
@export var bulletDictionary_Path: String = "res://Resources/Bullets/"
#-------------------------------------------------------------------------------
@export var difficultyLabel: Label
@export var maxScoreLabel_title: RichTextLabel
@export var maxScoreLabel_Num: RichTextLabel
@export var scoreLabel_title: RichTextLabel
@export var scoreLabel_Num: RichTextLabel
@export var powerLabel_title: RichTextLabel
@export var powerLabel_Num: RichTextLabel
@export var livesLabel_title: RichTextLabel
@export var livesLabel_Num: RichTextLabel
@export var moneyLabel_title: RichTextLabel
@export var moneyLabel_Num: RichTextLabel
@export var maxMoneyLabel_Num: RichTextLabel
@export var leftLabel: RichTextLabel
#-------------------------------------------------------------------------------
@export var completedPanel: PanelContainer
@export var completedLabel: Label
#-------------------------------------------------------------------------------
var enemyBullets_Enabled_Array: Array[Bullet]
var enemyBullets_Disabled_Array: Array[Bullet]
#-------------------------------------------------------------------------------
var enemy_Enabled_Array: Array[Enemy]
var enemy_Disabled_Array: Array[Enemy]
#-------------------------------------------------------------------------------
var boss_Enabled_Array: Array[Boss]
var boss_Disabled_Array: Array[Boss]
#-------------------------------------------------------------------------------
var playerBullets_Enabled_Array: Array[Bullet]
var playerBullets_Disabled_Array: Array[Bullet]
#-------------------------------------------------------------------------------
var items_Enabled_Array: Array[Item]
var items_Disabled_Array: Array[Item]
#-------------------------------------------------------------------------------
var tween_Array: Array[Tween]
#-------------------------------------------------------------------------------
var height: float
var width: float
#-------------------------------------------------------------------------------
var playerLimitsX: Vector2
var playerLimitsY: Vector2
#-------------------------------------------------------------------------------
var enemyLimitsX: Vector2
var enemyLimitsY: Vector2
#-------------------------------------------------------------------------------
var bossStartingPosition: Vector2
#-------------------------------------------------------------------------------
var lifePoints: int
var powerPoints: int
var moneyPoints: int
var scorePoints: int
#-------------------------------------------------------------------------------
var deltaTimeScale: float = 1
#-------------------------------------------------------------------------------
var timer_tween: Tween
var main_tween_Array: Array[Tween]
#-------------------------------------------------------------------------------
var player_invincible_counter: float = 0
var player_invincible_bool: bool
var player_shoot_counter: float = 0
#-------------------------------------------------------------------------------
var hitBox_radius: float = 8.0
var grazeBox_radius: float = 34.0
var magnetBox_radius: float = 98.0
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready():
	singleton = get_node("/root/singleton")
	#-------------------------------------------------------------------------------
	pauseMenu.Start()
	gameoverMenu.Start()
	marketMenu.Start()
	dialogueMenu.Start()
	#-------------------------------------------------------------------------------
	SetIdiome()
	#-------------------------------------------------------------------------------
	singleton.PlayBGM(singleton.bgmStage1)
	get_tree().set_deferred("paused", false)
	currentLayer.show()
	#-------------------------------------------------------------------------------
	await BeginGame()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	deltaTimeScale = Engine.time_scale
	tween_Array = get_tree().get_processed_tweens()
	Debug_Information()
	#-------------------------------------------------------------------------------
	for _i in range(enemyBullets_Enabled_Array.size()-1,-1,-1):
		enemyBullets_Enabled_Array[_i].physics_Update.call()
	#-------------------------------------------------------------------------------
	for _i in range(enemy_Enabled_Array.size()-1,-1,-1):
		enemy_Enabled_Array[_i].physics_Update.call()
	#-------------------------------------------------------------------------------
	for _i in range(boss_Enabled_Array.size()-1,-1,-1):
		boss_Enabled_Array[_i].physics_Update.call()
	#-------------------------------------------------------------------------------
	for _i in range(playerBullets_Enabled_Array.size()-1,-1,-1):
		playerBullets_Enabled_Array[_i].physics_Update.call()
	#-------------------------------------------------------------------------------
	for _i in range(items_Enabled_Array.size()-1,-1,-1):
		items_Enabled_Array[_i].physics_Update.call()
	#-------------------------------------------------------------------------------
	Game_StateMachine()
#endregion
#-------------------------------------------------------------------------------
#region STATE-MACHINE FUNCTIONS
func Game_StateMachine():
	player.hitBox_Sprite.rotate(0.05*deltaTimeScale)
	#-------------------------------------------------------------------------------
	match(myGAME_STATE):
		GAME_STATE.IN_GAMEPLAY:
			PlayerShoot()
			Player_StateMachine()
			PauseGame()
			return
		#-------------------------------------------------------------------------------
		GAME_STATE.IN_MARKET:
			match(player.myPLAYER_STATE):
				Player.PLAYER_STATE.ALIVE:
					pass
				#-------------------------------------------------------------------------------
				Player.PLAYER_STATE.DEATH:
					Player_StateMachine_Death()
				#-------------------------------------------------------------------------------
				Player.PLAYER_STATE.INVINCIBLE:
					Player_StateMachine_Invincible()
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		GAME_STATE.IN_DIALOGUE:
			Player_StateMachine()
			if(Input.is_action_just_pressed("input_Shoot")):
				dialogueMenu.dialogueNext_signal.emit()
		#-------------------------------------------------------------------------------
		GAME_STATE.IN_GAMEOVER:
			pass
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_StateMachine():
	match(player.myPLAYER_STATE):
		Player.PLAYER_STATE.ALIVE:
			Player_Movement()
		#-------------------------------------------------------------------------------
		Player.PLAYER_STATE.DEATH:
			Player_StateMachine_Death()
		#-------------------------------------------------------------------------------
		Player.PLAYER_STATE.INVINCIBLE:
			Player_StateMachine_Invincible()
			Player_Movement()
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_StateMachine_Death():
	player_invincible_counter += deltaTimeScale
	#-------------------------------------------------------------------------------
	if(player_invincible_counter > 2.0):
		if(player_invincible_bool):
			player.sprite.hide()
			player.magnetBox_Sprite.hide()
			player.grazeBox_Sprite.hide()
			player.hitBox_Sprite.hide()
			player_invincible_bool = false
		#-------------------------------------------------------------------------------
		else:
			player.sprite.show()
			player.magnetBox_Sprite.show()
			player.grazeBox_Sprite.show()
			player.hitBox_Sprite.show()
			player_invincible_bool = true
		#-------------------------------------------------------------------------------
		player_invincible_counter = 0.0
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_StateMachine_Invincible():
	player_invincible_counter += deltaTimeScale
	#-------------------------------------------------------------------------------
	if(player_invincible_counter > 2.0):
		if(player_invincible_bool):
			player.sprite.hide()
			player.grazeBox_Sprite.hide()
			player.hitBox_Sprite.hide()
			player_invincible_bool = false
		#-------------------------------------------------------------------------------
		else:
			player.sprite.show()
			player.grazeBox_Sprite.show()
			player.hitBox_Sprite.show()
			player_invincible_bool = true
		#-------------------------------------------------------------------------------
		player_invincible_counter = 0.0
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_Movement() -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#-------------------------------------------------------------------------------
	if(isFocus):
		if(!Input.is_action_pressed("input_Focus")):
			player.grazeBox_Sprite.hide()
			player.hitBox_Sprite.hide()
			isFocus = false
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	else:
		if(Input.is_action_pressed("input_Focus")):
			player.grazeBox_Sprite.show()
			player.hitBox_Sprite.show()
			isFocus = true
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	Player_Animation(input_dir.x)
	#-------------------------------------------------------------------------------
	if(input_dir != Vector2.ZERO):
		input_dir.normalized()
		var myPosition: Vector2 = player.position
		#-------------------------------------------------------------------------------
		if(isFocus):
			myPosition += input_dir * player.playerResource.focusSpeed * deltaTimeScale
		#-------------------------------------------------------------------------------
		else:
			myPosition += input_dir * player.playerResource.normalSpeed * deltaTimeScale
		#-------------------------------------------------------------------------------
		myPosition.x = clampf(myPosition.x, playerLimitsX.x, playerLimitsX.y)
		myPosition.y = clampf(myPosition.y, playerLimitsY.x, playerLimitsY.y)
		player.position = myPosition
	#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region PAUSE INPUTS
func PauseGame() -> void:
	if(myGAME_STATE == GAME_STATE.IN_GAMEOVER):
		return
	#-------------------------------------------------------------------------------
	if(Input.is_action_just_pressed("input_Pause")):
		pauseMenu.show()
		StopTime()
		singleton.MoveToButton(pauseMenu.continuar)
#-------------------------------------------------------------------------------
func StopTime():
	singleton.playPosition = singleton.bgmPlayer.get_playback_position()
	singleton.bgmPlayer.stop()
	get_tree().set_deferred("paused", true)
#-------------------------------------------------------------------------------
func PauseOff():
	pauseMenu.hide()
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
	get_tree().set_deferred("paused", false)
	singleton.bgmPlayer.play(singleton.playPosition)
#endregion
#-------------------------------------------------------------------------------
#region UI FINCTIONS
func SetGameLimits() -> void:
	await content.resized
	#-------------------------------------------------------------------------------
	height = content.size.y
	width = content.size.x
	#-------------------------------------------------------------------------------
	var _offSet: float = 10
	playerLimitsX = Vector2(_offSet, width-_offSet)
	playerLimitsY = Vector2(_offSet, height-_offSet)
	#-------------------------------------------------------------------------------
	enemyLimitsX = Vector2(0, width)
	enemyLimitsY = Vector2(0, height)
	#-------------------------------------------------------------------------------
	bossStartingPosition = Vector2(width*0.5, height*0.25)
#-------------------------------------------------------------------------------
func Debug_Information() -> void:
	var _s: String = ""
	_s += "-------------------------------------------------------\n"
	_s += str(Engine.get_frames_per_second()) + " fps.\n"
	_s += "Tweens: "+str(tween_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "Enemy Bullets Enabled: " + str(enemyBullets_Enabled_Array.size())+"\n"
	_s += "Enemy Bullets Disabled: " + str(enemyBullets_Disabled_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "Enemy Enabled: " + str(enemy_Enabled_Array.size())+"\n"
	_s += "Enemy Disabled: " + str(enemy_Disabled_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "Boss Enabled: " + str(boss_Enabled_Array.size())+"\n"
	_s += "Boss Disabled: " + str(boss_Disabled_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "Player Bullets Enabled: " + str(playerBullets_Enabled_Array.size())+"\n"
	_s += "Player Bullets Disabled: " + str(playerBullets_Disabled_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "Items Enabled: " + str(items_Enabled_Array.size())+"\n"
	_s += "Items Disabled: " + str(items_Disabled_Array.size())+"\n"
	_s += "-------------------------------------------------------\n"
	_s += "GAME_STATE." + GAME_STATE.keys()[myGAME_STATE]+"\n"
	_s += "PLAYER_STATE." + Player.PLAYER_STATE.keys()[player.myPLAYER_STATE]+"\n"
	_s += "-------------------------------------------------------\n"
	leftLabel.text = _s
#-------------------------------------------------------------------------------
func SetScore() -> void:
	var _s: String = str(scorePoints).pad_zeros(9)
	_s = _s.insert(_s.length()-3,",")
	_s = _s.insert(_s.length()-7,",")
	scoreLabel_Num.text = "[center]"+_s+"[/center]"
#-------------------------------------------------------------------------------
func SetInfoText_Life() -> void:
	livesLabel_Num.text = GetInfoText_LifePower(lifePoints, player.playerResource.maxLives)
#-------------------------------------------------------------------------------
func SetInfoText_Power() -> void:
	powerLabel_Num.text = GetInfoText_LifePower(powerPoints, player.playerResource.maxPower)
#-------------------------------------------------------------------------------
func GetInfoText_LifePower(_point:int, _maxPoint:int) -> String:
	var _s: String = "[center]"+str(_point).pad_zeros(2)+" / "+str(_maxPoint).pad_zeros(2)+"[/center]"
	return _s
#-------------------------------------------------------------------------------
func SetInfoText_Death():
	livesLabel_Num.text = "[center]"+"  --"+" / "+str(player.playerResource.maxLives).pad_zeros(2)+"[/center]"
#-------------------------------------------------------------------------------
func SetMoney() -> void:
	moneyLabel_Num.text = "[center]"+str(moneyPoints)+" G[/center]"
	#-------------------------------------------------------------------------------
func SetMaxMoney() -> void:
	maxMoneyLabel_Num.text = "[center]"+str(player.playerResource.maxMoney)+" G[/center]"
#endregion
#-------------------------------------------------------------------------------
#region START FUNCTIONS
func BeginGame() -> void:
	var _difficulty: int = singleton.currentSaveData_Json.get("difficultyIndex", 0)
	difficulty = float(_difficulty)
	difficultyLabel.text = tr("difficultyMenu_button"+str(_difficulty))
	#-------------------------------------------------------------------------------
	await SetGameLimits()
	player.SetPlayer(singleton.Copy_CurrentPlayer())
	player.grazeBox_Sprite.hide()
	player.hitBox_Sprite.hide()
	player.playback = player.animationTree.get("parameters/playback")
	player.playback.travel("Idle")
	player.myMOVING_STATE = Player.MOVING_STATE.IDLE
	#-------------------------------------------------------------------------------
	SetScore()
	SetMoney()
	SetMaxMoney()
	lifePoints = int(float(player.playerResource.maxLives)*1)
	SetInfoText_Life()
	powerPoints = int(float(player.playerResource.maxPower)*1)
	SetInfoText_Power()
	#-------------------------------------------------------------------------------
	completedPanel.hide()
	completedLabel.text = ""
	timerLabel.text = ""
	#-------------------------------------------------------------------------------
	player.position = Vector2(width*0.5, height*0.85)
	player.myPLAYER_STATE = Player.PLAYER_STATE.ALIVE
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
	cardInventory = {}
	#-------------------------------------------------------------------------------
	Create_Boss_Disabled(1)
	Create_Enemy_Disabled(1)
	Create_EnemyBullets_Disabled(2000)
	Create_Items_Disabled(500)
	Create_PlayerBullets_Disabled(50)
	#-------------------------------------------------------------------------------
	LoadBulletDatabase()
	Enter_GameState_InGameplay()
	Choreography()
#-------------------------------------------------------------------------------
func LoadBulletDatabase():
	bulletDictionary.clear()
	#-------------------------------------------------------------------------------
	var dir_array = DirAccess.get_files_at(bulletDictionary_Path)
	if(dir_array):
		for _i in dir_array.size():
			var _base_name: String = dir_array[_i].get_slice(".",0)
			var _bulletResource: BulletResource = load(bulletDictionary_Path+"/"+_base_name+".tres") as BulletResource
			bulletDictionary[_base_name] = _bulletResource
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region COMMON STAGE FUNCTIONS 
func Choreography():
	match(singleton.currentSaveData_Json["stageIndex"]):
		singleton.STAGE.STAGE_1:
			await Stage1()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_2:
			await Stage2()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_3:
			await Stage3()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_4:
			await Stage4()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_5:
			await Stage5()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_6:
			await Stage6()
		#-------------------------------------------------------------------------------
		singleton.STAGE.STAGE_7:
			await Stage7()
		#-------------------------------------------------------------------------------
		singleton.STAGE.ROGUELIKE_MODE:
			await Stage_RougeLike()
		#-------------------------------------------------------------------------------
		singleton.STAGE.BOSSRUSH_MODE:
			await Stage_BossRish()
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyWave_and_Market(_s:String, _callable:Callable, _timer: int):
	await ShowBanner(_s)
	_callable.call()
	await TimeOut_Tween(_timer)
	await Nothing_and_Market()
#-------------------------------------------------------------------------------
func Nothing_and_Market():
	await OpenMarket()
	Enter_GameState_InGameplay()
#-------------------------------------------------------------------------------
func OpenMarket():
	await ShowBanner2("Flea Market has being Open")
	myGAME_STATE = GAME_STATE.IN_MARKET
	await marketMenu.OpenMarket()
#-------------------------------------------------------------------------------
func Dialogue(_bossID:int, _from:int, _to:int):
	var _bossDialogueID: String = dialogueMenu.GetSubBossDialogueID(_bossID)
	await dialogueMenu.ReadDialogue(_bossDialogueID, _from, _to)
#-------------------------------------------------------------------------------
func Enter_GameState_InGameplay():
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
#-------------------------------------------------------------------------------
func StageCommon(_s:String, _enabled:int, _completed:int):
	await ShowBanner(_s)
	EnableStage(_enabled)
	CompletedStage(_completed)
	singleton.Save_SaveData_Json(singleton.optionMenu.optionSaveData_Json["saveIndex"])
	singleton.CommonSubmited()
	GoToMainScene()
#-------------------------------------------------------------------------------
func ShowBanner(_s:String, _timer:float = 1.0):
	await Seconds(_timer)
	await ShowBanner2(_s)
#-------------------------------------------------------------------------------
func ShowBanner2(_s:String):
	Banner_Open(_s)
	await Seconds(2.0)
	Banner_Close()
#-------------------------------------------------------------------------------
func Banner_Open(_s:String):
	completedPanel.show()
	completedLabel.text = _s
#-------------------------------------------------------------------------------
func Banner_Close():
	completedPanel.hide()
	completedLabel.text = ""
#-------------------------------------------------------------------------------
func EnableStage(_i:int):
	var _playerIndex: StringName = str(int(singleton.currentSaveData_Json["playerIndex"]))
	var _difficultyIndex: StringName = str(int(singleton.currentSaveData_Json["difficultyIndex"]))
	if(singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] == singleton.STAGE_STATE.DISABLED):
		singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] = singleton.STAGE_STATE.ENABLED
#-------------------------------------------------------------------------------
func CompletedStage(_i:int):
	var _playerIndex: StringName = str(int(singleton.currentSaveData_Json["playerIndex"]))
	var _difficultyIndex: StringName = str(int(singleton.currentSaveData_Json["difficultyIndex"]))
	singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] = singleton.STAGE_STATE.COMPLETED
#-------------------------------------------------------------------------------
func GoToMainScene():
	singleton.PlayBGM(singleton.bgmTitle)
	get_tree().set_deferred("paused", false)
	get_tree().change_scene_to_file(singleton.mainScene_Path)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 1 FUNCTIONS
func Stage1():
	await EnemyWave_and_Market("Enemy-Wave 1", func():Stage1_EnemyWave1(), 20)
	await EnemyWave_and_Market("Enemy-Wave 2", func():InfiniteEnemyTest(), 10)
	#-------------------------------------------------------------------------------
	#await Nothing_and_Market()
	await ShowBanner("Enter Boss")	#IMPORTANTE: Tiene que haber un await antres de entrar al dialogo porque si no se saltea la primer liena.
	myGAME_STATE = GAME_STATE.IN_DIALOGUE
	dialogueMenu.OpenDialogue()
	#-------------------------------------------------------------------------------
	await Dialogue(0, 0, 4)
	#-------------------------------------------------------------------------------
	var _boss: Boss = Create_Boss(0,0, 100)
	var _tween: Tween = create_tween()
	_tween.tween_property(_boss, "position", Vector2(width*0.5, height*0.2), 0.5)
	await _tween.finished
	#-------------------------------------------------------------------------------
	await Dialogue(0, 4, 8)
	#-------------------------------------------------------------------------------
	dialogueMenu.CloseDialogue()
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
	#-------------------------------------------------------------------------------
	await EnemyWave_and_Market("Spell-Card 1", func():Create_SpellCard(_boss), 60)
	await StageCommon("Stage 1 Completed",1,0)
#-------------------------------------------------------------------------------
func InfiniteEnemyTest():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(main_tween_Array)
		_tween2.set_loops()
		InfiniteEnemyTest_Tween(_tween2, 1)
		InfiniteEnemyTest_Tween(_tween2, -1)
	)
#-------------------------------------------------------------------------------
func InfiniteEnemyTest_Tween(_tween:Tween, _mirror:float):
	_tween.tween_callback(func():
		InfiniteEnemyTest_Enemy(_tween, _mirror)
		_tween.pause()
	)
#-------------------------------------------------------------------------------
func InfiniteEnemyTest_Enemy(_tween:Tween, _mirror:float):
	var _x: float = width*0.5+width*0.25*_mirror
	var _enemy: Enemy = Create_Enemy(_x, 0, 0, 0, 10)
	#-------------------------------------------------------------------------------
	_enemy.death_signal.connect(
		func(): _tween.play()
	)
	#-------------------------------------------------------------------------------
	var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween2.tween_property(_enemy, "position", Vector2(_x, height*0.3), 1.0)
#-------------------------------------------------------------------------------
func Stage1_EnemyWave1():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Stage1_EnemyWave1_Loop1()
	)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_EnemyWave1_Loop1():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_EnemyWave1_Tween(_tween, 1)
	_tween.tween_interval(1)
	Stage1_EnemyWave1_Tween(_tween, -1)
	_tween.tween_interval(1)
#-------------------------------------------------------------------------------
func Stage1_EnemyWave1_Tween(_tween:Tween, _mirror: float):
	for _i in 8:
		for _j in 1:
			var _x: float = width * 0.5 - width*(0.6 + 0.1 * _j) *_mirror
			var _y: float = -height * (0.2 - 0.1 * _j)
			_tween.tween_callback(func():
				Stage1_EnemyWave1_Enemy1(_x, _y, _mirror)
			)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.8)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_EnemyWave1_Enemy1(_x:float, _y:float, _mirror:float):
	var _enemy: Enemy = Create_Enemy(_x, _y, 4.0, 90-20*_mirror, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		_tween2.tween_interval(1.5)
		Stage1_EnemyWave1_Enemy1_Fire1(_tween2, _enemy)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(0.5)
	_tween.tween_property(_enemy,"dir",90-90*_mirror, 2.0)
	_tween.tween_interval(2.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy(_enemy)
	)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_EnemyWave1_Enemy1_Fire1(_tween:Tween, _node2D: Node2D):
	for _i in 10:
		_tween.tween_callback(func():
			var _dir: float = AngleToPlayer(_node2D)
			var _x:float = _node2D.position.x
			var _y:float = _node2D.position.y
			var _bullet: Bullet = Create_EnemyBullet(_x, _y, 8, _dir, "ArrowHead_Bullet", 3)
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.1)
#-------------------------------------------------------------------------------
func Create_SpellCard(_boss: Boss):
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.tween_interval(2)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(main_tween_Array)
		_tween2.set_loops()
		Create_SpellCard_Tween(_boss, _tween2, 1)
		Create_SpellCard_Tween(_boss, _tween2, -1)
	)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_SpellCard_Tween(_node2d:Node2D, _tween:Tween, _mirror: float):
	var _dir: float
	var _dir2: float = 0.0
	var _max1: float = 10.0*(difficulty+1)
	var _max2: float = 10.0*(difficulty+1)
	var _vel1: float = 4.0
	var _vel2: float = 1.0
	var _dvel: float = (_vel2-_vel1)/_max2
	var _frame: int = 0
	#-------------------------------------------------------------------------------
	for _j in _max2:
		_dir = 0.0
		_frame = int(_j)%16
		for _i in _max1:
			_tween.tween_callback(func():Create_SpellCard_bullet(_node2d, _dir+_dir2*_mirror, _vel1, _frame, _mirror))
			_dir += 360/_max1
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.1)
		_vel1 += _dvel
		_dir2 += 2
	#-------------------------------------------------------------------------------
	_tween.set_parallel(false)
	_tween.tween_interval(4.0)
#-------------------------------------------------------------------------------
func Create_SpellCard_bullet(_node2d:Node2D, _dir:float, _vel:float, _frame:int, _mirror: float):
	var _dir2: float = deg_to_rad(_dir)
	var _x: float = _node2d.position.x + 48 * cos(_dir2)
	var _y: float = _node2d.position.y + 48 * sin(_dir2)
	#-------------------------------------------------------------------------------
	var _bullet: Bullet = Create_EnemyBullet(_x, _y, 4.0, _dir, "Rice_Bullet", _frame)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_bullet.tween_Array)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		_bullet.can_Go_OffLimits = true
	)
	#-------------------------------------------------------------------------------
	_tween.tween_property(_bullet, "vel",0.5, 1.0)
	_tween.parallel().tween_property(_bullet, "dir",_bullet.dir+30*_mirror, 1.0)
	_tween.tween_property(_bullet, "dir",_bullet.dir+165*_mirror, 0.25)
	_tween.tween_property(_bullet, "vel",_vel, 1.0)
	_tween.parallel().tween_property(_bullet, "dir",_bullet.dir+270*_mirror, 3.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		_bullet.can_Go_OffLimits = false
	)
	#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region STAGE 2 FUNCTIONS
func Stage2():
	await StageCommon("Stage 2 Completed",2,1)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 3 FUNCTIONS
func Stage3():
	await StageCommon("Stage 3 Completed",3,2)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 4 FUNCTIONS
func Stage4():
	await StageCommon("Stage 4 Completed",4,3)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 5 FUNCTIONS
func Stage5():
	await StageCommon("Stage 5 Completed",5,4)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 6 FUNCTIONS
func Stage6():
	await StageCommon("Stage 6 Completed",6,5)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 7 FUNCTIONS
func Stage7():
	await StageCommon("Stage 7 Completed",7,6)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 8 FUNCTIONS
func Stage_RougeLike():
	await StageCommon("Stage Rogue-Like Completed",8,7)
#endregion
#-------------------------------------------------------------------------------
#region STAGE 9 FUNCTIONS
func Stage_BossRish():
	await StageCommon("Stage Boss-Rish Completed",8,8)
#endregion
#-------------------------------------------------------------------------------
#region PLAYER FUNCTIONS
func Player_Animation(velX:float):
	#-------------------------------------------------------------------------------
	match(player.myMOVING_STATE):
		Player.MOVING_STATE.IDLE:
			if(velX > 0.6):
				player.myMOVING_STATE = Player.MOVING_STATE.RIGHT
				player.playback.travel("Turning_Right")
				return
			#-------------------------------------------------------------------------------
			elif(velX < -0.6):
				player.myMOVING_STATE = Player.MOVING_STATE.LEFT
				player.playback.travel("Turning_Left")
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Enemy.MOVING_STATE.RIGHT:
			if(velX < 0.3):
				player.myMOVING_STATE = Player.MOVING_STATE.IDLE
				player.playback.travel("Turning_Idle_from_Right")
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Enemy.MOVING_STATE.LEFT:
			if(velX > -0.3):
				player.myMOVING_STATE = Player.MOVING_STATE.IDLE
				player.playback.travel("Turning_Idle_from_Left")
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func PlayerShoot():
	if(Input.is_action_pressed("input_Shoot")):
		player_shoot_counter += deltaTimeScale
		#-------------------------------------------------------------------------------
		if(player_shoot_counter > 5.0):
			player_shoot_counter = 0.0
			Create_PlayerBullet(player.position.x, player.position.y-50, 18.0, -90.0, "ArrowHead_Bullet", 4)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_Shooted():
	player.canBeHit = false
	if(player.myPLAYER_STATE == Player.PLAYER_STATE.ALIVE):
		if(lifePoints > 0):
			PlayerRespawn()
		#-------------------------------------------------------------------------------
		else:
			PlayerGameOver()
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func PlayerRespawn():
	#-------------------------------------------------------------------------------
	var _tween: Tween = create_tween()
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		lifePoints -= 1
		SetInfoText_Life()
		PlayerDeath()
		player.position = Vector2(width*0.5, height*1.2)
	)
	#-------------------------------------------------------------------------------
	#_tween.tween_interval(0.1)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		player.show()
		player.myMOVING_STATE = Player.MOVING_STATE.IDLE
		player.playback.travel("Idle")
	)
	_tween.tween_property(player, "position", Vector2(width*0.5, height*0.8), 1.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		player.myPLAYER_STATE = Player.PLAYER_STATE.INVINCIBLE
		player.magnetBox_Sprite.show()
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(2.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		player.myPLAYER_STATE = Player.PLAYER_STATE.ALIVE
		player.sprite.show()
		player.grazeBox_Sprite.show()
		player.hitBox_Sprite.show()
		player.canBeHit = true
	)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func PlayerGameOver() -> void:
	var _tween: Tween = create_tween()
	#-------------------------------------------------------------------------------
	timer_tween.pause()
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		myGAME_STATE = GAME_STATE.IN_GAMEOVER
		SetInfoText_Death()
		PlayerDeath()
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(2.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		StopTime()
		gameoverMenu.show()
		singleton.MoveToButton(gameoverMenu.retry)
	)
#-------------------------------------------------------------------------------
func PlayerDeath() -> void:
	player.myPLAYER_STATE = Player.PLAYER_STATE.DEATH
	player.hide()
	#-------------------------------------------------------------------------------
	for _i in range(items_Enabled_Array.size()-1,-1,-1):
		if(items_Enabled_Array[_i].myITEM_STATE == Item.ITEM_STATE.IMANTED):
			items_Enabled_Array[_i].velocity.y = -4
			items_Enabled_Array[_i].myITEM_STATE = Item.ITEM_STATE.SPIN
#endregion
#-------------------------------------------------------------------------------
#region PLAYER BULLET FUNCTIONS
func Create_PlayerBullets_Disabled(_iMax:int):
	for _i in _iMax:
		var _bullet: Bullet = bullet_Prefab.instantiate() as Bullet
		playerBullets_Disabled_Array.append(_bullet)
		_bullet.physics_Update = func(): PlayerBullet_PhysicsUpdate(_bullet)
		_bullet.hide()
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_PlayerBullet(_x:float, _y:float, _v:float, _dir:float, _type:String, _frame:int) ->Bullet:
	var _bullet: Bullet
	#-------------------------------------------------------------------------------
	if(playerBullets_Disabled_Array.size() > 0):
		_bullet = playerBullets_Disabled_Array[0]
		_bullet.show()
		playerBullets_Disabled_Array.erase(_bullet)
	#-------------------------------------------------------------------------------
	else:
		_bullet = bullet_Prefab.instantiate() as Bullet
		_bullet.physics_Update = func(): PlayerBullet_PhysicsUpdate(_bullet)
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
	playerBullets_Enabled_Array.append(_bullet)
	#-------------------------------------------------------------------------------
	var _bulletResource: BulletResource = bulletDictionary.get(_type, "ArrowHead_Bullet")
	_bullet.texture = _bulletResource.texture
	#_frame = clampi(_frame, 0, _bulletResource.maxFrame)
	_bullet.frame = _frame
	#-------------------------------------------------------------------------------
	_bullet.position = Vector2(_x, _y)
	_bullet.isGrazed = false
	_bullet.dir = _dir
	_bullet.vel = _v
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func PlayerBullet_PhysicsUpdate(_bullet: Bullet):
	if(_bullet.position.x > enemyLimitsX.x and _bullet.position.x < enemyLimitsX.y):
		if(_bullet.position.y > enemyLimitsY.x and _bullet.position.y < enemyLimitsY.y):
			PlayerBullet_PhysicsUpdate_Limitless(_bullet)
		#-------------------------------------------------------------------------------
		else:
			Destroy_PlayerBullet(_bullet)
			return
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	else:
		Destroy_PlayerBullet(_bullet)
		return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func PlayerBullet_PhysicsUpdate_Limitless(_bullet: Bullet):
	for _i in range(enemy_Enabled_Array.size()-1,-1,-1):
		#-------------------------------------------------------------------------------
		if(_bullet.position.distance_to(enemy_Enabled_Array[_i].position) < (_bullet.radius+enemy_Enabled_Array[_i].radius)):
			var _enemy: Enemy = enemy_Enabled_Array[_i]
			_enemy.hp -=1
			Set_EnemyLife_Label(_enemy)
			Destroy_PlayerBullet(_bullet)
			return
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	for _i in range(boss_Enabled_Array.size()-1,-1,-1):
		if(_bullet.position.distance_to(boss_Enabled_Array[_i].position)< (_bullet.radius+boss_Enabled_Array[_i].radius)):
			var _boss: Boss = boss_Enabled_Array[_i]
			_boss.hp -=1
			Set_BossLife_Label(_boss)
			Destroy_PlayerBullet(_bullet)
			return
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_bullet.dir)
	_bullet.velocity.x = _bullet.vel * cos(_dir2)
	_bullet.velocity.y = _bullet.vel * sin(_dir2)
	_bullet.rotation_degrees = _bullet.dir+90
	#-------------------------------------------------------------------------------
	_bullet.position += _bullet.velocity * deltaTimeScale
#-------------------------------------------------------------------------------
func Destroy_PlayerBullet(_bullet: Bullet):
	KillTween_Array(_bullet.tween_Array)
	playerBullets_Enabled_Array.erase(_bullet)
	playerBullets_Disabled_Array.append(_bullet)
	_bullet.hide()
#endregion
#-------------------------------------------------------------------------------
#region ITEM FUNCTIONS
func Create_Items_Disabled(_iMax:int):
	for _i in _iMax:
		var _item: Item = item_Prefab.instantiate() as Item
		items_Disabled_Array.append(_item)
		_item.physics_Update = func(): Items_PhysicsUpdate(_item)
		_item.hide()
		content.add_child(_item)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Items(_x:float, _y:float, _rad: float, _num:int, _vel_y:float):
	for _i in _num:
		Create_Item(_x+randf_range(-_rad,_rad), _y+randf_range(-_rad,_rad), _vel_y)
#-------------------------------------------------------------------------------
func Create_Item(_x:float, _y:float, _vel_y:float):
	var _item: Item
	#-------------------------------------------------------------------------------
	if(items_Disabled_Array.size()>0):
		_item = items_Disabled_Array[0]
		items_Disabled_Array.erase(_item)
		_item.show()
	#-------------------------------------------------------------------------------
	else:
		_item = item_Prefab.instantiate() as Item
		_item.physics_Update = func(): Items_PhysicsUpdate(_item)
		content.add_child(_item)
	#-------------------------------------------------------------------------------
	items_Enabled_Array.append(_item)
	#-------------------------------------------------------------------------------
	_item.myITEM_STATE = Item.ITEM_STATE.SPIN
	_item.velocity = Vector2(0, _vel_y)
	_x = clamp(_x, playerLimitsX.x, playerLimitsX.y)
	_y = clamp(_y, playerLimitsY.x, playerLimitsY.y)
	_item.position = Vector2(_x, _y)
#-------------------------------------------------------------------------------
func Items_PhysicsUpdate(_item:Item):
	var _velY_Max: float = 3.0
	var _velY_Accel: float = 0.05
	var _magnetVel: float = 8.0
	match(_item.myITEM_STATE):
		Item.ITEM_STATE.SPIN:
			if(_item.velocity.y <= 0):
				_item.velocity.y += _velY_Accel * deltaTimeScale
				_item.position.y += _item.velocity.y * deltaTimeScale
				_item.rotation += 0.5 * deltaTimeScale
				return
			#-------------------------------------------------------------------------------
			else:
				_item.rotation = 0
				_item.myITEM_STATE = Item.ITEM_STATE.FALL
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Item.ITEM_STATE.FALL:
			if(_item.position.y <= height):
				if(_item.velocity.y > _velY_Max):
					_item.velocity.y = _velY_Max
				#-------------------------------------------------------------------------------
				elif(_item.velocity.y < _velY_Max):
					_item.velocity.y += _velY_Accel * deltaTimeScale
				#-------------------------------------------------------------------------------
				_item.position.y += _item.velocity.y * deltaTimeScale
				#-------------------------------------------------------------------------------
				if(_item.position.distance_to(player.position)< (_item.radius+magnetBox_radius) and player.myPLAYER_STATE != Player.PLAYER_STATE.DEATH):
					_item.myITEM_STATE = Item.ITEM_STATE.IMANTED
					return
				#-------------------------------------------------------------------------------
				elif(myGAME_STATE != GAME_STATE.IN_GAMEPLAY and player.myPLAYER_STATE != Player.PLAYER_STATE.DEATH):
					_item.myITEM_STATE = Item.ITEM_STATE.IMANTED
					return
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
			else:
				DestroyItem(_item)
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Item.ITEM_STATE.IMANTED:
			var _vel: Vector2 = (player.position - _item.position)
			if(_vel.length_squared() > 144.0):
				var _dir = atan2(_vel.y, _vel.x)
				var _vel2 = Vector2(cos(_dir), sin(_dir))
				_item.position += _vel2 * _magnetVel * deltaTimeScale
			#-------------------------------------------------------------------------------
			else:
				scorePoints += 10
				moneyPoints += 1
				SetScore()
				SetMoney()
				DestroyItem(_item)
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func DestroyItem(_item:Item) -> void:
	items_Enabled_Array.erase(_item)
	items_Disabled_Array.append(_item)
	_item.hide()
#endregion
#-------------------------------------------------------------------------------
#region BOSS FUNTIONS
func Create_Boss_Disabled(_iMax:int):
	for _i in _iMax:
		var _boss: Boss = boss_Prefab.instantiate() as Boss
		boss_Disabled_Array.append(_boss)
		_boss.physics_Update = func():Boss_PhysicsUpdate(_boss)
		_boss.hide()
		content.add_child(_boss)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Boss(_x:float, _y:float, _hp: int) -> Boss:
	var _boss: Boss
	#-------------------------------------------------------------------------------
	if(enemy_Disabled_Array.size() > 0):
		_boss = boss_Disabled_Array[0]
		_boss.show()
		boss_Disabled_Array.erase(_boss)
	#-------------------------------------------------------------------------------
	else:
		_boss = boss_Prefab.instantiate() as Boss
		_boss.physics_Update = func():Boss_PhysicsUpdate(_boss)
		content.add_child(_boss)
	#-------------------------------------------------------------------------------
	boss_Enabled_Array.append(_boss)
	#-------------------------------------------------------------------------------
	_boss.position = Vector2(_x, _y)
	_boss.maxHp = _hp
	_boss.hp = _hp
	_boss.vel = 0
	_boss.dir = 90
	Set_BossLife_Label(_boss)
	#-------------------------------------------------------------------------------
	return _boss
#-------------------------------------------------------------------------------
func Boss_PhysicsUpdate(_boss:Boss):
	if(_boss.hp <= 0):
		Disable_Boss(_boss)
		Boss_InstantDeath()
		Create_Items(_boss.position.x, _boss.position.y, 50, 50, -3)
		return
	#-------------------------------------------------------------------------------
	if(_boss.position.distance_to(player.position) < (_boss.radius+hitBox_radius) and player.canBeHit):
		Player_Shooted()
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_boss.dir)
	_boss.velocity.x = _boss.vel * cos(_dir2)
	_boss.velocity.y = _boss.vel * sin(_dir2)
	#_boss.rotation_degrees = _boss.dir+90
	#-------------------------------------------------------------------------------
	_boss.position += _boss.velocity * deltaTimeScale
#-------------------------------------------------------------------------------
func Disable_Boss(_boss: Boss):
	KillTween_Array(_boss.tween_Array)
	boss_Enabled_Array.erase(_boss)
	boss_Disabled_Array.append(_boss)
	_boss.label.hide()
#-------------------------------------------------------------------------------
func Boss_InstantDeath():
	StopEverithing()
	timer_tween.kill()
	timer_tween.finished.emit()
#-------------------------------------------------------------------------------
func Set_BossLife_Label(_boss: Boss):
	_boss.label.text = str(_boss.hp)+" / "+str(_boss.maxHp) + " HP"
#endregion
#-------------------------------------------------------------------------------
#region ENEMY FUNCTIONS
func Create_Enemy_Disabled(_iMax:int):
	for _i in _iMax:
		var _enemy: Enemy = enemy_Prefab.instantiate() as Enemy
		enemy_Disabled_Array.append(_enemy)
		_enemy.physics_Update = func(): Enemy_PhysicsUpdate(_enemy)
		_enemy.hide()
		_enemy.playback = _enemy.animationTree.get("parameters/playback")
		content.add_child(_enemy)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Enemy(_x:float, _y:float, _v:float, _dir: float, _hp: int) -> Enemy:
	var _enemy: Enemy
	#-------------------------------------------------------------------------------
	if(enemy_Disabled_Array.size() > 0):
		_enemy = enemy_Disabled_Array[0]
		_enemy.show()
		enemy_Disabled_Array.erase(_enemy)
	#-------------------------------------------------------------------------------
	else:
		_enemy = enemy_Prefab.instantiate() as Enemy
		singleton.DisconnectAll(_enemy.death_signal)
		_enemy.physics_Update = func(): Enemy_PhysicsUpdate(_enemy)
		_enemy.playback = _enemy.animationTree.get("parameters/playback")
		content.add_child(_enemy)
	#-------------------------------------------------------------------------------
	enemy_Enabled_Array.append(_enemy)
	#-------------------------------------------------------------------------------
	_enemy.sprite.flip_h = false
	_enemy.playback.travel("Idle")
	_enemy.myMOVING_STATE = Enemy.MOVING_STATE.IDLE
	#-------------------------------------------------------------------------------
	_enemy.position = Vector2(_x, _y)
	_enemy.maxHp = _hp
	_enemy.hp = _hp
	_enemy.vel = _v
	_enemy.dir = _dir
	Set_EnemyLife_Label(_enemy)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Enemy_PhysicsUpdate(_enemy:Enemy):
	if(_enemy.hp <= 0):
		_enemy.death_signal.emit()
		Destroy_Enemy(_enemy)
		Create_Items(_enemy.position.x, _enemy.position.y, 50, 50, -3)
		return
	#-------------------------------------------------------------------------------
	if(_enemy.position.distance_to(player.position) < (_enemy.radius+hitBox_radius) and player.canBeHit):
		Player_Shooted()
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_enemy.dir)
	_enemy.velocity.x = _enemy.vel * cos(_dir2)
	_enemy.velocity.y = _enemy.vel * sin(_dir2)
	#_enemy.rotation_degrees = _enemy.dir+90
	#-------------------------------------------------------------------------------
	_enemy.position += _enemy.velocity * deltaTimeScale
	#-------------------------------------------------------------------------------
	Enemy_Animation(_enemy)
#-------------------------------------------------------------------------------
func Enemy_Animation(_enemy:Enemy):
	#-------------------------------------------------------------------------------
	match(_enemy.myMOVING_STATE):
		Enemy.MOVING_STATE.IDLE:
			if(_enemy.velocity.x > 2):
				_enemy.myMOVING_STATE = Enemy.MOVING_STATE.RIGHT
				_enemy.playback.travel("Turning_Right")
				return
			#-------------------------------------------------------------------------------
			elif(_enemy.velocity.x < -2):
				_enemy.myMOVING_STATE = Enemy.MOVING_STATE.LEFT
				_enemy.playback.travel("Turning_Right")
				_enemy.sprite.flip_h = true
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Enemy.MOVING_STATE.RIGHT:
			if(_enemy.velocity.x < 1):
				_enemy.myMOVING_STATE = Enemy.MOVING_STATE.IDLE
				_enemy.playback.travel("Turning_Idle")
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		Enemy.MOVING_STATE.LEFT:
			if(_enemy.velocity.x > -1):
				_enemy.myMOVING_STATE = Enemy.MOVING_STATE.IDLE
				_enemy.playback.travel("Turning_Idle")
				_enemy.sprite.flip_h = false
				return
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Destroy_Enemy(_enemy: Enemy):
	KillTween_Array(_enemy.tween_Array)
	enemy_Enabled_Array.erase(_enemy)
	enemy_Disabled_Array.append(_enemy)
	singleton.DisconnectAll(_enemy.death_signal)
	_enemy.hide()
#-------------------------------------------------------------------------------
func Set_EnemyLife_Label(_enemy: Enemy):
	_enemy.label.text = str(_enemy.hp)+" / "+str(_enemy.maxHp) + " hp"
#endregion
#-------------------------------------------------------------------------------
#region ENEMY BULLET FUNCTIONS
func Create_EnemyBullets_Disabled(_iMax:int):
	for _i in _iMax:
		var _bullet: Bullet = bullet_Prefab.instantiate() as Bullet
		enemyBullets_Disabled_Array.append(_bullet)
		_bullet.hide()
		_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate(_bullet)
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_EnemyBullet(_x:float, _y:float, _v:float, _dir:float, _type:String, _frame:int) ->Bullet:
	var _bullet: Bullet
	#-------------------------------------------------------------------------------
	if(enemyBullets_Disabled_Array.size() > 0):
		_bullet = enemyBullets_Disabled_Array[0]
		_bullet.show()
		enemyBullets_Disabled_Array.erase(_bullet)
	#-------------------------------------------------------------------------------
	else:
		_bullet = bullet_Prefab.instantiate() as Bullet
		content.add_child(_bullet)
		_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate(_bullet)
	#-------------------------------------------------------------------------------
	enemyBullets_Enabled_Array.append(_bullet)
	#-------------------------------------------------------------------------------
	var _bulletResource: BulletResource = bulletDictionary.get(_type, "ArrowHead_Bullet")
	_bullet.texture = _bulletResource.texture
	#_frame = clampi(_frame, 0, _bulletResource.maxFrame)
	_bullet.frame = _frame
	#-------------------------------------------------------------------------------
	_bullet.position = Vector2(_x, _y)
	_bullet.isGrazed = false
	_bullet.can_Go_OffLimits = false
	_bullet.dir = _dir
	_bullet.vel = _v
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.position.x > enemyLimitsX.x and _bullet.position.x < enemyLimitsX.y):
		if(_bullet.position.y > enemyLimitsY.x and _bullet.position.y < enemyLimitsY.y):
			EnemyBullet_PhysicsUpdate_Limitless(_bullet)
		#-------------------------------------------------------------------------------
		else:
			Destroy_EnemyBullet(_bullet)
			return
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	else:
		Destroy_EnemyBullet(_bullet)
		return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Limitless(_bullet: Bullet):
	if(_bullet.position.distance_to(player.position) < (_bullet.radius+grazeBox_radius) and !_bullet.isGrazed and player.myPLAYER_STATE == Player.PLAYER_STATE.ALIVE):
		Create_Item(_bullet.position.x, _bullet.position.y, -5)
		_bullet.isGrazed = true
	#-------------------------------------------------------------------------------
	if(_bullet.position.distance_to(player.position) < (_bullet.radius+hitBox_radius) and player.canBeHit):
		Player_Shooted()
		Destroy_EnemyBullet(_bullet)
		return
	#-------------------------------------------------------------------------------
	else:
		var _dir2: float = deg_to_rad(_bullet.dir)
		_bullet.velocity.x = _bullet.vel * cos(_dir2)
		_bullet.velocity.y = _bullet.vel * sin(_dir2)
		_bullet.rotation_degrees = _bullet.dir+90
		#-------------------------------------------------------------------------------
		_bullet.position += _bullet.velocity * deltaTimeScale
		#-------------------------------------------------------------------------------
		return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Destroy_EnemyBullet(_bullet: Bullet):
	KillTween_Array(_bullet.tween_Array)
	enemyBullets_Enabled_Array.erase(_bullet)
	enemyBullets_Disabled_Array.append(_bullet)
	_bullet.hide()
#endregion
#-------------------------------------------------------------------------------
#region TIMER FUNCTIONS
func Seconds(_f:float):
	await get_tree().create_timer(_f, false).timeout
#-------------------------------------------------------------------------------
func TimeOut_Tween(_iMax: int):
	var _tween: Tween = create_tween()
	timer_tween = _tween
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		timer = _iMax
		timerLabel.show()
		PrintTimer(timer, _iMax)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(1.0)
	#-------------------------------------------------------------------------------
	for _i in _iMax:
		_tween.tween_callback(func():
			timer-=1
			PrintTimer(timer, _iMax)
		)
		_tween.tween_interval(1.0)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		StopEverithing()
	)
	#-------------------------------------------------------------------------------
	await timer_tween.finished
#-------------------------------------------------------------------------------
func PrintTimer(_i:int, _iMax:int):
	timerLabel.text = str(_i).pad_zeros(2)+" / " +str(_iMax).pad_zeros(2) + " s"
#-------------------------------------------------------------------------------
func StopEverithing():
	timerLabel.text = ""
	timerLabel.hide()
	#-------------------------------------------------------------------------------
	KillTween_Array(main_tween_Array)
	#-------------------------------------------------------------------------------
	for _i in range(boss_Enabled_Array.size()-1, -1, -1):
		Disable_Boss(boss_Enabled_Array[_i])
	#-------------------------------------------------------------------------------
	for _i in range(enemy_Enabled_Array.size()-1, -1, -1):
		Destroy_Enemy(enemy_Enabled_Array[_i])
	#-------------------------------------------------------------------------------
	for _i in range(enemyBullets_Enabled_Array.size()-1, -1, -1):
		Destroy_EnemyBullet(enemyBullets_Enabled_Array[_i])
	#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region MATH FUNCTIONS
func AngleToPlayer(_obj: Node2D) -> float:
	var _f: float = rad_to_deg(atan2(player.position.y-_obj.position.y, player.position.x-_obj.position.x))
	return _f
#-------------------------------------------------------------------------------
func GetAngleFromTo(_obj1: Node2D, _obj2: Node2D) -> float:
	var _f: float = rad_to_deg(atan2(_obj2.position.y-_obj1.position.y, _obj2.position.x-_obj1.position.x))
	return _f
#-------------------------------------------------------------------------------
func GetAngleXY(_dx: float, _dy: float) -> float:
	var _f: float = rad_to_deg(atan2(_dy, _dx))
	return _f
#endregion
#-------------------------------------------------------------------------------
#region ARRAY[TWEEN] FUNCTIONS
func CreateTween_ArrayAppend(_tween_Array: Array[Tween]) -> Tween:
	var _tween: Tween = create_tween()
	_tween_Array.append(_tween)
	_tween.finished.connect(func():_tween_Array.erase(_tween))
	return _tween
#-------------------------------------------------------------------------------
func KillTween_Array(_tween_Array: Array[Tween]):
	for _i in range(_tween_Array.size()-1, -1, -1):
		_tween_Array[_i].kill()
		_tween_Array[_i].finished.emit()
#endregion
#-------------------------------------------------------------------------------
#region IDIOME FUNCTIONS
func SetIdiome():
	singleton.DisconnectAll(singleton.optionMenu.idiomeChange)
	#-------------------------------------------------------------------------------
	singleton.optionMenu.idiomeChange.connect(pauseMenu.SetIdiome)
	singleton.optionMenu.idiomeChange.connect(SetIdiome2)
	#-------------------------------------------------------------------------------
	pauseMenu.SetIdiome()
	SetIdiome2()
#-------------------------------------------------------------------------------
func SetIdiome2():
	maxScoreLabel_title.text = "[u]"+tr("gameUI_maxScore")+":[/u]"
	scoreLabel_title.text = "[u]"+tr("gameUI_score")+":[/u]"
	livesLabel_title.text = "[u]"+tr("gameUI_lives")+":[/u]"
	powerLabel_title.text = "[u]"+tr("gameUI_power")+":[/u]"
#endregion
#-------------------------------------------------------------------------------
