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
var btc_revealed := 0
var btc_offers: Array = []
var btc_selected_offer := {}
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

func chaser_correct_probability(category: String, profile: Dictionary = {}) -> float:
 var p: Dictionary = custom_chaser_ai if profile.is_empty() else profile
 var chance := float(p.get("knowledge", 85)) / 100.0
 if category.to_lower() == str(p.get("strongest_subject", "History")).to_lower():
  chance += 0.10
 return clampf(chance, 0.05, 0.98)

func chaser_answers_correctly(category: String, profile: Dictionary = {}) -> bool:
 return rng.randf() < chaser_correct_probability(category, profile)

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
    custom_chaser_ai[key] = data[key]

func save_chaser_profile() -> void:
 var file := FileAccess.open(CHASER_PROFILE_PATH, FileAccess.WRITE)
 if file != null:
  file.store_string(JSON.stringify(custom_chaser_ai))

func offer_factor() -> float:
 var style := str(custom_chaser_ai.get("offer_style", "Balanced"))
 var factor := chaser_offer_multiplier()
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
 var high_bias := float(custom_chaser_ai.get("high_offer_bias", 60)) / 100.0
 var low_bias := float(custom_chaser_ai.get("low_offer_bias", 40)) / 100.0
 var high := offer_round(base * (1.5 + high_bias * 3.0) * offer_factor())
 var low := offer_round(base * (0.1 + (1.0 - low_bias) * 0.35))
 low = mini(low, maxi(1000, base - 1000))
 high = maxi(high, base + 1000)
 return [
  {"name": "HIGH", "amount": high, "start": 3},
  {"name": "CASH BUILDER", "amount": cash_winnings, "start": 2},
  {"name": "LOW", "amount": low, "start": 1}
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
  action("%s · %s" % [choice["name"], format_cash(choice["amount"])], func(): accept_regular_offer(choice))

func accept_regular_offer(offer: Dictionary) -> void:
 head_player_step = int(offer["start"])
 begin_head_to_head()

func ai_option(title: String, key: String, options: Array) -> void:
 label(title + ": " + str(custom_chaser_ai.get(key, "")))
 for option in options:
  var chosen = option
  action(str(option), func():
   custom_chaser_ai[key] = chosen
   save_chaser_profile()
   show_chaser_ai_options()
  )

func show_chaser_ai_options() -> void:
 phase = "chaser_ai_options"
 clear_ui()
 draw_studio()
 heading("CUSTOM CHASER · OFFER AI")
 ai_option("Offer style", "offer_style", OFFER_STYLES)
 for setting in ["offer_aggression", "risk_taking", "high_offer_bias", "low_offer_bias", "btc_time_aggression"]:
  var key: String = setting
  label(key.replace("_", " ").capitalize() + ": " + str(custom_chaser_ai[key]))
  var slider := HSlider.new()
  slider.min_value = 0
  slider.max_value = 100
  slider.step = 5
  slider.value = float(custom_chaser_ai[key])
  slider.value_changed.connect(func(value: float):
   custom_chaser_ai[key] = int(value)
   save_chaser_profile()
  )
  overlay.add_child(slider)
 action("BACK TO SETUP", func(): select_mode(mode))

var rng := RandomNumberGenerator.new()
const QUESTION_HISTORY_PATH = "user://chase_question_history.json"
var seen_questions: Dictionary = {}
var session_questions: Dictionary = {}
var current_question: Array = []
var question_warning := ""

func question_key(q: Array) -> String:
 return (str(q[0]).strip_edges().to_lower() + "|" + "|".join(q[1])).sha256_text()

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
 for q in QUESTIONS:
  var key := question_key(q)
  if not session_questions.has(key):
   not_in_session.append(q)
   if not seen_questions.has(key):
    unseen.append(q)
 if unseen.is_empty() and not_in_session.is_empty():
  question_warning = "QUESTION BANK EXHAUSTED — add more questions to continue."
  return []
 if unseen.is_empty():
  seen_questions.clear()
  unseen = not_in_session
  question_warning = "ALL QUESTIONS USED — STARTING A NEW ROTATION."
 else:
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


func _ready() -> void:
 rng.randomize()
 load_question_history()
 load_chaser_profile()
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
 clock.stop()
 music.stop()
 clear_ui()
 heading("THE CHASE · 8-BIT ULTIMATE EDITION")
 label("NATIVE GODOT PREVIEW — gameplay migration in progress")
 for id in FORMATS:
  var chosen: String = id
  action(FORMATS[id]["title"], func(): select_mode(chosen))

func select_mode(id: String) -> void:
 mode = id
 phase = "setup"
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 label("Host: " + FORMATS[mode]["host"])
 action("START THE SHOW", start_intro)
 action("CUSTOM CHASER OFFER AI SETTINGS", show_chaser_ai_options)
 action("IMPORT OPENING MUSIC", func(): import_music("intro"))
 action("IMPORT HERE COMES THE CHASER CUE", func(): import_music("chaser-entrance"))
 action("IMPORT CASH BUILDER MUSIC", func(): import_music("cash"))
 if mode == "btc":
  action("IMPORT BTC BATTLE MUSIC", func(): import_music("btc-battle"))
 action("BACK", show_menu)

func start_intro() -> void:
 phase = "intro"
 session_questions.clear()
 intro_step = 0
 show_intro()

func show_intro() -> void:
 clear_ui()
 draw_studio()
 heading(FORMATS[mode]["title"])
 if mode == "btc":
  var steps := ["SPINNING C'S · OPENING", "PLEASE WELCOME " + FORMATS[mode]["host"].to_upper(), "CONTESTANT ENTRANCE", "THE CHASERS"]
  label(steps[intro_step])
 else:
  label("WELCOME TO THE CHASE")
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
 label("The Chaser makes their entrance!")
 action("CONTINUE TO OFFERS", show_regular_offers)

func begin_head_to_head() -> void:
 phase = "head_to_head"
 head_chaser_step = 0
 head_question = 0
 if prepare_question():
  show_head_to_head()
 else:
  show_question_exhausted()

func show_head_to_head() -> void:
 clear_ui()
 draw_studio()
 heading("THE HEAD-TO-HEAD")
 label("CONTESTANT: %d / 6     CHASER: %d / 6" % [head_player_step, head_chaser_step])
 if head_player_step >= 6:
  heading("YOU MADE IT HOME!")
  action("BACK TO SETUP", func(): select_mode(mode))
  return
 if head_chaser_step >= head_player_step + 2:
  heading("THE CHASER HAS CAUGHT YOU")
  action("BACK TO SETUP", func(): select_mode(mode))
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
 if index == q[2]:
  head_player_step += 1
 # Chaser performance is determined by the selected AI profile.
 if chaser_answers_correctly("General Knowledge"):
  head_chaser_step += 1
 head_question += 1
 if prepare_question():
  show_head_to_head()
 else:
  show_question_exhausted()

func cash_value() -> int:
 return 10000 if mode == "abc" else 1000

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
 label(("QUESTION %d OF 5" % (question_index + 1)) if mode == "btc" else ("%d SECONDS REMAINING" % seconds_left))
 label("CASH BUILDER TOTAL: %s" % format_cash(cash_winnings))
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
  btc_offers.append({"chasers": n, "money": offer_round((cash_winnings + (n - 1) * 10000) * offer_factor()), "clock": clampi(60 - n * 5 - int(round((float(custom_chaser_ai.get("btc_time_aggression", 55)) - 50.0) / 10.0)), 20, 60)})
 show_btc_offers()

func show_btc_offers() -> void:
 clear_ui()
 draw_studio()
 heading("BEAT THE CHASERS · THE OFFERS")
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
 phase = "btc_battle_preview"
 clear_ui()
 draw_studio()
 heading("OFFER ACCEPTED")
 label("%d CHASERS · £%d · %d SECOND CHASER CLOCK" % [offer["chasers"], offer["money"], offer["clock"]])
 label("The native Godot clock battle is not yet ported.")
 action("BACK TO SETUP", func(): select_mode(mode))

func import_music(slot: String) -> void:
 music_slot = slot
 file_dialog.popup_centered_ratio(0.7)

func _on_music_file(path: String) -> void:
 var ext := path.get_extension().to_lower()
 var stream: AudioStream
 if ext == "mp3":
  stream = AudioStreamMP3.load_from_file(path)
 elif ext == "ogg":
  stream = AudioStreamOggVorbis.load_from_file(path)
 elif ext == "wav":
  stream = AudioStreamWAV.load_from_file(path)
 if stream != null:
  imported_tracks[mode + ":" + music_slot] = stream
  label("IMPORTED: " + path.get_file())
 else:
  label("Could not decode this audio file.")

func play_track(slot: String) -> void:
 music.stop()
 music.volume_db = 0.0
 var key := mode + ":" + slot
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
 # Lit position indicators advance during the Head-to-Head round.
 if phase == "head_to_head":
  for j in range(mini(head_player_step, 6)):
   rect(stage, Vector2(290 + j * 95, 611 - j * 47), Vector2(35, 12), Color("#4ff4a6"))
  for j in range(mini(head_chaser_step, 6)):
   rect(stage, Vector2(955 - j * 95, 611 - j * 47), Vector2(35, 12), Color("#ff5979"))
