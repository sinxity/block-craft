extends Node

# AdMob integration stub
# Replace AD_UNIT_ID with real ID from Google AdMob when building for Android

const AD_UNIT_ID = "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx"
const SHOW_AD_AFTER_LEVEL = 15

var _levels_since_ad := 0

func _ready():
	pass  # Initialize AdMob SDK here when building for Android

func on_level_complete(level_number: int):
	if level_number < SHOW_AD_AFTER_LEVEL:
		return
	_levels_since_ad += 1
	if _levels_since_ad >= 3:  # Show ad every 3 levels after level 15
		_levels_since_ad = 0
		show_interstitial()

func show_interstitial():
	# On Android with AdMob plugin:
	# AdMob.show_interstitial()
	print("[AdManager] Would show interstitial ad here")

func show_rewarded():
	# For rewarded ads (e.g. extra skill charges)
	# AdMob.show_rewarded()
	print("[AdManager] Would show rewarded ad here")

var _rewarded_uses_today: int = 0
var _rewarded_date: String = ""
const REWARDED_DAILY_LIMIT = 3
const REWARDED_COINS = 30

func can_show_rewarded() -> bool:
	var today = Time.get_date_string_from_system()
	if _rewarded_date != today:
		_rewarded_date = today
		_rewarded_uses_today = 0
	return _rewarded_uses_today < REWARDED_DAILY_LIMIT

func show_rewarded_for_coins() -> bool:
	if not can_show_rewarded(): return false
	# In production: show actual AdMob rewarded ad here
	# For now, give coins directly as a stub
	_rewarded_uses_today += 1
	GameState.coins += REWARDED_COINS
	GameState.save_game()
	return true
