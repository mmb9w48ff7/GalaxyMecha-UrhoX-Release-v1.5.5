/* cosmic_dev.js：兑换码 + 开发者模式（网页版）。与 UrhoX 版同一套规则：
 * 码 = 9 字节载荷（类型 1 + 数额 3 + 编号 3 + 有效期 2）+ 6 字节 HMAC-SHA256 签名，Crockford Base32（24 字符）；
 * 开发者码绑定设备码；每个码每台设备限用 1 次；连续输错 5 次锁定 60 秒。码由作者用 tools/gen_codes.py 生成（私钥只在作者手里）。
 * 注意：离线网页无法做到绝对安全——密钥是混淆存放的，足以防止普通玩家伪造，但有人读源码仍能取出密钥。 */
(function () {
  'use strict';
  var RK = window.__RK, C = window.Cosmic, RUN = window.CosmicRun; if (!RK || !C) return;
  var VERSION = '1.3.5', ALPHA = '0123456789ABCDEFGHJKMNPQRSTVWXYZ', EPOCH_DAYS = 20454;
  // ---------------------------------------------------------------- SHA-256 / HMAC / Base32
  var K = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];
  function rr(x, n) { return (x >>> n) | (x << (32 - n)); }
  function sha256(bytes) {
    var h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19], len = bytes.length, m = bytes.slice();
    m.push(0x80); while (m.length % 64 !== 56) m.push(0);
    var bl = len * 8; for (var i = 7; i >= 0; i--) m.push(i >= 4 ? 0 : (bl >>> (i * 8)) & 255);
    var w = new Array(64);
    for (var c = 0; c < m.length; c += 64) {
      for (var t = 0; t < 16; t++) w[t] = (m[c + t * 4] << 24) | (m[c + t * 4 + 1] << 16) | (m[c + t * 4 + 2] << 8) | m[c + t * 4 + 3];
      for (t = 16; t < 64; t++) { var s0 = rr(w[t - 15], 7) ^ rr(w[t - 15], 18) ^ (w[t - 15] >>> 3), s1 = rr(w[t - 2], 17) ^ rr(w[t - 2], 19) ^ (w[t - 2] >>> 10); w[t] = (w[t - 16] + s0 + w[t - 7] + s1) | 0; }
      var a = h[0], b = h[1], cc = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
      for (t = 0; t < 64; t++) {
        var S1 = rr(e, 6) ^ rr(e, 11) ^ rr(e, 25), ch = (e & f) ^ (~e & g), t1 = (hh + S1 + ch + K[t] + w[t]) | 0, S0 = rr(a, 2) ^ rr(a, 13) ^ rr(a, 22), mj = (a & b) ^ (a & cc) ^ (b & cc), t2 = (S0 + mj) | 0;
        hh = g; g = f; f = e; e = (d + t1) | 0; d = cc; cc = b; b = a; a = (t1 + t2) | 0;
      }
      h[0] = (h[0] + a) | 0; h[1] = (h[1] + b) | 0; h[2] = (h[2] + cc) | 0; h[3] = (h[3] + d) | 0; h[4] = (h[4] + e) | 0; h[5] = (h[5] + f) | 0; h[6] = (h[6] + g) | 0; h[7] = (h[7] + hh) | 0;
    }
    var out = []; h.forEach(function (x) { out.push((x >>> 24) & 255, (x >>> 16) & 255, (x >>> 8) & 255, x & 255); }); return out;
  }
  function hmac(key, msg) {
    if (key.length > 64) key = sha256(key); key = key.concat(new Array(64 - key.length).fill(0));
    var ik = key.map(function (b) { return b ^ 0x36; }), ok = key.map(function (b) { return b ^ 0x5c; });
    return sha256(ok.concat(sha256(ik.concat(msg))));
  }
  function utf8(s) { return Array.prototype.slice.call(new TextEncoder().encode(s)); }
  function b32dec(str) {
    str = String(str).toUpperCase().replace(/[\s\-]/g, '').replace(/O/g, '0').replace(/[IL]/g, '1');
    var bits = 0, n = 0, out = [];
    for (var i = 0; i < str.length; i++) { var v = ALPHA.indexOf(str[i]); if (v < 0) return null; bits = (bits << 5) | v; n += 5; if (n >= 8) { out.push((bits >> (n - 8)) & 255); n -= 8; bits &= (1 << n) - 1; } }
    return out;
  }
  function secret() { return RK.A.map(function (a, i) { return a ^ RK.B[i]; }); }
  function same(a, b) { if (a.length !== b.length) return false; var d = 0; for (var i = 0; i < a.length; i++) d |= a[i] ^ b[i]; return d === 0; }
  // ---------------------------------------------------------------- 校验与兑换
  function did() {
    var s = C.save; if (!s.did || s.did.length !== 8) { var r = new Uint8Array(8); (window.crypto || window.msCrypto).getRandomValues(r); s.did = Array.prototype.map.call(r, function (b) { return ALPHA[b & 31]; }).join(''); C.write(); }
    return s.did;
  }
  function fmtDid(d) { return d.slice(0, 4) + '-' + d.slice(4); }
  function verify(code, d) {
    var raw = b32dec(code || ''); if (!raw || raw.length !== 15) return { err: '兑换码格式不对（应为 24 位字母数字）' };
    var payload = raw.slice(0, 9), sig = raw.slice(9), kind = payload[0], amount = (payload[1] << 16) | (payload[2] << 8) | payload[3], id = (payload[4] << 16) | (payload[5] << 8) | payload[6], exp = (payload[7] << 8) | payload[8];
    var expect = hmac(secret(), payload.concat(kind === 15 ? utf8(d || '') : [])).slice(0, 6);
    if (!same(sig, expect)) return { err: '无效的兑换码' };
    if (kind === 15) { var hh = sha256(utf8(d)); if (((hh[0] << 16) | (hh[1] << 8) | hh[2]) !== id) return { err: '这个开发者码不属于本设备' }; }
    else {
      if (RK.revoked[id]) return { err: '该兑换码已作废' };
      if (exp > 0 && Math.floor(Date.now() / 86400000) - EPOCH_DAYS > exp) return { err: '该兑换码已过期' };
    }
    return { kind: kind, amount: amount, id: id, exp: exp };
  }
  var fails = 0, lockUntil = 0;
  function guard() { var now = Date.now(); if (now < lockUntil) return { ok: false, msg: '尝试次数过多，请 ' + Math.ceil((lockUntil - now) / 1000) + ' 秒后再试' }; return { ok: true }; }
  function fail(msg) { fails++; if (fails >= 5) { lockUntil = Date.now() + 60000; fails = 0; } return { ok: false, msg: msg }; }
  function redeem(text) {
    var g = guard(); if (!g.ok) return g;
    var info = verify(text, did()); if (info.err) return fail(info.err);
    if (info.kind === 15) return { ok: false, msg: '这是开发者解锁码，请在 设置 → 连点版本号 7 次 里输入' };
    var s = C.save; s.redeemed = s.redeemed || {}; var k = String(info.id);
    if (s.redeemed[k]) return { ok: false, msg: '该兑换码在本设备已经使用过' };
    var msg; if (info.kind === 1) { s.credits += info.amount; msg = '信用点 +' + info.amount; } else if (info.kind === 2) { s.src += info.amount; msg = '星源 +' + info.amount; } else return fail('无法识别的兑换码类型');
    s.redeemed[k] = 1; fails = 0; C.write(); return { ok: true, msg: msg };
  }
  var dev = { on: false, speed: 1, stats: false };
  function check() { dev.on = false; var c = C.save && C.save.devCode; if (!c) return false; var info = verify(c, did()); dev.on = !info.err && info.kind === 15; if (!dev.on) { C.save.devCode = null; } refreshTag(); return dev.on; }
  function unlock(text) {
    var g = guard(); if (!g.ok) return g; var info = verify(text, did()); if (info.err) return fail(info.err);
    if (info.kind !== 15) return { ok: false, msg: '这不是开发者解锁码' };
    C.save.devCode = text; dev.on = true; fails = 0; C.write(); refreshTag(); return { ok: true, msg: '开发者模式已解锁' };
  }
  // ---------------------------------------------------------------- 界面
  var css = document.createElement('style');
  css.textContent = '.mk-get{max-height:94vh;overflow-y:auto}.dv-in{width:100%;box-sizing:border-box;margin:12px 0;padding:14px 16px;font:700 34px/1.2 monospace;letter-spacing:4px;text-align:center;color:#EDE6D6;background:#090C22;border:3px solid #5CF2DC;outline:none}' +
    '.dv-msg{min-height:34px;font-size:24px;text-align:center}.dv-msg.ok{color:#5CF2DC}.dv-msg.bad{color:#E0458C}.dv-did{font-size:34px;color:#5CF2DC;text-align:center;margin:6px 0}' +
    '.dv-tag{position:absolute;left:300px;top:24px;z-index:9;min-height:0;padding:6px 16px;font-size:22px;font-weight:700;color:#2A1A00;background:#F5A524;border:0;pointer-events:auto;cursor:pointer}' +
    '.dv-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:14px 0}.dv-grid .mini{min-height:62px;font-size:22px}' +
    '.dv-bp{position:absolute;right:30px;top:280px;width:380px;z-index:7;padding:12px;background:rgba(9,12,34,.92);box-shadow:inset 0 0 0 3px #34407A;pointer-events:auto}.dv-bp .g{display:grid;grid-template-columns:1fr 1fr;gap:8px}' +
    '.dv-bp button{min-height:48px;padding:0 6px;font-size:20px;font-weight:700;background:#34407A!important;color:#EDE6D6!important;box-shadow:inset 0 -4px 0 #090C22;border:0;cursor:pointer}.dv-bp button.on{background:#F5A524!important;color:#2A1A00!important}' +
    '.dv-stat{position:absolute;left:380px;top:28px;z-index:9;font:20px monospace;color:#5CF2DC;pointer-events:none;text-shadow:0 0 4px #000}';
  document.head.appendChild(css);
  function ui() { return document.getElementById('ui'); }
  function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
  function modal(html) { var m = el('div', 'sv-modal'); m.innerHTML = html; ui().appendChild(m); return m; }
  function toast(t) { var A = window.__A; var x = document.getElementById('toast'); if (x) { x.textContent = t; x.hidden = false; clearTimeout(toast._t); toast._t = setTimeout(function () { x.hidden = true; }, 2600); } }
  function backToHub() { if (window.CosmicHub && window.CosmicHub.refresh) window.CosmicHub.refresh(); }
  function codeModal(title, note, okLabel, action, withDid) {
    var m = modal('<div class="panel sv-pbox mk-get"><h1>' + title + '</h1>' + (withDid ? '<div class="dv-did">本设备设备码：' + fmtDid(did()) + '</div>' : '') + '<p class="note">' + note + '</p>' +
      '<input class="dv-in" maxlength="40" placeholder="XXXXXX-XXXXXX-XXXXXX-XXXXXX" autocomplete="off" spellcheck="false"><div class="dv-msg"></div>' +
      '<div class="sv-btns"><button class="btn" id="dv-cancel">取消</button><button class="btn primary" id="dv-ok">' + okLabel + '</button></div></div>');
    var inp = m.querySelector('.dv-in'), msg = m.querySelector('.dv-msg');
    function go() { var r = action(inp.value); msg.className = 'dv-msg ' + (r.ok ? 'ok' : 'bad'); msg.textContent = r.msg; if (r.ok) { inp.value = ''; if (r.close) { m.remove(); r.close(); } } }
    inp.addEventListener('input', function () { var v = inp.value.toUpperCase().replace(/[^0-9A-Z]/g, '').slice(0, 24); inp.value = v.replace(/(.{6})(?=.)/g, '$1-'); });
    inp.addEventListener('keydown', function (e) { e.stopPropagation(); if (e.key === 'Enter') go(); }); inp.addEventListener('keyup', function (e) { e.stopPropagation(); });
    m.querySelector('#dv-ok').onclick = go; m.querySelector('#dv-cancel').onclick = function () { m.remove(); backToHub(); };
    setTimeout(function () { inp.focus(); }, 50); return m;
  }
  function openRedeem() { codeModal('兑换码', '输入作者发放的兑换码，可兑换信用点或星源（每个码每台设备限用 1 次）', '确认', function (t) { var r = redeem(t); if (r.ok) { C.sfx('win'); r.msg = '兑换成功：' + r.msg; toast(r.msg); } return r; }, false); }
  function openUnlock() {
    codeModal('开发者模式', '把设备码发给作者，用 tools/gen_codes.py dev 设备码 生成解锁码后输入（只对本设备有效）', '解锁', function (t) { var r = unlock(t); if (r.ok) { r.close = function () { openHubPanel(); }; } return r; }, true);
  }
  function freeBuy(n, f) { var s = C.save, c0 = s.credits; for (var i = 0; i < n; i++) { s.credits = 1e12; f(); } s.credits = c0; }
  var ACTIONS = [
    ['信用点 +10,000', function () { C.save.credits += 10000; }], ['信用点 +1,000,000', function () { C.save.credits += 1000000; }], ['星源 +1,000', function () { C.save.src += 1000; }],
    ['星源 +100,000', function () { C.save.src += 100000; }], ['资源清零', function () { C.save.credits = 0; C.save.src = 0; }],
    ['解锁全部机甲（满级满星）', function () { C.MECHS.forEach(function (m) { C.save.mechs[m.id] = { lv: C.MECH_MAX, star: 5 }; }); }],
    ['解锁全部驾驶员（满星）', function () { C.CHARS.forEach(function (c) { C.save.chars[c.id] = { star: 5 }; }); }],
    ['全部章节通关 + 危险 10', function () { C.CHAPTERS.forEach(function (ch) { C.save.cleared[ch.id] = true; }); C.save.chapter = C.CHAPTERS.length; C.save.dangerMax = 10; }],
    ['全员碎片 +50', function () { C.MECHS.concat(C.CHARS).forEach(function (x) { C.save.frags[x.id] = (C.save.frags[x.id] || 0) + 50; }); }],
    ['免费抽 10 张卡牌', function () { freeBuy(10, function () { C.buyModule(); }); }], ['免费研发 10 枚芯片', function () { freeBuy(10, function () { C.buyChip(); }); }],
    ['重置每日（补给 / 任务 / 登录）', function () { C.save.daily = {}; C.save.login = null; C.load(); }], ['重播新手引导', function () { C.save.tutorialDone = false; }],
    ['召唤保底清零', function () { C.save.mechPity = C.save.mechPity3 = C.save.pilotPity = C.save.pilotPity3 = 0; }]
  ];
  var wipeArmed = false;
  function openHubPanel() {
    var m = modal('<div class="panel sv-pbox mk-get" style="width:min(1200px,92vw)"><h1>开发者面板</h1><p class="note">设备码 ' + fmtDid(did()) + '（仅作者可见；玩家看不到这个页面）</p><div class="dv-grid"></div>' +
      '<div class="dv-grid"><button class="mini alt dv-wipe">删除全部存档（慎用）</button><button class="mini alt dv-stats">调试信息：' + (dev.stats ? '开' : '关') + '</button><button class="mini alt dv-exit">退出开发者模式</button></div><button class="btn primary mk-close">关闭</button></div>');
    var g = m.querySelector('.dv-grid');
    ACTIONS.forEach(function (a) { var b = el('button', 'mini', a[0]); b.onclick = function () { a[1](); C.write(); C.sfx('click'); toast('已执行：' + a[0]); }; g.appendChild(b); });
    m.querySelector('.dv-wipe').onclick = function () { if (wipeArmed) { try { localStorage.removeItem('galaxy-mecha-save-v8'); } catch (e) { } location.reload(); } else { wipeArmed = true; toast('再点一次确认删除'); } };
    m.querySelector('.dv-stats').onclick = function () { dev.stats = !dev.stats; m.remove(); openHubPanel(); };
    m.querySelector('.dv-exit').onclick = function () { C.save.devCode = null; dev.on = false; C.write(); refreshTag(); m.remove(); toast('已退出开发者模式'); backToHub(); };
    m.querySelector('.mk-close').onclick = function () { m.remove(); backToHub(); };
  }
  var bp = null;
  function toggleBattle() {
    if (bp) { bp.remove(); bp = null; return; }
    var D = RUN.debug; bp = el('div', 'dv-bp'); ui().appendChild(bp);
    function paint() {
      var R = D.run(); if (!bp || !R) return;
      var items = [['无敌', function () { D.god(!R.god); }, R.god], ['秒杀', function () { D.oneHit(!R.devOne); }, R.devOne], ['满血', function () { D.heal(); }], ['清场', function () { D.clearEnemies(); }],
        ['升级 +1', function () { D.levelUp(); }], ['升级 +5', function () { for (var i = 0; i < 5; i++) D.levelUp(); }], ['信用点 +1000', function () { D.addCredits(1000); }], ['星源 +100', function () { D.addSrc(100); }],
        ['下一星域', function () { D.sector(R.sector + 1); }], ['星域 6 首领', function () { D.sector(6); }], ['星门前', function () { D.toGate(); }], ['调试信息', function () { dev.stats = !dev.stats; }, dev.stats],
        ['胜利结算', function () { D.endRun(true); }], ['失败结算', function () { D.endRun(false); }]];
      bp.innerHTML = '<div class="g"></div><div style="margin-top:10px;color:#A3ABCF;font-size:18px">速度倍率（战斗）</div><div class="g" style="grid-template-columns:repeat(4,1fr)"></div>';
      var g = bp.children[0], sp = bp.children[2];
      items.forEach(function (it) { var b = el('button', it[2] ? 'on' : '', it[0]); b.onclick = function () { it[1](); paint(); }; g.appendChild(b); });
      [0.5, 1, 2, 4].forEach(function (v) { var b = el('button', dev.speed === v ? 'on' : '', 'x' + v); b.onclick = function () { dev.speed = v; paint(); }; sp.appendChild(b); });
    }
    paint();
  }
  var tag = null, stat = null;
  function inRun() { return !!document.querySelector('.sv-top'); }
  function refreshTag() {
    if (dev.on && !tag) { tag = el('button', 'dv-tag', 'DEV'); tag.onclick = function () { if (inRun() && RUN.debug.run()) toggleBattle(); else openHubPanel(); }; ui().appendChild(tag); }
    if (!dev.on && tag) { tag.remove(); tag = null; }
  }
  // 速度倍率：包装战斗帧函数
  var ofr = RUN.frame; RUN.frame = function (dt) { var sp = dev.on ? dev.speed : 1; if (sp >= 2) { for (var i = 1; i < sp; i++) ofr.call(RUN, dt); ofr.call(RUN, dt); } else ofr.call(RUN, dt * sp); };
  // 常驻：保证标签在界面重建后还在；调试信息
  setInterval(function () {
    if (!C.save) return; if (!dev.checked) { dev.checked = true; check(); }
    if (dev.on && tag && !tag.isConnected) { tag = null; refreshTag(); }
    if (!inRun() && bp) { bp.remove(); bp = null; }
    if (dev.on && dev.stats && inRun() && RUN.debug.run()) { if (!stat || !stat.isConnected) { stat = el('div', 'dv-stat'); ui().appendChild(stat); } var R = RUN.debug.run(); stat.textContent = '敌人 ' + R.enemies.length + '　弹体 ' + R.shots.length + '　t=' + Math.round(R.t) + 's　等级 ' + R.level + '　速度 x' + dev.speed; }
    else if (stat) { stat.remove(); stat = null; }
  }, 300);
  var taps = 0, tapT = 0;
  window.CosmicDev = {
    version: VERSION, isDev: function () { return dev.on; }, openRedeem: openRedeem, redeem: redeem, verify: verify,
    verTap: function (m) { var t = Date.now(); if (t - tapT > 3000) taps = 0; tapT = t; taps++; if (taps >= 7) { taps = 0; if (m) m.remove(); check(); if (dev.on) openHubPanel(); else openUnlock(); } },
    _unlock: unlock, _check: check, _dev: dev
  };
})();
