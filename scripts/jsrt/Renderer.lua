-- Renderer.lua：E.render 的 UrhoX 后端。把网页版每帧生成的绘制列表（模型 + 4x4 矩阵 + 颜色替换）转成 UrhoX 节点：
-- 同一模型 / 同一颜色的节点放进对象池复用；矩阵分解为 位置 / 旋转 / 统一缩放；相机、灯光、辉光参数取自 f.env。
local VB = require("game.VoxelBuilder")
local R = { pools = {}, protos = {}, variants = {}, lastEnvSig = nil }
local sqrt = math.sqrt
local scene_, camNode_, camera_, drawRoot_, protoRoot_, zone_, starZone_, keyNode_, keyLight_, fillNode_, fillLight_, renderPath_
-- 星空节点：每份星点数据（战斗一份、召唤页一份）各建一次并缓存；本帧不用的隐藏（网页版 f.stars 为空时不画星空）
local starNodes_, starOn_ = setmetatable({}, { __mode = "k" }), nil
R.STAR_ZONE_MASK = 2
function R.Init(o)
    scene_, camNode_, camera_ = o.scene, o.camNode, o.camera
    zone_, keyNode_, keyLight_, fillNode_, fillLight_, renderPath_ = o.zone, o.keyNode, o.keyLight, o.fillNode, o.fillLight, o.renderPath
    starZone_ = o.starZone
    drawRoot_ = scene_:CreateChild("Draws"); protoRoot_ = scene_:CreateChild("DrawProtos")
end
local function quant(v) return math.floor(v * 8 + 0.5) end
local MAX_VARIANTS = 160
-- 颜色替换的量化：特效模型（fx_）亮度超过 1 的部分在 LDR 下只会被截掉，先按最大通道归一（保留色相），能少很多变体
local function tintQ(id, tint)
    local r, g, b = math.max(0, tint[0]), math.max(0, tint[1]), math.max(0, tint[2])
    if id:sub(1, 3) == "fx_" then local m = math.max(r, g, b); if m > 1 then r, g, b = r / m, g / m, b / m end end
    return quant(r), quant(g), quant(b)
end
local function keyOf(id, tint)
    if not tint then return id, 0, 0, 0 end
    local qr, qg, qb = tintQ(id, tint); return id .. "|" .. qr .. "," .. qg .. "," .. qb, qr, qg, qb
end
local function proto(id, tint)
    local key, qr, qg, qb = keyOf(id, tint)
    local p = R.protos[key]; if p ~= nil then return p or nil, key end
    if tint then
        local list = R.variants[id]; if not list then list = {}; R.variants[id] = list end
        if #list >= MAX_VARIANTS then
            -- v1.4.3：颜色变体太多时借用最接近的已有颜色（原来退回无色模型，玩几分钟后攻击特效全变成白色）
            local best, bd = nil, math.huge
            for _, v in ipairs(list) do local d = (v[1] - qr) ^ 2 + (v[2] - qg) ^ 2 + (v[3] - qb) ^ 2; if d < bd then bd, best = d, v end end
            p = R.protos[best[4]]; R.protos[key] = p; return p, key
        end
        local c = { (qr / 8) ^ (1 / 2.2), (qg / 8) ^ (1 / 2.2), (qb / 8) ^ (1 / 2.2) }   -- 网页版 tint 是线性值，转成与模型颜色相同的空间
        p = VB.Build(protoRoot_, id, "proto_" .. key, c); list[#list + 1] = { qr, qg, qb, key }
    else p = VB.Build(protoRoot_, id, "proto_" .. key) end
    p:SetDeepEnabled(false); R.protos[key] = p; return p, key
end
-- v1.4.9 特效重做：按绘制角色分别处理（角色由战斗模块写进绘制列表：thrust 推进器 / p 机甲攻击 / e 敌人攻击 / nova 冲击环 / fx 粒子 / gem 经验）。
-- 方案先在“UrhoX 观感预览”（网页引擎模拟 UrhoX 的 LDR + 叠加混合）里逐项对比调好，再一一搬到这里。
--  * 发光特效本体：叠加混合，亮度按角色分档，粒子 / 冲击环随寿命淡出（不再满亮度突然消失）。
--  * 细长弹道（子弹、激光、射线）：三层“横向粗、纵向只略长”的彩色光套，由内到外渐淡，不放大长度、不斜转（避免 v1.4.6 的十字形）。
--  * 敌人攻击：白芯改为暖粉色，光套偏红更亮，一眼可辨；预警线段（细）亮度减半。
--  * 推进器尾焰：本体缩到 0.8 倍、亮度降到 0.03~0.13，不加光晕。
local ADD_IDS = { fx_white = true, fx_white_bolt = true, fx_spark = true, fx_laser_player = true, fx_laser_enemy = true }
local ELONG = { fx_white_bolt = true, fx_laser_player = true, fx_laser_enemy = true }
local E_CORE = { [0] = 1.25, [1] = 0.5, [2] = 0.6 }
local LV = { 0.02, 0.035, 0.05, 0.065, 0.08, 0.1, 0.13, 0.16, 0.2, 0.25, 0.3, 0.36, 0.45, 0.55, 0.65, 0.75, 0.85 }
local function qk(k) local b = LV[1]; for i = 2, #LV do if math.abs(LV[i] - k) < math.abs(b - k) then b = LV[i] end end return b end
local HALO_MAX, GLOW_CAP = 140, 900
local QW, QX = 0.92388, 0.22095
R.glowK, R.glowN, R.glowL = {}, {}, {}
-- 叠加原型：同一颜色键（先经过 proto() 的变体上限）+ 同一亮度档共用；每个模型最多 GLOW_CAP 个，超出借用同色最接近的亮度档
local function glowProto(id, tint, k)
    local _, rk = proto(id, tint); local gk = "g" .. k .. "|" .. rk
    local p = R.protos[gk]; if p ~= nil then return p or nil, gk end
    if not VB.AddTechnique() then R.protos[gk] = false; return nil, gk end
    local byK = R.glowK[rk]; if not byK then byK = {}; R.glowK[rk] = byK end
    local qr, qg, qb = rk:match("|(%d+),(%d+),(%d+)$")
    local lk = id .. "@" .. k; local same = R.glowL[lk]; if not same then same = {}; R.glowL[lk] = same end
    if (R.glowN[id] or 0) >= GLOW_CAP then
        -- 超出上限：先找同颜色最接近的亮度档，再找同亮度档最接近的颜色；都没有才退回普通材质
        local best, bd = nil, 1e9; for kk in pairs(byK) do local dd = math.abs(kk - k); if dd < bd then bd, best = dd, kk end end
        if best and bd <= 0.08 then local k2 = "g" .. best .. "|" .. rk; R.protos[gk] = R.protos[k2]; return R.protos[k2], k2 end
        if qr and #same > 0 then
            local b2, d2 = nil, 1e9; for _, v in ipairs(same) do local dd = (v[1] - qr) ^ 2 + (v[2] - qg) ^ 2 + (v[3] - qb) ^ 2; if dd < d2 then d2, b2 = dd, v[4] end end
            if b2 then R.protos[gk] = R.protos[b2]; return R.protos[b2], b2 end
        end
        if best then local k2 = "g" .. best .. "|" .. rk; R.protos[gk] = R.protos[k2]; return R.protos[k2], k2 end
        R.protos[gk] = false; return nil, gk
    end
    R.glowN[id] = (R.glowN[id] or 0) + 1
    local c = nil
    if qr then qr, qg, qb = tonumber(qr), tonumber(qg), tonumber(qb); c = { (qr / 8) ^ (1 / 2.2), (qg / 8) ^ (1 / 2.2), (qb / 8) ^ (1 / 2.2) } end
    p = VB.Build(protoRoot_, id, "proto_" .. gk, c, { halo = k }); p:SetDeepEnabled(false); R.protos[gk] = p; byK[k] = p
    if qr then same[#same + 1] = { qr, qg, qb, gk } end
    return p, gk
end
-- 规则：返回 本体亮度、本体缩放、实际颜色、光套数量（光套写进 HB，避免每帧新建表）
local HB = {}
local function setH(i, k, x, y, z, rot) local h = HB[i]; if not h then h = {}; HB[i] = h end; h.k, h.x, h.y, h.z, h.rot = qk(k), x, y, z, rot end
local function fxRule(id, d)
    local role, a, tint, s = d.role, d.a or 1, d.tint, d.s or 0
    if role == "e" and not tint then tint = E_CORE end
    if role == "emz" then local f = a > 0.6 and 1 or a > 0.35 and 0.7 or a > 0.15 and 0.45 or 0.25; return qk(0.3 * f), 1, tint, 0 end
    if role == "e" and not ELONG[id] then return qk(0.45 * (s > 6 and 0.8 or 1)), 1, tint, 0 end
    if role == "thrust" then return qk(tint and (0.03 + 0.07 * a) or 0.13), 0.8, tint, 0 end
    local fade = 1
    if role == "fx" then fade = a > 0.6 and 1 or a > 0.35 and 0.7 or a > 0.15 and 0.45 or 0.25
    elseif role == "nova" then fade = a > 0.6 and 1 or a > 0.3 and 0.65 or 0.35 end
    local thin = ELONG[id] and s <= 2.4
    local k = role == "e" and (thin and 0.35 or 0.55) or role == "nova" and 0.55 or 0.7
    if s > 6 then k = math.min(k, 0.45) end
    local n = 0
    if ELONG[id] then
        local e, g = role == "e", thin and 0.5 or 1
        n = n + 1; setH(n, (e and 0.2 or 0.16) * g, 1.7, 1.7, 1.06, false)
        n = n + 1; setH(n, (e and 0.1 or 0.08) * g, 2.5, 2.5, 1.12, false)
        if not thin then n = n + 1; setH(n, e and 0.045 or 0.035, 3.4, 3.4, 1.2, false) end
    elseif (id == "fx_white" or id == "fx_spark") and s <= 4 and role ~= "nova" then
        n = n + 1; setH(n, 0.12 * fade, 1.9, 1.9, 1.9, true)
        if fade >= 0.7 then n = n + 1; setH(n, 0.05 * fade, 2.8, 2.8, 2.8, true) end
    elseif s > 6 then
        n = n + 1; setH(n, 0.1, 1.5, 1.5, 1.5, false); n = n + 1; setH(n, 0.04, 2.1, 2.1, 2.1, false)
    end
    return qk(k * fade), 1, tint, n
end
R._fxRule, R._HB = fxRule, HB                                                     -- 供无头测试对照网页预览规则
-- v1.5.0 柔光贴片：方块光套在 UrhoX 里边缘太硬（真机反馈“奇怪”）。改用 BillboardSet + 径向渐变贴图（assets/Textures/fx_glow.png）叠加：
-- 圆形柔光（始终面向镜头）给粒子 / 小方块，细长柔光（沿弹道方向拉长）给子弹 / 激光；弹道本体横向变细到 0.75。
-- 方案同样先在预览页逐项对比（tools/fx_preview/rules.js 的 rules.v150），这里一一对应。任何一步失败都自动退回 v1.4.9 的方块光套。
local MODEL_COL = { fx_white = { 1, 1, 1 }, fx_white_bolt = { 1, 1, 1 }, fx_spark = { 1, 0.702, 0.2784 }, fx_laser_player = { 0.3608, 0.949, 0.8627 }, fx_laser_enemy = { 1, 0.302, 0.4157 } }
local colCache = {}
local function fxColor(id, tint)
    local key = tint and keyOf(id, tint) or id; local c = colCache[key]; if c then return c end
    local r, g, b
    if tint then local qr, qg, qb = tintQ(id, tint); r, g, b = (qr / 8) ^ (1 / 2.2), (qg / 8) ^ (1 / 2.2), (qb / 8) ^ (1 / 2.2)
    else local m = MODEL_COL[id] or { 1, 1, 1 }; r, g, b = m[1], m[2], m[3] end
    local mx = math.max(r, g, b, 1e-4); r, g, b = r / mx, g / mx, b / mx
    local l = 0.2126 * r + 0.7152 * g + 0.0722 * b
    c = { math.max(0, math.min(1, l + (r - l) * 1.35)), math.max(0, math.min(1, l + (g - l) * 1.35)), math.max(0, math.min(1, l + (b - l) * 1.35)) }
    colCache[key] = c; return c
end
R._fxColor = fxColor
local SB, sbN = {}, 0
local function addS(dir, w, l, k, c, m)
    sbN = sbN + 1; local q = SB[sbN]; if not q then q = {}; SB[sbN] = q end
    k = qk(k); q.dir, q.w, q.l, q.r, q.g, q.b = dir, w, l, c[1] * k, c[2] * k, c[3] * k
    if dir then q.dx, q.dy, q.dz = m[8], m[9], m[10] end
end
-- 返回 本体亮度、本体缩放（x/y 与 z 分开）、实际颜色；柔光写进 SB（位置由调用方补上）
local function fxRuleSpr(id, d, m)
    local role, a, tint, s = d.role, d.a or 1, d.tint, d.s or 0
    if role == "e" and not tint then tint = E_CORE end
    local c = fxColor(id, tint); local e = role == "e"
    if role == "emz" then                                                                       -- v1.5.3：敌人枪口火花：暗、无柔光
        local f = a > 0.6 and 1 or a > 0.35 and 0.7 or a > 0.15 and 0.45 or 0.25
        return qk(0.3 * f), 1, 1, tint, 0
    end
    if e and not ELONG[id] then return qk(0.45 * (s > 6 and 0.8 or 1)), 1, 1, tint, 0 end          -- v1.5.3：敌人蓄力环 / 砸地环的光点降亮、无柔光
    if role == "thrust" then
        if not tint then addS(false, 0.1 * s * 3, 0, 0.1, c, m) end                                  -- v1.5.4：4.5 -> 3 倍
        return qk(tint and (0.03 + 0.07 * a) or 0.13), 0.8, 0.8, tint, 0
    end
    local fade = 1
    if role == "fx" then fade = a > 0.6 and 1 or a > 0.35 and 0.7 or a > 0.15 and 0.45 or 0.25
    elseif role == "nova" then fade = a > 0.6 and 1 or a > 0.3 and 0.65 or 0.35 end
    local thin = ELONG[id] and s <= 2.4
    local k = e and (thin and 0.35 or 0.55) or role == "nova" and 0.55 or 0.7                  -- v1.5.2：本体整体降亮，不刺眼
    if s > 6 then k = math.min(k, 0.45) end
    if ELONG[id] then
        -- v1.5.5：真机上“沿方向”广告牌（FC_DIRECTION）朝向不对，激光两侧变成一排排竖条；改为细本体 + 一层贴身光套，方向跟模型矩阵走，一定对齐
        setH(1, (e and 0.1 or 0.08) * (thin and 0.5 or 1), 1.7, 1.7, 1.04, false)
        return qk(k * fade), 0.8, 1, tint, 1
    elseif (id == "fx_white" or id == "fx_spark") and s <= 4 and role ~= "nova" and not e then addS(false, 0.1 * s * 3.5, 0, 0.4 * fade, c, m)   -- v1.5.4：5 -> 3.5 倍
    elseif s > 6 then addS(false, 0.1 * s * 2.2, 0, 0.25, c, m) end                                                                          -- v1.5.4：3 -> 2.2 倍
    return qk(k * fade), 1, 1, tint, 0
end
R._fxRuleSpr = function(id, d, m) sbN = 0; local k, sxy, sz, t, hn = fxRuleSpr(id, d, m); return k, sxy, sz, t, sbN, SB, hn or 0, HB end
-- 柔光贴片的引擎对象：两个 BillboardSet（圆形 / 沿方向），叠加混合 + 顶点色；建不起来就退回方块光套
local SPR_CAP, SPR_HALF = 400, 0.5                                                -- SPR_HALF：Billboard.size 是半边长
local spr = nil
local function initSprites()
    if spr ~= nil then return spr end
    spr = false
    local ok = pcall(function()
        if FC_ROTATE_XYZ == nil then error("no face mode") end
        local tex = cache:GetResource("Texture2D", "Textures/fx_glow.png"); if not tex then error("no texture") end
        local texL = cache:GetResource("Texture2D", "Textures/fx_glow_line.png") or tex
        local tech = nil
        for _, n in ipairs({ "Techniques/DiffVColAdd.xml", "Techniques/DiffVColAddAlpha.xml" }) do tech = cache:GetResource("Technique", n); if tech then break end end
        if not tech then error("no technique") end
        local mat = Material:new(); mat:SetTechnique(0, tech); mat:SetTexture(TU_DIFFUSE, tex)
        local matL = Material:new(); matL:SetTechnique(0, tech); matL:SetTexture(TU_DIFFUSE, texL)
        local node = scene_:CreateChild("FxGlow")
        local function mk(mode, mt)
            local bs = node:CreateComponent("BillboardSet"); bs.numBillboards = SPR_CAP; bs.material = mt; bs.relative = false; bs.sorted = false
            bs.faceCameraMode = mode; bs.castShadows = false
            for i = 0, SPR_CAP - 1 do bs:GetBillboard(i).enabled = false end
            bs:Commit(); return { bs = bs, on = 0 }
        end
        spr = { round = mk(FC_ROTATE_XYZ, mat) }                                    -- v1.5.5：不再使用 FC_DIRECTION
    end)
    if not ok then spr = false end
    return spr
end
local function flushSprites(list, n)
    local used = { round = 0, dir = 0 }
    for i = 1, n do
        local q = list[i]; local set = q.dir and spr.dir or spr.round; local j = used[q.dir and "dir" or "round"]
        if set and j < SPR_CAP then
            local bb = set.bs:GetBillboard(j)
            bb.position = Vector3(q.x, q.y, q.z); bb.color = Color(q.r, q.g, q.b, 1); bb.rotation = 0; bb.enabled = true
            if q.dir then
                local dl = sqrt(q.dx * q.dx + q.dy * q.dy + q.dz * q.dz); if dl < 1e-6 then dl = 1 end
                bb.direction = Vector3(q.dx / dl, q.dy / dl, q.dz / dl); bb.size = Vector2(q.w * SPR_HALF, q.l * SPR_HALF)
            else bb.size = Vector2(q.w * SPR_HALF, q.w * SPR_HALF) end
            used[q.dir and "dir" or "round"] = j + 1
        end
    end
    for _, key in ipairs({ "round", "dir" }) do
        local set = spr[key]
        if set then
            for j = used[key], set.on - 1 do set.bs:GetBillboard(j).enabled = false end
            if used[key] > 0 or set.on > 0 then set.bs:Commit() end
            set.on = used[key]
        end
    end
end
local FL, flN = {}, 0                                                            -- 本帧要画的柔光（带位置）
local function acquireKey(p, key)
    local pool = R.pools[key]; if not pool then pool = { list = {}, n = 0, on = 0 }; R.pools[key] = pool end
    pool.n = pool.n + 1
    local node = pool.list[pool.n]
    if not node then node = p:Clone(); node:SetParent(drawRoot_); pool.list[pool.n] = node end
    node:SetDeepEnabled(true)
    return node
end
local function acquire(id, tint)
    local p, key = proto(id, tint)
    if not p then if tint then return acquire(id, nil) end return nil end
    local pool = R.pools[key]; if not pool then pool = { list = {}, n = 0, on = 0 }; R.pools[key] = pool end
    pool.n = pool.n + 1
    local node = pool.list[pool.n]
    if not node then node = p:Clone(); node:SetParent(drawRoot_); pool.list[pool.n] = node end
    node:SetDeepEnabled(true)
    return node
end
local function quat(m, sx)
    local r00, r10, r20, r01, r11, r21, r02, r12, r22 = m[0] / sx, m[1] / sx, m[2] / sx, m[4] / sx, m[5] / sx, m[6] / sx, m[8] / sx, m[9] / sx, m[10] / sx
    local tr = r00 + r11 + r22; local w, x, y, z
    if tr > 0 then local s = sqrt(tr + 1) * 2; w = 0.25 * s; x = (r21 - r12) / s; y = (r02 - r20) / s; z = (r10 - r01) / s
    elseif r00 > r11 and r00 > r22 then local s = sqrt(1 + r00 - r11 - r22) * 2; w = (r21 - r12) / s; x = 0.25 * s; y = (r01 + r10) / s; z = (r02 + r20) / s
    elseif r11 > r22 then local s = sqrt(1 + r11 - r00 - r22) * 2; w = (r02 - r20) / s; x = (r01 + r10) / s; y = 0.25 * s; z = (r12 + r21) / s
    else local s = sqrt(1 + r22 - r00 - r11) * 2; w = (r10 - r01) / s; x = (r02 + r20) / s; y = (r12 + r21) / s; z = 0.25 * s end
    return w, x, y, z
end
function R.Env(env)
    local sig = tostring(env.bg[0]) .. tostring(env.ambient[0]) .. tostring(env.key.brightness) .. tostring(env.bloom and env.bloom.mix) .. tostring(R.glow) .. tostring(env.fog[0])
    if sig == R.lastEnvSig then return end
    R.lastEnvSig = sig
    -- v1.4.4 颜色校正：环境光 x0.85、主光 x1.15，拉开明暗层次（原来整体偏灰、发平）
    zone_.ambientColor = Color(env.ambient[0] * 0.85, env.ambient[1] * 0.85, env.ambient[2] * 0.85); zone_.fogColor = Color(env.bg[0], env.bg[1], env.bg[2])
    if starZone_ then starZone_.ambientColor = zone_.ambientColor; starZone_.fogColor = Color(env.bg[0], env.bg[1], env.bg[2]) end
    keyNode_.direction = Vector3(env.key.dir[0], env.key.dir[1], env.key.dir[2]):Normalized(); keyLight_.color = Color(env.key.color[0], env.key.color[1], env.key.color[2]); keyLight_.brightness = env.key.brightness * 1.15
    fillNode_.direction = Vector3(env.fill.dir[0], env.fill.dir[1], env.fill.dir[2]):Normalized(); fillLight_.color = Color(env.fill.color[0], env.fill.color[1], env.fill.color[2]); fillLight_.brightness = env.fill.brightness
    -- 雾：网页版是 mix(col, bg, f*f)，f 从 fog[0] 到 fog[1] 线性增长；UrhoX 雾是线性混合，起点后移 25% 来近似二次曲线
    zone_.fogStart = env.fog[0] + (env.fog[1] - env.fog[0]) * 0.25; zone_.fogEnd = env.fog[1]
    -- 辉光：网页版在线性空间用 smoothstep(thr, thr + 1.2, 最大通道) 取亮部；UrhoX 的 Bloom 在 gamma 空间硬阈值，所以把阈值换算到 gamma 空间（thr^(1/2.2)）
    local thr = math.min(0.9, env.bloom.threshold ^ (1 / 2.2) * 0.94); local mix = math.min(0.5, env.bloom.mix * 0.6) * (R.glow or 1)   -- v1.5.4：辉光强度封顶 0.5（机库场景原来可到 0.7，亮边外晕太大）
    renderPath_:SetShaderParameter("BloomThreshold", Variant(thr)); renderPath_:SetShaderParameter("BloomMix", Variant(Vector2(1.0, mix)))
end
-- E.backend：f = { env, eye, target, fov, aspect, near, far, draws, stars }
function R.Stats() local n, d = 0, 0; for _, p in pairs(R.pools) do n = n + #p.list; d = d + p.n end return n, d end
function R.Frame(f, VP)
    R.Env(f.env)
    camNode_.position = Vector3(f.eye[0], f.eye[1], f.eye[2]); camNode_:LookAt(Vector3(f.target[0], f.target[1], f.target[2])); camera_.fov = f.fov
    -- 星空：以相机为中心（网页版：星点不受雾影响，见 VoxelBuilder.BuildStars 与 GameApp 的无雾星空区域）
    local sn = nil
    if f.stars then
        sn = starNodes_[f.stars]
        if not sn then
            local st = f.stars.stars; local d = {}; for i = 0, st.data.length - 1 do d[#d + 1] = st.data[i] end
            local cols = {}; for i = 0, st.colors.length - 1 do local c = st.colors[i]; cols[#cols + 1] = { c[0], c[1], c[2] } end
            sn = VB.BuildStars(scene_, { data = d, colors = cols, zoneMask = starZone_ and R.STAR_ZONE_MASK or nil }); starNodes_[f.stars] = sn
            sn:SetEnabled(false)
        end
        sn.position = Vector3(f.eye[0], f.eye[1], f.eye[2])
    end
    if starOn_ ~= sn then
        if starOn_ then starOn_:SetEnabled(false) end
        if sn then sn:SetEnabled(true) end
        starOn_ = sn
    end
    for _, p in pairs(R.pools) do p.n = 0 end
    local halos, haloOn, addOn = 0, (R.glow or 1) >= 0.8 and R.halo ~= false, R.softFx ~= false
    local useSpr = addOn and R.sprites ~= false and initSprites() and true or false
    flN = 0
    local draws = f.draws
    for i = 0, draws.length - 1 do
        local d = draws[i]; local m = d.m.d or d.m
        local sx = sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2])
        local skip = addOn and d.mesh and ((d.mesh.id == "fx_white" and (d.kind or 0) == 1)          -- v1.5.2：激光 / 敌弹上的白色光点与起点闪光都不画
            or ((d.role == "etrail" or d.role == "ptrail") and ADD_IDS[d.mesh.id]))                     -- v1.5.3：敌弹 / 我方激光的拖尾粒子（沿途闪烁的白热亮点）不画
        if sx > 1e-6 and d.mesh and not skip then
            local id = d.mesh.id; local node, cxy, cz, tint, hn = nil, 1, 1, d.tint, 0
            if addOn and ADD_IDS[id] then
                local k
                if useSpr then sbN = 0; k, cxy, cz, tint, hn = fxRuleSpr(id, d, m)
                else local csc; k, csc, tint, hn = fxRule(id, d); cxy, cz = csc, csc end
                local gp, gk = glowProto(id, tint, k); if gp then node = acquireKey(gp, gk) end
                if node and useSpr and haloOn then
                    for j = 1, sbN do
                        local q = SB[j]; flN = flN + 1; local o = FL[flN]; if not o then o = {}; FL[flN] = o end
                        o.x, o.y, o.z, o.dir, o.w, o.l, o.r, o.g, o.b, o.dx, o.dy, o.dz = m[12], m[13], m[14], q.dir, q.w, q.l, q.r, q.g, q.b, q.dx, q.dy, q.dz
                    end
                end
            end
            if not node then
                local tt = d.tint; if tt and id:find("__", 1, true) then tt = nil end      -- v1.5.5：机甲部件不做受击染色（原来整台变粉）
                node = acquire(id, tt); cxy, cz, hn = 1, 1, 0
            end
            if node then
                local px, py, pz = m[12], m[13], m[14]; local w, x, y, z = quat(m, sx)
                node.position = Vector3(px, py, pz); node.rotation = Quaternion(w, x, y, z)
                if cxy == cz then node:SetScale(sx * cxy) else node:SetScale(Vector3(sx * cxy, sx * cxy, sx * cz)) end
                if haloOn then                                                          -- 退回路径的光套 / v1.5.5 细长弹道的贴身光套
                    for j = 1, hn do
                        if halos >= HALO_MAX then break end
                        local h = HB[j]; local hp, hk = glowProto(id, tint, h.k)
                        if hp then
                            halos = halos + 1; local n2 = acquireKey(hp, hk); n2.position = Vector3(px, py, pz)
                            if h.rot then n2.rotation = Quaternion(w * QW - (x + y + z) * QX, w * QX + x * QW + (y - z) * QX, w * QX + y * QW + (z - x) * QX, w * QX + z * QW + (x - y) * QX)
                            else n2.rotation = Quaternion(w, x, y, z) end
                            n2:SetScale(Vector3(sx * h.x, sx * h.y, sx * h.z))
                        end
                    end
                end
            end
        end
    end
    if spr then
        local ok = pcall(flushSprites, FL, useSpr and haloOn and flN or 0)
        if not ok then R.sprites = false end                                       -- 贴片更新出错：之后都退回方块光套
    end
    for _, p in pairs(R.pools) do
        for i = p.n + 1, p.on do p.list[i]:SetEnabled(false) end
        p.on = p.n
    end
end
return R
