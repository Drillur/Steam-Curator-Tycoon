extends Node
## Play as a Steam Curator scammer! The Bot LORED will create Bots which will
## automatically:
## 1. Scan SteamDB for upcoming games
## 2. Request keys for "review purposes"
## 3. Leave a review for the game, accruing followers
## 4. Sell the remaining keys for profit!!!

## Because LORED loads a LORED's or Upgrade's class directly from its script path, adding script
## hooks or script extensions via Godot Mod Loader is not necessary for those or similar classes

const MOD_DIR := "Drillur-SteamCuratorTycoon"
const LOG_NAME := "Drillur-SteamCuratorTycoon:Main"

var mod_dir_path := ""
var extensions_dir_path := ""
var translations_dir_path := ""

#region Mod Init

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)

#endregion

#region Steam Curator Tycoon

var calendar: Calendar


func _ready() -> void:
	ModLoaderLog.info("Ready", LOG_NAME)

	ResourceBag.skip_base_data()

	Rate.new(self, [&"buck"])

	calendar = Calendar.new(24.0)
	calendar.start()

	ModLoaderLog.info("Cacher: Await done", LOG_NAME)
	await Cacher.done.became_true
	ModLoaderLog.info("Cacher: Done", LOG_NAME)

	_init_steam_games()

	Main.instance.saved[&"SteamCuratorTycoon_calendar"] = calendar

#region Steam Games

var steam_games: Array
var max_steam_games: int = 10
var refresh_rate_stage: int = 0
var steam_game_script: GDScript

#region Init

func _init_steam_games() -> void:
	steam_game_script = load(mod_dir_path.path_join("mod/steam_game/steam_game.gd"))
	Main.instance.prestiged.connect(prestige)

	await Main.await_done()

	update_refresh_rate_stage()
	calendar.hour_changed.connect(fill_list.unbind(1))
	fill_list(calendar.hour, true)

#endregion

func fill_list(new_hour: int = calendar.hour, ignore_time: bool = false) -> void:
	if not ignore_time:
		if refresh_rate_stage == 4:
			pass
		elif refresh_rate_stage == 3 and new_hour % 3 != 0:
			return
		elif refresh_rate_stage == 2 and new_hour % 6 != 0:
			return
		elif refresh_rate_stage == 1 and new_hour % 12 != 0:
			return
		elif refresh_rate_stage == 0 and new_hour != 0:
			return

	for game in steam_games.duplicate():
		if game.used_up():
			game.kill()
	while steam_games.size() < max_steam_games:
		var game = steam_game_script.new(self)
		steam_games.append(game)

	steam_games.sort_custom(sort_by_followers)

	Stage.fetch(&"curator1").node.update_steam_games()


func sort_by_followers(a, b) -> bool:
	if a.followers == b.followers:
		return a.price >= b.price
	return a.followers >= b.followers


func update_refresh_rate_stage() -> void:
	Stage.fetch(&"curator1").node.refresh_label.text = (
			"Games refresh hourly" if refresh_rate_stage == 4 # 1 hr
			else "Games refresh every 3 hours" if refresh_rate_stage == 3 # 3 hr
			else "Games refresh every 6 hours" if refresh_rate_stage == 2 # 6 hr
			else "Games refresh twice daily" if refresh_rate_stage == 1 # 12 hr
			else "Games refresh daily") # 24 hr


## Increases max Steam Games 
func add_max_steam_games(amount: int) -> void:
	max_steam_games += amount
	fill_list(calendar.hour, true)


func prestige(_tier: int) -> void:
	clear()
	Rate.reset(self)
	fill_list(calendar.hour, true)


func clear() -> void:
	for game in steam_games.duplicate():
		game.kill()

#endregion

#endregion
