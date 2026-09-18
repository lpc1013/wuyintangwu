extends SceneTree
## 导出精灵对照表：20 物种 × (站立 / 迈步两帧 / 泡汤 / 落座)，用于校验属性驱动的程序化像素造型。
## 用法：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/spritesheet.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。

const OUT := "res://../vibe_images/_sprite_sheet.png"
const COLS := 4
const CELL := 170
const SCALE := 3
## 三张行走帧并排才看得出步态差多少：同一只动物的 walk / stepL / stepR 落在同格列的三个区块里
const POSES := ["walk", "stepL", "stepR", "soak", "rest"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var ids: Array = GameData.species_ids()
	var rows := int(ceil(float(ids.size()) / float(COLS)))
	var fids: Array = GameData.FACILITY_IDS
	var img := Image.create(CELL * (POSES.size() * COLS + 1), CELL * (rows + 2), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.11, 0.08, 0.14, 1.0))
	_grid(img, rows + 1)
	for i in ids.size():
		var id := String(ids[i])
		var r := i / COLS
		var c := i % COLS
		for p in POSES.size():
			var pose: String = POSES[p]
			# 同一只动物五个姿态共用一件浴衣：换了颜色就没法直接比出三帧行走的差别
			var yukata: Color = PixelArt.YUKATA[i % PixelArt.YUKATA.size()]
			var tex := PixelArt.make_animal(id, yukata, pose)
			var ox := ((p * COLS + c) + 1) * CELL + (CELL - tex.get_width() * SCALE) / 2
			var oy := (r + 1) * CELL + (CELL - tex.get_height() * SCALE) / 2
			_blit_scaled(img, tex, ox, oy)
	# 设施带：按 FACILITY_IDS 顺序横排
	for i in fids.size():
		var fid := String(fids[i])
		var ftex := PixelArt.make_facility(fid)
		var fx := (i + 1) * CELL + (CELL - ftex.get_width() * SCALE) / 2
		var fy := (rows + 1) * CELL + (CELL - ftex.get_height() * SCALE) / 2
		_blit_scaled(img, ftex, fx, fy)
	# 参考件：水波环 / 心心 / 茶烟
	var ripple := PixelArt.make_ripple(20)
	_blit_scaled(img, ripple, CELL, CELL / 2 - 8)
	var heart := PixelArt.make_heart()
	_blit_scaled(img, heart, CELL * 2, CELL / 2 - 8)
	var puff := PixelArt.make_steam_puff()
	_blit_scaled(img, puff, CELL * 3, CELL / 2 - 12)
	var err := img.save_png(OUT)
	print("spritesheet err=", err, " species=", ids.size(), " facilities=", fids.size(), " -> ", OUT)
	quit()

## 每格画十字准星，便于判断精灵是否居中 / 是否贴住底部锚
func _grid(img: Image, rows: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var line := Color(0.3, 0.9, 1.0, 0.35)
	for cx in range(CELL, w, CELL):
		for cy in h:
			img.set_pixel(cx, cy, line)
	for cy in range(CELL, h, CELL):
		for cx in w:
			img.set_pixel(cx, cy, line)

func _blit_scaled(img: Image, src: Image, x: int, y: int) -> void:
	for sy in src.get_height():
		for sx in src.get_width():
			var c: Color = src.get_pixel(sx, sy)
			if c.a <= 0.0:
				continue
			for dy in SCALE:
				for dx in SCALE:
					var px := x + sx * SCALE + dx
					var py := y + sy * SCALE + dy
					if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
						img.set_pixel(px, py, c)
