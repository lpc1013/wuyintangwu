class_name StoryArc
## 角色主线：每人一条按顺序讲的五拍链条——起因 / 关系变化 / 事件 / 结果 / 余韵。
##
## 为什么单开一个文件：story.gd 是 `python godot/tools/gen_story.py` 生成的，
## 网页版改文案后重跑生成会把这层覆盖掉，所以主线一律写在这里，由 GameManager
## 在取词时合并——Story 那张表一根手指都不许碰。
##
## 与闲聊池的分别是「顺序」：CHAT 是同池并排抽一条，这里是一格讲完才轮到下一格，
## 没讲到的那一格被 when 拦住时整条链就停住，不许跳着说。
## 拍数存在往来记忆里（就是那条 species 的 seen 表），跨存档、进收藏册，都不用另开字段。
##
## 字段沿用 Story 的形状：id 全局唯一、segments 多段、hint 一律给字典（不许 null）、
## when 只用 GameManager.KNOWN_WHEN_KEYS 里那几个下标。stage 是给闸机与作者看的标签。

## 五拍的名字：闸机按它核对顺序，HUD 的「心事 n/5」按它计数
const STAGES := ["起因", "关系变化", "事件", "结果", "余韵"]

const ARCS := {
	## 小狗·等人的：从「替一个人留日子」走到「自己也成了给别人留灯的那个」
	"shib": [
		{
			"id": "arc-shib-1",
			"beat": 1,
			"stage": "起因",
			"segments": ["「我每天来报到。他说过会来，我就把那天当个日子。」",
					"「日子过了多久我不数。水凉了，我就自己换一池热的。」"],
			"hint": {},
			"when": {"visitsMin": 1}
		},
		{
			"id": "arc-shib-2",
			"beat": 2,
			"stage": "关系变化",
			"segments": ["「今天我没看门口。我看的是你递毛巾的那只手。」",
					"「……先别告诉它。我还没准备好把『等』换成别的什么。」"],
			"hint": {},
			"when": {"visitsMin": 3}
		},
		{
			"id": "arc-shib-3",
			"beat": 3,
			"stage": "事件",
			"segments": ["「你挂的那盏灯，是给人留的门。」",
					"「我认得。我家门口也有一盏，天黑就亮，天亮就灭。」",
					"「昨晚它灭了。我是在这儿，看着你这盏亮到很晚。」"],
			"hint": {},
			"when": {"builtMin": 1}
		},
		{
			"id": "arc-shib-4",
			"beat": 4,
			"stage": "结果",
			"segments": ["「那封信你拆了吧。字是我叼着笔写的，有点歪。」",
					"「上面写：不用等了，他先把你的碗洗好了。」",
					"「我看完就去泡了今天第三池。……汤钱我会付的。」"],
			"hint": {},
			"when": {"lettersRead": 1}
		},
		{
			"id": "arc-shib-5",
			"beat": 5,
			"stage": "余韵",
			"segments": ["「我不等人了。我还是天天来。」",
					"「这两件事，原来一直是同一件。」",
					"「灯给你留着。我那边，往南走两个路口。」"],
			"hint": {"pool": "hot", "trend": "up", "weight": 1.3},
			"when": {"visitsMin": 6}
		},
	],
	## 熊·等春天的：从「每年醒在冬天里」走到「愿意醒着看一次化霜」
	"bear": [
		{
			"id": "arc-bear-1",
			"beat": 1,
			"stage": "起因",
			"segments": ["「我妈说，熊要睡到春天。我每年都醒在冬天里。」",
					"「醒来也没意思，就再睡。睡了又醒，醒了又没意思。」"],
			"hint": {},
			"when": {"visitsMin": 1}
		},
		{
			"id": "arc-bear-2",
			"beat": 2,
			"stage": "关系变化",
			"segments": ["「你这儿的雾是暖的，像我记得里的春天。」",
					"「我把这个记下来了。记下来就不算骗自己。」"],
			"hint": {},
			"when": {"visitsMin": 3}
		},
		{
			"id": "arc-bear-3",
			"beat": 3,
			"stage": "事件",
			"segments": ["「那盆草是真的。我闻了半晚。」",
					"「熊认得草。认得草的熊，不会睡过头。」"],
			"hint": {},
			"when": {"builtMin": 1}
		},
		{
			"id": "arc-bear-4",
			"beat": 4,
			"stage": "结果",
			"segments": ["「信是我托风带来的。只有一句：草发芽的时候我回来。」",
					"「写错了。我现在就在这儿，不用回来。」"],
			"hint": {},
			"when": {"lettersRead": 1}
		},
		{
			"id": "arc-bear-5",
			"beat": 5,
			"stage": "余韵",
			"segments": ["「今年我不睡了。我想看一眼你那口池子怎么化霜。」",
					"「熊要是愿意醒着，冬天也就短一点。」"],
			"hint": {"pool": "herb", "trend": "up", "weight": 1.3},
			"when": {"visitsMin": 6}
		},
	],
}

## 某一位的五拍：没写主线的物种交回空数组，调用方据此落回普通闲聊
static func entries(species_id: String) -> Array:
	return ARCS.get(species_id, [])

static func species_ids() -> Array:
	return ARCS.keys()

static func line_count() -> int:
	var n := 0
	for sp: String in ARCS:
		n += (ARCS[sp] as Array).size()
	return n

static func segment_count() -> int:
	var n := 0
	for sp: String in ARCS:
		for e: Dictionary in ARCS[sp]:
			n += (e.segments as Array).size()
	return n
