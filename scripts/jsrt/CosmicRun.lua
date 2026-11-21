-- 由 xpile-lite（tools/xpile_lite/transpile.js）从 cosmic_run.js（网页版 25） 自动生成，请勿手改。
-- 运行库见 jsrt/JS.lua。改玩法请改网页版 JS 后重新转换。
local JS = require("jsrt.JS")
local G, T, OR, AND, S2, LEN, MOD, typeof, tonum, smt, AMT = JS.G, JS.T, JS.OR, JS.AND, JS.S, JS.len, JS.mod, JS.typeof, JS.tonum, setmetatable, JS.AMT
local bor, band, bxor, shl, shr, ushr = JS.bor, JS.band, JS.bxor, JS.shl, JS.shr, JS.ushr
local Math_abs, Math_min, Math_max, Math_floor, Math_ceil, Math_round, Math_sqrt, Math_sin, Math_cos, Math_tan, Math_asin, Math_atan2, Math_exp, Math_hypot, Math_pow, Math_random, Math_sign, Math_imul, Math_PI = JS.Math_abs, JS.Math_min, JS.Math_max, JS.Math_floor, JS.Math_ceil, JS.Math_round, JS.Math_sqrt, JS.Math_sin, JS.Math_cos, JS.Math_tan, JS.Math_asin, JS.Math_atan2, JS.Math_exp, JS.Math_hypot, JS.Math_pow, JS.Math_random, JS.Math_sign, JS.Math_imul, math.pi
return function(HOST)
local S = {}
S.rand = function(_this, a, b)
do return (a + (Math_random() * (b - a))) end;
end;
S.clamp = function(_this, x, a, b)
do return (function() if (x < a) then return a else return (function() if (x > b) then return b else return x end end)() end end)() end;
end;
S.lerp = function(_this, a, b, t)
do return (a + ((b - a) * t)) end;
end;
S.pick = function(_this, l)
do return l[Math_floor((Math_random() * LEN(l)))] end;
end;
S.mmss = function(_this, t)
t = Math_max(0,(Math_floor(t)));
do return ((((((t < 600) and "0" or "") .. S2(Math_floor((t / 60)))) .. ":") .. ((MOD(t,60) < 10) and "0" or "")) .. S2(MOD(t,60))) end;
end;
S.d3 = function(_this, ax, ay, az, bx, by, bz)
local dx, dy, dz;
dx = (ax - bx); dy = (ay - by); dz = (az - bz);
do return (((dx * dx) + (dy * dy)) + (dz * dz)) end;
end;
S.dd = function(_this, a, b)
do return S.d3(nil,a.x,a.y,a.z,b.x,b.y,b.z) end;
end;
S.len3 = function(_this, x, y, z)
do return Math_sqrt((((x * x) + (y * y)) + (z * z))) end;
end;
S.nrm = function(_this, v)
local l;
l = (function() local _t = S.len3(nil,v[0],v[1],v[2]); if T(_t) then return _t end; return 1 end)();
do return smt({[0]=(v[0] / l),(v[1] / l),(v[2] / l),length=3},AMT) end;
end;
S.fwdOf = function(_this, yaw, pitch)
local cp;
cp = Math_cos((pitch * S.DEG));
do return smt({[0]=(Math_sin((yaw * S.DEG)) * cp),(-Math_sin((pitch * S.DEG))),(Math_cos((yaw * S.DEG)) * cp),length=3},AMT) end;
end;
S.rightOf = function(_this, yaw)
do return smt({[0]=Math_cos((yaw * S.DEG)),0,(-Math_sin((yaw * S.DEG))),length=3},AMT) end;
end;
S.cross = function(_this, a, b)
do return smt({[0]=((a[1] * b[2]) - (a[2] * b[1])),((a[2] * b[0]) - (a[0] * b[2])),((a[0] * b[1]) - (a[1] * b[0])),length=3},AMT) end;
end;
S.dot = function(_this, a, b)
do return (((a[0] * b[0]) + (a[1] * b[1])) + (a[2] * b[2])) end;
end;
S.angOf = function(_this, v)
local l;
l = (function() local _t = S.len3(nil,v[0],v[1],v[2]); if T(_t) then return _t end; return 1 end)();
do return smt({[0]=(Math_atan2(v[0],v[2]) / S.DEG),((-Math_asin((S.clamp(nil,(v[1] / l),(-1),1)))) / S.DEG),length=2},AMT) end;
end;
S.randDir = function(_this)
local u, a, r;
u = S.rand(nil,(-1),1); a = S.rand(nil,0,(Math_PI * 2)); r = Math_sqrt((1 - (u * u)));
do return smt({[0]=(Math_cos(a) * r),u,(Math_sin(a) * r),length=3},AMT) end;
end;
S.basis = function(_this, v)
local up, a, b;
up = ((Math_abs(v[1]) > 0.9) and smt({[0]=1,0,0,length=3},AMT) or smt({[0]=0,1,0,length=3},AMT)); a = S.nrm(nil,(S.cross(nil,up,v))); b = S.cross(nil,v,a);
do return smt({[0]=a,b,length=2},AMT) end;
end;
S.wrapA = function(_this, a)
do return (MOD((MOD(a,360) + 540),360) - 180) end;
end;
S.ease = function(_this, c, g, k, dt)
do return (c + ((g - c) * (1 - Math_exp(((-k) * dt))))) end;
end;
S.mT = function(_this, x, y, z)
local m;
m = S.E:m4();
m[12] = x;
m[13] = y;
m[14] = z;
do return m end;
end;
S.rot = function(_this, y, p, r)
do return S.E:trs(smt({[0]=0,0,0,length=3},AMT),y,p,r,1) end;
end;
S.pivot = function(_this, M, p, Rm, tr)
local m;
m = S.E:m4mul(M,(S.mT(nil,p[0],p[1],p[2])));
m = S.E:m4mul(m,Rm);
if T(tr) then
m = S.E:m4mul(m,(S.mT(nil,tr[0],tr[1],tr[2])));
end;
do return S.E:m4mul(m,(S.mT(nil,(-p[0]),(-p[1]),(-p[2])))) end;
end;
S.xf = function(_this, M, p)
do return smt({[0]=((((M[0] * p[0]) + (M[4] * p[1])) + (M[8] * p[2])) + M[12]),((((M[1] * p[0]) + (M[5] * p[1])) + (M[9] * p[2])) + M[13]),((((M[2] * p[0]) + (M[6] * p[1])) + (M[10] * p[2])) + M[14]),length=3},AMT) end;
end;
S.xd = function(_this, M, d)
do return S.nrm(nil,smt({[0]=(((M[0] * d[0]) + (M[4] * d[1])) + (M[8] * d[2])),(((M[1] * d[0]) + (M[5] * d[1])) + (M[9] * d[2])),(((M[2] * d[0]) + (M[6] * d[1])) + (M[10] * d[2])),length=3},AMT)) end;
end;
S.newPose = function(_this)
local md, fxm;
md = (function() local _t = HOST.window.VOX_MODELS; if not T(_t) then return _t end; return HOST.window.VOX_MODELS[S.R.mech] end)(); fxm = (T(S.MECHFX[S.R.mech]) and S.MECHFX[S.R.mech] or S.MECHFX.mech_azure);
do return {ok=(not (not (((T(md) and T(md.rig)) and T(md.parts)) and T(md.rig.waist)))),rig=(function() local _t = md; if not T(_t) then return _t end; return md.rig end)(),fxm=fxm,col=S.lin(nil,fxm.glow),vf=0,af=0,lean=0,bank=0,spin=0,thrR=0.25,thrV=0.2,twist=0,tP=0,hY=0,hP=0,aimK=0,aimT=0,tg=nil,hit=0,hitFlash=0,recB=0,rec={L=0,R=0},cast=nil,alt=0,podAlt=0,arm={L={p=0,e=0,y=0,r=0},R={p=0,e=0,y=0,r=0}},th={L={p=0,r=0},R={p=0,r=0}},kn={L=0,R=0},W=nil,mats=nil} end;
end;
S.setCast = function(_this, kind, dur)
if T(S.R.pose.ok) then
S.R.pose.cast = {kind=kind,t=0,dur=dur};
end;
end;
S.later = function(_this, sec, fn)
S.R.sched:push({t=sec,fn=fn});
end;
S.runSched = function(_this, dt)
local i, s;
do
i = (LEN(S.R.sched) - 1);
while (i >= 0) do
s = S.R.sched[i];
s.t = (s.t - dt);
if (s.t <= 0) then
S.R.sched:splice(i,1);
s:fn();
end;
i = i - 1;
end
end;
end;
S.mz = function(_this, side, i)
local po, l, p;
po = S.R.pose; l = (function() local _t = (function() local _t = po; if not T(_t) then return _t end; return po.W end)(); if not T(_t) then return _t end; return po.W.muz[side] end)();
if ((not T(l)) or (not T(LEN(l)))) then
do return S.P(nil) end;
end;
p = l[MOD((T(i) and i or 0),LEN(l))];
do return {x=p[0],y=p[1],z=p[2]} end;
end;
S.mainMz = function(_this, i)
local po;
po = S.R.pose;
do return S.mz(nil,(function() if (T(po) and T(po.ok)) then return po.fxm.fire[0] else return "R" end end)(),i) end;
end;
S.backPt = function(_this)
local po, b;
po = S.R.pose; b = (function() local _t = (function() local _t = po; if not T(_t) then return _t end; return po.W end)(); if not T(_t) then return _t end; return po.W.back end)();
do return (T(b) and {x=b[0],y=b[1],z=b[2]} or S.P(nil)) end;
end;
S.shoulderPt = function(_this, i)
local po, s;
po = S.R.pose; s = (function() local _t = (function() local _t = po; if not T(_t) then return _t end; return po.W end)(); if not T(_t) then return _t end; return po.W.shoulder end)();
do return (T(s) and {x=s[MOD(i,2)][0],y=s[MOD(i,2)][1],z=s[MOD(i,2)][2]} or {x=S.R.px,y=(S.R.py + 2),z=S.R.pz}) end;
end;
S.kick = function(_this, side, amt, body)
local po;
po = S.R.pose;
if ((not T(po)) or (not T(po.ok))) then
do return end;
end;
if T(side) then
po.rec[side] = Math_max(po.rec[side],amt);
end;
po.recB = Math_min(2,(po.recB + (T(body) and body or 0)));
end;
S.muzzleFx = function(_this, o, dir, sz)
local po, k;
po = S.R.pose;
if (((not T(po)) or (not T(po.ok))) or (LEN(S.R.parts) > 230)) then
do return end;
end;
S.R.parts:push({model="fx_white",x=(o.x + (dir[0] * 0.35)),y=(o.y + (dir[1] * 0.35)),z=(o.z + (dir[2] * 0.35)),vx=(dir[0] * 3),vy=(dir[1] * 3),vz=(dir[2] * 3),life=0.09,max=0.09,size=(2.4 * sz),tint=po.col,noGrav=true});
do
k = 0;
while (k < 2) do
S.R.parts:push({model="fx_white",x=o.x,y=o.y,z=o.z,vx=((dir[0] * 18) + S.rand(nil,(-3),3)),vy=((dir[1] * 18) + S.rand(nil,(-3),3)),vz=((dir[2] * 18) + S.rand(nil,(-3),3)),life=0.26,max=0.26,size=(1.1 * sz),tint=po.col,hot=true,noGrav=true});
k = k + 1;
end
end;
end;
S.podLaunch = function(_this, m, j, gap)
local po, W, pods, pd, sd;
po = S.R.pose; W = (function() local _t = (function() local _t = po; if not T(_t) then return _t end; return po.ok end)(); if not T(_t) then return _t end; return po.W end)(); pods = (function() local _t = W; if not T(_t) then return _t end; return (T(W.muz.P) and W.muz.P or W.shoulder) end)();
if (not T(pods)) then
do return m end;
end;
pd = pods[MOD(j,LEN(pods))]; sd = (function() if T(MOD(j,2)) then return (-1) else return 1 end end)();
m.launch = {x=pd[0],y=pd[1],z=pd[2],delay=(0.1 + Math_min(0.8,(j * (T(gap) and gap or 0.04)))),dir=S.nrm(nil,smt({[0]=(sd * 0.35),1,0.25,length=3},AMT)),t=0};
m.fh = (m.y - m.ty);
m.life = (m.life + 1.3);
m.hide = true;
do return m end;
end;
S.newTurret = function(_this, tp, props)
local po, W, from, tu, k;
po = S.R.pose; W = (function() local _t = (function() local _t = po; if not T(_t) then return _t end; return po.ok end)(); if not T(_t) then return _t end; return po.W end)(); from = (function() if T(W) then return W.crane else return smt({[0]=S.R.px,(S.R.py + 2),S.R.pz,length=3},AMT) end end)(); tu = {x=tp[0],y=tp[1],z=tp[2],life=10,fire=0,yaw=0,from=from,dep=0.45,dep0=0.45};
for _, _k4 in ipairs(JS.keys(props)) do k = _k4
tu[k] = props[k];
end;
S.R.turrets:push(tu);
do return tu end;
end;
S.poseStep = function(_this, dt)
local po, fxm, sp, cy, sy, t, dtc, c, dashing, dodging, vf, vs, vu, fk, sk, uk, legK, tg, yawL, dwn, ga, leanG, ph, down, cw, ck, twG, tPG, ay, dd_, trail, W, d, thr, k;
po = S.R.pose;
if (not T(po.ok)) then
do return end;
end;
fxm = po.fxm; sp = S.speed(nil); cy = Math_cos((S.R.yaw * S.DEG)); sy = Math_sin((S.R.yaw * S.DEG)); t = S.R.t; dtc = Math_max(dt,0.001); c = po.cast;
dashing = (not (not (T(S.R.dash) and ((not T(S.R.dash.dodge)) or T(S.R.dash.nitro))))); dodging = (not (not ((T(S.R.dash) and T(S.R.dash.dodge)) and (not T(S.R.dash.nitro)))));
vf = (function() if T(dashing) then return (sp * 1.5) else return ((S.R.vx * sy) + (S.R.vz * cy)) end end)(); vs = (T(dodging) and 0 or ((S.R.vx * cy) - (S.R.vz * sy))); vu = (T(S.R.dash) and 0 or S.R.vy);
fk = S.clamp(nil,(vf / sp),(-0.6),1.5); sk = S.clamp(nil,(vs / sp),(-1),1); uk = S.clamp(nil,(vu / sp),(-1),1); legK = S.clamp(nil,fk,0,1.2);
po.af = S.ease(nil,po.af,S.clamp(nil,(((vf - po.vf) / dtc) / 70),(-1.5),1.5),12,dt);
po.vf = vf;
po.aimT = (po.aimT - dt);
if ((po.aimT <= 0) or (T(po.tg) and (po.tg.hp <= 0))) then
po.aimT = 0.2;
po.tg = S.target(nil,S.R.px,S.R.py,S.R.pz,48);
end;
tg = (function() if (T(po.tg) and (po.tg.hp > 0)) then return po.tg else return nil end end)(); yawL = 0; dwn = 0;
if T(tg) then
ga = S.angOf(nil,smt({[0]=(tg.x - S.R.px),(tg.y - S.R.py),(tg.z - S.R.pz),length=3},AMT));
yawL = S.wrapA(nil,(ga[0] - S.R.yaw));
dwn = (ga[1] - (S.R.pitch + po.lean));
end;
po.aimK = S.ease(nil,po.aimK,(function() if T(tg) then return ((Math_abs(yawL) > 95) and 0 or 1) else return 0 end end)(),9,dt);
leanG = ((((fk * 17) + (T(dashing) and 20 or 0)) + (S.clamp(nil,po.af,0,1.5) * 5)) - ((T(c) and ((c.kind == "salvo") or (c.kind == "meteor"))) and 8 or 0));
po.lean = S.ease(nil,po.lean,S.clamp(nil,leanG,(-10),40),7,dt);
po.bank = S.ease(nil,po.bank,((-sk) * 9),6,dt);
po.spin = (function() if T(dodging) then return (((S.R.dash.t / S.R.dash.dur) * 360) * (function() if (((S.R.vx * cy) - (S.R.vz * sy)) >= 0) then return (-1) else return 1 end end)()) else return 0 end end)();
po.thrR = S.ease(nil,po.thrR,((((0.2 + (0.7 * S.clamp(nil,fk,0,1.2))) + (0.5 * S.clamp(nil,po.af,0,1.5))) + (function() if T(dashing) then return (T(S.R.dash.nitro) and 1.6 or 1.0) else return 0 end end)()) + (T(dodging) and 0.8 or 0)),12,dt);
po.thrV = S.ease(nil,po.thrV,((((0.18 + (0.7 * Math_max(0,uk))) + (0.35 * Math_abs(sk))) + (0.15 * Math_max(0,(-fk)))) + (T(dodging) and 0.6 or 0)),10,dt);
ph = smt({[0]=Math_sin((t * 2.1)),(Math_sin(((t * 2.1) + 1.6))),length=2},AMT); down = Math_max(0,(-uk));
;(smt({[0]="L","R",length=2},AMT)):forEach(function(_this, S_, i)
local tp, kn, rl;
tp = (((((6 + (18 * legK)) + (T(dashing) and 16 or 0)) + (T(dodging) and 52 or 0)) + (ph[i] * (3 + (4 * legK)))) - (down * 10));
kn = ((((((10 + (24 * legK)) + (T(dashing) and 4 or 0)) + (T(dodging) and 90 or 0)) + (14 * Math_max(0,uk))) + (ph[(1 - i)] * (3 + (5 * legK)))) - (down * 10));
rl = ((((S_ == "L") and 3 or (-3)) - (sk * 14)) + (function() if T(dodging) then return ((S_ == "L") and 12 or (-12)) else return 0 end end)());
if (T(c) and (c.kind == "salvo")) then
tp = (tp + 8);
kn = (kn + 14);
end;
po.th[S_].p = S.ease(nil,po.th[S_].p,tp,9,dt);
po.th[S_].r = S.ease(nil,po.th[S_].r,rl,9,dt);
po.kn[S_] = S.ease(nil,po.kn[S_],Math_max(2,kn),9,dt);
end);
cw = (function() if T(c) then return S.clamp(nil,(Math_sin((S.clamp(nil,(c.t / c.dur),0,1) * Math_PI)) * 1.6),0,1) else return 0 end end)(); ck = (function() if T(c) then return S.clamp(nil,(c.t / c.dur),0,1) else return 0 end end)();
twG = (function() if T(tg) then return (S.clamp(nil,(yawL * 0.7),(-30),30) * po.aimK) else return 0 end end)(); tPG = (((-po.recB) * 4) + (function() if T(tg) then return (S.clamp(nil,(dwn * 0.45),(-16),16) * po.aimK) else return 0 end end)());
if T(c) then
if (c.kind == "slash") then
twG = (function() if (ck < 0.25) then return ((-30) * (ck / 0.25)) else return (function() if (ck < 0.6) then return S.lerp(nil,(-30),32,((ck - 0.25) / 0.35)) else return S.lerp(nil,32,0,((ck - 0.6) / 0.4)) end end)() end end)();
elseif ((c.kind == "salvo") or (c.kind == "meteor")) then
tPG = (tPG - (10 * cw));
elseif (c.kind == "deploy") then
tPG = (tPG + (8 * cw));
elseif (c.kind == "beam") then
tPG = (tPG - (5 * cw));
end;
end;
tPG = (tPG + (Math_sin((t * 1.7)) * 0.8));
po.twist = S.ease(nil,po.twist,twG,9,dt);
po.tP = S.ease(nil,po.tP,tPG,12,dt);
po.hY = S.ease(nil,po.hY,(function() if T(tg) then return ((S.clamp(nil,(yawL - po.twist),(-34),34) * 0.75) * po.aimK) else return 0 end end)(),10,dt);
po.hP = S.ease(nil,po.hP,((function() if T(tg) then return ((S.clamp(nil,(dwn - po.tP),(-20),24) * 0.5) * po.aimK) else return 0 end end)() - (po.hit * 16)),12,dt);
ay = S.clamp(nil,(yawL - po.twist),(-22),22); dd_ = S.clamp(nil,(dwn - po.tP),(-42),42); trail = (S.clamp(nil,po.af,(-1),1.5) * 6);
;(smt({[0]="L","R",length=2},AMT)):forEach(function(_this, S_)
local role, side, sway, g, cp, cyaw, tot, pu, pe, aimW, a;
role = (T(fxm.aim[S_]) and fxm.aim[S_] or "free"); side = ((S_ == "L") and 1 or (-1)); sway = (Math_sin(((t * 1.8) + ((S_ == "L") and 0 or 2))) * 3); g = {p=0,y=0,r=(side * 6)};
if (role == "gun") then
g.p = S.lerp(nil,(((-12) + sway) + (14 * legK)),dd_,po.aimK);
g.y = ((po.aimK * ay) * 0.95);
g.r = (side * (4 + (6 * (1 - po.aimK))));
elseif ((role == "staff") or (role == "spear")) then
g.p = S.lerp(nil,((4 + (sway * 0.5)) + (10 * legK)),(dd_ + 90),po.aimK);
g.y = (po.aimK * ay);
elseif (role == "axe") then
g.p = (((-4) + sway) + (26 * legK));
g.r = (side * 8);
elseif (role == "guard") then
g.p = S.lerp(nil,(((-22) + sway) + (18 * legK)),(-42),po.aimK);
g.y = (po.aimK * 8);
else
g.p = (((-6) + sway) + (30 * legK));
g.r = (side * (7 + (6 * legK)));
end;
if T(dodging) then
g.p = (((role == "staff") or (role == "spear")) and 35 or 55);
g.r = (side * 10);
elseif T(dashing) then
g.p = (((role == "staff") or (role == "spear")) and 40 or 60);
g.y = 0;
end;
if T(c) then
cp = nil; cyaw = 0;
if (c.kind == "slash") then
if (S_ == "R") then
cp = (function() if (ck < 0.25) then return S.lerp(nil,g.p,(-70),(ck / 0.25)) else return (function() if (ck < 0.6) then return S.lerp(nil,(-70),120,(1 - Math_pow((1 - ((ck - 0.25) / 0.35)),3))) else return S.lerp(nil,120,g.p,((ck - 0.6) / 0.4)) end end)() end end)();
cw = 1;
else
cp = 40;
end;
elseif (c.kind == "heal") then
cp = (function() if (S_ == "R") then return ((role == "staff") and 50 or (-50)) else return (-75) end end)();
elseif (c.kind == "deploy") then
cp = (-75);
elseif (c.kind == "salvo") then
cp = (-130);
elseif (c.kind == "meteor") then
cp = ((S_ == "R") and 20 or (-140));
elseif (((c.kind == "beam") and (S_ == "R")) and (((role == "gun") or (role == "staff")) or (role == "spear"))) then
cp = (function() if (role == "gun") then return dd_ else return (dd_ + 90) end end)();
cyaw = ay;
end;
if (cp ~= nil) then
g.p = S.lerp(nil,g.p,cp,cw);
g.y = S.lerp(nil,g.y,cyaw,cw);
end;
end;
g.p = (g.p + (trail - (po.hit * 30)));
tot = g.p; aimW = ((po.aimK * (1 - cw)) * ((T(dashing) or T(dodging)) and 0 or 1));
if (role == "gun") then
pu = S.lerp(nil,(tot * 0.6),S.clamp(nil,((-26) + (0.5 * dd_)),(-70),10),aimW);
elseif ((role == "staff") or (role == "spear")) then
pu = (tot * 0.35);
else
pu = (tot * 0.6);
end;
pe = S.clamp(nil,((tot - pu) + (((role == "gun") and (aimW > 0.3)) and 8 or 12)),(-20),125);
a = po.arm[S_];
a.p = S.ease(nil,a.p,pu,13,dt);
a.e = S.ease(nil,a.e,pe,15,dt);
a.y = S.ease(nil,a.y,g.y,12,dt);
a.r = S.ease(nil,a.r,g.r,10,dt);
end);
if T(c) then
c.t = (c.t + dt);
if (c.t >= c.dur) then
po.cast = nil;
end;
end;
po.hit = Math_max(0,(po.hit - (dt * 4)));
po.hitFlash = (po.hitFlash - dt);
po.rec.L = Math_max(0,(po.rec.L - (dt * 9)));
po.rec.R = Math_max(0,(po.rec.R - (dt * 9)));
po.recB = Math_max(0,(po.recB - (dt * 7)));
W = po.W;
if (T(W) and (LEN(S.R.parts) < 240)) then
d = W.rearD; thr = po.thrR;
W.rear:forEach(function(_this, n)
if (Math_random() > (0.35 + (thr * 0.5))) then
do return end;
end;
S.R.parts:push({model="fx_white",x=n[0],y=n[1],z=n[2],vx=(((d[0] * (5 + (6 * thr))) - (S.R.vx * 0.15)) + S.rand(nil,(-1),1)),vy=(((d[1] * (5 + (6 * thr))) - (S.R.vy * 0.15)) + S.rand(nil,(-1),1)),vz=(((d[2] * (5 + (6 * thr))) - (S.R.vz * 0.15)) + S.rand(nil,(-1),1)),life=(0.35 + (0.25 * thr)),max=(0.35 + (0.25 * thr)),size=(1.2 + (thr * 0.8)),tint=po.col,noGrav=true});
end);
if ((((T(c) and (c.kind == "slash")) and (ck > 0.22)) and (ck < 0.7)) and T(W.axe)) then
do
k = 0;
while (k < 3) do
S.R.parts:push({model="fx_spark",x=(W.axe[0] + S.rand(nil,(-0.4),0.4)),y=(W.axe[1] + S.rand(nil,(-0.4),0.4)),z=(W.axe[2] + S.rand(nil,(-0.4),0.4)),vx=S.rand(nil,(-3),3),vy=S.rand(nil,(-3),3),vz=S.rand(nil,(-3),3),life=0.35,max=0.35,size=1.8,noGrav=true});
k = k + 1;
end
end;
end;
end;
end;
S.poseBuild = function(_this)
local po, rig, fxm, root, Mt, mats, Ma, W;
po = S.R.pose;
if (not T(po.ok)) then
do return end;
end;
rig = po.rig; fxm = po.fxm; root = S.E:trs(smt({[0]=S.R.px,((S.R.py - 2.4) + (Math_sin((S.R.t * 3)) * 0.12)),S.R.pz,length=3},AMT),S.R.yaw,(S.R.pitch + po.lean),((S.R.roll + po.bank) + po.spin),1.35);
Mt = S.pivot(nil,root,rig.waist,(S.rot(nil,po.twist,po.tP,0))); mats = {body=Mt}; Ma = JS.dict();
mats.head = S.pivot(nil,Mt,rig.neck,(S.rot(nil,po.hY,po.hP,0)));
;(smt({[0]="L","R",length=2},AMT)):forEach(function(_this, S_)
local a, role, rec, tr, pk, Mu;
a = po.arm[S_]; role = fxm.aim[S_]; rec = po.rec[S_]; tr = nil;
if (rec > 0.01) then
if ((role == "gun") or (role == "guard")) then
tr = smt({[0]=0,0,((-0.28) * rec),length=3},AMT);
elseif ((role == "staff") or (role == "spear")) then
tr = smt({[0]=0,(0.35 * rec),0,length=3},AMT);
end;
end;
pk = (function() if (role == "gun") then return ((-10) * rec) else return 0 end end)(); Mu = S.pivot(nil,Mt,rig[("shoulder" .. S2(S_))],(S.rot(nil,a.y,(a.p + (rec * 3)),a.r)));
mats[("uarm" .. S2(S_))] = Mu;
Ma[S_] = S.pivot(nil,Mu,rig[("elbow" .. S2(S_))],S.rot(nil,0,(a.e + pk),0),tr);
mats[("arm" .. S2(S_))] = Ma[S_];
mats[("thigh" .. S2(S_))] = S.pivot(nil,root,rig[("hip" .. S2(S_))],(S.rot(nil,0,po.th[S_].p,po.th[S_].r)));
mats[("shin" .. S2(S_))] = S.pivot(nil,mats[("thigh" .. S2(S_))],rig[("knee" .. S2(S_))],(S.rot(nil,0,po.kn[S_],0)));
end);
W = {muz=JS.dict(),rearD=S.xd(nil,Mt,smt({[0]=0,0,(-1),length=3},AMT)),vernD=S.xd(nil,Mt,smt({[0]=0,(-1),0,length=3},AMT)),rear=smt({[0]=S.xf(nil,Mt,rig.rearL),(S.xf(nil,Mt,rig.rearR)),length=2},AMT),vern=smt({[0]=S.xf(nil,Mt,rig.vernL),(S.xf(nil,Mt,rig.vernR)),length=2},AMT)};
;(smt({[0]="L","R",length=2},AMT)):forEach(function(_this, S_)
if T(rig[("muzzle" .. S2(S_))]) then
W.muz[S_] = rig[("muzzle" .. S2(S_))]:map(function(_this, q)
do return S.xf(nil,Ma[S_],q) end;
end);
end;
end);
if T(rig.muzzleP) then
W.muz.P = rig.muzzleP:map(function(_this, q)
do return S.xf(nil,Mt,q) end;
end);
end;
W.shoulder = smt({[0]=S.xf(nil,Mt,smt({[0]=rig.shoulderL[0],(rig.shoulderL[1] + 0.6),rig.shoulderL[2],length=3},AMT)),(S.xf(nil,Mt,smt({[0]=rig.shoulderR[0],(rig.shoulderR[1] + 0.6),rig.shoulderR[2],length=3},AMT))),length=2},AMT);
W.back = S.xf(nil,Mt,smt({[0]=((rig.rearL[0] + rig.rearR[0]) / 2),rig.rearL[1],(rig.rearL[2] - 0.1),length=3},AMT));
W.crane = (function() if T(rig.craneL) then return S.xf(nil,Mt,rig.craneL) else return W.shoulder[0] end end)();
W.axe = (function() if T(rig.axeEdge) then return S.xf(nil,Ma.R,rig.axeEdge) else return nil end end)();
po.mats = mats;
po.W = W;
end;
S.lv = function(_this, id)
do return (T(S.R.lv[id]) and S.R.lv[id] or 0) end;
end;
S.setting = function(_this, k, d)
local sv;
sv = (function() local _t = S.C.save; if not T(_t) then return _t end; return S.C.save.settings end)();
do return (function() if (T(sv) and (sv[k] ~= nil)) then return sv[k] else return d end end)() end;
end;
S.sensK = function(_this)
local v;
v = S.setting(nil,"sens","mid");
do return ((v == "low") and 0.7 or ((v == "high") and 1.4 or 1)) end;
end;
S.setSetting = function(_this, k, v)
local sv;
sv = (T(S.C.save.settings) and S.C.save.settings or (function() S.C.save.settings = JS.dict(); return S.C.save.settings end)());
sv[k] = v;
S.C:write();
if (k == "cam") then
S.camPreset = v;
if T(S.R) then
S.R.cx = nil;
end;
end;
if (((k == "music") and T(S.C.music)) and T(S.C.music.refresh)) then
S.C.music:refresh();
end;
if ((k == "lvMode") and (v ~= "later")) then
S.lvDefer = false;
end;
end;
S.M = function(_this)
do return S.C:mech(S.R.mech) end;
end;
S.fx = function(_this, k)
local c;
c = S.C:char(S.R.pilot);
do return (T(c.passive.fx[k]) and c.passive.fx[k] or 0) end;
end;
S.hullMax = function(_this)
do return Math_round((((((S.M(nil)).hp * S.R.mMul) * ((1 + S.R.st.hp) + S.fx(nil,"hull"))) * (1 + (0.2 * S.lv(nil,"hull")))) * (T(S.dmod(nil,"glass")) and 0.7 or 1))) end;
end;
S.dmgMult = function(_this)
do return ((((T(S.dmod(nil,"glass")) and 1.4 or 1) * (1 + S.R.st.atk)) * (1 + (0.1 * S.lv(nil,"power")))) * ((T(S.R.st.traits.berserk) and (S.R.hull < (S.hullMax(nil) * 0.3))) and 1.3 or 1)) end;
end;
S.cdMult = function(_this)
do return ((1 - (0.07 * S.lv(nil,"cooling"))) * (1 - S.R.st.cdr)) end;
end;
S.dmod = function(_this, id)
do return (not (not ((T(S.R) and T(S.R.daily)) and (S.R.daily.mods:indexOf(id) >= 0)))) end;
end;
S.speed = function(_this)
do return (((((S.M(nil)).spd * 1.1) * (1 + S.R.st.spd)) * (1 + (0.08 * S.lv(nil,"engine")))) * (T(S.dmod(nil,"swift")) and 1.15 or 1)) end;
end;
S.pickupR = function(_this)
do return ((11 * ((1 + S.R.st.pickup) + S.fx(nil,"pickup"))) * (1 + (0.35 * S.lv(nil,"magnet")))) end;
end;
S.xpNeed = function(_this, l)
do return Math_floor(((5 + (l * 4)) + ((l * l) * 0.35))) end;
end;
S.blast = function(_this)
do return ((1 + S.fx(nil,"blast")) * (1 + S.R.st.blast)) end;
end;
S.P = function(_this)
do return {x=S.R.px,y=S.R.py,z=S.R.pz} end;
end;
S.newRun = function(_this, chapterId, opt)
local ch0, s, match, dg, ch;
opt = (T(opt) and opt or JS.dict());
ch0 = S.C.CHAPTERS[(chapterId - 1)]; s = S.C.save; match = ((S.C:mech(s.mech)).match == s.pilot); dg = Math_max(1,(Math_min(10,(T(opt.danger) and opt.danger or 1))));
ch = G.Object:assign(JS.dict(),ch0,{hp=((ch0.hp * (1 + (0.12 * (dg - 1)))) * ((T(opt.daily) and (opt.mods:indexOf("iron") >= 0)) and 1.5 or 1)),dmg=(ch0.dmg * (1 + (0.08 * (dg - 1))))});
S.R = {ch=ch,danger=dg,endless=((not (not T(opt.endless))) or (not (not T(opt.daily)))),daily=(T(opt.daily) and {mods=opt.mods:slice()} or nil),wave=1,bossScale=(1 * (1 + (0.12 * (dg - 1)))),t=0,px=0,py=0,pz=(-90),vx=0,vy=0,vz=0,yaw=0,pitch=0,roll=0,camYaw=0,camPitch=8,xp=0,level=1,kills=0,credits=0,src=0,frags=JS.dict(),lv={main=1,support=1},pilot=s.pilot,copilot=s.pilot,mech=s.mech,match=match,mMul=(S.C:mechMul(s.mech) * (function() if T(match) then return (1 + S.C.MATCH_BONUS) else return 1 end end)()),cStar=(S.C:pilotMul(s.pilot) * (function() if T(match) then return (1 + S.C.MATCH_BONUS) else return 1 end end)()),dodgeCd=0,enemies=smt({length=0},AMT),shots=smt({length=0},AMT),ebullets=smt({length=0},AMT),missiles=smt({length=0},AMT),gems=smt({length=0},AMT),pickups=smt({length=0},AMT),parts=smt({length=0},AMT),nums=smt({length=0},AMT),bubbles=smt({length=0},AMT),turrets=smt({length=0},AMT),wells=smt({length=0},AMT),beams=smt({length=0},AMT),novas=smt({length=0},AMT),zones=smt({length=0},AMT),fires=smt({length=0},AMT),timers={main=0},spawnAcc=0,iframe=0,shake=0,boss=nil,phase="explore",won=false,over=false,ended=false,banner=nil,bannerT=0,decor=smt({length=0},AMT),pendingLevels=(T(((S.C:chipStats()).traits).headstart) and 1 or 0),st=S.C:chipStats(),mines=smt({length=0},AMT),booms=smt({length=0},AMT),strikes=smt({length=0},AMT),combo=0,comboT=0,activeCd=3,supportCd=2,dash=nil,cop={x=0,y=0,z=(-90),dash=nil},revived=false,adRevived=false,god=false,nodes=smt({length=0},AMT),nearNode=nil,target=nil,sched=smt({length=0},AMT),pose=nil};
S.R.evBag = smt({length=0},AMT);
S.R.tutRun = ((not T(S.C.save.tutorialDone)) and (not T(S.R.endless)));
S.R.tutPicked = false;
S.R.chestPick = 0;
S.R.feverT = 0;
S.R.feverK = 0;
S.initMods(nil);
S.initArms(nil);
S.R.pose = S.newPose(nil);
if (S.C.save.runs < 3) then
HOST.setTimeout(nil,function(_this)
if (T(S.R) and (not T(S.R.over))) then
S.banner(nil,"新手加速：前 3 局经验 +80%");
end;
end,2500);
end;
S.R.hull = S.hullMax(nil);
S.stars = (T(S.stars) and S.stars or S.E:buildStars({data=S.makeStars(nil),colors=smt({[0]=smt({[0]=0.92,0.93,1.0,length=3},AMT),smt({[0]=0.55,0.95,0.9,length=3},AMT),smt({[0]=1.0,0.8,0.5,length=3},AMT),length=3},AMT)}));
S.loadSector(nil,1);
end;
S.loadSector = function(_this, k)
local plan, ev, a, i, d, r;
k = Math_max(1,(Math_min(S.SECTORS,k)));
S.R.warping = false;
S.R.sector = k;
S.R.secMul = (1 + (0.15 * (k - 1)));
S.R.dmgMul = ((S.R.ch.dmg * (1 + (0.06 * (k - 1)))) * (T(S.R.endless) and 1 or 0.85));
S.R.px = 0;
S.R.py = 0;
S.R.pz = (-90);
S.R.vz = 0;
S.R.vy = S.R.vz;
S.R.vx = S.R.vy;
S.R.yaw = 0;
S.R.pitch = 0;
S.R.camYaw = 0;
S.R.camPitch = 8;
S.R.gems:forEach(function(_this, g)
S.R.xp = (S.R.xp + g.v);
end);
S.R.enemies = smt({length=0},AMT);
S.R.shots = smt({length=0},AMT);
S.R.ebullets = smt({length=0},AMT);
S.R.missiles = smt({length=0},AMT);
S.R.gems = smt({length=0},AMT);
S.R.pickups = smt({length=0},AMT);
S.R.turrets = smt({length=0},AMT);
S.R.wells = smt({length=0},AMT);
S.R.zones = smt({length=0},AMT);
S.R.fires = smt({length=0},AMT);
S.R.dash = nil;
S.R.mines = smt({length=0},AMT);
S.R.booms = smt({length=0},AMT);
S.R.strikes = smt({length=0},AMT);
S.R.cop.x = 0;
S.R.cop.y = 0;
S.R.cop.z = (-90);
S.R.boss = nil;
S.R.phase = "explore";
S.R.nodes = smt({length=0},AMT);
S.R.decor = smt({length=0},AMT);
S.R.secT = 0;
S.R.bossTimer = 0;
S.R.event = nil;
S.R.target = nil;
plan = (T(S.R.endless) and "endless" or S.PLAN[(k - 1)]);
S.R.secKills = 0;
S.R.chargeMsg = false;
S.R.gateNeed = (function() if ((plan == "normal") or (plan == "rest")) then return Math_round(((((50 + (15 * k)) + (15 * (S.R.ch.id - 1))) * (1 + (0.04 * (S.R.danger - 1)))) * ((T(S.R.tutRun) and (k == 1)) and 0.6 or 1))) else return 0 end end)();
S.R.risk = (((not (not T(S.R.nextRisk))) and (plan ~= "boss")) and (plan ~= "endless"));
S.R.nextRisk = false;
S.R.champ2 = false;
if T(S.R.risk) then
S.R.secMul = (S.R.secMul * 1.2);
S.R.dmgMul = (S.R.dmgMul * 1.1);
end;
if (plan == "endless") then
S.R.objective = "无尽模式：撑得越久越好";
S.R.waveT = 0;
S.R.wave = 1;
S.R.secMul = 1;
elseif (plan == "boss") then
S.R.bossTimer = 2.5;
S.R.objective = ("击败首领 " .. S2(S.R.ch.bossName));
else
if (T(S.R.tutRun) and (k == 1)) then
ev = "pirate";
S.R.evBag = S.EVENTS:filter(function(_this, e)
do return (e ~= "pirate") end;
end);
else
ev = ((plan == "elite") and "nest" or S.nextEvent(nil));
end;
S.R.lastEvent = ev;
a = S.rand(nil,(-0.9),0.9);
S.R.event = S.makeNode(nil,ev,(Math_sin(a) * S.rand(nil,30,60)),S.rand(nil,(-35),35),(S.rand(nil,(-10),35)));
S.R.nodes:push(S.R.event);
S.R.objective = ((T(S.R.risk) and "险途 · " or "") .. S2(S.NODE_INFO[ev].goal));
end;
if (plan == "rest") then
S.R.nodes:push((S.makeNode(nil,"merchant",28,10,(-70))));
end;
S.R.gate = S.makeNode(nil,"gate",S.rand(nil,(-25),25),S.rand(nil,(-20),20),95);
S.R.gate.state = (((plan == "boss") or (plan == "endless")) and "hidden" or "locked");
S.R.nodes:push(S.R.gate);
S.R.gate2 = nil;
if ((((plan ~= "boss") and (plan ~= "endless")) and (k <= 4)) and (not (T(S.R.tutRun) and (k == 1)))) then
S.R.gate2 = S.makeNode(nil,"gate",(S.R.gate.x + (function() if (S.R.gate.x > 0) then return (-48) else return 48 end end)()),(S.R.gate.y + S.rand(nil,(-8),8)),(S.R.gate.z - 8));
S.R.gate2.risk = true;
S.R.gate2.state = "locked";
S.R.gate2.info = S.NODE_INFO.riskgate;
S.R.gate2.objs[0].tint = smt({[0]=1.5,0.45,0.5,length=3},AMT);
S.R.gate.info = S.NODE_INFO.safegate;
S.R.nodes:push(S.R.gate2);
end;
do
i = 0;
while (i < 22) do
d = S.randDir(nil); r = S.rand(nil,190,300);
S.R.decor:push({model=S.pick(nil,smt({[0]="space_asteroid_a","space_asteroid_a","space_asteroid_b","space_ore_asteroid",length=4},AMT)),x=(d[0] * r),y=(d[1] * r),z=(d[2] * r),s=S.rand(nil,3,9),yaw=S.rand(nil,0,360),spin=S.rand(nil,(-8),8)});
i = i + 1;
end
end;
S.R.decor:push({model="space_planet",x=(-420),y=(-160),z=620,s=9,yaw=30,spin=0.5});
S.R.affix = (function() if (((k >= 2) and (plan ~= "boss")) and (plan ~= "endless")) then return S.pick(nil,S.AFFIX) else return nil end end)();
S.R.champT = (function() if (((((plan == "normal") or (plan == "rest")) and ((k >= 2) or (S.R.ch.id >= 2))) and (not (T(S.R.tutRun) and (k <= 2)))) or T(S.R.risk)) then return S.rand(nil,6,12) else return 0 end end)();
if ((plan == "normal") or (plan == "rest")) then
S.arrivalPack(nil);
end;
S.banner(nil,((((T(S.R.endless) and "无尽模式" or ((("星域 " .. S2(k)) .. " / ") .. S2(S.SECTORS))) .. "：") .. S2(S.R.objective)) .. (function() if T(S.R.affix) then return ("　词缀：" .. S2(S.R.affix.name)) else return "" end end)()));
end;
S.affix = function(_this, id)
do return (not (not (T(S.R) and ((T(S.R.affix) and (S.R.affix.id == id)) or T(S.dmod(nil,id)))))) end;
end;
S.nextEvent = function(_this)
local i, ev;
if ((not T(S.R.evBag)) or (not T(LEN(S.R.evBag)))) then
S.R.evBag = S.EVENTS:filter(function(_this, e)
do return (e ~= S.R.lastEvent) end;
end);
end;
i = Math_floor((Math_random() * LEN(S.R.evBag))); ev = S.R.evBag[i];
S.R.evBag:splice(i,1);
do return ev end;
end;
S.arrivalPack = function(_this)
local to, k, n, groups, g, f, cx, cy, cz, t0, i;
to = (T(S.R.event) and S.R.event or S.R.gate); k = S.R.sector; n = Math_round(((((((4 + (2 * k)) + (3 * (S.R.ch.id - 1))) * (T(S.affix(nil,"tide")) and 1.3 or 1)) * S.perfMul(nil)) * (1 + (0.05 * (S.R.danger - 1)))) * ((T(S.R.tutRun) and (k == 1)) and 0.5 or 1)));
groups = Math_max(2,(Math_ceil((n / 4))));
do
g = 0;
while (g < groups) do
f = S.rand(nil,0.3,0.7); cx = (S.lerp(nil,S.R.px,to.x,f) + S.rand(nil,(-14),14)); cy = (S.lerp(nil,S.R.py,to.y,f) + S.rand(nil,(-10),10)); cz = (S.lerp(nil,S.R.pz,to.z,f) + S.rand(nil,(-8),8)); t0 = S.roamType(nil);
do
i = g;
while (i < n) do
S.spawnEnemy(nil,(function() if (Math_random() < 0.7) then return t0 else return S.roamType(nil) end end)(),(cx + S.rand(nil,(-5),5)),(cy + S.rand(nil,(-5),5)),(cz + S.rand(nil,(-5),5)));
i = (i + groups);
end
end;
g = g + 1;
end
end;
end;
S.spawnChamp = function(_this)
local t, i, c, p, e, b;
t = "heavy";
do
i = 0;
while (i < 8) do
c = S.roamType(nil);
if (S.CHAMP_NO:indexOf(c) < 0) then
t = c;
do break end;
end;
i = i + 1;
end
end;
p = S.aheadPos(nil); e = S.spawnEnemy(nil,t,p[0],p[1],p[2]); b = S.ENEMY[t];
e.d = G.Object:assign(JS.dict(),b,{name=("精英·" .. S2(b.name)),elite=true,champ=true,scale=(b.scale * 1.45),dmg=(b.dmg * 1.2),xp=((b.xp * 6) + 8),cr=((b.cr * 6) + 20)});
e.max = (e.hp * 8);
e.hp = e.max;
e.r = (e.r * 1.45);
S.banner(nil,(("精英出现：" .. S2(e.d.name)) .. "（击败必掉战利品）"));
S.C:sfx("boss");
do return e end;
end;
S.nextSector = function(_this, risk)
local healK, f, next_, run;
if ((S.R.sector >= S.SECTORS) or T(S.R.warping)) then
do return end;
end;
healK = ((T(S.R.gate2) and (not T(risk))) and 0.6 or 0.3);
S.R.nextRisk = (not (not T(risk)));
f = HOST.document:getElementById("warp");
if T(f) then
f.classList:add("on");
end;
S.R.warping = true;
S.paused = true;
S.C:sfx("warp");
next_ = (S.R.sector + 1); run = S.R;
if T(HOST.window.CosmicRun.debug.sync) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * healK)));
S.loadSector(nil,next_);
S.paused = false;
if T(f) then
f.classList:remove("on");
end;
do return end;
end;
HOST.setTimeout(nil,function(_this)
if ((S.R ~= run) or (S.R.sector ~= (next_ - 1))) then
if T(f) then
f.classList:remove("on");
end;
do return end;
end;
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * healK)));
S.loadSector(nil,next_);
S.R.warping = false;
S.paused = false;
if T(f) then
f.classList:remove("on");
end;
end,600);
end;
S.objectiveDone = function(_this)
do return ((not T(S.R.event)) or (S.R.event.state == "done")) end;
end;
S.charging = function(_this)
do return (function() local _t = ((T(S.R.gate) and (S.R.gate.state == "locked")) and S.objectiveDone(nil)); if not T(_t) then return _t end; return ((T(S.R.secKills) and S.R.secKills or 0) < (T(S.R.gateNeed) and S.R.gateNeed or 0)) end)() end;
end;
S.makeNode = function(_this, type_, x, y, z)
local n, i;
n = {type=type_,x=x,y=y,z=z,state="idle",progress=0,timer=0,info=S.NODE_INFO[type_],objs=smt({length=0},AMT)};
if (type_ == "pirate") then
n.objs:push({model="space_pirate_base",x=x,y=(y - 6),z=z,s=0.7,spin=2});
end;
if (type_ == "derelict") then
n.objs:push({model="space_derelict",x=x,y=y,z=z,s=1.6,spin=3});
end;
if (type_ == "merchant") then
n.objs:push({model="space_station",x=x,y=(y - 2),z=z,s=0.8,spin=8});
n.objs:push({model="space_beacon",x=(x + 10),y=y,z=(z - 6),s=1.4,spin=0});
end;
if (type_ == "distress") then
n.pod = {hp=120,max=120};
n.objs:push({model="prop_loot_pod",x=x,y=y,z=z,s=5,spin=40});
n.objs:push({model="space_beacon",x=(x - 8),y=(y - 2),z=(z + 4),s=1.2,spin=0});
end;
if (type_ == "hunt") then
n.objs:push({model="space_beacon",x=x,y=y,z=z,s=1.8,spin=30});
end;
if (type_ == "ambush") then
n.objs:push({model="space_derelict",x=x,y=y,z=z,s=1.2,spin=6});
n.objs:push({model="space_beacon",x=(x + 8),y=y,z=z,s=1.3,spin=0});
end;
if (type_ == "nest") then
do
i = 0;
while (i < 4) do
n.objs:push({model="env_crystal_cluster",x=(x + S.rand(nil,(-9),9)),y=(y + S.rand(nil,(-6),6)),z=(z + S.rand(nil,(-9),9)),s=S.rand(nil,3,4.5),spin=S.rand(nil,(-20),20),pitch=S.rand(nil,0,360)});
i = i + 1;
end
end;
end;
if (type_ == "gate") then
n.objs:push({model="space_jumpgate",x=x,y=y,z=z,s=1.2,pitch=0,spin=0});
end;
do return n end;
end;
S.makeStars = function(_this)
local out, i, x, y, z, l, r;
out = smt({length=0},AMT);
do
i = 0;
while (i < 420) do
x = S.rand(nil,(-1),1); y = S.rand(nil,(-1),1); z = S.rand(nil,(-1),1); l = (function() local _t = Math_hypot(x,y,z); if T(_t) then return _t end; return 1 end)(); r = S.rand(nil,3000,3600);
out:push(((x / l) * r),((y / l) * r),((z / l) * r),S.rand(nil,9,17),((Math_random() < 0.7) and 0 or ((Math_random() < 0.66) and 1 or 2)));
i = i + 1;
end
end;
do return out end;
end;
S.spawnEnemy = function(_this, type_, x, y, z, node)
local d, mesh, hpMul, e;
d = S.ENEMY[type_]; mesh = S.E:getMesh(d.model);
hpMul = (function() if T(d.boss) then return S.R.bossScale else return ((S.R.ch.hp * S.R.secMul) * (T(S.R.endless) and 1 or (1 + (Math_min(S.R.secT,180) / 300)))) end end)();
e = {type=type_,d=d,mesh=mesh,x=x,y=y,z=z,hp=(d.hp * hpMul),max=0,r=Math_max(1.6,((mesh.radius * d.scale) * 0.55)),fire=(function() if T(d.shoot) then return S.rand(nil,1,d.shoot.cd) else return 0 end end)(),flash=0,contact=0,yaw=S.rand(nil,0,360),pitch=0,kx=0,ky=0,kz=0,bob=S.rand(nil,0,6),node=(T(node) and node or nil),summon=(T(d.summon) and d.summon or 0)};
S.clampBound(nil,e,20);
e.max = e.hp;
S.R.enemies:push(e);
if T(d.boss) then
S.R.boss = e;
end;
do return e end;
end;
S.clampBound = function(_this, o, extra)
local l, b;
l = S.len3(nil,o.x,o.y,o.z); b = (S.BOUND + (T(extra) and extra or 0));
if (l > b) then
o.x = (o.x * (b / l));
o.y = (o.y * (b / l));
o.z = (o.z * (b / l));
end;
end;
S.spherePos = function(_this, c, r)
local d;
d = S.randDir(nil);
do return smt({[0]=(c.x + (d[0] * r)),(c.y + (d[1] * r)),(c.z + (d[2] * r)),length=3},AMT) end;
end;
S.aheadPos = function(_this)
local f, d, dir;
f = S.camBasis.f; d = S.randDir(nil);
if (S.dot(nil,d,f) < (-0.2)) then
d = smt({[0]=(-d[0]),(-d[1]),(-d[2]),length=3},AMT);
end;
dir = S.nrm(nil,smt({[0]=(d[0] + (f[0] * 0.8)),(d[1] + (f[1] * 0.8)),(d[2] + (f[2] * 0.8)),length=3},AMT));
do return smt({[0]=(S.R.px + (dir[0] * 55)),(S.R.py + (dir[1] * 55)),(S.R.pz + (dir[2] * 55)),length=3},AMT) end;
end;
S.roamType = function(_this)
local m, k, c, w;
m = S.R.ch.mix:slice(); k = S.R.sector; c = S.R.ch.id;
if T(S.R.endless) then
w = S.R.wave;
m = smt({[0]="crawler","grunt","inter","bomber",length=4},AMT);
if (w >= 2) then
m:push("splitter","guard");
end;
if (w >= 3) then
m:push("sniper");
end;
if (w >= 4) then
m:push("phantom","heavy");
end;
if (w >= 6) then
m:push("guard","sniper","phantom","splitter");
end;
do return S.pick(nil,m) end;
end;
if (k >= 2) then
m:push("bomber");
end;
if (k >= 3) then
m:push("splitter");
end;
if ((c >= 2) or (k >= 4)) then
m:push("guard");
end;
if ((c >= 2) and (k >= 2)) then
m:push("sniper");
end;
if (c >= 3) then
m:push("phantom","phantom","sniper","guard");
end;
do return S.pick(nil,m) end;
end;
S.updateSpawns = function(_this, dt)
local bp, open, cap, rate, bph, ei, eq, elp, w, ebp, wt, pk, room, p, t0, pi;
S.R.secT = (S.R.secT + dt);
if (S.R.bossTimer > 0) then
S.R.bossTimer = (S.R.bossTimer - dt);
if (S.R.bossTimer <= 0) then
bp = S.aheadPos(nil);
S.spawnEnemy(nil,S.R.ch.boss,(bp[0] * 0.7),(bp[1] * 0.7),((bp[2] * 0.7) + 20));
S.R.boss.max = (S.R.boss.hp * 1.35);
S.R.boss.hp = S.R.boss.max;
S.R.phase = "boss";
S.banner(nil,("首领出现：" .. S2(S.R.boss.d.name)));
S.C:sfx("boss");
S.C.music:play("boss");
end;
end;
open = (S.R.gate.state == "open");
cap = Math_round((((((34 + (10 * S.R.sector)) + (8 * S.R.ch.id)) * (T(S.affix(nil,"tide")) and 1.3 or 1)) * S.perfMul(nil)) * (1 + (0.05 * (S.R.danger - 1))))); rate = ((((S.R.phase == "boss") and 0.5 or ((1.3 + (0.3 * S.R.sector)) + Math_min((S.R.secT / 120),1.2))) * (T(S.affix(nil,"tide")) and 1.25 or 1)) * (1 + (0.06 * (S.R.danger - 1))));
if (not T(S.R.endless)) then
cap = Math_min(cap,(Math_round((60 * S.perfMul(nil)))));
end;
if (T(S.R.event) and (S.R.event.state == "active")) then
rate = (rate * 0.55);
end;
if T(S.charging(nil)) then
rate = (rate * 1.5);
end;
if T(open) then
rate = (rate * 0.35);
end;
if (((not T(S.R.endless)) and (S.R.champT > 0)) and (not T(open))) then
S.R.champT = (S.R.champT - dt);
if (S.R.champT <= 0) then
S.spawnChamp(nil);
if (T(S.R.risk) and (not T(S.R.champ2))) then
S.R.champ2 = true;
S.R.champT = S.rand(nil,8,14);
end;
end;
end;
if (((not T(S.R.endless)) and T(S.R.boss)) and (S.R.boss.hp > 0)) then
S.R.escT = (((S.R.escT == nil) and 10 or S.R.escT) - dt);
if (S.R.escT <= 0) then
bph = (T(S.R.boss.ph) and S.R.boss.ph or 1);
S.R.escT = (smt({[0]=12,10,8,length=3},AMT))[(bph - 1)];
do
ei = 0;
while (ei < ((3 + S.R.ch.id) + bph)) do
eq = S.spherePos(nil,S.R.boss,(S.R.boss.r + S.rand(nil,6,12)));
S.spawnEnemy(nil,S.roamType(nil),eq[0],eq[1],eq[2]);
ei = ei + 1;
end
end;
end;
end;
if ((T(S.R.daily) and (S.R.secT >= S.C.DC_TIME)) and (not T(S.R.ended))) then
S.endRun(nil,true,false);
do return end;
end;
if ((T(S.R.daily) and T(S.dmod(nil,"elite"))) and (Math_floor((S.R.secT / 40)) > (T(S.R.eliteN) and S.R.eliteN or 0))) then
S.R.eliteN = Math_floor((S.R.secT / 40));
elp = S.aheadPos(nil);
S.spawnEnemy(nil,"brute",elp[0],elp[1],elp[2]);
S.banner(nil,"精英出现！");
end;
if T(S.R.endless) then
w = (1 + Math_floor((S.R.secT / 45)));
if (w > S.R.wave) then
S.R.wave = w;
S.R.secMul = (1 + (0.12 * (w - 1)));
S.R.dmgMul = (S.R.ch.dmg * (1 + (0.05 * (w - 1))));
S.C:sfx("gate");
if ((MOD(w,5) == 0) and (not T(S.R.boss))) then
ebp = S.aheadPos(nil);
S.R.bossScale = ((1 + (0.12 * (S.R.danger - 1))) * (1 + (0.3 * ((w / 5) - 1))));
S.spawnEnemy(nil,S.R.ch.boss,(ebp[0] * 0.7),(ebp[1] * 0.7),((ebp[2] * 0.7) + 20));
S.R.phase = "boss";
S.banner(nil,((("第 " .. S2(w)) .. " 波首领：") .. S2(S.R.boss.d.name)));
S.C:sfx("boss");
end;
end;
wt = (S.R.secT - ((S.R.wave - 1) * 45));
if ((wt >= 1.5) and (S.R.surgeA ~= S.R.wave)) then
S.R.surgeA = S.R.wave;
S.hordeRing(nil,(12 + (3 * S.R.wave)),true);
end;
if ((wt >= 25) and (S.R.surgeB ~= S.R.wave)) then
S.R.surgeB = S.R.wave;
S.hordeRing(nil,(8 + (2 * S.R.wave)),false);
end;
cap = Math_min(110,(Math_round(((50 + (7 * S.R.wave)) * S.perfMul(nil)))));
rate = (3 + (0.45 * S.R.wave));
end;
S.R.spawnAcc = (S.R.spawnAcc + (dt * rate));
pk = (T(S.R.packN) and S.R.packN or (T(S.R.endless) and 3 or 2));
while (S.R.spawnAcc >= pk) do
S.R.spawnAcc = (S.R.spawnAcc - pk);
room = (cap - LEN((S.R.enemies:filter(function(_this, e)
do return (((not T(e.node)) and (not T(e.d.ore))) and (not T(e.d.boss))) end;
end))));
if (room > 0) then
p = S.aheadPos(nil); t0 = S.roamType(nil);
do
pi = 0;
while (pi < Math_min(pk,room)) do
S.spawnEnemy(nil,(function() if ((pi == 0) or (Math_random() < 0.7)) then return t0 else return S.roamType(nil) end end)(),(p[0] + S.rand(nil,(-4),4)),(p[1] + S.rand(nil,(-4),4)),(p[2] + S.rand(nil,(-4),4)));
pi = pi + 1;
end
end;
end;
S.R.packN = (function() if T(S.R.endless) then return (3 + Math_floor((Math_random() * 4))) else return (2 + Math_floor((Math_random() * 3))) end end)();
pk = S.R.packN;
end;
end;
S.hordeRing = function(_this, n, ann)
local t, a0, i, a, r, e;
n = Math_min(Math_round((n * S.perfMul(nil))),(Math_max(0,(140 - LEN(S.R.enemies)))));
if (n <= 0) then
do return end;
end;
t = (((S.R.wave >= 3) and (Math_random() < 0.4)) and "splitter" or "crawler"); a0 = ((Math_random() * Math_PI) * 2);
do
i = 0;
while (i < n) do
a = (a0 + (((i / n) * Math_PI) * 2)); r = S.rand(nil,30,40); e = S.spawnEnemy(nil,(((MOD(i,5) == 4) and (S.R.wave >= 2)) and "bomber" or t),(S.R.px + (Math_cos(a) * r)),(S.R.py + S.rand(nil,(-8),8)),(S.R.pz + (Math_sin(a) * r)));
e.max = (e.hp * 0.7);
e.hp = e.max;
e.fodder = true;
i = i + 1;
end
end;
if (T(ann) and (S.R.phase ~= "boss")) then
S.banner(nil,(("第 " .. S2(S.R.wave)) .. " 波：怪潮来袭！"));
elseif T(ann) then
S.A:toast("怪潮来袭！");
end;
end;
S.key = function(_this, x, y, z)
do return ((((S2(Math_floor((x / S.CELL))) .. ",") .. S2(Math_floor((y / S.CELL)))) .. ",") .. S2(Math_floor((z / S.CELL)))) end;
end;
S.buildGrid = function(_this)
S.grid = JS.dict();
S.R.enemies:forEach(function(_this, e)
local k;
k = S.key(nil,e.x,e.y,e.z);
;((T(S.grid[k]) and S.grid[k] or (function() S.grid[k] = smt({length=0},AMT); return S.grid[k] end)())):push(e);
end);
end;
S.near = function(_this, x, y, z, r, fn)
local x0, x1, y0, y1, z0, z1, a, b, c, l, i;
x0 = Math_floor(((x - r) / S.CELL)); x1 = Math_floor(((x + r) / S.CELL)); y0 = Math_floor(((y - r) / S.CELL)); y1 = Math_floor(((y + r) / S.CELL)); z0 = Math_floor(((z - r) / S.CELL)); z1 = Math_floor(((z + r) / S.CELL));
do
a = x0;
while (a <= x1) do
do
b = y0;
while (b <= y1) do
do
c = z0;
while (c <= z1) do
do
l = S.grid[((((S2(a) .. ",") .. S2(b)) .. ",") .. S2(c))];
if (not T(l)) then
goto cont18;
end;
do
i = 0;
while (i < LEN(l)) do
if (fn(nil,l[i]) == false) then
do return end;
end;
i = i + 1;
end
end;
end
::cont18::
c = c + 1;
end
end;
b = b + 1;
end
end;
a = a + 1;
end
end;
end;
S.target = function(_this, x, y, z, maxR)
local best, bd, ore, od;
best = nil; bd = (maxR * maxR); ore = nil; od = (maxR * maxR);
S.R.enemies:forEach(function(_this, e)
local d;
if (e.hp <= 0) then
do return end;
end;
d = S.d3(nil,x,y,z,e.x,e.y,e.z);
if T(e.d.ore) then
if (d < od) then
od = d;
ore = e;
end;
elseif (d < bd) then
bd = d;
best = e;
end;
end);
if ((T(ore) and T(best)) and (od < (bd * 0.45))) then
do return ore end;
end;
do return (T(best) and best or ore) end;
end;
S.hurtEnemy = function(_this, e, dmg, kx, ky, kz, noNum, extraCrit, col)
local crit, gf, gp, m, bigE;
if (e.hp <= 0) then
do return end;
end;
crit = (Math_random() < (((0.08 + S.fx(nil,"crit")) + S.R.st.crit) + (T(extraCrit) and extraCrit or 0)));
if T(e.d.guard) then
gf = S.fwdOf(nil,e.yaw,0); gp = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT));
if (((gf[0] * gp[0]) + (gf[2] * gp[2])) > 0.35) then
dmg = (dmg * 0.2);
crit = false;
if ((not T(noNum)) and (LEN(S.R.nums) < 70)) then
S.R.nums:push({x=e.x,y=(e.y + (e.r * 1.2)),z=e.z,v="格挡",crit=false,col="#5CF2DC",life=0.5});
end;
if (LEN(S.R.parts) < 220) then
S.sparks(nil,e.x,e.y,e.z,"fx_spark_teal",2,8,0.2);
end;
end;
end;
dmg = (dmg * ((S.dmgMult(nil) * (function() if T(crit) then return (2 + S.R.st.critDmg) else return 1 end end)()) * (function() if (T(e.d.elite) or T(e.d.boss)) then return (1 + S.R.st.elite) else return 1 end end)()));
if T(e.d.ore) then
dmg = (dmg * (1 + S.fx(nil,"loot")));
end;
e.hp = (e.hp - dmg);
e.flash = (T(e.d.boss) and 0 or 0.06);
S.R.dmgDealt = ((T(S.R.dmgDealt) and S.R.dmgDealt or 0) + Math_min(dmg,(e.hp + dmg)));
if (((T(kx) or T(ky)) or T(kz)) and (not T(e.d.ore))) then
m = (T(e.d.boss) and 0.04 or (T(e.d.elite) and 0.25 or 1));
e.kx = (e.kx + (kx * m));
e.ky = (e.ky + (ky * m));
e.kz = (e.kz + (kz * m));
end;
if ((not T(noNum)) and (LEN(S.R.nums) < 70)) then
S.R.nums:push({x=e.x,y=(e.y + (e.r * 1.2)),z=e.z,v=Math_round(dmg),crit=crit,col=col,life=0.7});
end;
if ((not T(noNum)) and (not T(e.d.ore))) then
bigE = (T(e.d.elite) and e.d.elite or e.d.boss);
if (LEN(S.R.parts) < 200) then
S.sparks(nil,e.x,e.y,e.z,"fx_spark",(T(crit) and 4 or 1),(T(crit) and 12 or 8),0.22,nil,(T(crit) and 1 or 0.7));
end;
if (T(e.d.elite) and (not T(e.d.boss))) then
S.R.shake = Math_max(S.R.shake,(T(crit) and 0.05 or 0.02));
if T(crit) then
S.R.hitstop = Math_max((T(S.R.hitstop) and S.R.hitstop or 0),0.03);
end;
end;
if ((not T(e.d.boss)) or T(crit)) then
S.C:sfx((T(crit) and "crit" or "hit"));
end;
end;
if (e.hp <= 0) then
S.killEnemy(nil,e);
end;
end;
S.knock = function(_this, e, from, power)
local v;
v = S.nrm(nil,smt({[0]=(e.x - from.x),(e.y - from.y),(e.z - from.z),length=3},AMT));
do return smt({[0]=(v[0] * power),(v[1] * power),(v[2] * power),length=3},AMT) end;
end;
S.addCredits = function(_this, n)
S.R.credits = (S.R.credits + Math_round((n * (1 + S.R.st.credit))));
end;
S.killEnemy = function(_this, e)
local si, sp2, big, xp, v;
if (not T(e.d.ore)) then
S.R.kills = S.R.kills + 1;
S.R.secKills = ((T(S.R.secKills) and S.R.secKills or 0) + 1);
S.R.combo = (function() if (S.R.comboT > 0) then return (S.R.combo + 1) else return 1 end end)();
S.R.comboT = 2.5;
S.R.bestCombo = Math_max((T(S.R.bestCombo) and S.R.bestCombo or 0),S.R.combo);
if (((S.R.combo == 30) or (S.R.combo == 60)) or (S.R.combo == 100)) then
S.R.feverK = ((S.R.combo >= 100) and 0.5 or ((S.R.combo >= 60) and 0.35 or 0.2));
S.R.feverT = 6;
S.A:toast((((S2(S.R.combo) .. " 连击！狂热：主武器射速 +") .. S2(Math_round((S.R.feverK * 100)))) .. "%（6 秒）"));
S.C:sfx("skill");
end;
end;
if (T(e.d.split) and (not T(e.noSplit))) then
do
si = 0;
while (si < e.d.split) do
sp2 = S.spherePos(nil,e,(e.r + 1));
S.spawnEnemy(nil,"crawler",sp2[0],sp2[1],sp2[2],e.node);
si = si + 1;
end
end;
end;
big = (T(e.d.elite) and e.d.elite or e.d.boss);
if T(big) then
S.R.hitstop = Math_max((T(S.R.hitstop) and S.R.hitstop or 0),(T(e.d.boss) and 0.18 or 0.1));
end;
if T(e.d.boss) then
S.R.slowT = 1.2;
end;
S.sparks(nil,e.x,e.y,e.z,(T(e.d.ore) and "fx_debris" or "fx_spark"),(T(big) and 60 or 10),(T(big) and 30 or 14),0.8);
S.sparks(nil,e.x,e.y,e.z,"fx_debris",(T(big) and 30 or 5),12,1.4);
S.addCredits(nil,(((e.d.cr * (T(e.d.ore) and 1 or S.R.ch.hp)) * (T(e.d.ore) and 1 or (T(S.R.endless) and 0.6 or 0.6))) * (T(e.fodder) and 0.5 or 1)));
xp = ((T(e.fodder) and (Math_random() > 0.45)) and 0 or e.d.xp);
while (xp > 0) do
v = ((xp >= 10) and 10 or ((xp >= 5) and 5 or 1));
xp = (xp - v);
S.R.gems:push({x=(e.x + S.rand(nil,(-1.5),1.5)),y=(e.y + S.rand(nil,(-1.5),1.5)),z=(e.z + S.rand(nil,(-1.5),1.5)),v=v});
end;
if (((((not T(big)) and (not T(e.d.ore))) and (Math_random() < Math_min(0.05,(0.01 + S.R.st.luck)))) and ((S.R.t - (T(S.R.lastHeal) and S.R.lastHeal or (-99))) > 5)) and (LEN((S.R.pickups:filter(function(_this, p)
do return (p.kind == "heal") end;
end))) < 3)) then
S.R.lastHeal = S.R.t;
S.R.pickups:push({kind="heal",x=e.x,y=e.y,z=e.z});
end;
if (((T(S.R.sub) and (not T(e.d.ore))) and (T(big) or (Math_random() < 0.006))) and (LEN((S.R.pickups:filter(function(_this, p)
do return (p.kind == "ammo") end;
end))) < 4)) then
S.R.pickups:push({kind="ammo",x=e.x,y=e.y,z=e.z,n=(T(e.d.boss) and 6 or (T(big) and 3 or 2))});
end;
if (S.R.target == e) then
S.R.target = nil;
end;
if T(e.d.elite) then
S.R.shake = 0.4;
end;
if (T(e.d.elite) and T(S.dmod(nil,"elite"))) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.1)));
end;
if T(e.d.champ) then
S.R.pickups:push({kind="chest",x=e.x,y=e.y,z=e.z,cr=(60 * S.R.ch.id),lvl=1});
S.banner(nil,(S2(e.d.name) .. " 被击败！战利品已掉落"));
end;
if (T(e.d.boss) and T(S.R.endless)) then
S.R.bossKilled = ((T(S.R.bossKilled) and S.R.bossKilled or 0) + 1);
S.R.shake = 0.8;
S.R.src = (S.R.src + 3);
S.R.boss = nil;
S.R.phase = "explore";
S.banner(nil,(S2(e.d.name) .. " 被击败！星源 +3"));
S.C:sfx("win");
elseif T(e.d.boss) then
S.R.won = true;
S.R.shake = 1.2;
S.R.src = (S.R.src + 5);
S.banner(nil,(S2(e.d.name) .. " 被击败！"));
S.C:sfx("win");
HOST.setTimeout(nil,function(_this)
S.endRun(nil,true);
end,2200);
elseif T(big) then
S.C:sfx("boom");
elseif (Math_random() < 0.35) then
S.C:sfx("pop");
end;
end;
S.sparks = function(_this, x, y, z, model, n, spd, life, tint, sz)
local i, d, s;
do
i = 0;
while ((i < n) and (LEN(S.R.parts) < (260 * S.perfMul(nil)))) do
d = S.randDir(nil); s = (S.rand(nil,0.3,1) * spd);
S.R.parts:push({model=model,x=x,y=y,z=z,vx=(d[0] * s),vy=(d[1] * s),vz=(d[2] * s),life=(life * S.rand(nil,0.6,1.2)),max=life,size=(S.rand(nil,1.5,3) * (T(sz) and sz or 1)),tint=tint});
i = i + 1;
end
end;
end;
S.hotRamp = function(_this, t, k)
local q;
if (k > 0.7) then
do return S.HOT end;
end;
q = (0.3 + (0.7 * (k / 0.7)));
do return smt({[0]=(t[0] * q),((t[1] * q) * q),((t[2] * q) * q),length=3},AMT) end;
end;
S.emb = function(_this, x, y, z, tint, n, spd, life, size, up)
local i, d, s;
do
i = 0;
while ((i < n) and (LEN(S.R.parts) < (250 * S.perfMul(nil)))) do
d = S.randDir(nil); s = (S.rand(nil,0.4,1) * spd);
S.R.parts:push({model="fx_white",x=x,y=y,z=z,vx=(d[0] * s),vy=((d[1] * s) + (T(up) and up or 0)),vz=(d[2] * s),life=(life * S.rand(nil,0.7,1.2)),max=life,size=(size * S.rand(nil,0.7,1.2)),tint=(T(tint) and tint or S.EMBER),hot=true,noGrav=true});
i = i + 1;
end
end;
end;
S.ringBurst = function(_this, x, y, z, r, tint, dur)
if (LEN(S.R.novas) < 12) then
S.R.novas:push({x=x,y=(y + 1),z=z,r=r,life=dur,dur=dur,tint=tint,fast=true});
end;
end;
S.trail = function(_this, x, y, z, tint, size, life, et)
if (LEN(S.R.parts) < (200 * S.perfMul(nil))) then
S.R.parts:push({et=(T(et) and et or 0),model="fx_white",x=(x + S.rand(nil,(-0.15),0.15)),y=(y + S.rand(nil,(-0.15),0.15)),z=(z + S.rand(nil,(-0.15),0.15)),vx=S.rand(nil,(-1),1),vy=S.rand(nil,(-1),1),vz=S.rand(nil,(-1),1),life=life,max=life,size=size,tint=tint,hot=true,noGrav=true});
end;
end;
S.banner = function(_this, msg)
S.R.banner = msg;
S.R.bannerT = 3;
end;
S.hurtPlayer = function(_this, dmg)
local f;
if T(S.affix(nil,"fury")) then
dmg = (dmg * 1.25);
end;
if ((T(S.R.god) and (S.R.iframe <= 0)) and (not (T(S.R.dash) and T(S.R.dash.inv)))) then
S.R.dmgTaken = ((T(S.R.dmgTaken) and S.R.dmgTaken or 0) + ((dmg * S.R.dmgMul) * (1 - S.R.st.armor)));
S.R.iframe = 0.4;
end;
if (((((S.R.iframe > 0) or T(S.R.god)) or T(S.R.over)) or T(S.R.won)) or (T(S.R.dash) and T(S.R.dash.inv))) then
do return end;
end;
S.R.dmgTaken = ((T(S.R.dmgTaken) and S.R.dmgTaken or 0) + ((dmg * S.R.dmgMul) * (1 - S.R.st.armor)));
S.R.hull = (S.R.hull - ((dmg * S.R.dmgMul) * (1 - S.R.st.armor)));
S.R.iframe = 0.4;
S.C:sfx("hurt");
S.R.hitstop = Math_max((T(S.R.hitstop) and S.R.hitstop or 0),0.05);
if T(S.R.pose) then
S.R.pose.hit = 1;
S.R.pose.hitFlash = 0.09;
end;
S.R.shake = Math_max(S.R.shake,0.25);
f = HOST.document:getElementById("hitflash");
if T(f) then
f.style.opacity = ((T(S.C.save.settings) and (S.C.save.settings.fx == "soft")) and 0.2 or 0.4);
HOST.setTimeout(nil,function(_this)
f.style.opacity = 0;
end,120);
end;
if (S.R.hull <= 0) then
S.R.hull = 0;
S.onDeath(nil);
end;
end;
S.onDeath = function(_this)
if (T(S.R.st.traits.revive) and (not T(S.R.revived))) then
S.R.revived = true;
S.R.hull = (S.hullMax(nil) * 0.4);
S.R.iframe = 2;
S.nova(nil,S.P(nil),14,60,"#5CF2DC");
S.banner(nil,"星魂庇护：复活！");
do return end;
end;
S.R.over = true;
S.sparks(nil,S.R.px,S.R.py,S.R.pz,"fx_spark",80,30,1.2);
HOST.setTimeout(nil,S.openRevive,1100);
end;
S.bossPhase = function(_this, e)
local n, i, p;
S.banner(nil,(((S2(e.d.name) .. " 进入第 ") .. S2(e.ph)) .. " 阶段！"));
S.C:sfx("boss");
S.R.shake = Math_max(S.R.shake,0.7);
e.fire = 1.6;
e.laser = nil;
S.R.novas:push({x=e.x,y=e.y,z=e.z,r=(e.r * 3.2),life=0.6,dur=0.6,tint=smt({[0]=1.5,0.2,0.28,length=3},AMT),fast=true});
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.5,0.3,0.3,length=3},AMT),24,18,0.7,2.4);
n = ((e.ph == 2) and 6 or 8);
do
i = 0;
while (i < n) do
p = S.spherePos(nil,e,(e.r + 5));
S.spawnEnemy(nil,((MOD(i,3) == 0) and "inter" or "crawler"),p[0],p[1],p[2]);
i = i + 1;
end
end;
end;
S.updateEnemies = function(_this, dt)
local pod;
S.buildGrid(nil);
pod = (S.R.nodes:filter(function(_this, n)
do return ((n.type == "distress") and (n.state == "active")) end;
end))[0];
S.R.enemies:forEach(function(_this, e)
local d, hk, hp2, tx, ty, tz, dx, dy, dz, dist, n, mv, tg0, ks, SN, ks2, BB, BL, fw0, bd, lunging, LG, sx, sy, sz, spd, sk, sl2, damp, ang, kr, pd, ph0, pm, SL, rb, rk, ra, ba2, Ls, wd, kk3, lo, lw, lt, aim, b2, k2, sp, mo0, q9, rn, a, ca, sa, rv, na, o, nn, off, v, p, q;
d = e.d;
if (e.hp <= 0) then
do return end;
end;
e.flash = (e.flash - dt);
if T(d.ore) then
do return end;
end;
if (T(e.burn) and (e.burn.t > 0)) then
e.burn.t = (e.burn.t - dt);
e.hp = (e.hp - (e.burn.dps * dt));
end;
if (T(e.poison) and (e.poison.t > 0)) then
e.poison.t = (e.poison.t - dt);
e.hp = (e.hp - (e.poison.dps * dt));
end;
if (e.hp <= 0) then
e.hp = 0.0001;
S.hurtEnemy(nil,e,1,0,0,0,true);
do return end;
end;
if (e.slowT > 0) then
e.slowT = (e.slowT - dt);
end;
if (e.dmark > 0) then
e.dmark = (e.dmark - dt);
end;
if (e.lmark > 0) then
e.lmark = (e.lmark - dt);
end;
if (e.shock > 0) then
e.shock = (e.shock - dt);
end;
if (e.rcd > 0) then
e.rcd = (e.rcd - dt);
end;
if (e.stunT > 0) then
e.stunT = (e.stunT - dt);
if (Math_random() < 0.2) then
S.sparks(nil,e.x,(e.y + e.r),e.z,"fx_spark",1,4,0.25);
end;
do return end;
end;
if T(d.hive) then
e.hcd = ((function() if (e.hcd == nil) then return S.rand(nil,1.5,3) else return e.hcd end end)() - dt);
if ((e.hcd < 0.8) and (Math_random() < 0.3)) then
S.sparks(nil,e.x,(e.y + (e.r * 0.5)),e.z,"fx_spark",1,6,0.3,smt({[0]=0.8,0.45,1.4,length=3},AMT));
end;
if (e.hcd <= 0) then
e.hcd = d.hive.cd;
do
hk = 0;
while (hk < (d.hive.n + ((S.R.ch.id >= 3) and 1 or 0))) do
hp2 = S.spherePos(nil,e,(e.r + 2));
S.spawnEnemy(nil,(function() if ((S.R.ch.id >= 2) and (hk == 0)) then return S.pick(nil,smt({[0]="bomber","splitter",length=2},AMT)) else return "crawler" end end)(),hp2[0],hp2[1],hp2[2]);
hk = hk + 1;
end
end;
S.emb(nil,e.x,e.y,e.z,smt({[0]=0.8,0.45,1.4,length=3},AMT),8,8,0.5,2);
end;
do return end;
end;
if ((T(e.rageAt) and (not T(e.rage))) and (e.hp < (e.max * e.rageAt))) then
e.rage = true;
S.banner(nil,(S2(d.name) .. " 狂暴了！移动与砸地更快"));
S.C:sfx("boss");
S.R.shake = Math_max(S.R.shake,0.4);
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.5,0.3,0.25,length=3},AMT),20,14,0.6,2.4);
end;
tx = S.R.px; ty = S.R.py; tz = S.R.pz;
if (T(e.podHunter) and T(pod)) then
tx = pod.x;
ty = pod.y;
tz = pod.z;
end;
dx = (tx - e.x); dy = (ty - e.y); dz = (tz - e.z); dist = (function() local _t = S.len3(nil,dx,dy,dz); if T(_t) then return _t end; return 1 end)(); n = smt({[0]=(dx / dist),(dy / dist),(dz / dist),length=3},AMT); mv = n;
if ((T(d.keep) and (dist < d.keep)) and (not T(e.podHunter))) then
if (not T(e.orb)) then
e.orb = ((Math_random() < 0.5) and 1 or (-1));
end;
tg0 = ((Math_abs(n[1]) > 0.92) and smt({[0]=1,0,0,length=3},AMT) or S.nrm(nil,(S.cross(nil,smt({[0]=0,1,0,length=3},AMT),n))));
mv = S.nrm(nil,smt({[0]=(((tg0[0] * 0.9) * e.orb) - (n[0] * 0.3)),(((tg0[1] * 0.9) * e.orb) - (n[1] * 0.3)),(((tg0[2] * 0.9) * e.orb) - (n[2] * 0.3)),length=3},AMT));
end;
if (T(e.dv) and (not (T(e.lg) and (e.lg.t >= (function() if T(d.lunge) then return d.lunge.tele else return 0 end end)())))) then
ks = (1 - Math_exp(((-dt) * 9)));
mv = smt({[0]=S.lerp(nil,e.dv[0],mv[0],ks),S.lerp(nil,e.dv[1],mv[1],ks),(S.lerp(nil,e.dv[2],mv[2],ks)),length=3},AMT);
end;
e.dv = mv:slice();
if T(d.snipe) then
SN = d.snipe;
e.sncd = ((function() if (e.sncd == nil) then return S.rand(nil,1.5,SN.cd) else return e.sncd end end)() - dt);
if (((not T(e.sn)) and (e.sncd <= 0)) and (dist < 75)) then
e.sn = {t=0,dir=n:slice(),fired=false};
e.sncd = SN.cd;
end;
if T(e.sn) then
e.sn.t = (e.sn.t + dt);
mv = smt({[0]=0,0,0,length=3},AMT);
if (e.sn.t < (SN.tele * 0.75)) then
ks2 = Math_min(1,(dt * 4));
e.sn.dir = S.nrm(nil,smt({[0]=S.lerp(nil,e.sn.dir[0],n[0],ks2),S.lerp(nil,e.sn.dir[1],n[1],ks2),(S.lerp(nil,e.sn.dir[2],n[2],ks2)),length=3},AMT));
elseif ((e.sn.t >= SN.tele) and (not T(e.sn.fired))) then
e.sn.fired = true;
S.C:sfx("boom");
S.R.ebullets:push({x=(e.x + (e.sn.dir[0] * e.r)),y=(e.y + (e.sn.dir[1] * e.r)),z=(e.z + (e.sn.dir[2] * e.r)),vx=(e.sn.dir[0] * SN.spd),vy=(e.sn.dir[1] * SN.spd),vz=(e.sn.dir[2] * SN.spd),dmg=SN.dmg,life=2,snipe=true});
end;
if (e.sn.t >= (SN.tele + 0.3)) then
e.sn = nil;
end;
end;
end;
if T(d.bomb) then
BB = d.bomb;
if ((not T(e.fz)) and (dist < BB.trig)) then
e.fz = 0.0001;
S.C:sfx("click");
end;
if T(e.fz) then
e.fz = (e.fz + dt);
mv = smt({[0]=0,0,0,length=3},AMT);
if (e.fz >= BB.fuse) then
S.R.novas:push({x=e.x,y=e.y,z=e.z,r=BB.r,life=0.4,dur=0.4,tint=smt({[0]=1.5,0.6,0.2,length=3},AMT),fast=true});
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.5,0.6,0.2,length=3},AMT),14,12,0.5,2);
S.C:sfx("boom");
S.R.shake = Math_max(S.R.shake,0.2);
if (S.d3(nil,S.R.px,S.R.py,S.R.pz,e.x,e.y,e.z) < ((BB.r + 1.5) * (BB.r + 1.5))) then
S.hurtPlayer(nil,((d.dmg * BB.dmg) * (T(e.fodder) and 0.6 or 1)));
end;
e.hp = 0;
S.killEnemy(nil,e);
do return end;
end;
end;
end;
if T(d.blink) then
BL = d.blink;
e.bkcd = ((function() if (e.bkcd == nil) then return S.rand(nil,2,BL.cd) else return e.bkcd end end)() - dt);
if ((((not T(e.bk)) and (e.bkcd <= 0)) and (dist > 8)) and (dist < 60)) then
fw0 = S.fwdOf(nil,S.R.yaw,0);
e.bk = {t=0,dest=smt({[0]=(S.R.px - (fw0[0] * 11)),(S.R.py + S.rand(nil,(-2),2)),(S.R.pz - (fw0[2] * 11)),length=3},AMT)};
e.bkcd = BL.cd;
end;
if T(e.bk) then
e.bk.t = (e.bk.t + dt);
mv = smt({[0]=0,0,0,length=3},AMT);
if (e.bk.t >= BL.tele) then
S.emb(nil,e.x,e.y,e.z,smt({[0]=0.7,0.4,1.4,length=3},AMT),8,8,0.4,1.8);
e.x = e.bk.dest[0];
e.y = e.bk.dest[1];
e.z = e.bk.dest[2];
S.emb(nil,e.x,e.y,e.z,smt({[0]=0.7,0.4,1.4,length=3},AMT),8,8,0.4,1.8);
bd = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT));
e.lg = {t=0,dir=bd};
e.lcool = (function() if T(d.lunge) then return d.lunge.cd else return 5 end end)();
e.bk = nil;
end;
end;
end;
lunging = false;
if T(d.lunge) then
LG = d.lunge;
e.lcool = ((function() if (e.lcool == nil) then return S.rand(nil,0.4,1.4) else return e.lcool end end)() - dt);
if (((((not T(e.lg)) and (e.lcool <= 0)) and (dist < LG.range)) and (dist > 2.5)) and (not T(e.podHunter))) then
e.lg = {t=0,dir=n:slice()};
e.lcool = LG.cd;
end;
if T(e.lg) then
e.lg.t = (e.lg.t + dt);
if (e.lg.t < LG.tele) then
mv = smt({[0]=0,0,0,length=3},AMT);
elseif (e.lg.t < (LG.tele + LG.dur)) then
mv = e.lg.dir;
lunging = true;
else
e.lg = nil;
end;
end;
end;
sx = 0; sy = 0; sz = 0;
S.near(nil,e.x,e.y,e.z,(e.r * 2),function(_this, o)
local ox, oy, oz, od, min, k;
if ((o == e) or T(o.d.ore)) then
do return end;
end;
ox = (e.x - o.x); oy = (e.y - o.y); oz = (e.z - o.z); od = S.len3(nil,ox,oy,oz); min = (e.r + o.r);
if ((od < min) and (od > 0.001)) then
k = ((min - od) / od);
sx = (sx + (ox * k));
sy = (sy + (oy * k));
sz = (sz + (oz * k));
end;
end);
spd = ((((function() if T(lunging) then return d.lunge.dash else return d.spd end end)() * ((T(e.slow) or (e.slowT > 0)) and 0.45 or 1)) * (T(S.affix(nil,"swift")) and 1.25 or 1)) * (T(e.rage) and 1.3 or 1));
sk = Math_min(0.5,(dt * 14)); sl2 = S.len3(nil,sx,sy,sz);
if (sl2 > 1.2) then
sx = (sx * (1.2 / sl2));
sy = (sy * (1.2 / sl2));
sz = (sz * (1.2 / sl2));
end;
e.x = (e.x + ((((mv[0] * spd) + e.kx) * dt) + (sx * sk)));
e.y = (e.y + ((((mv[1] * spd) + e.ky) * dt) + (sy * sk)));
e.z = (e.z + ((((mv[2] * spd) + e.kz) * dt) + (sz * sk)));
S.clampBound(nil,e,20);
damp = Math_exp(((-dt) * 6));
e.kx = (e.kx * damp);
e.ky = (e.ky * damp);
e.kz = (e.kz * damp);
e.slow = false;
ang = S.angOf(nil,(function() if (S.len3(nil,mv[0],mv[1],mv[2]) > 0.1) then return mv else return n end end)()); kr = (1 - Math_exp(((-dt) * 10)));
e.yaw = (e.yaw + (S.wrapA(nil,(ang[0] - e.yaw)) * (function() if T(d.guard) then return (1 - Math_exp(((-dt) * 2.2))) else return kr end end)()));
e.pitch = (e.pitch + (((function() if T(d.ship) then return ang[1] else return S.clamp(nil,ang[1],(-30),30) end end)() - e.pitch) * kr));
e.contact = (e.contact - dt);
pd = Math_sqrt((S.d3(nil,S.R.px,S.R.py,S.R.pz,e.x,e.y,e.z)));
if ((pd < (e.r + 2.3)) and (e.contact <= 0)) then
S.hurtPlayer(nil,((d.dmg * (T(lunging) and 1.6 or 1)) * (T(e.fodder) and 0.6 or 1)));
e.contact = 0.8;
end;
if (((T(e.podHunter) and T(pod)) and (dist < (e.r + 3))) and (e.contact <= 0)) then
pod.pod.hp = (pod.pod.hp - d.dmg);
e.contact = 0.8;
end;
if T(d.boss) then
ph0 = (((e.hp / e.max) > 0.66) and 1 or (((e.hp / e.max) > 0.33) and 2 or 3));
if (not T(e.ph)) then
e.ph = 1;
end;
if (ph0 > e.ph) then
e.ph = ph0;
S.bossPhase(nil,e);
end;
end;
pm = (T(e.ph) and e.ph or 1);
if T(d.slam) then
SL = d.slam;
e.scd = ((function() if (e.scd == nil) then return (SL.cd * 0.6) else return e.scd end end)() - dt);
if (((not T(e.sl)) and (e.scd <= 0)) and (dist < (SL.r * 1.9))) then
e.sl = {t=0};
e.scd = ((SL.cd * ((T(d.boss) and (pm >= 3)) and 0.7 or 1)) * (T(e.rage) and 0.75 or 1));
end;
if T(e.sl) then
e.sl.t = (e.sl.t + dt);
if (e.sl.t >= SL.tele) then
e.sl = nil;
S.R.shake = Math_max(S.R.shake,0.5);
S.C:sfx("boom");
S.R.novas:push({x=e.x,y=(e.y - (e.r * 0.5)),z=e.z,r=SL.r,life=0.5,dur=0.5,tint=smt({[0]=1.5,0.6,0.2,length=3},AMT),fast=true});
S.emb(nil,e.x,(e.y - (e.r * 0.5)),e.z,smt({[0]=1.4,0.6,0.25,length=3},AMT),20,14,0.6,2.2,3);
if (S.d3(nil,S.R.px,S.R.py,S.R.pz,e.x,e.y,e.z) < ((SL.r + 1.5) * (SL.r + 1.5))) then
S.hurtPlayer(nil,(d.dmg * SL.dmg));
end;
if T(SL.ring) then
rb = S.basis(nil,smt({[0]=0,1,0,length=3},AMT));
do
rk = 0;
while (rk < (14 + (4 * (pm - 1)))) do
ra = (((rk / (14 + (4 * (pm - 1)))) * Math_PI) * 2);
S.R.ebullets:push({x=e.x,y=e.y,z=e.z,vx=(Math_cos(ra) * 13),vy=0,vz=(Math_sin(ra) * 13),dmg=(d.dmg * 0.5),life=4});
rk = rk + 1;
end
end;
end;
end;
end;
end;
if (e.bq > 0) then
e.bt = (e.bt - dt);
if (e.bt <= 0) then
e.bq = e.bq - 1;
e.bt = 0.13;
ba2 = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT));
S.R.ebullets:push({x=(e.x + ((ba2[0] * e.r) * 0.9)),y=(e.y + ((ba2[1] * e.r) * 0.9)),z=(e.z + ((ba2[2] * e.r) * 0.9)),vx=(ba2[0] * d.shoot.spd),vy=(ba2[1] * d.shoot.spd),vz=(ba2[2] * d.shoot.spd),dmg=d.shoot.dmg,life=4});
end;
end;
if ((T(d.laser) and (pm >= d.laser.from)) and (pd < 75)) then
e.lcd = ((function() if (e.lcd == nil) then return (d.laser.every * 0.55) else return e.lcd end end)() - dt);
if ((not T(e.laser)) and (e.lcd <= 0)) then
e.lcd = (d.laser.every * ((pm >= 3) and 0.7 or 1));
e.laser = {t=0,charge=1.2,fire=0.45,dir=S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT)),hit=false};
S.C:sfx("boss");
end;
end;
if T(e.laser) then
Ls = e.laser;
Ls.t = (Ls.t + dt);
if (Ls.t < (Ls.charge * 0.7)) then
wd = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT)); kk3 = Math_min(1,(dt * 3));
Ls.dir = S.nrm(nil,smt({[0]=S.lerp(nil,Ls.dir[0],wd[0],kk3),S.lerp(nil,Ls.dir[1],wd[1],kk3),(S.lerp(nil,Ls.dir[2],wd[2],kk3)),length=3},AMT));
elseif ((Ls.t >= Ls.charge) and (not T(Ls.hit))) then
Ls.hit = true;
S.R.shake = Math_max(S.R.shake,0.3);
lo = smt({[0]=(e.x + (Ls.dir[0] * e.r)),(e.y + (Ls.dir[1] * e.r)),(e.z + (Ls.dir[2] * e.r)),length=3},AMT); lw = smt({[0]=(S.R.px - lo[0]),(S.R.py - lo[1]),(S.R.pz - lo[2]),length=3},AMT); lt = (((lw[0] * Ls.dir[0]) + (lw[1] * Ls.dir[1])) + (lw[2] * Ls.dir[2]));
if (((lt > 0) and (lt < 95)) and (S.len3(nil,(lw[0] - (Ls.dir[0] * lt)),(lw[1] - (Ls.dir[1] * lt)),(lw[2] - (Ls.dir[2] * lt))) < 2.8)) then
S.hurtPlayer(nil,(d.dmg * 1.5));
end;
end;
if (Ls.t >= (Ls.charge + Ls.fire)) then
e.laser = nil;
end;
end;
if (T(d.shoot) and (pd < 60)) then
e.fire = (e.fire - dt);
if (e.fire <= 0) then
e.fire = (d.shoot.cd * (function() if T(d.boss) then return (smt({[0]=1,0.82,0.66,length=3},AMT))[(pm - 1)] else return 1 end end)());
aim = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT)); b2 = S.basis(nil,aim); sp = (d.shoot.spd * (function() if T(d.boss) then return (1 + (0.08 * (pm - 1))) else return 1 end end)()); mo0 = smt({[0]=(e.x + ((aim[0] * e.r) * 0.9)),(e.y + ((aim[1] * e.r) * 0.9)),(e.z + ((aim[2] * e.r) * 0.9)),length=3},AMT);
S.sparks(nil,mo0[0],mo0[1],mo0[2],"fx_spark",3,6,0.2,nil,0.8);
do
q9 = Math_max(0,(LEN(S.R.parts) - 3));
while (q9 < LEN(S.R.parts)) do
S.R.parts[q9].et = 2;
q9 = q9 + 1;
end
end;
if T(d.shoot.ring) then
rn = (d.shoot.ring + (function() if T(d.boss) then return (4 * (pm - 1)) else return 0 end end)());
do
k2 = 0;
while (k2 < rn) do
a = ((((k2 / rn) * Math_PI) * 2) + S.R.t); ca = Math_cos(a); sa = Math_sin(a);
rv = smt({[0]=((b2[0][0] * ca) + (b2[1][0] * sa)),((b2[0][1] * ca) + (b2[1][1] * sa)),((b2[0][2] * ca) + (b2[1][2] * sa)),length=3},AMT);
S.R.ebullets:push({x=e.x,y=e.y,z=e.z,vx=(rv[0] * sp),vy=(rv[1] * sp),vz=(rv[2] * sp),dmg=d.shoot.dmg,life=5});
k2 = k2 + 1;
end
end;
na = (T(d.shoot.aim) and d.shoot.aim or 0);
do
k2 = 0;
while (k2 < na) do
o = ((k2 - ((na - 1) / 2)) * 0.12);
S.R.ebullets:push({x=mo0[0],y=mo0[1],z=mo0[2],vx=(((aim[0] + (b2[0][0] * o)) * sp) * 1.4),vy=(((aim[1] + (b2[0][1] * o)) * sp) * 1.4),vz=(((aim[2] + (b2[0][2] * o)) * sp) * 1.4),dmg=d.shoot.dmg,life=5});
k2 = k2 + 1;
end
end;
else
e.cnt = ((T(e.cnt) and e.cnt or 0) + 1);
if T(d.shoot.burst) then
e.bq = (d.shoot.burst - 1);
e.bt = 0.13;
end;
nn = (d.shoot.n + (function() if T(d.boss) then return (2 * (pm - 1)) else return 0 end end)());
if (T(d.shoot.big) and (MOD(e.cnt,2) == 0)) then
nn = 0;
S.R.ebullets:push({x=mo0[0],y=mo0[1],z=mo0[2],vx=((aim[0] * sp) * 0.55),vy=((aim[1] * sp) * 0.55),vz=((aim[2] * sp) * 0.55),dmg=(d.shoot.dmg * 2.4),life=6,big=true});
end;
do
k2 = 0;
while (k2 < nn) do
off = (function() if (nn > 1) then return Math_tan(((((k2 / (nn - 1)) - 0.5) * (d.shoot.spread + (function() if T(d.boss) then return (12 * (pm - 1)) else return 0 end end)())) * S.DEG)) else return 0 end end)();
v = S.nrm(nil,smt({[0]=(aim[0] + (b2[0][0] * off)),(aim[1] + (b2[0][1] * off)),(aim[2] + (b2[0][2] * off)),length=3},AMT));
S.R.ebullets:push({x=mo0[0],y=mo0[1],z=mo0[2],vx=(v[0] * sp),vy=(v[1] * sp),vz=(v[2] * sp),dmg=d.shoot.dmg,life=4});
k2 = k2 + 1;
end
end;
end;
end;
end;
if T(e.summon) then
e.sumT = ((T(e.sumT) and e.sumT or e.summon) - dt);
if (e.sumT <= 0) then
e.sumT = (e.summon * (smt({[0]=1,0.8,0.6,length=3},AMT))[(pm - 1)]);
do
k2 = 0;
while (k2 < 8) do
p = S.spherePos(nil,e,(e.r + 4));
S.spawnEnemy(nil,"crawler",p[0],p[1],p[2]);
k2 = k2 + 1;
end
end;
end;
end;
if ((((not T(d.elite)) and (not T(d.boss))) and (not T(e.node))) and (pd > 100)) then
q = S.aheadPos(nil);
e.x = q[0];
e.y = q[1];
e.z = q[2];
end;
end);
S.R.enemies = S.R.enemies:filter(function(_this, e)
do return (e.hp > 0) end;
end);
end;
S.mainStats = function(_this)
local l, mul, rate, extra;
l = S.lv(nil,"main"); mul = ((((1 + (0.2 * Math_min((l - 1),1))) + (0.2 * ((l >= 4) and 1 or 0))) + (0.3 * ((l >= 6) and 1 or 0))) * S.R.mMul);
rate = (((1 + (0.06 * (l >= 2))) + (0.06 * (l >= 4))) + (0.1 * (l >= 6))); extra = (((l >= 3) and 1 or 0) + ((l >= 5) and 1 or 0));
do return {mul=mul,rate=rate,extra=extra} end;
end;
S.shot = function(_this, o, dir, spd, props)
local s, k;
s = {x=o.x,y=o.y,z=o.z,vx=(dir[0] * spd),vy=(dir[1] * spd),vz=(dir[2] * spd),hit=smt({length=0},AMT)};
for _, _k33 in ipairs(JS.keys(props)) do k = _k33
s[k] = props[k];
end;
S.R.shots:push(s);
do return s end;
end;
S.fan = function(_this, dir, n, spread, i)
local b, o;
if (n <= 1) then
do return dir end;
end;
b = S.basis(nil,dir); o = Math_tan((((i / (n - 1)) - 0.5) * spread));
do return S.nrm(nil,smt({[0]=(dir[0] + (b[0][0] * o)),(dir[1] + (b[0][1] * o)),(dir[2] + (b[0][2] * o)),length=3},AMT)) end;
end;
S.fireMain = function(_this, dt)
local W, wd, w, st, cm, po, wr, mul, range, t, i, n, o, dir, kk, fs, pr, side, toT, props, cen, bi, hl, sd, jb, jx, jy;
side = function(_this, s0)
do return (T(fs) and fs or s0) end;
end;
toT = function(_this, q)
do return S.nrm(nil,smt({[0]=(t.x - q.x),(t.y - q.y),(t.z - q.z),length=3},AMT)) end;
end;
props = function(_this, b)
if T(wd.size) then
b.size = ((T(b.size) and b.size or ((b.model == "fx_spark") and 3 or 2.4)) * wd.size);
end;
if T(wd.burn) then
b.burn = wd.burn;
end;
if T(wd.blastR) then
b.blastR = (wd.blastR * S.blast(nil));
end;
if T(wd.tint) then
b.tint = wd.tint;
end;
if (T(wd.crit) or T(S.R.trait.crit)) then
b.crit = ((T(wd.crit) and wd.crit or 0) + (T(S.R.trait.crit) and S.R.trait.crit or 0));
end;
if T(S.R.trait.close) then
b.close = S.R.trait.close;
end;
do return b end;
end;
W = S.R.wpn; wd = W.def; w = wd.fam; st = S.mainStats(nil); cm = ((S.cdMult(nil) * (1 - Math_min(0.4,S.R.st.rate))) / (function() if (S.R.feverT > 0) then return (1 + S.R.feverK) else return 1 end end)()); po = S.R.pose; wr = (T(wd.rate) and wd.rate or 1); mul = (st.mul * W.mul);
S.R.timers.main = (S.R.timers.main - dt);
if (S.R.timers.main > 0) then
do return end;
end;
range = (function() if (w == "shotgun") then return (T(wd.range) and wd.range or 32) else return 42 end end)(); t = S.target(nil,S.R.px,S.R.py,S.R.pz,range);
S.R.target = (function() if (T(t) and (not T(t.d.ore))) then return t else return (function() if ((T(S.R.target) and (S.R.target.hp > 0)) and (S.dd(nil,S.R.target,(S.P(nil))) < 3600)) then return S.R.target else return nil end end)() end end)();
if (not T(t)) then
do return end;
end;
if (((T(po.ok) and (po.fxm.fire[0] ~= "P")) and (po.aimK < 0.55)) and ((function() po.noAim = ((T(po.noAim) and po.noAim or 0) + dt); return po.noAim end)() < 0.6)) then
S.R.timers.main = 0.04;
do return end;
end;
po.noAim = 0;
S.C:sfx("shoot");
kk = (function() if T(po.ok) then return po.fxm.kick else return 0 end end)(); fs = (function() if T(W.native) then return nil else return (function() if T(po.ok) then return po.fxm.fire[0] else return "R" end end)() end end)(); pr = (T(wd.pierce) and wd.pierce or 0);
if (w == "laser") then
S.R.timers.main = (((0.34 / st.rate) / wr) * cm);
n = ((1 + st.extra) + (T(wd.extra) and wd.extra or 0));
o = S.mz(nil,side(nil,"R"),0);
dir = toT(nil,o);
do
i = 0;
while (i < n) do
S.shot(nil,o,S.fan(nil,dir,n,0.24,i),80,(props(nil,{dmg=(3.4 * mul),pierce=Math_max(0,(2 + pr)),life=0.7,model="fx_laser_player"})));
i = i + 1;
end
end;
S.muzzleFx(nil,o,dir,(T(wd.size) and wd.size or 1));
S.kick(nil,side(nil,"R"),1,(0.4 * kk));
if (not T(wd.single)) then
S.later(nil,0.08,function(_this)
local o2, tt, d2, j;
if ((not T(S.R)) or T(S.R.over)) then
do return end;
end;
o2 = S.mz(nil,side(nil,"R"),0); tt = (function() if (t.hp > 0) then return t else return nil end end)(); d2 = (function() if T(tt) then return S.nrm(nil,smt({[0]=(tt.x - o2.x),(tt.y - o2.y),(tt.z - o2.z),length=3},AMT)) else return dir end end)();
do
j = 0;
while (j < n) do
S.shot(nil,o2,S.fan(nil,d2,n,0.24,j),80,(props(nil,{dmg=(3.4 * mul),pierce=Math_max(0,(2 + pr)),life=0.7,model="fx_laser_player"})));
j = j + 1;
end
end;
S.muzzleFx(nil,o2,d2,0.8);
S.kick(nil,side(nil,"R"),0.8,(0.2 * kk));
end);
end;
elseif (w == "shotgun") then
S.R.timers.main = (((0.5 / st.rate) / wr) * cm);
n = Math_max(3,(Math_round(((6 + (st.extra * 2)) * (T(wd.count) and wd.count or 1)))));
cen = S.mz(nil,side(nil,"L"),1);
dir = toT(nil,cen);
do
bi = 0;
while (bi < 3) do
;(function(_this, bi)
S.later(nil,(bi * 0.05),function(_this)
local ob, tt, db, bb, per, q, dv, jj;
if ((not T(S.R)) or T(S.R.over)) then
do return end;
end;
ob = S.mz(nil,side(nil,"L"),bi); tt = (function() if (t.hp > 0) then return t else return nil end end)(); db = (function() if T(tt) then return S.nrm(nil,smt({[0]=(tt.x - ob.x),(tt.y - ob.y),(tt.z - ob.z),length=3},AMT)) else return dir end end)(); bb = S.basis(nil,db); per = Math_ceil((n / 3));
do
q = 0;
while (q < per) do
dv = S.fan(nil,db,per,0.24,q); jj = S.rand(nil,(-0.07),0.07);
dv = S.nrm(nil,smt({[0]=(dv[0] + (bb[1][0] * jj)),(dv[1] + (bb[1][1] * jj)),(dv[2] + (bb[1][2] * jj)),length=3},AMT));
S.shot(nil,ob,dv,72,(props(nil,{dmg=(13 * mul),pierce=Math_max(0,(1 + pr)),life=(T(wd.range) and 0.34 or 0.45),kb=(3 * (T(wd.kb) and wd.kb or 1)),model="fx_spark"})));
q = q + 1;
end
end;
S.muzzleFx(nil,ob,db,1.2);
S.kick(nil,side(nil,"L"),0.7,(0.45 * kk));
end);
end)(nil,bi);
bi = bi + 1;
end
end;
S.R.shake = Math_max(S.R.shake,0.06);
elseif (w == "heal") then
S.R.timers.main = (((0.32 / st.rate) / wr) * cm);
n = ((1 + st.extra) + (T(wd.extra) and wd.extra or 0));
o = S.mz(nil,side(nil,"R"),0);
dir = toT(nil,o);
hl = ((0.5 * ((wd.heal == nil) and 1 or wd.heal)) * (1 + (T(S.R.trait.heal) and S.R.trait.heal or 0)));
do
i = 0;
while (i < n) do
S.R.missiles:push({x=o.x,y=o.y,z=o.z,dir=S.nrm(nil,smt({[0]=(dir[0] + S.rand(nil,(-0.6),0.6)),(dir[1] + S.rand(nil,(-0.2),0.6)),(dir[2] + S.rand(nil,(-0.6),0.6)),length=3},AMT)),spd=28,target=t,dmg=(14 * mul),splash=((T(wd.splash) and wd.splash or 0) * S.blast(nil)),life=2.5,heal=hl,model="fx_spark_teal",size=4});
i = i + 1;
end
end;
S.muzzleFx(nil,o,dir,0.9);
S.kick(nil,side(nil,"R"),1,(0.2 * kk));
elseif (w == "twin") then
S.R.timers.main = (((0.32 / st.rate) / wr) * cm);
n = ((2 + st.extra) + (T(wd.extra) and wd.extra or 0));
do
i = 0;
while (i < n) do
sd = (function() if T(fs) then return fs else return (T(MOD((i + po.alt),2)) and "L" or "R") end end)();
o = S.mz(nil,sd,(function() if T(fs) then return (i + po.alt) else return 0 end end)());
dir = toT(nil,o);
if T(wd.jitter) then
jb = S.basis(nil,dir); jx = S.rand(nil,(-wd.jitter),wd.jitter); jy = S.rand(nil,(-wd.jitter),wd.jitter);
dir = S.nrm(nil,smt({[0]=((dir[0] + (jb[0][0] * jx)) + (jb[1][0] * jy)),((dir[1] + (jb[0][1] * jx)) + (jb[1][1] * jy)),((dir[2] + (jb[0][2] * jx)) + (jb[1][2] * jy)),length=3},AMT));
end;
S.shot(nil,o,dir,75,(props(nil,{dmg=(8.6 * mul),pierce=Math_max(0,(2 + pr)),life=0.7,model="fx_laser_player"})));
S.muzzleFx(nil,o,dir,0.7);
S.kick(nil,sd,0.8,(0.15 * kk));
i = i + 1;
end
end;
po.alt = po.alt + 1;
elseif (w == "prism") then
S.R.timers.main = (((0.34 / st.rate) / wr) * cm);
n = (((T(wd.single) and 1 or 3) + st.extra) + (T(wd.extra) and wd.extra or 0));
o = S.mz(nil,side(nil,"R"),0);
dir = toT(nil,o);
do
i = 0;
while (i < n) do
S.shot(nil,o,S.fan(nil,dir,n,(0.36 * (T(wd.spread) and wd.spread or 1)),i),74,(props(nil,{dmg=(3.9 * mul),pierce=Math_max(0,(2 + pr)),life=0.7,model="fx_white_bolt",tint=smt({[0]=0.75,0.35,1.3,length=3},AMT),size=2.8})));
i = i + 1;
end
end;
S.muzzleFx(nil,o,dir,1.2);
S.kick(nil,side(nil,"R"),1,(0.4 * kk));
elseif (w == "lob") then
S.R.timers.main = (((0.7 / st.rate) / wr) * cm);
n = ((1 + st.extra) + (T(wd.extra) and wd.extra or 0));
do
i = 0;
while (i < n) do
o = S.mz(nil,side(nil,"P"),(function() local _v = po.podAlt; po.podAlt = _v + 1; return _v end)());
dir = toT(nil,o);
S.R.missiles:push({x=o.x,y=o.y,z=o.z,dir=S.nrm(nil,smt({[0]=(dir[0] + S.rand(nil,(-0.5),0.5)),(dir[1] + 0.6),(dir[2] + S.rand(nil,(-0.5),0.5)),length=3},AMT)),spd=32,target=t,dmg=(12 * mul),splash=((3 * S.blast(nil)) * (T(wd.splash) and wd.splash or 1)),slowR=(function() if T(wd.slow) then return (((3 * S.blast(nil)) * (T(wd.splash) and wd.splash or 1)) * 1.3) else return 0 end end)(),slowT=(T(wd.slow) and wd.slow or 0),life=3,model="fx_missile",size=(2.2 * (T(wd.size) and wd.size or 1)),tint=(T(wd.tint) and wd.tint or nil)});
S.sparks(nil,o.x,o.y,o.z,"fx_spark",3,7,0.4,nil,0.8);
i = i + 1;
end
end;
S.kick(nil,nil,0,(0.8 * kk));
S.R.shake = Math_max(S.R.shake,0.05);
end;
end;
S.initArms = function(_this)
local lo, wd, sd, it, nd, nl;
lo = S.C:loadout(S.R.mech); wd = S.C:weapon(lo.main); sd = (function() if T(lo.sub) then return S.C:subDef(lo.sub) else return nil end end)(); it = (function() if T(sd) then return ((S.C:armory()).subs)[sd.id] else return nil end end)();
S.R.trait = (T(S.C.MECH_TRAIT[S.R.mech]) and S.C.MECH_TRAIT[S.R.mech] or JS.dict());
S.R.wpn = {def=wd,lv=S.C:armLv("weapons",wd.id),native=(wd.fam == ((S.M(nil)).weapon).type)};
S.R.wpn.mul = ((((T(wd.dmg) and wd.dmg or 1) * S.C:wLvMult(S.R.wpn.lv)) * (function() if T(S.R.wpn.native) then return (1 + S.C.NATIVE_BONUS) else return 1 end end)()) * (1 + (T(S.R.trait.main) and S.R.trait.main or 0)));
nd = S.C:nitroDef(lo.nitro); nl = (function() local _t = S.C:armLv("nitros",nd.id); if T(_t) then return _t end; return 1 end)();
S.R.nit = {def=nd,lv=nl,st=G.Object:assign(JS.dict(),nd,{name=nd.n,dist=(nd.dist * (1 + (0.05 * (nl - 1)))),cd=(nd.cd * (1 - (0.06 * (nl - 1)))),ram=(function() if T(nd.ram) then return (nd.ram * (T(S.R.trait.ram) and S.R.trait.ram or 1)) else return 0 end end)()})};
S.R.sub = ((T(sd) and T(it)) and {def=sd,lv=(T(it.lv) and it.lv or 1),ammo=Math_min((T(it.stock) and it.stock or 0),(S.C:subCap(S.R.mech))),cap=S.C:subCap(S.R.mech),cd=2,used=0,gained=0,flash=0,autoT=0} or nil);
end;
S.inR = function(_this, x, y, z, r, fn)
S.near(nil,x,y,z,(r + 3),function(_this, e)
if (((e.hp > 0) and (not T(e.d.ore))) and (S.d3(nil,x,y,z,e.x,e.y,e.z) < ((r + e.r) * (r + e.r)))) then
fn(nil,e);
end;
end);
end;
S.subCdMax = function(_this)
local s;
s = S.R.sub;
do return (((s.def.cd * S.cdMult(nil)) * (1 - (T(S.R.trait.subCd) and S.R.trait.subCd or 0))) * ((s.lv >= 5) and 0.8 or 1)) end;
end;
S.subCount = function(_this)
local s, d, b;
s = S.R.sub; d = s.def; b = ((s.lv >= 3) and 1 or 0);
do return (d.n0 + (function() if (d.id == "swarm") then return (3 * b) else return (function() if (d.id == "cluster") then return (2 * b) else return (function() if ((d.id == "cryo") or (d.id == "emp")) then return b else return 0 end end)() end end)() end end)()) end;
end;
S.subDmg = function(_this)
local s;
s = S.R.sub;
do return (((s.def.dmg * (1 + (0.15 * (s.lv - 1)))) * (1 + (T(S.R.trait.sub) and S.R.trait.sub or 0))) * S.R.mMul) end;
end;
S.subBlast = function(_this)
local s;
s = S.R.sub;
do return ((S.blast(nil) * (1 + (T(S.R.trait.blast) and S.R.trait.blast or 0))) * (((T(s) and (s.lv >= 3)) and ((s.def.id == "heavy") or (s.def.id == "gravity"))) and 1.15 or 1)) end;
end;
S.enemiesNear = function(_this, r)
local p, r2;
p = S.P(nil); r2 = (r * r);
do return S.R.enemies:filter(function(_this, e)
do return (((e.hp > 0) and (not T(e.d.ore))) and (S.dd(nil,p,e) < r2)) end;
end) end;
end;
S.densest = function(_this, list)
local best, bn;
best = list[0]; bn = (-1);
;(list:slice(0,24)):forEach(function(_this, e)
local c;
c = 0;
list:forEach(function(_this, o)
if (S.dd(nil,e,o) < 64) then
c = c + 1;
end;
end);
if (c > bn) then
bn = c;
best = e;
end;
end);
do return best end;
end;
S.launchSub = function(_this, d, t, i, dmg, size, tint, spd)
local o, up;
o = S.shoulderPt(nil,i); up = S.nrm(nil,smt({[0]=S.rand(nil,(-0.7),0.7),1,(S.rand(nil,(-0.7),0.7)),length=3},AMT));
S.R.missiles:push({x=o.x,y=o.y,z=o.z,dir=up,spd=spd,target=t,dmg=dmg,splash=0,life=4,model="fx_missile",size=size,tint=tint,sub=d});
S.sparks(nil,o.x,o.y,o.z,"fx_spark",2,7,0.3,nil,0.7);
end;
S.fireSub = function(_this, manual)
local S0, list, p, d, n, dmg, tint, t0, k, i;
S0 = (function() local _t = S.R; if not T(_t) then return _t end; return S.R.sub end)();
if (((not T(S0)) or T(S.paused)) or T(S.R.over)) then
do return false end;
end;
if (S0.cd > 0) then
do return false end;
end;
if (S0.ammo <= 0) then
if T(manual) then
S.A:toast("副武器弹药用完了：击败精英会掉弹药箱，升级时也可以补给");
end;
do return false end;
end;
list = S.enemiesNear(nil,60);
if (not T(LEN(list))) then
if T(manual) then
S.A:toast("附近没有目标");
end;
do return false end;
end;
p = S.P(nil);
list:sort(function(_this, a, b)
do return (S.dd(nil,a,p) - S.dd(nil,b,p)) end;
end);
d = S0.def; n = S.subCount(nil); dmg = S.subDmg(nil); tint = S.lin(nil,d.color);
S0.ammo = S0.ammo - 1;
S0.used = S0.used + 1;
S0.cd = S.subCdMax(nil);
S0.flash = 0.4;
S.C:sfx("skill");
S.R.shake = Math_max(S.R.shake,0.1);
if T(S.R.tutorial) then
S.R.tutorial:event("sub");
end;
if (d.id == "heavy") then
t0 = (function() local _t = (function() local _t = (list:filter(function(_this, e)
do return e.d.boss end;
end))[0]; if T(_t) then return _t end; return (list:filter(function(_this, e)
do return e.d.elite end;
end))[0] end)(); if T(_t) then return _t end; return ((list:slice()):sort(function(_this, a, b)
do return (b.hp - a.hp) end;
end))[0] end)();
S.launchSub(nil,d,t0,0,dmg,3.4,tint,18);
elseif (d.id == "cluster") then
t0 = S.densest(nil,list);
S.R.missiles:push((S.podLaunch(nil,{fall=true,x=t0.x,y=(t0.y + 30),z=t0.z,tx=t0.x,ty=t0.y,tz=t0.z,dmg=dmg,life=6,model="fx_missile",size=3.2,tint=tint,sub=d,n=n},0,0.03)));
elseif (d.id == "gravity") then
S.launchSub(nil,d,S.densest(nil,list),0,dmg,3,tint,22);
else
k = Math_min(LEN(list),(Math_max(1,(Math_ceil((n / 2))))));
do
i = 0;
while (i < n) do
S.launchSub(nil,d,list[MOD(i,k)],i,dmg,((d.id == "swarm") and 1.4 or 2.2),tint,24);
i = i + 1;
end
end;
end;
do return true end;
end;
S.subImpact = function(_this, m, t)
local d, x, y, z, br, tint, cn, k, cur, done, c, nx, nd, from, dl;
d = m.sub; x = (function() if T(m.fall) then return m.tx else return m.x end end)(); y = (function() if T(m.fall) then return m.ty else return m.y end end)(); z = (function() if T(m.fall) then return m.tz else return m.z end end)(); br = S.subBlast(nil); tint = m.tint;
if (d.id == "swarm") then
S.explode(nil,x,y,z,(d.r * br),m.dmg);
elseif (d.id == "heavy") then
if (T(t) and (t.hp > 0)) then
S.hurtEnemy(nil,t,((m.dmg * 0.5) * ((T(t.d.elite) or T(t.d.boss)) and 1.5 or 1)),0,0,0,false,0.2);
end;
S.explode(nil,x,y,z,(d.r * br),(m.dmg * 0.6));
S.ringBurst(nil,x,y,z,((d.r * br) * 1.3),tint,0.45);
S.R.shake = Math_max(S.R.shake,0.35);
S.C:sfx("boom");
elseif (d.id == "cluster") then
S.explode(nil,x,y,z,(5 * br),((m.dmg * d.main) / d.dmg));
S.C:sfx("boom");
S.R.shake = Math_max(S.R.shake,0.25);
cn = (T(m.n) and m.n or 6);
do
k = 0;
while (k < cn) do
;(function(_this, k)
local a, rr, bx, bz, by;
a = (((k / cn) * Math_PI) * 2); rr = (S.rand(nil,3,7) * br); bx = (x + (Math_cos(a) * rr)); bz = (z + (Math_sin(a) * rr)); by = (y + S.rand(nil,(-2),2));
S.later(nil,(0.1 + (k * 0.06)),function(_this)
if ((not T(S.R)) or T(S.R.over)) then
do return end;
end;
S.explode(nil,bx,by,bz,(d.r * br),m.dmg);
S.inR(nil,bx,by,bz,(d.r * br),function(_this, e)
e.burn = {dps=(m.dmg * 0.15),t=2};
end);
end);
end)(nil,k);
k = k + 1;
end
end;
elseif (d.id == "cryo") then
S.explode(nil,x,y,z,(d.r * br),m.dmg);
S.ringBurst(nil,x,y,z,(d.r * br),tint,0.35);
S.inR(nil,x,y,z,(d.r * br),function(_this, e)
e.slowT = 3;
end);
elseif (d.id == "emp") then
cur = (function() if (T(t) and (t.hp > 0)) then return t else return S.target(nil,x,y,z,12) end end)(); done = smt({length=0},AMT);
if T(cur) then
S.hurtEnemy(nil,cur,m.dmg,0,0,0);
done:push(cur);
cur.shock = 2;
if (not T(cur.d.boss)) then
cur.stunT = (T(cur.d.elite) and 0.3 or 0.7);
end;
end;
do
c = 0;
while (T(cur) and (c < d.chain)) do
nx = nil; nd = (18 * 18); from = cur;
S.R.enemies:forEach(function(_this, o)
local dq;
if (((o.hp > 0) and (done:indexOf(o) < 0)) and (not T(o.d.ore))) then
dq = S.dd(nil,from,o);
if (dq < nd) then
nd = dq;
nx = o;
end;
end;
end);
if (not T(nx)) then
do break end;
end;
dl = (function() local _t = Math_sqrt(nd); if T(_t) then return _t end; return 1 end)();
S.R.beams:push({x=cur.x,y=cur.y,z=cur.z,d=smt({[0]=((nx.x - cur.x) / dl),((nx.y - cur.y) / dl),((nx.z - cur.z) / dl),length=3},AMT),len=dl,life=0.16,tint=tint});
done:push(nx);
S.hurtEnemy(nil,nx,(m.dmg * 0.7),0,0,0);
nx.shock = 2;
if (not T(nx.d.boss)) then
nx.stunT = (T(nx.d.elite) and 0.3 or 0.7);
end;
cur = nx;
c = c + 1;
end
end;
S.emb(nil,x,y,z,tint,10,12,0.4,1.6,2);
elseif (d.id == "gravity") then
S.R.wells:push({x=x,y=y,z=z,r=(d.r * br),life=2.5,dmg=(m.dmg * 0.12),tick=0,implode={r=(9 * br),dmg=m.dmg,tint=tint}});
S.ringBurst(nil,x,y,z,(d.r * br),tint,0.5);
S.inR(nil,x,y,z,(d.r * br),function(_this, e)
e.dmark = 2.5;
end);
end;
if T(S.R.trait.subHeal) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + S.R.trait.subHeal));
end;
end;
S.updateSub = function(_this, dt)
local S0, list, big;
S0 = S.R.sub;
if (not T(S0)) then
do return end;
end;
if (S0.cd > 0) then
S0.cd = (S0.cd - dt);
end;
if (S0.flash > 0) then
S0.flash = (S0.flash - dt);
end;
S0.autoT = (S0.autoT - dt);
if ((((S0.cd > 0) or (S0.ammo <= 0)) or (not T(S.C.save.settings.subAuto))) or (S0.autoT > 0)) then
do return end;
end;
S0.autoT = 0.25;
list = S.enemiesNear(nil,40); big = list:some(function(_this, e)
do return (T(e.d.elite) and e.d.elite or e.d.boss) end;
end);
if ((LEN(list) >= 6) or T(big)) then
S.fireSub(nil,false);
end;
end;
S.nova = function(_this, c, r, dmg, color, tint)
S.R.novas:push({x=c.x,y=c.y,z=c.z,r=r,life=0.45,color=(T(color) and color or "#57B8FF"),tint=tint});
if T(dmg) then
S.near(nil,c.x,c.y,c.z,(r + 3),function(_this, e)
local d, k;
d = (function() local _t = Math_sqrt((S.dd(nil,c,e))); if T(_t) then return _t end; return 1 end)();
if (d < (r + e.r)) then
k = S.knock(nil,e,c,22);
S.hurtEnemy(nil,e,dmg,k[0],k[1],k[2]);
end;
end);
end;
end;
S.explode = function(_this, x, y, z, r, dmg)
S.sparks(nil,x,y,z,"fx_spark",4,14,0.5,nil,0.7);
S.emb(nil,x,y,z,S.EMBER,Math_min(22,(6 + Math_round((r * 3)))),(7 + (r * 2)),0.5,(1.5 + (r * 0.2)));
if (LEN(S.R.parts) < 230) then
S.R.parts:push({model="fx_white",x=x,y=y,z=z,vx=0,vy=0,vz=0,life=0.14,max=0.14,size=(2 + (r * 1.2)),tint=nil,noGrav=true});
end;
if (r >= 3) then
S.ringBurst(nil,x,y,z,(r * 1.1),S.EMBER,0.3);
end;
S.near(nil,x,y,z,(r + 3),function(_this, e)
if (S.d3(nil,x,y,z,e.x,e.y,e.z) < ((r + e.r) * (r + e.r))) then
S.hurtEnemy(nil,e,dmg,0,0,0);
end;
end);
end;
S.updateShots = function(_this, dt)
S.R.shots = S.R.shots:filter(function(_this, s)
local dead;
s.life = (s.life - dt);
s.x = (s.x + (s.vx * dt));
s.y = (s.y + (s.vy * dt));
s.z = (s.z + (s.vz * dt));
if (((s.model == "fx_laser_player") or (s.model == "fx_white_bolt")) and (Math_random() < 0.7)) then
S.trail(nil,(s.x - (s.vx * 0.02)),(s.y - (s.vy * 0.02)),(s.z - (s.vz * 0.02)),(T(s.tint) and s.tint or smt({[0]=0.36,0.95,0.86,length=3},AMT)),0.9,0.16,3);
end;
dead = false;
S.near(nil,s.x,s.y,s.z,4,function(_this, e)
if (s.hit:indexOf(e) >= 0) then
do return end;
end;
if (S.d3(nil,s.x,s.y,s.z,e.x,e.y,e.z) < ((e.r + 0.6) * (e.r + 0.6))) then
if T(s.blastR) then
S.explode(nil,s.x,s.y,s.z,s.blastR,(s.dmg * 0.8));
end;
if T(s.md) then
S.modHit(nil,s.md,e,s.dmg,{x=(s.x - (s.vx * 0.05)),y=(s.y - (s.vy * 0.05)),z=(s.z - (s.vz * 0.05))},4);
else
S.hurtEnemy(nil,e,(s.dmg * (function() if (T(s.close) and (S.dd(nil,e,(S.P(nil))) < 225)) then return (1 + s.close) else return 1 end end)()),((s.vx * 0.04) * (T(s.kb) and s.kb or 1)),((s.vy * 0.04) * (T(s.kb) and s.kb or 1)),((s.vz * 0.04) * (T(s.kb) and s.kb or 1)),false,s.crit);
if (T(s.burn) and (e.hp > 0)) then
e.burn = {dps=(s.dmg * s.burn),t=2};
end;
end;
s.hit:push(e);
S.sparks(nil,s.x,s.y,s.z,"fx_spark_teal",2,8,0.3);
if ((function() local _v = s.pierce; s.pierce = _v - 1; return _v end)() <= 0) then
dead = true;
do return false end;
end;
end;
end);
do return ((not T(dead)) and (s.life > 0)) end;
end);
S.R.missiles = S.R.missiles:filter(function(_this, m)
local L, k, d, want, k2;
m.life = (m.life - dt);
if (T(m.fall) and T(m.launch)) then
L = m.launch;
m.life = (m.life + dt);
if (L.delay > 0) then
L.delay = (L.delay - dt);
m.x = L.x;
m.y = L.y;
m.z = L.z;
do return true end;
end;
m.hide = false;
L.t = (L.t + dt);
m.x = (m.x + ((L.dir[0] * 55) * dt));
m.y = (m.y + ((L.dir[1] * 55) * dt));
m.z = (m.z + ((L.dir[2] * 55) * dt));
if (Math_random() < 0.6) then
S.sparks(nil,m.x,m.y,m.z,"fx_spark",1,3,0.3);
end;
if (L.t > 0.42) then
m.launch = nil;
m.x = m.tx;
m.y = (m.ty + m.fh);
m.z = m.tz;
end;
do return true end;
end;
if T(m.fall) then
m.y = (m.y - (dt * 60));
S.trail(nil,m.x,(m.y + 1.2),m.z,(T(m.meteor) and smt({[0]=0.75,0.35,1.3,length=3},AMT) or S.EMBER),(T(m.meteor) and 3.2 or 1.4),(T(m.meteor) and 0.5 or 0.3));
if T(m.meteor) then
S.trail(nil,m.x,(m.y + 2.6),m.z,smt({[0]=1.5,0.8,0.3,length=3},AMT),2.2,0.4);
end;
if (m.y <= (m.ty + 0.5)) then
if T(m.sub) then
S.subImpact(nil,m,nil);
do return false end;
end;
S.explode(nil,m.tx,m.ty,m.tz,m.splash,m.dmg);
if T(m.meteor) then
S.ringBurst(nil,m.tx,m.ty,m.tz,(m.splash * 1.4),smt({[0]=0.8,0.4,1.4,length=3},AMT),0.55);
S.emb(nil,m.tx,m.ty,m.tz,smt({[0]=0.8,0.4,1.4,length=3},AMT),18,16,0.8,2.4,6);
S.R.shake = 0.7;
S.C:sfx("boom");
S.sparks(nil,m.tx,m.ty,m.tz,"fx_spark_teal",40,26,1);
do
k = 0;
while (k < 6) do
d = S.randDir(nil);
S.shot(nil,{x=m.tx,y=m.ty,z=m.tz},d,55,{dmg=(m.dmg * 0.1),pierce=2,life=0.6,model="fx_white_bolt",tint=smt({[0]=0.75,0.35,1.3,length=3},AMT),size=3});
k = k + 1;
end
end;
end;
if T(m.slowR) then
S.near(nil,m.tx,m.ty,m.tz,m.slowR,function(_this, e)
e.slowT = 3;
end);
end;
do return false end;
end;
do return true end;
end;
if ((not T(m.target)) or (m.target.hp <= 0)) then
m.target = S.target(nil,m.x,m.y,m.z,45);
end;
if T(m.target) then
want = S.nrm(nil,smt({[0]=(m.target.x - m.x),(m.target.y - m.y),(m.target.z - m.z),length=3},AMT)); k2 = Math_min(1,(dt * 6));
m.dir = S.nrm(nil,smt({[0]=S.lerp(nil,m.dir[0],want[0],k2),S.lerp(nil,m.dir[1],want[1],k2),(S.lerp(nil,m.dir[2],want[2],k2)),length=3},AMT));
end;
m.spd = Math_min(55,(m.spd + (dt * 60)));
m.x = (m.x + ((m.dir[0] * m.spd) * dt));
m.y = (m.y + ((m.dir[1] * m.spd) * dt));
m.z = (m.z + ((m.dir[2] * m.spd) * dt));
if (m.model == "fx_missile") then
S.trail(nil,(m.x - (m.dir[0] * 0.8)),(m.y - (m.dir[1] * 0.8)),(m.z - (m.dir[2] * 0.8)),S.EMBER,1.5,0.38);
elseif T(m.tint) then
S.trail(nil,(m.x - (m.dir[0] * 0.6)),(m.y - (m.dir[1] * 0.6)),(m.z - (m.dir[2] * 0.6)),m.tint,1.2,0.3);
end;
if (T(m.target) and (S.dd(nil,m,m.target) < ((m.target.r + 1) * (m.target.r + 1)))) then
if T(m.sub) then
S.subImpact(nil,m,m.target);
elseif T(m.md) then
S.modHit(nil,m.md,m.target,m.dmg,m,6);
elseif T(m.splash) then
S.explode(nil,m.x,m.y,m.z,m.splash,m.dmg);
else
S.hurtEnemy(nil,m.target,m.dmg,0,0,0);
end;
if T(m.slowR) then
S.inR(nil,m.x,m.y,m.z,m.slowR,function(_this, e)
e.slowT = Math_max((T(e.slowT) and e.slowT or 0),(T(m.slowT) and m.slowT or 2));
end);
end;
if T(m.heal) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + m.heal));
end;
do return false end;
end;
if (m.life <= 0) then
if T(m.sub) then
S.subImpact(nil,m,nil);
elseif T(m.splash) then
S.explode(nil,m.x,m.y,m.z,m.splash,(m.dmg * 0.5));
end;
do return false end;
end;
do return true end;
end);
S.R.ebullets = S.R.ebullets:filter(function(_this, b)
b.life = (b.life - dt);
b.x = (b.x + (b.vx * dt));
b.y = (b.y + (b.vy * dt));
b.z = (b.z + (b.vz * dt));
if (Math_random() < 0.5) then
S.trail(nil,b.x,b.y,b.z,smt({[0]=1.3,0.2,0.25,length=3},AMT),1.3,0.25,1);
end;
if (S.d3(nil,b.x,b.y,b.z,S.R.px,S.R.py,S.R.pz) < ((T(b.big) and 3.3 or 2.3) * (T(b.big) and 3.3 or 2.3))) then
S.hurtPlayer(nil,b.dmg);
do return false end;
end;
do return (b.life > 0) end;
end);
end;
S.lin = function(_this, hex)
local h;
h = hex:replace("#","");
do return (smt({[0]=0,2,4,length=3},AMT)):map(function(_this, i)
do return (Math_pow((G.parseInt(nil,h:substr(i,2),16) / 255),2.2) * 1.15) end;
end) end;
end;
S.initMods = function(_this)
local s, deck, k, j, t;
s = S.C.save;
deck = S.C:modDeck();
do
k = (LEN(deck) - 1);
while (k > 0) do
j = Math_floor((Math_random() * (k + 1))); t = deck[k];
deck[k] = deck[j];
deck[j] = t;
k = k - 1;
end
end;
S.R.mods = smt({length=0},AMT);
S.R.modPool = deck;
if T(LEN(S.R.modPool)) then
S.addMod(nil,(S.R.modPool:shift()));
end;
end;
S.addMod = function(_this, m)
S.R.mods:push({m=m,lv=1,t=(0.8 + (LEN(S.R.mods) * 0.4)),i=LEN(S.R.mods),tint=S.lin(nil,m.color)});
end;
S.has = function(_this, md, k)
local g, ev;
if (md.m.tags:indexOf(k) >= 0) then
do return true end;
end;
g = S.C:goldTag(md.m);
if (T(g) and (g.tag == k)) then
do return true end;
end;
ev = (function() local _t = md.evo; if not T(_t) then return _t end; return S.C:evoOf(md.m) end)();
do return (not (not (T(ev) and (ev.tags:indexOf(k) >= 0)))) end;
end;
S.modStat = function(_this, md)
local F, l, ev;
F = G.Object:assign(JS.dict(),(S.C:modForm(md.m.form))); l = md.lv; ev = (function() if T(md.evo) then return S.C:evoOf(md.m) else return nil end end)();
F.k = (T(F.b) and F.b or F.k);
do return {F=F,dmg=((((((F.dmg * S.C.MOD_RARITY_MULT[md.m.tier]) * S.C:modLvMult(md.m)) * (1 + (0.25 * (l - 1)))) * (1 + S.R.st.skill)) * ((md.m.elem == "dark") and 1.15 or 1)) * (T(ev) and 1.5 or 1)),cd=((((F.cd * (1 - (0.08 * (l - 1)))) * S.cdMult(nil)) * (T(S.R.st.traits.overclock) and 0.85 or 1)) * (T(ev) and 0.88 or 1)),count=((((F.count + ((l >= 3) and 1 or 0)) + ((l >= 5) and 1 or 0)) + ((md.m.tier == 3) and 1 or 0)) + (function() if T(ev) then return ev.count else return 0 end end)()),size=((T(S.has(nil,md,"big")) and 1.4 or 1) * (function() if (T(ev) and T(ev.size)) then return ev.size else return 1 end end)()),pierce=(T(S.has(nil,md,"pierce")) and 2 or 0)} end;
end;
S.react = function(_this, e, md, dmg)
local el, frozen, pois, txt, col;
el = md.m.elem; frozen = (e.slowT > 0); pois = (T(e.poison) and (e.poison.t > 0)); txt = nil; col = nil;
if (e.rcd > 0) then
do return end;
end;
if (((el == "thunder") and T(frozen)) or ((el == "ice") and (e.shock > 0))) then
txt = "碎冰";
col = "#9DD8FF";
e.slowT = 0;
e.shock = 0;
S.ringBurst(nil,e.x,e.y,e.z,6,smt({[0]=0.6,0.9,1.5,length=3},AMT),0.3);
S.near(nil,e.x,e.y,e.z,6,function(_this, o)
if (((o ~= e) and (o.hp > 0)) and (not T(o.d.ore))) then
S.hurtEnemy(nil,o,(dmg * 1.2),0,0,0,true);
end;
end);
S.hurtEnemy(nil,e,(dmg * 1.2),0,0,0,true);
elseif ((el == "fire") and T(pois)) then
txt = "爆燃";
col = "#FF8A3A";
e.poison = nil;
S.ringBurst(nil,e.x,e.y,e.z,6.5,smt({[0]=1.5,0.6,0.2,length=3},AMT),0.35);
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.5,0.6,0.2,length=3},AMT),12,12,0.5,2);
S.near(nil,e.x,e.y,e.z,6.5,function(_this, o)
if (((o ~= e) and (o.hp > 0)) and (not T(o.d.ore))) then
S.hurtEnemy(nil,o,(dmg * 1.1),0,0,0,true);
end;
end);
S.hurtEnemy(nil,e,(dmg * 1.1),0,0,0,true);
elseif ((el == "fire") and T(frozen)) then
txt = "融蚀";
col = "#FFB347";
e.slowT = 0;
S.hurtEnemy(nil,e,(dmg * 0.9),0,0,0,true);
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.4,0.8,0.3,length=3},AMT),6,8,0.4,1.6);
elseif ((el == "thunder") and T(pois)) then
txt = "麻痹";
col = "#F5E050";
e.poison = nil;
e.stunT = (T(e.d.boss) and 0.35 or (T(e.d.elite) and 0.8 or 1.4));
S.emb(nil,e.x,e.y,e.z,smt({[0]=1.4,1.3,0.3,length=3},AMT),8,8,0.4,1.6);
elseif (((el == "light") and (e.dmark > 0)) or ((el == "dark") and (e.lmark > 0))) then
txt = "湮灭";
col = "#E0A0FF";
e.dmark = 0;
e.lmark = 0;
S.hurtEnemy(nil,e,(dmg * 1.6),0,0,0,true,1);
S.ringBurst(nil,e.x,e.y,e.z,4.5,smt({[0]=1.3,0.5,1.5,length=3},AMT),0.3);
end;
if T(txt) then
e.rcd = 0.5;
S.C:sfx("crit");
if (LEN(S.R.nums) < 70) then
S.R.nums:push({x=e.x,y=(e.y + (e.r * 1.9)),z=e.z,v=txt,crit=true,col=col,life=1.1});
end;
end;
end;
S.modHit = function(_this, md, e, dmg, from, kb)
local m, extra, k, chains, cur, done, c, nx, nd, dl, q;
if ((not T(e)) or (e.hp <= 0)) then
do return end;
end;
S.react(nil,e,md,dmg);
if (e.hp <= 0) then
do return end;
end;
m = md.m; extra = (((m.elem == "light") and 0.15 or 0) + (T(S.has(nil,md,"crit")) and 0.2 or 0)); k = S.knock(nil,e,from,((T(kb) and kb or 6) * (T(S.has(nil,md,"knock")) and 3 or 1)));
S.hurtEnemy(nil,e,dmg,k[0],k[1],k[2],false,extra,m.color);
if (m.elem == "thunder") then
e.shock = 2;
end;
if (m.elem == "light") then
e.lmark = 2.5;
end;
if (m.elem == "dark") then
e.dmark = 2.5;
end;
if (m.elem == "fire") then
e.burn = {dps=(dmg * 0.15),t=2};
end;
if (m.elem == "poison") then
e.poison = {dps=(dmg * 0.133),t=3};
end;
if ((m.elem == "ice") or T(S.has(nil,md,"slow"))) then
e.slowT = 2;
end;
if T(S.has(nil,md,"leech")) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (dmg * 0.02)));
end;
chains = (((m.elem == "thunder") and 1 or 0) + (T(S.has(nil,md,"chain")) and 2 or 0));
if (T(chains) and (not T(md.busy))) then
md.busy = true;
cur = e; done = smt({[0]=e,length=1},AMT);
do
c = 0;
while (c < chains) do
nx = nil; nd = (18 * 18);
S.R.enemies:forEach(function(_this, o)
local d;
if (((o.hp > 0) and (done:indexOf(o) < 0)) and (not T(o.d.ore))) then
d = S.dd(nil,cur,o);
if (d < nd) then
nd = d;
nx = o;
end;
end;
end);
if (not T(nx)) then
do break end;
end;
dl = (function() local _t = Math_sqrt(nd); if T(_t) then return _t end; return 1 end)();
S.R.beams:push({x=cur.x,y=cur.y,z=cur.z,d=smt({[0]=((nx.x - cur.x) / dl),((nx.y - cur.y) / dl),((nx.z - cur.z) / dl),length=3},AMT),len=dl,life=0.12,tint=md.tint});
done:push(nx);
S.hurtEnemy(nil,nx,(dmg * 0.5),0,0,0,false,extra,m.color);
cur = nx;
c = c + 1;
end
end;
md.busy = false;
end;
if ((T(S.has(nil,md,"split")) and (not T(md.busy))) and (Math_random() < 0.6)) then
do
q = 0;
while (q < 2) do
S.shot(nil,e,S.randDir(nil),50,{dmg=(dmg * 0.35),pierce=0,life=0.5,hit=smt({[0]=e,length=1},AMT),model="fx_white",tint=md.tint,size=2.4});
q = q + 1;
end
end;
end;
end;
S.modArea = function(_this, md, c, r, dmg, kb)
S.near(nil,c.x,c.y,c.z,(r + 6),function(_this, e)
if ((not T(e.d.ore)) and (S.dd(nil,c,e) < Math_pow((r + e.r),2))) then
S.modHit(nil,md,e,dmg,c,kb);
end;
end);
end;
S.beamHit = function(_this, o, dir, len, width, fn)
S.R.enemies:forEach(function(_this, e)
local rx, ry, rz, t, px, py, pz;
if T(e.d.ore) then
do return end;
end;
rx = (e.x - o.x); ry = (e.y - o.y); rz = (e.z - o.z); t = (((rx * dir[0]) + (ry * dir[1])) + (rz * dir[2]));
if ((t < 0) or (t > len)) then
do return end;
end;
px = (rx - (dir[0] * t)); py = (ry - (dir[1] * t)); pz = (rz - (dir[2] * t));
if ((((px * px) + (py * py)) + (pz * pz)) < Math_pow((e.r + width),2)) then
S.emb(nil,e.x,e.y,e.z,S.EMBER,3,9,0.3,1.3);
fn(nil,e);
end;
end);
end;
S.updateModules = function(_this, dt)
local p;
p = S.P(nil);
S.R.mods:forEach(function(_this, md)
local st, F, i, t, mo, bk, r, a, ox, oy, oz, dir, pool, e, strong, bd, bv;
st = S.modStat(nil,md); F = st.F; mo = S.mainMz(nil,0); bk = S.backPt(nil);
if (F.k == "orbit") then
md.ang = ((T(md.ang) and md.ang or 0) + (dt * 190));
md.orb = smt({length=0},AMT);
md.osz = (6 * st.size);
r = (7.5 * st.size);
do
i = 0;
while (i < st.count) do
a = ((md.ang + ((i * 360) / st.count)) * S.DEG); ox = (S.R.px + (Math_cos(a) * r)); oy = (S.R.py + (Math_sin((a * 2)) * 1.5)); oz = (S.R.pz + (Math_sin(a) * r));
md.orb:push(smt({[0]=ox,oy,oz,length=3},AMT));
S.near(nil,ox,oy,oz,4,function(_this, e)
local key;
key = ("oc" .. S2(md.i));
if (((not T(e.d.ore)) and (S.d3(nil,ox,oy,oz,e.x,e.y,e.z) < Math_pow((e.r + (1.3 * st.size)),2))) and ((T(e[key]) and e[key] or 0) <= S.R.t)) then
e[key] = (S.R.t + 0.4);
S.modHit(nil,md,e,st.dmg,p,8);
end;
end);
i = i + 1;
end
end;
do return end;
end;
md.t = (md.t - dt);
if (md.t > 0) then
do return end;
end;
t = S.target(nil,S.R.px,S.R.py,S.R.pz,45);
if (((not T(t)) and (F.k ~= "nova")) and (F.k ~= "mine")) then
md.t = 0.3;
do return end;
end;
md.t = st.cd;
dir = (function() if T(t) then return S.nrm(nil,smt({[0]=(t.x - S.R.px),(t.y - S.R.py),(t.z - S.R.pz),length=3},AMT)) else return S.camBasis.f end end)();
if (F.k == "homing") then
do
i = 0;
while (i < st.count) do
S.R.missiles:push({x=(S.shoulderPt(nil,i)).x,y=(S.shoulderPt(nil,i)).y,z=(S.shoulderPt(nil,i)).z,dir=S.nrm(nil,smt({[0]=(((function() if T(MOD(i,2)) then return (-1) else return 1 end end)() * 0.6) + S.rand(nil,(-0.3),0.3)),1,(S.rand(nil,(-0.2),0.5)),length=3},AMT)),spd=22,target=t,dmg=st.dmg,splash=0,life=3,model="fx_white",size=(3.2 * st.size),tint=md.tint,md=md});
i = i + 1;
end
end;
elseif (F.k == "nova") then
S.R.novas:push({x=p.x,y=p.y,z=p.z,r=(10 * st.size),life=0.45,tint=md.tint});
S.modArea(nil,md,p,(10 * st.size),st.dmg,22);
elseif (F.k == "strike") then
pool = S.R.enemies:filter(function(_this, e)
do return ((not T(e.d.ore)) and (S.dd(nil,p,e) < (40 * 40))) end;
end);
do
i = 0;
while ((i < st.count) and T(LEN(pool))) do
e = (pool:splice(Math_floor((Math_random() * LEN(pool))),1))[0];
S.R.strikes:push({x=e.x,y=e.y,z=e.z,life=0.22,tint=md.tint});
S.emb(nil,e.x,e.y,e.z,md.tint,7,12,0.4,1.4,3);
S.ringBurst(nil,e.x,e.y,e.z,3.5,md.tint,0.25);
S.modArea(nil,md,e,(3.5 * st.size),st.dmg,5);
i = i + 1;
end
end;
elseif (F.k == "beam") then
strong = (function() local _t = ((S.R.enemies:filter(function(_this, e)
do return ((not T(e.d.ore)) and (S.dd(nil,p,e) < 2500)) end;
end)):sort(function(_this, a, b)
do return (b.hp - a.hp) end;
end))[0]; if T(_t) then return _t end; return t end)(); bd = S.nrm(nil,smt({[0]=(strong.x - mo.x),(strong.y - mo.y),(strong.z - mo.z),length=3},AMT));
do
i = 0;
while (i < st.count) do
bv = S.fan(nil,bd,st.count,(0.25 * (st.count - 1)),i);
S.R.beams:push({x=mo.x,y=mo.y,z=mo.z,d=bv,len=60,life=0.2,tint=md.tint});
S.beamHit(nil,mo,bv,60,(1.6 * st.size),function(_this, e)
S.modHit(nil,md,e,st.dmg,mo,6);
end);
i = i + 1;
end
end;
S.muzzleFx(nil,mo,bd,1);
S.kick(nil,(function() if (S.R.pose.fxm.fire[0] == "P") then return nil else return S.R.pose.fxm.fire[0] end end)(),0.7,0.2);
elseif (F.k == "fan") then
do
i = 0;
while (i < st.count) do
S.shot(nil,mo,S.fan(nil,S.nrm(nil,smt({[0]=(t.x - mo.x),(t.y - mo.y),(t.z - mo.z),length=3},AMT)),st.count,0.7,i),60,{dmg=st.dmg,pierce=st.pierce,life=0.7,model="fx_white_bolt",tint=md.tint,size=(2.4 * st.size),md=md});
i = i + 1;
end
end;
elseif (F.k == "mine") then
do
i = 0;
while (i < st.count) do
S.R.mines:push({x=(bk.x + S.rand(nil,(-1),1)),y=(bk.y + S.rand(nil,(-1),1)),z=(bk.z + S.rand(nil,(-1),1)),life=9,arm=0.5,r=(5 * st.size),dmg=st.dmg,md=md,tint=md.tint});
i = i + 1;
end
end;
elseif (F.k == "boomerang") then
do
i = 0;
while (i < st.count) do
S.R.booms:push({x=mo.x,y=mo.y,z=mo.z,d=S.fan(nil,S.nrm(nil,smt({[0]=(t.x - mo.x),(t.y - mo.y),(t.z - mo.z),length=3},AMT)),st.count,(0.35 * (st.count - 1)),i),dist=0,out=true,md=md,dmg=st.dmg,size=(3 * st.size),tint=md.tint,id=Math_random()});
i = i + 1;
end
end;
end;
end);
S.R.mines = S.R.mines:filter(function(_this, mn)
local hit;
mn.life = (mn.life - dt);
mn.arm = (mn.arm - dt);
if (mn.arm <= 0) then
hit = false;
S.near(nil,mn.x,mn.y,mn.z,mn.r,function(_this, e)
if ((not T(e.d.ore)) and (S.dd(nil,mn,e) < (mn.r * mn.r))) then
hit = true;
end;
end);
if T(hit) then
S.R.novas:push({x=mn.x,y=mn.y,z=mn.z,r=(mn.r * 1.2),life=0.4,tint=mn.tint});
S.modArea(nil,mn.md,mn,(mn.r * 1.2),mn.dmg,14);
S.C:sfx("pop");
do return false end;
end;
end;
do return (mn.life > 0) end;
end);
S.R.booms = S.R.booms:filter(function(_this, b)
local sp, v, l;
sp = (42 * dt);
if T(b.out) then
b.x = (b.x + (b.d[0] * sp));
b.y = (b.y + (b.d[1] * sp));
b.z = (b.z + (b.d[2] * sp));
b.dist = (b.dist + sp);
if (b.dist > 26) then
b.out = false;
end;
else
v = smt({[0]=(S.R.px - b.x),(S.R.py - b.y),(S.R.pz - b.z),length=3},AMT); l = (function() local _t = S.len3(nil,v[0],v[1],v[2]); if T(_t) then return _t end; return 1 end)();
if (l < 2.5) then
do return false end;
end;
b.x = (b.x + (((v[0] / l) * sp) * 1.2));
b.y = (b.y + (((v[1] / l) * sp) * 1.2));
b.z = (b.z + (((v[2] / l) * sp) * 1.2));
end;
S.near(nil,b.x,b.y,b.z,4,function(_this, e)
local key;
key = ("bm" .. S2(b.id));
if (((not T(e.d.ore)) and (S.dd(nil,b,e) < Math_pow((e.r + 1.5),2))) and ((T(e[key]) and e[key] or 0) <= S.R.t)) then
e[key] = (S.R.t + 0.5);
S.modHit(nil,b.md,e,b.dmg,b,5);
end;
end);
do return true end;
end);
S.R.strikes = S.R.strikes:filter(function(_this, st)
st.life = (st.life - dt);
do return (st.life > 0) end;
end);
end;
S.activeCdMax = function(_this)
do return (((S.M(nil)).active).cd * S.cdMult(nil)) end;
end;
S.say = function(_this, who, id)
S.R.bubbles = S.R.bubbles:filter(function(_this, b)
do return (b.who ~= who) end;
end);
S.R.bubbles:push({who=who,text=S.pick(nil,(S.C:char(id)).lines),life=1.6});
end;
S.moveDir = function(_this)
local v, l;
v = smt({[0]=S.R.vx,S.R.vy,S.R.vz,length=3},AMT); l = S.len3(nil,v[0],v[1],v[2]);
do return ((l > 1) and smt({[0]=(v[0] / l),(v[1] / l),(v[2] / l),length=3},AMT) or S.camBasis.f) end;
end;
S.castActive = function(_this)
local id, m, aw, t, p, po, o0, dv, c, n, j, tx, ty, tz, s0;
if ((((not T(S.R)) or (S.R.activeCd > 0)) or T(S.R.over)) or T(S.paused)) then
do return end;
end;
S.C:sfx("skill");
if T(S.R.tutorial) then
S.R.tutorial:event("skill");
end;
id = (S.M(nil)).skill; m = (S.R.mMul * (1 + S.R.st.active)); aw = (S.C:mechLv(S.R.mech) >= S.C.MECH_AWAKE); p = S.P(nil); po = S.R.pose;
S.R.activeCd = S.activeCdMax(nil);
S.say(nil,"pilot",S.R.pilot);
if (S.R.nitroT > 0) then
m = (m * 1.3);
S.R.activeCd = (S.R.activeCd * 0.8);
S.R.nitroT = 0;
S.A:toast("氮气强化：技能伤害 +30%，冷却 -20%");
S.R.shake = Math_max(S.R.shake,0.1);
end;
if (id == "char_xingli") then
S.setCast(nil,"beam",0.6);
o0 = S.mainMz(nil,0);
S.muzzleFx(nil,o0,S.camBasis.f,1.6);
S.later(nil,0.2,function(_this)
local o, tt, bd;
o = S.mainMz(nil,0); tt = S.target(nil,o.x,o.y,o.z,90); bd = (function() if T(tt) then return S.nrm(nil,smt({[0]=(tt.x - o.x),(tt.y - o.y),(tt.z - o.z),length=3},AMT)) else return S.camBasis.f end end)();
;((T(aw) and smt({[0]=0,1,2,length=3},AMT) or smt({[0]=0,length=1},AMT))):forEach(function(_this, i, _, arr)
local bv;
bv = S.fan(nil,bd,LEN(arr),0.7,i);
S.R.beams:push({x=o.x,y=o.y,z=o.z,d=bv,len=90,life=0.2});
S.beamHit(nil,o,bv,90,3,function(_this, e)
S.hurtEnemy(nil,e,(230 * m),(bv[0] * 8),(bv[1] * 8),(bv[2] * 8));
end);
end);
S.muzzleFx(nil,o,bd,2.2);
S.kick(nil,"R",1.4,1.2);
S.R.shake = 0.3;
end);
elseif (id == "char_chiyan") then
S.setCast(nil,"slash",0.55);
t = S.target(nil,S.R.px,S.R.py,S.R.pz,40);
dv = (function() if (S.len3(nil,S.R.vx,S.R.vy,S.R.vz) > 1) then return S.moveDir(nil) else return (function() if T(t) then return S.nrm(nil,smt({[0]=(t.x - p.x),(t.y - p.y),(t.z - p.z),length=3},AMT)) else return S.camBasis.f end end)() end end)();
S.R.dash = {t=0,dur=0.35,x0=p.x,y0=p.y,z0=p.z,x1=(p.x + (dv[0] * 32)),y1=(p.y + (dv[1] * 32)),z1=(p.z + (dv[2] * 32)),dmg=(140 * m),hit=smt({length=0},AMT),inv=true,d=dv,fire=aw};
elseif (id == "char_yuexi") then
S.setCast(nil,"heal",0.9);
S.later(nil,0.25,function(_this)
local q, o, k;
q = S.P(nil);
S.R.zones:push({x=q.x,y=q.y,z=q.z,r=13,life=6,heal=0.08,dmg=((T(aw) and 50 or 25) * m),tick=0});
o = S.mainMz(nil,0);
do
k = 0;
while (k < 10) do
S.R.parts:push({model="fx_spark_teal",x=o.x,y=o.y,z=o.z,vx=S.rand(nil,(-4),4),vy=S.rand(nil,2,9),vz=S.rand(nil,(-4),4),life=0.6,max=0.6,size=2,noGrav=true});
k = k + 1;
end
end;
end);
elseif (id == "char_hupo") then
S.setCast(nil,"deploy",0.6);
S.later(nil,0.22,function(_this)
local i, tp;
do
i = 0;
while (i < (T(aw) and 5 or 3)) do
tp = S.turretSpot(nil,i,(T(aw) and 5 or 3));
S.newTurret(nil,tp,{life=10,fire=0,dmg=(3.5 * m),blast=true});
i = i + 1;
end
end;
end);
elseif (id == "char_shuangling") then
S.setCast(nil,"salvo",0.8);
t = S.target(nil,S.R.px,S.R.py,S.R.pz,60);
c = (T(t) and t or {x=(p.x + (S.camBasis.f[0] * 15)),y=(p.y + (S.camBasis.f[1] * 15)),z=(p.z + (S.camBasis.f[2] * 15))}); n = (T(aw) and 32 or 16);
do
j = 0;
while (j < n) do
tx = (c.x + S.rand(nil,(-11),11)); ty = (c.y + S.rand(nil,(-6),6)); tz = (c.z + S.rand(nil,(-11),11));
S.R.missiles:push((S.podLaunch(nil,{fall=true,x=tx,y=((ty + 30) + (j * 2.5)),z=tz,tx=tx,ty=ty,tz=tz,dmg=(15 * m),splash=(5 * S.blast(nil)),slowR=6,life=6,model="fx_missile",size=2.4},j,0.025)));
j = j + 1;
end
end;
elseif (id == "starfall") then
S.setCast(nil,"meteor",0.9);
t = S.target(nil,S.R.px,S.R.py,S.R.pz,60);
s0 = (T(t) and {x=t.x,y=t.y,z=t.z} or {x=(p.x + (S.camBasis.f[0] * 18)),y=(p.y + (S.camBasis.f[1] * 18)),z=(p.z + (S.camBasis.f[2] * 18))});
S.later(nil,0.3,function(_this)
local o, gd, q;
o = S.mainMz(nil,0); gd = S.nrm(nil,smt({[0]=(s0.x - o.x),((s0.y + 45) - o.y),(s0.z - o.z),length=3},AMT));
S.R.beams:push({x=o.x,y=o.y,z=o.z,d=gd,len=Math_sqrt((S.d3(nil,s0.x,(s0.y + 45),s0.z,o.x,o.y,o.z))),life=0.35,tint=S.R.pose.col});
S.muzzleFx(nil,o,gd,2);
do
q = 0;
while (q < (T(aw) and 2 or 1)) do
S.R.missiles:push({fall=true,meteor=true,x=(s0.x + (q * 6)),y=((s0.y + 45) + (q * 25)),z=(s0.z + (q * 4)),tx=(s0.x + (q * 6)),ty=s0.y,tz=(s0.z + (q * 4)),dmg=(200 * m),splash=(7 * S.blast(nil)),life=8,model="prop_meteor_shard",size=3.5});
q = q + 1;
end
end;
end);
end;
end;
S.turretSpot = function(_this, i, n)
local a, r, f, fl;
a = ((((function() if (n > 1) then return (i / (n - 1)) else return 0.5 end end)() * Math_PI) - (Math_PI / 2)) + S.rand(nil,(-0.15),0.15)); r = S.camBasis.r; f = smt({[0]=S.camBasis.f[0],0,S.camBasis.f[2],length=3},AMT); fl = (function() local _t = Math_hypot(f[0],f[2]); if T(_t) then return _t end; return 1 end)();
f = smt({[0]=(f[0] / fl),0,(f[2] / fl),length=3},AMT);
do return smt({[0]=((S.R.px + ((r[0] * Math_sin(a)) * 7)) + (f[0] * ((Math_cos(a) * 6) + 5))),(S.R.py + S.rand(nil,(-1.5),2.5)),((S.R.pz + ((r[2] * Math_sin(a)) * 7)) + (f[2] * ((Math_cos(a) * 6) + 5))),length=3},AMT) end;
end;
S.perfMul = function(_this)
local sv;
sv = (function() local _t = S.C.save; if not T(_t) then return _t end; return S.C.save.settings end)();
do return Math_min((T(HOST.window.__perf) and HOST.window.__perf or 1),((T(sv) and T(sv.saver)) and 0.6 or 1)) end;
end;
S.nitroOf = function(_this)
local nd;
if (T(S.R) and T(S.R.nit)) then
do return S.R.nit.st end;
end;
nd = S.C:nitroDef((S.C:nativeNitro((function() if T(S.R) then return S.R.mech else return "mech_azure" end end)())));
do return G.Object:assign({name=nd.n},nd) end;
end;
S.dodge = function(_this)
local N, dv, p, po, tg, W;
if (((((not T(S.R)) or T(S.R.dash)) or T(S.R.over)) or T(S.paused)) or (S.R.dodgeCd > 0)) then
do return end;
end;
N = S.nitroOf(nil); dv = S.moveDir(nil); p = S.P(nil); po = S.R.pose; tg = (function() if ((T(po) and T(po.tg)) and (po.tg.hp > 0)) then return po.tg else return nil end end)();
if (T(N.retreat) and T(tg)) then
dv = S.nrm(nil,smt({[0]=(S.R.px - tg.x),(S.R.py - tg.y),(S.R.pz - tg.z),length=3},AMT));
end;
S.R.dash = {t=0,dur=N.dur,x0=p.x,y0=p.y,z0=p.z,x1=(p.x + ((dv[0] * N.dist) * (1 + S.R.st.nitroDist))),y1=(p.y + ((dv[1] * N.dist) * (1 + S.R.st.nitroDist))),z1=(p.z + ((dv[2] * N.dist) * (1 + S.R.st.nitroDist))),dmg=((T(N.ram) and N.ram or 0) * S.R.mMul),hit=smt({length=0},AMT),inv=true,invT=N.inv,d=dv,dodge=true,nitro=true,easeOut=true};
S.R.nitroT = 2.2;
S.R.dodgeCd = ((N.cd * (1 - S.fx(nil,"dodge"))) * (1 - Math_min(0.5,S.R.st.nitro)));
S.C:sfx("nitro");
S.R.shake = Math_max(S.R.shake,0.12);
if T(N.heal) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * N.heal)));
end;
if T(N.retreat) then
S.R.novas:push({x=p.x,y=p.y,z=p.z,r=9,life=0.45,color="#57B8FF"});
S.near(nil,p.x,p.y,p.z,12,function(_this, e)
e.slowT = 2;
end);
end;
W = (function() local _t = po; if not T(_t) then return _t end; return po.W end)();
if T(W) then
W.rear:forEach(function(_this, n)
local k;
do
k = 0;
while ((k < 7) and (LEN(S.R.parts) < 250)) do
S.R.parts:push({model="fx_white",x=n[0],y=n[1],z=n[2],vx=((W.rearD[0] * S.rand(nil,10,24)) + S.rand(nil,(-2),2)),vy=((W.rearD[1] * S.rand(nil,10,24)) + S.rand(nil,(-2),2)),vz=((W.rearD[2] * S.rand(nil,10,24)) + S.rand(nil,(-2),2)),life=0.5,max=0.5,size=2.4,tint=po.col,noGrav=true});
k = k + 1;
end
end;
end);
end;
end;
S.updateActive = function(_this, dt)
local d, k, da;
S.R.nitroT = Math_max(0,((T(S.R.nitroT) and S.R.nitroT or 0) - dt));
S.R.activeCd = Math_max(0,(S.R.activeCd - dt));
S.R.dodgeCd = Math_max(0,(S.R.dodgeCd - dt));
if T(S.R.dash) then
d = S.R.dash;
d.t = (d.t + dt);
k = Math_min(1,(d.t / d.dur));
if T(d.invT) then
d.inv = (d.t < d.invT);
end;
if T(d.easeOut) then
k = (1 - ((1 - k) * (1 - k)));
end;
S.R.px = S.lerp(nil,d.x0,d.x1,k);
S.R.py = S.lerp(nil,d.y0,d.y1,k);
S.R.pz = S.lerp(nil,d.z0,d.z1,k);
if T(d.dmg) then
S.near(nil,S.R.px,S.R.py,S.R.pz,6,function(_this, e)
if ((d.hit:indexOf(e) < 0) and (S.d3(nil,S.R.px,S.R.py,S.R.pz,e.x,e.y,e.z) < Math_pow((4 + e.r),2))) then
d.hit:push(e);
S.hurtEnemy(nil,e,d.dmg,(d.d[0] * 35),(d.d[1] * 35),(d.d[2] * 35));
end;
end);
end;
S.emb(nil,S.R.px,S.R.py,S.R.pz,(function() if (T(S.R.pose) and T(S.R.pose.ok)) then return S.R.pose.col else return S.EMBER end end)(),3,5,0.5,2.2);
if ((not T(d.dodge)) or T(d.nitro)) then
da = S.angOf(nil,d.d);
S.R.yaw = (S.R.yaw + S.clamp(nil,S.wrapA(nil,(da[0] - S.R.yaw)),((-900) * dt),(900 * dt)));
S.R.pitch = S.lerp(nil,S.R.pitch,S.clamp(nil,(da[1] * 0.7),(-50),50),(1 - Math_exp(((-dt) * 14))));
end;
if (T(d.fire) and (Math_random() < 0.6)) then
S.R.fires:push({x=S.R.px,y=S.R.py,z=S.R.pz,life=3,tick=0});
end;
if (d.t >= d.dur) then
S.R.dash = nil;
S.R.iframe = (T(d.nitro) and 0.1 or 0.3);
end;
end;
S.R.zones = S.R.zones:filter(function(_this, z)
z.life = (z.life - dt);
z.tick = (z.tick - dt);
if (S.d3(nil,S.R.px,S.R.py,S.R.pz,z.x,z.y,z.z) < (z.r * z.r)) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + ((S.hullMax(nil) * z.heal) * dt)));
end;
S.near(nil,z.x,z.y,z.z,(z.r + 3),function(_this, e)
if (S.dd(nil,z,e) < (z.r * z.r)) then
e.slow = true;
if (T(z.dmg) and (z.tick <= 0)) then
S.hurtEnemy(nil,e,(z.dmg * 0.5),0,0,0,true);
end;
end;
end);
if (z.tick <= 0) then
z.tick = 0.5;
end;
do return (z.life > 0) end;
end);
S.R.fires = S.R.fires:filter(function(_this, f)
f.life = (f.life - dt);
f.tick = (f.tick - dt);
if (f.tick <= 0) then
f.tick = 0.5;
S.near(nil,f.x,f.y,f.z,5,function(_this, e)
if (S.dd(nil,f,e) < (9 + (e.r * e.r))) then
S.hurtEnemy(nil,e,(10 * S.R.mMul),0,0,0,true);
end;
end);
end;
if (Math_random() < 0.3) then
S.sparks(nil,f.x,f.y,f.z,"fx_spark",1,3,0.5);
end;
do return (f.life > 0) end;
end);
end;
S.supportStat = function(_this)
local l;
l = S.lv(nil,"support");
do return {dmg=(((1 + (0.35 * (l - 1))) * S.R.cStar) * (1 + S.R.st.sup)),cd=((1 - (0.1 * (l - 1))) * S.cdMult(nil)),count=((l >= 5) and 2 or 1),lv=l} end;
end;
S.updateSupport = function(_this, dt)
local c, id, st, ch, p, k, ts, mo, i, tp, w, tg, e0, m, tt, tx, ty, tz;
c = S.R.cop; id = S.R.pilot; st = S.supportStat(nil); ch = S.C:char(id); p = S.P(nil);
if T(c.dash) then
c.dash.t = (c.dash.t + dt);
k = Math_min(1,(c.dash.t / 0.38));
c.x = S.lerp(nil,c.dash.x0,c.dash.x1,k);
c.y = S.lerp(nil,c.dash.y0,c.dash.y1,k);
c.z = S.lerp(nil,c.dash.z0,c.dash.z1,k);
S.near(nil,c.x,c.y,c.z,6,function(_this, e)
if ((c.dash.hit:indexOf(e) < 0) and (S.dd(nil,c,e) < Math_pow((3.5 + e.r),2))) then
c.dash.hit:push(e);
S.hurtEnemy(nil,e,c.dash.dmg,(c.dash.d[0] * 30),(c.dash.d[1] * 30),(c.dash.d[2] * 30));
end;
end);
S.sparks(nil,c.x,c.y,c.z,"fx_spark",3,6,0.4);
if (k >= 1) then
c.dash.left = c.dash.left - 1;
if (c.dash.left > 0) then
S.copDash(nil,c,c.dash.dmg,c.dash.left);
else
c.dash = nil;
end;
end;
else
c.x = S.R.px;
c.y = S.R.py;
c.z = S.R.pz;
end;
if T(S.fx(nil,"regen")) then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + ((S.hullMax(nil) * S.fx(nil,"regen")) * dt)));
end;
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (((0.6 * S.lv(nil,"repair")) + S.R.st.regen) * dt)));
S.R.supportCd = (S.R.supportCd - dt);
if (S.R.supportCd > 0) then
do return end;
end;
S.R.supportCd = (ch.support.cd * st.cd);
if (id == "char_xingli") then
ts = ((S.R.enemies:filter(function(_this, e)
do return ((not T(e.d.ore)) and (S.dd(nil,p,e) < 2500)) end;
end)):sort(function(_this, a, b)
do return (b.hp - a.hp) end;
end)):slice(0,st.count);
if (not T(LEN(ts))) then
S.R.supportCd = 0.5;
do return end;
end;
mo = S.mainMz(nil,0);
ts:forEach(function(_this, t)
local bv;
bv = S.nrm(nil,smt({[0]=(t.x - mo.x),(t.y - mo.y),(t.z - mo.z),length=3},AMT));
S.R.beams:push({x=mo.x,y=mo.y,z=mo.z,d=bv,len=60,life=0.2});
S.muzzleFx(nil,mo,bv,0.8);
S.beamHit(nil,mo,bv,60,1.6,function(_this, e)
S.hurtEnemy(nil,e,(55 * st.dmg),(bv[0] * 8),(bv[1] * 8),(bv[2] * 8));
end);
end);
elseif (id == "char_chiyan") then
S.copDash(nil,c,(70 * st.dmg),st.count);
elseif (id == "char_yuexi") then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (15 * st.dmg)));
S.nova(nil,p,10,((15 * st.dmg) * ((st.lv >= 5) and 2 or 1)),"#7CF29A");
elseif (id == "char_hupo") then
do
i = 0;
while (i < st.count) do
tp = S.turretSpot(nil,(LEN(S.R.turrets) + i),4);
S.newTurret(nil,tp,{life=8,dmg=(4 * st.dmg)});
i = i + 1;
end
end;
elseif (id == "char_yeyuan") then
do
w = 0;
while (w < st.count) do
tg = S.R.enemies:filter(function(_this, e)
do return ((not T(e.d.ore)) and (S.dd(nil,p,e) < 1600)) end;
end);
if T(LEN(tg)) then
e0 = S.pick(nil,tg);
S.R.wells:push({x=e0.x,y=e0.y,z=e0.z,r=10,life=3,dmg=(16 * st.dmg),tick=0});
end;
w = w + 1;
end
end;
elseif (id == "char_shuangling") then
do
m = 0;
while (m < (7 * st.count)) do
tt = (function() if T(LEN(S.R.enemies)) then return S.pick(nil,S.R.enemies) else return nil end end)(); tx = (function() if T(tt) then return tt.x else return (p.x + S.rand(nil,(-25),25)) end end)(); ty = (function() if T(tt) then return tt.y else return p.y end end)(); tz = (function() if T(tt) then return tt.z else return (p.z + S.rand(nil,(-25),25)) end end)();
S.R.missiles:push((S.podLaunch(nil,{fall=true,x=tx,y=((ty + 32) + (m * 3)),z=tz,tx=tx,ty=ty,tz=tz,dmg=(12 * st.dmg),splash=(5 * S.blast(nil)),life=5,model="fx_missile",size=2.2},m,0.03)));
m = m + 1;
end
end;
end;
S.say(nil,"cop",id);
end;
S.copDash = function(_this, c, dmg, left)
local t, dv;
t = S.target(nil,S.R.px,S.R.py,S.R.pz,35); dv = (function() if T(t) then return S.nrm(nil,smt({[0]=(t.x - S.R.px),(t.y - S.R.py),(t.z - S.R.pz),length=3},AMT)) else return S.camBasis.f end end)();
c.dash = {t=0,x0=c.x,y0=c.y,z0=c.z,x1=(S.R.px + (dv[0] * 26)),y1=(S.R.py + (dv[1] * 26)),z1=(S.R.pz + (dv[2] * 26)),d=dv,dmg=dmg,hit=smt({length=0},AMT),left=left};
end;
S.updateTurrets = function(_this, dt)
S.R.turrets = S.R.turrets:filter(function(_this, tu)
local t, dv;
tu.life = (tu.life - dt);
tu.fire = (tu.fire - dt);
if (tu.dep > 0) then
tu.dep = (tu.dep - dt);
do return true end;
end;
t = S.target(nil,tu.x,tu.y,tu.z,34);
if T(t) then
dv = S.nrm(nil,smt({[0]=(t.x - tu.x),(t.y - tu.y),(t.z - tu.z),length=3},AMT));
tu.yaw = (Math_atan2(dv[0],dv[2]) / S.DEG);
if (tu.fire <= 0) then
tu.fire = 0.4;
S.shot(nil,tu,dv,60,{dmg=(tu.dmg * ((1 + S.R.st.summon) + S.fx(nil,"turret"))),blastR=(function() if T(tu.blast) then return (3 * S.blast(nil)) else return 0 end end)(),pierce=(T(tu.blast) and 0 or 2),life=0.8,model="fx_laser_player"});
end;
end;
do return (tu.life > 0) end;
end);
S.R.wells = S.R.wells:filter(function(_this, w)
local hitNow, d, im;
w.life = (w.life - dt);
w.tick = ((T(w.tick) and w.tick or 0) - dt);
hitNow = (T(w.dmg) and (w.tick <= 0));
if T(hitNow) then
w.tick = 0.5;
end;
S.near(nil,w.x,w.y,w.z,(w.r + 3),function(_this, e)
local v, l, s;
v = smt({[0]=(w.x - e.x),(w.y - e.y),(w.z - e.z),length=3},AMT); l = (function() local _t = S.len3(nil,v[0],v[1],v[2]); if T(_t) then return _t end; return 1 end)();
if (l < w.r) then
e.slow = true;
if ((T(w.dmg) and (not T(e.d.boss))) and (not T(e.d.ore))) then
s = (Math_min(l,(12 * dt)) / l);
e.x = (e.x + (v[0] * s));
e.y = (e.y + (v[1] * s));
e.z = (e.z + (v[2] * s));
end;
if (T(hitNow) and (not T(e.d.ore))) then
S.hurtEnemy(nil,e,(w.dmg * 0.5),0,0,0,true);
end;
end;
end);
if (T(w.dmg) and (Math_random() < 0.8)) then
d = S.randDir(nil);
S.R.parts:push({model="fx_white",x=(w.x + (d[0] * w.r)),y=(w.y + (d[1] * w.r)),z=(w.z + (d[2] * w.r)),vx=(((-d[0]) * w.r) * 1.5),vy=(((-d[1]) * w.r) * 1.5),vz=(((-d[2]) * w.r) * 1.5),life=0.6,max=0.6,size=2,tint=smt({[0]=0.55,0.3,1.1,length=3},AMT),noGrav=true});
end;
if ((w.life <= 0) and T(w.implode)) then
im = w.implode;
S.explode(nil,w.x,w.y,w.z,im.r,im.dmg);
S.ringBurst(nil,w.x,w.y,w.z,(im.r * 1.2),im.tint,0.45);
S.R.shake = Math_max(S.R.shake,0.3);
S.C:sfx("boom");
end;
do return (w.life > 0) end;
end);
S.R.beams = S.R.beams:filter(function(_this, b)
b.life = (b.life - dt);
do return (b.life > 0) end;
end);
end;
S.updateNodes = function(_this, dt)
local p;
S.R.nearNode = nil;
p = S.P(nil);
S.R.nodes:forEach(function(_this, n)
local d, i, q, ri, rq, j, q2, j2, q3, g, o, r, og, oq, s, w, en, hs, hq, kinds, as, aq, b, hv, ha;
d = Math_sqrt((S.dd(nil,p,n)));
if (((d < 40) and (n.state ~= "done")) and (n.state ~= "hidden")) then
S.R.nearNode = n;
end;
if (n.state == "done") then
do return end;
end;
if (n.type == "pirate") then
if ((n.state == "idle") and (d < 34)) then
n.state = "active";
S.banner(nil,"海贼据点：清剿全部海贼");
n.total = (10 + (S.R.ch.id * 4));
do
i = 0;
while (i < n.total) do
q = S.spherePos(nil,n,(S.rand(nil,6,18)));
S.spawnEnemy(nil,S.pick(nil,smt({[0]="grunt","grunt","inter",((S.R.ch.id > 1) and "heavy" or "grunt"),length=4},AMT)),q[0],q[1],q[2],n);
i = i + 1;
end
end;
elseif (((n.state == "active") and (not T(n.reinf))) and (LEN((S.R.enemies:filter(function(_this, e)
do return (e.node == n) end;
end))) <= (n.total * 0.4))) then
n.reinf = true;
S.banner(nil,"海贼增援抵达！");
S.C:sfx("gate");
do
ri = 0;
while (ri < (5 + (S.R.ch.id * 2))) do
rq = S.spherePos(nil,n,(S.rand(nil,26,36)));
S.spawnEnemy(nil,((ri == 0) and "heavy" or S.pick(nil,smt({[0]="grunt","inter","inter",length=3},AMT))),rq[0],rq[1],rq[2],n);
ri = ri + 1;
end
end;
elseif ((n.state == "active") and (not S.R.enemies:some(function(_this, e)
do return (e.node == n) end;
end))) then
n.state = "done";
S.R.pickups:push({kind="chest",x=n.x,y=n.y,z=n.z,cr=(80 * S.R.ch.id),lvl=1});
S.banner(nil,"据点清剿完成！");
end;
elseif (n.type == "derelict") then
if (d < 15) then
if (n.state == "idle") then
n.state = "active";
do
j = 0;
while (j < (12 + (S.R.ch.id * 3))) do
q2 = S.spherePos(nil,n,40);
S.spawnEnemy(nil,"crawler",q2[0],q2[1],q2[2],n);
j = j + 1;
end
end;
end;
n.progress = (n.progress + ((dt / 7) * (1 + S.fx(nil,"loot"))));
if ((n.progress >= 0.5) and (not T(n.wave2))) then
n.wave2 = true;
S.banner(nil,"第二波虫群来袭！");
do
j2 = 0;
while (j2 < (8 + (S.R.ch.id * 3))) do
q3 = S.spherePos(nil,n,(S.rand(nil,30,42)));
S.spawnEnemy(nil,((MOD(j2,3) == 0) and "bomber" or "crawler"),q3[0],q3[1],q3[2],n);
j2 = j2 + 1;
end
end;
end;
if (n.progress >= 1) then
n.state = "done";
S.R.enemies:forEach(function(_this, e)
if (e.node == n) then
e.node = nil;
end;
end);
S.addCredits(nil,(120 * S.R.ch.id));
do
g = 0;
while (g < 12) do
S.R.gems:push({x=(n.x + S.rand(nil,(-5),5)),y=(n.y + S.rand(nil,(-5),5)),z=(n.z + S.rand(nil,(-5),5)),v=1});
g = g + 1;
end
end;
if (Math_random() < 0.6) then
S.gainFrag(nil,2);
end;
S.banner(nil,("搜刮完成：信用点 +" .. S2((120 * S.R.ch.id))));
end;
end;
elseif (n.type == "ore") then
if ((n.state == "idle") and (d < 48)) then
n.state = "active";
do
o = 0;
while (o < 8) do
r = S.spherePos(nil,n,(S.rand(nil,3,14)));
S.spawnEnemy(nil,"ore",r[0],r[1],r[2],n);
o = o + 1;
end
end;
S.banner(nil,"护矿虫群出现！");
do
og = 0;
while (og < (6 + (S.R.ch.id * 2))) do
oq = S.spherePos(nil,n,(S.rand(nil,18,26)));
S.spawnEnemy(nil,(((MOD(og,4) == 0) and (S.R.ch.id >= 2)) and "splitter" or "crawler"),oq[0],oq[1],oq[2]);
og = og + 1;
end
end;
elseif ((n.state == "active") and (not S.R.enemies:some(function(_this, e)
do return (e.node == n) end;
end))) then
n.state = "done";
S.banner(nil,"富矿开采完毕");
end;
elseif (n.type == "distress") then
if ((n.state == "idle") and (d < 18)) then
n.state = "active";
n.timer = 20;
S.banner(nil,"守住逃生舱 20 秒！");
end;
if (n.state == "active") then
n.timer = (n.timer - dt);
n.spawn = ((T(n.spawn) and n.spawn or 0) - dt);
if (n.spawn <= 0) then
n.spawn = 2.2;
do
s = 0;
while (s < (3 + S.R.ch.id)) do
w = S.spherePos(nil,n,45);
en = S.spawnEnemy(nil,S.pick(nil,smt({[0]="inter","grunt","crawler",length=3},AMT)),w[0],w[1],w[2],n);
en.podHunter = (Math_random() < 0.5);
s = s + 1;
end
end;
end;
if (n.pod.hp <= 0) then
n.state = "done";
n.failed = true;
S.sparks(nil,n.x,n.y,n.z,"fx_spark",40,20,1);
n.objs = n.objs:slice(1);
S.banner(nil,"逃生舱被击毁了……");
elseif (n.timer <= 0) then
n.state = "done";
S.R.src = (S.R.src + 5);
S.addCredits(nil,(100 * S.R.ch.id));
S.banner(nil,"营救成功：星源 +5");
S.R.enemies:forEach(function(_this, e)
if (e.node == n) then
e.podHunter = false;
end;
end);
end;
end;
elseif (n.type == "hunt") then
if ((n.state == "idle") and (d < 40)) then
n.state = "active";
n.timer = 40;
n.k0 = S.R.kills;
n.need = (30 + (10 * S.R.ch.id));
n.spawn = 0;
S.banner(nil,(("限时猎杀：40 秒内击败 " .. S2(n.need)) .. " 个敌人！"));
end;
if (n.state == "active") then
n.timer = (n.timer - dt);
n.spawn = (n.spawn - dt);
n.got = (S.R.kills - n.k0);
if (n.spawn <= 0) then
n.spawn = 1.6;
do
hs = 0;
while (hs < (4 + S.R.ch.id)) do
hq = S.spherePos(nil,n,(S.rand(nil,25,45)));
S.spawnEnemy(nil,S.pick(nil,smt({[0]="crawler","crawler","grunt",length=3},AMT)),hq[0],hq[1],hq[2],n);
hs = hs + 1;
end
end;
end;
if (n.got >= n.need) then
n.state = "done";
S.R.enemies:forEach(function(_this, e)
if (e.node == n) then
e.node = nil;
end;
end);
S.R.pickups:push({kind="chest",x=n.x,y=n.y,z=n.z,cr=(100 * S.R.ch.id),lvl=1});
S.R.src = (S.R.src + 3);
S.banner(nil,"猎杀成功！战利品已掉落，星源 +3");
S.C:sfx("win");
elseif (n.timer <= 0) then
n.state = "done";
n.failed = true;
S.R.enemies:forEach(function(_this, e)
if (e.node == n) then
e.node = nil;
end;
end);
S.banner(nil,"时间到，猎杀失败");
end;
end;
elseif (n.type == "ambush") then
if ((n.state == "idle") and (d < 34)) then
n.state = "active";
n.wave = 0;
end;
if ((n.state == "active") and (not S.R.enemies:some(function(_this, e)
do return (e.node == n) end;
end))) then
if (n.wave >= 3) then
n.state = "done";
S.R.pickups:push({kind="chest",x=n.x,y=n.y,z=n.z,cr=(130 * S.R.ch.id),lvl=1});
S.gainFrag(nil,2);
S.banner(nil,"伏击瓦解！");
S.C:sfx("win");
else
n.wave = n.wave + 1;
S.banner(nil,(("伏击！第 " .. S2(n.wave)) .. " / 3 波"));
kinds = ((n.wave == 1) and smt({[0]="grunt","grunt","inter",length=3},AMT) or ((n.wave == 2) and smt({[0]="heavy","grunt","inter",length=3},AMT) or smt({[0]="brute","heavy","inter",length=3},AMT)));
do
as = 0;
while (as < (function() if (n.wave == 3) then return (4 + S.R.ch.id) else return (8 + (S.R.ch.id * 2)) end end)()) do
aq = S.spherePos(nil,n,(S.rand(nil,15,28)));
S.spawnEnemy(nil,(((n.wave == 3) and (as == 0)) and "brute" or S.pick(nil,(kinds:filter(function(_this, k)
do return (k ~= "brute") end;
end)))),aq[0],aq[1],aq[2],n);
as = as + 1;
end
end;
end;
end;
elseif (n.type == "merchant") then
if ((d < 18) and (not T(n.cool))) then
n.cool = true;
S.openShop(nil,n);
end;
if (d > 32) then
n.cool = false;
end;
elseif (n.type == "nest") then
if ((n.state == "idle") and (d < 32)) then
n.state = "active";
b = S.spherePos(nil,n,6);
n.guard = S.spawnEnemy(nil,"brute",b[0],b[1],b[2],n);
n.guard.max = (n.guard.hp * 1.25);
n.guard.hp = n.guard.max;
n.guard.rageAt = 0.5;
S.banner(nil,"巢穴守卫：晶核巨兽　先摧毁晶簇巢，阻止虫群孵化");
do
hv = 0;
while (hv < 3) do
ha = ((((hv / 3) * Math_PI) * 2) + S.rand(nil,(-0.3),0.3));
S.spawnEnemy(nil,"hive",(n.x + (Math_cos(ha) * 13)),(n.y + S.rand(nil,(-5),5)),(n.z + (Math_sin(ha) * 13)),n);
hv = hv + 1;
end
end;
elseif (n.state == "active") then
n.hives = LEN((S.R.enemies:filter(function(_this, e)
do return (function() local _t = ((e.node == n) and e.d.hive); if not T(_t) then return _t end; return (e.hp > 0) end)() end;
end)));
if ((n.guard.hp <= 0) and (n.hives == 0)) then
n.state = "done";
S.gainFrag(nil,5);
S.R.pickups:push({kind="chest",x=n.x,y=n.y,z=n.z,cr=(150 * S.R.ch.id),lvl=1});
S.banner(nil,"巢穴已摧毁！");
S.C:sfx("win");
end;
end;
elseif ((n.type == "gate") and T(n.risk)) then
if ((n.state == "locked") and (S.R.gate.state == "open")) then
n.state = "open";
end;
if (((n.state == "open") and (d < 15)) and (not T(S.paused))) then
S.nextSector(nil,true);
end;
elseif (n.type == "gate") then
if T(S.charging(nil)) then
S.R.objective = ((((T(S.R.risk) and "险途 · " or "") .. "星门充能：再击败 ") .. S2((S.R.gateNeed - S.R.secKills))) .. " 个敌人");
if (not T(S.R.chargeMsg)) then
S.R.chargeMsg = true;
S.banner(nil,"目标完成！击败敌人为星门充能");
S.C:sfx("gate");
end;
end;
if (((n.state == "locked") and T(S.objectiveDone(nil))) and (not T(S.charging(nil)))) then
n.state = "open";
S.banner(nil,(T(S.R.gate2) and "星门开启！青色「稳航」多修复耐久，红色「险途」更难但必掉宝箱" or "目标完成，星门已开启！冲击波清除了附近的敌人"));
S.C:sfx("gate");
S.R.shake = Math_max(S.R.shake,0.3);
if T(S.R.risk) then
S.R.pickups:push({kind="chest",x=S.R.px,y=S.R.py,z=(S.R.pz + 4),cr=(100 * S.R.ch.id),lvl=1});
S.A:toast("险途奖励：宝箱已掉落在你身边");
end;
if (LEN(S.R.novas) < 12) then
S.R.novas:push({x=S.R.px,y=S.R.py,z=S.R.pz,r=60,life=0.8,dur=0.8,tint=smt({[0]=0.5,1.4,1.3,length=3},AMT),fast=true});
end;
S.R.enemies:forEach(function(_this, e)
if ((T(e.d.ore) or T(e.d.elite)) or T(e.d.boss)) then
do return end;
end;
e.hp = 0;
if (LEN(S.R.gems) < 380) then
S.R.gems:push({x=e.x,y=e.y,z=e.z,v=e.d.xp,pull=true});
end;
end);
S.R.enemies = S.R.enemies:filter(function(_this, e)
do return (e.hp > 0) end;
end);
end;
if (((n.state == "open") and (d < 15)) and (not T(S.paused))) then
S.nextSector(nil,false);
end;
end;
end);
end;
S.gainFrag = function(_this, n)
local owned, id;
owned = G.Object:keys(S.C.save.chars); id = S.pick(nil,owned);
S.R.frags[id] = ((T(S.R.frags[id]) and S.R.frags[id] or 0) + n);
S.A:toast(((S2((S.C:char(id)).name) .. " 碎片 +") .. S2(n)));
end;
S.updatePickups = function(_this, dt)
local pr, pr2, p;
pr = S.pickupR(nil); pr2 = (pr * pr); p = S.P(nil);
S.R.gems = S.R.gems:filter(function(_this, g)
local d2v, d, sp, k;
d2v = S.dd(nil,g,p);
if ((d2v < pr2) or T(g.pull)) then
g.pull = true;
d = (function() local _t = Math_sqrt(d2v); if T(_t) then return _t end; return 1 end)(); sp = (40 + ((pr - Math_min(pr,d)) * 4)); k = ((sp * dt) / d);
g.x = (g.x + ((p.x - g.x) * k));
g.y = (g.y + ((p.y - g.y) * k));
g.z = (g.z + ((p.z - g.z) * k));
end;
if (d2v < (2.5 * 2.5)) then
S.gainXp(nil,g.v);
do return false end;
end;
do return true end;
end);
if (LEN(S.R.gems) > 400) then
S.R.gems:splice(0,(LEN(S.R.gems) - 400));
end;
S.R.pickups = S.R.pickups:filter(function(_this, pk)
local ga;
if (S.dd(nil,pk,p) < (4 * 4)) then
if (pk.kind == "heal") then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.3)));
S.A:toast("耐久修复 30%");
elseif (pk.kind == "ammo") then
ga = (function() if T(S.R.sub) then return Math_min((S.R.sub.cap - S.R.sub.ammo),pk.n) else return 0 end end)();
if T(S.R.sub) then
S.R.sub.ammo = (S.R.sub.ammo + ga);
S.R.sub.gained = (S.R.sub.gained + ga);
end;
S.C:sfx("pick");
S.A:toast(((("弹药箱：" .. S2((function() if T(S.R.sub) then return S.R.sub.def.n else return "副武器" end end)())) .. " +") .. S2(ga)));
else
S.addCredits(nil,pk.cr);
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.15)));
S.R.pendingLevels = (S.R.pendingLevels + (T(pk.lvl) and pk.lvl or 0));
S.R.chestPick = ((T(S.R.chestPick) and S.R.chestPick or 0) + (T(pk.lvl) and pk.lvl or 0));
S.C:sfx("win");
S.R.slowT = Math_max((T(S.R.slowT) and S.R.slowT or 0),0.4);
S.ringBurst(nil,S.R.px,(S.R.py - 2),S.R.pz,10,smt({[0]=1.5,1.2,0.4,length=3},AMT),0.6);
S.A:toast((("宝箱：信用点 +" .. S2(pk.cr)) .. "，宝箱升级效果加倍！"));
end;
do return false end;
end;
do return true end;
end);
end;
S.gainXp = function(_this, v)
if (Math_random() < 0.3) then
S.C:sfx("pick");
end;
S.R.xp = (S.R.xp + (((v * (1 + S.R.st.xp)) * ((S.C.save.runs < 3) and 1.8 or 1)) * (T(S.affix(nil,"fury")) and 1.3 or (T(S.affix(nil,"tide")) and 1.5 or 1))));
while (S.R.xp >= S.xpNeed(nil,S.R.level)) do
S.R.xp = (S.R.xp - S.xpNeed(nil,S.R.level));
S.R.level = S.R.level + 1;
S.R.pendingLevels = S.R.pendingLevels + 1;
end;
end;
S.choices = function(_this)
local p, pool, idx, w, q, out, sum, r, i;
p = LEN(((G.Object:keys(S.UPG)):filter(function(_this, k)
do return ((S.UPG[k].kind == "passive") and (S.lv(nil,k) > 0)) end;
end))); pool = smt({length=0},AMT);
;(G.Object:keys(S.UPG)):forEach(function(_this, k)
local u, l;
u = S.UPG[k]; l = S.lv(nil,k);
if (l >= u.max) then
do return end;
end;
if (((l == 0) and (u.kind == "passive")) and (p >= 4)) then
do return end;
end;
pool:push({id=k,w=((k == "main") and 1.6 or ((k == "support") and 1.5 or 1))});
end);
S.R.mods:forEach(function(_this, md, i)
if (md.lv < 5) then
pool:push({id=("mod" .. S2(i)),w=1.5});
end;
end);
if (T(S.R.sub) and (S.R.sub.ammo < (S.R.sub.cap * 0.5))) then
pool:push({id="ammo",w=1.4});
end;
if ((LEN(S.R.mods) < S.C.RUN_MOD_MAX) and T(LEN(S.R.modPool))) then
idx = S.R.modPool:map(function(_this, _, i)
do return i end;
end); w = ((LEN(S.R.mods) < 3) and 3 or 1.8);
do
q = 0;
while ((q < 2) and T(LEN(idx))) do
pool:push({id=("new" .. S2((idx:splice(Math_floor((Math_random() * LEN(idx))),1))[0])),w=w});
q = q + 1;
end
end;
end;
out = smt({length=0},AMT);
S.R.mods:forEach(function(_this, md, i)
if (T(S.evoReady(nil,md)) and (LEN(out) < 3)) then
out:push(("evo" .. S2(i)));
end;
end);
while ((LEN(out) < 3) and T(LEN(pool))) do
sum = pool:reduce(function(_this, s, x)
do return (s + x.w) end;
end,0); r = (Math_random() * sum); i = 0;
while (r > pool[i].w) do
r = (r - pool[i].w);
i = i + 1;
end;
out:push(pool[i].id);
pool:splice(i,1);
end;
if (not T(LEN(out))) then
out:push("heal");
end;
do return out end;
end;
S.evoReady = function(_this, md)
local ev;
ev = S.C:evoOf(md.m);
do return (not (not (((T(ev) and (not T(md.evo))) and (md.lv >= 5)) and (S.lv(nil,ev.pass) >= S.C.EVO_PASS_LV)))) end;
end;
S.checkEvoReady = function(_this)
S.R.mods:forEach(function(_this, md)
if (T(S.evoReady(nil,md)) and (not T(md.evoHint))) then
md.evoHint = true;
S.banner(nil,(S2(md.m.name) .. " 可以进化了！下次升级必出进化选项"));
S.C:sfx("win");
end;
end);
end;
S.applyChoice = function(_this, id)
local chest;
chest = ((T(S.R.chestPick) and S.R.chestPick or 0) > 0);
if T(chest) then
S.R.chestPick = S.R.chestPick - 1;
end;
S.R.tutPicked = true;
S.applyOne(nil,id);
if T(chest) then
S.chestBonus(nil,id);
end;
end;
S.chestBonus = function(_this, id)
local nmd, md;
if (id:indexOf("new") == 0) then
nmd = S.R.mods[(LEN(S.R.mods) - 1)];
if (T(nmd) and (nmd.lv < 5)) then
nmd.lv = nmd.lv + 1;
S.banner(nil,((("宝箱加倍：" .. S2(nmd.m.name)) .. " 直接 Lv") .. S2(nmd.lv)));
do return end;
end;
elseif (id:indexOf("mod") == 0) then
md = S.R.mods[tonum(id:slice(3))];
if (T(md) and (md.lv < 5)) then
md.lv = md.lv + 1;
S.banner(nil,(("宝箱加倍：" .. S2(md.m.name)) .. " 再 +1 级"));
do return end;
end;
elseif (T(S.UPG[id]) and (S.lv(nil,id) < S.UPG[id].max)) then
S.R.lv[id] = (S.lv(nil,id) + 1);
if (id == "hull") then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.25)));
end;
S.banner(nil,(("宝箱加倍：" .. S2(S.UPG[id].name)) .. " 再 +1 级"));
do return end;
end;
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.3)));
S.banner(nil,"宝箱加倍：额外修复 30% 耐久");
end;
S.applyOne = function(_this, id)
local em, nm, ga;
if (id:indexOf("evo") == 0) then
em = S.R.mods[tonum(id:slice(3))];
em.evo = true;
S.banner(nil,((("进化！" .. S2(em.m.name)) .. " · ") .. S2((S.C:evoOf(em.m)).n)));
S.C:sfx("win");
S.R.shake = Math_max(S.R.shake,0.4);
S.ringBurst(nil,S.R.px,(S.R.py - 2),S.R.pz,14,em.tint,0.6);
S.emb(nil,S.R.px,S.R.py,S.R.pz,em.tint,26,14,0.8,2.4,3);
do return end;
end;
if (id:indexOf("new") == 0) then
nm = (S.R.modPool:splice(tonum(id:slice(3)),1))[0];
if T(nm) then
S.addMod(nil,nm);
end;
do return end;
end;
if (id:indexOf("mod") == 0) then
do local _o79, _k80 = S.R.mods[tonum(id:slice(3))], "lv"; _o79[_k80] = _o79[_k80] + 1 end;
do return end;
end;
if (id == "heal") then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.4)));
do return end;
end;
if (id == "ammo") then
ga = Math_min((S.R.sub.cap - S.R.sub.ammo),8);
S.R.sub.ammo = (S.R.sub.ammo + ga);
S.R.sub.gained = (S.R.sub.gained + ga);
do return end;
end;
S.R.lv[id] = (S.lv(nil,id) + 1);
if (id == "hull") then
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.25)));
end;
end;
S.afterChoice = function(_this)
S.checkEvoReady(nil);
end;
S.modNumText = function(_this, md, nl)
local a, b, t, tg, gf, rh, ev;
a = S.modStat(nil,md); b = S.modStat(nil,(G.Object:assign(JS.dict(),md,{lv=nl}))); t = (((((((("伤害 " .. S2(Math_round(a.dmg))) .. " → ") .. S2(Math_round(b.dmg))) .. "，冷却 ") .. a.cd:toFixed(1)) .. "s → ") .. b.cd:toFixed(1)) .. "s");
if (a.count ~= b.count) then
t = (S2(t) .. ((("，数量 " .. S2(a.count)) .. " → ") .. S2(b.count)));
end;
tg = md.m.tags:map(function(_this, k)
local o;
o = (S.C.MOD_TAGS:filter(function(_this, x)
do return (x.k == k) end;
end))[0];
do return (function() if T(o) then return o.n else return k end end)() end;
end);
gf = S.C:goldTag(md.m);
if T(gf) then
tg:push(("金色：" .. S2(gf.d)));
end;
if T(LEN(tg)) then
t = (S2(t) .. ("。词条：" .. tg:join("、")));
end;
rh = S.C.REACT_HINT[md.m.elem];
if T(rh) then
t = (S2(t) .. ("。元素反应：" .. S2(rh)));
end;
ev = S.C:evoOf(md.m);
if ((T(ev) and (not T(md.evo))) and (nl >= 4)) then
t = (S2(t) .. (((((((("。" .. ((nl >= 5) and "已满级，" or "")) .. "搭配「") .. S2(S.UPG[ev.pass].name)) .. " Lv") .. S2(S.C.EVO_PASS_LV)) .. "」可进化（当前 Lv") .. S2(S.lv(nil,ev.pass))) .. "）"));
end;
do return t end;
end;
S.choiceInfo = function(_this, id)
local next_, nm, em, ev, c0, c1, md, nl, w, c, u;
next_ = (S.lv(nil,id) + 1);
if (id:indexOf("new") == 0) then
nm = S.R.modPool[tonum(id:slice(3))];
do return {name=nm.name,tag="获得新技能",icon=S.A:iconSVG(S.C:modIcon(nm),110),text=S.C:modDesc(nm),crew=true} end;
end;
if (id:indexOf("evo") == 0) then
em = S.R.mods[tonum(id:slice(3))]; ev = S.C:evoOf(em.m); c0 = S.modStat(nil,em); c1 = S.modStat(nil,(G.Object:assign(JS.dict(),em,{evo=true})));
do return {name=((S2(em.m.name) .. " · ") .. S2(ev.n)),tag="★ 进化",evo=true,icon=S.A:iconSVG(S.C:modIcon(em.m),120),text=((((((((((((S2(ev.d) .. "。伤害 ") .. S2(Math_round(c0.dmg))) .. " → ") .. S2(Math_round(c1.dmg))) .. "，冷却 ") .. c0.cd:toFixed(1)) .. "s → ") .. c1.cd:toFixed(1)) .. "s，数量 ") .. S2(c0.count)) .. " → ") .. S2(c1.count)),crew=true} end;
end;
if (id:indexOf("mod") == 0) then
md = S.R.mods[tonum(id:slice(3))]; nl = (md.lv + 1);
do return {name=md.m.name,tag=("技能模块 Lv" .. S2(nl)),icon=S.A:iconSVG(S.C:modIcon(md.m),110),text=S.modNumText(nil,md,nl),crew=true} end;
end;
if (id == "heal") then
do return {name="紧急维修",tag="回复",icon=S.A:iconSVG(S.ICON.heal,120),text="修复 40% 耐久"} end;
end;
if (id == "ammo") then
do return {name="弹药补给",tag="副武器",icon=S.A:iconSVG(S.ICON.ammo,120),text=(((((S2(S.R.sub.def.n) .. " 弹药 +8（当前 ") .. S2(S.R.sub.ammo)) .. " / ") .. S2(S.R.sub.cap)) .. "）")} end;
end;
if (id == "main") then
w = {name=S.R.wpn.def.n};
do return {name=w.name,tag=("主武器 Lv" .. S2(next_)),icon=S.A:catIcon(S.R.mech,80),text=S.UPG.main.desc[(next_ - 1)],crew=true} end;
end;
if (id == "support") then
c = S.C:char(S.R.pilot);
do return {name=((S2(c.name) .. "：") .. S2(c.support.name)),tag=("驾驶员 Lv" .. S2(next_)),icon=S.A:catIcon(S.R.pilot,76),text=S.UPG.support.desc[(next_ - 1)],crew=true} end;
end;
u = S.UPG[id];
do return {name=u.name,tag=("强化 Lv" .. S2(next_)),icon=S.A:iconSVG(S.ICON[id],120),text=u.desc[Math_min((next_ - 1),(LEN(u.desc) - 1))]} end;
end;
S.updatePlayer = function(_this, dt)
local jx, jy, lift, moving, goal, ga, dy, dp, f, r, l, want, sp, k, pl, push, vl, ty, tp, turn, a, ptg, dl, bf;
if T(S.keys.ArrowLeft) then
S.R.camYaw = (S.R.camYaw - (90 * dt));
end;
if T(S.keys.ArrowRight) then
S.R.camYaw = (S.R.camYaw + (90 * dt));
end;
if T(S.keys.ArrowUp) then
S.R.camPitch = (S.R.camPitch - (60 * dt));
end;
if T(S.keys.ArrowDown) then
S.R.camPitch = (S.R.camPitch + (60 * dt));
end;
S.look.idle = (S.look.idle + dt);
jx = S.joy.dx; jy = S.joy.dy;
if T(S.keys.KeyA) then
jx = (-1);
end;
if T(S.keys.KeyD) then
jx = 1;
end;
if T(S.keys.KeyW) then
jy = 1;
end;
if T(S.keys.KeyS) then
jy = (-1);
end;
lift = ((T(S.keys.KeyR) and 1 or 0) - (T(S.keys.KeyF) and 1 or 0));
moving = (((Math_abs(jx) + Math_abs(jy)) + Math_abs(lift)) > 0.05);
if ((((((T(S.setting(nil,"autoCam",true)) and (S.look.idle > 1.6)) and (S.look.id == nil)) and (not T(S.keys.ArrowLeft))) and (not T(S.keys.ArrowRight))) and (not T(S.keys.ArrowUp))) and (not T(S.keys.ArrowDown))) then
goal = (function() if (T(S.R.boss) and (S.R.boss.hp > 0)) then return S.R.boss else return (function() if (not T(S.objectiveDone(nil))) then return S.R.event else return (function() if (S.R.gate.state == "open") then return S.R.gate else return nil end end)() end end)() end end)();
if (T(goal) and (not T(moving))) then
ga = S.angOf(nil,smt({[0]=(goal.x - S.R.px),(goal.y - S.R.py),(goal.z - S.R.pz),length=3},AMT)); dy = (MOD(((ga[0] - S.R.camYaw) + 540),360) - 180); dp = ((S.clamp(nil,ga[1],(-60),60) + 6) - S.R.camPitch);
S.R.camYaw = (S.R.camYaw + S.clamp(nil,dy,((-35) * dt),(35 * dt)));
S.R.camPitch = (S.R.camPitch + S.clamp(nil,dp,((-25) * dt),(25 * dt)));
end;
end;
S.R.camPitch = S.clamp(nil,S.R.camPitch,(-70),70);
if T(S.R.dash) then
do return end;
end;
f = S.fwdOf(nil,S.R.camYaw,S.R.camPitch); r = S.rightOf(nil,S.R.camYaw); l = Math_hypot(jx,jy);
if (l > 1) then
jx = (jx / l);
jy = (jy / l);
end;
want = smt({[0]=((f[0] * jy) + (r[0] * jx)),((f[1] * jy) + lift),((f[2] * jy) + (r[2] * jx)),length=3},AMT); sp = S.speed(nil); k = (1 - Math_exp(((-dt) * 6)));
S.R.vx = S.lerp(nil,S.R.vx,(want[0] * sp),k);
S.R.vy = S.lerp(nil,S.R.vy,(want[1] * sp),k);
S.R.vz = S.lerp(nil,S.R.vz,(want[2] * sp),k);
S.R.px = (S.R.px + (S.R.vx * dt));
S.R.py = (S.R.py + (S.R.vy * dt));
S.R.pz = (S.R.pz + (S.R.vz * dt));
pl = S.len3(nil,S.R.px,S.R.py,S.R.pz);
S.R.outside = (pl > S.BOUND);
if (pl > S.BOUND) then
push = ((((pl - S.BOUND) * 2) * dt) / pl);
S.R.px = (S.R.px - (S.R.px * push));
S.R.py = (S.R.py - (S.R.py * push));
S.R.pz = (S.R.pz - (S.R.pz * push));
end;
vl = S.len3(nil,S.R.vx,S.R.vy,S.R.vz);
if (vl > 1.5) then
a = S.angOf(nil,smt({[0]=S.R.vx,S.R.vy,S.R.vz,length=3},AMT));
ty = a[0];
tp = S.clamp(nil,(a[1] * 0.6),(-35),35);
else
ty = S.R.camYaw;
tp = 0;
end;
ptg = (function() local _t = (function() local _t = S.R.pose; if not T(_t) then return _t end; return S.R.pose.ok end)(); if not T(_t) then return _t end; return S.R.pose.tg end)();
if (T(ptg) and (ptg.hp > 0)) then
dl = S.wrapA(nil,((S.angOf(nil,smt({[0]=(ptg.x - S.R.px),(ptg.y - S.R.py),(ptg.z - S.R.pz),length=3},AMT)))[0] - ty));
if (Math_abs(dl) > 40) then
ty = (ty + (dl - ((dl > 0) and 40 or (-40))));
end;
end;
turn = (MOD(((ty - S.R.yaw) + 540),360) - 180);
S.R.yaw = (S.R.yaw + S.clamp(nil,turn,((-400) * dt),(400 * dt)));
S.R.pitch = S.lerp(nil,S.R.pitch,tp,(1 - Math_exp(((-dt) * 6))));
S.R.roll = S.lerp(nil,S.R.roll,S.clamp(nil,(((-jx) * 25) - (turn * 0.3)),(-35),35),(1 - Math_exp(((-dt) * 6))));
if (((not T(S.R.pose.ok)) and (vl > 3)) and (Math_random() < 0.6)) then
bf = S.fwdOf(nil,S.R.yaw,S.R.pitch);
S.R.parts:push({model="fx_spark_teal",x=(S.R.px - (bf[0] * 1.6)),y=((S.R.py + 1.4) - (bf[1] * 1.6)),z=(S.R.pz - (bf[2] * 1.6)),vx=(((-S.R.vx) * 0.3) + S.rand(nil,(-2),2)),vy=(((-S.R.vy) * 0.3) + S.rand(nil,(-2),2)),vz=(((-S.R.vz) * 0.3) + S.rand(nil,(-2),2)),life=0.35,max=0.35,size=2,noGrav=true});
end;
S.R.iframe = (S.R.iframe - dt);
end;
S.updateParts = function(_this, dt)
local cb;
S.R.parts = S.R.parts:filter(function(_this, p)
local dm;
p.life = (p.life - dt);
p.x = (p.x + (p.vx * dt));
p.y = (p.y + (p.vy * dt));
p.z = (p.z + (p.vz * dt));
dm = Math_exp(((-dt) * 1.5));
p.vx = (p.vx * dm);
p.vy = (p.vy * dm);
p.vz = (p.vz * dm);
do return (p.life > 0) end;
end);
S.R.nums = S.R.nums:filter(function(_this, n)
n.life = (n.life - dt);
n.y = (n.y + (dt * 5));
do return (n.life > 0) end;
end);
S.R.bubbles = S.R.bubbles:filter(function(_this, b)
b.life = (b.life - dt);
do return (b.life > 0) end;
end);
S.R.novas = S.R.novas:filter(function(_this, n)
n.life = (n.life - dt);
do return (n.life > 0) end;
end);
S.R.bannerT = (S.R.bannerT - dt);
S.R.shake = Math_max(0,(S.R.shake - (dt * 1.5)));
if (S.R.feverT > 0) then
S.R.feverT = (S.R.feverT - dt);
end;
if (S.R.comboT > 0) then
S.R.comboT = (S.R.comboT - dt);
if ((S.R.comboT <= 0) and (S.R.combo >= 15)) then
cb = (S.R.combo * 2);
S.addCredits(nil,cb);
S.A:toast(((("连击 x" .. S2(S.R.combo)) .. "：信用点 +") .. S2(cb)));
end;
end;
end;
S.step = function(_this, dt)
if (not T(S.R)) then
do return end;
end;
if (T(S.paused) or (T(S.R.over) and (not T(S.R.won)))) then
S.updateParts(nil,dt);
do return end;
end;
if (S.R.hitstop > 0) then
S.R.hitstop = (S.R.hitstop - dt);
dt = (dt * 0.1);
elseif (S.R.slowT > 0) then
S.R.slowT = (S.R.slowT - dt);
dt = (dt * 0.35);
end;
S.R.t = (S.R.t + dt);
S.R.camDt = dt;
S.runSched(nil,dt);
S.updatePlayer(nil,dt);
S.updateActive(nil,dt);
S.poseStep(nil,dt);
S.poseBuild(nil);
S.updateSpawns(nil,dt);
S.updateNodes(nil,dt);
S.updateEnemies(nil,dt);
S.fireMain(nil,dt);
S.updateSub(nil,dt);
S.updateModules(nil,dt);
S.updateSupport(nil,dt);
S.updateTurrets(nil,dt);
S.updateShots(nil,dt);
S.updatePickups(nil,dt);
S.updateParts(nil,dt);
if (((S.R.pendingLevels > 0) and (not T(S.R.over))) and (not T(S.paused))) then
S.openLevelUp(nil);
end;
if T(S.R.tutorial) then
S.R.tutorial:tick();
end;
end;
S.render = function(_this)
local t, draws, soft, cam, f, dtc, sh, j, eye, tgt, cf, cr, cu, V, aspect, fov, tanH, sight, sightLen, sd, occ, fxScale, add, fxRole, fxA, po, htint, W, fl;
add = function(_this, model, x, y, z, yaw, pitch, roll, s, tint, kind)
local mesh, rx, ry, rz, dist, fwd, nearCut, fade, along, ox, oy, oz, pr;
mesh = S.E:getMesh(model);
if (not T(mesh)) then
do return end;
end;
if T(kind) then
rx = (x - eye[0]); ry = (y - eye[1]); rz = (z - eye[2]); dist = S.len3(nil,rx,ry,rz); fwd = (((rx * cf[0]) + (ry * cf[1])) + (rz * cf[2]));
nearCut = ((kind == 2) and 7 or 5); fade = ((kind == 2) and 14 or 8);
if ((dist < nearCut) or (fwd < ((kind == 2) and 6 or 3))) then
do return end;
end;
if (dist < fade) then
s = (s * ((dist - nearCut) / (fade - nearCut)));
end;
if (kind == 2) then
s = (s * fxScale);
along = (((rx * sd[0]) + (ry * sd[1])) + (rz * sd[2]));
if ((along > 0) and (along < (sightLen - 2.5))) then
ox = (rx - (sd[0] * along)); oy = (ry - (sd[1] * along)); oz = (rz - (sd[2] * along));
if ((((ox * ox) + (oy * oy)) + (oz * oz)) < (2.6 * 2.6)) then
do return end;
end;
end;
if (fwd > 0.5) then
pr = ((mesh.radius * s) / (fwd * tanH));
occ = (occ + Math_min(1,(((Math_PI * pr) * pr) / (4 * aspect))));
end;
end;
end;
draws:push({mesh=mesh,m=S.E:trs(smt({[0]=x,y,z,length=3},AMT),yaw,pitch,roll,s),s=s,tint=tint,kind=(T(kind) and kind or 0),role=fxRole,a=fxA});
end;
t = S.R.t; draws = smt({length=0},AMT); soft = (T(S.C.save.settings) and (S.C.save.settings.fx == "soft"));
cam = S.CAMS[S.camPreset]; f = S.fwdOf(nil,(S.R.camYaw + (T(S.R.dbgYaw) and S.R.dbgYaw or 0)),S.R.camPitch); dtc = (1 - Math_exp(((-(T(S.R.camDt) and S.R.camDt or 0.016)) * 8)));
S.R.cx = (function() if (S.R.cx == nil) then return S.R.px else return S.lerp(nil,S.R.cx,S.R.px,dtc) end end)();
S.R.cy = (function() if (S.R.cy == nil) then return S.R.py else return S.lerp(nil,S.R.cy,S.R.py,dtc) end end)();
S.R.cz = (function() if (S.R.cz == nil) then return S.R.pz else return S.lerp(nil,S.R.cz,S.R.pz,dtc) end end)();
sh = (T(soft) and 0 or (S.R.shake * 0.35)); j = function(_this)
do return (function() if T(sh) then return (S.rand(nil,(-1),1) * sh) else return 0 end end)() end;
end;
eye = smt({[0]=((S.R.cx - (f[0] * cam.dist)) + j(nil)),(((S.R.cy - (f[1] * cam.dist)) + cam.h) + j(nil)),((S.R.cz - (f[2] * cam.dist)) + j(nil)),length=3},AMT);
tgt = smt({[0]=(S.R.cx + (f[0] * 10)),((S.R.cy + (f[1] * 10)) + (cam.h * 0.55)),(S.R.cz + (f[2] * 10)),length=3},AMT);
cf = S.nrm(nil,smt({[0]=(tgt[0] - eye[0]),(tgt[1] - eye[1]),(tgt[2] - eye[2]),length=3},AMT)); cr = S.nrm(nil,(S.cross(nil,smt({[0]=0,1,0,length=3},AMT),cf))); cu = S.cross(nil,cf,cr);
S.camBasis = {f=cf,r=cr,u=cu,eye=eye};
V = S.A:view(); aspect = (V.w / V.h); fov = S.A:fitFov(cam.fov,aspect); tanH = Math_tan(((fov * S.DEG) / 2));
sight = smt({[0]=(S.R.px - eye[0]),(S.R.py - eye[1]),(S.R.pz - eye[2]),length=3},AMT); sightLen = S.len3(nil,sight[0],sight[1],sight[2]); sd = smt({[0]=(sight[0] / sightLen),(sight[1] / sightLen),(sight[2] / sightLen),length=3},AMT);
occ = 0; fxScale = (T(soft) and 0.75 or 1);
fxRole = nil; fxA = 1;
S.R.decor:forEach(function(_this, d)
add(nil,d.model,d.x,d.y,d.z,(d.yaw + (d.spin * t)),(20 + ((d.spin * t) * 0.5)),0,d.s);
end);
S.R.nodes:forEach(function(_this, n)
local open;
if (n.state == "hidden") then
do return end;
end;
open = ((n.type == "gate") and (n.state == "open"));
n.objs:forEach(function(_this, o)
add(nil,o.model,o.x,(o.y + (function() if T(open) then return (Math_sin((t * 3)) * 0.6) else return 0 end end)()),o.z,((T(o.spin) and o.spin or 0) * t),(T(o.pitch) and o.pitch or 0),(function() if T(open) then return (t * 40) else return 0 end end)(),(o.s * (((n.type == "gate") and (not T(open))) and 0.7 or 1)),o.tint);
end);
end);
if ((not T(S.R.over)) or T(S.R.won)) then
po = S.R.pose;
if (T(po.ok) and T(po.mats)) then
htint = ((po.hitFlash > 0) and smt({[0]=1.5,0.3,0.3,length=3},AMT) or nil);
S.PARTS:forEach(function(_this, nm)
local mesh;
mesh = S.E:getMesh(((S2(S.R.mech) .. "__") .. S2(nm)));
if (T(mesh) and T(po.mats[nm])) then
draws:push({mesh=mesh,m=po.mats[nm],s=1.35,tint=htint});
end;
end);
W = po.W; fl = function(_this, n, d, len, s0, thr, ph)
local j, q;
fxRole = "thrust";
do
j = 0;
while (j < 5) do
fxA = (1 - (j * 0.2));
q = (((len * j) / 4) + 0.04);
add(nil,"fx_white",(n[0] + (d[0] * q)),(n[1] + (d[1] * q)),(n[2] + (d[2] * q)),(t * 200),(t * 140),0,(((s0 * (1 - (j * 0.17))) * (0.55 + (0.45 * Math_min(thr,1.2)))) * (0.93 + (0.1 * Math_sin((((t * 6) + (j * 1.7)) + ph))))),(function() if (j == 0) then return nil else return po.col end end)(),0);
j = j + 1;
end
end;
fxRole = nil;
fxA = 1;
end;
W.rear:forEach(function(_this, n, k)
fl(nil,n,W.rearD,(0.25 + (1.5 * S.clamp(nil,po.thrR,0,1.6))),3.4,po.thrR,(k * 2));
end);
W.vern:forEach(function(_this, n, k)
fl(nil,n,W.vernD,(0.15 + (0.8 * S.clamp(nil,po.thrV,0,1.4))),2.6,po.thrV,((k * 3) + 1));
end);
else
add(nil,S.R.mech,S.R.px,((S.R.py - 2.4) + (Math_sin((t * 3)) * 0.12)),S.R.pz,S.R.yaw,(S.R.pitch + (T(S.R.dash) and 18 or 0)),S.R.roll,1.35);
end;
end;
S.R.enemies:forEach(function(_this, e)
local s, st;
s = e.d.scale; st = (T(e.d.ore) and e.d.ore or e.d.hive);
add(nil,e.d.model,e.x,(e.y - ((T(e.d.ship) or T(st)) and 0 or (e.r * 0.6))),e.z,(function() if T(st) then return ((t * (T(e.d.hive) and 12 or 20)) + (e.bob * 50)) else return e.yaw end end)(),(function() if T(e.d.ore) then return (30 + (e.bob * 40)) else return (T(e.d.hive) and 0 or e.pitch) end end)(),0,s,((((e.flash > 0) and (not T(e.d.boss))) and (not T(soft))) and smt({[0]=0.95,0.62,0.56,length=3},AMT) or (T(e.rage) and smt({[0]=1.35,0.6,0.5,length=3},AMT) or (T(e.d.champ) and smt({[0]=1.25,1.05,0.6,length=3},AMT) or (T(e.d.hive) and smt({[0]=1.1,0.8,1.35,length=3},AMT) or nil)))),1);
end);
fxRole = "e";
S.R.enemies:forEach(function(_this, e)
local sh, big, k, lk, la2, sk2, sr, sa, sq, sLen, fk2, fr2, fa, bq, ba3, wind, col, rr, a, ad, aa;
sh = e.d.shoot; big = (function() local _t = (T(e.d.boss) and e.d.boss or e.d.elite); if T(_t) then return _t end; return (e.type == "heavy") end)();
if (T(e.lg) and (e.lg.t < e.d.lunge.tele)) then
lk = (e.lg.t / e.d.lunge.tele); la2 = S.angOf(nil,e.lg.dir);
do
k = 0;
while (k < 10) do
add(nil,"fx_white_bolt",(e.x + (e.lg.dir[0] * ((e.r + 1) + (k * 1.2)))),(e.y + (e.lg.dir[1] * ((e.r + 1) + (k * 1.2)))),(e.z + (e.lg.dir[2] * ((e.r + 1) + (k * 1.2)))),la2[0],la2[1],0,1.8,smt({[0]=(1.0 + (0.4 * lk)),0.15,0.2,length=3},AMT),1);
k = k + 1;
end
end;
do return end;
end;
if T(e.sl) then
sk2 = (e.sl.t / e.d.slam.tele); sr = e.d.slam.r;
do
k = 0;
while (k < 40) do
sa = (((k / 40) * Math_PI) * 2);
add(nil,"fx_spark",(e.x + (Math_cos(sa) * sr)),(e.y - (e.r * 0.5)),(e.z + (Math_sin(sa) * sr)),0,0,0,2.2,smt({[0]=1.2,0.35,0.15,length=3},AMT),1);
if (MOD(k,2) == 0) then
add(nil,"fx_spark",(e.x + ((Math_cos(sa) * sr) * sk2)),(e.y - (e.r * 0.5)),(e.z + ((Math_sin(sa) * sr) * sk2)),0,0,0,2.6,smt({[0]=1.5,0.6,0.2,length=3},AMT),1);
end;
k = k + 1;
end
end;
do return end;
end;
if (T(e.sn) and (e.sn.t < e.d.snipe.tele)) then
sq = (e.sn.t / e.d.snipe.tele); sa = S.angOf(nil,e.sn.dir);
sLen = Math_min(30,(Math_ceil(((Math_sqrt((S.d3(nil,S.R.px,S.R.py,S.R.pz,e.x,e.y,e.z))) + 8) / 1.5))));
do
k = 0;
while (k < sLen) do
add(nil,"fx_white_bolt",(e.x + (e.sn.dir[0] * ((e.r + 1) + (k * 1.5)))),(e.y + (e.sn.dir[1] * ((e.r + 1) + (k * 1.5)))),(e.z + (e.sn.dir[2] * ((e.r + 1) + (k * 1.5)))),sa[0],sa[1],0,2.3,smt({[0]=(1.0 + (0.5 * sq)),0.12,0.2,length=3},AMT),1);
k = k + 1;
end
end;
add(nil,"fx_white",(e.x + (e.sn.dir[0] * (e.r + 1.5))),(e.y + (e.sn.dir[1] * (e.r + 1.5))),(e.z + (e.sn.dir[2] * (e.r + 1.5))),0,0,0,(2 + (5 * sq)),smt({[0]=1.4,0.2,0.3,length=3},AMT),1);
do return end;
end;
if T(e.fz) then
fk2 = (e.fz / e.d.bomb.fuse); fr2 = e.d.bomb.r;
do
k = 0;
while (k < 28) do
fa = (((k / 28) * Math_PI) * 2);
add(nil,"fx_spark",(e.x + (Math_cos(fa) * fr2)),(e.y - (e.r * 0.4)),(e.z + (Math_sin(fa) * fr2)),0,0,0,2,smt({[0]=1.2,0.4,0.15,length=3},AMT),1);
if (MOD(k,2) == 0) then
add(nil,"fx_spark",(e.x + ((Math_cos(fa) * fr2) * fk2)),(e.y - (e.r * 0.4)),(e.z + ((Math_sin(fa) * fr2) * fk2)),0,0,0,2.6,smt({[0]=1.5,0.7,0.2,length=3},AMT),1);
end;
k = k + 1;
end
end;
do return end;
end;
if T(e.bk) then
bq = (e.bk.t / e.d.blink.tele);
do
k = 0;
while (k < 20) do
ba3 = ((((k / 20) * Math_PI) * 2) + t);
add(nil,"fx_spark",(e.bk.dest[0] + ((Math_cos(ba3) * 4) * (1.2 - (0.5 * bq)))),(e.bk.dest[1] - 1),(e.bk.dest[2] + ((Math_sin(ba3) * 4) * (1.2 - (0.5 * bq)))),0,0,0,2.4,smt({[0]=0.7,0.35,1.4,length=3},AMT),1);
k = k + 1;
end
end;
do return end;
end;
if (not T(big)) then
do return end;
end;
wind = (function() if ((T(sh) and (e.fire > 0)) and (e.fire < 0.8)) then return (1 - (e.fire / 0.8)) else return (function() if ((T(e.summon) and (e.sumT > 0)) and (e.sumT < 1)) then return (1 - e.sumT) else return 0 end end)() end end)();
if (wind <= 0) then
do return end;
end;
col = (T(sh) and smt({[0]=1.3,0.18,0.22,length=3},AMT) or smt({[0]=0.9,0.3,1.3,length=3},AMT)); rr = (e.r * (1.0 + (wind * 0.7)));
do
k = 0;
while (k < 22) do
a = ((((k / 22) * Math_PI) * 2) + (t * 0.8));
add(nil,"fx_spark",(e.x + (Math_cos(a) * rr)),(e.y - (e.r * 0.4)),(e.z + (Math_sin(a) * rr)),0,0,0,(2.2 + (wind * 2)),col,1);
k = k + 1;
end
end;
if (T(sh) and (not T(sh.ring))) then
ad = S.nrm(nil,smt({[0]=(S.R.px - e.x),(S.R.py - e.y),(S.R.pz - e.z),length=3},AMT)); aa = S.angOf(nil,ad);
do
k = 0;
while (k < 14) do
add(nil,"fx_white_bolt",(e.x + (ad[0] * ((e.r + 1) + (k * 1.3)))),(e.y + (ad[1] * ((e.r + 1) + (k * 1.3)))),(e.z + (ad[2] * ((e.r + 1) + (k * 1.3)))),aa[0],aa[1],0,2.1,col,1);
k = k + 1;
end
end;
end;
end);
S.R.enemies:forEach(function(_this, e)
local L, oo, la, firing, kq, lb, kk, nn2, lx, ly, lz, ph2, cc, ss;
L = e.laser;
if (not T(L)) then
do return end;
end;
oo = smt({[0]=(e.x + (L.dir[0] * e.r)),(e.y + (L.dir[1] * e.r)),(e.z + (L.dir[2] * e.r)),length=3},AMT); la = S.angOf(nil,L.dir); firing = (L.t >= L.charge); kq = (function() if T(firing) then return (1 - ((L.t - L.charge) / L.fire)) else return (L.t / L.charge) end end)(); lb = S.basis(nil,L.dir); nn2 = 0;
do
kk = 0;
while (kk < 90) do
lx = (oo[0] + (L.dir[0] * kk)); ly = (oo[1] + (L.dir[1] * kk)); lz = (oo[2] + (L.dir[2] * kk));
if T(firing) then
add(nil,"fx_white_bolt",lx,ly,lz,la[0],la[1],0,(3.6 * (0.6 + (0.4 * kq))),nil,1);
if (MOD(nn2,2) == 0) then
ph2 = ((kk * 0.45) + (t * 20)); cc = (Math_cos(ph2) * 0.9); ss = (Math_sin(ph2) * 0.9);
add(nil,"fx_white",((lx + (lb[0][0] * cc)) + (lb[1][0] * ss)),((ly + (lb[0][1] * cc)) + (lb[1][1] * ss)),((lz + (lb[0][2] * cc)) + (lb[1][2] * ss)),0,0,0,(2.6 * kq),smt({[0]=1.4,0.2,0.3,length=3},AMT),1);
end;
else
add(nil,"fx_white_bolt",lx,ly,lz,la[0],la[1],0,2.2,smt({[0]=(1.0 + (0.4 * kq)),0.12,0.18,length=3},AMT),1);
end;
kk = (kk + 1.6);
nn2 = nn2 + 1;
end
end;
add(nil,"fx_white",oo[0],oo[1],oo[2],0,0,0,(function() if T(firing) then return (9 * kq) else return (3 + (7 * kq)) end end)(),(function() if T(firing) then return nil else return smt({[0]=1.4,0.2,0.3,length=3},AMT) end end)(),1);
end);
fxRole = "p";
S.R.shots:forEach(function(_this, s)
local a;
a = S.angOf(nil,smt({[0]=s.vx,s.vy,s.vz,length=3},AMT));
add(nil,s.model,s.x,s.y,s.z,a[0],a[1],0,(T(s.size) and s.size or ((s.model == "fx_spark") and 3 or 2.4)),s.tint,2);
end);
fxRole = "e";
S.R.ebullets:forEach(function(_this, b)
local ba;
ba = S.angOf(nil,smt({[0]=b.vx,b.vy,b.vz,length=3},AMT));
add(nil,"fx_white_bolt",b.x,b.y,b.z,ba[0],ba[1],0,(T(b.snipe) and 10 or (T(b.big) and 5 or 3.2)),(T(b.snipe) and smt({[0]=1.5,0.5,0.6,length=3},AMT) or smt({[0]=1.35,0.22,0.3,length=3},AMT)),1);
add(nil,"fx_white",b.x,b.y,b.z,0,0,0,(T(b.big) and 6 or 2.2),(T(b.big) and smt({[0]=1.4,0.3,0.35,length=3},AMT) or nil),1);
end);
fxRole = "p";
S.R.missiles:forEach(function(_this, m)
local a;
if T(m.hide) then
do return end;
end;
a = (function() if T(m.fall) then return (function() if T(m.launch) then return S.angOf(nil,m.launch.dir) else return smt({[0]=0,90,length=2},AMT) end end)() else return S.angOf(nil,m.dir) end end)();
add(nil,m.model,m.x,m.y,m.z,a[0],a[1],0,(T(m.size) and m.size or 2.2),m.tint,2);
end);
S.R.mods:forEach(function(_this, md)
if T(md.orb) then
md.orb:forEach(function(_this, o)
local an, rr2, j, a2;
add(nil,"fx_white",o[0],o[1],o[2],(t * 50),45,0,(md.osz * 0.65),md.tint,2);
an = Math_atan2((o[2] - S.R.pz),(o[0] - S.R.px)); rr2 = Math_hypot((o[0] - S.R.px),(o[2] - S.R.pz));
do
j = 1;
while (j <= 3) do
a2 = (an - (j * 0.2));
add(nil,"fx_white",(S.R.px + (Math_cos(a2) * rr2)),o[1],(S.R.pz + (Math_sin(a2) * rr2)),0,0,0,((md.osz * 0.65) * (1 - (j * 0.22))),md.tint,2);
j = j + 1;
end
end;
end);
end;
end);
S.R.mines:forEach(function(_this, mn)
add(nil,"fx_white",mn.x,mn.y,mn.z,(t * 120),45,0,(3 + (Math_sin((t * 3)) * 0.3)),mn.tint,2);
end);
S.R.booms:forEach(function(_this, b)
local bd, j;
bd = (T(b.out) and smt({[0]=(-b.d[0]),(-b.d[1]),(-b.d[2]),length=3},AMT) or S.nrm(nil,smt({[0]=(b.x - S.R.px),(b.y - S.R.py),(b.z - S.R.pz),length=3},AMT)));
do
j = 1;
while (j <= 4) do
add(nil,"fx_white",(b.x + ((bd[0] * j) * 1.1)),(b.y + ((bd[1] * j) * 1.1)),(b.z + ((bd[2] * j) * 1.1)),0,0,0,((b.size * (1 - (j * 0.2))) * 0.7),b.tint,2);
j = j + 1;
end
end;
add(nil,"fx_white_bolt",b.x,b.y,b.z,(t * 900),0,0,b.size,b.tint,2);
add(nil,"fx_white_bolt",b.x,b.y,b.z,((t * 900) + 90),0,0,b.size,b.tint,2);
end);
S.R.strikes:forEach(function(_this, st)
local q, f, fl, flick, q2, p0, p1, dx, dy, dz, L, ang, mx, my, mz2;
if (not T(st.pts)) then
st.pts = smt({length=0},AMT);
do
q = 0;
while (q <= 7) do
f = (q / 7);
st.pts:push(smt({[0]=(st.x + (function() if (T(q) and (q < 7)) then return (S.rand(nil,(-2.2),2.2) * (1 - (f * 0.5))) else return 0 end end)()),(st.y + (34 * (1 - f))),(st.z + (function() if (T(q) and (q < 7)) then return (S.rand(nil,(-2.2),2.2) * (1 - (f * 0.5))) else return 0 end end)()),length=3},AMT));
q = q + 1;
end
end;
end;
fl = (st.life / 0.22); flick = true;
do
q2 = 0;
while (q2 < 7) do
p0 = st.pts[q2]; p1 = st.pts[(q2 + 1)]; dx = (p1[0] - p0[0]); dy = (p1[1] - p0[1]); dz = (p1[2] - p0[2]); L = (function() local _t = S.len3(nil,dx,dy,dz); if T(_t) then return _t end; return 1 end)(); ang = S.angOf(nil,smt({[0]=(dx / L),(dy / L),(dz / L),length=3},AMT)); mx = ((p0[0] + p1[0]) / 2); my = ((p0[1] + p1[1]) / 2); mz2 = ((p0[2] + p1[2]) / 2);
add(nil,"fx_white_bolt",mx,my,mz2,ang[0],ang[1],0,((L * 1.05) * (0.5 + (0.5 * fl))),nil,2);
if T(flick) then
add(nil,"fx_white_bolt",(mx + 0.28),my,mz2,ang[0],ang[1],0,((L * 1.02) * fl),st.tint,2);
add(nil,"fx_white_bolt",(mx - 0.28),my,(mz2 - 0.28),ang[0],ang[1],0,((L * 1.02) * fl),st.tint,2);
end;
q2 = q2 + 1;
end
end;
add(nil,"fx_white",st.x,(st.y + 0.5),st.z,0,0,0,(7 * fl),nil,2);
add(nil,"fx_white",st.x,(st.y + 0.5),st.z,(t * 50),45,0,(11 * fl),st.tint,2);
end);
S.R.beams:forEach(function(_this, b)
local a, w, tn, bs, step, k, n, cs, px, py, pz, ph, c1, s1, ex, ey, ez;
a = S.angOf(nil,b.d); w = S.clamp(nil,(b.life / 0.2),0.25,1); tn = (T(b.tint) and b.tint or S.lin(nil,"#5CF2DC")); bs = S.basis(nil,b.d); step = (T(soft) and 2.4 or 1.5); n = 0;
cs = (step * 1.6);
do
k = 0;
while (k < b.len) do
px = (b.x + (b.d[0] * k)); py = (b.y + (b.d[1] * k)); pz = (b.z + (b.d[2] * k));
add(nil,"fx_white_bolt",px,py,pz,a[0],a[1],0,((cs * (0.78 + (0.22 * w))) * 1),nil,1);
if (MOD(n,2) == 0) then
ph = ((k * 0.55) + (t * 38)); c1 = ((Math_cos(ph) * 0.5) * w); s1 = ((Math_sin(ph) * 0.5) * w);
add(nil,"fx_white",((px + (bs[0][0] * c1)) + (bs[1][0] * s1)),((py + (bs[0][1] * c1)) + (bs[1][1] * s1)),((pz + (bs[0][2] * c1)) + (bs[1][2] * s1)),0,0,0,(1.7 * w),tn,1);
end;
k = (k + step);
n = n + 1;
end
end;
add(nil,"fx_white",b.x,b.y,b.z,0,0,0,(5 * w),nil,1);
add(nil,"fx_white",b.x,b.y,b.z,(t * 50),45,0,(7.5 * w),tn,1);
ex = (b.x + (b.d[0] * b.len)); ey = (b.y + (b.d[1] * b.len)); ez = (b.z + (b.d[2] * b.len));
add(nil,"fx_white",ex,ey,ez,(t * 50),45,0,(6 * w),tn,1);
end);
S.R.turrets:forEach(function(_this, tu)
local x, y, z, k;
x = tu.x; y = tu.y; z = tu.z;
if (tu.dep > 0) then
k = (1 - (tu.dep / tu.dep0));
x = S.lerp(nil,tu.from[0],tu.x,k);
y = (S.lerp(nil,tu.from[1],tu.y,k) + (Math_sin((k * Math_PI)) * 3));
z = S.lerp(nil,tu.from[2],tu.z,k);
end;
add(nil,"prop_turret",x,(y - 1),z,(tu.yaw + (function() if (tu.dep > 0) then return (tu.dep * 720) else return 0 end end)()),0,0,1.5,nil,2);
end);
S.R.fires:forEach(function(_this, fi)
add(nil,"fx_spark",fi.x,fi.y,fi.z,(t * 60),0,0,(4 + (Math_sin(((t * 4) + fi.x)) * 0.6)),nil,2);
end);
fxRole = "gem";
S.R.gems:forEach(function(_this, g)
add(nil,((g.v >= 10) and "prop_meteor_shard" or "fx_spark_teal"),g.x,(g.y + (Math_sin(((t * 4) + g.x)) * 0.2)),g.z,(t * 120),((g.v >= 10) and 0 or 45),0,((g.v >= 10) and 1.6 or ((g.v >= 5) and 6 or 4)),nil,2);
end);
fxRole = "pick";
S.R.pickups:forEach(function(_this, p)
add(nil,((p.kind == "heal") and "prop_medkit" or ((p.kind == "ammo") and "prop_supply_crate" or "prop_loot_pod")),p.x,p.y,p.z,(t * 90),0,0,((p.kind == "heal") and 4 or ((p.kind == "ammo") and 3.2 or 4.5)),nil,2);
end);
fxRole = "nova";
S.R.novas:forEach(function(_this, n)
local dur, k, e, rr, cnt, i, a, mdl, cx, sz, h;
dur = (T(n.dur) and n.dur or 0.45); k = (1 - (n.life / dur)); e = (1 - Math_pow((1 - k),2.2)); rr = (n.r * (0.25 + (0.75 * e))); cnt = ((T(soft) or (LEN(S.R.novas) > 6)) and 24 or 44);
fxA = (1 - k);
mdl = (T(n.tint) and "fx_white" or (((n.color == "#7CF29A") or (n.color == "#5CF2DC")) and "fx_spark_teal" or "fx_shield"));
do
i = 0;
while (i < cnt) do
a = (((i / cnt) * Math_PI) * 2);
cx = Math_cos(a); sz = Math_sin(a);
add(nil,mdl,(n.x + (cx * rr)),(n.y - 1),(n.z + (sz * rr)),0,0,0,(3.6 * (1 - (k * 0.65))),n.tint,2);
if (MOD(i,2) == 0) then
add(nil,"fx_white",(n.x + ((cx * rr) * 0.86)),(n.y - 1),(n.z + ((sz * rr) * 0.86)),0,0,0,(2 * (1 - k)),nil,2);
end;
i = i + 1;
end
end;
if (not T(soft)) then
do
i = 0;
while (i < 10) do
a = ((((i / 10) * Math_PI) * 2) + k);
do
h = 0;
while (h < 3) do
add(nil,mdl,(n.x + ((Math_cos(a) * rr) * 0.92)),((n.y - 1) + (((h + 1) * 1.4) * Math_sin((k * Math_PI)))),(n.z + ((Math_sin(a) * rr) * 0.92)),0,0,0,((2.4 - (h * 0.6)) * (1 - k)),n.tint,2);
h = h + 1;
end
end;
i = i + 1;
end
end;
end;
if (k < 0.28) then
add(nil,"fx_white",n.x,(n.y - 0.5),n.z,(t * 50),45,0,(10 * (1 - (k / 0.28))),nil,2);
end;
end);
fxRole = "p";
fxA = 1;
S.R.zones:forEach(function(_this, z)
local i, a, q3, a3, q, b, a2;
do
i = 0;
while (i < 24) do
a = ((((i / 24) * Math_PI) * 2) + (t * 0.6));
add(nil,"fx_spark_teal",(z.x + (Math_cos(a) * z.r)),(z.y - 2.2),(z.z + (Math_sin(a) * z.r)),0,0,0,2.6,nil,2);
i = i + 1;
end
end;
do
q3 = 0;
while (q3 < 16) do
a3 = (((((-q3) / 16) * Math_PI) * 2) - (t * 0.9));
add(nil,"fx_white",(z.x + ((Math_cos(a3) * z.r) * 0.55)),(z.y - 2.2),(z.z + ((Math_sin(a3) * z.r) * 0.55)),0,0,0,1.8,S.HEALC,2);
q3 = q3 + 1;
end
end;
do
q = 0;
while (q < 6) do
b = MOD(((q * 1.7) + (t * 0.8)),1); a2 = ((q * 1.05) + (t * 0.3));
add(nil,"fx_spark_teal",(z.x + ((Math_cos(a2) * z.r) * 0.7)),((z.y - 2) + (b * 5)),(z.z + ((Math_sin(a2) * z.r) * 0.7)),0,0,0,(2 * (1 - b)),nil,2);
q = q + 1;
end
end;
end);
fxRole = "fx";
S.R.parts:forEach(function(_this, p)
local kk, s;
if (T(soft) and ((function() p.id = (T(p.id) and p.id or Math_random()); return p.id end)() < 0.5)) then
do return end;
end;
kk = (p.life / p.max); s = ((p.size * S.clamp(nil,kk,(T(p.hot) and 0.06 or 0.15),1)) * 2);
fxA = kk;
fxRole = ((p.et == 1) and "etrail" or ((p.et == 2) and "emz" or ((p.et == 3) and "ptrail" or "fx")));
add(nil,p.model,p.x,p.y,p.z,(p.life * 200),(p.life * 140),0,s,(function() if T(p.hot) then return S.hotRamp(nil,(T(p.tint) and p.tint or S.EMBER),kk) else return p.tint end end)(),2);
end);
S.R.occ = occ;
S.R.occMax = Math_max((T(S.R.occMax) and S.R.occMax or 0),occ);
S.lastVP = S.E:render({env={bg=S.R.ch.env.bg,ambient=S.R.ch.env.ambient,fog=smt({[0]=140,420,length=2},AMT),key=S.R.ch.env.key,fill=S.R.ch.env.fill,bloom={threshold=0.9,mix=(T(soft) and 0.28 or 0.4)}},eye=eye,target=tgt,fov=fov,aspect=aspect,near=0.5,far=6000,draws=draws,stars=S.stars,shadow=nil});
end;
S.drawOverlay = function(_this)
local V, cv, ctx, s, w, h, Pj, onScreen, u, tq, bs, kk, pp, bw, bh, marks, goal, gx, gy, gr, jr;
Pj = function(_this, x, y, z)
do return S.E:project(S.lastVP,smt({[0]=x,y,z,length=3},AMT),w,h) end;
end;
onScreen = function(_this, q)
do return ((((T(q) and (q[0] > 0)) and (q[0] < w)) and (q[1] > 0)) and (q[1] < h)) end;
end;
V = S.A:view(); cv = HOST.document:getElementById("hud2d"); ctx = cv:getContext("2d"); s = V.s; w = V.w; h = V.h;
ctx:setTransform(1,0,0,1,0,0);
ctx:clearRect(0,0,cv.width,cv.height);
if (not T(S.lastVP)) then
do return end;
end;
ctx:setTransform(V.dpr,0,0,V.dpr,0,0);
u = Math_max(0.55,(s * 1.5));
ctx.textAlign = "center";
S.R.nodes:forEach(function(_this, n)
local q, col, dist, label, e2, rr;
if (n.state == "hidden") then
do return end;
end;
q = Pj(nil,n.x,n.y,n.z);
if (not T(onScreen(nil,q))) then
do return end;
end;
ctx.globalAlpha = (((q[1] < (h * 0.3)) and ((q[0] > (w * 0.7)) or (Math_abs((q[0] - (w / 2))) < (w * 0.22)))) and 0.35 or 1);
col = ((n.state == "done") and "rgba(163,171,207,.6)" or n.info.color); dist = Math_round((Math_sqrt((S.dd(nil,n,(S.P(nil)))))));
ctx.font = (("700 " .. S2(Math_round((13 * u)))) .. "px \"Noto Sans SC\", sans-serif");
label = ((((S2(n.info.name) .. (function() if (n.type == "gate") then return ((n.state == "open") and "（已开启）" or "（未开启）") else return (function() if (n.state == "done") then return (T(n.failed) and "（失败）" or "（完成）") else return "" end end)() end end)()) .. "  ") .. S2(dist)) .. " 米");
ctx.lineWidth = (3 * u);
ctx.strokeStyle = "rgba(9,12,34,.9)";
ctx:strokeText(label,q[0],(q[1] - (30 * u)));
ctx.fillStyle = col;
ctx:fillText(label,q[0],(q[1] - (30 * u)));
if ((n.type == "derelict") and (n.state ~= "done")) then
e2 = Pj(nil,(n.x + (S.camBasis.r[0] * 15)),(n.y + (S.camBasis.r[1] * 15)),(n.z + (S.camBasis.r[2] * 15))); rr = (function() if T(e2) then return Math_hypot((e2[0] - q[0]),(e2[1] - q[1])) else return 40 end end)();
ctx.strokeStyle = "rgba(245,165,36,.55)";
ctx.lineWidth = (2 * u);
ctx:beginPath();
ctx:arc(q[0],q[1],rr,0,(Math_PI * 2));
ctx:stroke();
if (n.progress > 0) then
ctx.strokeStyle = "#F5A524";
ctx.lineWidth = (5 * u);
ctx:beginPath();
ctx:arc(q[0],q[1],rr,((-Math_PI) / 2),(((-Math_PI) / 2) + ((n.progress * Math_PI) * 2)));
ctx:stroke();
end;
end;
if (((n.type == "gate") and (n.state == "open")) and T(n.info.tip)) then
ctx.fillStyle = n.info.color;
ctx:fillText(n.info.tip,q[0],(q[1] - (46 * u)));
end;
if ((((n.type == "gate") and (not T(n.risk))) and (n.state == "locked")) and (S.R.gateNeed > 0)) then
ctx.fillStyle = "#9DF7EC";
ctx:fillText((("星门能量 " .. S2(Math_min(100,(Math_floor(((S.R.secKills / S.R.gateNeed) * 100)))))) .. "%"),q[0],(q[1] - (46 * u)));
end;
if ((n.type == "hunt") and (n.state == "active")) then
ctx.fillStyle = "#FF8A3A";
ctx:fillText((((((S2((T(n.got) and n.got or 0)) .. " / ") .. S2(n.need)) .. "　") .. S2(Math_ceil(n.timer))) .. " 秒"),q[0],(q[1] - (46 * u)));
end;
if ((n.type == "ambush") and (n.state == "active")) then
ctx.fillStyle = "#B47CFF";
ctx:fillText((("第 " .. S2(n.wave)) .. " / 3 波"),q[0],(q[1] - (46 * u)));
end;
if ((n.type == "pirate") and (n.state == "active")) then
ctx.fillStyle = "#E0458C";
ctx:fillText(((("剩余 " .. S2(LEN((S.R.enemies:filter(function(_this, e)
do return (e.node == n) end;
end))))) .. " 个海贼") .. (T(n.reinf) and "" or "（还有增援）")),q[0],(q[1] - (46 * u)));
end;
if ((n.type == "nest") and (n.state == "active")) then
ctx.fillStyle = "#B47CFF";
ctx:fillText(((("晶簇巢 " .. S2(((n.hives == nil) and 3 or n.hives))) .. " / 3　守卫") .. ((T(n.guard) and (n.guard.hp > 0)) and "存活" or "已击败")),q[0],(q[1] - (46 * u)));
end;
if ((n.type == "distress") and (n.state == "active")) then
ctx.fillStyle = "rgba(9,12,34,.85)";
ctx:fillRect((q[0] - (40 * u)),(q[1] - (22 * u)),(80 * u),(8 * u));
ctx.fillStyle = "#5CF2DC";
ctx:fillRect((q[0] - (40 * u)),(q[1] - (22 * u)),((80 * u) * Math_max(0,(n.pod.hp / n.pod.max))),(8 * u));
ctx.fillStyle = "#EDE6D6";
ctx:fillText((S2(Math_ceil(n.timer)) .. " 秒"),q[0],(q[1] - (46 * u)));
end;
end);
ctx.globalAlpha = 1;
S.R.enemies:forEach(function(_this, e)
local wq;
if (((not (T(e.d.boss) or T(e.d.elite))) or (not T(e.d.shoot))) or (not ((e.fire > 0) and (e.fire < 0.8)))) then
do return end;
end;
wq = Pj(nil,e.x,(e.y + (e.r * 1.4)),e.z);
if (not T(onScreen(nil,wq))) then
do return end;
end;
ctx.font = (("700 " .. S2(Math_round((26 * u)))) .. "px \"Noto Sans SC\", sans-serif");
ctx.fillStyle = "#FF4D6A";
ctx.globalAlpha = (0.75 + (0.25 * Math_sin((S.R.t * 8))));
ctx:fillText("! 预警",wq[0],wq[1]);
ctx.globalAlpha = 1;
end);
if (T(S.R.target) and (S.R.target.hp > 0)) then
tq = Pj(nil,S.R.target.x,S.R.target.y,S.R.target.z);
if T(onScreen(nil,tq)) then
bs = S.clamp(nil,(((S.R.target.r * 900) / Math_max(5,tq[2])) * s),(14 * u),(70 * u)); kk = (bs * 0.4);
ctx.strokeStyle = "#FF4D6A";
ctx.lineWidth = (2.5 * u);
ctx:beginPath();
;(smt({[0]=smt({[0]=(-1),(-1),length=2},AMT),smt({[0]=1,(-1),length=2},AMT),smt({[0]=1,1,length=2},AMT),smt({[0]=(-1),1,length=2},AMT),length=4},AMT)):forEach(function(_this, c)
local x, y;
x = (tq[0] + (c[0] * bs)); y = (tq[1] + (c[1] * bs));
ctx:moveTo(x,(y - (c[1] * kk)));
ctx:lineTo(x,y);
ctx:lineTo((x - (c[0] * kk)),y);
end);
ctx:stroke();
if ((T(S.R.target.d.elite) or T(S.R.target.d.boss)) or (S.R.target.max > 80)) then
ctx.fillStyle = "rgba(9,12,34,.85)";
ctx:fillRect((tq[0] - bs),((tq[1] - bs) - (10 * u)),(bs * 2),(5 * u));
ctx.fillStyle = "#FF4D6A";
ctx:fillRect((tq[0] - bs),((tq[1] - bs) - (10 * u)),((bs * 2) * S.clamp(nil,(S.R.target.hp / S.R.target.max),0,1)),(5 * u));
end;
end;
end;
pp = Pj(nil,S.R.px,(S.R.py - 3.2),S.R.pz);
if (T(pp) and (not T(S.R.over))) then
bw = (60 * u); bh = (7 * u);
ctx.fillStyle = "rgba(9,12,34,.85)";
ctx:fillRect(((pp[0] - (bw / 2)) - 2),(pp[1] - 2),(bw + 4),(bh + 4));
ctx.fillStyle = (((S.R.hull / S.hullMax(nil)) < 0.3) and "#E0458C" or "#7CF29A");
ctx:fillRect((pp[0] - (bw / 2)),pp[1],(bw * S.clamp(nil,(S.R.hull / S.hullMax(nil)),0,1)),bh);
end;
;((function() if T(S.setting(nil,"nums",true)) then return S.R.nums else return smt({length=0},AMT) end end)()):forEach(function(_this, n)
local q;
q = Pj(nil,n.x,n.y,n.z);
if (not T(onScreen(nil,q))) then
do return end;
end;
ctx.globalAlpha = S.clamp(nil,(n.life / 0.35),0,1);
ctx.font = (("700 " .. S2(Math_round(((T(n.crit) and 17 or 12) * u)))) .. "px \"Noto Sans SC\", sans-serif");
ctx.lineWidth = (3 * u);
ctx.strokeStyle = "rgba(9,12,34,.9)";
ctx:strokeText(n.v,q[0],q[1]);
ctx.fillStyle = (T(n.crit) and "#F5A524" or (T(n.col) and n.col or "#EDE6D6"));
ctx:fillText(n.v,q[0],q[1]);
end);
ctx.globalAlpha = 1;
S.R.bubbles:forEach(function(_this, b)
local q, tw, th;
q = Pj(nil,S.R.px,(S.R.py + 4.2),S.R.pz);
if (not T(onScreen(nil,q))) then
do return end;
end;
ctx.font = (("700 " .. S2(Math_round((13 * u)))) .. "px \"Noto Sans SC\", sans-serif");
tw = ((ctx:measureText(b.text)).width + (16 * u)); th = (24 * u);
ctx.globalAlpha = S.clamp(nil,(b.life / 0.3),0,1);
ctx.fillStyle = "rgba(237,230,214,.95)";
ctx:fillRect((q[0] - (tw / 2)),(q[1] - th),tw,th);
ctx:beginPath();
ctx:moveTo((q[0] - (5 * u)),q[1]);
ctx:lineTo((q[0] + (5 * u)),q[1]);
ctx:lineTo(q[0],(q[1] + (6 * u)));
ctx:fill();
ctx.fillStyle = "#1A2046";
ctx.textBaseline = "middle";
ctx:fillText(b.text,q[0],(q[1] - (th / 2)));
ctx.textBaseline = "alphabetic";
ctx.globalAlpha = 1;
end);
marks = smt({length=0},AMT); goal = (function() if (not T(S.objectiveDone(nil))) then return S.R.event else return (function() if (S.R.gate.state == "open") then return S.R.gate else return nil end end)() end end)();
if T(goal) then
marks:push({o=goal,col=goal.info.color,label=(function() if (goal.type == "gate") then return (T(S.R.gate2) and "稳航" or "星门") else return goal.info.name end end)()});
end;
if (T(S.R.gate2) and (S.R.gate2.state == "open")) then
marks:push({o=S.R.gate2,col=S.R.gate2.info.color,label="险途"});
end;
S.R.enemies:forEach(function(_this, e)
if (T(e.d.elite) or T(e.d.boss)) then
marks:push({o=e,col=(T(e.d.champ) and "#FFD34D" or "#FF4D6A")});
elseif T(e.d.hive) then
marks:push({o=e,col="#B47CFF"});
end;
end);
;((S.R.enemies:filter(function(_this, e)
do return ((((not T(e.d.ore)) and (not T(e.d.elite))) and (not T(e.d.boss))) and (S.dd(nil,e,(S.P(nil))) < (18 * 18))) end;
end)):slice(0,6)):forEach(function(_this, e)
marks:push({o=e,col="rgba(255,77,106,.85)",small=true});
end);
marks:forEach(function(_this, m)
local o, q, rel, x, y, ang, rr, ex, ey, k2;
o = m.o; q = Pj(nil,o.x,o.y,o.z);
if ((((T(q) and (q[0] > 30)) and (q[0] < (w - 30))) and (q[1] > 30)) and (q[1] < (h - 30))) then
do return end;
end;
rel = smt({[0]=(o.x - S.camBasis.eye[0]),(o.y - S.camBasis.eye[1]),(o.z - S.camBasis.eye[2]),length=3},AMT); x = S.dot(nil,rel,S.camBasis.r); y = S.dot(nil,rel,S.camBasis.u);
if ((Math_abs(x) + Math_abs(y)) < 0.01) then
y = (-1);
end;
ang = Math_atan2((-y),x); rr = (Math_min(w,h) * (T(m.small) and 0.46 or 0.4)); ex = S.clamp(nil,((w / 2) + ((Math_cos(ang) * rr) * (w / h))),(24 * u),(w - (24 * u))); ey = S.clamp(nil,((h / 2) + (Math_sin(ang) * rr)),(24 * u),(h - (24 * u)));
k2 = (T(m.small) and 0.6 or 1);
ctx:save();
ctx:translate(ex,ey);
ctx:rotate(ang);
ctx.fillStyle = m.col;
ctx:beginPath();
ctx:moveTo(((18 * u) * k2),0);
ctx:lineTo((((-10) * u) * k2),(((-12) * u) * k2));
ctx:lineTo((((-10) * u) * k2),((12 * u) * k2));
ctx:fill();
ctx:restore();
if T(m.label) then
ctx.font = (("700 " .. S2(Math_round((12 * u)))) .. "px \"Noto Sans SC\", sans-serif");
ctx.fillStyle = m.col;
ctx:fillText((((S2(m.label) .. " ") .. S2(Math_round((Math_sqrt((S.dd(nil,o,(S.P(nil))))))))) .. "米"),(ex - ((Math_cos(ang) * 34) * u)),((ey - ((Math_sin(ang) * 26) * u)) + (4 * u)));
end;
end);
if T(S.R.outside) then
ctx.font = (("700 " .. S2(Math_round((16 * u)))) .. "px \"Noto Sans SC\", sans-serif");
ctx.fillStyle = "#FF4D6A";
ctx:fillText("已到达战场边缘，正在返回",(w / 2),(h * 0.3));
end;
if (((T(S.A.isMobile) and T(S.R.tutUI)) and (S.R.tutUI.n == 1)) and (S.joy.id == nil)) then
gx = (w * 0.18); gy = (h * 0.7); gr = (60 * u);
ctx.globalAlpha = (0.45 + (0.25 * Math_sin((S.R.t * 4))));
ctx.strokeStyle = "rgba(92,242,220,.9)";
ctx.lineWidth = (3 * u);
ctx:beginPath();
ctx:arc(gx,gy,gr,0,(Math_PI * 2));
ctx:stroke();
ctx.fillStyle = "rgba(237,230,214,.7)";
ctx:beginPath();
ctx:arc(gx,(gy - (gr * 0.45)),(22 * u),0,(Math_PI * 2));
ctx:fill();
ctx.font = (("700 " .. S2(Math_round((14 * u)))) .. "px \"Noto Sans SC\", sans-serif");
ctx.fillStyle = "#EDE6D6";
ctx:fillText("按住拖动飞行",gx,((gy + gr) + (22 * u)));
ctx.globalAlpha = 1;
end;
if (S.joy.id ~= nil) then
ctx.strokeStyle = "rgba(92,242,220,.7)";
ctx.lineWidth = (3 * u);
jr = (60 * u);
ctx:beginPath();
ctx:arc(S.joy.cx,S.joy.cy,jr,0,(Math_PI * 2));
ctx:stroke();
ctx.fillStyle = "rgba(237,230,214,.55)";
ctx:beginPath();
ctx:arc((S.joy.cx + (S.joy.dx * jr)),(S.joy.cy - (S.joy.dy * jr)),(22 * u),0,(Math_PI * 2));
ctx:fill();
end;
if (S.look.id ~= nil) then
ctx.strokeStyle = "rgba(245,165,36,.6)";
ctx.lineWidth = (2 * u);
ctx:beginPath();
ctx:arc(S.look.x,S.look.y,(26 * u),0,(Math_PI * 2));
ctx:stroke();
end;
end;
S.el = function(_this, tag, cls, html)
local e;
e = HOST.document:createElement(tag);
if T(cls) then
e.className = cls;
end;
if (html ~= nil) then
e.innerHTML = html;
end;
do return e end;
end;
S.buildHUD = function(_this)
local u, top, lb, pb, cop, card, act, dg, sb, tip, combo;
u = S.ui(nil);
u.innerHTML = "";
top = S.el(nil,"section","sv-top");
top.innerHTML = (("<div class=\"sv-xp\"><i></i><b></b></div><div class=\"sv-row\"><div class=\"sv-left\"><span class=\"cx-hull\"></span><span class=\"cx-cr\"></span><span class=\"cx-src\"></span></div>" .. "<div class=\"cx-mid\"><b class=\"cx-ch\"></b><span class=\"cx-dist\"></span></div><div class=\"sv-right\"></div></div><div class=\"sv-slots\"></div>") .. "<div class=\"sv-boss\" hidden><b></b><div class=\"sv-bossbar\"><i></i></div></div><div class=\"sv-banner\" hidden></div>");
u:appendChild(top);
S.lvDefer = false;
S.lvManual = false;
lb = S.el(nil,"button","cx-lvbadge");
lb.hidden = true;
lb.onclick = function(_this)
S.lvDefer = false;
S.lvManual = true;
end;
u:appendChild(lb);
pb = S.el(nil,"button","sbtn sv-pause cx-pause","暂停");
pb.onclick = S.openPause;
;(top:querySelector(".sv-right")):appendChild(pb);
cop = S.C:char(S.R.pilot); card = S.el(nil,"section","panel sv-cc cx-cop");
card.innerHTML = (((((((("<span class=\"ic\">" .. S2(S.A:catIcon(S.R.pilot,54))) .. "</span><div><b>") .. S2(cop.name)) .. " <small>") .. (T(S.R.match) and "专属 +20%" or "驾驶员")) .. "</small></b><small>") .. S2(cop.support.name)) .. "</small><div class=\"sv-cd\"><i></i></div></div><em></em>");
u:appendChild(card);
act = S.el(nil,"button","cx-active",(((("<span class=\"ic\">" .. S2(S.A:catIcon(S.R.mech,74))) .. "</span><b>") .. S2(((S.M(nil)).active).name)) .. "</b><i class=\"cx-cdmask\"></i><em></em>"));
act:addEventListener("pointerdown",function(_this, e)
e:stopPropagation();
S.castActive(nil);
end);
u:appendChild(act);
dg = S.el(nil,"button","cx-dodge",(("<b>" .. ((S.nitroOf(nil)).name):replace("氮气","氮气<br>")) .. "</b><i class=\"cx-cdmask\"></i>"));
dg:addEventListener("pointerdown",function(_this, e)
e:stopPropagation();
S.dodge(nil);
end);
u:appendChild(dg);
sb = nil;
if T(S.R.sub) then
sb = S.el(nil,"button","cx-sub",(("<b>" .. S2(S.R.sub.def.n)) .. "</b><em></em><i class=\"cx-cdmask\"></i>"));
sb.style:setProperty("--sc",S.R.sub.def.color);
sb:addEventListener("pointerdown",function(_this, e)
e:stopPropagation();
S.fireSub(nil,true);
end);
u:appendChild(sb);
end;
tip = S.el(nil,"div","cx-tip");
tip.hidden = true;
u:appendChild(tip);
combo = S.el(nil,"div","cx-combo");
combo.hidden = true;
u:appendChild(combo);
S.hud = {top=top,card=card,act=act,dg=dg,sb=sb,tip=tip,combo=combo,t=0,lvb=lb};
end;
S.updateHUD = function(_this, dt)
local top, slots, lbOn, cb, actb, bb, bn, st, frac, n;
S.hud.t = (S.hud.t - dt);
if (S.hud.t > 0) then
do return end;
end;
S.hud.t = 0.1;
top = S.hud.top;
;((top:querySelector(".sv-xp i")).style).width = (S2(((S.R.xp / S.xpNeed(nil,S.R.level)) * 100)) .. "%");
;(top:querySelector(".sv-xp b")).textContent = ("Lv " .. S2(S.R.level));
;(top:querySelector(".cx-hull")).textContent = ((("耐久 " .. S2(Math_ceil(S.R.hull))) .. " / ") .. S2(S.hullMax(nil)));
;(top:querySelector(".cx-cr")).innerHTML = ((S2(S.A:resIcon("credit",30)) .. " ") .. S.R.credits:toLocaleString("zh-CN"));
;(top:querySelector(".cx-src")).innerHTML = ((S2(S.A:resIcon("shard",30)) .. " 星源 ") .. S2(S.R.src));
;(top:querySelector(".cx-ch")).textContent = ((("第 " .. S2(S.R.ch.id)) .. " 章 ") .. S2(S.R.ch.name));
;(top:querySelector(".cx-dist")).textContent = (((function() if T(S.R.daily) then return ((((("每日挑战　第 " .. S2(S.R.wave)) .. " 波　剩余 ") .. S2(S.mmss(nil,(S.C.DC_TIME - S.R.secT)))) .. "　得分 ") .. S2(S.dcScore(nil))) else return (function() if T(S.R.endless) then return ((("无尽模式　第 " .. S2(S.R.wave)) .. " 波　") .. S2(S.mmss(nil,S.R.t))) else return ((((("星域 " .. S2(S.R.sector)) .. " / ") .. S2(S.SECTORS)) .. "　") .. S2(((S.R.gate.state == "open") and "飞进星门" or S.R.objective))) end end)() end end)() .. (function() if (S.R.danger > 1) then return ("　危险 " .. S2(S.R.danger)) else return "" end end)()) .. (function() if T(S.R.affix) then return (((("　[" .. S2(S.R.affix.name)) .. "：") .. S2(S.R.affix.desc)) .. "]") else return "" end end)());
slots = ((S.R.mods:map(function(_this, md)
do return (((("<span class=\"sv-slot\">" .. S2(S.A:iconSVG(S.C:modIcon(md.m),34))) .. "<b>") .. S2((T(md.evo) and "★" or md.lv))) .. "</b></span>") end;
end)):join("") .. (((G.Object:keys(S.UPG)):filter(function(_this, k)
do return (((S.lv(nil,k) > 0) and (k ~= "main")) and (k ~= "support")) end;
end)):map(function(_this, k)
do return (((("<span class=\"sv-slot\">" .. S2(S.A:iconSVG(S.ICON[k],34))) .. "<b>") .. S2(S.lv(nil,k))) .. "</b></span>") end;
end)):join(""));
if T(S.hud.lvb) then
lbOn = (function() local _t = ((S.R.pendingLevels > 0) and S.lvDefer); if not T(_t) then return _t end; return (not T(S.paused)) end)();
S.hud.lvb.hidden = (not T(lbOn));
if T(lbOn) then
S.hud.lvb.textContent = (("升级 ×" .. S2(S.R.pendingLevels)) .. "　点击选择");
end;
end;
cb = S.hud.combo;
if ((S.R.combo >= 5) and (S.R.comboT > 0)) then
cb.hidden = false;
cb.innerHTML = (((("<b>" .. S2(S.R.combo)) .. "</b><span>") .. ((S.R.feverT > 0) and "连击 · 狂热" or "连击")) .. "</span>");
else
cb.hidden = true;
end;
slots = ((((("<span class=\"sv-slot\">" .. S2(S.A:catIcon(S.R.mech,30))) .. "<b>") .. S2(S.lv(nil,"main"))) .. "</b></span>") .. S2(slots));
if (top._slots ~= slots) then
;(top:querySelector(".sv-slots")).innerHTML = slots;
top._slots = slots;
end;
actb = HOST.document:querySelector(".cx-active");
if T(actb) then
actb.classList:toggle("cx-boost",(S.R.nitroT > 0));
end;
bb = top:querySelector(".sv-boss");
bb.hidden = ((not T(S.R.boss)) or (S.R.boss.hp <= 0));
if T(S.R.boss) then
;(bb:querySelector("b")).textContent = S.R.boss.d.name;
;((bb:querySelector("i")).style).width = (S2((S.clamp(nil,(S.R.boss.hp / S.R.boss.max),0,1) * 100)) .. "%");
end;
bn = top:querySelector(".sv-banner");
bn.hidden = (not (S.R.bannerT > 0));
if (S.R.bannerT > 0) then
bn.textContent = S.R.banner;
end;
st = S.supportStat(nil);
;((S.hud.card:querySelector(".sv-cd i")).style).width = (S2((S.clamp(nil,(1 - (S.R.supportCd / (((S.C:char(S.R.pilot)).support).cd * st.cd))),0,1) * 100)) .. "%");
;(S.hud.card:querySelector("em")).textContent = ("Lv " .. S2(st.lv));
frac = (S.R.activeCd / S.activeCdMax(nil));
;((S.hud.act:querySelector(".cx-cdmask")).style).height = (S2((frac * 100)) .. "%");
;(S.hud.act:querySelector("em")).textContent = (function() if (S.R.activeCd > 0) then return Math_ceil(S.R.activeCd) else return "" end end)();
S.hud.act.classList:toggle("ready",(S.R.activeCd <= 0));
;((S.hud.dg:querySelector(".cx-cdmask")).style).height = (S2(((S.R.dodgeCd / (2.5 * (1 - S.fx(nil,"dodge")))) * 100)) .. "%");
if (T(S.hud.sb) and T(S.R.sub)) then
;(S.hud.sb:querySelector("em")).textContent = ((S2(S.R.sub.ammo) .. " / ") .. S2(S.R.sub.cap));
;((S.hud.sb:querySelector(".cx-cdmask")).style).height = (S2((S.clamp(nil,(S.R.sub.cd / S.subCdMax(nil)),0,1) * 100)) .. "%");
S.hud.sb.classList:toggle("empty",(S.R.sub.ammo <= 0));
end;
n = S.R.nearNode;
S.hud.tip.hidden = (not T(n));
if T(n) then
S.hud.tip.innerHTML = ((((("<b style=\"color:" .. S2(n.info.color)) .. "\">") .. S2(n.info.name)) .. "</b>") .. S2((function() if ((n.type == "derelict") and (n.state == "active")) then return (("搜刮中 " .. S2(Math_round((n.progress * 100)))) .. "%") else return (function() if ((n.type == "gate") and (n.state ~= "open")) then return ("先完成本星域目标：" .. S2(S.R.objective)) else return n.info.hint end end)() end end)()));
end;
end;
S.modal = function(_this, html)
local m;
m = S.el(nil,"div","sv-modal");
m.innerHTML = html;
;(S.ui(nil)):appendChild(m);
do return m end;
end;
S.autoLevel = function(_this)
local ids, best, bs, PRI, nm;
S.R.pendingLevels = S.R.pendingLevels - 1;
S.C:sfx("level");
S.R.rr = (T(S.R.rr) and S.R.rr or {free=2,ad=0});
ids = S.choices(nil); best = ids[0]; bs = (-1); PRI = {hull=45,power=44,cooling=43,engine=40,magnet=38,repair=36};
ids:forEach(function(_this, id)
local sc;
sc = ((id:indexOf("evo") == 0) and 100 or ((id:indexOf("mod") == 0) and 80 or ((id == "main") and 70 or ((id:indexOf("new") == 0) and 60 or ((id == "support") and 50 or (function() if (id == "heal") then return ((S.R.hull < (S.hullMax(nil) * 0.5)) and 90 or 10) else return (T(PRI[id]) and PRI[id] or 30) end end)())))));
if (sc > bs) then
bs = sc;
best = id;
end;
end);
nm = (S.choiceInfo(nil,best)).name;
S.applyChoice(nil,best);
S.afterChoice(nil);
S.A:toast(("自动升级：" .. S2(nm)));
S.R.gems:forEach(function(_this, g)
if (S.dd(nil,g,(S.P(nil))) < 2025) then
g.pull = true;
end;
end);
end;
S.lvForced = function(_this)
do return ((not (not T(S.R))) and (((T(S.R.chestPick) and S.R.chestPick or 0) > 0) or (T(S.R.tutRun) and (not T(S.R.tutPicked))))) end;
end;
S.levelMode = function(_this)
local m;
m = S.setting(nil,"lvMode","now");
if ((T(S.R) and T(S.R.tutRun)) and (not T(S.R.tutPicked))) then
do return "now" end;
end;
if T(S.lvForced(nil)) then
do return ((m == "auto") and "auto" or "now") end;
end;
do return m end;
end;
S.lvTitle = function(_this)
if (T(S.R) and ((T(S.R.chestPick) and S.R.chestPick or 0) > 0)) then
do return {t="宝箱奖励！",s="这次的选择效果加倍：技能 / 强化额外 +1 级"} end;
end;
if ((T(S.R) and T(S.R.tutRun)) and (not T(S.R.tutPicked))) then
do return {t="升级！",s="选一张卡：新技能、已有技能升级或机甲强化。同一技能升到 Lv5，再配合对应强化还能进化"} end;
end;
do return {t="升级！",s="选择一项强化"} end;
end;
S.openLevelUp = function(_this)
local mode, forced, tt, m, box, rr, done, fill;
done = function(_this)
m:remove();
S.paused = false;
S.afterChoice(nil);
S.R.gems:forEach(function(_this, g)
if (S.dd(nil,g,(S.P(nil))) < 2025) then
g.pull = true;
end;
end);
end;
fill = function(_this)
local ids, left;
box.innerHTML = "";
ids = S.choices(nil);
ids:forEach(function(_this, id)
local info, b;
info = S.choiceInfo(nil,id); b = S.el(nil,"button",(("sv-card" .. (T(info.crew) and " crew" or "")) .. (T(info.evo) and " evo" or "")));
b.innerHTML = (((((((((("<span class=\"tag" .. (T(info.crew) and " shard" or "")) .. "\">") .. S2(info.tag)) .. "</span><span class=\"ic\">") .. S2(info.icon)) .. "</span><b>") .. S2(info.name)) .. "</b><p>") .. S2(info.text)) .. "</p>");
b.onclick = function(_this)
S.applyChoice(nil,id);
done(nil);
end;
box:appendChild(b);
end);
left = ((S.R.rr.free > 0) and 0 or Math_max(0,(3 - S.R.rr.ad)));
rr.textContent = (function() if (S.R.rr.free > 0) then return (("刷新选项（免费 " .. S2(S.R.rr.free)) .. " 次）") else return (function() if (left > 0) then return (("看广告 刷新选项（还可 " .. S2(left)) .. " 次）") else return "刷新次数已用完" end end)() end end)();
rr.disabled = ((S.R.rr.free <= 0) and (left <= 0));
rr.className = ("btn" .. (((S.R.rr.free <= 0) and (left > 0)) and " cx-adbtn" or ""));
end;
mode = S.levelMode(nil); forced = S.lvForced(nil);
if (T(S.lvDefer) and (not T(forced))) then
do return end;
end;
if (mode == "auto") then
S.autoLevel(nil);
do return end;
end;
if ((mode == "later") and (not T(S.lvManual))) then
S.lvDefer = true;
do return end;
end;
S.lvManual = false;
if T(forced) then
S.lvDefer = false;
end;
tt = S.lvTitle(nil);
S.paused = true;
S.R.pendingLevels = S.R.pendingLevels - 1;
S.C:sfx("level");
S.R.rr = (T(S.R.rr) and S.R.rr or {free=2,ad=0});
m = S.modal(nil,(((((("<div class=\"sv-lu\"><h1>" .. S2(tt.t)) .. "</h1><p>") .. S2(tt.s)) .. "</p><div class=\"sv-cards\"></div><div class=\"lu-acts\"><button class=\"btn\" id=\"lu-rr\"></button><button class=\"btn\" id=\"lu-skip\">跳过，回复 30% 耐久</button><button class=\"btn\" id=\"lu-later\"") .. (T(forced) and " hidden" or "")) .. ">稍后选择<small>战斗继续，随时再点</small></button></div></div>")); box = m:querySelector(".sv-cards"); rr = m:querySelector("#lu-rr");
rr.onclick = function(_this)
if (S.R.rr.free > 0) then
S.R.rr.free = S.R.rr.free - 1;
S.C:sfx("click");
fill(nil);
do return end;
end;
if (S.R.rr.ad >= 2) then
do return end;
end;
S.C:showAd("刷新升级选项",function(_this, r)
if (not T(r.success)) then
S.A:toast("需要完整看完广告才能刷新");
do return end;
end;
S.R.rr.ad = S.R.rr.ad + 1;
S.C:sfx("click");
fill(nil);
end);
end;
;(m:querySelector("#lu-later")).onclick = function(_this)
m:remove();
S.paused = false;
S.R.pendingLevels = S.R.pendingLevels + 1;
S.lvDefer = true;
S.A:toast("升级已保留，点屏幕左侧的“升级”按钮随时选择");
end;
;(m:querySelector("#lu-skip")).onclick = function(_this)
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.3)));
S.A:toast("跳过：回复 30% 耐久");
done(nil);
end;
fill(nil);
end;
S.openShop = function(_this, n)
local disc, offers, html, m;
S.paused = true;
disc = 1;
offers = smt({[0]={name="紧急维修",text="修复 50% 耐久",cost=Math_round((150 * disc)),go=function(_this)
S.R.hull = Math_min(S.hullMax(nil),(S.R.hull + (S.hullMax(nil) * 0.5)));
end},{name="强化芯片",text="立即升级 1 次",cost=Math_round((260 * disc)),go=function(_this)
S.R.pendingLevels = S.R.pendingLevels + 1;
end},{name="星魂结晶",text="驾驶员碎片 +5",cost=Math_round((400 * disc)),go=function(_this)
S.R.frags[S.R.pilot] = ((T(S.R.frags[S.R.pilot]) and S.R.frags[S.R.pilot] or 0) + 5);
end},length=3},AMT);
html = (("<div class=\"panel sv-pbox\"><h1>流浪商人</h1><p class=\"note\">用本局收集的信用点交易。当前：" .. S2(S.R.credits)) .. "</p><div class=\"cx-shop\">");
offers:forEach(function(_this, o, i)
html = (S2(html) .. (((((((((("<button class=\"sv-card cx-offer\" data-i=\"" .. S2(i)) .. "\"") .. ((S.R.credits < o.cost) and " disabled" or "")) .. "><b>") .. S2(o.name)) .. "</b><p>") .. S2(o.text)) .. "</p><span class=\"tag\">") .. S2(o.cost)) .. " 信用点</span></button>"));
end);
html = (S2(html) .. "</div><button class=\"btn\" id=\"cx-leave\">离开</button></div>");
m = S.modal(nil,html);
;(m:querySelectorAll(".cx-offer")):forEach(function(_this, b)
b.onclick = function(_this)
local o;
o = offers[tonum(b.dataset.i)];
if (S.R.credits < o.cost) then
do return end;
end;
S.R.credits = (S.R.credits - o.cost);
o:go();
S.A:toast(("购买了 " .. S2(o.name)));
m:remove();
S.openShop(nil,n);
end;
end);
;(m:querySelector("#cx-leave")).onclick = function(_this)
m:remove();
S.paused = false;
end;
end;
S.openPause = function(_this)
local m;
if (T(S.paused) or (not T(S.R))) then
do return end;
end;
S.paused = true;
m = S.modal(nil,("<div class=\"panel sv-pbox\"><h1>暂停</h1><div class=\"sv-btns\"><button class=\"btn primary\" id=\"sv-res\">继续</button><button class=\"btn\" id=\"sv-set\">设置</button><button class=\"btn\" id=\"sv-quit\">撤退返回</button></div>" .. "<p class=\"note\">左半屏拖动飞行（朝镜头方向），右半屏拖动转视角；武器自动锁定开火。右下大按钮释放机甲技能（电脑空格），小按钮氮气推进（电脑 Shift，每台机甲氮气形态不同）。电脑：WASD 飞行，R/F 升降，方向键转视角。每个星域完成箭头指向的目标，并击败足够的敌人为星门充能，星门就会开启。闯过 6 个星域、击败首领即可通关。</p></div>"));
;(m:querySelector("#sv-res")).onclick = function(_this)
m:remove();
S.paused = false;
end;
;(m:querySelector("#sv-quit")).onclick = function(_this)
m:remove();
S.endRun(nil,false,true);
end;
;(m:querySelector("#sv-set")).onclick = function(_this)
m:remove();
S.paused = false;
S.openBattleSet(nil);
end;
end;
S.openBattleSet = function(_this)
local html, m;
S.paused = true;
html = "<div class=\"panel sv-pbox mk-get\"><h1>战斗设置</h1>";
S.BATTLE_SET:forEach(function(_this, it, i)
local cur;
cur = S.setting(nil,it.k,it.d);
html = (S2(html) .. (((("<div class=\"mk-row\"><div><b>" .. S2(it.n)) .. "</b></div>") .. (it.o:map(function(_this, o, j)
do return (((((((("<button class=\"mini" .. ((cur == o[0]) and "" or " alt")) .. "\" data-i=\"") .. S2(i)) .. "\" data-j=\"") .. S2(j)) .. "\">") .. S2(o[1])) .. "</button>") end;
end)):join("")) .. "</div>"));
end);
html = (S2(html) .. "<button class=\"btn primary\" id=\"bs-back\">返回</button></div>");
m = S.modal(nil,html);
;(m:querySelectorAll("[data-i]")):forEach(function(_this, b)
b.onclick = function(_this)
local it;
it = S.BATTLE_SET[tonum(b.dataset.i)];
S.setSetting(nil,it.k,it.o[tonum(b.dataset.j)][0]);
S.C:sfx("click");
m:remove();
S.paused = false;
S.openBattleSet(nil);
end;
end);
;(m:querySelector("#bs-back")).onclick = function(_this)
m:remove();
S.paused = false;
S.openPause(nil);
end;
end;
S.openRevive = function(_this)
local m, ad;
if T(S.R.ended) then
do return end;
end;
S.paused = true;
m = S.modal(nil,(("<div class=\"panel sv-pbox\"><h1>机甲被击毁</h1><p>看一段广告可以原地复活（耐久 50%），每局限一次。</p><div class=\"sv-btns\">" .. (T(S.R.adRevived) and "" or "<button class=\"btn primary\" id=\"cx-ad\">看广告复活</button>")) .. "<button class=\"btn\" id=\"cx-end\">结束远征</button></div></div>"));
ad = m:querySelector("#cx-ad");
if T(ad) then
ad.onclick = function(_this)
S.C:showAd("复活机甲",function(_this, r)
if (not T(r.success)) then
S.A:toast("需要完整看完广告才能复活");
do return end;
end;
m:remove();
S.R.adRevived = true;
S.R.over = false;
S.paused = false;
S.R.hull = (S.hullMax(nil) * 0.5);
S.R.iframe = 2;
S.nova(nil,S.P(nil),14,60,"#5CF2DC");
S.banner(nil,"复活！");
end);
end;
end;
;(m:querySelector("#cx-end")).onclick = function(_this)
m:remove();
S.endRun(nil,false);
end;
end;
S.buildTxt = function(_this)
do return (S.R.mods:map(function(_this, md)
do return (((S2(md.m.name) .. " Lv") .. S2(md.lv)) .. (T(md.evo) and "★" or "")) end;
end)):join("、") end;
end;
S.dcScore = function(_this)
do return ((((S.R.kills * 10) + ((S.R.wave - 1) * 100)) + ((T(S.R.bossKilled) and S.R.bossKilled or 0) * 300)) + ((T(S.R.won) or (T(S.R.ended) and (not T(S.R.over)))) and 500 or 0)) end;
end;
S.endRun = function(_this, win, retreat)
local s, first, dgm, credits, src, dgUnlock, dcScoreV, dcFirst, dcs, achNow, reach, fragTxt, m;
if ((not T(S.R)) or T(S.R.ended)) then
do return end;
end;
S.R.ended = true;
S.paused = true;
s = S.C.save; first = (T(win) and (not T(s.cleared[S.R.ch.id])));
dgm = (1 + (0.15 * (S.R.danger - 1))); credits = Math_round(((((S.R.credits + (S.R.kills * 1)) + (function() if T(win) then return (800 * S.R.ch.id) else return 0 end end)()) + (function() if T(S.R.endless) then return (S.R.wave * 60) else return 0 end end)()) * dgm)); src = ((S.R.src + (function() if T(first) then return S.R.ch.first else return 0 end end)()) + (function() if T(S.R.endless) then return Math_floor((S.R.wave / 3)) else return (function() if T(win) then return (S.R.danger - 1) else return 0 end end)() end end)());
if (((not T(win)) and (not T(retreat))) and (not T(S.R.endless))) then
credits = Math_round((credits * 0.7));
end;
dgUnlock = false;
if (((T(win) and (not T(S.R.endless))) and (S.R.danger >= (T(s.dangerMax) and s.dangerMax or 1))) and ((T(s.dangerMax) and s.dangerMax or 1) < 10)) then
s.dangerMax = ((T(s.dangerMax) and s.dangerMax or 1) + 1);
dgUnlock = true;
end;
if (T(S.R.endless) and (not T(S.R.daily))) then
s.endlessBest = Math_max((T(s.endlessBest) and s.endlessBest or 0),S.R.wave);
end;
dcScoreV = (function() if T(S.R.daily) then return ((((S.R.kills * 10) + ((S.R.wave - 1) * 100)) + ((T(S.R.bossKilled) and S.R.bossKilled or 0) * 300)) + (T(win) and 500 or 0)) else return 0 end end)(); dcFirst = false;
if T(S.R.daily) then
dcs = (S.C:dailyChallenge()).state;
dcFirst = (not T(dcs.done));
dcs.done = true;
dcs.runs = dcs.runs + 1;
dcs.best = Math_max(dcs.best,dcScoreV);
s.dcBest = Math_max((T(s.dcBest) and s.dcBest or 0),dcScoreV);
if T(dcFirst) then
credits = (credits + 800);
src = (src + (10 + ((dcScoreV >= 1500) and 5 or 0)));
end;
if T(S.dmod(nil,"iron")) then
credits = Math_round((credits * 1.2));
end;
end;
s.credits = (s.credits + credits);
s.src = (s.src + src);
s.runs = s.runs + 1;
s.totalKills = ((T(s.totalKills) and s.totalKills or 0) + S.R.kills);
if T(win) then
s.bossKills = ((T(s.bossKills) and s.bossKills or 0) + 1);
end;
achNow = S.C:achReady();
reach = (function() if T(win) then return S.SECTORS else return S.R.sector end end)();
if (not T(S.R.endless)) then
s.best[S.R.ch.id] = Math_max((T(s.best[S.R.ch.id]) and s.best[S.R.ch.id] or 0),reach);
end;
s.daily.runs = ((T(s.daily.runs) and s.daily.runs or 0) + 1);
s.daily.kills = ((T(s.daily.kills) and s.daily.kills or 0) + S.R.kills);
if T(S.R.sub) then
S.C:settleAmmo(S.R.sub.def.id,S.R.sub.used,S.R.sub.gained);
end;
;(G.Object:keys(S.R.frags)):forEach(function(_this, id)
s.frags[id] = ((T(s.frags[id]) and s.frags[id] or 0) + S.R.frags[id]);
end);
if (T(win) and (not T(S.R.endless))) then
s.cleared[S.R.ch.id] = true;
s.chapter = Math_max(s.chapter,(Math_min(LEN(S.C.CHAPTERS),(S.R.ch.id + 1))));
end;
S.C:write();
fragTxt = ((G.Object:keys(S.R.frags)):map(function(_this, id)
do return ((S2((S.C:char(id)).name) .. " 碎片 +") .. S2(S.R.frags[id])) end;
end)):join("，");
S.R.result = {win=win,retreat=retreat,credits=credits,src=src,first=first,dgUnlock=dgUnlock,dcScore=dcScoreV,dcFirst=dcFirst,achNow=achNow,fragTxt=fragTxt,subUsed=(function() if T(S.R.sub) then return S.R.sub.used else return 0 end end)(),subName=(function() if T(S.R.sub) then return S.R.sub.def.n else return "" end end)(),build=S.buildTxt(nil)};
m = S.modal(nil,((((((((((((((((((((((((((((((("<div class=\"panel sv-pbox\"><h1>" .. (function() if T(S.R.daily) then return (T(win) and "每日挑战完成" or "每日挑战结束") else return (T(S.R.endless) and "无尽模式结束" or (T(win) and "远征成功" or (T(retreat) and "已撤退返回" or "远征失败"))) end end)()) .. "</h1>") .. "<dl class=\"sv-res\"><div><dt>到达</dt><dd>") .. (function() if T(S.R.daily) then return ("得分 " .. S2(dcScoreV)) else return (function() if T(S.R.endless) then return (("第 " .. S2(S.R.wave)) .. " 波") else return (T(win) and "通关" or ((S2(S.R.sector) .. " / ") .. S2(S.SECTORS))) end end)() end end)()) .. "</dd></div><div><dt>用时</dt><dd>") .. S2(S.mmss(nil,S.R.t))) .. "</dd></div><div><dt>击破</dt><dd>") .. S2(S.R.kills)) .. "</dd></div><div><dt>信用点</dt><dd>+") .. credits:toLocaleString("zh-CN")) .. "</dd></div><div><dt>星源</dt><dd>+") .. S2(src)) .. "</dd></div></dl>") .. "<dl class=\"sv-res mk-grow\"><div><dt>本局等级</dt><dd>Lv ") .. S2(S.R.level)) .. "</dd></div><div><dt>最高连击</dt><dd>") .. S2((T(S.R.bestCombo) and S.R.bestCombo or 0))) .. "</dd></div><div><dt>造成伤害</dt><dd>") .. (Math_round((T(S.R.dmgDealt) and S.R.dmgDealt or 0))):toLocaleString("zh-CN")) .. "</dd></div><div><dt>承受伤害</dt><dd>") .. (Math_round((T(S.R.dmgTaken) and S.R.dmgTaken or 0))):toLocaleString("zh-CN")) .. "</dd></div></dl>") .. (function() if T(achNow) then return (("<p class=\"note\">有 " .. S2(achNow)) .. " 个成就可以领取，去“每日”页领取星源。</p>") else return "" end end)()) .. (function() if T(first) then return (((("<p class=\"note\">首次通关奖励：星源 +" .. S2(S.R.ch.first)) .. "。第 ") .. (function() if ((S.R.ch.id + 1) <= LEN(S.C.CHAPTERS)) then return (S2((S.R.ch.id + 1)) .. " 章已解锁。") else return "全部章节已通关。" end end)()) .. "</p>") else return "" end end)()) .. (function() if T(dgUnlock) then return (("<p class=\"note\">危险等级 " .. S2(s.dangerMax)) .. " 已解锁（奖励更高，敌人更强）。</p>") else return "" end end)()) .. (function() if (T(S.R.endless) and (not T(S.R.daily))) then return (("<p class=\"note\">无尽最高纪录：第 " .. S2(s.endlessBest)) .. " 波。</p>") else return "" end end)()) .. (function() if T(S.R.daily) then return ((("<p class=\"note\">今日最高分 " .. S2(((S.C:dailyChallenge()).state).best)) .. (function() if T(dcFirst) then return (("。首次完成奖励：信用点 +800，星源 +" .. S2((10 + ((dcScoreV >= 1500) and 5 or 0)))) .. "。") else return "。今日奖励已领取。" end end)()) .. "</p>") else return "" end end)()) .. ((((not T(win)) and (not T(retreat))) and (not T(S.R.endless))) and "<p class=\"note\">远征失败只带回 70% 信用点。</p>" or "")) .. (function() if T(fragTxt) then return (("<p class=\"note\">" .. S2(fragTxt)) .. "</p>") else return "" end end)()) .. (function() if T(S.R.result.build) then return (("<p class=\"note\">本局构筑：" .. S2(S.R.result.build)) .. "</p>") else return "" end end)()) .. "<div class=\"sv-btns\"><button class=\"btn cx-adbtn\" id=\"cx-double\">看广告 信用点翻倍</button><button class=\"btn\" id=\"cx-share\">分享战绩</button><button class=\"btn primary\" id=\"cx-home\">返回机库</button></div></div>"));
;(m:querySelector("#cx-share")).onclick = function(_this)
local tx, ta, e, e2;
tx = (((((((("我在《宇宙银河机甲》" .. (function() if T(S.R.daily) then return (("每日挑战拿到了 " .. S2(dcScoreV)) .. " 分") else return (function() if T(S.R.endless) then return (("无尽模式撑到了第 " .. S2(S.R.wave)) .. " 波") else return (function() if T(win) then return ((("通关了第 " .. S2(S.R.ch.id)) .. " 章") .. (function() if (S.R.danger > 1) then return (("（危险等级 " .. S2(S.R.danger)) .. "）") else return "" end end)()) else return ("闯到了星域 " .. S2(S.R.sector)) end end)() end end)() end end)()) .. "！用 ") .. S2((S.C:mech(S.R.mech)).name)) .. "击破 ") .. S2(S.R.kills)) .. " 个敌人，最高 ") .. S2((T(S.R.bestCombo) and S.R.bestCombo or 0))) .. " 连击。来挑战我吧！");
ta = HOST.document:createElement("textarea");
ta.value = tx;
ta.style.position = "fixed";
ta.style.opacity = "0";
HOST.document.body:appendChild(ta);
ta:select();
do local _ok, _f, _v = pcall(function()
HOST.document:execCommand("copy");
S.A:toast("战绩已复制，去分享给朋友吧");
end)
if not _ok then e = _f
S.A:toast(tx);
elseif _f == "R" then do return _v end end end;
ta:remove();
if T(HOST.navigator.share) then
do local _ok, _f, _v = pcall(function()
HOST.navigator:share({text=tx});
end)
if not _ok then e2 = _f
elseif _f == "R" then do return _v end end end;
end;
end;
;(m:querySelector("#cx-double")).onclick = function(_this, ev)
local b;
b = ev.currentTarget;
S.C:showAd("结算奖励翻倍",function(_this, r)
if (not T(r.success)) then
S.A:toast("需要完整看完广告才能领取");
do return end;
end;
s.credits = (s.credits + credits);
S.C:write();
b.disabled = true;
b.textContent = ("已翻倍 +" .. credits:toLocaleString("zh-CN"));
S.A:toast(("信用点再 +" .. credits:toLocaleString("zh-CN")));
end);
end;
;(m:querySelector("#cx-home")).onclick = function(_this)
S.R = nil;
HOST.window.CosmicHub:open();
end;
end;
S.tutSteps = function(_this)
local mob;
mob = (not (not T(S.A.isMobile)));
do return smt({[0]={text=(T(mob) and "左半屏按住拖动：朝镜头方向飞行；右半屏拖动：转动视角" or "WASD 飞行，R / F 升降；方向键或按住右半屏拖动：转动视角"),done=function(_this)
do return (S.len3(nil,S.R.vx,S.R.vy,S.R.vz) > 5) end;
end},{text="武器会自动锁定开火。击败敌人，飞过去捡青色能量，攒满就能升级选卡",done=function(_this)
do return ((S.R.level >= 2) and (not (not T(S.R.tutPicked)))) end;
end},{text=(T(mob) and "右下大按钮放机甲技能，旁边小按钮是氮气推进（冲刺时短暂无敌）。点一下技能试试" or "空格键放机甲技能，Shift 是氮气推进（冲刺时短暂无敌）。按一下空格试试"),done=function(_this)
do return S.R.tutorialSkill end;
end},{text="跟着屏幕边缘的箭头去完成本星域目标。目标可能在上方或下方",done=function(_this)
do return S.objectiveDone(nil) end;
end},{text="击败敌人为星门充能，屏幕上方会显示还差多少",done=function(_this)
do return ((S.R.gate.state == "open") or (S.R.sector >= 2)) end;
end},{text="星门开启了！飞进去前往下一个星域",done=function(_this)
do return (S.R.sector >= 2) end;
end},length=6},AMT) end;
end;
S.startTutorial = function(_this)
local steps, i, box, show;
show = function(_this)
S.R.tutUI = {n=(i + 1),total=LEN(steps),text=steps[i].text};
box.innerHTML = (((((("<span class=\"tag shard\">新手引导 " .. S2((i + 1))) .. " / ") .. S2(LEN(steps))) .. "</span><b>") .. S2(steps[i].text)) .. "</b>");
end;
steps = S.tutSteps(nil); i = 0;
box = S.el(nil,"div","cx-tut");
;(S.ui(nil)):appendChild(box);
show(nil);
S.R.tutorial = {event=function(_this, k)
if (k == "skill") then
S.R.tutorialSkill = true;
end;
end,tick=function(_this)
local moved;
if ((i >= LEN(steps)) or T(S.paused)) then
do return end;
end;
moved = false;
while ((i < LEN(steps)) and T(steps[i]:done())) do
i = i + 1;
moved = true;
end;
if (not T(moved)) then
do return end;
end;
S.C:sfx("pick");
if (i >= LEN(steps)) then
box:remove();
S.R.tutUI = nil;
S.C.save.tutorialDone = true;
S.C:write();
S.R.tutorial = nil;
S.A:toast("引导完成，祝你远征顺利！");
else
show(nil);
end;
end};
end;
S.bindPointer = function(_this)
local cv, up;
up = function(_this, e)
if (e.pointerId == S.joy.id) then
S.joy.id = nil;
S.joy.dy = 0;
S.joy.dx = S.joy.dy;
end;
if (e.pointerId == S.look.id) then
S.look.id = nil;
S.look.idle = 0;
end;
end;
cv = S.E.canvas;
cv:addEventListener("pointerdown",function(_this, e)
local r, x, y;
if (((S.A:mode() ~= "cosmic-run") or (not T(S.R))) or T(S.paused)) then
do return end;
end;
r = cv:getBoundingClientRect(); x = (e.clientX - r.left); y = (e.clientY - r.top);
if ((x < (r.width * 0.5)) and (S.joy.id == nil)) then
S.joy.id = e.pointerId;
S.joy.cx = x;
S.joy.cy = y;
S.joy.dy = 0;
S.joy.dx = S.joy.dy;
elseif (S.look.id == nil) then
S.look.id = e.pointerId;
S.look.x = x;
S.look.y = y;
S.look.idle = 0;
end;
cv:setPointerCapture(e.pointerId);
end);
cv:addEventListener("pointermove",function(_this, e)
local r, x, y, dx, dy, R0, l, k;
r = cv:getBoundingClientRect(); x = (e.clientX - r.left); y = (e.clientY - r.top);
if (e.pointerId == S.joy.id) then
dx = (x - S.joy.cx); dy = (y - S.joy.cy); R0 = (60 * Math_max(0.55,((S.A:view()).s * 1.5))); l = Math_hypot(dx,dy);
if (l > R0) then
dx = ((dx / l) * R0);
dy = ((dy / l) * R0);
end;
S.joy.dx = (dx / R0);
S.joy.dy = ((-dy) / R0);
elseif ((e.pointerId == S.look.id) and T(S.R)) then
k = ((0.32 / Math_max(0.3,((S.A:view()).s * 1.5))) * S.sensK(nil));
S.R.camYaw = (S.R.camYaw + ((x - S.look.x) * k));
S.R.camPitch = S.clamp(nil,(S.R.camPitch + ((y - S.look.y) * k)),(-70),70);
S.look.x = x;
S.look.y = y;
S.look.idle = 0;
end;
end);
cv:addEventListener("pointerup",up);
cv:addEventListener("pointercancel",up);
end;
;(function()
S.E = HOST.window.VoxEngine; S.C = HOST.window.Cosmic;
if ((not T(S.E)) or (not T(S.C))) then
do return end;
end;
S.DEG = (Math_PI / 180); S.BOUND = 150; S.SECTORS = 6;
S.PLAN = smt({[0]="normal","normal","elite","rest","normal","boss",length=6},AMT);
S.EVENTS = smt({[0]="pirate","derelict","ore","distress","hunt","ambush",length=6},AMT);
S.AFFIX = smt({[0]={id="swift",name="高速敌群",desc="敌人移速 +25%"},{id="fury",name="狂暴信号",desc="敌人伤害 +25%，能量 +30%"},{id="tide",name="能量潮汐",desc="敌人更多，能量 +50%"},length=3},AMT);
S.PARTS = smt({[0]="body","head","uarmL","uarmR","armL","armR","thighL","thighR","shinL","shinR",length=10},AMT);
S.MECHFX = JS.odict({mech_azure=JS.odict({fire=smt({[0]="R",length=1},AMT),aim=JS.odict({R="gun",L="guard"},{"R","L"}),glow="#9DF7EC",kick=0.5},{"fire","aim","glow","kick"}),mech_blaze=JS.odict({fire=smt({[0]="L",length=1},AMT),aim=JS.odict({L="gun",R="axe"},{"L","R"}),glow="#FF8A3A",kick=1.0},{"fire","aim","glow","kick"}),mech_halo=JS.odict({fire=smt({[0]="R",length=1},AMT),aim=JS.odict({R="staff",L="free"},{"R","L"}),glow="#C9B8FF",kick=0.3},{"fire","aim","glow","kick"}),mech_forge=JS.odict({fire=smt({[0]="R","L",length=2},AMT),aim=JS.odict({L="gun",R="gun"},{"L","R"}),glow="#FFB347",kick=0.5},{"fire","aim","glow","kick"}),mech_frost=JS.odict({fire=smt({[0]="P",length=1},AMT),aim=JS.odict({R="gun",L="free"},{"R","L"}),glow="#9DD8FF",kick=0.8},{"fire","aim","glow","kick"}),mech_starfall=JS.odict({fire=smt({[0]="R",length=1},AMT),aim=JS.odict({R="spear",L="free"},{"R","L"}),glow="#E0A0FF",kick=0.5},{"fire","aim","glow","kick"})},{"mech_azure","mech_blaze","mech_halo","mech_forge","mech_frost","mech_starfall"});
S.ENEMY = JS.odict({crawler=JS.odict({name="晶化爬虫",model="enemy_crystal_crawler",scale=3,lunge=JS.odict({cd=4.5,range=12,dash=24,dur=0.28,tele=0.45},{"cd","range","dash","dur","tele"}),hp=14,spd=9,dmg=6,xp=1,cr=2},{"name","model","scale","lunge","hp","spd","dmg","xp","cr"}),grunt=JS.odict({name="海贼喽啰",model="enemy_pirate_grunt",scale=2.6,lunge=JS.odict({cd=5.5,range=15,dash=28,dur=0.3,tele=0.5},{"cd","range","dash","dur","tele"}),hp=26,spd=7,dmg=8,xp=2,cr=3},{"name","model","scale","lunge","hp","spd","dmg","xp","cr"}),inter=JS.odict({name="海贼截击机",model="ship_pirate_interceptor",scale=0.9,hp=30,spd=11,dmg=7,xp=3,cr=4,keep=20,ship=true,shoot=JS.odict({cd=3.2,spd=20,dmg=6,n=1,spread=0,burst=3},{"cd","spd","dmg","n","spread","burst"})},{"name","model","scale","hp","spd","dmg","xp","cr","keep","ship","shoot"}),heavy=JS.odict({name="海贼重炮手",model="enemy_pirate_heavy",scale=3,hp=90,spd=4.5,dmg=12,xp=6,cr=8,shoot=JS.odict({cd=4,spd=16,dmg=7,n=3,spread=22,big=true},{"cd","spd","dmg","n","spread","big"})},{"name","model","scale","hp","spd","dmg","xp","cr","shoot"}),brute=JS.odict({name="晶核巨兽",model="enemy_crystal_brute",scale=3.4,slam=JS.odict({cd=7,r=14,tele=0.9,dmg=1.4},{"cd","r","tele","dmg"}),hp=520,spd=5,dmg=16,xp=30,cr=60,elite=true},{"name","model","scale","slam","hp","spd","dmg","xp","cr","elite"}),sniper=JS.odict({name="晶刺狙击手",model="enemy_crystal_sniper",scale=2.6,hp=40,spd=5,dmg=8,xp=5,cr=7,keep=34,snipe=JS.odict({cd=5.5,tele=1.4,dmg=16,spd=80},{"cd","tele","dmg","spd"})},{"name","model","scale","hp","spd","dmg","xp","cr","keep","snipe"}),guard=JS.odict({name="盾卫",model="enemy_shield_guard",scale=2.6,hp=85,spd=5.5,dmg=10,xp=5,cr=7,guard=true,lunge=JS.odict({cd=6.5,range=12,dash=22,dur=0.3,tele=0.55},{"cd","range","dash","dur","tele"})},{"name","model","scale","hp","spd","dmg","xp","cr","guard","lunge"}),splitter=JS.odict({name="裂变晶体",model="enemy_crystal_splitter",scale=2.4,hp=55,spd=6,dmg=7,xp=4,cr=5,split=3},{"name","model","scale","hp","spd","dmg","xp","cr","split"}),bomber=JS.odict({name="自爆虫",model="enemy_bomber_bug",scale=2.4,hp=12,spd=13,dmg=9,xp=2,cr=3,bomb=JS.odict({fuse=0.75,r=7,dmg=2.2,trig=6},{"fuse","r","dmg","trig"})},{"name","model","scale","hp","spd","dmg","xp","cr","bomb"}),phantom=JS.odict({name="幽影刺客",model="enemy_phantom_blade",scale=2.6,hp=40,spd=9,dmg=11,xp=6,cr=8,blink=JS.odict({cd=6.5,tele=0.7},{"cd","tele"}),lunge=JS.odict({cd=5,range=14,dash=30,dur=0.28,tele=0.35},{"cd","range","dash","dur","tele"})},{"name","model","scale","hp","spd","dmg","xp","cr","blink","lunge"}),ore=JS.odict({name="富矿",model="space_ore_asteroid",scale=1.3,hp=45,spd=0,dmg=0,xp=2,cr=15,ore=true},{"name","model","scale","hp","spd","dmg","xp","cr","ore"}),hive=JS.odict({name="晶簇巢",model="env_crystal_cluster",scale=3.6,hp=240,spd=0,dmg=0,xp=6,cr=12,hive=JS.odict({cd=5,n=2},{"cd","n"})},{"name","model","scale","hp","spd","dmg","xp","cr","hive"}),gunship_boss=JS.odict({name="海贼头目号",model="ship_pirate_gunship",scale=2.2,laser=JS.odict({from=2,every=8},{"from","every"}),hp=3300,spd=3.6,dmg=22,xp=0,cr=0,boss=true,keep=24,ship=true,shoot=JS.odict({cd=1.9,spd=17,dmg=9,n=7,spread=70},{"cd","spd","dmg","n","spread"})},{"name","model","scale","laser","hp","spd","dmg","xp","cr","boss","keep","ship","shoot"}),brute_king=JS.odict({name="晶核巨兽王",model="enemy_crystal_brute",scale=6.5,slam=JS.odict({cd=6,r=22,tele=1.0,dmg=1.5,ring=true},{"cd","r","tele","dmg","ring"}),hp=5600,spd=4.2,dmg=28,xp=0,cr=0,boss=true,shoot=JS.odict({cd=4,spd=14,dmg=10,ring=16},{"cd","spd","dmg","ring"}),summon=6},{"name","model","scale","slam","hp","spd","dmg","xp","cr","boss","shoot","summon"}),flagship_boss=JS.odict({name="赤髑号",model="ship_pirate_flagship",scale=1.5,laser=JS.odict({from=1,every=7},{"from","every"}),hp=8500,spd=3.2,dmg=30,xp=0,cr=0,boss=true,keep=30,ship=true,shoot=JS.odict({cd=3.2,spd=15,dmg=11,ring=20,aim=5},{"cd","spd","dmg","ring","aim"})},{"name","model","scale","laser","hp","spd","dmg","xp","cr","boss","keep","ship","shoot"})},{"crawler","grunt","inter","heavy","brute","sniper","guard","splitter","bomber","phantom","ore","hive","gunship_boss","brute_king","flagship_boss"});
S.UPG = JS.odict({main=JS.odict({kind="weapon",name="主武器强化",max=6,desc=smt({[0]="","伤害 +20%，射速 +6%","弹道 +1","伤害 +20%，射速 +6%","弹道 +1","伤害 +30%，射速 +10%",length=6},AMT)},{"kind","name","max","desc"}),hull=JS.odict({kind="passive",name="耐久强化",max=5,desc=smt({[0]="耐久上限 +20%，并修复 25%",length=1},AMT)},{"kind","name","max","desc"}),engine=JS.odict({kind="passive",name="引擎超频",max=5,desc=smt({[0]="移动速度 +8%",length=1},AMT)},{"kind","name","max","desc"}),magnet=JS.odict({kind="passive",name="引力收集器",max=5,desc=smt({[0]="拾取范围 +35%",length=1},AMT)},{"kind","name","max","desc"}),power=JS.odict({kind="passive",name="火控核心",max=5,desc=smt({[0]="所有伤害 +10%",length=1},AMT)},{"kind","name","max","desc"}),cooling=JS.odict({kind="passive",name="冷却回路",max=5,desc=smt({[0]="所有冷却 -7%（含机甲技能）",length=1},AMT)},{"kind","name","max","desc"}),repair=JS.odict({kind="passive",name="纳米修复",max=5,desc=smt({[0]="每秒修复耐久 +0.6",length=1},AMT)},{"kind","name","max","desc"}),support=JS.odict({kind="crew",name="驾驶员支援",max=5,desc=smt({[0]="","支援技能伤害 +35%，冷却 -10%","支援技能伤害 +35%，冷却 -10%","支援技能伤害 +35%，冷却 -10%","觉醒：支援技能数量翻倍",length=5},AMT)},{"kind","name","max","desc"})},{"main","hull","engine","magnet","power","cooling","repair","support"});
S.NODE_INFO = JS.odict({pirate=JS.odict({name="海贼据点",color="#E0458C",hint="靠近后清剿全部海贼（中途会有增援），打开战利品",goal="清剿海贼据点"},{"name","color","hint","goal"}),derelict=JS.odict({name="遗弃残骸",color="#F5A524",hint="停留在光圈内搜刮，会引来两波虫群",goal="搜刮遗弃残骸"},{"name","color","hint","goal"}),ore=JS.odict({name="富矿带",color="#F2B33D",hint="击碎全部矿石，小心护矿虫群",goal="开采富矿带"},{"name","color","hint","goal"}),hunt=JS.odict({name="限时猎杀",color="#FF8A3A",hint="靠近后 40 秒内击败足够多的敌人，奖励战利品",goal="限时猎杀"},{"name","color","hint","goal"}),ambush=JS.odict({name="精英伏击",color="#B47CFF",hint="连续 3 波伏击，波次间不会补血",goal="击退伏击"},{"name","color","hint","goal"}),distress=JS.odict({name="求救信号",color="#5CF2DC",hint="守住逃生舱 20 秒，奖励星源",goal="营救逃生舱"},{"name","color","hint","goal"}),merchant=JS.odict({name="流浪商人",color="#7CF29A",hint="靠近交易，用本局信用点购买强化",goal=""},{"name","color","hint","goal"}),nest=JS.odict({name="晶簇巢穴",color="#B47CFF",hint="摧毁 3 个晶簇巢并击败巢穴守卫，获得碎片",goal="摧毁晶簇巢穴"},{"name","color","hint","goal"}),gate=JS.odict({name="星门",color="#9DF7EC",hint="飞进星门前往下一个星域",goal=""},{"name","color","hint","goal"}),safegate=JS.odict({name="稳航星门",color="#9DF7EC",hint="稳航：跃迁时额外修复 30% 耐久",tip="稳航 · 额外修复 30% 耐久",goal=""},{"name","color","hint","tip","goal"}),riskgate=JS.odict({name="险途星门",color="#FF5A6A",hint="险途：下个星域敌人更强、多 1 只精英，完成后必掉宝箱",tip="险途 · 敌人更强 · 必掉宝箱",goal=""},{"name","color","hint","tip","goal"})},{"pirate","derelict","ore","hunt","ambush","distress","merchant","nest","gate","safegate","riskgate"});
S.R = nil; S.keys = JS.dict(); S.joy = JS.odict({id=nil,cx=0,cy=0,dx=0,dy=0},{"id","cx","cy","dx","dy"}); S.look = JS.odict({id=nil,x=0,y=0,idle=0},{"id","x","y","idle"}); S.paused = false; S.stars = nil; S.lastVP = nil; S.hud = JS.dict();
S.camBasis = JS.odict({f=smt({[0]=0,0,1,length=3},AMT),r=smt({[0]=1,0,0,length=3},AMT),u=smt({[0]=0,1,0,length=3},AMT),eye=smt({[0]=0,0,0,length=3},AMT)},{"f","r","u","eye"});
S.BATTLE_SET = smt({[0]={k="lvMode",n="升级选卡",d="now",o=smt({[0]=smt({[0]="now","立即弹出",length=2},AMT),smt({[0]="later","稍后选择",length=2},AMT),smt({[0]="auto","自动选择",length=2},AMT),length=3},AMT)},{k="nums",n="伤害数字",d=true,o=smt({[0]=smt({[0]=true,"显示",length=2},AMT),smt({[0]=false,"隐藏",length=2},AMT),length=2},AMT)},{k="autoCam",n="闲置时镜头转向目标",d=true,o=smt({[0]=smt({[0]=true,"开",length=2},AMT),smt({[0]=false,"关",length=2},AMT),length=2},AMT)},{k="sens",n="视角灵敏度",d="mid",o=smt({[0]=smt({[0]="low","低",length=2},AMT),smt({[0]="mid","中",length=2},AMT),smt({[0]="high","高",length=2},AMT),length=3},AMT)},{k="cam",n="战斗视角",d="chase",o=smt({[0]=smt({[0]="high","远景",length=2},AMT),smt({[0]="chase","标准",length=2},AMT),smt({[0]="mid","近景",length=2},AMT),length=3},AMT)},{k="subAuto",n="副武器自动发射",d=true,o=smt({[0]=smt({[0]=true,"开",length=2},AMT),smt({[0]=false,"关",length=2},AMT),length=2},AMT)},{k="music",n="背景音乐",d=true,o=smt({[0]=smt({[0]=true,"开",length=2},AMT),smt({[0]=false,"关",length=2},AMT),length=2},AMT)},{k="sound",n="音效",d=true,o=smt({[0]=smt({[0]=true,"开",length=2},AMT),smt({[0]=false,"关",length=2},AMT),length=2},AMT)},length=8},AMT);
S.CHAMP_NO = smt({[0]="crawler","bomber","splitter",length=3},AMT);
S.grid = JS.dict(); S.CELL = 8;
S.HOT = smt({[0]=1.7,1.55,1.3,length=3},AMT); S.EMBER = smt({[0]=1.5,0.75,0.25,length=3},AMT);
S.HEALC = smt({[0]=0.3,1.2,0.5,length=3},AMT);
S.C.RUN_MOD_MAX = 6;
S.CAMS = JS.odict({high=JS.odict({dist=22,h=6.5,fov=62},{"dist","h","fov"}),chase=JS.odict({dist=15,h=5,fov=64},{"dist","h","fov"}),mid=JS.odict({dist=12.5,h=4,fov=66},{"dist","h","fov"})},{"high","chase","mid"}); S.camPreset = "chase";
S.PIX = function(_this, rows, colors)
local pal, idx, px, B;
pal = smt({length=0},AMT); idx = JS.dict(); px = ""; B = "0123456789abcdefghijklmnopqrstuvwxyz";
rows:forEach(function(_this, r)
local i, c;
do
i = 0;
while (i < LEN(r)) do
do
c = r[i];
if (c == ".") then
px = (S2(px) .. ".");
goto cont102;
end;
if (not (idx[c] ~= nil)) then
idx[c] = LEN(pal);
pal:push(colors[c]);
end;
px = (px + B[idx[c]]);
end
::cont102::
i = i + 1;
end
end;
end);
do return {w=LEN(rows[0]),h=LEN(rows),pal=pal,px=px} end;
end;
S.ICON = JS.odict({missile=S.PIX(nil,smt({[0]="...aa...","..abba..","..abba..","..abba..","..abba..",".cabbac.",".c.dd.c.","...ee...",length=8},AMT),{a="#D6332A",b="#E8E3D6",c="#3E6E99",d="#FFB347",e="#FF7A3A"}),nova=S.PIX(nil,smt({[0]="..aaaa..",".a....a.","a..bb..a","a.bccb.a","a.bccb.a","a..bb..a",".a....a.","..aaaa..",length=8},AMT),{a="#57B8FF",b="#9DF7EC",c="#FFFFFF"}),blades=S.PIX(nil,smt({[0]="...a....","..ab....",".....aa.","a..c..ba","ab..c..a",".aa.....","....ba..","....a...",length=8},AMT),{a="#5CF2DC",b="#9DF7EC",c="#E0458C"}),hull=S.PIX(nil,smt({[0]=".aaaaaa.","abbbbbba","abccccba","abccccba","abccccba",".abccba.","..abba..","...aa...",length=8},AMT),{a="#3E5878",b="#7CF29A",c="#2E7A4A"}),engine=S.PIX(nil,smt({[0]="..aaaa..",".abbbba.",".abbbba.","..aaaa..","...cc...","..cddc..","..cddc..","...cc...",length=8},AMT),{a="#5A6175",b="#9AA3B5",c="#FF8A3A",d="#FFE7A3"}),magnet=S.PIX(nil,smt({[0]="aa....aa","aa....aa","bb....bb","bb....bb","bb....bb",".bb..bb.","..bbbb..","........",length=8},AMT),{a="#E8E3D6",b="#E0458C"}),power=S.PIX(nil,smt({[0]="....a...","...aa...","..aab...",".aabbbb.","....bba.","....ba..","...ba...","...a....",length=8},AMT),{a="#F5A524",b="#FFE7A3"}),cooling=S.PIX(nil,smt({[0]="...a....",".a.a.a..","..aaa...","aaabaaa.","..aaa...",".a.a.a..","...a....","........",length=8},AMT),{a="#57B8FF",b="#FFFFFF"}),repair=S.PIX(nil,smt({[0]="...aa...","...aa...",".aaaaaa.",".aaaaaa.","...aa...","...aa...","........","........",length=8},AMT),{a="#7CF29A"}),ammo=S.PIX(nil,smt({[0]="..aa....",".abba...",".abba.aa",".abbaabb",".abbaabb",".accaacc",".adda.dd","........",length=8},AMT),{a="#5A6175",b="#FF8A3A",c="#E8E3D6",d="#3E6E99"}),heal=S.PIX(nil,smt({[0]="..a..a..",".aaaaaa.",".aaaaaa.","..aaaa..","...aa...","........","........","........",length=8},AMT),{a="#FF6B8A"})},{"missile","nova","blades","hull","engine","magnet","power","cooling","repair","ammo","heal"});
S.C.ICON = S.ICON;
S.ui = function(_this)
do return HOST.document:getElementById("ui") end;
end;
S.lvDefer = false; S.lvManual = false;
HOST.window:addEventListener("keydown",function(_this, e)
if ((not T(S.A)) or (S.A:mode() ~= "cosmic-run")) then
do return end;
end;
S.keys[e.code] = true;
if (((e.code == "Space") or (e.code == "KeyJ")) and T(S.R)) then
e:preventDefault();
S.castActive(nil);
end;
if ((((e.code == "ShiftLeft") or (e.code == "ShiftRight")) or (e.code == "KeyK")) and T(S.R)) then
S.dodge(nil);
end;
if (((e.code == "KeyQ") or (e.code == "KeyL")) and T(S.R)) then
S.fireSub(nil,true);
end;
if (e.code:indexOf("Arrow") == 0) then
e:preventDefault();
S.look.idle = 0;
end;
if (((e.code == "Escape") and T(S.R)) and (not T(S.R.ended))) then
S.openPause(nil);
end;
end);
HOST.window:addEventListener("keyup",function(_this, e)
S.keys[e.code] = false;
end);
HOST.window:addEventListener("blur",function(_this)
S.keys = JS.dict();
S.joy.id = nil;
S.joy.dy = 0;
S.joy.dx = S.joy.dy;
S.look.id = nil;
end);
HOST.window.CosmicRun = {init=function(_this, api)
S.A = api;
S.bindPointer(nil);
end,start=function(_this, chapterId, opt)
S.camPreset = (function() local _t = (function() local _t = S.C.save.settings; if not T(_t) then return _t end; return S.C.save.settings.cam end)(); if T(_t) then return _t end; return "chase" end)();
S.A:setMode("cosmic-run");
S.newRun(nil,chapterId,opt);
S.paused = false;
S.buildHUD(nil);
if (not T(S.C.save.tutorialDone)) then
S.startTutorial(nil);
end;
S.C:sfx("warp");
S.C.music:play("battle");
end,frame=function(_this, dt)
if (not T(S.R)) then
do return end;
end;
S.step(nil,dt);
S.render(nil);
S.drawOverlay(nil);
if ((not T(S.R.ended)) and T(S.hud.top)) then
S.updateHUD(nil,dt);
end;
end,debug={orbit=function(_this, deg)
if T(S.R) then
S.R.dbgYaw = deg;
S.R.cx = nil;
end;
end,endRun=function(_this, w)
S.endRun(nil,(not (not T(w))),false);
end,hit=function(_this, i, e, dmg)
S.modHit(nil,S.R.mods[i],e,(T(dmg) and dmg or 20),S.P(nil),6);
end,camset=function(_this, o)
S.CAMS.custom = o;
S.camPreset = "custom";
if T(S.R) then
S.R.cx = nil;
end;
end,spawn=function(_this, type_, x, y, z)
do return S.spawnEnemy(nil,type_,x,y,z) end;
end,run=function(_this)
do return S.R end;
end,pose=function(_this)
do return (function() local _t = S.R; if not T(_t) then return _t end; return S.R.pose end)() end;
end,step=function(_this, n)
local i, c;
do
i = 0;
while (i < n) do
S.step(nil,(1 / 30));
c = HOST.document:querySelector(".sv-modal .sv-card:not(.cx-offer)");
if (T(S.paused) and T(c)) then
c:click();
end;
i = i + 1;
end
end;
end,move=function(_this, dx, dy)
S.joy.dx = dx;
S.joy.dy = dy;
end,look=function(_this, yaw, pitch)
if T(S.R) then
S.R.camYaw = yaw;
S.R.camPitch = pitch;
S.look.idle = 0;
end;
end,cast=S.castActive,dodge=S.dodge,god=function(_this, on)
if T(S.R) then
S.R.god = on;
end;
end,heal=function(_this)
if T(S.R) then
S.R.hull = S.hullMax(nil);
end;
end,clearEnemies=function(_this)
if T(S.R) then
;(S.R.enemies:slice()):forEach(function(_this, e)
S.hurtEnemy(nil,e,1e9,0,0,0,true);
end);
end;
end,oneHit=function(_this, on)
if (T(S.R) and ((not (not T(S.R.devOne))) ~= (not (not T(on))))) then
S.R.st.atk = (S.R.st.atk + (T(on) and 99 or (-99)));
S.R.devOne = (not (not T(on)));
end;
do return (function() if T(S.R) then return (not (not T(S.R.devOne))) else return false end end)() end;
end,addCredits=function(_this, n)
if T(S.R) then
S.R.credits = (S.R.credits + n);
end;
end,addSrc=function(_this, n)
if T(S.R) then
S.R.src = (S.R.src + n);
end;
end,levelUp=function(_this)
if T(S.R) then
S.R.pendingLevels = S.R.pendingLevels + 1;
end;
end,ammo=function(_this, n)
if (T(S.R) and T(S.R.sub)) then
S.R.sub.ammo = n;
end;
do return (function() if (T(S.R) and T(S.R.sub)) then return S.R.sub.ammo else return 0 end end)() end;
end,sub=function(_this)
if (T(S.R) and T(S.R.sub)) then
S.R.sub.cd = 0;
end;
do return S.fireSub(nil,true) end;
end,toGate=function(_this)
if T(S.R) then
if T(S.R.event) then
S.R.event.state = "done";
end;
S.R.secKills = (T(S.R.gateNeed) and S.R.gateNeed or 0);
S.R.px = S.R.gate.x;
S.R.py = S.R.gate.y;
S.R.pz = (S.R.gate.z - 25);
end;
end,sector=function(_this, k)
if T(S.R) then
S.loadSector(nil,k);
end;
end,cam=function(_this, k)
S.camPreset = k;
if T(S.R) then
S.R.cx = nil;
end;
end,dummy=function(_this, type_, x, y, z, hp, still)
local e;
e = S.spawnEnemy(nil,type_,x,y,z);
e.max = hp;
e.hp = e.max;
e.d = G.Object:assign(JS.dict(),e.d,{shoot=nil,dmg=0},(T(still) and {spd=0} or JS.dict()));
do return true end;
end,quiet=function(_this)
if T(S.R) then
S.R.enemies = smt({length=0},AMT);
S.R.gate.state = "open";
S.R.dmgDealt = 0;
S.R.px = 0;
S.R.py = 0;
S.R.pz = 0;
end;
end,occ=function(_this)
local m;
m = (T(S.R.occMax) and S.R.occMax or 0);
S.R.occMax = 0;
do return (Math_round((m * 1000)) / 10) end;
end,sphere=function(_this, r)
local V, v, n, back, bn, i, d, q, ok, a, b;
V = S.A:view(); v = 0; n = 0; back = 0; bn = 0;
do
i = 0;
while (i < 60) do
d = S.randDir(nil); q = S.E:project(S.lastVP,smt({[0]=(S.R.px + (d[0] * r)),(S.R.py + (d[1] * r)),(S.R.pz + (d[2] * r)),length=3},AMT),V.w,V.h); ok = ((((T(q) and (q[0] > 0)) and (q[0] < V.w)) and (q[1] > 0)) and (q[1] < V.h));
n = n + 1;
if T(ok) then
v = v + 1;
end;
if (S.dot(nil,d,S.camBasis.f) < (-0.3)) then
bn = bn + 1;
if T(ok) then
back = back + 1;
end;
end;
i = i + 1;
end
end;
a = S.E:project(S.lastVP,smt({[0]=S.R.px,(S.R.py - 2.4),S.R.pz,length=3},AMT),V.w,V.h); b = S.E:project(S.lastVP,smt({[0]=S.R.px,(S.R.py + 2.4),S.R.pz,length=3},AMT),V.w,V.h);
do return {all=Math_round(((v / n) * 100)),back=(function() if T(bn) then return Math_round(((back / bn) * 100)) else return 0 end end)(),mechPx=(function() if (T(a) and T(b)) then return Math_round((a[1] - b[1])) else return 0 end end)(),mechX=(function() if T(a) then return Math_round(((a[0] / V.w) * 100)) else return 0 end end)(),mechY=(function() if T(a) then return Math_round(((((a[1] + b[1]) / 2) / V.h) * 100)) else return 0 end end)()} end;
end,clear=function(_this)
if T(S.R) then
;(S.R.enemies:filter(function(_this, e)
do return ((not T(e.d.boss)) and (not T(e.d.ore))) end;
end)):forEach(function(_this, e)
e.hp = 0;
S.killEnemy(nil,e);
end);
end;
end,unpause=function(_this)
S.paused = false;
;(HOST.document:querySelectorAll(".sv-modal")):forEach(function(_this, m)
m:remove();
end);
end}};
end)();
return S
end
