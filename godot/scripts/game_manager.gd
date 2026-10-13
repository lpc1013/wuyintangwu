extends Node
## 全局配置表与场景导航。房间布局数据驱动：新增房间只需在 ROOMS 加一条。

const VIEWPORT_SIZE := Vector2i(896, 512)
const TITLE_BG := "res://assets/bg/title.png"
const MAP_BG := "res://assets/bg/map-gate.png"

## pools: 池区/功能区矩形（客人入座吸附区）；spawns: 客人出生点；map_anchor: 案内图上的入口按钮位置
## lights: 背景里本来就画好的灯笼/壁灯心点，入夜从这些位置往外打暖光
## kind: onsen（默认，下水泡汤）| lounge（落座喝茶，客人换成盘坐姿态、停留更久）
const ROOMS := {
	"ooike": {
		"label": "大池 · 室内大浴场",
		"bg": "res://assets/bg/room-ooike.png",
		"pools": [Rect2(121, 88, 620, 224)],
		"pool_types": ["hot"],
		"spawns": [Vector2(90, 490), Vector2(448, 500), Vector2(806, 490)],
		# 池沿两条坐凳带 + 前排两段裸地板（水壶、木屐、凳腿都画在它们之间）
		"lots": [Rect2(304, 456, 144, 56), Rect2(560, 456, 144, 56),
			Rect2(56, 328, 208, 36), Rect2(688, 328, 160, 36)],
		"map_anchor": Vector2(140, 440),
		"lights": [Vector2(28, 148), Vector2(101, 46), Vector2(150, 56),
			Vector2(746, 56), Vector2(795, 46), Vector2(868, 148)],
		"unlock_rep": 0,
	},
	"indoor": {
		"label": "室内浴场 · 湯乃森",
		"bg": "res://assets/bg/room-indoor.png",
		"pools": [Rect2(138, 227, 612, 110)],
		"pool_types": ["herb"],
		"spawns": [Vector2(120, 492), Vector2(448, 500), Vector2(776, 492)],
		# 洗漱凳排到了走廊边，只剩竹丛苔地一整块 + 右侧毛巾筐与木架之间一条石沿
		# （石沿 28 高只容得下手绘小件；抠图目录里最矮的盘子要 32，往下借 8 个像素）
		"lots": [Rect2(0, 344, 96, 96), Rect2(800, 352, 96, 36)],
		"map_anchor": Vector2(448, 235),
		"lights": [Vector2(567, 50), Vector2(858, 141)],
		"unlock_rep": 0,
	},
	"rotenburo": {
		"label": "露天风吕 · 星夜",
		"bg": "res://assets/bg/room-rotenburo.png",
		"pools": [Rect2(201, 253, 524, 145)],
		"pool_types": ["moon"],
		"spawns": [Vector2(150, 486), Vector2(448, 496), Vector2(746, 486)],
		# 池后枯山水白沙带 + 左右雪台
		"lots": [Rect2(330, 176, 340, 70), Rect2(600, 400, 296, 112),
			Rect2(0, 400, 84, 112)],
		"map_anchor": Vector2(448, 80),
		"lights": [Vector2(227, 161), Vector2(288, 180)],
		"unlock_rep": 25,
	},
	"ishiyu": {
		"label": "石泉 · 石板庭院",
		"bg": "res://assets/bg/room-ishiyu.png",
		"pools": [Rect2(457, 239, 290, 134), Rect2(150, 138, 216, 106)],
		"pool_types": ["stone", "milk"],
		"spawns": [Vector2(120, 452), Vector2(430, 470)],
		# 两池之间的苔地砾石 + 右下石板路；左下木桶台是画好的
		"lots": [Rect2(60, 250, 300, 110), Rect2(640, 400, 250, 110),
			Rect2(784, 148, 112, 132)],
		"map_anchor": Vector2(150, 300),
		"lights": [Vector2(488, 113)],
		"unlock_rep": 40,
	},
	"backyard": {
		"label": "后院温泉 · 木平台",
		"bg": "res://assets/bg/room-backyard.png",
		"pools": [Rect2(212, 221, 430, 154)],
		"pool_types": ["yuzu"],
		"spawns": [Vector2(120, 470), Vector2(700, 440)],
		# 池前木平台 + 右侧木地板 + 右上缘侧走廊；左下角是画好的引水口与石盆
		"lots": [Rect2(300, 415, 320, 97), Rect2(760, 430, 136, 82),
			Rect2(800, 212, 96, 96)],
		"map_anchor": Vector2(690, 300),
		"lights": [Vector2(572, 123), Vector2(843, 139), Vector2(877, 165)],
		"unlock_rep": 55,
	},
	"chashitsu": {
		"label": "休息茶室 · 榻榻米",
		"bg": "res://assets/bg/room-chashitsu.png",
		# 落座房间：客人不下水，盘坐在坐垫上喝茶，两条矩形是座席带而不是池面
		"kind": "lounge",
		"pools": [Rect2(120, 372, 270, 100), Rect2(560, 380, 230, 96)],
		"pool_types": ["tatami", "tatami"],
		# 背景里画死的坐垫中心，按座席带分组给出：左带只有茶几两侧两只，
		# 右带取前排三只（茶几后面那只被桌腿挡着，坐上去等于叠在桌子底下）
		"seats": [[Vector2(122, 394), Vector2(373, 390)],
			[Vector2(606, 378), Vector2(628, 410), Vector2(765, 407)]],
		"spawns": [Vector2(150, 494), Vector2(700, 498)],
		# 中央榻榻米 + 前景板缘的两段（夹在两组座敷与画好的条柜之间）；
		# 左边的开口是拉门外的庭院，不是地面
		"lots": [Rect2(400, 300, 160, 210), Rect2(392, 456, 160, 56),
			Rect2(0, 456, 112, 56)],
		"map_anchor": Vector2(760, 440),
		"lights": [Vector2(575, 56)],
		"unlock_rep": 70,
	},
}

var coins := 0
var current_room := "indoor"

func room_cfg(room_id: String) -> Dictionary:
	return ROOMS.get(room_id, {})

func room_count() -> int:
	return ROOMS.size()

## 房间玩法：onsen 下水泡汤，lounge 落座喝茶。缺省 onsen。
func room_kind(room_id: String) -> String:
	return String(ROOMS.get(room_id, {}).get("kind", "onsen"))

func is_lounge(room_id: String) -> bool:
	return room_kind(room_id) == "lounge"

## 抽一个本房间招待得起的心愿：心愿所需设施若在这间房里根本没有空地放下，
## 就不该许给客人——否则这一位天生拿不到满星，玩家也无从补救。
func pick_wish(room_id: String) -> String:
	var ids: Array[String] = []
	for id: String in GameData.WISHES:
		var fits := true
		for need: String in GameData.wish_needs(id):
			if not room_fits(room_id, String(need)):
				fits = false
				break
		if fits:
			ids.append(id)
	if ids.is_empty():
		return "alone"
	if is_lounge(room_id):
		# 茶室是坐着消磨时间的地方，先只想喝茶/小睡/闲聊的那些
		var seated: Array[String] = []
		for id: String in ids:
			if GameData.WISH_SEATED.has(id):
				seated.append(id)
		if not seated.is_empty():
			return String(seated.pick_random())
	return String(ids.pick_random())

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
const PLACEMENT_GRID := 16.0        # 落点网格：家具底部中心对齐到格点才排得齐
const FACILITY_INCOME_PER := 0.05   # 每件设施给本房间在席收益 +5%
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
		_roll_story_day()

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

## 夜罩强度：时段表里每档一个定值，直接取用会在整点「啪」地跳一档。
## 改成在本档内朝下一档线性过渡，昼夜连成一条斜坡，灯光才跟得上天色。
## 「深夜」那档跨 0 点（23→29），小时数落在 from 之前时要补满 24 再算进度。
func night_light() -> float:
	var idx := period_index()
	var p: Dictionary = GameData.PERIODS[idx]
	var q: Dictionary = GameData.PERIODS[(idx + 1) % GameData.PERIODS.size()]
	var from := float(p.from)
	var to := float(p.to)
	var h := hour
	if h < from:
		h += 24.0
	var t := clampf((h - from) / maxf(to - from, 1.0), 0.0, 1.0)
	return lerpf(float(p.light), float(q.light), t)

## 一天 210 秒，一小时才 8.75 秒，带分钟的话每秒跳六七下，玩家看到的是抖动的数字
## 而不是时间。展示只留小时；hour 仍是浮点，时段与夜罩渐变都靠它。
func clock_text() -> String:
	return "%02d:00" % int(floor(hour))

func shop_stars() -> int:
	return clampi(int(floor(reputation / 20.0)), 0, 5)

## 记一条点评，返回**实际**到账的声望增量：封顶之后再来五星也是 0，
## 现场反馈读的就是这个返回值，不能自己再乘一遍公式
func add_review(star_rating: int, good: bool, wish_done := false) -> float:
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
	var before := reputation
	reputation = clampf(reputation + float(star_rating - 2) * 2.0, 0.0, MAX_REPUTATION)
	advance_chapter()
	return reputation - before

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
	if bool(f.get("wall_only", false)):
		# 墙上件不占地面 lot，只认墙带高度与单间数量
		if center.y > wall_limit_y(room_id):
			return false
		return facility_count(room_id, id) < int(f.get("max_count", 99))
	# 落地件：整只必须待在背景留空的地面块里，否则会压到画死的木桶毛巾
	for l: Rect2 in cfg.get("lots", []):
		if l.encloses(rect):
			return true
	return false

## 落点吸附：以底部中心对齐格点，一排家具才站得齐
func snap_center(id: String, center: Vector2) -> Vector2:
	var half := Vector2(GameData.facility_size(id)) * 0.5
	var bx: float = round(center.x / PLACEMENT_GRID) * PLACEMENT_GRID
	var by: float = round((center.y + half.y) / PLACEMENT_GRID) * PLACEMENT_GRID
	return Vector2(bx, by - half.y)

## 只看几何：本房间是否存在一块容得下它的空地。忽略金币与已建设施的挤压，
## 供建造调色板把「这里根本放不下」的选项直接置灰，而不是让玩家反复点击试错。
func room_fits(room_id: String, id: String) -> bool:
	var f := GameData.facility(id)
	if f.is_empty():
		return false
	var cfg: Dictionary = ROOMS.get(room_id, {})
	if cfg.is_empty():
		return false
	var size := Vector2(GameData.facility_size(id))
	if bool(f.get("wall_only", false)):
		# 墙带不只是高度：底边还得落在 16 格上、顶边不压 HUD、下缘不碰池沿——
		# 少算一条，调色板就会把其实挂不上的件点亮着骗人点一次红一次
		for by in range(16, int(VIEWPORT_SIZE.y) + 1, 16):
			var top := float(by) - float(size.y)
			var center_y := top + float(size.y) * 0.5
			if top < HUD_BOTTOM or center_y > wall_limit_y(room_id):
				continue
			var rect := Rect2(64.0, top, float(size.x), float(size.y))
			var hit_pool := false
			for r: Rect2 in cfg.get("pools", []):
				if rect.intersects(r.grow(-2.0)):
					hit_pool = true
			if not hit_pool:
				return true
		return false
	for l: Rect2 in cfg.get("lots", []):
		if l.size.x >= size.x and l.size.y >= size.y:
			return true
	return false

func buy_facility(room_id: String, id: String, center: Vector2) -> bool:
	if not can_place(room_id, id, center):
		return false
	coins -= int(GameData.facility(id).cost)
	if not facilities.has(room_id):
		facilities[room_id] = []
	facilities[room_id].append({"id": id, "x": int(center.x), "y": int(center.y)})
	save_game()
	return true

## 拆除：落点被限制在地面块里，摆错了得有反悔的口子，退一半钱。
## grace 给手指留出容差：桌面用 0，触摸端按件放大命中矩形。
func sell_facility(room_id: String, center: Vector2, grace := 0.0) -> int:
	var list: Array = room_facilities(room_id)
	for i in list.size():
		var e: Dictionary = list[i]
		var size := Vector2(GameData.facility_size(String(e.id)))
		var rect := Rect2(Vector2(float(e.x), float(e.y)) - size * 0.5, size).grow(grace)
		if rect.has_point(center):
			list.remove_at(i)
			var refund := int(GameData.facility(String(e.id)).cost) / 2
			coins += refund
			save_game()
			return refund
	return 0

## 已建设施给本房间在席收益的加成倍率
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

## 席位等级带来的在席收益倍率
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


## ---------------- 叙事状态 ----------------

## 每只动物的往来记忆：visits 累计来访、seen_intro 是否已自我介绍、
## arc_stage 主线阶段、seen 本只已播过的条目 id（同一条不重播）
var memory := {}
## 风向情报：[{pool, trend, weight, until}]，读信或闲聊时写入，两天后过期
var forecast: Array = []
## 信箱：离店时攒下的信，次日才送达；读过才把 hint 折进风向
var mailbox: Array = []
## 已读文案的收藏册：id 全局唯一，读到一条记一条，分母是 Story.line_count()
var story_log: Array = []
## 当前章节下标（0 起）；达成 CHAPTERS 门槛后前进，末章封顶
var chapter := 0
## 跨天掷出的惊喜事件台词，等下一间房里的玩家来读
var pending_surprise: Dictionary = {}

const FORECAST_TTL := 2
const FORECAST_CAP := 6
const MAILBOX_CAP := 12
## 离店留信的概率，与网页版一致：熟客也未必留，留了才次日到
const LETTER_CHANCE := 0.5
## 跨天有几率撞上一桩店内奇闻
const SURPRISE_CHANCE := 0.45
## murmur 的 rare 台词按这个权重降权，稀有句不该比常句还常见
const RARE_WEIGHT := 0.3

signal mail_arrived(count: int)
signal chapter_advanced(index: int)

func _memory(sp: String) -> Dictionary:
	if not memory.has(sp):
		memory[sp] = {"visits": 0, "seen_intro": false, "arc_stage": 0, "seen": []}
	return memory[sp]

## 进店记账：arc_stage 沿用网页版公式（满 3 次小成、满 6 次大成），主线台词按它解锁
func note_visit(sp: String) -> Dictionary:
	var m := _memory(sp)
	m.visits = int(m.visits) + 1
	m.arc_stage = arc_stage(int(m.visits))
	return m

func arc_stage(visits: int) -> int:
	return 2 if visits >= 6 else (1 if visits >= 3 else 0)

## 契合度 → 网页版的三档水质评价：对味 perfect、普通 basic、踩雷 wrong
static func match_quality(aff: int) -> String:
	return "perfect" if aff > 0 else ("wrong" if aff < 0 else "basic")

## 台词判定上下文：条目 when 里出现的字段一律从这里取
func story_ctx(sp: String, aff: int) -> Dictionary:
	var m := _memory(sp)
	return {"visits": int(m.visits), "arc_stage": int(m.arc_stage), "match": match_quality(aff),
			"period": String(period().id), "first": not bool(m.seen_intro)}

## when 匹配：数据里目前只有 visitsMin / arcStage / match 三种键，
## 认得的键逐条比对，认不出的键放行——将来网页版加了新条件也不至于让本作闭嘴。
static func when_ok(when: Dictionary, ctx: Dictionary) -> bool:
	if when.has("visitsMin") and int(ctx.visits) < int(when.visitsMin):
		return false
	if when.has("visitsMax") and int(ctx.visits) > int(when.visitsMax):
		return false
	if when.has("arcStage") and int(ctx.arc_stage) != int(when.arcStage):
		return false
	if when.has("match") and String(ctx.match) != String(when.match):
		return false
	if when.has("period") and String(ctx.period) != String(when.period):
		return false
	if bool(when.get("first", false)) and not bool(ctx.first):
		return false
	return true

## 选一条此刻条件成立、且本只还没播过的台词。选不到就返回空字典：
## 剧情是经营之上的糖，任何一只动物没词可说都不该挡住玩法。
func pick_line(channel_id: String, sp: String, ctx: Dictionary) -> Dictionary:
	var m := _memory(sp)
	var seen: Array = m.seen
	var candidates: Array = []
	for e: Dictionary in Story.entries(channel_id, sp):
		var when: Dictionary = e.get("when", {})
		if not when.is_empty() and not when_ok(when, ctx):
			continue
		if seen.has(String(e.id)):
			continue
		candidates.append(e)
	if candidates.is_empty():
		# 全播过就重置这一只的记忆，宁可重播也别让店里彻底没了声音
		seen.clear()
		return {}
	var total := 0.0
	var weights: Array = []
	for e: Dictionary in candidates:
		var w := 1.0 if String(e.get("rarity", "common")) == "common" else RARE_WEIGHT
		weights.append(w)
		total += w
	var roll := randf() * total
	var chosen: Dictionary = candidates[candidates.size() - 1]
	for i in candidates.size():
		roll -= float(weights[i])
		if roll <= 0.0:
			chosen = candidates[i]
			break
	seen.append(String(chosen.id))
	_log_story(String(chosen.id))
	return chosen

func _log_story(id: String) -> void:
	if id == "" or story_log.has(id):
		return
	story_log.append(id)

func mark_intro_seen(sp: String) -> void:
	_memory(sp).seen_intro = true

## 风向写入：置信度折进权重（越没把握的越贴近 1），同池只留最新，两天后过期
func apply_hint(hint: Dictionary, confidence := 1.0) -> void:
	if hint.is_empty():
		return
	var pool := String(hint.get("pool", ""))
	if not GameData.POOLS.has(pool):
		return
	var w := clampf(1.0 + (float(hint.get("weight", 1.0)) - 1.0) * confidence, 0.5, 2.0)
	for e in forecast:
		if String(e.pool) == pool:
			e.weight = w
			e.until = day + FORECAST_TTL
			return
	forecast.append({"pool": pool, "trend": String(hint.get("trend", "up")), "weight": w,
			"until": day + FORECAST_TTL})
	while forecast.size() > FORECAST_CAP:
		forecast.pop_front()

## 选席倍率：风向只放大契合度，不推翻它——客人不会为了传闻去泡踩雷的汤
func spawn_weight(type_id: String) -> float:
	var mult := 1.0
	for e in forecast:
		if String(e.pool) == type_id and day <= int(e.until):
			mult *= float(e.weight)
	return clampf(mult, 0.6, 2.0)

func forecast_text() -> String:
	var parts: Array[String] = []
	for e in forecast:
		if day > int(e.until):
			continue
		var arrow := "↑" if float(e.weight) >= 1.0 else "↓"
		parts.append("%s %s%.1f" % [String(GameData.pool(String(e.pool)).get("name", e.pool)),
				arrow, absf(float(e.weight))])
	return " · ".join(parts)

## 离店留信：只掷五成骰子。网页版的 hintRate 管的是「闲聊那句带不带风向」，
## 本作风向写在条目自己的 hint 里，所以档案有这个字段也不参与这里的判定。
## 信先入账本，次日才算送达。
func post_letter(sp: String, ctx: Dictionary) -> Dictionary:
	if randf() >= LETTER_CHANCE:
		return {}
	var e := pick_line("letter", sp, ctx)
	if e.is_empty():
		return {}
	mailbox.append({"id": String(e.id), "species": sp, "title": String(e.get("title", "一封来信")),
			"body": String(e.get("body", "")), "day": day + 1, "hint": e.get("hint", {}), "read": false})
	while mailbox.size() > MAILBOX_CAP:
		mailbox.pop_front()
	save_game()
	return e

func due_mail() -> Array:
	var list: Array = []
	for i in mailbox.size():
		var m: Dictionary = mailbox[i]
		if not bool(m.read) and day >= int(m.day):
			list.append(i)
	return list

## 读信：只有读过之后信里的风向才生效，未读的信不该偷偷改经营数字
func read_mail(index: int) -> Dictionary:
	if index < 0 or index >= mailbox.size():
		return {}
	var m: Dictionary = mailbox[index]
	if bool(m.read) or day < int(m.day):
		return {}
	m.read = true
	var profile := Story.profile(String(m.species))
	apply_hint(m.hint, float(profile.get("confidence", 0.8)))
	_log_story(String(m.id))
	save_game()
	return m

## 跨天：过期风向清掉，到期的信报一次数，再掷一次店内奇闻
func _roll_story_day() -> void:
	var alive: Array = []
	for e in forecast:
		if day <= int(e.until):
			alive.append(e)
	forecast = alive
	var n := due_mail().size()
	if n > 0:
		mail_arrived.emit(n)
	_roll_surprise()

## 惊喜台词先攒着：跨天也许正站在案内图，那儿没有对白卡可以播
func _roll_surprise() -> void:
	if not pending_surprise.is_empty() or randf() >= SURPRISE_CHANCE:
		return
	var ids: Array = Story.event_ids()
	ids.shuffle()
	for id: String in ids:
		# 逐个试：pick_line 会替我们把播光的事件跳过，比先算剩余条数省事
		var e := pick_line("surprise", id, story_ctx(id, 0))
		if not e.is_empty():
			pending_surprise = e
			return

## 网页版的道具按「动作」取名，本作按设施取名，两边就近对上同一件物：
## 修剪→盆栽，祈愿→石灯笼，眺望→相机，补货→贩卖机，开席→长凳，喂茶→茶炉。
## 只剩水桶没有对应文本，点它就不出声，不硬凑。
const PROP_BY_FACILITY := {
	"plant": "trim", "lantern": "pray", "camera": "gaze",
	"vender": "restock", "bench": "feast", "tea": "feed",
}

## 空手点设施：读一段它的故事。ctx 仍走 story_ctx，
## 免得哪天道具文本加了 when 条件，空字典会让取值当场炸
func prop_line(facility_id: String) -> Dictionary:
	var prop_id := String(PROP_BY_FACILITY.get(facility_id, ""))
	if prop_id == "":
		return {}
	return pick_line("prop", prop_id, story_ctx(prop_id, 0))

## 主线阶梯：门槛只用本作已有的经营事实（累计接待 + 店铺星级），达成即推进
func chapter_now() -> Dictionary:
	return Story.CHAPTERS[clampi(chapter, 0, Story.CHAPTERS.size() - 1)]

func chapter_goal() -> String:
	var c := chapter_now()
	return "累计接待 %d/%d · 店铺 %d/%d 星" % [reviews_total, int(c.guests), shop_stars(), int(c.star)]

func advance_chapter() -> void:
	var moved := false
	while chapter < Story.CHAPTERS.size() - 1:
		var c: Dictionary = Story.CHAPTERS[chapter]
		if reviews_total < int(c.guests) or shop_stars() < int(c.star):
			break
		chapter += 1
		moved = true
	if moved:
		chapter_advanced.emit(chapter)

func save_game() -> void:
	var data := {
		"coins": coins, "day": day, "hour": hour,
		"reputation": reputation, "reviews_total": reviews_total,
		"reviews_good": reviews_good, "wishes_done": wishes_done, "codex": codex,
		"facilities": facilities, "pool_levels": pool_levels,
		"memory": memory, "forecast": forecast, "mailbox": mailbox,
		"story_log": story_log, "chapter": chapter,
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
	_load_story(data)

## 存档里的数字回读全是浮点，按各自的键还原成 int/bool；
## 物种或汤种已经不存在的那条直接丢弃，免得拿着查不到表的键去选台词。
func _load_story(data: Dictionary) -> void:
	memory.clear()
	var saved_mem: Dictionary = data.get("memory", {})
	for sp: String in saved_mem:
		if not GameData.SPECIES.has(sp):
			continue
		var raw: Dictionary = saved_mem[sp]
		var seen_list: Array = []
		for v: Variant in raw.get("seen", []):
			seen_list.append(String(v))
		memory[sp] = {"visits": int(raw.get("visits", 0)), "seen_intro": bool(raw.get("seen_intro", false)),
				"arc_stage": int(raw.get("arc_stage", 0)), "seen": seen_list}
	forecast.clear()
	for e: Variant in data.get("forecast", []):
		var item: Dictionary = e
		var pool := String(item.get("pool", ""))
		if not GameData.POOLS.has(pool):
			continue
		forecast.append({"pool": pool, "trend": String(item.get("trend", "up")),
				"weight": float(item.get("weight", 1.0)), "until": int(item.get("until", day))})
	mailbox.clear()
	for e: Variant in data.get("mailbox", []):
		var item: Dictionary = e
		var sp := String(item.get("species", ""))
		if not GameData.SPECIES.has(sp):
			continue
		mailbox.append({"id": String(item.get("id", "")), "species": sp,
				"title": String(item.get("title", "一封来信")), "body": String(item.get("body", "")),
				"day": int(item.get("day", day)), "hint": item.get("hint", {}),
				"read": bool(item.get("read", false))})
	story_log.clear()
	for v: Variant in data.get("story_log", []):
		story_log.append(String(v))
	chapter = clampi(int(data.get("chapter", 0)), 0, Story.CHAPTERS.size() - 1)

const BAR_COLOR := Color(0.09, 0.06, 0.13, 0.62)
## 触摸端最小命中高度：896 宽的画面投到手机上，26 高的按钮只剩十来物理像素
const TOUCH_BUTTON_HEIGHT := 36.0

func style_button(button: Button) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.09, 0.06, 0.13, 0.85)
	base.border_color = Color(0.95, 0.8, 0.45, 1.0)
	base.set_border_width_all(2)
	base.set_corner_radius_all(0)
	# 字号抬到 18 后顶栏一度撑爆 896：内边距从 6 收到 4 把宽度还给 HUD
	base.set_content_margin_all(4)
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
	button.add_theme_font_size_override("font_size", 18)
	if button.custom_minimum_size.y < TOUCH_BUTTON_HEIGHT:
		button.custom_minimum_size.y = TOUCH_BUTTON_HEIGHT

## ---------------- 房间解锁 ----------------

## 声望门槛：0 表示开业即用，其余按店铺声望逐间放开
func unlock_rep(room_id: String) -> int:
	return int(ROOMS.get(room_id, {}).get("unlock_rep", 0))

func is_unlocked(room_id: String) -> bool:
	return reputation >= float(unlock_rep(room_id))

func lock_text(room_id: String) -> String:
	var need := unlock_rep(room_id)
	var now := int(floor(reputation))
	return "声望 %d 解锁（当前 %d，还差 %d）" % [need, now, need - now]

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
