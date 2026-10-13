#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""把 godot/tools/_story_dump.json（旧版网页 Spring/index.html 已于 2026-10-13 移除，
该 dump 是当时由 _dump_story.js 求值固化的结案产物，现为文案唯一真相）
生成 godot/scripts/story.gd。

文案一律机械搬运，不做人工誊抄；顺带把网页版的两套词汇翻译成本项目的：
  角色 id → GameData.SPECIES 的物种 id（顶层键直接改写）
  pool-water-* → GameData.TYPES 的汤种 id（hint.pool 就地改写）
重跑：python godot/tools/gen_story.py（dump 已固化；若要重建 dump 才需 node _dump_story.js，而那依赖已移除的 Spring/index.html）
"""
import io
import json
import collections

SRC = "godot/tools/_story_dump.json"
OUT = "godot/scripts/story.gd"

# 网页版英文名 → 本项目物种 id。原 12 只 + 扩员的 10 只 + 最后补上台词的 8 只，
# 全名册三十只都登记在这张表里；漏一只，channel_table 就在裸下标上 KeyError。
ACTOR_TO_SPECIES = {
	"fox": "foxe", "panda": "panda", "mouse": "mouse", "cat": "cat3",
	"dog": "shib", "rabbit": "rabb", "pig": "pig", "penguin": "peng",
	"frog": "frog", "hedgehog": "hedg", "bear": "bear", "chick": "chick",
	"sloth": "slth", "hippo": "hipp", "koala": "koal", "swan": "swan", "owl": "owly",
	"turtle": "turt", "octopus": "octo", "squirrel": "sqrl", "badger": "badg", "goat": "goat",
	"capybara": "capy", "raccoon": "racc", "duck": "duck", "otter": "ottr", "deer": "deer",
	"redpanda": "rpnd", "seal": "seal", "cow": "coww",
}
# 网页版 8 种水色 → 本作 11 种汤：按体感就近归并。
# 温汤/红汤都是普通热池，合成温泉池；冷泉归雪山冰泉；气泡泉正是碳酸泉；泥浴与砂浴同为「埋进介质干泡」。
WATER_TO_TYPE = {
	"pool-water-blue": "hot", "pool-water-stone": "ice", "pool-water-red": "hot",
	"pool-water-green": "herb", "pool-water-milk": "milk", "pool-water-rose": "yuzu",
	"pool-water-carbon": "cyber", "pool-water-mud": "sand",
}
# 这几个频道按角色索引，其余（surprise/propStory）按事件索引，不改写顶层键
BY_ACTOR = ["profiles", "intro", "chat", "letter", "grumble", "farewell", "murmur"]


def lit(v, indent):
	"""把 JSON 值渲染成 GDScript 字面量；dict/array 展开多行，标量原样。"""
	if isinstance(v, dict):
		if not v:
			return "{}"
		pad = "\t" * (indent + 1)
		items = ["%s%s: %s" % (pad, key(k), lit(x, indent + 1)) for k, x in v.items()]
		return "{\n" + ",\n".join(items) + "\n" + "\t" * indent + "}"
	if isinstance(v, list):
		if not v:
			return "[]"
		if all(not isinstance(x, (dict, list)) for x in v):
			return "[" + ", ".join(lit(x, indent) for x in v) + "]"
		pad = "\t" * (indent + 1)
		return "[\n" + ",\n".join(pad + lit(x, indent + 1) for x in v) + "\n" + "\t" * indent + "]"
	if v is None:
		return "null"
	if isinstance(v, bool):
		return "true" if v else "false"
	if isinstance(v, (int, float)):
		return repr(v)
	return js_string(v)


## GDScript 的字典字面量只认字符串键：写成裸标识符会被当成变量引用，
## 报错却落在「使用 Story.CHAPTERS 的那一行」，离坏掉的文件隔着一整个模块。
def key(k):
	return js_string(k)


def js_string(s):
	out = s.replace("\\", "\\\\").replace('"', '\\"')
	out = out.replace("\r\n", "\\n").replace("\n", "\\n").replace("\t", "\\t")
	return '"' + out + '"'


def translate(entry):
	"""条目里只有 hint 需要换词汇与换表示：pool 换成本作汤种 id；
	网页版用 null 表示「这条不带风向」，本作 apply_hint 的形参是 Dictionary，
	原样搬过去就是读信时一句 Invalid argument，故归一成空字典。when 同理。"""
	for field in ("hint", "when"):
		if entry.get(field) is None:
			entry[field] = {}
	h = entry.get("hint")
	if isinstance(h, dict) and h.get("pool") in WATER_TO_TYPE:
		h["pool"] = WATER_TO_TYPE[h["pool"]]
	return entry


def channel_table(name, table):
	out = collections.OrderedDict()
	for actor, val in table.items():
		k = ACTOR_TO_SPECIES[actor] if name in BY_ACTOR else actor
		if name == "profiles":
			out[k] = val
		else:
			out[k] = [translate(e) for e in val]
	return out


# 网页版 minReputation 是它自己那套分数，这里按关卡给的三档就近折算成本作 0..5 的店铺星级
REP_TO_STAR = {2: 1, 5: 3, 10: 4}


def _chapters(levels):
	"""网页版每关的 target 是「本关内」的接待数，直接当门槛会让第 2 章比第 1 章还低；
	本作没有分关存档，故按累计接待人数换算，星级要求取本关自带信号并强制单调。"""
	out = []
	cum = 0
	star = 0
	for l in levels:
		t = l["target"]
		cum += int(t["guests"])
		want = max(star, int(t.get("starTarget", 0)), REP_TO_STAR.get(int(t.get("minReputation", 0)), 0))
		star = want
		out.append({"id": int(l["id"]), "name": l["name"], "guests": cum, "star": star})
	return out


def main():
	dump = json.load(io.open(SRC, encoding="utf-8"))
	db = dump["STORY_DB"]
	lines = [
		"class_name Story",
		"## 叙事数据层：全部文案由 godot/tools/gen_story.py 从 _story_dump.json 的 STORY_DB 机械生成，",
		"## dump 源自旧版网页 Spring/index.html（该目录 2026-10-13 已移除，不再可重建），",
		"## 且已落后本文件（缺 PROPCHAT 等后补块）：重跑会覆盖丢失，故默认勿重跑，改剧情直接改本文件。",
		"",
		"## 网页版角色 → 本项目物种：狐狸/熊猫/老鼠/猫/小狗/兔子/猪/企鹅/青蛙/刺猬/熊/小鸡",
		"## 其中 panda、mouse、pig、chick 是随叙事补进 GameData.SPECIES 的四只",
		"## STORY_DB_EXT 再收其余十八只（十只扩员新面孔 + 八只原本沉默的老角色），至此名册三十只全有台词；",
		"## 英文名到物种 id 的对照只有一处真相，就是 gen_story.py 的 ACTOR_TO_SPECIES，这里不再抄一遍",
		"## 网页版 8 种水色就近归并进本作 11 种汤：冷泉→雪山冰泉，玫瑰→柚子汤，气泡泉→赛博碳酸泉，泥浴→沙漠砂浴，温汤与红汤同为温泉池",
		"",
	]
	for name in ["profiles", "intro", "chat", "letter", "grumble", "farewell",
			"surprise", "propStory", "murmur"]:
		const = {"propStory": "PROP_STORY"}.get(name, name.upper())
		table = channel_table(name, db[name])
		if name == "profiles":
			lines.append("## %d 只角色的档案" % len(table))
		else:
			lines.append("## %d 条" % sum(len(v) for v in table.values()))
		lines.append("const %s := %s" % (const, lit(table, 0)))
		lines.append("")
	chapters = _chapters(dump["LEVELS"])
	lines.append("## 主线阶梯：沿用网页版 15 关的关卡名，达成条件改由本作已有的经营事实驱动")
	lines.append("const CHAPTERS := %s" % lit(chapters, 0))
	lines.append("")
	lines.append("""
## 频道名 → 数据表；room_view 与 GameManager 只认这几个键
static func channel(id: String) -> Dictionary:
	match id:
		"intro":
			return INTRO
		"chat":
			return CHAT
		"letter":
			return LETTER
		"grumble":
			return GRUMBLE
		"farewell":
			return FAREWELL
		"surprise":
			return SURPRISE
		"prop":
			return PROP_STORY
		"murmur":
			return MURMUR
	return {}

## 取某只动物（或某个事件键）在某频道下的全部候选条目
static func entries(channel_id: String, key_id: String) -> Array:
	return channel(channel_id).get(key_id, [])

## 角色档案；没有档案的物种返回空字典
static func profile(species: String) -> Dictionary:
	return PROFILES.get(species, {})

## 八张台词表。收藏进度的分母、以及「哪些频道存在」都只从这里算，
## 免得 room_view / GameManager 各自抄一份频道清单，早晚和 channel() 走散
static func channels() -> Array:
	return [INTRO, CHAT, LETTER, GRUMBLE, FAREWELL, SURPRISE, PROP_STORY, MURMUR]

## 台词总条数（不含档案）：玩家读过的条数拿它当分母
static func line_count() -> int:
	var n := 0
	for table: Dictionary in channels():
		for key_id: String in table:
			n += (table[key_id] as Array).size()
	return n

## 惊喜事件键：surprise 表按事件索引，不按角色索引
static func event_ids() -> Array:
	return SURPRISE.keys()

## 条目正文：segments 多段连播优先于单条 text
static func segments(entry: Dictionary) -> Array:
	if entry.has("segments"):
		return entry.segments as Array
	return [String(entry.get("text", ""))]
""")
	io.open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
	total = sum(sum(len(v) for v in db[c].values()) for c in db if c != "profiles")
	print("wrote %s: %d 条文案 + %d 章" % (OUT, total, len(chapters)))


main()
