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
## when_ok 认得的条件下标不在这里抄第二份：唯一的真相是 GameManager.KNOWN_WHEN_KEYS，
## 运行期从单例上取。哪天加了新条件键，只改那一处就够了。
var known_when: Array = []

var gm: Node
var failures := 0
## 跑过的断言条数：某一段中途被脚本错误炸掉时，收尾那条数不对或干脆不打印，
## 绿灯就骗不了人——全段的 ok 行看起来和跑完整段一模一样。
var asserts := 0
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
	# 跨天结算那一段要手动推 _process，先把经营时钟开到「玩家正在店里」
	gm.start_sim()
	known_when = gm.get("KNOWN_WHEN_KEYS")
	_run()
	print("BUILDCHECK ", "PASSED" if failures == 0 else "FAILED (%d)" % failures,
			" 断言 %d 条" % asserts)
	quit(0 if failures == 0 else 1)
	return true

func _truthy(label: String, cond: bool) -> void:
	asserts += 1
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

	# 6. 设施收益：认的是每件的效果，不是件数（纯放松的摆件不再等价于产币件）
	_reset()
	_truthy("空房间无加成", gm.facility_bonus(ROOM) == 1.0)
	var planted := _fill("ishiyu", "plant", 20)
	_truthy("石泉苔地塞下 %d 盆" % planted, planted >= 6)
	_truthy("放松类堆满也不加在席收益", absf(gm.facility_bonus("ishiyu") - 1.0) < 0.001)
	_truthy("放松类堆满确实把客人留得更久", gm.stay_power("ishiyu") > 1.04)

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
	# 茶室客人不下水：任何一档、任何原因拼出来的点评都不许提「泡」
	var rest_lines_clean := true
	for stars in range(1, 6):
		for _i in 12:
			if GameData.review_text(stars, true, stars >= 4, 1, 0).find("泡") >= 0:
				rest_lines_clean = false
	_truthy("茶室点评不提泡汤", rest_lines_clean)

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
	# 光看常量数值是空断言（谁都能把 36 改成 40 蒙过去）：真要验的是「点一颗按钮，皮肤会不会把它抬到能点」
	var touch_btn := Button.new()
	UiTheme.style_button(touch_btn)
	_truthy("按钮经主题处理后够手指点（%.0f）" % touch_btn.custom_minimum_size.y,
			touch_btn.custom_minimum_size.y >= UiTheme.TOUCH_BUTTON_HEIGHT
			and UiTheme.TOUCH_BUTTON_HEIGHT >= 36.0)
	touch_btn.free()
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
					if not known_when.has(w):
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
	# N-01：选中只是选中。抽十次也不许动账——没贴到玩家眼前的一句都不算读过
	for i in 10:
		gm.pick_line("chat", "foxe", ctx)
	_truthy("只抽词不落账：已播表为空", (gm.memory["foxe"].seen as Array).is_empty())
	_truthy("只抽词不落账：收藏册为空", gm.story_log.is_empty())
	# 抽一句、播一句、提交一句，才谈得上「同一条不重播」
	var picked := {}
	for i in pickable:
		var line: Dictionary = gm.pick_line("chat", "foxe", ctx)
		gm.commit_line("foxe", line)
		picked[String(line.get("id", ""))] = true
	_truthy("狐狸闲聊有词可抽（%d/%d 条达标）" % [picked.size(), pickable], picked.size() == pickable)
	_truthy("逐句提交后同一条不重播", picked.size() == pickable)
	_truthy("提交了几句就收藏几句", int(gm.story_log.size()) == pickable)
	var replay := String(gm.pick_line("chat", "foxe", ctx).get("id", ""))
	_truthy("播光之后仍能开口（重播而不是哑掉）", replay != "")
	_truthy("重播不新增收藏", int(gm.story_log.size()) == pickable)
	gm.commit_line("foxe", {"id": replay})
	_truthy("同一条重复提交不翻倍", int(gm.story_log.count(replay)) == 1)
	gm.commit_line("foxe", {})
	_truthy("空条目不落账", int(gm.story_log.size()) == pickable)
	_truthy("契合度换算成网页版三档", gm.match_quality(1) == "perfect"
			and gm.match_quality(0) == "basic" and gm.match_quality(-1) == "wrong")
	_truthy("主线阶段按来访数分档", gm.arc_stage(2) == 0 and gm.arc_stage(3) == 1 and gm.arc_stage(6) == 2)
	_truthy("visitsMin 不达标就闭嘴", not gm.when_ok({"visitsMin": 3}, gm.story_ctx("foxe", 0)))
	_truthy("认不出的 when 键警告后仍放行", gm.when_ok({"alienRule": 9}, ctx))
	# 新增的两个条件键：读的是玩家的经营动作，不是运气
	_reset()
	gm.facilities.clear()
	_truthy("builtMin：空房间不达标", not gm.when_ok({"builtMin": 1}, gm.story_ctx("foxe", 0, ROOM)))
	gm.buy_facility(ROOM, "vender", deck)
	_truthy("builtMin：摆一件就达标", gm.when_ok({"builtMin": 1}, gm.story_ctx("foxe", 0, ROOM)))
	_truthy("lettersRead：一封没拆不达标", not gm.when_ok({"lettersRead": 1}, gm.story_ctx("foxe", 0)))
	gm.letters_read = 3
	_truthy("lettersRead：拆到三封才达标", gm.when_ok({"lettersRead": 3}, gm.story_ctx("foxe", 0)))
	gm.letters_read = 0

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
		# 玩家每次空点都是一句「演成了」的台词：抽一句就得提交一句，
		# 不然这条断言测的是运气而不是「逐条播完」
		var gaze: Dictionary = gm.prop_line("camera")
		gm.commit_line("gaze", gaze)
		if not (gaze.get("hint", {}) as Dictionary).is_empty():
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
	_check_overlap()
	_check_settle()
	_check_review_text()
	_check_seat_cap()
	_check_mailbox()
	_check_save_safety()
	_check_clock_gate()
	_check_facility_economy()
	_check_wish_feasibility()
	_check_rules_layer()
	_check_story_arc()

## G-05：账面数值必须有下落，「堆最便宜的那几件」必须不再是解。
func _check_facility_economy() -> void:
	var dead := 0
	var used_keys := {}
	for id: String in GameData.FACILITY_IDS:
		var eff: Dictionary = GameData.facility(id).get("eff", {})
		for k: String in eff:
			used_keys[k] = true
			if not gm.EFF_CHANNELS.has(k):
				dead += 1
	_truthy("目录里 %d 个功效键全部有下落（漏 %d）" % [used_keys.size(), dead], dead == 0)
	# 反方向也要对：通道声明了某一维却没有任何一件喂得到，那条通道是空写的
	var unserved: Array[String] = []
	for k: String in gm.EFF_CHANNELS:
		var found := false
		for id: String in GameData.FACILITY_IDS:
			if float(GameData.facility(id).get("eff", {}).get(k, 0)) > 0.0:
				found = true
		if not found:
			unserved.append(String(k))
	_truthy("每条效果通道都有东西喂得到（空转 %s）" % ",".join(unserved), unserved.is_empty())
	# 同款递减：第二件只值半件，第三件只值 quarter
	var one: float = gm.income_power_of(["vender"])
	var two: float = gm.income_power_of(["vender", "vender"])
	var three: float = gm.income_power_of(["vender", "vender", "vender"])
	_truthy("第二件只加一半（%.3f → %.3f）" % [one, two], absf(two - one * 1.5) < 0.0001)
	_truthy("第三件只加四分之一", absf(three - one * 1.75) < 0.0001)
	var spam: Array = []
	for _i in 20:
		spam.append("vender")
	_truthy("刷二十件同款也顶不到 +30%%（%.3f）" % gm.income_power_of(spam),
			float(gm.income_power_of(spam)) < float(gm.FACILITY_INCOME_MAX) - 0.001)
	# 最便宜的六件按旧公式正好顶满，现在几乎不加在席收益
	var cheap: Array = []
	for id: String in GameData.FACILITY_IDS:
		if int(GameData.facility(id).cost) <= 20:
			cheap.append(id)
	var six: Array = []
	for i in mini(6, cheap.size()):
		six.append(cheap[i])
	_truthy("%d 件最便宜的摆件不再等于 +30%%（%.3f）" % [six.size(), gm.income_power_of(six)],
			float(gm.income_power_of(six)) < 0.1)
	var curated: Array = ["vender", "camera", "tea", "bench", "bucket", "ishidoro"]
	_truthy("精选六件明显更值（%.3f vs %.3f）" % [gm.income_power_of(curated), gm.income_power_of(six)],
			float(gm.income_power_of(curated)) > float(gm.income_power_of(six)) + 0.05)
	# 效率折节拍、放松折停留：两维各量各的
	_truthy("挂钟与扶梯的效率高", float(gm.eff_total_of(["clock", "clock", "ladder"], ["effcy"])) > 1.4)
	# 声望与招牌折成日结进账，并且真的落到店铺声望上
	_reset()
	gm.facilities.clear()
	gm.reputation = 30.0
	gm._reset_day_ledger()
	gm.facilities[ROOM] = [{"id": "noren", "x": 100, "y": 100},
			{"id": "signboard", "x": 200, "y": 300}]
	var fame: float = gm.daily_fame()
	var gained: float = gm._grant_daily_fame()
	_truthy("暖帘与告示牌折出日结声望 %.2f" % fame, fame > 0.0)
	_truthy("日结声望真的落到店铺上", absf(float(gm.reputation) - (30.0 + gained)) < 0.001)
	_truthy("这笔进账记进当日账本", absf(float(gm.today.fame) - gained) < 0.001)
	var quiet: float = gm.surprise_chance()
	gm.facilities.clear()
	_truthy("空店的基础奇闻概率 %.2f" % quiet, absf(quiet - float(gm.SURPRISE_CHANCE)) < 0.001)
	gm.facilities[ROOM] = [{"id": "spout", "x": 100, "y": 300}]
	_truthy("竹笕流水抬升奇闻概率", float(gm.surprise_chance()) > quiet)
	gm.facilities.clear()
	gm.reputation = 20.0
	gm._reset_day_ledger()
	# 面板文案只报有下落的通道，纯摆设就直说不产收益
	_truthy("纯摆设直说不产收益", String(gm.facility_effect_text("geta")).find("不产收益") >= 0)
	_truthy("零食摊的文案报得出在席收益", String(gm.facility_effect_text("vender")).find("在席收益") >= 0)
	_truthy("文案里不出现没下落的键名", String(gm.facility_effect_text("tea")).find("社交 1") < 0)

## 心愿的可完成性：除了「几何上放得下」，还要看玩家已经占了地、这条池子坐不坐得下第三位。
func _check_wish_feasibility() -> void:
	_reset()
	gm.facilities.clear()
	_truthy("露天 %d 位 · 社交 %.1f · 需 %d 位 → 闲聊不许许给它" % [
			gm.max_pool_seats("rotenburo"), gm.social_power("rotenburo"),
			gm.chat_peers_needed("rotenburo")],
			gm.max_pool_seats("rotenburo") == 2 and not gm.wish_feasible("rotenburo", "chat"))
	_truthy("大池坐得下三位，闲聊许得起", gm.max_pool_seats("ooike") >= 3
			and gm.wish_feasible("ooike", "chat"))
	_truthy("茶室按画死的坐垫数算位", gm.max_pool_seats("chashitsu") == 3)
	# 社交够 3 点，热闹到一个人也聊得起来 → 两位的池子也敢许闲聊
	gm.facilities["rotenburo"] = [{"id": "tea", "x": 100, "y": 300},
			{"id": "cushion", "x": 300, "y": 300}, {"id": "mat", "x": 500, "y": 300}]
	_truthy("热闹之后门槛放到一位（%.1f 点社交）" % gm.social_power("rotenburo"),
			gm.social_power("rotenburo") >= float(gm.EFF_SOCIAL_EASE)
			and gm.chat_peers_needed("rotenburo") == 1
			and gm.wish_feasible("rotenburo", "chat"))
	gm.facilities.clear()
	# 玩家把地面占满之后，「想买零食」就不该再许给客人——
	# room_fits 只看几何，会说「放得下」；真正该问的是此刻还剩不剩得下一块空地
	gm.facilities[ROOM] = [{"id": "oke_lid", "x": 48, "y": 370},
			{"id": "andon_floor", "x": 848, "y": 368}]
	_truthy("几何上仍说放得下零食摊", gm.room_fits(ROOM, "vender"))
	_truthy("两条地面块都被占住时判成没有落点", not gm.room_has_free_spot(ROOM, "vender"))
	_truthy("没有落点就不许零食心愿", not gm.wish_feasible(ROOM, "snack"))
	var granted_snack := false
	for _i in 80:
		if String(gm.pick_wish(ROOM)) == "snack":
			granted_snack = true
	_truthy("连着抽 80 次也抽不到招待不起的心愿", not granted_snack)
	# 已经摆好的那件不该反过来说「放不下」：有了就不必再找空地
	gm.facilities[ROOM] = [{"id": "vender", "x": 48, "y": 370}]
	_truthy("零食摊已在屋里，心愿照样许得起", gm.wish_feasible(ROOM, "snack"))
	_reset()
	gm.facilities.clear()

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
	for table: Dictionary in [GameData.REVIEW_ONSEN, GameData.REVIEW_LOUNGE]:
		for band: String in table:
			for line: String in (table[band] as Array):
				if line.length() > longest.length():
					longest = line
	for cause: Array in [GameData.REVIEW_CAUSE_WRONG_POOL, GameData.REVIEW_CAUSE_WISH_MISS,
			GameData.REVIEW_CAUSE_CROWDED, GameData.REVIEW_WISH_DONE]:
		for line: String in cause:
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
	gm.seen_lines.clear()
	gm.forecast.clear()
	gm.mailbox.clear()
	gm.story_log.clear()
	gm.letters_read = 0
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

## ---------------- 审计报告第一轮：规则与状态一致性 ----------------

## G-02：贴挤容差只有一处真相——overlap_depth()。
## 这里量三条边界：正好咬到容差、多压 1 像素、以及并排不压。
## 原来写成「两个矩形各收缩 6 再判交」，那是把容差放大成 12，还和常量注释反着说。
func _check_overlap() -> void:
	var a := Rect2(0, 0, 10, 10)
	_truthy("完全错开侵入 0", gm.overlap_depth(a, Rect2(20, 0, 10, 10)) == 0.0)
	_truthy("边界正好相接侵入 0", gm.overlap_depth(a, Rect2(10, 0, 10, 10)) == 0.0)
	_truthy("只算浅的那一轴（横 5 纵 9 → 5）", gm.overlap_depth(a, Rect2(5, 0, 10, 10)) == 5.0)
	_truthy("一角轻碰 1 像素就是 1", gm.overlap_depth(a, Rect2(0, 9, 10, 10)) == 1.0)
	_reset()
	gm.facilities.clear()
	var c := _lot_spot(ROOM, "chawan")
	var w := float(GameData.facility_size("chawan").x)
	var tol := float(gm.FACILITY_OVERLAP_TOL)
	_truthy("先摆一只茶碗", gm.buy_facility(ROOM, "chawan", c))
	_truthy("压到容差 %d 整仍放行" % int(tol), gm.can_place(ROOM, "chawan", c + Vector2(w - tol, 0)))
	_truthy("多压 1 像素就拒绝", not gm.can_place(ROOM, "chawan", c + Vector2(w - tol - 1.0, 0)))
	_truthy("并排不压才放行", gm.can_place(ROOM, "chawan", c + Vector2(w, 0)))
	# 池沿那条 2 像素的容差走同一个算式，不许出现两套判据
	var pool: Rect2 = gm.room_cfg(ROOM).pools[0]
	_truthy("压进池沿 2 像素仍放行", gm.overlap_depth(
			Rect2(pool.position.x - 32.0, pool.position.y - 2.0, 32.0, 32.0), pool) <= 2.0)

## G-04：心愿奖励只走离店结算这一个出口，表里写了 coin/fame 就必须真到账。
func _check_settle() -> void:
	_reset()
	gm._reset_day_ledger()
	gm.reputation = 20.0
	var coin_before: int = gm.coins
	var wish := "snack"
	var w: Dictionary = GameData.WISHES[wish]
	var s: Dictionary = gm.settle_guest(5, wish, true)
	_truthy("心愿金币进账 +%d" % int(w.coin), gm.coins == coin_before + int(w.coin))
	_truthy("结算如实报回金币", int(s.wish_coin) == int(w.coin))
	_truthy("声望 = 星级 6 + 心愿 %d" % int(w.fame),
			absf(float(gm.reputation) - (20.0 + 6.0 + float(w.fame))) < 0.001)
	_truthy("心愿金币进当日账本", int(gm.today.income) == int(w.coin))
	_truthy("心愿计数 +1", int(gm.today.wishes) == 1)
	gm.coins = coin_before
	gm.reputation = 20.0
	gm._reset_day_ledger()
	var miss: Dictionary = gm.settle_guest(5, wish, false)
	_truthy("没达成心愿不发钱", int(miss.wish_coin) == 0 and gm.coins == coin_before)
	_truthy("没达成时只进星级那 6 点", absf(float(gm.reputation) - 26.0) < 0.001)
	# 封顶之后再好的点评也不许把声望顶出界
	gm.reputation = float(gm.MAX_REPUTATION)
	gm.coins = coin_before
	var capped: Dictionary = gm.settle_guest(5, wish, true)
	_truthy("封顶时心愿奖励不越界", float(gm.reputation) <= float(gm.MAX_REPUTATION))
	_truthy("封顶时金币照发（钱不设顶）", gm.coins == coin_before + int(w.coin))
	_truthy("封顶时报回的声望是实际到账", absf(float(capped.rep_delta)) < 0.001)
	gm.reputation = 20.0

## N-02：一句话必须和它头上的星级同档。查的是「这句出自哪一池」而不是措辞黑名单——
## 白名单结实：哪天新加一句正面话，也不会让这条断言假绿。
func _check_review_text() -> void:
	var off := 0
	var lounge_off := 0
	for i in 60:
		# 一星 + 踩雷 + 心愿落空：只能是「汤种不对味」那两条
		if not GameData.REVIEW_CAUSE_WRONG_POOL.has(GameData.review_text(1, false, false, -1, 0)):
			off += 1
		# 五星 + 心愿达成：不许冒出任何一句通用池的话
		if not GameData.REVIEW_WISH_DONE.has(GameData.review_text(5, false, true, 1, 0)):
			off += 1
		# 两星 + 心愿落空：说得出原因，而不是笼统不满
		if not GameData.REVIEW_CAUSE_WISH_MISS.has(GameData.review_text(2, false, false, 0, 0)):
			off += 1
		# 三星 + 池子里挤：把「挤」这条原因说出来，而不是继续报喜
		if not GameData.REVIEW_CAUSE_CROWDED.has(GameData.review_text(3, false, true, 1, 2)):
			off += 1
		# 四星以上不挤且心愿没成：出自 positive 通用池
		if not (GameData.REVIEW_ONSEN.positive as Array).has(GameData.review_text(4, false, false, 1, 0)):
			off += 1
		# 茶室：任何一档都不许提「泡」，也不许说池子挤
		var l := GameData.review_text(3, true, true, 1, 3)
		if l.find("泡") >= 0 or GameData.REVIEW_CAUSE_CROWDED.has(l):
			lounge_off += 1
	_truthy("点评与星级从不打架（%d/300 出错）" % off, off == 0)
	_truthy("茶室点评不提下水与池子（%d/60 出错）" % lounge_off, lounge_off == 0)
	_truthy("三档分界：四星以上算好评", GameData.review_band(4) == "positive"
			and GameData.review_band(3) == "neutral" and GameData.review_band(2) == "negative")

## G-06：位子不是想买就有的——背景画死的坐垫会把容量顶住。
## 顶住的那一级必须给出 0 的座位增量，同时收益与额度仍在涨，标签才改得口。
func _check_seat_cap() -> void:
	_truthy("没有坐垫限制时按池宽算", GameData.seat_cap("hot", 3, 8, 0) == GameData.level_cap("hot", 3, 8))
	_truthy("画死 3 只就最多 3 位", GameData.seat_cap("tatami", 3, 8, 3) == 3)
	_truthy("顶住之后 1→2 级不加位子",
			GameData.seat_cap("tatami", 2, 8, 3) - GameData.seat_cap("tatami", 1, 8, 3) == 0)
	_truthy("没顶住时 1→2 级多 1 位",
			GameData.seat_cap("hot", 2, 8, 0) - GameData.seat_cap("hot", 1, 8, 0) == 1)
	_truthy("顶住的那一级收益仍在涨", GameData.level_income(2) > GameData.level_income(1))
	_truthy("顶住的那一级额度仍在涨", GameData.level_budget("tatami", 2) > GameData.level_budget("tatami", 1))
	# 茶室右带只有 3 只画死的坐垫：真实增量必须报得出 0，界面才不许写「多 1 个位」
	var seats: Array = gm.room_cfg("chashitsu").get("seats", [])
	var widest := 0
	for group: Array in seats:
		widest = maxi(widest, group.size())
	_truthy("茶室最多 %d 位一桌，顶住后升级不加位" % widest,
			GameData.seat_cap("tatami", 3, 12, widest) == widest)

## 信箱满员时不许吃掉未读的信：全未读就一封不塞，有一封读过才腾它的位置。
func _check_mailbox() -> void:
	_reset_story()
	gm.day = 3
	for i in gm.MAILBOX_CAP:
		gm.mailbox.append({"id": "full-%d" % i, "species": "foxe", "title": "t", "body": "b",
				"day": 4, "hint": {}, "read": false})
	var ids_before: Array = []
	for m: Dictionary in gm.mailbox:
		ids_before.append(String(m.id))
	for i in 30:
		gm.post_letter("foxe", gm.story_ctx("foxe", 1))
	var same: bool = gm.mailbox.size() == gm.MAILBOX_CAP
	for i in gm.MAILBOX_CAP:
		if String(gm.mailbox[i].id) != String(ids_before[i]):
			same = false
	_truthy("全未读时一封也没被挤掉", same)
	gm.mailbox[0].read = true
	var got := false
	for i in 30:
		if not gm.post_letter("foxe", gm.story_ctx("foxe", 1)).is_empty():
			got = true
			break
	_truthy("有一封读过就能腾出位置", got)
	_truthy("腾位后仍不越上限", gm.mailbox.size() == gm.MAILBOX_CAP)
	_truthy("腾掉的是读过那封", not bool(gm.mailbox[0].read))
	_reset_story()

## G-03：坏存档不许把整局带走。注入非法 id、缺坐标、越界数值与超新结构戳，
## 看的是「坏的那条丢了、好的那条还在」，以及主档写坏时退不退得回备份。
func _check_save_safety() -> void:
	var ctx: Dictionary = gm.save_ctx()
	var mixed := {
		"schema_version": SaveData.SCHEMA, "coins": 300, "day": 4, "hour": 10.0,
		"reputation": 55.0,
		"facilities": {ROOM: [{"id": "vender", "x": 48, "y": 392},
				{"id": "no_such_item", "x": 10, "y": 10}, {"id": "chawan", "y": 20},
				{"id": "chawan", "x": "九十八", "y": 392}]},
		"pool_levels": {ROOM2: [99, -3]},
		"mailbox": [{"species": "foxe", "body": "有正文", "read": false},
				{"species": "nope", "body": "物种不存在"}, {"species": "foxe", "body": ""}],
		"memory": {"foxe": {"visits": 5}, "nope": {"visits": 9}},
		"forecast": [{"pool": "herb", "until": 4}, {"pool": "gone", "until": 9}],
		"story_log": ["a", 3, ""],
	}
	var data: Dictionary = SaveData.apply(mixed, ctx)
	var kept: Array = (data.facilities as Dictionary)[ROOM]
	_truthy("非法 id 与缺坐标的丢，合法那条在（留 %d 条）" % kept.size(), kept.size() == 1)
	_truthy("留下的是零食摊那条", String(kept[0].id) == "vender")
	_truthy("等级夹回 1..%d" % gm.max_pool_level(),
			int((data.pool_levels as Dictionary)[ROOM2][0]) == gm.max_pool_level())
	_truthy("负等级夹到 1", int((data.pool_levels as Dictionary)[ROOM2][1]) == 1)
	_truthy("hour/day 原样读回", absf(float(data.hour) - 10.0) < 0.001 and int(data.day) == 4)
	_truthy("visits=5 折成 arc_stage=1", int((data.memory as Dictionary)["foxe"].arc_stage) == 1)
	_truthy("名册外的物种不进记忆", not (data.memory as Dictionary).has("nope"))
	_truthy("信箱只收有正文且物种在表里的", (data.mailbox as Array).size() == 1)
	_truthy("过期与查不到表的清掉", (data.forecast as Array).size() == 1)
	_truthy("收藏册只留字符串 id", (data.story_log as Array) == ["a"])
	_truthy("没结构戳的旧档照样读", int(SaveData.apply({"coins": 7}, ctx).coins) == 7)
	_truthy("声望夹在 0..100", absf(float(SaveData.apply({"reputation": 500}, ctx).reputation)
			- float(gm.MAX_REPUTATION)) < 0.001)
	# 原子写：替换旧档时先留备份；主档被写坏，读回来的应该是备份那份
	_reset()
	gm.coins = 777
	_truthy("第一次写盘成功", gm.save_game())
	gm.coins = 888
	_truthy("第二次写盘成功", gm.save_game())
	_truthy("替换前留下了备份", FileAccess.file_exists(SAVE + SaveData.BACKUP_SUFFIX))
	_truthy("备份里是上一份的 777", _coins_from(SAVE + SaveData.BACKUP_SUFFIX) == 777)
	var wreck := FileAccess.open(SAVE, FileAccess.WRITE)
	wreck.store_string("{ 这截不是合法 JSON")
	wreck.close()
	var back := SaveData.read(SAVE, ctx)
	_truthy("主档损坏时回退到备份", bool(back.ok) and String(back.source) == SaveData.SOURCE_BACKUP)
	_truthy("回退读到的金币是 777", int((back.data as Dictionary).coins) == 777)
	var too_new := FileAccess.open(SAVE, FileAccess.WRITE)
	too_new.store_string(JSON.stringify({"schema_version": 9999, "coins": 1}))
	too_new.close()
	var refused := SaveData.read(SAVE, ctx)
	_truthy("太新的存档不硬读，只从备份或新档走",
			not bool(refused.ok) or int((refused.data as Dictionary).coins) != 1)
	var tmp_left := FileAccess.file_exists(SAVE + SaveData.TMP_SUFFIX)
	_truthy("写盘不留临时文件", not tmp_left)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE + SaveData.BACKUP_SUFFIX))

## G-01：全局单例存在 ≠ 正在经营。停着不动的那段时间不该把日期推过去。
func _check_clock_gate() -> void:
	var day_before: int = gm.day
	gm.stop_sim()
	gm.hour = 23.9
	gm._process(30.0)
	_truthy("停表时不推时钟", absf(float(gm.hour) - 23.9) < 0.001)
	_truthy("停表时不跨天", gm.day == day_before)
	gm.start_sim()
	gm._process(0.5)
	_truthy("走表时时钟推进", float(gm.hour) > 23.9)
	# 场景自己表态：标题与案内图停表，进了房间才重新走
	for pair in [["res://scenes/title.tscn", false], ["res://scenes/map.tscn", false],
			["res://scenes/room.tscn", true]]:
		var inst: Node = (load(String(pair[0])) as PackedScene).instantiate()
		gm.start_sim()
		root.add_child(inst)
		var want := bool(pair[1])
		_truthy("%s 的时钟状态是%s" % [pair[0], "走" if want else "停"], bool(gm.sim_running) == want)
		root.remove_child(inst)
		inst.free()
	gm.stop_sim()

func _coins_from(path: String) -> int:
	if not FileAccess.file_exists(path):
		return -1
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var d: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	return int(d.get("coins", -1))

## 第三阶段验收：算式搬进 GameRules 之后要同时满足两件事——
## ①它不认识 ROOMS 表、不需要任何场景节点，随手拼一张字典也照样算得出落点；
##   否则「经营计算脱离 UI 可测」只是话术。
## ②GameManager 那层同名转发必须与它判得一模一样；
##   一旦分叉，玩家在店里点下去的那一下和闸机算的那一套就不是同一件事了。
func _check_rules_layer() -> void:
	var lot := Rect2(160, 300, 208, 160)
	var hand_cfg := {"pools": [Rect2(0, 0, 120, 80)], "spawns": [Vector2(760, 470)],
		"lots": [lot]}
	var spot := GameRules.snap_center("chawan", lot.get_center())
	_truthy("凭空拼的字典也算得出落点（不查 ROOMS 表）",
			GameRules.placement_ok(hand_cfg, [], "chawan", spot, true, 0, 220.0))
	_truthy("交空字典直接拒", not GameRules.placement_ok({}, [], "chawan", spot, true, 0, 220.0))
	_truthy("买不买得起是唯一的金钱闸",
			not GameRules.placement_ok(hand_cfg, [], "chawan", spot, false, 0, 220.0))
	_truthy("同格重影被拒", not GameRules.placement_ok(hand_cfg,
			[{"id": "chawan", "x": int(spot.x), "y": int(spot.y)}], "chawan", spot, true, 1, 220.0))
	_truthy("空地扫描同样只吃这张字典", GameRules.has_free_spot(hand_cfg, [], "chawan", 220.0, 0))
	var ids := ["vender", "vender", "tea"]
	var expect := GameRules.income_value("vender") * 1.5 + GameRules.income_value("tea")
	_truthy("收益算式认得同款减半（%.3f）" % GameRules.income_power_of(ids),
			absf(GameRules.income_power_of(ids) - expect) < 0.0001)
	_truthy("闲聊门槛只看传进来的社交值",
			GameRules.chat_peers_needed(2.9) == 2 and GameRules.chat_peers_needed(3.0) == 1)

	_reset()
	gm.facilities.clear()
	gm.coins = 60
	var mismatch := 0
	var compared := 0
	for room_id: String in gm.ROOMS:
		var cfg: Dictionary = gm.room_cfg(room_id)
		var wall: float = gm.wall_limit_y(room_id)
		for id: String in GameData.FACILITY_IDS:
			var f := GameData.facility(id)
			var spots: Array = [Vector2(200.0, wall + 8.0)]
			for rect: Rect2 in cfg.get("lots", []):
				spots.append(gm.snap_center(id, rect.get_center()))
			for sp: Variant in spots:
				compared += 1
				var direct := GameRules.placement_ok(cfg, gm.room_facilities(room_id), id,
						sp, gm.coins >= int(f.cost), gm.facility_count(room_id, id), wall)
				if direct != gm.can_place(room_id, id, sp):
					mismatch += 1
	_truthy("转发层与 GameRules 逐点一致（比了 %d 处，分叉 %d）" % [compared, mismatch],
			compared >= 100 and mismatch == 0)

## N-03：角色主线。档案上写着「等人的」「等春天的」却没人读过那个字段，
## 闲聊池也只是同排并抽——这里验的是它现在真成了一条有顺序、有门槛、讲得完的链。
func _check_story_arc() -> void:
	var planned := asserts
	# 1) 静态形状：每拍都要有 id / 段 / when 用得上限内的键 / hint 是字典
	var story_ids := {}
	for table: Dictionary in Story.channels():
		for key_id: String in table:
			for e: Dictionary in table[key_id]:
				story_ids[String(e.get("id", ""))] = true
	var arc_ids := {}
	var bad_shape := 0
	var collides := 0
	var off_beat := 0
	var unknown_sp := 0
	var beats := 0
	for sp: String in StoryArc.species_ids():
		if not GameData.SPECIES.has(sp):
			unknown_sp += 1
		var list: Array = StoryArc.entries(sp)
		for i in list.size():
			var e: Dictionary = list[i]
			beats += 1
			var id := String(e.get("id", ""))
			var when_keys: Array = (e.get("when", {}) as Dictionary).keys()
			var unknown_key := 0
			for w: String in when_keys:
				if not gm.KNOWN_WHEN_KEYS.has(w):
					unknown_key += 1
			if id == "" or arc_ids.has(id) or (e.get("segments", []) as Array).is_empty() \
					or typeof(e.get("hint", {})) != TYPE_DICTIONARY or unknown_key > 0:
				bad_shape += 1
			arc_ids[id] = true
			if story_ids.has(id):
				collides += 1
			# 拍号与阶段名都要按序：跳号就等于链条断了还装作没断
			if int(e.get("beat", 0)) != i + 1 or String(e.get("stage", "")) != StoryArc.STAGES[i]:
				off_beat += 1
	_truthy("主线 %d 拍只挂在名册里的物种（坏 %d 个）" % [beats, unknown_sp], unknown_sp == 0)
	_truthy("主线 %d 拍形状完整：id、段、hint、when 键（坏 %d 拍）" % [beats, bad_shape], bad_shape == 0)
	_truthy("主线拍号与阶段名按序（错位 %d 拍）" % off_beat, off_beat == 0)
	_truthy("主线 id 不与生成表相撞（撞 %d 处）" % collides, collides == 0)

	# 2) 档案标签与主线必须一一对上：写着「等人的」却查无此链，等于广告打了没人接
	var advertised := 0
	var unlabeled := 0
	for sp: String in GameData.SPECIES:
		var has_arc := not StoryArc.entries(sp).is_empty()
		# 档案里没主线的那 28 只写的是 null，String(null) 当场炸——先问有没有，再转字符串
		var arc_label: Variant = Story.profile(sp).get("arc", null)
		var labeled := arc_label != null and String(arc_label) != ""
		if labeled and not has_arc:
			advertised += 1
		if has_arc and not labeled:
			unlabeled += 1
	_truthy("档案 arc 标签 %d 条都有对应主线，主线也都有标签（空标签 %d，无名主线 %d）" % [
			beats, advertised, unlabeled], advertised == 0 and unlabeled == 0)

	# 3) 顺序：一拍讲完才轮到下一拍；门槛没到就整条链停住，绝不跳过
	var full := {"visits": 9, "arc_stage": 2, "match": "perfect", "period": "evening",
			"first": false, "built": 9, "letters_read": 9}
	var cold := full.duplicate(true)
	cold["visits"] = 0
	_truthy("一次都没来时主线不开口", gm.arc_next("shib", cold).is_empty())
	_reset_story()
	var walked: Array[String] = []
	for i in StoryArc.entries("shib").size():
		var beat: Dictionary = gm.arc_next("shib", full)
		if beat.is_empty():
			break
		walked.append(String(beat.id))
		gm.commit_line("shib", beat)
	var want: Array[String] = []
	for e: Dictionary in StoryArc.entries("shib"):
		want.append(String(e.id))
	_truthy("小狗五拍按序讲完（%d/%d）" % [walked.size(), want.size()], walked == want)
	_truthy("讲完之后再问就是空，不许翻来覆去讲同一件事", gm.arc_next("shib", full).is_empty())
	var prog: Dictionary = gm.arc_progress("shib")
	_truthy("进度如实记 5/5 且总数取的是这条链", int(prog.done) == 5 and int(prog.total) == 5)
	_truthy("进度不越界：没主线的物种报 0/0", gm.arc_progress("foxe") == {"done": 0, "total": 0})

	# 4) 卡住的那一拍就是墙：第 3 拍要玩家先摆过东西，没摆就停在那儿，不许跳到第 4 拍
	_reset_story()
	var no_build := full.duplicate(true)
	no_build["built"] = 0
	gm.commit_line("shib", gm.arc_next("shib", no_build))
	gm.commit_line("shib", gm.arc_next("shib", no_build))
	_truthy("门槛没到就停在第 3 拍前，不跳拍", gm.arc_next("shib", no_build).is_empty())
	_truthy("停在第 2 拍：进度读得出 2/5", int(gm.arc_progress("shib").done) == 2)
	no_build["built"] = 1
	_truthy("摆上一件，第 3 拍当场解锁", String(gm.arc_next("shib", no_build).id) == "arc-shib-3")
	# 主线走完不占闲聊：那位客人讲完心事还得肯聊天
	_reset_story()
	for e: Dictionary in StoryArc.entries("shib"):
		gm.commit_line("shib", e)
	_truthy("主线讲完仍能从闲聊池取词",
			not gm.pick_line("chat", "shib", gm.story_ctx("shib", 1, ROOM)).is_empty())

	# 5) 分母：收藏册算的是生成表 + 主线两层，少算一层玩家就永远集不满
	var story_lines := Story.line_count()
	_truthy("总文案 %d = 生成表 %d + 主线 %d" % [gm.total_lines(), story_lines, StoryArc.line_count()],
			gm.total_lines() == story_lines + StoryArc.line_count())
	_truthy("主线不在生成表里（重跑生成脚本不会把它冲掉）",
			Story.channel("chat").get("shib", []).size() > 0
			and String(Story.channel("chat").get("shib", [])[0].id) != "arc-shib-1")
	# 收尾这条是本段的覆盖凭据：中途被脚本错误炸掉时它打印不出来，
	# 前面那一串 ok 行看着和跑完整段一模一样，绿灯就是假的。
	_truthy("主线闸本段前 %d 条断言全部跑到（计划 16）" % (asserts - planned), asserts - planned == 16)
