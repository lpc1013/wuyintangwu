extends Node
## 全局配置表与场景导航。房间布局数据驱动：新增房间只需在 ROOMS 加一条。

## 画布尺寸的唯一真相在 GameRules（落点边界要用它），这里只转发给 UI 用
const VIEWPORT_SIZE := GameRules.VIEWPORT_SIZE
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
## ---------------- 经营算式住在 GameRules，这里只留同名转发 ----------------
## 拆法： GameManager 管「状态」（哪间屋、有哪些件、剩多少钱），
## GameRules 管「算式」（这个落点合不合法、这一列设施值多少收益）。
## 下面这批同名常量与函数是给老调用方（room_view / guest / 三道闸）留的门，
## 判据却只有一份——改 GameRules 一处就全变，不会再出现两份手抄互相打脸。
const HUD_BOTTOM := GameRules.HUD_BOTTOM
const FACILITY_OVERLAP_TOL := GameRules.FACILITY_OVERLAP_TOL
const POOL_OVERLAP_TOL := GameRules.POOL_OVERLAP_TOL
const PLACEMENT_GRID := GameRules.PLACEMENT_GRID
const EFF_INCOME := GameRules.EFF_INCOME
const EFF_STAY_PER := GameRules.EFF_STAY_PER
const EFF_TEMPO_PER := GameRules.EFF_TEMPO_PER
const EFF_TEMPO_MAX := GameRules.EFF_TEMPO_MAX
const EFF_FAME_KEYS := GameRules.EFF_FAME_KEYS
const EFF_FAME_PER := GameRules.EFF_FAME_PER
const EFF_FAME_MAX := GameRules.EFF_FAME_MAX
const EFF_SURPRISE_PER := GameRules.EFF_SURPRISE_PER
const EFF_SURPRISE_MAX := GameRules.EFF_SURPRISE_MAX
const EFF_SOCIAL_EASE := GameRules.EFF_SOCIAL_EASE
const FACILITY_DUP_DECAY := GameRules.FACILITY_DUP_DECAY
const FACILITY_INCOME_MAX := GameRules.FACILITY_INCOME_MAX
const EFF_CHANNELS := GameRules.EFF_CHANNELS

## 抽一个本房间此刻招待得起的心愿：除了几何上放不放得下，还要看玩家已经摆了多少件、
## 以及「想聊天」这种需要同池真有第三位的条件——否则这一位天生拿不到满星，玩家也无从补救。
func pick_wish(room_id: String) -> String:
	var ids: Array[String] = []
	for id: String in GameData.WISHES:
		if wish_feasible(room_id, id):
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

## 心愿在这一间屋此刻还落不落得下
func wish_feasible(room_id: String, wish_id: String) -> bool:
	for need: String in GameData.wish_needs(wish_id):
		var id := String(need)
		# 已经摆好的那件不必再找空地：有了就是有了
		if has_facility(room_id, id):
			continue
		if not room_has_free_spot(room_id, id):
			return false
	match wish_id:
		"chat":
			# 同池要凑得出「另外两位」（合计三位）；热闹的房间（社交≥3）放宽到另外一位
			return max_pool_seats(room_id) >= chat_peers_needed(room_id) + 1
	return true

## 经营时钟只在玩家真的在店里的时候走。标题画面与案内图都不算「正在经营」，
## 否则游戏开着不点开始，店里的日期也会自己跨过去。
var sim_running := false

func start_sim() -> void:
	sim_running = true

func stop_sim() -> void:
	sim_running = false

func _ready() -> void:
	load_game()
	_reset_day_ledger()

func _process(delta: float) -> void:
	if not sim_running:
		return
	hour += delta * 24.0 / GameData.DAY_SECONDS
	if hour >= 24.0:
		hour -= 24.0
		# 声望与招牌在日结折进账：那一维效果本来就该换成店铺星级，而不只是面板上一行字
		_grant_daily_fame()
		_close_day()
		day += 1
		pool_income_today.clear()
		_reset_day_ledger()
		_roll_story_day()

## 把摆件的声望效果记进今天的账本并落到店铺上，返回实际到账数
func _grant_daily_fame() -> float:
	var gain := daily_fame()
	if gain <= 0.0:
		return 0.0
	var before := reputation
	reputation = clampf(reputation + gain, 0.0, MAX_REPUTATION)
	var got := reputation - before
	today["fame"] = float(today.get("fame", 0.0)) + got
	return got

func _reset_day_ledger() -> void:
	today = {"income": 0, "guests": 0, "wishes": 0, "good": 0, "bad": 0, "stars": 0,
			"fame": 0.0, "by_type": {}}
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

## 离店结算的唯一出口：星级带来的声望、心愿的金币与声望、当日账本，全部从这里进。
## 以前「心愿达成后在席收益 ×1.25」是第二个入口，可 wish_done 要到起身才判定，
## 那一段永远走不到——奖励只在这一处发，玩家看到的和账上记的才是同一件事。
func settle_guest(stars: int, wish_id: String, wish_done: bool) -> Dictionary:
	var coin := 0
	var fame := 0.0
	if wish_done:
		var w: Dictionary = GameData.WISHES.get(wish_id, {})
		coin = int(w.get("coin", 0))
		fame = float(w.get("fame", 0))
		if coin > 0:
			coins += coin
			_ledger_add("income", coin)
			# 收入里另记一格「wish」：日报的今日收入含这笔，账要按来源拆得开
			var by_type: Dictionary = today.get("by_type", {})
			by_type["wish"] = int(by_type.get("wish", 0)) + coin
			today["by_type"] = by_type
	var rep := add_review(stars, stars >= 4, wish_done)
	if fame > 0.0:
		var before := reputation
		reputation = clampf(reputation + fame, 0.0, MAX_REPUTATION)
		rep += reputation - before
		# 心愿的声望可能把店铺星级顶上一档，章节门槛得再对一次表
		advance_chapter()
	return {"rep_delta": rep, "wish_coin": coin, "wish_fame": fame}

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

## 两块矩形的侵入深度：转发给 GameRules，判据只有那一份。
static func overlap_depth(rect: Rect2, other: Rect2) -> float:
	return GameRules.overlap_depth(rect, other)

## 落点合法性：本间状态（金币、已建清单、墙带）交给纯算式去判。
func can_place(room_id: String, id: String, center: Vector2, need_coin := true) -> bool:
	var f := GameData.facility(id)
	if f.is_empty():
		return false
	return GameRules.placement_ok(room_cfg(room_id), room_facilities(room_id), id, center,
			not need_coin or coins >= int(f.cost),
			facility_count(room_id, id), wall_limit_y(room_id))

## 落点吸附：以底部中心对齐格点，一排家具才站得齐
static func snap_center(id: String, center: Vector2) -> Vector2:
	return GameRules.snap_center(id, center)

## 只看几何：本房间是否存在一块容得下它的空地。忽略金币与已建设施的挤压，
## 供建造调色板把「这里根本放不下」的选项直接置灰，而不是让玩家反复点击试错。
func room_fits(room_id: String, id: String) -> bool:
	return GameRules.room_fits(room_cfg(room_id), id, wall_limit_y(room_id))

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

## 已建设施给本房间在席收益的加成倍率：按每件的 eff 折算，同一件重复摆逐次减半。
## 原来是「件数 ×5%」，于是六只最便宜的茶碗就能顶满 +30%，
## 玩家学到的是「堆便宜货」而不是「按汤屋主题与客人需求布置」。
func facility_bonus(room_id: String) -> float:
	return 1.0 + facility_income_power(room_id)

func facility_income_power(room_id: String) -> float:
	return income_power_of(room_ids_of(room_id))

## 一列设施 id 的在席收益强度：纯算式，校验脚本可以直接喂任意拼法，不必先把它摆进哪间屋
static func income_power_of(ids: Array) -> float:
	return GameRules.income_power_of(ids)

## 一件设施的在席收益价值：只有 coin / joy 这两维真的换成钱
static func income_value(id: String) -> float:
	return GameRules.income_value(id)

func room_ids_of(room_id: String) -> Array:
	var ids: Array = []
	for e: Dictionary in room_facilities(room_id):
		ids.append(String(e.id))
	return ids

## 某一维（或几维）效果在一列设施里的合计，重复件同样按档减半
static func eff_total_of(ids: Array, keys: Array) -> float:
	return GameRules.eff_total_of(ids, keys)

## 放松把客人留在池里的时间拉长（最多半倍）
func stay_power(room_id: String) -> float:
	return GameRules.stay_power(room_ids_of(room_id))

## 效率把产币的节拍缩短（倍率小于 1，封顶 -25%）
func tempo_power(room_id: String) -> float:
	return GameRules.tempo_power(room_ids_of(room_id))

## 社交合计：够 3 点就热闹到「一个人也聊得起来」
func social_power(room_id: String) -> float:
	return GameRules.social_power(room_ids_of(room_id))

## 把一件设施的效果翻成人话，只报真起作用的通道。
static func facility_effect_text(id: String) -> String:
	return GameRules.effect_text(id)

func chat_peers_needed(room_id: String) -> int:
	return GameRules.chat_peers_needed(social_power(room_id))

## 声望与招牌折成的日结进账（封顶 2 点，别让摆件把星级刷满）
func daily_fame() -> float:
	return GameRules.fame_gain(shop_eff_total_ids())

## 探索把跨天撞上店内奇闻的几率抬起来
func surprise_chance() -> float:
	return SURPRISE_CHANCE + GameRules.surprise_bonus(shop_eff_total_ids())

## 全店已建件 id 的清单：日结声望与奇闻概率看的是整间汤屋，不只眼下这一间
func shop_eff_total_ids() -> Array:
	var ids: Array = []
	for room_id: String in ROOMS:
		ids.append_array(room_ids_of(room_id))
	return ids

## 这条池子最多坐几位：汤种基础位、池宽、背景画死的坐垫三闸取最小。
## 与 room_view 的容量用的是同一套算式，心愿判定才不会被另一份手抄骗到。
func max_pool_seats(room_id: String) -> int:
	var cfg: Dictionary = ROOMS.get(room_id, {})
	var pool_list: Array = cfg.get("pools", [])
	var types: Array = cfg.get("pool_types", [])
	var all_seats: Array = cfg.get("seats", [])
	var best := 0
	for i in pool_list.size():
		var type_id := String(types[i]) if i < types.size() else "hot"
		var rect: Rect2 = pool_list[i]
		var seats: Array = all_seats[i] if i < all_seats.size() else []
		var n := GameData.seat_cap(type_id, pool_level(room_id, i),
				GameData.width_slots(rect.size.x), seats.size())
		best = maxi(best, n)
	return best

## 心愿所需的那件此刻还落不落得下：几何之外要躲开玩家已经摆好的那些件。
## 金币不是门槛——买不买是玩家的选择，天生完不成才是设计事故。
func room_has_free_spot(room_id: String, id: String) -> bool:
	return GameRules.has_free_spot(room_cfg(room_id), room_facilities(room_id), id,
			wall_limit_y(room_id), facility_count(room_id, id))

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
## 事件与道具台词的已播表：{key_id: [entry_id]}。这些键不是物种，不能塞进 memory——
## 存档按名册过滤，塞进去等于下次读取就丢，玩家会看着同一桩奇闻从头重演
var seen_lines := {}
## 风向情报：[{pool, trend, weight, until}]，读信或闲聊时写入，两天后过期
var forecast: Array = []
## 信箱：离店时攒下的信，次日才送达；读过才把 hint 折进风向
var mailbox: Array = []
## 已读文案的收藏册：id 全局唯一，读到一条记一条，分母是 total_lines()（生成表 + 主线）
var story_log: Array = []
## 拆过几封信：主线支线按它解锁「回信之后」的那一段
var letters_read := 0
## 当前章节下标（0 起）；达成 CHAPTERS 门槛后前进，末章封顶
var chapter := 0
## 跨天掷出的惊喜事件台词，等下一间房里的玩家来读；{key: 事件键, entry: 条目}
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

## 台词判定上下文：条目 when 里出现的字段一律从这里取。
## room_id 给 builtMin 用（这段词要玩家真在这间屋里摆过东西才开口）
## 只读名册、不开格：店内奇闻与道具的键不是物种，替它们在往来记忆里占一格，
## 那一格会被存档校验按名册过滤掉，里面的重播记录就蒸发在两次会话之间（连跑 120 天才露头）。
func story_ctx(sp: String, aff: int, room_id := "") -> Dictionary:
	var m: Dictionary = memory.get(sp, {})
	return {"visits": int(m.get("visits", 0)), "arc_stage": int(m.get("arc_stage", 0)),
			"match": match_quality(aff), "period": String(period().id),
			"first": not bool(m.get("seen_intro", false)),
			"built": room_facilities(room_id).size() if room_id != "" else 0,
			"letters_read": letters_read}

## when 里认得的条件下标：条件键一律要在这儿，拼错的键以前会静默放行，
## 等于那段词的门槛凭空消失了还没人知道。校验脚本读的就是这张表。
const KNOWN_WHEN_KEYS := ["visitsMin", "visitsMax", "arcStage", "match", "period", "first",
	"builtMin", "lettersRead"]

## when 匹配：认得的键逐条比对。开发构建遇到未知键当场报错，
## 发行版只留一条警告——文案拼错不该把玩家的对白整段吞掉。
static func when_ok(when: Dictionary, ctx: Dictionary) -> bool:
	for key: String in when:
		if not KNOWN_WHEN_KEYS.has(key):
			if OS.is_debug_build():
				push_error("未知的剧情条件键: " + key)
			else:
				push_warning("未知的剧情条件键: " + key)
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
	if when.has("builtMin") and int(ctx.built) < int(when.builtMin):
		return false
	if when.has("lettersRead") and int(ctx.letters_read) < int(when.lettersRead):
		return false
	return true

## 选一条此刻条件成立、且这一位还没播过的台词；全播过就允许重播（宁可重播也别让店里没了声音）。
## 这一步不改任何状态：选中不等于播过，更不等于读过——账要等真给玩家看了才落。
func pick_line(channel_id: String, sp: String, ctx: Dictionary) -> Dictionary:
	var allowed: Array = []
	for e: Dictionary in Story.entries(channel_id, sp):
		var when: Dictionary = e.get("when", {})
		if not when.is_empty() and not when_ok(when, ctx):
			continue
		allowed.append(e)
	if allowed.is_empty():
		return {}
	var seen := _seen_store(sp)
	var fresh: Array = []
	for e: Dictionary in allowed:
		if not seen.has(String(e.id)):
			fresh.append(e)
	# 抽光了也不清 seen：播过的记录是玩家的收藏，不该因为没新词就作废
	var pool: Array = fresh if not fresh.is_empty() else allowed
	var total := 0.0
	var weights: Array = []
	for e: Dictionary in pool:
		var w := 1.0 if String(e.get("rarity", "common")) == "common" else RARE_WEIGHT
		weights.append(w)
		total += w
	var roll := randf() * total
	var chosen: Dictionary = pool[pool.size() - 1]
	for i in pool.size():
		roll -= float(weights[i])
		if roll <= 0.0:
			chosen = pool[i]
			break
	return chosen

## 主线那一拍：按顺序取「还没讲的第一拍」，讲到哪儿全看那条 seen 表。
## 与闲聊池最大的分别是顺序不许乱：下一拍被 when 拦住时整条链就地停住，
## 绝不跳过它去讲后面那一拍——跳过就等于把故事的因果拆没了。
func arc_next(sp: String, ctx: Dictionary) -> Dictionary:
	for e: Dictionary in StoryArc.entries(sp):
		if _seen_store(sp).has(String(e.id)):
			continue
		var when: Dictionary = e.get("when", {})
		if not when.is_empty() and not when_ok(when, ctx):
			return {}
		return e
	return {}

## 讲到第几拍了：给对白卡上那行「心事 2/5」用，玩家得知道自己还差几趟
func arc_progress(sp: String) -> Dictionary:
	var beats: Array = StoryArc.entries(sp)
	var done := 0
	for e: Dictionary in beats:
		if _seen_store(sp).has(String(e.id)):
			done += 1
	return {"done": done, "total": beats.size()}

## 文案总数：生成表之外还有主线这一层，收藏率的分母要一起算
func total_lines() -> int:
	return Story.line_count() + StoryArc.line_count()

## 已播表落在哪：物种用它自己的往来记忆；店内奇闻、道具、道具闲聊的键不是物种，
## 走另一张表，存档两侧才不会被名册过滤掉
func _seen_store(key_id: String) -> Array:
	if GameData.SPECIES.has(key_id):
		return _memory(key_id).seen as Array
	if not seen_lines.has(key_id):
		seen_lines[key_id] = []
	return seen_lines[key_id]

## 台词真的贴到玩家眼前了才调用：seen 防重播，story_log 进收藏册。
## 展示失败（对白卡堆满、气泡被占）不许调用，那条词下次还在。
func commit_line(key_id: String, entry: Dictionary) -> void:
	commit_seen(key_id, entry)
	commit_read(entry)

func commit_seen(key_id: String, entry: Dictionary) -> void:
	var id := String(entry.get("id", ""))
	if id == "":
		return
	var seen := _seen_store(key_id)
	if not seen.has(id):
		seen.append(id)

func commit_read(entry: Dictionary) -> void:
	_log_story(String(entry.get("id", "")))

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
## 信先入账本，次日才算送达。信箱满员时先腾掉最早拆过的那一封；
## 十二封全没拆就干脆不收——玩家攒着的信不该被系统按顺序吃掉。
func post_letter(sp: String, ctx: Dictionary) -> Dictionary:
	if randf() >= LETTER_CHANCE:
		return {}
	if mailbox.size() >= MAILBOX_CAP and not _make_mail_room():
		return {}
	var e := pick_line("letter", sp, ctx)
	if e.is_empty():
		return {}
	mailbox.append({"id": String(e.id), "species": sp, "title": String(e.get("title", "一封来信")),
			"body": String(e.get("body", "")), "day": day + 1, "hint": e.get("hint", {}), "read": false})
	save_game()
	# 信已经写进信箱，这条 letter 台词就算用掉了；读没读要等 read_mail 才记进收藏册
	commit_seen(sp, e)
	return e

## 腾出一个信箱位：只动已读的最旧一封，全未读时返回 false
func _make_mail_room() -> bool:
	for i in mailbox.size():
		if bool(mailbox[i].read):
			mailbox.remove_at(i)
			return true
	return false

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
	letters_read += 1
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
	if not pending_surprise.is_empty() or randf() >= surprise_chance():
		return
	var ids: Array = Story.event_ids()
	ids.shuffle()
	for id: String in ids:
		# 逐个试：pick_line 会替我们把播光的事件跳过，比先算剩余条数省事
		var e := pick_line("surprise", id, story_ctx(id, 0))
		if not e.is_empty():
			pending_surprise = {"key": id, "entry": e}
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

## 存档来源："" 表示这次是从新档开局，"backup" 表示主档坏了退到备份。
## 界面与校验脚本都读它，别让「进度丢了」这件事只留在一条没人看的 push_warning 里。
var save_source := ""

func snapshot() -> Dictionary:
	return {
		"schema_version": SaveData.SCHEMA,
		"coins": coins, "day": day, "hour": hour,
		"reputation": reputation, "reviews_total": reviews_total,
		"reviews_good": reviews_good, "wishes_done": wishes_done, "codex": codex,
		"facilities": facilities, "pool_levels": pool_levels,
		"memory": memory, "seen_lines": seen_lines,
		"forecast": forecast, "mailbox": mailbox,
		"story_log": story_log, "letters_read": letters_read, "chapter": chapter,
	}

## 存档层要的上下文：房间名册与各项封顶。校验侧不认识场景，也不认识 UI。
func save_ctx() -> Dictionary:
	return {
		"rooms": ROOMS.keys(),
		"max_pool_level": max_pool_level(),
		"max_reputation": MAX_REPUTATION,
		"mailbox_cap": MAILBOX_CAP,
		"max_chapter": Story.CHAPTERS.size() - 1,
	}

func save_game() -> bool:
	return SaveData.write(SAVE_PATH, snapshot())

func load_game() -> void:
	save_source = ""
	var result := SaveData.read(SAVE_PATH, save_ctx())
	save_source = String(result.source)
	if not bool(result.ok):
		return
	_apply_saved(result.data)

func _apply_saved(data: Dictionary) -> void:
	coins = int(data.coins)
	day = int(data.day)
	hour = float(data.hour)
	reputation = float(data.reputation)
	reviews_total = int(data.reviews_total)
	reviews_good = int(data.reviews_good)
	wishes_done = int(data.wishes_done)
	codex.clear()
	for s: Variant in data.codex:
		codex.append(String(s))
	facilities.clear()
	var saved_fac: Dictionary = data.facilities
	for room_id: String in saved_fac:
		facilities[room_id] = saved_fac[room_id]
	pool_levels.clear()
	var saved_levels: Dictionary = data.pool_levels
	for room_id: String in saved_levels:
		pool_levels[room_id] = saved_levels[room_id]
		_ensure_levels(room_id)
	memory.clear()
	var saved_mem: Dictionary = data.memory
	for sp: String in saved_mem:
		memory[sp] = saved_mem[sp]
	seen_lines.clear()
	var saved_seen: Dictionary = data.seen_lines
	for key_id: String in saved_seen:
		seen_lines[key_id] = saved_seen[key_id]
	forecast.clear()
	for e: Variant in data.forecast:
		forecast.append(e)
	mailbox.clear()
	for e: Variant in data.mailbox:
		mailbox.append(e)
	story_log.clear()
	for v: Variant in data.story_log:
		story_log.append(String(v))
	letters_read = int(data.letters_read)
	chapter = int(data.chapter)

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
