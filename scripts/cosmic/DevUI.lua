-- DevUI.lua：兑换码页面、开发者解锁页面、开发者面板（机库 / 战斗）。开发者功能只在 Redeem.Dev.on（本设备用作者的开发者码解锁）时可用。
local UI = require("cosmic.UI")
local W = require("cosmic.WebUI")
local Kp = require("cosmic.Keypad")
local Rd = require("cosmic.Redeem")
local JS = require("jsrt.JS")
local K = W.C
local D = { speed = 1, stats = false, fps = 60, kp = nil, taps = 0, tapT = 0 }
local C, HOST, Hub
function D.Init(cosmic, host, hub) C, HOST, Hub = cosmic, host, hub; Rd.Dev.Check(cosmic); D.did = Rd.DeviceId(cosmic) end
function D.On() return Rd.Dev.on end
local function toast(m) if HOST.onToast then HOST.onToast(m) end end
local function dim() W.full({ 0, 0, 10 }, 190) end
local function sv() return C.save end
local function list(a) local t = {}; if a then for i = 0, a.length - 1 do t[#t + 1] = a[i] end end return t end

-- ---------------------------------------------------------------- 兑换码
function D.DrawRedeem()
    dim(); W.panel(480, 90, 960, 900, { alpha = 250 }); W.title(960, 106, "兑换码", 60, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber)
    W.text(960, 186, "输入作者发放的兑换码，可兑换信用点或星源（每个码每台设备限用 1 次）", 22, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    D.kp = D.kp or Kp.New(24)
    local ev = Kp.Draw(D.kp, 570, 236)
    if ev == "cancel" then D.kp = nil; Hub.modal = "settings"
    elseif ev == "submit" then
        local ok, msg = Rd.Redeem(C, D.kp.text); D.kp.ok = ok; D.kp.msg = (ok and "兑换成功：" or "") .. msg
        if ok then C:sfx("win"); toast("兑换成功：" .. msg); D.kp.text = "" end
    end
end
-- ---------------------------------------------------------------- 开发者解锁
function D.DrawUnlock()
    dim(); W.panel(480, 90, 960, 900, { alpha = 250 }); W.title(960, 106, "开发者模式", 60, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber)
    W.text(960, 186, "本设备设备码：" .. Rd.FormatDid(D.did), 34, K.teal, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    W.text(960, 232, "把设备码发给作者，用 tools/gen_codes.py dev 设备码 生成解锁码后在下面输入（只对本设备有效）", 20, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    D.kp = D.kp or Kp.New(24)
    local ev = Kp.Draw(D.kp, 570, 276, "解锁")
    if ev == "cancel" then D.kp = nil; Hub.modal = "settings"
    elseif ev == "submit" then
        local ok, msg = Rd.Dev.Unlock(C, D.kp.text); D.kp.ok = ok; D.kp.msg = msg
        if ok then C:sfx("win"); D.kp = nil; Hub.modal = "dev" end
    end
end
-- ---------------------------------------------------------------- 机库里的开发者面板
local function freeBuy(n, f) local s = sv(); local c0, k0 = s.credits, s.modBuys; for _ = 1, n do s.credits = 1e12; f() end; s.credits = c0 end
local ACTIONS = {
    { "信用点 +10,000", function() sv().credits = sv().credits + 10000 end },
    { "信用点 +1,000,000", function() sv().credits = sv().credits + 1000000 end },
    { "星源 +1,000", function() sv().src = sv().src + 1000 end },
    { "星源 +100,000", function() sv().src = sv().src + 100000 end },
    { "资源清零", function() sv().credits = 0; sv().src = 0 end },
    { "解锁全部机甲（满级满星）", function() for _, m in ipairs(list(C.MECHS)) do sv().mechs[m.id] = { lv = C.MECH_MAX, star = 5 } end end },
    { "解锁全部驾驶员（满星）", function() for _, c in ipairs(list(C.CHARS)) do sv().chars[c.id] = { star = 5 } end end },
    { "全部章节通关 + 危险 10", function() for _, ch in ipairs(list(C.CHAPTERS)) do sv().cleared[ch.id] = true end; sv().chapter = C.CHAPTERS.length; sv().dangerMax = 10 end },
    { "全员碎片 +50", function() for _, m in ipairs(list(C.MECHS)) do sv().frags[m.id] = (sv().frags[m.id] or 0) + 50 end; for _, c in ipairs(list(C.CHARS)) do sv().frags[c.id] = (sv().frags[c.id] or 0) + 50 end end },
    { "免费抽 10 张卡牌", function() freeBuy(10, function() C:buyModule() end) end },
    { "免费研发 10 枚芯片", function() freeBuy(10, function() C:buyChip() end) end },
    { "重置每日（补给 / 任务 / 登录）", function() sv().daily = JS.dict(); sv().login = nil; C:load(); end },
    { "重播新手引导", function() sv().tutorialDone = false end },
    { "召唤保底清零", function() sv().mechPity, sv().mechPity3, sv().pilotPity, sv().pilotPity3 = 0, 0, 0, 0 end },
}
D.ACTIONS = ACTIONS
function D.DrawHubPanel()
    dim(); W.panel(300, 70, 1320, 940, { alpha = 250 }); W.title(960, 84, "开发者面板", 56, K.amber, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, K.amber)
    W.text(960, 160, "设备码 " .. Rd.FormatDid(D.did) .. "　　信用点 " .. math.floor(sv().credits) .. "　星源 " .. math.floor(sv().src) .. "　（仅作者可见；玩家看不到这个页面）", 22, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
    for i, a in ipairs(ACTIONS) do
        local col, row = (i - 1) % 3, (i - 1) // 3
        if W.btn(330 + col * 428, 210 + row * 96, 412, 84, a[1], { size = 26 }) then a[2](); C:write(); C:sfx("click"); toast("已执行：" .. a[1]) end
    end
    if W.btn(330, 210 + 5 * 96 + 20, 412, 80, "删除全部存档（慎用）", { size = 26, purple = D.confirmWipe }) then
        if D.confirmWipe then C.save = nil; if HOST.localStorage then HOST.localStorage:removeItem("galaxy-mecha-save-v8") end; C:load(); D.did = Rd.DeviceId(C); D.confirmWipe = false; toast("存档已清空"); Hub.Init(C, HOST) else D.confirmWipe = true; toast("再点一次确认删除") end
    end
    if W.btn(758, 210 + 5 * 96 + 20, 412, 80, "调试信息：" .. (D.stats and "开" or "关"), { size = 26 }) then D.stats = not D.stats end
    if W.btn(1186, 210 + 5 * 96 + 20, 412, 80, "退出开发者模式", { size = 26 }) then Rd.Dev.Lock(C); Hub.modal = nil; toast("已退出开发者模式") end
    if W.btn(810, 920, 300, 70, "关闭", { primary = true, size = 30 }) then Hub.modal = nil end
end
-- ---------------------------------------------------------------- 战斗里的开发者面板（在 HUD 的 edge 坐标系里绘制）
D.open = false
function D.DrawBattle(S, Wd)
    local r = S.R; if not r or not Rd.Dev.on then return end
    local dbg = HOST.window.CosmicRun.debug
    if W.btn(36, 340, 92, 48, "DEV", { size = 22, primary = D.open }) then D.open = not D.open end
    if D.stats then
        local R = require("jsrt.Renderer"); local n, dr = R.Stats()
        W.text(140, 346, string.format("FPS %.0f　节点 %d　绘制 %d　敌人 %d　弹体 %d　t=%.0fs　等级 %d　速度 x%.1f", D.fps, n, dr, r.enemies.length, r.shots.length, r.t, r.level, D.speed), 20, K.teal)
    end
    if not D.open then return end
    local x, y = Wd - 380, 280
    W.panel(x, y, 360, 540, { alpha = 235, flat = true })
    local function b(i, label, fn, on) local col, row = (i - 1) % 2, (i - 1) // 2; if W.btn(x + 12 + col * 172, y + 12 + row * 62, 164, 54, label, { size = 20, primary = on }) then fn() end end
    b(1, "无敌", function() r.god = not r.god end, r.god)
    b(2, "秒杀", function() if r.devOne then r.st.atk = r.st.atk - 99; r.devOne = false else r.st.atk = r.st.atk + 99; r.devOne = true end end, r.devOne)
    b(3, "满血", function() r.hull = S:hullMax() end)
    b(4, "清场", function() for _, e in ipairs(list(r.enemies)) do S:hurtEnemy(e, 1e9, 0, 0, 0, true) end end)
    b(5, "升级 +1", function() r.pendingLevels = r.pendingLevels + 1 end)
    b(6, "升级 +5", function() r.pendingLevels = r.pendingLevels + 5 end)
    b(7, "信用点 +1000", function() r.credits = r.credits + 1000 end)
    b(8, "星源 +100", function() r.src = r.src + 100 end)
    b(9, "下一星域", function() if r.sector < S.SECTORS then dbg:sector(r.sector + 1) end end)
    b(10, "星域 6 首领", function() dbg:sector(S.SECTORS) end)
    b(11, "星门前", function() dbg:toGate() end)
    b(12, "调试信息", function() D.stats = not D.stats end, D.stats)
    b(13, "胜利结算", function() S:endRun(true) end)
    b(14, "失败结算", function() S:endRun(false) end)
    for i, sp in ipairs({ 0.5, 1, 2, 4 }) do if W.btn(x + 12 + (i - 1) * 86, y + 12 + 7 * 62 + 8, 80, 54, "x" .. sp, { size = 22, primary = D.speed == sp }) then D.speed = sp end end
    W.text(x + 180, y + 12 + 7 * 62 + 70, "速度倍率（战斗）", 18, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_TOP)
end
return D
