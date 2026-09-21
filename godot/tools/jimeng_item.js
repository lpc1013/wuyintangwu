// 即梦单件物品白底重绘驱动。占位符由 bash 注入: __NAME__ __FILE__ __BG__ __EXTRA__
const name = "__NAME__";
const file = "__FILE__";
const bgWord = "__BG__";
const extra = "__EXTRA__";

let page = pages().find(p => p.url().includes("jimeng"));
if (!page) {
  page = pages()[0];
  if (!page) page = await context.newPage();
}
usePage(page);

// 1. 重置 composer：整页刷新
await page.goto("https://jimeng.jianying.com/ai-tool/generate?type=image", { waitUntil: "domcontentloaded", timeout: 60000 });
await page.waitForTimeout(9000);

// 2. 确认模型 = Seedream 5.0 Lite（读不到就重试；读到了但不是 Lite 才动下拉）
let model = "";
for (let i = 0; i < 8; i++) {
  model = await page.evaluate(() => { const e = document.querySelector('.model-label-wceeNL') || document.querySelector('.lv-select-view-value'); return e ? e.innerText.trim() : ""; });
  if (model) break;
  await page.waitForTimeout(2000);
}
if (model && !/5\.0\s*Lite/i.test(model)) {
  const sel = await page.evaluate(() => { const e = document.querySelector('.model-label-wceeNL') || document.querySelector('.lv-select'); if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2 }; });
  await page.mouse.click(sel.x, sel.y);
  await page.waitForTimeout(1500);
  const o = await page.evaluate(() => {
    const c = [...document.querySelectorAll('[class*="option"],[role="option"]')].find(e => /5\.0\s*Lite/i.test(e.innerText || ""));
    if (!c) return null; const r = c.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  });
  if (!o) throw new Error("5.0 Lite option not found");
  await page.mouse.click(o.x, o.y);
  await page.waitForTimeout(800);
  model = await page.evaluate(() => { const e = document.querySelector('.model-label-wceeNL') || document.querySelector('.lv-select-view-value'); return e ? e.innerText.trim() : ""; });
}

// 3. 垫图上传：点 reference 槽，接住原生文件选择器
const slot = await page.evaluate(() => {
  const e = [...document.querySelectorAll('[class*="reference-upload"]')].find(x => { const r = x.getBoundingClientRect(); return r.width > 0; });
  if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
});
if (!slot) throw new Error("reference slot not found");
let refOk = false;
for (let attempt = 0; attempt < 3 && !refOk; attempt++) {
  let fc = null;
  try {
    [fc] = await Promise.all([
      page.waitForEvent("filechooser", { timeout: 8000 }),
      page.mouse.click(slot.x, slot.y),
    ]);
  } catch (e) { continue; }
  await fc.setFiles(file);
  for (let i = 0; i < 8 && !refOk; i++) {
    await page.waitForTimeout(1000);
    refOk = await page.evaluate(() => !!document.querySelector('[data-content-generator-references] img[src^="blob:"]'));
  }
}
if (!refOk) throw new Error("reference upload not confirmed");

// 4. 提示词
const prompt = `参考图里只有一个物品，把这个物品单独画在纯${bgWord}色背景上：保持原图的像素画风、配色、描边和朝向，物品完整居中不裁切，四周留白。画面里只画这一件物品，背景是均匀纯净的${bgWord}色，不要画桌面、地板、投影等任何背景元素，不要加文字和水印。${extra}`;
const pm = await page.evaluate(() => {
  const e = [...document.querySelectorAll(".tiptap.ProseMirror")].find(x => { const r = x.getBoundingClientRect(); return r.width > 0; });
  if (!e) return null; const r = e.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + Math.min(20, r.height / 2) };
});
if (!pm) throw new Error("prompt editor not found");
await page.locator(".tiptap.ProseMirror").first().click({ force: true });
await page.waitForTimeout(400);
await page.keyboard.insertText(prompt);
await page.waitForTimeout(600);

// 5. 记录已有结果 + 滚到底部 + 提交
const seenBefore = await page.evaluate(() => [...new Set([...document.querySelectorAll('img[src*="aigc_resize"]')].map(i => { try { return new URL(i.src).pathname; } catch (e) { return i.src; } }))]);
const submit = await page.evaluate(() => {
  const b = [...document.querySelectorAll('button[class*="submit-button"]')].find(x => { const r = x.getBoundingClientRect(); return r.width > 0 && !x.disabled; });
  if (!b) return false; b.click(); return true;
});
if (!submit) throw new Error("submit button not ready");

// 6. 等出图：先等 25s 再轮询，fresh 至少 4 张
await page.waitForTimeout(25000);
let fresh = [];
for (let i = 0; i < 22; i++) {
  fresh = await page.evaluate((seen) => [...document.querySelectorAll('img[src*="aigc_resize"]')]
    .map(x => { try { return { src: x.src, key: new URL(x.src).pathname }; } catch (e) { return null; } })
    .filter(Boolean).filter(x => !seen.includes(x.key)), [...seenBefore]);
  if (fresh.length >= 4) break;
  await page.waitForTimeout(5000);
}
if (fresh.length < 1) throw new Error("no fresh results");

// 7. 回传主图 + alt 的签名 URL，由 bash curl 落盘
return JSON.stringify({ name, model, fresh: fresh.length, urls: fresh.map(x => x.src) });
