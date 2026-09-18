class_name PixelArt
## 程序化像素精灵工厂：按 GameData.SPECIES 的属性（耳型/尾型/体型/面部标记）组合绘制，
## 与 HTML 版同一立意——不依赖外部素材表，代码逐像素绘制。
## 行走为背影（只见耳/尾/背部花纹），泡汤为正面露头（可见面部标记）。

const OUTLINE := Color(0.16, 0.1, 0.14, 1.0)
const TOWEL := Color(0.97, 0.97, 0.95)
const TOWEL_STRIPE := Color(0.62, 0.78, 0.9)
const BLUSH := Color(0.98, 0.6, 0.66)
const EYE := Color(0.2, 0.14, 0.16)

const YUKATA := [
	Color(0.25, 0.3, 0.55), Color(0.95, 0.6, 0.7), Color(0.45, 0.65, 0.4),
	Color(0.6, 0.5, 0.8), Color(0.95, 0.65, 0.3), Color(0.3, 0.6, 0.6),
]

const WALK_W := 24
const WALK_H := 28
const SOAK_W := 24
const SOAK_H := 18

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
	var im: Image
	if pose == "soak":
		im = _soak(sp, body, belly, dark)
	else:
		im = _walk(sp, body, belly, dark, yukata)
	return _rescaled(im, float(sp.get("size", 1.0)))

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

static func _walk(sp: Dictionary, body: Color, belly: Color, dark: Color, yukata: Color) -> Image:
	var im := make_image(WALK_W, WALK_H)
	var ear: String = sp.get("ear", "round")
	# 头（背影：整个头是毛色，耳型是主要区分）
	fill_ellipse(im, 11.5, 8.5, 6.4, 5.6, body)
	_draw_ear(im, ear, body, belly, dark)
	# 后颈毛：把头与肩连成一体，避免头浮在浴衣上
	fill_rect(im, 9, 12, 6, 4, body)
	# 尾巴画在躯干之前：只从身侧探出，根部被手臂遮住
	_draw_tail(im, String(sp.get("tail", "stub")), body, belly, dark, sp.get("ring", false))
	# 三花猫的斑块 / 奶牛的花斑：落在头背
	if sp.has("patch"):
		fill_ellipse(im, 8.0, 6.5, 2.6, 2.2, hex(sp.patch))
	if sp.has("spots2"):
		fill_ellipse(im, 9.0, 6.0, 2.0, 1.6, dark)
		fill_ellipse(im, 13.0, 21.0, 2.2, 1.8, dark)
	# 浴衣：比头窄一圈，好让两侧的手臂露出毛色
	fill_rect(im, 7, 15, 10, 11, yukata)
	fill_rect(im, 7, 15, 10, 1, body.darkened(0.18))      # 领口露出的肩背
	fill_rect(im, 7, 19, 10, 2, yukata.darkened(0.35))    # 腰带
	fill_rect(im, 10, 19, 4, 2, yukata.lightened(0.3))    # 带结
	fill_rect(im, 7, 25, 10, 1, yukata.darkened(0.2))     # 下摆
	# 手臂与爪子
	fill_rect(im, 4, 16, 3, 6, body)
	fill_rect(im, 17, 16, 3, 6, body)
	fill_rect(im, 4, 22, 3, 2, dark)
	fill_rect(im, 17, 22, 3, 2, dark)
	# 刺猬：背上竖一排硬刺
	if sp.get("spikes", false):
		for i in range(8, 17, 2):
			px(im, i, 17, dark)
			px(im, i, 21, dark)
	# 脚
	fill_rect(im, 8, 26, 3, 2, dark)
	fill_rect(im, 13, 26, 3, 2, dark)
	inner_outline(im)
	return im

static func _draw_ear(im: Image, kind: String, body: Color, belly: Color, dark: Color) -> void:
	match kind:
		"round":
			fill_ellipse(im, 7.0, 4.2, 2.4, 2.4, body)
			fill_ellipse(im, 16.0, 4.2, 2.4, 2.4, body)
		"point":
			fill_tri(im, 6, 8, 5, 2, 10, 6, body)
			fill_tri(im, 17, 8, 18, 2, 13, 6, body)
		"long":
			fill_ellipse(im, 8.0, 2.5, 1.6, 4.0, body)
			fill_ellipse(im, 15.0, 2.5, 1.6, 4.0, body)
			fill_ellipse(im, 8.0, 2.8, 0.8, 2.6, belly)
			fill_ellipse(im, 15.0, 2.8, 0.8, 2.6, belly)
		"antler":
			fill_rect(im, 7, 1, 1, 6, dark)
			fill_rect(im, 15, 1, 1, 6, dark)
			px(im, 6, 2, dark)
			px(im, 8, 4, dark)
			px(im, 16, 2, dark)
			px(im, 14, 4, dark)
		"none":
			pass

static func _draw_tail(im: Image, kind: String, body: Color, belly: Color, dark: Color, ring: bool) -> void:
	match kind:
		"stub":
			fill_ellipse(im, 20.0, 21.0, 1.8, 1.8, body.darkened(0.1))
		"curl":
			fill_ellipse(im, 20.4, 20.0, 2.2, 2.8, body)
			fill_ellipse(im, 21.0, 17.6, 1.3, 1.3, belly)
		"fluffy":
			fill_ellipse(im, 20.6, 19.0, 2.6, 4.2, body)
			fill_ellipse(im, 21.2, 15.6, 1.6, 1.6, belly)
			if ring:
				px(im, 20, 20, dark)
				px(im, 21, 20, dark)
				px(im, 20, 17, dark)
				px(im, 21, 17, dark)
		"flat":
			fill_ellipse(im, 20.6, 22.0, 2.8, 1.4, body.darkened(0.12))
		"fin":
			fill_tri(im, 19, 22, 22, 20, 21, 24, body.darkened(0.15))
		"none":
			pass

static func _soak(sp: Dictionary, body: Color, belly: Color, dark: Color) -> Image:
	var im := make_image(SOAK_W, SOAK_H)
	var ear: String = sp.get("ear", "round")
	fill_ellipse(im, 11.5, 9.0, 6.0, 5.5, body)
	_draw_ear(im, ear, body, belly, dark)
	if sp.get("horn", false):
		px(im, 6, 3, belly.lightened(0.1))
		px(im, 17, 3, belly.lightened(0.1))
	if sp.has("spots"):
		px(im, 9, 6, belly)
		px(im, 14, 5, belly)
		px(im, 12, 4, belly)
	if sp.has("patch"):
		fill_ellipse(im, 15.5, 7.0, 2.2, 1.8, hex(sp.patch))
	# 头顶折叠毛巾
	fill_ellipse(im, 11.5, 4.0, 5.5, 2.0, TOWEL)
	fill_rect(im, 7, 4, 10, 1, TOWEL_STRIPE)
	# 面部：闭眼 + 腮红 + 口鼻
	fill_rect(im, 9, 10, 2, 1, EYE)
	fill_rect(im, 13, 10, 2, 1, EYE)
	px(im, 7, 11, BLUSH)
	px(im, 16, 11, BLUSH)
	if sp.has("mask"):
		fill_rect(im, 8, 9, 3, 2, dark)
		fill_rect(im, 12, 9, 3, 2, dark)
		px(im, 9, 10, Color(0.98, 0.98, 0.96))
		px(im, 13, 10, Color(0.98, 0.98, 0.96))
	if sp.has("beak"):
		fill_rect(im, 10, 12, 3, 1, hex(sp.beak))
	elif sp.get("whisk", false):
		px(im, 6, 12, belly)
		px(im, 17, 12, belly)
		px(im, 5, 11, belly)
		px(im, 18, 11, belly)
		fill_rect(im, 11, 12, 2, 1, belly.lightened(0.15))
	else:
		fill_rect(im, 11, 12, 2, 1, belly.lightened(0.15))
	if sp.get("cheek", false):
		px(im, 6, 10, BLUSH.lightened(0.2))
		px(im, 17, 10, BLUSH.lightened(0.2))
	if sp.get("spikes", false):
		for i in range(5, 19, 2):
			px(im, i, 14, dark)
	# 肩部没入水面
	fill_ellipse(im, 11.5, 17.0, 6.5, 3.0, body.darkened(0.08))
	inner_outline(im)
	return im

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
