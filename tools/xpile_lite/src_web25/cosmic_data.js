/* 宇宙银河机甲 · 共享数据层
 * 角色、章节、天赋、召唤、机库、存档、激励广告（模拟）。
 * 数值表集中在这里，方便调平衡；移植 UrhoX 时整体翻译成 Lua 数据模块。
 */
(function () {
  'use strict';
  var C = window.Cosmic = window.Cosmic || {};
  var SAVE_KEY = 'galaxy-mecha-save-v8';

  // ------------------------------------------------------------------ 机甲（5 台初始机甲，开局全部可用，信用点升级）
  // 机甲决定：耐久、机动、主武器、主动技能。Lv10 觉醒主动技能；每级耐久与火力 +5%。
  C.MECHS = [
    { id: 'mech_azure', grade: 'S', name: '苍星', type: '均衡型', match: 'char_xingli', hp: 100, spd: 15, fire: 3, skill: 'char_xingli',
      weapon: { type: 'laser', name: '星轨射线枪', desc: '高速射线连发两击，每击穿透 2 个敌人' },
      active: { name: '星轨狙击', cd: 14, desc: '射出贯穿全图的光束，对直线上所有敌人造成 230 伤害', awake: '觉醒：同时射出 3 道扇形光束' } },
    { id: 'mech_blaze', grade: 'S', name: '炎铠', type: '重装型', match: 'char_chiyan', hp: 140, spd: 13.5, fire: 4, skill: 'char_chiyan',
      weapon: { type: 'shotgun', name: '散射炮', desc: '中近距离集束散射，附带强击退' },
      active: { name: '烈焰冲锋', cd: 9, desc: '冲刺 32 米，冲刺中无敌，撞飞沿途敌人并造成 140 伤害', awake: '觉醒：冲刺路径留下灼烧火焰' } },
    { id: 'mech_halo', grade: 'SS', name: '月辉', type: '支援型', match: 'char_yuexi', hp: 105, spd: 15, fire: 2, skill: 'char_yuexi',
      weapon: { type: 'heal', name: '追踪光弹', desc: '追踪敌人的光弹，伤害较高，每次命中修复 0.5 耐久' },
      active: { name: '星愈领域', cd: 16, desc: '展开治疗力场 6 秒，每秒修复 8% 耐久，力场内敌人减速并每秒受到 25 伤害', awake: '觉醒：力场伤害翻倍' } },
    { id: 'mech_forge', grade: 'SSSR', name: '琥珀工兵', type: '工程型', match: 'char_hupo', hp: 135, spd: 14, fire: 3, skill: 'char_hupo',
      weapon: { type: 'twin', name: '双臂机炮', desc: '两门旋转机炮并排射击，射速快，穿透 2 个敌人' },
      active: { name: '炮台阵列', cd: 16, desc: '投放 3 座爆破炮台，持续 10 秒，炮弹命中后小范围爆炸', awake: '觉醒：投放 5 座炮台' } },
    { id: 'mech_frost', grade: 'SS', name: '霜鸣', type: '炮击型', match: 'char_shuangling', hp: 110, spd: 15.5, fire: 5, skill: 'char_shuangling',
      weapon: { type: 'lob', name: '肩载导弹', desc: '发射追踪导弹，命中后范围爆炸' },
      active: { name: '冰霜导弹雨', cd: 13, desc: '在敌群中落下 16 枚导弹，每枚 15 范围伤害并减速 3 秒', awake: '觉醒：导弹数量翻倍' } },
    { id: 'mech_starfall', grade: 'SSR', name: '天殒', type: '星核型', match: 'char_yeyuan', hp: 125, spd: 15, fire: 5, skill: 'starfall',
      weapon: { type: 'prism', name: '星核长枪', desc: '三向晶体光弹，穿透 1 个敌人' },
      active: { name: '天殒坠星', cd: 14, desc: '召唤巨型陨星砸向敌群，造成 200 范围伤害，并溅射 6 枚碎晶', awake: '觉醒：连续坠落 2 颗陨星' } }
  ];
  // 稀有度：属性与技能整体倍率；SSR 另有更强的技能设计（霜鸣导弹更多、天殒陨星）
  C.GRADE = { S: { mul: 1.0, color: '#57B8FF', frag: 6 }, SS: { mul: 1.15, color: '#B47CFF', frag: 12 }, SSR: { mul: 1.25, color: '#F5A524', frag: 25 }, SSSR: { mul: 1.4, color: '#FF5D7A', frag: 40 } };
  C.MECH_MAX = 30;
  C.MECH_AWAKE = 10;
  C.mechCost = function (lv) { return Math.round(250 * Math.pow(1.28, lv - 1)); };
  C.mech = function (id) { for (var i = 0; i < C.MECHS.length; i++) if (C.MECHS[i].id === id) return C.MECHS[i]; return null; };
  C.mechLv = function (id) { return (C.save.mechs[id] && C.save.mechs[id].lv) || 1; };
  C.ownsMech = function (id) { return !!C.save.mechs[id]; };
  C.MATCH_BONUS = 0.2;

  // ------------------------------------------------------------------ 驾驶员（首发 5 位，星源召唤，碎片升星）
  // 驾驶员提供：支援技能（自动释放）与被动；驾驶自己的专属机甲时耐久与火力额外 +20%
  // 星级加成：属性 x (1 + 0.15 x (星级-1))；5 星觉醒强化主动技能
  C.CHARS = [
    { id: 'char_xingli', grade: 'S', name: '星璃', role: '狙击手', color: '#4FD6D0', mech: 'mech_azure',
      weapon: { type: 'laser', name: '穿透激光', desc: '高速激光，穿透 1 个敌人' },
      active: { name: '星轨狙击', cd: 14, desc: '朝最近的敌人射出贯穿全图的光束，造成 150 点伤害', awake: '觉醒：同时射出 3 道扇形光束' },
      support: { name: '狙击光束', cd: 4, desc: '每 4 秒射出光束，对最强的敌人造成 55 伤害' },
      passive: { name: '暴击率 +10%', fx: { crit: 0.1 } },
      lines: ['锁定。', '别乱动，我在瞄准。', '目标清除。'] },
    { id: 'char_chiyan', grade: 'S', name: '赤焰', role: '突击手', color: '#E2552F', mech: 'mech_blaze',
      weapon: { type: 'shotgun', name: '散射炮', desc: '中近距离集束散射，附带强击退' },
      active: { name: '烈焰冲锋', cd: 9, desc: '朝移动方向冲刺 32 米，冲刺中无敌并撞飞敌人', awake: '觉醒：冲刺路径留下灼烧火焰' },
      support: { name: '烈焰突击', cd: 7, desc: '每 7 秒放出火焰幻影冲锋，沿途造成 70 伤害' },
      passive: { name: '耐久上限 +25%', fx: { hull: 0.25 } },
      lines: ['让开让开！', '交给我正面！', '冲啊——'] },
    { id: 'char_yuexi', grade: 'SS', name: '月汐', role: '医疗兵', color: '#9B7BEA', mech: 'mech_halo',
      weapon: { type: 'heal', name: '治疗追踪弹', desc: '追踪敌人的星光弹，每次命中修复船体' },
      active: { name: '星愈领域', cd: 18, desc: '展开治疗领域 6 秒，每秒修复 8% 船体，敌人进入会减速', awake: '觉醒：领域同时持续伤害敌人' },
      support: { name: '治疗光环', cd: 8, desc: '每 8 秒修复 15 耐久，并对周围敌人造成 15 伤害' },
      passive: { name: '每秒修复 1% 耐久', fx: { regen: 0.01 } },
      lines: ['伤口交给我。', '撑住，马上就好。', '大家都还在吧？'] },
    { id: 'char_hupo', grade: 'SSSR', name: '琥珀', role: '工程师', color: '#F08A2C', mech: 'mech_forge',
      weapon: { type: 'twin', name: '双联机炮', desc: '两门机炮并排射击，射速快' },
      active: { name: '炮台阵列', cd: 16, desc: '在周围投放 3 座自动炮台，持续 10 秒', awake: '觉醒：投放 5 座炮台' },
      support: { name: '速建炮塔', cd: 9, desc: '每 9 秒架设 1 座炮塔，持续 8 秒' },
      passive: { name: '炮台伤害 +30%，搜刮采矿 +50%', fx: { loot: 0.5, turret: 0.3 } },
      lines: ['炮塔上线！', '这个我改过，威力翻倍。', '扳手才是正义。'] },
    { id: 'char_shuangling', grade: 'SS', name: '霜铃', role: '爆破手', color: '#57B8FF', mech: 'mech_frost',
      weapon: { type: 'lob', name: '抛射导弹', desc: '发射追踪导弹，命中后范围爆炸' },
      active: { name: '冰霜导弹雨', cd: 15, desc: '在敌群中落下 12 枚导弹，命中区域减速', awake: '觉醒：导弹数量翻倍' },
      support: { name: '导弹雨', cd: 5, desc: '每 5 秒召唤 7 枚导弹，每枚 12 范围伤害' },
      passive: { name: '爆炸范围 +20%', fx: { blast: 0.2 } },
      lines: ['点火——发射！', '烟花时间到了！', '再来一轮？'] },
    { id: 'char_yeyuan', grade: 'SSR', name: '夜鸢', role: '领航员', color: '#B47CFF', mech: 'mech_starfall',
      support: { name: '引力陷阱', cd: 7, desc: '每 7 秒在敌群中制造引力井 3 秒，牵引敌人并每秒造成 16 伤害' },
      passive: { name: '拾取范围 +40%，闪避冷却 -30%', fx: { pickup: 0.4, dodge: 0.3 } },
      lines: ['航线修正完毕。', '它们逃不掉的。', '跟着我的标记走。'] }
  ];
  // 战力：机甲（耐久 + 火力）x 星级 / 驾驶员加成 + 装备的卡牌与芯片；章节推荐战力用于提示玩家是否需要先变强
  C.power = function () {
    var s = C.save, id = s.mech, m = C.mech(id), k = C.mechMul(id) * (m.match === s.pilot ? 1 + C.MATCH_BONUS : 1) * C.pilotMul(s.pilot), p = (m.hp + m.fire * 18) * k;
    C.topMods(3).forEach(function (c) { p += (c.tier + 1) * 9 * C.modLvMult(c); });
    p += C.armPower(id);
    (s.chipEq || []).forEach(function (cid) { var c = s.chips.filter(function (x) { return x.id === cid; })[0]; if (c) p += (c.tier + 1) * 7 * C.chipLvMult(c); });
    return Math.round(p);
  };
  C.STAR_FRAGS = [0, 10, 20, 40, 80];   // 升到 2、3、4、5 星所需碎片

  // ------------------------------------------------------------------ 章节
  C.CHAPTERS = [
    { id: 1, rec: 180, name: '灰烬星域', boss: 'gunship_boss', bossName: '海贼头目号', hp: 1, dmg: 1, first: 30,
      env: { bg: [0.05, 0.06, 0.15], ambient: [0.42, 0.40, 0.55], fog: [5000, 9000], key: { dir: [0.35, -0.85, 0.4], color: [1, 0.92, 0.82], brightness: 1.15 },
        fill: { dir: [-0.5, -0.3, -0.6], color: [0.5, 0.8, 1.0], brightness: 0.45 }, bloom: { threshold: 0.5, mix: 1.0 } },
      mix: ['crawler', 'crawler', 'grunt', 'inter'], desc: '货运航线上的海贼越来越嚣张，击败他们的头目。' },
    { id: 2, rec: 300, name: '碎石星域', boss: 'brute_king', bossName: '晶核巨兽王', hp: 1.35, dmg: 1.1, first: 40,
      env: { bg: [0.06, 0.05, 0.12], ambient: [0.40, 0.36, 0.50], fog: [5000, 9000], key: { dir: [0.4, -0.8, 0.45], color: [1, 0.86, 0.72], brightness: 1.15 },
        fill: { dir: [-0.5, -0.3, -0.6], color: [0.5, 0.95, 0.85], brightness: 0.5 }, bloom: { threshold: 0.45, mix: 1.1 } },
      mix: ['crawler', 'crawler', 'crawler', 'grunt', 'inter', 'heavy'], desc: '晶化生物在碎石带疯狂繁殖，巢穴深处有一头巨兽之王。' },
    { id: 3, rec: 460, name: '赤环星域', boss: 'flagship_boss', bossName: '赤髑号', hp: 1.75, dmg: 1.2, first: 60,
      env: { bg: [0.09, 0.04, 0.08], ambient: [0.44, 0.34, 0.42], fog: [5000, 9000], key: { dir: [-0.3, -0.85, 0.4], color: [1, 0.78, 0.62], brightness: 1.2 },
        fill: { dir: [0.6, -0.2, -0.5], color: [0.95, 0.45, 0.65], brightness: 0.5 }, bloom: { threshold: 0.45, mix: 1.1 } },
      mix: ['crawler', 'grunt', 'grunt', 'inter', 'inter', 'heavy'], desc: '星海贼团的老巢。赤髑在这里等着你。' }
  ];

  // ------------------------------------------------------------------ 机库
  C.HANGAR = [
    { id: 'hull', name: '装甲板', desc: '船体上限 +8%', max: 20 },
    { id: 'gun', name: '主炮校准', desc: '主武器伤害 +6%', max: 20 }
  ];
  C.hangarCost = function (lv) { return Math.round(300 * Math.pow(1.35, lv)); };

  // ------------------------------------------------------------------ 召唤与广告
  C.SUMMON = { single: 10, ten: 90, rates: { SSSR: 0.01, SSR: 0.04, SS: 0.2, S: 0.75 }, pitySSR: 50, pitySSSR: 120 };
  C.mechStar = function (id) { var m = C.save.mechs[id]; return m ? m.star || 1 : 0; };
  C.mechMul = function (id) { var m = C.mech(id); return C.GRADE[m.grade].mul * (1 + 0.1 * (C.mechStar(id) - 1)) * (1 + 0.05 * (C.mechLv(id) - 1)); };
  C.pilotMul = function (id) { var c = C.char(id); return C.GRADE[c.grade].mul * C.starMult(id); };
  // 卡池抽一次：kind = 'mech' | 'pilot'；十连保底至少 SS，各池 50 抽内必出 SSR 以上，120 抽内必出 SSSR
  C.pull = function (kind, forceSS) {
    var s = C.save, pk = kind + 'Pity', list = kind === 'mech' ? C.MECHS : C.CHARS, own = kind === 'mech' ? s.mechs : s.chars;
    s[pk] = (s[pk] || 0) + 1; s.pulls++;
    var RT = C.SUMMON.rates, r = Math.random(), pk3 = kind + 'Pity3';
    var g = r < RT.SSSR ? 'SSSR' : r < RT.SSSR + RT.SSR ? 'SSR' : r < RT.SSSR + RT.SSR + RT.SS ? 'SS' : 'S';
    s[pk3] = (s[pk3] || 0) + 1;
    if (forceSS && g === 'S') g = 'SS';
    if (s[pk3] >= C.SUMMON.pitySSSR) g = 'SSSR'; else if (s[pk] >= C.SUMMON.pitySSR && (g === 'S' || g === 'SS')) g = 'SSR';
    if (g === 'SSSR') { s[pk3] = 0; s[pk] = 0; } else if (g === 'SSR') s[pk] = 0;
    var pool = list.filter(function (x) { return x.grade === g; }), it = pool[Math.floor(Math.random() * pool.length)];
    if (!own[it.id]) { own[it.id] = kind === 'mech' ? { lv: 1, star: 1 } : { star: 1 }; return { kind: kind, id: it.id, grade: g, isNew: true }; }
    var n = C.GRADE[g].frag; s.frags[it.id] = (s.frags[it.id] || 0) + n;
    return { kind: kind, id: it.id, grade: g, frag: n };
  };
  C.AD = { srcReward: 10, srcDaily: 5, upDaily: 5 };
  C.LV_MAX = 5;
  C.DAILY_SUPPLY = 10;
  C.TASKS = [
    { id: 'run', name: '完成 1 次远征', key: 'runs', need: 1, reward: 5 },
    { id: 'kill', name: '击败 300 个敌人', key: 'kills', need: 300, reward: 5 },
    { id: 'pull', name: '召唤 1 次', key: 'pulls', need: 1, reward: 5 }
  ];
  // 巡航收益：离线自动积累信用点，最多 8 小时；通关章节越多，每小时越多
  C.IDLE_CAP_H = 8;
  C.idleRate = function () { var s = C.save, n = Object.keys(s.cleared).length, b = 0; Object.keys(s.best).forEach(function (k) { b += s.best[k]; }); return 240 + 160 * n + 15 * b; };
  C.idleAmount = function () { var h = Math.min(C.IDLE_CAP_H, (Date.now() - (C.save.idleT || Date.now())) / 3600000); return { credits: Math.floor(h * C.idleRate()), hours: h }; };

  // ------------------------------------------------------------------ 存档
  function today() { var d = new Date(); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  C.newSave = function () {
    var mechs = { mech_azure: { lv: 1, star: 1 }, mech_blaze: { lv: 1, star: 1 } };
    return { credits: 600, src: 30, chars: { char_xingli: { star: 1 }, char_chiyan: { star: 1 } }, frags: {}, mechs: mechs,
      pilot: 'char_xingli', mech: 'mech_azure', chips: [], chipEq: [], modules: [], modEq: [], chipBuys: 0, modBuys: 0,
      pulls: 0, mechPity: 0, pilotPity: 0, hangar: { hull: 0, gun: 0 }, chapter: 1, cleared: {}, best: {},
      daily: { day: '', ads: 0, free: 0, supply: 0, runs: 0, kills: 0, pulls: 0, claimed: {} }, runs: 0, login: { last: '', n: 0 }, ach: {}, totalKills: 0, bossKills: 0, dangerMax: 1, endlessBest: 0, dc: null, dcBest: 0,
      settings: { sound: true, music: true, quality: 'auto' }, idleT: Date.now(), tutorialDone: false };
  };
  C.load = function () {
    var s = null;
    try { var t = localStorage.getItem(SAVE_KEY); s = t ? JSON.parse(t) : null; } catch (e) { s = null; }
    if (!s) { s = C.newSave(); C.save = s; var m1 = C.makeModule(0, 'homing', 'light'), m2 = C.makeModule(0, 'nova', 'ice'); s.modules = [m1, m2]; s.modEq = [m1.id, m2.id]; }
    if (s.daily.day !== today()) s.daily = { day: today(), adUp: 0, ads: 0, free: 0, supply: 0, runs: 0, kills: 0, pulls: 0, claimed: {} };
    s.login = s.login || { last: '', n: 0 }; s.ach = s.ach || {}; s.totalKills = s.totalKills || 0; s.bossKills = s.bossKills || 0; s.dangerMax = s.dangerMax || 1; s.endlessBest = s.endlessBest || 0; s.dcBest = s.dcBest || 0;
    s.settings = s.settings || { sound: true, music: true, quality: 'auto' }; if (s.settings.music === undefined) s.settings.music = true; s.idleT = s.idleT || Date.now(); s.daily.claimed = s.daily.claimed || {};
    // 迁移：旧存档的技能模块按“形态+元素+品质+变体”重建为固定卡牌（词条与颜色由种子决定），重复的合并升级
    var seen = {}, mods = [], idmap = {};
    (s.modules || []).forEach(function (m) {
      var v = m.v == null ? 0 : m.v, fresh = C.makeModule(m.tier, m.form, m.elem, v); idmap[m.id] = fresh.id;
      if (seen[fresh.id]) { var o = seen[fresh.id]; o.lvl = Math.min(C.LV_MAX, (o.lvl || 1) + (m.lvl || 1)); return; }
      fresh.lvl = m.lvl || 1; seen[fresh.id] = fresh; mods.push(fresh);
    });
    s.modules = mods; s.modEq = (s.modEq || []).map(function (i) { return idmap[i] || i; }).filter(function (i, k, a) { return seen[i] && a.indexOf(i) === k; }).slice(0, 3);
    (s.chips || []).forEach(function (c) { c.lvl = c.lvl || 1; });
    C.save = s; C.armory(); if (s.settings.subAuto === undefined) s.settings.subAuto = true;
    // 21 版：升级选卡默认改为“立即弹出”；老玩家（已打过 3 局以上、没改过设置）保持原来的“稍后选择”
    if (s.settings.lvMode === undefined) s.settings.lvMode = (s.runs || 0) >= 3 ? 'later' : 'now';
    return s;
  };
  // —— 7 日登录奖励：连续登录领取，断签后从第 1 天重新开始
  // —— 每日挑战：同一天所有玩家的规则相同（章节 + 2 个词缀），限时 4 分钟，按得分结算；每天首次完成有奖励
  C.DC_TIME = 240;
  C.DC_MODS = [
    { id: 'tide', n: '狂潮', d: '敌人数量 +30%，能量获取 +50%' }, { id: 'swift', n: '疾风', d: '敌人移速 +25%，你的移速 +15%' },
    { id: 'fury', n: '狂暴', d: '敌人伤害 +25%，能量获取 +30%' }, { id: 'iron', n: '铁壁', d: '敌人血量 +50%，信用点收益 +50%' },
    { id: 'glass', n: '玻璃大炮', d: '你的耐久 -30%，伤害 +40%' }, { id: 'elite', n: '精英日', d: '每 40 秒出现一只精英，击败后回复 10% 耐久' }
  ];
  C.dailyChallenge = function () {
    var key = (function () { var d = new Date(); return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); })(), rnd = seeded('dc' + key), pool = C.DC_MODS.slice(), mods = [], i;
    for (i = 0; i < 2; i++) mods.push(pool.splice(Math.floor(rnd() * pool.length), 1)[0].id);
    var ch = 1 + Math.floor(rnd() * Math.max(1, Math.min(C.CHAPTERS.length, C.save.chapter)));
    var dc = C.save.dc; if (!dc || dc.day !== key) dc = C.save.dc = { day: key, best: 0, done: false, runs: 0 };
    return { day: key, chapter: ch, mods: mods, danger: 2, state: dc };
  };
  C.dcMod = function (id) { return C.DC_MODS.filter(function (m) { return m.id === id; })[0]; };
  C.LOGIN_REWARDS = [{ cr: 500 }, { src: 10 }, { cr: 800 }, { src: 15 }, { cr: 1200 }, { src: 20 }, { src: 40, draw: 1 }];
  function dayKey(d) { return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  C.loginState = function () {
    var l = C.save.login, t = today(), y = new Date(); y.setDate(y.getDate() - 1);
    if (l.last === t) return { claimed: true, idx: (l.n + 6) % 7 };           // 今天已领：idx 为刚领的那一天
    var idx = l.last === dayKey(y) ? l.n % 7 : 0;                              // 昨天领过则接着领，否则重置
    return { claimed: false, idx: idx };
  };
  C.loginClaim = function () {
    var st = C.loginState(); if (st.claimed) return null;
    var rw = C.LOGIN_REWARDS[st.idx], l = C.save.login, txt = [];
    if (rw.cr) { C.save.credits += rw.cr; txt.push('信用点 +' + rw.cr); }
    if (rw.src) { C.save.src += rw.src; txt.push('星源 +' + rw.src); }
    if (rw.draw) { C.save.credits += C.MOD_COST(C.save.modBuys || 0); var r = C.buyModule(); if (r.mod) txt.push('免费抽到卡牌：' + r.mod.name); }
    l.last = today(); l.n = st.idx + 1; C.write(); return txt.join('，');
  };
  // —— 成就：由存档数据推算，达成后到每日页领取星源
  C.ACH = [
    { id: 'a_run1', name: '首次出击', desc: '完成 1 次远征', src: 5, ok: function (s) { return s.runs >= 1; } },
    { id: 'a_run10', name: '老练舰长', desc: '完成 10 次远征', src: 10, ok: function (s) { return s.runs >= 10; } },
    { id: 'a_ch1', name: '灰烬终结者', desc: '通关第 1 章', src: 15, ok: function (s) { return !!s.cleared[1]; } },
    { id: 'a_ch2', name: '碎石征服者', desc: '通关第 2 章', src: 20, ok: function (s) { return !!s.cleared[2]; } },
    { id: 'a_ch3', name: '赤环破局者', desc: '通关第 3 章', src: 30, ok: function (s) { return !!s.cleared[3]; } },
    { id: 'a_card10', name: '卡牌新手', desc: '收集 10 张技能卡牌', src: 10, ok: function (s) { return s.modules.length >= 10; } },
    { id: 'a_card30', name: '卡牌收藏家', desc: '收集 30 张技能卡牌', src: 15, ok: function (s) { return s.modules.length >= 30; } },
    { id: 'a_card100', name: '卡牌大师', desc: '收集 100 张技能卡牌', src: 30, ok: function (s) { return s.modules.length >= 100; } },
    { id: 'a_gold', name: '金光闪闪', desc: '获得 1 张金色卡牌', src: 20, ok: function (s) { return s.modules.some(function (m) { return m.tier === 3; }); } },
    { id: 'a_chip5', name: '芯片工程师', desc: '拥有 5 枚天赋芯片', src: 10, ok: function (s) { return s.chips.length >= 5; } },
    { id: 'a_lv10', name: '机甲精进', desc: '任意机甲升到 Lv10', src: 15, ok: function (s) { return Object.keys(s.mechs).some(function (k) { return s.mechs[k].lv >= 10; }); } },
    { id: 'a_kill1k', name: '千杀', desc: '累计击破 1000 个敌人', src: 15, ok: function (s) { return s.totalKills >= 1000; } },
    { id: 'a_kill5k', name: '万军之中', desc: '累计击破 5000 个敌人', src: 25, ok: function (s) { return s.totalKills >= 5000; } },
    { id: 'a_end10', name: '无尽远征', desc: '无尽模式到达第 10 波', src: 20, ok: function (s) { return (s.endlessBest || 0) >= 10; } },
    { id: 'a_dg5', name: '险中求胜', desc: '解锁危险等级 5', src: 25, ok: function (s) { return (s.dangerMax || 1) >= 5; } },
    { id: 'a_dc1', name: '每日挑战者', desc: '完成 1 次每日挑战', src: 10, ok: function (s) { return (s.dcBest || 0) > 0; } },
    { id: 'a_boss3', name: '首领猎手', desc: '累计击败 3 个首领', src: 20, ok: function (s) { return s.bossKills >= 3; } }
  ];
  C.achClaim = function (id) { var a = C.ACH.filter(function (x) { return x.id === id; })[0], s = C.save; if (!a || s.ach[id] || !a.ok(s)) return false; s.ach[id] = 1; s.src += a.src; C.write(); return true; };
  C.achReady = function () { var s = C.save; return C.ACH.filter(function (a) { return a.ok(s) && !s.ach[a.id]; }).length; };
  // —— 存档导出 / 导入（没有云存档时换设备或防止清缓存丢失）
  C.exportSave = function () { try { return btoa(unescape(encodeURIComponent(JSON.stringify(C.save)))); } catch (e) { return ''; } };
  C.importSave = function (txt) {
    try { var o = JSON.parse(decodeURIComponent(escape(atob(String(txt).trim())))); if (!o || typeof o.credits !== 'number' || !o.mechs) return false; localStorage.setItem(SAVE_KEY, JSON.stringify(o)); C.load(); return true; } catch (e) { return false; }
  };
  C.write = function () { try { localStorage.setItem(SAVE_KEY, JSON.stringify(C.save)); } catch (e) { /* 存储不可用时仅保留本次会话 */ } };
  C.reset = function () { try { localStorage.removeItem(SAVE_KEY); } catch (e) {} C.save = C.newSave(); C.write(); };
  C.char = function (id) { for (var i = 0; i < C.CHARS.length; i++) if (C.CHARS[i].id === id) return C.CHARS[i]; return null; };
  C.talent = function (id) { for (var i = 0; i < C.TALENTS.length; i++) if (C.TALENTS[i].id === id) return C.TALENTS[i]; return null; };

  C.starMult = function (id) { var c = C.save.chars[id]; return c ? 1 + 0.15 * (c.star - 1) : 1; };

  // 激励视频广告：HTML 版为模拟；UrhoX 版替换为 sdk:ShowRewardVideoAd(callback)，仅在 result.success 时发奖
  C.showAd = function (reason, cb) {
    var ov = document.createElement('div'); ov.className = 'ad-sim';
    ov.innerHTML = '<div class="ad-box"><span class="tag">模拟广告</span><h2>' + reason + '</h2><p>正式版这里会播放激励视频，看完才发奖励。</p><b class="ad-count">3</b>' +
      '<div class="ad-btns"><button class="btn" data-a="close">提前关闭</button></div></div>';
    document.getElementById('app').appendChild(ov);
    var n = 3, done = false, timer = setInterval(function () {
      n--; ov.querySelector('.ad-count').textContent = n > 0 ? n : '完成';
      if (n <= 0) { clearInterval(timer); finish(true, 'embed success'); }
    }, 700);
    function finish(ok, msg) { if (done) return; done = true; clearInterval(timer); ov.remove(); cb({ success: ok, msg: msg }); }
    ov.querySelector('[data-a=close]').onclick = function () { finish(false, 'embed manual close'); };
  };

  // ------------------------------------------------------------------ 音效与背景音乐：全部为 .ogg（Vorbis）
  // 源文件在 assets/audio/*.ogg（tools/build_audio.py 渲染）；HTML 单文件内嵌同一份 base64，启动时解码为 AudioBuffer。
  var actx = null, last = {}, GAP = { shoot: 0.09, pop: 0.05, pick: 0.06, hurt: 0.15, boom: 0.08, hit: 0.07, crit: 0.1 }, bufs = {}, loading = false;
  var VOL = { shoot: 0.9, pop: 1, boom: 1, pick: 1, hurt: 1, level: 1, skill: 1, warp: 1, gate: 1, boss: 1, win: 1, click: 1, dash: 1, nitro: 0.75, hit: 0.8, crit: 0.9 };
  function b64buf(b64) { var bin = atob(b64), n = bin.length, u = new Uint8Array(n); for (var i = 0; i < n; i++) u[i] = bin.charCodeAt(i); return u.buffer; }
  function loadAudio() {
    if (loading || !actx || !window.OGG_AUDIO) return; loading = true;
    Object.keys(window.OGG_AUDIO).forEach(function (k) {
      try { actx.decodeAudioData(b64buf(window.OGG_AUDIO[k]), function (b) { bufs[k] = b; if (k.indexOf('bgm_') === 0 && mus.want && !mus.src) C.music.play(mus.want); }, function () {}); } catch (e) { /* 解码失败时该音频静音 */ }
    });
  }
  C.unlockAudio = function () {
    if (!actx) { try { actx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { actx = null; } }
    if (actx && actx.state === 'suspended') actx.resume();
    loadAudio();
  };
  C.sfx = function (name) {
    if (!actx || !C.save || !C.save.settings.sound || actx.state !== 'running') return;
    var b = bufs['sfx_' + name]; if (!b) return;
    var now = actx.currentTime; if (GAP[name] && last[name] && now - last[name] < GAP[name]) return; last[name] = now;
    var src = actx.createBufferSource(), g = actx.createGain(); src.buffer = b; g.gain.value = VOL[name] || 1; src.connect(g); g.connect(actx.destination); src.start();
  };
  C.audioStat = function () { return { decoded: Object.keys(bufs).length, state: actx && actx.state }; };
  var mus = { want: null, src: null, name: null, gain: null };
  function stopMusic() { if (mus.src) { try { mus.src.stop(); } catch (e) {} mus.src = null; } mus.name = null; }
  C.music = {
    play: function (name) {
      mus.want = name;
      if (!actx || actx.state !== 'running' || !C.save || !C.save.settings.music) return;
      if (mus.name === name && mus.src) return;
      var b = bufs['bgm_' + name]; if (!b) return;       // 尚未解码完成：解码回调里会再次调用
      stopMusic();
      if (!mus.gain) { mus.gain = actx.createGain(); mus.gain.gain.value = 0.9; mus.gain.connect(actx.destination); }
      var src = actx.createBufferSource(); src.buffer = b; src.loop = true; src.connect(mus.gain); src.start(); mus.src = src; mus.name = name;
    },
    stop: function () { stopMusic(); },
    refresh: function () { if (C.save && C.save.settings.music && mus.want) { stopMusic(); C.music.play(mus.want); } else stopMusic(); }
  };
  var _unlock = C.unlockAudio;
  C.unlockAudio = function () { _unlock(); if (actx && actx.state === 'running' && mus.want && !mus.src) C.music.play(mus.want); };

  // ================================================================== 天赋芯片（信用点随机研发，1000+ 组合）
  // 16 种属性 x 1~3 条词条 x 4 种稀有度，数值在区间内随机；传说芯片额外带 1 个特性
  C.CHIP_STATS = [
    { k: 'atk', n: '火力', p: '烈焰', r: [3, 8] }, { k: 'hp', n: '耐久', p: '坚壁', r: [4, 10] }, { k: 'spd', n: '机动', p: '疾风', r: [2, 5] },
    { k: 'crit', n: '暴击率', p: '鹰眼', r: [2, 5] }, { k: 'critDmg', n: '暴击伤害', p: '破甲', r: [8, 20] }, { k: 'cdr', n: '冷却缩减', p: '超频', r: [2, 5] },
    { k: 'skill', n: '模块伤害', p: '共振', r: [4, 10] }, { k: 'active', n: '机甲技能伤害', p: '核心', r: [5, 12] }, { k: 'pickup', n: '拾取范围', p: '引力', r: [6, 15] },
    { k: 'credit', n: '信用点收益', p: '财富', r: [4, 10] }, { k: 'armor', n: '受伤减免', p: '护盾', r: [2, 4] }, { k: 'regen', n: '每秒修复', p: '纳米', r: [0.2, 0.6], abs: true },
    { k: 'elite', n: '精英与首领伤害', p: '猎手', r: [5, 12] }, { k: 'summon', n: '炮台伤害', p: '工匠', r: [6, 15] }, { k: 'blast', n: '爆炸范围', p: '爆裂', r: [5, 12] },
    { k: 'xp', n: '能量获取', p: '启迪', r: [4, 10] },
    { k: 'rate', n: '主武器射速', p: '狂热', r: [3, 8] }, { k: 'nitro', n: '氮气冷却缩减', p: '喷流', r: [4, 10] }, { k: 'nitroDist', n: '氮气距离', p: '推进', r: [6, 16] },
    { k: 'luck', n: '补给掉落率', p: '幸运', r: [0.5, 1.5] }, { k: 'sup', n: '驾驶员支援伤害', p: '默契', r: [6, 14] }
  ];
  // 8 个系列：决定芯片的主词条偏向（系列 x 21 种属性 x 4 种品质，另有 4 种传说特性）
  C.CHIP_SERIES = [
    { n: '先锋', b: ['atk', 'crit', 'critDmg', 'rate', 'spd', 'elite', 'nitroDist'] }, { n: '守护', b: ['hp', 'armor', 'regen', 'cdr', 'sup', 'luck', 'nitro'] },
    { n: '猎手', b: ['crit', 'critDmg', 'elite', 'atk', 'pickup', 'xp', 'rate'] }, { n: '工匠', b: ['summon', 'skill', 'blast', 'cdr', 'sup', 'credit', 'active'] },
    { n: '星语', b: ['skill', 'active', 'cdr', 'xp', 'blast', 'pickup', 'luck'] }, { n: '暗影', b: ['crit', 'critDmg', 'spd', 'nitro', 'nitroDist', 'atk', 'elite'] },
    { n: '曙光', b: ['hp', 'regen', 'armor', 'sup', 'xp', 'credit', 'luck'] }, { n: '赤焰', b: ['atk', 'rate', 'blast', 'active', 'skill', 'summon', 'critDmg'] }
  ];
  C.RARITY = [
    { n: '白色·普通', affixes: 1, mult: 1, color: '#E6EAF5', w: 60 }, { n: '蓝色·稀有', affixes: 2, mult: 1.3, color: '#57B8FF', w: 28 },
    { n: '紫色·史诗', affixes: 3, mult: 1.6, color: '#B47CFF', w: 10 }, { n: '金色·传说', affixes: 3, mult: 2.0, color: '#F5A524', w: 2 }
  ];
  C.TRAITS = [
    { k: 'headstart', n: '开局强化', d: '每局开局免费升级 1 次' }, { k: 'revive', n: '星魂庇护', d: '每局自动复活 1 次（40% 耐久）' },
    { k: 'berserk', n: '背水一战', d: '耐久低于 30% 时伤害 +30%' }, { k: 'overclock', n: '超频核心', d: '技能模块冷却 -15%' }
  ];
  C.CHIP_COST = function (n) { return Math.min(2000, 300 + n * 40); };
  C.MOD_COST = function (n) { return Math.min(2500, 400 + n * 60); };
  C.modLvMult = function (m) { return 1 + 0.12 * ((m.lvl || 1) - 1); };
  C.modOwned = function (form, elem, tier, v) { return C.save.modules.filter(function (x) { return x.form === form && x.elem === elem && x.tier === tier && (v == null || (x.v || 0) === v); })[0] || null; };
  C.modBest = function (form, elem) { var b = null; C.save.modules.forEach(function (x) { if (x.form === form && x.elem === elem && (!b || x.tier > b.tier)) b = x; }); return b; };
  C.REFUND = [80, 180, 400, 900];
  C.INV_MAX = 40;
  C.chipSlots = function () { return Math.min(6, 3 + Object.keys(C.save.cleared).length); };
  function rnd(a, b) { return a + Math.random() * (b - a); }
  function rollRarity(pityKey) {
    var s = C.save, t = 0, sum = 0, i; C.RARITY.forEach(function (r) { sum += r.w; });
    var x = Math.random() * sum; for (i = 0; i < C.RARITY.length; i++) { x -= C.RARITY[i].w; if (x <= 0) { t = i; break; } }
    s[pityKey] = (s[pityKey] || 0) + 1;
    if (s[pityKey] % 40 === 0) t = Math.max(t, 3); else if (s[pityKey] % 10 === 0) t = Math.max(t, 1);
    return t;
  }
  var uid = function () { return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36); };
  C.makeChip = function (tier) {
    var R = C.RARITY[tier], pool = C.CHIP_STATS.slice(), aff = [], ser = C.CHIP_SERIES[Math.floor(Math.random() * C.CHIP_SERIES.length)];
    for (var i = 0; i < R.affixes; i++) {
      var pl = i === 0 ? pool.filter(function (x) { return ser.b.indexOf(x.k) >= 0; }) : pool, st = pl[Math.floor(Math.random() * pl.length)]; pool.splice(pool.indexOf(st), 1);
      var v = rnd(st.r[0], st.r[1]) * R.mult;
      aff.push({ k: st.k, v: st.abs ? Math.round(v * 10) / 10 : Math.round(v) });
    }
    var main = C.CHIP_STATS.filter(function (x) { return x.k === aff[0].k; })[0];
    var chip = { id: uid(), tier: tier, lvl: 1, series: ser.n, name: ser.n + '·' + main.p + '芯片', aff: aff };
    if (tier === 3) chip.trait = C.TRAITS[Math.floor(Math.random() * C.TRAITS.length)].k;
    return chip;
  };
  C.buyChip = function () {
    var s = C.save, cost = C.CHIP_COST(s.chipBuys || 0);
    if (s.chips.length >= C.INV_MAX) return { err: '芯片仓库已满（' + C.INV_MAX + '），先分解一些' };
    if (s.credits < cost) return { err: '信用点不足' };
    s.credits -= cost; s.chipBuys = (s.chipBuys || 0) + 1;
    var c = C.makeChip(rollRarity('chipPity')); s.chips.push(c); return { chip: c };
  };
  C.chipLvMult = function (c) { return 1 + 0.12 * ((c.lvl || 1) - 1); };
  C.affText = function (a, c) { var st = C.CHIP_STATS.filter(function (x) { return x.k === a.k; })[0], v = c ? Math.round(a.v * C.chipLvMult(c) * 10) / 10 : a.v; return st.n + ' +' + v + (st.abs ? '' : '%'); };
  C.trait = function (k) { return C.TRAITS.filter(function (x) { return x.k === k; })[0]; };
  // 已装备芯片的属性汇总（百分比转成小数，绝对值保持）
  C.chipStats = function () {
    var out = { traits: {} }; C.CHIP_STATS.forEach(function (x) { out[x.k] = 0; });
    (C.save.chipEq || []).forEach(function (id) {
      var c = C.save.chips.filter(function (x) { return x.id === id; })[0]; if (!c) return;
      var lm = C.chipLvMult(c); c.aff.forEach(function (a) { var st = C.CHIP_STATS.filter(function (x) { return x.k === a.k; })[0]; out[a.k] += (st.abs ? a.v : a.v / 100) * lm; });
      if (c.trait) out.traits[c.trait] = true;
    });
    out.armor = Math.min(0.5, out.armor); out.cdr = Math.min(0.4, out.cdr);
    return out;
  };

  // ================================================================== 技能模块（信用点随机研发，1000+ 组合，颜色随机）
  // 8 种形态 x 6 种元素 x 词条（0~2 条，共 37 种组合）= 1776 种；颜色在元素色系内随机
  C.MOD_FORMS = [
    { k: 'homing', n: '追踪飞弹', cd: 2.2, dmg: 16, count: 2, d: '发射追踪飞弹' },
    { k: 'orbit', n: '环绕刃', cd: 0, dmg: 9, count: 2, d: '光刃持续环绕机甲切割敌人' },
    { k: 'nova', n: '冲击波', cd: 3.2, dmg: 26, count: 1, d: '以机甲为中心释放冲击波并击退' },
    { k: 'strike', n: '落雷', cd: 2.6, dmg: 34, count: 2, d: '轰击附近的敌人，小范围伤害' },
    { k: 'beam', n: '激光束', cd: 3.0, dmg: 45, count: 1, d: '向最强的敌人射出贯穿光束' },
    { k: 'fan', n: '弹幕扇射', cd: 1.6, dmg: 9, count: 5, d: '向最近的敌人扇形射出光弹' },
    { k: 'mine', n: '感应地雷', cd: 2.4, dmg: 40, count: 1, d: '在脚下布雷，敌人靠近即爆炸' },
    { k: 'boomerang', n: '回旋镖', cd: 2.0, dmg: 22, count: 1, d: '飞出再飞回，沿途穿透所有敌人' },
    { k: 'swarm', b: 'homing', n: '蜂群导弹', cd: 2.6, dmg: 8, count: 5, d: '一次放出大量小型追踪导弹' },
    { k: 'heavy', b: 'homing', n: '重型导弹', cd: 3.4, dmg: 48, count: 1, d: '发射一枚高伤害的重型追踪导弹' },
    { k: 'twinblade', b: 'orbit', n: '双生环刃', cd: 0, dmg: 6, count: 4, d: '四把小光刃快速环绕机甲' },
    { k: 'bigblade', b: 'orbit', n: '巨刃', cd: 0, dmg: 16, count: 1, d: '一把巨大的光刃环绕机甲，伤害极高' },
    { k: 'pulse', b: 'nova', n: '脉冲震荡', cd: 1.8, dmg: 15, count: 1, d: '高频释放小型冲击波' },
    { k: 'annihilate', b: 'nova', n: '湮灭冲击', cd: 5, dmg: 50, count: 1, d: '蓄力后释放强力冲击波' },
    { k: 'storm', b: 'strike', n: '雷暴', cd: 3.2, dmg: 22, count: 4, d: '同时轰击多个敌人' },
    { k: 'twinbeam', b: 'beam', n: '双联光束', cd: 3.0, dmg: 28, count: 2, d: '同时射出两道贯穿光束' },
    { k: 'cannon', b: 'beam', n: '轨道重炮', cd: 4.5, dmg: 90, count: 1, d: '蓄能射出一道极高伤害的贯穿光束' },
    { k: 'tempest', b: 'fan', n: '散弹风暴', cd: 1.8, dmg: 6, count: 9, d: '向前方射出大量光弹' },
    { k: 'cluster', b: 'mine', n: '集束地雷', cd: 3, dmg: 26, count: 3, d: '一次布下 3 枚地雷' },
    { k: 'twinrang', b: 'boomerang', n: '回旋双刃', cd: 2.0, dmg: 16, count: 2, d: '同时掷出两把回旋镖' }
  ];
  C.ELEMENTS = [
    { k: 'fire', n: '烈焰', hue: [8, 32], d: '灼烧：2 秒内追加 30% 伤害' },
    { k: 'ice', n: '寒霜', hue: [188, 212], d: '冰冻：命中减速 2 秒' },
    { k: 'thunder', n: '雷霆', hue: [46, 58], d: '雷击：额外跳到 1 个附近敌人' },
    { k: 'light', n: '圣光', hue: [160, 178], d: '圣光：暴击率 +15%' },
    { k: 'dark', n: '暗影', hue: [270, 300], d: '暗影：伤害 +15%' },
    { k: 'poison', n: '剧毒', hue: [92, 128], d: '中毒：3 秒内追加 40% 伤害' }
  ];
  C.MOD_TAGS = [
    { k: 'split', n: '分裂', d: '命中时分裂出 2 枚小弹' }, { k: 'pierce', n: '穿透', d: '弹体穿透 +2' },
    { k: 'chain', n: '连锁', d: '命中后连锁 2 个敌人' }, { k: 'slow', n: '迟缓', d: '命中减速' },
    { k: 'knock', n: '震荡', d: '强力击退' }, { k: 'leech', n: '吸能', d: '伤害的 2% 修复耐久' },
    { k: 'crit', n: '致命', d: '暴击率 +20%' }, { k: 'big', n: '扩张', d: '范围与体积 +40%' }
  ];
  C.MOD_RARITY_MULT = [1, 1.25, 1.5, 1.9];
  // 金色卡牌的专属特效：额外附带一个改变玩法的词条（与卡牌自带词条叠加）
  C.GOLD_FX = {
    homing: { tag: 'split', d: '导弹命中后分裂出 2 枚小弹，清群更快' }, orbit: { tag: 'knock', d: '环绕刃附带强力击退，把敌群推开' },
    nova: { tag: 'slow', d: '冲击波命中的敌人被冻结减速' }, strike: { tag: 'chain', d: '落雷会连锁跳向 2 个附近敌人' },
    beam: { tag: 'big', d: '光束变粗 40%，更容易扫到敌群' }, fan: { tag: 'pierce', d: '光弹额外穿透 2 个敌人' },
    mine: { tag: 'big', d: '地雷爆炸范围 +40%' }, boomerang: { tag: 'chain', d: '回旋镖命中后连锁 2 个敌人' }
  };
  // 卡牌进化：卡牌升到 Lv5 且对应被动达到 Lv2 后，升级时必出“进化”选项——数量增加、伤害 x1.5、冷却 -12%，并附带专属词条
  C.EVO_PASS_LV = 2;
  C.REACT_HINT = { fire: '火 + 毒 = 爆燃（范围爆炸）；火 + 冰冻 = 融蚀', ice: '冰冻的敌人被雷击 = 碎冰（范围伤害）', thunder: '雷 + 冰冻 = 碎冰；雷 + 毒 = 麻痹（定身）', poison: '毒 + 火 = 爆燃；毒 + 雷 = 麻痹', light: '光 + 暗 = 湮灭（暴击）', dark: '暗 + 光 = 湮灭（暴击）' };
  C.EVO = {
    homing: { pass: 'power', n: '集束', d: '导弹 +2 枚，命中后分裂出小弹', tags: ['split'], count: 2 },
    orbit: { pass: 'hull', n: '风暴', d: '环绕刃 +2 把，半径更大并强力击退', tags: ['knock'], count: 2, size: 1.3 },
    nova: { pass: 'cooling', n: '极寒', d: '冲击波范围 +40%，范围内敌人被冻结', tags: ['slow', 'big'], count: 1 },
    strike: { pass: 'engine', n: '天罚', d: '落雷 +2 道，并连锁 2 个敌人', tags: ['chain'], count: 2 },
    beam: { pass: 'power', n: '贯日', d: '光束 +1 条，更粗并额外穿透', tags: ['big', 'pierce'], count: 1 },
    fan: { pass: 'cooling', n: '弹幕', d: '弹幕 +2 发，额外穿透 2 个敌人', tags: ['pierce'], count: 2 },
    mine: { pass: 'magnet', n: '连锁', d: '地雷 +2 枚，爆炸范围 +40%', tags: ['big'], count: 2 },
    boomerang: { pass: 'engine', n: '回响', d: '回旋镖 +1 把，命中后连锁 2 个敌人', tags: ['chain'], count: 1 }
  };
  C.evoOf = function (m) { var F = C.modForm(m.form); return C.EVO[(F && F.b) || m.form]; };
  C.goldTag = function (m) { if (!m || m.tier !== 3) return null; var F = C.modForm(m.form); return C.GOLD_FX[(F && F.b) || m.form] || null; };
  function hsl2hex(h, s, l) {
    s /= 100; l /= 100; var k = function (n) { return (n + h / 30) % 12; }, a = s * Math.min(l, 1 - l);
    var f = function (n) { return Math.round(255 * (l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1))))); };
    return '#' + [f(0), f(8), f(4)].map(function (x) { return (x < 16 ? '0' : '') + x.toString(16); }).join('');
  }
  // 卡牌是固定的：同一 形态+元素+品质 的词条与颜色永远一致（种子随机），重复抽到只会升级
  function seeded(str) { var h = 1779033703 ^ str.length; for (var i = 0; i < str.length; i++) { h = Math.imul(h ^ str.charCodeAt(i), 3432918353); h = (h << 13) | (h >>> 19); } return function () { h = Math.imul(h ^ (h >>> 16), 2246822507); h = Math.imul(h ^ (h >>> 13), 3266489909); h ^= h >>> 16; return (h >>> 0) / 4294967296; }; }
  // 品质变体数：白 1 / 蓝 3 / 紫 3 / 金 2 → 每个“形态 x 元素”共 9 张，20 x 6 x 9 = 1080 张卡牌
  C.VARIANTS = [1, 3, 3, 2];
  C.MOD_TOTAL = function () { return C.MOD_FORMS.length * C.ELEMENTS.length * 9; };
  // 图鉴：按“形态 x 元素”统计（共 120 种），比 1080 张总数更直观
  C.modDex = function () { var seen = {}, n = 0; (C.save.modules || []).forEach(function (m) { var k = m.form + '|' + m.elem; if (!seen[k]) { seen[k] = true; n++; } }); return { got: n, total: C.MOD_FORMS.length * C.ELEMENTS.length }; };
  C.makeModule = function (tier, form, elem, v) {
    var F = form ? C.MOD_FORMS.filter(function (x) { return x.k === form; })[0] : C.MOD_FORMS[Math.floor(Math.random() * C.MOD_FORMS.length)];
    var El = elem ? C.ELEMENTS.filter(function (x) { return x.k === elem; })[0] : C.ELEMENTS[Math.floor(Math.random() * C.ELEMENTS.length)];
    v = v == null ? Math.floor(Math.random() * C.VARIANTS[tier]) : v;
    // 同一 形态+元素+品质 的词条池用固定种子洗牌，变体按位置取词条，保证各变体词条互不相同、永远一致
    var pr = seeded(F.k + El.k + 'p' + tier), pool = C.MOD_TAGS.slice(), k, j, tmp;
    for (k = pool.length - 1; k > 0; k--) { j = Math.floor(pr() * (k + 1)); tmp = pool[k]; pool[k] = pool[j]; pool[j] = tmp; }
    var n = [0, 1, 2, 2][tier], tags = [], tn = [];
    for (k = 0; k < n; k++) { var tg = pool[(v * n + k) % pool.length]; tags.push(tg.k); tn.push(tg.n); }
    var rg = seeded(F.k + El.k + tier + 'v' + v), color = hsl2hex(El.hue[0] + rg() * (El.hue[1] - El.hue[0]), 72 + rg() * 20, 56 + rg() * 10);
    return { id: F.k + ':' + El.k + ':' + tier + ':' + v, tier: tier, v: v, lvl: 1, form: F.k, elem: El.k, tags: tags, color: color, name: El.n + F.n + (tn.length ? '·' + tn.join('') : '') };
  };
  // 卡组：不再装备，拥有即入卡组；同一 形态+元素 只取最强的一张（品质 > 等级）
  C.modDeck = function () {
    var best = {};
    C.save.modules.forEach(function (x) { var k = x.form + ':' + x.elem, b = best[k]; if (!b || x.tier > b.tier || (x.tier === b.tier && (x.lvl || 1) > (b.lvl || 1))) best[k] = x; });
    return Object.keys(best).map(function (k) { return best[k]; });
  };
  C.topMods = function (n) { return C.modDeck().sort(function (a, b) { return (b.tier + 1) * C.modLvMult(b) - (a.tier + 1) * C.modLvMult(a); }).slice(0, n); };
  C.MOD_TEN = function (n) { var c = 0; for (var i = 0; i < 10; i++) c += C.MOD_COST(n + i); return Math.round(c * 0.9 / 10) * 10; };
  // 信用点抽 1 次 / 10 次（10 连 9 折，必出蓝色以上）；free = 看广告翻倍的免费抽取
  C.drawModules = function (cnt, free) {
    var s = C.save, cost = cnt === 10 ? C.MOD_TEN(s.modBuys || 0) : C.MOD_COST(s.modBuys || 0), out = [];
    if (!free && s.credits < cost) return { err: '信用点不足（需要 ' + cost.toLocaleString('zh-CN') + '）' };
    if (!free) s.credits -= cost;
    for (var i = 0; i < cnt; i++) { s.credits += C.MOD_COST(s.modBuys || 0); out.push(C.buyModule()); }
    if (cnt === 10 && !out.some(function (r) { return r.mod && r.mod.tier >= 1; })) {
      var m = C.makeModule(1), own = s.modules.filter(function (x) { return x.id === m.id; })[0];
      if (!own) { s.modules.push(m); out[9] = { mod: m, isNew: true }; } else { if ((own.lvl || 1) < C.LV_MAX) own.lvl = (own.lvl || 1) + 1; out[9] = { mod: own, dup: true }; }
    }
    C.write(); return { list: out, cost: free ? 0 : cost };
  };
  C.buyModule = function () {
    var s = C.save, cost = C.MOD_COST(s.modBuys || 0);
    if (s.credits < cost) return { err: '信用点不足' };
    s.credits -= cost; s.modBuys = (s.modBuys || 0) + 1;
    var m = C.makeModule(rollRarity('modPity')), own = s.modules.filter(function (x) { return x.id === m.id; })[0];
    if (!own) { s.modules.push(m); return { mod: m, isNew: true }; }
    // 重复抽到：卡牌升级（满级转为信用点）；稀有度更高则覆盖词条
    if ((own.lvl || 1) < C.LV_MAX) own.lvl = (own.lvl || 1) + 1; else { s.credits += C.REFUND[own.tier]; return { mod: own, dup: true, refund: C.REFUND[own.tier] }; }
    return { mod: own, dup: true };
  };
  // 看完广告：卡牌 / 芯片 +1 级（每日 AD.upDaily 次，最高 LV_MAX 级）
  C.adUpLeft = function () { return Math.max(0, C.AD.upDaily - (C.save.daily.adUp || 0)); };
  C.adUpgrade = function (it) {
    if (!it || (it.lvl || 1) >= C.LV_MAX) return { err: '已满级' };
    if (C.adUpLeft() <= 0) return { err: '今日广告升级次数已用完' };
    it.lvl = (it.lvl || 1) + 1; C.save.daily.adUp = (C.save.daily.adUp || 0) + 1; C.write(); return { ok: true };
  };
  C.modForm = function (k) { return C.MOD_FORMS.filter(function (x) { return x.k === k; })[0]; };
  C.modElem = function (k) { return C.ELEMENTS.filter(function (x) { return x.k === k; })[0]; };
  C.modTag = function (k) { return C.MOD_TAGS.filter(function (x) { return x.k === k; })[0]; };
  C.modDesc = function (m) {
    var F = C.modForm(m.form), mult = C.MOD_RARITY_MULT[m.tier];
    return F.d + '，伤害 ' + Math.round(F.dmg * mult * C.modLvMult(m)) + (F.cd ? '，冷却 ' + F.cd + ' 秒' : '，持续存在') + (F.count > 1 || m.tier === 3 ? '，数量 ' + (F.count + (m.tier === 3 ? 1 : 0)) : '');
  };

  // ------------------------------------------------------------------ 武器系统（v19）：每台机甲各自配装 主武器 / 副武器 / 氮气模块
  // 主武器：6 个系列 x 3 种型号（第 1 种是各机甲原装武器）；装在“本命”机甲上伤害 +10%。武器 Lv1~5，每级伤害 +12%。
  // 副武器：飞弹类，消耗弹药；在工坊“武器”页研发图纸、合成弹药（每次 5 发，库存上限 99），每次出击最多携带 20 发。
  // 氮气模块：6 种氮气推进可以装到任意机甲上；Lv1~5，每级冷却 -6%、距离 +5%。
  C.WFAM = [
    { k: 'laser', n: '射线枪', mech: 'mech_azure', d: '高速射线，穿透敌人' },
    { k: 'shotgun', n: '散射炮', mech: 'mech_blaze', d: '中近距离集束散射，强击退' },
    { k: 'heal', n: '追踪光弹', mech: 'mech_halo', d: '自动追踪的光弹，命中修复耐久' },
    { k: 'twin', n: '双臂机炮', mech: 'mech_forge', d: '两门机炮交替射击，射速快' },
    { k: 'lob', n: '肩载导弹', mech: 'mech_frost', d: '追踪导弹，命中范围爆炸' },
    { k: 'prism', n: '晶体长枪', mech: 'mech_starfall', d: '扇形晶体光弹，穿透' }
  ];
  C.WEAPONS = [
    { id: 'laser_0', fam: 'laser', m: 0, n: '星轨射线枪', d: '双发点射，每击穿透 2 个敌人', cost: 0, src: 0 },
    { id: 'laser_1', fam: 'laser', m: 1, n: '疾光速射枪', d: '射速 +60%，单发伤害 -38%，穿透 1', rate: 1.6, dmg: 0.62, pierce: -1, cost: 1200, src: 0 },
    { id: 'laser_2', fam: 'laser', m: 2, n: '裂星光矛', d: '单发重击：伤害 x2.3、穿透 5，射速 -25%', single: true, dmg: 2.3, pierce: 3, rate: 0.75, size: 1.6, cost: 2400, src: 15 },
    { id: 'shotgun_0', fam: 'shotgun', m: 0, n: '三管散射炮', d: '三根炮管依次点火，强击退', cost: 0, src: 0 },
    { id: 'shotgun_1', fam: 'shotgun', m: 1, n: '龙息喷火炮', d: '射程缩短，弹丸点燃敌人（持续灼烧），射速 +25%', burn: 0.2, range: 24, dmg: 0.8, rate: 1.25, tint: [1.6, 0.6, 0.15], cost: 1200, src: 0 },
    { id: 'shotgun_2', fam: 'shotgun', m: 2, n: '震荡霰弹炮', d: '弹丸减半、伤害 x1.5，命中小范围爆炸，击退更强', count: 0.5, dmg: 1.5, blastR: 2.2, kb: 2.5, cost: 2400, src: 15 },
    { id: 'heal_0', fam: 'heal', m: 0, n: '追踪光弹', d: '命中修复 0.5 耐久', cost: 0, src: 0 },
    { id: 'heal_1', fam: 'heal', m: 1, n: '星愈光弹', d: '命中修复 x2.4，伤害 -20%', heal: 2.4, dmg: 0.8, cost: 1200, src: 0 },
    { id: 'heal_2', fam: 'heal', m: 2, n: '流星光弹', d: '光弹 +1，命中范围溅射，不再修复耐久', extra: 1, splash: 2.6, heal: 0, cost: 2400, src: 15 },
    { id: 'twin_0', fam: 'twin', m: 0, n: '双臂机炮', d: '两门机炮交替射击，穿透 2', cost: 0, src: 0 },
    { id: 'twin_1', fam: 'twin', m: 1, n: '加特林机炮', d: '射速 x1.8，伤害 -40%，弹道略散', rate: 1.8, dmg: 0.6, jitter: 0.08, cost: 1200, src: 0 },
    { id: 'twin_2', fam: 'twin', m: 2, n: '爆裂机炮', d: '射速 -25%，子弹命中爆炸', rate: 0.75, dmg: 1.1, blastR: 2.4, cost: 2400, src: 15 },
    { id: 'lob_0', fam: 'lob', m: 0, n: '肩载导弹', d: '追踪导弹，命中范围爆炸', cost: 0, src: 0 },
    { id: 'lob_1', fam: 'lob', m: 1, n: '蜂巢导弹', d: '每轮多发 2 枚小导弹，单发伤害 -45%', extra: 2, dmg: 0.55, size: 0.7, cost: 1200, src: 0 },
    { id: 'lob_2', fam: 'lob', m: 2, n: '冰霜导弹', d: '爆炸范围 +30%，命中区域减速 2 秒（可触发碎冰）', splash: 1.3, dmg: 0.9, slow: 2, tint: [0.6, 0.9, 1.5], cost: 2400, src: 15 },
    { id: 'prism_0', fam: 'prism', m: 0, n: '星核长枪', d: '三向晶体光弹，穿透 2', cost: 0, src: 0 },
    { id: 'prism_1', fam: 'prism', m: 1, n: '五向晶簇枪', d: '晶体光弹 +2，扇面更宽，单发伤害 -28%', extra: 2, spread: 1.6, dmg: 0.72, cost: 1200, src: 0 },
    { id: 'prism_2', fam: 'prism', m: 2, n: '暴晶长枪', d: '单发：伤害 x2.4，暴击率 +30%，穿透 4', single: true, dmg: 2.4, crit: 0.3, pierce: 2, size: 1.5, cost: 2400, src: 15 }
  ];
  C.SUBS = [
    { id: 'swarm', n: '蜂群飞弹', d: '一次放出 8 枚追踪小飞弹，命中小范围爆炸', cd: 4, n0: 8, dmg: 16, r: 2.6, craft: 120, unlock: 0, src: 0, color: '#FF8A3A' },
    { id: 'cryo', n: '冰霜飞弹', d: '4 枚追踪飞弹，爆炸冻结范围内敌人 3 秒（可触发碎冰 / 融蚀反应）', cd: 5, n0: 4, dmg: 26, r: 5, craft: 160, unlock: 800, src: 0, el: 'ice', color: '#9DD8FF' },
    { id: 'emp', n: '电磁飞弹', d: '3 枚飞弹，命中后闪电连锁 4 个敌人并短暂麻痹（可触发碎冰 / 麻痹反应）', cd: 5, n0: 3, dmg: 34, chain: 4, craft: 200, unlock: 1000, src: 0, el: 'thunder', color: '#F5E050' },
    { id: 'cluster', n: '集束炸弹', d: '落向敌人最密集处，炸开 6 枚子弹并点燃敌人', cd: 6, n0: 6, dmg: 30, r: 3.6, main: 50, craft: 220, unlock: 1200, src: 0, el: 'fire', color: '#F5A524' },
    { id: 'heavy', n: '穿甲重弹', d: '优先锁定首领 / 精英 / 血量最高的敌人，大范围爆炸；对精英与首领伤害 +50%', cd: 7, n0: 1, dmg: 240, r: 6, craft: 260, unlock: 1500, src: 0, color: '#E0458C' },
    { id: 'gravity', n: '引力飞弹', d: '在敌群中制造黑洞牵引敌人 2.5 秒，随后坍缩爆炸', cd: 8, n0: 1, dmg: 120, r: 11, craft: 300, unlock: 2000, src: 10, el: 'dark', color: '#B47CFF' }
  ];
  C.NITROS = [
    { id: 'n_dash', n: '氮气冲刺', mech: 'mech_azure', d: '快速冲刺，冲刺中无敌', dist: 16, dur: 0.2, inv: 0.26, cd: 2.4 },
    { id: 'n_ram', n: '氮气冲撞', mech: 'mech_blaze', d: '撞飞沿途敌人并造成伤害', dist: 20, dur: 0.28, inv: 0.3, cd: 3.0, ram: 60 },
    { id: 'n_drift', n: '氮气漂移', mech: 'mech_halo', d: '漂移时修复 4% 耐久', dist: 15, dur: 0.24, inv: 0.3, cd: 2.4, heal: 0.04 },
    { id: 'n_boost', n: '氮气加速', mech: 'mech_forge', d: '长距离加速，无敌时间更长', dist: 34, dur: 0.9, inv: 0.35, cd: 3.4 },
    { id: 'n_retreat', n: '氮气后撤', mech: 'mech_frost', d: '向后撤离目标，原地留下减速力场', dist: 17, dur: 0.22, inv: 0.3, cd: 2.6, retreat: true },
    { id: 'n_warp', n: '氮气跃迁', mech: 'mech_starfall', d: '远距离跃迁', dist: 24, dur: 0.3, inv: 0.36, cd: 3.0 }
  ];
  // 机甲特性：按定位强化不同的武器搭配
  C.MECH_TRAIT = {
    mech_azure: { n: '全能适配', d: '主武器与副武器伤害 +10%', main: 0.1, sub: 0.1 },
    mech_blaze: { n: '近战压制', d: '15 米内主武器伤害 +25%，氮气冲撞伤害 x1.5', close: 0.25, ram: 1.5 },
    mech_halo: { n: '星愈回路', d: '副武器每次命中修复 1 耐久，主武器修复效果 +50%', subHeal: 1, heal: 0.5 },
    mech_forge: { n: '弹药工程', d: '副武器携带上限 +10，副武器冷却 -20%', cap: 10, subCd: 0.2 },
    mech_frost: { n: '火力覆盖', d: '副武器伤害 +30%，爆炸范围 +20%', sub: 0.3, blast: 0.2 },
    mech_starfall: { n: '星核共振', d: '主武器暴击率 +12%，副武器冷却 -10%', crit: 0.12, subCd: 0.1 }
  };
  C.ARM_LV_MAX = 5; C.SUB_STOCK_MAX = 99; C.SUB_CARRY = 20; C.SUB_BATCH = 5; C.NATIVE_BONUS = 0.1;
  C.weapon = function (id) { return C.WEAPONS.filter(function (w) { return w.id === id; })[0] || C.WEAPONS[0]; };
  C.subDef = function (id) { return C.SUBS.filter(function (w) { return w.id === id; })[0] || null; };
  C.nitroDef = function (id) { return C.NITROS.filter(function (w) { return w.id === id; })[0] || C.NITROS[0]; };
  C.wfam = function (k) { return C.WFAM.filter(function (f) { return f.k === k; })[0]; };
  C.nativeWeapon = function (mechId) { return C.mech(mechId).weapon.type + '_0'; };
  C.nativeNitro = function (mechId) { var n = C.NITROS.filter(function (x) { return x.mech === mechId; })[0]; return n ? n.id : 'n_dash'; };
  C.wLvMult = function (lv) { return 1 + 0.12 * ((lv || 1) - 1); };
  // 军械库存档：s.arms = { weapons: {id: {lv}}, subs: {id: {lv, stock}}, nitros: {id: {lv}}, loadout: {mechId: {main, sub, nitro}} }
  C.armory = function () {
    var s = C.save, a = s.arms;
    if (!a) {
      a = s.arms = { weapons: {}, subs: { swarm: { lv: 1, stock: 20 } }, nitros: {}, loadout: {} };
      C.WEAPONS.forEach(function (w) { if (w.m === 0) a.weapons[w.id] = { lv: 1 }; });
      C.NITROS.forEach(function (n) { a.nitros[n.id] = { lv: 1 }; });
    }
    a.weapons = a.weapons || {}; a.subs = a.subs || {}; a.nitros = a.nitros || {}; a.loadout = a.loadout || {};
    return a;
  };
  C.armLv = function (kind, id) { var it = C.armory()[kind][id]; return it ? it.lv || 1 : 0; };
  C.loadout = function (mechId) {
    var a = C.armory(), lo = a.loadout[mechId];
    if (!lo) lo = a.loadout[mechId] = { main: C.nativeWeapon(mechId), sub: 'swarm', nitro: C.nativeNitro(mechId) };
    if (!a.weapons[lo.main]) lo.main = C.nativeWeapon(mechId);
    if (lo.sub && !a.subs[lo.sub]) lo.sub = a.subs.swarm ? 'swarm' : null;
    if (!a.nitros[lo.nitro]) lo.nitro = C.nativeNitro(mechId);
    return lo;
  };
  C.equipArm = function (mechId, slot, id) {
    var lo = C.loadout(mechId), kind = slot === 'main' ? 'weapons' : slot === 'sub' ? 'subs' : 'nitros';
    if (id && !C.armory()[kind][id]) return { err: '还没有研发这件装备' };
    lo[slot] = id; C.write(); return { ok: true };
  };
  C.subCap = function (mechId) { var t = C.MECH_TRAIT[mechId] || {}; return C.SUB_CARRY + (t.cap || 0); };
  // 研发（解锁图纸）：信用点 + 星源
  C.armCost = function (kind, id) {
    if (kind === 'weapons') { var w = C.weapon(id); return { cr: w.cost, src: w.src || 0 }; }
    if (kind === 'subs') { var d = C.subDef(id); return { cr: d.unlock, src: d.src || 0 }; }
    return { cr: 600, src: 0 };
  };
  C.armUnlock = function (kind, id) {
    var a = C.armory(), s = C.save, c = C.armCost(kind, id);
    if (a[kind][id]) return { err: '已经拥有' };
    if (s.credits < c.cr) return { err: '信用点不足（需要 ' + c.cr.toLocaleString('zh-CN') + '）' };
    if (s.src < c.src) return { err: '星源不足（需要 ' + c.src + '）' };
    s.credits -= c.cr; s.src -= c.src;
    a[kind][id] = kind === 'subs' ? { lv: 1, stock: 10 } : { lv: 1 };
    C.write(); return { ok: true };
  };
  C.armUpCost = function (kind, lv) { return (kind === 'weapons' ? 400 : kind === 'subs' ? 350 : 250) * lv; };
  C.armUpgrade = function (kind, id) {
    var it = C.armory()[kind][id], s = C.save; if (!it) return { err: '还没有研发' };
    var lv = it.lv || 1; if (lv >= C.ARM_LV_MAX) return { err: '已满级' };
    var cost = C.armUpCost(kind, lv); if (s.credits < cost) return { err: '信用点不足（需要 ' + cost.toLocaleString('zh-CN') + '）' };
    s.credits -= cost; it.lv = lv + 1; C.write(); return { ok: true, lv: it.lv };
  };
  // 看广告升级：与卡牌 / 芯片共用每日次数
  C.armAdUp = function (kind, id) {
    var it = C.armory()[kind][id]; if (!it) return { err: '还没有研发' };
    if ((it.lv || 1) >= C.ARM_LV_MAX) return { err: '已满级' };
    if (C.adUpLeft() <= 0) return { err: '今日广告升级次数已用完' };
    it.lv = (it.lv || 1) + 1; C.save.daily.adUp = (C.save.daily.adUp || 0) + 1; C.write(); return { ok: true, lv: it.lv };
  };
  // 合成弹药：每次 5 发，库存上限 99
  C.craftAmmo = function (id, times) {
    var it = C.armory().subs[id], d = C.subDef(id), s = C.save; times = times || 1;
    if (!it || !d) return { err: '先研发这种飞弹的图纸' };
    var room = Math.floor((C.SUB_STOCK_MAX - (it.stock || 0)) / C.SUB_BATCH); times = Math.min(times, room);
    if (times <= 0) return { err: '库存已满（' + C.SUB_STOCK_MAX + '）' };
    var cost = d.craft * times; if (s.credits < cost) return { err: '信用点不足（需要 ' + cost.toLocaleString('zh-CN') + '）' };
    s.credits -= cost; it.stock = (it.stock || 0) + C.SUB_BATCH * times; C.write(); return { ok: true, n: C.SUB_BATCH * times, cost: cost };
  };
  // 出击结算：用掉的弹药从库存扣除，局内捡到的弹药补回库存
  C.settleAmmo = function (id, used, gained) {
    var it = C.armory().subs[id]; if (!it) return;
    it.stock = Math.max(0, Math.min(C.SUB_STOCK_MAX, (it.stock || 0) - used + gained));
  };
  C.armPower = function (mechId) {
    // 只计算超出初始配装的部分（老存档战力不变）：武器每级 +3.6，改型 +8；飞弹每级 +2.2，高级飞弹 +6；氮气每级 +4
    var lo = C.loadout(mechId), w = C.weapon(lo.main), p = 30 * (C.wLvMult(C.armLv('weapons', lo.main)) - 1) + (w.m > 0 ? 8 : 0);
    if (lo.sub) p += 18 * (C.wLvMult(C.armLv('subs', lo.sub)) - 1) + (lo.sub !== 'swarm' ? 6 : 0);
    return Math.round(p + 4 * (C.armLv('nitros', lo.nitro) - 1));
  };
  // 武器图标（8x8 像素，a = 主色，b = 白色高光），格式与技能卡牌图标相同：{ w, h, pal, px }
  var ARM_PAT = {
    laser: ['........', '........', 'aaa.....', 'abbbbbbb', 'aaa.....', '........', '........', '........'],
    shotgun: ['......a.', '....a...', 'aaa.a.a.', 'abbaa...', 'aaa.a.a.', '....a...', '......a.', '........'],
    heal: ['..aaaa..', '.aaabaa.', 'aaabbbaa', 'aabbbbba', 'aaabbbaa', '.aaabaa.', '..aaaa..', '........'],
    twin: ['........', 'aaaaaab.', 'aaaaaab.', '........', 'aaaaaab.', 'aaaaaab.', '........', '........'],
    lob: ['...b....', '..aaa...', '..aaa...', '..aaa...', '.aaaaa..', '.a.a.a..', '...b....', '........'],
    prism: ['...a....', '..aba...', '.abbba..', 'abbbbba.', '.abbba..', '..aba...', '...a....', '........'],
    swarm: ['aab.....', '........', '...aab..', '........', 'aab.....', '........', '...aab..', '........'],
    cryo: ['...a....', '.a.a.a..', '..aba...', 'aabbbaa.', '..aba...', '.a.a.a..', '...a....', '........'],
    emp: ['....aa..', '...aa...', '..aaaa..', '.aabba..', '...aa...', '..aa....', '.aa.....', '........'],
    cluster: ['....b...', '...a....', '.aaaaa..', 'aaabaaa.', 'aabbbaa.', 'aaabaaa.', '.aaaaa..', '........'],
    heavy: ['........', '..a.....', 'aaaaaab.', 'aaaaaabb', 'aaaaaab.', '..a.....', '........', '........'],
    gravity: ['..aaaa..', '.a....a.', 'a..bb..a', 'a.b..b.a', 'a..bb..a', '.a....a.', '..aaaa..', '........'],
    nitro: ['........', 'a.......', 'aa..bb..', 'aaabbbb.', 'aa..bb..', 'a.......', '........', '........']
  };
  var FAM_COL = { laser: '#5CF2DC', shotgun: '#FF8A3A', heal: '#7CF29A', twin: '#F5A524', lob: '#9DD8FF', prism: '#B47CFF' };
  C.armIcon = function (kind, id) {
    var key, col;
    if (kind === 'weapons') { var w = C.weapon(id); key = w.fam; col = FAM_COL[w.fam]; }
    else if (kind === 'subs') { var d = C.subDef(id); key = d.id; col = d.color; }
    else { key = 'nitro'; col = '#57B8FF'; }
    var px = ''; ARM_PAT[key].forEach(function (r) { for (var i = 0; i < r.length; i++) px += r[i] === '.' ? '.' : r[i] === 'a' ? '0' : '1'; });
    return { w: 8, h: 8, pal: [col, '#FFFFFF'], px: px };
  };
  C.armColor = function (kind, id) { return kind === 'weapons' ? FAM_COL[C.weapon(id).fam] : kind === 'subs' ? C.subDef(id).color : '#57B8FF'; };
})();
