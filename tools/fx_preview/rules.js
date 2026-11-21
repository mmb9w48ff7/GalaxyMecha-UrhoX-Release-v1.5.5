// UrhoX 特效规则（与 Renderer.lua 一一对应），供预览页使用
(function () {
  var MODEL_COL = { fx_white: [1, 1, 1], fx_white_bolt: [1, 1, 1], fx_spark: [1, .702, .2784], fx_laser_player: [.3608, .949, .8627], fx_laser_enemy: [1, .302, .4157] };
  function boost(c, k) { var g = .2126 * c[0] + .7152 * c[1] + .0722 * c[2]; return c.map(function (v) { return Math.max(0, Math.min(1, g + (v - g) * k)); }); }
  function fxColor(id, tint) {
    var c;
    if (tint) { var r = Math.max(0, tint[0]), g = Math.max(0, tint[1]), b = Math.max(0, tint[2]), m = Math.max(r, g, b); if (m > 1) { r /= m; g /= m; b /= m; }
      c = [r, g, b].map(function (v) { return Math.pow(Math.floor(v * 8 + .5) / 8, 1 / 2.2); }); }
    else c = MODEL_COL[id];
    var mx = Math.max(c[0], c[1], c[2], 1e-4); return boost([c[0] / mx, c[1] / mx, c[2] / mx], 1.35);
  }
  window.__fxColor = fxColor;
  var ADD = { fx_white: 1, fx_white_bolt: 1, fx_spark: 1, fx_laser_player: 1, fx_laser_enemy: 1 };
  var rules = {};
  rules.old = function (d) {                                   // v1.4.8
    var id = d.mesh.id; if (!ADD[id]) return null;
    var k = (d.kind || 0) === 0 ? (d.tint ? 0.32 : 0.45) : (d.s > 6 ? 0.7 : 0.9), c = fxColor(id, d.tint), HALO = { fx_white: 1, fx_spark: .8 };
    var r = { col: c.map(function (v) { return v * k; }) };
    if (HALO[id] && (d.kind || 0) !== 0 && d.s <= 4) r.halo = { col: c.map(function (v) { return v * 0.18 * HALO[id]; }), scale: 1.8, rot: 1 };
    return r;
  };
  // ---- 新方案：按角色（推进器 / 机甲攻击 / 敌人攻击 / 冲击环 / 粒子）分别处理；细长弹道用“粗而短”的彩色光套，不再整体放大或斜转
  var ELONG = { fx_white_bolt: 1, fx_laser_player: 1, fx_laser_enemy: 1 }, E_CORE = [1.25, 0.5, 0.6];
  var LV = [0.02, 0.035, 0.05, 0.065, 0.08, 0.1, 0.13, 0.16, 0.2, 0.25, 0.3, 0.36, 0.45, 0.55, 0.65, 0.75, 0.85];
  function qk(k) { var b = LV[0]; for (var i = 0; i < LV.length; i++) if (Math.abs(LV[i] - k) < Math.abs(b - k)) b = LV[i]; return b; }
  window.__qk = qk;
  rules.new = function (d) {
    var id = d.mesh.id; if (!ADD[id]) return null;
    var role = d.role, a = d.a == null ? 1 : d.a, tint = d.tint;
    if (role === 'e' && !tint) tint = E_CORE;
    var c = fxColor(id, tint), mul = function (k) { k = qk(k); return c.map(function (v) { return v * k; }); }, r = { halos: [] };
    if (role === 'thrust') { r.col = mul(tint ? 0.03 + 0.07 * a : 0.13); r.sc = 0.8; return r; }
    var fade = role === 'fx' ? (a > 0.6 ? 1 : a > 0.35 ? 0.7 : a > 0.15 ? 0.45 : 0.25) : role === 'nova' ? (a > 0.6 ? 1 : a > 0.3 ? 0.65 : 0.35) : 1;
    var thin = ELONG[id] && d.s <= 2.4, k = role === 'e' ? (thin ? 0.45 : 0.8) : role === 'nova' ? 0.7 : 0.85;
    if (d.s > 6) k = Math.min(k, 0.6);
    r.col = mul(k * fade);
    if (ELONG[id]) {                                          // 细长弹道：三层由内到外渐淡的彩色光套（横向粗、纵向只略长），边缘不明显
      var e = role === 'e', g = thin ? 0.5 : 1;
      r.halos.push({ col: mul((e ? 0.2 : 0.16) * g), s: [1.7, 1.7, 1.06] });
      r.halos.push({ col: mul((e ? 0.1 : 0.08) * g), s: [2.5, 2.5, 1.12] });
      if (!thin) r.halos.push({ col: mul(e ? 0.045 : 0.035), s: [3.4, 3.4, 1.2] });
    } else if ((id === 'fx_white' || id === 'fx_spark') && d.s <= 4 && role !== 'nova') {
      r.halos.push({ col: mul(0.12 * fade), s: 1.9, rot: 1 }); if (fade >= 0.7) r.halos.push({ col: mul(0.05 * fade), s: 2.8, rot: 1 });
    } else if (d.s > 6) { r.halos.push({ col: mul(0.1), s: 1.5 }); r.halos.push({ col: mul(0.04), s: 2.1 }); }
    return r;
  };
  // ---- v1.5.0：光套改成柔光贴片（UrhoX BillboardSet + 径向渐变贴图）；细长弹道本体变细，柔光沿弹道方向拉长
  rules.v150 = function (d) {
    var id = d.mesh.id; if (!ADD[id]) return null;
    var role = d.role, a = d.a == null ? 1 : d.a, tint = d.tint, s = d.s || 0;
    if (role === 'e' && !tint) tint = E_CORE;
    var c = fxColor(id, tint), mul = function (k) { k = qk(k); return c.map(function (v) { return v * k; }); }, r = { sprites: [] };
    if (role === 'thrust') { r.col = mul(tint ? 0.03 + 0.07 * a : 0.13); r.sc = 0.8; if (!tint) r.sprites.push({ w: 0.1 * s * 4.5, col: mul(0.1) }); return r; }
    var fade = role === 'fx' ? (a > 0.6 ? 1 : a > 0.35 ? 0.7 : a > 0.15 ? 0.45 : 0.25) : role === 'nova' ? (a > 0.6 ? 1 : a > 0.3 ? 0.65 : 0.35) : 1;
    var thin = ELONG[id] && s <= 2.4, k = role === 'e' ? (thin ? 0.4 : 0.65) : role === 'nova' ? 0.7 : 0.85;
    if (s > 6) k = Math.min(k, 0.6);
    r.col = mul(k * fade);
    var m = d.m, e = role === 'e';
    if (ELONG[id]) {
      var len = (id === 'fx_laser_player' ? 1.4 : id === 'fx_laser_enemy' ? 1.2 : 1.0) * s, wid = 0.1 * s;
      r.sc = [0.75, 0.75, 1];
      r.sprites.push({ dir: [m[8], m[9], m[10]], w: Math.max(0.8, wid * (e ? 7 : 6)), l: len * 1.25 + wid * 3, col: mul((e ? 0.7 : 0.6) * (thin ? 0.5 : 1)) });
    } else if ((id === 'fx_white' || id === 'fx_spark') && s <= 4 && role !== 'nova' && !e) r.sprites.push({ w: 0.1 * s * 6, col: mul(0.55 * fade) });
    else if (s > 6) r.sprites.push({ w: 0.1 * s * 3.4, col: mul(0.4) });
    return r;
  };
  // ---- v1.5.1：简洁激光——激光 / 敌弹中间的小白点（kind 1 的 fx_white，尺寸 <= 6.5）不画；细长柔光改用中段均匀的线形贴图
  rules.v151 = function (d) { if (d.mesh.id === 'fx_white' && (d.kind || 0) === 1 && (d.s || 0) <= 6.5) return { col: [0, 0, 0], skip: true }; return rules.v150(d); };
  // ---- v1.5.2：更柔和、不刺眼——激光柔光变窄，激光上的 fx_white 全部不画（含首领激光起点闪光），本体与柔光整体降亮
  rules.v152 = function (d) {
    var id = d.mesh.id; if (!ADD[id]) return null;
    if (id === 'fx_white' && (d.kind || 0) === 1) return { col: [0, 0, 0], skip: true };
    var role = d.role, a = d.a == null ? 1 : d.a, tint = d.tint, s = d.s || 0;
    if (role === 'e' && !tint) tint = E_CORE;
    var c = fxColor(id, tint), mul = function (k) { k = qk(k); return c.map(function (v) { return v * k; }); }, r = { sprites: [] };
    if (role === 'thrust') { r.col = mul(tint ? 0.03 + 0.07 * a : 0.13); r.sc = 0.8; if (!tint) r.sprites.push({ w: 0.1 * s * 4.5, col: mul(0.1) }); return r; }
    var fade = role === 'fx' ? (a > 0.6 ? 1 : a > 0.35 ? 0.7 : a > 0.15 ? 0.45 : 0.25) : role === 'nova' ? (a > 0.6 ? 1 : a > 0.3 ? 0.65 : 0.35) : 1;
    var thin = ELONG[id] && s <= 2.4, k = role === 'e' ? (thin ? 0.35 : 0.55) : role === 'nova' ? 0.55 : 0.7;
    if (s > 6) k = Math.min(k, 0.45);
    r.col = mul(k * fade);
    var m = d.m, e = role === 'e';
    if (ELONG[id]) {
      var len = (id === 'fx_laser_player' ? 1.4 : id === 'fx_laser_enemy' ? 1.2 : 1.0) * s, wid = 0.1 * s;
      r.sc = [0.75, 0.75, 1];
      r.sprites.push({ dir: [m[8], m[9], m[10]], w: Math.max(0.6, wid * (e ? 4.5 : 4)), l: len * 1.2 + wid * 2, col: mul((e ? 0.6 : 0.5) * (thin ? 0.5 : 1)) });
    } else if ((id === 'fx_white' || id === 'fx_spark') && s <= 4 && role !== 'nova' && !e) r.sprites.push({ w: 0.1 * s * 5, col: mul(0.4 * fade) });
    else if (s > 6) r.sprites.push({ w: 0.1 * s * 3, col: mul(0.25) });
    return r;
  };
  // ---- v1.5.3：敌弹 / 我方激光的拖尾粒子（沿途随机冒出的白热亮点）不画；敌人枪口火花变暗、无柔光；敌人蓄力环点降亮
  rules.v153 = function (d) {
    if (d.role === 'etrail' || d.role === 'ptrail') return ADD[d.mesh.id] ? { col: [0, 0, 0], skip: true } : null;
    if (d.role === 'emz' && ADD[d.mesh.id]) { var a = d.a == null ? 1 : d.a, f = a > 0.6 ? 1 : a > 0.35 ? 0.7 : a > 0.15 ? 0.45 : 0.25, c = window.__fxColor(d.mesh.id, d.tint), k = window.__qk(0.3 * f); return { col: c.map(function (v) { return v * k; }) }; }
    var r = rules.v152(d);
    if (r && !r.skip && d.role === 'e' && !ELONG[d.mesh.id]) { var c2 = window.__fxColor(d.mesh.id, d.tint || E_CORE), k2 = window.__qk(0.45 * (d.s > 6 ? 0.8 : 1)); r.col = c2.map(function (v) { return v * k2; }); }
    return r;
  };
  // ---- v1.5.4：柔光（光辉）整体收小——激光柔光 4.5/4 -> 3.5/3 倍，粒子圆形柔光 5 -> 3.5 倍，大闪光 3 -> 2.2 倍，推进器白芯 4.5 -> 3 倍
  rules.v154 = function (d) {
    var r = rules.v153(d); if (!r || !r.sprites) return r;
    var s = d.s || 0, id = d.mesh.id, wid = 0.1 * s;
    r.sprites.forEach(function (q) {
      if (q.dir) { var e = d.role === 'e'; q.w = Math.max(0.5, wid * (e ? 3.5 : 3)); }
      else if (d.role === 'thrust') q.w = 0.1 * s * 3;
      else if (s > 6) q.w = 0.1 * s * 2.2;
      else q.w = 0.1 * s * 3.5;
    });
    return r;
  };
  // ---- v1.5.5：UrhoX 的“沿方向”广告牌朝向不可靠（真机上变成一排排竖条），细长弹道改回“细本体 + 一层贴身光套”（方向由模型矩阵决定，一定对齐）
  rules.v155 = function (d) {
    var r = rules.v154(d); if (!r || r.skip) return r;
    var id = d.mesh.id;
    if (ELONG[id] && r.sprites) {
      var e = d.role === 'e', thin = (d.s || 0) <= 2.4, c = window.__fxColor(id, d.role === 'e' && !d.tint ? E_CORE : d.tint), k = window.__qk((e ? 0.1 : 0.08) * (thin ? 0.5 : 1));
      r.sprites = []; r.sc = [0.8, 0.8, 1]; r.halos = [{ col: c.map(function (v) { return v * k; }), s: [1.7, 1.7, 1.04] }];
    }
    return r;
  };
  rules.nothrust = function (d) { if (d.role === 'thrust') return { col: [0, 0, 0] }; return rules.new(d); };
  window.__rules = rules;
  window.__urhoRule = function (d) { return rules[window.__ruleSet || 'old'](d); };
  window.__urhoBloom = function (env) { return { thr: Math.min(0.9, Math.pow(env.bloom.threshold, 1 / 2.2) * 0.94), mix: Math.min(0.5, env.bloom.mix * (window.__ruleSet === 'v154' ? 0.6 : window.__ruleSet === 'v152' || window.__ruleSet === 'v153' ? 0.7 : 0.78)) }; };
  window.__m4local = function (m, rot, sc) {
    var L;
    if (rot) { var w = 0.92388, x = 0.22095, y = x, z = x;
      L = [1 - 2 * (y * y + z * z), 2 * (x * y + z * w), 2 * (x * z - y * w), 0, 2 * (x * y - z * w), 1 - 2 * (x * x + z * z), 2 * (y * z + x * w), 0, 2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x * x + y * y), 0, 0, 0, 0, 1];
    } else L = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    var sv = typeof sc === 'number' ? [sc, sc, sc] : sc;
    for (var i = 0; i < 3; i++) { L[i] *= sv[0]; L[4 + i] *= sv[1]; L[8 + i] *= sv[2]; }
    var o = new Float32Array(16);
    for (var col = 0; col < 4; col++) for (var row = 0; row < 4; row++) { var s = 0; for (var k = 0; k < 4; k++) s += m[k * 4 + row] * L[col * 4 + k]; o[col * 4 + row] = s; }
    return o;
  };
})();
