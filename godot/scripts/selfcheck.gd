extends SceneTree
## headless 自检：实例化全部场景与每个房间配置，确认节点树完整、无缺失引用。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/selfcheck.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。
## 检查放在首帧 _process：_initialize 阶段退出会导致 _ready 不执行。

const SCENES := [
	"res://scenes/title.tscn",
	"res://scenes/map.tscn",
	"res://scenes/room.tscn",
]

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true
	quit(_run_checks())
	return false

func _run_checks() -> int:
	if root.get_node_or_null("GameManager") == null:
		var gm: Node = (load("res://scripts/game_manager.gd") as GDScript).new()
		gm.name = "GameManager"
		root.add_child(gm)
	var failures := 0
	for path in SCENES:
		var scene := load(path) as PackedScene
		if scene == null:
			printerr("FAIL load ", path)
			failures += 1
			continue
		var inst: Node = scene.instantiate()
		root.add_child(inst)
		print("OK ", path, " nodes=", _count(inst))
		inst.queue_free()
	var gm_node: Node = root.get_node("GameManager")
	for room_id: String in gm_node.ROOMS:
		gm_node.current_room = room_id
		var room: Node = (load("res://scenes/room.tscn") as PackedScene).instantiate()
		root.add_child(room)
		var pool_count: int = room.get_node("PoolAreas").get_child_count()
		var spawn_count: int = room.get_node("SpawnPoints").get_child_count()
		var want_pools: int = gm_node.ROOMS[room_id].pools.size()
		var want_spawns: int = gm_node.ROOMS[room_id].spawns.size()
		if pool_count != want_pools or spawn_count != want_spawns:
			printerr("FAIL room ", room_id, " pools=", pool_count, "/", want_pools, " spawns=", spawn_count, "/", want_spawns)
			failures += 1
		else:
			print("OK room:", room_id, " pools=", pool_count, " spawns=", spawn_count)
		# 触摸端没有 F1/F2/F3，也没有右键：顶栏这排按钮就是三档开关与拆除的唯一入口
		var dock: Node = room.get_node_or_null("HUD/TopBar/Dock")
		var dock_ok := dock != null
		if dock_ok:
			for dock_name: String in ["DockMail", "DockLayout", "DockBuild", "DockExpand",
					"DockDemolish", "DockDrop"]:
				var b := dock.get_node(dock_name) as Button
				if b == null or b.custom_minimum_size.y < gm_node.TOUCH_BUTTON_HEIGHT:
					dock_ok = false
		if not dock_ok:
			printerr("FAIL room ", room_id, " 顶栏按钮坞缺项或太矮")
			failures += 1
		# 顶栏挤爆了会把最右边的「案内图」推出画布，手机端窗口本来就窄，先按最坏情况拦一道
		var bar := room.get_node("HUD/TopBar") as HBoxContainer
		# 「放下」只在建造模式现身，而那正是顶栏最挤的一档
		(bar.get_node("Dock/DockDrop") as Control).visible = true
		var need := float(bar.offset_left - bar.offset_right)
		var kids := 0
		for c in bar.get_children():
			if c is Control and c.visible:
				need += (c as Control).get_combined_minimum_size().x
				kids += 1
		need += float(bar.get_theme_constant("separation")) * maxi(0, kids - 1)
		var budget: float = gm_node.VIEWPORT_SIZE.x
		if need > budget:
			printerr("FAIL room ", room_id, " 顶栏最小宽度 ", "%.0f" % need, " 超出画布 ", budget)
			failures += 1
		# 夜里的暖光是运行时照着配置表长出来的：数量对不上就是 _build_glows 与 ROOMS 脱了钩。
		# 只能走 get()——room 的静态类型是 Node，编译期看不见 room_view 的成员。
		var lamps = room.get("lamp_glows")
		var sheen = room.get("water_glows")
		var want_lamps: int = gm_node.ROOMS[room_id].lights.size()
		var want_sheen: int = 0 if gm_node.is_lounge(room_id) else want_pools
		if lamps == null or sheen == null or lamps.size() != want_lamps or sheen.size() != want_sheen:
			var got_lamps: int = 0 if lamps == null else lamps.size()
			var got_sheen: int = 0 if sheen == null else sheen.size()
			printerr("FAIL room ", room_id, " 灯光 ", got_lamps, "/", want_lamps,
					" 水光 ", got_sheen, "/", want_sheen)
			failures += 1
		else:
			# 玩家挂的纸灯笼也要跟着亮：加一盏就该多一圈光（数组是同一份，clear 不换引用）
			var lanterns = room.get("lantern_glows")
			var before: int = lanterns.size()
			room.call("_add_facility_node", "lantern", Vector2(140, 96))
			if lanterns.size() != before + 1:
				printerr("FAIL room ", room_id, " 挂上灯笼却没点亮 ", before, "→", lanterns.size())
				failures += 1
			else:
				print("OK night:", room_id, " lamps=", want_lamps,
						" sheen=", want_sheen, " lanterns=", lanterns.size())
		# 热气按汤种的 steam 档长出来：清单对不上就是 _build_steam 与 POOLS 脱了钩
		var spools = room.get("steam_pools")
		var ptypes: Array = gm_node.ROOMS[room_id].pool_types
		var want_steam := 0
		for ti in ptypes.size():
			if GameData.pool_steam(String(ptypes[ti])) > 0.0:
				want_steam += 1
		if spools == null or spools.size() != want_steam:
			var got_steam: int = 0 if spools == null else spools.size()
			printerr("FAIL room ", room_id, " 冒汽池 ", got_steam, "/", want_steam)
			failures += 1
		else:
			print("OK steam:", room_id, " pools=", want_steam)
		# 封顶与回收跟房间无关，只在一家房里验一遍
		if room_id == "indoor" and want_steam > 0:
			var scap: int = room.get("STEAM_MAX")
			for si in scap + 3:
				room.call("_spawn_steam", 0, 1.0)
			var live_s = room.get("steams")
			if live_s.size() != scap:
				printerr("FAIL 热气没封顶: ", live_s.size(), "/", scap)
				failures += 1
			room.call("_update_steam", 4.0)
			if not live_s.is_empty():
				printerr("FAIL 热气到期没回收: ", live_s.size())
				failures += 1
			else:
				print("OK steam: capped=", scap)
		# 飘字只在一家房里验一遍：封顶与回收跟房间无关
		if room_id == "indoor":
			var cap: int = room.get("FLOAT_MAX")
			for i in cap + 3:
				room.call("_float_text", Vector2(120, 220), "+1", Color(1, 1, 1))
			var live = room.get("floats")
			if live.size() != cap:
				printerr("FAIL 飘字没封顶: ", live.size(), "/", cap)
				failures += 1
			room.call("_update_floats", 2.0)
			if not live.is_empty():
				printerr("FAIL 飘字到期没回收: ", live.size())
				failures += 1
			else:
				print("OK floats: capped=", cap)
		# 对白卡不许压在模态面板上：跨天正好推进章节时，两者会同屏抢底部那块地
		if room_id == "indoor":
			var before_fail := failures
			var card = room.get("story_card")
			room.set("story_showing", true)
			room.call("_sync_story_card")
			if not card.visible:
				printerr("FAIL 平时挂着台词却不收线")
				failures += 1
			room.call("_on_day_reported", {"day": 3, "guests": 1, "income": 10, "wishes": 1,
					"good": 1, "bad": 0, "stars_avg": 4.0, "rep_delta": 1.0, "by_type": {}})
			if not room.get("report_panel").visible or card.visible:
				printerr("FAIL 结算面板开着，对白卡还占着底部")
				failures += 1
			room.call("_close_report")
			if not card.visible:
				printerr("FAIL 结算关掉后台词没回来 modal=", room.call("_modal_up"),
						" showing=", room.get("story_showing"))
				failures += 1
			if room.get_tree().paused:
				printerr("FAIL 结算关掉后树还停着")
				failures += 1
			room.call("_toggle_mail")
			if card.visible:
				printerr("FAIL 信箱开着，对白卡还占着底部")
				failures += 1
			room.call("_toggle_mail")
			if not card.visible:
				printerr("FAIL 信箱关掉后台词没回来")
				failures += 1
			if failures == before_fail:
				print("OK modal: indoor 对白卡给结算与信箱让位，退场后回来")
		# 点评条：星级、那句话、心愿与声望增量都钉在顶栏下方那一条里
		if room_id == "indoor":
			var before_fail := failures
			var stamp: Label = room.get("review_line")
			if stamp == null:
				printerr("FAIL indoor 没有点评条")
				failures += 1
			else:
				if stamp.visible:
					printerr("FAIL 没人点评点评条却亮着")
				room.call("_review_stamp", "阿橘", 5, "汤很暖，下次还来。", 6.0, "想安静", true)
				var t5 := String(stamp.text)
				if not stamp.visible or not t5.contains("★★★★★") or not t5.contains("声望 +6") \
						or not t5.contains("✓想安静"):
					printerr("FAIL 五星点评读不全: ", t5)
					failures += 1
				if stamp.get_theme_color("font_color") != Color(room.get("REVIEW_GOOD_TINT")):
					printerr("FAIL 好评没烫金: ", stamp.get_theme_color("font_color"))
					failures += 1
				# 淡出只给尾段：读完之前不许开始变透明
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) * 0.6)
				if stamp.modulate.a < 0.99:
					printerr("FAIL 点评条提前淡了: ", stamp.modulate.a)
					failures += 1
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) * 0.15)
				if not stamp.visible or stamp.modulate.a >= 0.99 or stamp.modulate.a <= 0.01:
					printerr("FAIL 尾段没在淡: visible=", stamp.visible, " a=", stamp.modulate.a)
					failures += 1
				room.call("_review_stamp", "小满", 2, "人有点多，没泡尽兴。", -2.0, "想独处", false)
				var t2 := String(stamp.text)
				if not t2.contains("★★☆☆☆") or not t2.contains("声望 -2") or not t2.contains("✗想独处"):
					printerr("FAIL 差评读不全: ", t2)
					failures += 1
				if stamp.get_theme_color("font_color") != Color(room.get("REVIEW_BAD_TINT")):
					printerr("FAIL 差评没发红: ", stamp.get_theme_color("font_color"))
					failures += 1
				# 必须挂在 HUD 那一层：夜罩是 layer 5 的整片蓝，同一个画布里 z_index 给多高都压不过它
				var hud: CanvasLayer = stamp.get_parent()
				var veil: CanvasLayer = room.get("night_layer")
				if hud == null or veil == null or int(hud.layer) <= int(veil.layer):
					printerr("FAIL 点评条压不进夜罩之上: hud=", hud, " veil=", veil)
					failures += 1
				# 起点是从顶栏实际高度推出来的，不是写死的 46：顶栏加高不许把这条带压到底下
				var top_bar: Control = room.get_node("HUD/TopBarBG")
				if float(stamp.position.y) < float(top_bar.offset_bottom):
					printerr("FAIL 点评条滑进顶栏底下了: y=", stamp.position.y,
							" 顶栏高=", top_bar.offset_bottom)
					failures += 1
				# 底衬垫在字后面、还得盖得住字：比字还窄就等于没垫
				var plate: ColorRect = room.get("review_plate")
				if plate == null:
					printerr("FAIL 点评条没有底衬")
					failures += 1
				elif not bool(plate.show_behind_parent) or plate.get_parent() != stamp:
					printerr("FAIL 底衬没垫在字后面")
					failures += 1
				elif float(plate.size.x) < stamp.get_minimum_size().x:
					printerr("FAIL 底衬比字还窄: ", plate.size.x, " < ", stamp.get_minimum_size().x)
					failures += 1
				# 挪到 HUD 上就盖得住结算与信箱，只能自己让位——照对白卡那套开合序列走一遍
				room.call("_review_stamp", "阿橘", 5, "汤很暖，下次还来。", 6.0, "想安静", true)
				room.call("_on_day_reported", {"day": 3, "guests": 1, "income": 10, "wishes": 1,
						"good": 1, "bad": 0, "stars_avg": 4.0, "rep_delta": 1.0, "by_type": {}})
				if stamp.visible:
					printerr("FAIL 结算面板开着，点评条还压在账目上")
					failures += 1
				room.call("_close_report")
				if not stamp.visible:
					printerr("FAIL 结算关掉后点评条没回来")
					failures += 1
				room.call("_toggle_mail")
				if stamp.visible:
					printerr("FAIL 信箱开着，点评条还压着信")
					failures += 1
				# 让位期间连表一起冻住：信箱不暂停树，照旧走表等于让玩家读封信的功夫烧掉一条点评
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) + 1.0)
				room.call("_toggle_mail")
				if not stamp.visible:
					printerr("FAIL 读信期间把点评条走没了")
					failures += 1
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) + 0.1)
				if stamp.visible:
					printerr("FAIL 点评条读完不收")
					failures += 1
				if failures == before_fail:
					print("OK review: indoor 点评条钉得上、分得出色、压在夜罩之上、面板开着会让位")
			# 飘字与头顶气泡跟点评条同病：留在房间画布里就会被夜罩染暗，这次一并抬到 HUD
			var lift_fail := failures
			var layer: CanvasLayer = room.get("hud")
			room.call("_float_text", Vector2(200, 300), "+30", Color(1.0, 1.0, 1.0))
			var fl: Array = room.get("floats")
			var flop: Node = (fl[fl.size() - 1] as Dictionary).node
			if flop.get_parent() != layer:
				printerr("FAIL 飘字还留在房间画布里: ", flop.get_parent())
				failures += 1
			# 气泡有守卫：挂着台词时本该噤声，不清干净就测不到抬层这一步
			room.set("story_showing", false)
			room.set("story_queue", [])
			room.set("_bubble_left", 0.0)
			room.call("_sync_story_card")
			var pal := Node2D.new()
			room.add_child(pal)
			pal.position = Vector2(120, 260)
			var off: Vector2 = room.get("BUBBLE_OFFSET")
			room.call("_bubble", pal, "水有点烫")
			var bub: Label = room.get("bubble_label")
			if bub == null:
				printerr("FAIL 气泡没贴出来")
				failures += 1
			elif bub.get_parent() != layer:
				printerr("FAIL 气泡还挂在客人身上: ", bub.get_parent())
				failures += 1
			# 挂 HUD 就不再生在客人身上，位置得靠每帧贴；漏了这一步气泡会钉在原地
			elif bub.position != Vector2(120, 260) + off:
				printerr("FAIL 气泡没贴到客人头顶: ", bub.position)
				failures += 1
			else:
				pal.position = Vector2(300, 200)
				room.call("_sync_bubble")
				if bub.position != Vector2(300, 200) + off:
					printerr("FAIL 客人走开气泡没跟上: ", bub.position)
					failures += 1
			# 交接那一帧：第二颗必须换成新宿主，旧气泡的收尾不许把刚接上的那颗摘掉
			var pal2 := Node2D.new()
			room.add_child(pal2)
			pal2.position = Vector2(500, 320)
			room.set("_bubble_left", 0.0)
			room.call("_bubble", pal2, "换人了")
			var bub2: Label = room.get("bubble_label")
			if room.get("bubble_host") != pal2 or bub2 == bub:
				printerr("FAIL 新气泡没接上新宿主")
				failures += 1
			elif bub2.position != Vector2(500, 320) + off:
				printerr("FAIL 新气泡没贴到新宿主头顶: ", bub2.position)
				failures += 1
			if failures == lift_fail:
				print("OK lift: indoor 飘字与气泡抬到夜罩之上，气泡跟着客人走")
		room.queue_free()
	# 贴图迁移：一个物种一旦吃了贴图，六张必须同画布——混进一张程序化图，
	# 迈步时就是两档像素密度来回跳，玩家看到的不是换腿而是整只抖动。
	# 走 load 而不是直接写 Guest：guest.gd 正文引用自动加载，静态引它会崩掉入口脚本
	var guest_script := load("res://scripts/guest.gd") as GDScript
	var tex_fail := failures
	var tex_migrated := 0
	var sit_todo := 0
	for id in GameData.SPECIES.keys():
		if not bool(guest_script.call("uses_ai_tex", String(id))):
			continue
		tex_migrated += 1
		var base: Texture2D = guest_script.call("_tex", String(id), Color.WHITE, "walk")
		for pose in ["stepL", "stepR", "hop", "soak", "rest"]:
			var t: Texture2D = guest_script.call("_tex", String(id), Color.WHITE, pose)
			if t.get_size() != base.get_size():
				printerr("FAIL ", id, " 的 ", pose, " 画布 ", t.get_size(),
						" 与 walk ", base.get_size(), " 不同")
				failures += 1
		# sit 是茶室专用的第七张：缺了只能退回占位 rest（坐着像站着），不该静悄悄
		var sit: Texture2D = guest_script.call("_ai_tex", String(id), "sit")
		if sit == null:
			sit_todo += 1
		elif sit.get_size() != base.get_size():
			printerr("FAIL ", id, " 的 sit 画布 ", sit.get_size(),
					" 与 walk ", base.get_size(), " 不同")
			failures += 1
	if tex_migrated == 0:
		printerr("FAIL 没有任何物种吃到贴图，assets/animals 空了")
		failures += 1
	elif failures == tex_fail:
		var tail := "" if sit_todo == 0 else "，还差 %d 张 sit" % sit_todo
		print("OK tex: ", tex_migrated, " 个物种吃贴图，六张姿态同画布", tail)
	if failures > 0:
		printerr("SELFCHECK FAILED: ", failures)
	else:
		print("SELFCHECK PASSED")
	return 1 if failures > 0 else 0

func _count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count(child)
	return total
