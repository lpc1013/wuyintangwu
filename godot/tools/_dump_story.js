// 一次性抽取脚本：把 Spring/index.html 里的叙事常量原样求值成 JSON，
// 免得 GDScript 那侧靠肉眼誊抄上千行中文文案。跑完即删。
const fs = require('fs');
const path = 'Spring/index.html';
const src = fs.readFileSync(path, 'utf8');

function slice(name) {
	const at = src.indexOf('const ' + name + ' = ');
	if (at < 0) throw new Error('missing ' + name);
	const eq = src.indexOf('=', at + name.length);
	const cu = src.indexOf('{', eq), cb = src.indexOf('[', eq);
	const open = (cb >= 0 && (cu < 0 || cb < cu)) ? cb : cu;
	let depth = 0, i = open, inStr = null;
	for (; i < src.length; i++) {
		const c = src[i];
		if (inStr) {
			if (c === '\\') { i++; continue; }
			if (c === inStr) inStr = null;
			continue;
		}
		if (c === "'" || c === '"' || c === '`') { inStr = c; continue; }
		if (c === '/' && src[i + 1] === '/') { while (i < src.length && src[i] !== '\n') i++; continue; }
		if (c === '{' || c === '[') depth++;
		else if (c === '}' || c === ']') { depth--; if (depth === 0) break; }
	}
	return src.slice(at, i + 1) + ';';
}

const names = ['LEVELS', 'STAFF_TYPES', 'DIALOGUES', 'STORY_DB'];
const out = {};
for (const n of names) {
	const code = slice(n);
	out[n] = eval('(function(){' + code + ' return ' + n + ';})()');
}
// 扩员的那十只单独立在 STORY_DB_EXT 里（网页版自己负责合并，本脚本逐块求值，合不上）。
// 抽出来时可能整块不存在——那是 S1 降级红线允许的删法，这里跟着一起降级成「没有 ext」。
try {
	const ext = eval('(function(){' + slice('STORY_DB_EXT') + ' return STORY_DB_EXT;})()');
	for (const ch of Object.keys(ext)) {
		out.STORY_DB[ch] = Object.assign(out.STORY_DB[ch] || {}, ext[ch]);
	}
} catch (e) {
	console.log('no STORY_DB_EXT: ' + e.message);
}
fs.writeFileSync('godot/tools/_story_dump.json', JSON.stringify(out, null, 1));

const db = out.STORY_DB;
const lines = [];
for (const k of Object.keys(db)) {
	const v = db[k];
	lines.push(k + ': ' + Object.keys(v).length + ' keys');
}
console.log(lines.join('\n'));
console.log('LEVELS=' + out.LEVELS.length, 'STAFF=' + out.STAFF_TYPES.length,
	'DIALOGUES=' + Object.keys(out.DIALOGUES).length);
