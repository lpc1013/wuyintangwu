extends SceneTree
## 设施经营规则的 headless 单元测试：落点校验、限量与墙带、金币门槛、
## 产币单日上限、设施收益加成、心愿设施门槛、存档往返。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/buildcheck.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，而购买与升级会 save_game，
## 让它落到默认目录等于每跑一次就抹掉一次玩家进度。
## 注意：--script 模式下自动加载单例不是全局标识符，一律 root.get_node 取。

const ROOM := "indoor"
## 大池温泉：唯一 coin_gen 且额度受限的池子，用来验证扩建后的额度提升
const ROOM2 := "ooike"
const SAVE := "user://save.json"
const LANTERN_MAX := 8
## 按角色索引的频道：这些的顶层键必须是 GameData.SPECIES 里的物种
const ACTOR_CHANNELS := ["intro", "chat", "letter", "grumble", "farewell", "murmur"]
## 按事件/道具索引的频道：顶层键走另一套词汇，单独查
const EVENT_CHANNELS := ["surprise", "prop"]
## when_ok 认得的条件下标；网页版哪天加了新条件，这条会先叫出来
const KNOWN_WHEN := ["visitsMin", "visitsMax", "arcStage", "match", "period", "first"]

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
	# 1. 池面上不放设施；背景留白的地面块里可以
	var deck := _lot_spot(ROOM, "vender")
	_falsy("池面不能放零食摊", gm.can_place(ROOM, "vender", _pool_center()))
	_truthy("平台可以放零食摊", gm.can_place(ROOM, "vender", deck))
	_truthy("落点吸附到 16 格底部中心", gm.snap_center("vender", Vector2(43.0, 371.0)) == Vector2(48.0, 368.0))
	_falsy("地面块之外不能放", gm.can_place(ROOM, "vender", Vector2(400.0, 460.0)))
	for room: String in gm.ROOMS.keys():
		_truthy("%s 至少容得下一件设施" % room, _any_fits(room))
		# 地面块画小了就是死格子，配置里不该存在
		var lots: Array = gm.room_cfg(room).lots
		for li in lots.size():
			var l: Rect2 = lots[li]
			var held := false
			for id: String in GameData.FACILITY_IDS:
				if bool(GameData.facility(id).get("wall_only", false)):
					continue
				var s := Vector2(GameData.facility_size(id))
				if l.size.x >= s.x and l.size.y >= s.y:
					held = true
					break
			_truthy("%s 地面块 %d 容得下设施" % [room, li], held)

	# 1b. 摆件点评表按设施 id 索引：每件都得有词，id 不许撞车也不许冒出目录外的
	var pc_table: Dictionary = Story.channel("propchat")
	var pc_ids := {}
	for id: String in GameData.FACILITY_IDS:
		_truthy("propchat 有「%s」" % id, (pc_table.get(id, []) as Array).size() >= 2)
	for tid: String in pc_table:
		_truthy("propchat 键「%s」在设施目录里" % tid, GameData.FACILITY_IDS.has(tid))
		for e: Dictionary in pc_table[tid]:
			var eid := String(e.id)
			_truthy("propchat id 不重复「%s」" % eid, not pc_ids.has(eid))
			pc_ids[eid] = true

	# 2. 购买扣币并入库；同一位置不可重复
	var cost := int(GameData.facility("vender").cost)
	var before: int = gm.coins
	_truthy("购买成功", gm.buy_facility(ROOM, "vender", deck))
	_truthy("扣款等于造价", before - gm.coins == cost)
	_truthy("房间登记 1 件", gm.room_facilities(ROOM).size() == 1)
	_falsy("重叠位置被拒绝", gm.can_place(ROOM, "vender", deck))

	# 2b. 拆除退一半，腾出的落点立刻可以重建
	var coins_mid: int = gm.coins
	_truthy("点中家具可拆除", gm.sell_facility(ROOM, deck) == cost / 2)
	_truthy("退款进账", gm.coins == coins_mid + cost / 2)
	_truthy("拆完空位可重建", gm.can_place(ROOM, "vender", deck))
	_truthy("点空处不退款", gm.sell_facility(ROOM, Vector2(400.0, 120.0)) == 0)

	# 2c. 拆除容差：手指点不准小件，边界外几个像素也得拆得中（偏移按件高一半+3 给）
	gm.buy_facility(ROOM, "vender", deck)
	var grazing := deck + Vector2(0, float(GameData.facility_size("vender").y) * 0.5 + 3.0)
	_truthy("零容差时边界外点不中", gm.sell_facility(ROOM, grazing) == 0)
	_truthy("容差 8 时边界外点得中", gm.sell_facility(ROOM, grazing, 8.0) > 0)

	# 3. 灯笼只能上墙，且限量（墙带取到池沿上方为止；间距按新贴图宽 +8）
	var hang := Vector2(200.0, gm.wall_limit_y(ROOM) - 54.0)
	var step := float(GameData.facility_size("lantern").x) + 8.0
	_falsy("灯笼不能放在平台", gm.can_place(ROOM, "lantern", deck))
	_truthy("灯笼可以挂在墙带", gm.can_place(ROOM, "lantern", hang))
	for i in LANTERN_MAX:
		gm.buy_facility(ROOM, "lantern", Vector2(hang.x + float(i) * step, hang.y))
	_truthy("灯笼上限 %d 盏" % LANTERN_MAX, gm.facility_count(ROOM, "lantern") == LANTERN_MAX)
	_falsy("再多一盏被拒绝", gm.can_place(ROOM, "lantern", Vector2(hang.x + 8.0 * step, hang.y)))

	# 4. 金币不足
	gm.coins = 0
	_falsy("没钱不能建", gm.can_place(ROOM, "bench", _lot_spot(ROOM, "bench")))

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
	# 盆栽换成了 64×88 的抠图，室内 96 见方的地只塞得下一盆；
	# 封顶测试挪去石泉——那里有 300×110 与 250×110 两条长苔带，网格塞得满
	var planted := _fill("ishiyu", "plant", 20)
	_truthy("石泉苔地塞下 %d 盆" % planted, planted >= 6)
	_truthy("加成封顶 1.3", absf(gm.facility_bonus("ishiyu") - 1.3) < 0.001)

	# 7. 心愿门槛：零食心愿要零食摊
	_reset()
	_truthy("零食心愿声明需要零食摊", GameData.wish_needs("snack").has("vender"))
	_falsy("尚未建设零食摊", gm.has_facility(ROOM, "vender"))
	gm.buy_facility(ROOM, "vender", deck)
	_truthy("建设后心愿可满足", gm.has_facility(ROOM, "vender"))

	# 7b. 茶室 kind 化：不下水的房间里，客人坐得住、心愿也许得起
	_reset()
	_truthy("茶室标记为落座", gm.room_kind("chashitsu") == "lounge" and gm.is_lounge("chashitsu"))
	_falsy("浴场仍是泡汤", gm.is_lounge(ROOM))
	_truthy("榻榻米有回头客", GameData.affinity("capy", "tatami") == 1)
	var seat_only := true
	for _i in 60:
		if not GameData.WISH_SEATED.has(gm.pick_wish("chashitsu")):
			seat_only = false
	_truthy("茶室只许安坐类心愿", seat_only)
	var always_affordable := true
	for room: String in gm.ROOMS.keys():
		for _i in 60:
			var w := String(gm.pick_wish(room))
			for need: String in GameData.wish_needs(w):
				if not gm.room_fits(room, String(need)):
					always_affordable = false
	_truthy("心愿不会许给招待不起的房间", always_affordable)
	var rest := PixelArt.make_animal("shib", PixelArt.YUKATA[0], "rest")
	var walk := PixelArt.make_animal("shib", PixelArt.YUKATA[0], "walk")
	_truthy("落座图与行走图同画布，锚点不漂", rest.get_size() == walk.get_size())
	_truthy("坐垫落在地面线上", rest.get_pixel(16, 39).a > 0.5)
	_truthy("头顶留空不压别的客人", rest.get_pixel(16, 0).a < 0.5)
	# 步态三帧：行走靠 walk / stepL / stepR 轮换，画布与地面线必须完全一致，
	# 否则每换一帧脚就跳一下，看着像在抖而不是在走
	var step_l := PixelArt.make_animal("shib", PixelArt.YUKATA[0], "stepL")
	var step_r := PixelArt.make_animal("shib", PixelArt.YUKATA[0], "stepR")
	_truthy("迈步两帧与站立同画布", step_l.get_size() == walk.get_size()
			and step_r.get_size() == walk.get_size())
	_truthy("站立时两脚都踩在地面线上", walk.get_pixel(12, 39).a > 0.5 and walk.get_pixel(19, 39).a > 0.5)
	_truthy("抬左脚那只真离了地、右脚仍踩实", step_l.get_pixel(12, 39).a < 0.5
			and step_l.get_pixel(19, 39).a > 0.5)
	_truthy("抬右脚时离地的换到另一边", step_r.get_pixel(19, 39).a < 0.5
			and step_r.get_pixel(12, 39).a > 0.5)
	_truthy("两脚之间留缝，不糊成一整块", walk.get_pixel(15, 39).a < 0.5
			and walk.get_pixel(16, 39).a < 0.5)
	_truthy("抬腿那侧的爪子荡到后面、对侧甩到前面", step_l.get_pixel(8, 31).a < 0.5
			and step_l.get_pixel(23, 32).a > 0.5 and walk.get_pixel(8, 31).a > 0.5
			and walk.get_pixel(23, 32).a < 0.5)
	# 步态分档：档位不只是表上的数字，得真的落到画布格子上
	var gait_covered := true
	for id: String in GameData.species_ids():
		var g: Dictionary = GameData.gait_of(id)
		if g.is_empty() or not g.has("step") or not g.has("frames"):
			gait_covered = false
	_truthy("每个物种都落到一个存在的步态档", gait_covered)
	var gait_mapped := true
	for id: String in GameData.GAIT_OF.keys():
		if not GameData.SPECIES.has(id) or not GameData.GAITS.has(String(GameData.GAIT_OF[id])):
			gait_mapped = false
	_truthy("步态登记表没有拼错的物种或档名", gait_mapped)
	var gait_poses := true
	for gid: String in GameData.GAITS.keys():
		for pose: String in (GameData.GAITS[gid].get("frames", []) as Array):
			if not ["walk", "stepL", "stepR", "hop"].has(pose):
				gait_poses = false
	_truthy("档位用到的姿态名都画得出来", gait_poses)
	# 抬脚格数：沉的一档脚底板几乎擦地，默认档离地两格
	_truthy("熊只抬一格、柴犬抬两格",
			_clearance("bear", 1) == 1 and _clearance("shib", 1) == 2
			and _clearance("shib", 2) == 2)
	# 摆臂：沉重档爪子跟着身子不动（两帧同点同色），默认档一迈步爪子就换前后
	_truthy("沉重档前爪不荡、默认档荡",
			_solid(_walk_frame("bear", 1), 23, 32) == _solid(_walk_frame("bear", 0), 23, 32)
			and _solid(_walk_frame("bear", 1), 8, 31) == _solid(_walk_frame("bear", 0), 8, 31)
			and _solid(step_l, 23, 32) != _solid(walk, 23, 32)
			and _solid(step_l, 8, 31) != _solid(walk, 8, 31))
	_truthy("只有蹼禽那一档左右摆", int(GameData.gait_of("duck").get("sway", -1)) == 1
			and int(GameData.gait_of("bear").get("sway", -1)) == 0
			and int(GameData.gait_of("cat3").get("sway", -1)) == 0)
	# 跳步档位两脚一起离地，落地帧又一起踩实
	_truthy("腾空帧两脚一起离地", _clearance("rabb", 3) == 2
			and _foot_row(_walk_frame("rabb", 3), 12) < _foot_row(_walk_frame("rabb", 0), 12)
			and _foot_row(_walk_frame("rabb", 3), 19) < _foot_row(_walk_frame("rabb", 0), 19))
	_truthy("脚尖点地的那档落地不沉", int(GameData.gait_of("cat3").get("dip", -1)) == 0
			and int(GameData.gait_of("shib").get("dip", -1)) == 1)
	_truthy("碎步档步幅最短、移速最快", float(GameData.gait_of("mouse").get("step", 9.0)) < 0.6
			and float(GameData.gait_of("mouse").get("speed", 0.0)) > 1.2)
	_truthy("沉重档步子长、走得慢", float(GameData.gait_of("bear").get("step", 0.0)) > 1.2
			and float(GameData.gait_of("bear").get("speed", 9.0)) < 0.9)
	var rest_lines_ok := not GameData.REVIEW_LINES_LOUNGE.is_empty()
	for line: String in GameData.REVIEW_LINES_LOUNGE:
		if line.find("泡") >= 0:
			rest_lines_ok = false
	_truthy("茶室点评不提泡汤", rest_lines_ok)

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

	# 12. 触摸端适配：手机窗口比 896×512 还窄，缩放必须允许小数
	var sm := String(ProjectSettings.get_setting("display/window/stretch/scale_mode"))
	_truthy("缩放模式允许小数（当前 %s）" % sm, sm == "fractional")
	_truthy("逻辑画布仍是 896×512", Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height")) == gm.VIEWPORT_SIZE)
	_truthy("按钮够手指点", float(gm.TOUCH_BUTTON_HEIGHT) >= 36.0)
	_truthy("提示浏览器锁横屏", int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 4)
	# headless 窗口只有 64×64，比任何手机都狠：缩放后的画布右下角仍落在窗口里，才说明没裁边角。
	# 这条变换只在 CanvasItem 上暴露，Window 没有，所以临时挂一个 Control 进树去读。
	var probe := Control.new()
	root.add_child(probe)
	var xform: Transform2D = probe.get_viewport_transform()
	probe.queue_free()
	var canvas: Vector2 = gm.VIEWPORT_SIZE
	var corner: Vector2 = xform * canvas
	_truthy("小窗里画布不被裁（%s 落在 %s）" % [corner, root.size],
			corner.x <= root.size.x + 1.0 and corner.y <= root.size.y + 1.0)

	# 13. 叙事文案闭环：机械搬运的表缺一个键，运行期只会静默少一句台词，没人报错
	_reset_story()
	var total_lines := 0
	var dup_ids := 0
	var unknown_actors := 0
	var unknown_pools := 0
	var null_hints := 0
	var unknown_when := 0
	var orphan_props := 0
	var seen_ids := {}
	for ch: String in ACTOR_CHANNELS + EVENT_CHANNELS:
		var table := Story.channel(ch)
		_truthy("频道 %s 有内容" % ch, not table.is_empty())
		for key_id: String in table:
			if ACTOR_CHANNELS.has(ch) and not GameData.SPECIES.has(key_id):
				unknown_actors += 1
			if ch == "prop" and not gm.PROP_BY_FACILITY.values().has(key_id):
				orphan_props += 1
			for e: Dictionary in table[key_id]:
				total_lines += 1
				var line_id := String(e.get("id", ""))
				if line_id == "" or seen_ids.has(line_id):
					dup_ids += 1
				seen_ids[line_id] = true
				var hint: Variant = e.get("hint", {})
				if hint == null:
					null_hints += 1
				elif not (hint as Dictionary).is_empty() \
						and not GameData.POOLS.has(String((hint as Dictionary).get("pool", ""))):
					unknown_pools += 1
				for w: String in (e.get("when", {}) as Dictionary):
					if not KNOWN_WHEN.has(w):
						unknown_when += 1
	_truthy("台词共 %d 条，与网页版 STORY_DB 对齐" % total_lines, total_lines == 576)
	_truthy("每条 id 全局唯一（坏 %d 条）" % dup_ids, dup_ids == 0)
	_truthy("角色频道只点本作有的物种（坏 %d 个）" % unknown_actors, unknown_actors == 0)
	# 反方向：漏一个频道不会报错，只会让那只客人从此站着不开口。
	# 扩员时最容易漏的就是这个——新物种进了名册，台词只填了一半频道。
	var mute := 0
	for ch: String in ACTOR_CHANNELS:
		var table := Story.channel(ch)
		for id: String in GameData.SPECIES:
			if not table.has(id):
				mute += 1
	_truthy("名册 %d 只在 %d 个角色频道都有台词（缺 %d 处）" % [
			GameData.SPECIES.size(), ACTOR_CHANNELS.size(), mute], mute == 0)
	_truthy("hint.pool 全是本作汤种（坏 %d 条）" % unknown_pools, unknown_pools == 0)
	_truthy("没有 null 的 hint，否则 apply_hint 形参当场炸", null_hints == 0)
	_truthy("when 只用运行时认得的键（坏 %d 种）" % unknown_when, unknown_when == 0)
	_truthy("道具台词都挂得到本作的某件设施（坏 %d 个）" % orphan_props, orphan_props == 0)
	_truthy("名册 %d 只每只都有档案（档案 %d 份）" % [GameData.SPECIES.size(), Story.PROFILES.size()],
			Story.PROFILES.size() == GameData.SPECIES.size())
	_truthy("档案昵称非空", String(Story.profile("foxe").nickname) != "")
	var mono_guests := 0
	var mono_star := 0
	var steps_ok := true
	for c: Dictionary in Story.CHAPTERS:
		steps_ok = steps_ok and int(c.guests) > mono_guests and int(c.star) >= mono_star \
				and int(c.star) <= 5 and String(c.name) != ""
		mono_guests = int(c.guests)
		mono_star = int(c.star)
	_truthy("主线 %d 章门槛单调且有名" % Story.CHAPTERS.size(), steps_ok)

	# 14. 取词与风向
	_reset_story()
	var ctx: Dictionary = gm.story_ctx("foxe", 0)
	var pickable := 0
	for e: Dictionary in Story.entries("chat", "foxe"):
		var when: Dictionary = e.get("when", {})
		if when.is_empty() or gm.when_ok(when, ctx):
			pickable += 1
	var picked := {}
	for i in pickable:
		var line: Dictionary = gm.pick_line("chat", "foxe", ctx)
		picked[String(line.get("id", ""))] = true
	_truthy("狐狸闲聊有词可抽（%d/%d 条达标）" % [picked.size(), pickable], picked.size() == pickable)
	_truthy("同一条不重播", picked.size() == pickable)
	_truthy("抽光这一次返回空", gm.pick_line("chat", "foxe", ctx).is_empty())
	_truthy("抽光后自动重置，不会永久哑掉", not gm.pick_line("chat", "foxe", ctx).is_empty())
	_truthy("已读文案进收藏册", gm.story_log.size() >= 2)
	_truthy("契合度换算成网页版三档", gm.match_quality(1) == "perfect"
			and gm.match_quality(0) == "basic" and gm.match_quality(-1) == "wrong")
	_truthy("主线阶段按来访数分档", gm.arc_stage(2) == 0 and gm.arc_stage(3) == 1 and gm.arc_stage(6) == 2)
	_truthy("visitsMin 不达标就闭嘴", not gm.when_ok({"visitsMin": 3}, gm.story_ctx("foxe", 0)))
	_truthy("认不出的 when 键放行", gm.when_ok({"alienRule": 9}, ctx))

	# 15. 风向：置信度折权重、同池覆盖、上下限、条数封顶、过期清理
	_reset_story()
	gm.apply_hint({"pool": "nope", "weight": 2.0})
	_truthy("不认识的汤种不写风向", gm.forecast.is_empty())
	gm.apply_hint({"pool": "herb", "trend": "up", "weight": 2.0}, 0.5)
	_truthy("置信度把 2.0 折成 1.5（当前 %.2f）" % gm.spawn_weight("herb"),
			absf(gm.spawn_weight("herb") - 1.5) < 0.001)
	gm.apply_hint({"pool": "herb", "trend": "up", "weight": 99.0})
	_truthy("同池只留最新一条", gm.forecast.size() == 1)
	_truthy("倍率封顶 2.0", absf(gm.spawn_weight("herb") - 2.0) < 0.001)
	for p: String in ["hot", "ice", "milk", "yuzu", "sand", "cyber", "moon", "moss", "stone", "sake"]:
		gm.apply_hint({"pool": p, "trend": "down", "weight": 0.2})
	_truthy("风向条数封顶 %d" % gm.FORECAST_CAP, gm.forecast.size() == gm.FORECAST_CAP)
	_truthy("倍率有下限，风向不会把汤抽干", gm.spawn_weight("stone") >= 0.6)
	_truthy("风向文案列出了池名", gm.forecast_text().find("池") >= 0 or gm.forecast_text().find("汤") >= 0)
	var day0: int = gm.day
	gm.day = day0 + gm.FORECAST_TTL + 1
	gm._roll_story_day()
	_truthy("过期风向被清掉", gm.forecast.is_empty() and gm.spawn_weight("herb") == 1.0)
	gm.day = day0

	# 16. 信箱：次日送达、读过才改风向、重复读无效
	_reset_story()
	gm.day = 5
	gm.mailbox.append({"id": "mail-t", "species": "foxe", "title": "测试信", "body": "正文在此",
			"day": 6, "hint": {"pool": "yuzu", "trend": "up", "weight": 1.4}, "read": false})
	_truthy("未到期的信读不了", gm.read_mail(0).is_empty())
	_truthy("未读的信不改风向", gm.spawn_weight("yuzu") == 1.0)
	gm.day = 6
	_truthy("到期即进待读列表", gm.due_mail() == [0])
	_truthy("读信拿到正文", String(gm.read_mail(0).get("body", "")) == "正文在此")
	_truthy("读过才把风向落进账本", gm.spawn_weight("yuzu") > 1.0)
	_truthy("重复读不再返回", gm.read_mail(0).is_empty())
	_truthy("已读的信不再待读", gm.due_mail().is_empty())
	_truthy("读过的信进收藏册", gm.story_log.has("mail-t"))
	_truthy("越界下标不炸", gm.read_mail(9).is_empty())
	gm.mailbox.clear()
	var left := 0
	for i in 24:
		if not gm.post_letter("foxe", gm.story_ctx("foxe", 1)).is_empty():
			left += 1
	_truthy("离店留信约五成（%d/24）" % left, left > 0 and left < 24)
	_truthy("信箱有封顶（当前 %d）" % gm.mailbox.size(), gm.mailbox.size() <= gm.MAILBOX_CAP)
	var next_day := true
	for m: Dictionary in gm.mailbox:
		next_day = next_day and int(m.day) == gm.day + 1
	_truthy("留下的信一律次日到", next_day)

	# 17. 道具故事与惊喜事件
	_reset_story()
	var prop: Dictionary = gm.prop_line("plant")
	_truthy("点盆栽能读到故事", String(prop.get("text", "")) != "")
	_truthy("没有道具文本的水桶安静返回空", gm.prop_line("bucket").is_empty())
	var gazes := 0
	for i in 6:
		if not (gm.prop_line("camera").get("hint", {}) as Dictionary).is_empty():
			gazes += 1
	_truthy("望远镜的故事里能漏出风向", gm.spawn_weight("ice") > 1.0 or gazes > 0)
	_reset_story()
	for i in 30:
		gm._roll_surprise()
		if not gm.pending_surprise.is_empty():
			break
	_truthy("跨天掷得出店内奇闻", not gm.pending_surprise.is_empty())
	var held: Dictionary = gm.pending_surprise
	gm._roll_surprise()
	_truthy("没读走的奇闻不会被覆盖", gm.pending_surprise == held)
	gm.pending_surprise = {}

	# 18. 主线推进：只用本作已有的经营事实，且绝不倒退
	_reset_story()
	gm.reviews_total = 0
	gm.advance_chapter()
	_truthy("零接待停在第一章", gm.chapter == 0)
	gm.reviews_total = int(Story.CHAPTERS[0].guests) - 1
	gm.advance_chapter()
	_truthy("差一位仍不推进", gm.chapter == 0)
	gm.reviews_total = int(Story.CHAPTERS[0].guests)
	gm.advance_chapter()
	_truthy("达成门槛即推进一章", gm.chapter == 1)
	gm.reviews_total = 99999
	gm.reputation = 100.0
	gm.advance_chapter()
	_truthy("满经营数据冲到末章", gm.chapter == Story.CHAPTERS.size() - 1)
	gm.reviews_total = 0
	gm.reputation = 0.0
	gm.advance_chapter()
	_truthy("章节不会倒退", gm.chapter == Story.CHAPTERS.size() - 1)
	_truthy("章节目标可读", gm.chapter_goal().find("累计接待") == 0)

	# 11. 存档往返
	_reset()
	gm.buy_facility(ROOM, "vender", deck)
	gm.note_visit("foxe")
	gm.note_visit("foxe")
	gm.mark_intro_seen("foxe")
	gm.apply_hint({"pool": "herb", "trend": "up", "weight": 1.3})
	gm.mailbox.append({"id": "mail-save", "species": "foxe", "title": "存一封", "body": "正文",
			"day": gm.day + 1, "hint": {}, "read": false})
	gm.story_log.append("chat-foxe-1")
	gm.chapter = 4
	gm.save_game()
	gm.facilities.clear()
	gm.pool_levels.clear()
	_reset_story()
	gm.load_game()
	_truthy("存档恢复设施", gm.has_facility(ROOM, "vender"))
	_truthy("存档恢复池位等级", gm.pool_level(ROOM2, 0) == 3)
	_truthy("存档恢复来访记忆", int(gm.memory["foxe"].visits) == 2)
	_truthy("存档恢复自我介绍标记", bool(gm.memory["foxe"].seen_intro))
	_truthy("存档恢复风向", gm.spawn_weight("herb") > 1.0)
	_truthy("存档恢复信箱", gm.mailbox.size() == 1 and String(gm.mailbox[0].id) == "mail-save")
	_truthy("存档恢复收藏册", gm.story_log.has("chat-foxe-1"))
	_truthy("存档恢复章节", gm.chapter == 4)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	_check_night()
	_check_steam()
	_check_review()

## 夜间氛围：夜罩曲线必须连续（整点跳档很出戏），灯点必须落在画面里，
## 光晕贴图要中心实心、边缘全透并且只生成一次。
func _check_night() -> void:
	var prev := 0.0
	var biggest := 0.0
	for i in 24 * 20:
		gm.hour = float(i) / 20.0
		var cur: float = gm.night_light()
		if i > 0:
			biggest = maxf(biggest, absf(cur - prev))
		prev = cur
	_truthy("夜罩连续过渡，步长 3 分钟内最大变化 %0.3f" % biggest, biggest < 0.01)
	gm.hour = 9.0
	_truthy("上午平台期完全不压夜罩", gm.night_light() == 0.0)
	gm.hour = 11.0
	_truthy("正午前天色仍清", gm.night_light() < 0.03)
	gm.hour = 23.0
	var darkest: float = gm.night_light()
	_truthy("入夜最重的一档压得住夜罩", darkest > 0.55)
	gm.hour = 17.0
	_truthy("黄昏轻于深夜", gm.night_light() < darkest)
	gm.hour = 9.0
	var rooms: Dictionary = gm.ROOMS
	var vp: Vector2 = Vector2(gm.VIEWPORT_SIZE)
	for room_id: String in rooms:
		var lights: Array = gm.room_cfg(room_id).get("lights", [])
		_truthy("%s 备有入夜灯点" % room_id, not lights.is_empty())
		for pos: Vector2 in lights:
			_truthy("%s 灯点 %s 在画面内" % [room_id, pos],
					Rect2(Vector2.ZERO, vp).has_point(pos))
	var glow := PixelArt.glow_texture()
	var gi := glow.get_image()
	var mid := glow.get_width() / 2
	_truthy("光晕中心不透明", gi.get_pixel(mid, mid).a > 0.9)
	_truthy("光晕四角全透", gi.get_pixel(0, 0).a == 0.0 and gi.get_pixel(gi.get_width() - 1, gi.get_height() - 1).a == 0.0)
	_truthy("光晕贴图复用同一份", glow == PixelArt.glow_texture())

## 热气浓淡全在表的 steam 档上：漏填会被当成 0，那口池子就从此不冒汽，
## 所以逐条盯着；贴图本身只验形状（主团实心、四角全透、只烘一次）。
func _check_steam() -> void:
	var pools: Dictionary = GameData.POOLS
	for type_id: String in pools:
		var p: Dictionary = pools[type_id]
		_truthy("%s 登记了热气浓淡" % type_id, p.has("steam"))
		var s: float = float(p.get("steam", -1.0))
		_truthy("%s 浓淡在 0..1（%0.2f）" % [type_id, s], s >= 0.0 and s <= 1.0)
	for cold_id: String in ["ice", "sand", "tatami"]:
		_truthy("%s 不冒热气" % cold_id, GameData.pool_steam(cold_id) == 0.0)
	_truthy("温泉池浓过任何别的汤", GameData.pool_steam("hot") >= 0.9)
	_truthy("牛奶浴比温泉淡", GameData.pool_steam("milk") < GameData.pool_steam("hot"))
	_truthy("没登记的汤种按不冒汽处理", GameData.pool_steam("nope") == 0.0)
	var rooms: Dictionary = gm.ROOMS
	for room_id: String in rooms:
		var types: Array = rooms[room_id].get("pool_types", [])
		var steaming := 0
		for i in types.size():
			if GameData.pool_steam(String(types[i])) > 0.0:
				steaming += 1
		if String(rooms[room_id].get("kind", "onsen")) == "lounge":
			_truthy("%s 一座热气的池子都没有" % room_id, steaming == 0)
		else:
			_truthy("%s 至少一口池冒热气" % room_id, steaming > 0)
	var tex := PixelArt.steam_texture()
	var im := tex.get_image()
	# 主团在 (0.37, 0.63)：那一点必须实心，不然飘起来是根半透的雾柱
	var core := im.get_pixel(int(0.37 * PixelArt.STEAM_SIZE), int(0.63 * PixelArt.STEAM_SIZE))
	_truthy("热气团心不透明", core.a > 0.6 and core.r > 0.99)
	_truthy("热气团四角全透", im.get_pixel(0, 0).a == 0.0
			and im.get_pixel(im.get_width() - 1, im.get_height() - 1).a == 0.0)
	_truthy("热气贴图复用同一份", tex == PixelArt.steam_texture())

## 点评条的账与字：现场反馈读的是 add_review 返回的**实际**增量，
## 所以封顶、见底这两种"算式对但到账不对"的情形必须当场露出来；
## 字数再算不宽也只按方块字估，宁可把余量算少。
func _check_review() -> void:
	gm.reputation = 0.0
	_truthy("五星当场进 6 点声望", absf(float(gm.add_review(5, true, true)) - 6.0) < 0.001)
	_truthy("两星不好不坏，增量正好 0", absf(float(gm.add_review(2, false, false))) < 0.001)
	gm.reputation = 1.0
	_truthy("一星只扣得动见底那 1 点", absf(float(gm.add_review(1, false, false)) + 1.0) < 0.001)
	_truthy("声望不会扣成负数", float(gm.reputation) == 0.0)
	gm.reputation = float(gm.MAX_REPUTATION)
	_truthy("封顶后再好的点评也只进 0", absf(float(gm.add_review(5, true, true))) < 0.001)
	gm.reputation = 0.0
	# 最坏拼法：最长的点评句 + 最长的心愿名 + 五星 + 三位数声望
	var longest := ""
	for line: String in GameData.REVIEW_LINES:
		if line.length() > longest.length():
			longest = line
	for line: String in GameData.REVIEW_LINES_LOUNGE:
		if line.length() > longest.length():
			longest = line
	var widest := ""
	for w: String in GameData.WISHES.keys():
		var label := String(GameData.WISHES[w].label)
		if label.length() > widest.length():
			widest = label
	var stamp := "阿橘 ★★★★★「%s」 ✓%s 声望 +100" % [longest, widest]
	# 14 号字里一个汉字/星号约占 14px，空格与「」只会更窄，照方块字估是偏严的下限
	_truthy("最坏拼法仍放得进点评条（%d 字 ≈ %dpx / 872）" % [stamp.length(), stamp.length() * 18],
			stamp.length() * 18 <= 872)

func _on_report(report: Dictionary) -> void:
	report_seen = report

func _reset() -> void:
	gm.coins = 5000
	gm.facilities.clear()
	gm.pool_income_today.clear()

## 叙事状态整批清场：每段断言都从「谁都没来过、没读过一句」起步
func _reset_story() -> void:
	gm.memory.clear()
	gm.forecast.clear()
	gm.mailbox.clear()
	gm.story_log.clear()
	gm.chapter = 0
	gm.pending_surprise = {}

func _pool_center() -> Vector2:
	var rect: Rect2 = gm.room_cfg(ROOM).pools[0]
	return rect.get_center()

## 地面块中心即合法落点：坐标跟着背景重画走，断言不必逐个改
func _lot_spot(room: String, id: String, li: int = 0) -> Vector2:
	var lots: Array = gm.room_cfg(room).lots
	var rect: Rect2 = lots[li]
	var p: Vector2 = gm.snap_center(id, rect.get_center())
	return p

func _any_fits(room: String) -> bool:
	for id: String in GameData.FACILITY_IDS:
		if gm.room_fits(room, id):
			return true
	return false

## 把设施按网格往地面块里塞，返回实际塞进去的件数
func _fill(room: String, id: String, want: int) -> int:
	var size := Vector2(GameData.facility_size(id))
	var placed := 0
	var lots: Array = gm.room_cfg(room).lots
	for i in lots.size():
		var l: Rect2 = lots[i]
		for r in int(l.size.y / size.y):
			for c in int(l.size.x / size.x):
				if placed >= want:
					return placed
				var center := Vector2(l.position.x + (c + 0.5) * size.x,
						l.position.y + (r + 1.0) * size.y - size.y * 0.5)
				if gm.buy_facility(room, id, center):
					placed += 1
	return placed

## 未缩放的行走帧：直连 PixelArt._walk 取 32×40 原始画布。
## 体型缩放会把行号整体挪掉，逐格比抬脚高度只能在原始画布上做。
func _walk_frame(id: String, lift: int) -> Image:
	var sp: Dictionary = GameData.species(id)
	var t := PixelArt.tones(PixelArt.hex(String(sp.get("body", "#808080"))),
			PixelArt.hex(String(sp.get("belly", "#ffffff"))),
			PixelArt.hex(String(sp.get("dark", "#303030"))))
	return PixelArt._walk(sp, t, PixelArt.YUKATA[0], lift, id)

## 某像素是否画了东西：比对两帧的同一格用
func _solid(im: Image, x: int, y: int) -> bool:
	return im.get_pixel(x, y).a > 0.5

## 某列最靠下的不透明像素：脚掌踩到第几格，看的就是这一行
func _foot_row(im: Image, x: int) -> int:
	for y in range(im.get_height() - 1, -1, -1):
		if im.get_pixel(x, y).a > 0.5:
			return y
	return -1

## 抬脚格数：同一条腿在站立帧的脚底行，减它在迈步帧的脚底行
func _clearance(id: String, lift: int) -> int:
	var x := 12 if lift == 1 or lift == 3 else 19
	return _foot_row(_walk_frame(id, 0), x) - _foot_row(_walk_frame(id, lift), x)
