class_name PixelArt
## 程序化像素精灵工厂：按 GameData.SPECIES 的属性（耳型/尾型/体型/面部标记）组合绘制，
## 与 HTML 版同一立意——不依赖外部素材表，代码逐像素绘制。
## 所有姿态一律正对镜头，五官只需画一遍：行走睁眼、泡汤闭眼加毛巾、茶室盘坐捧茶。
## 行走另有 stepL / stepR 两帧，只换抬哪条腿，画布尺寸与锚点三帧完全一致。

const OUTLINE := Color(0.16, 0.1, 0.14, 1.0)
const TOWEL := Color(0.97, 0.97, 0.95)
const TOWEL_STRIPE := Color(0.62, 0.78, 0.9)
const BLUSH := Color(0.98, 0.6, 0.66)
const EYE := Color(0.2, 0.14, 0.16)
const TEACUP := Color(0.94, 0.93, 0.88)
const MATCHA := Color(0.44, 0.64, 0.33)
const COMB := Color(0.83, 0.33, 0.25)
const CUSHION := Color(0.55, 0.21, 0.27)

const YUKATA := [
	Color(0.25, 0.3, 0.55), Color(0.95, 0.6, 0.7), Color(0.45, 0.65, 0.4),
	Color(0.6, 0.5, 0.8), Color(0.95, 0.65, 0.3), Color(0.3, 0.6, 0.6),
]

const WALK_W := 32
const WALK_H := 40
const SOAK_W := 32
const SOAK_H := 28
## 落座画布与行走同尺寸：脚掌换成坐垫后仍贴着同一条地面线，锚定逻辑不必分支
const REST_W := 32
const REST_H := 40

static var _color_cache := {}
static var _tex_cache := {}

static func make_image(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

static func hex(hex_str: String) -> Color:
	if not _color_cache.has(hex_str):
		_color_cache[hex_str] = Color.from_string(hex_str, Color.MAGENTA)
	return _color_cache[hex_str]

static func px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

static func fill_rect(im: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			px(im, x, y, c)

static func fill_ellipse(im: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(im, x, y, c)

## 带光向的椭圆：底色铺满后压暗右下、提亮左上，得到体积而不是色块
static func fill_ball(im: Image, cx: float, cy: float, rx: float, ry: float, t: Dictionary) -> void:
	fill_ellipse(im, cx, cy, rx, ry, t.shade)
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0:
				continue
			if dy > 0.35 and dx > 0.15:
				px(im, x, y, t.deep)
			elif dy < -0.15 and dx < 0.25:
				px(im, x, y, t.lit)
			else:
				px(im, x, y, t.base)

static func fill_tri(im: Image, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, c: Color) -> void:
	var minx := mini(mini(x0, x1), x2)
	var maxx := maxi(maxi(x0, x1), x2)
	var miny := mini(mini(y0, y1), y2)
	var maxy := maxi(maxi(y0, y1), y2)
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var d1 := (x - x1) * (y0 - y1) - (x0 - x1) * (y - y1)
			var d2 := (x - x2) * (y1 - y2) - (x1 - x2) * (y - y2)
			var d3 := (x - x0) * (y2 - y0) - (x2 - x0) * (y - y0)
			var neg := (d1 < 0) or (d2 < 0) or (d3 < 0)
			var pos := (d1 > 0) or (d2 > 0) or (d3 > 0)
			if not (neg and pos):
				px(im, x, y, c)

## 由物种主色派生一整套明度，保证同一只动物身上所有部件共享光源
static func tones(body: Color, belly: Color, dark: Color) -> Dictionary:
	return {
		"base": body,
		"lit": body.lightened(0.18),
		"shade": body.darkened(0.14),
		"deep": body.darkened(0.3),
		"belly": belly,
		"belly_lit": belly.lightened(0.08),
		"belly_shade": belly.darkened(0.14),
		"dark": dark,
		"dark_lit": dark.lightened(0.16),
	}

## 收尾：四邻透明的像素描成轮廓色，左上斜向透明的像素打一道高光边。
## 光源统一在左上，才能和厚涂背景对得上。
static func outline_and_rim(im: Image, rim_amount := 0.42) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var opaque := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and im.get_pixel(x, y).a > 0.5
	var rim: Array[Vector2i] = []
	for y in h:
		for x in w:
			if not opaque.call(x, y):
				continue
			var on_edge: bool = not (opaque.call(x - 1, y) and opaque.call(x + 1, y)
				and opaque.call(x, y - 1) and opaque.call(x, y + 1))
			if on_edge:
				im.set_pixel(x, y, OUTLINE)
			elif not (opaque.call(x - 1, y - 1) and opaque.call(x - 1, y)):
				rim.append(Vector2i(x, y))
	for p in rim:
		var c: Color = im.get_pixel(p.x, p.y)
		im.set_pixel(p.x, p.y, c.lightened(rim_amount))

## 内描边：不透明像素的四邻域若透明则压暗为轮廓色，得到干净 1px 轮廓
static func inner_outline(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var edges: Array[Vector2i] = []
	for y in h:
		for x in w:
			if im.get_pixel(x, y).a < 0.5:
				continue
			var on_edge := false
			for n in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
				if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or im.get_pixel(n.x, n.y).a < 0.5:
					on_edge = true
					break
			if on_edge:
				edges.append(Vector2i(x, y))
	for p in edges:
		im.set_pixel(p.x, p.y, OUTLINE)

static func make_animal(species_id: String, yukata: Color, pose: String) -> Image:
	var sp := GameData.species(species_id)
	var body: Color = hex(sp.get("body", "#c8a878"))
	var belly: Color = hex(sp.get("belly", "#f0dcb8"))
	var dark: Color = hex(sp.get("dark", "#4a3a30"))
	var t := tones(body, belly, dark)
	var im: Image
	if pose == "soak":
		im = _soak(sp, t)
	elif pose == "rest":
		im = _rest(sp, t, yukata)
	else:
		im = _walk(sp, t, yukata, stride(pose))
	return _rescaled(im, float(sp.get("size", 1.0)))

## 姿态名 → 抬哪只脚：0 两脚着地（站立、落位前的那一下），1 左脚抬起，2 右脚抬起。
## 走路只需这三张图，切换由 guest 按实际位移驱动，不需要更多帧也读得出在迈步。
static func stride(pose: String) -> int:
	if pose == "stepL":
		return 1
	if pose == "stepR":
		return 2
	return 0

## 体型缩放：放大输出画布以免大体型被裁切，并以底部中心为锚，
## 保证脚掌 / 水面线不随体型漂移。
static func _rescaled(im: Image, s: float) -> Image:
	if absf(s - 1.0) < 0.03:
		return im
	var w := im.get_width()
	var h := im.get_height()
	var nw := maxi(4, int(round(w * s)))
	var nh := maxi(4, int(round(h * s)))
	var scaled := im.duplicate()
	scaled.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	var out := make_image(maxi(w, nw), maxi(h, nh))
	var ox := (out.get_width() - nw) / 2
	var oy := out.get_height() - nh
	for y in nh:
		for x in nw:
			var c: Color = scaled.get_pixel(x, y)
			if c.a > 0.0:
				px(out, ox + x, oy + y, c)
	return out

## 客人始终正对镜头：行走与泡汤共用同一颗头，只换表情与下半身。
## 好处是五官只需画一遍，玩家在人群里一眼读到物种与情绪。
static func _walk(sp: Dictionary, t: Dictionary, yukata: Color, lift: int = 0) -> Image:
	var im := make_image(WALK_W, WALK_H)
	# 尾巴先画：正面视角下只从身侧探出一截，根部被身体挡住
	_draw_tail(im, String(sp.get("tail", "stub")), t, bool(sp.get("ring", false)))
	# 肩毛：把头与浴衣之间那道缝填实，脖子不会断
	fill_ball(im, 16.0, 25.0, 8.0, 5.0, t)
	_draw_yukata(im, yukata, t)
	_draw_paw(im, 6, t, -1 if lift == 1 else (1 if lift == 2 else 0))
	_draw_paw(im, 21, t, 1 if lift == 1 else (-1 if lift == 2 else 0))
	_draw_leg(im, 10, t, lift == 1)
	_draw_leg(im, 18, t, lift == 2)
	_head(im, sp, t, true, false)
	outline_and_rim(im)
	return im

## 落座：茶室里不泡水，两腿收成一片摊开的膝头、屁股压进坐垫、双爪捧一碗抹茶。
## 与站姿共用同一颗头和同一套浴衣，只有下半身换掉——玩家才认得出是同一只动物。
static func _rest(sp: Dictionary, t: Dictionary, yukata: Color) -> Image:
	var im := make_image(REST_W, REST_H)
	var ct := tones(CUSHION, CUSHION, CUSHION)
	_draw_tail(im, String(sp.get("tail", "stub")), t, bool(sp.get("ring", false)))
	# 坐垫压在尾巴后面：尾尖从垫子右沿探出来，不会被读成垫子的一部分
	fill_ball(im, 16.0, 36.0, 13.6, 4.6, ct)
	fill_ellipse(im, 16.0, 34.0, 10.0, 2.2, ct.lit)
	# 膝头：站着时靠两条腿撑开的地面接触面，盘坐时摊成整块宽底
	fill_ball(im, 16.0, 31.0, 11.2, 6.4, t)
	fill_ball(im, 16.0, 25.0, 8.0, 5.0, t)
	_draw_yukata(im, yukata, t)
	# 前爪比站姿收拢两格，环住膝前那只碗
	_draw_paw(im, 8, t)
	_draw_paw(im, 19, t)
	_rest_teacup(im)
	_head(im, sp, t, true, false)
	outline_and_rim(im)
	return im

## 抹茶碗：碗沿两侧留白瓷、中间一抹茶色，圈足压在膝头上，正面一眼读得出在喝茶
static func _rest_teacup(im: Image) -> void:
	fill_rect(im, 12, 30, 8, 1, TEACUP)
	fill_rect(im, 13, 31, 6, 2, TEACUP.darkened(0.1))
	fill_rect(im, 14, 33, 4, 1, TEACUP.darkened(0.32))
	fill_rect(im, 13, 30, 6, 1, MATCHA)
	px(im, 13, 30, MATCHA.lightened(0.22))
	px(im, 12, 31, TEACUP.lightened(0.06))

## 头：接近正圆的球 + 两团包子脸，五官整体压低到圆的下半部，幼态比例靠这个撑起来
static func _head(im: Image, sp: Dictionary, t: Dictionary, open_eyes: bool, towel: bool) -> void:
	fill_ball(im, 16.0, 13.5, 10.4, 9.8, t)
	fill_ball(im, 9.0, 18.5, 4.0, 3.4, t)
	fill_ball(im, 23.0, 18.5, 4.0, 3.4, t)
	# 熊猫的耳朵与眼圈同色：整套耳部明度换成暗色派生，白耳会让它像戴了顶白帽
	var et := t
	if sp.get("ear_dark", false):
		et = tones(t.dark, t.dark, t.belly)
	_draw_ear(im, String(sp.get("ear", "round")), et)
	if sp.get("horn", false):
		for bx in [6, 25]:
			fill_rect(im, bx, 6, 2, 3, t.belly_lit)
			px(im, bx, 5, t.belly)
			px(im, bx + 1, 8, t.belly_shade)
	if sp.get("spikes", false):
		_draw_spikes(im, t)
	_top_tuft(im, t)
	if sp.get("comb", false):
		# 齿冠必须留出 2 像素厚的内芯：单像素部件会被 outline_and_rim 整个描成轮廓色，红就没了
		fill_rect(im, 14, 3, 5, 2, COMB)
		fill_rect(im, 12, 4, 2, 2, COMB)
		fill_rect(im, 18, 4, 2, 2, COMB)
		px(im, 16, 2, COMB)
		px(im, 15, 5, COMB.darkened(0.24))
		px(im, 17, 5, COMB.darkened(0.24))
	if towel:
		_towel(im)
	if sp.has("spots"):
		px(im, 10, 8, t.belly_lit)
		px(im, 21, 7, t.belly_lit)
		px(im, 18, 9, t.belly_lit)
	if sp.has("patch"):
		fill_ellipse(im, 21.5, 10.0, 3.6, 3.0, hex(sp.patch))
	# 口鼻区比脸浅一圈，鼻子和嘴才有落点
	fill_ball(im, 16.0, 19.5, 5.4, 3.8, tones(t.belly, t.belly, t.dark))
	if sp.has("mask"):
		for pair in [[8, 15], [17, 24]]:
			fill_ellipse(im, float(pair[0] + 3), 13.5, 3.8, 3.2, t.dark)
		# 熊猫的眼斑本身是黑的，不先垫一层浅色巩膜，深色眼珠画上去就是一团糊
		if sp.has("mask_eye"):
			var sclera := hex(sp.mask_eye)
			for cx in [11, 20]:
				fill_ellipse(im, float(cx) + 0.5, 13.0, 1.8, 1.7, sclera)
	_eyes(im, open_eyes, t)
	_mouth(im, sp, t)
	if sp.has("snout"):
		# 猪的辨识点是那张横鼻子：普通鼻嘴在正面太小，先擦掉再压一枚猪鼻
		var sn := hex(sp.snout)
		fill_ellipse(im, 16.0, 19.0, 4.4, 2.8, sn)
		fill_ellipse(im, 15.4, 18.4, 3.4, 1.9, sn.lightened(0.12))
		for nx in [14, 18]:
			px(im, nx, 19, sn.darkened(0.45))
			px(im, nx, 20, sn.darkened(0.32))
	if sp.get("cheek", false):
		for bx in [5, 25]:
			fill_rect(im, bx, 15, 2, 2, BLUSH.lightened(0.18))

## 头顶一撮呆毛：打破光滑椭圆，正面看最有辨识度
static func _top_tuft(im: Image, t: Dictionary) -> void:
	for x in [13, 15, 17, 19]:
		px(im, x, 4, t.lit)
	px(im, 14, 3, t.base)
	px(im, 18, 3, t.base)

## 浴衣（正面）：两只振袖 + 交领右衽 + 腰前带结 + 圆弧下摆
static func _draw_yukata(im: Image, yukata: Color, t: Dictionary) -> void:
	var body := yukata
	var lit := yukata.lightened(0.14)
	var shade := yukata.darkened(0.2)
	var deep := yukata.darkened(0.36)
	# 衣身：肩收、下摆张，底边收圆，整块是蛋形而不是方块
	for y in range(21, 36):
		var half := 5 + int(maxi(0, y - 29) * 0.45)
		for x in range(16 - half, 16 + half + 1):
			var c := body
			if x <= 13:
				c = lit
			elif x >= 18:
				c = shade
			px(im, x, y, c)
	# 振袖：宽袖口垂到腰下，袖里露爪子
	for pair in [[5, false], [22, true]]:
		var sx: int = pair[0]
		var is_right: bool = pair[1]
		for y in range(22, 31):
			var w := 5 if y < 27 else 4
			for i in w:
				var c := lit
				if is_right:
					c = shade if i >= w - 2 else body
				elif i >= w - 1:
					c = body
				px(im, sx + i, y, c)
			if y >= 29:
				for i in w:
					px(im, sx + i, y, deep)
	# 交领：从左肩压向右腰，V 里露出胸毛
	for i in 6:
		var y := 24 + i
		px(im, 12 + i, y, deep)
		px(im, 20 - i, y, deep)
		for x in range(13 + i, 20 - i):
			px(im, x, y, t.belly if x < 16 else t.belly_shade)
	# 腰带与腰前带结
	fill_rect(im, 10, 29, 12, 3, deep)
	fill_rect(im, 10, 29, 12, 1, lit.darkened(0.08))
	fill_rect(im, 13, 28, 7, 5, body.lightened(0.28))
	fill_rect(im, 13, 28, 7, 1, body.lightened(0.42))
	px(im, 15, 30, deep)
	px(im, 17, 30, deep)
	fill_rect(im, 13, 32, 7, 1, deep)
	# 下摆褶皱与投影
	for x in [13, 16, 19]:
		for y in range(33, 36):
			px(im, x, y, shade)
	px(im, 11, 35, deep)
	px(im, 12, 35, deep)
	px(im, 19, 35, deep)
	px(im, 20, 35, deep)

## 爪子：从袖口下探出来，两像素宽的趾缝。
## sway 是手臂的前后摆：正面视角没有前后景深，只能靠上下这一格读——
## 抬腿那侧的爪子荡到后面（上移），撑地那侧的甩到前面（下移），与对侧脚同步才有迈步的重量。
static func _draw_paw(im: Image, x: int, t: Dictionary, sway := 0) -> void:
	var y := 29 + sway
	fill_rect(im, x, y, 5, 3, t.base)
	fill_rect(im, x, y, 5, 1, t.lit)
	fill_rect(im, x + 4, y, 1, 3, t.shade)
	px(im, x + 1, y + 2, t.deep)
	px(im, x + 3, y + 2, t.deep)

## 腿与脚掌：掌宽六格、两脚之间留两格缝，正面才读得出「两条腿分开踩在地上」。
## 小脚掌挨在一起会被看成裙底掉下的一整块，抬脚也就没人看得见。
## 抬脚整只提两格、压一道脚底暗面：离地两格是这个尺寸下还能认出的最小幅度。
static func _draw_leg(im: Image, x: int, t: Dictionary, lifted := false) -> void:
	if lifted:
		fill_rect(im, x, 35, 3, 1, t.shade)
		fill_rect(im, x - 1, 36, 6, 2, t.dark)
		fill_rect(im, x - 1, 36, 6, 1, t.dark_lit)
		fill_rect(im, x - 1, 37, 6, 1, t.deep)
		return
	fill_rect(im, x, 35, 3, 3, t.shade)
	fill_rect(im, x - 1, 38, 6, 2, t.dark)
	fill_rect(im, x - 1, 38, 6, 1, t.dark_lit)
	fill_rect(im, x, 39, 4, 1, t.deep)

static func _draw_ear(im: Image, kind: String, t: Dictionary) -> void:
	match kind:
		"round":
			_ear_ball(im, 8.0, 5.5, t)
			_ear_ball(im, 24.0, 5.5, t)
		"point":
			fill_tri(im, 5, 12, 4, 2, 13, 7, t.base)
			fill_tri(im, 27, 12, 28, 2, 19, 7, t.shade)
			fill_tri(im, 7, 10, 7, 5, 11, 8, t.belly_shade)
			fill_tri(im, 25, 10, 25, 5, 21, 8, t.belly_shade)
		"long":
			for side in [[9.5, false], [22.5, true]]:
				var cx: float = side[0]
				var is_right: bool = side[1]
				fill_ellipse(im, cx, 6.0, 2.6, 5.6, t.shade if is_right else t.base)
				fill_ellipse(im, cx, 6.4, 1.3, 3.8, t.belly_shade)
				px(im, int(cx) - 1, 2, t.lit)
		"antler":
			for side in [[10, -1], [22, 1]]:
				var bx: int = side[0]
				var dir: int = side[1]
				for i in range(8):
					px(im, bx + int(dir * i * 0.4), 12 - i, t.dark)
				px(im, bx + dir * 2, 8, t.dark)
				px(im, bx + dir * 3, 7, t.dark)
				px(im, bx - dir * 1, 6, t.dark)
				px(im, bx - dir * 2, 5, t.dark)
				px(im, bx + dir * 1, 10, t.dark_lit)
		"none":
			pass

static func _ear_ball(im: Image, cx: float, cy: float, t: Dictionary) -> void:
	fill_ellipse(im, cx, cy, 3.8, 3.8, t.shade)
	fill_ellipse(im, cx - 0.6, cy - 0.6, 2.8, 2.8, t.base)
	fill_ellipse(im, cx, cy + 0.8, 1.6, 1.6, t.belly_shade)
	px(im, int(cx) - 2, int(cy) - 2, t.lit)

static func _draw_tail(im: Image, kind: String, t: Dictionary, ring: bool) -> void:
	match kind:
		"stub":
			fill_ellipse(im, 27.5, 31.0, 2.8, 2.8, t.shade)
			px(im, 26, 29, t.lit)
		"curl":
			fill_ellipse(im, 28.0, 29.0, 3.0, 3.8, t.base)
			fill_ellipse(im, 29.0, 26.0, 2.0, 2.0, t.belly)
			px(im, 26, 27, t.lit)
		"fluffy":
			fill_ellipse(im, 28.0, 27.0, 3.6, 5.8, t.base)
			fill_ellipse(im, 29.2, 22.5, 2.2, 2.2, t.belly_lit)
			fill_ellipse(im, 27.0, 30.0, 2.0, 3.0, t.shade)
			if ring:
				for y in [31, 27, 23]:
					fill_rect(im, 25, y, 7, 1, t.deep)
		"flat":
			fill_ellipse(im, 28.5, 32.0, 4.0, 2.2, t.shade)
			fill_rect(im, 25, 31, 7, 1, t.lit)
		"fin":
			fill_tri(im, 25, 33, 31, 29, 29, 36, t.shade)
			px(im, 27, 32, t.lit)
		"none":
			pass

## 刺猬：头两侧各一排硬刺，从圆头轮廓外探出
static func _draw_spikes(im: Image, t: Dictionary) -> void:
	for side in [-1, 1]:
		for i in 4:
			var x: int = 16 + side * (8 + i)
			var y := 8 + i * 3
			px(im, x, y, t.dark)
			px(im, x, y + 1, t.dark_lit)
			px(im, x + side, y, t.deep)

static func _soak(sp: Dictionary, t: Dictionary) -> Image:
	var im := make_image(SOAK_W, SOAK_H)
	# 没入水中的肩背先画：水线压在画布底边，只露头
	var wet := tones(t.base.darkened(0.12), t.belly, t.dark)
	fill_ball(im, 16.0, 27.0, 11.0, 6.0, wet)
	fill_rect(im, 5, 23, 22, 1, Color(0.72, 0.9, 0.94, 0.5))
	_head(im, sp, t, false, true)
	outline_and_rim(im)
	# 肩背正好被画布底边切平，描边会留一道通宽暗线、读成一块木板；
	# 沿剪影底缘压一道亮水色，水面才像是绕着身体破开
	for x in SOAK_W:
		if im.get_pixel(x, SOAK_H - 2).a > 0.5:
			px(im, x, SOAK_H - 1, Color(0.72, 0.92, 0.96, 0.75))
			px(im, x, SOAK_H - 2, Color(0.86, 0.97, 1.0, 0.45))
	return im

## 头顶折叠毛巾：上缘受光、下缘投影，中间一道蓝条
static func _towel(im: Image) -> void:
	fill_ellipse(im, 16.0, 4.5, 8.6, 3.6, TOWEL.darkened(0.16))
	fill_ellipse(im, 15.4, 3.8, 7.6, 2.8, TOWEL)
	fill_rect(im, 8, 5, 17, 1, TOWEL_STRIPE)
	fill_rect(im, 8, 7, 17, 1, TOWEL.darkened(0.3))
	px(im, 11, 2, Color(1, 1, 1))
	px(im, 12, 2, Color(1, 1, 1))

## 眼睛：睁开是大颗圆眼加高光，闭眼是两道弯弧——泡汤时一律是享受的表情
static func _eyes(im: Image, open_eyes: bool, t: Dictionary) -> void:
	for cx in [11, 20]:
		if open_eyes:
			fill_rect(im, cx, 12, 2, 3, EYE)
			px(im, cx, 12, Color(0.95, 0.95, 0.97))
			px(im, cx + 1, 14, EYE.darkened(0.3))
		else:
			px(im, cx - 1, 14, EYE)
			px(im, cx, 13, EYE)
			px(im, cx + 1, 14, EYE)
	for bx in [6, 24]:
		fill_rect(im, bx, 17, 2, 2, BLUSH)
		px(im, bx, 16, BLUSH.lightened(0.16))

## 口鼻：喙 / 猫科鼻嘴 / 普通鼻嘴，三选一
static func _mouth(im: Image, sp: Dictionary, t: Dictionary) -> void:
	if sp.has("beak"):
		var beak: Color = hex(sp.beak)
		fill_rect(im, 13, 18, 6, 3, beak.darkened(0.1))
		fill_rect(im, 13, 18, 6, 1, beak.lightened(0.18))
		fill_rect(im, 14, 21, 4, 1, beak.darkened(0.3))
		px(im, 14, 19, beak.lightened(0.32))
		return
	if sp.get("whisk", false):
		for y in [18, 20]:
			px(im, 4, y, t.belly_lit)
			px(im, 3, y + 1, t.belly_lit)
			px(im, 27, y, t.belly_shade)
			px(im, 28, y + 1, t.belly_shade)
	fill_rect(im, 15, 18, 2, 2, t.dark)
	px(im, 15, 18, t.dark_lit)
	px(im, 14, 20, t.dark)
	px(im, 15, 21, t.dark)
	px(im, 17, 21, t.dark)
	px(im, 18, 20, t.dark)

const WOOD := Color(0.54, 0.35, 0.19)
const WOOD_DARK := Color(0.35, 0.22, 0.11)
const WOOD_LIGHT := Color(0.72, 0.5, 0.28)
const PAPER := Color(0.95, 0.89, 0.76)
const RED := Color(0.78, 0.31, 0.24)
const GLOW := Color(1.0, 0.82, 0.45)
const LEAF := Color(0.31, 0.54, 0.29)
const LEAF_LIGHT := Color(0.45, 0.7, 0.4)
const METAL := Color(0.72, 0.76, 0.8)
const INDIGO := Color(0.24, 0.3, 0.52)

static var _facility_cache := {}

static func facility_texture(id: String) -> ImageTexture:
	if not _facility_cache.has(id):
		_facility_cache[id] = ImageTexture.create_from_image(make_facility(id))
	return _facility_cache[id]

static func make_facility(id: String) -> Image:
	match id:
		"lantern": return _f_lantern()
		"bench": return _f_bench()
		"vender": return _f_vender()
		"camera": return _f_camera()
		"plant": return _f_plant()
		"bucket": return _f_bucket()
		"tea": return _f_tea()
	return make_image(8, 8)

static func _line(im: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy
	while true:
		px(im, x0, y0, c)
		if x0 == x1 and y0 == y1:
			return
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

## 纸灯笼：直筒鼓身，中间透出暖光、两侧收红，横向纸骨，上下黑漆座与短穗
static func _f_lantern() -> Image:
	var im := make_image(16, 20)
	px(im, 7, 0, WOOD_DARK)
	px(im, 8, 0, WOOD_DARK)
	fill_rect(im, 5, 1, 6, 1, WOOD_DARK)
	var columns := [
		[3, RED.darkened(0.22)], [4, RED], [5, RED.lightened(0.18)],
		[6, GLOW.darkened(0.12)], [7, GLOW], [8, GLOW], [9, GLOW.darkened(0.12)],
		[10, RED.lightened(0.18)], [11, RED], [12, RED.darkened(0.22)],
	]
	for y in range(2, 17):
		for pair in columns:
			px(im, int(pair[0]), y, pair[1])
	for y in [5, 9, 13]:
		fill_rect(im, 3, y, 10, 1, RED.darkened(0.34))
	fill_rect(im, 4, 17, 8, 1, WOOD_DARK)
	px(im, 7, 18, RED.darkened(0.05))
	px(im, 8, 18, RED.darkened(0.05))
	px(im, 7, 19, RED.darkened(0.3))
	inner_outline(im)
	return im

## 木长椅：两道靠背横木 + 座板 + 四条腿
static func _f_bench() -> Image:
	var im := make_image(28, 14)
	fill_rect(im, 3, 1, 22, 1, WOOD)
	fill_rect(im, 3, 4, 22, 1, WOOD)
	fill_rect(im, 4, 1, 2, 6, WOOD_DARK)
	fill_rect(im, 22, 1, 2, 6, WOOD_DARK)
	fill_rect(im, 2, 7, 24, 3, WOOD)
	fill_rect(im, 2, 7, 24, 1, WOOD_LIGHT)
	fill_rect(im, 4, 10, 3, 4, WOOD_DARK)
	fill_rect(im, 21, 10, 3, 4, WOOD_DARK)
	return im

## 零食摊：红白条纹暖帘 + 木台 + 两只点心碗
static func _f_vender() -> Image:
	var im := make_image(30, 26)
	for x in range(2, 28):
		var c: Color = RED if (int(x / 3.0) % 2 == 0) else PAPER
		fill_rect(im, x, 0, 1, 4, c)
	for x in range(2, 28, 3):
		px(im, x + 1, 4, RED.darkened(0.2))
	fill_rect(im, 2, 4, 2, 18, WOOD_DARK)
	fill_rect(im, 26, 4, 2, 18, WOOD_DARK)
	fill_rect(im, 4, 14, 22, 6, WOOD)
	fill_rect(im, 4, 14, 22, 1, WOOD_LIGHT)
	fill_ellipse(im, 10.0, 13.0, 3.0, 1.6, PAPER)
	fill_ellipse(im, 19.0, 13.0, 3.0, 1.6, PAPER)
	fill_rect(im, 9, 12, 3, 1, Color(0.85, 0.6, 0.3))
	fill_rect(im, 18, 12, 3, 1, Color(0.85, 0.6, 0.3))
	fill_rect(im, 6, 20, 18, 4, INDIGO)
	px(im, 11, 22, PAPER)
	px(im, 18, 22, PAPER)
	fill_rect(im, 3, 24, 24, 2, WOOD_DARK)
	return im

## 拍照角：三脚架上的方盒子相机，闪光灯高亮
static func _f_camera() -> Image:
	var im := make_image(20, 20)
	fill_rect(im, 4, 3, 12, 7, Color(0.28, 0.3, 0.36))
	fill_rect(im, 4, 3, 12, 1, METAL)
	fill_rect(im, 8, 1, 4, 2, Color(0.28, 0.3, 0.36))
	fill_ellipse(im, 10.0, 7.0, 2.6, 2.6, Color(0.1, 0.11, 0.14))
	px(im, 9, 6, Color(0.45, 0.55, 0.75))
	fill_rect(im, 14, 4, 2, 2, GLOW)
	_line(im, 10, 10, 6, 19, WOOD_DARK)
	_line(im, 10, 10, 14, 19, WOOD_DARK)
	_line(im, 10, 10, 10, 19, WOOD_DARK)
	return im

## 盆栽景：三层苔绿树冠 + 陶盆
static func _f_plant() -> Image:
	var im := make_image(16, 20)
	fill_ellipse(im, 8.0, 7.0, 5.0, 4.6, LEAF)
	fill_ellipse(im, 4.5, 10.0, 3.2, 3.0, LEAF)
	fill_ellipse(im, 11.5, 10.0, 3.2, 3.0, LEAF)
	fill_ellipse(im, 7.0, 5.5, 2.6, 2.2, LEAF_LIGHT)
	px(im, 11, 9, LEAF_LIGHT)
	px(im, 5, 12, LEAF_LIGHT)
	fill_rect(im, 8, 12, 1, 3, WOOD_DARK)
	fill_rect(im, 3, 14, 10, 2, Color(0.66, 0.37, 0.26))
	fill_rect(im, 4, 16, 8, 3, Color(0.55, 0.3, 0.21))
	px(im, 5, 18, Color(0.42, 0.23, 0.16))
	px(im, 10, 18, Color(0.42, 0.23, 0.16))
	inner_outline(im)
	return im

## 木桶架：铁箍杉木桶 + 水面 + 挂勺
static func _f_bucket() -> Image:
	var im := make_image(18, 20)
	fill_rect(im, 3, 6, 12, 10, WOOD)
	for x in [5, 8, 11]:
		fill_rect(im, x, 6, 1, 10, WOOD_DARK)
	fill_rect(im, 3, 8, 12, 1, METAL)
	fill_rect(im, 3, 13, 12, 1, METAL)
	fill_rect(im, 4, 6, 10, 1, Color(0.55, 0.78, 0.82))
	fill_rect(im, 2, 5, 14, 1, WOOD_LIGHT)
	fill_rect(im, 2, 16, 2, 4, WOOD_DARK)
	fill_rect(im, 14, 16, 2, 4, WOOD_DARK)
	_line(im, 15, 2, 11, 6, WOOD_LIGHT)
	fill_rect(im, 9, 6, 3, 2, WOOD_LIGHT)
	return im

## 茶点桌：矮木桌 + 铁壶 + 两只麦茶杯
static func _f_tea() -> Image:
	var im := make_image(26, 14)
	fill_rect(im, 2, 6, 22, 2, WOOD)
	fill_rect(im, 2, 6, 22, 1, WOOD_LIGHT)
	fill_rect(im, 2, 8, 22, 1, WOOD_DARK)
	fill_rect(im, 3, 9, 2, 5, WOOD_DARK)
	fill_rect(im, 21, 9, 2, 5, WOOD_DARK)
	fill_ellipse(im, 10.0, 4.0, 3.4, 2.6, Color(0.3, 0.34, 0.32))
	fill_rect(im, 8, 1, 4, 1, Color(0.22, 0.25, 0.24))
	px(im, 10, 0, METAL)
	fill_rect(im, 13, 3, 2, 1, Color(0.3, 0.34, 0.32))
	fill_rect(im, 17, 3, 3, 3, PAPER)
	fill_rect(im, 21, 3, 3, 3, PAPER)
	fill_rect(im, 17, 3, 3, 1, Color(0.5, 0.62, 0.42))
	fill_rect(im, 21, 3, 3, 1, Color(0.5, 0.62, 0.42))
	return im

static func make_ripple(width: int) -> Image:
	var im := make_image(width, 6)
	var rx := float(width) * 0.5 - 1.0
	for x in width:
		var dx := (float(x) - rx) / rx
		var t := 1.0 - dx * dx
		if t <= 0.0:
			continue
		var y_top := int(3.0 - 2.0 * sqrt(t))
		var y_bot := int(3.0 + 2.0 * sqrt(t))
		px(im, x, y_top, Color(0.9, 0.99, 1.0, 0.85))
		px(im, x, y_bot, Color(0.9, 0.99, 1.0, 0.6))
	return im

static func make_heart() -> Image:
	var im := make_image(7, 6)
	var shape := [
		" XX XX ",
		"XXXXXXX",
		"XXXXXXX",
		" XXXXX ",
		"  XXX  ",
		"   X   ",
	]
	for y in shape.size():
		for x in shape[y].length():
			if shape[y][x] == "X":
				px(im, x, y, Color(0.98, 0.45, 0.6, 1.0))
	return im

static func make_steam_puff() -> Image:
	var im := make_image(8, 8)
	fill_ellipse(im, 3.5, 5.0, 3.0, 2.5, Color(1, 1, 1, 0.5))
	fill_ellipse(im, 4.5, 2.5, 2.0, 2.0, Color(1, 1, 1, 0.35))
	return im
