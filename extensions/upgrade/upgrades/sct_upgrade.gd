extends Upgrade


static var curator1: MarginContainer
static var bot1: Node


func _post_init() -> void:
	super()
	
	await Main.await_done()
	
	if curator1 == null:
		curator1 = Stage.fetch(&"curator1").node
		bot1 = curator1.bots.get_child(0)
	
	var my_method: Callable
	
	match key:
		# BotLimit upgrades
		#&"bot_limit1", &"bot_limit2", &"bot_limit3", &"bot_limit4", \
		#&"bot_limit5", &"xbot_limit":
			#my_method = _on_bot_limit_changed
		
		# BotHaste upgrades
		&"bot_haste1", &"bot_haste2", &"bot_haste3", &"bot_haste4", \
		&"bot_haste5", &"bot_haste6", &"xbot_haste1":
			my_method = _on_bot_haste_changed
		
		# BotWeight upgrades
		&"bot_email_weight1", &"bot_review_weight1":
			my_method = _on_bot_weight_changed
		
		# ChartUpdate upgrades
		&"chart_update_rate1", &"chart_update_rate2", &"chart_update_rate3",  &"chart_update_rate4":
			my_method = _on_chart_update_changed
		
		# ChartLimit upgrades
		&"chart_limit1":
			my_method = _on_chart_limit_changed
		
		# ClockUpgrade
		&"xclock_hour_duration1":
			my_method = _on_clock_upgrade_changed
	
	if my_method:
		applied.changed.connect(my_method.call)
		if applied.is_true():
			my_method.call()


func _init_mod_effect(_op_type: Upgrade.OpType, _operator: String,
		_affected_object1: String, _affected_object2: String,
		_effect1: String, _effect2: String) -> void:
	
	_create_modifier(_effect2)
	
	await Main.await_done(0.1)
	
	if _affected_object1 == "bot":
		if _effect1 == "total":
			bot1.count.total.book.add_adder(modifier)
	
	super(_op_type, _operator, _affected_object1, _affected_object2, _effect1, _effect2)


func _on_bot_haste_changed() -> void:
	var sell_duration: float = 0.0
	var review_duration: float = 0.0
	var email_duration: float = 0.0
	var idle_duration: float = 0.0
	
	match key:
		&"bot_haste6":
			idle_duration = -0.1875
			email_duration = -0.375
			review_duration = -0.75
			sell_duration = -1.125
		&"bot_haste5":
			sell_duration = -1.5
			review_duration = -1.0
			email_duration = -0.5
			idle_duration = -0.25
		&"bot_haste3":
			sell_duration = -3.0
			review_duration = -2.0
			email_duration = -1.0
			idle_duration = -0.5
		&"bot_haste1", &"bot_haste2", &"bot_haste4":
			sell_duration = -3.0
			review_duration = -2.0
			email_duration = -1.0
		&"xbox_haste1":
			email_duration = -0.025
			review_duration = -0.15
			sell_duration = -0.275
	
	var multiplier: float = 1.0 if applied.is_true() else -1.0
	bot1.sell_duration += sell_duration * multiplier
	bot1.review_duration += review_duration * multiplier
	bot1.email_duration += email_duration * multiplier
	bot1.idle_duration += idle_duration * multiplier
	bot1.update_durations()


func _on_bot_weight_changed() -> void:
	var multiplier: float = 1.0 if applied.is_true() else -1.0
	match key:
		&"bot_email_weight1":
			bot1.email_weight_obvious_fake -= 10.0 * multiplier
			bot1.email_weight_lacking -= 7.5 * multiplier
			bot1.email_weight_standard -= 5.0 * multiplier
			bot1.email_weight_good -= 2.5 * multiplier
		&"bot_review_weight1":
			bot1.review_weight_harmful -= 10.0 * multiplier
			bot1.review_weight_useless -= 7.5 * multiplier
			bot1.review_weight_standard -= 5.0 * multiplier
			bot1.review_weight_insightful -= 2.5 * multiplier


func _on_chart_update_changed() -> void:
	var multiplier: int = 1 if applied.is_true() else -1
	curator1.main.refresh_rate_stage += multiplier
	curator1.main.update_refresh_rate_stage()


func _on_chart_limit_changed() -> void:
	var amount_gained: int = Upgrade.data[key].get("Effect", 1)
	var multiplier: float = 1.0 if applied.is_true() else -1.0
	curator1.main.add_max_steam_games(int(amount_gained * multiplier))


func _on_clock_upgrade_changed() -> void:
	var amount_gained: float = 12.0
	var multiplier: float = 1.0 if applied.is_true() else -1.0
	curator1.main.calendar.day_duration.minus_equals(amount_gained * multiplier)
