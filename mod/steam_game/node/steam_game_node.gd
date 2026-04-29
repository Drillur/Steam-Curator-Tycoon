extends MarginContainer


static var curator1: MarginContainer

var steam_game: RefCounted: set = set_steam_game

#region Onready Variables

@onready var name_label: RichLabel = %NameLabel
@onready var texture_rect: TextureRect = %TextureRect
@onready var price_label: RichLabel = %PriceLabel
@onready var follower_label: RichLabel = %FollowerLabel
@onready var days_until_release_label: RichLabel = %DaysUntilReleaseLabel
@onready var declined_container: MarginContainer = %DeclinedContainer
@onready var highlight: Panel = %Highlight
@onready var reason_label: RichLabel = %ReasonLabel
@onready var declined_label: RichLabel = %DeclinedLabel
@onready var declined_background: Panel = %DeclinedBackground
@onready var emailed: RichButton = %Emailed
@onready var reviewed: RichButton = %Reviewed
@onready var keys: RichButton = %Keys

#endregion


#region Ready


func init() -> void:
	curator1.main.calendar.day_changed.connect(update_days_until_release.unbind(2))


#endregion


#region Setters


func set_steam_game(new_game: RefCounted) -> void:
	if steam_game:
		if steam_game == new_game:
			return
		clear()
	steam_game = new_game
	setup()


#endregion


#region Control


func setup() -> void:
	name_label.text = steam_game.name
	price_label.text = "$" + LoudNumber.format_number(steam_game.price)
	follower_label.text = LoudNumber.format_number(steam_game.followers) + " Followers"
	
	texture_rect.modulate = steam_game.color
	highlight.modulate = steam_game.color
	declined_background.modulate = steam_game.color
	declined_label.modulate = steam_game.color
	emailed.color = steam_game.color
	reviewed.color = steam_game.color
	keys.color = steam_game.color
	
	steam_game.state_changed.connect(update_ui)
	steam_game.review_written_changed.connect(update_ui)
	steam_game.state_changed.connect(update_keys)
	steam_game.keys_changed.connect(update_keys)
	update_ui()
	update_keys()
	update_days_until_release()
	
	steam_game.node = self
	show()


func update_days_until_release() -> void:
	if not steam_game:
		return
	const TEXT: String = "%s Days Until Release"
	var day_text: String = LoudNumber.format_number(steam_game.days_until_release)
	days_until_release_label.text = TEXT % day_text


func update_ui() -> void:
	emailed.button_pressed = steam_game.state >= steam_game.State.DECLINED
	reviewed.button_pressed = steam_game.review_written
	keys.button_pressed = (steam_game.state > steam_game.State.DECLINED
			and steam_game.keys == 0 and steam_game.keys_in_use == 0)
	
	highlight.visible = steam_game.state > steam_game.State.DECLINED
	
	declined_container.visible = steam_game.state == steam_game.State.DECLINED


func update_keys() -> void:
	if steam_game.state < steam_game.State.AWAITING_REVIEW:
		const TEXT: String = "No Keys Yet"
		keys.text = TEXT
	
	elif steam_game.keys > 0 or steam_game.keys_in_use > 0:
		const TEXT: String = "%s Keys Left"
		keys.text = TEXT % LoudNumber.format_number(steam_game.keys)
	
	else:
		const TEXT: String = "Keys Used"
		keys.text = TEXT


func clear() -> void:
	steam_game.state_changed.disconnect(update_ui)
	steam_game.keys_changed.disconnect(update_keys)
	steam_game.state_changed.disconnect(update_keys)
	steam_game.review_written_changed.disconnect(update_ui)
	steam_game.node = null
	hide()


#endregion
