-- UI.lua：NanoVG 立即模式界面（设计分辨率 1920x1080）+ 触控 / 鼠标输入。
-- 不依赖 urhox-libs/UI，只用文档记录的 nvg* 接口与 Input 接口。
local U = require("cosmic.Util")
local Sdk = require("cosmic.Sdk")
local UI = { vg = nil, s = 1, w = 1920, h = 1080, lw = 1920, ox = 0, oy = 0, fox = 0, foy = 0, taps = {}, ptr = {}, stick = nil, camdx = 0, font = nil, hit = {}, down = {} }
local FONT = "sans"
function UI.Init(vg)
    UI.vg = vg; UI.font = nvgCreateFont(vg, FONT, "Fonts/MiSans-Bold.ttf")
    if UI.font == nil or UI.font < 0 then UI.font = nvgCreateFont(vg, FONT, "Fonts/MiSans-Regular.ttf") end
end
-- ---------------------------------------------------------------- 输入
local function gather()
    local list = {}
    local n = input:GetNumTouches()
    if n and n > 0 then for i = 0, n - 1 do local t = input:GetTouch(i); list[#list + 1] = { id = t.touchID, x = t.position.x, y = t.position.y } end
    elseif input:GetMouseButtonDown(MOUSEB_LEFT) then list[1] = { id = -1, x = input.mousePosition.x, y = input.mousePosition.y } end
    return list
end
-- 自适应：设计分辨率 1920x1080。屏幕比 16:9 窄（4:3、16:10）时按宽度缩放（整体缩小并垂直居中，不裁切）；比 16:9 宽（18:9、21:9）时按高度缩放，
-- 机库 / 弹窗放在居中的 1920 宽内容区（center），战斗 HUD 贴着真实屏幕边缘（edge）。UI.SetFrame / UI.Frame(mode) 切换。
function UI.BeginFrame(w, h)
    UI.w, UI.h = w, h
    local s0 = h / 1080
    if w / s0 < 1920 then UI.s = w / 1920; UI.lw = 1920; UI.oy = (h / UI.s - 1080) / 2 else UI.s = s0; UI.lw = w / s0; UI.oy = 0 end
    UI.ox = (UI.lw - 1920) / 2; UI.fox, UI.foy = UI.ox, UI.oy
    UI.taps = {}; UI.hit = {}; UI.released = {}
    local seen = {}
    for _, p in ipairs(gather()) do
        local rx, ry = p.x / UI.s, p.y / UI.s; seen[p.id] = true
        local st = UI.ptr[p.id]
        if not st then st = { id = p.id, rsx = rx, rsy = ry, rx = rx, ry = ry, px = p.x, py = p.y, owner = nil, travel = 0, dx = 0, dy = 0 }; UI.ptr[p.id] = st; UI.taps[#UI.taps + 1] = { rx = rx, ry = ry, px = p.x, py = p.y, id = p.id, st = st }
        else st.dx, st.dy = rx - st.rx, ry - st.ry; st.rx, st.ry = rx, ry; st.px, st.py = p.x, p.y; st.travel = math.max(st.travel, math.sqrt((rx - st.rsx) ^ 2 + (ry - st.rsy) ^ 2)) end
    end
    for id, st in pairs(UI.ptr) do if not seen[id] then if UI.stick == st then UI.stick = nil end; UI.released[#UI.released + 1] = st; UI.ptr[id] = nil end end
    UI.Reproject()
end
-- 把触点从屏幕设计坐标换算到当前坐标系（减去当前坐标系的偏移）
function UI.Reproject()
    local fx, fy = UI.fox, UI.foy
    for _, t in ipairs(UI.taps) do t.x, t.y = t.rx - fx, t.ry - fy end
    local function prj(st) st.x, st.y, st.sx, st.sy = st.rx - fx, st.ry - fy, st.rsx - fx, st.rsy - fy end
    for _, st in pairs(UI.ptr) do prj(st) end
    for _, st in ipairs(UI.released) do prj(st) end
end
function UI.SetFrame(mode) if mode == "edge" then UI.fox = 0 else UI.fox = UI.ox end; UI.foy = UI.oy; UI.Reproject() end
-- 点击检测：本帧刚按下且落在矩形内（并且该触点未被别的控件占用）
local function tapIn(x, y, w, h)
    for _, t in ipairs(UI.taps) do if not t.used and t.x >= x and t.x <= x + w and t.y >= y and t.y <= y + h then t.used = true; t.st.owner = "btn"; return true end end
    return false
end
function UI.Pressed(key) return input:GetKeyPress(key) end
-- 战斗输入：左半屏拖动 = 摇杆，右半屏拖动 = 转镜头；键盘 WASD / 方向键
function UI.RunInput()
    local inp = { jx = 0, jy = 0, camdx = 0 }
    for _, t in ipairs(UI.taps) do
        if not t.used then
            if t.x < UI.lw * 0.5 and not UI.stick then UI.stick = t.st; t.st.owner = "stick"; t.st.cx, t.st.cy = t.x, t.y; t.used = true
            elseif t.x >= UI.lw * 0.5 then t.st.owner = "cam"; t.used = true end
        end
    end
    for _, st in pairs(UI.ptr) do
        if st.owner == "cam" and st.dx then inp.camdx = inp.camdx + st.dx * 0.18; st.dx = 0 end
    end
    if UI.stick then
        local dx, dy = UI.stick.x - UI.stick.cx, UI.stick.y - UI.stick.cy; local len = math.sqrt(dx * dx + dy * dy); local R = 110
        if len > 8 then local k = math.min(1, len / R); inp.jx, inp.jy = dx / len * k, -dy / len * k end
    end
    local function key(k) return input:GetKeyDown(k) end
    if key(KEY_A) or key(KEY_LEFT) then inp.jx = inp.jx - 1 end
    if key(KEY_D) or key(KEY_RIGHT) then inp.jx = inp.jx + 1 end
    if key(KEY_W) or key(KEY_UP) then inp.jy = inp.jy + 1 end
    if key(KEY_S) or key(KEY_DOWN) then inp.jy = inp.jy - 1 end
    local l = math.sqrt(inp.jx * inp.jx + inp.jy * inp.jy); if l > 1 then inp.jx, inp.jy = inp.jx / l, inp.jy / l end
    if input:GetKeyPress(KEY_SPACE) or input:GetKeyPress(KEY_SHIFT) then inp.nitro = true end
    if input:GetKeyPress(KEY_E) then inp.skill = true end
    return inp
end
-- ---------------------------------------------------------------- 绘制工具
local COL = { bg = { 9, 12, 34 }, panel = { 18, 24, 58 }, hi = { 52, 64, 122 }, teal = { 92, 242, 220 }, amber = { 245, 165, 36 }, bone = { 237, 230, 214 }, danger = { 255, 77, 106 }, muted = { 150, 158, 190 } }
UI.COL = COL
local GRADE = { S = { 87, 184, 255 }, SS = { 180, 124, 255 }, SSR = { 245, 165, 36 }, SSSR = { 255, 93, 122 } }
UI.GRADE = GRADE
local function rgba(c, a) return nvgRGBA(c[1], c[2], c[3], a or 255) end
local function text(x, y, s, size, c, align, a)
    nvgFontFace(UI.vg, FONT); nvgFontSize(UI.vg, size); nvgTextAlign(UI.vg, align or (NVG_ALIGN_LEFT + NVG_ALIGN_TOP)); nvgFillColor(UI.vg, rgba(c or COL.bone, a)); nvgText(UI.vg, x, y, s)
end
UI.Text = text
local function rect(x, y, w, h, c, a, r) nvgBeginPath(UI.vg); if r then nvgRoundedRect(UI.vg, x, y, w, h, r) else nvgRect(UI.vg, x, y, w, h) end; nvgFillColor(UI.vg, rgba(c, a)); nvgFill(UI.vg) end
local function stroke(x, y, w, h, c, wd) nvgBeginPath(UI.vg); nvgRect(UI.vg, x, y, w, h); nvgStrokeColor(UI.vg, rgba(c)); nvgStrokeWidth(UI.vg, wd or 3); nvgStroke(UI.vg) end
function UI.Button(x, y, w, h, label, opt)
    opt = opt or {}
    local c = opt.color or COL.hi
    rect(x, y, w, h, opt.disabled and { 40, 44, 70 } or c); rect(x, y + h - 6, w, 6, { 0, 0, 0 }, 70)
    if opt.border then stroke(x, y, w, h, opt.border, 3) end
    text(x + w / 2, y + h / 2 - (opt.sub and (opt.subSize and 9 or 12) or 0), label, opt.size or 34, opt.textColor or (opt.disabled and COL.muted or COL.bone), NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    if opt.sub then text(x + w / 2, y + h / 2 + (opt.subSize and opt.subSize * 0.55 or 22), opt.sub, opt.subSize or 20, COL.muted, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE) end
    if opt.disabled then return false end
    return tapIn(x, y, w, h)
end
function UI.Bar(x, y, w, h, frac, c, bg) rect(x, y, w, h, bg or { 0, 0, 0 }, 110); rect(x, y, w * U.clamp(frac, 0, 1), h, c) end
function UI.Frame(mode) UI.SetFrame(mode or "center"); nvgSave(UI.vg); nvgScale(UI.vg, UI.s, UI.s); nvgTranslate(UI.vg, UI.fox, UI.foy) end
function UI.EndFrame() nvgRestore(UI.vg) end
function UI.Panel(x, y, w, h, a) rect(x, y, w, h, COL.bg, a or 215); stroke(x, y, w, h, COL.hi, 3) end
function UI.Wrap(x, y, w, s, size, c)
    nvgFontFace(UI.vg, FONT); nvgFontSize(UI.vg, size); nvgTextAlign(UI.vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP); nvgFillColor(UI.vg, rgba(c or COL.bone)); nvgTextBox(UI.vg, x, y, w, s)
end
-- 像素图标（网页版 A.iconSVG 的 NanoVG 版）：ic = { w, h, pal, px }；pal 可以是 Lua 列表（目录数据，1 起始）或 JS 数组（0 起始，带 length）
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local Canvas = require("jsrt.CanvasShim")
local cat_, res_
local function icons()
    if not cat_ then cat_ = {}; for _, it in ipairs(require("voxeldata.Catalog").items) do cat_[it.id] = it.icon end; res_ = require("voxeldata.Scenes").resIcons end
end
function UI.CatIcon(id) icons(); return cat_[id] end
function UI.ResIcon(id) icons(); return res_[id] end
function UI.Icon(ic, x, y, size)
    if not ic then return end
    local w, h = ic.w, ic.h; local cs = size / w; local pal = ic.pal; local js = pal.length ~= nil
    for j = 0, h - 1 do for i = 0, w - 1 do
        local ch = ic.px:sub(j * w + i + 1, j * w + i + 1)
        if ch ~= "." then
            local idx = B36:find(ch, 1, true) - 1; local col = js and pal[idx] or pal[idx + 1]
            nvgBeginPath(UI.vg); nvgRect(UI.vg, x + i * cs, y + j * cs, cs + 0.6, cs + 0.6); nvgFillColor(UI.vg, Canvas.parseColor(col, 1)); nvgFill(UI.vg)
        end
    end end
end
return UI
