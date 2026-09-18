extends SceneTree
## 设施经营规则的 headless 单元测试：落点校验、限量与墙带、金币门槛、
## 产币单日上限、设施收益加成、心愿设施门槛、存档往返。
## 运行：Godot_console.exe --headless --path godot --script res://scripts/buildcheck.gd
## 注意：--script 模式下自动加载单例不是全局标识符，一律 root.get_node 取。

const ROOM := "indoor"
## 大池温泉：唯一 coin_gen 且额度受限的池子，用来验证扩建后的额度提升
const ROOM2 := "ooike"
const SAVE := "user://save.json"
const LANTERN_MAX := 8

var gm: Node
var failures := 0
var done := false
var frame := 0
var report_seen := {}

func _process(_delta: float) -> bool:
	frame += 1
	if done or frame < 2:
		return false
	done = true
	gm = root.get_node_or_null("GameManager")
	if gm == null:
		done = false
		return false
	_run()
	print("BUILDCHECK ", "PASSED" if failures == 0 else "FAILED (%d)" % failures)
	quit(0 if failures == 0 else 1)
	return true

func _truthy(label: String, cond: bool) -> void:
	if cond:
		print("  ok   - ", label)
	else:
		failures += 1
		print("  FAIL - ", label)

func _falsy(label: String, cond: bool) -> void:
	_truthy(label, not cond)

func _run() -> void:
	_reset()
	# 1. 池面上不放设施，池外平台可以
	var deck := _deck_spot()
	_falsy("池面不能放零食摊", gm.can_place(ROOM, "vender", _pool_center()))
	_truthy("平台可以放零食摊", gm.can_place(ROOM, "vender", deck))

	# 2. 购买扣币并入库；同一位置不可重复
	var cost := int(GameData.facility("vender").cost)
	var before: int = gm.coins
	_truthy("购买成功", gm.buy_facility(ROOM, "vender", deck))
	_truthy("扣款等于造价", before - gm.coins == cost)
	_truthy("房间登记 1 件", gm.room_facilities(ROOM).size() == 1)
	_falsy("重叠位置被拒绝", gm.can_place(ROOM, "vender", deck))

	# 3. 灯笼只能上墙，且限量
	var hang := Vector2(200.0, gm.wall_limit_y(ROOM) - 24.0)
	_falsy("灯笼不能放在平台", gm.can_place(ROOM, "lantern", deck))
	_truthy("灯笼可以挂在墙带", gm.can_place(ROOM, "lantern", hang))
	for i in LANTERN_MAX:
		gm.buy_facility(ROOM, "lantern", Vector2(hang.x + float(i) * 36.0, hang.y))
	_truthy("灯笼上限 %d 盏" % LANTERN_MAX, gm.facility_count(ROOM, "lantern") == LANTERN_MAX)
	_falsy("再多一盏被拒绝", gm.can_place(ROOM, "lantern", Vector2(hang.x + 320.0, hang.y)))

	# 4. 金币不足
	gm.coins = 0
	_falsy("没钱不能建", gm.can_place(ROOM, "bench", _deck_spot(120.0)))

	# 5. 产币汤种单日上限；不产币的汤种不设限
	_reset()
	var cap := int(GameData.pool("hot").daily_cap)
	var granted := 0
	for _i in 40:
		granted += gm.take_pool_budget("hot", 20)
	_truthy("温泉池今日封顶 %d" % cap, granted == cap)
	_truthy("封顶后不再放行", gm.take_pool_budget("hot", 20) == 0)
	_truthy("不产币的汤种不设限", gm.take_pool_budget("herb", 20) == 20)

	# 6. 设施收益加成，且封顶 1.3
	_reset()
	_truthy("空房间无加成", gm.facility_bonus(ROOM) == 1.0)
	for i in 20:
		gm.buy_facility(ROOM, "plant", Vector2(30.0 + float(i % 10) * 80.0, 420.0 + float(int(i / 10)) * 40.0))
	_truthy("加成封顶 1.3", absf(gm.facility_bonus(ROOM) - 1.3) < 0.001)

	# 7. 心愿门槛：零食心愿要零食摊
	_reset()
	_truthy("零食心愿声明需要零食摊", GameData.wish_needs("snack").has("vender"))
	_falsy("尚未建设零食摊", gm.has_facility(ROOM, "vender"))
	gm.buy_facility(ROOM, "vender", deck)
	_truthy("建设后心愿可满足", gm.has_facility(ROOM, "vender"))

	# 8. 池位扩建：等级、造价、容量、额度、收益同步提升
	_reset()
	gm.pool_levels.clear()
	_truthy("初始等级 1", gm.pool_level(ROOM2, 0) == 1)
	_truthy("GameManager 造价与算式一致", gm.upgrade_cost(ROOM2, 0) == GameData.upgrade_cost("hot", 1))
	_truthy("位多的大池更贵 180", GameData.upgrade_cost("hot", 1) == 180)
	_truthy("2→3 级按倍率涨到 288", GameData.upgrade_cost("hot", 2) == 288)
	_truthy("1 级 4 位", GameData.level_cap("hot", 1, 8) == 4)
	_truthy("3 级 6 位", GameData.level_cap("hot", 3, 8) == 6)
	_truthy("容量不越过池宽", GameData.level_cap("hot", 3, 2) == 2)
	_truthy("1 级额度 240", GameData.level_budget("hot", 1) == 240)
	_truthy("3 级额度 480", GameData.level_budget("hot", 3) == 480)
	_truthy("不产币汤种无额度", GameData.level_budget("herb", 3) == 0)
	_truthy("3 级收益 ×1.36", absf(GameData.level_income(3) - 1.36) < 0.001)
	gm.coins = 100
	_falsy("钱不够不能升级", gm.can_upgrade(ROOM2, 0))
	gm.coins = 5000
	var cost1: int = gm.upgrade_cost(ROOM2, 0)
	var coins1: int = gm.coins
	_truthy("升级成功", gm.do_upgrade(ROOM2, 0))
	_truthy("扣款等于造价", coins1 - gm.coins == cost1)
	_truthy("等级升到 2", gm.pool_level(ROOM2, 0) == 2)
	_falsy("越界序号被拒绝", gm.do_upgrade(ROOM2, 9))
	var total2 := 0
	for _i in 40:
		total2 += gm.take_pool_budget("hot", 20, ROOM2, 0)
	_truthy("2 级额度放到 360", total2 == 360)
	_truthy("额度查询取最高等级", gm.budget_for_type("hot") == 360)
	gm.do_upgrade(ROOM2, 0)
	_truthy("满级 3", gm.pool_level(ROOM2, 0) == 3)
	_falsy("满级后不能再升", gm.can_upgrade(ROOM2, 0))

	# 9. 当日账本与跨天结算快照
	_reset()
	gm._reset_day_ledger()
	var rep_before: float = gm.reputation
	gm.take_pool_budget("hot", 30, ROOM2, 0)
	_truthy("账本累计收入", int(gm.today.income) == 30)
	_truthy("账本分汤种记账", int(gm.today.by_type.hot) == 30)
	gm.add_review(5, true, true)
	_truthy("接待计数", int(gm.today.guests) == 1)
	_truthy("星级入总", int(gm.today.stars) == 5)
	_truthy("心愿计数", int(gm.today.wishes) == 1)
	gm.day_reported.connect(_on_report)
	gm.hour = 23.6
	var day_before: int = gm.day
	gm._process(10.0)
	_truthy("跨天触发结算", not report_seen.is_empty())
	_truthy("结算快照属于昨天", int(report_seen.day) == day_before)
	_truthy("快照收入 30", int(report_seen.income) == 30)
	_truthy("快照平均星级 5", absf(float(report_seen.stars_avg) - 5.0) < 0.001)
	_truthy("快照声望 +6", absf(float(report_seen.rep_delta) - (gm.reputation - rep_before)) < 0.001)
	_truthy("新一天账本清零", int(gm.today.income) == 0)
	_truthy("新一天额度重置", gm.pool_income_today.is_empty())
	_truthy("天数推进", gm.day == day_before + 1)
	gm.day_reported.disconnect(_on_report)

	# 10. 房间声望门槛：零声望只开两间，满声望全开，锁着的进不去
	gm.reputation = 0.0
	_truthy("零声望开放 2 间", gm.unlocked_count() == 2)
	_falsy("露天风吕尚未解锁", gm.is_unlocked("rotenburo"))
	_truthy("锁定文案写明门槛", gm.lock_text("chashitsu").find("70") >= 0)
	gm.current_room = "ooike"
	gm.goto_room("chashitsu")
	_truthy("锁定房间拒绝进入", String(gm.current_room) == "ooike")
	gm.reputation = 100.0
	_truthy("满声望全开 %d 间" % gm.room_count(), gm.unlocked_count() == gm.room_count())
	gm.reputation = 20.0

	# 11. 存档往返
	_reset()
	gm.buy_facility(ROOM, "vender", deck)
	gm.save_game()
	gm.facilities.clear()
	gm.pool_levels.clear()
	gm.load_game()
	_truthy("存档恢复设施", gm.has_facility(ROOM, "vender"))
	_truthy("存档恢复池位等级", gm.pool_level(ROOM2, 0) == 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

func _on_report(report: Dictionary) -> void:
	report_seen = report

func _reset() -> void:
	gm.coins = 5000
	gm.facilities.clear()
	gm.pool_income_today.clear()

func _pool_center() -> Vector2:
	var rect: Rect2 = gm.room_cfg(ROOM).pools[0]
	return rect.get_center()

## 池下方的平台空位（避开出生点）
func _deck_spot(x: float = 260.0) -> Vector2:
	var rect: Rect2 = gm.room_cfg(ROOM).pools[0]
	return Vector2(x, rect.end.y + 42.0)
