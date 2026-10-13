class_name SaveData
## 存档层：只管「这一份 JSON 能不能信」。
## 字段级校验、坏记录逐条丢弃、版本迁移、临时文件＋改名＋备份的原子写入都在这里，
## GameManager 只提供状态本体，不再自己拼 JSON、也不再因为一条脏数据整局报废。

## 存档结构版本。加字段不必升版本（读取侧一律给缺省值）；
## 改了字段含义或删了字段才升，并把它补进 migrate()。
const SCHEMA := 2
const BACKUP_SUFFIX := ".bak"
const TMP_SUFFIX := ".tmp"

## 读盘结果：ok=false 表示这份数据一律不可用（读不到、解析失败、结构不是字典、
## 版本比本程序还新），调用方应当按新档开局，而不是拿半份状态继续跑。
const SOURCE_NONE := ""
const SOURCE_PRIMARY := "primary"
const SOURCE_BACKUP := "backup"

## 校验上下文：房间名册与封顶值由调用方给，存档层不认识场景，也不认识 UI。
## species/pool/facility 三张表是纯数据，直接查 GameData。
static func read(path: String, ctx: Dictionary) -> Dictionary:
	var primary := _read_dict(path)
	if not primary.is_empty() and int(primary.get("schema_version", 1)) <= SCHEMA:
		return {"ok": true, "source": SOURCE_PRIMARY, "data": apply(primary, ctx)}
	var backup := _read_dict(path + BACKUP_SUFFIX)
	if not backup.is_empty() and int(backup.get("schema_version", 1)) <= SCHEMA:
		push_warning("主存档不可用，已回退到上一份备份：" + path)
		return {"ok": true, "source": SOURCE_BACKUP, "data": apply(backup, ctx)}
	if FileAccess.file_exists(path):
		push_warning("存档读不出来，按新档开局：" + path)
	return {"ok": false, "source": SOURCE_NONE, "data": {}}

static func _read_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var out: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	return out

## 校验 + 迁移：认得出来的字段逐个还原，认不出的一律按新档缺省给。
## 返回的字典里每个值都已类型正确，调用方可以直接往状态上贴。
static func apply(raw: Dictionary, ctx: Dictionary) -> Dictionary:
	var migrated := migrate(raw)
	var rooms: Array = ctx.get("rooms", [])
	return {
		"schema_version": SCHEMA,
		"coins": maxi(0, _as_int(migrated.get("coins", 0), 0)),
		"day": maxi(1, _as_int(migrated.get("day", 1), 1)),
		"hour": clampf(_as_float(migrated.get("hour", 9.0), 9.0), 0.0, 24.0),
		"reputation": clampf(_as_float(migrated.get("reputation", 20.0), 20.0), 0.0,
				_ctx_float(ctx, "max_reputation", 100.0)),
		"reviews_total": maxi(0, _as_int(migrated.get("reviews_total", 0), 0)),
		"reviews_good": maxi(0, _as_int(migrated.get("reviews_good", 0), 0)),
		"wishes_done": maxi(0, _as_int(migrated.get("wishes_done", 0), 0)),
		"codex": _known_ids(migrated.get("codex", []), GameData.SPECIES.keys()),
		"facilities": _facilities(migrated.get("facilities", {}), rooms),
		"pool_levels": _levels(migrated.get("pool_levels", {}), rooms,
				int(ctx.get("max_pool_level", 3))),
		"memory": _memory(migrated.get("memory", {})),
		"seen_lines": _seen_lines(migrated.get("seen_lines", {})),
		"forecast": _forecast(migrated.get("forecast", []), int(migrated.get("day", 1))),
		"mailbox": _mailbox(migrated.get("mailbox", []), int(migrated.get("day", 1)),
				int(ctx.get("mailbox_cap", 12))),
		"story_log": _strings(migrated.get("story_log", [])),
		"letters_read": maxi(0, _as_int(migrated.get("letters_read", 0), 0)),
		"chapter": clampi(_as_int(migrated.get("chapter", 0), 0), 0,
				int(ctx.get("max_chapter", 0))),
	}

## 版本迁移：v1 与 v2 的字段布局一致，差的只是结构戳；
## 真出现字段语义变化时，在这里把老字段翻成新字段，别去改读取侧的缺省值。
static func migrate(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	var v := int(data.get("schema_version", 1))
	if v < 2:
		# v1 没写结构戳，字段含义与今天相同，只补戳；坏在下一层校验里逐条处理
		pass
	data["schema_version"] = SCHEMA
	return data

## ---------------- 逐字段校验 ----------------

static func _as_int(v: Variant, def: int) -> int:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	return def

static func _as_float(v: Variant, def: float) -> float:
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	return def

static func _as_bool(v: Variant, def: bool) -> bool:
	return bool(v) if typeof(v) == TYPE_BOOL else def

static func _ctx_float(ctx: Dictionary, key: String, def: float) -> float:
	return _as_float(ctx.get(key, def), def)

## 只收字符串数组；非字符串与空串丢掉。存档里的 id 全是字符串，
## JSON 回读可能是数字，宁可漏一条也不要往状态里塞一个查不到表的键。
static func _strings(v: Variant) -> Array:
	var out: Array = []
	if typeof(v) != TYPE_ARRAY:
		return out
	for e: Variant in v:
		if typeof(e) == TYPE_STRING and String(e) != "":
			out.append(String(e))
	return out

## 限定在已知键里的 id：查不到表的物种、汤种、设施一律丢，重复的只留一份
static func _known_ids(v: Variant, allowed: Array) -> Array:
	var out: Array = []
	for id: String in _strings(v):
		if allowed.has(id) and not out.has(id):
			out.append(id)
	return out

## 已建设施：房间必须在名册里，记录必须带合法设施 id 与有限数值坐标。
## 单条坏记录只丢那一条，不把这间房的其余家具一起陪葬。
static func _facilities(v: Variant, rooms: Array) -> Dictionary:
	var out := {}
	if typeof(v) != TYPE_DICTIONARY:
		return out
	var saved: Dictionary = v
	for room_id: String in saved:
		if not rooms.has(room_id):
			continue
		var list: Array = []
		if typeof(saved[room_id]) != TYPE_ARRAY:
			continue
		for e: Variant in saved[room_id]:
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var item: Dictionary = e
			var id := String(item.get("id", ""))
			if not GameData.FACILITIES.has(id):
				continue
			# 坐标必须是真数：JSON 把数字全读成 float，字符串与 null 都算坏记录
			if typeof(item.get("x", "")) != TYPE_FLOAT and typeof(item.get("x", "")) != TYPE_INT:
				continue
			if typeof(item.get("y", "")) != TYPE_FLOAT and typeof(item.get("y", "")) != TYPE_INT:
				continue
			var x := float(item.x)
			var y := float(item.y)
			if not is_finite(x) or not is_finite(y):
				continue
			list.append({"id": id, "x": int(x), "y": int(y)})
		out[room_id] = list
	return out

static func _levels(v: Variant, rooms: Array, max_level: int) -> Dictionary:
	var out := {}
	if typeof(v) != TYPE_DICTIONARY:
		return out
	var saved: Dictionary = v
	for room_id: String in saved:
		if not rooms.has(room_id) or typeof(saved[room_id]) != TYPE_ARRAY:
			continue
		var list: Array = []
		for e: Variant in saved[room_id]:
			list.append(clampi(_as_int(e, 1), 1, max_level))
		out[room_id] = list
	return out

## 事件与道具台词的已播表：{键: [条目 id]}。这些键不是物种，所以单独一张表校验，
## 只保证里面全是字符串 id
static func _seen_lines(v: Variant) -> Dictionary:
	var out := {}
	if typeof(v) != TYPE_DICTIONARY:
		return out
	var saved: Dictionary = v
	for key_id: String in saved:
		out[key_id] = _strings(saved[key_id])
	return out

## 每只动物的往来记忆：visits 只增不减，arc_stage 由来访次数重算而不是照抄存档，
## 免得有人手改一个 stage 就把主线台词一次性全解锁
static func _memory(v: Variant) -> Dictionary:
	var out := {}
	if typeof(v) != TYPE_DICTIONARY:
		return out
	var saved: Dictionary = v
	for sp: String in saved:
		if not GameData.SPECIES.has(sp) or typeof(saved[sp]) != TYPE_DICTIONARY:
			continue
		var raw: Dictionary = saved[sp]
		var visits := maxi(0, _as_int(raw.get("visits", 0), 0))
		out[sp] = {
			"visits": visits,
			"seen_intro": _as_bool(raw.get("seen_intro", false), false),
			"arc_stage": 2 if visits >= 6 else (1 if visits >= 3 else 0),
			"seen": _strings(raw.get("seen", [])),
		}
	return out

## 风向情报：汤种必须在表里，过期的一律不收——存档里躺着一条已经作废的风向，
## 比没有风向更容易骗到玩家
static func _forecast(v: Variant, today: int) -> Array:
	var out: Array = []
	if typeof(v) != TYPE_ARRAY:
		return out
	for e: Variant in v:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = e
		var pool := String(item.get("pool", ""))
		var until := _as_int(item.get("until", 0), 0)
		if not GameData.POOLS.has(pool) or until < today:
			continue
		out.append({
			"pool": pool,
			"trend": "down" if String(item.get("trend", "up")) == "down" else "up",
			"weight": clampf(_as_float(item.get("weight", 1.0), 1.0), 0.5, 2.0),
			"until": until,
		})
	return out

## 信箱：物种必须在名册里、正文非空、day 是有限整数。
## 超上限时优先淘汰已读的最旧一封，未读的信不许被系统吃掉。
static func _mailbox(v: Variant, today: int, cap: int) -> Array:
	var out: Array = []
	if typeof(v) != TYPE_ARRAY:
		return out
	for e: Variant in v:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = e
		var sp := String(item.get("species", ""))
		var body := String(item.get("body", ""))
		if not GameData.SPECIES.has(sp) or body == "":
			continue
		out.append({
			"id": String(item.get("id", "")),
			"species": sp,
			"title": String(item.get("title", "一封来信")),
			"body": body,
			"day": maxi(1, _as_int(item.get("day", today), today)),
			"hint": item.get("hint", {}) if typeof(item.get("hint", {})) == TYPE_DICTIONARY else {},
			"read": _as_bool(item.get("read", false), false),
		})
	while out.size() > cap:
		# 兜底裁剪：只在存档本身超限才走到这里。淘汰顺序一律先已读的最旧一封，
		# 全是未读时留最新的几封——未拆的信不该被系统划掉，正常投递在 post_letter 就拦下了
		var drop := -1
		for i in out.size():
			if bool(out[i].read):
				drop = i
				break
		if drop < 0:
			for i in out.size():
				if drop == -1 or int(out[i].day) <= int(out[drop].day):
					drop = i
		out.remove_at(drop)
	return out

## ---------------- 写盘 ----------------

## 原子写入：先落到 .tmp，确认写完了再把旧主档挪成备份，最后改名顶上。
## 任何一步失败都留得下可读的那一份——半途断电或磁盘满不该让整局进度归零。
static func write(path: String, data: Dictionary) -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("打不开 user:// 目录，存档没写出去")
		return false
	var tmp := path + TMP_SUFFIX
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("写不出临时存档: %s（错误码 %d）" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	var had_primary := dir.file_exists(path)
	if had_primary:
		if dir.copy(path, path + BACKUP_SUFFIX) != OK:
			push_warning("旧存档备份失败，继续替换主档")
	if dir.remove(path) != OK and had_primary:
		push_error("旧存档挪不开，保留原档不覆盖")
		dir.remove(tmp)
		return false
	if dir.rename(tmp, path) != OK:
		push_error("改名顶上主档失败，尝试从备份还原")
		dir.remove(tmp)
		if had_primary and dir.file_exists(path + BACKUP_SUFFIX):
			dir.copy(path + BACKUP_SUFFIX, path)
		return false
	return true
