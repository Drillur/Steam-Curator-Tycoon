extends MarginContainer

var main: Node
var bot1: Node

#region Onready Variables

@onready var refresh_label: RichTextLabel = %RefreshLabel
@onready var date_label: RichLabel = %DateLabel
@onready var time_label: RichLabel = %TimeLabel

@onready var bots: Node = %Bots
@onready var bot_nodes: VBoxContainer = %BotNodes
@onready var steam_games: GridContainer = %SteamGames

@onready var current_bots_label: RichLabel = %CurrentBotsLabel
@onready var total_bots_label: RichLabel = %TotalBotsLabel

@onready var refactor_label: RichLabel = %RefactorLabel
@onready var key_gain_multiplier_label: RichLabel = %KeyGainMultiplierLabel
@onready var follower_gain_multiplier_label: RichLabel = %FollowerGainMultiplierLabel
@onready var key_value_multiplier_label: RichLabel = %KeyValueMultiplierLabel
@onready var bot_log: RichLabel = %BotLog

#endregion

#region Ready

func _ready() -> void:
	main = ModLoader.get_node("Drillur-SteamCuratorTycoon")
	main.calendar.day_changed.connect(update_steam_games.unbind(2))
	main.calendar.hour_changed.connect(_update_date_label.unbind(2))
	main.calendar.minute_changed.connect(_update_time_label.unbind(2))

	#await Main.await_done()

	bot_nodes.get_child(0).bots = bots
	bot1 = bots.get_child(0)
	bot1.main = main

	_update_date_label()
	_update_time_label()
	update_steam_games()
	update_bot_node_ids()

	Currency.get_amount(&"refactor").changed.connect(bot1.update_refactor_values)
	bot1.update_refactor_values()

	refactor_label.attach_big_float(Currency.get_amount(&"refactor"))
	key_gain_multiplier_label.attach_float(bot1.refactor_key_gain_multiplier)
	follower_gain_multiplier_label.attach_float(bot1.refactor_follower_gain_multiplier)
	key_value_multiplier_label.attach_float(bot1.refactor_key_value_multiplier)

	current_bots_label.attach_int(bot1.count.current)
	total_bots_label.attach_int(bot1.count.total)

	update_bot_log()

	await Main.await_done(0.25)
	Currency.get_amount(&"bot").changed.connect(bot1.update_count)
	bot1.update_count()
	bot1._log_production()

#endregion

#region Signals

func _update_hour_label() -> void:
	pass


func _on_bots_gui_input(event: InputEvent) -> void:
	const MAX: int = 10
	if (
			not event is InputEventMouseButton
			or not event.is_pressed()
			or not (
					event.button_index == MOUSE_BUTTON_WHEEL_UP
					or event.button_index == MOUSE_BUTTON_WHEEL_DOWN
			)
	):
		return

	var scrolled_up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
	var new_index: int = bot_nodes.get_child(0).top_id + (-1 if scrolled_up else 1)

	var max_index := maxi(bot1.count.total.minus(MAX), 0)
	bot_nodes.get_child(0).top_id = clampi(new_index, 0, max_index)
	update_bot_node_ids()

#endregion

#region Control

func update_bot_node_ids() -> void:
	for node in bot_nodes.get_children():
		node.id = node.top_id + node.node_index
		if node.main == null:
			node.main = get_owner()


func update_steam_games() -> void:
	if main.steam_games.is_empty():
		return

	var i: int = 0
	for node in steam_games.get_children():
		if i >= main.steam_games.size():
			node.hide()
		else:
			node.steam_game = main.steam_games[i]
			node.show()
		i += 1


func _update_date_label() -> void:
	date_label.write(main.calendar.get_date_text())


func _update_time_label() -> void:
	time_label.write(
		"%02d:%02d" % [
			main.calendar.hour,
			main.calendar.minute,
		],
	)


func update_bot_log() -> void:
	while true:
		await Utility.timer(0.5)

		var new_text: String = ""
		for x in bot1.status_log:
			new_text += x

		bot_log.write(new_text)

#endregion
