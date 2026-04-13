extends Node

var current_level: int = 1
var inventory: Dictionary = {}
var unlocked_levels: Array = [1]
var build_stage: int = 0
# 0 = trees standing
# 1 = trees chopped, foundation spot visible
# 2 = foundation built (levels 1-2 done)
# 3 = walls built (levels 3-4 done)
# 4 = roof built (level 5 done)
# ...
var pending_levels: Array = []  # queue of levels to play next
var skills: Dictionary = {
	"axe_skill":  {"unlocked": false, "unlock_level": 3, "charges": 0, "max_charges": 3},
	"bomb_skill": {"unlocked": false, "unlock_level": 5, "charges": 0, "max_charges": 3},
	"skip_skill": {"unlocked": false, "unlock_level": 7, "charges": 0, "max_charges": 3},
}
var hub_trees_chopped: bool = false
var hub_chopped_trees: Array = []
var level_stars: Dictionary = {}
var coins: int = 0
var sound_enabled: bool = true
var daily_completed_date: String = ""
var is_daily_run: bool = false
var streak: int = 0
var last_play_date: String = ""
var achievements: Dictionary = {}
var levels_no_skills: int = 0
var active_skin: String = "classic"
var owned_skins: Array = ["classic"]
var active_piece_style: String = "classic"
var active_board_bg: String = "cream"
var language: String = "ru"
var login_reward_date: String = ""
var login_reward_day: int = 0  # 1-7 cycle

const STRINGS = {
	"ru": {
		"settings_title": " Настройки",
		"sound_on":  " Звук: ВКЛ",
		"sound_off": " Звук: ВЫКЛ",
		"lang_label": " Язык: Русский",
		"google_btn": " Аккаунт Google",
		"google_unavail": "⏳ Недоступно в этой версии",
		"exit_btn": " Выйти из игры",
		"skin_active": " Активен",
		"skin_equip": "Надеть",
		"skin_free": "Получить бесплатно",
		"skill_charges": "Заряды: %d / %d",
		"skill_locked": " Не разблокирован",
		"skill_full": " Полный",
		"style_select": "Выбрать",
		"styles_title": "Стиль фигур",
		"bg_title": "Фон доски",
		"btn_build": "▶\nСтроить",
		"btn_play": "▶\nИграть",
		"shop_title": " Магазин",
		"shop_skins": "  Скины",
		"shop_skills": "  Навыки",
		"custom_title": " Кастомизация",
		"hub_custom": "\nКастом",
		"hub_shop": "\nМагазин",
		"hub_done": " Ферма построена!",
		"level_select_title": "Уровни",
		"diff_easy":   " Легкий",
		"diff_medium": " Средний",
		"diff_hard":   " Сложный",
		"diff_expert": " Эксперт",
		"timer_level": "Таймер-уровень",
		"play_btn":    "Играть!",
		"level_complete": "Уровень пройден!",
		"next_level":  "▶ Следующий",
		"to_hub":      "▶ В хаб",
		"to_levels":   "▶ К уровням",
		"reward_label": "Получен:",
		"endless_game_over": " Игра окончена",
		"endless_score": "Счёт:",
		"endless_best": "Рекорд:",
		"endless_retry": " Снова",
		"endless_hub": " В хаб",
	},
	"en": {
		"settings_title": " Settings",
		"sound_on":  " Sound: ON",
		"sound_off": " Sound: OFF",
		"lang_label": " Language: English",
		"google_btn": " Google Account",
		"google_unavail": "⏳ Not available in this version",
		"exit_btn": " Exit Game",
		"skin_active": " Active",
		"skin_equip": "Equip",
		"skin_free": "Get for free",
		"skill_charges": "Charges: %d / %d",
		"skill_locked": " Not unlocked",
		"skill_full": " Full",
		"style_select": "Select",
		"styles_title": "Piece Style",
		"bg_title": "Board Background",
		"btn_build": "▶\nBuild",
		"btn_play": "▶\nPlay",
		"shop_title": " Shop",
		"shop_skins": "  Skins",
		"shop_skills": "  Skills",
		"custom_title": " Customise",
		"hub_custom": "\nCustom",
		"hub_shop": "\nShop",
		"hub_done": " Farm built!",
		"level_select_title": "Levels",
		"diff_easy":   " Easy",
		"diff_medium": " Medium",
		"diff_hard":   " Hard",
		"diff_expert": " Expert",
		"timer_level": "Timer Level",
		"play_btn":    "Play!",
		"level_complete": "Level Complete!",
		"next_level":  "▶ Next",
		"to_hub":      "▶ To Hub",
		"to_levels":   "▶ Levels",
		"reward_label": "Received:",
		"endless_game_over": " Game Over",
		"endless_score": "Score:",
		"endless_best": "Best:",
		"endless_retry": " Retry",
		"endless_hub": " Hub",
	},
}

const ACHIEVEMENTS = [
	{"id": "first_level", "emoji": "", "name": "Первые шаги",    "name_en": "First Steps",     "desc": "Пройди первый уровень",         "desc_en": "Complete level 1",                "coins": 20},
	{"id": "level_10",    "emoji": "", "name": "Разминка",        "name_en": "Warm Up",         "desc": "Пройди 10 уровней",             "desc_en": "Complete 10 levels",              "coins": 30},
	{"id": "level_25",    "emoji": "", "name": "На разгоне",      "name_en": "Gaining Speed",   "desc": "Пройди 25 уровней",             "desc_en": "Complete 25 levels",              "coins": 50},
	{"id": "level_50",    "emoji": "", "name": "Ветеран",         "name_en": "Veteran",         "desc": "Пройди 50 уровней",             "desc_en": "Complete 50 levels",              "coins": 100},
	{"id": "level_100",   "emoji": "", "name": "Мастер",          "name_en": "Master",          "desc": "Пройди все 100 уровней",        "desc_en": "Complete all 100 levels",         "coins": 200},
	{"id": "three_stars", "emoji": "⭐", "name": "Перфекционист",   "name_en": "Perfectionist",   "desc": "3 звезды на 10 уровнях",        "desc_en": "3 stars on 10 levels",            "coins": 50},
	{"id": "timer_ace",   "emoji": "", "name": "Молния",          "name_en": "Lightning",       "desc": "Пройди таймер менее чем за 30с", "desc_en": "Complete a timer level in <30s", "coins": 40},
	{"id": "no_skills_5", "emoji": "", "name": "Без подсказок",  "name_en": "No Hints",        "desc": "Пройди 5 уровней без навыков",  "desc_en": "Complete 5 levels without skills","coins": 30},
	{"id": "daily_first", "emoji": "", "name": "Первый день",     "name_en": "Day One",         "desc": "Пройди ежедневный челлендж",    "desc_en": "Complete a daily challenge",      "coins": 30},
	{"id": "streak_3",    "emoji": "", "name": "Три дня подряд",  "name_en": "3-Day Streak",    "desc": "Зайди 3 дня подряд",            "desc_en": "Play 3 days in a row",            "coins": 30},
	{"id": "streak_7",    "emoji": "", "name": "Неделя",          "name_en": "One Week",        "desc": "Зайди 7 дней подряд",           "desc_en": "Play 7 days in a row",            "coins": 60},
	{"id": "collector",   "emoji": "", "name": "Коллекционер",    "name_en": "Collector",       "desc": "Купи 3 скина",                  "desc_en": "Own 3 skins",                     "coins": 50},
]

func t(key: String) -> String:
	return STRINGS.get(language, STRINGS["ru"]).get(key, key)

func _ready():
	load_game()

func set_level_stars(level: int, stars: int):
	var existing = level_stars.get(level, 0)
	if stars > existing:
		level_stars[level] = stars
	var next = level + 1
	if next not in unlocked_levels:
		unlocked_levels.append(next)
	if level < 100 and current_level <= level:
		current_level = next
	for key in skills:
		if not skills[key]["unlocked"] and current_level >= skills[key]["unlock_level"]:
			skills[key]["unlocked"] = true
			skills[key]["charges"] = skills[key]["max_charges"]

func get_daily_level() -> int:
	var day = int(Time.get_unix_time_from_system() / 86400.0)
	return (day % 35) + 1

func is_daily_done() -> bool:
	var today = Time.get_date_string_from_system()
	return daily_completed_date == today

func complete_daily():
	daily_completed_date = Time.get_date_string_from_system()
	coins += 50
	save_game()

func update_streak():
	var today = Time.get_date_string_from_system()
	if last_play_date == today:
		return
	var unix_yesterday = Time.get_unix_time_from_system() - 86400.0
	var yesterday = Time.get_date_string_from_unix_time(int(unix_yesterday))
	streak = streak + 1 if last_play_date == yesterday else 1
	last_play_date = today
	if streak >= 3: unlock_achievement("streak_3")
	if streak >= 7: unlock_achievement("streak_7")
	save_game()

func unlock_achievement(id: String) -> bool:
	if achievements.get(id, false):
		return false
	achievements[id] = true
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			coins += a["coins"]
			break
	save_game()
	return true

func check_level_achievements(level: int, stars: int, skills_used: int, is_timer: bool, timer_secs: float):
	if level >= 1:  unlock_achievement("first_level")
	if current_level > 10:  unlock_achievement("level_10")
	if current_level > 25:  unlock_achievement("level_25")
	if current_level > 50:  unlock_achievement("level_50")
	if current_level > 100: unlock_achievement("level_100")
	var three_star_count = 0
	for l in level_stars:
		if level_stars[l] >= 3: three_star_count += 1
	if three_star_count >= 10: unlock_achievement("three_stars")
	if is_timer and timer_secs <= 30.0: unlock_achievement("timer_ace")
	if skills_used == 0:
		levels_no_skills += 1
		if levels_no_skills >= 5: unlock_achievement("no_skills_5")
	if owned_skins.size() >= 3: unlock_achievement("collector")

func get_new_achievements() -> Array:
	# Returns list of achievement ids unlocked this session (not yet shown)
	# Used to show popup after level. Reset by caller.
	return []

func complete_level(level: int, reward: String):
	if reward != "":
		inventory[reward] = inventory.get(reward, 0) + 1
	var next = level + 1
	if next not in unlocked_levels:
		unlocked_levels.append(next)
	current_level = next
	# Check skill unlocks
	for key in skills:
		if not skills[key]["unlocked"] and current_level >= skills[key]["unlock_level"]:
			skills[key]["unlocked"] = true
			skills[key]["charges"] = skills[key]["max_charges"]
	save_game()

func has_item(item: String) -> bool:
	return inventory.get(item, 0) > 0

func use_skill(skill_key: String) -> bool:
	if not skills[skill_key]["unlocked"]:
		return false
	if skills[skill_key]["charges"] <= 0:
		return false
	skills[skill_key]["charges"] -= 1
	save_game()
	return true

func refill_skill_charges():
	for key in skills:
		if skills[key]["unlocked"]:
			skills[key]["charges"] = skills[key]["max_charges"]
	save_game()

func save_game():
	var save = {
		"current_level": current_level,
		"inventory": inventory,
		"unlocked_levels": unlocked_levels,
		"skills": skills,
		"hub_trees_chopped": hub_trees_chopped,
		"hub_chopped_trees": hub_chopped_trees,
		"build_stage": build_stage,
		"pending_levels": pending_levels,
		"level_stars": level_stars,
		"coins": coins,
		"sound_enabled": sound_enabled,
		"daily_completed_date": daily_completed_date,
		"streak": streak,
		"last_play_date": last_play_date,
		"achievements": achievements,
		"levels_no_skills": levels_no_skills,
		"active_skin": active_skin,
		"owned_skins": owned_skins,
		"active_piece_style": active_piece_style,
		"active_board_bg": active_board_bg,
		"language": language,
		"login_reward_date": login_reward_date,
		"login_reward_day": login_reward_day,
	}
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save))
	file.close()

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		return
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data:
		current_level = data.get("current_level", 1)
		inventory = data.get("inventory", {})
		unlocked_levels = data.get("unlocked_levels", [1])
		hub_trees_chopped = data.get("hub_trees_chopped", false)
		hub_chopped_trees = data.get("hub_chopped_trees", [])
		build_stage = data.get("build_stage", 0)
		pending_levels = data.get("pending_levels", [])
		level_stars = data.get("level_stars", {})
		coins = data.get("coins", 0)
		sound_enabled = data.get("sound_enabled", true)
		daily_completed_date = data.get("daily_completed_date", "")
		streak = data.get("streak", 0)
		last_play_date = data.get("last_play_date", "")
		achievements = data.get("achievements", {})
		levels_no_skills = data.get("levels_no_skills", 0)
		active_skin = data.get("active_skin", "classic")
		owned_skins = data.get("owned_skins", ["classic"])
		active_piece_style = data.get("active_piece_style", "classic")
		active_board_bg = data.get("active_board_bg", "cream")
		language = data.get("language", "ru")
		login_reward_date = data.get("login_reward_date", "")
		login_reward_day = data.get("login_reward_day", 0)
		var saved_skills = data.get("skills", {})
		for key in saved_skills:
			if key in skills:
				skills[key] = saved_skills[key]

func reset_game():
	current_level = 1
	inventory = {}
	unlocked_levels = [1]
	build_stage = 0
	pending_levels = []
	hub_trees_chopped = false
	hub_chopped_trees = []
	level_stars = {}
	coins = 0
	daily_completed_date = ""
	is_daily_run = false
	streak = 0
	last_play_date = ""
	achievements = {}
	levels_no_skills = 0
	active_skin = "classic"
	owned_skins = ["classic"]
	active_piece_style = "classic"
	active_board_bg = "cream"
	login_reward_date = ""
	login_reward_day = 0
	skills = {
		"axe_skill":  {"unlocked": false, "unlock_level": 3, "charges": 0, "max_charges": 3},
		"bomb_skill": {"unlocked": false, "unlock_level": 5, "charges": 0, "max_charges": 3},
		"skip_skill": {"unlocked": false, "unlock_level": 7, "charges": 0, "max_charges": 3},
	}
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")

func can_claim_login_reward() -> bool:
	var today = Time.get_date_string_from_system()
	return login_reward_date != today

func claim_login_reward() -> Dictionary:
	var today = Time.get_date_string_from_system()
	login_reward_date = today
	login_reward_day = (login_reward_day % 7) + 1
	var reward = _get_login_reward(login_reward_day)
	if reward.get("coins", 0) > 0:
		coins += reward["coins"]
	if reward.get("skill_charges", "") != "":
		var sk = reward["skill_charges"]
		if skills.has(sk):
			skills[sk]["charges"] = min(skills[sk]["charges"] + 2, skills[sk]["max_charges"])
	save_game()
	return reward

func _get_login_reward(day: int) -> Dictionary:
	match day:
		1: return {"coins": 20,  "label": " 20", "label_en": " 20"}
		2: return {"coins": 30,  "label": " 30", "label_en": " 30"}
		3: return {"coins": 50,  "label": " 50", "label_en": " 50"}
		4: return {"coins": 0,   "skill_charges": "axe_skill", "label": " +2 заряда", "label_en": " +2 charges"}
		5: return {"coins": 70,  "label": " 70", "label_en": " 70"}
		6: return {"coins": 100, "label": " 100", "label_en": " 100"}
		7: return {"coins": 150, "label": " 150 ", "label_en": " 150 "}
		_: return {"coins": 20,  "label": " 20", "label_en": " 20"}
