/* 宇宙银河机甲 · 机库主界面（局外）
 * 布局：顶栏（舰长 / 标志 / 资源）、中央 3D 机库、左侧机甲与驾驶员卡、右侧章节与出击、底部导航。
 * 子页面：机库（机甲升级 + 改装天赋）、驾驶员（升星 / 出战）、召唤、每日。
 */
(function () {
  'use strict';
  var E = window.VoxEngine, C = window.Cosmic;
  if (!E || !C) return;
  var A, banner = 'mech', tab = 'home', sub = 'mech', wsub = 'mods', wsel = null, fresh = null, chapterSel = 1, mechSel = null, pilotSel = null, lastTalent = null, t0 = performance.now();
  var ENV = { bg: [0.05, 0.06, 0.14], ambient: [0.46, 0.44, 0.6], fog: [30, 70], key: { dir: [-0.4, -0.8, -0.45], color: [1, 0.95, 0.88], brightness: 1.25 },
    fill: { dir: [0.6, -0.3, 0.7], color: [0.45, 0.75, 1.0], brightness: 0.55 }, bloom: { threshold: 0.55, mix: 0.95 } };
  function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
  function fmt(n) { return Math.round(n).toLocaleString('zh-CN'); }
  function ui() { return document.getElementById('ui'); }
  function s() { return C.save; }
  function stars(n) { var o = ''; for (var i = 0; i < 5; i++) o += '<i class="st' + (i < n ? ' on' : '') + '"></i>'; return o; }
  function statBar(label, v, max, col) { return '<div class="mk-stat"><span>' + label + '</span><div><i style="width:' + Math.min(100, v / max * 100) + '%;background:' + col + '"></i></div><b>' + Math.round(v) + '</b></div>'; }
  function mechPower(id) { var m = C.mech(id), k = C.mechMul(id); return { hp: m.hp * k, fire: m.fire * 20 * k, spd: m.spd * 6 }; }
  function gtag(g) { return '<span class="mk-grade g' + g + '">' + g + '</span>'; }

  // ------------------------------------------------------------------ 3D 机库场景（全部使用现有资产搭建）
  var DECOR = (function () {
    var d = [];
    for (var x = -5; x <= 5; x++) for (var z = -3; z <= 3; z++) d.push(['env_deck_tile', [x * 2, -0.25, z * 2], 0, 1]);
    [-7.5, -4.5, -1.5, 1.5, 4.5, 7.5].forEach(function (x, i) { d.push([i === 2 ? 'env_door' : 'env_wall', [x, 0, -6.6], 0, 1]); });
    d.push(['env_antenna', [-9.5, 0, -4.8], 30, 1]); d.push(['env_antenna', [9.5, 0, -4.8], -30, 1]);
    d.push(['prop_cargo_container', [-7.4, 0, -2.6], 90, 1.1]); d.push(['prop_cargo_container', [-7.4, 1.32, -2.6], 85, 1.1]);
    d.push(['prop_supply_crate', [6.6, 0, -3.4], 15, 1.2]); d.push(['prop_supply_crate', [7.6, 0, -2.6], -10, 1.2]); d.push(['prop_supply_crate', [7.0, 0.95, -3.0], 30, 1.2]);
    d.push(['prop_fuel_canister', [5.6, 0, -4.4], 0, 1.2]); d.push(['prop_fuel_canister', [6.2, 0, -5.0], 0, 1.2]);
    d.push(['prop_console', [-4.8, 0, -4.6], 20, 1.1]);
    d.push(['env_crystal_cluster', [8.8, 0, 1.6], -40, 1.2]);
    d.push(['prop_turret', [-8.6, 0, 1.8], 140, 1.1]);
    return d;
  })();
  // 查看模式：机库 / 驾驶员页只展示一个主体，拖动旋转；主体自动居中到左右面板之间的空白区域
  var VIEW = { yaw: 0, dragX: null, last: -10 };
  var SA = null, hp = [];
  var GCOL = { S: '#57B8FF', SS: '#B47CFF', SSR: '#F5A524', SSSR: '#FF5D7A' }, GTINT = { S: [0.3, 0.7, 1.5], SS: [0.75, 0.4, 1.5], SSR: [1.6, 1.0, 0.25], SSSR: [1.7, 0.35, 0.55] };
  function top(g) { return g === 'SSR' || g === 'SSSR'; }
  function sortG(list) { var own = function (x) { return (C.MECHS.indexOf(x) >= 0 ? s().mechs[x.id] : s().chars[x.id]) ? 1 : 0; }; return list.slice().sort(function (a, b) { return ORDER[b.grade] - ORDER[a.grade] || own(b) - own(a); }); }
  function sceneFocus() {
    if (tab === 'pilots') return { pilot: pilotSel || s().pilot, mech: null };
    if (tab === 'hangar') return { mech: mechSel || s().mech, pilot: null };
    return { mech: s().mech, pilot: s().pilot };
  }
  // 根据界面上左右面板的位置，算出主体应出现的屏幕水平位置，再反推相机横移
  function frameShift(V, fovDeg, dist, leftDesign, rightDesign) {
    var l = V.safe[0] + leftDesign * V.s, r = V.w - V.safe[1] - rightDesign * V.s, ndc = ((l + r) / 2) / V.w * 2 - 1;
    return ndc * Math.tan(fovDeg * Math.PI / 360) * (V.w / V.h) * dist;
  }
  function frame(dt) {
    dt = Math.min(0.05, dt || 0.016);
    var V = A.view(), t = (performance.now() - t0) / 1000, draws = [];
    function add(model, p, yaw, sc, tint, pitch) { var m = E.getMesh(model); if (m) draws.push({ mesh: m, m: E.trs(p, yaw, pitch || 0, 0, sc), s: sc, tint: tint }); }
    var aspect = V.w / V.h, eye, tgt, fov;
    if (tab === 'summon') { var sc = summonScene(add, t, dt); eye = sc.eye; tgt = sc.tgt; fov = A.fitFov(sc.fov, aspect); }
    else {
      DECOR.forEach(function (d) { add(d[0], d[1], d[2], d[3]); });
      var f = sceneFocus();
      if (tab === 'hangar' || tab === 'pilots') {
        if (VIEW.dragX === null && t - VIEW.last > 2.5) VIEW.yaw += dt * 14;
        add('sys_pedestal', [0, 0, 0], 0, 2.6);
        if (f.mech) add(f.mech, [0, 0.24 + Math.sin(t * 1.6) * 0.05, 0], VIEW.yaw, 1.15);
        else add(f.pilot, [0, 0.25 + Math.sin(t * 2) * 0.04, 0], VIEW.yaw, 2.3);
        fov = A.fitFov(38, aspect);
        var dist = 11, sx = frameShift(V, fov, dist, 36 + 300 + 20, 36 + 600 + 20);
        eye = [sx, 3.1, dist]; tgt = [sx, 2.2, 0];
      } else {
        var sway = Math.sin(t * 0.5) * 18;
        add('sys_pedestal', [0, 0, 0], 0, 2.4);
        if (f.mech) add(f.mech, [-0.6, 0.24 + Math.sin(t * 1.6) * 0.05, 0], sway, 1.1);
        if (f.pilot) add(f.pilot, [2.7, 0, 1.4], -25 + Math.sin(t * 0.9) * 6, 1.25);
        eye = [3.2, 3.6, 11.5]; tgt = [0.2, 2.1, 0]; fov = A.fitFov(36, aspect);
      }
    }
    E.render({ env: tab === 'summon' ? SUM_ENV : ENV, eye: eye, target: tgt, fov: fov, aspect: aspect, near: 0.1, far: 400, draws: draws, stars: tab === 'summon' ? hubStars() : null, shadow: tab === 'summon' ? null : { range: 12, center: [0, 0, -1] } });
    var cv = document.getElementById('hud2d'); cv.getContext('2d').clearRect(0, 0, cv.width, cv.height);
  }
  var SUM_ENV = { bg: [0.03, 0.03, 0.09], ambient: [0.38, 0.36, 0.55], fog: [40, 160], key: { dir: [-0.3, -0.8, -0.5], color: [1, 0.92, 0.85], brightness: 1.1 },
    fill: { dir: [0.5, -0.2, 0.8], color: [0.6, 0.45, 1.0], brightness: 0.7 }, bloom: { threshold: 0.5, mix: 1.1 } };
  var hubStarBuf = null;
  function hubStars() {
    if (!hubStarBuf) { var out = []; for (var i = 0; i < 420; i++) { var x = Math.random() * 2 - 1, y = Math.random() * 2 - 1, z = Math.random() * 2 - 1, l = Math.hypot(x, y, z) || 1, r = 300; out.push(x / l * r, y / l * r, z / l * r, 3 + Math.random() * 6, Math.random() < 0.7 ? 0 : (Math.random() < 0.5 ? 1 : 2)); }
      hubStarBuf = E.buildStars({ data: out, colors: [[0.92, 0.93, 1.0], [0.6, 0.85, 1.0], [1.0, 0.8, 0.5]] }); }
    return hubStarBuf;
  }
  // ------------------------------------------------------------------ 召唤祭坛与召唤动画（3D 部分，界面部分在召唤页里）
  function burst(n, c, speed, tint, life, up) {
    for (var i = 0; i < n && hp.length < 220; i++) { var u = Math.random() * 2 - 1, a = Math.random() * Math.PI * 2, r = Math.sqrt(1 - u * u), sp = speed * (0.4 + Math.random() * 0.6);
      hp.push({ x: c[0], y: c[1], z: c[2], vx: Math.cos(a) * r * sp, vy: (up ? Math.abs(u) : u) * sp, vz: Math.min(Math.sin(a) * r * sp, sp * 0.15), life: life * (0.6 + Math.random() * 0.6), max: life, tint: tint, size: 0.6 + Math.random() * 0.6 }); }
  }
  function summonScene(add, t, dt) {
    var isM = banner === 'mech', feat = (isM ? C.MECHS : C.CHARS).filter(function (x) { return top(x.grade); });
    add('sys_pedestal', [0, 0, 0], t * 6, 3.4);
    for (var i = 0; i < 5; i++) { var a = Math.PI + i / 4 * Math.PI; add('env_crystal_cluster', [Math.cos(a) * 8, 0, Math.sin(a) * 5 - 3], a * 57 + t * 8, 1.15); }
    var eye = [0, 3.3, 12.5], tgt = [0, 2.6, 0], fov = 44, shard = [0, 3.4 + Math.sin(t * 1.5) * 0.25, 0], spin = t * 40;
    if (!SA) {
      add('prop_meteor_shard', shard, spin, 2.2);
      feat.forEach(function (x, k) { var px = k ? 4.4 : -4.4, py = 1.6 + Math.sin(t * 1.2 + k * 2) * 0.15; add('sys_pedestal', [px, py, -1.5], 0, 1.1); add(x.id, [px, py + 0.12, -1.5], (k ? -20 : 20) + Math.sin(t * 0.8 + k) * 10, isM ? 0.72 : 1.5); });
      if (Math.random() < 0.18) burst(1, [shard[0], shard[1], shard[2]], 1, [0.3, 0.55, 0.85], 1.6, true);
    } else {
      SA.t += dt; var T = SA.t, tint = GTINT[SA.grade];
      if (SA.phase === 'charge') {
        spin = t * 40 + T * T * 900; shard[1] += T * 2.5;
        add('prop_meteor_shard', shard, spin, 2.2 + T);
        for (var q = 0; q < 2; q++) { var aa = Math.PI + Math.random() * Math.PI, rr = 7; hp.push({ x: Math.cos(aa) * rr, y: 0.5 + Math.random() * 4, z: Math.sin(aa) * rr, vx: -Math.cos(aa) * rr * 1.4, vy: 1.5, vz: -Math.sin(aa) * rr * 1.4, life: 0.7, max: 0.7, tint: [0.7, 0.75, 0.95], size: 1 }); }
        if (T > 0.9) { SA.phase = 'fall'; SA.t = 0; C.sfx('warp'); }
      } else if (SA.phase === 'fall') {
        var k = Math.min(1, T / 0.6), y = 34 - 32 * k * k, col = k > 0.55 ? tint : [0.8, 0.8, 0.95];
        add('prop_meteor_shard', [0, y, 0], t * 500, 3.2);
        burst(2, [0, y + 1, 0], 2.5, col, 0.5);
        eye = [0, 3.3 + k * 0.6, 12.5]; tgt = [0, 2.6 + (1 - k) * 4, 0];
        if (k >= 1) { SA.phase = 'burst'; SA.t = 0; burst(90, [0, 1.5, 0], 16, tint, 1.4); C.sfx(top(SA.grade) ? 'win' : 'boom'); domFlash(); }
      } else if (SA.phase === 'burst') {
        var sh = Math.max(0, 0.6 - T) * 0.5; eye = [Math.random() * sh - sh / 2, 3.3 + Math.random() * sh, 12.5];
        if (Math.random() < 0.9) burst(3, [0, 1, 0], 6, tint, 1, true);
        if (T > 0.75) { SA.phase = 'cards'; SA.t = 0; domCards(); }
      } else if (SA.phase === 'cards') {
        if (Math.random() < 0.5) burst(1, [0, 1, 0], 4, tint, 1.2, true);
      } else if (SA.phase === 'show') {
        var it = SA.show[SA.si], g = it.grade, isMech = it.kind === 'mech';
        add(it.id, [0, 0.15, 0], Math.sin(T * 0.7) * 25 + T * 20, isMech ? 1.05 : 2.1);
        if (Math.random() < 0.9) burst(2, [Math.random() * 4 - 2, 0.2, Math.random() * 4 - 2], 3, GTINT[g], 1.6, true);
        eye = [0, 2.8, 10.5]; tgt = [0, 2.3, 0];
      }
    }
    hp = hp.filter(function (p) { p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt; p.z += p.vz * dt; var d = Math.exp(-dt * 1.8); p.vx *= d; p.vy *= d; p.vz *= d; return p.life > 0; });
    hp.forEach(function (p) { if (p.z > 5) return; add('fx_white', [p.x, p.y, p.z], p.life * 300, p.size * 1.3 * Math.max(0.2, p.life / p.max), p.tint, 45); });
    return { eye: eye, tgt: tgt, fov: fov };
  }

  // ------------------------------------------------------------------ 红点
  function dailyClaimable() {
    var sv = s(); if (!sv.daily.supply || !C.loginState().claimed || C.achReady() > 0 || !C.dailyChallenge().state.done) return true;
    if (C.idleAmount().credits >= 100) return true;
    return C.TASKS.some(function (t) { return !sv.daily.claimed[t.id] && (sv.daily[t.key] || 0) >= t.need; });
  }
  function pilotUpgradable() { var sv = s(); return C.CHARS.some(function (c) { var o = sv.chars[c.id], f = sv.frags[c.id] || 0; return o && o.star < 5 && f >= C.STAR_FRAGS[o.star]; }); }
  function mechUpgradable() { var sv = s(); return (C.mechLv(sv.mech) < C.MECH_MAX && sv.credits >= C.mechCost(C.mechLv(sv.mech))) || C.MECHS.some(function (m) { var st = C.mechStar(m.id); return st && st < 5 && (sv.frags[m.id] || 0) >= C.STAR_FRAGS[st]; }); }

  // ------------------------------------------------------------------ 外框
  var NAV = [['home', '出击', 'go'], ['hangar', '机库', 'mech'], ['pilots', '驾驶员', 'pilot'], ['work', '工坊', 'work'], ['summon', '召唤', 'summon'], ['daily', '每日', 'daily']];
  var NAV_ICON = {
    go: ['..aa....', '..aaa...', '..aaaa..', '..aaaaa.', '..aaaa..', '..aaa...', '..aa....', '........'],
    mech: ['..aaaa..', '..abba..', 'aaaaaaaa', 'a.aaaa.a', '..aaaa..', '..a..a..', '..a..a..', '.aa..aa.'],
    pilot: ['..aaaa..', '.aaaaaa.', '.abaaba.', '.aaaaaa.', '..aaaa..', '.aaaaaa.', 'aaaaaaaa', 'aaaaaaaa'],
    summon: ['...a....', '..aba...', '.abbba..', 'abbbbba.', '.abbba..', '..aba...', '...a....', '........'],
    daily: ['aaaaaaaa', 'abbbbbba', 'aaaaaaaa', 'abababba', 'aaaaaaaa', 'ababbaba', 'aaaaaaaa', '........'],
    work: ['.a.aa.a.', 'aaaaaaaa', '.abbbba.', 'aabaabaa', 'aabaabaa', '.abbbba.', 'aaaaaaaa', '.a.aa.a.']
  };
  function navIcon(id) {
    var px = ''; NAV_ICON[id].forEach(function (r) { for (var i = 0; i < r.length; i++) px += r[i] === '.' ? '.' : (r[i] === 'a' ? '0' : '1'); });
    return A.iconSVG({ w: 8, h: 8, pal: ['currentColor', '#5CF2DC'], px: px }, 44);
  }
  function shell(content) {
    var u = ui(); u.innerHTML = ''; var sv = s(), cleared = Object.keys(sv.cleared).length;
    var top = el('header', 'mk-top');
    top.innerHTML = '<div class="mk-captain"><span class="ic">' + A.catIcon('char_captain', 52) + '</span><div><b>舰长 罗汉</b><small>已通关 ' + cleared + ' / ' + C.CHAPTERS.length + ' 章</small></div></div>' +
      '<div class="mk-logo"><b>宇宙银河机甲</b><small>VOXEL MECHA</small></div>' +
      '<div class="mk-res"><span>' + A.resIcon('credit', 34) + '<b>' + fmt(sv.credits) + '</b></span><span class="src">' + A.resIcon('shard', 34) + '<b>' + fmt(sv.src) + '</b><button class="mk-plus" aria-label="获取星源">+</button></span>' +
      '<button class="mk-gear">设置</button></div>';
    u.appendChild(top);
    top.querySelector('.mk-plus').onclick = openGetSrc;
    top.querySelector('.mk-gear').onclick = openSettings;
    var dots = { daily: dailyClaimable(), pilots: pilotUpgradable(), summon: sv.src >= C.SUMMON.single || !sv.daily.free, hangar: mechUpgradable() };
    var nav = el('nav', 'mk-nav');
    NAV.forEach(function (n) {
      var b = el('button', 'mk-tab' + (tab === n[0] ? ' on' : ''), navIcon(n[2]) + '<span>' + n[1] + '</span>' + (dots[n[0]] ? '<i class="dot"></i>' : ''));
      b.onclick = function () { C.sfx('click'); tab = n[0]; mechSel = null; pilotSel = null; wsel = null; render(); };
      nav.appendChild(b);
    });
    u.appendChild(nav);
    content.forEach(function (c) { u.appendChild(c); });
  }
  // 独立界面外框（工坊、每日）：自带返回键与资源栏，不显示底部导航
  function shellFull(title, desc, body, subtabs) {
    var u = ui(); u.innerHTML = ''; var sv = s();
    var top = el('header', 'mk-ftop');
    top.innerHTML = '<button class="mk-back">‹ 返回</button><div class="mk-ft"><h2>' + title + '</h2><p>' + desc + '</p></div>' +
      (subtabs ? '<div class="mk-sub">' + subtabs.map(function (st) { return '<button data-s="' + st[0] + '"' + (wsub === st[0] ? ' class="on"' : '') + '>' + st[1] + '</button>'; }).join('') + '</div>' : '<span></span>') +
      '<div class="mk-res"><span>' + A.resIcon('credit', 34) + '<b>' + fmt(sv.credits) + '</b></span><span class="src">' + A.resIcon('shard', 34) + '<b>' + fmt(sv.src) + '</b><button class="mk-plus" aria-label="获取星源">+</button></span></div>';
    u.appendChild(top);
    top.querySelector('.mk-back').onclick = function () { C.sfx('click'); tab = 'home'; wsel = null; render(); };
    top.querySelector('.mk-plus').onclick = openGetSrc;
    top.querySelectorAll('.mk-sub button').forEach(function (bt) { bt.onclick = function () { wsub = bt.dataset.s; wsel = null; fresh = null; C.sfx('click'); render(); }; });
    var b = el('div', 'mk-fbody'); b.appendChild(body); u.appendChild(b);
  }
  function render() {
    if (tab === 'work') { shellFull('工坊', wsub === 'mods' ? '收集技能卡牌（形态 x 元素），抽到即入卡组，局内升级随机出现' : wsub === 'arms' ? '主武器 / 副武器 / 氮气推进：研发、升级、合成弹药，给每台机甲配装' : '研发天赋芯片，装备后永久生效', workBody(), [['mods', '技能模块'], ['chips', '天赋芯片'], ['arms', '武器']]); return; }
    if (tab === 'daily') { shellFull('每日', '每天回来领取补给、任务奖励与巡航收益', dailyBody()); return; }
    if (tab === 'home') shell(homeView());
    else if (tab === 'hangar') shell(hangarView());
    else if (tab === 'pilots') shell(pilotsView());
    else if (tab === 'summon') shell(summonView());
    else shell([page('每日', '每天回来领取补给与任务奖励', dailyBody())]);
  }
  function page(title, desc, body, subtabs, key) {
    var p = el('section', 'mk-page');
    var head = '<header><div><h2>' + title + '</h2><p>' + desc + '</p></div>';
    var cur = key === 'wsub' ? wsub : sub;
    if (subtabs) head += '<div class="mk-sub">' + subtabs.map(function (st) { return '<button data-s="' + st[0] + '"' + (cur === st[0] ? ' class="on"' : '') + '>' + st[1] + '</button>'; }).join('') + '</div>';
    p.innerHTML = head + '</header>';
    var b = el('div', 'mk-pbody'); b.appendChild(body); p.appendChild(b);
    p.querySelectorAll('.mk-sub button').forEach(function (bt) { bt.onclick = function () { if (key === 'wsub') { wsub = bt.dataset.s; wsel = null; } else sub = bt.dataset.s; C.sfx('click'); render(); }; });
    return p;
  }

  // ------------------------------------------------------------------ 主界面（出击）
  function mechCard(id, compact) {
    var m = C.mech(id), lv = C.mechLv(id), pw = mechPower(id), aw = lv >= C.MECH_AWAKE;
    return '<div class="mk-card mk-mech g' + m.grade + '"><div class="mk-ch">' + gtag(m.grade) + '<span class="tag">' + m.type + '</span><b>' + m.name + '</b><em>Lv ' + lv + (aw ? ' 觉醒' : '') + '</em></div><div class="mk-stars">' + stars(C.mechStar(id)) + '</div>' +
      statBar('耐久', pw.hp, 260, '#7CF29A') + statBar('火力', pw.fire, 190, '#F5A524') + statBar('机动', pw.spd, 100, '#57B8FF') +
      (compact ? '' : '<dl><div><dt>主武器</dt><dd>' + m.weapon.name + '<small>' + m.weapon.desc + '</small></dd></div><div><dt>机甲技能</dt><dd>' + m.active.name + '<small>' + m.active.desc + '，冷却 ' + m.active.cd + ' 秒</small></dd></div></dl>') + '</div>';
  }
  function pilotCard(id) {
    var c = C.char(id), st = s().chars[id] ? s().chars[id].star : 0, match = C.mech(s().mech).match === id;
    return '<div class="mk-card mk-pilot g' + c.grade + '"><span class="ic">' + A.catIcon(id, 64) + '</span><div><div class="mk-ch">' + gtag(c.grade) + '<b>' + c.name + '</b><em>' + c.role + '</em></div><div class="mk-stars">' + stars(st) + '</div>' +
      '<small>' + c.support.name + '：' + c.support.desc + '</small><small>被动：' + c.passive.name + '</small>' +
      (match ? '<span class="mk-match">专属机甲 耐久与火力 +20%</span>' : '<span class="mk-match off">专属机甲：' + C.mech(c.mech).name + '</span>') + '</div></div>';
  }
  // 推荐下一步：按玩家当前进度给出最多 3 条提示
  function nextSteps() {
    var sv = s(), out = [], cards = sv.modules.length, eqN = (sv.modEq || []).length;
    if (!sv.runs && !sv.best[1]) out.push({ go: 'home', t: '出击第 1 章', d: '跟着新手引导飞一圈，赚信用点和星源' });
    if (cards < 6) out.push({ go: 'work', t: '去工坊抽技能卡牌', d: '卡牌抽到即入卡组，局内升级随机出现（现有 ' + cards + ' 张）' });
    if (sv.credits >= C.MOD_TEN(sv.modBuys || 0)) out.push({ go: 'work', t: '信用点够 10 连抽了', d: '10 连 9 折必出蓝色以上，看广告还能翻倍再抽 10 张' });
    else if (sv.credits >= C.MOD_COST(sv.modBuys || 0)) out.push({ go: 'work', t: '信用点够抽卡了', d: '抽 1 次，看广告可翻倍再抽 1 次' });
    var nc = C.CHAPTERS[Math.min(C.CHAPTERS.length, sv.chapter) - 1]; if (nc && C.power() < nc.rec * 0.9) out.unshift({ go: 'hangar', t: '战力不足（' + C.power() + ' / 推荐 ' + nc.rec + '）', d: '先升级机甲等级 / 星级，多抽卡牌、装备芯片' });
    if (mechUpgradable()) out.push({ go: 'hangar', t: '机甲可以升级', d: '到机库提升等级或星级，耐久与火力一起变强' });
    if (pilotUpgradable()) out.push({ go: 'pilots', t: '驾驶员可以升星', d: '碎片足够了，升星提高支援技能' });
    if (dailyClaimable()) out.push({ go: 'daily', t: '每日有奖励可领', d: '补给、任务和巡航收益' });
    if (sv.chips.length < 3) out.push({ go: 'work', t: '研发天赋芯片', d: '芯片属性永久生效，凑齐同系列有额外效果' });
    var lo0 = C.loadout(sv.mech), am = lo0.sub ? (C.armory().subs[lo0.sub].stock || 0) : 99; if (am < 10) out.unshift({ go: 'arms', t: '副武器弹药不足（' + am + ' 发）', d: '去工坊 · 武器 合成弹药，每次出击最多带 ' + C.subCap(sv.mech) + ' 发' });
    return out.slice(0, 3);
  }
  var dangerSel = 1;
  function powCls(ch) { var r = C.power() / ch.rec; return r >= 1 ? 'ok' : r >= 0.8 ? 'mid' : 'low'; }
  function powTxt(ch) { var r = C.power() / ch.rec; return r >= 1.15 ? '战力充足，可以放心挑战' : r >= 1 ? '战力达标' : r >= 0.8 ? '略显吃力，建议先升级机甲或多抽卡牌' : '战力不足，建议先去机库 / 工坊变强'; }
  function homeView() {
    var sv = s(), left = el('section', 'mk-left'), right = el('section', 'mk-right');
    var mm = C.mech(sv.mech);
    left.innerHTML = '<p class="mk-label">出战机甲</p>' + mechCard(sv.mech, true).replace('</div></div>', '</div><p class="mk-brief">' + mm.weapon.name + '，技能 ' + mm.active.name + '</p></div>') + '<p class="mk-label">驾驶员</p>' + pilotCard(sv.pilot) +
      '<div class="mk-swap"><button class="mini alt" data-go="hangar">更换机甲</button><button class="mini alt" data-go="pilots">更换驾驶员</button></div>';
    var ch = C.CHAPTERS[chapterSel - 1], locked = chapterSel > sv.chapter, best = sv.best[ch.id] || 0;
    var pips = ''; for (var i = 1; i <= 6; i++) pips += '<i class="' + (i <= best ? 'on' : '') + (i === 3 ? ' elite' : '') + (i === 6 ? ' boss' : '') + '"></i>';
    right.innerHTML = '<div class="mk-card mk-chap"><div class="mk-chnav"><button class="mk-arrow" data-d="-1" aria-label="上一章"' + (chapterSel <= 1 ? ' disabled' : '') + '>‹</button>' +
      '<div><small>第 ' + ch.id + ' 章</small><b>' + ch.name + '</b></div><button class="mk-arrow" data-d="1" aria-label="下一章"' + (chapterSel >= C.CHAPTERS.length ? ' disabled' : '') + '>›</button></div>' +
      '<p>' + ch.desc + '</p><div class="mk-pips">' + pips + '</div><div class="mk-pow ' + powCls(ch) + '"><span>推荐战力 ' + ch.rec + '</span><b>你的战力 ' + C.power() + '</b><small>' + powTxt(ch) + '</small></div><div class="mk-chinfo"><span>首领 ' + ch.bossName + '</span><span>' + (sv.cleared[ch.id] ? '已通关' : '首通 星源 +' + ch.first) + '</span></div></div>' +
      '<div class="mk-dg"><button class="mk-arrow" data-dg="-1"' + (dangerSel <= 1 ? ' disabled' : '') + '>‹</button><div><b>危险等级 ' + dangerSel + '</b><small>敌人血量 +' + Math.round(12 * (dangerSel - 1)) + '%　伤害 +' + Math.round(8 * (dangerSel - 1)) + '%　奖励 +' + Math.round(15 * (dangerSel - 1)) + '%</small></div><button class="mk-arrow" data-dg="1"' + (dangerSel >= (sv.dangerMax || 1) ? ' disabled' : '') + '>›</button></div>' +
      '<button class="mk-go"' + (locked ? ' disabled' : '') + '><b>' + (locked ? '通关上一章解锁' : '出击') + '</b><small>' + (locked ? '' : '6 个星域，约 6 分钟') + '</small></button>' +
      '<button class="mk-end"' + (sv.cleared[1] ? '' : ' disabled') + '><b>无尽模式</b><small>' + (sv.cleared[1] ? '最高纪录：第 ' + (sv.endlessBest || 0) + ' 波' : '通关第 1 章解锁') + '</small></button>';
    left.querySelectorAll('[data-go]').forEach(function (b) { b.onclick = function () { tab = b.dataset.go; sub = 'mech'; render(); }; });
    right.querySelectorAll('.mk-arrow').forEach(function (b) { b.onclick = function () { chapterSel = Math.max(1, Math.min(C.CHAPTERS.length, chapterSel + (+b.dataset.d))); C.sfx('click'); render(); }; });
    var tips = nextSteps();
    if (tips.length) { var tb = el('div', 'mk-tips', '<p class="mk-label">推荐下一步</p>' + tips.map(function (t) { return '<button class="mk-tip" data-go="' + t.go + '"><b>' + t.t + '</b><small>' + t.d + '</small></button>'; }).join('')); left.appendChild(tb); tb.querySelectorAll('.mk-tip').forEach(function (b) { b.onclick = function () { C.sfx('click'); var go = b.dataset.go; if (go === 'arms') { tab = 'work'; wsub = 'arms'; wmech = null; ws.id = null; } else { tab = go; wsub = go === 'work' ? 'mods' : wsub; } sub = 'mech'; render(); }; }); }
    right.querySelector('.mk-go').onclick = function () { if (chapterSel <= sv.chapter) { C.sfx('gate'); window.CosmicRun.start(chapterSel, { danger: dangerSel }); } };
    right.querySelector('.mk-end').onclick = function () { if (sv.cleared[1]) { C.sfx('gate'); window.CosmicRun.start(chapterSel <= sv.chapter ? chapterSel : 1, { danger: dangerSel, endless: true }); } };
    right.querySelectorAll('[data-dg]').forEach(function (b) { b.onclick = function () { dangerSel = Math.max(1, Math.min(sv.dangerMax || 1, dangerSel + (+b.dataset.dg))); C.sfx('click'); render(); }; });
    return [left, right];
  }

  // ------------------------------------------------------------------ 机库：独立三栏（左列表 / 中 3D 展示台 / 右信息）
  function plate(id, isMech) {
    var x = isMech ? C.mech(id) : C.char(id), own = isMech ? C.ownsMech(id) : s().chars[id], st = isMech ? C.mechStar(id) : (own ? own.star : 0);
    return el('div', 'mk-plate', gtag(x.grade) + '<b>' + x.name + '</b><span>' + (isMech ? x.type : x.role) + '</span><div class="mk-stars">' + stars(st) + '</div>' + (own ? '' : '<em>未获得</em>') + '<small>拖动旋转查看</small>');
  }
  function listCol(items, selId, isMech) {
    items = sortG(items);     // 按等级从高到低排序，同级已拥有的在前
    var sv = s(), col = el('section', 'mk-lcol');
    col.innerHTML = items.map(function (x) {
      var o = isMech ? C.ownsMech(x.id) : sv.chars[x.id], on = x.id === selId, act = isMech ? x.id === sv.mech : x.id === sv.pilot;
      return '<button class="mk-li g' + x.grade + (on ? ' on' : '') + (o ? '' : ' locked') + '" data-id="' + x.id + '"><span class="ic">' + A.catIcon(x.id, 40) + '</span><div><b>' + x.name + '</b><small>' +
        (o ? (isMech ? 'Lv ' + C.mechLv(x.id) + ' · ' + C.mechStar(x.id) + ' 星' : x.role + ' · ' + o.star + ' 星') : '召唤获得') + '</small></div>' + gtag(x.grade) + (act ? '<i class="tg p">出战</i>' : '') + '</button>';
    }).join('');
    col.querySelectorAll('.mk-li').forEach(function (b) { b.onclick = function () { if (isMech) mechSel = b.dataset.id; else pilotSel = b.dataset.id; VIEW.yaw = 0; C.sfx('click'); render(); }; });
    return col;
  }
  function hangarView() {
    var sv = s(), id = mechSel || sv.mech, m = C.mech(id), own = C.ownsMech(id), lv = C.mechLv(id), pw = mechPower(id), aw = lv >= C.MECH_AWAKE;
    var cost = C.mechCost(lv), max = lv >= C.MECH_MAX, st = C.mechStar(id), frags = sv.frags[id] || 0, need = st >= 5 ? 0 : C.STAR_FRAGS[st], pilot = C.char(m.match);
    var rp = el('section', 'mk-rpanel g' + m.grade);
    rp.innerHTML = '<header>' + gtag(m.grade) + '<div><h2>' + m.name + '</h2><p>' + m.type + (own ? ' · Lv ' + lv + (aw ? ' · 已觉醒' : '') : ' · 未获得') + '</p></div></header>' +
      statBar('耐久', pw.hp, 260, '#7CF29A') + statBar('火力', pw.fire, 190, '#F5A524') + statBar('机动', pw.spd, 100, '#57B8FF') +
      '<dl><div><dt>武器配装（主武器 / 副武器 / 氮气）</dt><dd>' + C.weapon(C.loadout(id).main).n + ' / ' + (C.loadout(id).sub ? C.subDef(C.loadout(id).sub).n : '无') + ' / ' + C.nitroDef(C.loadout(id).nitro).n + '<small>机甲特性「' + (C.MECH_TRAIT[id] || {}).n + '」：' + (C.MECH_TRAIT[id] || {}).d + '</small></dd></div><div><dt>机甲技能 · 冷却 ' + m.active.cd + ' 秒</dt><dd>' + m.active.name + '<small>' + m.active.desc + '。' + m.active.awake + '</small></dd></div>' +
      '<div><dt>专属驾驶员</dt><dd>' + pilot.name + '<small>' + (sv.chars[pilot.id] ? '已拥有，' : '未获得，') + '搭配时耐久与火力 +20%</small></dd></div></dl><div class="mk-acts"></div>';
    var acts = rp.querySelector('.mk-acts');
    if (own) {
      var up = el('button', 'btn primary', max ? '已满级' : '升级 ' + A.resIcon('credit', 24) + ' ' + fmt(cost)); up.disabled = max;
      up.onclick = function () { if (sv.credits < cost) { A.toast('信用点不足：去出击赚取，或在每日里领巡航收益'); return; } sv.credits -= cost; sv.mechs[id].lv = lv + 1; C.write(); C.sfx('level'); A.toast(m.name + ' 升到 Lv ' + (lv + 1) + (lv + 1 === C.MECH_AWAKE ? '，技能觉醒！' : '')); render(); };
      var sb = el('button', 'btn', st >= 5 ? '已满星' : '升星（碎片 ' + frags + '/' + need + '）'); sb.disabled = st >= 5 || frags < need;
      sb.onclick = function () { sv.frags[id] -= need; sv.mechs[id].star = st + 1; C.write(); C.sfx('win'); A.toast(m.name + ' 升到 ' + (st + 1) + ' 星'); render(); };
      acts.appendChild(up); acts.appendChild(sb);
      var wb = el('button', 'btn mk-wide', '武器配装'); wb.onclick = function () { tab = 'work'; wsub = 'arms'; wmech = id; ws.id = null; C.sfx('click'); render(); }; acts.appendChild(wb);
      if (id !== sv.mech) { var se = el('button', 'btn mk-wide', '设为出战机甲'); se.onclick = function () { sv.mech = id; C.write(); C.sfx('click'); A.toast('出战机甲：' + m.name); render(); }; acts.appendChild(se); }
    } else { var gs = el('button', 'btn primary mk-wide', '前往机甲召唤'); gs.onclick = function () { tab = 'summon'; banner = 'mech'; render(); }; acts.appendChild(gs); }
    return [listCol(C.MECHS, id, true), rp, plate(id, true)];
  }
  // ------------------------------------------------------------------ 驾驶员：独立三栏
  function pilotsView() {
    var sv = s(), id = pilotSel || sv.pilot, c = C.char(id), own = sv.chars[id], st = own ? own.star : 0, frags = sv.frags[id] || 0, need = st >= 5 ? 0 : C.STAR_FRAGS[st] || 10;
    var rp = el('section', 'mk-rpanel g' + c.grade);
    rp.innerHTML = '<header>' + gtag(c.grade) + '<div><h2>' + c.name + '</h2><p>' + c.role + (own ? ' · ' + st + ' 星' : ' · 未获得') + '</p></div></header>' +
      '<dl><div><dt>支援技能 · 冷却 ' + c.support.cd + ' 秒</dt><dd>' + c.support.name + '<small>' + c.support.desc + '</small></dd></div><div><dt>被动</dt><dd>' + c.passive.name + '</dd></div>' +
      '<div><dt>专属机甲</dt><dd>' + C.mech(c.mech).name + '<small>' + (C.ownsMech(c.mech) ? '已拥有，' : '未获得，') + '搭配时耐久与火力 +20%</small></dd></div>' +
      '<div><dt>当前倍率</dt><dd>支援技能 x' + C.pilotMul(id).toFixed(2) + '<small>' + c.grade + ' 级基础 x' + C.GRADE[c.grade].mul + '，每升 1 星 +15%</small></dd></div></dl><div class="mk-acts"></div>';
    var acts = rp.querySelector('.mk-acts');
    if (own) {
      var up = el('button', 'btn primary', st >= 5 ? '已满星' : '升星（碎片 ' + frags + '/' + need + '）'); up.disabled = st >= 5 || frags < need;
      up.onclick = function () { sv.frags[id] -= need; own.star++; C.write(); C.sfx('level'); A.toast(c.name + ' 升到 ' + own.star + ' 星'); render(); };
      acts.appendChild(up);
      if (id !== sv.pilot) { var bp = el('button', 'btn', '设为驾驶员'); bp.onclick = function () { sv.pilot = id; C.write(); C.sfx('click'); A.toast('驾驶员：' + c.name); render(); }; acts.appendChild(bp); }
    } else { var gs = el('button', 'btn primary mk-wide', '前往驾驶员召唤'); gs.onclick = function () { tab = 'summon'; banner = 'pilot'; render(); }; acts.appendChild(gs); }
    return [listCol(C.CHARS, id, false), rp, plate(id, false)];
  }

  // ------------------------------------------------------------------ 召唤：独立全屏布局 + 召唤动画
  function summonView() {
    var sv = s(), isM = banner === 'mech', list = isM ? C.MECHS : C.CHARS, freeLeft = !sv.daily.free;
    var left = el('section', 'sm-banners');
    left.innerHTML = [['mech', '机甲召唤', C.MECHS], ['pilot', '驾驶员召唤', C.CHARS]].map(function (b) {
      var p = sv[b[0] + 'Pity'] || 0, ssr = b[2].filter(function (x) { return top(x.grade); });
      return '<button class="sm-bn' + (banner === b[0] ? ' on' : '') + '" data-b="' + b[0] + '"><span class="sm-bt">' + b[1] + '</span><span class="sm-bf">' + ssr.map(function (x) { return A.catIcon(x.id, 46); }).join('') + '</span>' +
        '<small>SSR / SSSR ' + ssr.map(function (x) { return x.name; }).join('、') + '</small><i style="width:' + (p / C.SUMMON.pitySSR * 100) + '%"></i><em>保底 ' + p + ' / ' + C.SUMMON.pitySSR + '</em></button>';
    }).join('');
    left.querySelectorAll('[data-b]').forEach(function (b) { b.onclick = function () { banner = b.dataset.b; C.sfx('click'); render(); }; });
    var title = el('section', 'sm-title', '<b>' + (isM ? '机甲召唤' : '驾驶员召唤') + '</b><span>SSR+ 出现率 5% · 十连必出 SS+ · ' + (C.SUMMON.pitySSR - (sv[banner + 'Pity'] || 0)) + ' 抽内必出 SSR+ · ' + (C.SUMMON.pitySSSR - (sv[banner + 'Pity3'] || 0)) + ' 抽内必出 SSSR</span>');
    var act = el('section', 'sm-actions');
    act.innerHTML = '<div class="sm-btns"><button class="btn cx-adbtn sm-free"' + (freeLeft ? '' : ' disabled') + '><b>每日免费</b><small>' + (freeLeft ? '看广告召唤 1 次' : '明天再来') + '</small></button>' +
      '<button class="btn sm-one"><b>召唤 1 次</b><small>' + A.resIcon('shard', 22) + ' ' + C.SUMMON.single + '</small></button><button class="btn primary sm-ten"><b>召唤 10 次</b><small>' + A.resIcon('shard', 22) + ' ' + C.SUMMON.ten + '（9 折）</small></button></div>' +
      '<button class="sm-rates">概率详情</button>';
    act.querySelector('.sm-rates').onclick = function () { rates(list); };
    function pull(n, cost) {
      if (sv.src < cost) { openGetSrc(); return; }
      sv.src -= cost; sv.daily.pulls = (sv.daily.pulls || 0) + n;
      var out = []; for (var i = 0; i < n; i++) out.push(C.pull(banner, false));
      if (n === 10 && !out.some(function (r) { return r.grade !== 'S'; })) { sv[banner + 'Pity']--; out[9] = C.pull(banner, true); }
      C.write(); startSummon(out);
    }
    act.querySelector('.sm-one').onclick = function () { pull(1, C.SUMMON.single); };
    act.querySelector('.sm-ten').onclick = function () { pull(10, C.SUMMON.ten); };
    act.querySelector('.sm-free').onclick = function () {
      if (sv.daily.free) return;
      C.showAd('每日免费召唤', function (r) { if (!r.success) { A.toast('需要完整看完广告才能召唤'); return; } sv.daily.free = 1; sv.daily.pulls = (sv.daily.pulls || 0) + 1; var res = [C.pull(banner, false)]; C.write(); startSummon(res); });
    };
    return [left, title, act];
  }
  function rates(list) {
    var m = el('div', 'sv-modal');
    m.innerHTML = '<div class="panel sv-pbox mk-get"><h1>概率详情</h1>' + ['SSSR', 'SSR', 'SS', 'S'].map(function (g) {
      var xs = list.filter(function (x) { return x.grade === g; });
      return '<div class="mk-row"><div>' + gtag(g) + ' <b>' + xs.map(function (x) { return x.name; }).join('、') + '</b><small>合计 ' + Math.round(C.SUMMON.rates[g] * 100) + '%，每个 ' + (C.SUMMON.rates[g] * 100 / xs.length).toFixed(1) + '%</small></div></div>';
    }).join('') + '<p class="note">十连至少 1 个 SS 以上；每个卡池 50 抽内必出 SSR，两个卡池分开计算。每个卡池 120 抽内必出 SSSR。已拥有的会转成碎片：S +6，SS +12，SSR +25，SSSR +40。</p><button class="btn primary mk-close">知道了</button></div>';
    ui().appendChild(m); m.querySelector('.mk-close').onclick = function () { m.remove(); };
  }
  // —— 召唤动画：蓄能 → 陨石坠落 → 光爆 → 翻卡 → 新角色登场 ——
  var ORDER = { S: 0, SS: 1, SSR: 2, SSSR: 3 };
  function startSummon(res) {
    var best = res.reduce(function (a, r) { return ORDER[r.grade] > ORDER[a] ? r.grade : a; }, 'S');
    SA = { phase: 'charge', t: 0, grade: best, res: res, show: res.filter(function (r) { return r.isNew && r.grade !== 'S'; }), si: 0 };
    hp = []; ui().classList.add('summoning');
    var ov = el('div', 'sm-anim'); ov.innerHTML = '<div class="sm-rays"></div><div class="sm-flash"></div><div class="sm-stage"></div><button class="sm-skip">跳过</button>';
    ui().appendChild(ov); SA.ov = ov;
    ov.querySelector('.sm-skip').onclick = function () { if (SA.phase === 'charge' || SA.phase === 'fall' || SA.phase === 'burst') { SA.phase = 'cards'; SA.t = 0; domFlash(true); domCards(true); } else if (SA.phase === 'cards') domCards(true); else finishSummon(); };
    C.sfx('skill');
  }
  function domFlash(quiet) {
    var ov = SA.ov, c = GCOL[SA.grade];
    ov.style.setProperty('--g', c); ov.classList.add('lit', 'g' + SA.grade);
    if (!quiet) { var f = ov.querySelector('.sm-flash'); f.classList.remove('go'); void f.offsetWidth; f.classList.add('go'); }
  }
  function domCards(instant) {
    var ov = SA.ov, st = ov.querySelector('.sm-stage'), res = SA.res;
    st.innerHTML = '<div class="sm-cards n' + res.length + '">' + res.map(function (r, i) {
      var x = r.kind === 'mech' ? C.mech(r.id) : C.char(r.id);
      return '<div class="sm-card g' + r.grade + '" style="--d:' + (instant ? 0 : 0.15 + i * 0.16 + (top(r.grade) ? 0.35 : 0)) + 's"><div class="sm-in"><div class="sm-back"><span>✦</span></div>' +
        '<div class="sm-front">' + gtag(r.grade) + '<span class="ic">' + A.catIcon(r.id, res.length > 1 ? 56 : 120) + '</span><b>' + x.name + '</b><small>' + (r.isNew ? '新获得！' : '碎片 +' + r.frag) + '</small></div></div></div>';
    }).join('') + '</div><button class="btn primary sm-next">' + (SA.show.length ? '查看新角色' : '完成') + '</button>';
    var cards = st.querySelectorAll('.sm-card');
    cards.forEach(function (c, i) { setTimeout(function () { c.classList.add('flip'); C.sfx(top(res[i].grade) ? 'win' : res[i].grade === 'SS' ? 'level' : 'click'); }, instant ? 0 : (0.15 + i * 0.16 + (top(res[i].grade) ? 0.35 : 0)) * 1000); });
    st.querySelector('.sm-next').onclick = function () { if (SA.show.length) startShow(0); else finishSummon(); };
  }
  function startShow(i) {
    SA.phase = 'show'; SA.t = 0; SA.si = i; hp = [];
    var r = SA.show[i], x = r.kind === 'mech' ? C.mech(r.id) : C.char(r.id), st = SA.ov.querySelector('.sm-stage');
    SA.ov.className = 'sm-anim lit g' + r.grade; SA.ov.style.setProperty('--g', GCOL[r.grade]);
    st.innerHTML = '<div class="sm-show"><div class="sm-stamp g' + r.grade + '">' + r.grade + '</div><b>' + x.name + '</b><span>' + (r.kind === 'mech' ? x.type + ' 机甲' : x.role) + '</span><em>新获得！</em>' +
      '<p>' + (r.kind === 'mech' ? x.active.name + '：' + x.active.desc : x.support.name + '：' + x.support.desc) + '</p></div><button class="btn primary sm-next">' + (i + 1 < SA.show.length ? '下一个' : '完成') + '</button>';
    C.sfx(top(r.grade) ? 'win' : 'level');
    st.querySelector('.sm-next').onclick = function () { if (i + 1 < SA.show.length) startShow(i + 1); else finishSummon(); };
  }
  function finishSummon() { if (SA && SA.ov) SA.ov.remove(); SA = null; hp = []; ui().classList.remove('summoning'); render(); }

  // ------------------------------------------------------------------ 工坊：技能模块与天赋芯片
  var CHIP_PIX = ['.a.aa.a.', 'aaaaaaaa', '.abbbba.', 'aabccbaa', 'aabccbaa', '.abbbba.', 'aaaaaaaa', '.a.aa.a.'];
  function chipIcon(c, px) {
    var col = C.RARITY[c.tier].color, out = '';
    CHIP_PIX.forEach(function (r) { for (var i = 0; i < r.length; i++) out += r[i] === '.' ? '.' : r[i] === 'a' ? '0' : r[i] === 'b' ? '1' : '2'; });
    return A.iconSVG({ w: 8, h: 8, pal: ['#5A6175', col, '#FFFFFF'], px: out }, px);
  }
  function itemIcon(it, isMod, px) { return isMod ? A.iconSVG(C.modIcon(it), px) : chipIcon(it, px); }
  function itemLines(it, isMod) {
    if (isMod) {
      var E1 = C.modElem(it.elem), lines = ['<li>' + C.modDesc(it) + '</li>', '<li>' + E1.d + '</li>'];
      it.tags.forEach(function (k) { var t = C.modTag(k); lines.push('<li>' + t.n + '：' + t.d + '</li>'); });
      if (it.tier === 3) { lines.push('<li>金色：数量 +1，伤害 x1.9</li>'); var gf = C.goldTag(it); if (gf) lines.push('<li class="tr">金色特效：' + gf.d + '</li>'); }
      return lines.join('');
    }
    var l = it.aff.map(function (a) { return '<li>' + C.affText(a, it) + '</li>'; }).join('');
    if (it.trait) { var tr = C.trait(it.trait); l += '<li class="tr">' + tr.n + '：' + tr.d + '</li>'; }
    return l;
  }
  // 工坊（独立界面）：技能卡牌图鉴（形态 x 元素，未抽到的为灰色）与天赋芯片，均可看广告升级
  var wk = { form: 'homing', elem: 'light', tier: null, v: null };
  function adLvBtn(it) {
    var lv = it.lvl || 1, left = C.adUpLeft();
    return '<button class="btn cx-adbtn wk-ad"' + (lv >= C.LV_MAX || left <= 0 ? ' disabled' : '') + '>看广告 升到 Lv ' + Math.min(C.LV_MAX, lv + 1) + '<small>' + (lv >= C.LV_MAX ? '已满级' : '今日还可 ' + left + ' 次') + '</small></button>';
  }
  function doAdUp(it, name) {
    C.showAd('升级' + name, function (r) {
      if (!r.success) { A.toast('需要完整看完广告才能升级'); return; }
      var u = C.adUpgrade(it); if (u.err) { A.toast(u.err); return; }
      C.sfx('level'); A.toast(name + ' 升到 Lv ' + it.lvl); render();
    });
  }
  function pips(lv) { var o = ''; for (var i = 1; i <= C.LV_MAX; i++) o += '<i class="' + (i <= lv ? 'on' : '') + '"></i>'; return '<span class="wk-pips">' + o + '</span>'; }
  function modsView() {
    var sv = s(), eq = sv.modEq = (sv.modEq || []).filter(function (id) { return sv.modules.some(function (x) { return x.id === id; }); }), owned = sv.modules.length, total = C.MOD_TOTAL();
    var box = el('div', 'wk-split'), left = el('div', 'wk-main'), right = el('aside', 'wk-side');
    var sl = '', deckN = C.modDeck().length;
    for (var i = 0; i < 0; i++) {
      var m = null;
      sl += '<button class="wk-slot' + (m ? ' full r' + m.tier : '') + '" data-id="' + (m ? m.id : '') + '">' + (m ? '<span class="ic">' + A.iconSVG(C.modIcon(m), 52) + '</span><b>' + m.name + '</b><em>Lv ' + (m.lvl || 1) + '</em>' : '<b>空槽位</b>') + '</button>';
    }
    sl = '<div class="wk-sum"><b>本局卡组 ' + deckN + ' 张</b><span>出击时开局随机带 1 张，升级时随机出现新卡（每局最多 ' + C.RUN_MOD_MAX + ' 个技能），每次组合都不一样。同形态同元素取最强的一张</span></div>';
    var grid = '<div class="wk-codex"><div class="wk-ch"><span></span>' + C.ELEMENTS.map(function (e) { return '<b>' + e.n + '</b>'; }).join('') + '</div>';
    C.MOD_FORMS.forEach(function (F) {
      grid += '<div class="wk-cr"><b class="wk-fn">' + F.n + '</b>';
      C.ELEMENTS.forEach(function (El) {
        var m = C.modBest(F.k, El.k), preview = m || C.makeModule(0, F.k, El.k), isEq = false, dots = '';
        for (var t = 0; t < 4; t++) dots += '<i class="' + (C.modOwned(F.k, El.k, t) ? 'on t' + t : '') + '"></i>';
        grid += '<button class="wk-card' + (m ? ' own r' + m.tier : ' gray') + (wk.form === F.k && wk.elem === El.k ? ' sel' : '') + (isEq ? ' eqd' : '') + (fresh === F.k + ':' + El.k ? ' fresh' : '') + '" data-f="' + F.k + '" data-e="' + El.k + '">' +
          '<span class="ic">' + A.iconSVG(C.modIcon(preview), 38) + '</span><span class="wk-dots">' + dots + '</span>' + (isEq ? '<i class="tg c">装备</i>' : '') + '</button>';
      });
      grid += '</div>';
    });
    grid += '</div>';
    left.innerHTML = '<div class="wk-sum"><b>已收集 ' + owned + ' / ' + total + ' 张卡牌</b><span>20 种形态 x 6 种元素 x 4 种品质（白 / 蓝 / 紫 / 金）x 词条变体，共 ' + total + ' 张。抽到的卡牌自动加入卡组；重复抽到会升级该卡牌</span></div>' + sl + grid;
    if (wk.tier == null || !C.modOwned(wk.form, wk.elem, wk.tier)) { var bst = C.modBest(wk.form, wk.elem); if (bst) { wk.tier = bst.tier; wk.v = bst.v || 0; } }
    if (wk.tier != null && (wk.v == null || !C.modOwned(wk.form, wk.elem, wk.tier, wk.v))) { var any = C.modOwned(wk.form, wk.elem, wk.tier); if (any) wk.v = any.v || 0; }
    var F0 = C.modForm(wk.form), E0 = C.modElem(wk.elem), tShow = wk.tier == null ? 0 : wk.tier, sel = wk.tier != null ? C.modOwned(wk.form, wk.elem, wk.tier, wk.v) : null, cost = C.MOD_COST(sv.modBuys || 0), det;
    var gsel = '<div class="wk-grades">' + [0, 1, 2, 3].map(function (t) { var o = C.modOwned(wk.form, wk.elem, t); return '<button class="wk-g t' + t + (o ? '' : ' gray') + (tShow === t ? ' sel' : '') + '" data-t="' + t + '">' + C.RARITY[t].n.split('·')[0] + '</button>'; }).join('') + '</div>';
    var vsel = '<div class="wk-vars">' + [].concat(Array(C.VARIANTS[tShow]).join(',').split(',')).map(function (_, v) { var pv = C.makeModule(tShow, wk.form, wk.elem, v), o = C.modOwned(wk.form, wk.elem, tShow, v); return '<button class="wk-v' + (o ? '' : ' gray') + (sel && (sel.v || 0) === v && sel.tier === tShow ? ' sel' : '') + '" data-v="' + v + '">' + (pv.name.indexOf('·') >= 0 ? pv.name.split('·')[1] : '基础') + (o ? ' Lv' + (o.lvl || 1) : '') + '</button>'; }).join('') + '</div>';
    if (sel) {
      det = '<div class="mk-ch"><span class="ic">' + A.iconSVG(C.modIcon(sel), 64) + '</span><div><b class="wk-nm">' + sel.name + '</b><small style="color:' + C.RARITY[sel.tier].color + '">' + C.RARITY[sel.tier].n + '　' + pips(sel.lvl || 1) + ' Lv ' + (sel.lvl || 1) + '</small></div></div>' + gsel + vsel + '<ul>' + itemLines(sel, true) + '<li>卡牌等级加成：伤害 +' + Math.round((C.modLvMult(sel) - 1) * 100) + '%</li></ul>' +
        '<div class="mk-pbtns">' + adLvBtn(sel) + '</div>';
    } else {
      det = '<div class="mk-ch"><span class="ic gray">' + A.iconSVG(C.modIcon({ form: wk.form, color: '#8A92B0' }), 64) + '</span><div><b class="wk-nm">' + E0.n + F0.n + '</b><small>未获得</small></div></div>' + gsel + vsel + '<ul><li>' + F0.d + '</li><li>' + E0.d + '</li><li class="tr">元素反应：' + (C.REACT_HINT[E0.k] || '') + '</li></ul><p class="note">抽到这张卡牌后自动加入卡组，局内升级时随机出现。品质越高，伤害与词条越强。</p>';
    }
    right.innerHTML = '<div class="mk-card mk-idet">' + det + '<div class="mk-pbtns"><button class="btn primary mk-buy" data-n="1">抽 1 次<small>' + A.resIcon('credit', 22) + ' ' + fmt(cost) + '</small></button><button class="btn primary mk-buy" data-n="10">抽 10 次<small>' + A.resIcon('credit', 22) + ' ' + fmt(C.MOD_TEN(sv.modBuys || 0)) + '（9 折）</small></button></div><p class="mk-odds">共 ' + total + ' 张卡牌。品质概率：白 60%，蓝 28%，紫 10%，金 2%。10 连必出蓝色以上，每 40 次必出金色。重复抽到 = 卡牌 +1 级。抽完可看广告翻倍，免费再抽同样次数。</p></div>';
    box.appendChild(left); box.appendChild(right);
    box.querySelectorAll('.wk-card').forEach(function (b) { b.onclick = function () { wk.form = b.dataset.f; wk.elem = b.dataset.e; wk.tier = null; fresh = null; C.sfx('click'); render(); }; });
    box.querySelectorAll('.wk-g').forEach(function (b) { b.onclick = function () { wk.tier = +b.dataset.t; var o = C.modOwned(wk.form, wk.elem, wk.tier); wk.v = o ? (o.v || 0) : 0; C.sfx('click'); render(); }; });
    box.querySelectorAll('.wk-v').forEach(function (b) { b.onclick = function () { wk.tier = tShow; wk.v = +b.dataset.v; C.sfx('click'); render(); }; });
    var ab = box.querySelector('.wk-ad'); if (ab) ab.onclick = function () { doAdUp(sel, sel.name); };
    box.querySelectorAll('.mk-buy').forEach(function (b) { b.onclick = function () { doDraw(+b.dataset.n, false); }; });
    return box;
  }
  function chipsView() {
    var sv = s(), list = sv.chips, slots = C.chipSlots(), eq = sv.chipEq = (sv.chipEq || []).filter(function (id) { return list.some(function (x) { return x.id === id; }); });
    var box = el('div', 'wk-split'), left = el('div', 'wk-main'), right = el('aside', 'wk-side'), cost = C.CHIP_COST(sv.chipBuys || 0);
    var sl = '<div class="wk-slots six"><span class="mk-label">已装备芯片（' + eq.length + ' / ' + slots + '，通关章节解锁更多槽位）</span><div>';
    for (var i = 0; i < 6; i++) {
      var it = list.filter(function (x) { return x.id === eq[i]; })[0], locked = i >= slots;
      sl += '<button class="wk-slot' + (it ? ' full r' + it.tier : '') + (locked ? ' locked' : '') + '" data-id="' + (it ? it.id : '') + '">' + (it ? '<span class="ic">' + chipIcon(it, 44) + '</span><b>' + it.name + '</b><em>Lv ' + (it.lvl || 1) + '</em>' : '<b>' + (locked ? '通关解锁' : '空槽位') + '</b>') + '</button>';
    }
    sl += '</div></div>';
    var sorted = list.slice().sort(function (a, b) { return b.tier - a.tier || (b.lvl || 1) - (a.lvl || 1); });
    var inv = '<div class="wk-inv">' + (sorted.length ? sorted.map(function (it) {
      var on = eq.indexOf(it.id) >= 0;
      return '<button class="mk-item r' + it.tier + (wsel === it.id ? ' sel' : '') + (fresh === it.id ? ' fresh' : '') + '" data-id="' + it.id + '"><span class="ic">' + chipIcon(it, 46) + '</span><b>' + it.name + '</b><small style="color:' + C.RARITY[it.tier].color + '">' + C.RARITY[it.tier].n + '　Lv ' + (it.lvl || 1) + '</small>' + (on ? '<i class="tg c">已装备</i>' : '') + '</button>';
    }).join('') : '<p class="note">芯片仓库是空的，点右侧研发一个吧。</p>') + '</div>';
    left.innerHTML = '<div class="wk-sum"><b>芯片仓库 ' + list.length + ' / ' + C.INV_MAX + '</b><span>装备的芯片属性全部叠加，永久生效；芯片每升 1 级，词条数值 +12%</span></div>' + sl + inv;
    var sel = wsel ? list.filter(function (x) { return x.id === wsel; })[0] : null, det;
    if (sel) {
      det = '<div class="mk-ch"><span class="ic">' + chipIcon(sel, 64) + '</span><div><b class="wk-nm">' + sel.name + '</b><small style="color:' + C.RARITY[sel.tier].color + '">' + C.RARITY[sel.tier].n + '　' + pips(sel.lvl || 1) + ' Lv ' + (sel.lvl || 1) + '</small></div></div><ul>' + itemLines(sel, false) + '</ul>' +
        '<div class="mk-pbtns"><button class="btn primary mk-eq">' + (eq.indexOf(sel.id) >= 0 ? '卸下' : '装备') + '</button>' + adLvBtn(sel) + '<button class="btn mk-dis">分解 +' + C.REFUND[sel.tier] + '</button></div>';
    } else det = '<p class="note">点左侧的芯片查看详情，可装备、看广告升级或分解。</p>';
    right.innerHTML = '<div class="mk-card mk-idet">' + det + '<button class="btn primary mk-buy">研发天赋芯片<small>' + A.resIcon('credit', 22) + ' ' + fmt(cost) + '，仓库 ' + list.length + ' / ' + C.INV_MAX + '</small></button><p class="mk-odds">品质概率：白 60%，蓝 28%，紫 10%，金 2%。每 10 次必出蓝色以上，每 40 次必出金色。芯片共 8 个系列 x 21 种属性 x 4 种品质，另有 4 种金色特性。</p></div>';
    box.appendChild(left); box.appendChild(right);
    box.querySelectorAll('.mk-item, .wk-slot.full').forEach(function (b) { b.onclick = function () { wsel = b.dataset.id; fresh = null; C.sfx('click'); render(); }; });
    var eb = box.querySelector('.mk-eq');
    if (eb) eb.onclick = function () { var k = eq.indexOf(sel.id); if (k >= 0) eq.splice(k, 1); else { if (eq.length >= slots) { A.toast('槽位已满，先卸下一个'); return; } eq.push(sel.id); } C.write(); C.sfx('click'); render(); };
    var ab = box.querySelector('.wk-ad'); if (ab) ab.onclick = function () { doAdUp(sel, sel.name); };
    var db = box.querySelector('.mk-dis');
    if (db) db.onclick = function () { var k = eq.indexOf(sel.id); if (k >= 0) eq.splice(k, 1); list.splice(list.indexOf(sel), 1); sv.credits += C.REFUND[sel.tier]; wsel = null; C.write(); C.sfx('pop'); A.toast('分解完成：信用点 +' + C.REFUND[sel.tier]); render(); };
    box.querySelector('.mk-buy').onclick = function () {
      var r = C.buyChip(); if (r.err) { A.toast(r.err); return; }
      var it = r.chip; C.write(); C.sfx(it.tier >= 2 ? 'win' : 'level'); if (eq.length < slots) eq.push(it.id); wsel = it.id; fresh = it.id; render(); reveal(it, false);
    };
    return box;
  }
  // ------------------------------------------------------------------ 工坊 · 武器（v19）：每台机甲的 主武器 / 副武器 / 氮气推进 配装、研发、升级、合成弹药
  var ws = { kind: 'weapons', id: null }, wmech = null;
  function armName(kind, id) { return kind === 'weapons' ? C.weapon(id).n : kind === 'subs' ? C.subDef(id).n : C.nitroDef(id).n; }
  function ownedMechs() { var sv = s(); return C.MECHS.filter(function (m) { return sv.mechs[m.id]; }).map(function (m) { return m.id; }); }
  function armsView() {
    var sv = s(), mid = wmech && sv.mechs[wmech] ? wmech : sv.mech, m = C.mech(mid), lo = C.loadout(mid), a = C.armory(), tr = C.MECH_TRAIT[mid] || { n: '', d: '' };
    if (!ws.id) { ws.kind = 'weapons'; ws.id = lo.main; }
    var box = el('div', 'wk-split'), left = el('div', 'wk-main'), right = el('aside', 'wk-side');
    function slot(kind, id, label) {
      var lv = id ? C.armLv(kind, id) : 0, info = kind === 'subs' ? (id ? 'Lv ' + lv + ' · 库存 ' + (a.subs[id].stock || 0) + '，带 ' + Math.min(a.subs[id].stock || 0, C.subCap(mid)) + ' 发' : '未装备') : 'Lv ' + lv;
      return '<button class="wk-slot full wa-slot' + (id && ws.kind === kind && ws.id === id ? ' sel' : '') + '" data-k="' + kind + '" data-id="' + (id || '') + '" style="--wc:' + (id ? C.armColor(kind, id) : '#5A6175') + '"><small>' + label + '</small>' + (id ? '<span class="ic">' + A.iconSVG(C.armIcon(kind, id), 44) + '</span>' : '') + '<b>' + (id ? armName(kind, id) : '空') + '</b><em>' + info + '</em></button>';
    }
    function cell(kind, it, isEq, native) {
      var lv = C.armLv(kind, it.id), own = lv > 0, info = kind === 'subs' && own ? 'Lv ' + lv + ' · 库存 ' + (a.subs[it.id].stock || 0) : own ? 'Lv ' + lv : '未研发';
      return '<button class="wa-cell' + (own ? '' : ' gray') + (ws.kind === kind && ws.id === it.id ? ' sel' : '') + '" data-k="' + kind + '" data-id="' + it.id + '" style="--wc:' + C.armColor(kind, it.id) + '"><span class="ic">' + A.iconSVG(C.armIcon(kind, it.id), 34) + '</span><b>' + it.n + '</b><small>' + info + '</small>' + (isEq ? '<i class="tg c">装备中</i>' : native ? '<i class="tg">本命</i>' : '') + '</button>';
    }
    var h = '<div class="wk-sum wa-head"><div class="wa-mech"><button class="mini alt wa-prev">‹</button><span class="ic">' + A.catIcon(mid, 52) + '</span><div><b>' + m.name + ' 的配装</b><small>' + m.type + (mid === sv.mech ? ' · 出战中' : ' · 点左右切换机甲') + '</small></div><button class="mini alt wa-next">›</button></div>' +
      '<span>机甲特性「' + tr.n + '」：' + tr.d + '。机甲技能「' + m.active.name + '」：' + m.active.desc + '</span></div>' +
      '<div class="wk-slots wa-slots"><div>' + slot('weapons', lo.main, '主武器') + slot('subs', lo.sub, '副武器') + slot('nitros', lo.nitro, '氮气推进') + '</div></div>';
    h += '<p class="mk-label">主武器：6 个系列 x 3 种型号，装在本命机甲上伤害 +' + Math.round(C.NATIVE_BONUS * 100) + '%</p><div class="wa-grid">';
    C.WFAM.forEach(function (f) {
      h += '<div class="wa-row"><b class="wk-fn">' + f.n + '</b>' + C.WEAPONS.filter(function (w) { return w.fam === f.k; }).map(function (w) { return cell('weapons', w, lo.main === w.id, f.k === m.weapon.type); }).join('') + '</div>';
    });
    h += '</div><p class="mk-label">副武器（飞弹，消耗弹药；每次出击最多带 ' + C.subCap(mid) + ' 发）</p><div class="wa-grid wa-3">' + C.SUBS.map(function (d) { return cell('subs', d, lo.sub === d.id, false); }).join('') + '</div>';
    h += '<p class="mk-label">氮气推进</p><div class="wa-grid wa-3">' + C.NITROS.map(function (n) { return cell('nitros', n, lo.nitro === n.id, n.mech === mid); }).join('') + '</div>';
    left.innerHTML = h;
    // 右侧：选中装备的详情与操作
    var k = ws.kind, id = ws.id || lo.main, lv = C.armLv(k, id), own = lv > 0, slotKey = k === 'weapons' ? 'main' : k === 'subs' ? 'sub' : 'nitro', isEq = lo[slotKey] === id, lines = [], name, L = lv || 1;
    if (k === 'weapons') {
      var w = C.weapon(id), f = C.wfam(w.fam); name = w.n;
      lines.push(w.d); lines.push('系列：' + f.n + '，' + f.d);
      lines.push(w.fam === m.weapon.type ? '本命武器：' + m.name + ' 使用时伤害 +' + Math.round(C.NATIVE_BONUS * 100) + '%' : '本命机甲：' + C.mech(f.mech).name + '（装在' + m.name + '上从它自己的炮口射出）');
      lines.push('等级加成：伤害 +' + Math.round((C.wLvMult(L) - 1) * 100) + '%（每级 +12%，最高 Lv' + C.ARM_LV_MAX + '）');
    } else if (k === 'subs') {
      var d = C.subDef(id), stock = own ? a.subs[id].stock || 0 : 0; name = d.n;
      lines.push(d.d); lines.push('冷却 ' + d.cd + ' 秒，每次 ' + d.n0 + ' 枚，单枚伤害 ' + Math.round(d.dmg * (1 + 0.15 * (L - 1))) + '（每级 +15%）');
      lines.push('Lv3：数量 / 范围提升；Lv5：冷却 -20%');
      lines.push('库存 ' + stock + ' / ' + C.SUB_STOCK_MAX + '，出击携带 ' + Math.min(stock, C.subCap(mid)) + ' 发；用掉的从库存扣除，没用完的退回');
      lines.push('战斗中点“副武器”按钮发射（电脑 Q 键）；设置里可开自动发射');
    } else {
      var nd = C.nitroDef(id); name = nd.n;
      lines.push(nd.d); lines.push('距离 ' + Math.round(nd.dist * (1 + 0.05 * (L - 1))) + ' 米，冷却 ' + (nd.cd * (1 - 0.06 * (L - 1))).toFixed(1) + ' 秒，无敌 ' + nd.inv + ' 秒');
      lines.push('每级：冷却 -6%，距离 +5%');
    }
    var det = '<div class="mk-ch"><span class="ic' + (own ? '' : ' gray') + '">' + A.iconSVG(C.armIcon(k, id), 64) + '</span><div><b class="wk-nm">' + name + '</b><small>' + (k === 'weapons' ? '主武器' : k === 'subs' ? '副武器' : '氮气推进') + '　' + (own ? pips(lv) + ' Lv ' + lv : '未研发') + '</small></div></div><ul>' + lines.map(function (t) { return '<li>' + t + '</li>'; }).join('') + '</ul><div class="mk-pbtns">';
    if (!own) { var c = C.armCost(k, id); det += '<button class="btn primary wa-unlock">研发<small>' + A.resIcon('credit', 22) + ' ' + fmt(c.cr) + (c.src ? '，星源 ' + c.src : '') + '</small></button>'; }
    else {
      det += isEq ? (k === 'subs' ? '<button class="btn wa-uneq">卸下副武器</button>' : '<button class="btn" disabled>已装备</button>') : '<button class="btn primary wa-eq">装备到' + m.name + '</button>';
      if (lv < C.ARM_LV_MAX) det += '<button class="btn wa-up">升到 Lv ' + (lv + 1) + '<small>' + A.resIcon('credit', 22) + ' ' + fmt(C.armUpCost(k, lv)) + '</small></button>';
      det += '<button class="btn cx-adbtn wa-ad"' + (lv >= C.ARM_LV_MAX || C.adUpLeft() <= 0 ? ' disabled' : '') + '>看广告 升级<small>' + (lv >= C.ARM_LV_MAX ? '已满级' : '今日还可 ' + C.adUpLeft() + ' 次') + '</small></button>';
      if (k === 'subs') { var dd = C.subDef(id); det += '<button class="btn primary wa-craft" data-n="1">合成 +5 发<small>' + A.resIcon('credit', 22) + ' ' + fmt(dd.craft) + '</small></button><button class="btn wa-craft" data-n="5">合成 +25 发<small>' + A.resIcon('credit', 22) + ' ' + fmt(dd.craft * 5) + '</small></button>'; }
    }
    right.innerHTML = '<div class="mk-card mk-idet wa-det">' + det + '</div><p class="mk-odds">主武器决定弹道，副武器是消耗弹药的飞弹，氮气推进决定闪避方式。每台机甲单独配装；升级与弹药全机甲共用。</p></div>';
    box.appendChild(left); box.appendChild(right);
    box.querySelectorAll('[data-k]').forEach(function (b) { b.onclick = function () { if (!b.dataset.id) { ws.kind = b.dataset.k; ws.id = C.SUBS[0].id; } else { ws.kind = b.dataset.k; ws.id = b.dataset.id; } C.sfx('click'); render(); }; });
    function cycle(dir) { var l = ownedMechs(), i = l.indexOf(mid); wmech = l[(i + dir + l.length) % l.length]; ws.id = null; C.sfx('click'); render(); }
    box.querySelector('.wa-prev').onclick = function () { cycle(-1); }; box.querySelector('.wa-next').onclick = function () { cycle(1); };
    function done(r, msg) { if (r.err) { A.toast(r.err); return; } C.sfx('level'); if (msg) A.toast(msg); render(); }
    var b1 = box.querySelector('.wa-unlock'); if (b1) b1.onclick = function () { done(C.armUnlock(k, id), '研发完成：' + name); };
    var b2 = box.querySelector('.wa-eq'); if (b2) b2.onclick = function () { done(C.equipArm(mid, slotKey, id), m.name + ' 装备了 ' + name); };
    var b3 = box.querySelector('.wa-uneq'); if (b3) b3.onclick = function () { done(C.equipArm(mid, 'sub', null), '已卸下副武器'); };
    var b4 = box.querySelector('.wa-up'); if (b4) b4.onclick = function () { done(C.armUpgrade(k, id), name + ' 升到 Lv ' + (lv + 1)); };
    var b5 = box.querySelector('.wa-ad'); if (b5) b5.onclick = function () { C.showAd('升级' + name, function (r) { if (!r.success) { A.toast('需要完整看完广告才能升级'); return; } done(C.armAdUp(k, id), name + ' 升到 Lv ' + (lv + 1)); }); };
    box.querySelectorAll('.wa-craft').forEach(function (b) { b.onclick = function () { var r = C.craftAmmo(id, +b.dataset.n); done(r, r.ok ? name + ' 弹药 +' + r.n : null); }; });
    return box;
  }
  function workBody() { return wsub === 'mods' ? modsView() : wsub === 'arms' ? armsView() : chipsView(); }
  function doDraw(n, free) {
    var r = C.drawModules(n, free); if (r.err) { A.toast(r.err); return; }
    var best = r.list.reduce(function (a, x) { return !a || x.mod.tier > a.mod.tier ? x : a; }, null), it = best.mod;
    C.sfx(it.tier >= 2 ? 'win' : 'level'); wk.form = it.form; wk.elem = it.elem; wk.tier = it.tier; wk.v = it.v || 0; fresh = it.form + ':' + it.elem;
    render(); revealMany(r.list, n, free);
  }
  function revealMany(list, n, wasFree) {
    var m = el('div', 'sv-modal mk-reveal'), top = list.reduce(function (a, x) { return Math.max(a, x.mod.tier); }, 0), nNew = list.filter(function (x) { return x.isNew; }).length;
    var cells = list.map(function (r) { var it = r.mod; return '<div class="mk-rc r' + it.tier + '"><span class="ic">' + A.iconSVG(C.modIcon(it), n > 1 ? 70 : 130) + '</span><b>' + it.name + '</b><small style="color:' + C.RARITY[it.tier].color + '">' + C.RARITY[it.tier].n + '</small><em>' + (r.isNew ? '新卡牌！' : r.refund ? '满级 +' + r.refund + ' 信用点' : 'Lv ' + (it.lvl || 1)) + '</em></div>'; }).join('');
    m.innerHTML = '<div class="mk-rv r' + top + '"><h1>' + (wasFree ? '翻倍奖励 · ' : '') + '抽取 ' + n + ' 次</h1><p class="wk-dup">新卡牌 ' + nNew + ' 张，已加入卡组；其余卡牌升级</p><div class="mk-rgrid' + (n > 1 ? ' ten' : '') + '">' + cells + '</div>' +
      '<div class="mk-pbtns">' + (wasFree ? '' : '<button class="btn cx-adbtn mk-dbl">看广告 翻倍<small>免费再抽 ' + n + ' 次</small></button>') + '<button class="btn primary mk-ok">收下</button></div></div>';
    ui().appendChild(m);
    m.querySelector('.mk-ok').onclick = function () { m.remove(); };
    var d = m.querySelector('.mk-dbl');
    if (d) d.onclick = function () {
      C.showAd('抽卡翻倍', function (r) { if (!r.success) { A.toast('需要完整看完广告才能翻倍'); return; } m.remove(); doDraw(n, true); });
    };
  }
  function reveal(it, isMod, r) {
    var m = el('div', 'sv-modal mk-reveal'), dup = r && r.dup;
    m.innerHTML = '<div class="mk-rv r' + it.tier + '"><span class="tag" style="background:' + C.RARITY[it.tier].color + ';color:#10142B">' + C.RARITY[it.tier].n + '</span><span class="ic">' + itemIcon(it, isMod, 150) + '</span>' +
      '<h1>' + it.name + '</h1>' + (dup ? '<p class="wk-dup">已拥有：卡牌升到 Lv ' + (it.lvl || 1) + (r.refund ? '（已满级，折算信用点 +' + r.refund + '）' : '') + '</p>' : isMod ? '<p class="wk-dup">新卡牌解锁！</p>' : '') + '<ul>' + itemLines(it, isMod) + '</ul><button class="btn primary">收下</button></div>';
    ui().appendChild(m);
    m.querySelector('button').onclick = function () { m.remove(); };
  }

  // ------------------------------------------------------------------ 每日
  function dailyBody() {
    var box = el('div', 'wk-daily'), sv = s(), idle = C.idleAmount(), pct = Math.min(1, idle.hours / C.IDLE_CAP_H), L = el('div', 'wk-dcol'), Rr = el('div', 'wk-dcol');
    var tasks = C.TASKS.map(function (t) {
      var v = Math.min(t.need, sv.daily[t.key] || 0), done = v >= t.need, got = sv.daily.claimed[t.id];
      return '<div class="mk-row"><div><b>' + t.name + '</b><div class="mk-prog"><i style="width:' + (v / t.need * 100) + '%"></i><span>' + v + ' / ' + t.need + '</span></div></div>' +
        '<span class="mk-rew">' + A.resIcon('shard', 26) + ' +' + t.reward + '</span>' + (got ? '<span class="tag">已领取</span>' : '<button class="mini" data-t="' + t.id + '"' + (done ? '' : ' disabled') + '>领取</button>') + '</div>';
    }).join('');
    var adLeft = Math.max(0, C.AD.srcDaily - sv.daily.ads);
    var ls = C.loginState(), lg = '<p class="mk-label">7 日登录奖励</p><div class="wk-login">' + C.LOGIN_REWARDS.map(function (r, i) {
      var done = ls.claimed ? i <= ls.idx : i < ls.idx, cur = !ls.claimed && i === ls.idx, tx = (r.cr ? r.cr + ' 信用点' : r.src + ' 星源') + (r.draw ? '<br>+ 免费抽卡' : '');
      return '<div class="wk-day' + (done ? ' done' : '') + (cur ? ' cur' : '') + '"><b>第 ' + (i + 1) + ' 天</b><small>' + tx + '</small></div>';
    }).join('') + '</div><div class="mk-row"><div><b>' + (ls.claimed ? '今日已领取' : '今日奖励可领取') + '</b><small>连续登录奖励更高，断签从第 1 天重新开始</small></div>' + (ls.claimed ? '<span class="tag">已领取</span>' : '<button class="mini mk-login">领取</button>') + '</div>';
    var ach = C.ACH.map(function (a) { var ok = a.ok(sv), got = sv.ach[a.id]; return '<div class="mk-row"><div><b>' + a.name + '</b><small>' + a.desc + '</small></div><span class="mk-rew">' + A.resIcon('shard', 26) + ' +' + a.src + '</span>' + (got ? '<span class="tag">已领取</span>' : '<button class="mini" data-a="' + a.id + '"' + (ok ? '' : ' disabled') + '>领取</button>') + '</div>'; }).join('');
    var dc = C.dailyChallenge(), dcm = dc.mods.map(function (id) { var m = C.dcMod(id); return '<li><b>' + m.n + '</b>：' + m.d + '</li>'; }).join('');
    var dcHtml = '<p class="mk-label">每日挑战</p><div class="mk-card wk-dc"><b>第 ' + dc.chapter + ' 章 · 限时 4 分钟</b><ul>' + dcm + '</ul><small>今日最高分 ' + dc.state.best + '　历史最高 ' + (sv.dcBest || 0) + '　' + (dc.state.done ? '今日奖励已领取（可继续刷分）' : '首次完成：信用点 +800，星源 +10') + '</small><button class="btn primary mk-dcgo">开始挑战</button></div>';
    L.innerHTML = lg + dcHtml + '<p class="mk-label">巡航收益</p><div class="mk-card mk-idle"><div><small>离线也会积累，最多 ' + C.IDLE_CAP_H + ' 小时</small><b>' + A.resIcon('credit', 34) + ' ' + fmt(idle.credits) + '</b><div class="mk-prog"><i style="width:' + pct * 100 + '%"></i><span>' + idle.hours.toFixed(1) + ' / ' + C.IDLE_CAP_H + ' 小时，每小时 ' + C.idleRate() + '</span></div></div>' +
      '<div class="mk-idleb"><button class="btn mk-idle1"' + (idle.credits > 0 ? '' : ' disabled') + '>领取</button><button class="btn cx-adbtn mk-idle2"' + (idle.credits > 0 ? '' : ' disabled') + '>看广告 双倍</button></div></div>' +
      '<p class="mk-label">每日补给</p><div class="mk-row mk-supply"><div><b>每日补给</b><small>每天登录都能领</small></div><span class="mk-rew">' + A.resIcon('shard', 26) + ' +' + C.DAILY_SUPPLY + '</span>' + (sv.daily.supply ? '<span class="tag">已领取</span>' : '<button class="mini mk-sup">领取</button>') + '</div>' +
      '<div class="mk-row"><div><b>看广告领星源</b><small>今日还可领取 ' + adLeft + ' 次</small></div><span class="mk-rew">' + A.resIcon('shard', 26) + ' +' + C.AD.srcReward + '</span><button class="mini cx-adbtn mk-adsrc"' + (adLeft > 0 ? '' : ' disabled') + '>看广告</button></div>' +
      '<div class="mk-row"><div><b>广告升级</b><small>今日还可看广告升级技能卡牌 / 天赋芯片 ' + C.adUpLeft() + ' 次</small></div><button class="mini alt mk-gowork">去工坊</button></div>';
    Rr.innerHTML = '<p class="mk-label">每日任务</p>' + tasks + '<p class="mk-label">成就（' + Object.keys(sv.ach).length + ' / ' + C.ACH.length + '）</p>' + ach;
    box.appendChild(L); box.appendChild(Rr);
    function claimIdle(mult) { var a = C.idleAmount(); sv.credits += a.credits * mult; sv.idleT = Date.now(); C.write(); C.sfx('pick'); A.toast('巡航收益：信用点 +' + fmt(a.credits * mult)); render(); }
    box.querySelector('.mk-idle1').onclick = function () { claimIdle(1); };
    box.querySelector('.mk-idle2').onclick = function () { C.showAd('巡航收益双倍', function (r) { if (!r.success) { A.toast('需要完整看完广告才能领取'); return; } claimIdle(2); }); };
    var sp = box.querySelector('.mk-sup'); if (sp) sp.onclick = function () { sv.daily.supply = 1; sv.src += C.DAILY_SUPPLY; C.write(); C.sfx('pick'); A.toast('每日补给：星源 +' + C.DAILY_SUPPLY); render(); };
    var as = box.querySelector('.mk-adsrc'); if (as) as.onclick = function () { C.showAd('领取星源', function (r) { if (!r.success) { A.toast('需要完整看完广告才能领取'); return; } sv.daily.ads++; sv.src += C.AD.srcReward; C.write(); C.sfx('pick'); A.toast('星源 +' + C.AD.srcReward); render(); }); };
    box.querySelector('.mk-dcgo').onclick = function () { C.sfx('gate'); window.CosmicRun.start(dc.chapter, { daily: true, mods: dc.mods, danger: dc.danger }); };
    var lb = box.querySelector('.mk-login'); if (lb) lb.onclick = function () { var t = C.loginClaim(); if (t) { C.sfx('win'); A.toast('登录奖励：' + t); render(); } };
    box.querySelectorAll('button[data-a]').forEach(function (b) { b.onclick = function () { if (C.achClaim(b.dataset.a)) { C.sfx('pick'); A.toast('成就奖励已领取'); render(); } }; });
    box.querySelector('.mk-gowork').onclick = function () { tab = 'work'; wsub = 'mods'; render(); };
    box.querySelectorAll('button[data-t]').forEach(function (b) {
      b.onclick = function () { var t = C.TASKS.filter(function (x) { return x.id === b.dataset.t; })[0]; sv.daily.claimed[t.id] = 1; sv.src += t.reward; C.write(); C.sfx('pick'); A.toast('任务奖励：星源 +' + t.reward); render(); };
    });
    return box;
  }

  // ------------------------------------------------------------------ 弹窗：获取星源、设置
  function modal(html) { var m = el('div', 'sv-modal'); m.innerHTML = html; ui().appendChild(m); return m; }
  function openGetSrc() {
    var sv = s(), left = C.AD.srcDaily - sv.daily.ads;
    var m = modal('<div class="panel sv-pbox mk-get"><h1>获取星源</h1>' +
      '<div class="mk-row"><div><b>观看广告</b><small>今日还可领取 ' + Math.max(0, left) + ' 次</small></div><span class="mk-rew">+' + C.AD.srcReward + '</span><button class="btn cx-adbtn mk-ad"' + (left > 0 ? '' : ' disabled') + '>看广告</button></div>' +
      '<div class="mk-row"><div><b>每日补给与每日任务</b><small>在“每日”页领取，合计每天 ' + (C.DAILY_SUPPLY + C.TASKS.reduce(function (a, t) { return a + t.reward; }, 0)) + '</small></div><button class="btn mk-goday">前往</button></div>' +
      '<div class="mk-row"><div><b>章节首通、营救逃生舱、击败首领</b><small>出击时获得</small></div></div>' +
      '<button class="btn primary mk-close">关闭</button></div>');
    m.querySelector('.mk-close').onclick = function () { m.remove(); };
    m.querySelector('.mk-goday').onclick = function () { m.remove(); tab = 'daily'; render(); };
    var ad = m.querySelector('.mk-ad');
    if (ad) ad.onclick = function () {
      C.showAd('领取星源', function (r) {
        if (!r.success) { A.toast('需要完整看完广告才能领取'); return; }
        sv.daily.ads++; sv.src += C.AD.srcReward; C.write(); C.sfx('pick'); A.toast('星源 +' + C.AD.srcReward); m.remove(); render();
      });
    };
  }
  // 关于与合规：原创声明、概率公示、隐私与适龄提示（上架应用商店需要）
  function openAbout() {
    var S_ = C.SUMMON, pct = function (v) { return (v * 100).toFixed(v * 100 % 1 ? 1 : 0) + '%'; };
    var m = modal('<div class="panel sv-pbox mk-get mk-about"><h1>关于与合规</h1>' +
      '<p class="mk-label">版本</p><p>宇宙银河机甲（测试版）　存档仅保存在本机。</p>' +
      '<p class="mk-label">原创声明</p><p>游戏内全部机甲、角色、敌人、场景模型均为原创体素建模；音效与背景音乐为程序合成的原创音频（.ogg）；界面字体为 Noto Sans SC 与站酷庆科黄油体（均为 SIL OFL 开源字体）。与任何现有动漫、游戏、影视作品及其角色、机体、商标无关联。</p>' +
      '<p class="mk-label">抽取概率公示</p>' +
      '<p>召唤（机甲 / 驾驶员）：SSSR ' + pct(S_.rates.SSSR) + '，SSR ' + pct(S_.rates.SSR) + '，SS ' + pct(S_.rates.SS) + '，S ' + pct(S_.rates.S) + '；连续 ' + S_.pitySSR + ' 次未出 SSR 时，下一次必出 SSR 以上；连续 ' + S_.pitySSSR + ' 次未出 SSSR 时，下一次必出 SSSR（保底）。</p>' +
      '<p>工坊（技能卡牌 / 天赋芯片）：白色 60%，蓝色 28%，紫色 10%，金色 2%；每 10 次至少蓝色（10 连必出蓝色以上），每 40 次必出金色；看广告可翻倍免费再抽同样次数；技能卡牌共 ' + C.MOD_TOTAL() + ' 张。重复获得会提升卡牌等级。所有抽取只消耗游戏内货币（信用点 / 星源），本版本无真实货币付费。</p>' +
      '<p class="mk-label">广告</p><p>“看广告”为可选行为，用于领取少量奖励或升级，不看不影响通关。</p>' +
      '<p class="mk-label">隐私</p><p>本游戏不要求登录，不收集个人信息；存档保存在设备本地浏览器存储中，清除浏览器数据会丢失存档。</p>' +
      '<p class="mk-label">适龄提示</p><p>含卡通风格的科幻战斗（无血腥），建议 12 岁及以上；请合理安排游戏时间。</p>' +
      '<button class="btn primary mk-close">关闭</button></div>');
    m.querySelector('.mk-close').onclick = function () { m.remove(); };
  }
  function openSettings() {
    var sv = s();
    function fxb(v, t) { return '<button class="mini' + ((sv.settings.fx || 'normal') === v ? '' : ' alt') + '" data-fx="' + v + '">' + t + '</button>'; }
    function cm(v, t) { return '<button class="mini' + ((sv.settings.cam || 'chase') === v ? '' : ' alt') + '" data-c="' + v + '">' + t + '</button>'; }
    function q(v, t) { return '<button class="mini' + (sv.settings.quality === v ? '' : ' alt') + '" data-q="' + v + '">' + t + '</button>'; }
    function lvb(v, t) { return '<button class="mini' + ((sv.settings.lvMode || 'later') === v ? '' : ' alt') + '" data-lv="' + v + '">' + t + '</button>'; }
    var m = modal('<div class="panel sv-pbox mk-get"><h1>设置</h1>' +
      '<div class="mk-row"><div><b>升级选卡</b><small>稍后：战斗不中断，点 HUD 上的“升级”按钮再选；自动：按推荐优先级自动选</small></div>' + lvb('now', '立即弹出') + lvb('later', '稍后选择') + lvb('auto', '自动选择') + '</div>' +
      '<div class="mk-row"><div><b>副武器自动发射</b><small>开：敌群密集或出现精英 / 首领时自动发射飞弹；关：只在点按钮时发射</small></div><button class="mini mk-subauto' + (sv.settings.subAuto !== false ? '' : ' alt') + '">' + (sv.settings.subAuto !== false ? '开' : '关') + '</button></div>' +
      '<div class="mk-row"><div><b>背景音乐</b><small>主界面、战斗、首领战各一首</small></div><button class="mini mk-mus' + (sv.settings.music ? '' : ' alt') + '">' + (sv.settings.music ? '开' : '关') + '</button></div>' +
      '<div class="mk-row"><div><b>音效</b><small>射击、爆炸、拾取、升级</small></div><button class="mini mk-snd' + (sv.settings.sound ? '' : ' alt') + '">' + (sv.settings.sound ? '开' : '关') + '</button></div>' +
      '<div class="mk-row"><div><b>战斗视角</b><small>远景看得更广，近景更有代入感</small></div>' + cm('high', '远景') + cm('chase', '标准') + cm('mid', '近景') + '</div>' +
      '<div class="mk-row"><div><b>特效强度</b><small>柔和：特效更小更少、关闭镜头震动，适合容易眼花的玩家</small></div>' + fxb('normal', '标准') + fxb('soft', '柔和') + '</div>' +
      '<div class="mk-row"><div><b>画质</b><small>自动：帧率偏低时切到流畅</small></div>' + q('auto', '自动') + q('high', '高清') + q('low', '流畅') + '</div>' +
      '<div class="mk-row"><div><b>省电模式</b><small>限制 30 帧、降低画质与粒子，适合低端手机或想省电</small></div><button class="mini mk-saver' + (sv.settings.saver ? '' : ' alt') + '">' + (sv.settings.saver ? '开' : '关') + '</button></div>' +
      '<div class="mk-row"><div><b>存档备份</b><small>导出存档代码，换设备或清缓存前备份；也可导入</small></div><button class="mini alt mk-exp">导出</button><button class="mini alt mk-imp">导入</button></div>' +
      '<div class="mk-row"><div><b>关于与合规</b><small>原创声明、抽卡概率公示、隐私与适龄提示</small></div><button class="mini alt mk-about">查看</button></div>' +
      '<div class="mk-row"><div><b>新手引导</b><small>下一次出击重新播放</small></div><button class="mini alt mk-tut">重新播放</button></div>' +
      '<div class="mk-row"><div><b>兑换码</b><small>输入作者发放的兑换码，兑换信用点或星源</small></div><button class="mini alt mk-redeem">兑换</button></div>' +
      '<div class="mk-row mk-ver" style="cursor:pointer"><div><small>版本 v' + (window.CosmicDev ? window.CosmicDev.version : '') + '</small></div></div>' +
      '<button class="btn primary mk-close">完成</button></div>');
    m.querySelector('.mk-mus').onclick = function () { sv.settings.music = !sv.settings.music; C.write(); C.music.refresh(); m.remove(); openSettings(); };
    m.querySelector('.mk-snd').onclick = function () { sv.settings.sound = !sv.settings.sound; C.write(); m.remove(); openSettings(); };
    m.querySelector('.mk-subauto').onclick = function () { sv.settings.subAuto = sv.settings.subAuto === false; C.write(); m.remove(); openSettings(); };
    m.querySelectorAll('[data-lv]').forEach(function (b) { b.onclick = function () { sv.settings.lvMode = b.dataset.lv; C.write(); m.remove(); openSettings(); }; });
    m.querySelectorAll('[data-fx]').forEach(function (b) { b.onclick = function () { sv.settings.fx = b.dataset.fx; C.write(); m.remove(); openSettings(); }; });
    m.querySelectorAll('[data-c]').forEach(function (b) { b.onclick = function () { sv.settings.cam = b.dataset.c; C.write(); m.remove(); openSettings(); }; });
    m.querySelectorAll('[data-q]').forEach(function (b) { b.onclick = function () { sv.settings.quality = b.dataset.q; C.write(); A.applyQuality(); m.remove(); openSettings(); }; });
    m.querySelector('.mk-exp').onclick = function () {
      var code = C.exportSave(), em = modal('<div class="panel sv-pbox mk-get"><h1>导出存档</h1><p class="note">复制下面的代码保存好；在“导入”里粘贴即可恢复。</p><textarea class="wk-ta" readonly>' + code + '</textarea><div class="sv-btns"><button class="btn mk-cp">复制</button><button class="btn primary mk-x">关闭</button></div></div>');
      em.querySelector('.mk-cp').onclick = function () { var ta = em.querySelector('textarea'); ta.select(); try { document.execCommand('copy'); A.toast('已复制'); } catch (e) { A.toast('请长按选择复制'); } };
      em.querySelector('.mk-x').onclick = function () { em.remove(); };
    };
    m.querySelector('.mk-imp').onclick = function () {
      var im = modal('<div class="panel sv-pbox mk-get"><h1>导入存档</h1><p class="note">粘贴导出的存档代码。导入会覆盖当前存档，请先确认。</p><textarea class="wk-ta"></textarea><div class="sv-btns"><button class="btn mk-ok">导入</button><button class="btn primary mk-x">取消</button></div></div>');
      im.querySelector('.mk-x').onclick = function () { im.remove(); };
      im.querySelector('.mk-ok').onclick = function () { if (C.importSave(im.querySelector('textarea').value)) { A.toast('导入成功'); im.remove(); m.remove(); chapterSel = Math.min(C.save.chapter, C.CHAPTERS.length); render(); } else A.toast('存档代码无效'); };
    };
    m.querySelector('.mk-about').onclick = function () { C.sfx('click'); openAbout(); };
    m.querySelector('.mk-saver').onclick = function () { sv.settings.saver = !sv.settings.saver; C.write(); A.applyQuality(); m.remove(); openSettings(); };
    m.querySelector('.mk-redeem').onclick = function () { m.remove(); window.CosmicDev.openRedeem(); };
    m.querySelector('.mk-ver').onclick = function () { window.CosmicDev.verTap(m); };
    m.querySelector('.mk-tut').onclick = function () { sv.tutorialDone = false; C.write(); A.toast('下一次出击会重新播放新手引导'); };
    m.querySelector('.mk-close').onclick = function () { m.remove(); render(); };
  }

  window.CosmicHub = {
    refresh: function () { render(); },
    init: function (api) {
      A = api; C.load(); chapterSel = Math.min(C.save.chapter, C.CHAPTERS.length);
      // 展示台拖动旋转（机库、驾驶员页）
      var cv = E.canvas;
      cv.addEventListener('pointerdown', function (e) { if (A.mode() !== 'cosmic-hub' || (tab !== 'hangar' && tab !== 'pilots')) return; VIEW.dragX = e.clientX; cv.setPointerCapture(e.pointerId); });
      cv.addEventListener('pointermove', function (e) { if (VIEW.dragX === null) return; VIEW.yaw += (e.clientX - VIEW.dragX) * 0.6; VIEW.dragX = e.clientX; VIEW.last = (performance.now() - t0) / 1000; });
      function up() { VIEW.dragX = null; VIEW.last = (performance.now() - t0) / 1000; }
      cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', up);
    },
    open: function () { if (SA) finishSummon(); A.setMode('cosmic-hub'); tab = 'home'; mechSel = null; pilotSel = null; chapterSel = Math.min(C.save.chapter, C.CHAPTERS.length); render(); C.music.play('hub'); },
    frame: frame, render: function () { render(); }, debug: { sa: function () { return SA; }, set: function (t) { tab = t; render(); } }
  };
})();

