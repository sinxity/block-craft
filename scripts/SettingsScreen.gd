extends Node2D

func _ready():
	_refresh()
	var btn_back = get_node_or_null("UI/TopBar/BtnBack")
	if btn_back: btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	var btn_sound = get_node_or_null("UI/BtnSound")
	if btn_sound: btn_sound.pressed.connect(_on_sound_toggle)
	var btn_lang = get_node_or_null("UI/BtnLanguage")
	if btn_lang: btn_lang.pressed.connect(_on_language_toggle)
	var btn_google = get_node_or_null("UI/BtnGoogle")
	if btn_google: btn_google.pressed.connect(_on_google_pressed)
	var btn_exit = get_node_or_null("UI/BtnExit")
	if btn_exit: btn_exit.pressed.connect(func(): get_tree().quit())

	var btn_reset = get_node_or_null("UI/BtnDevReset")
	if btn_reset: btn_reset.pressed.connect(_on_dev_reset)

func _refresh():
	var title = get_node_or_null("UI/TopBar/Title")
	if title: title.text = GameState.t("settings_title")

	var btn_sound = get_node_or_null("UI/BtnSound")
	if btn_sound:
		btn_sound.text = GameState.t("sound_on") if GameState.sound_enabled else GameState.t("sound_off")
		btn_sound.modulate = Color(1,1,1) if GameState.sound_enabled else Color(0.6,0.6,0.6)

	var btn_lang = get_node_or_null("UI/BtnLanguage")
	if btn_lang: btn_lang.text = GameState.t("lang_label")

	var btn_google = get_node_or_null("UI/BtnGoogle")
	if btn_google: btn_google.text = GameState.t("google_btn")

	var btn_exit = get_node_or_null("UI/BtnExit")
	if btn_exit: btn_exit.text = GameState.t("exit_btn")

func _on_sound_toggle():
	GameState.sound_enabled = not GameState.sound_enabled
	GameState.save_game()
	_refresh()

func _on_language_toggle():
	GameState.language = "en" if GameState.language == "ru" else "ru"
	GameState.save_game()
	SceneTransition.reload()

func _on_dev_reset():
	GameState.reset_game()
	SceneTransition.go_to("res://scenes/Hub.tscn")

func _on_google_pressed():
	var btn = get_node_or_null("UI/BtnGoogle")
	if btn:
		btn.text = GameState.t("google_unavail")
		await get_tree().create_timer(2.0).timeout
		btn.text = GameState.t("google_btn")
