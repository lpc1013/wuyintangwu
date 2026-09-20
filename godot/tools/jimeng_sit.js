// 即梦逐物种产 sit 坐姿图：一次调用领一只还没出图的物种，拿它自己的 walk 原图垫图，
// 提交 → 等图 → 逐张开详情抓原图。跑法：
//   tabbit-cli nodejs --task jimsit --request-id <id> --timeout-ms 180000 < 本文件
// 判据是 vibe_images/ai_raw/sit/<物种>.webp 存不存在，中断后重跑同一份就接着往下走。
const fs = require("fs")
const ROOT = "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal"
const RAW = ROOT + "/vibe_images/ai_raw"
const SIT = RAW + "/sit"
const ALT = SIT + "/alt"
const FAILLOG = RAW + "/sit_fail.json"

const todo = JSON.parse(fs.readFileSync(RAW + "/sit_todo.json", "utf8"))
const fails = fs.existsSync(FAILLOG) ? JSON.parse(fs.readFileSync(FAILLOG, "utf8")) : {}
if (!fs.existsSync(SIT)) fs.mkdirSync(SIT, { recursive: true })
if (!fs.existsSync(ALT)) fs.mkdirSync(ALT, { recursive: true })
const have = new Set(fs.readdirSync(SIT).map(f => f.toLowerCase()))
// 一只连撞三次就跳过：串行驱动对着同一只死磕，三十只永远跑不完
const item = todo.find(t => ![ ".webp", ".png", ".jpg", ".jpeg" ].some(e => have.has(t.id + e))
  && (fails[t.id] || 0) < 3)
if (!item) return { idle: true, skipped: Object.keys(fails).filter(k => (fails[k] || 0) >= 3) }
const bail = code => {
  fails[item.id] = (fails[item.id] || 0) + 1
  fs.writeFileSync(FAILLOG, JSON.stringify(fails, null, 1), "utf8")
  return { id: item.id, error: code, attempt: fails[item.id] }
}
// todo.json 里的 ref 是仓库相对路径、还带反斜杠，setFiles 要绝对正斜杠路径
item.ref = item.ref.replace(/\\/g, "/")
if (!item.ref.startsWith("/")) item.ref = ROOT + "/" + item.ref
if (!fs.existsSync(item.ref)) return bail("no-ref")

await page.goto("https://jimeng.jianying.com/ai-tool/generate?type=image", { waitUntil: "domcontentloaded", timeout: 60000 })
const waitEd = () => page.waitForSelector('.tiptap.ProseMirror', { timeout: 25000 }).then(() => true).catch(() => false)
if (!await waitEd()) {
  await page.reload({ waitUntil: "domcontentloaded", timeout: 60000 })
  if (!await waitEd()) return bail("composer-never-appeared")
}
await page.waitForTimeout(3000)
await page.keyboard.press("Escape")
await page.waitForTimeout(600)

// 垫图：先传参考图再填提示词。传不上就当场收工——少了垫图，同一只动物的脸就换人了，
// 这种图落进游戏里比缺一张图更糟。
const slot = await page.evaluate(() => {
  const el = document.querySelector('[class*="reference-upload"]')
  if (!el) return null
  const r = el.getBoundingClientRect()
  return r.width > 8 && r.height > 8 ? { x: r.x + r.width / 2, y: r.y + r.height / 2 } : null
})
if (!slot) return bail("no-reference-slot")
// 槽位是个 div，locator 点不动；原生文件弹窗只能靠 filechooser 事件接
const picked = await Promise.all([
  page.waitForEvent("filechooser", { timeout: 8000 }),
  page.mouse.click(slot.x, slot.y),
]).then(([ fc ]) => fc.setFiles(item.ref).then(() => true).catch(e => "setFiles-" + e.message))
  .catch(() => "no-event")
if (picked !== true) return bail(String(picked).slice(0, 60))
// 缩略图要等浏览器把文件读进来才挂上，实测 2~4 秒，点查一次必假阴性
let thumb = null
for (let i = 0; i < 8 && !thumb; i++) {
  await page.waitForTimeout(1000)
  thumb = await page.evaluate(() => {
    const best = [...document.querySelectorAll('img[src^="blob:"]')]
      .sort((a, b) => b.naturalWidth - a.naturalWidth)[0]
    return best ? { w: best.naturalWidth, h: best.naturalHeight } : null
  })
}
if (!thumb) return bail("ref-not-echoed")

// 站点会记住上次的模型版本与比例，回读一遍确认还是 5.0 Lite，别悄悄被换掉
const settings = await page.evaluate(() => {
  const t = document.body.innerText
  return { ver: (t.match(/\b[0-9]+\.[0-9]+\s*(?:Lite|lite)?/) || [ "" ])[0].trim(), pro: /Pro\s*版/.test(t) }
})

// 签名 URL 的域名前缀和尺寸段都会变，只有 ~ 前面那段是图的身份证
const cardKeys = () => page.evaluate(() => [...document.querySelectorAll('img[src*="aigc_resize"]')]
  .map(i => new URL(i.src).pathname.split("~")[0]))
const head0 = (await cardKeys())[0] || ""

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
const took = () => page.url().includes("workspace=")
if (!await took()) {
  if (!submitBtn) return bail("no-submit-button")
  await page.mouse.click(submitBtn.x, submitBtn.y)
  await page.waitForTimeout(2500)
  if (!await took()) return bail("submit-did-not-take")
}

// 出图约 60~70s。判据用「列表第一张换了没」，历史是懒加载的，做差集会把旧图当成新图
let fresh = []
for (let i = 0; i < 18; i++) {
  await page.waitForTimeout(5000)
  const now = await cardKeys()
  if (now.length && now[0] !== head0) fresh = now.slice(0, 4)
  if (fresh.length >= 4) break
}
if (!fresh.length) return bail("timeout-no-new-image")

// 每张卡都要点进去才拿得到 1728×2304 原图，列表里只有 540×720 缩略
const grab = async idx => {
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
  if (!g.ok) g = await grab(i)
  if (!g.ok) { saved.push({ i, ...g }); continue }
  const dst = `${ALT}/${item.id}_${i}.webp`
  fs.writeFileSync(dst, g.buf)
  if (!primary) {
    primary = `${SIT}/${item.id}.webp`
    fs.copyFileSync(dst, primary)
  }
  saved.push({ i, file: dst.split("/").slice(-1)[0], w: g.w, h: g.h })
}
if (!primary) return bail("every-card-failed")
delete fails[item.id]
fs.writeFileSync(FAILLOG, JSON.stringify(fails, null, 1), "utf8")
return { id: item.id, name: item.name, ref: thumb, settings, cards: fresh.length, saved }
