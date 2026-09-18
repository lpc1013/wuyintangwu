extends Node
## 全局配置表与场景导航。房间布局数据驱动：新增房间只需在 ROOMS 加一条。

const VIEWPORT_SIZE := Vector2i(896, 512)
const TITLE_BG := "res://assets/bg/title.png"
const MAP_BG := "res://assets/bg/map-gate.png"

## pools: 池区/功能区矩形（客人入池吸附区）；spawns: 客人出生点；map_anchor: 案内图上的入口按钮位置
const ROOMS := {
	"ooike": {
		"label": "大池 · 室内大浴场",
		"bg": "res://assets/bg/room-ooike.png",
		"pools": [Rect2(121, 88, 620, 224)],
		"pool_types": ["hot"],
		"spawns": [Vector2(90, 490), Vector2(448, 500), Vector2(806, 490)],
		"map_anchor": Vector2(140, 440),
		"unlock_rep": 0,
	},
	"indoor": {
		"label": "室内浴场 · 湯乃森",
		"bg": "res://assets/bg/room-indoor.png",
		"pools": [Rect2(138, 227, 612, 110)],
		"pool_types": ["herb"],
		"spawns": [Vector2(120, 492), Vector2(448, 500), Vector2(776, 492)],
		"map_anchor": Vector2(448, 235),
		"unlock_rep": 0,
	},
	"rotenburo": {
		"label": "露天风吕 · 星夜",
		"bg": "res://assets/bg/room-rotenburo.png",
		"pools": [Rect2(201, 253, 524, 145)],
		"pool_types": ["moon"],
		"spawns": [Vector2(150, 486), Vector2(448, 496), Vector2(746, 486)],
		"map_anchor": Vector2(448, 80),
		"unlock_rep": 25,
	},
	"ishiyu": {
		"label": "石泉 · 石板庭院",
		"bg": "res://assets/bg/room-ishiyu.png",
		"pools": [Rect2(457, 239, 290, 134), Rect2(150, 138, 216, 106)],
		"pool_types": ["stone", "milk"],
		"spawns": [Vector2(120, 452), Vector2(430, 470)],
		"map_anchor": Vector2(150, 300),
		"unlock_rep": 40,
	},
	"backyard": {
		"label": "后院温泉 · 木平台",
		"bg": "res://assets/bg/room-backyard.png",
		"pools": [Rect2(212, 221, 430, 154)],
		"pool_types": ["yuzu"],
		"spawns": [Vector2(120, 470), Vector2(700, 440)],
		"map_anchor": Vector2(690, 300),
		"unlock_rep": 55,
	},
	"chashitsu": {
		"label": "休息茶室 · 榻榻米",
		"bg": "res://assets/bg/room-chashitsu.png",
		"water": false,
		"pools": [Rect2(120, 372, 270, 100), Rect2(560, 380, 230, 96)],
		"pool_types": ["tatami", "tatami"],
		"spawns": [Vector2(150, 494), Vector2(700, 498)],
		"map_anchor": Vector2(760, 440),
		"unlock_rep": 70,
	},
}

var coins := 0
var current_room := "indoor"

func room_cfg(room_id: String) -> Dictionary:
	return ROOMS.get(room_id, {})

func room_count() -> int:
	return ROOMS.size()

## 昼夜时钟：hour 为 0..24 的浮点时数，按 GameData.DAY_SECONDS 走完一天
var hour := 9.0
var day := 1
var reputation := 20.0      # 0..100，映射为店铺星级
var reviews_total := 0
var reviews_good := 0
var wishes_done := 0
var codex: Array[String] = []

## 已建设施：room_id -> [{id, x, y}]；单日上限账本：汤种 -> 今日已产币
var facilities := {}
var pool_income_today := {}
## 池位等级：room_id -> [level, ...]，缺省视为 1 级
var pool_levels := {}
## 当日账本与最近一次跨天结算快照
var today := {}
var day_start_rep := 20.0
var last_report := {}

signal day_reported(report: Dictionary)

const SAVE_PATH := "user://save.json"
const MAX_REPUTATION := 100.0
const HUD_BOTTOM := 44.0            # 顶栏高度，设施不得压住
const FACILITY_PAD := 6.0           # 设施之间的最小间距
const FACILITY_INCOME_PER := 0.05   # 每件设施给本房间泡澡收益 +5%
const FACILITY_INCOME_MAX := 0.30

func _ready() -> void:
	load_game()
	_reset_day_ledger()

func _process(delta: float) -> void:
	hour += delta * 24.0 / GameData.DAY_SECONDS
	if hour >= 24.0:
		hour -= 24.0
		_close_day()
		day += 1
		pool_income_today.clear()
		_reset_day_ledger()

func _reset_day_ledger() -> void:
	today = {"income": 0, "guests": 0, "wishes": 0, "good": 0, "bad": 0, "stars": 0, "by_type": {}}
	day_start_rep = reputation

## 跨天：把当日账本连同声望增减打包成结算快照并广播
func _close_day() -> void:
	var report := today.duplicate(true)
	report["day"] = day
	report["rep_delta"] = reputation - day_start_rep
	var guests_served := int(report.guests)
	report["stars_avg"] = (float(int(report.stars)) / float(guests_served)) if guests_served > 0 else 0.0
	last_report = report
	day_reported.emit(report)

func _ledger_add(key: String, amount: int) -> void:
	today[key] = int(today.get(key, 0)) + amount

func period_index() -> int:
	return GameData.period_index_for_hour(int(floor(hour)))

func period() -> Dictionary:
	return GameData.PERIODS[period_index()]

func income_mult() -> float:
	return float(period().income)

func night_light() -> float:
	return float(period().light)

func clock_text() -> String:
	var h := int(floor(hour))
	var m := int(fmod(hour, 1.0) * 60.0)
	return "%02d:%02d" % [h, m]

func shop_stars() -> int:
	return clampi(int(floor(reputation / 20.0)), 0, 5)

func add_review(star_rating: int, good: bool, wish_done := false) -> void:
	reviews_total += 1
	if good:
		reviews_good += 1
		_ledger_add("good", 1)
	else:
		_ledger_add("bad", 1)
	if wish_done:
		wishes_done += 1
		_ledger_add("wishes", 1)
	_ledger_add("guests", 1)
	_ledger_add("stars", star_rating)
	reputation = clampf(reputation + float(star_rating - 2) * 2.0, 0.0, MAX_REPUTATION)

## 图鉴：首次接待到某物种时返回 true，便于弹提示
func note_species(species_id: String) -> bool:
	if codex.has(species_id):
		return false
	codex.append(species_id)
	return true

## ---------------- 设施经营 ----------------

func room_facilities(room_id: String) -> Array:
	return facilities.get(room_id, [])

func facility_count(room_id: String, id: String) -> int:
	var n := 0
	for e: Dictionary in room_facilities(room_id):
		if String(e.id) == id:
			n += 1
	return n

func has_facility(room_id: String, id: String) -> bool:
	return facility_count(room_id, id) > 0

## 墙带上限：所有池子里最靠上的那条边再往上一截；没有池的房间给一个固定值
func wall_limit_y(room_id: String) -> float:
	var cfg: Dictionary = ROOMS.get(room_id, {})
	var top := INF
	for r: Rect2 in cfg.get("pools", []):
		top = minf(top, r.position.y)
	if is_inf(top):
		return 140.0
	return clampf(top - 12.0, HUD_BOTTOM + 16.0, 300.0)

## 落点合法性：只依据房间配置与已建设施判定，headless 校验可直接复用
func can_place(room_id: String, id: String, center: Vector2) -> bool:
	var f := GameData.facility(id)
	if f.is_empty():
		return false
	var cfg: Dictionary = ROOMS.get(room_id, {})
	if cfg.is_empty():
		return false
	if coins < int(f.cost):
		return false
	var size := Vector2(GameData.facility_size(id))
	var rect := Rect2(center - size * 0.5, size)
	if rect.position.y < HUD_BOTTOM or rect.end.y > float(VIEWPORT_SIZE.y):
		return false
	if rect.position.x < 0.0 or rect.end.x > float(VIEWPORT_SIZE.x):
		return false
	for r: Rect2 in cfg.get("pools", []):
		if rect.intersects(r.grow(-2.0)):
			return false
	for s: Vector2 in cfg.get("spawns", []):
		if rect.has_point(s):
			return false
	for e: Dictionary in room_facilities(room_id):
		var other := Vector2(GameData.facility_size(String(e.id)))
		var orect := Rect2(Vector2(float(e.x), float(e.y)) - other * 0.5, other)
		if rect.grow(-FACILITY_PAD).intersects(orect.grow(-FACILITY_PAD)):
			return false
	if f.get("wall_only", false):
		if center.y > wall_limit_y(room_id):
			return false
		if facility_count(room_id, id) >= int(f.get("max_count", 99)):
			return false
	return true

func buy_facility(room_id: String, id: String, center: Vector2) -> bool:
	if not can_place(room_id, id, center):
		return false
	coins -= int(GameData.facility(id).cost)
	if not facilities.has(room_id):
		facilities[room_id] = []
	facilities[room_id].append({"id": id, "x": int(center.x), "y": int(center.y)})
	save_game()
	return true

## 已建设施给本房间泡澡收益的加成倍率
func facility_bonus(room_id: String) -> float:
	return 1.0 + minf(FACILITY_INCOME_MAX, FACILITY_INCOME_PER * room_facilities(room_id).size())

## 产币汤种的单日额度：按该池当前等级放大，扣减并返回实际放行数量，0 表示今日已达上限
func take_pool_budget(type_id: String, want: int, room_id := "", pool_index := 0) -> int:
	var p := GameData.pool(type_id)
	var got := want
	if bool(p.get("coin_gen", false)) and int(p.get("daily_cap", 0)) > 0:
		var cap := GameData.level_budget(type_id, pool_level(room_id, pool_index))
		var used := int(pool_income_today.get(type_id, 0))
		got = clampi(want, 0, maxi(0, cap - used))
	if got > 0:
		pool_income_today[type_id] = int(pool_income_today.get(type_id, 0)) + got
		today["income"] = int(today.get("income", 0)) + got
		var by_type: Dictionary = today.get("by_type", {})
		by_type[type_id] = int(by_type.get(type_id, 0)) + got
		today["by_type"] = by_type
	return got

## ---------------- 池位扩建 ----------------

## 补齐等级数组到该房间的池子数量
func _ensure_levels(room_id: String) -> Array:
	var cfg: Dictionary = ROOMS.get(room_id, {})
	var n: int = cfg.get("pools", []).size()
	if n == 0:
		return []
	if not pool_levels.has(room_id):
		pool_levels[room_id] = []
	var list: Array = pool_levels[room_id]
	while list.size() < n:
		list.append(1)
	return list

func pool_level(room_id: String, index: int) -> int:
	var list := _ensure_levels(room_id)
	if index < 0 or index >= list.size():
		return 1
	return int(list[index])

func pool_type_at(room_id: String, index: int) -> String:
	var types: Array = ROOMS.get(room_id, {}).get("pool_types", [])
	return String(types[index]) if index >= 0 and index < types.size() else "hot"

func max_pool_level() -> int:
	return int(GameData.UPGRADE.max_level)

func upgrade_cost(room_id: String, index: int) -> int:
	return GameData.upgrade_cost(pool_type_at(room_id, index), pool_level(room_id, index))

func can_upgrade(room_id: String, index: int) -> bool:
	var pools: Array = ROOMS.get(room_id, {}).get("pools", [])
	if index < 0 or index >= pools.size():
		return false
	if pool_level(room_id, index) >= max_pool_level():
		return false
	return coins >= upgrade_cost(room_id, index)

func do_upgrade(room_id: String, index: int) -> bool:
	if not can_upgrade(room_id, index):
		return false
	coins -= upgrade_cost(room_id, index)
	var list := _ensure_levels(room_id)
	list[index] = int(list[index]) + 1
	save_game()
	return true

## 池位等级带来的泡澡收益倍率
func pool_income_mult(room_id: String, index: int) -> float:
	return GameData.level_income(pool_level(room_id, index))

## 某汤种当前生效的单日额度：取所有接待它的池子里等级最高的一份
func budget_for_type(type_id: String) -> int:
	var best := 0
	for room_id: String in ROOMS:
		var n: int = ROOMS[room_id].get("pools", []).size()
		for i in n:
			if pool_type_at(room_id, i) == type_id:
				best = maxi(best, GameData.level_budget(type_id, pool_level(room_id, i)))
	return best


func save_game() -> void:
	var data := {
		"coins": coins, "day": day, "hour": hour,
		"reputation": reputation, "reviews_total": reviews_total,
		"reviews_good": reviews_good, "wishes_done": wishes_done, "codex": codex,
		"facilities": facilities, "pool_levels": pool_levels,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	coins = int(data.get("coins", 0))
	day = int(data.get("day", 1))
	hour = float(data.get("hour", 9.0))
	reputation = float(data.get("reputation", 20))
	reviews_total = int(data.get("reviews_total", 0))
	reviews_good = int(data.get("reviews_good", 0))
	wishes_done = int(data.get("wishes_done", 0))
	codex.clear()
	for s: Variant in data.get("codex", []):
		codex.append(String(s))
	facilities.clear()
	var saved: Dictionary = data.get("facilities", {})
	for room_id: String in saved:
		if not ROOMS.has(room_id):
			continue
		var list: Array = []
		for e: Variant in saved[room_id]:
			var item: Dictionary = e
			if not item.has("id"):
				continue
			list.append({"id": String(item.id), "x": int(item.x), "y": int(item.y)})
		facilities[room_id] = list
	pool_levels.clear()
	var saved_levels: Dictionary = data.get("pool_levels", {})
	for room_id: String in saved_levels:
		if not ROOMS.has(room_id):
			continue
		var list: Array = []
		for v: Variant in saved_levels[room_id]:
			list.append(clampi(int(v), 1, max_pool_level()))
		pool_levels[room_id] = list
		_ensure_levels(room_id)

const BAR_COLOR := Color(0.09, 0.06, 0.13, 0.62)

func style_button(button: Button) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.09, 0.06, 0.13, 0.85)
	base.border_color = Color(0.95, 0.8, 0.45, 1.0)
	base.set_border_width_all(2)
	base.set_corner_radius_all(0)
	base.set_content_margin_all(6)
	var hover: StyleBoxFlat = base.duplicate()
	hover.bg_color = Color(0.18, 0.11, 0.24, 0.92)
	var pressed: StyleBoxFlat = base.duplicate()
	pressed.bg_color = Color(0.04, 0.02, 0.07, 0.92)
	# 默认主题在 disabled 下不画面板，锁定的按钮会糊在像素背景里，这里补一块暗板
	var disabled: StyleBoxFlat = base.duplicate()
	disabled.bg_color = Color(0.12, 0.10, 0.16, 0.72)
	disabled.border_color = Color(0.46, 0.42, 0.52, 0.85)
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.92, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.58, 0.66, 1.0))
	button.add_theme_font_size_override("font_size", 14)

## ---------------- 房间解锁 ----------------

## 声望门槛：0 表示开业即用，其余按店铺声望逐间放开
func unlock_rep(room_id: String) -> int:
	return int(ROOMS.get(room_id, {}).get("unlock_rep", 0))

func is_unlocked(room_id: String) -> bool:
	return reputation >= float(unlock_rep(room_id))

func lock_text(room_id: String) -> String:
	return "声望 %d 解锁（当前 %d）" % [unlock_rep(room_id), int(floor(reputation))]

func unlocked_count() -> int:
	var n := 0
	for room_id: String in ROOMS:
		if is_unlocked(room_id):
			n += 1
	return n

func goto_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func goto_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func goto_room(room_id: String) -> void:
	if not ROOMS.has(room_id):
		push_error("未知房间: " + room_id)
		return
	if not is_unlocked(room_id):
		push_error("房间尚未解锁: " + room_id + " " + lock_text(room_id))
		return
	current_room = room_id
	get_tree().change_scene_to_file("res://scenes/room.tscn")
