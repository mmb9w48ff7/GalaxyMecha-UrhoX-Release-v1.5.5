-- GameUI.lua：战斗界面（HUD + 弹窗 + 触控输入），对应网页版 cosmic_run.js 里用 DOM 实现的 buildHUD / updateHUD / openLevelUp /
-- openShop / openPause / openRevive / endRun 弹窗 / startTutorial / bindPointer。游戏逻辑仍由转换后的网页版代码执行，这里只负责显示与点击。
local U = require("cosmic.Util")
local UI = require("cosmic.UI")
local GameUI = { toast = nil, t = 0 }
local S, C, HOST
local COL = UI.COL
local ORANGE_ = { 200, 130, 20 }
local u = {}                                  -- 界面状态：levelup / shop / pause / revive / tut
local AD_REFRESH = 3                          -- 升级刷新：每局免费 2 次，之后看广告最多再刷新 3 次（18 版网页）
GameUI.state = u
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function R() return S.R end
local function hexRGB(c) if type(c) ~= "string" or #c < 7 then return { 255, 138, 58 } end return { tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16) } end
function GameUI.Toast(msg) GameUI.toast = { text = msg, t = 2.6 } end

-- ---------------------------------------------------------------- 覆盖网页版的 DOM 函数
function GameUI.Install(mod, cosmic, host)
    S, C, HOST = mod, cosmic, host
    host.onToast = GameUI.Toast
    S.buildHUD = function() end
    S.updateHUD = function() end
    S.bindPointer = function() end
    local function finishLevel()
        u.levelup = nil; S.paused = false; S:afterChoice()
        local r = R(); r.gems:forEach(function(_, g) if S:dd(g, S:P()) < 2025 then g.pull = true end end)
    end
    GameUI.finishLevel = finishLevel
    -- 升级选卡模式（设置里可选）：now 立即弹出 / later 稍后选择（默认：战斗不中断，HUD 上有“升级 xN”按钮）/ auto 自动选择
    local PRI = { hull = 45, power = 44, cooling = 43, engine = 40, magnet = 38, repair = 36 }
    local function autoScore(id, r)
        if id:sub(1, 3) == "evo" then return 100 elseif id:sub(1, 3) == "mod" then return 80 elseif id == "main" then return 70 elseif id:sub(1, 3) == "new" then return 60
        elseif id == "support" then return 50 elseif id == "heal" then return (r.hull < S:hullMax() * 0.5) and 90 or 10
        elseif id == "ammo" then return (r.sub and r.sub.ammo < 6) and 85 or 35 end
        return PRI[id] or 30
    end
    function GameUI.LevelMode() return S:levelMode() end                      -- 21 版：默认“立即弹出”；新手第一次升级与宝箱升级强制弹出
    S.openLevelUp = function()
        local r = R(); local mode = GameUI.LevelMode(); local forced = S:lvForced()
        if u.defer and not forced then return end                               -- 已选择“稍后”：不再自动弹出，等玩家点 HUD 上的按钮（宝箱 / 新手第一次除外）
        if mode == "auto" then                                                  -- 自动选择：按优先级（进化 > 升级已有卡牌 > 主武器 > 新技能 > 驾驶员 > 被动 > 回复）
            r.pendingLevels = r.pendingLevels - 1; C:sfx("level"); r.rr = r.rr or { free = 2, ad = 0 }
            local ids = S:choices(); local best, bs = ids[0], -1
            for i = 0, ids.length - 1 do local sc = autoScore(ids[i], r); if sc > bs then best, bs = ids[i], sc end end
            local nm = S:choiceInfo(best).name; S:applyChoice(best); S:afterChoice(); GameUI.Toast("自动升级：" .. nm)
            r.gems:forEach(function(_, g2) if S:dd(g2, S:P()) < 2025 then g2.pull = true end end); return
        end
        if mode == "later" and not u.manual then u.defer = true; return end    -- 稍后：先记着，战斗继续
        u.manual = nil; if forced then u.defer = nil end
        S.paused = true; r.pendingLevels = r.pendingLevels - 1; C:sfx("level"); r.rr = r.rr or { free = 2, ad = 0 }
        u.levelup = { ids = S:choices(), forced = forced }
    end
    -- 弹窗里点“稍后选择”：把这次升级放回待选，战斗继续
    function GameUI.DeferLevel() local r = R(); r.pendingLevels = r.pendingLevels + 1; u.levelup = nil; S.paused = false; u.defer = true; GameUI.Toast("升级已保留，点屏幕左侧的“升级”按钮随时选择") end
    function GameUI.OpenPendingLevel() u.defer = nil; u.manual = true end
    S.openShop = function(_, n)
        S.paused = true; local r = R()
        local offers = {
            { name = "紧急维修", text = "修复 50% 耐久", cost = math.floor(150 + 0.5), go = function() r.hull = math.min(S:hullMax(), r.hull + S:hullMax() * 0.5) end },
            { name = "强化芯片", text = "立即升级 1 次", cost = 260, go = function() r.pendingLevels = r.pendingLevels + 1 end },
            { name = "星魂结晶", text = "驾驶员碎片 +5", cost = 400, go = function() r.frags[r.pilot] = (r.frags[r.pilot] or 0) + 5 end },
        }
        u.shop = { offers = offers }
    end
    S.openPause = function()
        if S.paused or not R() then return end
        S.paused = true; u.pause = true
    end
    S.openRevive = function()
        if R().ended then return end
        S.paused = true; u.revive = true
    end
    -- 新手引导：21 版起由转换后的战斗代码（startTutorial）驱动，状态在 r.tutUI，这里只负责显示
end
function GameUI.Reset() u.levelup, u.shop, u.pause, u.revive, u.tut, u.defer, u.manual, u.pset = nil, nil, nil, nil, nil, nil, nil, nil; GameUI.ResetFx() end

-- ---------------------------------------------------------------- 画面遮罩：进入星门的跃迁 / 受击闪光（网页版 #warp / #hitflash）
-- 战斗代码（由网页版转换）照旧调用 document.getElementById('warp').classList.add('on') / hitflash.style.opacity = 0.4，
-- 这里的元素只记录状态；GameUI.Update 按网页版 CSS 的过渡时间做淡入淡出，GameUI.DrawFx 用 NanoVG 径向渐变画出来。
local FX = {
    warp = { on = false, op = 0, a = 0, from = 0, to = 0, t = 1, dur = 0.28 },      -- #warp { transition: opacity .28s ease }
    hitflash = { on = false, op = 0, a = 0, from = 0, to = 0, t = 1, dur = 0.12 },  -- #hitflash { transition: opacity .12s }
}
GameUI.FX = FX
local fxEls = {}
function GameUI.FxEl(id)
    local st = FX[id]; if not st then return nil end
    local e = fxEls[id]; if e then return e end
    local DOM = require("jsrt.Host").DOM
    local cls = {
        add = function(_, c) if c == "on" then st.on = true end end,
        remove = function(_, c) if c == "on" then st.on = false end end,
        toggle = function(_, c, force) if c == "on" then if force == nil then st.on = not st.on else st.on = force and true or false end end return st.on end,
        contains = function(_, c) return c == "on" and st.on end,
    }
    local style = setmetatable({}, { __index = function(_, k) if k == "opacity" then return st.op end return nil end,
        __newindex = function(_, k, v) if k == "opacity" then st.op = tonumber(v) or 0 end end })
    e = setmetatable({ classList = cls, style = style }, { __index = function() return DOM end, __newindex = function() end })
    fxEls[id] = e; return e
end
function GameUI.ResetFx() for _, st in pairs(FX) do st.on = false; st.op = 0; st.a = 0; st.from = 0; st.to = 0; st.t = 1 end end
-- CSS 的 ease = cubic-bezier(0.25, 0.1, 0.25, 1)
local function cssEase(x)
    if x <= 0 then return 0 elseif x >= 1 then return 1 end
    local t = x
    for _ = 1, 8 do                                                   -- 牛顿迭代：由 x 求贝塞尔参数 t
        local cx = 3 * 0.25 * (1 - t) ^ 2 * t + 3 * 0.25 * (1 - t) * t * t + t * t * t - x
        local dx = 3 * 0.25 * (1 - t) ^ 2 + 6 * (0.25 - 0.25) * (1 - t) * t + 3 * (1 - 0.25) * t * t
        if math.abs(cx) < 1e-5 or dx == 0 then break end
        t = math.max(0, math.min(1, t - cx / dx))
    end
    return 3 * 0.1 * (1 - t) ^ 2 * t + 3 * 1 * (1 - t) * t * t + t * t * t
end
GameUI.cssEase = cssEase
local function tweenFx(st, target, dt)
    if target ~= st.to then st.from = st.a; st.to = target; st.t = 0 end
    if st.t < 1 then st.t = math.min(1, st.t + dt / st.dur); st.a = st.from + (st.to - st.from) * cssEase(st.t) else st.a = st.to end
end
function GameUI.UpdateFx(dt)
    tweenFx(FX.warp, FX.warp.on and 1 or 0, dt)
    tweenFx(FX.hitflash, FX.hitflash.op or 0, dt)
end
-- 椭圆径向渐变（CSS radial-gradient(ellipse at center, ...)：椭圆过屏幕四角，长短轴比 = 屏幕宽高比）
-- stops = { { 位置 0~1, r, g, b, a }, ... }；多段时后一段从“透明的下一色”过渡到下一色，叠在前一段上
local function ellipseLayer(vg, w, h, stops, op)
    local Rr = h * 0.5 * math.sqrt(2)
    nvgSave(vg); nvgTranslate(vg, w / 2, h / 2); nvgScale(vg, w / h, 1)
    for i = 1, #stops - 1 do
        local a, b = stops[i], stops[i + 1]
        local ia = (i == 1) and a[5] or 0
        local ic = (i == 1) and a or b
        local paint = nvgRadialGradient(vg, 0, 0, a[1] * Rr, b[1] * Rr, nvgRGBA(ic[2], ic[3], ic[4], math.floor(ia * op * 255 + 0.5)), nvgRGBA(b[2], b[3], b[4], math.floor(b[5] * op * 255 + 0.5)))
        nvgBeginPath(vg); nvgRect(vg, -h / 2, -h / 2, h, h); nvgFillPaint(vg, paint); nvgFill(vg)
    end
    nvgRestore(vg)
end
local HIT_STOPS = { { 0.68, 224, 69, 140, 0 }, { 1.0, 224, 69, 140, 0.55 } }                       -- v1.5.4：红边从 55% 半径处开始 -> 68%，只留屏幕最外圈                       -- rgba(224,69,140,0) 55%, rgba(224,69,140,.55) 100%
local WARP_STOPS = { { 0, 92, 242, 220, 0.32 }, { 0.45, 16, 24, 58, 0.9 }, { 0.75, 5, 6, 15, 0.97 } } -- rgba(92,242,220,.32) 0%, rgba(16,24,58,.9) 45%, rgba(5,6,15,.97) 75%
function GameUI.DrawFx(w, h)
    local vg = UI.vg; if not vg or not (nvgRadialGradient and nvgFillPaint) then return end
    if FX.hitflash.a > 0.004 then ellipseLayer(vg, w, h, HIT_STOPS, math.min(1, FX.hitflash.a) * 0.5) end   -- v1.5.4：受击屏幕边缘红闪 x0.5
    if FX.warp.a > 0.004 then ellipseLayer(vg, w, h, WARP_STOPS, math.min(1, FX.warp.a)) end
end
function GameUI.ModalOpen() return u.levelup or u.shop or u.pause or u.pset or u.revive or (R() and R().result and R().ended) end

-- ---------------------------------------------------------------- 绘制
local function mmss(t) return U.fmtTime(t) end
local function dim(W) nvgBeginPath(UI.vg); nvgRect(UI.vg, 0, 0, W, 1080); nvgFillColor(UI.vg, nvgRGBA(0, 0, 10, 175)); nvgFill(UI.vg) end
local W = require("cosmic.WebUI")
local K = W.C
local function choiceIcon(id)
    local r = R()
    if id:sub(1, 3) == "new" then return C:modIcon(r.modPool[tonumber(id:sub(4))]) end
    if id:sub(1, 3) == "evo" or id:sub(1, 3) == "mod" then return C:modIcon(r.mods[tonumber(id:sub(4))].m) end
    if id == "heal" then return C.ICON.heal end
    if id == "main" then return UI.CatIcon(r.mech) end
    if id == "support" then return UI.CatIcon(r.pilot) end
    return C.ICON[id]
end
function GameUI.DrawHud()
    local r = R(); if not r then return end
    W.block = GameUI.ModalOpen() and true or false
    local Wd = UI.lw; local pad = 36; local m = S:M()
    -- 顶部经验条（带边框）与等级
    W.box(pad, 18, Wd - pad * 2, 30, { bg = K.lo, alpha = 200, border = K.hi, bw = 3 }); W.rect(pad + 3, 21, (Wd - pad * 2 - 6) * clamp(r.xp / S:xpNeed(r.level), 0, 1), 24, K.teal)
    W.text(Wd - pad - 12, 50, "Lv " .. r.level, 24, K.muted, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)
    -- 耐久 / 信用点 / 星源（带图标）
    W.text(pad, 60, "耐久 " .. math.ceil(r.hull) .. " / " .. S:hullMax(), 30, K.bone)
    UI.Icon(UI.ResIcon("credit"), pad, 104, 30); W.text(pad + 42, 102, tostring(math.floor(r.credits)), 28, K.bone)
    UI.Icon(UI.ResIcon("shard"), pad, 142, 30); W.text(pad + 42, 140, "星源 " .. r.src, 28, K.bone)
    -- 槽位：主武器 + 已装备卡牌 + 已获得的被动强化（图标 + 等级）
    local sx = pad
    local function slot(ic, label, hot)
        W.box(sx, 186, 58, 58, { bg = K.lo, alpha = 200, border = K.hi, bw = 3 }); W.pix(ic, sx + 8, 192, 38, nil, 255, true); W.text(sx + 52, 224, tostring(label), 18, hot and K.amber or K.bone, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP); sx = sx + 64
    end
    slot(UI.CatIcon(r.mech), S:lv("main"))
    r.mods:forEach(function(_, md) slot(C:modIcon(md.m), md.evo and "★" or md.lv, md.evo) end)
    for _, k in ipairs(require("jsrt.JS").keys(S.UPG)) do if k ~= "main" and k ~= "support" and S:lv(k) > 0 then slot(C.ICON[k], S:lv(k)) end end
    -- 待选升级：战斗不中断时在这里提示，点一下再选卡
    if r.pendingLevels > 0 and not GameUI.ModalOpen() and u.defer then
        local pulse = 0.5 + 0.5 * math.sin(GameUI.t * 6); GameUI.t = GameUI.t
        W.rect(pad, 256, 330, 70, K.amber, math.floor(200 + 55 * pulse)); W.rect(pad, 256, 330, 5, K.amberHi); W.rect(pad, 320, 330, 6, K.amberLo)
        W.text(pad + 165, 291, "升级 ×" .. r.pendingLevels .. "　点击选择", 30, K.ink, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        if W.hit(pad, 256, 330, 70) then GameUI.OpenPendingLevel() end
    end
    local head
    if r.daily then head = "每日挑战　第 " .. r.wave .. " 波　剩余 " .. mmss(C.DC_TIME - r.secT) .. "　得分 " .. S:dcScore()
    elseif r.endless then head = "无尽模式　第 " .. r.wave .. " 波　" .. mmss(r.t)
    else head = "星域 " .. r.sector .. " / " .. S.SECTORS .. "　" .. ((r.gate.state == "open") and "飞进星门" or tostring(r.objective or "")) end
    if r.danger > 1 then head = head .. "　危险 " .. r.danger end
    if r.affix then head = head .. "　[" .. r.affix.name .. "：" .. r.affix.desc .. "]" end
    W.title(Wd / 2, 52, "第 " .. r.ch.id .. " 章 " .. r.ch.name, 52, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    W.text(Wd / 2, 118, head, 28, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    -- 连击 / Boss / 提示 / 横幅
    if r.combo >= 5 and r.comboT > 0 then W.title(Wd - 340, 200, tostring(r.combo), 64, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP); W.text(Wd - 340, 270, (r.feverT and r.feverT > 0) and "连击 · 狂热" or "连击", 26, (r.feverT and r.feverT > 0) and K.amber or K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP) end
    if r.boss and r.boss.hp > 0 then
        W.text(Wd / 2, 160, r.boss.d.name, 30, K.danger, NVG_ALIGN_CENTER + NVG_ALIGN_TOP); W.box(Wd / 2 - 460, 198, 920, 26, { bg = K.lo, alpha = 210, border = K.hi, bw = 3 }); W.rect(Wd / 2 - 457, 201, 914 * clamp(r.boss.hp / r.boss.max, 0, 1), 20, K.danger)
    end
    if r.bannerT > 0 and not GameUI.ModalOpen() then W.title(Wd / 2, 250, r.banner, 60, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, nil) end
    local n = r.nearNode
    if n then W.text(Wd / 2, 956, n.info.name .. "　" .. ((n.type == "derelict" and n.state == "active") and ("搜刮中 " .. math.floor(n.progress * 100 + 0.5) .. "%") or ((n.type == "gate" and n.state ~= "open") and ("先完成本星域目标：" .. tostring(r.objective)) or tostring(n.info.hint))), 28, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP) end
    local tu = r.tutUI                                                          -- 新手引导框放在顶部目标栏下方，不挡机甲和迎面的敌人
    if tu and not GameUI.ModalOpen() then
        W.box(Wd / 2 - 560, 140, 1120, 84, { bg = K.lo, alpha = 235, border = K.teal, bw = 3 }); W.tag("新手引导 " .. tu.n .. " / " .. tu.total, Wd / 2 - 90, 128, 180, 30, K.teal, K.ink, 20)
        W.text(Wd / 2, 170, tu.text, 26, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    end
    -- 驾驶员卡片（头像 + 支援技能冷却 + 等级）
    local cop = C:char(r.pilot); local st = S:supportStat()
    W.panel(pad, 905, 300, 108, { alpha = 235 }); W.pix(UI.CatIcon(r.pilot), pad + 14, 917, 80, nil, 255, true)
    W.textFit(pad + 92, 915, cop.name, 28, K.bone, NVG_ALIGN_LEFT + NVG_ALIGN_TOP, 255, 120); W.text(pad + 284, 917, "Lv " .. st.lv, 20, K.muted, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)
    W.text(pad + 92, 946, r.match and "专属 +20%" or "驾驶员", 18, K.teal); W.textFit(pad + 92, 968, cop.support.name, 18, K.teal, NVG_ALIGN_LEFT + NVG_ALIGN_TOP, 255, 190)
    W.rect(pad + 92, 996, 184, 8, K.lo, 220); W.rect(pad + 92, 996, 184 * clamp(1 - r.supportCd / (cop.support.cd * st.cd), 0, 1), 8, K.teal)
    -- 机甲技能 / 氮气 / 暂停
    local ready = r.activeCd <= 0
    local bx, by = Wd - 36 - 230, 1080 - 30 - 230
    W.rect(bx, by, 230, 230, { 20, 26, 60 }, 240); W.box(bx, by, 230, 230, { bg = { 0, 0, 0 }, alpha = 0, border = (r.nitroT > 0) and K.teal or (ready and K.amber or K.hi), bw = 6 })
    W.pix(UI.CatIcon(r.mech), bx + 70, by + 14, 150, nil, ready and 255 or 120, true)
    W.text(bx + 115, by + 175, ready and m.active.name or tostring(math.ceil(r.activeCd)), ready and 28 or 52, ready and K.bone or K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, ready and 255 or 230)
    if not ready then W.rect(bx + 6, by + 218, 218 * clamp(1 - r.activeCd / S:activeCdMax(), 0, 1), 8, K.amber) end
    if W.hit(bx, by, 230, 230) then S:castActive() end
    local N = S:nitroOf(); local dgReady = r.dodgeCd <= 0; local dx0, dy0 = Wd - 36 - 250 - 140, 1080 - 40 - 140
    W.rect(dx0, dy0, 140, 140, { 20, 26, 60 }, 240); W.box(dx0, dy0, 140, 140, { bg = { 0, 0, 0 }, alpha = 0, border = dgReady and K.blue or K.hi, bw = 6 })
    W.text(dx0 + 70, dy0 + 70, dgReady and N.name or tostring(math.ceil(r.dodgeCd)), dgReady and 26 or 44, dgReady and K.bone or K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    if W.hit(dx0, dy0, 140, 140) then S:dodge() end
    -- 副武器（v1.4.0）：弹药 / 冷却 / 点按发射（电脑 Q 键）
    local sb = r.sub
    if sb then
        local sx0, sy0 = dx0, dy0 - 152; local sc = hexRGB(sb.def.color); local ready = sb.cd <= 0 and sb.ammo > 0
        W.rect(sx0, sy0, 140, 132, { 20, 26, 60 }, 240)
        local bc = (sb.flash > 0) and K.bone or (ready and sc or K.hi); W.rect(sx0, sy0, 140, 5, bc); W.rect(sx0, sy0 + 127, 140, 5, bc); W.rect(sx0, sy0, 5, 132, bc); W.rect(sx0 + 135, sy0, 5, 132, bc)
        W.textFit(sx0 + 70, sy0 + 14, sb.def.n, 22, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, ready and 255 or 170, 126)
        W.text(sx0 + 70, sy0 + 46, sb.ammo .. " / " .. sb.cap, 32, sb.ammo > 0 and K.amber or K.danger, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        if sb.cd > 0 then W.rect(sx0 + 10, sy0 + 104, 120, 8, K.lo, 220); W.rect(sx0 + 10, sy0 + 104, 120 * clamp(1 - sb.cd / S:subCdMax(), 0, 1), 8, sc)
        else W.text(sx0 + 70, sy0 + 96, (C.save.settings.subAuto ~= false) and "自动 / 点击发射" or "点击发射", 16, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP) end
        if W.hit(sx0, sy0, 140, 132) then S:fireSub(true) end
    end
    require("cosmic.DevUI").DrawBattle(S, Wd)
    local ex = HOST.exitRect; local pauseX = Wd - 418 - ((ex and ex.right and ex.right > 0.8) and 140 or 0)
    W.rect(pauseX, 60, 112, 82, K.lo, 190); W.rect(pauseX, 60, 112, 4, K.hi); W.text(pauseX + 56, 101, "暂停", 28, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    if W.hit(pauseX, 60, 112, 82) then S:openPause() end
end
local function dim(a) W.full({ 0, 0, 10 }, a or 175) end
local function drawLevelUp()
    local r, Wd = R(), 1920; dim(150)
    local lu = u.levelup                                                         -- 本帧开头的弹窗状态：点了卡牌 / 跳过后 u.levelup 会被清空
    local tt = S:lvTitle()
    W.title(Wd / 2, 130, tt.t, 120, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber); W.text(Wd / 2, 270, tt.s, 28, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    local ids = u.levelup.ids; local cw, gap = 441, 28; local x0 = (Wd - (ids.length * cw + (ids.length - 1) * gap)) / 2
    for i = 0, ids.length - 1 do
        local id = ids[i]; local info = S:choiceInfo(id); local x, y = x0 + i * (cw + gap), 324
        local accent = info.evo and K.amber or (info.crew and K.teal or K.hi)
        W.rect(x, y, cw, 498, { 22, 28, 70 }, 250); W.rect(x, y, cw, 6, accent); W.rect(x, y + 490, cw, 8, accent)
        if info.evo then W.box(x, y, cw, 498, { bg = { 0, 0, 0 }, alpha = 0, border = K.amber, bw = 4 }) end
        W.tag(info.tag, x + cw / 2 - 90, y + 24, 180, 36, accent, info.crew and K.ink or K.bone, 22)
        W.pix(choiceIcon(id), x + cw / 2 - 60, y + 86, 120, nil, 255, true)
        W.title(x + cw / 2, y + 242, info.name, 40, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, nil, cw - 40)
        W.wrap(x + 30, y + 312, cw - 60, info.text, 24, K.bone, 1.5)
        if W.hit(x, y, cw, 498) then S:applyChoice(id); GameUI.finishLevel(); return end   -- 已选卡：弹窗关闭，本帧不再画下面的按钮（v1.4.2 闪退原因）
    end
    local free = r.rr.free > 0; local left = free and 0 or math.max(0, AD_REFRESH - r.rr.ad)
    local label = free and ("刷新选项（免费 " .. r.rr.free .. " 次）") or (left > 0 and ("看广告 刷新选项（还可 " .. left .. " 次）") or "刷新次数已用完")
    if W.btn(572, 846, 389, 96, label, { size = 26, disabled = (not free) and left <= 0, teal = not free and left > 0 }) then
        if free then r.rr.free = r.rr.free - 1; C:sfx("click"); u.levelup.ids = S:choices()
        elseif r.rr.ad < AD_REFRESH then C:showAd("刷新升级选项", function(_, res) if not res.success then GameUI.Toast("需要完整看完广告才能刷新") return end r.rr.ad = r.rr.ad + 1; C:sfx("click"); if u.levelup then u.levelup.ids = S:choices() end end) end
    end
    if W.btn(975, 846, 372, 96, "跳过，回复 30% 耐久", { size = 26 }) then r.hull = math.min(S:hullMax(), r.hull + S:hullMax() * 0.3); GameUI.Toast("跳过：回复 30% 耐久"); GameUI.finishLevel(); return end
    if not lu.forced and W.btn(1361, 846, 300, 96, "稍后选择", { size = 28, sub = "战斗继续，随时再点", subSize = 18 }) then GameUI.DeferLevel() end
end
local function drawShop()
    local r, Wd = R(), 1920; dim(); W.panel(Wd / 2 - 600, 220, 1200, 600, { alpha = 248 })
    W.title(Wd / 2, 236, "流浪商人", 64, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber); W.text(Wd / 2, 320, "用本局收集的信用点交易。当前：" .. math.floor(r.credits), 28, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    for i, o in ipairs(u.shop.offers) do
        local x = Wd / 2 - 560 + (i - 1) * 380
        W.panel(x, 380, 360, 300, { alpha = 235 }); W.text(x + 180, 404, o.name, 36, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP); W.text(x + 180, 464, o.text, 26, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
        if W.btn(x + 30, 586, 300, 74, o.cost .. " 信用点", { size = 28, primary = r.credits >= o.cost, disabled = r.credits < o.cost }) then r.credits = r.credits - o.cost; o.go(); GameUI.Toast("购买了 " .. o.name); S:openShop() end
    end
    if W.btn(Wd / 2 - 150, 714, 300, 70, "离开", { size = 30 }) then u.shop = nil; S.paused = false end
end
local function drawPause()
    local Wd = 1920; dim(); W.panel(Wd / 2 - 560, 200, 1120, 640, { alpha = 248 }); W.title(Wd / 2, 220, "暂停", 76, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber)
    W.wrap(Wd / 2 - 500, 330, 1000, "左半屏拖动飞行（朝镜头方向），右半屏拖动转视角；武器自动锁定开火。右下大按钮释放机甲技能（电脑空格），小按钮氮气推进（电脑 Shift），上方是副武器飞弹（电脑 Q，消耗弹药）。电脑：WASD 飞行，R/F 升降，方向键转视角。每个星域完成箭头指向的目标，并击败足够的敌人为星门充能，星门就会开启。闯过 6 个星域、击败首领即可通关。", 28, K.bone, 1.55)
    if W.btn(Wd / 2 - 520, 690, 320, 96, "继续", { primary = true, size = 36 }) then u.pause = nil; S.paused = false end
    if W.btn(Wd / 2 - 160, 690, 320, 96, "设置", { size = 34 }) then u.pause = nil; u.pset = true end
    if W.btn(Wd / 2 + 200, 690, 320, 96, "撤退返回", { size = 34 }) then u.pause = nil; S:endRun(false, true) end
end
-- 战斗设置（暂停 -> 设置）：设置项来自战斗模块的 BATTLE_SET，与网页版同一张表；改动立即生效并存档
local function drawBattleSet()
    local Wd = 1920; dim(); W.panel(Wd / 2 - 620, 110, 1240, 860, { alpha = 248 }); W.title(Wd / 2, 124, "战斗设置", 64, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber)
    local st = C.save.settings; local L = S.BATTLE_SET
    for i = 0, L.length - 1 do
        local it = L[i]; local y = 220 + i * 76
        W.text(Wd / 2 - 580, y + 16, it.n, 28, K.bone)
        local cur = st[it.k]; if cur == nil then cur = it.d end
        for j = 0, it.o.length - 1 do
            local o = it.o[j]
            if W.btn(Wd / 2 - 100 + j * 230, y, 210, 62, o[1], { size = 26, primary = cur == o[0] }) then S:setSetting(it.k, o[0]); C:sfx("click") end
        end
    end
    if W.btn(Wd / 2 - 150, 856, 300, 76, "返回", { primary = true, size = 30 }) then u.pset = nil; u.pause = true end
end
local function drawRevive()
    local r, Wd = R(), 1920; dim(); W.panel(Wd / 2 - 480, 280, 960, 460, { alpha = 248 }); W.title(Wd / 2, 300, "机甲被击毁", 68, K.danger, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    W.text(Wd / 2, 410, "看一段广告可以原地复活（耐久 50%），每局限一次。", 30, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    if not r.adRevived then
        if W.btn(Wd / 2 - 440, 560, 420, 100, "看广告复活", { teal = true, size = 32 }) then
            C:showAd("复活机甲", function(_, res)
                if not res.success then GameUI.Toast("需要完整看完广告才能复活") return end
                u.revive = nil; r.adRevived = true; r.over = false; S.paused = false; r.hull = S:hullMax() * 0.5; r.iframe = 2; S:nova(S:P(), 14, 60, "#5CF2DC"); S:banner("复活！")
            end)
        end
    end
    if W.btn(Wd / 2 + 20, 560, 420, 100, "结束远征", { size = 32 }) then u.revive = nil; S:endRun(false) end
end
local function drawResult()
    local r, Wd = R(), 1920; local rs = r.result; local s = C.save; dim(170); W.panel(471, 138, 976, 798, { alpha = 250 })
    local title = r.daily and (rs.win and "每日挑战完成" or "每日挑战结束") or r.endless and "无尽模式结束" or rs.win and "远征成功" or rs.retreat and "已撤退返回" or "远征失败"
    W.title(526, 170, title, 86, rs.win and K.amber or K.danger, NVG_ALIGN_LEFT + NVG_ALIGN_TOP, nil)
    local reach = r.daily and ("得分 " .. rs.dcScore) or r.endless and ("第 " .. r.wave .. " 波") or rs.win and "通关" or (r.sector .. " / " .. S.SECTORS)
    local row1 = { { "到达", reach }, { "用时", mmss(r.t) }, { "击破", tostring(r.kills) }, { "信用点", "+" .. rs.credits }, { "星源", "+" .. rs.src } }
    local xs1 = { 526, 727, 951, 1104, 1316 }
    for i, row in ipairs(row1) do W.text(xs1[i], 322, row[1], 22, K.muted); W.text(xs1[i], 352, row[2], 52, K.bone) end
    local row2 = { { "本局等级", "Lv " .. r.level }, { "最高连击", tostring(r.bestCombo or 0) }, { "造成伤害", tostring(math.floor((r.dmgDealt or 0) + 0.5)) }, { "承受伤害", tostring(math.floor((r.dmgTaken or 0) + 0.5)) } }
    local xs2 = { 526, 783, 1040, 1298 }
    for i, row in ipairs(row2) do W.text(xs2[i], 440, row[1], 22, K.muted); W.text(xs2[i], 470, row[2], 52, K.bone) end
    if rs.build and rs.build ~= "" then W.textFit(526, 540, "本局构筑：" .. rs.build, 24, K.teal, NVG_ALIGN_LEFT + NVG_ALIGN_TOP, 255, 870) end
    local ny = 584
    local function note(t, c) W.text(526, ny, t, 26, c or K.bone); ny = ny + 52 end
    if rs.achNow and rs.achNow > 0 then note("有 " .. rs.achNow .. " 个成就可以领取，去“每日”页领取星源。") end
    if rs.first then note("首次通关奖励：星源 +" .. r.ch.first .. (C.CHAPTERS.length > r.ch.id and ("。第 " .. (r.ch.id + 1) .. " 章已解锁。") or "。")) end
    if rs.dgUnlock then note("危险等级 " .. s.dangerMax .. " 已解锁（奖励更高，敌人更强）。", K.amber) end
    if r.endless and not r.daily then note("无尽最高纪录：第 " .. s.endlessBest .. " 波。") end
    if r.daily then note("今日最高分 " .. C:dailyChallenge().state.best .. (rs.dcFirst and "。首次完成奖励已发放。" or "。今日奖励已领取。")) end
    if not rs.win and not rs.retreat and not r.endless then note("远征失败只带回 70% 信用点。", K.muted) end
    if rs.fragTxt and rs.fragTxt ~= "" then note(rs.fragTxt, K.teal) end
    if rs.subUsed and rs.subUsed > 0 then note(rs.subName .. " 消耗 " .. rs.subUsed .. " 发（没用完的已退回库存）", K.muted) end
    if W.btn(525, 820, 277, 104, rs.doubled and "已翻倍" or "看广告 信用点翻倍", { teal = not rs.doubled, size = 26, disabled = rs.doubled }) then
        C:showAd("结算奖励翻倍", function(_, res) if not res.success then GameUI.Toast("需要完整看完广告才能领取") return end s.credits = s.credits + rs.credits; C:write(); rs.doubled = true; GameUI.Toast("信用点再 +" .. rs.credits) end)
    end
    if W.btn(822, 820, 277, 104, "分享战绩", { size = 28 }) then
        local tx = "我在《宇宙银河机甲》" .. (r.daily and ("每日挑战拿到了 " .. rs.dcScore .. " 分") or r.endless and ("无尽模式撑到了第 " .. r.wave .. " 波") or rs.win and ("通关了第 " .. r.ch.id .. " 章") or ("闯到了星域 " .. r.sector)) .. "！用 " .. C:mech(r.mech).name .. "击破 " .. r.kills .. " 个敌人。来挑战我吧！"
        if HOST.onShare then HOST.onShare(tx) end; GameUI.Toast("战绩：" .. tx)
    end
    if W.btn(1118, 820, 278, 104, "返回机库", { primary = true, size = 32 }) then S.R = nil; GameUI.Reset(); if GameUI.onHome then GameUI.onHome() end end
end
function GameUI.DrawModals()
    local r = R(); if not r then return end
    W.block = false
    if r.ended and r.result then drawResult()
    elseif u.levelup then drawLevelUp()
    elseif u.shop then drawShop()
    elseif u.revive then drawRevive()
    elseif u.pset then drawBattleSet()
    elseif u.pause then drawPause() end
    GameUI.DrawToast()
end
-- ---------------------------------------------------------------- 输入（对应 bindPointer / keydown）
local KEYMAP = { KeyW = KEY_W, KeyA = KEY_A, KeyS = KEY_S, KeyD = KEY_D, KeyR = KEY_R, KeyF = KEY_F, ArrowLeft = KEY_LEFT, ArrowRight = KEY_RIGHT, ArrowUp = KEY_UP, ArrowDown = KEY_DOWN }
function GameUI.Input(W, H, viewS)
    local r = R(); if not r or GameUI.ModalOpen() then return end
    local joy, look, keys = S.joy, S.look, S.keys
    for _, t in ipairs(UI.taps) do
        if not t.used then
            if t.px < W * 0.5 and joy.id == nil then joy.id = t.id; joy.cx = t.px; joy.cy = t.py; joy.dx = 0; joy.dy = 0; t.used = true
            elseif look.id == nil then look.id = t.id; look.x = t.px; look.y = t.py; look.idle = 0; t.used = true end
        end
    end
    for id, st in pairs(UI.ptr) do
        if id == joy.id then
            local R0 = 60 * math.max(0.55, viewS * 1.5); local dx, dy = st.px - joy.cx, st.py - joy.cy; local l = math.sqrt(dx * dx + dy * dy)
            if l > R0 then dx = dx / l * R0; dy = dy / l * R0 end
            joy.dx = dx / R0; joy.dy = -dy / R0
        elseif id == look.id then
            local k = 0.32 / math.max(0.3, viewS * 1.5) * S:sensK()
            r.camYaw = r.camYaw + (st.px - look.x) * k; r.camPitch = clamp(r.camPitch + (st.py - look.y) * k, -70, 70); look.x = st.px; look.y = st.py; look.idle = 0
        end
    end
    for _, st in ipairs(UI.released) do
        if st.id == joy.id then joy.id = nil; joy.dx = 0; joy.dy = 0 end
        if st.id == look.id then look.id = nil; look.idle = 0 end
    end
    for code, k in pairs(KEYMAP) do keys[code] = input:GetKeyDown(k) or nil end
    if input:GetKeyPress(KEY_SPACE) then S:castActive() end
    if input:GetKeyPress(KEY_SHIFT) then S:dodge() end
    if KEY_Q and input:GetKeyPress(KEY_Q) then S:fireSub(true) end
    if input:GetKeyPress(KEY_ESCAPE) and not r.ended then S:openPause() end
end
function GameUI.DrawToast() if GameUI.toast and GameUI.toast.t > 0 then local W2 = require("cosmic.WebUI"); W2.box(960 - 380, 150, 760, 60, { bg = W2.C.lo, alpha = 235, border = W2.C.teal, bw = 3 }); W2.text(960, 164, GameUI.toast.text, 28, W2.C.teal, NVG_ALIGN_CENTER + NVG_ALIGN_TOP) end end
function GameUI.Update(dt) GameUI.t = (GameUI.t or 0) + dt; if GameUI.toast then GameUI.toast.t = GameUI.toast.t - dt end; GameUI.UpdateFx(dt) end
return GameUI
