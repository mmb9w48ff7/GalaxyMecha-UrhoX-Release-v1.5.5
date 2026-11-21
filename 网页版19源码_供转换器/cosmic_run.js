/* 宇宙银河机甲 · 星域远征（局内，太空第三人称 3D）
 * 机甲在球形太空战场中自由飞行：左半屏摇杆移动（朝镜头方向飞），右半屏拖动转视角，自动瞄准。
 * 每章 6 个星域：完成目标打开星门，第 3 星域精英、第 4 星域商人、第 6 星域首领。
 * 机甲决定武器与机甲技能，驾驶员提供支援技能与被动；技能模块与天赋芯片来自工坊。
 */
(function () {
  'use strict';
  var E = window.VoxEngine, C = window.Cosmic;
  if (!E || !C) return;
  var A, DEG = Math.PI / 180, BOUND = 150, SECTORS = 6;
  var PLAN = ['normal', 'normal', 'elite', 'rest', 'normal', 'boss'];
  var EVENTS = ['pirate', 'derelict', 'ore', 'distress', 'hunt', 'ambush'];
  var AFFIX = [{ id: 'swift', name: '高速敌群', desc: '敌人移速 +25%' }, { id: 'fury', name: '狂暴信号', desc: '敌人伤害 +25%，能量 +30%' }, { id: 'tide', name: '能量潮汐', desc: '敌人更多，能量 +50%' }];
  function rand(a, b) { return a + Math.random() * (b - a); }
  function clamp(x, a, b) { return x < a ? a : x > b ? b : x; }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function pick(l) { return l[Math.floor(Math.random() * l.length)]; }
  function mmss(t) { t = Math.max(0, Math.floor(t)); return (t < 600 ? '0' : '') + Math.floor(t / 60) + ':' + (t % 60 < 10 ? '0' : '') + (t % 60); }
  // —— 三维工具（物体统一用 x, y, z 字段）——
  function d3(ax, ay, az, bx, by, bz) { var dx = ax - bx, dy = ay - by, dz = az - bz; return dx * dx + dy * dy + dz * dz; }
  function dd(a, b) { return d3(a.x, a.y, a.z, b.x, b.y, b.z); }
  function len3(x, y, z) { return Math.sqrt(x * x + y * y + z * z); }
  function nrm(v) { var l = len3(v[0], v[1], v[2]) || 1; return [v[0] / l, v[1] / l, v[2] / l]; }
  function fwdOf(yaw, pitch) { var cp = Math.cos(pitch * DEG); return [Math.sin(yaw * DEG) * cp, -Math.sin(pitch * DEG), Math.cos(yaw * DEG) * cp]; }
  function rightOf(yaw) { return [Math.cos(yaw * DEG), 0, -Math.sin(yaw * DEG)]; }
  function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
  function angOf(v) { var l = len3(v[0], v[1], v[2]) || 1; return [Math.atan2(v[0], v[2]) / DEG, -Math.asin(clamp(v[1] / l, -1, 1)) / DEG]; }
  function randDir() { var u = rand(-1, 1), a = rand(0, Math.PI * 2), r = Math.sqrt(1 - u * u); return [Math.cos(a) * r, u, Math.sin(a) * r]; }
  // 与 v 垂直的两个单位向量（用于环形弹幕、散射）
  function basis(v) { var up = Math.abs(v[1]) > 0.9 ? [1, 0, 0] : [0, 1, 0], a = nrm(cross(up, v)), b = cross(v, a); return [a, b]; }

  // ------------------------------------------------------------------ 机甲分件动作：躯干 / 头 / 双臂 / 大腿 / 小腿
  // 模型在构建时已按部件拆开（tools/voxlib.py build_parts），所有部件与整机共用同一原点，
  // 运行时只需绕关节（rig）旋转。rig 同时给出枪口、尾喷口、肩舱、吊臂等挂点（米，模型局部坐标）。
  // 角度约定（与 E.trs 一致）：pitch 为正 = +Z 轴向下（机头低、小腿向后摆、手臂向后摆）；yaw 为正 = 转向 +X（机甲左侧）。
  var PARTS = ['body', 'head', 'uarmL', 'uarmR', 'armL', 'armR', 'thighL', 'thighR', 'shinL', 'shinR'];
  // aim：手臂角色。gun = 枪管沿手臂前方；staff / spear = 武器沿手臂上方（抬臂后才指向前方）；axe = 近战斧；guard = 盾；free = 空手
  // fire：主武器发射位置（L / R = 手臂枪口，P = 肩部导弹舱）
  var MECHFX = {
    mech_azure: { fire: ['R'], aim: { R: 'gun', L: 'guard' }, glow: '#9DF7EC', kick: 0.5 },
    mech_blaze: { fire: ['L'], aim: { L: 'gun', R: 'axe' }, glow: '#FF8A3A', kick: 1.0 },
    mech_halo: { fire: ['R'], aim: { R: 'staff', L: 'free' }, glow: '#C9B8FF', kick: 0.3 },
    mech_forge: { fire: ['R', 'L'], aim: { L: 'gun', R: 'gun' }, glow: '#FFB347', kick: 0.5 },
    mech_frost: { fire: ['P'], aim: { R: 'gun', L: 'free' }, glow: '#9DD8FF', kick: 0.8 },
    mech_starfall: { fire: ['R'], aim: { R: 'spear', L: 'free' }, glow: '#E0A0FF', kick: 0.5 }
  };
  function wrapA(a) { return (((a % 360) + 540) % 360) - 180; }
  function ease(c, g, k, dt) { return c + (g - c) * (1 - Math.exp(-k * dt)); }
  function mT(x, y, z) { var m = E.m4(); m[12] = x; m[13] = y; m[14] = z; return m; }
  function rot(y, p, r) { return E.trs([0, 0, 0], y, p, r, 1); }
  // M * T(p) * Rm * T(tr) * T(-p)：绕关节 p 旋转，tr 为旋转后沿部件局部轴的位移（后坐 / 刺击）
  function pivot(M, p, Rm, tr) {
    var m = E.m4mul(M, mT(p[0], p[1], p[2])); m = E.m4mul(m, Rm);
    if (tr) m = E.m4mul(m, mT(tr[0], tr[1], tr[2]));
    return E.m4mul(m, mT(-p[0], -p[1], -p[2]));
  }
  function xf(M, p) { return [M[0] * p[0] + M[4] * p[1] + M[8] * p[2] + M[12], M[1] * p[0] + M[5] * p[1] + M[9] * p[2] + M[13], M[2] * p[0] + M[6] * p[1] + M[10] * p[2] + M[14]]; }
  function xd(M, d) { return nrm([M[0] * d[0] + M[4] * d[1] + M[8] * d[2], M[1] * d[0] + M[5] * d[1] + M[9] * d[2], M[2] * d[0] + M[6] * d[1] + M[10] * d[2]]); }
  function newPose() {
    var md = window.VOX_MODELS && window.VOX_MODELS[R.mech], fxm = MECHFX[R.mech] || MECHFX.mech_azure;
    return { ok: !!(md && md.rig && md.parts && md.rig.waist), rig: md && md.rig, fxm: fxm, col: lin(fxm.glow),
      vf: 0, af: 0, lean: 0, bank: 0, spin: 0, thrR: 0.25, thrV: 0.2, twist: 0, tP: 0, hY: 0, hP: 0, aimK: 0, aimT: 0, tg: null,
      hit: 0, hitFlash: 0, recB: 0, rec: { L: 0, R: 0 }, cast: null, alt: 0, podAlt: 0,
      arm: { L: { p: 0, e: 0, y: 0, r: 0 }, R: { p: 0, e: 0, y: 0, r: 0 } }, th: { L: { p: 0, r: 0 }, R: { p: 0, r: 0 } }, kn: { L: 0, R: 0 }, W: null, mats: null };
  }
  function setCast(kind, dur) { if (R.pose.ok) R.pose.cast = { kind: kind, t: 0, dur: dur }; }
  function later(sec, fn) { R.sched.push({ t: sec, fn: fn }); }
  function runSched(dt) { for (var i = R.sched.length - 1; i >= 0; i--) { var s = R.sched[i]; s.t -= dt; if (s.t <= 0) { R.sched.splice(i, 1); s.fn(); } } }
  // 枪口 / 挂点世界坐标（取上一帧的姿态；没有分件数据时退回机甲中心）
  function mz(side, i) { var po = R.pose, l = po && po.W && po.W.muz[side]; if (!l || !l.length) return P(); var p = l[(i || 0) % l.length]; return { x: p[0], y: p[1], z: p[2] }; }
  function mainMz(i) { var po = R.pose; return mz(po && po.ok ? po.fxm.fire[0] : 'R', i); }
  function backPt() { var po = R.pose, b = po && po.W && po.W.back; return b ? { x: b[0], y: b[1], z: b[2] } : P(); }
  function shoulderPt(i) { var po = R.pose, s = po && po.W && po.W.shoulder; return s ? { x: s[i % 2][0], y: s[i % 2][1], z: s[i % 2][2] } : { x: R.px, y: R.py + 2, z: R.pz }; }
  function kick(side, amt, body) { var po = R.pose; if (!po || !po.ok) return; if (side) po.rec[side] = Math.max(po.rec[side], amt); po.recB = Math.min(2, po.recB + (body || 0)); }
  // 枪口火光：一团短促的亮光 + 沿枪口方向飞出的火星
  function muzzleFx(o, dir, sz) {
    var po = R.pose; if (!po || !po.ok || R.parts.length > 230) return;
    R.parts.push({ model: 'fx_white', x: o.x + dir[0] * 0.35, y: o.y + dir[1] * 0.35, z: o.z + dir[2] * 0.35, vx: dir[0] * 3, vy: dir[1] * 3, vz: dir[2] * 3, life: 0.09, max: 0.09, size: 2.4 * sz, tint: po.col, noGrav: true });
    for (var k = 0; k < 2; k++) R.parts.push({ model: 'fx_white', x: o.x, y: o.y, z: o.z, vx: dir[0] * 18 + rand(-3, 3), vy: dir[1] * 18 + rand(-3, 3), vz: dir[2] * 18 + rand(-3, 3), life: 0.26, max: 0.26, size: 1.1 * sz, tint: po.col, hot: true, noGrav: true });
  }
  // 下落类导弹（星陨雨、爆破雨）先从肩舱垂直发射，再从目标上空落下，而不是凭空出现
  function podLaunch(m, j, gap) {
    var po = R.pose, W = po && po.ok && po.W, pods = W && (W.muz.P || W.shoulder);
    if (!pods) return m;
    var pd = pods[j % pods.length], sd = j % 2 ? -1 : 1;
    m.launch = { x: pd[0], y: pd[1], z: pd[2], delay: 0.1 + Math.min(0.8, j * (gap || 0.04)), dir: nrm([sd * 0.35, 1, 0.25]), t: 0 };
    m.fh = m.y - m.ty; m.life += 1.3; m.hide = true;
    return m;
  }
  function newTurret(tp, props) {
    var po = R.pose, W = po && po.ok && po.W, from = W ? W.crane : [R.px, R.py + 2, R.pz], tu = { x: tp[0], y: tp[1], z: tp[2], life: 10, fire: 0, yaw: 0, from: from, dep: 0.45, dep0: 0.45 };
    for (var k in props) tu[k] = props[k]; R.turrets.push(tu); return tu;
  }

  // 每帧姿态：根据速度、加速度、目标方向、开火后坐、受击、技能施放，求出各关节的目标角度并平滑
  function poseStep(dt) {
    var po = R.pose; if (!po.ok) return;
    var fxm = po.fxm, sp = speed(), cy = Math.cos(R.yaw * DEG), sy = Math.sin(R.yaw * DEG), t = R.t, dtc = Math.max(dt, 0.001), c = po.cast;
    var dashing = !!(R.dash && (!R.dash.dodge || R.dash.nitro)), dodging = !!(R.dash && R.dash.dodge && !R.dash.nitro);
    var vf = dashing ? sp * 1.5 : R.vx * sy + R.vz * cy, vs = dodging ? 0 : R.vx * cy - R.vz * sy, vu = R.dash ? 0 : R.vy;
    var fk = clamp(vf / sp, -0.6, 1.5), sk = clamp(vs / sp, -1, 1), uk = clamp(vu / sp, -1, 1), legK = clamp(fk, 0, 1.2);
    po.af = ease(po.af, clamp((vf - po.vf) / dtc / 70, -1.5, 1.5), 12, dt); po.vf = vf;
    // —— 目标与瞄准
    po.aimT -= dt; if (po.aimT <= 0 || (po.tg && po.tg.hp <= 0)) { po.aimT = 0.2; po.tg = target(R.px, R.py, R.pz, 48); }
    var tg = po.tg && po.tg.hp > 0 ? po.tg : null, yawL = 0, dwn = 0;
    if (tg) { var ga = angOf([tg.x - R.px, tg.y - R.py, tg.z - R.pz]); yawL = wrapA(ga[0] - R.yaw); dwn = ga[1] - (R.pitch + po.lean); }
    po.aimK = ease(po.aimK, tg ? (Math.abs(yawL) > 95 ? 0 : 1) : 0, 9, dt);
    // —— 机身：加速时前倾，疾冲时压低，闪避时翻滚
    var leanG = fk * 17 + (dashing ? 20 : 0) + clamp(po.af, 0, 1.5) * 5 - (c && (c.kind === 'salvo' || c.kind === 'meteor') ? 8 : 0);
    po.lean = ease(po.lean, clamp(leanG, -10, 40), 7, dt);
    po.bank = ease(po.bank, -sk * 9, 6, dt);
    po.spin = dodging ? (R.dash.t / R.dash.dur) * 360 * (R.vx * cy - R.vz * sy >= 0 ? -1 : 1) : 0;
    // —— 喷口：尾喷随前进速度与加速度增强，疾冲 / 闪避时全开；腰侧推进筒（朝下）负责升降与横移
    po.thrR = ease(po.thrR, 0.2 + 0.7 * clamp(fk, 0, 1.2) + 0.5 * clamp(po.af, 0, 1.5) + (dashing ? (R.dash.nitro ? 1.6 : 1.0) : 0) + (dodging ? 0.8 : 0), 12, dt);
    po.thrV = ease(po.thrV, 0.18 + 0.7 * Math.max(0, uk) + 0.35 * Math.abs(sk) + 0.15 * Math.max(0, -fk) + (dodging ? 0.6 : 0), 10, dt);
    // —— 腿：悬停时微微下垂，前进时向后收拢，上升时蜷起，下降时伸直，闪避时抱成一团
    var ph = [Math.sin(t * 2.1), Math.sin(t * 2.1 + 1.6)], down = Math.max(0, -uk);
    ['L', 'R'].forEach(function (S, i) {
      var tp = 6 + 18 * legK + (dashing ? 16 : 0) + (dodging ? 52 : 0) + ph[i] * (3 + 4 * legK) - down * 10;
      var kn = 10 + 24 * legK + (dashing ? 4 : 0) + (dodging ? 90 : 0) + 14 * Math.max(0, uk) + ph[1 - i] * (3 + 5 * legK) - down * 10;
      var rl = (S === 'L' ? 3 : -3) - sk * 14 + (dodging ? (S === 'L' ? 12 : -12) : 0);
      if (c && c.kind === 'salvo') { tp += 8; kn += 14; }
      po.th[S].p = ease(po.th[S].p, tp, 9, dt); po.th[S].r = ease(po.th[S].r, rl, 9, dt); po.kn[S] = ease(po.kn[S], Math.max(2, kn), 9, dt);
    });
    // —— 躯干扭转 / 头部转向目标
    var cw = c ? clamp(Math.sin(clamp(c.t / c.dur, 0, 1) * Math.PI) * 1.6, 0, 1) : 0, ck = c ? clamp(c.t / c.dur, 0, 1) : 0;
    var twG = tg ? clamp(yawL * 0.7, -30, 30) * po.aimK : 0, tPG = -po.recB * 4 + (tg ? clamp(dwn * 0.45, -16, 16) * po.aimK : 0);
    if (c) {
      if (c.kind === 'slash') twG = ck < 0.25 ? -30 * (ck / 0.25) : ck < 0.6 ? lerp(-30, 32, (ck - 0.25) / 0.35) : lerp(32, 0, (ck - 0.6) / 0.4);
      else if (c.kind === 'salvo' || c.kind === 'meteor') tPG -= 10 * cw;
      else if (c.kind === 'deploy') tPG += 8 * cw;
      else if (c.kind === 'beam') tPG -= 5 * cw;
    }
    tPG += Math.sin(t * 1.7) * 0.8;
    po.twist = ease(po.twist, twG, 9, dt); po.tP = ease(po.tP, tPG, 12, dt);
    po.hY = ease(po.hY, tg ? clamp(yawL - po.twist, -34, 34) * 0.75 * po.aimK : 0, 10, dt);
    po.hP = ease(po.hP, (tg ? clamp(dwn - po.tP, -20, 24) * 0.5 * po.aimK : 0) - po.hit * 16, 12, dt);
    // —— 手臂
    var ay = clamp(yawL - po.twist, -22, 22), dd_ = clamp(dwn - po.tP, -42, 42), trail = clamp(po.af, -1, 1.5) * 6;
    ['L', 'R'].forEach(function (S) {
      var role = fxm.aim[S] || 'free', side = S === 'L' ? 1 : -1, sway = Math.sin(t * 1.8 + (S === 'L' ? 0 : 2)) * 3, g = { p: 0, y: 0, r: side * 6 };
      if (role === 'gun') { g.p = lerp(-12 + sway + 14 * legK, dd_, po.aimK); g.y = po.aimK * ay * 0.95; g.r = side * (4 + 6 * (1 - po.aimK)); }
      else if (role === 'staff' || role === 'spear') { g.p = lerp(4 + sway * 0.5 + 10 * legK, dd_ + 90, po.aimK); g.y = po.aimK * ay; }
      else if (role === 'axe') { g.p = -4 + sway + 26 * legK; g.r = side * 8; }
      else if (role === 'guard') { g.p = lerp(-22 + sway + 18 * legK, -42, po.aimK); g.y = po.aimK * 8; }
      else { g.p = -6 + sway + 30 * legK; g.r = side * (7 + 6 * legK); }
      if (dodging) { g.p = role === 'staff' || role === 'spear' ? 35 : 55; g.r = side * 10; }
      else if (dashing) { g.p = role === 'staff' || role === 'spear' ? 40 : 60; g.y = 0; }
      if (c) {
        var cp = null, cyaw = 0;
        if (c.kind === 'slash') { if (S === 'R') { cp = ck < 0.25 ? lerp(g.p, -70, ck / 0.25) : ck < 0.6 ? lerp(-70, 120, 1 - Math.pow(1 - (ck - 0.25) / 0.35, 3)) : lerp(120, g.p, (ck - 0.6) / 0.4); cw = 1; } else { cp = 40; } }
        else if (c.kind === 'heal') cp = S === 'R' ? (role === 'staff' ? 50 : -50) : -75;
        else if (c.kind === 'deploy') cp = -75;
        else if (c.kind === 'salvo') cp = -130;
        else if (c.kind === 'meteor') cp = S === 'R' ? 20 : -140;
        else if (c.kind === 'beam' && S === 'R' && (role === 'gun' || role === 'staff' || role === 'spear')) { cp = role === 'gun' ? dd_ : dd_ + 90; cyaw = ay; }
        if (cp !== null) { g.p = lerp(g.p, cp, cw); g.y = lerp(g.y, cyaw, cw); }
      }
      g.p += trail - po.hit * 30;
      // 总俯仰 g.p 拆给大臂（肩）与小臂（肘）：瞄准时大臂微抬、肘部弯曲托住武器，而不是整条手臂像木棍一样硬转
      var tot = g.p, pu, pe, aimW = po.aimK * (1 - cw) * (dashing || dodging ? 0 : 1);
      if (role === 'gun') pu = lerp(tot * 0.6, clamp(-26 + 0.5 * dd_, -70, 10), aimW);
      else if (role === 'staff' || role === 'spear') pu = tot * 0.35;
      else pu = tot * 0.6;
      pe = clamp(tot - pu + (role === 'gun' && aimW > 0.3 ? 8 : 12), -20, 125);
      var a = po.arm[S]; a.p = ease(a.p, pu, 13, dt); a.e = ease(a.e, pe, 15, dt); a.y = ease(a.y, g.y, 12, dt); a.r = ease(a.r, g.r, 10, dt);
    });
    if (c) { c.t += dt; if (c.t >= c.dur) po.cast = null; }
    po.hit = Math.max(0, po.hit - dt * 4); po.hitFlash -= dt;
    po.rec.L = Math.max(0, po.rec.L - dt * 9); po.rec.R = Math.max(0, po.rec.R - dt * 9); po.recB = Math.max(0, po.recB - dt * 7);
    // —— 尾焰粒子 + 斧刃拖尾（使用上一帧的挂点位置）
    var W = po.W;
    if (W && R.parts.length < 240) {
      var d = W.rearD, thr = po.thrR;
      W.rear.forEach(function (n) {
        if (Math.random() > 0.35 + thr * 0.5) return;
        R.parts.push({ model: 'fx_white', x: n[0], y: n[1], z: n[2], vx: d[0] * (5 + 6 * thr) - R.vx * 0.15 + rand(-1, 1), vy: d[1] * (5 + 6 * thr) - R.vy * 0.15 + rand(-1, 1), vz: d[2] * (5 + 6 * thr) - R.vz * 0.15 + rand(-1, 1), life: 0.35 + 0.25 * thr, max: 0.35 + 0.25 * thr, size: 1.2 + thr * 0.8, tint: po.col, noGrav: true });
      });
      if (c && c.kind === 'slash' && ck > 0.22 && ck < 0.7 && W.axe) for (var k = 0; k < 3; k++) R.parts.push({ model: 'fx_spark', x: W.axe[0] + rand(-0.4, 0.4), y: W.axe[1] + rand(-0.4, 0.4), z: W.axe[2] + rand(-0.4, 0.4), vx: rand(-3, 3), vy: rand(-3, 3), vz: rand(-3, 3), life: 0.35, max: 0.35, size: 1.8, noGrav: true });
    }
  }
  // 由关节角度求各部件的世界矩阵与挂点世界坐标（渲染与发射共用）
  function poseBuild() {
    var po = R.pose; if (!po.ok) return;
    var rig = po.rig, fxm = po.fxm, root = E.trs([R.px, R.py - 2.4 + Math.sin(R.t * 3) * 0.12, R.pz], R.yaw, R.pitch + po.lean, R.roll + po.bank + po.spin, 1.35);
    var Mt = pivot(root, rig.waist, rot(po.twist, po.tP, 0)), mats = { body: Mt }, Ma = {};
    mats.head = pivot(Mt, rig.neck, rot(po.hY, po.hP, 0));
    ['L', 'R'].forEach(function (S) {
      var a = po.arm[S], role = fxm.aim[S], rec = po.rec[S], tr = null;
      if (rec > 0.01) { if (role === 'gun' || role === 'guard') tr = [0, 0, -0.28 * rec]; else if (role === 'staff' || role === 'spear') tr = [0, 0.35 * rec, 0]; }
      var pk = role === 'gun' ? -10 * rec : 0, Mu = pivot(Mt, rig['shoulder' + S], rot(a.y, a.p + rec * 3, a.r));
      mats['uarm' + S] = Mu; Ma[S] = pivot(Mu, rig['elbow' + S], rot(0, a.e + pk, 0), tr); mats['arm' + S] = Ma[S];
      mats['thigh' + S] = pivot(root, rig['hip' + S], rot(0, po.th[S].p, po.th[S].r));
      mats['shin' + S] = pivot(mats['thigh' + S], rig['knee' + S], rot(0, po.kn[S], 0));
    });
    var W = { muz: {}, rearD: xd(Mt, [0, 0, -1]), vernD: xd(Mt, [0, -1, 0]), rear: [xf(Mt, rig.rearL), xf(Mt, rig.rearR)], vern: [xf(Mt, rig.vernL), xf(Mt, rig.vernR)] };
    ['L', 'R'].forEach(function (S) { if (rig['muzzle' + S]) W.muz[S] = rig['muzzle' + S].map(function (q) { return xf(Ma[S], q); }); });
    if (rig.muzzleP) W.muz.P = rig.muzzleP.map(function (q) { return xf(Mt, q); });
    W.shoulder = [xf(Mt, [rig.shoulderL[0], rig.shoulderL[1] + 0.6, rig.shoulderL[2]]), xf(Mt, [rig.shoulderR[0], rig.shoulderR[1] + 0.6, rig.shoulderR[2]])];
    W.back = xf(Mt, [(rig.rearL[0] + rig.rearR[0]) / 2, rig.rearL[1], rig.rearL[2] - 0.1]);
    W.crane = rig.craneL ? xf(Mt, rig.craneL) : W.shoulder[0];
    W.axe = rig.axeEdge ? xf(Ma.R, rig.axeEdge) : null;
    po.mats = mats; po.W = W;
  }

  // ------------------------------------------------------------------ 敌人
  var ENEMY = {
    crawler: { name: '晶化爬虫', model: 'enemy_crystal_crawler', scale: 3, lunge: { cd: 4.5, range: 12, dash: 24, dur: 0.28, tele: 0.45 }, hp: 14, spd: 9, dmg: 6, xp: 1, cr: 2 },
    grunt: { name: '海贼喽啰', model: 'enemy_pirate_grunt', scale: 2.6, lunge: { cd: 5.5, range: 15, dash: 28, dur: 0.3, tele: 0.5 }, hp: 26, spd: 7, dmg: 8, xp: 2, cr: 3 },
    inter: { name: '海贼截击机', model: 'ship_pirate_interceptor', scale: 0.9, hp: 30, spd: 11, dmg: 7, xp: 3, cr: 4, keep: 20, ship: true, shoot: { cd: 3.2, spd: 20, dmg: 6, n: 1, spread: 0, burst: 3 } },
    heavy: { name: '海贼重炮手', model: 'enemy_pirate_heavy', scale: 3, hp: 90, spd: 4.5, dmg: 12, xp: 6, cr: 8, shoot: { cd: 4, spd: 16, dmg: 7, n: 3, spread: 22, big: true } },
    brute: { name: '晶核巨兽', model: 'enemy_crystal_brute', scale: 3.4, slam: { cd: 7, r: 14, tele: 0.9, dmg: 1.4 }, hp: 520, spd: 5, dmg: 16, xp: 30, cr: 60, elite: true },
    sniper: { name: '晶刺狙击手', model: 'enemy_crystal_sniper', scale: 2.6, hp: 40, spd: 5, dmg: 8, xp: 5, cr: 7, keep: 34, snipe: { cd: 5.5, tele: 1.4, dmg: 16, spd: 80 } },
    guard: { name: '盾卫', model: 'enemy_shield_guard', scale: 2.6, hp: 85, spd: 5.5, dmg: 10, xp: 5, cr: 7, guard: true, lunge: { cd: 6.5, range: 12, dash: 22, dur: 0.3, tele: 0.55 } },
    splitter: { name: '裂变晶体', model: 'enemy_crystal_splitter', scale: 2.4, hp: 55, spd: 6, dmg: 7, xp: 4, cr: 5, split: 3 },
    bomber: { name: '自爆虫', model: 'enemy_bomber_bug', scale: 2.4, hp: 12, spd: 13, dmg: 9, xp: 2, cr: 3, bomb: { fuse: 0.75, r: 7, dmg: 2.2, trig: 6 } },
    phantom: { name: '幽影刺客', model: 'enemy_phantom_blade', scale: 2.6, hp: 40, spd: 9, dmg: 11, xp: 6, cr: 8, blink: { cd: 6.5, tele: 0.7 }, lunge: { cd: 5, range: 14, dash: 30, dur: 0.28, tele: 0.35 } },
    ore: { name: '富矿', model: 'space_ore_asteroid', scale: 1.3, hp: 45, spd: 0, dmg: 0, xp: 2, cr: 15, ore: true },
    gunship_boss: { name: '海贼头目号', model: 'ship_pirate_gunship', scale: 2.2, laser: { from: 2, every: 8 }, hp: 3300, spd: 3.6, dmg: 22, xp: 0, cr: 0, boss: true, keep: 24, ship: true, shoot: { cd: 1.9, spd: 17, dmg: 9, n: 7, spread: 70 } },
    brute_king: { name: '晶核巨兽王', model: 'enemy_crystal_brute', scale: 6.5, slam: { cd: 6, r: 22, tele: 1.0, dmg: 1.5, ring: true }, hp: 5600, spd: 4.2, dmg: 28, xp: 0, cr: 0, boss: true, shoot: { cd: 4, spd: 14, dmg: 10, ring: 16 }, summon: 6 },
    flagship_boss: { name: '赤髑号', model: 'ship_pirate_flagship', scale: 1.5, laser: { from: 1, every: 7 }, hp: 8500, spd: 3.2, dmg: 30, xp: 0, cr: 0, boss: true, keep: 30, ship: true, shoot: { cd: 3.2, spd: 15, dmg: 11, ring: 20, aim: 5 } }
  };
  var UPG = {
    main: { kind: 'weapon', name: '主武器强化', max: 6, desc: ['', '伤害 +20%，射速 +6%', '弹道 +1', '伤害 +20%，射速 +6%', '弹道 +1', '伤害 +30%，射速 +10%'] },
    hull: { kind: 'passive', name: '耐久强化', max: 5, desc: ['耐久上限 +20%，并修复 25%'] },
    engine: { kind: 'passive', name: '引擎超频', max: 5, desc: ['移动速度 +8%'] },
    magnet: { kind: 'passive', name: '引力收集器', max: 5, desc: ['拾取范围 +35%'] },
    power: { kind: 'passive', name: '火控核心', max: 5, desc: ['所有伤害 +10%'] },
    cooling: { kind: 'passive', name: '冷却回路', max: 5, desc: ['所有冷却 -7%（含机甲技能）'] },
    repair: { kind: 'passive', name: '纳米修复', max: 5, desc: ['每秒修复耐久 +0.6'] },
    support: { kind: 'crew', name: '驾驶员支援', max: 5, desc: ['', '支援技能伤害 +35%，冷却 -10%', '支援技能伤害 +35%，冷却 -10%', '支援技能伤害 +35%，冷却 -10%', '觉醒：支援技能数量翻倍'] }
  };
  var NODE_INFO = {
    pirate: { name: '海贼据点', color: '#E0458C', hint: '靠近后清剿全部海贼，打开战利品', goal: '清剿海贼据点' },
    derelict: { name: '遗弃残骸', color: '#F5A524', hint: '停留在光圈内搜刮，会引来虫群', goal: '搜刮遗弃残骸' },
    ore: { name: '富矿带', color: '#F2B33D', hint: '击碎全部矿石', goal: '开采富矿带' },
    hunt: { name: '限时猎杀', color: '#FF8A3A', hint: '靠近后 40 秒内击败足够多的敌人，奖励战利品', goal: '限时猎杀' },
    ambush: { name: '精英伏击', color: '#B47CFF', hint: '连续 3 波伏击，波次间不会补血', goal: '击退伏击' },
    distress: { name: '求救信号', color: '#5CF2DC', hint: '守住逃生舱 20 秒，奖励星源', goal: '营救逃生舱' },
    merchant: { name: '流浪商人', color: '#7CF29A', hint: '靠近交易，用本局信用点购买强化', goal: '' },
    nest: { name: '晶簇巢穴', color: '#B47CFF', hint: '击败巢穴守卫，获得碎片', goal: '击败巢穴守卫' },
    gate: { name: '星门', color: '#9DF7EC', hint: '飞进星门前往下一个星域', goal: '' }
  };

  // ------------------------------------------------------------------ 状态与属性
  var R = null, keys = {}, joy = { id: null, cx: 0, cy: 0, dx: 0, dy: 0 }, look = { id: null, x: 0, y: 0, idle: 0 }, paused = false, stars = null, lastVP = null, hud = {};
  var camBasis = { f: [0, 0, 1], r: [1, 0, 0], u: [0, 1, 0], eye: [0, 0, 0] };
  function lv(id) { return R.lv[id] || 0; }
  function M() { return C.mech(R.mech); }
  function fx(k) { var c = C.char(R.pilot); return c.passive.fx[k] || 0; }
  function hullMax() { return Math.round(M().hp * R.mMul * (1 + R.st.hp + fx('hull')) * (1 + 0.2 * lv('hull')) * (dmod('glass') ? 0.7 : 1)); }
  function dmgMult() { return (dmod('glass') ? 1.4 : 1) * (1 + R.st.atk) * (1 + 0.1 * lv('power')) * (R.st.traits.berserk && R.hull < hullMax() * 0.3 ? 1.3 : 1); }
  function cdMult() { return (1 - 0.07 * lv('cooling')) * (1 - R.st.cdr); }
  function dmod(id) { return !!(R && R.daily && R.daily.mods.indexOf(id) >= 0); }
  function speed() { return M().spd * 1.1 * (1 + R.st.spd) * (1 + 0.08 * lv('engine')) * (dmod('swift') ? 1.15 : 1); }
  function pickupR() { return 11 * (1 + R.st.pickup + fx('pickup')) * (1 + 0.35 * lv('magnet')); }
  function xpNeed(l) { return Math.floor(5 + l * 4 + l * l * 0.35); }
  function blast() { return (1 + fx('blast')) * (1 + R.st.blast); }
  function P() { return { x: R.px, y: R.py, z: R.pz }; }

  function newRun(chapterId, opt) {
    opt = opt || {};
    var ch0 = C.CHAPTERS[chapterId - 1], s = C.save, match = C.mech(s.mech).match === s.pilot, dg = Math.max(1, Math.min(10, opt.danger || 1));
    // 危险等级：敌人血量 +12% / 级、伤害 +8% / 级（含首领），刷怪更密，奖励 +15% / 级
    var ch = Object.assign({}, ch0, { hp: ch0.hp * (1 + 0.12 * (dg - 1)) * (opt.daily && opt.mods.indexOf('iron') >= 0 ? 1.5 : 1), dmg: ch0.dmg * (1 + 0.08 * (dg - 1)) });
    R = { ch: ch, danger: dg, endless: !!opt.endless || !!opt.daily, daily: opt.daily ? { mods: opt.mods.slice() } : null, wave: 1, bossScale: 1 * (1 + 0.12 * (dg - 1)), t: 0, px: 0, py: 0, pz: -90, vx: 0, vy: 0, vz: 0, yaw: 0, pitch: 0, roll: 0, camYaw: 0, camPitch: 8, xp: 0, level: 1, kills: 0, credits: 0, src: 0, frags: {},
      lv: { main: 1, support: 1 }, pilot: s.pilot, copilot: s.pilot, mech: s.mech, match: match,
      mMul: C.mechMul(s.mech) * (match ? 1 + C.MATCH_BONUS : 1), cStar: C.pilotMul(s.pilot) * (match ? 1 + C.MATCH_BONUS : 1), dodgeCd: 0,
      enemies: [], shots: [], ebullets: [], missiles: [], gems: [], pickups: [], parts: [], nums: [], bubbles: [], turrets: [], wells: [], beams: [], novas: [], zones: [], fires: [],
      timers: { main: 0 }, spawnAcc: 0, iframe: 0, shake: 0, boss: null, phase: 'explore', won: false, over: false, ended: false,
      banner: null, bannerT: 0, decor: [], pendingLevels: C.chipStats().traits.headstart ? 1 : 0, st: C.chipStats(), mines: [], booms: [], strikes: [], combo: 0, comboT: 0,
      activeCd: 3, supportCd: 2, dash: null, cop: { x: 0, y: 0, z: -90, dash: null }, revived: false, adRevived: false, god: false, nodes: [], nearNode: null, target: null, sched: [], pose: null };
    initMods(); initArms();
    R.pose = newPose();
    if (C.save.runs < 3) setTimeout(function () { if (R && !R.over) banner('新手加速：前 3 局经验 +80%'); }, 2500);
    R.hull = hullMax();
    stars = stars || E.buildStars({ data: makeStars(), colors: [[0.92, 0.93, 1.0], [0.55, 0.95, 0.9], [1.0, 0.8, 0.5]] });
    loadSector(1);
  }
  function loadSector(k) {
    k = Math.max(1, Math.min(SECTORS, k)); R.warping = false;
    R.sector = k; R.secMul = 1 + 0.15 * (k - 1); R.dmgMul = R.ch.dmg * (1 + 0.06 * (k - 1));
    R.px = 0; R.py = 0; R.pz = -90; R.vx = R.vy = R.vz = 0; R.yaw = 0; R.pitch = 0; R.camYaw = 0; R.camPitch = 8;
    R.gems.forEach(function (g) { R.xp += g.v; });
    R.enemies = []; R.shots = []; R.ebullets = []; R.missiles = []; R.gems = []; R.pickups = []; R.turrets = []; R.wells = []; R.zones = []; R.fires = []; R.dash = null; R.mines = []; R.booms = []; R.strikes = [];
    R.cop.x = 0; R.cop.y = 0; R.cop.z = -90; R.boss = null; R.phase = 'explore'; R.nodes = []; R.decor = []; R.secT = 0; R.bossTimer = 0; R.event = null; R.target = null;
    var plan = R.endless ? 'endless' : PLAN[k - 1], ev;
    if (plan === 'endless') { R.objective = '无尽模式：撑得越久越好'; R.waveT = 0; R.wave = 1; R.secMul = 1; }
    else if (plan === 'boss') { R.bossTimer = 2.5; R.objective = '击败首领 ' + R.ch.bossName; }
    else {
      ev = plan === 'elite' ? 'nest' : pick(EVENTS.filter(function (e) { return e !== R.lastEvent; }));
      R.lastEvent = ev;
      // 目标点放在前方立体空间中，高度随机，迫使玩家上下机动
      var a = rand(-0.9, 0.9);
      R.event = makeNode(ev, Math.sin(a) * rand(30, 60), rand(-35, 35), rand(-10, 35)); R.nodes.push(R.event);
      R.objective = NODE_INFO[ev].goal;
    }
    if (plan === 'rest') R.nodes.push(makeNode('merchant', 28, 10, -70));
    R.gate = makeNode('gate', rand(-25, 25), rand(-20, 20), 95); R.gate.state = plan === 'boss' || plan === 'endless' ? 'hidden' : 'locked'; R.nodes.push(R.gate);
    // 远景：小行星分布在战场外围的立体球壳上
    for (var i = 0; i < 22; i++) { var d = randDir(), r = rand(190, 300); R.decor.push({ model: pick(['space_asteroid_a', 'space_asteroid_a', 'space_asteroid_b', 'space_ore_asteroid']), x: d[0] * r, y: d[1] * r, z: d[2] * r, s: rand(3, 9), yaw: rand(0, 360), spin: rand(-8, 8) }); }
    R.decor.push({ model: 'space_planet', x: -420, y: -160, z: 620, s: 9, yaw: 30, spin: 0.5 });
    R.affix = k >= 2 && plan !== 'boss' && plan !== 'endless' ? pick(AFFIX) : null;
    banner((R.endless ? '无尽模式' : '星域 ' + k + ' / ' + SECTORS) + '：' + R.objective + (R.affix ? '　词缀：' + R.affix.name : ''));
  }
  function affix(id) { return !!(R && ((R.affix && R.affix.id === id) || dmod(id))); }
  function nextSector() {
    if (R.sector >= SECTORS || R.warping) return;
    var f = document.getElementById('warp'); if (f) f.classList.add('on');
    R.warping = true; paused = true; C.sfx('warp');
    var next = R.sector + 1, run = R;
    if (window.CosmicRun.debug.sync) { R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.2); loadSector(next); paused = false; if (f) f.classList.remove('on'); return; }
    setTimeout(function () { if (R !== run || R.sector !== next - 1) { if (f) f.classList.remove('on'); return; } R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.2); loadSector(next); R.warping = false; paused = false; if (f) f.classList.remove('on'); }, 600);
  }
  function objectiveDone() { return !R.event || R.event.state === 'done'; }
  function makeNode(type, x, y, z) {
    var n = { type: type, x: x, y: y, z: z, state: 'idle', progress: 0, timer: 0, info: NODE_INFO[type], objs: [] };
    if (type === 'pirate') n.objs.push({ model: 'space_pirate_base', x: x, y: y - 6, z: z, s: 0.7, spin: 2 });
    if (type === 'derelict') n.objs.push({ model: 'space_derelict', x: x, y: y, z: z, s: 1.6, spin: 3 });
    if (type === 'merchant') { n.objs.push({ model: 'space_station', x: x, y: y - 2, z: z, s: 0.8, spin: 8 }); n.objs.push({ model: 'space_beacon', x: x + 10, y: y, z: z - 6, s: 1.4, spin: 0 }); }
    if (type === 'distress') { n.pod = { hp: 120, max: 120 }; n.objs.push({ model: 'prop_loot_pod', x: x, y: y, z: z, s: 5, spin: 40 }); n.objs.push({ model: 'space_beacon', x: x - 8, y: y - 2, z: z + 4, s: 1.2, spin: 0 }); }
    if (type === 'hunt') n.objs.push({ model: 'space_beacon', x: x, y: y, z: z, s: 1.8, spin: 30 });
    if (type === 'ambush') { n.objs.push({ model: 'space_derelict', x: x, y: y, z: z, s: 1.2, spin: 6 }); n.objs.push({ model: 'space_beacon', x: x + 8, y: y, z: z, s: 1.3, spin: 0 }); }
    if (type === 'nest') for (var i = 0; i < 4; i++) n.objs.push({ model: 'env_crystal_cluster', x: x + rand(-9, 9), y: y + rand(-6, 6), z: z + rand(-9, 9), s: rand(3, 4.5), spin: rand(-20, 20), pitch: rand(0, 360) });
    if (type === 'gate') n.objs.push({ model: 'space_jumpgate', x: x, y: y, z: z, s: 1.2, pitch: 0, spin: 0 });
    return n;
  }
  function makeStars() {
    var out = [];
    for (var i = 0; i < 420; i++) { var x = rand(-1, 1), y = rand(-1, 1), z = rand(-1, 1), l = Math.hypot(x, y, z) || 1, r = rand(3000, 3600); out.push(x / l * r, y / l * r, z / l * r, rand(9, 17), Math.random() < 0.7 ? 0 : (Math.random() < 0.66 ? 1 : 2)); }
    return out;
  }

  // ------------------------------------------------------------------ 敌人
  function spawnEnemy(type, x, y, z, node) {
    var d = ENEMY[type], mesh = E.getMesh(d.model);
    var hpMul = d.boss ? R.bossScale : R.ch.hp * R.secMul * (R.endless ? 1 : 1 + R.secT / 300);
    var e = { type: type, d: d, mesh: mesh, x: x, y: y, z: z, hp: d.hp * hpMul, max: 0, r: Math.max(1.6, mesh.radius * d.scale * 0.55),
      fire: d.shoot ? rand(1, d.shoot.cd) : 0, flash: 0, contact: 0, yaw: rand(0, 360), pitch: 0, kx: 0, ky: 0, kz: 0, bob: rand(0, 6), node: node || null, summon: d.summon || 0 };
    clampBound(e, 20);
    e.max = e.hp; R.enemies.push(e);
    if (d.boss) R.boss = e;
    return e;
  }
  function clampBound(o, extra) { var l = len3(o.x, o.y, o.z), b = BOUND + (extra || 0); if (l > b) { o.x *= b / l; o.y *= b / l; o.z *= b / l; } }
  function spherePos(c, r) { var d = randDir(); return [c.x + d[0] * r, c.y + d[1] * r, c.z + d[2] * r]; }
  // 刷怪：偏向镜头前方的半球，让玩家看得到来袭的敌人
  function aheadPos() {
    var f = camBasis.f, d = randDir(); if (dot(d, f) < -0.2) d = [-d[0], -d[1], -d[2]];
    var dir = nrm([d[0] + f[0] * 0.8, d[1] + f[1] * 0.8, d[2] + f[2] * 0.8]);
    return [R.px + dir[0] * 55, R.py + dir[1] * 55, R.pz + dir[2] * 55];
  }
  function roamType() {
    var m = R.ch.mix.slice(), k = R.sector, c = R.ch.id;
    if (R.endless) { var w = R.wave; m = ['crawler', 'grunt', 'inter', 'bomber']; if (w >= 2) m.push('splitter', 'guard'); if (w >= 3) m.push('sniper'); if (w >= 4) m.push('phantom', 'heavy'); if (w >= 6) m.push('guard', 'sniper', 'phantom', 'splitter'); return pick(m); }
    if (k >= 2) m.push('bomber'); if (k >= 3) m.push('splitter'); if (c >= 2 || k >= 4) m.push('guard'); if (c >= 2 && k >= 2) m.push('sniper'); if (c >= 3) m.push('phantom', 'phantom', 'sniper', 'guard');
    return pick(m);
  }
  function updateSpawns(dt) {
    R.secT += dt;
    if (R.bossTimer > 0) { R.bossTimer -= dt; if (R.bossTimer <= 0) { var bp = aheadPos(); spawnEnemy(R.ch.boss, bp[0] * 0.7, bp[1] * 0.7, bp[2] * 0.7 + 20); R.phase = 'boss'; banner('首领出现：' + R.boss.d.name); C.sfx('boss'); C.music.play('boss'); } }
    if (R.gate.state === 'open') return;
    var cap = Math.round((34 + 10 * R.sector + 8 * R.ch.id) * (affix('tide') ? 1.3 : 1) * perfMul() * (1 + 0.05 * (R.danger - 1))), rate = (R.phase === 'boss' ? 0.35 : 0.9 + 0.22 * R.sector + R.secT / 120) * (affix('tide') ? 1.25 : 1) * (1 + 0.06 * (R.danger - 1));
    if (R.daily && R.secT >= C.DC_TIME && !R.ended) { endRun(true, false); return; }
    if (R.daily && dmod('elite') && Math.floor(R.secT / 40) > (R.eliteN || 0)) { R.eliteN = Math.floor(R.secT / 40); var elp = aheadPos(); spawnEnemy('brute', elp[0], elp[1], elp[2]); banner('精英出现！'); }
    if (R.endless) {
      var w = 1 + Math.floor(R.secT / 45);
      if (w > R.wave) {
        R.wave = w; R.secMul = 1 + 0.12 * (w - 1); R.dmgMul = R.ch.dmg * (1 + 0.05 * (w - 1)); banner('无尽模式：第 ' + w + ' 波'); C.sfx('gate');
        if (w % 5 === 0 && !R.boss) { var ebp = aheadPos(); R.bossScale = (1 + 0.12 * (R.danger - 1)) * (1 + 0.3 * (w / 5 - 1)); spawnEnemy(R.ch.boss, ebp[0] * 0.7, ebp[1] * 0.7, ebp[2] * 0.7 + 20); R.phase = 'boss'; banner('第 ' + w + ' 波首领：' + R.boss.d.name); C.sfx('boss'); }
      }
      cap = Math.min(150, Math.round((38 + 6 * R.wave) * perfMul())); rate = 1.1 + 0.18 * R.wave;
    }
    R.spawnAcc += dt * rate;
    while (R.spawnAcc >= 1) {
      R.spawnAcc -= 1;
      if (R.enemies.filter(function (e) { return !e.node && !e.d.ore && !e.d.boss; }).length < cap) { var p = aheadPos(); spawnEnemy(roamType(), p[0], p[1], p[2]); }
    }
  }
  // 三维空间网格：分离与命中查询
  var grid = {}, CELL = 8;
  function key(x, y, z) { return Math.floor(x / CELL) + ',' + Math.floor(y / CELL) + ',' + Math.floor(z / CELL); }
  function buildGrid() { grid = {}; R.enemies.forEach(function (e) { var k = key(e.x, e.y, e.z); (grid[k] || (grid[k] = [])).push(e); }); }
  function near(x, y, z, r, fn) {
    var x0 = Math.floor((x - r) / CELL), x1 = Math.floor((x + r) / CELL), y0 = Math.floor((y - r) / CELL), y1 = Math.floor((y + r) / CELL), z0 = Math.floor((z - r) / CELL), z1 = Math.floor((z + r) / CELL);
    for (var a = x0; a <= x1; a++) for (var b = y0; b <= y1; b++) for (var c = z0; c <= z1; c++) { var l = grid[a + ',' + b + ',' + c]; if (!l) continue; for (var i = 0; i < l.length; i++) if (fn(l[i]) === false) return; }
  }
  // 自动瞄准：优先敌人，附近没有敌人时才打矿石
  function target(x, y, z, maxR) {
    var best = null, bd = maxR * maxR, ore = null, od = maxR * maxR;
    R.enemies.forEach(function (e) {
      if (e.hp <= 0) return; var d = d3(x, y, z, e.x, e.y, e.z);
      if (e.d.ore) { if (d < od) { od = d; ore = e; } } else if (d < bd) { bd = d; best = e; }
    });
    return best || ore;
  }
  function hurtEnemy(e, dmg, kx, ky, kz, noNum, extraCrit, col) {
    if (e.hp <= 0) return;
    var crit = Math.random() < 0.08 + fx('crit') + R.st.crit + (extraCrit || 0);
    if (e.d.guard) { var gf = fwdOf(e.yaw, 0), gp = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]); if (gf[0] * gp[0] + gf[2] * gp[2] > 0.35) { dmg *= 0.2; crit = false; if (!noNum && R.nums.length < 70) R.nums.push({ x: e.x, y: e.y + e.r * 1.2, z: e.z, v: '格挡', crit: false, col: '#5CF2DC', life: 0.5 }); if (R.parts.length < 220) sparks(e.x, e.y, e.z, 'fx_spark_teal', 2, 8, 0.2); } }
    dmg *= dmgMult() * (crit ? 2 + R.st.critDmg : 1) * ((e.d.elite || e.d.boss) ? 1 + R.st.elite : 1);
    if (e.d.ore) dmg *= 1 + fx('loot');
    e.hp -= dmg; e.flash = e.d.boss ? 0 : 0.06; R.dmgDealt = (R.dmgDealt || 0) + Math.min(dmg, e.hp + dmg);
    if ((kx || ky || kz) && !e.d.ore) { var m = e.d.boss ? 0.04 : e.d.elite ? 0.25 : 1; e.kx += kx * m; e.ky += ky * m; e.kz += kz * m; }
    if (!noNum && R.nums.length < 70) R.nums.push({ x: e.x, y: e.y + e.r * 1.2, z: e.z, v: Math.round(dmg), crit: crit, col: col, life: 0.7 });
    if (!noNum && !e.d.ore) {
      var bigE = e.d.elite || e.d.boss;
      if (R.parts.length < 200) sparks(e.x, e.y, e.z, 'fx_spark', crit ? 4 : 1, crit ? 12 : 8, 0.22, null, crit ? 1 : 0.7);
      if (e.d.elite && !e.d.boss) { R.shake = Math.max(R.shake, crit ? 0.05 : 0.02); if (crit) R.hitstop = Math.max(R.hitstop || 0, 0.03); }
      if (!e.d.boss || crit) C.sfx(crit ? 'crit' : 'hit');
    }
    if (e.hp <= 0) killEnemy(e);
  }
  function knock(e, from, power) { var v = nrm([e.x - from.x, e.y - from.y, e.z - from.z]); return [v[0] * power, v[1] * power, v[2] * power]; }
  function addCredits(n) { R.credits += Math.round(n * (1 + R.st.credit)); }
  function killEnemy(e) {
    if (!e.d.ore) { R.kills++; R.combo = R.comboT > 0 ? R.combo + 1 : 1; R.comboT = 2.5; R.bestCombo = Math.max(R.bestCombo || 0, R.combo); }
    if (e.d.split && !e.noSplit) { for (var si = 0; si < e.d.split; si++) { var sp2 = spherePos(e, e.r + 1); spawnEnemy('crawler', sp2[0], sp2[1], sp2[2], e.node); } }
    var big = e.d.elite || e.d.boss;
    if (big) R.hitstop = Math.max(R.hitstop || 0, e.d.boss ? 0.18 : 0.1);
    if (e.d.boss) R.slowT = 1.2;
    sparks(e.x, e.y, e.z, e.d.ore ? 'fx_debris' : 'fx_spark', big ? 60 : 10, big ? 30 : 14, 0.8);
    sparks(e.x, e.y, e.z, 'fx_debris', big ? 30 : 5, 12, 1.4);
    addCredits(e.d.cr * (e.d.ore ? 1 : R.ch.hp));
    var xp = e.d.xp;
    while (xp > 0) { var v = xp >= 10 ? 10 : xp >= 5 ? 5 : 1; xp -= v; R.gems.push({ x: e.x + rand(-1.5, 1.5), y: e.y + rand(-1.5, 1.5), z: e.z + rand(-1.5, 1.5), v: v }); }
    // 补给药箱：基础 1%，幸运芯片加成，上限 5%；场上最多 3 个，且两次掉落至少间隔 5 秒，避免满地药箱
    if (!big && !e.d.ore && Math.random() < Math.min(0.05, 0.01 + R.st.luck) && R.t - (R.lastHeal || -99) > 5 && R.pickups.filter(function (p) { return p.kind === 'heal'; }).length < 3) { R.lastHeal = R.t; R.pickups.push({ kind: 'heal', x: e.x, y: e.y, z: e.z }); }
    if (R.sub && !e.d.ore && (big || Math.random() < 0.006) && R.pickups.filter(function (p) { return p.kind === 'ammo'; }).length < 4) R.pickups.push({ kind: 'ammo', x: e.x, y: e.y, z: e.z, n: e.d.boss ? 6 : big ? 3 : 2 });
    if (R.target === e) R.target = null;
    if (e.d.elite) R.shake = 0.4;
    if (e.d.elite && dmod('elite')) R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.1);
    if (e.d.boss && R.endless) { R.bossKilled = (R.bossKilled || 0) + 1; R.shake = 0.8; R.src += 3; R.boss = null; R.phase = 'explore'; banner(e.d.name + ' 被击败！星源 +3'); C.sfx('win'); }
    else if (e.d.boss) { R.won = true; R.shake = 1.2; R.src += 5; banner(e.d.name + ' 被击败！'); C.sfx('win'); setTimeout(function () { endRun(true); }, 2200); }
    else if (big) C.sfx('boom'); else if (Math.random() < 0.35) C.sfx('pop');
  }
  function sparks(x, y, z, model, n, spd, life, tint, sz) {
    for (var i = 0; i < n && R.parts.length < 260 * perfMul(); i++) { var d = randDir(), s = rand(0.3, 1) * spd; R.parts.push({ model: model, x: x, y: y, z: z, vx: d[0] * s, vy: d[1] * s, vz: d[2] * s, life: life * rand(0.6, 1.2), max: life, size: rand(1.5, 3) * (sz || 1), tint: tint }); }
  }
  // —— 特效工具：热色渐变粒子（白热 -> 主色 -> 暗红）、冲击环、拖尾
  var HOT = [1.7, 1.55, 1.3], EMBER = [1.5, 0.75, 0.25];
  function hotRamp(t, k) { if (k > 0.7) return HOT; var q = 0.3 + 0.7 * (k / 0.7); return [t[0] * q, t[1] * q * q, t[2] * q * q]; }
  function emb(x, y, z, tint, n, spd, life, size, up) {
    for (var i = 0; i < n && R.parts.length < 250 * perfMul(); i++) { var d = randDir(), s = rand(0.4, 1) * spd; R.parts.push({ model: 'fx_white', x: x, y: y, z: z, vx: d[0] * s, vy: d[1] * s + (up || 0), vz: d[2] * s, life: life * rand(0.7, 1.2), max: life, size: size * rand(0.7, 1.2), tint: tint || EMBER, hot: true, noGrav: true }); }
  }
  function ringBurst(x, y, z, r, tint, dur) { if (R.novas.length < 12) R.novas.push({ x: x, y: y + 1, z: z, r: r, life: dur, dur: dur, tint: tint, fast: true }); }
  function trail(x, y, z, tint, size, life) { if (R.parts.length < 200 * perfMul()) R.parts.push({ model: 'fx_white', x: x + rand(-0.15, 0.15), y: y + rand(-0.15, 0.15), z: z + rand(-0.15, 0.15), vx: rand(-1, 1), vy: rand(-1, 1), vz: rand(-1, 1), life: life, max: life, size: size, tint: tint, hot: true, noGrav: true }); }
  var HEALC = [0.3, 1.2, 0.5];
  function banner(msg) { R.banner = msg; R.bannerT = 3; }
  function hurtPlayer(dmg) {
    if (affix('fury')) dmg *= 1.25;
    if (R.god && R.iframe <= 0 && !(R.dash && R.dash.inv)) { R.dmgTaken = (R.dmgTaken || 0) + dmg * R.dmgMul * (1 - R.st.armor); R.iframe = 0.4; }
    if (R.iframe > 0 || R.god || R.over || R.won || (R.dash && R.dash.inv)) return;
    R.dmgTaken = (R.dmgTaken || 0) + dmg * R.dmgMul * (1 - R.st.armor); R.hull -= dmg * R.dmgMul * (1 - R.st.armor); R.iframe = 0.4; C.sfx('hurt'); R.hitstop = Math.max(R.hitstop || 0, 0.05); if (R.pose) { R.pose.hit = 1; R.pose.hitFlash = 0.09; }
    R.shake = Math.max(R.shake, 0.25); var f = document.getElementById('hitflash'); if (f) { f.style.opacity = (C.save.settings && C.save.settings.fx === 'soft') ? 0.2 : 0.4; setTimeout(function () { f.style.opacity = 0; }, 120); }
    if (R.hull <= 0) { R.hull = 0; onDeath(); }
  }
  function onDeath() {
    if (R.st.traits.revive && !R.revived) { R.revived = true; R.hull = hullMax() * 0.4; R.iframe = 2; nova(P(), 14, 60, '#5CF2DC'); banner('星魂庇护：复活！'); return; }
    R.over = true; sparks(R.px, R.py, R.pz, 'fx_spark', 80, 30, 1.2);
    setTimeout(openRevive, 1100);
  }
  // 首领阶段切换：血量 66% / 33% 时进入下一阶段——短暂停火、环形冲击、召唤小怪，之后弹幕更密、冷却更短
  function bossPhase(e) {
    banner(e.d.name + ' 进入第 ' + e.ph + ' 阶段！'); C.sfx('boss'); R.shake = Math.max(R.shake, 0.7); e.fire = 1.6; e.laser = null;
    R.novas.push({ x: e.x, y: e.y, z: e.z, r: e.r * 3.2, life: 0.6, dur: 0.6, tint: [1.5, 0.2, 0.28], fast: true });
    emb(e.x, e.y, e.z, [1.5, 0.3, 0.3], 24, 18, 0.7, 2.4);
    var n = e.ph === 2 ? 6 : 8; for (var i = 0; i < n; i++) { var p = spherePos(e, e.r + 5); spawnEnemy(i % 3 === 0 ? 'inter' : 'crawler', p[0], p[1], p[2]); }
  }
  function updateEnemies(dt) {
    buildGrid();
    var pod = R.nodes.filter(function (n) { return n.type === 'distress' && n.state === 'active'; })[0];
    R.enemies.forEach(function (e) {
      var d = e.d; if (e.hp <= 0) return;
      e.flash -= dt;
      if (d.ore) return;
      if (e.burn && e.burn.t > 0) { e.burn.t -= dt; e.hp -= e.burn.dps * dt; } if (e.poison && e.poison.t > 0) { e.poison.t -= dt; e.hp -= e.poison.dps * dt; }
      if (e.hp <= 0) { e.hp = 0.0001; hurtEnemy(e, 1, 0, 0, 0, true); return; }
      if (e.slowT > 0) e.slowT -= dt; if (e.dmark > 0) e.dmark -= dt; if (e.lmark > 0) e.lmark -= dt; if (e.shock > 0) e.shock -= dt; if (e.rcd > 0) e.rcd -= dt;
      if (e.stunT > 0) { e.stunT -= dt; if (Math.random() < 0.2) sparks(e.x, e.y + e.r, e.z, 'fx_spark', 1, 4, 0.25); return; }     // 麻痹：原地不动
      var tx = R.px, ty = R.py, tz = R.pz;
      if (e.podHunter && pod) { tx = pod.x; ty = pod.y; tz = pod.z; }
      var dx = tx - e.x, dy = ty - e.y, dz = tz - e.z, dist = len3(dx, dy, dz) || 1, n = [dx / dist, dy / dist, dz / dist], mv = n;
      if (d.keep && dist < d.keep && !e.podHunter) {
        if (!e.orb) e.orb = Math.random() < 0.5 ? 1 : -1;
        var tg0 = Math.abs(n[1]) > 0.92 ? [1, 0, 0] : nrm(cross([0, 1, 0], n)); mv = nrm([tg0[0] * 0.9 * e.orb - n[0] * 0.3, tg0[1] * 0.9 * e.orb - n[1] * 0.3, tg0[2] * 0.9 * e.orb - n[2] * 0.3]);
      }
      // 移动方向平滑：避免保距、分离、受击等造成的方向逐帧翻转（怪物“颤抖”的主因之一）
      if (e.dv && !(e.lg && e.lg.t >= (d.lunge ? d.lunge.tele : 0))) { var ks = 1 - Math.exp(-dt * 9); mv = [lerp(e.dv[0], mv[0], ks), lerp(e.dv[1], mv[1], ks), lerp(e.dv[2], mv[2], ks)]; }
      e.dv = mv.slice();
      // 冲撞（爬虫、喽啰）：靠近后原地蓄力 0.45~0.5 秒（红色预警线），再沿锁定方向猛冲，冲撞伤害 x1.6
      // 狙击手：远距离停下蓄力 1.4 秒（红色瞄准线先追踪、后锁定），随后射出高速贯穿光矢
      if (d.snipe) {
        var SN = d.snipe; e.sncd = (e.sncd == null ? rand(1.5, SN.cd) : e.sncd) - dt;
        if (!e.sn && e.sncd <= 0 && dist < 75) { e.sn = { t: 0, dir: n.slice(), fired: false }; e.sncd = SN.cd; }
        if (e.sn) {
          e.sn.t += dt; mv = [0, 0, 0];
          if (e.sn.t < SN.tele * 0.75) { var ks2 = Math.min(1, dt * 4); e.sn.dir = nrm([lerp(e.sn.dir[0], n[0], ks2), lerp(e.sn.dir[1], n[1], ks2), lerp(e.sn.dir[2], n[2], ks2)]); }
          else if (e.sn.t >= SN.tele && !e.sn.fired) { e.sn.fired = true; C.sfx('boom'); R.ebullets.push({ x: e.x + e.sn.dir[0] * e.r, y: e.y + e.sn.dir[1] * e.r, z: e.z + e.sn.dir[2] * e.r, vx: e.sn.dir[0] * SN.spd, vy: e.sn.dir[1] * SN.spd, vz: e.sn.dir[2] * SN.spd, dmg: SN.dmg, life: 2, snipe: true }); }
          if (e.sn.t >= SN.tele + 0.3) e.sn = null;
        }
      }
      // 自爆虫：贴近后停下，红圈扩张 0.75 秒，随后自爆（范围伤害，自身死亡）
      if (d.bomb) {
        var BB = d.bomb; if (!e.fz && dist < BB.trig) { e.fz = 0.0001; C.sfx('click'); }
        if (e.fz) {
          e.fz += dt; mv = [0, 0, 0];
          if (e.fz >= BB.fuse) {
            R.novas.push({ x: e.x, y: e.y, z: e.z, r: BB.r, life: 0.4, dur: 0.4, tint: [1.5, 0.6, 0.2], fast: true }); emb(e.x, e.y, e.z, [1.5, 0.6, 0.2], 14, 12, 0.5, 2); C.sfx('boom'); R.shake = Math.max(R.shake, 0.2);
            if (d3(R.px, R.py, R.pz, e.x, e.y, e.z) < (BB.r + 1.5) * (BB.r + 1.5)) hurtPlayer(d.dmg * BB.dmg);
            e.hp = 0.0001; killEnemy(e); return;
          }
        }
      }
      // 幽影刺客：周期性瞬移到玩家背后（先在落点显示紫色圈 0.7 秒），落地后立刻突刺
      if (d.blink) {
        var BL = d.blink; e.bkcd = (e.bkcd == null ? rand(2, BL.cd) : e.bkcd) - dt;
        if (!e.bk && e.bkcd <= 0 && dist > 8 && dist < 60) { var fw0 = fwdOf(R.yaw, 0); e.bk = { t: 0, dest: [R.px - fw0[0] * 11, R.py + rand(-2, 2), R.pz - fw0[2] * 11] }; e.bkcd = BL.cd; }
        if (e.bk) {
          e.bk.t += dt; mv = [0, 0, 0];
          if (e.bk.t >= BL.tele) {
            emb(e.x, e.y, e.z, [0.7, 0.4, 1.4], 8, 8, 0.4, 1.8); e.x = e.bk.dest[0]; e.y = e.bk.dest[1]; e.z = e.bk.dest[2]; emb(e.x, e.y, e.z, [0.7, 0.4, 1.4], 8, 8, 0.4, 1.8);
            var bd = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]); e.lg = { t: 0, dir: bd }; e.lcool = d.lunge ? d.lunge.cd : 5; e.bk = null;
          }
        }
      }
      var lunging = false;
      if (d.lunge) {
        var LG = d.lunge; e.lcool = (e.lcool == null ? rand(0.4, 1.4) : e.lcool) - dt;
        if (!e.lg && e.lcool <= 0 && dist < LG.range && dist > 2.5 && !e.podHunter) { e.lg = { t: 0, dir: n.slice() }; e.lcool = LG.cd; }
        if (e.lg) { e.lg.t += dt; if (e.lg.t < LG.tele) mv = [0, 0, 0]; else if (e.lg.t < LG.tele + LG.dur) { mv = e.lg.dir; lunging = true; } else e.lg = null; }
      }
      var sx = 0, sy = 0, sz = 0;
      near(e.x, e.y, e.z, e.r * 2, function (o) {
        if (o === e || o.d.ore) return;
        var ox = e.x - o.x, oy = e.y - o.y, oz = e.z - o.z, od = len3(ox, oy, oz), min = e.r + o.r;
        if (od < min && od > 0.001) { var k = (min - od) / od; sx += ox * k; sy += oy * k; sz += oz * k; }
      });
      var spd = (lunging ? d.lunge.dash : d.spd) * (e.slow || e.slowT > 0 ? 0.45 : 1) * (affix('swift') ? 1.25 : 1);
      var sk = Math.min(0.5, dt * 14), sl2 = len3(sx, sy, sz); if (sl2 > 1.2) { sx *= 1.2 / sl2; sy *= 1.2 / sl2; sz *= 1.2 / sl2; }
      e.x += (mv[0] * spd + e.kx) * dt + sx * sk; e.y += (mv[1] * spd + e.ky) * dt + sy * sk; e.z += (mv[2] * spd + e.kz) * dt + sz * sk;
      clampBound(e, 20);
      var damp = Math.exp(-dt * 6); e.kx *= damp; e.ky *= damp; e.kz *= damp; e.slow = false;
      var ang = angOf(len3(mv[0], mv[1], mv[2]) > 0.1 ? mv : n), kr = 1 - Math.exp(-dt * 10); e.yaw += wrapA(ang[0] - e.yaw) * (d.guard ? 1 - Math.exp(-dt * 2.2) : kr); e.pitch += ((d.ship ? ang[1] : clamp(ang[1], -30, 30)) - e.pitch) * kr; e.contact -= dt;
      var pd = Math.sqrt(d3(R.px, R.py, R.pz, e.x, e.y, e.z));
      if (pd < e.r + 2.3 && e.contact <= 0) { hurtPlayer(d.dmg * (lunging ? 1.6 : 1)); e.contact = 0.8; }
      if (e.podHunter && pod && dist < e.r + 3 && e.contact <= 0) { pod.pod.hp -= d.dmg; e.contact = 0.8; }
      if (d.boss) { var ph0 = e.hp / e.max > 0.66 ? 1 : e.hp / e.max > 0.33 ? 2 : 3; if (!e.ph) e.ph = 1; if (ph0 > e.ph) { e.ph = ph0; bossPhase(e); } }
      var pm = e.ph || 1;
      if (d.slam) {
        var SL = d.slam; e.scd = (e.scd == null ? SL.cd * 0.6 : e.scd) - dt;
        if (!e.sl && e.scd <= 0 && dist < SL.r * 1.9) { e.sl = { t: 0 }; e.scd = SL.cd * (d.boss && pm >= 3 ? 0.7 : 1); }
        if (e.sl) {
          e.sl.t += dt;
          if (e.sl.t >= SL.tele) {
            e.sl = null; R.shake = Math.max(R.shake, 0.5); C.sfx('boom');
            R.novas.push({ x: e.x, y: e.y - e.r * 0.5, z: e.z, r: SL.r, life: 0.5, dur: 0.5, tint: [1.5, 0.6, 0.2], fast: true }); emb(e.x, e.y - e.r * 0.5, e.z, [1.4, 0.6, 0.25], 20, 14, 0.6, 2.2, 3);
            if (d3(R.px, R.py, R.pz, e.x, e.y, e.z) < (SL.r + 1.5) * (SL.r + 1.5)) hurtPlayer(d.dmg * SL.dmg);
            if (SL.ring) { var rb = basis([0, 1, 0]); for (var rk = 0; rk < 14 + 4 * (pm - 1); rk++) { var ra = rk / (14 + 4 * (pm - 1)) * Math.PI * 2; R.ebullets.push({ x: e.x, y: e.y, z: e.z, vx: Math.cos(ra) * 13, vy: 0, vz: Math.sin(ra) * 13, dmg: d.dmg * 0.5, life: 4 }); } }
          }
        }
      }
      if (e.bq > 0) { e.bt -= dt; if (e.bt <= 0) { e.bq--; e.bt = 0.13; var ba2 = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]); R.ebullets.push({ x: e.x + ba2[0] * e.r * 0.9, y: e.y + ba2[1] * e.r * 0.9, z: e.z + ba2[2] * e.r * 0.9, vx: ba2[0] * d.shoot.spd, vy: ba2[1] * d.shoot.spd, vz: ba2[2] * d.shoot.spd, dmg: d.shoot.dmg, life: 4 }); } }
      if (d.laser && pm >= d.laser.from && pd < 75) {
        e.lcd = (e.lcd == null ? d.laser.every * 0.55 : e.lcd) - dt;
        if (!e.laser && e.lcd <= 0) { e.lcd = d.laser.every * (pm >= 3 ? 0.7 : 1); e.laser = { t: 0, charge: 1.2, fire: 0.45, dir: nrm([R.px - e.x, R.py - e.y, R.pz - e.z]), hit: false }; C.sfx('boss'); }
      }
      if (e.laser) {
        var Ls = e.laser; Ls.t += dt;
        if (Ls.t < Ls.charge * 0.7) { var wd = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]), kk3 = Math.min(1, dt * 3); Ls.dir = nrm([lerp(Ls.dir[0], wd[0], kk3), lerp(Ls.dir[1], wd[1], kk3), lerp(Ls.dir[2], wd[2], kk3)]); }   // 前 0.7 段缓慢追踪，随后锁定
        else if (Ls.t >= Ls.charge && !Ls.hit) {
          Ls.hit = true; R.shake = Math.max(R.shake, 0.3);
          var lo = [e.x + Ls.dir[0] * e.r, e.y + Ls.dir[1] * e.r, e.z + Ls.dir[2] * e.r], lw = [R.px - lo[0], R.py - lo[1], R.pz - lo[2]], lt = lw[0] * Ls.dir[0] + lw[1] * Ls.dir[1] + lw[2] * Ls.dir[2];
          if (lt > 0 && lt < 95 && len3(lw[0] - Ls.dir[0] * lt, lw[1] - Ls.dir[1] * lt, lw[2] - Ls.dir[2] * lt) < 2.8) hurtPlayer(d.dmg * 1.5);
        }
        if (Ls.t >= Ls.charge + Ls.fire) e.laser = null;
      }
      if (d.shoot && pd < 60) {
        e.fire -= dt;
        if (e.fire <= 0) {
          e.fire = d.shoot.cd * (d.boss ? [1, 0.82, 0.66][pm - 1] : 1);
          var aim = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]), b2 = basis(aim), k2, sp = d.shoot.spd * (d.boss ? 1 + 0.08 * (pm - 1) : 1), mo0 = [e.x + aim[0] * e.r * 0.9, e.y + aim[1] * e.r * 0.9, e.z + aim[2] * e.r * 0.9];
          sparks(mo0[0], mo0[1], mo0[2], 'fx_spark', 3, 6, 0.2, null, 0.8);
          if (d.shoot.ring) {
            var rn = d.shoot.ring + (d.boss ? 4 * (pm - 1) : 0);
            for (k2 = 0; k2 < rn; k2++) { var a = k2 / rn * Math.PI * 2 + R.t, ca = Math.cos(a), sa = Math.sin(a);
              var rv = [b2[0][0] * ca + b2[1][0] * sa, b2[0][1] * ca + b2[1][1] * sa, b2[0][2] * ca + b2[1][2] * sa];
              R.ebullets.push({ x: e.x, y: e.y, z: e.z, vx: rv[0] * sp, vy: rv[1] * sp, vz: rv[2] * sp, dmg: d.shoot.dmg, life: 5 }); }
            var na = d.shoot.aim || 0;
            for (k2 = 0; k2 < na; k2++) { var o = (k2 - (na - 1) / 2) * 0.12; R.ebullets.push({ x: mo0[0], y: mo0[1], z: mo0[2], vx: (aim[0] + b2[0][0] * o) * sp * 1.4, vy: (aim[1] + b2[0][1] * o) * sp * 1.4, vz: (aim[2] + b2[0][2] * o) * sp * 1.4, dmg: d.shoot.dmg, life: 5 }); }
          } else {
            e.cnt = (e.cnt || 0) + 1;
            if (d.shoot.burst) { e.bq = d.shoot.burst - 1; e.bt = 0.13; }
            var nn = d.shoot.n + (d.boss ? 2 * (pm - 1) : 0);
            if (d.shoot.big && e.cnt % 2 === 0) { nn = 0; R.ebullets.push({ x: mo0[0], y: mo0[1], z: mo0[2], vx: aim[0] * sp * 0.55, vy: aim[1] * sp * 0.55, vz: aim[2] * sp * 0.55, dmg: d.shoot.dmg * 2.4, life: 6, big: true }); }
            for (k2 = 0; k2 < nn; k2++) { var off = nn > 1 ? Math.tan((k2 / (nn - 1) - 0.5) * (d.shoot.spread + (d.boss ? 12 * (pm - 1) : 0)) * DEG) : 0;
              var v = nrm([aim[0] + b2[0][0] * off, aim[1] + b2[0][1] * off, aim[2] + b2[0][2] * off]);
              R.ebullets.push({ x: mo0[0], y: mo0[1], z: mo0[2], vx: v[0] * sp, vy: v[1] * sp, vz: v[2] * sp, dmg: d.shoot.dmg, life: 4 }); }
          }
        }
      }
      if (e.summon) { e.sumT = (e.sumT || e.summon) - dt; if (e.sumT <= 0) { e.sumT = e.summon * [1, 0.8, 0.6][pm - 1]; for (k2 = 0; k2 < 8; k2++) { var p = spherePos(e, e.r + 4); spawnEnemy('crawler', p[0], p[1], p[2]); } } }
      if (!d.elite && !d.boss && !e.node && pd > 100) { var q = aheadPos(); e.x = q[0]; e.y = q[1]; e.z = q[2]; }
    });
    R.enemies = R.enemies.filter(function (e) { return e.hp > 0; });
  }

  // ------------------------------------------------------------------ 主武器（由机甲决定）
  function mainStats() {
    var l = lv('main'), mul = (1 + 0.2 * Math.min(l - 1, 1) + 0.2 * (l >= 4 ? 1 : 0) + 0.3 * (l >= 6 ? 1 : 0)) * R.mMul;
    var rate = 1 + 0.06 * (l >= 2) + 0.06 * (l >= 4) + 0.1 * (l >= 6), extra = (l >= 3 ? 1 : 0) + (l >= 5 ? 1 : 0);
    return { mul: mul, rate: rate, extra: extra };
  }
  function shot(o, dir, spd, props) { var s = { x: o.x, y: o.y, z: o.z, vx: dir[0] * spd, vy: dir[1] * spd, vz: dir[2] * spd, hit: [] }; for (var k in props) s[k] = props[k]; R.shots.push(s); return s; }
  function fan(dir, n, spread, i) { if (n <= 1) return dir; var b = basis(dir), o = Math.tan((i / (n - 1) - 0.5) * spread); return nrm([dir[0] + b[0][0] * o, dir[1] + b[0][1] * o, dir[2] + b[0][2] * o]); }
  function fireMain(dt) {
    // v19 武器系统：系列（laser / shotgun / heal / twin / lob / prism）决定弹道，型号（wd）调整射速、伤害、穿透与特效
    var W = R.wpn, wd = W.def, w = wd.fam, st = mainStats(), cm = cdMult() * (1 - Math.min(0.4, R.st.rate)), po = R.pose, wr = wd.rate || 1, mul = st.mul * W.mul;
    R.timers.main -= dt;
    if (R.timers.main > 0) return;
    var range = w === 'shotgun' ? (wd.range || 32) : 42, t = target(R.px, R.py, R.pz, range);
    R.target = t && !t.d.ore ? t : R.target && R.target.hp > 0 && dd(R.target, P()) < 3600 ? R.target : null;
    if (!t) return;
    if (po.ok && po.fxm.fire[0] !== 'P' && po.aimK < 0.55 && (po.noAim = (po.noAim || 0) + dt) < 0.6) { R.timers.main = 0.04; return; }
    po.noAim = 0;
    C.sfx('shoot');
    var i, n, o, dir, kk = po.ok ? po.fxm.kick : 0, fs = W.native ? null : (po.ok ? po.fxm.fire[0] : 'R'), pr = wd.pierce || 0;
    function side(s0) { return fs || s0; }      // 非本命武器：从机甲自己的开火位置射出
    function toT(q) { return nrm([t.x - q.x, t.y - q.y, t.z - q.z]); }
    function props(b) {
      if (wd.size) b.size = (b.size || (b.model === 'fx_spark' ? 3 : 2.4)) * wd.size;
      if (wd.burn) b.burn = wd.burn; if (wd.blastR) b.blastR = wd.blastR * blast(); if (wd.tint) b.tint = wd.tint;
      if (wd.crit || R.trait.crit) b.crit = (wd.crit || 0) + (R.trait.crit || 0); if (R.trait.close) b.close = R.trait.close;
      return b;
    }
    if (w === 'laser') {
      R.timers.main = 0.34 / st.rate / wr * cm; n = 1 + st.extra + (wd.extra || 0); o = mz(side('R'), 0); dir = toT(o);
      for (i = 0; i < n; i++) shot(o, fan(dir, n, 0.24, i), 80, props({ dmg: 3.4 * mul, pierce: Math.max(0, 2 + pr), life: 0.7, model: 'fx_laser_player' }));
      muzzleFx(o, dir, wd.size || 1); kick(side('R'), 1, 0.4 * kk);
      if (!wd.single) later(0.08, function () {      // 双发点射：第二发稍后从枪口再射出，节奏更像连续开火
        if (!R || R.over) return; var o2 = mz(side('R'), 0), tt = t.hp > 0 ? t : null, d2 = tt ? nrm([tt.x - o2.x, tt.y - o2.y, tt.z - o2.z]) : dir;
        for (var j = 0; j < n; j++) shot(o2, fan(d2, n, 0.24, j), 80, props({ dmg: 3.4 * mul, pierce: Math.max(0, 2 + pr), life: 0.7, model: 'fx_laser_player' })); muzzleFx(o2, d2, 0.8); kick(side('R'), 0.8, 0.2 * kk);
      });
    }
    else if (w === 'shotgun') {
      R.timers.main = 0.5 / st.rate / wr * cm; n = Math.max(3, Math.round((6 + st.extra * 2) * (wd.count || 1))); var cen = mz(side('L'), 1); dir = toT(cen);
      for (var bi = 0; bi < 3; bi++) (function (bi) {   // 三根炮管依次点火（间隔 0.05 秒），每根打出 n/3 发
        later(bi * 0.05, function () {
          if (!R || R.over) return; var ob = mz(side('L'), bi), tt = t.hp > 0 ? t : null, db = tt ? nrm([tt.x - ob.x, tt.y - ob.y, tt.z - ob.z]) : dir, bb = basis(db), per = Math.ceil(n / 3);
          for (var q = 0; q < per; q++) { var dv = fan(db, per, 0.24, q), jj = rand(-0.07, 0.07); dv = nrm([dv[0] + bb[1][0] * jj, dv[1] + bb[1][1] * jj, dv[2] + bb[1][2] * jj]); shot(ob, dv, 72, props({ dmg: 13 * mul, pierce: Math.max(0, 1 + pr), life: wd.range ? 0.34 : 0.45, kb: 3 * (wd.kb || 1), model: 'fx_spark' })); }
          muzzleFx(ob, db, 1.2); kick(side('L'), 0.7, 0.45 * kk);
        });
      })(bi);
      R.shake = Math.max(R.shake, 0.06);
    }
    else if (w === 'heal') {
      R.timers.main = 0.32 / st.rate / wr * cm; n = 1 + st.extra + (wd.extra || 0); o = mz(side('R'), 0); dir = toT(o);
      var hl = 0.5 * (wd.heal === undefined ? 1 : wd.heal) * (1 + (R.trait.heal || 0));
      for (i = 0; i < n; i++) R.missiles.push({ x: o.x, y: o.y, z: o.z, dir: nrm([dir[0] + rand(-0.6, 0.6), dir[1] + rand(-0.2, 0.6), dir[2] + rand(-0.6, 0.6)]), spd: 28, target: t, dmg: 14 * mul, splash: (wd.splash || 0) * blast(), life: 2.5, heal: hl, model: 'fx_spark_teal', size: 4 });
      muzzleFx(o, dir, 0.9); kick(side('R'), 1, 0.2 * kk);
    }
    else if (w === 'twin') {
      R.timers.main = 0.32 / st.rate / wr * cm; n = 2 + st.extra + (wd.extra || 0);
      for (i = 0; i < n; i++) {
        var sd = fs ? fs : (i + po.alt) % 2 ? 'L' : 'R'; o = mz(sd, fs ? i + po.alt : 0); dir = toT(o);
        if (wd.jitter) { var jb = basis(dir), jx = rand(-wd.jitter, wd.jitter), jy = rand(-wd.jitter, wd.jitter); dir = nrm([dir[0] + jb[0][0] * jx + jb[1][0] * jy, dir[1] + jb[0][1] * jx + jb[1][1] * jy, dir[2] + jb[0][2] * jx + jb[1][2] * jy]); }
        shot(o, dir, 75, props({ dmg: 8.6 * mul, pierce: Math.max(0, 2 + pr), life: 0.7, model: 'fx_laser_player' })); muzzleFx(o, dir, 0.7); kick(sd, 0.8, 0.15 * kk);
      }
      po.alt++;
    }
    else if (w === 'prism') {
      R.timers.main = 0.34 / st.rate / wr * cm; n = (wd.single ? 1 : 3) + st.extra + (wd.extra || 0); o = mz(side('R'), 0); dir = toT(o);
      for (i = 0; i < n; i++) shot(o, fan(dir, n, 0.36 * (wd.spread || 1), i), 74, props({ dmg: 3.9 * mul, pierce: Math.max(0, 2 + pr), life: 0.7, model: 'fx_white_bolt', tint: [0.75, 0.35, 1.3], size: 2.8 }));
      muzzleFx(o, dir, 1.2); kick(side('R'), 1, 0.4 * kk);
    }
    else if (w === 'lob') {
      R.timers.main = 0.7 / st.rate / wr * cm; n = 1 + st.extra + (wd.extra || 0);
      for (i = 0; i < n; i++) {
        o = mz(side('P'), po.podAlt++); dir = toT(o);
        R.missiles.push({ x: o.x, y: o.y, z: o.z, dir: nrm([dir[0] + rand(-0.5, 0.5), dir[1] + 0.6, dir[2] + rand(-0.5, 0.5)]), spd: 32, target: t, dmg: 12 * mul, splash: 3 * blast() * (wd.splash || 1), slowR: wd.slow ? 3 * blast() * (wd.splash || 1) * 1.3 : 0, slowT: wd.slow || 0, life: 3, model: 'fx_missile', size: 2.2 * (wd.size || 1), tint: wd.tint || null });
        sparks(o.x, o.y, o.z, 'fx_spark', 3, 7, 0.4, null, 0.8);
      }
      kick(null, 0, 0.8 * kk); R.shake = Math.max(R.shake, 0.05);
    }
  }
  // ------------------------------------------------------------------ 武器系统（v19）：装备读取 / 副武器飞弹 / 氮气模块 / 机甲特性
  function initArms() {
    var lo = C.loadout(R.mech), wd = C.weapon(lo.main), sd = lo.sub ? C.subDef(lo.sub) : null, it = sd ? C.armory().subs[sd.id] : null;
    R.trait = C.MECH_TRAIT[R.mech] || {};
    R.wpn = { def: wd, lv: C.armLv('weapons', wd.id), native: wd.fam === M().weapon.type };
    R.wpn.mul = (wd.dmg || 1) * C.wLvMult(R.wpn.lv) * (R.wpn.native ? 1 + C.NATIVE_BONUS : 1) * (1 + (R.trait.main || 0));
    var nd = C.nitroDef(lo.nitro), nl = C.armLv('nitros', nd.id) || 1;
    R.nit = { def: nd, lv: nl, st: Object.assign({}, nd, { name: nd.n, dist: nd.dist * (1 + 0.05 * (nl - 1)), cd: nd.cd * (1 - 0.06 * (nl - 1)), ram: nd.ram ? nd.ram * (R.trait.ram || 1) : 0 }) };
    R.sub = sd && it ? { def: sd, lv: it.lv || 1, ammo: Math.min(it.stock || 0, C.subCap(R.mech)), cap: C.subCap(R.mech), cd: 2, used: 0, gained: 0, flash: 0, autoT: 0 } : null;
  }
  function inR(x, y, z, r, fn) { near(x, y, z, r + 3, function (e) { if (e.hp > 0 && !e.d.ore && d3(x, y, z, e.x, e.y, e.z) < (r + e.r) * (r + e.r)) fn(e); }); }
  function subCdMax() { var s = R.sub; return s.def.cd * cdMult() * (1 - (R.trait.subCd || 0)) * (s.lv >= 5 ? 0.8 : 1); }
  function subCount() { var s = R.sub, d = s.def, b = s.lv >= 3 ? 1 : 0; return d.n0 + (d.id === 'swarm' ? 3 * b : d.id === 'cluster' ? 2 * b : (d.id === 'cryo' || d.id === 'emp') ? b : 0); }
  function subDmg() { var s = R.sub; return s.def.dmg * (1 + 0.15 * (s.lv - 1)) * (1 + (R.trait.sub || 0)) * R.mMul; }
  function subBlast() { var s = R.sub; return blast() * (1 + (R.trait.blast || 0)) * (s && s.lv >= 3 && (s.def.id === 'heavy' || s.def.id === 'gravity') ? 1.15 : 1); }
  function enemiesNear(r) { var p = P(), r2 = r * r; return R.enemies.filter(function (e) { return e.hp > 0 && !e.d.ore && dd(p, e) < r2; }); }
  function densest(list) { var best = list[0], bn = -1; list.slice(0, 24).forEach(function (e) { var c = 0; list.forEach(function (o) { if (dd(e, o) < 64) c++; }); if (c > bn) { bn = c; best = e; } }); return best; }
  function launchSub(d, t, i, dmg, size, tint, spd) {
    var o = shoulderPt(i), up = nrm([rand(-0.7, 0.7), 1, rand(-0.7, 0.7)]);
    R.missiles.push({ x: o.x, y: o.y, z: o.z, dir: up, spd: spd, target: t, dmg: dmg, splash: 0, life: 4, model: 'fx_missile', size: size, tint: tint, sub: d });
    sparks(o.x, o.y, o.z, 'fx_spark', 2, 7, 0.3, null, 0.7);
  }
  // 发射副武器：manual = 玩家点按钮（没弹药 / 没目标时给提示）
  function fireSub(manual) {
    var S0 = R && R.sub; if (!S0 || paused || R.over) return false;
    if (S0.cd > 0) return false;
    if (S0.ammo <= 0) { if (manual) A.toast('副武器弹药用完了：击败精英会掉弹药箱，升级时也可以补给'); return false; }
    var list = enemiesNear(60); if (!list.length) { if (manual) A.toast('附近没有目标'); return false; }
    var p = P(); list.sort(function (a, b) { return dd(a, p) - dd(b, p); });
    var d = S0.def, n = subCount(), dmg = subDmg(), tint = lin(d.color), t0;
    S0.ammo--; S0.used++; S0.cd = subCdMax(); S0.flash = 0.4; C.sfx('skill'); R.shake = Math.max(R.shake, 0.1);
    if (R.tutorial) R.tutorial.event('sub');
    if (d.id === 'heavy') {
      t0 = list.filter(function (e) { return e.d.boss; })[0] || list.filter(function (e) { return e.d.elite; })[0] || list.slice().sort(function (a, b) { return b.hp - a.hp; })[0];
      launchSub(d, t0, 0, dmg, 3.4, tint, 18);
    } else if (d.id === 'cluster') {
      t0 = densest(list);
      R.missiles.push(podLaunch({ fall: true, x: t0.x, y: t0.y + 30, z: t0.z, tx: t0.x, ty: t0.y, tz: t0.z, dmg: dmg, life: 6, model: 'fx_missile', size: 3.2, tint: tint, sub: d, n: n }, 0, 0.03));
    } else if (d.id === 'gravity') launchSub(d, densest(list), 0, dmg, 3, tint, 22);
    else { var k = Math.min(list.length, Math.max(1, Math.ceil(n / 2))); for (var i = 0; i < n; i++) launchSub(d, list[i % k], i, dmg, d.id === 'swarm' ? 1.4 : 2.2, tint, 24); }
    return true;
  }
  function subImpact(m, t) {
    var d = m.sub, x = m.fall ? m.tx : m.x, y = m.fall ? m.ty : m.y, z = m.fall ? m.tz : m.z, br = subBlast(), tint = m.tint;
    if (d.id === 'swarm') explode(x, y, z, d.r * br, m.dmg);
    else if (d.id === 'heavy') {
      if (t && t.hp > 0) hurtEnemy(t, m.dmg * 0.5 * ((t.d.elite || t.d.boss) ? 1.5 : 1), 0, 0, 0, false, 0.2);
      explode(x, y, z, d.r * br, m.dmg * 0.6); ringBurst(x, y, z, d.r * br * 1.3, tint, 0.45); R.shake = Math.max(R.shake, 0.35); C.sfx('boom');
    } else if (d.id === 'cluster') {
      explode(x, y, z, 5 * br, m.dmg * d.main / d.dmg); C.sfx('boom'); R.shake = Math.max(R.shake, 0.25);
      var cn = m.n || 6;
      for (var k = 0; k < cn; k++) (function (k) {
        var a = k / cn * Math.PI * 2, rr = rand(3, 7) * br, bx = x + Math.cos(a) * rr, bz = z + Math.sin(a) * rr, by = y + rand(-2, 2);
        later(0.1 + k * 0.06, function () { if (!R || R.over) return; explode(bx, by, bz, d.r * br, m.dmg); inR(bx, by, bz, d.r * br, function (e) { e.burn = { dps: m.dmg * 0.15, t: 2 }; }); });
      })(k);
    } else if (d.id === 'cryo') {
      explode(x, y, z, d.r * br, m.dmg); ringBurst(x, y, z, d.r * br, tint, 0.35);
      inR(x, y, z, d.r * br, function (e) { e.slowT = 3; });
    } else if (d.id === 'emp') {
      var cur = t && t.hp > 0 ? t : target(x, y, z, 12), done = [];
      if (cur) { hurtEnemy(cur, m.dmg, 0, 0, 0); done.push(cur); cur.shock = 2; if (!cur.d.boss) cur.stunT = cur.d.elite ? 0.3 : 0.7; }
      for (var c = 0; cur && c < d.chain; c++) {
        var nx = null, nd = 18 * 18, from = cur;
        R.enemies.forEach(function (o) { if (o.hp > 0 && done.indexOf(o) < 0 && !o.d.ore) { var dq = dd(from, o); if (dq < nd) { nd = dq; nx = o; } } });
        if (!nx) break;
        var dl = Math.sqrt(nd) || 1; R.beams.push({ x: cur.x, y: cur.y, z: cur.z, d: [(nx.x - cur.x) / dl, (nx.y - cur.y) / dl, (nx.z - cur.z) / dl], len: dl, life: 0.16, tint: tint });
        done.push(nx); hurtEnemy(nx, m.dmg * 0.7, 0, 0, 0); nx.shock = 2; if (!nx.d.boss) nx.stunT = nx.d.elite ? 0.3 : 0.7; cur = nx;
      }
      emb(x, y, z, tint, 10, 12, 0.4, 1.6, 2);
    } else if (d.id === 'gravity') {
      R.wells.push({ x: x, y: y, z: z, r: d.r * br, life: 2.5, dmg: m.dmg * 0.12, tick: 0, implode: { r: 9 * br, dmg: m.dmg, tint: tint } });
      ringBurst(x, y, z, d.r * br, tint, 0.5);
      inR(x, y, z, d.r * br, function (e) { e.dmark = 2.5; });
    }
    if (R.trait.subHeal) R.hull = Math.min(hullMax(), R.hull + R.trait.subHeal);
  }
  function updateSub(dt) {
    var S0 = R.sub; if (!S0) return;
    if (S0.cd > 0) S0.cd -= dt; if (S0.flash > 0) S0.flash -= dt;
    S0.autoT -= dt;
    if (S0.cd > 0 || S0.ammo <= 0 || !C.save.settings.subAuto || S0.autoT > 0) return;
    S0.autoT = 0.25;   // 自动发射：每 0.25 秒检查一次，敌群密集（40 米内不少于 6 个）或有精英 / 首领时才发射，弹药用在刀刃上
    var list = enemiesNear(40), big = list.some(function (e) { return e.d.elite || e.d.boss; });
    if (list.length >= 6 || big) fireSub(false);
  }
  function nova(c, r, dmg, color, tint) {
    R.novas.push({ x: c.x, y: c.y, z: c.z, r: r, life: 0.45, color: color || '#57B8FF', tint: tint });
    if (dmg) near(c.x, c.y, c.z, r + 3, function (e) { var d = Math.sqrt(dd(c, e)) || 1; if (d < r + e.r) { var k = knock(e, c, 22); hurtEnemy(e, dmg, k[0], k[1], k[2]); } });
  }
  function explode(x, y, z, r, dmg) {
    sparks(x, y, z, 'fx_spark', 4, 14, 0.5, null, 0.7);
    emb(x, y, z, EMBER, Math.min(22, 6 + Math.round(r * 3)), 7 + r * 2, 0.5, 1.5 + r * 0.2);
    if (R.parts.length < 230) R.parts.push({ model: 'fx_white', x: x, y: y, z: z, vx: 0, vy: 0, vz: 0, life: 0.14, max: 0.14, size: 2 + r * 1.2, tint: null, noGrav: true });
    if (r >= 3) ringBurst(x, y, z, r * 1.1, EMBER, 0.3);
    near(x, y, z, r + 3, function (e) { if (d3(x, y, z, e.x, e.y, e.z) < (r + e.r) * (r + e.r)) hurtEnemy(e, dmg, 0, 0, 0); });
  }
  function updateShots(dt) {
    R.shots = R.shots.filter(function (s) {
      s.life -= dt; s.x += s.vx * dt; s.y += s.vy * dt; s.z += s.vz * dt;
      if ((s.model === 'fx_laser_player' || s.model === 'fx_white_bolt') && Math.random() < 0.7) trail(s.x - s.vx * 0.02, s.y - s.vy * 0.02, s.z - s.vz * 0.02, s.tint || [0.36, 0.95, 0.86], 0.9, 0.16);
      var dead = false;
      near(s.x, s.y, s.z, 4, function (e) {
        if (s.hit.indexOf(e) >= 0) return;
        if (d3(s.x, s.y, s.z, e.x, e.y, e.z) < (e.r + 0.6) * (e.r + 0.6)) {
          if (s.blastR) explode(s.x, s.y, s.z, s.blastR, s.dmg * 0.8);
          if (s.md) modHit(s.md, e, s.dmg, { x: s.x - s.vx * 0.05, y: s.y - s.vy * 0.05, z: s.z - s.vz * 0.05 }, 4);
          else { hurtEnemy(e, s.dmg * (s.close && dd(e, P()) < 225 ? 1 + s.close : 1), s.vx * 0.04 * (s.kb || 1), s.vy * 0.04 * (s.kb || 1), s.vz * 0.04 * (s.kb || 1), false, s.crit); if (s.burn && e.hp > 0) e.burn = { dps: s.dmg * s.burn, t: 2 }; }
          s.hit.push(e); sparks(s.x, s.y, s.z, 'fx_spark_teal', 2, 8, 0.3);
          if (s.pierce-- <= 0) { dead = true; return false; }
        }
      });
      return !dead && s.life > 0;
    });
    R.missiles = R.missiles.filter(function (m) {
      m.life -= dt;
      if (m.fall && m.launch) {
        var L = m.launch; m.life += dt;
        if (L.delay > 0) { L.delay -= dt; m.x = L.x; m.y = L.y; m.z = L.z; return true; }
        m.hide = false; L.t += dt; m.x += L.dir[0] * 55 * dt; m.y += L.dir[1] * 55 * dt; m.z += L.dir[2] * 55 * dt; if (Math.random() < 0.6) sparks(m.x, m.y, m.z, 'fx_spark', 1, 3, 0.3);
        if (L.t > 0.42) { m.launch = null; m.x = m.tx; m.y = m.ty + m.fh; m.z = m.tz; }
        return true;
      }
      if (m.fall) {
        m.y -= dt * 60; trail(m.x, m.y + 1.2, m.z, m.meteor ? [0.75, 0.35, 1.3] : EMBER, m.meteor ? 3.2 : 1.4, m.meteor ? 0.5 : 0.3); if (m.meteor) trail(m.x, m.y + 2.6, m.z, [1.5, 0.8, 0.3], 2.2, 0.4);
        if (m.y <= m.ty + 0.5) {
          if (m.sub) { subImpact(m, null); return false; }
          explode(m.tx, m.ty, m.tz, m.splash, m.dmg);
          if (m.meteor) { ringBurst(m.tx, m.ty, m.tz, m.splash * 1.4, [0.8, 0.4, 1.4], 0.55); emb(m.tx, m.ty, m.tz, [0.8, 0.4, 1.4], 18, 16, 0.8, 2.4, 6); R.shake = 0.7; C.sfx('boom'); sparks(m.tx, m.ty, m.tz, 'fx_spark_teal', 40, 26, 1); for (var k = 0; k < 6; k++) { var d = randDir(); shot({ x: m.tx, y: m.ty, z: m.tz }, d, 55, { dmg: m.dmg * 0.1, pierce: 2, life: 0.6, model: 'fx_white_bolt', tint: [0.75, 0.35, 1.3], size: 3 }); } }
          if (m.slowR) near(m.tx, m.ty, m.tz, m.slowR, function (e) { e.slowT = 3; });
          return false;
        }
        return true;
      }
      if (!m.target || m.target.hp <= 0) m.target = target(m.x, m.y, m.z, 45);
      if (m.target) { var want = nrm([m.target.x - m.x, m.target.y - m.y, m.target.z - m.z]), k2 = Math.min(1, dt * 6); m.dir = nrm([lerp(m.dir[0], want[0], k2), lerp(m.dir[1], want[1], k2), lerp(m.dir[2], want[2], k2)]); }
      m.spd = Math.min(55, m.spd + dt * 60);
      m.x += m.dir[0] * m.spd * dt; m.y += m.dir[1] * m.spd * dt; m.z += m.dir[2] * m.spd * dt;
      if (m.model === 'fx_missile') trail(m.x - m.dir[0] * 0.8, m.y - m.dir[1] * 0.8, m.z - m.dir[2] * 0.8, EMBER, 1.5, 0.38); else if (m.tint) trail(m.x - m.dir[0] * 0.6, m.y - m.dir[1] * 0.6, m.z - m.dir[2] * 0.6, m.tint, 1.2, 0.3);
      if (m.target && dd(m, m.target) < (m.target.r + 1) * (m.target.r + 1)) {
        if (m.sub) subImpact(m, m.target); else if (m.md) modHit(m.md, m.target, m.dmg, m, 6); else if (m.splash) explode(m.x, m.y, m.z, m.splash, m.dmg); else hurtEnemy(m.target, m.dmg, 0, 0, 0);
        if (m.slowR) inR(m.x, m.y, m.z, m.slowR, function (e) { e.slowT = Math.max(e.slowT || 0, m.slowT || 2); });
        if (m.heal) R.hull = Math.min(hullMax(), R.hull + m.heal);
        return false;
      }
      if (m.life <= 0) { if (m.sub) subImpact(m, null); else if (m.splash) explode(m.x, m.y, m.z, m.splash, m.dmg * 0.5); return false; }
      return true;
    });
    R.ebullets = R.ebullets.filter(function (b) {
      b.life -= dt; b.x += b.vx * dt; b.y += b.vy * dt; b.z += b.vz * dt; if (Math.random() < 0.5) trail(b.x, b.y, b.z, [1.3, 0.2, 0.25], 1.3, 0.25);
      if (d3(b.x, b.y, b.z, R.px, R.py, R.pz) < (b.big ? 3.3 : 2.3) * (b.big ? 3.3 : 2.3)) { hurtPlayer(b.dmg); return false; }
      return b.life > 0;
    });
  }

  // ------------------------------------------------------------------ 技能模块（工坊研发、出击时装备，最多 3 个）
  function lin(hex) { var h = hex.replace('#', ''); return [0, 2, 4].map(function (i) { return Math.pow(parseInt(h.substr(i, 2), 16) / 255, 2.2) * 1.15; }); }
  function initMods() {
    var s = C.save;
    // 只有在工坊抽到并装备的卡牌才会出现：第 1 张开局自带，其余在局内升级时作为“获得新技能”选项出现
    // 不再装备：拥有的全部卡牌洗成本局卡组，开局随机带 1 张，其余在局内升级时随机出现，每局组合都不同
    var deck = C.modDeck();
    for (var k = deck.length - 1; k > 0; k--) { var j = Math.floor(Math.random() * (k + 1)), t = deck[k]; deck[k] = deck[j]; deck[j] = t; }
    R.mods = []; R.modPool = deck;
    if (R.modPool.length) addMod(R.modPool.shift());
  }
  C.RUN_MOD_MAX = 6;
  function addMod(m) { R.mods.push({ m: m, lv: 1, t: 0.8 + R.mods.length * 0.4, i: R.mods.length, tint: lin(m.color) }); }
  function has(md, k) { if (md.m.tags.indexOf(k) >= 0) return true; var g = C.goldTag(md.m); if (g && g.tag === k) return true; var ev = md.evo && C.evoOf(md.m); return !!(ev && ev.tags.indexOf(k) >= 0); }
  function modStat(md) {
    var F = Object.assign({}, C.modForm(md.m.form)), l = md.lv, ev = md.evo ? C.evoOf(md.m) : null; F.k = F.b || F.k;
    return { F: F, dmg: F.dmg * C.MOD_RARITY_MULT[md.m.tier] * C.modLvMult(md.m) * (1 + 0.25 * (l - 1)) * (1 + R.st.skill) * (md.m.elem === 'dark' ? 1.15 : 1) * (ev ? 1.5 : 1),
      cd: F.cd * (1 - 0.08 * (l - 1)) * cdMult() * (R.st.traits.overclock ? 0.85 : 1) * (ev ? 0.88 : 1),
      count: F.count + (l >= 3 ? 1 : 0) + (l >= 5 ? 1 : 0) + (md.m.tier === 3 ? 1 : 0) + (ev ? ev.count : 0), size: (has(md, 'big') ? 1.4 : 1) * (ev && ev.size ? ev.size : 1), pierce: has(md, 'pierce') ? 2 : 0 };
  }
  // 元素反应：对已带有特定状态的敌人命中对应元素，触发额外效果（每个敌人 0.5 秒内最多触发一次）
  //   雷 + 冰冻 = 碎冰（范围伤害）；火 + 毒 = 爆燃（范围爆炸）；火 + 冰冻 = 融蚀（额外伤害）；雷 + 毒 = 麻痹（定身）；光 + 暗 = 湮灭（暴击伤害，双向）
  function react(e, md, dmg) {
    var el = md.m.elem, frozen = e.slowT > 0, pois = e.poison && e.poison.t > 0, txt = null, col = null;
    if (e.rcd > 0) return;
    if ((el === 'thunder' && frozen) || (el === 'ice' && e.shock > 0)) {
      txt = '碎冰'; col = '#9DD8FF'; e.slowT = 0; e.shock = 0; ringBurst(e.x, e.y, e.z, 6, [0.6, 0.9, 1.5], 0.3);
      near(e.x, e.y, e.z, 6, function (o) { if (o !== e && o.hp > 0 && !o.d.ore) hurtEnemy(o, dmg * 1.2, 0, 0, 0, true); });
      hurtEnemy(e, dmg * 1.2, 0, 0, 0, true);
    } else if (el === 'fire' && pois) {
      txt = '爆燃'; col = '#FF8A3A'; e.poison = null; ringBurst(e.x, e.y, e.z, 6.5, [1.5, 0.6, 0.2], 0.35); emb(e.x, e.y, e.z, [1.5, 0.6, 0.2], 12, 12, 0.5, 2);
      near(e.x, e.y, e.z, 6.5, function (o) { if (o !== e && o.hp > 0 && !o.d.ore) hurtEnemy(o, dmg * 1.1, 0, 0, 0, true); });
      hurtEnemy(e, dmg * 1.1, 0, 0, 0, true);
    } else if (el === 'fire' && frozen) {
      txt = '融蚀'; col = '#FFB347'; e.slowT = 0; hurtEnemy(e, dmg * 0.9, 0, 0, 0, true); emb(e.x, e.y, e.z, [1.4, 0.8, 0.3], 6, 8, 0.4, 1.6);
    } else if (el === 'thunder' && pois) {
      txt = '麻痹'; col = '#F5E050'; e.poison = null; e.stunT = e.d.boss ? 0.35 : e.d.elite ? 0.8 : 1.4; emb(e.x, e.y, e.z, [1.4, 1.3, 0.3], 8, 8, 0.4, 1.6);
    } else if ((el === 'light' && e.dmark > 0) || (el === 'dark' && e.lmark > 0)) {
      txt = '湮灭'; col = '#E0A0FF'; e.dmark = 0; e.lmark = 0; hurtEnemy(e, dmg * 1.6, 0, 0, 0, true, 1); ringBurst(e.x, e.y, e.z, 4.5, [1.3, 0.5, 1.5], 0.3);
    }
    if (txt) { e.rcd = 0.5; C.sfx('crit'); if (R.nums.length < 70) R.nums.push({ x: e.x, y: e.y + e.r * 1.9, z: e.z, v: txt, crit: true, col: col, life: 1.1 }); }
  }
  function modHit(md, e, dmg, from, kb) {
    if (!e || e.hp <= 0) return;
    react(e, md, dmg);
    if (e.hp <= 0) return;
    var m = md.m, extra = (m.elem === 'light' ? 0.15 : 0) + (has(md, 'crit') ? 0.2 : 0), k = knock(e, from, (kb || 6) * (has(md, 'knock') ? 3 : 1));
    hurtEnemy(e, dmg, k[0], k[1], k[2], false, extra, m.color);
    if (m.elem === 'thunder') e.shock = 2; if (m.elem === 'light') e.lmark = 2.5; if (m.elem === 'dark') e.dmark = 2.5;
    if (m.elem === 'fire') e.burn = { dps: dmg * 0.15, t: 2 };
    if (m.elem === 'poison') e.poison = { dps: dmg * 0.133, t: 3 };
    if (m.elem === 'ice' || has(md, 'slow')) e.slowT = 2;
    if (has(md, 'leech')) R.hull = Math.min(hullMax(), R.hull + dmg * 0.02);
    var chains = (m.elem === 'thunder' ? 1 : 0) + (has(md, 'chain') ? 2 : 0);
    if (chains && !md.busy) {
      md.busy = true; var cur = e, done = [e];
      for (var c = 0; c < chains; c++) {
        var nx = null, nd = 18 * 18;
        R.enemies.forEach(function (o) { if (o.hp > 0 && done.indexOf(o) < 0 && !o.d.ore) { var d = dd(cur, o); if (d < nd) { nd = d; nx = o; } } });
        if (!nx) break;
        var dl = Math.sqrt(nd) || 1; R.beams.push({ x: cur.x, y: cur.y, z: cur.z, d: [(nx.x - cur.x) / dl, (nx.y - cur.y) / dl, (nx.z - cur.z) / dl], len: dl, life: 0.12, tint: md.tint });
        done.push(nx); hurtEnemy(nx, dmg * 0.5, 0, 0, 0, false, extra, m.color); cur = nx;
      }
      md.busy = false;
    }
    if (has(md, 'split') && !md.busy && Math.random() < 0.6) for (var q = 0; q < 2; q++) shot(e, randDir(), 50, { dmg: dmg * 0.35, pierce: 0, life: 0.5, hit: [e], model: 'fx_white', tint: md.tint, size: 2.4 });
  }
  function modArea(md, c, r, dmg, kb) { near(c.x, c.y, c.z, r + 6, function (e) { if (!e.d.ore && dd(c, e) < Math.pow(r + e.r, 2)) modHit(md, e, dmg, c, kb); }); }
  function beamHit(o, dir, len, width, fn) {
    R.enemies.forEach(function (e) {
      if (e.d.ore) return; var rx = e.x - o.x, ry = e.y - o.y, rz = e.z - o.z, t = rx * dir[0] + ry * dir[1] + rz * dir[2]; if (t < 0 || t > len) return;
      var px = rx - dir[0] * t, py = ry - dir[1] * t, pz = rz - dir[2] * t;
      if (px * px + py * py + pz * pz < Math.pow(e.r + width, 2)) { emb(e.x, e.y, e.z, EMBER, 3, 9, 0.3, 1.3); fn(e); }
    });
  }
  function updateModules(dt) {
    var p = P();
    R.mods.forEach(function (md) {
      var st = modStat(md), F = st.F, i, t, mo = mainMz(0), bk = backPt();
      if (F.k === 'orbit') {
        md.ang = (md.ang || 0) + dt * 190; md.orb = []; md.osz = 6 * st.size; var r = 7.5 * st.size;
        for (i = 0; i < st.count; i++) {
          var a = (md.ang + i * 360 / st.count) * DEG, ox = R.px + Math.cos(a) * r, oy = R.py + Math.sin(a * 2) * 1.5, oz = R.pz + Math.sin(a) * r; md.orb.push([ox, oy, oz]);
          near(ox, oy, oz, 4, function (e) { var key = 'oc' + md.i; if (!e.d.ore && d3(ox, oy, oz, e.x, e.y, e.z) < Math.pow(e.r + 1.3 * st.size, 2) && (e[key] || 0) <= R.t) { e[key] = R.t + 0.4; modHit(md, e, st.dmg, p, 8); } });
        }
        return;
      }
      md.t -= dt; if (md.t > 0) return;
      t = target(R.px, R.py, R.pz, 45);
      if (!t && F.k !== 'nova' && F.k !== 'mine') { md.t = 0.3; return; }
      md.t = st.cd;
      var dir = t ? nrm([t.x - R.px, t.y - R.py, t.z - R.pz]) : camBasis.f;
      if (F.k === 'homing') for (i = 0; i < st.count; i++) R.missiles.push({ x: shoulderPt(i).x, y: shoulderPt(i).y, z: shoulderPt(i).z, dir: nrm([(i % 2 ? -1 : 1) * 0.6 + rand(-0.3, 0.3), 1, rand(-0.2, 0.5)]), spd: 22, target: t, dmg: st.dmg, splash: 0, life: 3, model: 'fx_white', size: 3.2 * st.size, tint: md.tint, md: md });
      else if (F.k === 'nova') { R.novas.push({ x: p.x, y: p.y, z: p.z, r: 10 * st.size, life: 0.45, tint: md.tint }); modArea(md, p, 10 * st.size, st.dmg, 22); }
      else if (F.k === 'strike') {
        var pool = R.enemies.filter(function (e) { return !e.d.ore && dd(p, e) < 40 * 40; });
        for (i = 0; i < st.count && pool.length; i++) { var e = pool.splice(Math.floor(Math.random() * pool.length), 1)[0]; R.strikes.push({ x: e.x, y: e.y, z: e.z, life: 0.22, tint: md.tint }); emb(e.x, e.y, e.z, md.tint, 7, 12, 0.4, 1.4, 3); ringBurst(e.x, e.y, e.z, 3.5, md.tint, 0.25); modArea(md, e, 3.5 * st.size, st.dmg, 5); }
      }
      else if (F.k === 'beam') {
        var strong = R.enemies.filter(function (e) { return !e.d.ore && dd(p, e) < 2500; }).sort(function (a, b) { return b.hp - a.hp; })[0] || t, bd = nrm([strong.x - mo.x, strong.y - mo.y, strong.z - mo.z]);
        for (i = 0; i < st.count; i++) { var bv = fan(bd, st.count, 0.25 * (st.count - 1), i); R.beams.push({ x: mo.x, y: mo.y, z: mo.z, d: bv, len: 60, life: 0.2, tint: md.tint }); beamHit(mo, bv, 60, 1.6 * st.size, function (e) { modHit(md, e, st.dmg, mo, 6); }); }
        muzzleFx(mo, bd, 1); kick(R.pose.fxm.fire[0] === 'P' ? null : R.pose.fxm.fire[0], 0.7, 0.2);
      }
      else if (F.k === 'fan') { for (i = 0; i < st.count; i++) shot(mo, fan(nrm([t.x - mo.x, t.y - mo.y, t.z - mo.z]), st.count, 0.7, i), 60, { dmg: st.dmg, pierce: st.pierce, life: 0.7, model: 'fx_white_bolt', tint: md.tint, size: 2.4 * st.size, md: md }); }
      else if (F.k === 'mine') { for (i = 0; i < st.count; i++) R.mines.push({ x: bk.x + rand(-1, 1), y: bk.y + rand(-1, 1), z: bk.z + rand(-1, 1), life: 9, arm: 0.5, r: 5 * st.size, dmg: st.dmg, md: md, tint: md.tint }); }
      else if (F.k === 'boomerang') { for (i = 0; i < st.count; i++) R.booms.push({ x: mo.x, y: mo.y, z: mo.z, d: fan(nrm([t.x - mo.x, t.y - mo.y, t.z - mo.z]), st.count, 0.35 * (st.count - 1), i), dist: 0, out: true, md: md, dmg: st.dmg, size: 3 * st.size, tint: md.tint, id: Math.random() }); }
    });
    R.mines = R.mines.filter(function (mn) {
      mn.life -= dt; mn.arm -= dt;
      if (mn.arm <= 0) { var hit = false; near(mn.x, mn.y, mn.z, mn.r, function (e) { if (!e.d.ore && dd(mn, e) < mn.r * mn.r) hit = true; });
        if (hit) { R.novas.push({ x: mn.x, y: mn.y, z: mn.z, r: mn.r * 1.2, life: 0.4, tint: mn.tint }); modArea(mn.md, mn, mn.r * 1.2, mn.dmg, 14); C.sfx('pop'); return false; } }
      return mn.life > 0;
    });
    R.booms = R.booms.filter(function (b) {
      var sp = 42 * dt;
      if (b.out) { b.x += b.d[0] * sp; b.y += b.d[1] * sp; b.z += b.d[2] * sp; b.dist += sp; if (b.dist > 26) b.out = false; }
      else { var v = [R.px - b.x, R.py - b.y, R.pz - b.z], l = len3(v[0], v[1], v[2]) || 1; if (l < 2.5) return false; b.x += v[0] / l * sp * 1.2; b.y += v[1] / l * sp * 1.2; b.z += v[2] / l * sp * 1.2; }
      near(b.x, b.y, b.z, 4, function (e) { var key = 'bm' + b.id; if (!e.d.ore && dd(b, e) < Math.pow(e.r + 1.5, 2) && (e[key] || 0) <= R.t) { e[key] = R.t + 0.5; modHit(b.md, e, b.dmg, b, 5); } });
      return true;
    });
    R.strikes = R.strikes.filter(function (st) { st.life -= dt; return st.life > 0; });
  }

  // ------------------------------------------------------------------ 机甲技能、闪避、驾驶员支援
  function activeCdMax() { return M().active.cd * cdMult(); }
  function say(who, id) { R.bubbles = R.bubbles.filter(function (b) { return b.who !== who; }); R.bubbles.push({ who: who, text: pick(C.char(id).lines), life: 1.6 }); }
  function moveDir() { var v = [R.vx, R.vy, R.vz], l = len3(v[0], v[1], v[2]); return l > 1 ? [v[0] / l, v[1] / l, v[2] / l] : camBasis.f; }
  function castActive() {
    if (!R || R.activeCd > 0 || R.over || paused) return;
    C.sfx('skill'); if (R.tutorial) R.tutorial.event('skill');
    var id = M().skill, m = R.mMul * (1 + R.st.active), aw = C.mechLv(R.mech) >= C.MECH_AWAKE, t, p = P(), po = R.pose;
    R.activeCd = activeCdMax(); say('pilot', R.pilot);
    if (R.nitroT > 0) { m *= 1.3; R.activeCd *= 0.8; R.nitroT = 0; A.toast('氮气强化：技能伤害 +30%，冷却 -20%'); R.shake = Math.max(R.shake, 0.1); }
    if (id === 'char_xingli') {
      // 星璃：抬枪蓄力 0.2 秒，从步枪枪口射出贯穿光束
      setCast('beam', 0.6); var o0 = mainMz(0); muzzleFx(o0, camBasis.f, 1.6);
      later(0.2, function () {
        var o = mainMz(0), tt = target(o.x, o.y, o.z, 90), bd = tt ? nrm([tt.x - o.x, tt.y - o.y, tt.z - o.z]) : camBasis.f;
        (aw ? [0, 1, 2] : [0]).forEach(function (i, _, arr) { var bv = fan(bd, arr.length, 0.7, i); R.beams.push({ x: o.x, y: o.y, z: o.z, d: bv, len: 90, life: 0.2 }); beamHit(o, bv, 90, 3, function (e) { hurtEnemy(e, 230 * m, bv[0] * 8, bv[1] * 8, bv[2] * 8); }); });
        muzzleFx(o, bd, 2.2); kick('R', 1.4, 1.2); R.shake = 0.3;
      });
    } else if (id === 'char_chiyan') {
      // 赤焰：战斧蓄力后向前冲锋，斧刃划出火星轨迹
      setCast('slash', 0.55);
      t = target(R.px, R.py, R.pz, 40); var dv = len3(R.vx, R.vy, R.vz) > 1 ? moveDir() : t ? nrm([t.x - p.x, t.y - p.y, t.z - p.z]) : camBasis.f;
      R.dash = { t: 0, dur: 0.35, x0: p.x, y0: p.y, z0: p.z, x1: p.x + dv[0] * 32, y1: p.y + dv[1] * 32, z1: p.z + dv[2] * 32, dmg: 140 * m, hit: [], inv: true, d: dv, fire: aw };
    } else if (id === 'char_yuexi') {
      // 月汐：举杖，治疗力场在机甲脚下展开
      setCast('heal', 0.9);
      later(0.25, function () { var q = P(); R.zones.push({ x: q.x, y: q.y, z: q.z, r: 13, life: 6, heal: 0.08, dmg: (aw ? 50 : 25) * m, tick: 0 }); var o = mainMz(0); for (var k = 0; k < 10; k++) R.parts.push({ model: 'fx_spark_teal', x: o.x, y: o.y, z: o.z, vx: rand(-4, 4), vy: rand(2, 9), vz: rand(-4, 4), life: 0.6, max: 0.6, size: 2, noGrav: true }); });
    } else if (id === 'char_hupo') {
      // 琥珀：吊臂把炮台甩到身前，炮台在空中展开后开始射击
      setCast('deploy', 0.6);
      later(0.22, function () { for (var i = 0; i < (aw ? 5 : 3); i++) { var tp = turretSpot(i, aw ? 5 : 3); newTurret(tp, { life: 10, fire: 0, dmg: 3.5 * m, blast: true }); } });
    } else if (id === 'char_shuangling') {
      // 霜铃：双臂上举，肩舱垂直发射导弹群，从目标上空坠落
      setCast('salvo', 0.8);
      t = target(R.px, R.py, R.pz, 60); var c = t || { x: p.x + camBasis.f[0] * 15, y: p.y + camBasis.f[1] * 15, z: p.z + camBasis.f[2] * 15 }, n = aw ? 32 : 16;
      for (var j = 0; j < n; j++) { var tx = c.x + rand(-11, 11), ty = c.y + rand(-6, 6), tz = c.z + rand(-11, 11); R.missiles.push(podLaunch({ fall: true, x: tx, y: ty + 30 + j * 2.5, z: tz, tx: tx, ty: ty, tz: tz, dmg: 15 * m, splash: 5 * blast(), slowR: 6, life: 6, model: 'fx_missile', size: 2.4 }, j, 0.025)); }
    } else if (id === 'starfall') {
      // 夜鸢：长枪指天，星核光柱引下陨星
      setCast('meteor', 0.9);
      t = target(R.px, R.py, R.pz, 60); var s0 = t ? { x: t.x, y: t.y, z: t.z } : { x: p.x + camBasis.f[0] * 18, y: p.y + camBasis.f[1] * 18, z: p.z + camBasis.f[2] * 18 };
      later(0.3, function () {
        var o = mainMz(0), gd = nrm([s0.x - o.x, s0.y + 45 - o.y, s0.z - o.z]);
        R.beams.push({ x: o.x, y: o.y, z: o.z, d: gd, len: Math.sqrt(d3(s0.x, s0.y + 45, s0.z, o.x, o.y, o.z)), life: 0.35, tint: R.pose.col }); muzzleFx(o, gd, 2);
        for (var q = 0; q < (aw ? 2 : 1); q++) R.missiles.push({ fall: true, meteor: true, x: s0.x + q * 6, y: s0.y + 45 + q * 25, z: s0.z + q * 4, tx: s0.x + q * 6, ty: s0.y, tz: s0.z + q * 4, dmg: 200 * m, splash: 7 * blast(), life: 8, model: 'prop_meteor_shard', size: 3.5 });
      });
    }
  }
  // 炮台位置：机甲左右两侧与前方的扇形区域（相对镜头），避开视线通道
  function turretSpot(i, n) {
    var a = (n > 1 ? i / (n - 1) : 0.5) * Math.PI - Math.PI / 2 + rand(-0.15, 0.15), r = camBasis.r, f = [camBasis.f[0], 0, camBasis.f[2]], fl = Math.hypot(f[0], f[2]) || 1;
    f = [f[0] / fl, 0, f[2] / fl];
    return [R.px + r[0] * Math.sin(a) * 7 + f[0] * (Math.cos(a) * 6 + 5), R.py + rand(-1.5, 2.5), R.pz + r[2] * Math.sin(a) * 7 + f[2] * (Math.cos(a) * 6 + 5)];
  }
  // 氮气：取代原来的闪避，由背部推进模组喷出氮气；每台机甲的氮气形态不同
  // 氮气推进的数值在 C.NITROS（数据层），每台机甲在机库 / 工坊里配装（v19）
  function perfMul() { var sv = C.save && C.save.settings; return Math.min(window.__perf || 1, sv && sv.saver ? 0.6 : 1); }
  function nitroOf() { if (R && R.nit) return R.nit.st; var nd = C.nitroDef(C.nativeNitro(R ? R.mech : 'mech_azure')); return Object.assign({ name: nd.n }, nd); }
  function dodge() {
    if (!R || R.dash || R.over || paused || R.dodgeCd > 0) return;
    var N = nitroOf(), dv = moveDir(), p = P(), po = R.pose, tg = po && po.tg && po.tg.hp > 0 ? po.tg : null;
    if (N.retreat && tg) dv = nrm([R.px - tg.x, R.py - tg.y, R.pz - tg.z]);
    R.dash = { t: 0, dur: N.dur, x0: p.x, y0: p.y, z0: p.z, x1: p.x + dv[0] * N.dist * (1 + R.st.nitroDist), y1: p.y + dv[1] * N.dist * (1 + R.st.nitroDist), z1: p.z + dv[2] * N.dist * (1 + R.st.nitroDist), dmg: (N.ram || 0) * R.mMul, hit: [], inv: true, invT: N.inv, d: dv, dodge: true, nitro: true, easeOut: true };
    R.nitroT = 2.2;
    R.dodgeCd = N.cd * (1 - fx('dodge')) * (1 - Math.min(0.5, R.st.nitro)); C.sfx('nitro');
    R.shake = Math.max(R.shake, 0.12);
    if (N.heal) R.hull = Math.min(hullMax(), R.hull + hullMax() * N.heal);
    if (N.retreat) { R.novas.push({ x: p.x, y: p.y, z: p.z, r: 9, life: 0.45, color: '#57B8FF' }); near(p.x, p.y, p.z, 12, function (e) { e.slowT = 2; }); }
    // 背部喷口爆出一团氮气焰
    var W = po && po.W; if (W) W.rear.forEach(function (n) { for (var k = 0; k < 7 && R.parts.length < 250; k++) R.parts.push({ model: 'fx_white', x: n[0], y: n[1], z: n[2], vx: W.rearD[0] * rand(10, 24) + rand(-2, 2), vy: W.rearD[1] * rand(10, 24) + rand(-2, 2), vz: W.rearD[2] * rand(10, 24) + rand(-2, 2), life: 0.5, max: 0.5, size: 2.4, tint: po.col, noGrav: true }); });
  }
  function updateActive(dt) {
    R.nitroT = Math.max(0, (R.nitroT || 0) - dt);
    R.activeCd = Math.max(0, R.activeCd - dt); R.dodgeCd = Math.max(0, R.dodgeCd - dt);
    if (R.dash) {
      var d = R.dash; d.t += dt; var k = Math.min(1, d.t / d.dur); if (d.invT) d.inv = d.t < d.invT; if (d.easeOut) k = 1 - (1 - k) * (1 - k);
      R.px = lerp(d.x0, d.x1, k); R.py = lerp(d.y0, d.y1, k); R.pz = lerp(d.z0, d.z1, k);
      if (d.dmg) near(R.px, R.py, R.pz, 6, function (e) { if (d.hit.indexOf(e) < 0 && d3(R.px, R.py, R.pz, e.x, e.y, e.z) < Math.pow(4 + e.r, 2)) { d.hit.push(e); hurtEnemy(e, d.dmg, d.d[0] * 35, d.d[1] * 35, d.d[2] * 35); } });
      emb(R.px, R.py, R.pz, R.pose && R.pose.ok ? R.pose.col : EMBER, 3, 5, 0.5, 2.2);
      if (!d.dodge || d.nitro) { var da = angOf(d.d); R.yaw += clamp(wrapA(da[0] - R.yaw), -900 * dt, 900 * dt); R.pitch = lerp(R.pitch, clamp(da[1] * 0.7, -50, 50), 1 - Math.exp(-dt * 14)); }
      if (d.fire && Math.random() < 0.6) R.fires.push({ x: R.px, y: R.py, z: R.pz, life: 3, tick: 0 });
      if (d.t >= d.dur) { R.dash = null; R.iframe = d.nitro ? 0.1 : 0.3; }
    }
    R.zones = R.zones.filter(function (z) {
      z.life -= dt; z.tick -= dt;
      if (d3(R.px, R.py, R.pz, z.x, z.y, z.z) < z.r * z.r) R.hull = Math.min(hullMax(), R.hull + hullMax() * z.heal * dt);
      near(z.x, z.y, z.z, z.r + 3, function (e) { if (dd(z, e) < z.r * z.r) { e.slow = true; if (z.dmg && z.tick <= 0) hurtEnemy(e, z.dmg * 0.5, 0, 0, 0, true); } });
      if (z.tick <= 0) z.tick = 0.5;
      return z.life > 0;
    });
    R.fires = R.fires.filter(function (f) {
      f.life -= dt; f.tick -= dt;
      if (f.tick <= 0) { f.tick = 0.5; near(f.x, f.y, f.z, 5, function (e) { if (dd(f, e) < 9 + e.r * e.r) hurtEnemy(e, 10 * R.mMul, 0, 0, 0, true); }); }
      if (Math.random() < 0.3) sparks(f.x, f.y, f.z, 'fx_spark', 1, 3, 0.5);
      return f.life > 0;
    });
  }
  function supportStat() { var l = lv('support'); return { dmg: (1 + 0.35 * (l - 1)) * R.cStar * (1 + R.st.sup), cd: (1 - 0.1 * (l - 1)) * cdMult(), count: l >= 5 ? 2 : 1, lv: l }; }
  function updateSupport(dt) {
    var c = R.cop, id = R.pilot, st = supportStat(), ch = C.char(id), p = P();
    if (c.dash) {
      c.dash.t += dt; var k = Math.min(1, c.dash.t / 0.38);
      c.x = lerp(c.dash.x0, c.dash.x1, k); c.y = lerp(c.dash.y0, c.dash.y1, k); c.z = lerp(c.dash.z0, c.dash.z1, k);
      near(c.x, c.y, c.z, 6, function (e) { if (c.dash.hit.indexOf(e) < 0 && dd(c, e) < Math.pow(3.5 + e.r, 2)) { c.dash.hit.push(e); hurtEnemy(e, c.dash.dmg, c.dash.d[0] * 30, c.dash.d[1] * 30, c.dash.d[2] * 30); } });
      sparks(c.x, c.y, c.z, 'fx_spark', 3, 6, 0.4);
      if (k >= 1) { c.dash.left--; if (c.dash.left > 0) copDash(c, c.dash.dmg, c.dash.left); else c.dash = null; }
    } else { c.x = R.px; c.y = R.py; c.z = R.pz; }
    if (fx('regen')) R.hull = Math.min(hullMax(), R.hull + hullMax() * fx('regen') * dt);
    R.hull = Math.min(hullMax(), R.hull + (0.6 * lv('repair') + R.st.regen) * dt);
    R.supportCd -= dt;
    if (R.supportCd > 0) return;
    R.supportCd = ch.support.cd * st.cd;
    if (id === 'char_xingli') {
      var ts = R.enemies.filter(function (e) { return !e.d.ore && dd(p, e) < 2500; }).sort(function (a, b) { return b.hp - a.hp; }).slice(0, st.count);
      if (!ts.length) { R.supportCd = 0.5; return; }
      var mo = mainMz(0); ts.forEach(function (t) { var bv = nrm([t.x - mo.x, t.y - mo.y, t.z - mo.z]); R.beams.push({ x: mo.x, y: mo.y, z: mo.z, d: bv, len: 60, life: 0.2 }); muzzleFx(mo, bv, 0.8); beamHit(mo, bv, 60, 1.6, function (e) { hurtEnemy(e, 55 * st.dmg, bv[0] * 8, bv[1] * 8, bv[2] * 8); }); });
    } else if (id === 'char_chiyan') { copDash(c, 70 * st.dmg, st.count); }
    else if (id === 'char_yuexi') { R.hull = Math.min(hullMax(), R.hull + 15 * st.dmg); nova(p, 10, 15 * st.dmg * (st.lv >= 5 ? 2 : 1), '#7CF29A'); }
    else if (id === 'char_hupo') { for (var i = 0; i < st.count; i++) { var tp = turretSpot(R.turrets.length + i, 4); newTurret(tp, { life: 8, dmg: 4 * st.dmg }); } }
    else if (id === 'char_yeyuan') {
      for (var w = 0; w < st.count; w++) { var tg = R.enemies.filter(function (e) { return !e.d.ore && dd(p, e) < 1600; }); if (tg.length) { var e0 = pick(tg); R.wells.push({ x: e0.x, y: e0.y, z: e0.z, r: 10, life: 3, dmg: 16 * st.dmg, tick: 0 }); } }
    }
    else if (id === 'char_shuangling') {
      for (var m = 0; m < 7 * st.count; m++) { var tt = R.enemies.length ? pick(R.enemies) : null, tx = tt ? tt.x : p.x + rand(-25, 25), ty = tt ? tt.y : p.y, tz = tt ? tt.z : p.z + rand(-25, 25); R.missiles.push(podLaunch({ fall: true, x: tx, y: ty + 32 + m * 3, z: tz, tx: tx, ty: ty, tz: tz, dmg: 12 * st.dmg, splash: 5 * blast(), life: 5, model: 'fx_missile', size: 2.2 }, m, 0.03)); }
    }
    say('cop', id);
  }
  function copDash(c, dmg, left) {
    var t = target(R.px, R.py, R.pz, 35), dv = t ? nrm([t.x - R.px, t.y - R.py, t.z - R.pz]) : camBasis.f;
    c.dash = { t: 0, x0: c.x, y0: c.y, z0: c.z, x1: R.px + dv[0] * 26, y1: R.py + dv[1] * 26, z1: R.pz + dv[2] * 26, d: dv, dmg: dmg, hit: [], left: left };
  }
  function updateTurrets(dt) {
    R.turrets = R.turrets.filter(function (tu) {
      tu.life -= dt; tu.fire -= dt;
      if (tu.dep > 0) { tu.dep -= dt; return true; }
      var t = target(tu.x, tu.y, tu.z, 34);
      if (t) { var dv = nrm([t.x - tu.x, t.y - tu.y, t.z - tu.z]); tu.yaw = Math.atan2(dv[0], dv[2]) / DEG;
        if (tu.fire <= 0) { tu.fire = 0.4; shot(tu, dv, 60, { dmg: tu.dmg * (1 + R.st.summon + fx('turret')), blastR: tu.blast ? 3 * blast() : 0, pierce: tu.blast ? 0 : 2, life: 0.8, model: 'fx_laser_player' }); } }
      return tu.life > 0;
    });
    R.wells = R.wells.filter(function (w) {
      w.life -= dt; w.tick = (w.tick || 0) - dt;
      var hitNow = w.dmg && w.tick <= 0; if (hitNow) w.tick = 0.5;
      near(w.x, w.y, w.z, w.r + 3, function (e) {
        var v = [w.x - e.x, w.y - e.y, w.z - e.z], l = len3(v[0], v[1], v[2]) || 1;
        if (l < w.r) { e.slow = true; if (w.dmg && !e.d.boss && !e.d.ore) { var s = Math.min(l, 12 * dt) / l; e.x += v[0] * s; e.y += v[1] * s; e.z += v[2] * s; } if (hitNow && !e.d.ore) hurtEnemy(e, w.dmg * 0.5, 0, 0, 0, true); }
      });
      if (w.dmg && Math.random() < 0.8) { var d = randDir(); R.parts.push({ model: 'fx_white', x: w.x + d[0] * w.r, y: w.y + d[1] * w.r, z: w.z + d[2] * w.r, vx: -d[0] * w.r * 1.5, vy: -d[1] * w.r * 1.5, vz: -d[2] * w.r * 1.5, life: 0.6, max: 0.6, size: 2, tint: [0.55, 0.3, 1.1], noGrav: true }); }
      if (w.life <= 0 && w.implode) { var im = w.implode; explode(w.x, w.y, w.z, im.r, im.dmg); ringBurst(w.x, w.y, w.z, im.r * 1.2, im.tint, 0.45); R.shake = Math.max(R.shake, 0.3); C.sfx('boom'); }
      return w.life > 0;
    });
    R.beams = R.beams.filter(function (b) { b.life -= dt; return b.life > 0; });
  }

  // ------------------------------------------------------------------ 地点事件
  function updateNodes(dt) {
    R.nearNode = null;
    var p = P();
    R.nodes.forEach(function (n) {
      var d = Math.sqrt(dd(p, n));
      if (d < 40 && n.state !== 'done' && n.state !== 'hidden') R.nearNode = n;
      if (n.state === 'done') return;
      if (n.type === 'pirate') {
        if (n.state === 'idle' && d < 34) {
          n.state = 'active'; banner('海贼据点：清剿全部海贼');
          for (var i = 0; i < 9 + R.ch.id * 3; i++) { var q = spherePos(n, rand(6, 18)); spawnEnemy(pick(['grunt', 'grunt', 'inter', R.ch.id > 1 ? 'heavy' : 'grunt']), q[0], q[1], q[2], n); }
        } else if (n.state === 'active' && !R.enemies.some(function (e) { return e.node === n; })) {
          n.state = 'done'; R.pickups.push({ kind: 'chest', x: n.x, y: n.y, z: n.z, cr: 80 * R.ch.id, lvl: 1 }); banner('据点清剿完成！');
        }
      } else if (n.type === 'derelict') {
        if (d < 15) {
          if (n.state === 'idle') { n.state = 'active'; for (var j = 0; j < 12 + R.ch.id * 3; j++) { var q2 = spherePos(n, 40); spawnEnemy('crawler', q2[0], q2[1], q2[2], n); } }
          n.progress += dt / 5 * (1 + fx('loot'));
          if (n.progress >= 1) { n.state = 'done'; addCredits(120 * R.ch.id); for (var g = 0; g < 12; g++) R.gems.push({ x: n.x + rand(-5, 5), y: n.y + rand(-5, 5), z: n.z + rand(-5, 5), v: 1 }); if (Math.random() < 0.6) gainFrag(2); banner('搜刮完成：信用点 +' + 120 * R.ch.id); }
        }
      } else if (n.type === 'ore') {
        if (n.state === 'idle' && d < 48) { n.state = 'active'; for (var o = 0; o < 8; o++) { var r = spherePos(n, rand(3, 14)); spawnEnemy('ore', r[0], r[1], r[2], n); } }
        else if (n.state === 'active' && !R.enemies.some(function (e) { return e.node === n; })) { n.state = 'done'; banner('富矿开采完毕'); }
      } else if (n.type === 'distress') {
        if (n.state === 'idle' && d < 18) { n.state = 'active'; n.timer = 20; banner('守住逃生舱 20 秒！'); }
        if (n.state === 'active') {
          n.timer -= dt; n.spawn = (n.spawn || 0) - dt;
          if (n.spawn <= 0) { n.spawn = 2.2; for (var s = 0; s < 3 + R.ch.id; s++) { var w = spherePos(n, 45); var en = spawnEnemy(pick(['inter', 'grunt', 'crawler']), w[0], w[1], w[2], n); en.podHunter = Math.random() < 0.5; } }
          if (n.pod.hp <= 0) { n.state = 'done'; n.failed = true; sparks(n.x, n.y, n.z, 'fx_spark', 40, 20, 1); n.objs = n.objs.slice(1); banner('逃生舱被击毁了……'); }
          else if (n.timer <= 0) { n.state = 'done'; R.src += 5; addCredits(100 * R.ch.id); banner('营救成功：星源 +5'); R.enemies.forEach(function (e) { if (e.node === n) e.podHunter = false; }); }
        }
      } else if (n.type === 'hunt') {
        if (n.state === 'idle' && d < 40) { n.state = 'active'; n.timer = 40; n.k0 = R.kills; n.need = 22 + 8 * R.ch.id; n.spawn = 0; banner('限时猎杀：40 秒内击败 ' + n.need + ' 个敌人！'); }
        if (n.state === 'active') {
          n.timer -= dt; n.spawn -= dt; n.got = R.kills - n.k0;
          if (n.spawn <= 0) { n.spawn = 1.6; for (var hs = 0; hs < 4 + R.ch.id; hs++) { var hq = spherePos(n, rand(25, 45)); spawnEnemy(pick(['crawler', 'crawler', 'grunt']), hq[0], hq[1], hq[2], n); } }
          if (n.got >= n.need) { n.state = 'done'; R.enemies.forEach(function (e) { if (e.node === n) e.node = null; }); R.pickups.push({ kind: 'chest', x: n.x, y: n.y, z: n.z, cr: 100 * R.ch.id, lvl: 1 }); R.src += 3; banner('猎杀成功！战利品已掉落，星源 +3'); C.sfx('win'); }
          else if (n.timer <= 0) { n.state = 'done'; n.failed = true; R.enemies.forEach(function (e) { if (e.node === n) e.node = null; }); banner('时间到，猎杀失败'); }
        }
      } else if (n.type === 'ambush') {
        if (n.state === 'idle' && d < 34) { n.state = 'active'; n.wave = 0; }
        if (n.state === 'active' && !R.enemies.some(function (e) { return e.node === n; })) {
          if (n.wave >= 3) { n.state = 'done'; R.pickups.push({ kind: 'chest', x: n.x, y: n.y, z: n.z, cr: 130 * R.ch.id, lvl: 1 }); gainFrag(2); banner('伏击瓦解！'); C.sfx('win'); }
          else {
            n.wave++; banner('伏击！第 ' + n.wave + ' / 3 波');
            var kinds = n.wave === 1 ? ['grunt', 'grunt', 'inter'] : n.wave === 2 ? ['heavy', 'grunt', 'inter'] : ['brute', 'heavy', 'inter'];
            for (var as = 0; as < (n.wave === 3 ? 4 : 7 + R.ch.id * 2); as++) { var aq = spherePos(n, rand(15, 28)); spawnEnemy(n.wave === 3 && as === 0 ? 'brute' : pick(kinds.filter(function (k) { return k !== 'brute'; })), aq[0], aq[1], aq[2], n); }
          }
        }
      } else if (n.type === 'merchant') {
        if (d < 18 && !n.cool) { n.cool = true; openShop(n); }
        if (d > 32) n.cool = false;
      } else if (n.type === 'nest') {
        if (n.state === 'idle' && d < 32) { n.state = 'active'; var b = spherePos(n, 6); n.guard = spawnEnemy('brute', b[0], b[1], b[2], n); banner('巢穴守卫：晶核巨兽'); }
        else if (n.state === 'active' && n.guard.hp <= 0) { n.state = 'done'; gainFrag(5); R.pickups.push({ kind: 'chest', x: n.x, y: n.y, z: n.z, cr: 150 * R.ch.id, lvl: 1 }); }
      } else if (n.type === 'gate') {
        if (n.state === 'locked' && objectiveDone()) { n.state = 'open'; banner('目标完成，星门已开启！'); C.sfx('gate'); R.enemies.forEach(function (e) { if (!e.d.ore && !e.d.elite) e.hp = 0; }); R.enemies = R.enemies.filter(function (e) { return e.hp > 0; }); }
        if (n.state === 'open' && d < 15 && !paused) nextSector();
      }
    });
  }
  function gainFrag(n) { var owned = Object.keys(C.save.chars), id = pick(owned); R.frags[id] = (R.frags[id] || 0) + n; A.toast(C.char(id).name + ' 碎片 +' + n); }

  // ------------------------------------------------------------------ 拾取与升级
  function updatePickups(dt) {
    var pr = pickupR(), pr2 = pr * pr, p = P();
    R.gems = R.gems.filter(function (g) {
      var d2v = dd(g, p);
      if (d2v < pr2 || g.pull) { g.pull = true; var d = Math.sqrt(d2v) || 1, sp = 40 + (pr - Math.min(pr, d)) * 4, k = sp * dt / d; g.x += (p.x - g.x) * k; g.y += (p.y - g.y) * k; g.z += (p.z - g.z) * k; }
      if (d2v < 2.5 * 2.5) { gainXp(g.v); return false; }
      return true;
    });
    if (R.gems.length > 400) R.gems.splice(0, R.gems.length - 400);
    R.pickups = R.pickups.filter(function (pk) {
      if (dd(pk, p) < 4 * 4) {
        if (pk.kind === 'heal') { R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.3); A.toast('耐久修复 30%'); }
        else if (pk.kind === 'ammo') { var ga = R.sub ? Math.min(R.sub.cap - R.sub.ammo, pk.n) : 0; if (R.sub) { R.sub.ammo += ga; R.sub.gained += ga; } C.sfx('pick'); A.toast('弹药箱：' + (R.sub ? R.sub.def.n : '副武器') + ' +' + ga); }
        else { addCredits(pk.cr); R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.15); R.pendingLevels += pk.lvl || 0; A.toast('战利品：信用点 +' + pk.cr + '，免费升级 1 次'); }
        return false;
      }
      return true;
    });
  }
  function gainXp(v) { if (Math.random() < 0.3) C.sfx('pick'); R.xp += v * (1 + R.st.xp) * (C.save.runs < 3 ? 1.8 : 1) * (affix('fury') ? 1.3 : affix('tide') ? 1.5 : 1); while (R.xp >= xpNeed(R.level)) { R.xp -= xpNeed(R.level); R.level++; R.pendingLevels++; } }
  function choices() {
    var p = Object.keys(UPG).filter(function (k) { return UPG[k].kind === 'passive' && lv(k) > 0; }).length, pool = [];
    Object.keys(UPG).forEach(function (k) { var u = UPG[k], l = lv(k); if (l >= u.max) return; if (l === 0 && u.kind === 'passive' && p >= 4) return; pool.push({ id: k, w: k === 'main' ? 1.6 : k === 'support' ? 1.5 : 1 }); });
    R.mods.forEach(function (md, i) { if (md.lv < 5) pool.push({ id: 'mod' + i, w: 1.5 }); });
    if (R.sub && R.sub.ammo < R.sub.cap * 0.5) pool.push({ id: 'ammo', w: 1.4 });
    if (R.mods.length < C.RUN_MOD_MAX && R.modPool.length) {   // 每次升级最多随机给 2 张新卡，技能越少新卡越容易出
      var idx = R.modPool.map(function (_, i) { return i; }), w = R.mods.length < 3 ? 3 : 1.8;
      for (var q = 0; q < 2 && idx.length; q++) pool.push({ id: 'new' + idx.splice(Math.floor(Math.random() * idx.length), 1)[0], w: w });
    }
    var out = [];
    R.mods.forEach(function (md, i) { if (evoReady(md) && out.length < 3) out.push('evo' + i); });     // 可进化的卡牌：进化选项必出
    while (out.length < 3 && pool.length) { var sum = pool.reduce(function (s, x) { return s + x.w; }, 0), r = Math.random() * sum, i = 0; while (r > pool[i].w) { r -= pool[i].w; i++; } out.push(pool[i].id); pool.splice(i, 1); }
    if (!out.length) out.push('heal');
    return out;
  }
  function evoReady(md) { var ev = C.evoOf(md.m); return !!(ev && !md.evo && md.lv >= 5 && lv(ev.pass) >= C.EVO_PASS_LV); }
  function checkEvoReady() { R.mods.forEach(function (md) { if (evoReady(md) && !md.evoHint) { md.evoHint = true; banner(md.m.name + ' 可以进化了！下次升级必出进化选项'); C.sfx('win'); } }); }
  function applyChoice(id) {
    if (id.indexOf('evo') === 0) { var em = R.mods[+id.slice(3)]; em.evo = true; banner('进化！' + em.m.name + ' · ' + C.evoOf(em.m).n); C.sfx('win'); R.shake = Math.max(R.shake, 0.4); ringBurst(R.px, R.py - 2, R.pz, 14, em.tint, 0.6); emb(R.px, R.py, R.pz, em.tint, 26, 14, 0.8, 2.4, 3); return; }
    if (id.indexOf('new') === 0) { var nm = R.modPool.splice(+id.slice(3), 1)[0]; if (nm) addMod(nm); return; }
    if (id.indexOf('mod') === 0) { R.mods[+id.slice(3)].lv++; return; }
    if (id === 'heal') { R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.4); return; }
    if (id === 'ammo') { var ga = Math.min(R.sub.cap - R.sub.ammo, 8); R.sub.ammo += ga; R.sub.gained += ga; return; }
    R.lv[id] = lv(id) + 1;
    if (id === 'hull') R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.25);
  }
  function afterChoice() { checkEvoReady(); }
  // 升级前后的具体数值 + 卡牌词条 + 进化提示
  function modNumText(md, nl) {
    var a = modStat(md), b = modStat(Object.assign({}, md, { lv: nl })), t = '伤害 ' + Math.round(a.dmg) + ' → ' + Math.round(b.dmg) + '，冷却 ' + a.cd.toFixed(1) + 's → ' + b.cd.toFixed(1) + 's';
    if (a.count !== b.count) t += '，数量 ' + a.count + ' → ' + b.count;
    var tg = md.m.tags.map(function (k) { var o = C.MOD_TAGS.filter(function (x) { return x.k === k; })[0]; return o ? o.n : k; });
    var gf = C.goldTag(md.m); if (gf) tg.push('金色：' + gf.d);
    if (tg.length) t += '。词条：' + tg.join('、');
    var rh = C.REACT_HINT[md.m.elem]; if (rh) t += '。元素反应：' + rh;
    var ev = C.evoOf(md.m); if (ev && !md.evo && nl >= 4) t += '。' + (nl >= 5 ? '已满级，' : '') + '搭配「' + UPG[ev.pass].name + ' Lv' + C.EVO_PASS_LV + '」可进化（当前 Lv' + lv(ev.pass) + '）';
    return t;
  }
  function choiceInfo(id) {
    var next = lv(id) + 1;
    if (id.indexOf('new') === 0) { var nm = R.modPool[+id.slice(3)]; return { name: nm.name, tag: '获得新技能', icon: A.iconSVG(C.modIcon(nm), 110), text: C.modDesc(nm), crew: true }; }
    if (id.indexOf('evo') === 0) { var em = R.mods[+id.slice(3)], ev = C.evoOf(em.m), c0 = modStat(em), c1 = modStat(Object.assign({}, em, { evo: true })); return { name: em.m.name + ' · ' + ev.n, tag: '★ 进化', evo: true, icon: A.iconSVG(C.modIcon(em.m), 120), text: ev.d + '。伤害 ' + Math.round(c0.dmg) + ' → ' + Math.round(c1.dmg) + '，冷却 ' + c0.cd.toFixed(1) + 's → ' + c1.cd.toFixed(1) + 's，数量 ' + c0.count + ' → ' + c1.count, crew: true }; }
    if (id.indexOf('mod') === 0) { var md = R.mods[+id.slice(3)], nl = md.lv + 1; return { name: md.m.name, tag: '技能模块 Lv' + nl, icon: A.iconSVG(C.modIcon(md.m), 110), text: modNumText(md, nl), crew: true }; }
    if (id === 'heal') return { name: '紧急维修', tag: '回复', icon: A.iconSVG(ICON.heal, 120), text: '修复 40% 耐久' };
    if (id === 'ammo') return { name: '弹药补给', tag: '副武器', icon: A.iconSVG(ICON.ammo, 120), text: R.sub.def.n + ' 弹药 +8（当前 ' + R.sub.ammo + ' / ' + R.sub.cap + '）' };
    if (id === 'main') { var w = { name: R.wpn.def.n }; return { name: w.name, tag: '主武器 Lv' + next, icon: A.catIcon(R.mech, 80), text: UPG.main.desc[next - 1], crew: true }; }
    if (id === 'support') { var c = C.char(R.pilot); return { name: c.name + '：' + c.support.name, tag: '驾驶员 Lv' + next, icon: A.catIcon(R.pilot, 76), text: UPG.support.desc[next - 1], crew: true }; }
    var u = UPG[id]; return { name: u.name, tag: '强化 Lv' + next, icon: A.iconSVG(ICON[id], 120), text: u.desc[Math.min(next - 1, u.desc.length - 1)] };
  }

  // ------------------------------------------------------------------ 飞行：摇杆朝镜头方向移动，右半屏拖动转视角
  function updatePlayer(dt) {
    // 视角：键盘方向键转动；闲置时缓慢转向当前目标
    if (keys.ArrowLeft) R.camYaw -= 90 * dt; if (keys.ArrowRight) R.camYaw += 90 * dt;
    if (keys.ArrowUp) R.camPitch -= 60 * dt; if (keys.ArrowDown) R.camPitch += 60 * dt;
    look.idle += dt;
    var jx = joy.dx, jy = joy.dy;
    if (keys.KeyA) jx = -1; if (keys.KeyD) jx = 1; if (keys.KeyW) jy = 1; if (keys.KeyS) jy = -1;
    var lift = (keys.KeyR ? 1 : 0) - (keys.KeyF ? 1 : 0);
    var moving = Math.abs(jx) + Math.abs(jy) + Math.abs(lift) > 0.05;
    if (look.idle > 1.6 && look.id === null && !keys.ArrowLeft && !keys.ArrowRight && !keys.ArrowUp && !keys.ArrowDown) {
      var goal = R.boss && R.boss.hp > 0 ? R.boss : !objectiveDone() ? R.event : R.gate.state === 'open' ? R.gate : null;
      if (goal && !moving) { var ga = angOf([goal.x - R.px, goal.y - R.py, goal.z - R.pz]), dy = ((ga[0] - R.camYaw + 540) % 360) - 180, dp = clamp(ga[1], -60, 60) + 6 - R.camPitch;
        R.camYaw += clamp(dy, -35 * dt, 35 * dt); R.camPitch += clamp(dp, -25 * dt, 25 * dt); }
    }
    R.camPitch = clamp(R.camPitch, -70, 70);
    if (R.dash) return;
    var f = fwdOf(R.camYaw, R.camPitch), r = rightOf(R.camYaw), l = Math.hypot(jx, jy); if (l > 1) { jx /= l; jy /= l; }
    var want = [f[0] * jy + r[0] * jx, f[1] * jy + lift, f[2] * jy + r[2] * jx], sp = speed(), k = 1 - Math.exp(-dt * 6);
    R.vx = lerp(R.vx, want[0] * sp, k); R.vy = lerp(R.vy, want[1] * sp, k); R.vz = lerp(R.vz, want[2] * sp, k);
    R.px += R.vx * dt; R.py += R.vy * dt; R.pz += R.vz * dt;
    // 边界：球形战场，越界时柔和推回
    var pl = len3(R.px, R.py, R.pz); R.outside = pl > BOUND;
    if (pl > BOUND) { var push = (pl - BOUND) * 2 * dt / pl; R.px -= R.px * push; R.py -= R.py * push; R.pz -= R.pz * push; }
    // 机甲朝向：移动时朝向速度方向，并按横移倾斜；静止时朝向镜头前方
    var vl = len3(R.vx, R.vy, R.vz), ty, tp, turn;
    if (vl > 1.5) { var a = angOf([R.vx, R.vy, R.vz]); ty = a[0]; tp = clamp(a[1] * 0.6, -35, 35); } else { ty = R.camYaw; tp = 0; }
    var ptg = R.pose && R.pose.ok && R.pose.tg;
    if (ptg && ptg.hp > 0) { var dl = wrapA(angOf([ptg.x - R.px, ptg.y - R.py, ptg.z - R.pz])[0] - ty); if (Math.abs(dl) > 40) ty += dl - (dl > 0 ? 40 : -40); }
    turn = ((ty - R.yaw + 540) % 360) - 180; R.yaw += clamp(turn, -400 * dt, 400 * dt); R.pitch = lerp(R.pitch, tp, 1 - Math.exp(-dt * 6));
    R.roll = lerp(R.roll, clamp(-jx * 25 - turn * 0.3, -35, 35), 1 - Math.exp(-dt * 6));
    if (!R.pose.ok && vl > 3 && Math.random() < 0.6) { var bf = fwdOf(R.yaw, R.pitch); R.parts.push({ model: 'fx_spark_teal', x: R.px - bf[0] * 1.6, y: R.py + 1.4 - bf[1] * 1.6, z: R.pz - bf[2] * 1.6, vx: -R.vx * 0.3 + rand(-2, 2), vy: -R.vy * 0.3 + rand(-2, 2), vz: -R.vz * 0.3 + rand(-2, 2), life: 0.35, max: 0.35, size: 2, noGrav: true }); }
    R.iframe -= dt;
  }
  function updateParts(dt) {
    R.parts = R.parts.filter(function (p) { p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt; p.z += p.vz * dt; var dm = Math.exp(-dt * 1.5); p.vx *= dm; p.vy *= dm; p.vz *= dm; return p.life > 0; });
    R.nums = R.nums.filter(function (n) { n.life -= dt; n.y += dt * 5; return n.life > 0; });
    R.bubbles = R.bubbles.filter(function (b) { b.life -= dt; return b.life > 0; });
    R.novas = R.novas.filter(function (n) { n.life -= dt; return n.life > 0; });
    R.bannerT -= dt; R.shake = Math.max(0, R.shake - dt * 1.5);
    if (R.comboT > 0) { R.comboT -= dt; if (R.comboT <= 0 && R.combo >= 15) { var cb = R.combo * 2; addCredits(cb); A.toast('连击 x' + R.combo + '：信用点 +' + cb); } }
  }
  function step(dt) {
    if (!R) return;
    if (paused || (R.over && !R.won)) { updateParts(dt); return; }
    // 顿帧 / 慢动作：重击、击杀精英与首领、自身受击时短暂放慢时间
    if (R.hitstop > 0) { R.hitstop -= dt; dt *= 0.1; } else if (R.slowT > 0) { R.slowT -= dt; dt *= 0.35; }
    R.t += dt; R.camDt = dt;
    runSched(dt); updatePlayer(dt); updateActive(dt); poseStep(dt); poseBuild(); updateSpawns(dt); updateNodes(dt); updateEnemies(dt); fireMain(dt); updateSub(dt); updateModules(dt);
    updateSupport(dt); updateTurrets(dt); updateShots(dt); updatePickups(dt); updateParts(dt);
    if (R.pendingLevels > 0 && !R.over && !paused) openLevelUp();
    if (R.tutorial) R.tutorial.tick();
  }

  // ------------------------------------------------------------------ 渲染：第三人称环绕相机
  // 预设经过实测：标准 = 距离 15、高 5（机甲位于画面中下部，让出中心视野）；远景 22；近景 12.5
  var CAMS = { high: { dist: 22, h: 6.5, fov: 62 }, chase: { dist: 15, h: 5, fov: 64 }, mid: { dist: 12.5, h: 4, fov: 66 } }, camPreset = 'chase';
  function render() {
    var t = R.t, draws = [], soft = C.save.settings && C.save.settings.fx === 'soft';
    // 先算相机：在机甲身后沿镜头方向环绕，带平滑跟随
    var cam = CAMS[camPreset], f = fwdOf(R.camYaw + (R.dbgYaw || 0), R.camPitch), dtc = 1 - Math.exp(-(R.camDt || 0.016) * 8);
    R.cx = R.cx == null ? R.px : lerp(R.cx, R.px, dtc); R.cy = R.cy == null ? R.py : lerp(R.cy, R.py, dtc); R.cz = R.cz == null ? R.pz : lerp(R.cz, R.pz, dtc);
    var sh = soft ? 0 : R.shake * 0.35, j = function () { return sh ? rand(-1, 1) * sh : 0; };
    var eye = [R.cx - f[0] * cam.dist + j(), R.cy - f[1] * cam.dist + cam.h + j(), R.cz - f[2] * cam.dist + j()];
    var tgt = [R.cx + f[0] * 10, R.cy + f[1] * 10 + cam.h * 0.55, R.cz + f[2] * 10];
    var cf = nrm([tgt[0] - eye[0], tgt[1] - eye[1], tgt[2] - eye[2]]), cr = nrm(cross([0, 1, 0], cf)), cu = cross(cf, cr);
    camBasis = { f: cf, r: cr, u: cu, eye: eye };
    var V = A.view(), aspect = V.w / V.h, fov = A.fitFov(cam.fov, aspect), tanH = Math.tan(fov * DEG / 2);
    // 视线通道：镜头到机甲之间不放特效，保证始终看得清自己的机甲
    var sight = [R.px - eye[0], R.py - eye[1], R.pz - eye[2]], sightLen = len3(sight[0], sight[1], sight[2]), sd = [sight[0] / sightLen, sight[1] / sightLen, sight[2] / sightLen];
    var occ = 0, fxScale = soft ? 0.75 : 1;
    // kind：0 场景 / 1 敌人 / 2 特效。敌人与特效离镜头过近时隐藏或缩小，特效不进入视线通道
    function add(model, x, y, z, yaw, pitch, roll, s, tint, kind) {
      var mesh = E.getMesh(model); if (!mesh) return;
      if (kind) {
        var rx = x - eye[0], ry = y - eye[1], rz = z - eye[2], dist = len3(rx, ry, rz), fwd = rx * cf[0] + ry * cf[1] + rz * cf[2];
        var nearCut = kind === 2 ? 7 : 5, fade = kind === 2 ? 14 : 8;
        if (dist < nearCut || fwd < (kind === 2 ? 6 : 3)) return;
        if (dist < fade) s *= (dist - nearCut) / (fade - nearCut);
        if (kind === 2) {
          s *= fxScale;
          var along = rx * sd[0] + ry * sd[1] + rz * sd[2];
          if (along > 0 && along < sightLen - 2.5) { var ox = rx - sd[0] * along, oy = ry - sd[1] * along, oz = rz - sd[2] * along; if (ox * ox + oy * oy + oz * oz < 2.6 * 2.6) return; }
          if (fwd > 0.5) { var pr = mesh.radius * s / (fwd * tanH); occ += Math.min(1, Math.PI * pr * pr / (4 * aspect)); }
        }
      }
      draws.push({ mesh: mesh, m: E.trs([x, y, z], yaw, pitch, roll, s), s: s, tint: tint });
    }
    R.decor.forEach(function (d) { add(d.model, d.x, d.y, d.z, d.yaw + d.spin * t, 20 + d.spin * t * 0.5, 0, d.s); });
    R.nodes.forEach(function (n) { if (n.state === 'hidden') return; var open = n.type === 'gate' && n.state === 'open'; n.objs.forEach(function (o) { add(o.model, o.x, o.y + (open ? Math.sin(t * 3) * 0.6 : 0), o.z, (o.spin || 0) * t, o.pitch || 0, open ? t * 40 : 0, o.s * (n.type === 'gate' && !open ? 0.7 : 1)); }); });
    if (!R.over || R.won) {
      var po = R.pose;
      if (po.ok && po.mats) {
        var htint = po.hitFlash > 0 ? [1.5, 0.3, 0.3] : null;
        PARTS.forEach(function (nm) { var mesh = E.getMesh(R.mech + '__' + nm); if (mesh && po.mats[nm]) draws.push({ mesh: mesh, m: po.mats[nm], s: 1.35, tint: htint }); });
        // 尾喷：两个向后的喇叭口，长度随推力变化；腰侧推进筒向下喷出短焰
        var W = po.W, fl = function (n, d, len, s0, thr, ph) { for (var j = 0; j < 5; j++) { var q = len * j / 4 + 0.04; add('fx_white', n[0] + d[0] * q, n[1] + d[1] * q, n[2] + d[2] * q, t * 200, t * 140, 0, s0 * (1 - j * 0.17) * (0.55 + 0.45 * Math.min(thr, 1.2)) * (0.93 + 0.1 * Math.sin(t * 6 + j * 1.7 + ph)), j === 0 ? null : po.col, 0); } };
        W.rear.forEach(function (n, k) { fl(n, W.rearD, 0.25 + 1.5 * clamp(po.thrR, 0, 1.6), 3.4, po.thrR, k * 2); });
        W.vern.forEach(function (n, k) { fl(n, W.vernD, 0.15 + 0.8 * clamp(po.thrV, 0, 1.4), 2.6, po.thrV, k * 3 + 1); });
      } else add(R.mech, R.px, R.py - 2.4 + Math.sin(t * 3) * 0.12, R.pz, R.yaw, R.pitch + (R.dash ? 18 : 0), R.roll, 1.35);
    }
    R.enemies.forEach(function (e) { var s = e.d.scale; add(e.d.model, e.x, e.y - (e.d.ship || e.d.ore ? 0 : e.r * 0.6), e.z, e.d.ore ? t * 20 + e.bob * 50 : e.yaw, e.d.ore ? 30 + e.bob * 40 : e.pitch, 0, s, e.flash > 0 && !e.d.boss && !soft ? [0.95, 0.62, 0.56] : null, 1); });
    // 攻击预警：首领 / 精英 / 重炮手开火前 0.8 秒，脚下出现红色扩张圈，直线弹幕会画出瞄准线；召唤技能为紫色圈
    R.enemies.forEach(function (e) {
      var sh = e.d.shoot, big = e.d.boss || e.d.elite || e.type === 'heavy', k;
      if (e.lg && e.lg.t < e.d.lunge.tele) { var lk = e.lg.t / e.d.lunge.tele, la2 = angOf(e.lg.dir); for (k = 0; k < 10; k++) add('fx_white_bolt', e.x + e.lg.dir[0] * (e.r + 1 + k * 1.2), e.y + e.lg.dir[1] * (e.r + 1 + k * 1.2), e.z + e.lg.dir[2] * (e.r + 1 + k * 1.2), la2[0], la2[1], 0, 1.8, [1.0 + 0.4 * lk, 0.15, 0.2], 1); return; }
      if (e.sl) { var sk2 = e.sl.t / e.d.slam.tele, sr = e.d.slam.r; for (k = 0; k < 40; k++) { var sa = k / 40 * Math.PI * 2; add('fx_spark', e.x + Math.cos(sa) * sr, e.y - e.r * 0.5, e.z + Math.sin(sa) * sr, 0, 0, 0, 2.2, [1.2, 0.35, 0.15], 1); if (k % 2 === 0) add('fx_spark', e.x + Math.cos(sa) * sr * sk2, e.y - e.r * 0.5, e.z + Math.sin(sa) * sr * sk2, 0, 0, 0, 2.6, [1.5, 0.6, 0.2], 1); } return; }
      if (e.sn && e.sn.t < e.d.snipe.tele) { var sq = e.sn.t / e.d.snipe.tele, sa = angOf(e.sn.dir); var sLen = Math.min(30, Math.ceil((Math.sqrt(d3(R.px, R.py, R.pz, e.x, e.y, e.z)) + 8) / 1.5)); for (k = 0; k < sLen; k++) add('fx_white_bolt', e.x + e.sn.dir[0] * (e.r + 1 + k * 1.5), e.y + e.sn.dir[1] * (e.r + 1 + k * 1.5), e.z + e.sn.dir[2] * (e.r + 1 + k * 1.5), sa[0], sa[1], 0, 2.3, [1.0 + 0.5 * sq, 0.12, 0.2], 1); add('fx_white', e.x + e.sn.dir[0] * (e.r + 1.5), e.y + e.sn.dir[1] * (e.r + 1.5), e.z + e.sn.dir[2] * (e.r + 1.5), 0, 0, 0, 2 + 5 * sq, [1.4, 0.2, 0.3], 1); return; }
      if (e.fz) { var fk2 = e.fz / e.d.bomb.fuse, fr2 = e.d.bomb.r; for (k = 0; k < 28; k++) { var fa = k / 28 * Math.PI * 2; add('fx_spark', e.x + Math.cos(fa) * fr2, e.y - e.r * 0.4, e.z + Math.sin(fa) * fr2, 0, 0, 0, 2, [1.2, 0.4, 0.15], 1); if (k % 2 === 0) add('fx_spark', e.x + Math.cos(fa) * fr2 * fk2, e.y - e.r * 0.4, e.z + Math.sin(fa) * fr2 * fk2, 0, 0, 0, 2.6, [1.5, 0.7, 0.2], 1); } return; }
      if (e.bk) { var bq = e.bk.t / e.d.blink.tele; for (k = 0; k < 20; k++) { var ba3 = k / 20 * Math.PI * 2 + t; add('fx_spark', e.bk.dest[0] + Math.cos(ba3) * 4 * (1.2 - 0.5 * bq), e.bk.dest[1] - 1, e.bk.dest[2] + Math.sin(ba3) * 4 * (1.2 - 0.5 * bq), 0, 0, 0, 2.4, [0.7, 0.35, 1.4], 1); } return; }
      if (!big) return;
      var wind = sh && e.fire > 0 && e.fire < 0.8 ? 1 - e.fire / 0.8 : (e.summon && e.sumT > 0 && e.sumT < 1 ? 1 - e.sumT : 0);
      if (wind <= 0) return;
      var col = sh ? [1.3, 0.18, 0.22] : [0.9, 0.3, 1.3], rr = e.r * (1.0 + wind * 0.7);
      for (k = 0; k < 22; k++) { var a = k / 22 * Math.PI * 2 + t * 0.8; add('fx_spark', e.x + Math.cos(a) * rr, e.y - e.r * 0.4, e.z + Math.sin(a) * rr, 0, 0, 0, 2.2 + wind * 2, col, 1); }
      if (sh && !sh.ring) { var ad = nrm([R.px - e.x, R.py - e.y, R.pz - e.z]), aa = angOf(ad); for (k = 0; k < 14; k++) add('fx_white_bolt', e.x + ad[0] * (e.r + 1 + k * 1.3), e.y + ad[1] * (e.r + 1 + k * 1.3), e.z + ad[2] * (e.r + 1 + k * 1.3), aa[0], aa[1], 0, 2.1, col, 1); }   // 连续瞄准线（片段重叠）
    });
    // 首领激光：蓄力时是一条细红线 + 起点聚能球；发射瞬间变成粗大的白热光束（片段重叠，连续无断点）
    R.enemies.forEach(function (e) {
      var L = e.laser; if (!L) return;
      var oo = [e.x + L.dir[0] * e.r, e.y + L.dir[1] * e.r, e.z + L.dir[2] * e.r], la = angOf(L.dir), firing = L.t >= L.charge, kq = firing ? 1 - (L.t - L.charge) / L.fire : L.t / L.charge, lb = basis(L.dir), kk, nn2 = 0;
      for (kk = 0; kk < 90; kk += 1.6, nn2++) {
        var lx = oo[0] + L.dir[0] * kk, ly = oo[1] + L.dir[1] * kk, lz = oo[2] + L.dir[2] * kk;
        if (firing) {
          add('fx_white_bolt', lx, ly, lz, la[0], la[1], 0, 3.6 * (0.6 + 0.4 * kq), null, 1);
          if (nn2 % 2 === 0) { var ph2 = kk * 0.45 + t * 20, cc = Math.cos(ph2) * 0.9, ss = Math.sin(ph2) * 0.9; add('fx_white', lx + lb[0][0] * cc + lb[1][0] * ss, ly + lb[0][1] * cc + lb[1][1] * ss, lz + lb[0][2] * cc + lb[1][2] * ss, 0, 0, 0, 2.6 * kq, [1.4, 0.2, 0.3], 1); }
        } else add('fx_white_bolt', lx, ly, lz, la[0], la[1], 0, 2.2, [1.0 + 0.4 * kq, 0.12, 0.18], 1);
      }
      add('fx_white', oo[0], oo[1], oo[2], 0, 0, 0, firing ? 9 * kq : 3 + 7 * kq, firing ? null : [1.4, 0.2, 0.3], 1);
    });
    R.shots.forEach(function (s) { var a = angOf([s.vx, s.vy, s.vz]); add(s.model, s.x, s.y, s.z, a[0], a[1], 0, s.size || (s.model === 'fx_spark' ? 3 : 2.4), s.tint, 2); });
    R.ebullets.forEach(function (b) { var ba = angOf([b.vx, b.vy, b.vz]); add('fx_white_bolt', b.x, b.y, b.z, ba[0], ba[1], 0, b.snipe ? 10 : b.big ? 5 : 3.2, b.snipe ? [1.5, 0.5, 0.6] : [1.35, 0.22, 0.3], 1); add('fx_white', b.x, b.y, b.z, 0, 0, 0, b.big ? 6 : 2.2, b.big ? [1.4, 0.3, 0.35] : null, 1); });
    R.missiles.forEach(function (m) { if (m.hide) return; var a = m.fall ? (m.launch ? angOf(m.launch.dir) : [0, 90]) : angOf(m.dir); add(m.model, m.x, m.y, m.z, a[0], a[1], 0, m.size || 2.2, m.tint, 2); });
    R.mods.forEach(function (md) { if (md.orb) md.orb.forEach(function (o) {
      add('fx_white', o[0], o[1], o[2], t * 50, 45, 0, md.osz * 0.65, md.tint, 2);
      var an = Math.atan2(o[2] - R.pz, o[0] - R.px), rr2 = Math.hypot(o[0] - R.px, o[2] - R.pz);
      for (var j = 1; j <= 3; j++) { var a2 = an - j * 0.2; add('fx_white', R.px + Math.cos(a2) * rr2, o[1], R.pz + Math.sin(a2) * rr2, 0, 0, 0, md.osz * 0.65 * (1 - j * 0.22), md.tint, 2); }
    }); });
    R.mines.forEach(function (mn) { add('fx_white', mn.x, mn.y, mn.z, t * 120, 45, 0, 3 + Math.sin(t * 3) * 0.3, mn.tint, 2); });
    R.booms.forEach(function (b) { var bd = b.out ? [-b.d[0], -b.d[1], -b.d[2]] : nrm([b.x - R.px, b.y - R.py, b.z - R.pz]); for (var j = 1; j <= 4; j++) add('fx_white', b.x + bd[0] * j * 1.1, b.y + bd[1] * j * 1.1, b.z + bd[2] * j * 1.1, 0, 0, 0, b.size * (1 - j * 0.2) * 0.7, b.tint, 2);
      add('fx_white_bolt', b.x, b.y, b.z, t * 900, 0, 0, b.size, b.tint, 2); add('fx_white_bolt', b.x, b.y, b.z, t * 900 + 90, 0, 0, b.size, b.tint, 2); });
    // 闪电：锯齿主干（白芯 + 两侧主色光边）+ 落点闪光
    R.strikes.forEach(function (st) {
      if (!st.pts) { st.pts = []; for (var q = 0; q <= 7; q++) { var f = q / 7; st.pts.push([st.x + (q && q < 7 ? rand(-2.2, 2.2) * (1 - f * 0.5) : 0), st.y + 34 * (1 - f), st.z + (q && q < 7 ? rand(-2.2, 2.2) * (1 - f * 0.5) : 0)]); } }
      var fl = st.life / 0.22, flick = true;
      for (var q2 = 0; q2 < 7; q2++) {
        var p0 = st.pts[q2], p1 = st.pts[q2 + 1], dx = p1[0] - p0[0], dy = p1[1] - p0[1], dz = p1[2] - p0[2], L = len3(dx, dy, dz) || 1, ang = angOf([dx / L, dy / L, dz / L]), mx = (p0[0] + p1[0]) / 2, my = (p0[1] + p1[1]) / 2, mz2 = (p0[2] + p1[2]) / 2;
        add('fx_white_bolt', mx, my, mz2, ang[0], ang[1], 0, L * 1.05 * (0.5 + 0.5 * fl), null, 2);
        if (flick) { add('fx_white_bolt', mx + 0.28, my, mz2, ang[0], ang[1], 0, L * 1.02 * fl, st.tint, 2); add('fx_white_bolt', mx - 0.28, my, mz2 - 0.28, ang[0], ang[1], 0, L * 1.02 * fl, st.tint, 2); }
      }
      add('fx_white', st.x, st.y + 0.5, st.z, 0, 0, 0, 7 * fl, null, 2); add('fx_white', st.x, st.y + 0.5, st.z, t * 50, 45, 0, 11 * fl, st.tint, 2);
    });
    // 光束：细一些，并跳过靠近镜头的一段（打身后敌人时不会从镜头前横穿）
    // 光束：连续的白热芯（片段相互重叠、不随寿命缩短，避免一段一段）+ 缠绕的螺旋光丝 + 枪口光球 + 末端光斑
    R.beams.forEach(function (b) {
      var a = angOf(b.d), w = clamp(b.life / 0.2, 0.25, 1), tn = b.tint || lin('#5CF2DC'), bs = basis(b.d), step = soft ? 2.4 : 1.5, k, n = 0;
      var cs = step * 1.6;                         // 每段长度 = 步长 x 1.6，保证首尾重叠
      for (k = 0; k < b.len; k += step, n++) {
        var px = b.x + b.d[0] * k, py = b.y + b.d[1] * k, pz = b.z + b.d[2] * k;
        add('fx_white_bolt', px, py, pz, a[0], a[1], 0, cs * (0.78 + 0.22 * w) * 1, null, 1);   // kind 1：只裁掉贴近镜头的段，不会被视线通道切成断点
        if (n % 2 === 0) {
          var ph = k * 0.55 + t * 38, c1 = Math.cos(ph) * 0.5 * w, s1 = Math.sin(ph) * 0.5 * w;
          add('fx_white', px + bs[0][0] * c1 + bs[1][0] * s1, py + bs[0][1] * c1 + bs[1][1] * s1, pz + bs[0][2] * c1 + bs[1][2] * s1, 0, 0, 0, 1.7 * w, tn, 1);
        }
      }
      add('fx_white', b.x, b.y, b.z, 0, 0, 0, 5 * w, null, 1); add('fx_white', b.x, b.y, b.z, t * 50, 45, 0, 7.5 * w, tn, 1);
      var ex = b.x + b.d[0] * b.len, ey = b.y + b.d[1] * b.len, ez = b.z + b.d[2] * b.len;
      add('fx_white', ex, ey, ez, t * 50, 45, 0, 6 * w, tn, 1);
    });
    R.turrets.forEach(function (tu) { var x = tu.x, y = tu.y, z = tu.z; if (tu.dep > 0) { var k = 1 - tu.dep / tu.dep0; x = lerp(tu.from[0], tu.x, k); y = lerp(tu.from[1], tu.y, k) + Math.sin(k * Math.PI) * 3; z = lerp(tu.from[2], tu.z, k); } add('prop_turret', x, y - 1, z, tu.yaw + (tu.dep > 0 ? tu.dep * 720 : 0), 0, 0, 1.5, null, 2); });
    R.fires.forEach(function (fi) { add('fx_spark', fi.x, fi.y, fi.z, t * 60, 0, 0, 4 + Math.sin(t * 4 + fi.x) * 0.6, null, 2); });
    R.gems.forEach(function (g) { add(g.v >= 10 ? 'prop_meteor_shard' : 'fx_spark_teal', g.x, g.y + Math.sin(t * 4 + g.x) * 0.2, g.z, t * 120, g.v >= 10 ? 0 : 45, 0, g.v >= 10 ? 1.6 : g.v >= 5 ? 6 : 4, null, 2); });
    R.pickups.forEach(function (p) { add(p.kind === 'heal' ? 'prop_medkit' : p.kind === 'ammo' ? 'prop_supply_crate' : 'prop_loot_pod', p.x, p.y, p.z, t * 90, 0, 0, p.kind === 'heal' ? 4 : p.kind === 'ammo' ? 3.2 : 4.5, null, 2); });
    // 冲击波：水平光环（以机甲高度展开），从斜上方看是椭圆，不再正对镜头挡住视线
    R.novas.forEach(function (n) {
      var dur = n.dur || 0.45, k = 1 - n.life / dur, e = 1 - Math.pow(1 - k, 2.2), rr = n.r * (0.25 + 0.75 * e), cnt = soft || R.novas.length > 6 ? 24 : 44, i, a;
      var mdl = n.tint ? 'fx_white' : (n.color === '#7CF29A' || n.color === '#5CF2DC' ? 'fx_spark_teal' : 'fx_shield');
      for (i = 0; i < cnt; i++) {
        a = i / cnt * Math.PI * 2; var cx = Math.cos(a), sz = Math.sin(a);
        add(mdl, n.x + cx * rr, n.y - 1, n.z + sz * rr, 0, 0, 0, 3.6 * (1 - k * 0.65), n.tint, 2);                  // 外环（主色）
        if (i % 2 === 0) add('fx_white', n.x + cx * rr * 0.86, n.y - 1, n.z + sz * rr * 0.86, 0, 0, 0, 2 * (1 - k), null, 2); // 内环（白热）
      }
      if (!soft) for (i = 0; i < 10; i++) { a = i / 10 * Math.PI * 2 + k; for (var h = 0; h < 3; h++) add(mdl, n.x + Math.cos(a) * rr * 0.92, n.y - 1 + (h + 1) * 1.4 * Math.sin(k * Math.PI), n.z + Math.sin(a) * rr * 0.92, 0, 0, 0, (2.4 - h * 0.6) * (1 - k), n.tint, 2); }   // 环上升起的光柱
      if (k < 0.28) add('fx_white', n.x, n.y - 0.5, n.z, t * 50, 45, 0, 10 * (1 - k / 0.28), null, 2);              // 起爆闪光
    });
    // 治疗力场：机甲脚下的水平光环 + 缓慢上升的小光点
    R.zones.forEach(function (z) { for (var i = 0; i < 24; i++) { var a = i / 24 * Math.PI * 2 + t * 0.6; add('fx_spark_teal', z.x + Math.cos(a) * z.r, z.y - 2.2, z.z + Math.sin(a) * z.r, 0, 0, 0, 2.6, null, 2); }
      for (var q3 = 0; q3 < 16; q3++) { var a3 = -q3 / 16 * Math.PI * 2 - t * 0.9; add('fx_white', z.x + Math.cos(a3) * z.r * 0.55, z.y - 2.2, z.z + Math.sin(a3) * z.r * 0.55, 0, 0, 0, 1.8, HEALC, 2); }
      for (var q = 0; q < 6; q++) { var b = (q * 1.7 + t * 0.8) % 1, a2 = q * 1.05 + t * 0.3; add('fx_spark_teal', z.x + Math.cos(a2) * z.r * 0.7, z.y - 2 + b * 5, z.z + Math.sin(a2) * z.r * 0.7, 0, 0, 0, 2 * (1 - b), null, 2); } });
    R.parts.forEach(function (p) { if (soft && (p.id = (p.id || Math.random())) < 0.5) return; var kk = p.life / p.max, s = p.size * clamp(kk, p.hot ? 0.06 : 0.15, 1) * 2; add(p.model, p.x, p.y, p.z, p.life * 200, p.life * 140, 0, s, p.hot ? hotRamp(p.tint || EMBER, kk) : p.tint, 2); });
    R.occ = occ; R.occMax = Math.max(R.occMax || 0, occ);
    lastVP = E.render({ env: { bg: R.ch.env.bg, ambient: R.ch.env.ambient, fog: [140, 420], key: R.ch.env.key, fill: R.ch.env.fill, bloom: { threshold: 0.9, mix: soft ? 0.28 : 0.4 } },
      eye: eye, target: tgt, fov: fov, aspect: aspect, near: 0.5, far: 6000, draws: draws, stars: stars, shadow: null });
  }
  function drawOverlay() {
    var V = A.view(), cv = document.getElementById('hud2d'), ctx = cv.getContext('2d'), s = V.s, w = V.w, h = V.h;
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, cv.width, cv.height);
    if (!lastVP) return;
    ctx.setTransform(V.dpr, 0, 0, V.dpr, 0, 0);
    function Pj(x, y, z) { return E.project(lastVP, [x, y, z], w, h); }
    function onScreen(q) { return q && q[0] > 0 && q[0] < w && q[1] > 0 && q[1] < h; }
    var u = Math.max(0.55, s * 1.5);
    ctx.textAlign = 'center';
    // 地点标签与搜刮进度
    R.nodes.forEach(function (n) {
      if (n.state === 'hidden') return;
      var q = Pj(n.x, n.y, n.z); if (!onScreen(q)) return;
      var col = n.state === 'done' ? 'rgba(163,171,207,.6)' : n.info.color, dist = Math.round(Math.sqrt(dd(n, P())));
      ctx.font = '700 ' + Math.round(13 * u) + 'px "Noto Sans SC", sans-serif';
      var label = n.info.name + (n.type === 'gate' ? (n.state === 'open' ? '（已开启）' : '（未开启）') : n.state === 'done' ? (n.failed ? '（失败）' : '（完成）') : '') + '  ' + dist + ' 米';
      ctx.lineWidth = 3 * u; ctx.strokeStyle = 'rgba(9,12,34,.9)'; ctx.strokeText(label, q[0], q[1] - 30 * u); ctx.fillStyle = col; ctx.fillText(label, q[0], q[1] - 30 * u);
      if (n.type === 'derelict' && n.state !== 'done') {
        var e2 = Pj(n.x + camBasis.r[0] * 15, n.y + camBasis.r[1] * 15, n.z + camBasis.r[2] * 15), rr = e2 ? Math.hypot(e2[0] - q[0], e2[1] - q[1]) : 40;
        ctx.strokeStyle = 'rgba(245,165,36,.55)'; ctx.lineWidth = 2 * u; ctx.beginPath(); ctx.arc(q[0], q[1], rr, 0, Math.PI * 2); ctx.stroke();
        if (n.progress > 0) { ctx.strokeStyle = '#F5A524'; ctx.lineWidth = 5 * u; ctx.beginPath(); ctx.arc(q[0], q[1], rr, -Math.PI / 2, -Math.PI / 2 + n.progress * Math.PI * 2); ctx.stroke(); }
      }
      if (n.type === 'hunt' && n.state === 'active') { ctx.fillStyle = '#FF8A3A'; ctx.fillText((n.got || 0) + ' / ' + n.need + '　' + Math.ceil(n.timer) + ' 秒', q[0], q[1] - 46 * u); }
      if (n.type === 'ambush' && n.state === 'active') { ctx.fillStyle = '#B47CFF'; ctx.fillText('第 ' + n.wave + ' / 3 波', q[0], q[1] - 46 * u); }
      if (n.type === 'distress' && n.state === 'active') {
        ctx.fillStyle = 'rgba(9,12,34,.85)'; ctx.fillRect(q[0] - 40 * u, q[1] - 22 * u, 80 * u, 8 * u);
        ctx.fillStyle = '#5CF2DC'; ctx.fillRect(q[0] - 40 * u, q[1] - 22 * u, 80 * u * Math.max(0, n.pod.hp / n.pod.max), 8 * u);
        ctx.fillStyle = '#EDE6D6'; ctx.fillText(Math.ceil(n.timer) + ' 秒', q[0], q[1] - 46 * u);
      }
    });
    R.enemies.forEach(function (e) {
      if (!(e.d.boss || e.d.elite) || !e.d.shoot || !(e.fire > 0 && e.fire < 0.8)) return;
      var wq = Pj(e.x, e.y + e.r * 1.4, e.z); if (!onScreen(wq)) return;
      ctx.font = '700 ' + Math.round(26 * u) + 'px "Noto Sans SC", sans-serif'; ctx.fillStyle = '#FF4D6A'; ctx.globalAlpha = 0.75 + 0.25 * Math.sin(R.t * 8); ctx.fillText('! 预警', wq[0], wq[1]); ctx.globalAlpha = 1;
    });
    // 锁定框：当前自动瞄准的目标
    if (R.target && R.target.hp > 0) {
      var tq = Pj(R.target.x, R.target.y, R.target.z);
      if (onScreen(tq)) {
        var bs = clamp(R.target.r * 900 / Math.max(5, tq[2]) * s, 14 * u, 70 * u), kk = bs * 0.4;
        ctx.strokeStyle = '#FF4D6A'; ctx.lineWidth = 2.5 * u; ctx.beginPath();
        [[-1, -1], [1, -1], [1, 1], [-1, 1]].forEach(function (c) { var x = tq[0] + c[0] * bs, y = tq[1] + c[1] * bs; ctx.moveTo(x, y - c[1] * kk); ctx.lineTo(x, y); ctx.lineTo(x - c[0] * kk, y); });
        ctx.stroke();
        if (R.target.d.elite || R.target.d.boss || R.target.max > 80) { ctx.fillStyle = 'rgba(9,12,34,.85)'; ctx.fillRect(tq[0] - bs, tq[1] - bs - 10 * u, bs * 2, 5 * u); ctx.fillStyle = '#FF4D6A'; ctx.fillRect(tq[0] - bs, tq[1] - bs - 10 * u, bs * 2 * clamp(R.target.hp / R.target.max, 0, 1), 5 * u); }
      }
    }
    var pp = Pj(R.px, R.py - 3.2, R.pz);
    if (pp && !R.over) {
      var bw = 60 * u, bh = 7 * u; ctx.fillStyle = 'rgba(9,12,34,.85)'; ctx.fillRect(pp[0] - bw / 2 - 2, pp[1] - 2, bw + 4, bh + 4);
      ctx.fillStyle = R.hull / hullMax() < 0.3 ? '#E0458C' : '#7CF29A'; ctx.fillRect(pp[0] - bw / 2, pp[1], bw * clamp(R.hull / hullMax(), 0, 1), bh);
    }
    R.nums.forEach(function (n) {
      var q = Pj(n.x, n.y, n.z); if (!onScreen(q)) return;
      ctx.globalAlpha = clamp(n.life / 0.35, 0, 1); ctx.font = '700 ' + Math.round((n.crit ? 17 : 12) * u) + 'px "Noto Sans SC", sans-serif';
      ctx.lineWidth = 3 * u; ctx.strokeStyle = 'rgba(9,12,34,.9)'; ctx.strokeText(n.v, q[0], q[1]); ctx.fillStyle = n.crit ? '#F5A524' : (n.col || '#EDE6D6'); ctx.fillText(n.v, q[0], q[1]);
    });
    ctx.globalAlpha = 1;
    R.bubbles.forEach(function (b) {
      var q = Pj(R.px, R.py + 4.2, R.pz); if (!onScreen(q)) return;
      ctx.font = '700 ' + Math.round(13 * u) + 'px "Noto Sans SC", sans-serif';
      var tw = ctx.measureText(b.text).width + 16 * u, th = 24 * u;
      ctx.globalAlpha = clamp(b.life / 0.3, 0, 1); ctx.fillStyle = 'rgba(237,230,214,.95)'; ctx.fillRect(q[0] - tw / 2, q[1] - th, tw, th);
      ctx.beginPath(); ctx.moveTo(q[0] - 5 * u, q[1]); ctx.lineTo(q[0] + 5 * u, q[1]); ctx.lineTo(q[0], q[1] + 6 * u); ctx.fill();
      ctx.fillStyle = '#1A2046'; ctx.textBaseline = 'middle'; ctx.fillText(b.text, q[0], q[1] - th / 2); ctx.textBaseline = 'alphabetic'; ctx.globalAlpha = 1;
    });
    // 屏幕外指示：目标、星门、精英与首领、身边看不见的敌人（立体方向换算到屏幕平面）
    var marks = [], goal = !objectiveDone() ? R.event : (R.gate.state === 'open' ? R.gate : null);
    if (goal) marks.push({ o: goal, col: goal.info.color, label: goal.type === 'gate' ? '星门' : goal.info.name });
    R.enemies.forEach(function (e) { if (e.d.elite || e.d.boss) marks.push({ o: e, col: '#FF4D6A' }); });
    R.enemies.filter(function (e) { return !e.d.ore && !e.d.elite && !e.d.boss && dd(e, P()) < 18 * 18; }).slice(0, 6).forEach(function (e) { marks.push({ o: e, col: 'rgba(255,77,106,.85)', small: true }); });
    marks.forEach(function (m) {
      var o = m.o, q = Pj(o.x, o.y, o.z);
      if (q && q[0] > 30 && q[0] < w - 30 && q[1] > 30 && q[1] < h - 30) return;
      var rel = [o.x - camBasis.eye[0], o.y - camBasis.eye[1], o.z - camBasis.eye[2]], x = dot(rel, camBasis.r), y = dot(rel, camBasis.u);
      if (Math.abs(x) + Math.abs(y) < 0.01) y = -1;
      var ang = Math.atan2(-y, x), rr = Math.min(w, h) * (m.small ? 0.46 : 0.4), ex = clamp(w / 2 + Math.cos(ang) * rr * (w / h), 24 * u, w - 24 * u), ey = clamp(h / 2 + Math.sin(ang) * rr, 24 * u, h - 24 * u);
      var k2 = m.small ? 0.6 : 1; ctx.save(); ctx.translate(ex, ey); ctx.rotate(ang); ctx.fillStyle = m.col; ctx.beginPath(); ctx.moveTo(18 * u * k2, 0); ctx.lineTo(-10 * u * k2, -12 * u * k2); ctx.lineTo(-10 * u * k2, 12 * u * k2); ctx.fill(); ctx.restore();
      if (m.label) { ctx.font = '700 ' + Math.round(12 * u) + 'px "Noto Sans SC", sans-serif'; ctx.fillStyle = m.col; ctx.fillText(m.label + ' ' + Math.round(Math.sqrt(dd(o, P()))) + '米', ex - Math.cos(ang) * 34 * u, ey - Math.sin(ang) * 26 * u + 4 * u); }
    });
    if (R.outside) { ctx.font = '700 ' + Math.round(16 * u) + 'px "Noto Sans SC", sans-serif'; ctx.fillStyle = '#FF4D6A'; ctx.fillText('已到达战场边缘，正在返回', w / 2, h * 0.3); }
    // 触控提示：左半屏摇杆，右半屏视角
    if (joy.id !== null) {
      ctx.strokeStyle = 'rgba(92,242,220,.7)'; ctx.lineWidth = 3 * u; var jr = 60 * u; ctx.beginPath(); ctx.arc(joy.cx, joy.cy, jr, 0, Math.PI * 2); ctx.stroke();
      ctx.fillStyle = 'rgba(237,230,214,.55)'; ctx.beginPath(); ctx.arc(joy.cx + joy.dx * jr, joy.cy - joy.dy * jr, 22 * u, 0, Math.PI * 2); ctx.fill();
    }
    if (look.id !== null) { ctx.strokeStyle = 'rgba(245,165,36,.6)'; ctx.lineWidth = 2 * u; ctx.beginPath(); ctx.arc(look.x, look.y, 26 * u, 0, Math.PI * 2); ctx.stroke(); }
  }

  // ------------------------------------------------------------------ 界面
  var PIX = function (rows, colors) { var pal = [], idx = {}, px = '', B = '0123456789abcdefghijklmnopqrstuvwxyz'; rows.forEach(function (r) { for (var i = 0; i < r.length; i++) { var c = r[i]; if (c === '.') { px += '.'; continue; } if (!(c in idx)) { idx[c] = pal.length; pal.push(colors[c]); } px += B[idx[c]]; } }); return { w: rows[0].length, h: rows.length, pal: pal, px: px }; };
  var ICON = {
    missile: PIX(['...aa...', '..abba..', '..abba..', '..abba..', '..abba..', '.cabbac.', '.c.dd.c.', '...ee...'], { a: '#D6332A', b: '#E8E3D6', c: '#3E6E99', d: '#FFB347', e: '#FF7A3A' }),
    nova: PIX(['..aaaa..', '.a....a.', 'a..bb..a', 'a.bccb.a', 'a.bccb.a', 'a..bb..a', '.a....a.', '..aaaa..'], { a: '#57B8FF', b: '#9DF7EC', c: '#FFFFFF' }),
    blades: PIX(['...a....', '..ab....', '.....aa.', 'a..c..ba', 'ab..c..a', '.aa.....', '....ba..', '....a...'], { a: '#5CF2DC', b: '#9DF7EC', c: '#E0458C' }),
    hull: PIX(['.aaaaaa.', 'abbbbbba', 'abccccba', 'abccccba', 'abccccba', '.abccba.', '..abba..', '...aa...'], { a: '#3E5878', b: '#7CF29A', c: '#2E7A4A' }),
    engine: PIX(['..aaaa..', '.abbbba.', '.abbbba.', '..aaaa..', '...cc...', '..cddc..', '..cddc..', '...cc...'], { a: '#5A6175', b: '#9AA3B5', c: '#FF8A3A', d: '#FFE7A3' }),
    magnet: PIX(['aa....aa', 'aa....aa', 'bb....bb', 'bb....bb', 'bb....bb', '.bb..bb.', '..bbbb..', '........'], { a: '#E8E3D6', b: '#E0458C' }),
    power: PIX(['....a...', '...aa...', '..aab...', '.aabbbb.', '....bba.', '....ba..', '...ba...', '...a....'], { a: '#F5A524', b: '#FFE7A3' }),
    cooling: PIX(['...a....', '.a.a.a..', '..aaa...', 'aaabaaa.', '..aaa...', '.a.a.a..', '...a....', '........'], { a: '#57B8FF', b: '#FFFFFF' }),
    repair: PIX(['...aa...', '...aa...', '.aaaaaa.', '.aaaaaa.', '...aa...', '...aa...', '........', '........'], { a: '#7CF29A' }),
    ammo: PIX(['..aa....', '.abba...', '.abba.aa', '.abbaabb', '.abbaabb', '.accaacc', '.adda.dd', '........'], { a: '#5A6175', b: '#FF8A3A', c: '#E8E3D6', d: '#3E6E99' }),
    heal: PIX(['..a..a..', '.aaaaaa.', '.aaaaaa.', '..aaaa..', '...aa...', '........', '........', '........'], { a: '#FF6B8A' })
  };
  C.ICON = ICON;
  var ui = function () { return document.getElementById('ui'); };
  function el(tag, cls, html) { var e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
  function buildHUD() {
    var u = ui(); u.innerHTML = '';
    var top = el('section', 'sv-top');
    top.innerHTML = '<div class="sv-xp"><i></i><b></b></div><div class="sv-row"><div class="sv-left"><span class="cx-hull"></span><span class="cx-cr"></span><span class="cx-src"></span></div>' +
      '<div class="cx-mid"><b class="cx-ch"></b><span class="cx-dist"></span></div><div class="sv-right"></div></div><div class="sv-slots"></div>' +
      '<div class="sv-boss" hidden><b></b><div class="sv-bossbar"><i></i></div></div><div class="sv-banner" hidden></div>';
    u.appendChild(top);
    lvDefer = false; lvManual = false;
    var lb = el('button', 'cx-lvbadge'); lb.hidden = true; lb.onclick = function () { lvDefer = false; lvManual = true; }; u.appendChild(lb); 
    var pb = el('button', 'sbtn sv-pause cx-pause', '暂停'); pb.onclick = openPause; top.querySelector('.sv-right').appendChild(pb);
    var cop = C.char(R.pilot), card = el('section', 'panel sv-cc cx-cop');
    card.innerHTML = '<span class="ic">' + A.catIcon(R.pilot, 54) + '</span><div><b>' + cop.name + ' <small>' + (R.match ? '专属 +20%' : '驾驶员') + '</small></b><small>' + cop.support.name + '</small><div class="sv-cd"><i></i></div></div><em></em>';
    u.appendChild(card);
    var act = el('button', 'cx-active', '<span class="ic">' + A.catIcon(R.mech, 74) + '</span><b>' + M().active.name + '</b><i class="cx-cdmask"></i><em></em>');
    act.addEventListener('pointerdown', function (e) { e.stopPropagation(); castActive(); });
    u.appendChild(act);
    var dg = el('button', 'cx-dodge', '<b>' + nitroOf().name.replace('氮气', '氮气<br>') + '</b><i class="cx-cdmask"></i>'); dg.addEventListener('pointerdown', function (e) { e.stopPropagation(); dodge(); }); u.appendChild(dg);
    var sb = null;
    if (R.sub) { sb = el('button', 'cx-sub', '<b>' + R.sub.def.n + '</b><em></em><i class="cx-cdmask"></i>'); sb.style.setProperty('--sc', R.sub.def.color); sb.addEventListener('pointerdown', function (e) { e.stopPropagation(); fireSub(true); }); u.appendChild(sb); }
    var tip = el('div', 'cx-tip'); tip.hidden = true; u.appendChild(tip);
    var combo = el('div', 'cx-combo'); combo.hidden = true; u.appendChild(combo);
    hud = { top: top, card: card, act: act, dg: dg, sb: sb, tip: tip, combo: combo, t: 0, lvb: lb };
  }
  function updateHUD(dt) {
    hud.t -= dt; if (hud.t > 0) return; hud.t = 0.1;
    var top = hud.top;
    top.querySelector('.sv-xp i').style.width = (R.xp / xpNeed(R.level) * 100) + '%';
    top.querySelector('.sv-xp b').textContent = 'Lv ' + R.level;
    top.querySelector('.cx-hull').textContent = '耐久 ' + Math.ceil(R.hull) + ' / ' + hullMax();
    top.querySelector('.cx-cr').innerHTML = A.resIcon('credit', 30) + ' ' + R.credits.toLocaleString('zh-CN');
    top.querySelector('.cx-src').innerHTML = A.resIcon('shard', 30) + ' 星源 ' + R.src;
    top.querySelector('.cx-ch').textContent = '第 ' + R.ch.id + ' 章 ' + R.ch.name;
    top.querySelector('.cx-dist').textContent = (R.daily ? '每日挑战　第 ' + R.wave + ' 波　剩余 ' + mmss(C.DC_TIME - R.secT) + '　得分 ' + dcScore() : R.endless ? '无尽模式　第 ' + R.wave + ' 波　' + mmss(R.t) : '星域 ' + R.sector + ' / ' + SECTORS + '　' + (R.gate.state === 'open' ? '飞进星门' : R.objective)) + (R.danger > 1 ? '　危险 ' + R.danger : '') + (R.affix ? '　[' + R.affix.name + '：' + R.affix.desc + ']' : '');
    var slots = R.mods.map(function (md) { return '<span class="sv-slot">' + A.iconSVG(C.modIcon(md.m), 34) + '<b>' + (md.evo ? '★' : md.lv) + '</b></span>'; }).join('') + Object.keys(UPG).filter(function (k) { return lv(k) > 0 && k !== 'main' && k !== 'support'; }).map(function (k) { return '<span class="sv-slot">' + A.iconSVG(ICON[k], 34) + '<b>' + lv(k) + '</b></span>'; }).join('');
    if (hud.lvb) { var lbOn = R.pendingLevels > 0 && lvDefer && !paused; hud.lvb.hidden = !lbOn; if (lbOn) hud.lvb.textContent = '升级 ×' + R.pendingLevels + '　点击选择'; }
    var cb = hud.combo; if (R.combo >= 5 && R.comboT > 0) { cb.hidden = false; cb.innerHTML = '<b>' + R.combo + '</b><span>连击</span>'; } else cb.hidden = true;
    slots = '<span class="sv-slot">' + A.catIcon(R.mech, 30) + '<b>' + lv('main') + '</b></span>' + slots;
    if (top._slots !== slots) { top.querySelector('.sv-slots').innerHTML = slots; top._slots = slots; }
    var actb = document.querySelector('.cx-active'); if (actb) actb.classList.toggle('cx-boost', R.nitroT > 0);
    var bb = top.querySelector('.sv-boss'); bb.hidden = !R.boss || R.boss.hp <= 0;
    if (R.boss) { bb.querySelector('b').textContent = R.boss.d.name; bb.querySelector('i').style.width = clamp(R.boss.hp / R.boss.max, 0, 1) * 100 + '%'; }
    var bn = top.querySelector('.sv-banner'); bn.hidden = !(R.bannerT > 0); if (R.bannerT > 0) bn.textContent = R.banner;
    var st = supportStat();
    hud.card.querySelector('.sv-cd i').style.width = clamp(1 - R.supportCd / (C.char(R.pilot).support.cd * st.cd), 0, 1) * 100 + '%';
    hud.card.querySelector('em').textContent = 'Lv ' + st.lv;
    var frac = R.activeCd / activeCdMax();
    hud.act.querySelector('.cx-cdmask').style.height = (frac * 100) + '%';
    hud.act.querySelector('em').textContent = R.activeCd > 0 ? Math.ceil(R.activeCd) : '';
    hud.act.classList.toggle('ready', R.activeCd <= 0);
    hud.dg.querySelector('.cx-cdmask').style.height = (R.dodgeCd / (2.5 * (1 - fx('dodge'))) * 100) + '%';
    if (hud.sb && R.sub) { hud.sb.querySelector('em').textContent = R.sub.ammo + ' / ' + R.sub.cap; hud.sb.querySelector('.cx-cdmask').style.height = clamp(R.sub.cd / subCdMax(), 0, 1) * 100 + '%'; hud.sb.classList.toggle('empty', R.sub.ammo <= 0); }
    var n = R.nearNode;
    hud.tip.hidden = !n;
    if (n) hud.tip.innerHTML = '<b style="color:' + n.info.color + '">' + n.info.name + '</b>' + (n.type === 'derelict' && n.state === 'active' ? '搜刮中 ' + Math.round(n.progress * 100) + '%' : n.type === 'gate' && n.state !== 'open' ? '先完成本星域目标：' + R.objective : n.info.hint);
  }
  function modal(html) { var m = el('div', 'sv-modal'); m.innerHTML = html; ui().appendChild(m); return m; }
  // 升级选卡模式（设置里可选）：now 立即弹出 / later 稍后选择（默认：战斗不中断，HUD 上有“升级 xN”按钮）/ auto 自动选择
  var lvDefer = false, lvManual = false;
  function autoLevel() {
    R.pendingLevels--; C.sfx('level'); R.rr = R.rr || { free: 2, ad: 0 };
    var ids = choices(), best = ids[0], bs = -1, PRI = { hull: 45, power: 44, cooling: 43, engine: 40, magnet: 38, repair: 36 };
    ids.forEach(function (id) {
      var sc = id.indexOf('evo') === 0 ? 100 : id.indexOf('mod') === 0 ? 80 : id === 'main' ? 70 : id.indexOf('new') === 0 ? 60 : id === 'support' ? 50 : id === 'heal' ? (R.hull < hullMax() * 0.5 ? 90 : 10) : (PRI[id] || 30);
      if (sc > bs) { bs = sc; best = id; }
    });
    var nm = choiceInfo(best).name; applyChoice(best); afterChoice(); A.toast('自动升级：' + nm);
    R.gems.forEach(function (g) { if (dd(g, P()) < 2025) g.pull = true; });
  }
  function openLevelUp() {
    var mode = (C.save.settings && C.save.settings.lvMode) || 'later';
    if (lvDefer) return;                                                    // 已选择“稍后”：不再自动弹出，等玩家点 HUD 上的按钮
    if (mode === 'auto') { autoLevel(); return; }
    if (mode === 'later' && !lvManual) { lvDefer = true; return; }
    lvManual = false;
    paused = true; R.pendingLevels--; C.sfx('level'); R.rr = R.rr || { free: 2, ad: 0 };
    var m = modal('<div class="sv-lu"><h1>升级！</h1><p>选择一项强化</p><div class="sv-cards"></div><div class="lu-acts"><button class="btn" id="lu-rr"></button><button class="btn" id="lu-skip">跳过，回复 30% 耐久</button><button class="btn primary" id="lu-later">稍后选择<small>战斗继续，随时再点</small></button></div></div>'), box = m.querySelector('.sv-cards'), rr = m.querySelector('#lu-rr');
    function done() { m.remove(); paused = false; afterChoice(); R.gems.forEach(function (g) { if (dd(g, P()) < 2025) g.pull = true; }); }
    function fill() {
      box.innerHTML = ''; var ids = choices();
      ids.forEach(function (id) {
        var info = choiceInfo(id), b = el('button', 'sv-card' + (info.crew ? ' crew' : '') + (info.evo ? ' evo' : ''));
        b.innerHTML = '<span class="tag' + (info.crew ? ' shard' : '') + '">' + info.tag + '</span><span class="ic">' + info.icon + '</span><b>' + info.name + '</b><p>' + info.text + '</p>';
        b.onclick = function () { applyChoice(id); done(); };
        box.appendChild(b);
      });
      var left = R.rr.free > 0 ? 0 : Math.max(0, 3 - R.rr.ad);
      rr.textContent = R.rr.free > 0 ? '刷新选项（免费 ' + R.rr.free + ' 次）' : left > 0 ? '看广告 刷新选项（还可 ' + left + ' 次）' : '刷新次数已用完'; rr.disabled = R.rr.free <= 0 && left <= 0;
      rr.className = 'btn' + (R.rr.free <= 0 && left > 0 ? ' cx-adbtn' : '');
    }
    rr.onclick = function () {
      if (R.rr.free > 0) { R.rr.free--; C.sfx('click'); fill(); return; }
      if (R.rr.ad >= 2) return;
      C.showAd('刷新升级选项', function (r) { if (!r.success) { A.toast('需要完整看完广告才能刷新'); return; } R.rr.ad++; C.sfx('click'); fill(); });
    };
    m.querySelector('#lu-later').onclick = function () { m.remove(); paused = false; R.pendingLevels++; lvDefer = true; A.toast('升级已保留，点屏幕左侧的“升级”按钮随时选择'); };
    m.querySelector('#lu-skip').onclick = function () { R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.3); A.toast('跳过：回复 30% 耐久'); done(); };
    fill();
  }
  function openShop(n) {
    paused = true;
    var disc = 1;
    var offers = [
      { name: '紧急维修', text: '修复 50% 耐久', cost: Math.round(150 * disc), go: function () { R.hull = Math.min(hullMax(), R.hull + hullMax() * 0.5); } },
      { name: '强化芯片', text: '立即升级 1 次', cost: Math.round(260 * disc), go: function () { R.pendingLevels++; } },
      { name: '星魂结晶', text: '驾驶员碎片 +5', cost: Math.round(400 * disc), go: function () { R.frags[R.pilot] = (R.frags[R.pilot] || 0) + 5; } }
    ];
    var html = '<div class="panel sv-pbox"><h1>流浪商人</h1><p class="note">用本局收集的信用点交易。当前：' + R.credits + '</p><div class="cx-shop">';
    offers.forEach(function (o, i) { html += '<button class="sv-card cx-offer" data-i="' + i + '"' + (R.credits < o.cost ? ' disabled' : '') + '><b>' + o.name + '</b><p>' + o.text + '</p><span class="tag">' + o.cost + ' 信用点</span></button>'; });
    html += '</div><button class="btn" id="cx-leave">离开</button></div>';
    var m = modal(html);
    m.querySelectorAll('.cx-offer').forEach(function (b) { b.onclick = function () { var o = offers[+b.dataset.i]; if (R.credits < o.cost) return; R.credits -= o.cost; o.go(); A.toast('购买了 ' + o.name); m.remove(); openShop(n); }; });
    m.querySelector('#cx-leave').onclick = function () { m.remove(); paused = false; };
  }
  function openPause() {
    if (paused || !R) return; paused = true;
    var m = modal('<div class="panel sv-pbox"><h1>暂停</h1><div class="sv-btns"><button class="btn primary" id="sv-res">继续</button><button class="btn" id="sv-quit">撤退返回</button></div>' +
      '<p class="note">左半屏拖动飞行（朝镜头方向），右半屏拖动转视角；武器自动锁定开火。右下大按钮释放机甲技能（电脑空格），小按钮氮气推进（电脑 Shift，每台机甲氮气形态不同）。电脑：WASD 飞行，R/F 升降，方向键转视角。每个星域完成箭头指向的目标，星门就会开启。闯过 6 个星域、击败首领即可通关。</p></div>');
    m.querySelector('#sv-res').onclick = function () { m.remove(); paused = false; };
    m.querySelector('#sv-quit').onclick = function () { m.remove(); endRun(false, true); };
  }
  function openRevive() {
    if (R.ended) return; paused = true;
    var m = modal('<div class="panel sv-pbox"><h1>机甲被击毁</h1><p>看一段广告可以原地复活（耐久 50%），每局限一次。</p><div class="sv-btns">' +
      (R.adRevived ? '' : '<button class="btn primary" id="cx-ad">看广告复活</button>') + '<button class="btn" id="cx-end">结束远征</button></div></div>');
    var ad = m.querySelector('#cx-ad');
    if (ad) ad.onclick = function () {
      C.showAd('复活机甲', function (r) {
        if (!r.success) { A.toast('需要完整看完广告才能复活'); return; }
        m.remove(); R.adRevived = true; R.over = false; paused = false; R.hull = hullMax() * 0.5; R.iframe = 2; nova(P(), 14, 60, '#5CF2DC'); banner('复活！');
      });
    };
    m.querySelector('#cx-end').onclick = function () { m.remove(); endRun(false); };
  }
  function dcScore() { return R.kills * 10 + (R.wave - 1) * 100 + (R.bossKilled || 0) * 300 + (R.won || R.ended && !R.over ? 500 : 0); }
  function endRun(win, retreat) {
    if (!R || R.ended) return;
    R.ended = true; paused = true;
    var s = C.save, first = win && !s.cleared[R.ch.id];
    var dgm = 1 + 0.15 * (R.danger - 1), credits = Math.round((R.credits + R.kills * 3 + (win ? 800 * R.ch.id : 0) + (R.endless ? R.wave * 60 : 0)) * dgm), src = R.src + (first ? R.ch.first : 0) + (R.endless ? Math.floor(R.wave / 3) : win ? R.danger - 1 : 0);
    if (!win && !retreat && !R.endless) credits = Math.round(credits * 0.7);
    var dgUnlock = false; if (win && !R.endless && R.danger >= (s.dangerMax || 1) && (s.dangerMax || 1) < 10) { s.dangerMax = (s.dangerMax || 1) + 1; dgUnlock = true; }
    if (R.endless && !R.daily) s.endlessBest = Math.max(s.endlessBest || 0, R.wave);
    var dcScoreV = R.daily ? R.kills * 10 + (R.wave - 1) * 100 + (R.bossKilled || 0) * 300 + (win ? 500 : 0) : 0, dcFirst = false;
    if (R.daily) { var dcs = C.dailyChallenge().state; dcFirst = !dcs.done; dcs.done = true; dcs.runs++; dcs.best = Math.max(dcs.best, dcScoreV); s.dcBest = Math.max(s.dcBest || 0, dcScoreV); if (dcFirst) { credits += 800; src += 10 + (dcScoreV >= 1500 ? 5 : 0); } if (dmod('iron')) credits = Math.round(credits * 1.2); }
    s.credits += credits; s.src += src; s.runs++; s.totalKills = (s.totalKills || 0) + R.kills; if (win) s.bossKills = (s.bossKills || 0) + 1;
    var achNow = C.achReady();
    var reach = win ? SECTORS : R.sector; if (!R.endless) s.best[R.ch.id] = Math.max(s.best[R.ch.id] || 0, reach);
    s.daily.runs = (s.daily.runs || 0) + 1; s.daily.kills = (s.daily.kills || 0) + R.kills;
    if (R.sub) C.settleAmmo(R.sub.def.id, R.sub.used, R.sub.gained);
    Object.keys(R.frags).forEach(function (id) { s.frags[id] = (s.frags[id] || 0) + R.frags[id]; });
    if (win && !R.endless) { s.cleared[R.ch.id] = true; s.chapter = Math.max(s.chapter, Math.min(C.CHAPTERS.length, R.ch.id + 1)); }
    C.write();
    var fragTxt = Object.keys(R.frags).map(function (id) { return C.char(id).name + ' 碎片 +' + R.frags[id]; }).join('，');
    // 结算数据（UrhoX 版的 NanoVG 结算页读取）
    R.result = { win: win, retreat: retreat, credits: credits, src: src, first: first, dgUnlock: dgUnlock, dcScore: dcScoreV, dcFirst: dcFirst, achNow: achNow, fragTxt: fragTxt, subUsed: R.sub ? R.sub.used : 0, subName: R.sub ? R.sub.def.n : '' };
    var m = modal('<div class="panel sv-pbox"><h1>' + (R.daily ? (win ? '每日挑战完成' : '每日挑战结束') : R.endless ? '无尽模式结束' : win ? '远征成功' : retreat ? '已撤退返回' : '远征失败') + '</h1>' +
      '<dl class="sv-res"><div><dt>到达</dt><dd>' + (R.daily ? '得分 ' + dcScoreV : R.endless ? '第 ' + R.wave + ' 波' : win ? '通关' : R.sector + ' / ' + SECTORS) + '</dd></div><div><dt>用时</dt><dd>' + mmss(R.t) + '</dd></div><div><dt>击破</dt><dd>' + R.kills + '</dd></div><div><dt>信用点</dt><dd>+' + credits.toLocaleString('zh-CN') + '</dd></div><div><dt>星源</dt><dd>+' + src + '</dd></div></dl>' +
      '<dl class="sv-res mk-grow"><div><dt>本局等级</dt><dd>Lv ' + R.level + '</dd></div><div><dt>最高连击</dt><dd>' + (R.bestCombo || 0) + '</dd></div><div><dt>造成伤害</dt><dd>' + Math.round(R.dmgDealt || 0).toLocaleString('zh-CN') + '</dd></div><div><dt>承受伤害</dt><dd>' + Math.round(R.dmgTaken || 0).toLocaleString('zh-CN') + '</dd></div></dl>' +
      (achNow ? '<p class="note">有 ' + achNow + ' 个成就可以领取，去“每日”页领取星源。</p>' : '') +
      (first ? '<p class="note">首次通关奖励：星源 +' + R.ch.first + '。第 ' + (R.ch.id + 1 <= C.CHAPTERS.length ? (R.ch.id + 1) + ' 章已解锁。' : '全部章节已通关。') + '</p>' : '') +
      (dgUnlock ? '<p class="note">危险等级 ' + s.dangerMax + ' 已解锁（奖励更高，敌人更强）。</p>' : '') + (R.endless && !R.daily ? '<p class="note">无尽最高纪录：第 ' + s.endlessBest + ' 波。</p>' : '') + (R.daily ? '<p class="note">今日最高分 ' + C.dailyChallenge().state.best + (dcFirst ? '。首次完成奖励：信用点 +800，星源 +' + (10 + (dcScoreV >= 1500 ? 5 : 0)) + '。' : '。今日奖励已领取。') + '</p>' : '') +
      (!win && !retreat && !R.endless ? '<p class="note">远征失败只带回 70% 信用点。</p>' : '') + (fragTxt ? '<p class="note">' + fragTxt + '</p>' : '') +
      '<div class="sv-btns"><button class="btn cx-adbtn" id="cx-double">看广告 信用点翻倍</button><button class="btn" id="cx-share">分享战绩</button><button class="btn primary" id="cx-home">返回机库</button></div></div>');
    m.querySelector('#cx-share').onclick = function () {
      var tx = '我在《宇宙银河机甲》' + (R.daily ? '每日挑战拿到了 ' + dcScoreV + ' 分' : R.endless ? '无尽模式撑到了第 ' + R.wave + ' 波' : win ? '通关了第 ' + R.ch.id + ' 章' + (R.danger > 1 ? '（危险等级 ' + R.danger + '）' : '') : '闯到了星域 ' + R.sector) + '！用 ' + C.mech(R.mech).name + '击破 ' + R.kills + ' 个敌人，最高 ' + (R.bestCombo || 0) + ' 连击。来挑战我吧！';
      var ta = document.createElement('textarea'); ta.value = tx; ta.style.position = 'fixed'; ta.style.opacity = '0'; document.body.appendChild(ta); ta.select();
      try { document.execCommand('copy'); A.toast('战绩已复制，去分享给朋友吧'); } catch (e) { A.toast(tx); } ta.remove();
      if (navigator.share) { try { navigator.share({ text: tx }); } catch (e2) {} }
    };
    m.querySelector('#cx-double').onclick = function (ev) {
      var b = ev.currentTarget;
      C.showAd('结算奖励翻倍', function (r) {
        if (!r.success) { A.toast('需要完整看完广告才能领取'); return; }
        s.credits += credits; C.write(); b.disabled = true; b.textContent = '已翻倍 +' + credits.toLocaleString('zh-CN'); A.toast('信用点再 +' + credits.toLocaleString('zh-CN'));
      });
    };
    m.querySelector('#cx-home').onclick = function () { R = null; window.CosmicHub.open(); };
  }

  // ------------------------------------------------------------------ 新手引导（第一局）
  function startTutorial() {
    var steps = [
      { text: '左半屏拖动：朝镜头方向飞行。右半屏拖动：转动视角', done: function () { return len3(R.vx, R.vy, R.vz) > 5; } },
      { text: '武器会自动锁定开火。飞过去捡青色的能量升级', done: function () { return R.level >= 2; } },
      { text: '右下大按钮是机甲技能，旁边的小按钮是氮气推进，能冲刺并短暂无敌。点一下技能试试', done: function () { return R.tutorialSkill; } },
      { text: '跟着屏幕边缘的箭头，完成本星域的目标。目标可能在上方或下方', done: function () { return objectiveDone(); } },
      { text: '星门开启了！飞进去前往下一个星域', done: function () { return R.sector >= 2; } }
    ], i = 0;
    var box = document.createElement('div'); box.className = 'cx-tut'; ui().appendChild(box);
    function show() { box.innerHTML = '<span class="tag shard">新手引导 ' + (i + 1) + ' / ' + steps.length + '</span><b>' + steps[i].text + '</b>'; }
    show();
    R.tutorial = {
      event: function (k) { if (k === 'skill') R.tutorialSkill = true; },
      tick: function () {
        if (i >= steps.length || paused) return;
        if (steps[i].done()) { i++; C.sfx('pick'); if (i >= steps.length) { box.remove(); C.save.tutorialDone = true; C.write(); R.tutorial = null; A.toast('引导完成，祝你远征顺利！'); } else show(); }
      }
    };
  }

  // ------------------------------------------------------------------ 输入：左半屏摇杆移动，右半屏拖动转视角
  window.addEventListener('keydown', function (e) {
    if (!A || A.mode() !== 'cosmic-run') return;
    keys[e.code] = true;
    if ((e.code === 'Space' || e.code === 'KeyJ') && R) { e.preventDefault(); castActive(); }
    if ((e.code === 'ShiftLeft' || e.code === 'ShiftRight' || e.code === 'KeyK') && R) dodge();
    if ((e.code === 'KeyQ' || e.code === 'KeyL') && R) fireSub(true);
    if (e.code.indexOf('Arrow') === 0) { e.preventDefault(); look.idle = 0; }
    if (e.code === 'Escape' && R && !R.ended) openPause();
  });
  window.addEventListener('keyup', function (e) { keys[e.code] = false; });
  window.addEventListener('blur', function () { keys = {}; joy.id = null; joy.dx = joy.dy = 0; look.id = null; });
  function bindPointer() {
    var cv = E.canvas;
    cv.addEventListener('pointerdown', function (e) {
      if (A.mode() !== 'cosmic-run' || !R || paused) return;
      var r = cv.getBoundingClientRect(), x = e.clientX - r.left, y = e.clientY - r.top;
      if (x < r.width * 0.5 && joy.id === null) { joy.id = e.pointerId; joy.cx = x; joy.cy = y; joy.dx = joy.dy = 0; }
      else if (look.id === null) { look.id = e.pointerId; look.x = x; look.y = y; look.idle = 0; }
      cv.setPointerCapture(e.pointerId);
    });
    cv.addEventListener('pointermove', function (e) {
      var r = cv.getBoundingClientRect(), x = e.clientX - r.left, y = e.clientY - r.top;
      if (e.pointerId === joy.id) {
        var dx = x - joy.cx, dy = y - joy.cy, R0 = 60 * Math.max(0.55, A.view().s * 1.5), l = Math.hypot(dx, dy);
        if (l > R0) { dx = dx / l * R0; dy = dy / l * R0; } joy.dx = dx / R0; joy.dy = -dy / R0;
      } else if (e.pointerId === look.id && R) {
        var k = 0.32 / Math.max(0.3, A.view().s * 1.5);
        R.camYaw += (x - look.x) * k; R.camPitch = clamp(R.camPitch + (y - look.y) * k, -70, 70); look.x = x; look.y = y; look.idle = 0;
      }
    });
    function up(e) { if (e.pointerId === joy.id) { joy.id = null; joy.dx = joy.dy = 0; } if (e.pointerId === look.id) { look.id = null; look.idle = 0; } }
    cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', up);
  }

  window.CosmicRun = {
    init: function (api) { A = api; bindPointer(); },
    start: function (chapterId, opt) { camPreset = (C.save.settings && C.save.settings.cam) || 'chase'; A.setMode('cosmic-run'); newRun(chapterId, opt); paused = false; buildHUD(); if (!C.save.tutorialDone) startTutorial(); C.sfx('warp'); C.music.play('battle'); },
    frame: function (dt) { if (!R) return; step(dt); render(); drawOverlay(); if (!R.ended && hud.top) updateHUD(dt); },
    debug: {
      orbit: function (deg) { if (R) { R.dbgYaw = deg; R.cx = null; } }, endRun: function (w) { endRun(!!w, false); }, hit: function (i, e, dmg) { modHit(R.mods[i], e, dmg || 20, P(), 6); }, camset: function (o) { CAMS.custom = o; camPreset = 'custom'; if (R) R.cx = null; }, spawn: function (type, x, y, z) { return spawnEnemy(type, x, y, z); }, run: function () { return R; }, pose: function () { return R && R.pose; }, step: function (n) { for (var i = 0; i < n; i++) { step(1 / 30); var c = document.querySelector('.sv-modal .sv-card:not(.cx-offer)'); if (paused && c) c.click(); } },
      move: function (dx, dy) { joy.dx = dx; joy.dy = dy; }, look: function (yaw, pitch) { if (R) { R.camYaw = yaw; R.camPitch = pitch; look.idle = 0; } },
      cast: castActive, dodge: dodge, god: function (on) { if (R) R.god = on; },
      heal: function () { if (R) R.hull = hullMax(); }, clearEnemies: function () { if (R) R.enemies.slice().forEach(function (e) { hurtEnemy(e, 1e9, 0, 0, 0, true); }); },
      oneHit: function (on) { if (R && !!R.devOne !== !!on) { R.st.atk += on ? 99 : -99; R.devOne = !!on; } return R ? !!R.devOne : false; },
      addCredits: function (n) { if (R) R.credits += n; }, addSrc: function (n) { if (R) R.src += n; },
      levelUp: function () { if (R) R.pendingLevels++; },
      ammo: function (n) { if (R && R.sub) R.sub.ammo = n; return R && R.sub ? R.sub.ammo : 0; }, sub: function () { if (R && R.sub) R.sub.cd = 0; return fireSub(true); },
      toGate: function () { if (R) { if (R.event) R.event.state = 'done'; R.px = R.gate.x; R.py = R.gate.y; R.pz = R.gate.z - 25; } },
      sector: function (k) { if (R) loadSector(k); },
      cam: function (k) { camPreset = k; if (R) R.cx = null; },
      dummy: function (type, x, y, z, hp, still) { var e = spawnEnemy(type, x, y, z); e.hp = e.max = hp; e.d = Object.assign({}, e.d, { shoot: null, dmg: 0 }, still ? { spd: 0 } : {}); return true; },
      quiet: function () { if (R) { R.enemies = []; R.gate.state = 'open'; R.dmgDealt = 0; R.px = 0; R.py = 0; R.pz = 0; } },
      // 视野检查：机甲周围半径 r 的球面上均匀取点，统计在屏幕内的比例
      occ: function () { var m = R.occMax || 0; R.occMax = 0; return Math.round(m * 1000) / 10; },
      sphere: function (r) { var V = A.view(), v = 0, n = 0, back = 0, bn = 0; for (var i = 0; i < 60; i++) { var d = randDir(), q = E.project(lastVP, [R.px + d[0] * r, R.py + d[1] * r, R.pz + d[2] * r], V.w, V.h), ok = q && q[0] > 0 && q[0] < V.w && q[1] > 0 && q[1] < V.h; n++; if (ok) v++; if (dot(d, camBasis.f) < -0.3) { bn++; if (ok) back++; } } var a = E.project(lastVP, [R.px, R.py - 2.4, R.pz], V.w, V.h), b = E.project(lastVP, [R.px, R.py + 2.4, R.pz], V.w, V.h); return { all: Math.round(v / n * 100), back: bn ? Math.round(back / bn * 100) : 0, mechPx: a && b ? Math.round(a[1] - b[1]) : 0, mechX: a ? Math.round(a[0] / V.w * 100) : 0, mechY: a ? Math.round((a[1] + b[1]) / 2 / V.h * 100) : 0 }; },
      clear: function () { if (R) R.enemies.filter(function (e) { return !e.d.boss && !e.d.ore; }).forEach(function (e) { e.hp = 0; killEnemy(e); }); },
      unpause: function () { paused = false; document.querySelectorAll('.sv-modal').forEach(function (m) { m.remove(); }); }
    }
  };
})();

