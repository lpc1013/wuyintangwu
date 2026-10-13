/* 旧版网页游戏（根目录 index.html）的回归闸。
   审计报告点名的四条（H-01 拆除返币 / H-02 碎碎念受帧率影响 / H-03 评级公式 /
   H-04 无作用属性当数值展示）都是「源码里写了但链路不通」那一类，
   所以这里既读源码形状，也把评级公式按关卡天数重算一遍。
   运行：node check_html.js  （退出码 0 = 全绿） */
/* 运行：node check_html.js [目标文件]，默认查根目录 index.html。
   指一份改了毛病的副本进去，可以验这条闸到底抓不抓得住。 */
const fs = require('fs');
const path = require('path');

const TARGET = process.argv[2] ? path.resolve(process.argv[2])
 : path.join(__dirname, 'index.html');
const SRC = fs.readFileSync(TARGET, 'utf8');
let failures = 0;
function ok(label, cond) {
 console.log('  ' + (cond ? 'ok   - ' : 'FAIL - ') + label);
 if (!cond) failures++;
}
/* 取一个函数体：从 `function name(` 起，按大括号配对截到函数结束 */
function body(name) {
 const at = SRC.indexOf('function ' + name + '(');
 if (at < 0) return '';
 let depth = 0, started = false;
 for (let i = at; i < SRC.length; i++) {
  const c = SRC[i];
  if (c === '{') { depth++; started = true; }
  else if (c === '}') { depth--; if (started && depth === 0) return SRC.slice(at, i + 1); }
 }
 return '';
}

/* ---- H-01：拆除必须真的返币，而且返的和按钮上写的是同一个算式 ---- */
const dem = body('demolish');
const panelAt = SRC.indexOf('拆除（返');
const promised = panelAt >= 0 ? SRC.slice(panelAt, panelAt + 120) : '';
const refundIn = /G\.coins\+=\s*refund/.test(dem);
const MATH = /Math\.round\(([A-Za-z0-9_.[\]]*cost\*\.5\*p\.level)\)/;
const refundFormula = (dem.match(MATH) || [])[1];
const promisedFormula = (promised.match(MATH) || [])[1];
ok('拆除把退款记进金币（G.coins+=refund）', refundIn);
ok('退款算式存在且含 cost*.5*p.level', !!refundFormula && /cost\*\.5\*p\.level/.test(refundFormula));
const core = s => (s || '').replace(/(FACILITIES\[p\.id\]|f)\.cost/, 'cost');
ok('按钮文案与退款是同一份算式',
 !!refundFormula && !!promisedFormula && core(refundFormula) === core(promisedFormula));
ok('提示语把退回数额说出来', /退回 \$\{refund\}/.test(dem));

/* ---- H-02：碎碎念倒计时只许模拟侧减一次 ---- */
const chatter = body('soakChatter');
ok('soakChatter 不再自己减 1/60', !/chatterT-=1\/60/.test(chatter));
ok('soakChatter 仍会读倒计时', /if\(gu\.chatterT>0\)return/.test(chatter));
const soakCase = (SRC.match(/case 'soak':\{[\s\S]*?\n \}/) || [''])[0];
const updateDec = (soakCase.match(/chatterT-=dt/g) || []).length;
ok('模拟里恰好一处按 dt 递减', updateDec === 1);
ok('全文件 chatterT-= 只有模拟那一处',
 (SRC.match(/chatterT-=/g) || []).length === 1);

/* ---- H-03：评级按「还剩几天」归一，S/A/B 三档都要真拿得到 ---- */
const rankSrc = body('checkLevelEnd');
const slackExpr = /const slack=lv\.days<=1\?1:\(daysLeft-1\)\/\(lv\.days-1\)/.test(rankSrc);
const th = rankSrc.match(/slack>=([\d.]+)\?'S':slack>=([\d.]+)\?'A':'B'/);
ok('余量归一的写法在源码里', slackExpr);
ok('阈值读得出来', !!th);
if (th) {
 const sTh = parseFloat(th[1]), aTh = parseFloat(th[2]);
 const rank = (days, doneDay) => {
  const daysLeft = Math.max(0, days - doneDay + 1);
  const slack = days <= 1 ? 1 : (daysLeft - 1) / (days - 1);
  return slack >= sTh ? 'S' : slack >= aTh ? 'A' : 'B';
 };
 const block = (SRC.match(/const LEVELS=\[[\s\S]*?\n\];/) || [''])[0];
 const days = [...block.matchAll(/days:(\d+)/g)].map(m => parseInt(m[1], 10));
 ok('关卡天数读出来 ' + JSON.stringify(days), days.length >= 3);
 let bFound = false, sOnLastDay = false, aFound = false;
 for (const d of days) {
  for (let day = 1; day <= d; day++) {
   const r = rank(d, day);
   if (r === 'B') bFound = true;
   if (r === 'A') aFound = true;
   if (r === 'S' && day === d && d > 1) sOnLastDay = true;
  }
 }
 ok('拖到最后一天也有对应的档（B 可达）', bFound);
 ok('中间收工有 A 档', aFound);
 ok('用满天数绝不评 S', !sOnLastDay);
 ok('第一天收工评 S', rank(3, 1) === 'S' && rank(1, 1) === 'S');
}

/* ---- H-04：面板上的数字只许留给真起作用的键 ---- */
const live = (SRC.match(/const EFF_LIVE=\{([^}]+)\}/) || ['', ''])[1];
const liveKeys = live.split(',').map(s => s.split(':')[0].trim()).filter(Boolean);
ok('EFF_LIVE 列出了模拟读到的键', liveKeys.length >= 3
 && ['coin', 'joy', 'relax'].every(k => liveKeys.includes(k)));
// 模拟里真正读到的 eff 键（f.eff.xxx / p.eff.xxx）：必须全在 EFF_LIVE 里，
// 否则就是「有个数值在起作用却不在白名单上」
const readKeys = [...new Set((SRC.match(/f\.eff\.(\w+)/g) || [])
 .map(s => s.split('.').pop()))];
ok('白名单与实际读到的功效键一一对应（读到 ' + readKeys.join('/') + '）',
 readKeys.every(k => liveKeys.includes(k)) && liveKeys.every(k => readKeys.includes(k)));
ok('设施面板给非活性键只标氛围，不给 Lv',
 /if\(!EFF_LIVE\[k\]\)\{[\s\S]*?氛围[\s\S]*?continue;/.test(body('openFacPanel')));
ok('建造列表同样不拿死数值示人', /EFF_LIVE\[k\]\?v:'·氛围'/.test(SRC));

/* ---- 语法闸：整份内联脚本要能被解析（改坏了括号就当场露） ---- */
const scripts = [...SRC.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
ok('内联脚本 ' + scripts.length + ' 段全部语法通过', scripts.length > 0
 && scripts.every(s => {
  try { new Function(s); return true; }
  catch (e) { console.log('       语法错误：' + e.message); return false; }
 }));

console.log('HTMLCHECK ' + (failures === 0 ? 'PASSED' : 'FAILED (' + failures + ')'));
process.exit(failures === 0 ? 0 : 1);
