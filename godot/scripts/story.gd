class_name Story
## 叙事数据层：全部文案由 godot/tools/gen_story.py 从 Spring/index.html 的 STORY_DB 机械生成，
## 要改剧情请改网页版再重跑生成脚本，别在这里手改——手改的那部分下次生成会被覆盖。
## 生成命令：node godot/tools/_dump_story.js && python godot/tools/gen_story.py

## 网页版角色 → 本项目物种：狐狸/熊猫/老鼠/猫/小狗/兔子/猪/企鹅/青蛙/刺猬/熊/小鸡
## 其中 panda、mouse、pig、chick 是随叙事补进 GameData.SPECIES 的四只
## 网页版 8 种水色就近归并进本作 11 种汤：冷泉→雪山冰泉，玫瑰→柚子汤，气泡泉→赛博碳酸泉，泥浴→沙漠砂浴，温汤与红汤同为温泉池

## 12 只角色的档案
const PROFILES := {
	"foxe": {
		"name": "狐狸",
		"nickname": "消息贩子",
		"hintRate": 0.55,
		"confidence": 0.7,
		"arc": null
	},
	"panda": {
		"name": "熊猫",
		"nickname": "退休气象员",
		"hintRate": 0.35,
		"confidence": 0.95,
		"arc": null
	},
	"mouse": {
		"name": "老鼠",
		"nickname": "跑腿的",
		"hintRate": 0.4,
		"confidence": 0.5,
		"arc": null
	},
	"cat3": {
		"name": "猫",
		"nickname": "老常客",
		"hintRate": 0.3,
		"confidence": 0.6,
		"arc": null
	},
	"shib": {
		"name": "小狗",
		"nickname": "等人的",
		"hintRate": 0.25,
		"confidence": 0.7,
		"arc": "wait"
	},
	"rabb": {
		"name": "兔子",
		"nickname": "一直在紧张",
		"hintRate": 0.25,
		"confidence": 0.6,
		"arc": null
	},
	"pig": {
		"name": "猪",
		"nickname": "吃饱就睡",
		"hintRate": 0.25,
		"confidence": 0.6,
		"arc": null
	},
	"peng": {
		"name": "企鹅",
		"nickname": "远道来的",
		"hintRate": 0.2,
		"confidence": 0.8,
		"arc": null
	},
	"frog": {
		"name": "青蛙",
		"nickname": "看天的",
		"hintRate": 0.2,
		"confidence": 0.75,
		"arc": null
	},
	"hedg": {
		"name": "刺猬",
		"nickname": "不爱说话的",
		"hintRate": 0.2,
		"confidence": 0.8,
		"arc": null
	},
	"bear": {
		"name": "熊",
		"nickname": "等春天的",
		"hintRate": 0.15,
		"confidence": 0.85,
		"arc": "spring"
	},
	"chick": {
		"name": "小鸡",
		"nickname": "第一次来",
		"hintRate": 0.15,
		"confidence": 0.5,
		"arc": null
	}
}

## 12 条
const INTRO := {
	"peng": [
		{
			"id": "penguin-i1",
			"segments": ["企鹅拖着一只旧行李箱进来，箱角结着盐霜。", "它在门口停了很久，反复确认真的可以进来。", "「我走了四十天。……那我就，稍微待一会儿。」"],
			"hint": {},
			"when": {}
		}
	],
	"panda": [
		{
			"id": "panda-i1",
			"segments": ["熊猫在门口抬头看了很久的天。", "「气象台退休三年了。看天这毛病改不掉。」", "「我不算命。我只是早半天知道风往哪边吹。」"],
			"hint": {},
			"when": {}
		}
	],
	"bear": [
		{
			"id": "bear-i1",
			"segments": ["熊在门口跺掉脚上的雪。", "「我睡过了头。醒来发现春天还没来。」", "「那就先泡个澡。等到哪天我不来了，就是等到了。」"],
			"hint": {},
			"when": {}
		}
	],
	"foxe": [
		{
			"id": "fox-i1",
			"segments": ["狐狸把尾巴甩了甩，四处扫了一圈。", "「这地方我熟。我不白来——我带消息。」", "「我说的话你听七成就好。剩下三成我留着下次卖。」"],
			"hint": {},
			"when": {}
		}
	],
	"cat3": [
		{
			"id": "cat-i1",
			"segments": ["猫熟门熟路地跳上台阶。", "「这家店我来过。上一个老板泡坏了我的胡子。」", "「换老板了？行吧。我给你三次机会。」"],
			"hint": {},
			"when": {}
		}
	],
	"shib": [
		{
			"id": "dog-i1",
			"segments": ["小狗坐在门口，尾巴规规矩矩地收着。", "「我不是来泡澡的。我是来等人的。」", "「他说过要带我来。所以我先来了，先替他看看。」"],
			"hint": {},
			"when": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-i1",
			"segments": ["兔子在门口停住，先往左看，再往右看。", "「出口在哪、水多深、有没有大声的客人。」", "「三样都确认完，我才敢下水。……好，可以了。」"],
			"hint": {},
			"when": {}
		}
	],
	"frog": [
		{
			"id": "frog-i1",
			"segments": ["青蛙一进门就趴在窗台上。", "「今晚有雨。呱——我从来没看错过。」", "「我不是来泡澡的，是来避雨的。顺便泡个澡。」"],
			"hint": {},
			"when": {}
		}
	],
	"pig": [
		{
			"id": "pig-i1",
			"segments": ["猪一屁股坐在长凳上。", "「我没什么追求。吃饱、泡热、睡着，一天就成了。」", "「上次在别家穿走了别人的浴衣。人家追我两条街。」"],
			"hint": {},
			"when": {}
		}
	],
	"chick": [
		{
			"id": "chick-i1",
			"segments": ["小鸡站在门槛前犹豫了很久。", "「叽……我第一次来这种地方。要脱毛吗？」", "「他们说泡温泉会长个子。是真的吗？」"],
			"hint": {},
			"when": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-i1",
			"segments": ["刺猬在角落缩成一团，半天才伸出一根鼻子。", "「……我不占地方。别靠太近。」", "「不是嫌你，是我怕扎着你。」"],
			"hint": {},
			"when": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-i1",
			"segments": ["老鼠从门缝底下钻进来，抖了抖胡子。", "「跑腿的，全城都跑。什么风声我都听得见。」", "「消息不保真，但便宜——一碗热水就够了。」"],
			"hint": {},
			"when": {}
		}
	]
}

## 72 条
const CHAT := {
	"foxe": [
		{
			"id": "fox-c1",
			"text": "「冷泉那边最近热闹得很，我劝你水备足点。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.7
			},
			"when": {}
		},
		{
			"id": "fox-c2",
			"text": "「牛奶浴？最近没什么人提。你自己掂量。」",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "fox-c3",
			"text": "「我上回在别家把浴衣拿错了，穿回去才发现是只熊的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "fox-c4",
			"text": "「老板，你这店缺的不是池子，是会说话的人。比如我。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "fox-c5",
			"text": "「我听见雪底有响动。顺便的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "fox-c6",
			"text": "「药草那边我劝你别囤。风头过了。」",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		}
	],
	"panda": [
		{
			"id": "panda-c1",
			"text": "「气压在降。这种时候，怕冷的会成群结队地来。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.8
			},
			"when": {}
		},
		{
			"id": "panda-c2",
			"text": "「药草汤那边这两天会清净些，我不会看错。」",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.7
			},
			"when": {}
		},
		{
			"id": "panda-c3",
			"text": "「退休了才明白，天气不需要人预报，它自己会来。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "panda-c4",
			"text": "「你信我一次。信错了，我下次给你补一条。」",
			"when": {
				"visitsMin": 2
			},
			"hint": {}
		},
		{
			"id": "panda-c5",
			"text": "「我算过，竹子只嚼出一小半。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "panda-c6",
			"text": "「气泡那边的热气散了。明后天会冷清。」",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-c1",
			"text": "「吱！我听巷口那帮家伙说，气泡泉最近特别抢手。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "mouse-c2",
			"text": "「泥浴？没人提，一个字都没有。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "mouse-c3",
			"text": "「我跑腿的时候顺走过一件浴衣。不是故意的，真的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "mouse-c4",
			"text": "「红汤那边今天静。一个字都没听见。」",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.82
			},
			"when": {}
		},
		{
			"id": "mouse-c5",
			"text": "「吱，我认路靠胡子。眼睛不太行。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "mouse-c6",
			"text": "「我送信从不留名。怕人认出来。」",
			"hint": {},
			"when": {}
		}
	],
	"cat3": [
		{
			"id": "cat-c1",
			"text": "「我今天来的路上，看见三只往玫瑰汤那边走。三只。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "cat-c2",
			"text": "「别摸我头。摸背。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "cat-c3",
			"text": "「你这店比上个月像样多了。别得意，我只是随口一说。」",
			"when": {
				"visitsMin": 4
			},
			"hint": {}
		},
		{
			"id": "cat-c4",
			"text": "「我喘得响。……对骨头好。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "cat-c5",
			"text": "「冷泉那边空着。我路过看的。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.82
			},
			"when": {}
		},
		{
			"id": "cat-c6",
			"text": "「我不认人。我认水温。」",
			"hint": {},
			"when": {}
		}
	],
	"shib": [
		{
			"id": "dog-c1",
			"text": "「汪！今天他也没来。没关系，我明天再来。」",
			"when": {
				"arcStage": 0
			},
			"hint": {}
		},
		{
			"id": "dog-c2",
			"text": "「你要是看见一个穿灰外套的人……算了。」",
			"when": {
				"arcStage": 1
			},
			"hint": {}
		},
		{
			"id": "dog-c3",
			"text": "「今天不等了。今天是来找你的。」",
			"when": {
				"arcStage": 2
			},
			"hint": {}
		},
		{
			"id": "dog-c4",
			"text": "「今天门口一股奶味！来的都往那边去了！」",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "dog-c5",
			"text": "「石头那边今天有味道。热闹。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "dog-c6",
			"text": "「你身上有别家店的味道。汪。」",
			"hint": {},
			"when": {}
		}
	],
	"bear": [
		{
			"id": "bear-c1",
			"text": "「还没到春天。我摸过外面的石头，还是凉的。」",
			"when": {
				"arcStage": 0
			},
			"hint": {}
		},
		{
			"id": "bear-c2",
			"text": "「今天的石头有一点点温了。一点点。」",
			"when": {
				"arcStage": 1
			},
			"hint": {}
		},
		{
			"id": "bear-c3",
			"text": "「我闻到草味了。老板……我可能快不来了。」",
			"when": {
				"arcStage": 2
			},
			"hint": {}
		},
		{
			"id": "bear-c4",
			"text": "「有泡泡那个池子，今天吵得我睡不着。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "bear-c5",
			"text": "「我睡一冬，火还没点着。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "bear-c6",
			"text": "「玫瑰那边今天不香了。人也少。」",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		}
	],
	"peng": [
		{
			"id": "penguin-c1",
			"text": "「热水原来是这种感觉。像被人抱住，但不那么紧。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "penguin-c2",
			"text": "「红汤那边我不敢靠近。可客人一直往那儿去。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.6
			},
			"when": {}
		},
		{
			"id": "penguin-c3",
			"text": "「四十天。走完才发现，最难的不是冷，是一个人。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "penguin-c4",
			"text": "「我脚蹼是热的。别摸。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "penguin-c5",
			"text": "「药草那边今天很挤。我没挤进去。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.45
			},
			"when": {}
		},
		{
			"id": "penguin-c6",
			"text": "「我行李箱里没东西了。全是盐。」",
			"hint": {},
			"when": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-c1",
			"text": "「我这个位置能看见药草那边。今天满了。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "rabbit-c2",
			"text": "「我先看了一眼出口。就一眼。然后就不想走了。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "rabbit-c3",
			"text": "「你说话一直很小声。我发现了。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "rabbit-c4",
			"text": "「泥那边我数了。今天十一个。」",
			"hint": {
				"pool": "sand",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "rabbit-c5",
			"text": "「我今天只检查了两样。少了一样。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "rabbit-c6",
			"text": "「我数了三遍，冷泉那边一个都没有。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		}
	],
	"frog": [
		{
			"id": "frog-c1",
			"text": "「要下雨了。雨天花香散不掉，玫瑰那边会挤。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "frog-c2",
			"text": "「呱。人类总说我吵，可我只是在念天气。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-c3",
			"text": "「你听——屋檐在滴水了。我说什么来着。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-c4",
			"text": "「气泡那边今晚会满。呱，信我。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "frog-c5",
			"text": "「云走得慢，雨就下得久。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-c6",
			"text": "「红汤那边热气冲得高。明天会散。」",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		}
	],
	"pig": [
		{
			"id": "pig-c1",
			"text": "「我找泥找到药草那头，人多得下不去脚。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "pig-c2",
			"text": "「我没衣服可拿错。我羡慕你们有。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "pig-c3",
			"text": "「吃饱、泡热、睡着。你看我像不像已经赢了？」",
			"hint": {},
			"when": {}
		},
		{
			"id": "pig-c4",
			"text": "「牛奶那边今天淡。我闻得出来。」",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.82
			},
			"when": {}
		},
		{
			"id": "pig-c5",
			"text": "「气泡泉今天挤。挤到我都进不去。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "pig-c6",
			"text": "「我睡着的时候，你别叫醒我。」",
			"hint": {},
			"when": {}
		}
	],
	"chick": [
		{
			"id": "chick-c1",
			"text": "「叽！气泡在挠我脚底，好痒好痒！」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "chick-c2",
			"text": "「我长高了吗？你看，我踮脚了。」",
			"when": {
				"visitsMin": 2
			},
			"hint": {}
		},
		{
			"id": "chick-c3",
			"text": "「泥那边好多客人在打滚，我也想去！」",
			"hint": {
				"pool": "sand",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "chick-c4",
			"text": "「我认准第一个动的。改不了。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "chick-c5",
			"text": "「玫瑰那边好香！好多人在排！」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "chick-c6",
			"text": "「叽，我把毛数了一遍。数丢了。」",
			"hint": {},
			"when": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-c1",
			"text": "「……药草味。挺好的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "hedgehog-c2",
			"text": "「奶白那边今天排到门口。我等不了，走开了。」",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "hedgehog-c3",
			"text": "「你这次没让我等。我记住了。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "hedgehog-c4",
			"text": "「我的刺是头发。硬了点。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "hedgehog-c5",
			"text": "「我身上这些才是我的衣服。勾不掉，也拿不错。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "hedgehog-c6",
			"text": "「泥那边今天空。……我去了。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		}
	]
}

## 30 条
const LETTER := {
	"foxe": [
		{
			"id": "fox-l1",
			"title": "狐狸的便条",
			"body": "老板：\n上次那条消息，你要是听了，这会儿应该已经赚回来了。\n下一阵风还是往冷泉那边刮，我只说到这儿。\n——不署名的那位",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "fox-l2",
			"title": "狐狸的第二封",
			"body": "老板：\n牛奶浴那边最近静得反常。静得反常，通常不是好事，也不是坏事。\n你自己判断。\n——你懂的",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "fox-l3",
			"title": "狐狸的第三封",
			"body": "老板：\n泥那边我去踩过了，脚拔不出来。\n拔不出来的意思是，去的人多。\n这条你别到处说，说了就不值钱了。\n——还是不署名",
			"hint": {
				"pool": "sand",
				"trend": "up",
				"weight": 1.45
			},
			"when": {}
		}
	],
	"panda": [
		{
			"id": "panda-l1",
			"title": "一封手写的天气预报",
			"body": "老板：\n我在窗前坐了一夜。北边的云散了，接下来几天会转凉。\n转凉的时候，怕冷的会成群往热的地方去。\n这不是算命，是习惯。\n——熊猫",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.6
			},
			"when": {}
		},
		{
			"id": "panda-l2",
			"title": "退休气象员的补记",
			"body": "老板：\n上一封写得急，漏了一条：药草那边这几日会淡下去。\n淡下去也没什么不好，人少的池子，水最干净。\n——熊猫",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "panda-l3",
			"title": "气象员的更正",
			"body": "老板：\n我要收回半句话。\n暖锋来得比我算的早，红汤那边这几天会松下来。\n算错了就是算错了，我不给自己找台阶。\n——熊猫",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.72
			},
			"when": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-l1",
			"title": "皱巴巴的小纸条",
			"body": "老板！\n巷口都在传，有泡泡的那种池子最近特别火。\n我不保真啊，我就是个跑腿的。\n（这张纸是我捡的，别嫌）",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "mouse-l2",
			"title": "老鼠的道歉信",
			"body": "老板：\n上次那件浴衣真的不是我故意拿的。\n我已经洗干净了，但我找不到还回去的路。\n对不起。也谢谢你没报官。",
			"hint": {},
			"when": {}
		}
	],
	"cat3": [
		{
			"id": "cat-l1",
			"title": "猫的通知",
			"body": "我下次还来。\n不是因为你，是因为水温。\n顺便说一句，玫瑰那边最近一点动静都没有。\n（不用回信）",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "cat-l2",
			"title": "猫的第二封通知",
			"body": "三次机会用完了。\n结论：你可以继续开下去。\n（还是不用回信）",
			"hint": {},
			"when": {}
		},
		{
			"id": "cat-l3",
			"title": "猫的第三封通知",
			"body": "浴衣的事，大家心照不宣。挺好。\n我谁都没问，也不打算问。\n（这封也不用回信）",
			"hint": {},
			"when": {}
		}
	],
	"shib": [
		{
			"id": "dog-l1",
			"title": "小狗写的信",
			"body": "老板：\n今天他还是没来。\n但你给我留了靠窗的位子，我看见门口了。\n谢谢你。明天我还来。",
			"hint": {},
			"when": {}
		},
		{
			"id": "dog-l2",
			"title": "小狗的第二封信",
			"body": "老板：\n我把等他这件事，慢慢变成了来这里这件事。\n明天见。",
			"hint": {},
			"when": {}
		}
	],
	"bear": [
		{
			"id": "bear-l1",
			"title": "熊的一页纸",
			"body": "老板：\n外面还是凉的。我把手按在石头上，能按出一个白印子。\n有泡泡那边响了一整夜。我数着数着就睡着了。\n——还在等的那只",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "bear-l2",
			"title": "熊的最后一页",
			"body": "老板：\n我闻到草了。\n今年可能真的要来了。\n如果哪天我没出现，别找我，那是好消息。",
			"hint": {},
			"when": {}
		},
		{
			"id": "bear-l3",
			"title": "熊的一张便条",
			"body": "老板：\n药草那边这两天热气很足，隔着门都闻得到。\n闻得到的时候，人就会往那儿走。\n我不常说这些，这次算例外。",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.45
			},
			"when": {}
		},
		{
			"id": "bear-l4",
			"title": "熊的最后一封",
			"body": "老板：\n草味是真的了。\n春天到了，池边我留着。\n就这样。",
			"hint": {},
			"when": {}
		}
	],
	"peng": [
		{
			"id": "penguin-l1",
			"title": "带着盐味的信",
			"body": "老板：\n回程走了三十九天，比来时快了一天。\n路上那处泥池空着，一个客人都没有。\n你的店，我会跟同乡讲。",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "penguin-l2",
			"title": "企鹅的短信",
			"body": "老板：\n我把那天的水温记在本子上了。\n以后走不动的时候，就翻出来看看。",
			"hint": {},
			"when": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-l1",
			"title": "兔子的字条",
			"body": "老板：\n我数了一下，今天有六个客人往玫瑰那边去。\n我也不知道我为什么要数。\n就是忍不住。",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "rabbit-l2",
			"title": "兔子的第二张字条",
			"body": "老板：\n今天我没看出口。\n我自己也吓了一跳。\n下次我试试连水深也不量。",
			"hint": {},
			"when": {}
		}
	],
	"frog": [
		{
			"id": "frog-l1",
			"title": "湿了一角的信",
			"body": "老板：\n我说过会下雨吧。\n雨停接着冷两天。冷起来，凉水那边就空了。\n呱。",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		},
		{
			"id": "frog-l2",
			"title": "青蛙的第二封",
			"body": "老板：\n屋檐修一修吧，滴水的节奏乱了，我念不准天气了。",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-l3",
			"title": "青蛙的第三封",
			"body": "老板：\n雨停了，天要闷。\n一闷起来，奶白那种稠的水反倒有人排。\n我念天气从没错过。呱。",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		}
	],
	"pig": [
		{
			"id": "pig-l1",
			"title": "油乎乎的一封",
			"body": "老板：\n我找泥找到了石头那边。泥没有，客人排到门外。\n（这封信被我压在饭盒底下了，请见谅）",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "pig-l2",
			"title": "猪的检讨",
			"body": "老板：\n关于浴衣的事。\n我已经不会再拿错了，因为你把柜子拆了。\n谢谢你用这种方式原谅我。",
			"hint": {},
			"when": {}
		}
	],
	"chick": [
		{
			"id": "chick-l1",
			"title": "歪歪扭扭的信",
			"body": "老板：\n我量了！我长高了半根手指！\n红色那个池子好多客人排队，我不敢过去。\n（这封信是我自己写的，没让人帮忙）",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "chick-l2",
			"title": "小鸡的问题",
			"body": "老板：\n上次忘了问——泡温泉真的会长个子吗？\n如果不会，你也不用告诉我。",
			"hint": {},
			"when": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-l1",
			"title": "很短的一封信",
			"body": "老板：\n有泡泡那边今天没人。我在旁边坐了很久。\n就这些。\n（信封上有个小洞，是我扎的，抱歉）",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "hedgehog-l2",
			"title": "刺猬的第二封",
			"body": "老板：\n你上次没催我。\n我想说的就这一句。",
			"hint": {},
			"when": {}
		}
	]
}

## 24 条
const GRUMBLE := {
	"foxe": [
		{
			"id": "fox-gru-1",
			"text": "「……你是故意的吗。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "fox-gru-2",
			"text": "「等着也行。我顺便看看谁来了。」",
			"hint": {},
			"when": {}
		}
	],
	"panda": [
		{
			"id": "panda-gru-1",
			"text": "「这水温我没预报过。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "panda-gru-2",
			"text": "「不急。我等过更久的云。」",
			"hint": {},
			"when": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-gru-1",
			"text": "「吱！这不是我说的那个池子。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "mouse-gru-2",
			"text": "「我腿短。你别嫌我挪得慢。」",
			"hint": {},
			"when": {}
		}
	],
	"cat3": [
		{
			"id": "cat-gru-1",
			"text": "「我胡子又要泡坏了。第二次了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "cat-gru-2",
			"text": "「我不是在催。我只是坐在这里看着。」",
			"hint": {},
			"when": {}
		}
	],
	"shib": [
		{
			"id": "dog-gru-1",
			"text": "「汪……这个不对。我记得不是这个。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "dog-gru-2",
			"text": "「排队我在行。这个我真在行。」",
			"hint": {},
			"when": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-gru-1",
			"text": "「水深不对。我量过的，不对。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "rabbit-gru-2",
			"text": "「我又把出口看了一遍。第四遍。」",
			"hint": {},
			"when": {}
		}
	],
	"pig": [
		{
			"id": "pig-gru-1",
			"text": "「这水太干净了。我洗不脏。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "pig-gru-2",
			"text": "「饿了。等和饿一起来最难熬。」",
			"hint": {},
			"when": {}
		}
	],
	"peng": [
		{
			"id": "penguin-gru-1",
			"text": "「热。……我是说，很有诚意。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "penguin-gru-2",
			"text": "「我站着就好。我很会站。」",
			"hint": {},
			"when": {}
		}
	],
	"frog": [
		{
			"id": "frog-gru-1",
			"text": "「呱？我念的天气跟这水对不上。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "frog-gru-2",
			"text": "「我贴着这块地砖。也挺凉快。」",
			"hint": {},
			"when": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-gru-1",
			"text": "「……这水把我的刺泡软了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "hedgehog-gru-2",
			"text": "「没位置也行。我站着，别管我。」",
			"hint": {},
			"when": {}
		}
	],
	"bear": [
		{
			"id": "bear-gru-1",
			"text": "「这水不对。我摸石头都比这准。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "bear-gru-2",
			"text": "「我站着也能睡着。你慢慢来。」",
			"hint": {},
			"when": {}
		}
	],
	"chick": [
		{
			"id": "chick-gru-1",
			"text": "「叽？！这个不痒！一点都不痒！」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "chick-gru-2",
			"text": "「我排队了！我一直在排！」",
			"hint": {},
			"when": {}
		}
	]
}

## 36 条
const FAREWELL := {
	"foxe": [
		{
			"id": "fox-far-p",
			"text": "「这次的消息，我下回给你打个折。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "fox-far-b",
			"text": "「凑合。我见过更凑合的。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "fox-far-w",
			"text": "「你这消息渠道，得换个人了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"panda": [
		{
			"id": "panda-far-p",
			"text": "「你今天押对了。我记这一笔。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "panda-far-b",
			"text": "「不好不坏。天气也大多这样。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "panda-far-w",
			"text": "「我早半天知道风向。你没问。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-far-p",
			"text": "「门口那滩水是我踩的。别擦。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "mouse-far-b",
			"text": "「吱。我下回还从门缝进来。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "mouse-far-w",
			"text": "「消息我照传。这次的我不提。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"cat3": [
		{
			"id": "cat-far-p",
			"text": "「胡子完好。你保住一次机会。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "cat-far-b",
			"text": "「水就是水。我又不是来喝的。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "cat-far-w",
			"text": "「三次机会，你刚用掉一次。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"shib": [
		{
			"id": "dog-far-p2",
			"text": "「明天我踩着点来。」",
			"when": {
				"match": "perfect",
				"arcStage": 2
			},
			"hint": {},
			"collect": "story"
		},
		{
			"id": "dog-far-b",
			"text": "「行。今天也算来过了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "dog-far-w",
			"text": "「这个我不太会泡。我再学学。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-far-p",
			"text": "「我忘了看出口。你听见没有。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "rabbit-far-b",
			"text": "「没出事。没出事就很好了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "rabbit-far-w",
			"text": "「我数了七下就出来了。七下。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"pig": [
		{
			"id": "pig-far-p",
			"text": "「吃饱、泡热、困了。齐了。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "pig-far-b",
			"text": "「还行。我睡哪都能睡。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "pig-far-w",
			"text": "「我出来还是这么干净。亏了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"peng": [
		{
			"id": "penguin-far-p",
			"text": "「那个角落，下次……算了。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "penguin-far-b",
			"text": "「很好了。真的，已经很好了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "penguin-far-w",
			"text": "「我脸红是热的。不是别的。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"frog": [
		{
			"id": "frog-far-p",
			"text": "「呱——今晚我念得准。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "frog-far-b",
			"text": "「雨还没停。我再绕一圈。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "frog-far-w",
			"text": "「这水跟我念的天气打架。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-far-p",
			"text": "「我刺没竖起来。一次都没有。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "hedgehog-far-b",
			"text": "「……嗯。走了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "hedgehog-far-w",
			"text": "「我没扎着谁。这就够了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"bear": [
		{
			"id": "bear-far-p",
			"text": "「这样的水，能睡到开春。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "bear-far-b",
			"text": "「够了。我要求本来就不高。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "bear-far-w",
			"text": "「凉的……我会更困。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"chick": [
		{
			"id": "chick-far-p",
			"text": "「叽！我好像又高了一点点！」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "chick-far-b",
			"text": "「下次我还坐这个位置。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "chick-far-w",
			"text": "「不痒的水……我记住了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	]
}

## 12 条
const SURPRISE := {
	"vip-visit": [
		{
			"id": "sur-vip-1",
			"text": "门口那位站得很直。伞收得也整齐。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-vip-2",
			"text": "有人提前擦了台阶。没人承认是谁。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"promo-day": [
		{
			"id": "sur-promo-1",
			"text": "前台的算盘今天一直在响。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-promo-2",
			"text": "零钱盒今天关不上了。挺好的烦恼。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"pipe-burst": [
		{
			"id": "sur-pipe-1",
			"text": "管子响了两声。……第三声一般就该修了。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-pipe-2",
			"text": "墙里有水在跑。它认得路，我不认得。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"festival": [
		{
			"id": "sur-fest-1",
			"text": "今天外面有鼓声。水面一直在抖。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-fest-2",
			"text": "巷子口飘进来一片纸屑。红的。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"lucky-day": [
		{
			"id": "sur-lucky-1",
			"text": "今天谁进来都先笑一下。不知道为什么。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-lucky-2",
			"text": "掉在地上的硬币，今天都立着。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"lost-item": [
		{
			"id": "sur-lost-1",
			"text": "门口多了件没人认领的浴衣。很小，灰的。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "sur-lost-2",
			"text": "那块布后来被风刮走了。没谁来找。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	]
}

## 30 条
const PROP_STORY := {
	"trim": [
		{
			"id": "prop-trim-1",
			"text": "叶子底下压着一小片浴衣布。不知道是谁的。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-trim-2",
			"text": "剪下来的枝子，明天会被人拿去插瓶。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-trim-3",
			"text": "这盆比上个月高了一指。没人量过。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-trim-4",
			"text": "叶子背面有一行水痕。像谁靠过。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-trim-5",
			"text": "修剪要屏住呼吸。不然会剪歪。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"pray": [
		{
			"id": "prop-pray-1",
			"text": "今天想不出要许什么。这也挺好。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-pray-2",
			"text": "灯芯歪了。愿望大概也会歪一点。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-pray-3",
			"text": "有人在灯罩内侧写了字。看不清。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-pray-4",
			"text": "点上以后什么都没发生。本来就不该发生。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-pray-5",
			"text": "风一吹，影子在墙上晃。像有人点头。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"gaze": [
		{
			"id": "prop-gaze-1",
			"text": "远处有一队人往这边来。看不清是谁。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-gaze-2",
			"text": "山那头的雾比昨天低。低了半个屋顶。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-gaze-3",
			"text": "望远镜被人动过。正对着冷泉那一片。",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.25
			},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-gaze-4",
			"text": "数了数屋顶。第七片瓦一直是斜的。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-gaze-5",
			"text": "从这里看得见自家的烟。原来这么小。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"restock": [
		{
			"id": "prop-restock-1",
			"text": "第三格又卡住了。它一直这样。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-restock-2",
			"text": "有人投过一枚不能用的币。留着当纪念。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-restock-3",
			"text": "最下面一排从来没人买。它们也不着急。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-restock-4",
			"text": "补货时机器会哼一声。像满足了。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-restock-5",
			"text": "玻璃上有三个鼻子印。高度都不一样。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"feast": [
		{
			"id": "prop-feast-1",
			"text": "刚摆好，猪就到了。它怎么知道的。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feast-2",
			"text": "今天多做了两份。多的那份没等到人。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feast-3",
			"text": "锅底那层焦的，其实最抢手。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feast-4",
			"text": "有人把签子摆成了一个小房子。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feast-5",
			"text": "香味先出门，客人后进门。没错过。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	],
	"feed": [
		{
			"id": "prop-feed-1",
			"text": "奶温刚好。猫假装路过了三次。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feed-2",
			"text": "杯口留了一圈白印。谁都不擦。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feed-3",
			"text": "最后一杯总是留到打烊。习惯了。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feed-4",
			"text": "有只小的踮着脚，够不到台面。",
			"hint": {},
			"collect": "story",
			"when": {}
		},
		{
			"id": "prop-feed-5",
			"text": "加热时锅边会响。像小声说话。",
			"hint": {},
			"collect": "story",
			"when": {}
		}
	]
}

## 36 条
const MURMUR := {
	"foxe": [
		{
			"id": "fox-mur-1",
			"segments": ["「水里没人听我说话。」", "「正好。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "fox-mur-2",
			"segments": ["「我这次什么都没带。」", "「就来泡个澡。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "fox-mur-r",
			"segments": ["「我说的那七成里。」", "「有一成是真心的。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"panda": [
		{
			"id": "panda-mur-1",
			"segments": ["「气压在往下走。」", "「泡澡刚好。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "panda-mur-2",
			"segments": ["「云散得比我想的快。」", "「不重要。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "panda-mur-r",
			"segments": ["「你上次挪过那个池子。」", "「我记着。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"mouse": [
		{
			"id": "mouse-mur-1",
			"segments": ["「这池子对我来说是海。」", "「我不说出去。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "mouse-mur-2",
			"segments": ["「热水把胡子泡直了。」", "「不习惯。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "mouse-mur-r",
			"segments": ["「我笑的时候你们听不见。」", "「频率不对。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"cat3": [
		{
			"id": "cat-mur-1",
			"segments": ["「胡子这次没事。」", "「我先不夸。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "cat-mur-2",
			"segments": ["「水面上有我的脸。」", "「还是很好看。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "cat-mur-r",
			"segments": ["「上一个老板不问水温。」", "「这个问。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"shib": [
		{
			"id": "dog-mur-1",
			"segments": ["「泡热了，尾巴会自己动。」", "「管不住。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "dog-mur-2",
			"segments": ["「水声盖过了门口。」", "「挺好的。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "dog-mur-r",
			"segments": ["「我闻得出今天谁来过。」", "「不告诉你。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"rabb": [
		{
			"id": "rabbit-mur-1",
			"segments": ["「出口在左边第三步。」", "「……不看了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "rabbit-mur-2",
			"segments": ["「水到胸口。刚好。」", "「我量过了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "rabbit-mur-r",
			"segments": ["「我耳朵能转一整圈。」", "「现在它们垂着。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"pig": [
		{
			"id": "pig-mur-1",
			"segments": ["「凉快了。」", "「人生完整了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "pig-mur-2",
			"segments": ["「泡到第三分钟。」", "「我就不是我了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "pig-mur-r",
			"segments": ["「我这辈子没羡慕过谁。」", "「今天有一点。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"peng": [
		{
			"id": "penguin-mur-1",
			"segments": ["「水面上有雾。」", "「挡住脸，方便。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "penguin-mur-2",
			"segments": ["「四十天的脚，泡开了。」", "「值。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "penguin-mur-r",
			"segments": ["「我一直在算回程。」", "「今天算错了两次。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"frog": [
		{
			"id": "frog-mur-1",
			"segments": ["「我的体温跟水一样了。」", "「找不到自己了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-mur-2",
			"segments": ["「屋檐还在滴。」", "「三下一停。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "frog-mur-r",
			"segments": ["「呱——」", "「……在水里没人嫌我吵。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"hedg": [
		{
			"id": "hedgehog-mur-1",
			"segments": ["「刺全朝下了。」", "「没人看见。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "hedgehog-mur-2",
			"segments": ["「水没进来。」", "「我以为会进来。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "hedgehog-mur-r",
			"segments": ["「今天没人往后退。」", "「一个都没有。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"bear": [
		{
			"id": "bear-mur-1",
			"segments": ["「热的。」", "「那就还没到春天。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "bear-mur-2",
			"segments": ["「我数水泡。」", "「数到十九就睡着了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "bear-mur-r",
			"segments": ["「我往边上坐了一点。」", "「习惯了。」"],
			"when": {
				"arcStage": 1
			},
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {}
		}
	],
	"chick": [
		{
			"id": "chick-mur-1",
			"segments": ["「叽……水在挠我脚底。」", "「痒。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "chick-mur-2",
			"segments": ["「我踮脚够不到底。」", "「明天就够得到了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "chick-mur-r",
			"segments": ["「毛湿了会变得很小。」", "「别让人看见。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	]
}

## 主线阶梯：沿用网页版 15 关的关卡名，达成条件改由本作已有的经营事实驱动
const CHAPTERS := [
	{
		"id": 1,
		"name": "开门大吉",
		"guests": 3,
		"star": 0
	},
	{
		"id": 2,
		"name": "小试牛刀",
		"guests": 7,
		"star": 0
	},
	{
		"id": 3,
		"name": "初具规模",
		"guests": 12,
		"star": 0
	},
	{
		"id": 4,
		"name": "稳步经营",
		"guests": 18,
		"star": 0
	},
	{
		"id": 5,
		"name": "客流渐旺",
		"guests": 25,
		"star": 0
	},
	{
		"id": 6,
		"name": "渐入佳境",
		"guests": 33,
		"star": 1
	},
	{
		"id": 7,
		"name": "温泉名店",
		"guests": 42,
		"star": 3
	},
	{
		"id": 8,
		"name": "口碑相传",
		"guests": 52,
		"star": 3
	},
	{
		"id": 9,
		"name": "全能旅店",
		"guests": 63,
		"star": 3
	},
	{
		"id": 10,
		"name": "风生水起",
		"guests": 75,
		"star": 3
	},
	{
		"id": 11,
		"name": "温泉大师",
		"guests": 88,
		"star": 3
	},
	{
		"id": 12,
		"name": "极上之汤",
		"guests": 102,
		"star": 4
	},
	{
		"id": 13,
		"name": "天下名泉",
		"guests": 117,
		"star": 4
	},
	{
		"id": 14,
		"name": "至高荣誉",
		"guests": 133,
		"star": 4
	},
	{
		"id": 15,
		"name": "传说之汤",
		"guests": 151,
		"star": 5
	}
]


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
