class_name GameData
## 从 index.html 迁移的数据表：时段、物种、汤种、功效维度。
## 全部为纯数据 + 静态查表，不含状态；运行时状态在 GameManager。
## 颜色存 #rrggbb 字符串而非 Color，因为 Color(String) 不是常量表达式。

const DAY_SECONDS := 210.0
const EFF_NAMES := {
	"coin": "产币", "joy": "开心", "fame": "声望", "explore": "探索",
	"relax": "放松", "social": "社交", "effcy": "效率", "sign": "招牌",
}

## light = 夜罩强度，income = 该时段收益倍率（夜晚更高）
const PERIODS := [
	{"id": "dawn", "name": "清晨", "from": 5, "to": 7, "light": 0.25, "income": 1.0},
	{"id": "morn", "name": "上午", "from": 7, "to": 10, "light": 0.0, "income": 1.0},
	{"id": "noon", "name": "正午", "from": 10, "to": 13, "light": 0.0, "income": 1.0},
	{"id": "aftn", "name": "午后", "from": 13, "to": 16, "light": 0.06, "income": 1.0},
	{"id": "dusk", "name": "黄昏", "from": 16, "to": 19, "light": 0.22, "income": 1.2},
	{"id": "nite", "name": "夜晚", "from": 19, "to": 23, "light": 0.5, "income": 1.5},
	{"id": "late", "name": "深夜", "from": 23, "to": 29, "light": 0.62, "income": 1.6},
]

## ear: round|point|long|antler|none   tail: stub|curl|fluffy|flat|fin|none
## likes 为偏好席位（契合+，含茶室榻榻米），dislike 为讨厌的汤种（契合-）
const SPECIES := {
	"capy": {"name": "水豚", "ear": "round", "tail": "stub", "size": 1.18,
		"body": "#b07a3e", "belly": "#e2c290", "dark": "#6f4a20",
		"likes": ["hot", "herb", "tatami"], "dislike": "ice", "pay": 14, "perso": "温吞哲学派",
		"names": ["墩墩", "慢郎", "柚柚子", "石石", "温泉守"]},
	"rabb": {"name": "兔子", "ear": "long", "tail": "curl", "size": 0.92,
		"body": "#efe3da", "belly": "#fffaf4", "dark": "#b09a8e",
		"likes": ["milk", "moon", "tatami"], "dislike": "cyber", "pay": 10, "perso": "软乎乎胆小鬼",
		"names": ["雪团", "糯米", "月见", "小跳", "棉花"]},
	"cat3": {"name": "三花猫", "ear": "point", "tail": "curl", "size": 0.95,
		"body": "#f0a95f", "belly": "#fff3e2", "dark": "#8a5a2a", "patch": "#3a3a3a",
		"likes": ["sand", "yuzu"], "dislike": "ice", "pay": 12, "perso": "傲娇品鉴师",
		"names": ["花卷", "琥珀", "三三", "团子", "墨墨"]},
	"shib": {"name": "柴犬", "ear": "point", "tail": "curl", "size": 1.0,
		"body": "#e0913f", "belly": "#fff2dd", "dark": "#8a4f16",
		"likes": ["cyber", "milk"], "dislike": "moon", "pay": 12, "perso": "元气自来熟",
		"names": ["旺财", "豆豆", "大福", "丸子", "阿柴"]},
	"foxe": {"name": "狐狸", "ear": "point", "tail": "fluffy", "size": 1.0,
		"body": "#e86f3a", "belly": "#ffe8d2", "dark": "#8a3a16",
		"likes": ["moon", "yuzu"], "dislike": "sand", "pay": 14, "perso": "神秘夜行者",
		"names": ["绀叶", "小狐", "琥珀丸", "夕雾", "铃音"]},
	"racc": {"name": "浣熊", "ear": "round", "tail": "fluffy", "size": 0.98,
		"body": "#8a8a92", "belly": "#e8e4dc", "dark": "#3a3a44", "mask": true,
		"likes": ["herb", "hot"], "dislike": "milk", "pay": 11, "perso": "搓洗强迫症",
		"names": ["搓搓", "小浣", "灰灰", "桶桶", "夜宵"]},
	"bear": {"name": "棕熊", "ear": "round", "tail": "stub", "size": 1.32,
		"body": "#8a5a30", "belly": "#d8a86a", "dark": "#4e2f14",
		"likes": ["hot", "ice"], "dislike": "moon", "pay": 18, "perso": "憨厚大胃王",
		"names": ["熊岳", "蜜蜜", "大山", "圆滚", "掌掌"]},
	"peng": {"name": "企鹅", "ear": "none", "tail": "fin", "size": 0.95,
		"body": "#3a4a5e", "belly": "#f4f8ff", "dark": "#222c38", "beak": "#ffab3a",
		"likes": ["ice", "cyber"], "dislike": "hot", "pay": 13, "perso": "怕热冒险家",
		"names": ["浮冰", "摇摇", "南极客", "小翼", "冰冰"]},
	"duck": {"name": "小鸭", "ear": "none", "tail": "flat", "size": 0.85,
		"body": "#ffd94a", "belly": "#fff3b8", "dark": "#b8922a", "beak": "#ff8c3a",
		"likes": ["yuzu", "hot"], "dislike": "sand", "pay": 9, "perso": "嘎嘎气氛组",
		"names": ["嘎嘎", "布丁", "小黄", "涟漪", "扁扁"]},
	"ottr": {"name": "水獭", "ear": "round", "tail": "flat", "size": 1.0,
		"body": "#7a5a42", "belly": "#e8d2b4", "dark": "#463020",
		"likes": ["cyber", "hot", "stone"], "dislike": "sand", "pay": 13, "perso": "手拉手睡派",
		"names": ["漂漂", "贝壳", "小捞", "转转", "海藻"]},
	"deer": {"name": "小鹿", "ear": "antler", "tail": "stub", "size": 1.1,
		"body": "#c88a4e", "belly": "#f4e0c0", "dark": "#7a4e22", "spots": true,
		"likes": ["herb", "moon", "tatami"], "dislike": "cyber", "pay": 15, "perso": "林间贵客",
		"names": ["斑斑", "铃兰", "小角", "晨露", "枫叶"]},
	"frog": {"name": "青蛙", "ear": "none", "tail": "none", "size": 0.82,
		"body": "#6abf5a", "belly": "#d8f0c8", "dark": "#3a7a2e",
		"likes": ["herb", "hot"], "dislike": "ice", "pay": 8, "perso": "雨天歌唱家",
		"names": ["呱呱", "荷叶", "跳跳", "雨音", "小青"]},
	"hedg": {"name": "刺猬", "ear": "round", "tail": "stub", "size": 0.9,
		"body": "#c8a878", "belly": "#f0dcb8", "dark": "#6a5644", "spikes": true, "solo": true,
		"likes": ["moss", "herb", "moon"], "dislike": "cyber", "pay": 16, "perso": "独处主义小刺球",
		"names": ["刺刺", "团团", "慢慢", "独独", "小栗"]},
	"rpnd": {"name": "小熊猫", "ear": "round", "tail": "fluffy", "size": 0.96,
		"body": "#d06a3a", "belly": "#f4d8b8", "dark": "#5a2e16", "ring": true, "cheek": true,
		"likes": ["herb", "yuzu", "tatami"], "dislike": "ice", "pay": 13, "perso": "树梢上的午睡派",
		"names": ["红叶", "竹竹", "睡睡", "暖绒", "九圈"]},
	"seal": {"name": "海豹", "ear": "none", "tail": "fin", "size": 1.05,
		"body": "#8aa8c0", "belly": "#e8f4fa", "dark": "#4a6a84", "whisk": true,
		"likes": ["ice", "cyber"], "dislike": "sand", "pay": 13, "perso": "圆滚滚的浮冰常客",
		"names": ["嘟嘟", "浮浮", "浪花", "圆圆", "冰冰"]},
	"coww": {"name": "奶牛", "ear": "round", "tail": "curl", "size": 1.22,
		"body": "#f4f0e8", "belly": "#fff8f0", "dark": "#3a3a44", "horn": true, "spots2": true,
		"likes": ["milk", "hot"], "dislike": "ice", "pay": 15, "perso": "慢悠悠的奶香鉴赏家",
		"names": ["哞哞", "奶盖", "花斑", "青团", "慢慢"]},
	## 以下四只随剧情接入补入：偏好沿用网页版的水色（冷泉/玫瑰/泥浴/气泡泉）
	"panda": {"name": "熊猫", "ear": "round", "tail": "stub", "size": 1.2,
		"body": "#efeade", "belly": "#fdfbf4", "dark": "#2c2a2f",
		"mask": true, "mask_eye": "#f6f3ea", "ear_dark": true,
		"likes": ["ice", "moss"], "dislike": "cyber", "pay": 16, "perso": "退休气象员",
		"names": ["云竹", "阿蒙", "晴雨", "团团子", "北北"]},
	"mouse": {"name": "老鼠", "ear": "round", "tail": "curl", "size": 0.74,
		"body": "#b7b0a8", "belly": "#eae3da", "dark": "#6b6058",
		"likes": ["yuzu", "cyber"], "dislike": "moss", "pay": 9, "perso": "巷口跑腿的",
		"names": ["吱吱", "米粒", "线线", "阿顺", "小跑"]},
	"pig": {"name": "小猪", "ear": "point", "tail": "curl", "size": 1.08,
		"body": "#eba6a6", "belly": "#fbd9d4", "dark": "#a95f66",
		"cheek": true, "snout": "#e08d94",
		"likes": ["sand", "hot"], "dislike": "ice", "pay": 11, "perso": "吃饱就睡",
		"names": ["哼哼", "噜噜", "土豆", "年糕", "泥泥"]},
	"chick": {"name": "小鸡", "ear": "none", "tail": "none", "size": 0.78,
		"body": "#ffe066", "belly": "#fff6c4", "dark": "#c99a2e",
		"beak": "#ff9a3a", "comb": true,
		"likes": ["cyber", "yuzu"], "dislike": "ice", "pay": 8, "perso": "到处认门",
		"names": ["叽叽", "豆芽", "绒毛", "噗噗", "桃子"]},
}

## 步态分档：二十个物种共用一套节拍的话，熊和鸭子就走成了一个样。
## step=步幅倍率（乘 Guest.STEP_PX，决定多久换一次抬脚），speed=移速倍率，
## dip=落脚那一下身子沉几像素，dip_t=沉按住多久（换帧进度），sway=左右摆几像素，
## air=腾空那半拍整只抬几像素，rise=脚掌离地几像素（画进抬腿帧），swing=前爪摆幅，
## frames=一个步序内的姿态轮次。
const GAITS := {
	## 熊、水豚、牛：步子迈得长、走得慢、脚几乎不离地，落地那一下按得久
	"trudge": {"step": 1.35, "speed": 0.78, "dip": 1, "dip_t": 0.45, "sway": 0, "air": 0,
		"rise": 1, "swing": 0, "frames": ["stepL", "stepR"]},
	## 鸭、企鹅、海豹：短步、慢行，身子随两脚交替左右倒
	"waddle": {"step": 0.72, "speed": 0.88, "dip": 1, "dip_t": 0.3, "sway": 1, "air": 0,
		"rise": 2, "swing": 1, "frames": ["stepL", "stepR"]},
	## 猫、狐狸、鹿：脚尖点地，几乎没有落地那一下沉降
	"tiptoe": {"step": 1.0, "speed": 1.16, "dip": 0, "dip_t": 0.28, "sway": 0, "air": 0,
		"rise": 2, "swing": 1, "frames": ["stepL", "stepR"]},
	## 兔子、青蛙：不换腿，两脚一起蹬，半拍里整只离地
	"hop": {"step": 0.9, "speed": 1.05, "dip": 1, "dip_t": 0.25, "sway": 0, "air": 1,
		"rise": 2, "swing": 1, "frames": ["hop", "walk"]},
	## 老鼠、刺猬：碎步急走，步幅小到位移一半就换脚
	"scurry": {"step": 0.55, "speed": 1.3, "dip": 1, "dip_t": 0.2, "sway": 0, "air": 0,
		"rise": 2, "swing": 1, "frames": ["stepL", "stepR"]},
	## 柴犬、浣熊、小熊猫：默认档，也就是原来的那套节奏
	"walk": {"step": 1.0, "speed": 1.0, "dip": 1, "dip_t": 0.28, "sway": 0, "air": 0,
		"rise": 2, "swing": 1, "frames": ["stepL", "stepR"]},
}

## 物种 → 档位；没列出的走默认档 "walk"
const GAIT_OF := {
	"capy": "trudge", "bear": "trudge", "coww": "trudge", "panda": "trudge", "pig": "trudge",
	"duck": "waddle", "peng": "waddle", "chick": "waddle", "ottr": "waddle", "seal": "waddle",
	"cat3": "tiptoe", "foxe": "tiptoe", "deer": "tiptoe",
	"rabb": "hop", "frog": "hop",
	"mouse": "scurry", "hedg": "scurry",
}

## 汤种：cap 为池位容量，coin_gen 决定是否直接产币，daily_cap 为该汤种单日产币上限，solo 表示只接待一位
const POOLS := {
	"hot": {"name": "温泉池", "water": "#7fd4b8", "cap": 4, "coin_gen": true, "daily_cap": 240,
		"eff": {"coin": 2, "joy": 1, "fame": 1, "relax": 3, "social": 1}},
	"milk": {"name": "牛奶浴", "water": "#f7f0e0", "cap": 3, "coin_gen": true, "daily_cap": 180,
		"eff": {"coin": 1, "joy": 3, "fame": 1, "relax": 2, "social": 2}},
	"yuzu": {"name": "柚子汤", "water": "#ffd98a", "cap": 3, "coin_gen": true, "daily_cap": 160,
		"eff": {"coin": 1, "joy": 2, "fame": 2, "relax": 2, "sign": 1}},
	"herb": {"name": "森林药汤", "water": "#6faf7a", "cap": 3, "coin_gen": false,
		"eff": {"joy": 1, "fame": 1, "explore": 2, "relax": 2, "effcy": 1}},
	"ice": {"name": "雪山冰泉", "water": "#9fd8ef", "cap": 3, "coin_gen": false,
		"eff": {"joy": 1, "fame": 1, "explore": 2, "effcy": 2}},
	"sand": {"name": "沙漠砂浴", "water": "#e8b56b", "cap": 4, "coin_gen": true, "daily_cap": 260,
		"eff": {"coin": 3, "joy": 1, "explore": 1, "relax": 1, "sign": 1}},
	"cyber": {"name": "赛博碳酸泉", "water": "#46e6d4", "cap": 4, "coin_gen": true, "daily_cap": 200,
		"eff": {"joy": 2, "fame": 1, "relax": 1, "social": 1, "effcy": 2}},
	"moon": {"name": "月光露汤", "water": "#b9c8ff", "cap": 2, "coin_gen": false,
		"eff": {"joy": 2, "fame": 3, "relax": 2, "sign": 2}},
	"moss": {"name": "苔石独汤", "water": "#86b894", "cap": 1, "coin_gen": false, "solo": true,
		"eff": {"joy": 1, "fame": 1, "explore": 1, "relax": 3}},
	"stone": {"name": "青岩石泉", "water": "#9ad0c8", "cap": 3, "coin_gen": true, "daily_cap": 220,
		"eff": {"coin": 2, "joy": 1, "fame": 1, "explore": 1, "relax": 2}},
	## 茶室榻榻米：不泡水的坐席，靠茶点产币，与温泉池各算各的额度
	"tatami": {"name": "榻榻米茶席", "water": "", "cap": 4, "coin_gen": true, "daily_cap": 150,
		"eff": {"coin": 1, "joy": 1, "relax": 2, "social": 2}},
}

## 设施：w/h 为精灵画布像素（显示时统一按 DISPLAY_SCALE 放大）
## wall_only 只能挂在墙带上；max_count 限制单间数量；snack/photo/nap 为心愿供给标记
const FACILITIES := {
	"lantern": {"name": "纸灯笼", "cost": 30, "w": 16, "h": 20, "wall_only": true, "max_count": 8,
		"eff": {"joy": 1, "fame": 1}, "desc": "只能挂在墙上的暖光灯笼。"},
	"bench": {"name": "木长椅", "cost": 40, "w": 28, "h": 14, "nap": true,
		"eff": {"relax": 1, "joy": 1}, "desc": "客人等位时坐一坐。"},
	"vender": {"name": "零食摊", "cost": 90, "w": 30, "h": 26, "snack": true,
		"eff": {"coin": 1, "joy": 2}, "desc": "想吃零食的客人会来这儿。"},
	"camera": {"name": "拍照角", "cost": 70, "w": 20, "h": 20, "photo": true,
		"eff": {"fame": 1, "joy": 1}, "desc": "想拍照的客人在此留影。"},
	"plant": {"name": "盆栽景", "cost": 35, "w": 16, "h": 20,
		"eff": {"relax": 1}, "desc": "增添绿意，安静治愈。"},
	"bucket": {"name": "木桶架", "cost": 45, "w": 18, "h": 20,
		"eff": {"relax": 1, "joy": 1}, "desc": "备用的杉木桶，散发着木香。"},
	"tea": {"name": "茶点桌", "cost": 60, "w": 26, "h": 14, "nap": true,
		"eff": {"joy": 1, "social": 1}, "desc": "麦茶与团子，自助取用。"},
}
const FACILITY_IDS := ["lantern", "bench", "vender", "camera", "plant", "bucket", "tea"]
const DISPLAY_SCALE := 2

## 席位扩建：每升一级多一个位、在席收益与单日投币额度同步放大
const UPGRADE := {
	"max_level": 3, "base_cost": 120, "cost_step": 1.6,
	"cap_per_level": 1, "income_per_level": 0.18, "budget_per_level": 0.5,
}

## 今日心愿：need 为达成所需的设施标记（缺省表示不依赖设施），fame/coin 为完成后的增益
const WISHES := {
	"snack": {"label": "想吃零食", "need": "vender", "fame": 3, "coin": 6},
	"photo": {"label": "想拍照", "need": "camera", "fame": 3, "coin": 5},
	"tea": {"label": "想喝茶", "need": "tea", "fame": 3, "coin": 5},
	"alone": {"label": "想独处", "fame": 2, "coin": 4},
	"chat": {"label": "想聊天", "fame": 2, "coin": 4},
	"nap": {"label": "想小睡", "need": ["bench", "tea"], "fame": 2, "coin": 4},
}
## 坐着消磨时间才完成得了的心愿：茶室客人只会许这些
const WISH_SEATED := ["tea", "nap", "chat", "alone"]

const REVIEW_LINES := [
	"汤很暖，下次还来。",
	"泡完毛都顺了。",
	"水有点烫，但是舒服。",
	"安静，适合发呆。",
	"人有点多，没泡尽兴。",
	"心愿达成了，今天圆满。",
	"差点意思，想泡的池没排上。",
	"灯影很好看，记了一路。",
]
## 茶室客人不下水，点评里自然也不该抱怨池子排不上
const REVIEW_LINES_LOUNGE := [
	"麦茶是热的，榻榻米也是。",
	"坐了一下午，什么都没想。",
	"团子很软，下次带朋友来。",
	"这里安静，耳朵终于不响了。",
	"坐垫偏硬，膝盖到现在还麻。",
]

static func species_ids() -> Array:
	return SPECIES.keys()

static func species(id: String) -> Dictionary:
	return SPECIES.get(id, {})

## 物种的步态档位：未登记或写错档名一律回落默认档，动画侧不需要再判空
static func gait_of(species_id: String) -> Dictionary:
	return GAITS.get(String(GAIT_OF.get(species_id, "walk")), GAITS["walk"])

static func pool(type_id: String) -> Dictionary:
	return POOLS.get(type_id, {})

static func facility(id: String) -> Dictionary:
	return FACILITIES.get(id, {})

## 设施占地（已按显示倍率放大），供落点校验与幽灵预览共用
static func facility_size(id: String) -> Vector2i:
	var f := facility(id)
	return Vector2i(int(f.get("w", 16)), int(f.get("h", 16))) * DISPLAY_SCALE

## 心愿所需设施：need 允许写成单个 id 或 id 数组，统一成数组返回
static func wish_needs(wish_id: String) -> Array:
	var need: Variant = WISHES.get(wish_id, {}).get("need", [])
	if need is Array:
		return need
	return [need]

## ---------------- 池位扩建：纯算式，状态在 GameManager ----------------

## 从 level 升到 level+1 的造价；位多的大池更贵
static func upgrade_cost(type_id: String, level: int) -> int:
	var u := UPGRADE
	var t := pool(type_id)
	var roomy := 1.0 + 0.25 * float(maxi(0, int(t.get("cap", 2)) - 2))
	var raw := float(u.base_cost) * pow(float(u.cost_step), float(maxi(1, level) - 1)) * roomy
	return int(round(raw))

## 升级后的池位容量：汤种基础位 + 每级赠送位，但不超过池子宽度容得下的位数
static func level_cap(type_id: String, level: int, by_width: int) -> int:
	var extra: int = int(UPGRADE.cap_per_level) * maxi(0, level - 1)
	return clampi(mini(int(pool(type_id).get("cap", 4)) + extra, by_width), 1, by_width)

## 升级后的单日投币额度；不产币的汤种返回 0 表示不设限
static func level_budget(type_id: String, level: int) -> int:
	var base := int(pool(type_id).get("daily_cap", 0))
	if base <= 0 or not bool(pool(type_id).get("coin_gen", false)):
		return 0
	var scaled := float(base) * (1.0 + float(UPGRADE.budget_per_level) * float(maxi(0, level - 1)))
	return int(round(scaled))

static func level_income(level: int) -> float:
	return 1.0 + float(UPGRADE.income_per_level) * float(maxi(0, level - 1))

## 契合度：命中偏好 +1，撞上雷点 -1，其余 0
static func affinity(species_id: String, pool_type: String) -> int:
	var sp := species(species_id)
	if sp.is_empty():
		return 0
	if sp.likes.has(pool_type):
		return 1
	if sp.dislike == pool_type:
		return -1
	return 0

static func period_index_for_hour(hour: int) -> int:
	for i in PERIODS.size():
		var p: Dictionary = PERIODS[i]
		var to: int = p.to
		if to > 24:
			if hour >= p.from or hour < to - 24:
				return i
		elif hour >= p.from and hour < to:
			return i
	return 1

static func color_of(hex_str: String, fallback: Color) -> Color:
	if hex_str.is_empty():
		return fallback
	return Color.from_string(hex_str, fallback)
