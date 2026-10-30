extends Control

# Native Godot foundation. Legacy Electron gameplay remains in src/ until ported.
const FORMATS = {
 "uk": {"title": "THE CHASE · UK", "host": "Bradley Walsh", "players": 4},
 "gsn": {"title": "THE CHASE · GSN", "host": "Brooke Burns", "players": 4},
 "abc": {"title": "THE CHASE · ABC", "host": "Sara Haines", "players": 3},
 "btc": {"title": "BEAT THE CHASERS", "host": "Bradley Walsh", "players": 1}
}
const QUESTIONS = [
 ["What planet is known as the Red Planet?", ["Mars", "Venus", "Saturn", "Mercury"], 0],
 ["How many sides does a hexagon have?", ["Five", "Six", "Seven", "Eight"], 1],
 ["Which ocean borders California?", ["Atlantic", "Indian", "Pacific", "Arctic"], 2],
 ["What is the capital of France?", ["Berlin", "Madrid", "Paris", "Rome"], 2],
 ["What is 12 multiplied by 8?", ["86", "94", "96", "108"], 2],
 ["Which element has the chemical symbol O?", ["Gold", "Oxygen", "Osmium", "Iron"], 1],
 ["How many minutes are in one hour?", ["45", "50", "60", "90"], 2]
]
var mode := "uk"
var phase := "menu"
var stage: Control
var overlay: VBoxContainer
var clock: Timer
var question_index := 0
var cash_correct := 0
var cash_winnings := 0
var seconds_left := 60
var intro_step := 0
var head_player_step := 0
var head_chaser_step := 0
var head_question := 0
var last_chaser_result := ""
var surviving_contestants := 0
var current_contestant := 1
var team_bank := 0
var selected_head_offer := 0
var all_caught_special := false
var team_members: Array = []
var final_team_score := 0
var final_chaser_score := 0
var final_stage := "team"
var final_buzzer := -1
var final_message := ""
var final_questions_asked := 0
const FINAL_TEAM_QUESTIONS = 12
const FINAL_CHASER_QUESTIONS = 18

var btc_revealed := 0
var btc_offers: Array = []
var btc_selected_offer := {}
var btc_player_seconds := 60
var btc_chaser_seconds := 0
var btc_turn := "player"
var btc_buzzed_chaser := -1
var btc_battle_message := ""
var btc_battle_over := false
const BTC_CHASERS = ["Mark Labbett", "Anne Hegerty", "Shaun Wallace", "Paul Sinha", "Jenny Ryan"]
var imported_tracks := {}
var music: AudioStreamPlayer
var file_dialog: FileDialog
var music_slot := "intro"
# Default profile for player-created Chasers. Official Chasers can override it.
const CUSTOM_CHASER_AI = {
 "knowledge": 85,
 "speed": 70,
 "offer_aggression": 65,
 "risk_taking": 45,
 "strongest_subject": "History",
 "offer_style": "Balanced",
 "high_offer_bias": 60,
 "low_offer_bias": 40,
 "btc_time_aggression": 55
}
var custom_chaser_ai: Dictionary = CUSTOM_CHASER_AI.duplicate(true)
const OFFICIAL_CHASERS = ["Mark Labbett", "Anne Hegerty", "Shaun Wallace", "Paul Sinha", "Jenny Ryan", "Darragh Ennis", "Brad Rutter", "James Holzhauer", "Ken Jennings", "Victoria Groce", "Brandon Blackwell", "Buzzy Cohen"]
const TOPICS = ["History", "Geography", "Science", "Sports", "Entertainment", "Literature", "Arts", "Politics", "General Knowledge"]
const CHASER_ROSTER_PATH = "user://chaser_profiles.json"
var chaser_profiles: Dictionary = {}
var active_chaser := "Mark Labbett"

const CAST_NAMES = ["Bradley Walsh", "Brooke Burns", "Sara Haines", "Mark Labbett", "Anne Hegerty", "Shaun Wallace", "Paul Sinha", "Jenny Ryan", "Darragh Ennis", "Ken Jennings", "James Holzhauer", "Brad Rutter", "Victoria Groce", "Brandon Blackwell", "Buzzy Cohen"]
const CAST_NICKNAMES = {"Mark Labbett":"The Beast", "Anne Hegerty":"The Governess", "Shaun Wallace":"The Dark Destroyer", "Paul Sinha":"The Sinnerman", "Jenny Ryan":"The Vixen", "Darragh Ennis":"The Menace", "Ken Jennings":"The Professor", "James Holzhauer":"The High Roller", "Brad Rutter":"The Buzzsaw", "Victoria Groce":"The Queen", "Brandon Blackwell":"The Lightning Bolt", "Buzzy Cohen":"The Stunner"}
const CAST_ATLAS = preload("res://assets/chase_cast_atlas.svg")
func cast_portrait(name: String, size: int = 96) -> TextureRect:
 var portrait := TextureRect.new()
 var index := CAST_NAMES.find(name)
 if index < 0:
  return portrait
 var atlas := AtlasTexture.new()
 atlas.atlas = CAST_ATLAS
 atlas.region = Rect2(index * 64, 0, 64, 64)
 portrait.texture = atlas
 portrait.custom_minimum_size = Vector2(size, size)
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 return portrait

func cast_card(name: String, can_select: bool = false) -> void:
 var line := HBoxContainer.new()
 line.alignment = BoxContainer.ALIGNMENT_CENTER
 line.add_child(cast_portrait(name, 58))
 var caption := Label.new()
 caption.text = name + (" · " + str(CAST_NICKNAMES[name]) if CAST_NICKNAMES.has(name) else " · HOST")
 caption.custom_minimum_size = Vector2(260, 0)
 line.add_child(caption)
 if can_select:
  var pick := Button.new()
  pick.text = "SELECT" if active_chaser != name else "SELECTED"
  pick.pressed.connect(func():
   active_chaser = name
   select_mode(mode)
  )
  line.add_child(pick)
 overlay.add_child(line)

func eligible_chasers() -> Array:
 if mode == "gsn":
  return ["Mark Labbett"]
 if mode == "abc":
  return ["Ken Jennings", "James Holzhauer", "Brad Rutter", "Victoria Groce", "Brandon Blackwell", "Buzzy Cohen", "Mark Labbett"]
 return ["Mark Labbett", "Anne Hegerty", "Shaun Wallace", "Paul Sinha", "Jenny Ryan", "Darragh Ennis"]

func choose_chaser_screen() -> void:
 phase = "choose_chaser"
 clear_ui()
 draw_studio()
 heading("CHOOSE YOUR CHASER")
 var scroller := ScrollContainer.new()
 scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var list := VBoxContainer.new()
 scroller.add_child(list)
 for name in eligible_chasers():
  var chosen: String = name
  var line := HBoxContainer.new()
  line.add_child(cast_portrait(chosen, 64))
  var pick := Button.new()
  pick.text = chosen + " · " + str(CAST_NICKNAMES.get(chosen, "CHASER"))
  pick.pressed.connect(func():
   active_chaser = chosen
   select_mode(mode)
  )
  line.add_child(pick)
  list.add_child(line)
 overlay.add_child(scroller)
 action("BACK TO SETUP", func(): select_mode(mode))

func profile_for(name: String) -> Dictionary:
 return chaser_profiles.get(name, CUSTOM_CHASER_AI)

func load_roster_profiles() -> void:
 for name in OFFICIAL_CHASERS:
  chaser_profiles[name] = CUSTOM_CHASER_AI.duplicate(true)
 var first_custom: Dictionary = CUSTOM_CHASER_AI.duplicate(true)
 first_custom["strongest_subject"] = "Sports"
 chaser_profiles["Custom Chaser"] = first_custom
 if FileAccess.file_exists(CHASER_ROSTER_PATH):
  var file := FileAccess.open(CHASER_ROSTER_PATH, FileAccess.READ)
  if file != null:
   var data = JSON.parse_string(file.get_as_text())
   if data is Dictionary:
    for name in data:
     if data[name] is Dictionary:
      var p: Dictionary = CUSTOM_CHASER_AI.duplicate(true)
      p.merge(data[name], true)
      chaser_profiles[str(name)] = p

func save_roster_profiles() -> void:
 var file := FileAccess.open(CHASER_ROSTER_PATH, FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify(chaser_profiles))

func chaser_roster_screen() -> void:
 phase = "chaser_roster"
 clear_ui()
 draw_studio()
 heading("CHASER AI PROFILES")
 for name in chaser_profiles:
  var selected: String = name
  action(selected, func():
   active_chaser = selected
   show_chaser_ai_options()
  )
 action("BACK", func(): select_mode(mode))

func update_chaser_setting(key: String, value: Variant) -> void:
 var p: Dictionary = profile_for(active_chaser)
 p[key] = value
 chaser_profiles[active_chaser] = p
 save_roster_profiles()


func chaser_correct_probability(category: String, profile: Dictionary = {}, round_name: String = "head_to_head") -> float:
 var p: Dictionary = profile_for(active_chaser) if profile.is_empty() else profile
 var knowledge := clampf(float(p.get("knowledge", 85)), 0.0, 100.0)
 # Elite Chasers are highly accurate, but never perfect.
 var chance := 0.57 + (knowledge / 100.0) * 0.39
 if category.to_lower() == str(p.get("strongest_subject", "History")).to_lower():
  chance += 0.025
 match round_name:
  "final_chase":
   chance -= 0.035
  "btc":
   chance -= 0.05
 return clampf(chance, 0.50, 0.965)

func chaser_answers_correctly(category: String, profile: Dictionary = {}, round_name: String = "head_to_head") -> bool:
 return rng.randf() < chaser_correct_probability(category, profile, round_name)

func chaser_answer_delay(profile: Dictionary = {}) -> float:
 var p: Dictionary = custom_chaser_ai if profile.is_empty() else profile
 var speed := clampf(float(p.get("speed", 70)), 0.0, 100.0)
 return lerpf(5.0, 0.8, speed / 100.0) + rng.randf_range(-0.25, 0.25)

func chaser_offer_multiplier(profile: Dictionary = {}) -> float:
 var p: Dictionary = custom_chaser_ai if profile.is_empty() else profile
 var aggression := clampf(float(p.get("offer_aggression", 65)), 0.0, 100.0) / 100.0
 var risk := clampf(float(p.get("risk_taking", 45)), 0.0, 100.0) / 100.0
 return 0.75 + aggression * 0.65 + risk * 0.25

const OFFER_STYLES = ["Balanced", "Aggressive", "Conservative", "Unpredictable"]
const CHASER_PROFILE_PATH = "user://custom_chaser_ai.json"
var normal_offers: Array = []

func load_chaser_profile() -> void:
 if not FileAccess.file_exists(CHASER_PROFILE_PATH):
  return
 var file := FileAccess.open(CHASER_PROFILE_PATH, FileAccess.READ)
 if file == null:
  return
 var data = JSON.parse_string(file.get_as_text())
 if data is Dictionary:
  for key in CUSTOM_CHASER_AI:
   if data.has(key):
    profile_for(active_chaser)[key] = data[key]

func save_chaser_profile() -> void:
 var file := FileAccess.open(CHASER_PROFILE_PATH, FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify(custom_chaser_ai))

func offer_factor() -> float:
 var style := str(profile_for(active_chaser).get("offer_style", "Balanced"))
 var factor := chaser_offer_multiplier(profile_for(active_chaser))
 match style:
  "Aggressive":
   factor *= 1.35
  "Conservative":
   factor *= 0.8
  "Unpredictable":
   factor *= rng.randf_range(0.65, 1.45)
 return factor

func offer_round(value: float) -> int:
 return maxi(1000, int(round(value / 1000.0)) * 1000)

func generate_regular_offers() -> Array:
 var base := maxi(cash_winnings, cash_value())
 var high_bias := float(profile_for(active_chaser).get("high_offer_bias", 60)) / 100.0
 var low_bias := float(profile_for(active_chaser).get("low_offer_bias", 40)) / 100.0
 var high := offer_round(base * (1.5 + high_bias * 3.0) * offer_factor())
 var low := offer_round(base * (0.1 + (1.0 - low_bias) * 0.35))
 low = mini(low, maxi(1000, base - 1000))
 high = maxi(high, base + 1000)
 return [
  {"name": "HIGH", "amount": high, "start": 1},
  {"name": "CASH BUILDER", "amount": cash_winnings, "start": 2},
  {"name": "LOW", "amount": low, "start": 3}
 ]

func show_regular_offers() -> void:
 phase = "regular_offers"
 normal_offers = generate_regular_offers()
 clear_ui()
 draw_studio()
 heading("THE CHASER MAKES THEIR OFFERS")
 label("Choose your starting position on the table.")
 for offer in normal_offers:
  var choice: Dictionary = offer
  action("%s · %s · %d CORRECT TO GET HOME" % [choice["name"], format_cash(choice["amount"]), 6 - int(choice["start"])], func(): accept_regular_offer(choice))

func accept_regular_offer(offer: Dictionary) -> void:
 selected_head_offer = int(offer["amount"])
 head_player_step = int(offer["start"])
 begin_head_to_head()

func ai_option(title: String, key: String, options: Array) -> void:
 label(title + ": " + str(profile_for(active_chaser).get(key, "")))
 for option in options:
  var chosen = option
  action(str(option), func():
   update_chaser_setting(key, chosen)
   show_chaser_ai_options()
  )

func show_chaser_ai_options() -> void:
 phase = "chaser_ai_options"
 clear_ui()
 draw_studio()
 heading(active_chaser.to_upper() + " · CHASER AI")
 label("What is this Chaser’s best topic?")
 ai_option("Strongest subject", "strongest_subject", TOPICS)
 ai_option("Offer style", "offer_style", OFFER_STYLES)
 for setting in ["knowledge", "speed", "offer_aggression", "risk_taking", "high_offer_bias", "low_offer_bias", "btc_time_aggression"]:
  var key: String = setting
  label(key.replace("_", " ").capitalize() + ": " + str(profile_for(active_chaser).get(key, 50)))
  var slider := HSlider.new()
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 5
  slider.value = float(profile_for(active_chaser).get(key, 50))
  slider.value_changed.connect(func(value: float):
   update_chaser_setting(key, int(value))
  )
  overlay.add_child(slider)
 action("BACK TO CHASER LIST", chaser_roster_screen)

var rng := RandomNumberGenerator.new()
const QUESTION_HISTORY_PATH = "user://chase_question_history.json"
var seen_questions: Dictionary = {}
var session_questions: Dictionary = {}
var current_question: Array = []
var question_warning := ""
var question_bank: Array = []
var question_categories: Dictionary = {}

func load_question_bank() -> void:
 question_bank.clear()
 question_categories.clear()
 var registered: Dictionary = {}
 for sample in QUESTIONS:
  var sample_key := question_key(sample)
  if not registered.has(sample_key):
   question_bank.append(sample)
   registered[sample_key] = true
 var file := FileAccess.open("res://data/questions.json", FileAccess.READ)
 if file == null:
  return
 var data = JSON.parse_string(file.get_as_text())
 if not data is Dictionary:
  return
 for item in data.get("questions", []):
  if not item is Dictionary:
   continue
  var opts = item.get("options", [])
  if not opts is Array or opts.size() != 4:
   continue
  var q: Array = [str(item.get("question", "")), opts, int(item.get("answer", 0))]
  if q[0] == "" or q[2] < 0 or q[2] > 3:
   continue
  var key := question_key(q)
  if not registered.has(key):
   question_bank.append(q)
   registered[key] = true
   question_categories[key] = str(item.get("category", "General Knowledge"))

func current_question_category() -> String:
 return str(question_categories.get(question_key(current_question), "General Knowledge"))

func question_key(q: Array) -> String:
 return str(q[0]).strip_edges().to_lower().sha256_text()

func load_question_history() -> void:
 seen_questions.clear()
 if not FileAccess.file_exists(QUESTION_HISTORY_PATH):
  return
 var file := FileAccess.open(QUESTION_HISTORY_PATH, FileAccess.READ)
 if file == null:
  return
 var parsed = JSON.parse_string(file.get_as_text())
 if parsed is Dictionary:
  for key in parsed.get("seen", []):
   seen_questions[str(key)] = true

func save_question_history() -> void:
 var file := FileAccess.open(QUESTION_HISTORY_PATH, FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify({"seen": seen_questions.keys()}))

func next_unique_question() -> Array:
 var unseen: Array = []
 var not_in_session: Array = []
 for q in question_bank:
  var key := question_key(q)
  if not session_questions.has(key):
   not_in_session.append(q)
   if not seen_questions.has(key):
    unseen.append(q)
 if unseen.is_empty() and not_in_session.is_empty():
  question_warning = "QUESTION BANK EXHAUSTED — no unused questions remain in this session."
  return []
 if unseen.is_empty():
  question_warning = "EVERY QUESTION HAS BEEN USED. ADD MORE TO THE BANK TO CONTINUE WITHOUT REPEATS."
  return []
 question_warning = ""
 var q: Array = unseen[rng.randi_range(0, unseen.size() - 1)]
 var key := question_key(q)
 session_questions[key] = true
 seen_questions[key] = true
 save_question_history()
 return q

func prepare_question() -> bool:
 current_question = next_unique_question()
 return not current_question.is_empty()

func show_question_exhausted() -> void:
 clock.stop()
 music.stop()
 phase = "questions_exhausted"
 clear_ui()
 draw_studio()
 heading("QUESTION BANK EXHAUSTED")
 label("No unused questions remain in this game.")
 action("BACK TO MENU", show_menu)


# Original chiptune menu music, synthesized in memory (not a transcription of TV music).
var menu_theme_player: AudioStreamPlayer
var menu_theme_audio: AudioStream
const MENU_MUSIC_PATH = "user://chase_menu_theme.mp3"

func menu_note_frequency(semitone: int) -> float:
 return 440.0 * pow(2.0, float(semitone - 69) / 12.0)

func build_menu_theme() -> AudioStreamWAV:
 var rate := 22050
 var bpm := 138.0
 var beat := 60.0 / bpm
 var steps := 64
 var step_seconds := beat / 2.0
 var total_samples := int(float(steps) * step_seconds * float(rate))
 var melody := [76, -1, 79, 81, 83, 81, 79, -1, 74, -1, 76, 79, 81, 79, 76, -1,
  72, -1, 76, 79, 80, 79, 76, -1, 71, -1, 74, 76, 79, 76, 74, -1,
  76, -1, 79, 83, 84, 83, 79, -1, 74, -1, 77, 81, 83, 81, 77, -1,
  72, 74, 76, 79, 81, 79, 76, 74, 71, -1, 74, 76, 72, -1, -1, -1]
 var bass := [40, 40, 43, 40, 38, 38, 43, 38, 36, 36, 43, 36, 38, 38, 43, 38]
 var bytes := PackedByteArray()
 bytes.resize(total_samples * 2)
 for sample_index in range(total_samples):
  var time := float(sample_index) / float(rate)
  var step_index := int(time / step_seconds)
  var local_time := fmod(time, step_seconds)
  var pulse := 0.0
  var pitch: int = melody[step_index % melody.size()]
  if pitch >= 0:
   var freq := menu_note_frequency(pitch)
   var square := 1.0 if fmod(time * freq, 1.0) < 0.5 else -1.0
   pulse += square * 0.19 * maxf(0.0, 1.0 - local_time / step_seconds)
  var bass_pitch: int = bass[(step_index / 4) % bass.size()]
  var bass_freq := menu_note_frequency(bass_pitch)
  pulse += (1.0 if fmod(time * bass_freq, 1.0) < 0.5 else -1.0) * 0.10
  if step_index % 4 == 0 and local_time < 0.11:
   pulse += sin(6.2831853 * (95.0 - local_time * 400.0) * local_time) * 0.20 * (1.0 - local_time / 0.11)
  if step_index % 2 == 1 and local_time < 0.055:
   var noise := fmod(sin(float(sample_index) * 12.9898) * 43758.5453, 1.0)
   pulse += (noise * 2.0 - 1.0) * 0.055 * (1.0 - local_time / 0.055)
  var pcm := int(clampf(pulse, -0.95, 0.95) * 32767.0)
  if pcm < 0:
   pcm += 65536
  bytes[sample_index * 2] = pcm & 255
  bytes[sample_index * 2 + 1] = (pcm >> 8) & 255
 var result := AudioStreamWAV.new()
 result.format = AudioStreamWAV.FORMAT_16_BITS
 result.mix_rate = rate
 result.stereo = false
 result.data = bytes
 result.loop_mode = AudioStreamWAV.LOOP_FORWARD
 result.loop_begin = 0
 result.loop_end = total_samples
 return result

func start_menu_theme() -> void:
 if FileAccess.file_exists(MENU_MUSIC_PATH) and not menu_theme_player.stream is AudioStreamMP3:
  var imported := AudioStreamMP3.load_from_file(MENU_MUSIC_PATH)
  if imported != null:
   imported.loop = true
   menu_theme_player.stream = imported
 if menu_theme_player != null and not menu_theme_player.playing:
  menu_theme_player.play()

func stop_menu_theme() -> void:
 if menu_theme_player != null:
  menu_theme_player.stop()

func _ready() -> void:
 rng.randomize()
 load_question_bank()
 load_question_history()
 load_chaser_profile()
 load_roster_profiles()
 stage = Control.new()
 stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage)
 overlay = VBoxContainer.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.add_theme_constant_override("separation", 12)
 add_child(overlay)
 clock = Timer.new()
 clock.wait_time = 1.0
 clock.timeout.connect(_on_tick)
 add_child(clock)
 music = AudioStreamPlayer.new()
 add_child(music)
 restore_music_imports()
 menu_theme_audio = build_menu_theme()
 if FileAccess.file_exists(MENU_MUSIC_PATH):
  var saved_track := AudioStreamMP3.load_from_file(MENU_MUSIC_PATH)
  if saved_track != null:
   saved_track.loop = true
   menu_theme_audio = saved_track
 menu_theme_player = AudioStreamPlayer.new()
 menu_theme_player.stream = menu_theme_audio
 menu_theme_player.volume_db = -10.0
 add_child(menu_theme_player)
 file_dialog = FileDialog.new()
 file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
 file_dialog.access = FileDialog.ACCESS_FILESYSTEM
 file_dialog.filters = PackedStringArray(["*.ogg, *.mp3, *.wav ; Audio"])
 file_dialog.file_selected.connect(_on_music_file)
 add_child(file_dialog)
 show_menu()

func clear_ui() -> void:
 for child in overlay.get_children():
  child.queue_free()
 for child in stage.get_children():
  child.queue_free()

func heading(t: String) -> void:
 var l := Label.new()
 l.text = t
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size", 28)
 l.add_theme_color_override("font_color", Color("#ffe7a1"))
 overlay.add_child(l)

func label(t: String) -> void:
 var l := Label.new()
 l.text = t
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size", 18)
 overlay.add_child(l)

func action(t: String, callback: Callable) -> void:
 var b := Button.new()
 b.text = t
 b.custom_minimum_size = Vector2(0, 43)
 b.pressed.connect(callback)
 overlay.add_child(b)

func show_menu() -> void:
 phase = "menu"
 start_menu_theme()
 clock.stop()
 music.stop()
 clear_ui()
 heading("THE CHASE · 8-BIT ULTIMATE EDITION")
 label("NATIVE GODOT PREVIEW — gameplay migration in progress")
 action("IMPORT YOUR 8-BIT MAIN MENU THEME (MP3)", func(): import_music("menu-theme"))
 if FileAccess.file_exists(MENU_MUSIC_PATH):
  label("CUSTOM 8-BIT MENU THEME INSTALLED")
 for id in FORMATS:
  var chosen: String = id
  action(FORMATS[id]["title"], func(): select_mode(chosen))

func select_mode(id: String) -> void:
 stop_menu_theme()
 mode = id
 phase = "setup"
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 cast_card(str(FORMATS[mode]["host"]))
 if not eligible_chasers().has(active_chaser):
  active_chaser = str(eligible_chasers()[0])
 cast_card(active_chaser)
 action("CHANGE CHASER", choose_chaser_screen)
 action("START THE SHOW", start_intro)
 action("CHASER AI PROFILES AND BEST SUBJECT", chaser_roster_screen)
 action("IMPORT OPENING MUSIC", func(): import_music("intro"))
 action("IMPORT HERE COMES THE CHASER CUE", func(): import_music("chaser-entrance"))
 action("IMPORT CASH BUILDER MUSIC", func(): import_music("cash"))
 action("IMPORT FINAL CHASE MUSIC", func(): import_music("final"))
 if mode == "btc":
  action("IMPORT BTC BATTLE MUSIC", func(): import_music("btc-battle"))
 action("BACK", show_menu)

func start_intro() -> void:
 current_contestant = 1
 surviving_contestants = 0
 team_bank = 0
 all_caught_special = false
 team_members.clear()
 phase = "intro"
 session_questions.clear()
 intro_step = 0
 show_intro()

func btc_opening_visual() -> void:
 # Original in-engine pixel-art opening. Adapts to the active Chaser lineup.
 var banner := Label.new()
 banner.text = "BEAT THE CHASERS"
 banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 banner.add_theme_font_size_override("font_size", 34)
 banner.add_theme_color_override("font_color", Color("#f9df91"))
 overlay.add_child(banner)
 var lineup := HBoxContainer.new()
 lineup.alignment = BoxContainer.ALIGNMENT_CENTER
 for i in range(BTC_CHASERS.size()):
  var chaser_name: String = BTC_CHASERS[i]
  var stack := VBoxContainer.new()
  var portrait := cast_portrait(chaser_name, 100)
  stack.add_child(portrait)
  var tag := Label.new()
  tag.text = chaser_name.split(" ")[0].to_upper()
  tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  tag.add_theme_font_size_override("font_size", 13)
  stack.add_child(tag)
  lineup.add_child(stack)
 overlay.add_child(lineup)

func show_intro() -> void:
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 if mode == "btc":
  if intro_step == 0:
   label("THE C'S ARE SPINNING · 8-BIT OPENING")
   btc_opening_visual()
  elif intro_step == 1:
   label("PLEASE WELCOME " + str(FORMATS[mode]["host"]).to_upper())
   cast_card(str(FORMATS[mode]["host"]))
  elif intro_step == 2:
   label("CONTESTANT ENTRANCE")
  else:
   label("THE CHASERS ENTER")
   btc_opening_visual()
 else:
  label("WELCOME TO THE CHASE")
  cast_card(str(FORMATS[mode]["host"]))
 if intro_step == 0:
  play_track("intro")
 action("NEXT", next_intro)
 action("SKIP TO CASH BUILDER", begin_cash)

func next_intro() -> void:
 intro_step += 1
 if intro_step >= (4 if mode == "btc" else 1):
  begin_cash()
 else:
  show_intro()


func reveal_chaser() -> void:
 phase = "chaser_entrance"
 play_track("chaser-entrance")
 clear_ui()
 draw_studio()
 heading("HERE COMES THE CHASER")
 cast_card(active_chaser)
 label("The Chaser makes their entrance!")
 action("CONTINUE TO OFFERS", show_regular_offers)

func begin_head_to_head() -> void:
 phase = "head_to_head"
 head_chaser_step = 0
 head_question = 0
 last_chaser_result = ""
 if prepare_question():
  show_head_to_head()
 else:
  show_question_exhausted()

func show_head_to_head() -> void:
 clear_ui()
 draw_studio()
 heading("THE HEAD-TO-HEAD")
 cast_card(active_chaser)
 label("TO GET HOME: %d MORE CORRECT   |   CHASER: %d STEPS" % [maxi(0, 6 - head_player_step), head_chaser_step])
 label("GREEN ARROW: CONTESTANT    RED ARROW: CHASER")
 if last_chaser_result != "":
  label(last_chaser_result)
 if head_player_step >= 6:
  heading("YOU MADE IT HOME!")
  action("CONTINUE", func(): complete_contestant(true))
  action("BACK TO SETUP", func(): select_mode(mode))
  return
 if head_chaser_step >= head_player_step:
  heading("THE CHASER HAS CAUGHT YOU")
  action("CONTINUE", func(): complete_contestant(false))
  return
 var q: Array = current_question
 if question_warning != "":
  label(question_warning)
 label(q[0])
 for i in range(4):
  var choice := i
  action(q[1][i], func(): answer_head(choice))

func answer_head(index: int) -> void:
 var q: Array = current_question
 last_chaser_result = ""
 if index == q[2]:
  head_player_step += 1
 else:
  last_chaser_result = "YOU ANSWERED INCORRECTLY. YOUR POSITION DOES NOT MOVE."
 # Chaser performance is determined by the selected AI profile.
 if chaser_answers_correctly(current_question_category()):
  head_chaser_step += 1
  last_chaser_result += " THE CHASER MOVES ONE STEP."
 else:
  last_chaser_result += " THE CHASER GOT IT WRONG AND STAYS PUT."
 head_question += 1
 if head_player_step >= 6 or head_chaser_step >= head_player_step:
  show_head_to_head()
 elif prepare_question():
  show_head_to_head()
 else:
  show_question_exhausted()


func complete_contestant(survived: bool) -> void:
 if survived:
  surviving_contestants += 1
  team_bank += selected_head_offer
  team_members.append("CONTESTANT %d" % current_contestant)
 current_contestant += 1
 if current_contestant <= int(FORMATS[mode]["players"]):
  show_next_contestant()
 elif surviving_contestants == 0:
  show_all_caught_special()
 else:
  begin_final_chase()

func show_next_contestant() -> void:
 phase = "next_contestant"
 clear_ui()
 draw_studio()
 heading("NEXT CONTESTANT")
 label("%d OF %d CONTESTANTS COMPLETED" % [current_contestant - 1, int(FORMATS[mode]["players"])])
 label("%d THROUGH · TEAM BANK: %s" % [surviving_contestants, format_cash(team_bank)])
 label("CONTESTANT %d, STEP UP TO THE CASH BUILDER!" % current_contestant)
 action("START CASH BUILDER", begin_cash)

func show_all_caught_special() -> void:
 phase = "all_caught"
 clear_ui()
 draw_studio()
 heading("ALL CONTESTANTS CAUGHT!")
 label("ONE CONTESTANT RETURNS FOR A CONSOLATION FINAL CHASE.")
 var consolation := 30000 if mode == "abc" else 4000
 label("TOTAL PRIZE: %s · SPLIT BETWEEN ALL %d ORIGINAL CONTESTANTS" % [format_cash(consolation), int(FORMATS[mode]["players"])])
 action("PLAY CONSOLATION FINAL CHASE", func():
  all_caught_special = true
  surviving_contestants = 1
  team_bank = consolation
  team_members = ["RETURNING CONTESTANT"]
  begin_final_chase()
 )
 action("BACK TO SETUP", func(): select_mode(mode))

func begin_final_chase() -> void:
 phase = "final_chase"
 final_stage = "team"
 final_team_score = clampi(surviving_contestants, 1, int(FORMATS[mode]["players"]))
 final_chaser_score = 0
 final_questions_asked = 0
 final_buzzer = -1
 final_message = "Each contestant has a buzzer. First to buzz answers."
 play_track("final")
 if prepare_question():
  show_final_chase()
 else:
  show_question_exhausted()

func show_final_chase() -> void:
 phase = "final_chase"
 clear_ui()
 draw_studio()
 heading("THE FINAL CHASE")
 cast_card(active_chaser)
 label("TEAM TARGET: %d    CHASER: %d" % [final_team_score, final_chaser_score])
 label(final_message)
 if final_stage == "finished":
  var won := final_chaser_score < final_team_score
  heading("THE TEAM WINS!" if won else "THE CHASER WINS!")
  if won:
   var shares := int(FORMATS[mode]["players"]) if all_caught_special else surviving_contestants
   label("PRIZE: %s · %s EACH" % [format_cash(team_bank), format_cash(team_bank / maxi(1, shares))])
  action("BACK TO SETUP", func(): select_mode(mode))
  return
 if final_stage == "team" and final_questions_asked >= FINAL_TEAM_QUESTIONS:
  final_stage = "chaser"
  final_questions_asked = 0
  final_message = "THE CHASER'S TURN — wrong answers give a pushback chance."
  if not prepare_question():
   show_question_exhausted()
   return
 if final_stage == "chaser" and (final_chaser_score >= final_team_score or final_questions_asked >= FINAL_CHASER_QUESTIONS):
  final_stage = "finished"
  show_final_chase()
  return
 if final_stage == "team":
  label("TEAM ROUND · QUESTION %d · %d SURVIVORS" % [final_questions_asked + 1, surviving_contestants])
  label(str(current_question[0]))
  if final_buzzer < 0:
   for i in range(surviving_contestants):
    var contestant_id := i
    action("CONTESTANT %d · BUZZ IN" % (i + 1), func(): final_buzz(contestant_id))
  else:
   label("CONTESTANT %d BUZZED FIRST" % (final_buzzer + 1))
   final_answer_buttons(false)
 elif final_stage == "pushback":
  label("PUSHBACK OPPORTUNITY — TEAM CONFERS")
  label(str(current_question[0]))
  final_answer_buttons(true)
 else:
  label("CHASER ROUND · QUESTION %d" % (final_questions_asked + 1))
  label(str(current_question[0]))
  action("CHASER ANSWERS", resolve_final_chaser)

func final_buzz(contestant_id: int) -> void:
 if final_stage != "team" or final_buzzer >= 0:
  return
 final_buzzer = contestant_id
 show_final_chase()

func final_answer_buttons(pushback: bool) -> void:
 for i in range(4):
  var answer_id := i
  action(str(current_question[1][i]), func(): resolve_final_team_answer(answer_id, pushback))

func resolve_final_team_answer(answer_id: int, pushback: bool) -> void:
 var correct := answer_id == int(current_question[2])
 if pushback:
  if correct:
   if final_chaser_score <= 0:
    final_team_score += 1
    final_message = "CORRECT PUSHBACK AT ZERO! THE TEAM TARGET INCREASES BY ONE."
   else:
    final_chaser_score -= 1
    final_message = "CORRECT PUSHBACK! THE CHASER MOVES BACK ONE."
  else:
   final_message = "PUSHBACK MISSED. THE CHASER STAYS PUT."
  final_stage = "chaser"
 else:
  if correct:
   final_team_score += 1
   final_message = "CONTESTANT %d CORRECT! TEAM SCORES." % (final_buzzer + 1)
  else:
   final_message = "INCORRECT. NO POINT FOR THE TEAM."
  final_buzzer = -1
 final_questions_asked += 1
 if prepare_question():
  show_final_chase()
 else:
  show_question_exhausted()

func resolve_final_chaser() -> void:
 if final_stage != "chaser":
  return
 if chaser_answers_correctly(current_question_category(), profile_for(active_chaser), "final_chase"):
  final_chaser_score += 1
  final_questions_asked += 1
  final_message = "CHASER CORRECT — ONE STEP CLOSER."
  if final_chaser_score >= final_team_score:
   final_stage = "finished"
   show_final_chase()
  elif prepare_question():
   show_final_chase()
  else:
   show_question_exhausted()
 else:
  final_stage = "pushback"
  final_message = "CHASER WRONG! TEAM CAN PUSH BACK."
  show_final_chase()

func cash_value() -> int:
 return 10000 if mode == "abc" else 5000 if mode == "gsn" else 1000

func format_cash(amount: int) -> String:
 var symbol := "$" if mode == "abc" or mode == "gsn" else "£"
 var digits := str(amount)
 var grouped := ""
 while digits.length() > 3:
  grouped = "," + digits.substr(digits.length() - 3, 3) + grouped
  digits = digits.substr(0, digits.length() - 3)
 return symbol + digits + grouped

func begin_cash() -> void:
 phase = "cash"
 question_index = 0
 cash_correct = 0
 cash_winnings = 0
 seconds_left = 60
 play_track("cash")
 if mode != "btc":
  clock.start()
 if prepare_question():
  show_question()
 else:
  show_question_exhausted()

func show_question() -> void:
 clear_ui()
 draw_studio()
 heading("CASH BUILDER")
 label(("QUESTION %d OF 5" % (question_index + 1)) if mode == "btc" else ("%d:%02d REMAINING" % [seconds_left / 60, seconds_left % 60]))
 if mode != "btc":
  label("AUTHENTIC CASH BUILDER · 60 SECONDS · NO QUESTION CAP")
 label("CASH BUILDER TOTAL: %s" % format_cash(cash_winnings))
 if mode != "btc":
  label("CONTESTANT %d OF %d · TEAM BANK: %s" % [current_contestant, int(FORMATS[mode]["players"]), format_cash(team_bank)])
 var q: Array = current_question
 if question_warning != "":
  label(question_warning)
 label(q[0])
 for i in range(4):
  var answer_index := i
  action(q[1][i], func(): answer(answer_index))
 action("MAIN MENU", show_menu)

func answer(index: int) -> void:
 var q: Array = current_question
 if index == q[2]:
  cash_correct += 1
  cash_winnings += cash_value()
 question_index += 1
 if (mode == "btc" and question_index >= 5) or (mode != "btc" and seconds_left <= 0):
  finish_cash()
 else:
  if prepare_question():
   show_question()
  else:
   show_question_exhausted()

func _on_tick() -> void:
 if phase == "btc_battle":
  if btc_battle_over:
   clock.stop()
   return
  if btc_turn == "player":
   btc_player_seconds = maxi(0, btc_player_seconds - 1)
  else:
   btc_chaser_seconds = maxi(0, btc_chaser_seconds - 1)
  if btc_player_seconds <= 0 or btc_chaser_seconds <= 0:
   btc_battle_over = true
   clock.stop()
  show_btc_battle()
  return
 if phase != "cash":
  return
 seconds_left -= 1
 if seconds_left <= 5:
  music.volume_db = linear_to_db(maxf(0.001, float(seconds_left) / 5.0))
 if seconds_left <= 0:
  finish_cash()
 else:
  show_question()

func finish_cash() -> void:
 clock.stop()
 music.stop()
 phase = "cash_result"
 clear_ui()
 draw_studio()
 heading("CASH BUILDER COMPLETE")
 label("%d CORRECT ANSWERS" % cash_correct)
 label("TOTAL: %s" % format_cash(cash_winnings))
 label("The next round is ready." if mode != "btc" else "The Chasers are preparing their offers.")
 if mode == "btc":
  begin_btc_offers()
 else:
  action("HERE COMES THE CHASER", reveal_chaser)
  action("BACK TO SHOW SETUP", func(): select_mode(mode))

func begin_btc_offers() -> void:
 phase = "btc_offers"
 btc_revealed = 2
 btc_offers.clear()
 # Each subsequent Chaser adds a new offer. All offers are displayed before selection.
 for n in range(2, 6):
  btc_offers.append({"chasers": n, "money": offer_round((cash_winnings + (n - 1) * 10000) * offer_factor()), "clock": clampi(60 - n * 5 - int(round((float(profile_for(BTC_CHASERS[n - 1]).get("btc_time_aggression", 55)) - 50.0) / 10.0)), 20, 60)})
 show_btc_offers()

func show_btc_offers() -> void:
 clear_ui()
 draw_studio()
 heading("BEAT THE CHASERS · THE OFFERS")
 cast_card(BTC_CHASERS[btc_revealed - 1])
 label("%d CHASERS REVEALED" % btc_revealed)
 for i in range(btc_revealed):
  label(BTC_CHASERS[i])
 var current: Dictionary = btc_offers[btc_revealed - 2]
 label("%s OFFERS: £%d · CHASERS GET %d SECONDS" % [BTC_CHASERS[btc_revealed - 1], current["money"], current["clock"]])
 if btc_revealed < 5:
  action("REVEAL NEXT CHASER AND OFFER", func():
   btc_revealed += 1
   show_btc_offers()
  )
 else:
  action("VIEW ALL OFFERS", show_btc_selection)

func show_btc_selection() -> void:
 phase = "btc_selection"
 clear_ui()
 draw_studio()
 heading("NOW CHOOSE YOUR OFFER")
 label("All Chasers and their offers have been revealed.")
 for offer in btc_offers:
  var selected: Dictionary = offer
  action("%d CHASERS · £%d · %d SECONDS" % [selected["chasers"], selected["money"], selected["clock"]], func(): choose_btc_offer(selected))

func choose_btc_offer(offer: Dictionary) -> void:
 btc_selected_offer = offer.duplicate()
 btc_player_seconds = 60
 btc_chaser_seconds = int(offer["clock"])
 btc_turn = "player"
 btc_buzzed_chaser = -1
 btc_battle_over = false
 btc_battle_message = "Your turn. A correct answer switches the clock to the Chasers."
 play_track("btc-battle")
 clock.start()
 if prepare_question():
  show_btc_battle()
 else:
  show_question_exhausted()

func show_btc_battle() -> void:
 phase = "btc_battle"
 clear_ui()
 draw_studio()
 heading("BEAT THE CHASERS · FACE THE CHASERS")
 label("CONTESTANT: %d SEC     CHASERS: %d SEC" % [btc_player_seconds, btc_chaser_seconds])
 label(btc_battle_message)
 if btc_battle_over:
  clock.stop()
  music.stop()
  heading("YOU BEAT THE CHASERS!" if btc_chaser_seconds <= 0 else "THE CHASERS WIN!")
  action("BACK TO SETUP", func(): select_mode(mode))
  return
 label("TURN: " + ("CONTESTANT" if btc_turn == "player" else "CHASERS"))
 label(str(current_question[0]))
 if btc_turn == "player":
  for i in range(4):
   var answer_id := i
   action(str(current_question[1][i]), func(): btc_player_answer(answer_id))
 else:
  if btc_buzzed_chaser < 0:
   label("ONE CHASER BUZZES IN TO ANSWER.")
   for i in range(int(btc_selected_offer["chasers"])):
    var chaser_id := i
    action(BTC_CHASERS[i] + " · BUZZ IN", func(): btc_chaser_buzz(chaser_id))
  else:
   label(BTC_CHASERS[btc_buzzed_chaser].to_upper() + " HAS BUZZED IN.")
   action("ANSWER QUESTION", btc_chaser_answer)

func btc_next_question() -> void:
 if btc_player_seconds <= 0 or btc_chaser_seconds <= 0:
  btc_battle_over = true
  clock.stop()
  show_btc_battle()
 elif prepare_question():
  show_btc_battle()
 else:
  show_question_exhausted()

func btc_player_answer(answer_id: int) -> void:
 if btc_turn != "player" or btc_battle_over:
  return
 if answer_id == int(current_question[2]):
  btc_turn = "chasers"
  btc_battle_message = "CORRECT! CHASERS' CLOCK IS ACTIVE."
 else:
  btc_battle_message = "INCORRECT. CONTESTANT CONTINUES."
 btc_next_question()

func btc_chaser_buzz(chaser_id: int) -> void:
 if btc_turn != "chasers" or btc_buzzed_chaser >= 0 or btc_battle_over:
  return
 if chaser_id < 0 or chaser_id >= int(btc_selected_offer["chasers"]):
  return
 btc_buzzed_chaser = chaser_id
 show_btc_battle()

func btc_chaser_answer() -> void:
 if btc_turn != "chasers" or btc_buzzed_chaser < 0 or btc_battle_over:
  return
 var name: String = BTC_CHASERS[btc_buzzed_chaser]
 if chaser_answers_correctly(current_question_category(), profile_for(name), "btc"):
  btc_turn = "player"
  btc_battle_message = name + " ANSWERED CORRECTLY. CONTESTANT'S TURN."
 else:
  btc_battle_message = name + " ANSWERED INCORRECTLY. CHASERS CONTINUE."
 btc_buzzed_chaser = -1
 btc_next_question()


func music_save_path(slot: String, for_mode: String) -> String:
 return "user://chase_audio_%s_%s.mp3" % [for_mode, slot]

func restore_music_imports() -> void:
 for format_id in FORMATS:
  for slot in ["intro", "chaser-entrance", "cash", "final", "btc-battle"]:
   var path := music_save_path(slot, str(format_id))
   if FileAccess.file_exists(path):
    var loaded := AudioStreamMP3.load_from_file(path)
    if loaded != null:
     loaded.loop = true
     imported_tracks[str(format_id) + ":" + slot] = loaded

func import_music(slot: String) -> void:
 music_slot = slot
 file_dialog.popup_centered_ratio(0.7)

func _on_music_file(path: String) -> void:
 if music_slot == "menu-theme":
  if path.get_extension().to_lower() != "mp3":
   label("Please select an MP3 for the menu theme.")
   return
  var source := FileAccess.open(path, FileAccess.READ)
  if source == null:
   label("Unable to read the selected MP3.")
   return
  var data := source.get_buffer(source.get_length())
  var target := FileAccess.open(MENU_MUSIC_PATH, FileAccess.WRITE)
  if target == null:
   label("Unable to save the menu music.")
   return
  target.store_buffer(data)
  target.close()
  var custom_stream := AudioStreamMP3.load_from_file(MENU_MUSIC_PATH)
  if custom_stream == null:
   label("Unable to decode the selected MP3.")
   return
  custom_stream.loop = true
  menu_theme_player.stop()
  menu_theme_player.stream = custom_stream
  menu_theme_player.play()
  show_menu()
  return
 var ext := path.get_extension().to_lower()
 var stream: AudioStream
 if ext == "mp3":
  stream = AudioStreamMP3.load_from_file(path)
 elif ext == "ogg":
  stream = AudioStreamOggVorbis.load_from_file(path)
 elif ext == "wav":
  stream = AudioStreamWAV.load_from_file(path)
 if stream != null:
  if ext == "mp3":
   var source := FileAccess.open(path, FileAccess.READ)
   if source != null:
    var target := FileAccess.open(music_save_path(music_slot, mode), FileAccess.WRITE)
    if target != null:
     target.store_buffer(source.get_buffer(source.get_length()))
     target.close()
  imported_tracks[mode + ":" + music_slot] = stream
  if music_slot == "cash":
   imported_tracks["btc:cash"] = stream
   imported_tracks["uk:cash"] = stream
  label("IMPORTED: " + path.get_file())
 else:
  label("Could not decode this audio file.")

func play_track(slot: String) -> void:
 music.stop()
 music.volume_db = 0.0
 var key := mode + ":" + slot
 if mode == "btc" and (slot == "cash" or slot == "final") and not imported_tracks.has(key):
  key = "uk:" + slot
 if imported_tracks.has(key):
  music.stream = imported_tracks[key]
  music.play()

func rect(parent: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
 var r := ColorRect.new()
 r.position = pos
 r.size = size
 r.color = color
 parent.add_child(r)
 return r

func polygon(parent: Control, vertices: PackedVector2Array, color: Color) -> void:
 var p := Polygon2D.new()
 p.polygon = vertices
 p.color = color
 parent.add_child(p)

func stage_portrait(name: String, at: Vector2, size: int = 92) -> void:
 var image := cast_portrait(name, size)
 image.position = at
 image.size = Vector2(size, size)
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(image)

func draw_studio() -> void:
 var bg := Color("#111c49") if mode == "uk" else Color("#103668") if mode == "gsn" else Color("#163c70") if mode == "abc" else Color("#291143")
 rect(stage, Vector2.ZERO, Vector2(1280, 720), bg)
 # Audience, lighting trusses and illuminated rear wall.
 for i in range(14):
  rect(stage, Vector2(35 + i * 92, 80), Vector2(42, 13), Color("#f6d185"))
  rect(stage, Vector2(35 + i * 92, 105), Vector2(22, 190), bg.lightened(0.14))
 rect(stage, Vector2(110, 210), Vector2(1060, 320), bg.lightened(0.25))
 polygon(stage, PackedVector2Array([Vector2(0, 550), Vector2(1280, 550), Vector2(1280, 720), Vector2(0, 720)]), Color("#081128"))
 if mode == "btc":
  rect(stage, Vector2(230, 195), Vector2(820, 35), Color("#d2a4fa"))
  rect(stage, Vector2(230, 195), Vector2(52, 230), Color("#9e6cdb"))
  rect(stage, Vector2(998, 195), Vector2(52, 230), Color("#9e6cdb"))
  polygon(stage, PackedVector2Array([Vector2(300, 380), Vector2(980, 380), Vector2(900, 455), Vector2(380, 455)]), Color("#a274dd"))
  polygon(stage, PackedVector2Array([Vector2(580, 450), Vector2(700, 450), Vector2(790, 720), Vector2(490, 720)]), Color("#55317e"))
  stage_portrait(str(FORMATS[mode]["host"]), Vector2(70, 330), 108)
  for i in range(BTC_CHASERS.size()):
   stage_portrait(str(BTC_CHASERS[i]), Vector2(310 + i * 140, 252), 100)
  return
 # The Chase table runs from the Chaser's raised desk at the back
 # down toward the contestant's desk at the front of the studio.
 polygon(stage, PackedVector2Array([Vector2(535, 250), Vector2(745, 250), Vector2(1065, 665), Vector2(215, 665)]), Color("#dfb65e") if mode == "uk" else Color("#80c8f5"))
 polygon(stage, PackedVector2Array([Vector2(548, 262), Vector2(732, 262), Vector2(1032, 647), Vector2(248, 647)]), Color("#0c2454"))
 for i in range(7):
  var t := float(i + 1) / 8.0
  var y := lerpf(270.0, 635.0, t)
  var half_width := lerpf(95.0, 370.0, t)
  polygon(stage, PackedVector2Array([Vector2(640 - half_width, y), Vector2(640 + half_width, y), Vector2(640 + half_width + 8, y + 12), Vector2(640 - half_width - 8, y + 12)]), Color("#e6bc65") if mode == "uk" else Color("#71c7ed"))
 # Chaser raised desk, contestant desk, and host side lectern.
 rect(stage, Vector2(505, 225), Vector2(270, 35), Color("#e2b55d") if mode == "uk" else Color("#8ad0f5"))
 rect(stage, Vector2(370, 648), Vector2(540, 35), Color("#d2a653") if mode == "uk" else Color("#7eb9e9"))
 rect(stage, Vector2(72, 440), Vector2(135, 95), Color("#b68a45"))
 # Larger, high-contrast chase board. Seven visible lanes run down the table.
 if phase == "head_to_head":
  var top_y := 278.0
  var bottom_y := 632.0
  var chaser_lane := clampi(head_chaser_step, 0, 8)
  var player_lane := clampi(head_player_step, 0, 8)
  # A red arrow tracks the Chaser; green tracks the contestant.
  var cy := lerpf(top_y, bottom_y, float(chaser_lane) / 8.0)
  var py := lerpf(top_y, bottom_y, float(player_lane) / 8.0)
  var chaser_x := 640.0 + lerpf(103.0, 368.0, float(chaser_lane) / 8.0)
  var player_x := 640.0 - lerpf(103.0, 368.0, float(player_lane) / 8.0)
  polygon(stage, PackedVector2Array([
   Vector2(chaser_x + 22, cy - 24),
   Vector2(chaser_x + 58, cy),
   Vector2(chaser_x + 22, cy + 24),
   Vector2(chaser_x + 22, cy + 11),
   Vector2(chaser_x - 18, cy + 11),
   Vector2(chaser_x - 18, cy - 11),
   Vector2(chaser_x + 22, cy - 11)
  ]), Color("#ff273a"))
  polygon(stage, PackedVector2Array([
   Vector2(player_x - 22, py - 24),
   Vector2(player_x - 58, py),
   Vector2(player_x - 22, py + 24),
   Vector2(player_x - 22, py + 11),
   Vector2(player_x + 18, py + 11),
   Vector2(player_x + 18, py - 11),
   Vector2(player_x - 22, py - 11)
  ]), Color("#35ff91"))


 # Studio cast portraits are part of the background set, not the question UI.
 stage_portrait(str(FORMATS[mode]["host"]), Vector2(55, 330), 108)
 stage_portrait(active_chaser, Vector2(1070, 330), 108)
