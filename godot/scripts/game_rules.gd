class_name GameRules
## 经营规则的纯算式：落点几何、设施经济、心愿可行性的无状态部分。
## 这里不读节点、不弹窗、不碰存档，也不认识「当前房间」——
## 调用方把房间配置与已建清单交进来，规则只回一个 bool 或一个数。
## 拆出这一层的意义：建造与经济可以脱离 UI 单独测（buildcheck 直接调这里）。

const HUD_BOTTOM := 44.0                 # 顶栏高度，设施不得压住
## 两件家具允许互相压进去的最深像素数：像素美术里木桶挨着毛巾筐本就该咬住几格，
## 完全不许重叠会在整块地面上留下用不上的缝。判据只有一处真相——overlap_depth()。
const FACILITY_OVERLAP_TOL := 6.0
## 池沿同理，但只许咬住 2 格：池面是客人要下水的地方，多让一像素就是压进汤里
const POOL_OVERLAP_TOL := 2.0
const PLACEMENT_GRID := 16.0             # 落点网格：家具底部中心对齐到格点才排得齐
const VIEWPORT_SIZE := Vector2i(896, 512)

## ---------------- 设施经济：每一个 eff 键都必须有一条真实下落 ----------------
## 在席收益：产币类给足，开心类给半。原公式是「每件 +5%、封顶 +30%」，
## 于是一只 15 金的茶碗和一只 100 金的石灯笼等价，玩家很快就算出「摆满最便宜的那几件」这一解。
const EFF_INCOME := {"coin": 0.05, "joy": 0.02}
## 放松：把客人留在池里的时间拉长
const EFF_STAY_PER := 0.03
const EFF_STAY_MAX := 0.5
## 效率：产币的节拍缩短
const EFF_TEMPO_PER := 0.04
const EFF_TEMPO_MAX := 0.25
## 声望与招牌：跨天日结时折成店铺声望
const EFF_FAME_KEYS := ["fame", "sign"]
const EFF_FAME_PER := 0.05
const EFF_FAME_MAX := 2.0
## 探索：跨天撞上店内奇闻的几率
const EFF_SURPRISE_PER := 0.02
const EFF_SURPRISE_MAX := 0.20
## 社交：凑够 3 点屋里就热闹，「想聊天」的那位一个人也聊得起来
const EFF_SOCIAL_EASE := 3.0
## 同一件重复摆的收益递减：第一件全额，第二件一半，第三件四分之一……
const FACILITY_DUP_DECAY := 0.5
## 在席收益的总封顶
const FACILITY_INCOME_MAX := 0.30

## 某一维效果有没有落到一条真实通道上：校验脚本拿它证明「账面数值都不是空话」
const EFF_CHANNELS := {
	"coin": "income", "joy": "income", "relax": "stay", "effcy": "tempo",
	"fame": "fame", "sign": "fame", "explore": "surprise", "social": "social",
}

## ---------------- 落点几何 ----------------

static func rect_at(center: Vector2, size: Vector2) -> Rect2:
	return Rect2(center - size * 0.5, size)

## 两块矩形的侵入深度：要把它们分开，最少沿某个轴挪开几像素。
## 不相交返回 0；重叠越深数越大。建造合法性、幽灵预览、拆除命中都读这一个算式。
static func overlap_depth(rect: Rect2, other: Rect2) -> float:
	var ox := minf(rect.end.x, other.end.x) - maxf(rect.position.x, other.position.x)
	var oy := minf(rect.end.y, other.end.y) - maxf(rect.position.y, other.position.y)
	if ox <= 0.0 or oy <= 0.0:
		return 0.0
	return minf(ox, oy)

## 落点吸附：以底部中心对齐格点，一排家具才站得齐
static func snap_center(id: String, center: Vector2) -> Vector2:
	var half := Vector2(GameData.facility_size(id)) * 0.5
	var bx: float = round(center.x / PLACEMENT_GRID) * PLACEMENT_GRID
	var by: float = round((center.y + half.y) / PLACEMENT_GRID) * PLACEMENT_GRID
	return Vector2(bx, by - half.y)

## 落点合法性。placed 是本间已建的 [{id,x,y}]，same_count 是同款件数，
## wall_limit 由调用方按房间配置算好交进来（规则层不认识 ROOMS），
## afford 由调用方按余额判好——心愿扫描要问「天生完不成吗」，那时钱不算门槛。
static func placement_ok(cfg: Dictionary, placed: Array, id: String, center: Vector2,
		afford: bool, same_count: int, wall_limit: float) -> bool:
	var f := GameData.facility(id)
	if f.is_empty() or cfg.is_empty():
		return false
	if not afford:
		return false
	var size := Vector2(GameData.facility_size(id))
	var rect := rect_at(center, size)
	if rect.position.y < HUD_BOTTOM or rect.end.y > float(VIEWPORT_SIZE.y):
		return false
	if rect.position.x < 0.0 or rect.end.x > float(VIEWPORT_SIZE.x):
		return false
	for r: Rect2 in cfg.get("pools", []):
		if overlap_depth(rect, r) > POOL_OVERLAP_TOL:
			return false
	for s: Vector2 in cfg.get("spawns", []):
		if rect.has_point(s):
			return false
	for e: Dictionary in placed:
		var other := Vector2(GameData.facility_size(String(e.id)))
		if overlap_depth(rect, rect_at(Vector2(float(e.x), float(e.y)), other)) > FACILITY_OVERLAP_TOL:
			return false
	if bool(f.get("wall_only", false)):
		# 墙上件不占地面 lot，只认墙带高度与单间数量
		if center.y > wall_limit:
			return false
		return same_count < int(f.get("max_count", 99))
	# 落地件：整只必须待在背景留空的地面块里，否则会压到画死的木桶毛巾
	for l: Rect2 in cfg.get("lots", []):
		if l.encloses(rect):
			return true
	return false

## 只看几何：本房间是否存在一块容得下它的空地（不看已经摆了些什么）。
## 供建造调色板把「这里根本放不下」的选项置灰；此刻还剩不剩空地要问 has_free_spot。
static func room_fits(cfg: Dictionary, id: String, wall_limit: float) -> bool:
	var f := GameData.facility(id)
	if f.is_empty() or cfg.is_empty():
		return false
	var size := Vector2(GameData.facility_size(id))
	if bool(f.get("wall_only", false)):
		# 墙带不只是高度：底边还得落在 16 格上、顶边不压 HUD、下缘不碰池沿——
		# 少算一条，调色板就会把其实挂不上的件点亮着骗人点一次红一次
		for by in range(16, int(VIEWPORT_SIZE.y) + 1, 16):
			var top := float(by) - float(size.y)
			var center_y := top + float(size.y) * 0.5
			if top < HUD_BOTTOM or center_y > wall_limit:
				continue
			var rect := Rect2(64.0, top, float(size.x), float(size.y))
			var hit_pool := false
			for r: Rect2 in cfg.get("pools", []):
				if overlap_depth(rect, r) > POOL_OVERLAP_TOL:
					hit_pool = true
			if not hit_pool:
				return true
		return false
	for l: Rect2 in cfg.get("lots", []):
		if l.size.x >= size.x and l.size.y >= size.y:
			return true
	return false

## 此刻还落不落得下：在已建件之外找一块真正的空地。
## 金币不是门槛——买不买是玩家的选择，天生完不成才是设计事故。
static func has_free_spot(cfg: Dictionary, placed: Array, id: String, wall_limit: float,
		same_count: int) -> bool:
	if not room_fits(cfg, id, wall_limit):
		return false
	var f := GameData.facility(id)
	if bool(f.get("wall_only", false)):
		return same_count < int(f.get("max_count", 99))
	var size := Vector2(GameData.facility_size(id))
	var half := size * 0.5
	var tried := {}
	for l: Rect2 in cfg.get("lots", []):
		if l.size.x < size.x or l.size.y < size.y:
			continue
		var gy := l.position.y + half.y
		while gy <= l.end.y - half.y:
			var gx := l.position.x + half.x
			while gx <= l.end.x - half.x:
				var spot := snap_center(id, Vector2(gx, gy))
				if not tried.has(spot):
					tried[spot] = true
					if placement_ok(cfg, placed, id, spot, true, same_count, wall_limit):
						return true
				gx += PLACEMENT_GRID
			gy += PLACEMENT_GRID
	return false

## ---------------- 设施经济 ----------------

static func eff_of(id: String) -> Dictionary:
	return GameData.facility(id).get("eff", {})

## 一件设施的在席收益价值：只有 coin / joy 这两维真的换成钱
static func income_value(id: String) -> float:
	var eff := eff_of(id)
	var v := 0.0
	for k: String in EFF_INCOME:
		v += float(eff.get(k, 0)) * float(EFF_INCOME[k])
	return v

## 一列设施 id 的在席收益强度：同款逐次减半，总量封顶
static func income_power_of(ids: Array) -> float:
	var total := 0.0
	var seen := {}
	for v: Variant in ids:
		var id := String(v)
		var n := int(seen.get(id, 0))
		seen[id] = n + 1
		total += income_value(id) * pow(FACILITY_DUP_DECAY, float(n))
	return minf(FACILITY_INCOME_MAX, total)

## 某一维（或几维）效果在一列设施里的合计，重复件同样按档减半
static func eff_total_of(ids: Array, keys: Array) -> float:
	var total := 0.0
	var seen := {}
	for v: Variant in ids:
		var id := String(v)
		var n := int(seen.get(id, 0))
		seen[id] = n + 1
		var factor := pow(FACILITY_DUP_DECAY, float(n))
		var eff := eff_of(id)
		for k: String in keys:
			total += float(eff.get(k, 0)) * factor
	return total

## 放松把客人留在池里的时间拉长
static func stay_power(ids: Array) -> float:
	return 1.0 + minf(EFF_STAY_MAX, eff_total_of(ids, ["relax"]) * EFF_STAY_PER)

## 效率把产币的节拍缩短（倍率小于 1）
static func tempo_power(ids: Array) -> float:
	return 1.0 - minf(EFF_TEMPO_MAX, eff_total_of(ids, ["effcy"]) * EFF_TEMPO_PER)

## 声望与招牌折成的日结进账（封顶 2 点，别让摆件把星级刷满）
static func fame_gain(ids: Array) -> float:
	return minf(EFF_FAME_MAX, eff_total_of(ids, EFF_FAME_KEYS) * EFF_FAME_PER)

## 探索把跨天撞上店内奇闻的几率抬起来（返回增量）
static func surprise_bonus(ids: Array) -> float:
	return minf(EFF_SURPRISE_MAX, eff_total_of(ids, ["explore"]) * EFF_SURPRISE_PER)

static func social_power(ids: Array) -> float:
	return eff_total_of(ids, ["social"])

## 闲聊心愿需要同池的「另外几位」：屋里够热闹就放宽到一位
static func chat_peers_needed(social: float) -> int:
	return 2 if social < EFF_SOCIAL_EASE else 1

## 把一件设施的效果翻成人话，只报真起作用的通道。
## 面板上从此不再有「社交 2」这种看着能算、其实不作用于任何东西的数字。
static func effect_text(id: String) -> String:
	var eff := eff_of(id)
	var parts: Array[String] = []
	var income := 0.0
	for k: String in EFF_INCOME:
		income += float(eff.get(k, 0)) * float(EFF_INCOME[k])
	if income > 0.0:
		parts.append("在席收益 +%.0f%%" % (income * 100.0))
	if float(eff.get("relax", 0)) > 0.0:
		parts.append("停留 +%.0f%%" % (float(eff.get("relax", 0)) * EFF_STAY_PER * 100.0))
	if float(eff.get("effcy", 0)) > 0.0:
		parts.append("产币节拍 -%.0f%%" % (float(eff.get("effcy", 0)) * EFF_TEMPO_PER * 100.0))
	var fame := float(eff.get("fame", 0)) + float(eff.get("sign", 0))
	if fame > 0.0:
		parts.append("日结声望 +%.2f" % (fame * EFF_FAME_PER))
	if float(eff.get("explore", 0)) > 0.0:
		parts.append("店内奇闻 +%.0f%%" % (float(eff.get("explore", 0)) * EFF_SURPRISE_PER * 100.0))
	if float(eff.get("social", 0)) > 0.0:
		parts.append("热闹 +%d（凑够 %d 点则闲聊更易）" % [int(eff.get("social", 0)), int(EFF_SOCIAL_EASE)])
	if parts.is_empty():
		return "纯摆设：不产收益，只好看"
	return " · ".join(parts) + " · 同款第二件起效果减半"
