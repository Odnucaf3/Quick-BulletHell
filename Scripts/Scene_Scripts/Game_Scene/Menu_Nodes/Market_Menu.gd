extends Panel
class_name Market_Menu
#region VARIABLES
var singleton: Singleton
@export var gameScene: Game_Scene
#-------------------------------------------------------------------------------
@export_group("Buy Menu Properties")
@export var buyMenu: VBoxContainer
@export var scrollContainer: ScrollContainer
@export var cardContainer: HBoxContainer
@export var cardPrefab: PackedScene
@export var cardButton: Array[Button]
var cardDictionary: Dictionary
@export var cardDictionary_Path: String = "res://Resources/Cards/"
@export var deckTexture: Texture2D
@export var description: RichTextLabel
#-------------------------------------------------------------------------------
@export_group("Confirm Menu Properties")
@export var confirmCard_Panel: Panel
@export var confirmCard_Artwork: TextureRect
@export var confirmCard_Hold: Label
@export var confirmCard_Price: Label
@export var confirmMenu: MarginContainer
@export var confirmCard_Title: Label
@export var yesButton: Button
@export var noButton: Button
const buttonSize: Vector2 = Vector2(225, 225)
#-------------------------------------------------------------------------------
signal closeMarket_signal
#endregion
#-------------------------------------------------------------------------------
#region STATE MACHINE
func Start():
	singleton = get_node("/root/singleton")
	#-------------------------------------------------------------------------------
	LoadCardDatabase()
	#-------------------------------------------------------------------------------
	buyMenu.hide()
	confirmMenu.hide()
	hide()
#endregion
#-------------------------------------------------------------------------------
#region CREATE MARKET FUNCTIONS
func LoadCardDatabase():
	cardDictionary.clear()
	#-------------------------------------------------------------------------------
	var dir_array = DirAccess.get_files_at(cardDictionary_Path)
	if(dir_array):
		for _i in dir_array.size():
			var _base_name: String = dir_array[_i].get_slice(".",0)
			var _card: CardResource = load(cardDictionary_Path+"/"+_base_name+".tres") as CardResource
			cardDictionary[_base_name] = _card
#-------------------------------------------------------------------------------
func OpenMarket():
	CreateCardMarket()
	scrollContainer.custom_minimum_size = buttonSize
	#-------------------------------------------------------------------------------
	var _i: int
	#-------------------------------------------------------------------------------
	if(cardButton.size()>0):
		_i = 1
	#-------------------------------------------------------------------------------
	else:
		_i = 0
	#-------------------------------------------------------------------------------
	singleton.MoveToButton(cardButton[_i])
	scrollContainer.scroll_horizontal = int(buttonSize.x + cardContainer.get_theme_constant("separation")) * _i	#NOTA IMPORTANTE: Por alguna razon el boton no se alinea con el container la primera vez, hay que ayudarlo
	#-------------------------------------------------------------------------------
	buyMenu.show()
	confirmMenu.hide()
	show()
	await closeMarket_signal
#-------------------------------------------------------------------------------
func CreateCardMarket() ->void:
	DeleteCardButtons()
	CreateDeckButton()
	for _key in cardDictionary:
		CreateCardButton(cardDictionary[_key])
#-------------------------------------------------------------------------------
func DeleteCardButtons() -> void:
	for _cb in cardButton:
		_cb.queue_free()
	cardButton.clear()
	ClearContainer()
#-------------------------------------------------------------------------------
func ClearContainer():
	for _child in cardContainer.get_children():
		_child.queue_free()
#-------------------------------------------------------------------------------
func CreateCardButton(_cr: CardResource):
	var _cb : CardButton = CreateCardButton_Common(_cr.artwork)
	#-------------------------------------------------------------------------------
	var _selected: Callable = func():CardButton_Selected(GetCardText_ID(_cr))
	var _submited: Callable = func():CardButton_Subited(_cr, _cb)
	singleton.SetButton(_cb, _selected, _submited, CardButton_Canceled)
	#-------------------------------------------------------------------------------
	_cb.hold.text = GetCardText_Hold(_cr)
	_cb.price.text = GetCardText_Price(_cr)
#-------------------------------------------------------------------------------
func CreateDeckButton():
	var _cb : CardButton = CreateCardButton_Common(deckTexture)
	singleton.SetButton(_cb, func():CardButton_Selected("card_id_0"), func():DeckButton_Submit(_cb), func():DeckButton_Canceled(_cb))
	_cb.hold.text = ""
	_cb.price.text = ""
#-------------------------------------------------------------------------------
func CreateCardButton_Common(_texture: Texture2D) -> CardButton:
	var _cb : CardButton = cardPrefab.instantiate() as CardButton
	_cb.custom_minimum_size = buttonSize
	if(singleton.useCustomButton):
		_cb.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_cb.artwork.texture = _texture
	cardContainer.add_child(_cb)
	cardButton.append(_cb)
	return _cb
#-------------------------------------------------------------------------------
func GetCardText_Hold(_cr:CardResource) -> String:
	var _s: String = str(GetCard_Hold(_cr)) + " / " + str(_cr.maxHold)
	return _s
#-------------------------------------------------------------------------------
func GetCard_Hold(_cr:CardResource) -> int:
	var _i:int = _cr.maxHold - gameScene.cardInventory.get(_cr, 0)
	return _i
#-------------------------------------------------------------------------------
func GetCardText_Price(_cr:CardResource) -> String:
	var _s: String = "   " + str(GetCard_Price(_cr)) + " $"
	return _s
#-------------------------------------------------------------------------------
func GetCard_Price(_cr:CardResource) -> int:
	var _i:int = _cr.price * (1 + gameScene.cardInventory.get(_cr, 0))
	return _i
#-------------------------------------------------------------------------------
func GetCardText_ID(_cr:CardResource) -> String:
	var _s: String = cardDictionary.find_key(_cr)
	return _s
#-------------------------------------------------------------------------------
func GetCardText_Name(_id:String) -> String:
	var _s: String = tr("name_"+_id)
	return _s
#-------------------------------------------------------------------------------
func GetCardText_Description(_id:String) -> String:
	var _s: String = tr("desc_"+_id)
	return _s
#endregion
#-------------------------------------------------------------------------------
#region CARD BUTTON FUNCTIONS
func CardButton_Selected(_id:String) -> void:
	var _s: String = "[center][u][font_size=35]"+ GetCardText_Name(_id) + "[/font_size][/u][font_size=20]\n"
	_s += _id+"\n"
	_s += GetCardText_Description(_id)
	description.text = _s
	singleton.CommonSelected()
#-------------------------------------------------------------------------------
func CardButton_Subited(_cr:CardResource, _cb:CardButton) -> void:
	if(GetCard_Price(_cr) <= gameScene.moneyPoints and GetCard_Hold(_cr) > 0):
		confirmCard_Hold.text = GetCardText_Hold(_cr)
		confirmCard_Price.text = GetCardText_Price(_cr)
		confirmCard_Title.text = "Do You Want to Buy This Card?"
		#-------------------------------------------------------------------------------
		var _submit: Callable = func(): ConfirmMenu_Card_YesButton_Submited(_cr)
		CardButton_Submit_Common(_cr.artwork, _cb, _submit)
		singleton.CommonSubmited()
	else:
		singleton.CommonCanceled()
#-------------------------------------------------------------------------------
func DeckButton_Submit(_cb:CardButton) -> void:
	DeckButton_Common(_cb)
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func DeckButton_Canceled(_cb:CardButton) -> void:
	DeckButton_Common(_cb)
	singleton.CommonCanceled()
#-------------------------------------------------------------------------------
func DeckButton_Common(_cb:CardButton) -> void:
	confirmCard_Hold.text = ""
	confirmCard_Price.text = ""
	confirmCard_Title.text = "Do You Want to Quit the Market?"
	#-------------------------------------------------------------------------------
	var _submit: Callable = func(): ConfirmMenu_Deck_YesButton_Submited()
	CardButton_Submit_Common(deckTexture, _cb, _submit)
#-------------------------------------------------------------------------------
func CardButton_Submit_Common(_texture:Texture2D, _cb:CardButton, _callable:Callable) -> void:
	confirmCard_Panel.custom_minimum_size = buttonSize
	confirmCard_Artwork.texture = _texture
	#-------------------------------------------------------------------------------
	singleton.DisconnectButton(yesButton)
	singleton.DisconnectButton(noButton)
	singleton.SetButton(yesButton, singleton.CommonSelected, _callable, ConfirmMenu_YesButton_Canceled)
	singleton.SetButton(noButton, singleton.CommonSelected, func():ConfirmMenu_NoButton_Submited(_cb), func():ConfirmMenu_NoButton_Canceled(_cb))
	#-------------------------------------------------------------------------------
	buyMenu.hide()
	confirmMenu.show()
	singleton.MoveToButton(noButton)
#-------------------------------------------------------------------------------
func CardButton_Canceled() -> void:
	singleton.MoveToFirstButton(cardButton)
	singleton.CommonCanceled()
#endregion
#-------------------------------------------------------------------------------
#region CONFIRM MENU FUNCTIONS
func ConfirmMenu_Card_YesButton_Submited(_cr:CardResource):
	DeleteCardButtons()
	print(GetCardText_Name(GetCardText_ID(_cr))+" was added to your bag.")
	CardBuy_Effect(_cr)
	hide()
	closeMarket_signal.emit()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func ConfirmMenu_Deck_YesButton_Submited():
	DeleteCardButtons()
	hide()
	closeMarket_signal.emit()
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func ConfirmMenu_YesButton_Canceled():
	singleton.MoveToButton(noButton)
	singleton.CommonCanceled()
#-------------------------------------------------------------------------------
func ConfirmMenu_NoButton_Submited(_cb:CardButton):
	ConfurmMenu_NoButton_Common(_cb)
	singleton.CommonSubmited()
#-------------------------------------------------------------------------------
func ConfirmMenu_NoButton_Canceled(_cb:CardButton):
	ConfurmMenu_NoButton_Common(_cb)
	singleton.CommonCanceled()
#-------------------------------------------------------------------------------
func ConfurmMenu_NoButton_Common(_cb:CardButton):
	confirmMenu.hide()
	buyMenu.show()
	singleton.MoveToButton(_cb)
#endregion
#-------------------------------------------------------------------------------
#region DECK BUTTON FUNCTIONS
#-------------------------------------------------------------------------------
#endregion
#-------------------------------------------------------------------------------
#region MISC FUNCTIONS
func CardBuy_Effect(_cr:CardResource):
	gameScene.moneyPoints -= _cr.price
	gameScene.cardInventory[_cr] = gameScene.cardInventory.get(_cr, 0) + 1
	gameScene.SetMoney()
	match(GetCardText_ID(_cr)):
		"card_id_1":
			gameScene.lifePoints += 1
			gameScene.SetInfoText_Life()
		"card_id_2":
			gameScene.powerPoints += 1
			gameScene.SetInfoText_Power()
		"card_id_3":
			gameScene.player.playerResource.maxMoney += 100
			gameScene.SetMaxMoney()
#endregion
#-------------------------------------------------------------------------------
