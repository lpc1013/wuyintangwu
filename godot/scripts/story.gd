class_name Story
## 叙事数据层：全部文案由 godot/tools/gen_story.py 从 _story_dump.json 的 STORY_DB 机械生成，
## dump 源自旧版网页 Spring/index.html（该目录 2026-10-13 已移除，不再可重建），
## 且已落后本文件（缺 PROPCHAT 等后补块）：重跑会覆盖丢失，故默认勿重跑，改剧情直接改本文件。

## 网页版角色 → 本项目物种：狐狸/熊猫/老鼠/猫/小狗/兔子/猪/企鹅/青蛙/刺猬/熊/小鸡
## 其中 panda、mouse、pig、chick 是随叙事补进 GameData.SPECIES 的四只
## STORY_DB_EXT 再收其余十八只（十只扩员新面孔 + 八只原本沉默的老角色），至此名册三十只全有台词；
## 英文名到物种 id 的对照只有一处真相，就是 gen_story.py 的 ACTOR_TO_SPECIES，这里不再抄一遍
## 网页版 8 种水色就近归并进本作 11 种汤：冷泉→雪山冰泉，玫瑰→柚子汤，气泡泉→赛博碳酸泉，泥浴→沙漠砂浴，温汤与红汤同为温泉池

## 30 只角色的档案
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
	},
	"slth": {
		"name": "树懒",
		"nickname": "三天前知道的",
		"hintRate": 0.12,
		"confidence": 0.55,
		"arc": null
	},
	"hipp": {
		"name": "河马",
		"nickname": "只泡最深的",
		"hintRate": 0.3,
		"confidence": 0.8,
		"arc": null
	},
	"koal": {
		"name": "考拉",
		"nickname": "只认一种叶子",
		"hintRate": 0.15,
		"confidence": 0.7,
		"arc": null
	},
	"swan": {
		"name": "天鹅",
		"nickname": "看着很贵",
		"hintRate": 0.35,
		"confidence": 0.65,
		"arc": null
	},
	"owly": {
		"name": "猫头鹰",
		"nickname": "夜里看得清",
		"hintRate": 0.45,
		"confidence": 0.85,
		"arc": null
	},
	"turt": {
		"name": "乌龟",
		"nickname": "记得二十年前",
		"hintRate": 0.2,
		"confidence": 0.9,
		"arc": null
	},
	"octo": {
		"name": "章鱼",
		"nickname": "同时干八件事",
		"hintRate": 0.5,
		"confidence": 0.6,
		"arc": null
	},
	"sqrl": {
		"name": "松鼠",
		"nickname": "囤到忘了放哪",
		"hintRate": 0.4,
		"confidence": 0.45,
		"arc": null
	},
	"badg": {
		"name": "狗獾",
		"nickname": "从地下来",
		"hintRate": 0.35,
		"confidence": 0.8,
		"arc": null
	},
	"goat": {
		"name": "山羊",
		"nickname": "什么都啃一口",
		"hintRate": 0.25,
		"confidence": 0.7,
		"arc": null
	},
	"capy": {
		"name": "水豚",
		"nickname": "泡哪儿都一样",
		"hintRate": 0.15,
		"confidence": 0.6,
		"arc": null
	},
	"racc": {
		"name": "浣熊",
		"nickname": "什么都要搓一遍",
		"hintRate": 0.55,
		"confidence": 0.85,
		"arc": null
	},
	"duck": {
		"name": "小鸭",
		"nickname": "嘎嘎就是回答",
		"hintRate": 0.3,
		"confidence": 0.5,
		"arc": null
	},
	"ottr": {
		"name": "水獭",
		"nickname": "睡觉要牵着",
		"hintRate": 0.4,
		"confidence": 0.7,
		"arc": null
	},
	"deer": {
		"name": "小鹿",
		"nickname": "听见了就抬眼",
		"hintRate": 0.45,
		"confidence": 0.8,
		"arc": null
	},
	"rpnd": {
		"name": "小熊猫",
		"nickname": "睡在最高的地方",
		"hintRate": 0.2,
		"confidence": 0.6,
		"arc": null
	},
	"seal": {
		"name": "海豹",
		"nickname": "上岸很为难",
		"hintRate": 0.35,
		"confidence": 0.75,
		"arc": null
	},
	"coww": {
		"name": "奶牛",
		"nickname": "闻得出今早的奶",
		"hintRate": 0.5,
		"confidence": 0.9,
		"arc": null
	}
}

## 30 条
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
	],
	"slth": [
		{
			"id": "sloth-i1",
			"segments": ["树懒趴在门框上，用三分钟挪完了最后一级台阶。", "「我说话慢。不是没想好，是早说完了，你还在等。」", "「三天前我看好的池子，今天大概还热。大概。」"],
			"hint": {},
			"when": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-i1",
			"segments": ["河马进来时门帘被顶开又落回去，像被风吹的。", "「我挑池子只看一件事——深不深。」", "「浅的水到不了肩膀。到不了肩膀，等于没泡。」"],
			"hint": {},
			"when": {}
		}
	],
	"koal": [
		{
			"id": "koala-i1",
			"segments": ["考拉抱着一小捆叶子进门，坐下第一件事是把叶子数一遍。", "「我只吃这一种。别的给我，我也只放着。」", "「你们这儿的水也一样。认过一次，就认一辈子。」"],
			"hint": {},
			"when": {}
		}
	],
	"swan": [
		{
			"id": "swan-i1",
			"segments": ["天鹅沿着墙边走完一整圈，谁都不看。", "「水面要静，背要直，进来的顺序要最后。」", "「水面底下我在蹬。这个你别告诉别人。」"],
			"hint": {},
			"when": {}
		}
	],
	"owly": [
		{
			"id": "owl-i1",
			"segments": ["猫头鹰是撞进来的——它白天看不清路。", "「抱歉。我夜里不是这样。」", "「夜里谁在说话、谁在排队，我全看得见。」"],
			"hint": {},
			"when": {}
		}
	],
	"turt": [
		{
			"id": "turtle-i1",
			"segments": ["乌龟在门槛前停住，先把头伸进来，再停一会儿。", "「二十年前这里还是一片泡汤的坡。我认得。」", "「我不催。我等的东西一般要等十年。」"],
			"hint": {},
			"when": {}
		}
	],
	"octo": [
		{
			"id": "octopus-i1",
			"segments": ["章鱼进门的同时在跟三个人打招呼，用的是不同的手。", "「我一次说八件事。哪件重要，我不知道。」", "「你挑一件记住就行。挑错了也不算亏。」"],
			"hint": {},
			"when": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-i1",
			"segments": ["松鼠冲进来，怀里抱着一堆东西，坐下就开始找地方藏。", "「这池子会火！我确定——我把它藏哪儿了来着。」", "「我记得结论。过程我拿回去补。」"],
			"hint": {},
			"when": {}
		}
	],
	"badg": [
		{
			"id": "badger-i1",
			"segments": ["地板下的检修口顶开，狗獾钻出来，抖了抖毛上的灰。", "「我不走门。门是给客人走的。」", "「管子从哪过、水从哪来，我比你清楚。」"],
			"hint": {},
			"when": {}
		}
	],
	"goat": [
		{
			"id": "goat-i1",
			"segments": ["山羊一进门就啃了一口门帘。", "「别紧张。我什么都啃，不代表什么都喜欢。」", "「不好吃的我吐出来。所以我说好吃的时候，你该信。」"],
			"hint": {},
			"when": {}
		}
	],
	"capy": [
		{
			"id": "capybara-i1",
			"segments": ["水豚在池边站了很久，久到别人以为他在等位子。", "「我不是挑。我只是在想，泡哪儿都一样。」", "「想完了就泡这儿。水温这事，别太认真。」"],
			"hint": {},
			"when": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-i1",
			"segments": ["浣熊把袖子撸到肘上，进门先找水桶。", "「东西都要搓。食物、手、碗。不搓我不吃。」", "「你那池子干净是看着干净。我信我的手。」"],
			"hint": {},
			"when": {}
		}
	],
	"duck": [
		{
			"id": "duck-i1",
			"segments": ["小鸭一进门就开始叫，叫得门帘都在抖。", "「我不会挑池子。哪里有水我就去哪里。」", "「水凉我就叫得响一点，吵到人是我没看见。」"],
			"hint": {},
			"when": {}
		}
	],
	"ottr": [
		{
			"id": "otter-i1",
			"segments": ["水獭进来时回头数了一圈，像在点数。", "「我不一个人泡。谁把手给我。」", "「没人给也行。我抱着自己的脚睡。」"],
			"hint": {},
			"when": {}
		}
	],
	"deer": [
		{
			"id": "deer-i1",
			"segments": ["小鹿在门帘外站了一会儿才进来，角上挂着两片叶子。", "「我先看出口。看完再看水。」", "「你们这儿太安静。安静得让我想听听到底有没有声音。」"],
			"hint": {},
			"when": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-i1",
			"segments": ["小熊猫是顺着横梁爬进来的，怀里抱着一截木头。", "「高处的风不一样。高处睡着踏实。」", "「底下那口冷水我不去。冷了睡不着，睡不着就要闹。」"],
			"hint": {},
			"when": {}
		}
	],
	"seal": [
		{
			"id": "seal-i1",
			"segments": ["海豹是被人请上台阶的，上来之后就不太想动了。", "「水里我很灵活。岸上这块地方专门跟我作对。」", "「有浮冰我就在。你们这儿有冷泉，那就算有。」"],
			"hint": {},
			"when": {}
		}
	],
	"coww": [
		{
			"id": "cow-i1",
			"segments": ["奶牛走得很慢，到池边先站住，鼻子动了几下。", "「我闻得出一池子里加了什么。今天加得少。」", "「冷水我不评价。冷水没什么可评价的。」"],
			"hint": {},
			"when": {}
		}
	]
}

## 180 条
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
	],
	"slth": [
		{
			"id": "sloth-c1",
			"text": "「三天前，冷泉那边排到了门外。……现在应该还热。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "sloth-c2",
			"text": "「热池昨天一个人都没有。我说得慢，不是我说得晚。」",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.9
			},
			"when": {}
		},
		{
			"id": "sloth-c3",
			"text": "「你催我没用。我脑子不是那个速度。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "sloth-c4",
			"text": "「上回我提醒你那句，你到今天才听懂。也算对上。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "sloth-c5",
			"text": "「树懒一周才下一次树找厕所。泡澡对我是长途旅行。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "sloth-c6",
			"text": "「奶白那池稠。稠的东西浮力大，我省力。」",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-c1",
			"text": "「水深我量过了。到肩膀的只有冷泉那边。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "hippo-c2",
			"text": "「砂浴太浅。我半截在外面，等于没泡。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "hippo-c3",
			"text": "「我一天喝八桶水，所以最懂什么叫不解渴。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "hippo-c4",
			"text": "「药草那池今天味道冲。冲的时候人多。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "hippo-c5",
			"text": "「老板，靠里那个位子留我。不是害羞，是墙凉。」",
			"when": {
				"visitsMin": 4
			},
			"hint": {}
		},
		{
			"id": "hippo-c6",
			"text": "「别看我这身板，皮比谁都薄，晒十分钟就裂。」",
			"hint": {},
			"when": {}
		}
	],
	"koal": [
		{
			"id": "koala-c1",
			"text": "「药草那池的气味不对路，但方向是对的。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "koala-c2",
			"text": "「我只去一个池子。别的池子我不评价，也不听。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "koala-c3",
			"text": "「奶浴太滑了，我抓不住边。抓不住的东西我不喜欢。」",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "koala-c4",
			"text": "「你调过水温。我闻得出来，别问我怎么知道的。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "koala-c5",
			"text": "「考拉一天醒四个小时。今天我已经用掉两个了。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "koala-c6",
			"text": "「那股花香的池子太闹。闹的地方不适合我这种只吃一种叶子的人。」",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		}
	],
	"swan": [
		{
			"id": "swan-c1",
			"text": "「冒泡那池的水面最静。静的水才留得住人。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "swan-c2",
			"text": "「砂浴……我在那儿待不了一分钟。别问为什么。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.7
			},
			"when": {}
		},
		{
			"id": "swan-c3",
			"text": "「我进池子的顺序永远是最后一个。这是规矩，不是怕。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "swan-c4",
			"text": "「花香那池最近有人专门来拍。拍的人多了，就要排。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "swan-c5",
			"text": "「你今天多摆了一把椅子。我看见了，不说谢谢。」",
			"when": {
				"visitsMin": 5
			},
			"hint": {}
		},
		{
			"id": "swan-c6",
			"text": "「天鹅的羽毛防水，所以入水前那一秒我最紧张。」",
			"hint": {},
			"when": {}
		}
	],
	"owly": [
		{
			"id": "owl-c1",
			"text": "「夜里谁往哪边去，我数得清清楚楚。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.45
			},
			"when": {}
		},
		{
			"id": "owl-c2",
			"text": "「白天别说这些。白天我只看见亮。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "owl-c3",
			"text": "「冷泉那池半夜最满。满的时候，白天会空。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "owl-c4",
			"text": "「你打烊太早了。最好的客人都是夜里来的。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "owl-c5",
			"text": "「我转头能转二百七十度。你背后那几个位子我也看着。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "owl-c6",
			"text": "「今晚起风。起风的时候，热池那边会提前满。」",
			"when": {
				"period": "nite"
			},
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.5
			}
		}
	],
	"turt": [
		{
			"id": "turtle-c1",
			"text": "「二十年前这坡上只有一个池。现在你们分这么细。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "turtle-c2",
			"text": "「冷泉那池底下有块石头是活的，会晃。晃的池子留客。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "turtle-c3",
			"text": "「我不去冒泡那池。太吵。吵的东西散得也快。」",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "turtle-c4",
			"text": "「慢一点没有坏处。我等的东西一般十年到。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "turtle-c5",
			"text": "「药草那池的味道，跟我小时候那口井像。像的东西会回来。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "turtle-c6",
			"text": "「老板，你把台账翻到最早那页。最早那页有答案。」",
			"when": {
				"visitsMin": 6
			},
			"hint": {}
		}
	],
	"octo": [
		{
			"id": "octopus-c1",
			"text": "「三件事：冷泉要满、奶白要淡、砂浴在排队——你挑一件办。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "octopus-c2",
			"text": "「我一只手记一个池子，八只手记不完你这家店。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "octopus-c3",
			"text": "「花香那池我量过了。四个人同一分钟来的。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "octopus-c4",
			"text": "「药草那边我劝你别囤。我四只手都这么说。」",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.72
			},
			"when": {}
		},
		{
			"id": "octopus-c5",
			"text": "「我昨天把浴衣穿反了。不是失误，是另一只手先穿的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "octopus-c6",
			"text": "「章鱼没有骨头。所以我泡哪儿都像泡对了，你别学我。」",
			"hint": {},
			"when": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-c1",
			"text": "「我确定！冷泉那边要火！我把它藏哪儿了来着——结论我记住了。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "squirrel-c2",
			"text": "「花香那池我囤了三条毛巾。三条。为什么三条我忘了。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "squirrel-c3",
			"text": "「冒泡那池……我本来想说什么来着。」",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.9
			},
			"when": {}
		},
		{
			"id": "squirrel-c4",
			"text": "「老板，你柜子里第二层是不是我的松果。不是的话我拿错了，抱歉。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "squirrel-c5",
			"text": "「我记结论不记过程。过程你想知道，明天再来问。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "squirrel-c6",
			"text": "「松鼠的记性靠味道。你换了香薰，我的账就乱了一半。」",
			"hint": {},
			"when": {}
		}
	],
	"badg": [
		{
			"id": "badger-c1",
			"text": "「管子从冷泉那边过。管子结霜，今晚那池就满。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.5
			},
			"when": {}
		},
		{
			"id": "badger-c2",
			"text": "「砂浴底下是空的。空的东西填不满，你省点砂。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "badger-c3",
			"text": "「我不走门。走门的是客人，我走该走的路。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "badger-c4",
			"text": "「奶白那池的下水堵了半指。我没说，你自己查。」",
			"when": {
				"visitsMin": 4
			},
			"hint": {}
		},
		{
			"id": "badger-c5",
			"text": "「獾的洞有七个口。你这家店只有两个，我替你着急。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "badger-c6",
			"text": "「药草那池的根是我从北坡刨的。刨得多的东西，价钱要跌。」",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		}
	],
	"goat": [
		{
			"id": "goat-c1",
			"text": "「我啃过你门口那块牌子。牌子写的是实话：热池今天人多。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "goat-c2",
			"text": "「砂浴我尝过，不好吃。不好吃的东西客人也不爱吃。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		},
		{
			"id": "goat-c3",
			"text": "「别挡着我，我在闻这个池子。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "goat-c4",
			"text": "「你上回问我校招。我啃了一口你的账本，纸是甜的，记的就是好事。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "goat-c5",
			"text": "「山羊的胃有四个室。所以我说难喝，是四票都算过的。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "goat-c6",
			"text": "「花香那池我啃过花瓣。啃过就知道，那股味最近会淡。」",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		}
	],
	"capy": [
		{
			"id": "capybara-c1",
			"text": "「热池和药草池我觉得都一样好。这不是敷衍，是真的。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.1
			},
			"when": {}
		},
		{
			"id": "capybara-c2",
			"text": "「冷水我不去。不是怕冷，是没那个必要。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "capybara-c3",
			"text": "「谁坐我旁边都行。我谁也不挤。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "capybara-c4",
			"text": "「你最近累。我看人不用看脸，看他们下水那一下。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "capybara-c5",
			"text": "「水豚泡到只露两个鼻孔。不是舒服，是懒得再动。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "capybara-c6",
			"text": "「今天人比昨天多。天一冷人都往热处挤，不用看招牌。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-c1",
			"text": "「奶白那池我搓不出东西。奶糊在手上一滑，反倒像没洗。」",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "raccoon-c2",
			"text": "「药草池的水是活的。活水才敢下手搓。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "raccoon-c3",
			"text": "「你毛巾换了吗。没换别跟我说换了。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "raccoon-c4",
			"text": "「我替你这店搓过多少回，你自己心里有数。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "raccoon-c5",
			"text": "「池边那块石头还温着。温着的东西，明天水要更烫。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "raccoon-c6",
			"text": "「水浑不浑我看不出来，得搓。搓完布是灰的，就是浑。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.9
			},
			"when": {}
		}
	],
	"duck": [
		{
			"id": "duck-c1",
			"text": "「花香那池的花瓣漂在水上！我吃了三口！嘎！」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "duck-c2",
			"text": "「砂浴没有水。砂浴不算洗澡！嘎！」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.7
			},
			"when": {}
		},
		{
			"id": "duck-c3",
			"text": "「人多的地方水也暖。今天这池子挤，正好。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.1
			},
			"when": {}
		},
		{
			"id": "duck-c4",
			"text": "「我记得你！上回你给我留过靠里的位置！嘎！」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "duck-c5",
			"text": "「冷泉那边今天没人叫。没人叫就是不对。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "duck-c6",
			"text": "「我嘎嘎不是有事。我嘎嘎是我高兴。」",
			"hint": {},
			"when": {}
		}
	],
	"ottr": [
		{
			"id": "otter-c1",
			"text": "「冒泡那池最好。它一直在动，我就不会先睡着。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "otter-c2",
			"text": "「砂浴太干了。睡着黏一身砂，醒来谁都不认。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		},
		{
			"id": "otter-c3",
			"text": "「水獭睡觉手拉手，漂着不散。这是正事，不是撒娇。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "otter-c4",
			"text": "「你上回替我留了两个位子。我记得。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "otter-c5",
			"text": "「冷泉的水托人。人一浮起来就不想下来了。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "otter-c6",
			"text": "「今天有两只一起泡的。他们没牵手。怪。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.05
			},
			"when": {}
		}
	],
	"deer": [
		{
			"id": "deer-c1",
			"text": "「药草池有草的气味。那个我认得，那个是活的。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "deer-c2",
			"text": "「会响的那口池子别叫我过去。它一响我耳朵就立起来。」",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.72
			},
			"when": {}
		},
		{
			"id": "deer-c3",
			"text": "「我站着不坐。坐着跑不起来。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "deer-c4",
			"text": "「你店里那扇门的响法变了。以前是从外头响，现在是从里头。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "deer-c5",
			"text": "「今晚月亮好。月好的晚上，林子里的路我全认得。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "deer-c6",
			"text": "「冷泉边上有露水。露水在，说明今晚凉。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.1
			},
			"when": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-c1",
			"text": "「花香那池暖。暖的地方好睡，睡醒嘴里还有味。」",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "redpanda-c2",
			"text": "「冷泉是醒着的人才去的。我这一辈子多半在睡。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.7
			},
			"when": {}
		},
		{
			"id": "redpanda-c3",
			"text": "「别摇我那截木头。摇了就得重来。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "redpanda-c4",
			"text": "「你每回都在我睡下之后才来。没跟你说过话，不代表不认识你。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "redpanda-c5",
			"text": "「药草池上面那根横梁最好。又暖又高。」",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.1
			},
			"when": {}
		},
		{
			"id": "redpanda-c6",
			"text": "「今天尾巴垂进水里了。垂得进去，就是水正好。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.08
			},
			"when": {}
		}
	],
	"seal": [
		{
			"id": "seal-c1",
			"text": "「冷泉才对。冷的水才配叫泉。」",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "seal-c2",
			"text": "「砂浴别叫我。我上不去也下不来，两头为难。」",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.68
			},
			"when": {}
		},
		{
			"id": "seal-c3",
			"text": "「我在这儿躺着不是懒。我本来就是这个形状。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "seal-c4",
			"text": "「你每回都替我留最里那一格。留了我才肯翻个身。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "seal-c5",
			"text": "「冒泡泉的水在跳。跳得太欢，冰就要化了，趁早。」",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "seal-c6",
			"text": "「热池太热。热了就得一直泡着不出来，那不叫泡，叫煮。」",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.72
			},
			"when": {}
		}
	],
	"coww": [
		{
			"id": "cow-c1",
			"text": "「奶白那池是今天现调的。稠是对的，淡了两分。」",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "cow-c2",
			"text": "「热池要烫到能化开奶。化不开，就说明不够热。」",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		},
		{
			"id": "cow-c3",
			"text": "「反刍一天八小时。所以我有的是时间看你营业。」",
			"hint": {},
			"when": {}
		},
		{
			"id": "cow-c4",
			"text": "「你门口那条路我走了二十趟。哪块砖松了我都记得。」",
			"when": {
				"visitsMin": 3
			},
			"hint": {}
		},
		{
			"id": "cow-c5",
			"text": "「冷泉那水我不敢下。凉的奶不是奶，是别的东西。」",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.7
			},
			"when": {}
		},
		{
			"id": "cow-c6",
			"text": "「花香池的花放久了会出一点酸味。你现在闻不到，牛能。」",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		}
	]
}

## 84 条
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
	],
	"slth": [
		{
			"id": "sloth-l1",
			"title": "三天前写好的信",
			"body": "老板：\n这封信我写了三天。\n写的时候冷泉那边刚排起队。\n你现在收到，还来得及赶上一个尾巴。\n——树懒",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.1
			},
			"when": {}
		},
		{
			"id": "sloth-l2",
			"title": "树懒的补记",
			"body": "老板：\n上一封我漏了一句。\n漏的那句是：热池那边我写错了。\n错的地方，你反着看。\n——树懒",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "sloth-l3",
			"title": "一封还没写完的信",
			"body": "老板：\n这封我还在路上。\n（信到这里就断了，后面半页是三天后补的）\n我其实只想说一句：谢谢你没催我。",
			"hint": {},
			"when": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-l1",
			"title": "河马的一页纸",
			"body": "老板：\n我回来又量了一次水深。\n冷泉那边还是到肩膀。到肩膀我就还来。\n——河马",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "hippo-l2",
			"title": "河马的说明",
			"body": "老板：\n砂浴不是不好，是给我用的话太薄。\n薄的意思你自己判断。\n——河马",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "hippo-l3",
			"title": "河马的第二页",
			"body": "老板：\n我走的时候把门口的石板踩松了一块。\n明天会有人绊倒。那个人可能是往花香那池去的。\n——河马",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		}
	],
	"koal": [
		{
			"id": "koala-l1",
			"title": "考拉的信（只有一行）",
			"body": "老板：\n药草那池我明天还来。\n——考拉",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "koala-l2",
			"title": "考拉的道歉",
			"body": "老板：\n我昨天把别人的浴衣抱走了。\n不是拿错，是它闻起来像我那棵树。\n我已经洗干净挂回去了，挂在最高的钩子上。",
			"hint": {},
			"when": {}
		},
		{
			"id": "koala-l3",
			"title": "考拉的第三封",
			"body": "老板：\n奶白那池我劝你别扩。\n扩了也是空的，空的是时候不对。\n——考拉",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		}
	],
	"swan": [
		{
			"id": "swan-l1",
			"title": "一张压得很平的信",
			"body": "老板：\n今天有人在水边站了很久没下水。\n那种人不会去浅池，会去最满的那个。\n——天鹅",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "swan-l2",
			"title": "天鹅的第二封",
			"body": "老板：\n我在水面上看着很安静。\n水底下那双脚今天替你数了人数。\n数得不多，你先别扩。",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "swan-l3",
			"title": "天鹅的第三封",
			"body": "老板：\n砂浴那件事我写得很难为情。\n我确实滚进去了。滚进去以后我没有立刻出来。\n这件事请不要告诉任何客人。",
			"hint": {},
			"when": {}
		}
	],
	"owly": [
		{
			"id": "owl-l1",
			"title": "夜里写的信",
			"body": "老板：\n今晚打烊前，热池那边还会再来一批。\n他们是从山上下来的，走的是近路。\n——猫头鹰",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.45
			},
			"when": {}
		},
		{
			"id": "owl-l2",
			"title": "猫头鹰的更正",
			"body": "老板：\n上一封我写的是「还会再来」。\n我回去想了想，那句应该是「已经来过了」。\n我白天写字不准。",
			"hint": {
				"pool": "hot",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "owl-l3",
			"title": "猫头鹰的第三封",
			"body": "老板：\n你店里那盏最亮的灯，照得见门口，照不见角落。\n角落那几个人才是真来泡的。\n——猫头鹰",
			"hint": {},
			"when": {}
		}
	],
	"turt": [
		{
			"id": "turtle-l1",
			"title": "一封写了二十年的信",
			"body": "老板：\n我上次来是二十年前。那时候只有一个池。\n现在你分成很多个，我记不住。\n我只记得一件事：会晃的那池留客。\n——乌龟",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "turtle-l2",
			"title": "乌龟的第二封",
			"body": "老板：\n冒泡那池太吵，我劝你把它挪远一点。\n挪远了，安静那几池反倒有人排队。\n——乌龟",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		},
		{
			"id": "turtle-l3",
			"title": "乌龟的第三封",
			"body": "老板：\n我记错了。二十年前是两个池。\n记错不要紧，要紧的是我明天还来。",
			"hint": {},
			"when": {}
		}
	],
	"octo": [
		{
			"id": "octopus-l1",
			"title": "四只手写的信（另外四只在写别的）",
			"body": "老板：\n一、冷泉要满。二、花香要淡。\n三、砂浴在排队。四、我忘了第四条。\n第四条我下次补。\n——章鱼",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.4
			},
			"when": {}
		},
		{
			"id": "octopus-l2",
			"title": "章鱼的补信",
			"body": "老板：\n第四条想起来了：你上回给我留的那条毛巾，我拿错了。\n拿成了四条。四条里有一条是别人的。\n这条我送回来。",
			"hint": {},
			"when": {}
		},
		{
			"id": "octopus-l3",
			"title": "章鱼的第三封",
			"body": "老板：\n奶白那池我一只手试过，两只手试过。\n试到最后八只手都不想去。\n不去的意思，你自己掂量。",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.75
			},
			"when": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-l1",
			"title": "夹着松果的信",
			"body": "老板：\n我本来要写三件事，现在只剩一件：\n花香那池会火。另外两件我藏起来了。\n藏在哪我不说，说了就不好找了。\n——松鼠",
			"hint": {
				"pool": "yuzu",
				"trend": "up",
				"weight": 1.35
			},
			"when": {}
		},
		{
			"id": "squirrel-l2",
			"title": "松鼠的道歉",
			"body": "老板：\n柜子里第二层那个松果不是你的。\n是我的。我昨天翻你的账本就是在找它。\n对不起。账本我看了，数字我不记得。",
			"hint": {},
			"when": {}
		},
		{
			"id": "squirrel-l3",
			"title": "松鼠的第二封",
			"body": "老板：\n冷泉那边我囤了位置。\n囤位置这件事我做得不熟练，可能囤到别人那儿去了。\n总之你先备着。",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		}
	],
	"badg": [
		{
			"id": "badger-l1",
			"title": "从检修口塞进来的信",
			"body": "老板：\n管子我通了一遍。通了以后药草那池的味道会淡。\n淡了人就不去。你要不要重新堵上，你决定。\n——狗獾",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.72
			},
			"when": {}
		},
		{
			"id": "badger-l2",
			"title": "狗獾的第二封",
			"body": "老板：\n你后墙根下有一条旧水道，二十年前走水。\n挖开还能用。能用多久我不知道，我不挖别人家的墙。\n——狗獾",
			"hint": {},
			"when": {}
		},
		{
			"id": "badger-l3",
			"title": "狗獾的第三封",
			"body": "老板：\n砂浴那池我睡过底下。底下比上面凉。\n凉的地方留不住人，人往热的地方去。\n——狗獾",
			"hint": {
				"pool": "sand",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		}
	],
	"goat": [
		{
			"id": "goat-l1",
			"title": "有牙印的信",
			"body": "老板：\n这封信我啃过一角。啃过的部分是好话。\n热池那边明天该多备水，我鼻子不骗人。\n——山羊",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "goat-l2",
			"title": "山羊的第二封",
			"body": "老板：\n你门口那块「客满」的木牌我啃了。\n不是抗议。是它写的是假话，假话不好吃。\n——山羊",
			"hint": {},
			"when": {}
		},
		{
			"id": "goat-l3",
			"title": "山羊的第三封",
			"body": "老板：\n花香那池的花瓣不好吃，涩。\n涩的东西客人嚼两天就腻了，趁早换。\n——山羊",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		}
	],
	"capy": [
		{
			"id": "capybara-l1",
			"title": "没人署名的信",
			"body": "老板：\n我在你池边坐了一下午，什么都没干。\n这封信也没什么内容，就是想说说热池今天挺好。\n——水豚",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.25
			},
			"when": {}
		},
		{
			"id": "capybara-l2",
			"title": "水豚的第二封",
			"body": "老板：\n药草那池的叶子沉底了。沉底的叶子不香。\n捞一捞。捞不捞都行。\n——水豚",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "capybara-l3",
			"title": "水豚的第三封",
			"body": "老板：\n有人说我泡得太久。久不是我的毛病，是他的。\n不过确实堵着人了，下次我早退一刻。\n——水豚",
			"hint": {},
			"when": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-l1",
			"title": "搓过的信",
			"body": "老板：\n这封信纸我在手里搓了三遍，三遍才敢读。\n药草池的叶子该一天一换。换得勤，人才来。\n——浣熊",
			"hint": {
				"pool": "herb",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "raccoon-l2",
			"title": "浣熊的第二封",
			"body": "老板：\n奶浴是好东西，可它甜。甜的东西留人，也留脏。\n擦完再让人泡，行不行。\n——浣熊",
			"hint": {
				"pool": "milk",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "raccoon-l3",
			"title": "浣熊的第三封",
			"body": "老板：\n你的水桶是干净的。我搓过了，布没黑。\n这句算表扬，我不轻易给。\n——浣熊",
			"hint": {},
			"when": {}
		}
	],
	"duck": [
		{
			"id": "duck-l1",
			"title": "一排小脚印的信",
			"body": "老板：\n这信是我踩出来的字，读不顺不怪我。\n热池今天很挤，挤是好事情，挤说明水暖。\n——小鸭",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		},
		{
			"id": "duck-l2",
			"title": "小鸭的第二封",
			"body": "老板：\n砂浴真的不是洗澡。我站进去叫了三声，没人理我。\n下次那地方别写「浴」。\n——小鸭",
			"hint": {},
			"when": {}
		},
		{
			"id": "duck-l3",
			"title": "小鸭的第三封",
			"body": "老板：\n冒泡泉咕嘟咕嘟响！我照着它也叫！嘎！\n两个声音合起来最好听。\n——小鸭",
			"hint": {
				"pool": "cyber",
				"trend": "up",
				"weight": 1.15
			},
			"when": {}
		}
	],
	"ottr": [
		{
			"id": "otter-l1",
			"title": "湿了一角的信",
			"body": "老板：\n这封信是从水上漂回来的，字有点糊。\n冒泡泉的气泡一变小，人就不来了。盯着点。\n——水獭",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.82
			},
			"when": {}
		},
		{
			"id": "otter-l2",
			"title": "水獭的第二封",
			"body": "老板：\n冷泉今天偏浅。浅了浮不起来，浮不起来就睡不着。\n加深一点就行。\n——水獭",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "otter-l3",
			"title": "水獭的第三封",
			"body": "老板：\n今晚我和一只不认识的手拉手睡了一夜。\n明天我们还来。你留两个位子。\n——水獭",
			"hint": {},
			"when": {}
		}
	],
	"deer": [
		{
			"id": "deer-l1",
			"title": "角上夹着的信",
			"body": "老板：\n这信是我角上带回来的，不是写给你，是给你的池子看。\n药草那池的叶子快尽了。尽了就没人来。\n——小鹿",
			"hint": {
				"pool": "herb",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "deer-l2",
			"title": "小鹿的第二封",
			"body": "老板：\n夜里那口冒泡的泉还在响。响一整夜。\n鹿睡不住。别的大概也睡不住。\n——小鹿",
			"hint": {
				"pool": "cyber",
				"trend": "down",
				"weight": 0.78
			},
			"when": {}
		},
		{
			"id": "deer-l3",
			"title": "小鹿的第三封",
			"body": "老板：\n我今天一回都没抬头。有人走近的时候也没抬头。\n这是很大的事。\n——小鹿",
			"hint": {},
			"when": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-l1",
			"title": "睡皱了的信",
			"body": "老板：\n这封信在我脸底下压了一下午，字都皱了。\n花香池该添花瓣。少了味道就散，散了睡不着。\n——小熊猫",
			"hint": {
				"pool": "yuzu",
				"trend": "down",
				"weight": 0.8
			},
			"when": {}
		},
		{
			"id": "redpanda-l2",
			"title": "小熊猫的第二封",
			"body": "老板：\n有人把冷泉添满了。添满是好意，可是我下不去。\n给那口池留个台阶。\n——小熊猫",
			"hint": {},
			"when": {}
		},
		{
			"id": "redpanda-l3",
			"title": "小熊猫的第三封",
			"body": "老板：\n我在梁上看见你一个人算账算到很晚。\n算完记得睡。睡在梁上比睡在账本上好。\n——小熊猫",
			"hint": {},
			"when": {}
		}
	],
	"seal": [
		{
			"id": "seal-l1",
			"title": "湿淋淋的信",
			"body": "老板：\n这封信没晾干就递给你了，纸软了不怪我。\n冷泉的冰该补了。补慢了，今天下午就没人去。\n——海豹",
			"hint": {
				"pool": "ice",
				"trend": "down",
				"weight": 0.85
			},
			"when": {}
		},
		{
			"id": "seal-l2",
			"title": "海豹的第二封",
			"body": "老板：\n台阶太滑。滑的东西不该让我碰。\n铺一层草，我就肯上来。\n——海豹",
			"hint": {},
			"when": {}
		},
		{
			"id": "seal-l3",
			"title": "海豹的第三封",
			"body": "老板：\n今天在冷泉那边拍肚皮的人是我。是我。\n你听见了，就知道我来了。\n——海豹",
			"hint": {
				"pool": "ice",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		}
	],
	"coww": [
		{
			"id": "cow-l1",
			"title": "带奶味的信",
			"body": "老板：\n这封信上沾了我的奶，你闻闻。是好奶。\n奶白池今天稠。稠的日子人来得早，米要备够。\n——奶牛",
			"hint": {
				"pool": "milk",
				"trend": "up",
				"weight": 1.3
			},
			"when": {}
		},
		{
			"id": "cow-l2",
			"title": "奶牛的第二封",
			"body": "老板：\n你的奶是外头买的。买的不行也不是不行，是差一口气。\n差在哪我说不清，找头牛来尝一次就知道。\n——奶牛",
			"hint": {},
			"when": {}
		},
		{
			"id": "cow-l3",
			"title": "奶牛的第三封",
			"body": "老板：\n今天我在热池边站得久。不是迟钝，是舍不得不走。\n明天还来。\n——奶牛",
			"hint": {
				"pool": "hot",
				"trend": "up",
				"weight": 1.2
			},
			"when": {}
		}
	]
}

## 60 条
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
	],
	"slth": [
		{
			"id": "sloth-gru-1",
			"text": "「这个水……我还没泡到，就要走了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "sloth-gru-2",
			"text": "「排队可以。队伍别动得太快。」",
			"hint": {},
			"when": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-gru-1",
			"text": "「这水到不了我的肩膀。差很多。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "hippo-gru-2",
			"text": "「我占地方。我知道。我可以站远一点。」",
			"hint": {},
			"when": {}
		}
	],
	"koal": [
		{
			"id": "koala-gru-1",
			"text": "「这不是我认的那个池子。我不认第二次。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "koala-gru-2",
			"text": "「我先睡一会儿。睡醒你再决定要不要赶我。」",
			"hint": {},
			"when": {}
		}
	],
	"swan": [
		{
			"id": "swan-gru-1",
			"text": "「我的背绷不住了。这样很难看。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "swan-gru-2",
			"text": "「我在等。我等的样子很好看，你别催。」",
			"hint": {},
			"when": {}
		}
	],
	"owly": [
		{
			"id": "owl-gru-1",
			"text": "「白天这水……我看不清它深不深。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "owl-gru-2",
			"text": "「灯太亮了。我闭上眼也是亮的。」",
			"hint": {},
			"when": {}
		}
	],
	"turt": [
		{
			"id": "turtle-gru-1",
			"text": "「这池子我游不动。不是冷，是没到那份上。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "turtle-gru-2",
			"text": "「慢一点。你们什么都快。」",
			"hint": {},
			"when": {}
		}
	],
	"octo": [
		{
			"id": "octopus-gru-1",
			"text": "「我八只手，一只都没够到边。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "octopus-gru-2",
			"text": "「我在数。数到第几只我忘了。」",
			"hint": {},
			"when": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-gru-1",
			"text": "「这里没有我能藏的东西。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "squirrel-gru-2",
			"text": "「我先把要说的忘了。忘了就等会儿再说。」",
			"hint": {},
			"when": {}
		}
	],
	"badg": [
		{
			"id": "badger-gru-1",
			"text": "「这水底下不通。不通的池子我不喜欢。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "badger-gru-2",
			"text": "「我不催。我在洞里等过更久的。」",
			"hint": {},
			"when": {}
		}
	],
	"goat": [
		{
			"id": "goat-gru-1",
			"text": "「这个不好吃。我是说，不好泡。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "goat-gru-2",
			"text": "「我啃一口确认过了。这个不行。」",
			"hint": {},
			"when": {}
		}
	],
	"capy": [
		{
			"id": "capybara-gru-1",
			"text": "「这个水冷。水冷我不争，我就是不泡。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "capybara-gru-2",
			"text": "「我不是不高兴。我只是不动。」",
			"hint": {},
			"when": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-gru-1",
			"text": "「这水我搓了三遍，手上那层还在。不泡了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "raccoon-gru-2",
			"text": "「不干净的东西我不说第二遍，我直接去洗。」",
			"hint": {},
			"when": {}
		}
	],
	"duck": [
		{
			"id": "duck-gru-1",
			"text": "「这里没有水！嘎！没有水！」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "duck-gru-2",
			"text": "「我不高兴的时候也叫。这叫两样的嘎。」",
			"hint": {},
			"when": {}
		}
	],
	"ottr": [
		{
			"id": "otter-gru-1",
			"text": "「这里没人。我不一个人睡。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "otter-gru-2",
			"text": "「干了。干的地方睡不得。」",
			"hint": {},
			"when": {}
		}
	],
	"deer": [
		{
			"id": "deer-gru-1",
			"text": "「这池子一直在响。我不下水。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "deer-gru-2",
			"text": "「这地方对着出口。我站着不动。」",
			"hint": {},
			"when": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-gru-1",
			"text": "「水冷。我换个地方睡。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "redpanda-gru-2",
			"text": "「这池子睡不成。太吵。」",
			"hint": {},
			"when": {}
		}
	],
	"seal": [
		{
			"id": "seal-gru-1",
			"text": "「地上不行。地上我什么都做不了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "seal-gru-2",
			"text": "「太热。我要浮起来才活得像我自己。」",
			"hint": {},
			"when": {}
		}
	],
	"coww": [
		{
			"id": "cow-gru-1",
			"text": "「这个凉。凉的东西我不入口，也不下身。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		},
		{
			"id": "cow-gru-2",
			"text": "「味不对。哪儿不对我说不清，反正不对。」",
			"hint": {},
			"when": {}
		}
	]
}

## 90 条
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
	],
	"slth": [
		{
			"id": "sloth-far-p",
			"text": "「我明天还来。明天我说的是今天的事。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "sloth-far-b",
			"text": "「还行。还行要泡很久才品得出。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "sloth-far-w",
			"text": "「这水太急。我赶不上。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-far-p",
			"text": "「到肩膀了。今天到肩膀了。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "hippo-far-b",
			"text": "「够泡。够泡我就不挑了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "hippo-far-w",
			"text": "「我出来还是干的。这不算泡。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"koal": [
		{
			"id": "koala-far-p",
			"text": "「我认了这个池子。第二次认。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "koala-far-b",
			"text": "「嗯。我睡过了。睡过就算来过。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "koala-far-w",
			"text": "「这里没有我要的那种味道。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"swan": [
		{
			"id": "swan-far-p",
			"text": "「你什么都没看见。这就是最好的招待。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "swan-far-b",
			"text": "「水面还算平。我勉强站住了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "swan-far-w",
			"text": "「我的脚在水底下忙了一整晚。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"owly": [
		{
			"id": "owl-far-p",
			"text": "「下次我白天来。白天我也认得这里。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "owl-far-b",
			"text": "「还行。还行不是夸，是实话。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "owl-far-w",
			"text": "「太亮了，也太早了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"turt": [
		{
			"id": "turtle-far-p",
			"text": "「这水能记二十年。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "turtle-far-b",
			"text": "「跟二十年前差不多。差不多就是好。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "turtle-far-w",
			"text": "「这池子留不住我，我也留不住它。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"octo": [
		{
			"id": "octopus-far-p",
			"text": "「八只手都举赞成。很少有这么齐的时候。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "octopus-far-b",
			"text": "「五票通过，三票弃权。算好吧。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "octopus-far-w",
			"text": "「有一只手到现在还生气。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-far-p",
			"text": "「我把今天藏起来了。藏在哪不重要，反正藏好了。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "squirrel-far-b",
			"text": "「还行。还行我明天就忘了。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "squirrel-far-w",
			"text": "「我忘了今天是怎么过的。应该过得不好。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"badg": [
		{
			"id": "badger-far-p",
			"text": "「你这店的地底下是通的。通的地方我不说第二遍。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "badger-far-b",
			"text": "「能泡。能泡我就从洞里上来。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "badger-far-w",
			"text": "「这水走的是死路。死路我不待。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"goat": [
		{
			"id": "goat-far-p",
			"text": "「我一口都没啃。这就是最高评价。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "goat-far-b",
			"text": "「不好不坏。像青草。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "goat-far-w",
			"text": "「这个我啃过了，不啃第二次。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"capy": [
		{
			"id": "capybara-far-p",
			"text": "「泡到忘了时间。下次还这样。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "capybara-far-b",
			"text": "「挺好。不好也不坏，正好。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "capybara-far-w",
			"text": "「下次我坐门口就好。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-far-p",
			"text": "「今天没搓出脏的。这就是好。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "raccoon-far-b",
			"text": "「凑合。回去还得再洗一遍手。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "raccoon-far-w",
			"text": "「我袖口湿了。是这池子的错。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"duck": [
		{
			"id": "duck-far-p",
			"text": "「今天我叫得最响。下次还来叫。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "duck-far-b",
			"text": "「一般般响。嘎。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "duck-far-w",
			"text": "「我嗓子疼。今天不叫了。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"ottr": [
		{
			"id": "otter-far-p",
			"text": "「睡着了。睡着了就是好。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "otter-far-b",
			"text": "「半睡。算及格。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "otter-far-w",
			"text": "「我抱着自己的脚。有点冷。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"deer": [
		{
			"id": "deer-far-p",
			"text": "「我在这儿站到了天黑。天黑才走。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "deer-far-b",
			"text": "「还行。角上的叶子没掉。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "deer-far-w",
			"text": "「我耳朵一直没放下来。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-far-p",
			"text": "「我睡着了。位置是我自己找的。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "redpanda-far-b",
			"text": "「半梦。那截木头还行。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "redpanda-far-w",
			"text": "「尾巴干了。干了就是没泡好。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"seal": [
		{
			"id": "seal-far-p",
			"text": "「今天浮得很圆。下次还这样。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "seal-far-b",
			"text": "「不冷不热。凑合躺着。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "seal-far-w",
			"text": "「我肚子磨破了。这不算泡过。」",
			"when": {
				"match": "wrong"
			},
			"hint": {}
		}
	],
	"coww": [
		{
			"id": "cow-far-p",
			"text": "「今天这池像刚挤出来的。好。」",
			"when": {
				"match": "perfect"
			},
			"hint": {}
		},
		{
			"id": "cow-far-b",
			"text": "「不功不过。还能嚼。」",
			"when": {
				"match": "basic"
			},
			"hint": {}
		},
		{
			"id": "cow-far-w",
			"text": "「我站一会儿就出来了。出来得早就是不满意。」",
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

## 90 条
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
	],
	"slth": [
		{
			"id": "sloth-mur-1",
			"segments": ["「水把我浮起来了。」", "「那我就不用动了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "sloth-mur-2",
			"segments": ["「三分钟后我要挪一下。」", "「……两分钟后再说。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "sloth-mur-r",
			"segments": ["「我说得慢。」", "「所以我说完的那句，通常是真的。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"hipp": [
		{
			"id": "hippo-mur-1",
			"segments": ["「到肩膀了。」", "「那就谁也不用理了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "hippo-mur-2",
			"segments": ["「水里没人能推我。」", "「这个我喜欢。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "hippo-mur-r",
			"segments": ["「我在最底下坐着。」", "「上面那些声音跟我没关系。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"koal": [
		{
			"id": "koala-mur-1",
			"segments": ["「这个味道不对。」", "「但是能睡。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "koala-mur-2",
			"segments": ["「抱着这块石头。」", "「跟抱着树差不多。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "koala-mur-r",
			"segments": ["「我只认一种东西。」", "「认得久了，就省了很多事。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"swan": [
		{
			"id": "swan-mur-1",
			"segments": ["「水面别起波纹。」", "「别起、别起、别起——」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "swan-mur-2",
			"segments": ["「背要直。」", "「在水里也直。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "swan-mur-r",
			"segments": ["「水底下那双脚。」", "「今天可以停一下。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"owly": [
		{
			"id": "owl-mur-1",
			"segments": ["「这个时辰水最静。」", "「静得能听见别人。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "owl-mur-2",
			"segments": ["「我一只眼睁着。」", "「另一只也睁着。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "owl-mur-r",
			"segments": ["「白天谁都不看我。」", "「晚上所有人都被我看着。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"turt": [
		{
			"id": "turtle-mur-1",
			"segments": ["「这水跟二十年前一样。」", "「也可能不一样。我不计较。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "turtle-mur-2",
			"segments": ["「壳在水里会轻一点。」", "「轻一点就够。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "turtle-mur-r",
			"segments": ["「我记性太好。」", "「泡着的时候才肯忘一会儿。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"octo": [
		{
			"id": "octopus-mur-1",
			"segments": ["「一只手在数水温。」", "「另外七只在泡。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "octopus-mur-2",
			"segments": ["「我可以同时想八件事。」", "「现在只想一件。麻烦。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "octopus-mur-r",
			"segments": ["「今天没人跟我说话。」", "「八只手都闲下来了。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"sqrl": [
		{
			"id": "squirrel-mur-1",
			"segments": ["「这里藏一个。」", "「……刚才藏哪了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "squirrel-mur-2",
			"segments": ["「水里有松果的影子。」", "「不是。不是也先捞。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "squirrel-mur-r",
			"segments": ["「今天什么都没囤。」", "「手空着，人还在。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"badg": [
		{
			"id": "badger-mur-1",
			"segments": ["「管子在我背后响。」", "「响着才安心。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "badger-mur-2",
			"segments": ["「水底下是石头。」", "「石头我认得。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "badger-mur-r",
			"segments": ["「我不爱说话。」", "「泡着的时候话更少。正好。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"goat": [
		{
			"id": "goat-mur-1",
			"segments": ["「先闻，再下。」", "「闻着没问题。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "goat-mur-2",
			"segments": ["「这池子没东西可啃。」", "「也挺好。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "goat-mur-r",
			"segments": ["「我今天一口都没咬。」", "「忍住了。忍住了算我的。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"capy": [
		{
			"id": "capybara-mur-1",
			"segments": ["「水没过肩膀。」", "「剩下那点我自己补。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "capybara-mur-2",
			"segments": ["「谁靠过来都行。」", "「我不动。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "capybara-mur-r",
			"segments": ["「我泡着一动不动。」", "「不是睡着。是在想事。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"racc": [
		{
			"id": "raccoon-mur-1",
			"segments": ["「先搓一遍。」", "「不搓不安心。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "raccoon-mur-2",
			"segments": ["「这只碗我洗了三回。」", "「第三回才算数。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "raccoon-mur-r",
			"segments": ["「我也知道没必要。」", "「手还是动了。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"duck": [
		{
			"id": "duck-mur-1",
			"segments": ["「水在动。」", "「在动就好玩。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "duck-mur-2",
			"segments": ["「我先下。」", "「谁跟来都行。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "duck-mur-r",
			"segments": ["「今天没人跟我一起叫。」", "「叫得有点累了。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"ottr": [
		{
			"id": "otter-mur-1",
			"segments": ["「手给我。」", "「就不会掉下去。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "otter-mur-2",
			"segments": ["「我漂着呢。」", "「漂着就没事。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "otter-mur-r",
			"segments": ["「一个人也行。」", "「……也行。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"deer": [
		{
			"id": "deer-mur-1",
			"segments": ["「风从那边来。」", "「那边有人。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "deer-mur-2",
			"segments": ["「水很浅。」", "「浅得能看见自己的腿。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "deer-mur-r",
			"segments": ["「今天一次都没惊心。」", "「一次都没有。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"rpnd": [
		{
			"id": "redpanda-mur-1",
			"segments": ["「上面风好。」", "「上面能睡。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "redpanda-mur-2",
			"segments": ["「抱紧。」", "「抱着才睡得着。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "redpanda-mur-r",
			"segments": ["「我在最高的地方看着。」", "「看到了。都看到了。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"seal": [
		{
			"id": "seal-mur-1",
			"segments": ["「浮着。」", "「浮着就赢了。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "seal-mur-2",
			"segments": ["「拍一下。」", "「拍一下才舒服。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "seal-mur-r",
			"segments": ["「在岸上我什么都不是。」", "「一下水就不是了。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	],
	"coww": [
		{
			"id": "cow-mur-1",
			"segments": ["「先站着。」", "「站着才闻得准。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "cow-mur-2",
			"segments": ["「今天有三分。」", "「三分是好的一半。」"],
			"rarity": "common",
			"hint": {},
			"when": {}
		},
		{
			"id": "cow-mur-r",
			"segments": ["「没人听我讲味道的差别。」", "「差别是有的。」"],
			"rarity": "rare",
			"bubbleStyle": "glow",
			"hint": {},
			"when": {}
		}
	]
}

## 摆件点评：键是设施 id（不是物种），客人泡到半程有几率夸一句屋里摆的件。
## 台词 species 中立、两拍短句，跟 murmur 同一种气泡节奏
const PROPCHAT := {
	"lantern": [
		{"id": "pc-lantern-1", "segments": ["「灯底下最暖和。」", "「难怪大家都往这儿凑。」"]},
		{"id": "pc-lantern-2", "segments": ["「纸糊的，风一吹就晃。」", "「晃得也有道理。」"]},
	],
	"bench": [
		{"id": "pc-bench-1", "segments": ["「这根椅子被人坐热过。」", "「我就不说破。」"]},
		{"id": "pc-bench-2", "segments": ["「坐着等位。」", "「比站着排队体面。」"]},
	],
	"vender": [
		{"id": "pc-vender-1", "segments": ["「和果子摆得整整齐齐。」", "「今天很争气。」"]},
		{"id": "pc-vender-2", "segments": ["「路过第三趟了。」", "「手比脑子先付了钱。」"]},
	],
	"camera": [
		{"id": "pc-camera-1", "segments": ["「富士画就挂在这儿。」", "「谁站前面谁上镜。」"]},
		{"id": "pc-camera-2", "segments": ["「拍完千万别回头。」", "「回头就糊了。」"]},
	],
	"plant": [
		{"id": "pc-plant-1", "segments": ["「叶子好像又绿了一点。」", "「多半是心理作用。」"]},
		{"id": "pc-plant-2", "segments": ["「有人对它说过话。」", "「它没答应，但听见了。」"]},
	],
	"bucket": [
		{"id": "pc-bucket-1", "segments": ["「新桶有股杉木味。」", "「闻着像还没泡就赚了。」"]},
		{"id": "pc-bucket-2", "segments": ["「桶摞着桶。」", "「像一屋子没说完的话。」"]},
	],
	"tea": [
		{"id": "pc-tea-1", "segments": ["「麦茶是凉的，团子是软的。」", "「挑不出毛病。」"]},
		{"id": "pc-tea-2", "segments": ["「自助的意思就是。」", "「再拿一个也没人管。」"]},
	],
	"andon_hang": [
		{"id": "pc-andonhang-1", "segments": ["「灯悬在头顶。」", "「照得谁都不好意思低头。」"]},
		{"id": "pc-andonhang-2", "segments": ["「绳子要是再长三寸。」", "「我就得绕着走。」"]},
	],
	"kakejiku": [
		{"id": "pc-kakejiku-1", "segments": ["「画里的山比这边的高。」", "「服气。」"]},
		{"id": "pc-kakejiku-2", "segments": ["「挂轴卷起来是冬天。」", "「展开就是秋天。」"]},
	],
	"kouro": [
		{"id": "pc-kouro-1", "segments": ["「这香讲五德。」", "「我先记住安静这条。」"]},
		{"id": "pc-kouro-2", "segments": ["「烟直着往上走。」", "「不碰谁，也没人碰它。」"]},
	],
	"andon_floor": [
		{"id": "pc-andonfloor-1", "segments": ["「矮灯挨着地。」", "「连光都是暖乎的。」"]},
		{"id": "pc-andonfloor-2", "segments": ["「走路看着点它。」", "「它今晚还要亮呢。」"]},
	],
	"tetsubin": [
		{"id": "pc-tetsubin-1", "segments": ["「铁壶哼上了。」", "「水快开了。」"]},
		{"id": "pc-tetsubin-2", "segments": ["「壶盖一响。」", "「今天的水声归它领唱。」"]},
	],
	"chawan": [
		{"id": "pc-chawan-1", "segments": ["「碗沿有个小缺口。」", "「正好贴着嘴唇。」"]},
		{"id": "pc-chawan-2", "segments": ["「半盏麦茶。」", "「多了反而喝不出香。」"]},
	],
	"clay_teapot": [
		{"id": "pc-clayteapot-1", "segments": ["「壶嘴冲着哪边。」", "「我就坐哪边等。」"]},
		{"id": "pc-clayteapot-2", "segments": ["「紫砂养得久了。」", "「空壶倒水也有味。」"]},
	],
	"bowls_stack": [
		{"id": "pc-bowlsstack-1", "segments": ["「一摞碗晃了一下。」", "「没倒，算它稳。」"]},
		{"id": "pc-bowlsstack-2", "segments": ["「我数过三回。」", "「每回都少一只，每回又都对。」"]},
	],
	"basket": [
		{"id": "pc-basket-1", "segments": ["「竹篓看着是空的。」", "「其实什么都收。」"]},
		{"id": "pc-basket-2", "segments": ["「谁扔了块皂进去。」", "「香了整个筐。」"]},
	],
	"cushion": [
		{"id": "pc-cushion-1", "segments": ["「垫子上有别人的体温。」", "「我装作没在意。」"]},
		{"id": "pc-cushion-2", "segments": ["「坐下去才三秒。」", "「起身的计划取消了。」"]},
	],
	"clock": [
		{"id": "pc-clock-1", "segments": ["「滴答，滴答。」", "「汤还没好，钟先急了。」"]},
		{"id": "pc-clock-2", "segments": ["「指针比我准时。」", "「这个我认。」"]},
	],
	"noren": [
		{"id": "pc-noren-1", "segments": ["「帘子一掀。」", "「热气先出去打招呼。」"]},
		{"id": "pc-noren-2", "segments": ["「蓝布上印着汤气。」", "「懂行的隔着街就来了。」"]},
	],
	"signboard": [
		{"id": "pc-signboard-1", "segments": ["「今日汤温四十二。」", "「字是歪的，水不歪。」"]},
		{"id": "pc-signboard-2", "segments": ["「告示又添了一行小字。」", "「越小的字越要紧。」"]},
	],
	"spout": [
		{"id": "pc-spout-1", "segments": ["「竹笕的水没停过。」", "「它不累，我看着累。」"]},
		{"id": "pc-spout-2", "segments": ["「哗哗声把话都接住了。」", "「说什么都像对白。」"]},
	],
	"washstand": [
		{"id": "pc-washstand-1", "segments": ["「半盆清水。」", "「照出今天最清醒的我。」"]},
		{"id": "pc-washstand-2", "segments": ["「木架轻轻响了一声。」", "「它也在伸懒腰。」"]},
	],
	"shampoo": [
		{"id": "pc-shampoo-1", "segments": ["「按两下就够。」", "「有人按了五下，我看见了。」"]},
		{"id": "pc-shampoo-2", "segments": ["「香香的。」", "「出门前谁都不是秃子。」"]},
	],
	"towel_stack": [
		{"id": "pc-towelstack-1", "segments": ["「叠得这么方正。」", "「都不好意思弄乱它。」"]},
		{"id": "pc-towelstack-2", "segments": ["「白毛巾摞到了顶。」", "「太阳晒过的味道跑不出来。」"]},
	],
	"towel_basket": [
		{"id": "pc-towelbasket-1", "segments": ["「卷好的毛巾排排躺。」", "「抽一条，谁也别客气。」"]},
		{"id": "pc-towelbasket-2", "segments": ["「筐里最上面那条。」", "「今天第三次被放回去了。」"]},
	],
	"ishidoro": [
		{"id": "pc-ishidoro-1", "segments": ["「石缝里全是苔。」", "「比我会存年头。」"]},
		{"id": "pc-ishidoro-2", "segments": ["「石灯一点。」", "「院子立刻有了主角。」"]},
	],
	"azalea": [
		{"id": "pc-azalea-1", "segments": ["「花开到这份上。」", "「蜜蜂都得排号。」"]},
		{"id": "pc-azalea-2", "segments": ["「五月也就开这一回。」", "「今天算赶上了。」"]},
	],
	"oke_lid": [
		{"id": "pc-okelid-1", "segments": ["「盖上的提手印凹得正好。」", "「每只手都按得准。」"]},
		{"id": "pc-okelid-2", "segments": ["「木盖一掀。」", "「憋了一路的热气全撒出来。」"]},
	],
	"mat": [
		{"id": "pc-mat-1", "segments": ["「赤脚踩上去。」", "「草席先跟我问好。」"]},
		{"id": "pc-mat-2", "segments": ["「席子编得密。」", "「灰都插不进去。」"]},
	],
	"geta": [
		{"id": "pc-geta-1", "segments": ["「门口这双木屐。」", "「鞋带还是湿的。」"]},
		{"id": "pc-geta-2", "segments": ["「咔哒，咔哒。」", "「穿它的人走路很急。」"]},
	],
	"stool_towel": [
		{"id": "pc-stooltowel-1", "segments": ["「凳上的巾叠得规矩。」", "「没人看着也这么标准。」"]},
		{"id": "pc-stooltowel-2", "segments": ["「小木凳吱呀一声。」", "「算是打过招呼了。」"]},
	],
	"ladder": [
		{"id": "pc-ladder-1", "segments": ["「扶着杆子下池。」", "「体面，比跳下去强。」"]},
		{"id": "pc-ladder-2", "segments": ["「金属杆泡得凉丝丝。」", "「手比嘴诚实。」"]},
	],
	"palm_potted": [
		{"id": "pc-palmpotted-1", "segments": ["「一蓬叶子撑开来。」", "「浴场也有了夏天。」"]},
		{"id": "pc-palmpotted-2", "segments": ["「苏铁不着急开花。」", "「我也不着急走。」"]},
	],
	"kake_bacho": [
		{"id": "pc-kakebacho-1", "segments": ["「铁皮桶一手提溜。」", "「打热水的都是老手。」"]},
		{"id": "pc-kakebacho-2", "segments": ["「桶梁晃了一下。」", "「水一滴没洒。」"]},
	],
	"andon_snow": [
		{"id": "pc-andonsnow-1", "segments": ["「灯顶积了一晚的雪。」", "「光反而更暖。」"]},
		{"id": "pc-andonsnow-2", "segments": ["「雪见灯不看雪。」", "「看灯的人也高兴。」"]},
	],
	"fence": [
		{"id": "pc-fence-1", "segments": ["「矮栅栏拦不住谁。」", "「但看着就该绕着走。」"]},
		{"id": "pc-fence-2", "segments": ["「木头晒了一整天。」", "「晚上还带着太阳味。」"]},
	],
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
		"propchat":
			return PROPCHAT
		"murmur":
			return MURMUR
	return {}

## 取某只动物（或某个事件键）在某频道下的全部候选条目
static func entries(channel_id: String, key_id: String) -> Array:
	return channel(channel_id).get(key_id, [])

## 角色档案；没有档案的物种返回空字典
static func profile(species: String) -> Dictionary:
	return PROFILES.get(species, {})

## 九张台词表。收藏进度的分母、以及「哪些频道存在」都只从这里算，
## 免得 room_view / GameManager 各自抄一份频道清单，早晚和 channel() 走散
static func channels() -> Array:
	return [INTRO, CHAT, LETTER, GRUMBLE, FAREWELL, SURPRISE, PROP_STORY, PROPCHAT, MURMUR]

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
