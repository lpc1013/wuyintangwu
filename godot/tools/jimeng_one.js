// 即梦逐物种产图驱动：一次调用领一只还没出图的物种，提交 → 等图 → 逐张开详情抓原图。
// 跑法：tabbit-cli nodejs --task jimg --request-id <id> --timeout-ms 180000 < 本文件
// 自己读 todo.json 挑活，中断后重跑同一份就接着往下走；进度就是 ai_raw 目录里有没有文件。
const fs = require("fs")
const ROOT = "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal"
const RAW = ROOT + "/vibe_images/ai_raw"
const ALT = RAW + "/alt"

const todo = JSON.parse(fs.readFileSync(RAW + "/todo.json", "utf8"))
const have = new Set(fs.readdirSync(RAW).map(f => f.toLowerCase()))
const item = todo.find(t => ![ ".webp", ".png", ".jpg", ".jpeg" ].some(e => have.has(t.id + e)))
if (!item) return { idle: true, left: 0 }
if (!fs.existsSync(ALT)) fs.mkdirSync(ALT, { recursive: true })

// 每次都要回到干净的生成页：出过一次图之后 URL 会带上 workspace=...，页面进到会话态，
// 那里的 submit 按钮两层叠在一起，点下去什么也不会发
await page.goto("https://jimeng.jianying.com/ai-tool/generate?type=image", { waitUntil: "domcontentloaded", timeout: 60000 })
// 站点偶发一个 Uncaught TypeError，输入框根本不渲染；固定等几秒不如直接等它出现
const waitEd = () => page.waitForSelector('.tiptap.ProseMirror', { timeout: 25000 }).then(() => true).catch(() => false)
if (!await waitEd()) {
  await page.reload({ waitUntil: "domcontentloaded", timeout: 60000 })
  if (!await waitEd()) return { id: item.id, error: "composer-never-appeared" }
}
await page.waitForTimeout(3000)
await page.keyboard.press("Escape")
await page.waitForTimeout(600)

// 签名 URL 的域名前缀（p11/p26）和 aigc_resize 尺寸段都会变，只有 ~ 前面那段是图的身份证
const cardKeys = () => page.evaluate(() => [...document.querySelectorAll('img[src*="aigc_resize"]')]
  .map(i => new URL(i.src).pathname.split("~")[0]))

const head = (await cardKeys())[0] || ""

const ed = page.locator('.tiptap.ProseMirror').first()
await ed.click({ force: true, timeout: 15000 })
await page.keyboard.press("Control+A")
await page.keyboard.press("Delete")
await page.keyboard.insertText(item.prompt)
await page.waitForTimeout(600)
const submitBtn = await page.evaluate(() => {
  const b = [...document.querySelectorAll('button[class*="submit"]')]
    .find(x => x.getBoundingClientRect().width > 8 && x.getBoundingClientRect().height > 8)
  if (!b) return null
  const r = b.getBoundingClientRect()
  b.click()
  return { x: r.x + r.width / 2, y: r.y + r.height / 2 }
})
await page.waitForTimeout(2000)
// 提交成功的凭据是 URL 跳进了新会话（workspace=...）。输入框清空不能用：
// 会话视图的 composer 会把这条提示词原样回显，拿它判会永远判成失败，白重跑一次生成
const took = () => page.url().includes("workspace=")
if (!await took()) {
  if (!submitBtn) return { id: item.id, error: "no-submit-button" }
  await page.mouse.click(submitBtn.x, submitBtn.y)
  await page.waitForTimeout(2500)
  if (!await took()) return { id: item.id, error: "submit-did-not-take" }
}

// 出图约 60~70s，四张卡还会陆续渲染，所以要攒够 4 张再收工。
// 整趟要留在 tabbit 的 180s 上限内：导航 10s + 提交 6s + 轮询 90s + 四次开详情 18s。
// 判据用「列表第一张换了没」而不是和提交前的全集做差集：历史是懒加载的，
// 提交前那一屏可能还没铺满，差集会把旧图当成新图。
let fresh = []
for (let i = 0; i < 18; i++) {
  await page.waitForTimeout(5000)
  const now = await cardKeys()
  if (now.length && now[0] !== head) fresh = now.slice(0, 4)
  if (fresh.length >= 4) break
}
if (!fresh.length) return { id: item.id, error: "timeout-no-new-image" }

// 每张卡都要点进去才拿得到 1728×2304 原图，列表里只有 540×720 缩略
const grab = async idx => {
  const box = await page.evaluate(n => {
    const im = [...document.querySelectorAll('img[src*="aigc_resize"]')][n]
    if (!im) return null
    const r = im.getBoundingClientRect()
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 }
  }, idx)
  if (!box) return { fail: "no-card" }
  // 卡片在视口外点不到，先滚进来
  await page.evaluate(n => {
    const im = [...document.querySelectorAll('img[src*="aigc_resize"]')][n]
    if (im) im.scrollIntoView({ block: "center" })
  }, idx)
  await page.waitForTimeout(500)
  const b2 = await page.evaluate(n => {
    const r = [...document.querySelectorAll('img[src*="aigc_resize"]')][n].getBoundingClientRect()
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 }
  }, idx)
  await page.mouse.click(b2.x, b2.y)
  await page.waitForTimeout(2600)
  const big = await page.evaluate(() => {
    const best = [...document.querySelectorAll('img')]
      .filter(i => i.naturalWidth >= 1000 && /dreamina/i.test(i.src))
      .sort((a, b) => b.naturalWidth - a.naturalWidth)[0]
    return best ? { src: best.src, w: best.naturalWidth, h: best.naturalHeight } : null
  })
  await page.keyboard.press("Escape")
  await page.waitForTimeout(700)
  if (!big) return { fail: "no-original" }
  const resp = await context.request.get(big.src)
  if (!resp.ok()) return { fail: "http-" + resp.status() }
  return { ok: true, w: big.w, h: big.h, buf: await resp.body() }
}

const saved = []
let primary = ""
for (let i = 0; i < fresh.length; i++) {
  let g = await grab(i)
  if (!g.ok) g = await grab(i) // 弹窗动画没走完时点开是空的，原地再来一次
  if (!g.ok) { saved.push({ i, ...g }); continue }
  const dst = `${ALT}/${item.id}_${i}.webp`
  fs.writeFileSync(dst, g.buf)
  if (!primary) {
    primary = `${RAW}/${item.id}.webp`
    fs.copyFileSync(dst, primary)
  }
  saved.push({ i, file: dst.split("/").slice(-1)[0], w: g.w, h: g.h })
}
return { id: item.id, name: item.name, cards: fresh.length, primary: !!primary, saved }
