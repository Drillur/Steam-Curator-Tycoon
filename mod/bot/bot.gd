extends Node

signal time_left_changed(time_left: float)
signal status_text_changed

static var main: Node
static var list: Array = []

static var count: LoudIntPair = LoudIntPair.new(0, 1, true)

static var refactor_follower_gain_multiplier := LoudFloat.new(1.0)
static var refactor_key_gain_multiplier := LoudFloat.new(1.0)
static var refactor_key_value_multiplier := LoudFloat.new(1.0)

static var sell_duration: float = 15.0
static var review_duration: float = 10.0
static var email_duration: float = 5.0
static var idle_duration: float = 1.0

static var status_log: Array[String] = []
static var pending_production := Big.new(0.0)

var id: int
var enabled: bool = false:
	set = _set_enabled
var selected_game: RefCounted ## Null if idle
var status_text: String = "Not Deployed":
	set = _set_status_text

#region Onready Variables

@onready var state_chart: StateChart = %StateChart
#@onready var cooldown_transition: Transition = %CooldownTransition ## The automatic transition out of a working state
@onready var cooldown_to_idle_transition: Transition = %Idle
@onready var cooldown: AtomicState = %Cooldown
@onready var sell_key: AtomicState = %SellKey
@onready var review_game: AtomicState = %ReviewGame
@onready var send_email: AtomicState = %SendEmail

#endregion

#region Static

static func update_count() -> void:
	var bot_amount: BigFloat = Currency.get_amount(&"bot")
	if bot_amount.is_greater_than(count.get_total()):
		bot_amount.set_to(count.get_total())
	count.current.set_to(bot_amount.current.to_int())

	for bot in list:
		bot.enabled = bot.id < count.val()
	for bot_node in Stage.fetch(&"curator1").node.bot_nodes.get_children():
		bot_node.visible = bot_node.top_id + bot_node.id < count.get_total()


static func update_refactor_values() -> void:
	var logged: float = Currency.get_value(&"refactor").plus(10).to_log()
	logged = maxf(1.0, logged)
	refactor_follower_gain_multiplier.set_to(logged)
	refactor_key_gain_multiplier.set_to(((logged - 1) * 0.75) + 1)
	refactor_key_value_multiplier.set_to(((logged - 1) * 0.5) + 1)


static func add_to_log(text: String) -> void:
	while status_log.size() > 19:
		status_log.remove_at(status_log.size() - 1)
	status_log.push_front(" - " + text + "\n\n")


static func update_durations() -> void:
	for bot in list:
		bot.state_chart.set_expression_property(&"sell_duration", sell_duration)
		bot.state_chart.set_expression_property(&"review_duration", review_duration)
		bot.state_chart.set_expression_property(&"email_duration", email_duration)
		bot.state_chart.set_expression_property(&"idle_duration", idle_duration)


static func _log_production() -> void:
	Utility.timer(randf_range(0.05, 1.0))
	while true:
		await Utility.timer(1.0)
		Rate.log_production(main, &"buck", pending_production)
		pending_production.set_to(0.0)

#endregion

#region Init

func _ready() -> void:
	id = get_index()
	list.append(self)

#endregion

#region Setters

func _set_enabled(new_val: bool) -> void:
	if enabled == new_val:
		return

	enabled = new_val

	if enabled:
		_decide_next_action()
	else:
		state_chart.send_event(&"stop_working")


func _set_status_text(new_text: String) -> void:
	if status_text == new_text:
		return
	status_text = new_text
	status_text_changed.emit()

#endregion

#region State

#region Idle

func _on_idle_state_entered() -> void:
	_decide_next_action()


func _decide_next_action() -> void:
	if not enabled:
		return

	for game in main.steam_games:
		if game.state == game.State.AWAITING_REVIEW:
			selected_game = game
			state_chart.send_event(&"review_game")
			return

		if game.state == game.State.NEW_GAME:
			selected_game = game
			state_chart.send_event(&"send_email")
			return

		if game.state >= game.State.REVIEW_BEING_WRITTEN and game.keys > 0:
			selected_game = game
			state_chart.send_event(&"sell_key")
			return

	# Transitions to Cooldown state, which returns here after cooldown_duration
	state_chart.send_event(&"no_tasks_available")

#endregion

#region Working

func _on_working_child_state_exited() -> void:
	time_left_changed.emit(0.0)
	selected_game = null

#region Sell Key

func _on_sell_key_state_entered() -> void:
	selected_game.keys -= 1
	selected_game.keys_in_use += 1
	status_text = "Selling Key..."


func _on_sell_key_state_processing(_delta: float) -> void:
	time_left_changed.emit(sell_key._pending_transition_remaining_delay)


func _on_sell_key_state_exited() -> void:
	selected_game.keys_in_use -= 1

	if selected_game.keys == 0 and selected_game.keys_in_use == 0:
		selected_game.state = selected_game.State.EXHAUSTED

	var key_price: float = _get_key_price(selected_game)
	add_to_log(
		"Sold key for [b]+%s[/b] %s" % [
			LoudNumber.format_number(key_price),
			Currency.get_details(&"buck").get_icon_and_colored_plural_name(),
		],
	)
	Currency.add(&"buck", key_price, true)
	pending_production.plus_equals(key_price)


func _get_key_price(game) -> float:
	var base_price: float = game.price
	var days_until_release: int = game.days_until_release
	var time_multiplier: float = _get_price_time_multiplier(days_until_release)
	var popularity_modifier: float = _get_price_popularity_modifier(game.followers)

	var final_multiplier: float = time_multiplier * popularity_modifier * refactor_key_value_multiplier.val()
	var key_price: float = base_price * final_multiplier * randf_range(0.75, 1.25)

	return key_price


func _get_price_time_multiplier(days_until_release: int) -> float:
	if days_until_release == 1:
		return 2.0
	elif days_until_release == 2:
		return 3.0
	elif days_until_release == 3:
		return 4.5
	else:
		return 4.5 + (days_until_release - 3) * 0.25


func _get_price_popularity_modifier(followers: int) -> float:
	if followers >= 1_000_000:
		return 2.5
	elif followers >= 500_000:
		return 2.0
	elif followers >= 100_000:
		return 1.5
	elif followers >= 25_000:
		return 1.2
	elif followers >= 5_000:
		return 1.0
	else:
		return 0.7

#endregion

#region Review Game

enum ReviewQuality {
	PEAK,
	INSIGHTFUL,
	STANDARD,
	USELESS,
	HARMFUL,
}

static var review_weight_insightful: float = 10.0
static var review_weight_standard: float = 20.0
static var review_weight_useless: float = 30.0
static var review_weight_harmful: float = 40.0


func _on_review_game_state_entered() -> void:
	selected_game.keys -= 1
	selected_game.keys_in_use += 1
	selected_game.state = selected_game.State.REVIEW_BEING_WRITTEN
	status_text = "Reviewing..."


func _on_review_game_state_processing(_delta: float) -> void:
	time_left_changed.emit(review_game._pending_transition_remaining_delay)


func _on_review_game_state_exited() -> void:
	selected_game.keys_in_use -= 1
	selected_game.review_written = true

	var followers_gained: int = _get_followers_gained(selected_game.followers)
	if followers_gained > 0:
		Currency.add(&"follower", followers_gained, true)

	if selected_game.keys == 0 and selected_game.keys_in_use == 0:
		selected_game.state = selected_game.State.EXHAUSTED


func _get_followers_gained(game_followers: int) -> int:
	var review_quality: ReviewQuality = _get_review_quality()

	var game_multiplier: float = _get_follower_gain_from_game_followers(game_followers)
	var quality_multiplier: float = _get_review_quality_multiplier(review_quality)

	var base_followers: float = game_multiplier * quality_multiplier
	base_followers = refactor_follower_gain_multiplier.times(base_followers)
	var final_followers: float = base_followers * randf_range(0.75, 1.25)

	var result: int = LoudFloat.roll_as_int(final_followers)

	# Log the follower gain
	var a_or_an: String = (
			"An" if review_quality == ReviewQuality.INSIGHTFUL else "A")
	var quality_text: String = ReviewQuality.keys()[review_quality]
	quality_text = quality_text.capitalize().to_lower()
	var follower_details: Details = Currency.get_details(&"follower")
	var follower: String = (
			follower_details.get_icon_and_plural_name() if result > 1 else \
			follower_details.get_icon_and_name())
	var plus: String = "+" if result > 0 else ""
	add_to_log(
		"%s %s review yielded [b]%s%s[/b] %s" % [
			a_or_an,
			quality_text,
			plus,
			result,
			follower,
		],
	)

	return result


func _get_follower_gain_from_game_followers(game_followers: float) -> float:
	return randf_range(game_followers * 0.001, game_followers * 0.0025)


func _get_review_quality_multiplier(quality: ReviewQuality) -> float:
	match quality:
		ReviewQuality.PEAK:
			return 5.0
		ReviewQuality.INSIGHTFUL:
			return 2.0
		ReviewQuality.STANDARD:
			return 1.0
		ReviewQuality.USELESS:
			return 0.5
		_:
			return 0.1


func _get_review_quality() -> ReviewQuality:
	const REVIEW_QUALITIES: Array[ReviewQuality] = [
		ReviewQuality.PEAK,
		ReviewQuality.INSIGHTFUL,
		ReviewQuality.STANDARD,
		ReviewQuality.USELESS,
		ReviewQuality.HARMFUL,
	]

	if review_weight_insightful == 0.0:
		return ReviewQuality.PEAK

	var weights: Array[float] = [
		1.0,
		review_weight_insightful,
		review_weight_standard,
		review_weight_useless,
		review_weight_harmful,
	]
	return REVIEW_QUALITIES[Utility.rng.rand_weighted(weights)]

#endregion

#region Send Email

enum EmailQuality {
	PROFESSIONAL,
	GOOD,
	STANDARD,
	LACKING,
	OBVIOUS_FAKE,
}

static var email_weight_good: float = 10.0
static var email_weight_standard: float = 20.0
static var email_weight_lacking: float = 30.0
static var email_weight_obvious_fake: float = 40.0


func _on_send_email_state_entered() -> void:
	selected_game.state = selected_game.State.EMAIL_PENDING
	status_text = "Emailing..."


func _on_send_email_state_processing(_delta: float) -> void:
	time_left_changed.emit(send_email._pending_transition_remaining_delay)


func _on_send_email_state_exited() -> void:
	var base_key_chance: float = _get_base_chance(selected_game.followers)
	var email_quality := _get_email_quality()
	var quality_multiplier: float = _get_email_quality_multiplier(email_quality)

	var chance_of_receiving_keys: float = base_key_chance * quality_multiplier

	var a_or_an: String = (
			"An" if email_quality == EmailQuality.OBVIOUS_FAKE else "A")
	var email_quality_text: String = (
			EmailQuality.keys()[email_quality].capitalize().to_lower())

	if randf() < chance_of_receiving_keys:
		selected_game.keys += _get_key_gain(selected_game.followers)
		selected_game.state = selected_game.State.AWAITING_REVIEW

		var key_text: String = ResourceBag.get_icon_text(
			"SteamCuratorTycoon_key",
			selected_game.color,
		)
		add_to_log(
			"%s %s email yielded [b]+%s[/b] %s keys" % [
				a_or_an,
				email_quality_text,
				selected_game.keys,
				key_text,
			],
		)

	else:
		if selected_game.node:
			var due_to: String = (
					"Despite" if email_quality <= EmailQuality.GOOD else "Due to")
			selected_game.node.reason_label.write(
				"(%s %s [b]%s[/b] email)" %
				[due_to, a_or_an.to_lower(), email_quality_text],
			)
		selected_game.state = selected_game.State.DECLINED
		add_to_log("%s %s email was declined" % [a_or_an, email_quality_text])


func _get_base_chance(followers: int) -> float:
	if followers >= 1_000_000:
		return 0.01
	elif followers >= 500_000:
		return 0.02
	elif followers >= 100_000:
		return 0.05
	elif followers >= 25_000:
		return 0.10
	elif followers >= 5_000:
		return 0.15
	else:
		return 0.25


func _get_email_quality_multiplier(quality: EmailQuality) -> float:
	match quality:
		EmailQuality.PROFESSIONAL:
			return 5.0
		EmailQuality.GOOD:
			return 2.0
		EmailQuality.STANDARD:
			return 1.0
		EmailQuality.LACKING:
			return 0.5
		_:
			return 0.1


func _get_email_quality() -> EmailQuality:
	const EMAIL_QUALITIES: Array[EmailQuality] = [
		EmailQuality.PROFESSIONAL,
		EmailQuality.GOOD,
		EmailQuality.STANDARD,
		EmailQuality.LACKING,
		EmailQuality.OBVIOUS_FAKE,
	]
	if email_weight_good == 0.0:
		return EmailQuality.PROFESSIONAL
	var weights: Array[float] = [
		1.0,
		email_weight_good,
		email_weight_standard,
		email_weight_lacking,
		email_weight_obvious_fake,
	]
	return EMAIL_QUALITIES[Utility.rng.rand_weighted(weights)]


func _get_key_gain(followers: int) -> int:
	var base_gain: float = _get_base_key_gain(followers)
	var follower_multiplier: float = _get_key_gain_follower_multiplier()
	var rand: float = randf_range(0.75, 1.25)
	var sum: float = refactor_key_gain_multiplier.times(
		base_gain * follower_multiplier * rand,
	)

	return maxi(LoudFloat.roll_as_int(sum), 1)


func _get_base_key_gain(followers: int) -> float:
	if followers >= 1_000_000:
		return 1.0
	elif followers >= 500_000:
		return randf_range(1, 2)
	elif followers >= 100_000:
		return randf_range(1, 3)
	elif followers >= 25_000:
		return randf_range(1, 5)
	elif followers >= 5_000:
		return randf_range(1, 7)
	else:
		return randf_range(2, 10)


func _get_key_gain_follower_multiplier() -> float:
	var followers: float = Currency.get_value(&"follower").to_float()

	if followers < 100:
		return randf_range(0.01, 0.1)

	var log_followers: float = log(followers) / log(10.0)
	var base_multiplier: float = log_followers - 1.5
	var final_multiplier: float = base_multiplier * 0.3 * randf_range(0.8, 1.2)

	return 1.0 + final_multiplier

#endregion

#endregion

#region Cooldown

func _on_cooldown_state_entered() -> void:
	status_text = "Idle"


func _on_cooldown_state_processing(_delta: float) -> void:
	time_left_changed.emit(cooldown._pending_transition_remaining_delay)


func _on_cooldown_state_exited() -> void:
	time_left_changed.emit(0.0)

#endregion

func _on_stop_working_taken() -> void:
	status_text = "Not Deployed"

#endregion
