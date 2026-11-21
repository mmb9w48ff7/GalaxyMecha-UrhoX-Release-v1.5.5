-- 由 xpile-lite（tools/xpile_lite/transpile.js）从 cosmic_data.js + cosmic_icons.js（网页版 21） 自动生成，请勿手改。
-- 运行库见 jsrt/JS.lua。改玩法请改网页版 JS 后重新转换。
local JS = require("jsrt.JS")
local G, T, OR, AND, S2, LEN, MOD, typeof, tonum, smt, AMT = JS.G, JS.T, JS.OR, JS.AND, JS.S, JS.len, JS.mod, JS.typeof, JS.tonum, setmetatable, JS.AMT
local bor, band, bxor, shl, shr, ushr = JS.bor, JS.band, JS.bxor, JS.shl, JS.shr, JS.ushr
local Math_abs, Math_min, Math_max, Math_floor, Math_ceil, Math_round, Math_sqrt, Math_sin, Math_cos, Math_tan, Math_asin, Math_atan2, Math_exp, Math_hypot, Math_pow, Math_random, Math_sign, Math_imul, Math_PI = JS.Math_abs, JS.Math_min, JS.Math_max, JS.Math_floor, JS.Math_ceil, JS.Math_round, JS.Math_sqrt, JS.Math_sin, JS.Math_cos, JS.Math_tan, JS.Math_asin, JS.Math_atan2, JS.Math_exp, JS.Math_hypot, JS.Math_pow, JS.Math_random, JS.Math_sign, JS.Math_imul, math.pi
return function(HOST)
local S = {}
S.today = function(_this)
local d;
d = G.new_Date();
do return ((((S2(d:getFullYear()) .. "-") .. S2((d:getMonth() + 1))) .. "-") .. S2(d:getDate())) end;
end;
S.dayKey = function(_this, d)
do return ((((S2(d:getFullYear()) .. "-") .. S2((d:getMonth() + 1))) .. "-") .. S2(d:getDate())) end;
end;
S.b64buf = function(_this, b64)
local bin, n, u, i;
bin = HOST.atob(nil,b64); n = LEN(bin); u = G.new_Uint8Array(n);
do
i = 0;
while (i < n) do
u[i] = bin:charCodeAt(i);
i = i + 1;
end
end;
do return u.buffer end;
end;
S.loadAudio = function(_this)
if ((T(S.loading) or (not T(S.actx))) or (not T(HOST.window.OGG_AUDIO))) then
do return end;
end;
S.loading = true;
;(G.Object:keys(HOST.window.OGG_AUDIO)):forEach(function(_this, k)
local e;
do local _ok, _f, _v = pcall(function()
S.actx:decodeAudioData(S.b64buf(nil,HOST.window.OGG_AUDIO[k]),function(_this, b)
S.bufs[k] = b;
if (((k:indexOf("bgm_") == 0) and T(S.mus.want)) and (not T(S.mus.src))) then
S.C.music:play(S.mus.want);
end;
end,function(_this)
end);
end)
if not _ok then e = _f
elseif _f == "R" then do return _v end end end;
end);
end;
S.stopMusic = function(_this)
local e;
if T(S.mus.src) then
do local _ok, _f, _v = pcall(function()
S.mus.src:stop();
end)
if not _ok then e = _f
elseif _f == "R" then do return _v end end end;
S.mus.src = nil;
end;
S.mus.name = nil;
end;
S.rnd = function(_this, a, b)
do return (a + (Math_random() * (b - a))) end;
end;
S.rollRarity = function(_this, pityKey)
local s, t, sum, i, x;
s = S.C.save; t = 0; sum = 0;
S.C.RARITY:forEach(function(_this, r)
sum = (sum + r.w);
end);
x = (Math_random() * sum);
do
i = 0;
while (i < LEN(S.C.RARITY)) do
x = (x - S.C.RARITY[i].w);
if (x <= 0) then
t = i;
do break end;
end;
i = i + 1;
end
end;
s[pityKey] = ((T(s[pityKey]) and s[pityKey] or 0) + 1);
if (MOD(s[pityKey],40) == 0) then
t = Math_max(t,3);
elseif (MOD(s[pityKey],10) == 0) then
t = Math_max(t,1);
end;
do return t end;
end;
S.hsl2hex = function(_this, h, s, l)
local k, a, f;
s = (s / 100);
l = (l / 100);
k = function(_this, n)
do return MOD((n + (h / 30)),12) end;
end; a = (s * Math_min(l,(1 - l)));
f = function(_this, n)
do return Math_round((255 * (l - (a * Math_max((-1),(Math_min((k(nil,n) - 3),(Math_min((9 - k(nil,n)),1))))))))) end;
end;
do return ("#" .. ((smt({[0]=f(nil,0),f(nil,8),(f(nil,4)),length=3},AMT)):map(function(_this, x)
do return (((x < 16) and "0" or "") .. x:toString(16)) end;
end)):join("")) end;
end;
S.seeded = function(_this, str)
local h, i;
h = bxor(1779033703,LEN(str));
do
i = 0;
while (i < LEN(str)) do
h = Math_imul(bxor(h,str:charCodeAt(i)),3432918353);
h = bor(shl(h,13),ushr(h,19));
i = i + 1;
end
end;
do return function(_this)
h = Math_imul(bxor(h,ushr(h,16)),2246822507);
h = Math_imul(bxor(h,ushr(h,13)),3266489909);
h = bxor(h,ushr(h,16));
do return (ushr(h,0) / 4294967296) end;
end end;
end;
S.C = (function() HOST.window.Cosmic = (T(HOST.window.Cosmic) and HOST.window.Cosmic or JS.dict()); return HOST.window.Cosmic end)();
S.SAVE_KEY = "galaxy-mecha-save-v8";
S.C.MECHS = smt({[0]={id="mech_azure",grade="S",name="苍星",type="均衡型",match="char_xingli",hp=100,spd=15,fire=3,skill="char_xingli",weapon={type="laser",name="星轨射线枪",desc="高速射线连发两击，每击穿透 2 个敌人"},active={name="星轨狙击",cd=14,desc="射出贯穿全图的光束，对直线上所有敌人造成 230 伤害",awake="觉醒：同时射出 3 道扇形光束"}},{id="mech_blaze",grade="S",name="炎铠",type="重装型",match="char_chiyan",hp=140,spd=13.5,fire=4,skill="char_chiyan",weapon={type="shotgun",name="散射炮",desc="中近距离集束散射，附带强击退"},active={name="烈焰冲锋",cd=9,desc="冲刺 32 米，冲刺中无敌，撞飞沿途敌人并造成 140 伤害",awake="觉醒：冲刺路径留下灼烧火焰"}},{id="mech_halo",grade="SS",name="月辉",type="支援型",match="char_yuexi",hp=105,spd=15,fire=2,skill="char_yuexi",weapon={type="heal",name="追踪光弹",desc="追踪敌人的光弹，伤害较高，每次命中修复 0.5 耐久"},active={name="星愈领域",cd=16,desc="展开治疗力场 6 秒，每秒修复 8% 耐久，力场内敌人减速并每秒受到 25 伤害",awake="觉醒：力场伤害翻倍"}},{id="mech_forge",grade="SSSR",name="琥珀工兵",type="工程型",match="char_hupo",hp=135,spd=14,fire=3,skill="char_hupo",weapon={type="twin",name="双臂机炮",desc="两门旋转机炮并排射击，射速快，穿透 2 个敌人"},active={name="炮台阵列",cd=16,desc="投放 3 座爆破炮台，持续 10 秒，炮弹命中后小范围爆炸",awake="觉醒：投放 5 座炮台"}},{id="mech_frost",grade="SS",name="霜鸣",type="炮击型",match="char_shuangling",hp=110,spd=15.5,fire=5,skill="char_shuangling",weapon={type="lob",name="肩载导弹",desc="发射追踪导弹，命中后范围爆炸"},active={name="冰霜导弹雨",cd=13,desc="在敌群中落下 16 枚导弹，每枚 15 范围伤害并减速 3 秒",awake="觉醒：导弹数量翻倍"}},{id="mech_starfall",grade="SSR",name="天殒",type="星核型",match="char_yeyuan",hp=125,spd=15,fire=5,skill="starfall",weapon={type="prism",name="星核长枪",desc="三向晶体光弹，穿透 1 个敌人"},active={name="天殒坠星",cd=14,desc="召唤巨型陨星砸向敌群，造成 200 范围伤害，并溅射 6 枚碎晶",awake="觉醒：连续坠落 2 颗陨星"}},length=6},AMT);
S.C.GRADE = {S={mul=1.0,color="#57B8FF",frag=6},SS={mul=1.15,color="#B47CFF",frag=12},SSR={mul=1.25,color="#F5A524",frag=25},SSSR={mul=1.4,color="#FF5D7A",frag=40}};
S.C.MECH_MAX = 30;
S.C.MECH_AWAKE = 10;
S.C.mechCost = function(_this, lv)
do return Math_round((250 * Math_pow(1.28,(lv - 1)))) end;
end;
S.C.mech = function(_this, id)
local i;
do
i = 0;
while (i < LEN(S.C.MECHS)) do
if (S.C.MECHS[i].id == id) then
do return S.C.MECHS[i] end;
end;
i = i + 1;
end
end;
do return nil end;
end;
S.C.mechLv = function(_this, id)
do return (function() local _t = (function() local _t = S.C.save.mechs[id]; if not T(_t) then return _t end; return S.C.save.mechs[id].lv end)(); if T(_t) then return _t end; return 1 end)() end;
end;
S.C.ownsMech = function(_this, id)
do return (not (not T(S.C.save.mechs[id]))) end;
end;
S.C.MATCH_BONUS = 0.2;
S.C.CHARS = smt({[0]={id="char_xingli",grade="S",name="星璃",role="狙击手",color="#4FD6D0",mech="mech_azure",weapon={type="laser",name="穿透激光",desc="高速激光，穿透 1 个敌人"},active={name="星轨狙击",cd=14,desc="朝最近的敌人射出贯穿全图的光束，造成 150 点伤害",awake="觉醒：同时射出 3 道扇形光束"},support={name="狙击光束",cd=4,desc="每 4 秒射出光束，对最强的敌人造成 55 伤害"},passive={name="暴击率 +10%",fx={crit=0.1}},lines=smt({[0]="锁定。","别乱动，我在瞄准。","目标清除。",length=3},AMT)},{id="char_chiyan",grade="S",name="赤焰",role="突击手",color="#E2552F",mech="mech_blaze",weapon={type="shotgun",name="散射炮",desc="中近距离集束散射，附带强击退"},active={name="烈焰冲锋",cd=9,desc="朝移动方向冲刺 32 米，冲刺中无敌并撞飞敌人",awake="觉醒：冲刺路径留下灼烧火焰"},support={name="烈焰突击",cd=7,desc="每 7 秒放出火焰幻影冲锋，沿途造成 70 伤害"},passive={name="耐久上限 +25%",fx={hull=0.25}},lines=smt({[0]="让开让开！","交给我正面！","冲啊——",length=3},AMT)},{id="char_yuexi",grade="SS",name="月汐",role="医疗兵",color="#9B7BEA",mech="mech_halo",weapon={type="heal",name="治疗追踪弹",desc="追踪敌人的星光弹，每次命中修复船体"},active={name="星愈领域",cd=18,desc="展开治疗领域 6 秒，每秒修复 8% 船体，敌人进入会减速",awake="觉醒：领域同时持续伤害敌人"},support={name="治疗光环",cd=8,desc="每 8 秒修复 15 耐久，并对周围敌人造成 15 伤害"},passive={name="每秒修复 1% 耐久",fx={regen=0.01}},lines=smt({[0]="伤口交给我。","撑住，马上就好。","大家都还在吧？",length=3},AMT)},{id="char_hupo",grade="SSSR",name="琥珀",role="工程师",color="#F08A2C",mech="mech_forge",weapon={type="twin",name="双联机炮",desc="两门机炮并排射击，射速快"},active={name="炮台阵列",cd=16,desc="在周围投放 3 座自动炮台，持续 10 秒",awake="觉醒：投放 5 座炮台"},support={name="速建炮塔",cd=9,desc="每 9 秒架设 1 座炮塔，持续 8 秒"},passive={name="炮台伤害 +30%，搜刮采矿 +50%",fx={loot=0.5,turret=0.3}},lines=smt({[0]="炮塔上线！","这个我改过，威力翻倍。","扳手才是正义。",length=3},AMT)},{id="char_shuangling",grade="SS",name="霜铃",role="爆破手",color="#57B8FF",mech="mech_frost",weapon={type="lob",name="抛射导弹",desc="发射追踪导弹，命中后范围爆炸"},active={name="冰霜导弹雨",cd=15,desc="在敌群中落下 12 枚导弹，命中区域减速",awake="觉醒：导弹数量翻倍"},support={name="导弹雨",cd=5,desc="每 5 秒召唤 7 枚导弹，每枚 12 范围伤害"},passive={name="爆炸范围 +20%",fx={blast=0.2}},lines=smt({[0]="点火——发射！","烟花时间到了！","再来一轮？",length=3},AMT)},{id="char_yeyuan",grade="SSR",name="夜鸢",role="领航员",color="#B47CFF",mech="mech_starfall",support={name="引力陷阱",cd=7,desc="每 7 秒在敌群中制造引力井 3 秒，牵引敌人并每秒造成 16 伤害"},passive={name="拾取范围 +40%，闪避冷却 -30%",fx={pickup=0.4,dodge=0.3}},lines=smt({[0]="航线修正完毕。","它们逃不掉的。","跟着我的标记走。",length=3},AMT)},length=6},AMT);
S.C.power = function(_this)
local s, id, m, k, p;
s = S.C.save; id = s.mech; m = S.C:mech(id); k = ((S.C:mechMul(id) * (function() if (m.match == s.pilot) then return (1 + S.C.MATCH_BONUS) else return 1 end end)()) * S.C:pilotMul(s.pilot)); p = ((m.hp + (m.fire * 18)) * k);
;(S.C:topMods(3)):forEach(function(_this, c)
p = (p + (((c.tier + 1) * 9) * S.C:modLvMult(c)));
end);
p = (p + S.C:armPower(id));
;((T(s.chipEq) and s.chipEq or smt({length=0},AMT))):forEach(function(_this, cid)
local c;
c = (s.chips:filter(function(_this, x)
do return (x.id == cid) end;
end))[0];
if T(c) then
p = (p + (((c.tier + 1) * 7) * S.C:chipLvMult(c)));
end;
end);
do return Math_round(p) end;
end;
S.C.STAR_FRAGS = smt({[0]=0,10,20,40,80,length=5},AMT);
S.C.CHAPTERS = smt({[0]={id=1,rec=180,name="灰烬星域",boss="gunship_boss",bossName="海贼头目号",hp=1,dmg=1,first=30,env={bg=smt({[0]=0.05,0.06,0.15,length=3},AMT),ambient=smt({[0]=0.42,0.40,0.55,length=3},AMT),fog=smt({[0]=5000,9000,length=2},AMT),key={dir=smt({[0]=0.35,(-0.85),0.4,length=3},AMT),color=smt({[0]=1,0.92,0.82,length=3},AMT),brightness=1.15},fill={dir=smt({[0]=(-0.5),(-0.3),(-0.6),length=3},AMT),color=smt({[0]=0.5,0.8,1.0,length=3},AMT),brightness=0.45},bloom={threshold=0.5,mix=1.0}},mix=smt({[0]="crawler","crawler","grunt","inter",length=4},AMT),desc="货运航线上的海贼越来越嚣张，击败他们的头目。"},{id=2,rec=300,name="碎石星域",boss="brute_king",bossName="晶核巨兽王",hp=1.35,dmg=1.1,first=40,env={bg=smt({[0]=0.06,0.05,0.12,length=3},AMT),ambient=smt({[0]=0.40,0.36,0.50,length=3},AMT),fog=smt({[0]=5000,9000,length=2},AMT),key={dir=smt({[0]=0.4,(-0.8),0.45,length=3},AMT),color=smt({[0]=1,0.86,0.72,length=3},AMT),brightness=1.15},fill={dir=smt({[0]=(-0.5),(-0.3),(-0.6),length=3},AMT),color=smt({[0]=0.5,0.95,0.85,length=3},AMT),brightness=0.5},bloom={threshold=0.45,mix=1.1}},mix=smt({[0]="crawler","crawler","crawler","grunt","inter","heavy",length=6},AMT),desc="晶化生物在碎石带疯狂繁殖，巢穴深处有一头巨兽之王。"},{id=3,rec=460,name="赤环星域",boss="flagship_boss",bossName="赤髑号",hp=1.75,dmg=1.2,first=60,env={bg=smt({[0]=0.09,0.04,0.08,length=3},AMT),ambient=smt({[0]=0.44,0.34,0.42,length=3},AMT),fog=smt({[0]=5000,9000,length=2},AMT),key={dir=smt({[0]=(-0.3),(-0.85),0.4,length=3},AMT),color=smt({[0]=1,0.78,0.62,length=3},AMT),brightness=1.2},fill={dir=smt({[0]=0.6,(-0.2),(-0.5),length=3},AMT),color=smt({[0]=0.95,0.45,0.65,length=3},AMT),brightness=0.5},bloom={threshold=0.45,mix=1.1}},mix=smt({[0]="crawler","grunt","grunt","inter","inter","heavy",length=6},AMT),desc="星海贼团的老巢。赤髑在这里等着你。"},length=3},AMT);
S.C.HANGAR = smt({[0]={id="hull",name="装甲板",desc="船体上限 +8%",max=20},{id="gun",name="主炮校准",desc="主武器伤害 +6%",max=20},length=2},AMT);
S.C.hangarCost = function(_this, lv)
do return Math_round((300 * Math_pow(1.35,lv))) end;
end;
S.C.SUMMON = {single=10,ten=90,rates={SSSR=0.01,SSR=0.04,SS=0.2,S=0.75},pitySSR=50,pitySSSR=120};
S.C.mechStar = function(_this, id)
local m;
m = S.C.save.mechs[id];
do return (function() if T(m) then return (T(m.star) and m.star or 1) else return 0 end end)() end;
end;
S.C.mechMul = function(_this, id)
local m;
m = S.C:mech(id);
do return ((S.C.GRADE[m.grade].mul * (1 + (0.1 * (S.C:mechStar(id) - 1)))) * (1 + (0.05 * (S.C:mechLv(id) - 1)))) end;
end;
S.C.pilotMul = function(_this, id)
local c;
c = S.C:char(id);
do return (S.C.GRADE[c.grade].mul * S.C:starMult(id)) end;
end;
S.C.pull = function(_this, kind, forceSS)
local s, pk, list, own, RT, r, pk3, g, pool, it, n;
s = S.C.save; pk = (S2(kind) .. "Pity"); list = (function() if (kind == "mech") then return S.C.MECHS else return S.C.CHARS end end)(); own = (function() if (kind == "mech") then return s.mechs else return s.chars end end)();
s[pk] = ((T(s[pk]) and s[pk] or 0) + 1);
s.pulls = s.pulls + 1;
RT = S.C.SUMMON.rates; r = Math_random(); pk3 = (S2(kind) .. "Pity3");
g = ((r < RT.SSSR) and "SSSR" or ((r < (RT.SSSR + RT.SSR)) and "SSR" or ((r < ((RT.SSSR + RT.SSR) + RT.SS)) and "SS" or "S")));
s[pk3] = ((T(s[pk3]) and s[pk3] or 0) + 1);
if (T(forceSS) and (g == "S")) then
g = "SS";
end;
if (s[pk3] >= S.C.SUMMON.pitySSSR) then
g = "SSSR";
elseif ((s[pk] >= S.C.SUMMON.pitySSR) and ((g == "S") or (g == "SS"))) then
g = "SSR";
end;
if (g == "SSSR") then
s[pk3] = 0;
s[pk] = 0;
elseif (g == "SSR") then
s[pk] = 0;
end;
pool = list:filter(function(_this, x)
do return (x.grade == g) end;
end); it = pool[Math_floor((Math_random() * LEN(pool)))];
if (not T(own[it.id])) then
own[it.id] = ((kind == "mech") and {lv=1,star=1} or {star=1});
do return {kind=kind,id=it.id,grade=g,isNew=true} end;
end;
n = S.C.GRADE[g].frag;
s.frags[it.id] = ((T(s.frags[it.id]) and s.frags[it.id] or 0) + n);
do return {kind=kind,id=it.id,grade=g,frag=n} end;
end;
S.C.AD = {srcReward=10,srcDaily=5,upDaily=5};
S.C.LV_MAX = 5;
S.C.DAILY_SUPPLY = 10;
S.C.TASKS = smt({[0]={id="run",name="完成 1 次远征",key="runs",need=1,reward=5},{id="kill",name="击败 300 个敌人",key="kills",need=300,reward=5},{id="pull",name="召唤 1 次",key="pulls",need=1,reward=5},length=3},AMT);
S.C.IDLE_CAP_H = 8;
S.C.idleRate = function(_this)
local s, n, b;
s = S.C.save; n = LEN((G.Object:keys(s.cleared))); b = 0;
;(G.Object:keys(s.best)):forEach(function(_this, k)
b = (b + s.best[k]);
end);
do return ((240 + (160 * n)) + (15 * b)) end;
end;
S.C.idleAmount = function(_this)
local h;
h = Math_min(S.C.IDLE_CAP_H,((G.Date:now() - (T(S.C.save.idleT) and S.C.save.idleT or G.Date:now())) / 3600000));
do return {credits=Math_floor((h * S.C:idleRate())),hours=h} end;
end;
S.C.newSave = function(_this)
local mechs;
mechs = {mech_azure={lv=1,star=1},mech_blaze={lv=1,star=1}};
do return {credits=600,src=30,chars={char_xingli={star=1},char_chiyan={star=1}},frags=JS.dict(),mechs=mechs,pilot="char_xingli",mech="mech_azure",chips=smt({length=0},AMT),chipEq=smt({length=0},AMT),modules=smt({length=0},AMT),modEq=smt({length=0},AMT),chipBuys=0,modBuys=0,pulls=0,mechPity=0,pilotPity=0,hangar={hull=0,gun=0},chapter=1,cleared=JS.dict(),best=JS.dict(),daily={day="",ads=0,free=0,supply=0,runs=0,kills=0,pulls=0,claimed=JS.dict()},runs=0,login={last="",n=0},ach=JS.dict(),totalKills=0,bossKills=0,dangerMax=1,endlessBest=0,dc=nil,dcBest=0,settings={sound=true,music=true,quality="auto"},idleT=G.Date:now(),tutorialDone=false} end;
end;
S.C.load = function(_this)
local s, t, e, m1, m2, seen, mods, idmap;
s = nil;
do local _ok, _f, _v = pcall(function()
t = HOST.localStorage:getItem(S.SAVE_KEY);
s = (function() if T(t) then return G.JSON:parse(t) else return nil end end)();
end)
if not _ok then e = _f
s = nil;
elseif _f == "R" then do return _v end end end;
if (not T(s)) then
s = S.C:newSave();
S.C.save = s;
m1 = S.C:makeModule(0,"homing","light"); m2 = S.C:makeModule(0,"nova","ice");
s.modules = smt({[0]=m1,m2,length=2},AMT);
s.modEq = smt({[0]=m1.id,m2.id,length=2},AMT);
end;
if (s.daily.day ~= S.today(nil)) then
s.daily = {day=S.today(nil),adUp=0,ads=0,free=0,supply=0,runs=0,kills=0,pulls=0,claimed=JS.dict()};
end;
s.login = (T(s.login) and s.login or {last="",n=0});
s.ach = (T(s.ach) and s.ach or JS.dict());
s.totalKills = (T(s.totalKills) and s.totalKills or 0);
s.bossKills = (T(s.bossKills) and s.bossKills or 0);
s.dangerMax = (T(s.dangerMax) and s.dangerMax or 1);
s.endlessBest = (T(s.endlessBest) and s.endlessBest or 0);
s.dcBest = (T(s.dcBest) and s.dcBest or 0);
s.settings = (T(s.settings) and s.settings or {sound=true,music=true,quality="auto"});
if (s.settings.music == nil) then
s.settings.music = true;
end;
s.idleT = (T(s.idleT) and s.idleT or G.Date:now());
s.daily.claimed = (T(s.daily.claimed) and s.daily.claimed or JS.dict());
seen = JS.dict(); mods = smt({length=0},AMT); idmap = JS.dict();
;((T(s.modules) and s.modules or smt({length=0},AMT))):forEach(function(_this, m)
local v, fresh, o;
v = ((m.v == nil) and 0 or m.v); fresh = S.C:makeModule(m.tier,m.form,m.elem,v);
idmap[m.id] = fresh.id;
if T(seen[fresh.id]) then
o = seen[fresh.id];
o.lvl = Math_min(S.C.LV_MAX,((T(o.lvl) and o.lvl or 1) + (T(m.lvl) and m.lvl or 1)));
do return end;
end;
fresh.lvl = (T(m.lvl) and m.lvl or 1);
seen[fresh.id] = fresh;
mods:push(fresh);
end);
s.modules = mods;
s.modEq = ((((T(s.modEq) and s.modEq or smt({length=0},AMT))):map(function(_this, i)
do return (T(idmap[i]) and idmap[i] or i) end;
end)):filter(function(_this, i, k, a)
do return (T(seen[i]) and (a:indexOf(i) == k)) end;
end)):slice(0,3);
;((T(s.chips) and s.chips or smt({length=0},AMT))):forEach(function(_this, c)
c.lvl = (T(c.lvl) and c.lvl or 1);
end);
S.C.save = s;
S.C:armory();
if (s.settings.subAuto == nil) then
s.settings.subAuto = true;
end;
if (s.settings.lvMode == nil) then
s.settings.lvMode = (((T(s.runs) and s.runs or 0) >= 3) and "later" or "now");
end;
do return s end;
end;
S.C.DC_TIME = 240;
S.C.DC_MODS = smt({[0]={id="tide",n="狂潮",d="敌人数量 +30%，能量获取 +50%"},{id="swift",n="疾风",d="敌人移速 +25%，你的移速 +15%"},{id="fury",n="狂暴",d="敌人伤害 +25%，能量获取 +30%"},{id="iron",n="铁壁",d="敌人血量 +50%，信用点收益 +50%"},{id="glass",n="玻璃大炮",d="你的耐久 -30%，伤害 +40%"},{id="elite",n="精英日",d="每 40 秒出现一只精英，击败后回复 10% 耐久"},length=6},AMT);
S.C.dailyChallenge = function(_this)
local key, rnd, pool, mods, i, ch, dc;
key = (function(_this)
local d;
d = G.new_Date();
do return ((((S2(d:getFullYear()) .. "-") .. S2((d:getMonth() + 1))) .. "-") .. S2(d:getDate())) end;
end)(nil); rnd = S.seeded(nil,("dc" .. S2(key))); pool = S.C.DC_MODS:slice(); mods = smt({length=0},AMT);
do
i = 0;
while (i < 2) do
mods:push(((pool:splice(Math_floor((rnd(nil) * LEN(pool))),1))[0]).id);
i = i + 1;
end
end;
ch = (1 + Math_floor((rnd(nil) * Math_max(1,(Math_min(LEN(S.C.CHAPTERS),S.C.save.chapter))))));
dc = S.C.save.dc;
if ((not T(dc)) or (dc.day ~= key)) then
S.C.save.dc = {day=key,best=0,done=false,runs=0};
dc = S.C.save.dc;
end;
do return {day=key,chapter=ch,mods=mods,danger=2,state=dc} end;
end;
S.C.dcMod = function(_this, id)
do return (S.C.DC_MODS:filter(function(_this, m)
do return (m.id == id) end;
end))[0] end;
end;
S.C.LOGIN_REWARDS = smt({[0]={cr=500},{src=10},{cr=800},{src=15},{cr=1200},{src=20},{src=40,draw=1},length=7},AMT);
S.C.loginState = function(_this)
local l, t, y, idx;
l = S.C.save.login; t = S.today(nil); y = G.new_Date();
y:setDate((y:getDate() - 1));
if (l.last == t) then
do return {claimed=true,idx=MOD((l.n + 6),7)} end;
end;
idx = (function() if (l.last == S.dayKey(nil,y)) then return MOD(l.n,7) else return 0 end end)();
do return {claimed=false,idx=idx} end;
end;
S.C.loginClaim = function(_this)
local st, rw, l, txt, r;
st = S.C:loginState();
if T(st.claimed) then
do return nil end;
end;
rw = S.C.LOGIN_REWARDS[st.idx]; l = S.C.save.login; txt = smt({length=0},AMT);
if T(rw.cr) then
S.C.save.credits = (S.C.save.credits + rw.cr);
txt:push(("信用点 +" .. S2(rw.cr)));
end;
if T(rw.src) then
S.C.save.src = (S.C.save.src + rw.src);
txt:push(("星源 +" .. S2(rw.src)));
end;
if T(rw.draw) then
S.C.save.credits = (S.C.save.credits + S.C:MOD_COST((T(S.C.save.modBuys) and S.C.save.modBuys or 0)));
r = S.C:buyModule();
if T(r.mod) then
txt:push(("免费抽到卡牌：" .. S2(r.mod.name)));
end;
end;
l.last = S.today(nil);
l.n = (st.idx + 1);
S.C:write();
do return txt:join("，") end;
end;
S.C.ACH = smt({[0]={id="a_run1",name="首次出击",desc="完成 1 次远征",src=5,ok=function(_this, s)
do return (s.runs >= 1) end;
end},{id="a_run10",name="老练舰长",desc="完成 10 次远征",src=10,ok=function(_this, s)
do return (s.runs >= 10) end;
end},{id="a_ch1",name="灰烬终结者",desc="通关第 1 章",src=15,ok=function(_this, s)
do return (not (not T(s.cleared[1]))) end;
end},{id="a_ch2",name="碎石征服者",desc="通关第 2 章",src=20,ok=function(_this, s)
do return (not (not T(s.cleared[2]))) end;
end},{id="a_ch3",name="赤环破局者",desc="通关第 3 章",src=30,ok=function(_this, s)
do return (not (not T(s.cleared[3]))) end;
end},{id="a_card10",name="卡牌新手",desc="收集 10 张技能卡牌",src=10,ok=function(_this, s)
do return (LEN(s.modules) >= 10) end;
end},{id="a_card30",name="卡牌收藏家",desc="收集 30 张技能卡牌",src=15,ok=function(_this, s)
do return (LEN(s.modules) >= 30) end;
end},{id="a_card100",name="卡牌大师",desc="收集 100 张技能卡牌",src=30,ok=function(_this, s)
do return (LEN(s.modules) >= 100) end;
end},{id="a_gold",name="金光闪闪",desc="获得 1 张金色卡牌",src=20,ok=function(_this, s)
do return s.modules:some(function(_this, m)
do return (m.tier == 3) end;
end) end;
end},{id="a_chip5",name="芯片工程师",desc="拥有 5 枚天赋芯片",src=10,ok=function(_this, s)
do return (LEN(s.chips) >= 5) end;
end},{id="a_lv10",name="机甲精进",desc="任意机甲升到 Lv10",src=15,ok=function(_this, s)
do return (G.Object:keys(s.mechs)):some(function(_this, k)
do return (s.mechs[k].lv >= 10) end;
end) end;
end},{id="a_kill1k",name="千杀",desc="累计击破 1000 个敌人",src=15,ok=function(_this, s)
do return (s.totalKills >= 1000) end;
end},{id="a_kill5k",name="万军之中",desc="累计击破 5000 个敌人",src=25,ok=function(_this, s)
do return (s.totalKills >= 5000) end;
end},{id="a_end10",name="无尽远征",desc="无尽模式到达第 10 波",src=20,ok=function(_this, s)
do return ((T(s.endlessBest) and s.endlessBest or 0) >= 10) end;
end},{id="a_dg5",name="险中求胜",desc="解锁危险等级 5",src=25,ok=function(_this, s)
do return ((T(s.dangerMax) and s.dangerMax or 1) >= 5) end;
end},{id="a_dc1",name="每日挑战者",desc="完成 1 次每日挑战",src=10,ok=function(_this, s)
do return ((T(s.dcBest) and s.dcBest or 0) > 0) end;
end},{id="a_boss3",name="首领猎手",desc="累计击败 3 个首领",src=20,ok=function(_this, s)
do return (s.bossKills >= 3) end;
end},length=17},AMT);
S.C.achClaim = function(_this, id)
local a, s;
a = (S.C.ACH:filter(function(_this, x)
do return (x.id == id) end;
end))[0]; s = S.C.save;
if (((not T(a)) or T(s.ach[id])) or (not T(a:ok(s)))) then
do return false end;
end;
s.ach[id] = 1;
s.src = (s.src + a.src);
S.C:write();
do return true end;
end;
S.C.achReady = function(_this)
local s;
s = S.C.save;
do return LEN((S.C.ACH:filter(function(_this, a)
do return (function() local _t = a:ok(s); if not T(_t) then return _t end; return (not T(s.ach[a.id])) end)() end;
end))) end;
end;
S.C.exportSave = function(_this)
local e;
do local _ok, _f, _v = pcall(function()
do return "R", HOST.btoa(nil,(HOST.unescape(nil,(HOST.encodeURIComponent(nil,(G.JSON:stringify(S.C.save))))))) end;
end)
if not _ok then e = _f
do return "" end;
elseif _f == "R" then do return _v end end end;
end;
S.C.importSave = function(_this, txt)
local o, e;
do local _ok, _f, _v = pcall(function()
o = G.JSON:parse((HOST.decodeURIComponent(nil,(HOST.escape(nil,(HOST.atob(nil,((G.String(nil,txt)):trim()))))))));
if (((not T(o)) or (typeof(o.credits) ~= "number")) or (not T(o.mechs))) then
do return "R", false end;
end;
HOST.localStorage:setItem(S.SAVE_KEY,(G.JSON:stringify(o)));
S.C:load();
do return "R", true end;
end)
if not _ok then e = _f
do return false end;
elseif _f == "R" then do return _v end end end;
end;
S.C.write = function(_this)
local e;
do local _ok, _f, _v = pcall(function()
HOST.localStorage:setItem(S.SAVE_KEY,(G.JSON:stringify(S.C.save)));
end)
if not _ok then e = _f
elseif _f == "R" then do return _v end end end;
end;
S.C.reset = function(_this)
local e;
do local _ok, _f, _v = pcall(function()
HOST.localStorage:removeItem(S.SAVE_KEY);
end)
if not _ok then e = _f
elseif _f == "R" then do return _v end end end;
S.C.save = S.C:newSave();
S.C:write();
end;
S.C.char = function(_this, id)
local i;
do
i = 0;
while (i < LEN(S.C.CHARS)) do
if (S.C.CHARS[i].id == id) then
do return S.C.CHARS[i] end;
end;
i = i + 1;
end
end;
do return nil end;
end;
S.C.talent = function(_this, id)
local i;
do
i = 0;
while (i < LEN(S.C.TALENTS)) do
if (S.C.TALENTS[i].id == id) then
do return S.C.TALENTS[i] end;
end;
i = i + 1;
end
end;
do return nil end;
end;
S.C.starMult = function(_this, id)
local c;
c = S.C.save.chars[id];
do return (function() if T(c) then return (1 + (0.15 * (c.star - 1))) else return 1 end end)() end;
end;
S.C.showAd = function(_this, reason, cb)
local ov, n, done, timer, finish;
finish = function(_this, ok, msg)
if T(done) then
do return end;
end;
done = true;
HOST.clearInterval(nil,timer);
ov:remove();
cb(nil,{success=ok,msg=msg});
end;
ov = HOST.document:createElement("div");
ov.className = "ad-sim";
ov.innerHTML = ((("<div class=\"ad-box\"><span class=\"tag\">模拟广告</span><h2>" .. S2(reason)) .. "</h2><p>正式版这里会播放激励视频，看完才发奖励。</p><b class=\"ad-count\">3</b>") .. "<div class=\"ad-btns\"><button class=\"btn\" data-a=\"close\">提前关闭</button></div></div>");
;(HOST.document:getElementById("app")):appendChild(ov);
n = 3; done = false; timer = HOST.setInterval(nil,function(_this)
n = n - 1;
;(ov:querySelector(".ad-count")).textContent = (function() if (n > 0) then return n else return "完成" end end)();
if (n <= 0) then
HOST.clearInterval(nil,timer);
finish(nil,true,"embed success");
end;
end,700);
;(ov:querySelector("[data-a=close]")).onclick = function(_this)
finish(nil,false,"embed manual close");
end;
end;
S.actx = nil; S.last = JS.dict(); S.GAP = JS.odict({shoot=0.09,pop=0.05,pick=0.06,hurt=0.15,boom=0.08,hit=0.07,crit=0.1},{"shoot","pop","pick","hurt","boom","hit","crit"}); S.bufs = JS.dict(); S.loading = false;
S.VOL = JS.odict({shoot=0.9,pop=1,boom=1,pick=1,hurt=1,level=1,skill=1,warp=1,gate=1,boss=1,win=1,click=1,dash=1,nitro=0.75,hit=0.8,crit=0.9},{"shoot","pop","boom","pick","hurt","level","skill","warp","gate","boss","win","click","dash","nitro","hit","crit"});
S.C.unlockAudio = function(_this)
local e;
if (not T(S.actx)) then
do local _ok, _f, _v = pcall(function()
S.actx = error("xpile: 不支持的 new @270");
end)
if not _ok then e = _f
S.actx = nil;
elseif _f == "R" then do return _v end end end;
end;
if (T(S.actx) and (S.actx.state == "suspended")) then
S.actx:resume();
end;
S.loadAudio(nil);
end;
S.C.sfx = function(_this, name)
local b, now, src, g;
if ((((not T(S.actx)) or (not T(S.C.save))) or (not T(S.C.save.settings.sound))) or (S.actx.state ~= "running")) then
do return end;
end;
b = S.bufs[("sfx_" .. S2(name))];
if (not T(b)) then
do return end;
end;
now = S.actx.currentTime;
if ((T(S.GAP[name]) and T(S.last[name])) and ((now - S.last[name]) < S.GAP[name])) then
do return end;
end;
S.last[name] = now;
src = S.actx:createBufferSource(); g = S.actx:createGain();
src.buffer = b;
g.gain.value = (T(S.VOL[name]) and S.VOL[name] or 1);
src:connect(g);
g:connect(S.actx.destination);
src:start();
end;
S.C.audioStat = function(_this)
do return {decoded=LEN((G.Object:keys(S.bufs))),state=(function() local _t = S.actx; if not T(_t) then return _t end; return S.actx.state end)()} end;
end;
S.mus = JS.odict({want=nil,src=nil,name=nil,gain=nil},{"want","src","name","gain"});
S.C.music = {play=function(_this, name)
local b, src;
S.mus.want = name;
if ((((not T(S.actx)) or (S.actx.state ~= "running")) or (not T(S.C.save))) or (not T(S.C.save.settings.music))) then
do return end;
end;
if ((S.mus.name == name) and T(S.mus.src)) then
do return end;
end;
b = S.bufs[("bgm_" .. S2(name))];
if (not T(b)) then
do return end;
end;
S.stopMusic(nil);
if (not T(S.mus.gain)) then
S.mus.gain = S.actx:createGain();
S.mus.gain.gain.value = 0.9;
S.mus.gain:connect(S.actx.destination);
end;
src = S.actx:createBufferSource();
src.buffer = b;
src.loop = true;
src:connect(S.mus.gain);
src:start();
S.mus.src = src;
S.mus.name = name;
end,stop=function(_this)
S.stopMusic(nil);
end,refresh=function(_this)
if ((T(S.C.save) and T(S.C.save.settings.music)) and T(S.mus.want)) then
S.stopMusic(nil);
S.C.music:play(S.mus.want);
else
S.stopMusic(nil);
end;
end};
S._unlock = S.C.unlockAudio;
S.C.unlockAudio = function(_this)
S._unlock(nil);
if (((T(S.actx) and (S.actx.state == "running")) and T(S.mus.want)) and (not T(S.mus.src))) then
S.C.music:play(S.mus.want);
end;
end;
S.C.CHIP_STATS = smt({[0]={k="atk",n="火力",p="烈焰",r=smt({[0]=3,8,length=2},AMT)},{k="hp",n="耐久",p="坚壁",r=smt({[0]=4,10,length=2},AMT)},{k="spd",n="机动",p="疾风",r=smt({[0]=2,5,length=2},AMT)},{k="crit",n="暴击率",p="鹰眼",r=smt({[0]=2,5,length=2},AMT)},{k="critDmg",n="暴击伤害",p="破甲",r=smt({[0]=8,20,length=2},AMT)},{k="cdr",n="冷却缩减",p="超频",r=smt({[0]=2,5,length=2},AMT)},{k="skill",n="模块伤害",p="共振",r=smt({[0]=4,10,length=2},AMT)},{k="active",n="机甲技能伤害",p="核心",r=smt({[0]=5,12,length=2},AMT)},{k="pickup",n="拾取范围",p="引力",r=smt({[0]=6,15,length=2},AMT)},{k="credit",n="信用点收益",p="财富",r=smt({[0]=4,10,length=2},AMT)},{k="armor",n="受伤减免",p="护盾",r=smt({[0]=2,4,length=2},AMT)},{k="regen",n="每秒修复",p="纳米",r=smt({[0]=0.2,0.6,length=2},AMT),abs=true},{k="elite",n="精英与首领伤害",p="猎手",r=smt({[0]=5,12,length=2},AMT)},{k="summon",n="炮台伤害",p="工匠",r=smt({[0]=6,15,length=2},AMT)},{k="blast",n="爆炸范围",p="爆裂",r=smt({[0]=5,12,length=2},AMT)},{k="xp",n="能量获取",p="启迪",r=smt({[0]=4,10,length=2},AMT)},{k="rate",n="主武器射速",p="狂热",r=smt({[0]=3,8,length=2},AMT)},{k="nitro",n="氮气冷却缩减",p="喷流",r=smt({[0]=4,10,length=2},AMT)},{k="nitroDist",n="氮气距离",p="推进",r=smt({[0]=6,16,length=2},AMT)},{k="luck",n="补给掉落率",p="幸运",r=smt({[0]=0.5,1.5,length=2},AMT)},{k="sup",n="驾驶员支援伤害",p="默契",r=smt({[0]=6,14,length=2},AMT)},length=21},AMT);
S.C.CHIP_SERIES = smt({[0]={n="先锋",b=smt({[0]="atk","crit","critDmg","rate","spd","elite","nitroDist",length=7},AMT)},{n="守护",b=smt({[0]="hp","armor","regen","cdr","sup","luck","nitro",length=7},AMT)},{n="猎手",b=smt({[0]="crit","critDmg","elite","atk","pickup","xp","rate",length=7},AMT)},{n="工匠",b=smt({[0]="summon","skill","blast","cdr","sup","credit","active",length=7},AMT)},{n="星语",b=smt({[0]="skill","active","cdr","xp","blast","pickup","luck",length=7},AMT)},{n="暗影",b=smt({[0]="crit","critDmg","spd","nitro","nitroDist","atk","elite",length=7},AMT)},{n="曙光",b=smt({[0]="hp","regen","armor","sup","xp","credit","luck",length=7},AMT)},{n="赤焰",b=smt({[0]="atk","rate","blast","active","skill","summon","critDmg",length=7},AMT)},length=8},AMT);
S.C.RARITY = smt({[0]={n="白色·普通",affixes=1,mult=1,color="#E6EAF5",w=60},{n="蓝色·稀有",affixes=2,mult=1.3,color="#57B8FF",w=28},{n="紫色·史诗",affixes=3,mult=1.6,color="#B47CFF",w=10},{n="金色·传说",affixes=3,mult=2.0,color="#F5A524",w=2},length=4},AMT);
S.C.TRAITS = smt({[0]={k="headstart",n="开局强化",d="每局开局免费升级 1 次"},{k="revive",n="星魂庇护",d="每局自动复活 1 次（40% 耐久）"},{k="berserk",n="背水一战",d="耐久低于 30% 时伤害 +30%"},{k="overclock",n="超频核心",d="技能模块冷却 -15%"},length=4},AMT);
S.C.CHIP_COST = function(_this, n)
do return Math_min(2000,(300 + (n * 40))) end;
end;
S.C.MOD_COST = function(_this, n)
do return Math_min(2500,(400 + (n * 60))) end;
end;
S.C.modLvMult = function(_this, m)
do return (1 + (0.12 * ((T(m.lvl) and m.lvl or 1) - 1))) end;
end;
S.C.modOwned = function(_this, form, elem, tier, v)
do return (function() local _t = (S.C.save.modules:filter(function(_this, x)
do return ((((x.form == form) and (x.elem == elem)) and (x.tier == tier)) and ((v == nil) or ((T(x.v) and x.v or 0) == v))) end;
end))[0]; if T(_t) then return _t end; return nil end)() end;
end;
S.C.modBest = function(_this, form, elem)
local b;
b = nil;
S.C.save.modules:forEach(function(_this, x)
if (((x.form == form) and (x.elem == elem)) and ((not T(b)) or (x.tier > b.tier))) then
b = x;
end;
end);
do return b end;
end;
S.C.REFUND = smt({[0]=80,180,400,900,length=4},AMT);
S.C.INV_MAX = 40;
S.C.chipSlots = function(_this)
do return Math_min(6,(3 + LEN((G.Object:keys(S.C.save.cleared))))) end;
end;
S.uid = function(_this)
do return ((G.Date:now()):toString(36) .. (Math_floor((Math_random() * 1e6))):toString(36)) end;
end;
S.C.makeChip = function(_this, tier)
local R, pool, aff, ser, i, pl, st, v, main, chip;
R = S.C.RARITY[tier]; pool = S.C.CHIP_STATS:slice(); aff = smt({length=0},AMT); ser = S.C.CHIP_SERIES[Math_floor((Math_random() * LEN(S.C.CHIP_SERIES)))];
do
i = 0;
while (i < R.affixes) do
pl = (function() if (i == 0) then return pool:filter(function(_this, x)
do return (ser.b:indexOf(x.k) >= 0) end;
end) else return pool end end)(); st = pl[Math_floor((Math_random() * LEN(pl)))];
pool:splice(pool:indexOf(st),1);
v = (S.rnd(nil,st.r[0],st.r[1]) * R.mult);
aff:push({k=st.k,v=(function() if T(st.abs) then return (Math_round((v * 10)) / 10) else return Math_round(v) end end)()});
i = i + 1;
end
end;
main = (S.C.CHIP_STATS:filter(function(_this, x)
do return (x.k == aff[0].k) end;
end))[0];
chip = {id=S.uid(nil),tier=tier,lvl=1,series=ser.n,name=(((S2(ser.n) .. "·") .. S2(main.p)) .. "芯片"),aff=aff};
if (tier == 3) then
chip.trait = S.C.TRAITS[Math_floor((Math_random() * LEN(S.C.TRAITS)))].k;
end;
do return chip end;
end;
S.C.buyChip = function(_this)
local s, cost, c;
s = S.C.save; cost = S.C:CHIP_COST((T(s.chipBuys) and s.chipBuys or 0));
if (LEN(s.chips) >= S.C.INV_MAX) then
do return {err=(("芯片仓库已满（" .. S2(S.C.INV_MAX)) .. "），先分解一些")} end;
end;
if (s.credits < cost) then
do return {err="信用点不足"} end;
end;
s.credits = (s.credits - cost);
s.chipBuys = ((T(s.chipBuys) and s.chipBuys or 0) + 1);
c = S.C:makeChip((S.rollRarity(nil,"chipPity")));
s.chips:push(c);
do return {chip=c} end;
end;
S.C.chipLvMult = function(_this, c)
do return (1 + (0.12 * ((T(c.lvl) and c.lvl or 1) - 1))) end;
end;
S.C.affText = function(_this, a, c)
local st, v;
st = (S.C.CHIP_STATS:filter(function(_this, x)
do return (x.k == a.k) end;
end))[0]; v = (function() if T(c) then return (Math_round(((a.v * S.C:chipLvMult(c)) * 10)) / 10) else return a.v end end)();
do return (((S2(st.n) .. " +") .. S2(v)) .. (T(st.abs) and "" or "%")) end;
end;
S.C.trait = function(_this, k)
do return (S.C.TRAITS:filter(function(_this, x)
do return (x.k == k) end;
end))[0] end;
end;
S.C.chipStats = function(_this)
local out;
out = {traits=JS.dict()};
S.C.CHIP_STATS:forEach(function(_this, x)
out[x.k] = 0;
end);
;((T(S.C.save.chipEq) and S.C.save.chipEq or smt({length=0},AMT))):forEach(function(_this, id)
local c, lm;
c = (S.C.save.chips:filter(function(_this, x)
do return (x.id == id) end;
end))[0];
if (not T(c)) then
do return end;
end;
lm = S.C:chipLvMult(c);
c.aff:forEach(function(_this, a)
local st;
st = (S.C.CHIP_STATS:filter(function(_this, x)
do return (x.k == a.k) end;
end))[0];
out[a.k] = (out[a.k] + ((function() if T(st.abs) then return a.v else return (a.v / 100) end end)() * lm));
end);
if T(c.trait) then
out.traits[c.trait] = true;
end;
end);
out.armor = Math_min(0.5,out.armor);
out.cdr = Math_min(0.4,out.cdr);
do return out end;
end;
S.C.MOD_FORMS = smt({[0]={k="homing",n="追踪飞弹",cd=2.2,dmg=16,count=2,d="发射追踪飞弹"},{k="orbit",n="环绕刃",cd=0,dmg=9,count=2,d="光刃持续环绕机甲切割敌人"},{k="nova",n="冲击波",cd=3.2,dmg=26,count=1,d="以机甲为中心释放冲击波并击退"},{k="strike",n="落雷",cd=2.6,dmg=34,count=2,d="轰击附近的敌人，小范围伤害"},{k="beam",n="激光束",cd=3.0,dmg=45,count=1,d="向最强的敌人射出贯穿光束"},{k="fan",n="弹幕扇射",cd=1.6,dmg=9,count=5,d="向最近的敌人扇形射出光弹"},{k="mine",n="感应地雷",cd=2.4,dmg=40,count=1,d="在脚下布雷，敌人靠近即爆炸"},{k="boomerang",n="回旋镖",cd=2.0,dmg=22,count=1,d="飞出再飞回，沿途穿透所有敌人"},{k="swarm",b="homing",n="蜂群导弹",cd=2.6,dmg=8,count=5,d="一次放出大量小型追踪导弹"},{k="heavy",b="homing",n="重型导弹",cd=3.4,dmg=48,count=1,d="发射一枚高伤害的重型追踪导弹"},{k="twinblade",b="orbit",n="双生环刃",cd=0,dmg=6,count=4,d="四把小光刃快速环绕机甲"},{k="bigblade",b="orbit",n="巨刃",cd=0,dmg=16,count=1,d="一把巨大的光刃环绕机甲，伤害极高"},{k="pulse",b="nova",n="脉冲震荡",cd=1.8,dmg=15,count=1,d="高频释放小型冲击波"},{k="annihilate",b="nova",n="湮灭冲击",cd=5,dmg=50,count=1,d="蓄力后释放强力冲击波"},{k="storm",b="strike",n="雷暴",cd=3.2,dmg=22,count=4,d="同时轰击多个敌人"},{k="twinbeam",b="beam",n="双联光束",cd=3.0,dmg=28,count=2,d="同时射出两道贯穿光束"},{k="cannon",b="beam",n="轨道重炮",cd=4.5,dmg=90,count=1,d="蓄能射出一道极高伤害的贯穿光束"},{k="tempest",b="fan",n="散弹风暴",cd=1.8,dmg=6,count=9,d="向前方射出大量光弹"},{k="cluster",b="mine",n="集束地雷",cd=3,dmg=26,count=3,d="一次布下 3 枚地雷"},{k="twinrang",b="boomerang",n="回旋双刃",cd=2.0,dmg=16,count=2,d="同时掷出两把回旋镖"},length=20},AMT);
S.C.ELEMENTS = smt({[0]={k="fire",n="烈焰",hue=smt({[0]=8,32,length=2},AMT),d="灼烧：2 秒内追加 30% 伤害"},{k="ice",n="寒霜",hue=smt({[0]=188,212,length=2},AMT),d="冰冻：命中减速 2 秒"},{k="thunder",n="雷霆",hue=smt({[0]=46,58,length=2},AMT),d="雷击：额外跳到 1 个附近敌人"},{k="light",n="圣光",hue=smt({[0]=160,178,length=2},AMT),d="圣光：暴击率 +15%"},{k="dark",n="暗影",hue=smt({[0]=270,300,length=2},AMT),d="暗影：伤害 +15%"},{k="poison",n="剧毒",hue=smt({[0]=92,128,length=2},AMT),d="中毒：3 秒内追加 40% 伤害"},length=6},AMT);
S.C.MOD_TAGS = smt({[0]={k="split",n="分裂",d="命中时分裂出 2 枚小弹"},{k="pierce",n="穿透",d="弹体穿透 +2"},{k="chain",n="连锁",d="命中后连锁 2 个敌人"},{k="slow",n="迟缓",d="命中减速"},{k="knock",n="震荡",d="强力击退"},{k="leech",n="吸能",d="伤害的 2% 修复耐久"},{k="crit",n="致命",d="暴击率 +20%"},{k="big",n="扩张",d="范围与体积 +40%"},length=8},AMT);
S.C.MOD_RARITY_MULT = smt({[0]=1,1.25,1.5,1.9,length=4},AMT);
S.C.GOLD_FX = {homing={tag="split",d="导弹命中后分裂出 2 枚小弹，清群更快"},orbit={tag="knock",d="环绕刃附带强力击退，把敌群推开"},nova={tag="slow",d="冲击波命中的敌人被冻结减速"},strike={tag="chain",d="落雷会连锁跳向 2 个附近敌人"},beam={tag="big",d="光束变粗 40%，更容易扫到敌群"},fan={tag="pierce",d="光弹额外穿透 2 个敌人"},mine={tag="big",d="地雷爆炸范围 +40%"},boomerang={tag="chain",d="回旋镖命中后连锁 2 个敌人"}};
S.C.EVO_PASS_LV = 2;
S.C.REACT_HINT = {fire="火 + 毒 = 爆燃（范围爆炸）；火 + 冰冻 = 融蚀",ice="冰冻的敌人被雷击 = 碎冰（范围伤害）",thunder="雷 + 冰冻 = 碎冰；雷 + 毒 = 麻痹（定身）",poison="毒 + 火 = 爆燃；毒 + 雷 = 麻痹",light="光 + 暗 = 湮灭（暴击）",dark="暗 + 光 = 湮灭（暴击）"};
S.C.EVO = {homing={pass="power",n="集束",d="导弹 +2 枚，命中后分裂出小弹",tags=smt({[0]="split",length=1},AMT),count=2},orbit={pass="hull",n="风暴",d="环绕刃 +2 把，半径更大并强力击退",tags=smt({[0]="knock",length=1},AMT),count=2,size=1.3},nova={pass="cooling",n="极寒",d="冲击波范围 +40%，范围内敌人被冻结",tags=smt({[0]="slow","big",length=2},AMT),count=1},strike={pass="engine",n="天罚",d="落雷 +2 道，并连锁 2 个敌人",tags=smt({[0]="chain",length=1},AMT),count=2},beam={pass="power",n="贯日",d="光束 +1 条，更粗并额外穿透",tags=smt({[0]="big","pierce",length=2},AMT),count=1},fan={pass="cooling",n="弹幕",d="弹幕 +2 发，额外穿透 2 个敌人",tags=smt({[0]="pierce",length=1},AMT),count=2},mine={pass="magnet",n="连锁",d="地雷 +2 枚，爆炸范围 +40%",tags=smt({[0]="big",length=1},AMT),count=2},boomerang={pass="engine",n="回响",d="回旋镖 +1 把，命中后连锁 2 个敌人",tags=smt({[0]="chain",length=1},AMT),count=1}};
S.C.evoOf = function(_this, m)
local F;
F = S.C:modForm(m.form);
do return S.C.EVO[(function() local _t = (function() local _t = F; if not T(_t) then return _t end; return F.b end)(); if T(_t) then return _t end; return m.form end)()] end;
end;
S.C.goldTag = function(_this, m)
local F;
if ((not T(m)) or (m.tier ~= 3)) then
do return nil end;
end;
F = S.C:modForm(m.form);
do return (function() local _t = S.C.GOLD_FX[(function() local _t = (function() local _t = F; if not T(_t) then return _t end; return F.b end)(); if T(_t) then return _t end; return m.form end)()]; if T(_t) then return _t end; return nil end)() end;
end;
S.C.VARIANTS = smt({[0]=1,3,3,2,length=4},AMT);
S.C.MOD_TOTAL = function(_this)
do return ((LEN(S.C.MOD_FORMS) * LEN(S.C.ELEMENTS)) * 9) end;
end;
S.C.modDex = function(_this)
local seen, n;
seen = JS.dict(); n = 0;
;((T(S.C.save.modules) and S.C.save.modules or smt({length=0},AMT))):forEach(function(_this, m)
local k;
k = ((S2(m.form) .. "|") .. S2(m.elem));
if (not T(seen[k])) then
seen[k] = true;
n = n + 1;
end;
end);
do return {got=n,total=(LEN(S.C.MOD_FORMS) * LEN(S.C.ELEMENTS))} end;
end;
S.C.makeModule = function(_this, tier, form, elem, v)
local F, El, pr, pool, k, j, tmp, n, tags, tn, tg, rg, color;
F = (function() if T(form) then return (S.C.MOD_FORMS:filter(function(_this, x)
do return (x.k == form) end;
end))[0] else return S.C.MOD_FORMS[Math_floor((Math_random() * LEN(S.C.MOD_FORMS)))] end end)();
El = (function() if T(elem) then return (S.C.ELEMENTS:filter(function(_this, x)
do return (x.k == elem) end;
end))[0] else return S.C.ELEMENTS[Math_floor((Math_random() * LEN(S.C.ELEMENTS)))] end end)();
v = (function() if (v == nil) then return Math_floor((Math_random() * S.C.VARIANTS[tier])) else return v end end)();
pr = S.seeded(nil,((S2((F.k + El.k)) .. "p") .. S2(tier))); pool = S.C.MOD_TAGS:slice();
do
k = (LEN(pool) - 1);
while (k > 0) do
j = Math_floor((pr(nil) * (k + 1)));
tmp = pool[k];
pool[k] = pool[j];
pool[j] = tmp;
k = k - 1;
end
end;
n = (smt({[0]=0,1,2,2,length=4},AMT))[tier]; tags = smt({length=0},AMT); tn = smt({length=0},AMT);
do
k = 0;
while (k < n) do
tg = pool[MOD(((v * n) + k),LEN(pool))];
tags:push(tg.k);
tn:push(tg.n);
k = k + 1;
end
end;
rg = S.seeded(nil,((S2(((F.k + El.k) + tier)) .. "v") .. S2(v))); color = S.hsl2hex(nil,(El.hue[0] + (rg(nil) * (El.hue[1] - El.hue[0]))),(72 + (rg(nil) * 20)),(56 + (rg(nil) * 10)));
do return {id=((((((S2(F.k) .. ":") .. S2(El.k)) .. ":") .. S2(tier)) .. ":") .. S2(v)),tier=tier,v=v,lvl=1,form=F.k,elem=El.k,tags=tags,color=color,name=(S2((El.n + F.n)) .. (function() if T(LEN(tn)) then return ("·" .. tn:join("")) else return "" end end)())} end;
end;
S.C.modDeck = function(_this)
local best;
best = JS.dict();
S.C.save.modules:forEach(function(_this, x)
local k, b;
k = ((S2(x.form) .. ":") .. S2(x.elem)); b = best[k];
if (((not T(b)) or (x.tier > b.tier)) or ((x.tier == b.tier) and ((T(x.lvl) and x.lvl or 1) > (T(b.lvl) and b.lvl or 1)))) then
best[k] = x;
end;
end);
do return (G.Object:keys(best)):map(function(_this, k)
do return best[k] end;
end) end;
end;
S.C.topMods = function(_this, n)
do return ((S.C:modDeck()):sort(function(_this, a, b)
do return (((b.tier + 1) * S.C:modLvMult(b)) - ((a.tier + 1) * S.C:modLvMult(a))) end;
end)):slice(0,n) end;
end;
S.C.MOD_TEN = function(_this, n)
local c, i;
c = 0;
do
i = 0;
while (i < 10) do
c = (c + S.C:MOD_COST((n + i)));
i = i + 1;
end
end;
do return (Math_round(((c * 0.9) / 10)) * 10) end;
end;
S.C.drawModules = function(_this, cnt, free)
local s, cost, out, i, m, own;
s = S.C.save; cost = (function() if (cnt == 10) then return S.C:MOD_TEN((T(s.modBuys) and s.modBuys or 0)) else return S.C:MOD_COST((T(s.modBuys) and s.modBuys or 0)) end end)(); out = smt({length=0},AMT);
if ((not T(free)) and (s.credits < cost)) then
do return {err=(("信用点不足（需要 " .. cost:toLocaleString("zh-CN")) .. "）")} end;
end;
if (not T(free)) then
s.credits = (s.credits - cost);
end;
do
i = 0;
while (i < cnt) do
s.credits = (s.credits + S.C:MOD_COST((T(s.modBuys) and s.modBuys or 0)));
out:push((S.C:buyModule()));
i = i + 1;
end
end;
if ((cnt == 10) and (not out:some(function(_this, r)
do return (T(r.mod) and (r.mod.tier >= 1)) end;
end))) then
m = S.C:makeModule(1); own = (s.modules:filter(function(_this, x)
do return (x.id == m.id) end;
end))[0];
if (not T(own)) then
s.modules:push(m);
out[9] = {mod=m,isNew=true};
else
if ((T(own.lvl) and own.lvl or 1) < S.C.LV_MAX) then
own.lvl = ((T(own.lvl) and own.lvl or 1) + 1);
end;
out[9] = {mod=own,dup=true};
end;
end;
S.C:write();
do return {list=out,cost=(T(free) and 0 or cost)} end;
end;
S.C.buyModule = function(_this)
local s, cost, m, own;
s = S.C.save; cost = S.C:MOD_COST((T(s.modBuys) and s.modBuys or 0));
if (s.credits < cost) then
do return {err="信用点不足"} end;
end;
s.credits = (s.credits - cost);
s.modBuys = ((T(s.modBuys) and s.modBuys or 0) + 1);
m = S.C:makeModule((S.rollRarity(nil,"modPity"))); own = (s.modules:filter(function(_this, x)
do return (x.id == m.id) end;
end))[0];
if (not T(own)) then
s.modules:push(m);
do return {mod=m,isNew=true} end;
end;
if ((T(own.lvl) and own.lvl or 1) < S.C.LV_MAX) then
own.lvl = ((T(own.lvl) and own.lvl or 1) + 1);
else
s.credits = (s.credits + S.C.REFUND[own.tier]);
do return {mod=own,dup=true,refund=S.C.REFUND[own.tier]} end;
end;
do return {mod=own,dup=true} end;
end;
S.C.adUpLeft = function(_this)
do return Math_max(0,(S.C.AD.upDaily - (T(S.C.save.daily.adUp) and S.C.save.daily.adUp or 0))) end;
end;
S.C.adUpgrade = function(_this, it)
if ((not T(it)) or ((T(it.lvl) and it.lvl or 1) >= S.C.LV_MAX)) then
do return {err="已满级"} end;
end;
if (S.C:adUpLeft() <= 0) then
do return {err="今日广告升级次数已用完"} end;
end;
it.lvl = ((T(it.lvl) and it.lvl or 1) + 1);
S.C.save.daily.adUp = ((T(S.C.save.daily.adUp) and S.C.save.daily.adUp or 0) + 1);
S.C:write();
do return {ok=true} end;
end;
S.C.modForm = function(_this, k)
do return (S.C.MOD_FORMS:filter(function(_this, x)
do return (x.k == k) end;
end))[0] end;
end;
S.C.modElem = function(_this, k)
do return (S.C.ELEMENTS:filter(function(_this, x)
do return (x.k == k) end;
end))[0] end;
end;
S.C.modTag = function(_this, k)
do return (S.C.MOD_TAGS:filter(function(_this, x)
do return (x.k == k) end;
end))[0] end;
end;
S.C.modDesc = function(_this, m)
local F, mult;
F = S.C:modForm(m.form); mult = S.C.MOD_RARITY_MULT[m.tier];
do return ((((S2(F.d) .. "，伤害 ") .. S2(Math_round(((F.dmg * mult) * S.C:modLvMult(m))))) .. (function() if T(F.cd) then return (("，冷却 " .. S2(F.cd)) .. " 秒") else return "，持续存在" end end)()) .. (function() if ((F.count > 1) or (m.tier == 3)) then return ("，数量 " .. S2((F.count + ((m.tier == 3) and 1 or 0)))) else return "" end end)()) end;
end;
S.C.WFAM = smt({[0]={k="laser",n="射线枪",mech="mech_azure",d="高速射线，穿透敌人"},{k="shotgun",n="散射炮",mech="mech_blaze",d="中近距离集束散射，强击退"},{k="heal",n="追踪光弹",mech="mech_halo",d="自动追踪的光弹，命中修复耐久"},{k="twin",n="双臂机炮",mech="mech_forge",d="两门机炮交替射击，射速快"},{k="lob",n="肩载导弹",mech="mech_frost",d="追踪导弹，命中范围爆炸"},{k="prism",n="晶体长枪",mech="mech_starfall",d="扇形晶体光弹，穿透"},length=6},AMT);
S.C.WEAPONS = smt({[0]={id="laser_0",fam="laser",m=0,n="星轨射线枪",d="双发点射，每击穿透 2 个敌人",cost=0,src=0},{id="laser_1",fam="laser",m=1,n="疾光速射枪",d="射速 +60%，单发伤害 -38%，穿透 1",rate=1.6,dmg=0.62,pierce=(-1),cost=1200,src=0},{id="laser_2",fam="laser",m=2,n="裂星光矛",d="单发重击：伤害 x2.3、穿透 5，射速 -25%",single=true,dmg=2.3,pierce=3,rate=0.75,size=1.6,cost=2400,src=15},{id="shotgun_0",fam="shotgun",m=0,n="三管散射炮",d="三根炮管依次点火，强击退",cost=0,src=0},{id="shotgun_1",fam="shotgun",m=1,n="龙息喷火炮",d="射程缩短，弹丸点燃敌人（持续灼烧），射速 +25%",burn=0.2,range=24,dmg=0.8,rate=1.25,tint=smt({[0]=1.6,0.6,0.15,length=3},AMT),cost=1200,src=0},{id="shotgun_2",fam="shotgun",m=2,n="震荡霰弹炮",d="弹丸减半、伤害 x1.5，命中小范围爆炸，击退更强",count=0.5,dmg=1.5,blastR=2.2,kb=2.5,cost=2400,src=15},{id="heal_0",fam="heal",m=0,n="追踪光弹",d="命中修复 0.5 耐久",cost=0,src=0},{id="heal_1",fam="heal",m=1,n="星愈光弹",d="命中修复 x2.4，伤害 -20%",heal=2.4,dmg=0.8,cost=1200,src=0},{id="heal_2",fam="heal",m=2,n="流星光弹",d="光弹 +1，命中范围溅射，不再修复耐久",extra=1,splash=2.6,heal=0,cost=2400,src=15},{id="twin_0",fam="twin",m=0,n="双臂机炮",d="两门机炮交替射击，穿透 2",cost=0,src=0},{id="twin_1",fam="twin",m=1,n="加特林机炮",d="射速 x1.8，伤害 -40%，弹道略散",rate=1.8,dmg=0.6,jitter=0.08,cost=1200,src=0},{id="twin_2",fam="twin",m=2,n="爆裂机炮",d="射速 -25%，子弹命中爆炸",rate=0.75,dmg=1.1,blastR=2.4,cost=2400,src=15},{id="lob_0",fam="lob",m=0,n="肩载导弹",d="追踪导弹，命中范围爆炸",cost=0,src=0},{id="lob_1",fam="lob",m=1,n="蜂巢导弹",d="每轮多发 2 枚小导弹，单发伤害 -45%",extra=2,dmg=0.55,size=0.7,cost=1200,src=0},{id="lob_2",fam="lob",m=2,n="冰霜导弹",d="爆炸范围 +30%，命中区域减速 2 秒（可触发碎冰）",splash=1.3,dmg=0.9,slow=2,tint=smt({[0]=0.6,0.9,1.5,length=3},AMT),cost=2400,src=15},{id="prism_0",fam="prism",m=0,n="星核长枪",d="三向晶体光弹，穿透 2",cost=0,src=0},{id="prism_1",fam="prism",m=1,n="五向晶簇枪",d="晶体光弹 +2，扇面更宽，单发伤害 -28%",extra=2,spread=1.6,dmg=0.72,cost=1200,src=0},{id="prism_2",fam="prism",m=2,n="暴晶长枪",d="单发：伤害 x2.4，暴击率 +30%，穿透 4",single=true,dmg=2.4,crit=0.3,pierce=2,size=1.5,cost=2400,src=15},length=18},AMT);
S.C.SUBS = smt({[0]={id="swarm",n="蜂群飞弹",d="一次放出 8 枚追踪小飞弹，命中小范围爆炸",cd=4,n0=8,dmg=16,r=2.6,craft=120,unlock=0,src=0,color="#FF8A3A"},{id="cryo",n="冰霜飞弹",d="4 枚追踪飞弹，爆炸冻结范围内敌人 3 秒（可触发碎冰 / 融蚀反应）",cd=5,n0=4,dmg=26,r=5,craft=160,unlock=800,src=0,el="ice",color="#9DD8FF"},{id="emp",n="电磁飞弹",d="3 枚飞弹，命中后闪电连锁 4 个敌人并短暂麻痹（可触发碎冰 / 麻痹反应）",cd=5,n0=3,dmg=34,chain=4,craft=200,unlock=1000,src=0,el="thunder",color="#F5E050"},{id="cluster",n="集束炸弹",d="落向敌人最密集处，炸开 6 枚子弹并点燃敌人",cd=6,n0=6,dmg=30,r=3.6,main=50,craft=220,unlock=1200,src=0,el="fire",color="#F5A524"},{id="heavy",n="穿甲重弹",d="优先锁定首领 / 精英 / 血量最高的敌人，大范围爆炸；对精英与首领伤害 +50%",cd=7,n0=1,dmg=240,r=6,craft=260,unlock=1500,src=0,color="#E0458C"},{id="gravity",n="引力飞弹",d="在敌群中制造黑洞牵引敌人 2.5 秒，随后坍缩爆炸",cd=8,n0=1,dmg=120,r=11,craft=300,unlock=2000,src=10,el="dark",color="#B47CFF"},length=6},AMT);
S.C.NITROS = smt({[0]={id="n_dash",n="氮气冲刺",mech="mech_azure",d="快速冲刺，冲刺中无敌",dist=16,dur=0.2,inv=0.26,cd=2.4},{id="n_ram",n="氮气冲撞",mech="mech_blaze",d="撞飞沿途敌人并造成伤害",dist=20,dur=0.28,inv=0.3,cd=3.0,ram=60},{id="n_drift",n="氮气漂移",mech="mech_halo",d="漂移时修复 4% 耐久",dist=15,dur=0.24,inv=0.3,cd=2.4,heal=0.04},{id="n_boost",n="氮气加速",mech="mech_forge",d="长距离加速，无敌时间更长",dist=34,dur=0.9,inv=0.35,cd=3.4},{id="n_retreat",n="氮气后撤",mech="mech_frost",d="向后撤离目标，原地留下减速力场",dist=17,dur=0.22,inv=0.3,cd=2.6,retreat=true},{id="n_warp",n="氮气跃迁",mech="mech_starfall",d="远距离跃迁",dist=24,dur=0.3,inv=0.36,cd=3.0},length=6},AMT);
S.C.MECH_TRAIT = {mech_azure={n="全能适配",d="主武器与副武器伤害 +10%",main=0.1,sub=0.1},mech_blaze={n="近战压制",d="15 米内主武器伤害 +25%，氮气冲撞伤害 x1.5",close=0.25,ram=1.5},mech_halo={n="星愈回路",d="副武器每次命中修复 1 耐久，主武器修复效果 +50%",subHeal=1,heal=0.5},mech_forge={n="弹药工程",d="副武器携带上限 +10，副武器冷却 -20%",cap=10,subCd=0.2},mech_frost={n="火力覆盖",d="副武器伤害 +30%，爆炸范围 +20%",sub=0.3,blast=0.2},mech_starfall={n="星核共振",d="主武器暴击率 +12%，副武器冷却 -10%",crit=0.12,subCd=0.1}};
S.C.ARM_LV_MAX = 5;
S.C.SUB_STOCK_MAX = 99;
S.C.SUB_CARRY = 20;
S.C.SUB_BATCH = 5;
S.C.NATIVE_BONUS = 0.1;
S.C.weapon = function(_this, id)
do return (function() local _t = (S.C.WEAPONS:filter(function(_this, w)
do return (w.id == id) end;
end))[0]; if T(_t) then return _t end; return S.C.WEAPONS[0] end)() end;
end;
S.C.subDef = function(_this, id)
do return (function() local _t = (S.C.SUBS:filter(function(_this, w)
do return (w.id == id) end;
end))[0]; if T(_t) then return _t end; return nil end)() end;
end;
S.C.nitroDef = function(_this, id)
do return (function() local _t = (S.C.NITROS:filter(function(_this, w)
do return (w.id == id) end;
end))[0]; if T(_t) then return _t end; return S.C.NITROS[0] end)() end;
end;
S.C.wfam = function(_this, k)
do return (S.C.WFAM:filter(function(_this, f)
do return (f.k == k) end;
end))[0] end;
end;
S.C.nativeWeapon = function(_this, mechId)
do return (S2(((S.C:mech(mechId)).weapon).type) .. "_0") end;
end;
S.C.nativeNitro = function(_this, mechId)
local n;
n = (S.C.NITROS:filter(function(_this, x)
do return (x.mech == mechId) end;
end))[0];
do return (function() if T(n) then return n.id else return "n_dash" end end)() end;
end;
S.C.wLvMult = function(_this, lv)
do return (1 + (0.12 * ((T(lv) and lv or 1) - 1))) end;
end;
S.C.armory = function(_this)
local s, a;
s = S.C.save; a = s.arms;
if (not T(a)) then
s.arms = {weapons=JS.dict(),subs={swarm={lv=1,stock=20}},nitros=JS.dict(),loadout=JS.dict()};
a = s.arms;
S.C.WEAPONS:forEach(function(_this, w)
if (w.m == 0) then
a.weapons[w.id] = {lv=1};
end;
end);
S.C.NITROS:forEach(function(_this, n)
a.nitros[n.id] = {lv=1};
end);
end;
a.weapons = (T(a.weapons) and a.weapons or JS.dict());
a.subs = (T(a.subs) and a.subs or JS.dict());
a.nitros = (T(a.nitros) and a.nitros or JS.dict());
a.loadout = (T(a.loadout) and a.loadout or JS.dict());
do return a end;
end;
S.C.armLv = function(_this, kind, id)
local it;
it = ((S.C:armory())[kind])[id];
do return (function() if T(it) then return (T(it.lv) and it.lv or 1) else return 0 end end)() end;
end;
S.C.loadout = function(_this, mechId)
local a, lo;
a = S.C:armory(); lo = a.loadout[mechId];
if (not T(lo)) then
a.loadout[mechId] = {main=S.C:nativeWeapon(mechId),sub="swarm",nitro=S.C:nativeNitro(mechId)};
lo = a.loadout[mechId];
end;
if (not T(a.weapons[lo.main])) then
lo.main = S.C:nativeWeapon(mechId);
end;
if (T(lo.sub) and (not T(a.subs[lo.sub]))) then
lo.sub = (T(a.subs.swarm) and "swarm" or nil);
end;
if (not T(a.nitros[lo.nitro])) then
lo.nitro = S.C:nativeNitro(mechId);
end;
do return lo end;
end;
S.C.equipArm = function(_this, mechId, slot, id)
local lo, kind;
lo = S.C:loadout(mechId); kind = ((slot == "main") and "weapons" or ((slot == "sub") and "subs" or "nitros"));
if (T(id) and (not T(((S.C:armory())[kind])[id]))) then
do return {err="还没有研发这件装备"} end;
end;
lo[slot] = id;
S.C:write();
do return {ok=true} end;
end;
S.C.subCap = function(_this, mechId)
local t;
t = (T(S.C.MECH_TRAIT[mechId]) and S.C.MECH_TRAIT[mechId] or JS.dict());
do return (S.C.SUB_CARRY + (T(t.cap) and t.cap or 0)) end;
end;
S.C.armCost = function(_this, kind, id)
local w, d;
if (kind == "weapons") then
w = S.C:weapon(id);
do return {cr=w.cost,src=(T(w.src) and w.src or 0)} end;
end;
if (kind == "subs") then
d = S.C:subDef(id);
do return {cr=d.unlock,src=(T(d.src) and d.src or 0)} end;
end;
do return {cr=600,src=0} end;
end;
S.C.armUnlock = function(_this, kind, id)
local a, s, c;
a = S.C:armory(); s = S.C.save; c = S.C:armCost(kind,id);
if T(a[kind][id]) then
do return {err="已经拥有"} end;
end;
if (s.credits < c.cr) then
do return {err=(("信用点不足（需要 " .. c.cr:toLocaleString("zh-CN")) .. "）")} end;
end;
if (s.src < c.src) then
do return {err=(("星源不足（需要 " .. S2(c.src)) .. "）")} end;
end;
s.credits = (s.credits - c.cr);
s.src = (s.src - c.src);
a[kind][id] = ((kind == "subs") and {lv=1,stock=10} or {lv=1});
S.C:write();
do return {ok=true} end;
end;
S.C.armUpCost = function(_this, kind, lv)
do return (((kind == "weapons") and 400 or ((kind == "subs") and 350 or 250)) * lv) end;
end;
S.C.armUpgrade = function(_this, kind, id)
local it, s, lv, cost;
it = ((S.C:armory())[kind])[id]; s = S.C.save;
if (not T(it)) then
do return {err="还没有研发"} end;
end;
lv = (T(it.lv) and it.lv or 1);
if (lv >= S.C.ARM_LV_MAX) then
do return {err="已满级"} end;
end;
cost = S.C:armUpCost(kind,lv);
if (s.credits < cost) then
do return {err=(("信用点不足（需要 " .. cost:toLocaleString("zh-CN")) .. "）")} end;
end;
s.credits = (s.credits - cost);
it.lv = (lv + 1);
S.C:write();
do return {ok=true,lv=it.lv} end;
end;
S.C.armAdUp = function(_this, kind, id)
local it;
it = ((S.C:armory())[kind])[id];
if (not T(it)) then
do return {err="还没有研发"} end;
end;
if ((T(it.lv) and it.lv or 1) >= S.C.ARM_LV_MAX) then
do return {err="已满级"} end;
end;
if (S.C:adUpLeft() <= 0) then
do return {err="今日广告升级次数已用完"} end;
end;
it.lv = ((T(it.lv) and it.lv or 1) + 1);
S.C.save.daily.adUp = ((T(S.C.save.daily.adUp) and S.C.save.daily.adUp or 0) + 1);
S.C:write();
do return {ok=true,lv=it.lv} end;
end;
S.C.craftAmmo = function(_this, id, times)
local it, d, s, room, cost;
it = ((S.C:armory()).subs)[id]; d = S.C:subDef(id); s = S.C.save;
times = (T(times) and times or 1);
if ((not T(it)) or (not T(d))) then
do return {err="先研发这种飞弹的图纸"} end;
end;
room = Math_floor(((S.C.SUB_STOCK_MAX - (T(it.stock) and it.stock or 0)) / S.C.SUB_BATCH));
times = Math_min(times,room);
if (times <= 0) then
do return {err=(("库存已满（" .. S2(S.C.SUB_STOCK_MAX)) .. "）")} end;
end;
cost = (d.craft * times);
if (s.credits < cost) then
do return {err=(("信用点不足（需要 " .. cost:toLocaleString("zh-CN")) .. "）")} end;
end;
s.credits = (s.credits - cost);
it.stock = ((T(it.stock) and it.stock or 0) + (S.C.SUB_BATCH * times));
S.C:write();
do return {ok=true,n=(S.C.SUB_BATCH * times),cost=cost} end;
end;
S.C.settleAmmo = function(_this, id, used, gained)
local it;
it = ((S.C:armory()).subs)[id];
if (not T(it)) then
do return end;
end;
it.stock = Math_max(0,(Math_min(S.C.SUB_STOCK_MAX,(((T(it.stock) and it.stock or 0) - used) + gained))));
end;
S.C.armPower = function(_this, mechId)
local lo, w, p;
lo = S.C:loadout(mechId); w = S.C:weapon(lo.main); p = ((30 * (S.C:wLvMult((S.C:armLv("weapons",lo.main))) - 1)) + ((w.m > 0) and 8 or 0));
if T(lo.sub) then
p = (p + ((18 * (S.C:wLvMult((S.C:armLv("subs",lo.sub))) - 1)) + ((lo.sub ~= "swarm") and 6 or 0)));
end;
do return Math_round((p + (4 * (S.C:armLv("nitros",lo.nitro) - 1)))) end;
end;
S.ARM_PAT = JS.odict({laser=smt({[0]="........","........","aaa.....","abbbbbbb","aaa.....","........","........","........",length=8},AMT),shotgun=smt({[0]="......a.","....a...","aaa.a.a.","abbaa...","aaa.a.a.","....a...","......a.","........",length=8},AMT),heal=smt({[0]="..aaaa..",".aaabaa.","aaabbbaa","aabbbbba","aaabbbaa",".aaabaa.","..aaaa..","........",length=8},AMT),twin=smt({[0]="........","aaaaaab.","aaaaaab.","........","aaaaaab.","aaaaaab.","........","........",length=8},AMT),lob=smt({[0]="...b....","..aaa...","..aaa...","..aaa...",".aaaaa..",".a.a.a..","...b....","........",length=8},AMT),prism=smt({[0]="...a....","..aba...",".abbba..","abbbbba.",".abbba..","..aba...","...a....","........",length=8},AMT),swarm=smt({[0]="aab.....","........","...aab..","........","aab.....","........","...aab..","........",length=8},AMT),cryo=smt({[0]="...a....",".a.a.a..","..aba...","aabbbaa.","..aba...",".a.a.a..","...a....","........",length=8},AMT),emp=smt({[0]="....aa..","...aa...","..aaaa..",".aabba..","...aa...","..aa....",".aa.....","........",length=8},AMT),cluster=smt({[0]="....b...","...a....",".aaaaa..","aaabaaa.","aabbbaa.","aaabaaa.",".aaaaa..","........",length=8},AMT),heavy=smt({[0]="........","..a.....","aaaaaab.","aaaaaabb","aaaaaab.","..a.....","........","........",length=8},AMT),gravity=smt({[0]="..aaaa..",".a....a.","a..bb..a","a.b..b.a","a..bb..a",".a....a.","..aaaa..","........",length=8},AMT),nitro=smt({[0]="........","a.......","aa..bb..","aaabbbb.","aa..bb..","a.......","........","........",length=8},AMT)},{"laser","shotgun","heal","twin","lob","prism","swarm","cryo","emp","cluster","heavy","gravity","nitro"});
S.FAM_COL = JS.odict({laser="#5CF2DC",shotgun="#FF8A3A",heal="#7CF29A",twin="#F5A524",lob="#9DD8FF",prism="#B47CFF"},{"laser","shotgun","heal","twin","lob","prism"});
S.C.armIcon = function(_this, kind, id)
local key, col, w, d, px;
if (kind == "weapons") then
w = S.C:weapon(id);
key = w.fam;
col = S.FAM_COL[w.fam];
elseif (kind == "subs") then
d = S.C:subDef(id);
key = d.id;
col = d.color;
else
key = "nitro";
col = "#57B8FF";
end;
px = "";
S.ARM_PAT[key]:forEach(function(_this, r)
local i;
do
i = 0;
while (i < LEN(r)) do
px = (S2(px) .. ((r[i] == ".") and "." or ((r[i] == "a") and "0" or "1")));
i = i + 1;
end
end;
end);
do return {w=8,h=8,pal=smt({[0]=col,"#FFFFFF",length=2},AMT),px=px} end;
end;
S.C.armColor = function(_this, kind, id)
do return (function() if (kind == "weapons") then return S.FAM_COL[(S.C:weapon(id)).fam] else return (function() if (kind == "subs") then return (S.C:subDef(id)).color else return "#57B8FF" end end)() end end)() end;
end;
;(function(_this)
local C, P;
C = HOST.window.Cosmic;
P = {homing=smt({[0]="...aa...","..abba..","..abba..","..abba..",".aabbaa.",".a.aa.a.","...bb...","..b..b..",length=8},AMT),orbit=smt({[0]="..aaaa..",".a....a.","a..bb..a","a.b..b.a","a.b..b.a","a..bb..a",".a....a.","..aaaa..",length=8},AMT),nova=smt({[0]="a..a..a.",".a.a.a..","..aaa...","aaabaaa.","..aaa...",".a.a.a..","a..a..a.","........",length=8},AMT),strike=smt({[0]="....aa..","...aa...","..aa....",".aaaaa..","...aa...","..aa....",".aa.....","aa......",length=8},AMT),beam=smt({[0]="........","b.......",".aaaaaaa","abbbbbbb",".aaaaaaa","b.......","........","........",length=8},AMT),fan=smt({[0]="a.....a.",".a...a..","..a.a...","...b....","..a.a...",".a...a..","a.....a.","........",length=8},AMT),mine=smt({[0]="...a....",".aaaaa..",".abbba..","aabbbaa.",".abbba..",".aaaaa..","...a....","........",length=8},AMT),boomerang=smt({[0]="aaaa....","abba....","aab.....","aa.b....","....b...",".....b..","......aa","......aa",length=8},AMT)};
C.modIcon = function(_this, m)
local px, fm, pat;
px = ""; fm = C:modForm(m.form); pat = (function() local _t = (function() local _t = P[(function() local _t = (function() local _t = fm; if not T(_t) then return _t end; return fm.b end)(); if T(_t) then return _t end; return m.form end)()]; if T(_t) then return _t end; return P[m.form] end)(); if T(_t) then return _t end; return P.homing end)();
pat:forEach(function(_this, r)
local i;
do
i = 0;
while (i < LEN(r)) do
px = (S2(px) .. ((r[i] == ".") and "." or ((r[i] == "a") and "0" or "1")));
i = i + 1;
end
end;
end);
do return {w=8,h=8,pal=smt({[0]=m.color,"#FFFFFF",length=2},AMT),px=px} end;
end;
end)(nil);
return S
end
