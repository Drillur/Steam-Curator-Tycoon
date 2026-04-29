extends RefCounted


signal keys_changed
signal review_written_changed
signal state_changed

enum State {
	NEW_GAME,
	EMAIL_PENDING,
	DECLINED,
	AWAITING_REVIEW,
	REVIEW_BEING_WRITTEN,
	EXHAUSTED,
}

static var main: Node

var name: String
var state: State = State.NEW_GAME: set = _set_state

var price: float
var followers: int
var days_until_release: int = randi_range(7, 14)
var keys: int = 0: set = _set_keys
var keys_in_use: int = 0

var review_written: bool = false: set = _set_review_written

var node: MarginContainer
var color: Color = Utility.get_random_color()


func _init(_main: Node) -> void:
	if main == null:
		main = _main
	
	name = _generate_random_title()
	followers = _get_follower_count()
	price = _get_price()
	
	main.calendar.day_changed.connect(
			subtract_days_until_release.unbind(2))


func _get_follower_count() -> int:
	var rand_val: float = randf()
	
	if rand_val < 0.70:
		return randi_range(50, 5000)
	
	elif rand_val < 0.85:
		return randi_range(5000, 25_000)
	
	elif rand_val < 0.95:
		return randi_range(25_000, 100_000)
	
	elif rand_val < 0.99:
		return randi_range(100_000, 500_000)
	
	return randi_range(500_000, 2_500_000)


func _get_price() -> float:
	var result: float
	
	if followers < 1_000:
		result = randf_range(0.99, 7.99)
	elif followers < 5_000:
		result = randf_range(4.99, 14.99)
	elif followers < 25_000:
		result = randf_range(9.99, 24.99)
	elif followers < 100_000:
		result = randf_range(14.99, 34.99)
	elif followers < 500_000:
		result = randf_range(24.99, 49.99)
	else:
		result = randf_range(39.99, 69.99)
	
	var rounded: float = roundf(result)
	
	if result < 10.0:
		if rounded <= 1.0:
			return 1.0
		return rounded - 0.01
	
	elif result < 30.0:
		match randi() % 3:
			0: return rounded - 0.01
			1: return rounded - 0.51
			2: return float(rounded)
	
	match randi() % 2:
		0: return rounded - 0.01
		_: return float(rounded)


#endregion


#region Setters


func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	
	state = new_state
	
	state_changed.emit()


func _set_keys(new_keys: int) -> void:
	if keys == new_keys:
		return
	keys = new_keys
	keys_changed.emit()


func _set_review_written(new_val: bool) -> void:
	if review_written == new_val:
		return
	review_written = new_val
	review_written_changed.emit()


func _generate_random_title() -> String:
	const FULL_TITLES: PackedStringArray = [
		"Shattered Realms", "The Crimson Blade", "Echoes of Eternity",
		"Shadowmere Chronicles", "Dragon's Crown Legacy", "The Last Archmage",
		"Ruins of the Ancient Kings", "Moonlight Covenant", "The Witching Hour",
		"Blade of the Fallen", "Neon Horizon", "Stellar Outcasts",
		"The Void Runners", "Cybernetic Dreams", "Quantum Shadows",
		"Mars Protocol", "The Digital Frontier", "Starfall Rebellion",
		"Neural Network", "Galaxy's End", "Iron Fist Tournament",
		"Bloodstone Arena", "The Fighting Spirit", "Warrior's Pride",
		"Clash of Titans", "Street Legends", "The Final Round",
		"Combat Elite", "Victory Road", "Battle Royale Supreme",
		"Midnight Terror", "The Haunted Manor", "Whispers in the Dark",
		"Silent Screams", "The Dead Zone", "Phantom's Curse",
		"Nightmare Asylum", "Blood Moon Rising", "The Forgotten Crypt",
		"Shadows of Fear", "Velocity Rush", "Neon Streets",
		"Turbo Legends", "The Speed Demon", "Midnight Racers",
		"Chrome Wheels", "Highway Heroes", "Burnout City",
		"Racing Thunder", "The Fast Lane", "Empire's Fall",
		"The Art of War", "Tactical Supremacy", "Kingdom Under Siege",
		"Battle Commander", "The Great Campaign", "War Machine",
		"Strategic Conquest", "The Final Gambit", "Victory at All Costs",
		"Lost Expedition", "The Hidden Valley", "Treasure Seekers",
		"Journey to the Unknown", "The Explorer's Guild", "Forgotten Lands",
		"Quest for the Golden Idol", "The Adventure Begins", "Uncharted Waters",
		"The Great Discovery", "The Cipher Code", "Mind Games",
		"The Puzzle Master", "Mystery Manor", "Brain Teasers Unlimited",
		"The Logic Trap", "Riddle Me This", "The Enigma Files",
		"Puzzle Quest", "The Thinking Man's Game", "Championship Glory",
		"The Ultimate League", "Sports Legends", "Victory Stadium",
		"The Grand Tournament", "Athletic Dreams", "Champions United",
		"The Playoff Push", "Stadium Heroes", "The Winning Formula",
		"The Time Weaver", "Pixel Perfect", "The Memory Thief",
		"Gravity's Edge", "The Color Wars", "Sound and Fury",
		"The Dream Walker", "Reality Check", "The Impossible Game",
		"Beyond Tomorrow",
	]
	const ADJECTIVES: Array[String] = [
		"Ancient", "Dark", "Lost", "Forgotten", "Sacred", "Mystic", "Epic", "Legendary",
		"Shadow", "Golden", "Crystal", "Frozen", "Burning", "Hidden", "Secret", "Divine",
		"Cursed", "Eternal", "Infinite", "Ultimate", "Final", "Last", "Royal",
		"Imperial", "Arcane", "Crimson", "Steel", "Iron", "Blood", "Storm", "Thunder",
		"Fire", "Ice", "Stone", "Diamond", "Obsidian", "Solar", "Lunar", "Stellar"
	]
	const PRIMARY_NOUNS: Array[String] = [
		"Kingdom", "Empire", "Realm", "World", "Chronicles", "Saga", "Legacy",
		"Quest", "Adventure", "Journey", "Odyssey", "War", "Battle", "Arena",
		"Tournament", "Order", "Guild", "Brotherhood", "Alliance", "Prophecy",
		"Destiny", "Dawn", "Dusk", "Eclipse", "Awakening", "Ascension", "Return",
		"Revenge", "Redemption", "Revolution", "Genesis", "Origins"
	]
	const CREATURES: Array[String] = [
		"Dragons", "Warriors", "Knights", "Wizards", "Mages", "Assassins",
		"Rangers", "Guardians", "Champions", "Heroes", "Legends", "Titans",
		"Demons", "Angels", "Spirits", "Shadows", "Phoenixes", "Wolves",
		"Lions", "Eagles", "Panthers", "Ninjas", "Samurai", "Gladiators",
		"Vikings", "Pirates", "Rogues", "Mercenaries", "Soldiers"
	]
	const COOL_ACTIONS: Array[String] = [
		"Rising", "Fallen", "Reborn", "Unleashed", "Awakened", "Ascended",
		"Siege", "Conquest", "Invasion", "Liberation", "Rebellion", "Uprising",
		"Vengeance", "Wrath", "Glory", "Victory", "Betrayal", "Revolution"
	]
	const PLACES: Array[String] = [
		"Atlantis", "Avalon", "Valhalla", "Olympus", "Asgard", "Camelot",
		"the Abyss", "the Void", "the North", "the East", "the West", "the South",
		"the Underworld", "the Heavens", "the Wasteland", "the Depths",
		"the Mountains", "the Seas", "the Skies", "Eternity", "Infinity"
	]
	const TITLE_PATTERNS: Array[Array] = [
		[ADJECTIVES, PRIMARY_NOUNS],
		[ADJECTIVES, CREATURES],
		[CREATURES, "of", PLACES],
		["The", ADJECTIVES, PRIMARY_NOUNS],
		["The", CREATURES, "of", PLACES],
		[PRIMARY_NOUNS, COOL_ACTIONS],
		[CREATURES, COOL_ACTIONS],
		[ADJECTIVES, COOL_ACTIONS],
		[ADJECTIVES, CREATURES, "of", PLACES],
		[CREATURES, "of", "the", ADJECTIVES, PRIMARY_NOUNS],
		["PRIMARY_NOUNS:", ADJECTIVES, COOL_ACTIONS],
		[ADJECTIVES, "PRIMARY_NOUNS:", COOL_ACTIONS],
		[ADJECTIVES, ADJECTIVES, PRIMARY_NOUNS],
		[ADJECTIVES, ADJECTIVES, CREATURES],
		["Rise of the", ADJECTIVES, CREATURES],
		["Fall of the", ADJECTIVES, PRIMARY_NOUNS],
		[CREATURES, PRIMARY_NOUNS],
		[ADJECTIVES, "of", PLACES],
	]
	
	const FULL_TITLE_CHANCE: float = 1.0 / 100_000
	
	if randf() < FULL_TITLE_CHANCE:
		return FULL_TITLES[randi() % FULL_TITLES.size()]
	
	var pattern: Array = TITLE_PATTERNS.pick_random()
	var title_parts: Array[String] = []
	
	for part in pattern:
		if part is Array:
			title_parts.append(part.pick_random())
		elif part.ends_with(":"):
			var word_array = part.trim_suffix(":")
			var arrays_map = {
				"PRIMARY_NOUNS": PRIMARY_NOUNS,
				"ADJECTIVES": ADJECTIVES
			}
			if arrays_map.has(word_array):
				var word = arrays_map[word_array].pick_random()
				title_parts.append(word + ":")
			else:
				title_parts.append(part)
		else:
			title_parts.append(part)
	
	return " ".join(title_parts)


#endregion


#region Control


func subtract_days_until_release() -> void:
	days_until_release -= 1
	if days_until_release <= 0:
		kill()


func kill() -> void:
	main.steam_games.erase(self)


#endregion


#region Get Values


## No keys left, or declined to give keys
func used_up() -> bool:
	return state == State.DECLINED or state == State.EXHAUSTED


#endregion
