extends Node
class_name Game_Scene
#-------------------------------------------------------------------------------
enum GAME_STATE{IN_GAMEPLAY, IN_MARKET, IN_DIALOGUE, IN_GAMEOVER}
#region VARIABLES
var singleton: Singleton
#-------------------------------------------------------------------------------
var myGAME_STATE: GAME_STATE = GAME_STATE.IN_GAMEPLAY
var isSlowMotion: bool = false
var time_scale: float = 1.0
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
@export var explotion: Sprite2D
@export var explotion_anim: AnimationPlayer
var isFocus: bool = false
var cardInventory: Dictionary[CardResource, int]
#-------------------------------------------------------------------------------
@export var enemy_Prefab: PackedScene
@export var smallShip_sprite: Texture2D
@export var midShip_sprite: Texture2D
@export var bigShip_sprite: Texture2D
@export var asteroid_sprite: Texture2D
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
@export var completedLabel: RichTextLabel
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
var bullet_Color_Id_Max: int = 16
var turn_counter: int = 0
var phase_counter: int = 0
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
	completedPanel.hide()
	#-------------------------------------------------------------------------------
	SetIdiome()
	#-------------------------------------------------------------------------------
	singleton.PlayBGM(singleton.bgmStage1)
	NormalMotion()
	Resume_Time()
	currentLayer.show()
	#-------------------------------------------------------------------------------
	await BeginGame()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	deltaTimeScale = Engine.time_scale
	tween_Array = get_tree().get_processed_tweens()
	Debug_Information()
	#-------------------------------------------------------------------------------
	Set_SlowMotion()
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
			Pause_On()
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
			Player_Hitbox()
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
func Player_Hitbox():
	#-------------------------------------------------------------------------------
	for _i in range(enemyBullets_Enabled_Array.size()-1, -1, -1):
		var _bullet: Bullet = enemyBullets_Enabled_Array[_i]
		if(_bullet.position.distance_to(player.position) <  (_bullet.radius+player.grazeBox_radius) and !_bullet.isGrazed):
			var _rad: float = 10.0
			Create_Item(_bullet.position.x+randf_range(-_rad, _rad), _bullet.position.y+randf_range(-_rad, _rad), -5)
			_bullet.isGrazed = true
		#-------------------------------------------------------------------------------
		if(_bullet.position.distance_to(player.position) < (_bullet.radius+player.hitBox_radius) and player.canBeHit):
			Player_Shooted()
			Destroy_EnemyBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	for _i in range(enemy_Enabled_Array.size()-1, -1, -1):
		var _enemy: Enemy = enemy_Enabled_Array[_i]
		if(_enemy.position.distance_to(player.position) < (_enemy.hitbox_radius+player.hitBox_radius) and player.canBeHit):
			Player_Shooted()
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	for _i in range(boss_Enabled_Array.size()-1, -1, -1):
		var _boss: Boss = boss_Enabled_Array[_i]
		if(_boss.position.distance_to(player.position) < (_boss.hitbox_radius+player.hitBox_radius) and player.canBeHit):
			Player_Shooted()
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
func Pause_On() -> void:
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
	Engine.time_scale = 0.0
#-------------------------------------------------------------------------------
func Pause_Off():
	pauseMenu.hide()
	singleton.bgmPlayer.play(singleton.playPosition)
	Resume_Time()
#-------------------------------------------------------------------------------
func Resume_Time():
	get_tree().set_deferred("paused", false)
	Engine.time_scale = time_scale
#-------------------------------------------------------------------------------
func Set_SlowMotion() -> void:
	if(get_tree().paused):
		return
	#-------------------------------------------------------------------------------
	if(Input.is_action_just_pressed("Debug_SlowMotion")):
		if(isSlowMotion):
			NormalMotion()
		#-------------------------------------------------------------------------------
		else:
			time_scale = 0.3
			Engine.time_scale = time_scale
			isSlowMotion = true
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func NormalMotion():
	time_scale = 1.0
	Engine.time_scale = time_scale
	isSlowMotion = false
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
	var _offSet2: float = 32
	enemyLimitsX = Vector2(0-_offSet2, width+_offSet2)
	enemyLimitsY = Vector2(0-_offSet2, height+_offSet2)
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
	_s += "Slow Motion: " + str(isSlowMotion) + "\n"
	for _i in boss_Enabled_Array.size():
		_s += str(boss_Enabled_Array[_i].canBeHit) + "\n"
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
	#-------------------------------------------------------------------------------
	explotion.global_position = Vector2.ZERO
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
func EnemyWave_and_Market(_callable:Callable, _timer:int):
	await EnemyWave_and_Nothing(_callable, _timer)
	await Nothing_and_Market()
#-------------------------------------------------------------------------------
func EnemyWave_and_Nothing(_callable:Callable, _timer:int):
	await ShowBanner_EnemyWave()
	_callable.call()
	await TimeOut_Tween(_timer)
#-------------------------------------------------------------------------------
func SpellCard_and_Market(_boss:Boss, _hp:int, _callable:Callable, _timer:int):
	await SpellCard_and_Nothing(_boss, _hp, _callable, _timer)
	await Nothing_and_Market()
	await Move_Boss_to_Hook(_boss)
#-------------------------------------------------------------------------------
func SpellCard_and_Nothing(_boss:Boss, _hp: int, _callable:Callable, _timer:int):
	await ShowBanner_SpellCard()
	Enable_Boss(_boss, _hp, _callable)
	_callable.call()
	await TimeOut_Tween(_timer)
#-------------------------------------------------------------------------------
func Enable_Boss(_boss:Boss, _hp:int, _callable:Callable):
	boss_Disabled_Array.erase(_boss)
	boss_Enabled_Array.append(_boss)
	#-------------------------------------------------------------------------------
	_boss.maxHp = _hp
	_boss.hp = _hp
	Set_BossLife_Label(_boss)
	_boss.label.show()
	#-------------------------------------------------------------------------------
	_boss.canBeHit = true
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Nothing_and_Market():
	await OpenMarket()
	Enter_GameState_InGameplay()
#-------------------------------------------------------------------------------
func OpenMarket():
	await ShowBanner_OpenMarket()
	myGAME_STATE = GAME_STATE.IN_MARKET
	await marketMenu.OpenMarket()
#-------------------------------------------------------------------------------
func Dialogue_1_1():
	dialogueMenu.dialogue_id = dialogueMenu.GetSubBossDialogueID(0)
	dialogueMenu.dialogue_index = 0
	#-------------------------------------------------------------------------------
	await ReadLine(true, false)
	await ReadLine(true, false)
	await ReadLine(true, false)
	await ReadLine(true, false)
	await ReadLine(false, true)
	await ReadLine(false, true)
#-------------------------------------------------------------------------------
func Dialogue_1_2():
	#var _bossDialogueID: String = dialogueMenu.GetSubBossDialogueID(0)
	#dialogueMenu.dialogue_index = 0
	#-------------------------------------------------------------------------------
	await ReadLine(true, false)
	await ReadLine(false, true)
	await ReadLine(true, false)
	await ReadLine(false, true)
	await ReadLine(true, false)
	await ReadLine(false, true)
#-------------------------------------------------------------------------------
func ReadLine(_showSpeaker1:bool, _showSpeaker2:bool):
	await dialogueMenu.ReadLine(_showSpeaker1, _showSpeaker2)
#-------------------------------------------------------------------------------
func Enter_GameState_InGameplay():
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
#endregion
#-------------------------------------------------------------------------------
#region CLEAR STAGE FUNCTIONS
func Stage_Completed(_enabled:int, _completed:int):
	await ShowBanner_Completed(_completed)
	EnableStage(_enabled)
	CompletedStage(_completed)
	singleton.Save_SaveData_Json(singleton.optionMenu.optionSaveData_Json["saveIndex"])
	singleton.CommonSubmited()
	GoToMainScene()
#-------------------------------------------------------------------------------
func EnableStage(_i:int):
	var _playerIndex: StringName = str(int(singleton.currentSaveData_Json["playerIndex"]))
	var _difficultyIndex: StringName = str(int(singleton.currentSaveData_Json["difficultyIndex"]))
	#-------------------------------------------------------------------------------
	if(singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] == singleton.STAGE_STATE.DISABLED):
		singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] = singleton.STAGE_STATE.ENABLED
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func CompletedStage(_i:int):
	var _playerIndex: StringName = str(int(singleton.currentSaveData_Json["playerIndex"]))
	var _difficultyIndex: StringName = str(int(singleton.currentSaveData_Json["difficultyIndex"]))
	singleton.currentSaveData_Json["saveData"][_playerIndex][_difficultyIndex][str(_i)]["value"] = singleton.STAGE_STATE.COMPLETED
#-------------------------------------------------------------------------------
func GoToMainScene():
	singleton.PlayBGM(singleton.bgmTitle)
	Resume_Time()
	get_tree().change_scene_to_file(singleton.mainScene_Path)
#endregion
#-------------------------------------------------------------------------------
#region BANNER FUNCTIONS
func ShowBanner_EnemyWave():
	turn_counter += 1
	phase_counter += 1
	#-------------------------------------------------------------------------------
	var _s:String = "[center]"
	_s += "[font_size=20]"+"Turn " + str(turn_counter)
	_s += "\n"
	_s += "[font_size=35]"+"Enemy Wave " + str(phase_counter)
	#-------------------------------------------------------------------------------
	await Seconds(1.0)
	await ShowBanner(_s)
#-------------------------------------------------------------------------------
func ShowBanner_SpellCard():
	turn_counter += 1
	phase_counter += 1
	#-------------------------------------------------------------------------------
	var _s:String = "[center]"
	_s += "[font_size=20]"+"Turn " + str(turn_counter)
	_s += "\n"
	_s +="[font_size=35]"+"Spell Card " + str(phase_counter)
	#-------------------------------------------------------------------------------
	await Seconds(1.0)
	await ShowBanner(_s)
#-------------------------------------------------------------------------------
func ShowBanner_OpenMarket():
	#-------------------------------------------------------------------------------
	var _s:String = "[center]"
	_s += "[font_size=20]"+"Turn " + str(turn_counter)
	_s += "\n"
	_s +="[font_size=35]"+"Space Market"
	#-------------------------------------------------------------------------------
	await ShowBanner(_s)
#-------------------------------------------------------------------------------
func ShowBanner_EnterBoss():
	#-------------------------------------------------------------------------------
	var _s:String = "[center]"
	_s += "[font_size=20]"+"Turn " + str(turn_counter+1)
	_s += "\n"
	_s +="[font_size=35]"+"Enter Boss"
	#-------------------------------------------------------------------------------
	await Seconds(1.0)
	await ShowBanner(_s)
#-------------------------------------------------------------------------------
func ShowBanner_Completed(_i:int):
	#-------------------------------------------------------------------------------
	var _s:String = "[center]"
	_s += "[font_size=45]"+"Completed"
	_s += "\n"
	_s += "[font_size=20]"+"Stage " + str(_i+1) +" Cleared"
	#-------------------------------------------------------------------------------
	await Seconds(1.0)
	await ShowBanner(_s)
#-------------------------------------------------------------------------------
func ShowBanner(_s:String):
	completedLabel.text = _s
	completedPanel.show()
	await Seconds(2.0)
	completedPanel.hide()
	completedLabel.text = ""
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1
func Stage1():
	phase_counter = 0
	#-------------------------------------------------------------------------------
	await EnemyWave_and_Market(func():Stage1_Phase3(), 30)
	await EnemyWave_and_Market(func():Stage1_Phase5(), 30)
	#await EnemyWave_and_Market(func():Stage1_Phase7(), 30)
	#await EnemyWave_and_Market(func():Stage1_Phase6(), 30)
	#await EnemyWave_and_Market(func():Stage1_Phase4(), 60)
	#await EnemyWave_and_Market(func():Stage1_Phase2(), 30)
	#-------------------------------------------------------------------------------
	await ShowBanner_EnterBoss()
	#await Stage1_Boss1_Dialogue1()
	var _boss: Boss = await EnterBoss()
	#await Stage1_Boss1_Dialogue2()
	#-------------------------------------------------------------------------------
	#Exit_Dialogue_Enter_Gameplay()
	#-------------------------------------------------------------------------------
	phase_counter = 0
	#-------------------------------------------------------------------------------
	await SpellCard_and_Market(_boss, 100, func():Stage1_SpellCard1(_boss), 60)
	await SpellCard_and_Nothing(_boss, 100, func():Stage1_SpellCard2(_boss), 60)
	#-------------------------------------------------------------------------------
	_boss.hide()
	#-------------------------------------------------------------------------------
	await Stage_Completed(1,0)
#-------------------------------------------------------------------------------
func Stage1_Boss1_Dialogue1():		#IMPORTANTE: Tiene que haber un await antes de entrar al dialogo porque si no se saltea la primer liena.
	myGAME_STATE = GAME_STATE.IN_DIALOGUE
	dialogueMenu.speaker2.hide()
	dialogueMenu.OpenDialogue()
	#-------------------------------------------------------------------------------
	await Dialogue_1_1()
#-------------------------------------------------------------------------------
func EnterBoss() -> Boss:
	var _boss: Boss = Create_Boss(-width*0, -height*0)
	#-------------------------------------------------------------------------------
	await Move_Boss_to_Hook(_boss)
	#-------------------------------------------------------------------------------
	return _boss
#-------------------------------------------------------------------------------
func Move_Boss_to_Hook(_boss:Boss):
	var _target_position: Vector2 = Vector2(width*0.5, height*0.25)
	var _dir: float = GetAngleXY(_target_position.x - _boss.position.x, _target_position.y - _boss.position.y)
	#-------------------------------------------------------------------------------
	var _tween: Tween = create_tween()
	_tween.tween_property(_boss, "position", _target_position, 1.0)
	_tween.parallel().tween_property(_boss.sprite, "rotation_degrees", _dir-90, 0.3)
	_tween.tween_property(_boss.sprite, "rotation_degrees", 0, 0.3)
	#-------------------------------------------------------------------------------
	await _tween.finished
#-------------------------------------------------------------------------------
func Stage1_Boss1_Dialogue2():
	dialogueMenu.speaker2.show()
	await Dialogue_1_2()
#-------------------------------------------------------------------------------
func Exit_Dialogue_Enter_Gameplay():
	dialogueMenu.CloseDialogue()
	myGAME_STATE = GAME_STATE.IN_GAMEPLAY
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1: PHASES
func Stage1_Phase1():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_Wave1(_tween, 1)
	Stage1_Wave1(_tween, -1)
#-------------------------------------------------------------------------------
func Stage1_Phase2():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_Wave2(_tween, 1)
	Stage1_Wave2(_tween, -1)
#-------------------------------------------------------------------------------
func Stage1_Phase3():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	#-------------------------------------------------------------------------------
	Stage1_Phase3_Mirror(_tween, 1)
	Stage1_Phase3_Mirror(_tween, -1)
#-------------------------------------------------------------------------------
func Stage1_Phase3_Mirror(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(main_tween_Array)
		_tween2.tween_interval(0.15)
		Stage1_Wave3(_tween2, _mirror)
	)
	#-------------------------------------------------------------------------------
	Stage1_Wave3(_tween, -_mirror)
	#_tween.tween_interval(1)
	Stage1_Wave8(_tween, -_mirror, _mirror)
	Stage1_Wave8(_tween, _mirror, _mirror)
	_tween.tween_interval(2)
#-------------------------------------------------------------------------------
func Stage1_Phase4():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(main_tween_Array)
		Stage1_Wave4(_tween2, -1)
		)
	#-------------------------------------------------------------------------------
	Stage1_Wave4(_tween, 1)
#-------------------------------------------------------------------------------
func Stage1_Phase5():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_Wave5(_tween, 1)
	Stage1_Wave5(_tween, -1)
	#-------------------------------------------------------------------------------
	var _tween2: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween2.set_loops()
	Stage1_Wave9(_tween2, 1)
#-------------------------------------------------------------------------------
func Stage1_Phase6():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_Wave6(_tween, 1)
	Stage1_Wave6(_tween, -1)
#-------------------------------------------------------------------------------
func Stage1_Phase7():
	var _tween: Tween = CreateTween_ArrayAppend(main_tween_Array)
	_tween.set_loops()
	Stage1_Wave7(_tween, 1)
	Stage1_Wave7(_tween, -1)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1: WAVES
func Stage1_Wave1(_tween:Tween, _mirror: float):
	for _i in 8:
		#-------------------------------------------------------------------------------
		for _j in 1:
			var _x: float = width * 0.5 - width*(0.6 + 0.1 * _j) *_mirror
			var _y: float = -height * (0.2 - 0.1 * _j)
			_tween.tween_callback(func():
				Stage1_Enemy1(_x, _y, _mirror)
			)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.8)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	_tween.tween_interval(1)
#-------------------------------------------------------------------------------
func Stage1_Wave2(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _x: float = width*0.5+width*0.25*_mirror
		var _y: float = -height*0.1
		var _enemy: Enemy = Stage1_Enemy2(_x, _y, _mirror)
		#-------------------------------------------------------------------------------
		Pause_Tween_Until_Enemy_Death(_enemy, _tween)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Wave3(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	var _x: float = Get_Center_X(0.4*_mirror)
	var _y: float = height
	#-------------------------------------------------------------------------------
	var _dir: float = 90
	var _dir_origen: float = 90 + 180*_mirror - 5*_mirror
	#-------------------------------------------------------------------------------
	var _num1: float = 8
	#-------------------------------------------------------------------------------
	for _i in _num1:
		#-------------------------------------------------------------------------------
		var _dir_pendiente: float = _mirror * 10 * cos(deg_to_rad(_dir))
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			Stage1_Enemy3(_x, _y, _dir_origen+_dir_pendiente, _mirror)
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.3)
		#-------------------------------------------------------------------------------
		_dir -= 360/(_num1-1)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	_tween.tween_interval(4.0)
#-------------------------------------------------------------------------------
func Stage1_Wave4(_tween:Tween, _mirror:float):
	var _dir: float = 180
	var _rad_x: float = width * 0.15
	var _num1: float = 8
	var _x_origen: float = Get_Center_X(0.3*_mirror)
	#-------------------------------------------------------------------------------
	for _i in _num1:
		#-------------------------------------------------------------------------------
		var _dir2: float = deg_to_rad(_dir)
		var _x_pendiente: float = _mirror * _rad_x * cos(_dir2)
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			#-------------------------------------------------------------------------------
			Stage1_Enemy4(_x_origen-_x_pendiente, height*-0.1, _mirror)
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_dir -= 360/(_num1-1)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.4)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	_tween.tween_interval(2.0)
#-------------------------------------------------------------------------------
func Stage1_Wave5(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _x: float = width*0.5+width*0.25*_mirror
		var _y: float = -height*0.1
		var _enemy: Enemy = Stage1_Enemy5(_x, _y, _mirror)
		#-------------------------------------------------------------------------------
		Pause_Tween_Until_Enemy_Death(_enemy, _tween)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Wave6(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _x: float = width*0.5+width*0.25*_mirror
		var _y: float = -height*0.1
		var _enemy: Enemy = Stage1_Enemy6(_x, _y, _mirror)
		#-------------------------------------------------------------------------------
		Pause_Tween_Until_Enemy_Death(_enemy, _tween)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Wave7(_tween:Tween, _mirror:float):
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _x: float = width*0.5+width*0.25*_mirror
		var _y: float = -height*0.1
		var _enemy: Enemy = Stage1_Enemy7(_x, _y, _mirror)
		#-------------------------------------------------------------------------------
		Pause_Tween_Until_Enemy_Death(_enemy, _tween)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(0.5)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Wave8(_tween:Tween,_mirror:float, _mirror2:float):
	var _num: float = 9
	var _x: float = Get_Center_X(-_mirror*0.5)
	var _dx: float = width/_num
	#-------------------------------------------------------------------------------
	for _i in _num:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _enemy: Enemy = Stage1_Enemy8(_x, -height*0.05, _mirror2)
		)
		#-------------------------------------------------------------------------------
		_x += _dx*_mirror
		_tween.tween_interval(0.3)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Wave9(_tween:Tween, _mirror:float):
	var _num: float = 24
	var _y: float = -height*0.1
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _enemy: Enemy = Stage1_Enemy9(width*0.5, _y, 1.0, 90, 16.5, _mirror)
		SetEnemyAnim_MidMeteorite(_enemy)
	)
	for _i in _num:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _x: float = randf_range(width*0.1, width*0.9)
			var _enemy: Enemy = Stage1_Enemy9(_x, _y, randf_range(2.5, 3.5), 90+randf_range(-15,15), 5.5, _mirror)
			SetEnemyAnim_SmallMeteorite(_enemy)
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.25)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(2.0)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1: ENEMIES
func Stage1_Enemy1(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 4.0, 90-20*_mirror, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		_tween2.tween_interval(1.5)
		Stage1_Fire1(_tween2, _enemy)
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
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy2(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 7, 90, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_property(_enemy, "vel", 0.5, 1.0)
	Stage1_Fire2(_tween, _enemy, _mirror)
	_tween.tween_interval(3.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy_with_Death_Signal(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy3(_x:float, _y:float, _dir:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 15.0, _dir, 4)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	#-------------------------------------------------------------------------------
	_tween.tween_property(_enemy,"vel",0.50, 1.15)
	_tween.tween_property(_enemy,"dir",90, 1)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		#_tween2.tween_interval(1.5)
		Stage1_Fire3(_tween2, _enemy)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(2.0)
	_tween.tween_property(_enemy,"dir",90+80*_mirror, 1.5)
	_tween.parallel().tween_property(_enemy,"vel",4, 1.5)
	_tween.tween_interval(2.5)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy4(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 1.5, 90, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	#-------------------------------------------------------------------------------
	#_tween.tween_property(_enemy,"vel",2.0, 1.15)
	_tween.tween_interval(1.0)
	#_tween.tween_property(_enemy,"dir",90, 1)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		#_tween2.tween_interval(1.5)
		Stage1_Fire3(_tween2, _enemy)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(1.0)
	_tween.tween_property(_enemy,"dir",90+60*_mirror, 1.0)
	_tween.parallel().tween_property(_enemy,"vel",4, 1.5)
	_tween.tween_interval(2.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy5(_x:float, _y:float, _mirror:float) -> Enemy:
	var _dir: float = 90
	var _enemy: Enemy = Create_Enemy(_x, _y, 7, _dir, 10)
	SetEnemyAnim_MidShip(_enemy)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_property(_enemy, "vel", 0, 1.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		Stage1_Fire5(_tween2, _enemy, _mirror)
	)
	#-------------------------------------------------------------------------------
	_tween.tween_interval(4.0)
	_tween.tween_property(_enemy, "vel", 7, 1.2)
	_tween.parallel().tween_property(_enemy, "dir", _dir-90*_mirror, 1.2)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy_with_Death_Signal(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy6(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 7, 90, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_property(_enemy, "vel", 0, 1.0)
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		Stage1_Fire6(_tween2, _enemy, _mirror)
	)
	_tween.tween_interval(3.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy_with_Death_Signal(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy7(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, 7, 90, 10)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_property(_enemy, "vel", 0, 1.0)
	_tween.tween_callback(func():
		var _tween2: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
		Stage1_Fire7(_tween2, _enemy, _mirror)
	)
	_tween.tween_interval(3.0)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy_with_Death_Signal(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy8(_x:float, _y:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy_Senoidal(_x, _y, 2, 90, 0, 2.5*_mirror, 80, 4)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_interval(6)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Stage1_Enemy9(_x:float, _y:float, _vel:float, _dir:float, _timer:float, _mirror:float) -> Enemy:
	var _enemy: Enemy = Create_Enemy(_x, _y, _vel, _dir, 20)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_enemy.tween_Array)
	_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
	_tween.tween_callback(func():
		Destroy_Enemy(_enemy)
	)
	#-------------------------------------------------------------------------------
	return _enemy
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1: FIRE
func Stage1_Fire1(_tween:Tween, _node2D: Node2D):
	var _num1: float = 5.0 + 2.0 * difficulty
	var _vel: float = 7.5 + 0.3 * difficulty
	var _timer: float = 0.2 - 0.03 * difficulty
	#-------------------------------------------------------------------------------
	for _i in _num1:
		_tween.tween_callback(func():
			var _dir: float = AngleToPlayer(_node2D)
			var _x:float = _node2D.position.x
			var _y:float = _node2D.position.y
			var _bullet: Bullet = Create_EnemyBullet_A(_x, _y, _vel, _dir, "bullet2", false)
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Fire2(_tween:Tween, _node2D: Node2D, _mirror:float):
	var _max1: float = 10 + 5 * difficulty
	var _max2: float = 15 + 2 * difficulty
	var _vel: float = 4 + 0.5 * difficulty
	var _timer: float = 0.2 - 0.02 * difficulty
	#-------------------------------------------------------------------------------
	var _ang: float = 0
	var _dir: float = AngleToPlayer(_node2D)
	#-------------------------------------------------------------------------------
	for _j in _max2:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _dir2: float = 0
			#-------------------------------------------------------------------------------
			for _i in _max1:
				var _x:float = _node2D.position.x
				var _y:float = _node2D.position.y
				var _bullet: Bullet = Create_EnemyBullet_A(_x, _y, _vel, _dir+_dir2+_ang, "bullet2", false)
				_dir2 += 360/_max1
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_ang += 5.0*_mirror
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Fire3(_tween:Tween, _node2D: Node2D):
	var _num1: float = 3.0
	var _num2: float = 5.0
	var _vel: float = 12 + 0.3 * difficulty
	var _timer: float = 0.05
	var _cone: float = 10
	#-------------------------------------------------------------------------------
	for _i in _num1:
		_tween.tween_callback(func():
			var _dir: float = AngleToPlayer(_node2D) - _cone/2.0
			var _x:float = _node2D.position.x
			var _y:float = _node2D.position.y
			#-------------------------------------------------------------------------------
			for _j in 5:
				var _bullet: Bullet = Create_EnemyBullet_A(_x, _y, _vel, _dir, "bullet2", false)
				#-------------------------------------------------------------------------------
				var _tween2: Tween = CreateTween_ArrayAppend(_bullet.tween_Array)
				_tween2.tween_property(_bullet, "vel", _vel-5.0, 0.5)
				#-------------------------------------------------------------------------------
				_dir += _cone / (_num2-1.0)
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Fire5(_tween:Tween, _node2D: Node2D, _mirror:float):
	var _max1: float = 30
	var _max2: float = 3
	var _cone: float = 35
	var _vel: float = 5
	var _timer: float = 0.1
	var _dir: float = AngleToPlayer(_node2D)
	var _spin: float = 0
	var _frecuencia: float = 5
	var _amplitud: float = 60
	#-------------------------------------------------------------------------------
	for _i in _max1:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _ang: float = -_cone/2
			#-------------------------------------------------------------------------------
			for _j in _max2:
				Create_EnemyBullet_Senoidal(_node2D.position.x, _node2D.position.y, _vel, _dir+_ang, _spin, _frecuencia, _amplitud, "bullet2", false)
				Create_EnemyBullet_Senoidal(_node2D.position.x, _node2D.position.y, _vel, _dir+_ang, _spin, -_frecuencia, _amplitud, "bullet1", false)
				_ang += _cone/(_max2-1)
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Fire6(_tween:Tween, _node2D: Node2D, _mirror:float):
	var _max1: float = 15
	var _max2: float = 10
	var _cone: float = 180
	var _vel: float = 6
	var _timer: float = 0.1
	var _dir: float = AngleToPlayer(_node2D) + 180
	#-------------------------------------------------------------------------------
	for _i in _max1:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _ang: float = -_cone/2
			#-------------------------------------------------------------------------------
			for _j in _max2:
				Create_EnemyBullet_Bounce(_node2D.position.x, _node2D.position.y, _vel, _dir+_ang, 8, true, false, true, true, "bullet1", false)
				_ang += _cone/(_max2-1)
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Stage1_Fire7(_tween:Tween, _node2D: Node2D, _mirror:float):
	var _max1: float = 1
	var _max2: float = 3
	var _num: float = 10
	var _cone: float = 45
	var _vel: float = 4
	var _timer: float = 0.1
	var _dir: float = AngleToPlayer(_node2D)
	#-------------------------------------------------------------------------------
	for _i in _max1:
		#-------------------------------------------------------------------------------
		_tween.tween_callback(func():
			var _dir2: float = -_cone/2
			#-------------------------------------------------------------------------------
			for _j in _max2:
				var _array_bullet: Array[Bullet] = Create_EnemyBullet_Wheel(_node2D.position.x, _node2D.position.y, _vel, _dir+_dir2, _num, -6, 80, -90, 2, true, true, true, true, "bullet2", false)
				#-------------------------------------------------------------------------------
				_dir2 += _cone/(_max2-1)
			#-------------------------------------------------------------------------------
		)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(_timer)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_EnemyBullet_Wheel(_x:float, _y:float, _vel:float, _dir:float, _num:float, _frecuencia:float, _amplitud:float, _rotation_offset:float, _bounce_counter: int, _bounce_up: bool, _bounce_down: bool, _bounce_left: bool, _bounce_right: bool, _type:String, _can_Go_OffLimits:bool) ->Array[Bullet]:
	var _ang: float = 0
	var _bullet_array: Array[Bullet]
	#-------------------------------------------------------------------------------
	for _i in _num:
		var _bullet: Bullet = Create_EnemyBullet_Spin(_x, _y, _vel, _dir, _ang, _frecuencia, 0, _rotation_offset, _bounce_counter, _bounce_up, _bounce_down, _bounce_left, _bounce_right, _type, _can_Go_OffLimits)
		var _tween2: Tween = CreateTween_ArrayAppend(_bullet.tween_Array)
		_tween2.tween_property(_bullet, "amplitud", _amplitud, 0.3)
		_ang += 360/_num
		_bullet_array.append(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet_array
#endregion
#-------------------------------------------------------------------------------
#region STAGE_1: SPELLCARD
func Stage1_SpellCard1(_boss: Boss):
	var _tween: Tween = CreateTween_ArrayAppend(_boss.tween_Array)
	_tween.set_loops()
	Stage1_SpellCard1_Mirror(_boss, _tween, 1)
	Stage1_SpellCard1_Mirror(_boss, _tween, -1)
#-------------------------------------------------------------------------------
func Stage1_SpellCard1_Mirror(_node2d:Node2D, _tween:Tween, _mirror: float):
	var _dir: float
	var _dir2: float = 0.0
	var _max1: float = 10.0 + 10.0 * (difficulty + 1.0)
	var _max2: int = int(10.0 + 10.0 * (difficulty + 1.0))
	var _vel1: float = 4.0
	var _vel2: float = 1.0
	var _dvel: float = (_vel2-_vel1)/_max2
	var _frame: int = 0
	#-------------------------------------------------------------------------------
	for _j in _max2:
		_dir = 0.0
		_frame = _j % bullet_Color_Id_Max
		#-------------------------------------------------------------------------------
		for _i in _max1:
			_tween.tween_callback(func():Stage1_SpellCard1_Bullet1(_node2d, _dir+_dir2*_mirror, _vel1, _mirror))
			_dir += 360/_max1
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.1)
		_vel1 += _dvel
		_dir2 += 2
	#-------------------------------------------------------------------------------
	_tween.set_parallel(false)
	_tween.tween_interval(4.0)
#-------------------------------------------------------------------------------
func Stage1_SpellCard1_Bullet1(_node2d:Node2D, _dir:float, _vel:float, _mirror: float):
	var _dir2: float = deg_to_rad(_dir)
	var _x: float = _node2d.position.x + 48 * cos(_dir2)
	var _y: float = _node2d.position.y + 48 * sin(_dir2)
	#-------------------------------------------------------------------------------
	var _bullet: Bullet = Create_EnemyBullet_A(_x, _y, 4.0, _dir, "bullet1", true)
	#-------------------------------------------------------------------------------
	var _tween: Tween = CreateTween_ArrayAppend(_bullet.tween_Array)
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
#-------------------------------------------------------------------------------
func Stage1_SpellCard2(_boss: Boss):
	var _tween: Tween = CreateTween_ArrayAppend(_boss.tween_Array)
	_tween.set_loops()
	Stage1_SpellCard2_Mirror(_boss, _tween)
#-------------------------------------------------------------------------------
func Stage1_SpellCard2_Mirror(_node2d:Node2D, _tween:Tween):
	var _dir: float
	var _dir2: float = 90.0
	var _max1: float = 10.0 + 5 * difficulty
	var _max2: int = int(10.0 + 5.0 * difficulty)
	var _vel_x: float
	var _vel_y: float
	var _frame: int = 0
	var _cone: float = 180.0
	#-------------------------------------------------------------------------------
	for _j in _max2:
		_dir = -_cone/2.0
		_dir2 = randf_range(-90.0-30.0, -90.0+30.0)
		_vel_x = 4.0
		_vel_y = randf_range(4.0, 6.0)
		_frame = _j % bullet_Color_Id_Max
		#-------------------------------------------------------------------------------
		for _i in _max1:
			var _deg_2_rad: float = deg_to_rad(_dir+_dir2)
			var _vel_x2: float = _vel_x * cos(_deg_2_rad)
			var _vel_y2: float = _vel_y * sin(_deg_2_rad)
			#-------------------------------------------------------------------------------
			_tween.tween_callback(func():
				var _bullet: Bullet = Create_EnemyBullet_B(_node2d.position.x, _node2d.position.y, _vel_x2, _vel_y2, "bullet-b1", true)
				var _tween2: Tween = CreateTween_ArrayAppend(_bullet.tween_Array)
				_tween2.tween_property(_bullet, "vel_Y", randf_range(3.0, 5.0), 2.0)
				#-------------------------------------------------------------------------------
				_tween2.tween_interval(3.0)
				_tween2.tween_callback(func():
					_bullet.can_Go_OffLimits = false
				)
				#-------------------------------------------------------------------------------
			)
			#-------------------------------------------------------------------------------
			_dir += _cone/(_max1-1.0)
		#-------------------------------------------------------------------------------
		_tween.tween_interval(0.1)
	#-------------------------------------------------------------------------------
	_tween.set_parallel(false)
	_tween.tween_interval(4.0)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_2
func Stage2():
	await Stage_Completed(2,1)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_3
func Stage3():
	await Stage_Completed(3,2)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_4
func Stage4():
	await Stage_Completed(4,3)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_5
func Stage5():
	await Stage_Completed(5,4)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_6
func Stage6():
	await Stage_Completed(6,5)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_7
func Stage7():
	await Stage_Completed(7,6)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_8
func Stage_RougeLike():
	await Stage_Completed(8,7)
#endregion
#-------------------------------------------------------------------------------
#region STAGE_9
func Stage_BossRish():
	await Stage_Completed(8,8)
#endregion
#-------------------------------------------------------------------------------
#region PLAYER FUNCTIONS
func PlayerShoot():
	if(Input.is_action_pressed("input_Shoot")):
		player_shoot_counter += deltaTimeScale
		#-------------------------------------------------------------------------------
		if(player_shoot_counter > 5.0):
			player_shoot_counter = 0.0
			Create_PlayerBullet(player.position.x-15, player.position.y-50, 18.0, -90.0, "bullet1")
			Create_PlayerBullet(player.position.x+15, player.position.y-50, 18.0, -90.0, "bullet1")
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Player_Shooted():
	player.canBeHit = false
	if(lifePoints > 0):
		PlayerRespawn()
	#-------------------------------------------------------------------------------
	else:
		PlayerGameOver()
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
	explotion.position = player.position
	explotion_anim.play("Explotion")
	#-------------------------------------------------------------------------------
	for _i in range(items_Enabled_Array.size()-1,-1,-1):
		if(items_Enabled_Array[_i].myITEM_STATE == Item.ITEM_STATE.IMANTED):
			items_Enabled_Array[_i].vel_Y = -4
			items_Enabled_Array[_i].myITEM_STATE = Item.ITEM_STATE.SPIN
#endregion
#-------------------------------------------------------------------------------
#region PLAYER BULLET FUNCTIONS
func Create_PlayerBullets_Disabled(_iMax:int):
	for _i in _iMax:
		var _bullet: Bullet = bullet_Prefab.instantiate() as Bullet
		playerBullets_Disabled_Array.append(_bullet)
		#_bullet.physics_Update = func(): PlayerBullet_PhysicsUpdate(_bullet)
		_bullet.hide()
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_PlayerBullet(_x:float, _y:float, _v:float, _dir:float, _type:String) ->Bullet:
	var _bullet: Bullet
	#-------------------------------------------------------------------------------
	if(playerBullets_Disabled_Array.size() > 0):
		_bullet = playerBullets_Disabled_Array[0]
		_bullet.show()
		playerBullets_Disabled_Array.erase(_bullet)
	#-------------------------------------------------------------------------------
	else:
		_bullet = bullet_Prefab.instantiate() as Bullet
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
	_bullet.physics_Update = func(): PlayerBullet_PhysicsUpdate(_bullet)
	#-------------------------------------------------------------------------------
	playerBullets_Enabled_Array.append(_bullet)
	#-------------------------------------------------------------------------------
	var _bulletResource: BulletResource = bulletDictionary.get(_type, "bullet1")
	_bullet.texture = _bulletResource.texture
	_bullet.radius = _bulletResource.radius
	#-------------------------------------------------------------------------------
	_bullet.position = Vector2(_x, _y)
	_bullet.isGrazed = false
	_bullet.dir = _dir
	_bullet.rotation_degrees = _bullet.dir
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
	var _dir2: float = deg_to_rad(_bullet.dir)
	_bullet.vel_X = _bullet.vel * cos(_dir2)
	_bullet.vel_Y = _bullet.vel * sin(_dir2)
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.position.x += _bullet.vel_X * deltaTimeScale
	_bullet.position.y += _bullet.vel_Y * deltaTimeScale
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
	_item.vel_Y =  _vel_y
	#-------------------------------------------------------------------------------
	_item.radius = 15.0
	#-------------------------------------------------------------------------------
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
			if(_item.vel_Y <= 0):
				_item.vel_Y += _velY_Accel * deltaTimeScale
				_item.position.y += _item.vel_Y * deltaTimeScale
				_item.rotation += 0.2 * deltaTimeScale
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
				if(_item.vel_Y > _velY_Max):
					_item.vel_Y = _velY_Max
				#-------------------------------------------------------------------------------
				elif(_item.vel_Y < _velY_Max):
					_item.vel_Y += _velY_Accel * deltaTimeScale
				#-------------------------------------------------------------------------------
				_item.position.y += _item.vel_Y * deltaTimeScale
				#-------------------------------------------------------------------------------
				if(player.myPLAYER_STATE != Player.PLAYER_STATE.DEATH):
					if(_item.position.distance_to(player.position) < (_item.radius+player.magnetBox_radius) or myGAME_STATE != GAME_STATE.IN_GAMEPLAY):
						_item.myITEM_STATE = Item.ITEM_STATE.IMANTED
						return
					#-------------------------------------------------------------------------------
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
				moneyPoints += 1
				#-------------------------------------------------------------------------------
				if(moneyPoints > player.playerResource.maxMoney):
					moneyPoints = player.playerResource.maxMoney
					scorePoints += 10
				#-------------------------------------------------------------------------------
				else:
					scorePoints += 20
				#-------------------------------------------------------------------------------
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
		_boss.hide()
		content.add_child(_boss)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Boss(_x:float, _y:float) -> Boss:
	var _boss: Boss
	#-------------------------------------------------------------------------------
	if(enemy_Disabled_Array.size() > 0):
		_boss = boss_Disabled_Array[0]
		_boss.show()
	#-------------------------------------------------------------------------------
	else:
		_boss = boss_Prefab.instantiate() as Boss
		boss_Disabled_Array.append(_boss)
		content.add_child(_boss)
	#-------------------------------------------------------------------------------
	_boss.physics_Update = func():Boss_PhysicsUpdate(_boss)
	#-------------------------------------------------------------------------------
	_boss.position = Vector2(_x, _y)
	#-------------------------------------------------------------------------------
	_boss.hitbox_radius = 30.0
	_boss.hurtbox_radius = 45.0
	#-------------------------------------------------------------------------------
	_boss.vel = 0
	_boss.dir = 90
	#-------------------------------------------------------------------------------
	_boss.canBeHit = false
	_boss.label.hide()
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
	for _i in range(playerBullets_Enabled_Array.size()-1,-1,-1):
		var _bullet: Bullet = playerBullets_Enabled_Array[_i]
		#-------------------------------------------------------------------------------
		if(_bullet.position.distance_to(_boss.position) < (_bullet.radius+_boss.hurtbox_radius) and _boss.canBeHit):
			_boss.hp -=1
			Set_BossLife_Label(_boss)
			Destroy_PlayerBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_boss.dir)
	_boss.vel_X = _boss.vel * cos(_dir2)
	_boss.vel_Y = _boss.vel * sin(_dir2)
	_boss.sprite.rotation_degrees = _boss.dir - 90		#NOTA: Borrar si quiero enemigos que miren para abajo.
	#-------------------------------------------------------------------------------
	_boss.position.x += _boss.vel_X * deltaTimeScale
	_boss.position.y += _boss.vel_Y * deltaTimeScale
	#-------------------------------------------------------------------------------
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
	Set_CommonLife_Label(_boss.label, _boss.hp, _boss.maxHp)
#-------------------------------------------------------------------------------
func Set_CommonLife_Label(_label:Label, _hp:int, _maxHp:int):
	_label.text = "  "+str(_hp)+" / "+str(_maxHp) + " hp"
#endregion
#-------------------------------------------------------------------------------
#region ENEMY FUNCTIONS
func Create_Enemy_Disabled(_iMax:int):
	for _i in _iMax:
		var _enemy: Enemy = enemy_Prefab.instantiate() as Enemy
		enemy_Disabled_Array.append(_enemy)
		#_enemy.physics_Update = func(): Enemy_PhysicsUpdate(_enemy)
		_enemy.hide()
		content.add_child(_enemy)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Enemy(_x:float, _y:float, _v:float, _dir: float, _hp: int) -> Enemy:
	var _enemy: Enemy = Create_Enemy_Common(_x, _y, _v, _dir, _hp)
	_enemy.physics_Update = func(): Enemy_PhysicsUpdate(_enemy)
	return _enemy
#-------------------------------------------------------------------------------
func Enemy_PhysicsUpdate(_enemy:Enemy):
	if(_enemy.hp <= 0):
		Destroy_Enemy_with_Death_Signal(_enemy)
		var _num: int = 7+int(3*difficulty)
		Create_Items(_enemy.position.x, _enemy.position.y, 25, _num, -3)
		return
	#-------------------------------------------------------------------------------
	for _i in range(playerBullets_Enabled_Array.size()-1,-1,-1):
		var _bullet: Bullet = playerBullets_Enabled_Array[_i]
		#-------------------------------------------------------------------------------
		if(_bullet.position.distance_to(_enemy.position) < (_bullet.radius+_enemy.hurtbox_radius) and _enemy.canBeHit):
			_enemy.hp -=1
			Set_EnemyLife_Label(_enemy)
			Destroy_PlayerBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_enemy.dir)
	_enemy.vel_X = _enemy.vel * cos(_dir2)
	_enemy.vel_Y = _enemy.vel * sin(_dir2)
	_enemy.sprite.rotation_degrees = _enemy.dir + _enemy.rotation_offset		#NOTA: Borrar si quiero enemigos que miren para abajo.
	#-------------------------------------------------------------------------------
	_enemy.position.x += _enemy.vel_X * deltaTimeScale
	_enemy.position.y += _enemy.vel_Y * deltaTimeScale
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Enemy_Senoidal(_x:float, _y:float, _v:float, _dir:float, _spin:float, _frecuencia:float, _amplitud:float, _hp: int) -> Enemy:
	var _enemy: Enemy = Create_Enemy_Common(_x, _y, _v, _dir, _hp)
	_enemy.physics_Update = func(): Enemy_PhysicsUpdate_Senoidal(_enemy)
	#-------------------------------------------------------------------------------
	_enemy.pos_X = _enemy.position.x
	_enemy.pos_Y = _enemy.position.y
	#-------------------------------------------------------------------------------
	_enemy.spin = _spin
	_enemy.frecuencia = _frecuencia
	_enemy.amplitud = _amplitud
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_dir)
	#-------------------------------------------------------------------------------
	_enemy.vel_X = _enemy.vel * cos(_dir2)
	_enemy.vel_Y = _enemy.vel * sin(_dir2)
	#-------------------------------------------------------------------------------
	var _dir2_perpendicular: float = deg_to_rad(_dir + 90)
	#-------------------------------------------------------------------------------
	_enemy.amplitud_x = _enemy.amplitud * cos(_dir2_perpendicular)
	_enemy.amplitud_y = _enemy.amplitud * sin(_dir2_perpendicular)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Enemy_PhysicsUpdate_Senoidal(_enemy:Enemy):
	if(_enemy.hp <= 0):
		Destroy_Enemy_with_Death_Signal(_enemy)
		var _num: int = 7+int(3*difficulty)
		Create_Items(_enemy.position.x, _enemy.position.y, 25, _num, -3)
		return
	#-------------------------------------------------------------------------------
	for _i in range(playerBullets_Enabled_Array.size()-1,-1,-1):
		var _bullet: Bullet = playerBullets_Enabled_Array[_i]
		#-------------------------------------------------------------------------------
		if(_bullet.position.distance_to(_enemy.position) < (_bullet.radius+_enemy.hurtbox_radius) and _enemy.canBeHit):
			_enemy.hp -=1
			Set_EnemyLife_Label(_enemy)
			Destroy_PlayerBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	_enemy.spin += _enemy.frecuencia * deltaTimeScale
	var _seno: float = sin(deg_to_rad(_enemy.spin))
	#-------------------------------------------------------------------------------
	var _pos_x: float = _enemy.amplitud_x * _seno
	var _pos_y: float = _enemy.amplitud_y * _seno
	#-------------------------------------------------------------------------------
	_enemy.pos_X += _enemy.vel_X * deltaTimeScale
	_enemy.pos_Y += _enemy.vel_Y * deltaTimeScale
	#-------------------------------------------------------------------------------
	var _pos_X_new: float = _enemy.pos_X +_pos_x
	var _pos_Y_new: float = _enemy.pos_Y +_pos_y
	#-------------------------------------------------------------------------------
	_enemy.sprite.rotation_degrees = rad_to_deg(atan2(_pos_Y_new-_enemy.position.y, _pos_X_new-_enemy.position.x)) + _enemy.rotation_offset
	#-------------------------------------------------------------------------------
	_enemy.position.x = _pos_X_new
	_enemy.position.y = _pos_Y_new
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_Enemy_Common(_x:float, _y:float, _v:float, _dir: float, _hp: int) -> Enemy:
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
		content.add_child(_enemy)
	#-------------------------------------------------------------------------------
	enemy_Enabled_Array.append(_enemy)
	
	#-------------------------------------------------------------------------------
	_enemy.position = Vector2(_x, _y)
	#-------------------------------------------------------------------------------
	_enemy.maxHp = _hp
	_enemy.hp = _hp
	_enemy.vel = _v
	_enemy.dir = _dir
	#-------------------------------------------------------------------------------
	SetEnemyAnim_SmallShip(_enemy)
	#-------------------------------------------------------------------------------
	Set_EnemyLife_Label(_enemy)
	#-------------------------------------------------------------------------------
	return _enemy
#-------------------------------------------------------------------------------
func Destroy_Enemy_with_Death_Signal(_enemy: Enemy):
	_enemy.death_signal.emit()
	Destroy_Enemy(_enemy)
#-------------------------------------------------------------------------------
func Destroy_Enemy(_enemy: Enemy):
	KillTween_Array(_enemy.tween_Array)
	enemy_Enabled_Array.erase(_enemy)
	enemy_Disabled_Array.append(_enemy)
	singleton.DisconnectAll(_enemy.death_signal)
	_enemy.hide()
#-------------------------------------------------------------------------------
func Pause_Tween_Until_Enemy_Death(_enemy:Enemy, _tween: Tween):
	singleton.DisconnectAll(_enemy.death_signal)
	#-------------------------------------------------------------------------------
	_enemy.death_signal.connect(func():
		_tween.play()
	)
	#-------------------------------------------------------------------------------
	_tween.pause()
#-------------------------------------------------------------------------------
func Set_EnemyLife_Label(_enemy: Enemy):
	Set_CommonLife_Label(_enemy.label, _enemy.hp, _enemy.maxHp)
#endregion
#-------------------------------------------------------------------------------
#region ENEMY ANIMATIONS
func SetEnemyAnim_SmallShip(_enemy:Enemy):
	_enemy.animationTree.active = true
	#-------------------------------------------------------------------------------
	_enemy.sprite.hframes = 2
	_enemy.sprite.vframes = 1
	_enemy.sprite.texture = smallShip_sprite
	_enemy.sprite.frame = 0
	_enemy.sprite.offset = Vector2(0, -3)
	#-------------------------------------------------------------------------------
	Set_Enemy_Rotation(_enemy, -90)
	#-------------------------------------------------------------------------------
	_enemy.hitbox_radius = 15.0
	_enemy.hurtbox_radius = 30.0
	_enemy.shadow.scale = Vector2(0.08, 0.08)
	_enemy.shadow.offset = Vector2(0, -30)
#-------------------------------------------------------------------------------
func SetEnemyAnim_MidShip(_enemy:Enemy):
	_enemy.animationTree.active = true
	#-------------------------------------------------------------------------------
	_enemy.sprite.hframes = 2
	_enemy.sprite.vframes = 1
	_enemy.sprite.texture = midShip_sprite
	_enemy.sprite.frame = 0
	_enemy.sprite.offset = Vector2(0, 0)
	#-------------------------------------------------------------------------------
	Set_Enemy_Rotation(_enemy, -90)
	#-------------------------------------------------------------------------------
	_enemy.hitbox_radius = 15.0
	_enemy.hurtbox_radius = 30.0
	_enemy.shadow.scale = Vector2(0.14, 0.08)
	_enemy.shadow.offset = Vector2(0, 0)
#-------------------------------------------------------------------------------
func SetEnemyAnim_BigShip(_enemy:Enemy):
	_enemy.animationTree.active = true
	#-------------------------------------------------------------------------------
	_enemy.sprite.hframes = 2
	_enemy.sprite.vframes = 1
	_enemy.sprite.texture = bigShip_sprite
	_enemy.sprite.frame = 0
	_enemy.sprite.offset = Vector2(0, 0)
	#-------------------------------------------------------------------------------
	Set_Enemy_Rotation(_enemy, -90)
	#-------------------------------------------------------------------------------
	_enemy.hitbox_radius = 15.0
	_enemy.hurtbox_radius = 30.0
	_enemy.shadow.scale = Vector2(0.08, 0.08)
	_enemy.shadow.offset = Vector2(0, 0)
#-------------------------------------------------------------------------------
func SetEnemyAnim_SmallMeteorite(_enemy:Enemy):
	_enemy.animationTree.active = false
	#-------------------------------------------------------------------------------
	_enemy.sprite.hframes = 3
	_enemy.sprite.vframes = 3
	_enemy.sprite.texture = asteroid_sprite
	_enemy.sprite.frame = randi_range(6, 8)
	_enemy.sprite.offset = Vector2(0, 0)
	#-------------------------------------------------------------------------------
	Set_Enemy_Rotation(_enemy, randf_range(0, 360))
	#-------------------------------------------------------------------------------
	_enemy.hitbox_radius = 20.0
	_enemy.hurtbox_radius = 30.0
	_enemy.shadow.scale = Vector2(0.08, 0.08)
	_enemy.shadow.offset = Vector2(0, 0)
#-------------------------------------------------------------------------------
func SetEnemyAnim_MidMeteorite(_enemy:Enemy):
	_enemy.animationTree.active = false
	#-------------------------------------------------------------------------------
	_enemy.sprite.hframes = 3
	_enemy.sprite.vframes = 3
	_enemy.sprite.texture = asteroid_sprite
	_enemy.sprite.frame = randi_range(3, 5)
	_enemy.sprite.offset = Vector2(0, 0)
	#-------------------------------------------------------------------------------
	Set_Enemy_Rotation(_enemy, randf_range(0, 360))
	#-------------------------------------------------------------------------------
	_enemy.hitbox_radius = 35.0
	_enemy.hurtbox_radius = 45.0
	_enemy.shadow.scale = Vector2(0.13, 0.13)
	_enemy.shadow.offset = Vector2(0, 0)
#-------------------------------------------------------------------------------
func Set_Enemy_Rotation(_enemy:Enemy, _rotation_offset: float):
	_enemy.rotation_offset = _rotation_offset
	_enemy.sprite.rotation_degrees = _enemy.dir + _rotation_offset
#endregion
#-------------------------------------------------------------------------------
#region ENEMY BULLET FUNCTIONS
func Create_EnemyBullets_Disabled(_iMax:int):
	for _i in _iMax:
		var _bullet: Bullet = bullet_Prefab.instantiate() as Bullet
		enemyBullets_Disabled_Array.append(_bullet)
		_bullet.hide()
		#_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate(_bullet)
		content.add_child(_bullet)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func Create_EnemyBullet_A(_x:float, _y:float, _v:float, _dir:float, _type:String, _can_Go_OffLimits:bool) ->Bullet:
	var _bullet: Bullet = Create_EnemyBullet_Common(_x, _y, _type, _can_Go_OffLimits)
	#-------------------------------------------------------------------------------
	_bullet.vel = _v
	_bullet.dir = _dir
	_bullet.rotation_degrees = _bullet.dir
	_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate_A(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func Create_EnemyBullet_B(_x:float, _y:float, _velX:float, _velY:float, _type:String, _can_Go_OffLimits:bool) ->Bullet:
	var _bullet: Bullet = Create_EnemyBullet_Common(_x, _y, _type, _can_Go_OffLimits)
	#-------------------------------------------------------------------------------
	_bullet.vel_X = _velX
	_bullet.vel_Y = _velY
	_bullet.rotation_degrees = GetAngleXY(_velX, _velY)
	_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate_B(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func Create_EnemyBullet_Senoidal(_x:float, _y:float, _v:float, _dir:float, _spin:float, _frecuencia:float, _amplitud:float, _type:String, _can_Go_OffLimits:bool) ->Bullet:
	var _bullet: Bullet = Create_EnemyBullet_Common(_x, _y, _type, _can_Go_OffLimits)
	#-------------------------------------------------------------------------------
	_bullet.pos_X = _x
	_bullet.pos_Y = _y
	#-------------------------------------------------------------------------------
	_bullet.vel = _v
	_bullet.dir = _dir
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.spin = _spin
	_bullet.frecuencia = _frecuencia
	_bullet.amplitud = _amplitud
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_dir)
	#-------------------------------------------------------------------------------
	_bullet.vel_X = _bullet.vel * cos(_dir2)
	_bullet.vel_Y = _bullet.vel * sin(_dir2)
	#-------------------------------------------------------------------------------
	var _dir2_perpendicular: float = deg_to_rad(_dir + 90)
	#-------------------------------------------------------------------------------
	_bullet.amplitud_x = _bullet.amplitud * cos(_dir2_perpendicular)
	_bullet.amplitud_y = _bullet.amplitud * sin(_dir2_perpendicular)
	#-------------------------------------------------------------------------------
	_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate_Senoidal(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func Create_EnemyBullet_Bounce(_x:float, _y:float, _v:float, _dir:float, _bounce_counter: int, _bounce_up: bool, _bounce_down: bool, _bounce_left: bool, _bounce_right: bool, _type:String, _can_Go_OffLimits:bool) ->Bullet:
	var _bullet: Bullet = Create_EnemyBullet_Common(_x, _y, _type, _can_Go_OffLimits)
	#-------------------------------------------------------------------------------
	_bullet.vel = _v
	_bullet.dir = _dir
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.bounce_counter = _bounce_counter
	_bullet.bounce_up = _bounce_up
	_bullet.bounce_down = _bounce_down
	_bullet.bounce_left = _bounce_left
	_bullet.bounce_right = _bounce_right
	#-------------------------------------------------------------------------------
	_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate_Bounce(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func Create_EnemyBullet_Spin(_x:float, _y:float, _v:float, _dir:float, _spin:float, _frecuencia:float, _amplitud:float, _rotation_offset:float, _bounce_counter: int, _bounce_up: bool, _bounce_down: bool, _bounce_left: bool, _bounce_right: bool, _type:String, _can_Go_OffLimits:bool) ->Bullet:
	var _bullet: Bullet = Create_EnemyBullet_Common(_x, _y, _type, _can_Go_OffLimits)
	#-------------------------------------------------------------------------------
	_bullet.pos_X = _x
	_bullet.pos_Y = _y
	#-------------------------------------------------------------------------------
	_bullet.vel = _v
	_bullet.dir = _dir
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.rotation_offset = _rotation_offset
	#-------------------------------------------------------------------------------
	_bullet.spin = _spin
	_bullet.frecuencia = _frecuencia
	_bullet.amplitud = _amplitud
	#-------------------------------------------------------------------------------
	#var _dir2: float = deg_to_rad(_dir)
	#-------------------------------------------------------------------------------
	#_bullet.vel_X = _bullet.vel * cos(_dir2)
	#_bullet.vel_Y = _bullet.vel * sin(_dir2)
	#-------------------------------------------------------------------------------
	#var _dir2_perpendicular: float = deg_to_rad(_dir + 90)
	#-------------------------------------------------------------------------------
	#_bullet.amplitud_x = _bullet.amplitud * cos(_dir2_perpendicular)
	#_bullet.amplitud_y = _bullet.amplitud * sin(_dir2_perpendicular)
	#-------------------------------------------------------------------------------
	_bullet.bounce_counter = _bounce_counter
	_bullet.bounce_up = _bounce_up
	_bullet.bounce_down = _bounce_down
	_bullet.bounce_left = _bounce_left
	_bullet.bounce_right = _bounce_right
	#-------------------------------------------------------------------------------
	_bullet.physics_Update = func(): EnemyBullet_PhysicsUpdate_Spin(_bullet)
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func Create_EnemyBullet_Common(_x:float, _y:float, _type:String, _can_Go_OffLimits:bool) ->Bullet:
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
	#-------------------------------------------------------------------------------
	enemyBullets_Enabled_Array.append(_bullet)
	#-------------------------------------------------------------------------------
	var _bulletResource: BulletResource = bulletDictionary.get(_type, "bullet1")
	_bullet.texture = _bulletResource.texture
	#-------------------------------------------------------------------------------
	_bullet.radius = _bulletResource.radius
	#-------------------------------------------------------------------------------
	_bullet.position = Vector2(_x, _y)
	_bullet.isGrazed = false
	_bullet.can_Go_OffLimits = _can_Go_OffLimits
	#-------------------------------------------------------------------------------
	return _bullet
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_A(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless_A(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.position.x > enemyLimitsX.x and _bullet.position.x < enemyLimitsX.y):
		if(_bullet.position.y > enemyLimitsY.x and _bullet.position.y < enemyLimitsY.y):
			EnemyBullet_PhysicsUpdate_Limitless_A(_bullet)
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
func EnemyBullet_PhysicsUpdate_Limitless_A(_bullet: Bullet):
	var _dir2: float = deg_to_rad(_bullet.dir)
	_bullet.vel_X = _bullet.vel * cos(_dir2)
	_bullet.vel_Y = _bullet.vel * sin(_dir2)
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.position.x += _bullet.vel_X * deltaTimeScale
	_bullet.position.y += _bullet.vel_Y * deltaTimeScale
	return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_B(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless_B(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.position.x > enemyLimitsX.x and _bullet.position.x < enemyLimitsX.y):
		if(_bullet.position.y > enemyLimitsY.x and _bullet.position.y < enemyLimitsY.y):
			EnemyBullet_PhysicsUpdate_Limitless_B(_bullet)
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
func EnemyBullet_PhysicsUpdate_Limitless_B(_bullet: Bullet):
	_bullet.rotation_degrees = GetAngleXY(_bullet.vel_X, _bullet.vel_Y)
	#-------------------------------------------------------------------------------
	_bullet.position.x += _bullet.vel_X * deltaTimeScale
	_bullet.position.y += _bullet.vel_Y * deltaTimeScale
	return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Senoidal(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless_Senoidal(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.position.x > enemyLimitsX.x and _bullet.position.x < enemyLimitsX.y):
		if(_bullet.position.y > enemyLimitsY.x and _bullet.position.y < enemyLimitsY.y):
			EnemyBullet_PhysicsUpdate_Limitless_Senoidal(_bullet)
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
func EnemyBullet_PhysicsUpdate_Limitless_Senoidal(_bullet: Bullet):
	#-------------------------------------------------------------------------------
	_bullet.spin += _bullet.frecuencia * deltaTimeScale
	var _seno: float = sin(deg_to_rad(_bullet.spin))
	#-------------------------------------------------------------------------------
	var _pos_x: float = _bullet.amplitud_x * _seno
	var _pos_y: float = _bullet.amplitud_y * _seno
	#-------------------------------------------------------------------------------
	_bullet.pos_X += _bullet.vel_X * deltaTimeScale
	_bullet.pos_Y += _bullet.vel_Y * deltaTimeScale
	#-------------------------------------------------------------------------------
	var _pos_X_new: float = _bullet.pos_X +_pos_x
	var _pos_Y_new: float = _bullet.pos_Y +_pos_y
	#-------------------------------------------------------------------------------
	_bullet.rotation = atan2(_pos_Y_new-_bullet.position.y, _pos_X_new-_bullet.position.x)
	#-------------------------------------------------------------------------------
	_bullet.position.x = _pos_X_new
	_bullet.position.y = _pos_Y_new
	return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Bounce(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless_Bounce(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.position.y < 0):
		if(_bullet.bounce_up and _bullet.bounce_counter>0):
			_bullet.position.y = 0
			_bullet.dir = -_bullet.dir
			_bullet.bounce_counter -= 1
		#-------------------------------------------------------------------------------
		else:
			Destroy_EnemyBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	elif(_bullet.position.y > height):
		if(_bullet.bounce_down and _bullet.bounce_counter>0):
			_bullet.position.y = height
			_bullet.dir = -_bullet.dir
			_bullet.bounce_counter -= 1
		#-------------------------------------------------------------------------------
		else:
			Destroy_EnemyBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	elif(_bullet.position.x < 0):
		if(_bullet.bounce_left and _bullet.bounce_counter>0):
			_bullet.position.x = 0
			_bullet.dir = -(_bullet.dir + 180)
			_bullet.bounce_counter -= 1
		#-------------------------------------------------------------------------------
		else:
			Destroy_EnemyBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	elif(_bullet.position.x > width):
		if(_bullet.bounce_right and _bullet.bounce_counter>0):
			_bullet.position.x = width
			_bullet.dir = -(_bullet.dir + 180)
			_bullet.bounce_counter -= 1
		#-------------------------------------------------------------------------------
		else:
			Destroy_EnemyBullet(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	else:
		EnemyBullet_PhysicsUpdate_Limitless_Bounce(_bullet)
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Limitless_Bounce(_bullet: Bullet):
	var _dir2: float = deg_to_rad(_bullet.dir)
	_bullet.vel_X = _bullet.vel * cos(_dir2)
	_bullet.vel_Y = _bullet.vel * sin(_dir2)
	_bullet.rotation_degrees = _bullet.dir
	#-------------------------------------------------------------------------------
	_bullet.position.x += _bullet.vel_X * deltaTimeScale
	_bullet.position.y += _bullet.vel_Y * deltaTimeScale
	return
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Spin(_bullet: Bullet):
	if(_bullet.can_Go_OffLimits):
		EnemyBullet_PhysicsUpdate_Limitless_Spin(_bullet)
		return
	#-------------------------------------------------------------------------------
	if(_bullet.bounce_counter>0):
		if(_bullet.pos_Y < 0):
			if(_bullet.bounce_up):
				_bullet.pos_Y = 0
				_bullet.dir = -_bullet.dir
				_bullet.bounce_counter -= 1
			#-------------------------------------------------------------------------------
			else:
				Destroy_EnemyBullet(_bullet)
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		elif(_bullet.pos_Y > height):
			if(_bullet.bounce_down):
				_bullet.pos_Y = height
				_bullet.dir = -_bullet.dir
				_bullet.bounce_counter -= 1
			#-------------------------------------------------------------------------------
			else:
				Destroy_EnemyBullet(_bullet)
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		elif(_bullet.pos_X < 0):
			if(_bullet.bounce_left):
				_bullet.pos_X = 0
				_bullet.dir = -(_bullet.dir + 180)
				_bullet.bounce_counter -= 1
			#-------------------------------------------------------------------------------
			else:
				Destroy_EnemyBullet(_bullet)
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		elif(_bullet.pos_X > width):
			if(_bullet.bounce_right):
				_bullet.pos_X = width
				_bullet.dir = -(_bullet.dir + 180)
				_bullet.bounce_counter -= 1
			#-------------------------------------------------------------------------------
			else:
				Destroy_EnemyBullet(_bullet)
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		else:
			EnemyBullet_PhysicsUpdate_Limitless_Spin(_bullet)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	else:
		if(_bullet.position.x > enemyLimitsX.x-_bullet.amplitud and _bullet.position.x < enemyLimitsX.y+_bullet.amplitud):
			if(_bullet.position.y > enemyLimitsY.x-_bullet.amplitud and _bullet.position.y < enemyLimitsY.y+_bullet.amplitud):
				EnemyBullet_PhysicsUpdate_Limitless_Spin(_bullet)
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
#-------------------------------------------------------------------------------
func EnemyBullet_PhysicsUpdate_Limitless_Spin(_bullet: Bullet):
	#-------------------------------------------------------------------------------
	_bullet.spin += _bullet.frecuencia * deltaTimeScale
	var _spin: float = deg_to_rad(_bullet.spin)
	#-------------------------------------------------------------------------------
	var _pos_x: float = _bullet.amplitud * cos(_spin)
	var _pos_y: float = _bullet.amplitud * sin(_spin)
	#-------------------------------------------------------------------------------
	var _dir2: float = deg_to_rad(_bullet.dir)
	_bullet.vel_X = _bullet.vel * cos(_dir2)
	_bullet.vel_Y = _bullet.vel * sin(_dir2)
	_bullet.pos_X += _bullet.vel_X * deltaTimeScale
	_bullet.pos_Y += _bullet.vel_Y * deltaTimeScale
	#-------------------------------------------------------------------------------
	var _pos_X_new: float = _bullet.pos_X +_pos_x
	var _pos_Y_new: float = _bullet.pos_Y +_pos_y
	#-------------------------------------------------------------------------------
	_bullet.rotation = rad_to_deg(atan2(_pos_y, _pos_x)) + _bullet.rotation_offset
	#-------------------------------------------------------------------------------
	_bullet.position.x = _pos_X_new
	_bullet.position.y = _pos_Y_new
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
	timerLabel.text = "  "+str(_i).pad_zeros(2)+" / " +str(_iMax).pad_zeros(2) + " s"
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
#-------------------------------------------------------------------------------
func Get_Center_X(_f: float) -> float:
	var _x: float = width * 0.5 + width * _f
	return _x
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
