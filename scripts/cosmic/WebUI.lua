-- WebUI.lua：与网页版 index.template.html 样式一致的 NanoVG 控件。
-- 颜色 / 尺寸全部取自网页版 CSS：.panel（斜切角 14px、上 / 左 5px 亮边、右 5px / 下 7px 暗边）、.btn（凸起按钮）、.mk-nav（底部导航）、
-- .mk-res（资源条）、.mk-stat（属性条）、.st（菱形星级）、.mk-grade（等级徽章）等。设计分辨率 1920 x 1080。
local UI = require("cosmic.UI")
local Canvas = require("jsrt.CanvasShim")
local W = {}
local C = {
    panel = { 24, 30, 66 }, hi = { 52, 64, 122 }, lo = { 9, 12, 34 }, amber = { 245, 165, 36 }, amberHi = { 255, 210, 122 }, amberLo = { 168, 106, 6 }, ink = { 42, 26, 0 },
    teal = { 92, 242, 220 }, danger = { 224, 69, 140 }, hp = { 124, 242, 154 }, bone = { 237, 230, 214 }, muted = { 163, 171, 207 }, space = { 16, 20, 43 }, blue = { 87, 184, 255 },
}
W.C = C
W.GRADE = { S = { 87, 184, 255 }, SS = { 180, 124, 255 }, SSR = { 245, 165, 36 }, SSSR = { 255, 93, 122 } }
local function vg() return UI.vg end
local function col(c, a) return nvgRGBA(c[1], c[2], c[3], a or 255) end
-- 覆盖整个屏幕（任何比例）的纯色填充：弹窗遮罩 / 闪光
function W.full(c, a) W.rect(-UI.fox, -UI.foy, UI.lw, 1080 + 2 * UI.foy, c, a) end
-- 估算文字宽度（CJK = 字号，数字 / 字母 0.6，其余 0.4）；maxw 给定时自动缩小字号以放得下
function W.measure(s, size)
    local n = 0
    for _, cp in utf8.codes(tostring(s)) do n = n + ((cp > 0x2E80) and 1 or ((cp >= 48 and cp <= 122) and 0.6 or 0.4)) end
    return n * size
end
function W.fitSize(s, size, maxw) local m = W.measure(s, size); if maxw and m > maxw then return math.max(math.floor(size * 0.55), math.floor(size * maxw / m)) end return size end
function W.rect(x, y, w, h, c, a) nvgBeginPath(vg()); nvgRect(vg(), x, y, w, h); nvgFillColor(vg(), col(c, a)); nvgFill(vg()) end
function W.line(x, y, w, h, c, a) W.rect(x, y, w, h, c, a) end
local function octo(x, y, w, h, cut)
    nvgBeginPath(vg()); nvgMoveTo(vg(), x + cut, y); nvgLineTo(vg(), x + w - cut, y); nvgLineTo(vg(), x + w, y + cut); nvgLineTo(vg(), x + w, y + h - cut)
    nvgLineTo(vg(), x + w - cut, y + h); nvgLineTo(vg(), x + cut, y + h); nvgLineTo(vg(), x, y + h - cut); nvgLineTo(vg(), x, y + cut); nvgClosePath(vg())
end
-- ---------------------------------------------------------------- 文字
local function textPrep(size, align) nvgFontFace(vg(), "sans"); nvgFontSize(vg(), size); nvgTextAlign(vg(), align or (NVG_ALIGN_LEFT + NVG_ALIGN_TOP)) end
function W.text(x, y, s, size, c, align, a, spacing)
    textPrep(size, align); if spacing and nvgTextLetterSpacing then nvgTextLetterSpacing(vg(), spacing) end
    nvgFillColor(vg(), col(c or C.bone, a)); nvgText(vg(), x, y, tostring(s)); if spacing and nvgTextLetterSpacing then nvgTextLetterSpacing(vg(), 0) end
end
-- 带投影 / 发光的标题字（网页版 --display 字体效果的近似）
function W.textFit(x, y, s, size, c, align, a, maxw) W.text(x, y, s, W.fitSize(s, size, maxw), c, align, a) end
function W.title(x, y, s, size, c, align, glow, maxw)
    if maxw then size = W.fitSize(s, size, maxw) end
    textPrep(size, align or (NVG_ALIGN_CENTER + NVG_ALIGN_TOP)); s = tostring(s)
    if glow and nvgFontBlur then nvgFontBlur(vg(), 10); nvgFillColor(vg(), col(glow, 150)); nvgText(vg(), x, y, s); nvgFontBlur(vg(), 0) end
    nvgFillColor(vg(), col({ 10, 12, 34 }, 200)); nvgText(vg(), x + 3, y + 4, s); nvgFillColor(vg(), col(c or C.amber)); nvgText(vg(), x, y, s)
end
-- 估算自动换行后的行数（CJK 字宽 = 字号，其余 0.56 倍）
function W.lines(s, w, size)
    local n, cur = 1, 0
    for _, cp in utf8.codes(tostring(s)) do
        local cw = (cp > 0x2E80) and size or size * 0.56
        if cur + cw > w and cur > 0 then n = n + 1; cur = 0 end
        cur = cur + cw
    end
    return n
end
function W.wrap(x, y, w, s, size, c, lineH)
    textPrep(size); nvgFillColor(vg(), col(c or C.bone)); if nvgTextLineHeight then nvgTextLineHeight(vg(), (lineH or 1.5) * 1.0) end; nvgTextBox(vg(), x, y, w, tostring(s))
end
-- ---------------------------------------------------------------- 面板（.panel）
function W.panel(x, y, w, h, o)
    o = o or {}; local cut = o.cut or 14
    octo(x, y, w, h, cut); nvgFillColor(vg(), col(C.panel, math.max(o.alpha or 246, 240))); nvgFill(vg())
    if not o.flat then
        W.rect(x + cut, y, w - cut * 2, 5, C.hi); W.rect(x, y + cut, 5, h - cut * 2, C.hi)
        W.rect(x + w - 5, y + cut, 5, h - cut * 2, C.lo); W.rect(x + cut, y + h - 7, w - cut * 2, 7, C.lo)
        nvgBeginPath(vg()); nvgMoveTo(vg(), x + cut, y); nvgLineTo(vg(), x, y + cut); nvgLineTo(vg(), x, y + cut + 5); nvgLineTo(vg(), x + cut + 6, y); nvgClosePath(vg()); nvgFillColor(vg(), col(C.hi)); nvgFill(vg())
        nvgBeginPath(vg()); nvgMoveTo(vg(), x + w - cut, y + h); nvgLineTo(vg(), x + w, y + h - cut); nvgLineTo(vg(), x + w, y + h - cut - 6); nvgLineTo(vg(), x + w - cut - 6, y + h); nvgClosePath(vg()); nvgFillColor(vg(), col(C.lo)); nvgFill(vg())
    end
    if o.accent then W.rect(x, y, w, 5, o.accent) end                       -- 顶部强调色条（等级色）
    if o.left then W.rect(x, y + 4, 5, h - 8, o.left) end                   -- 左侧强调条
end
-- 深色底的方框（资源条 / 槽位）：内描边 3px
function W.box(x, y, w, h, o)
    o = o or {}; W.rect(x, y, w, h, o.bg or C.lo, math.max(o.alpha or 235, 225))
    local b = o.border or C.hi; local t = o.bw or 3
    W.rect(x, y, w, t, b); W.rect(x, y + h - t, w, t, b); W.rect(x, y, t, h, b); W.rect(x + w - t, y, t, h, b)
    if o.left then W.rect(x, y, 5, h, o.left) end
end
-- ---------------------------------------------------------------- 按钮（.btn / .btn.primary）
W.block = false                                   -- 弹窗打开时，下层页面不接收点击
-- v1.4.4 触控吸附：手机上手指落点偏一点就点不到小按钮（顶栏“返回 / 页签 / + / 设置”）。
-- 本帧没有被任何控件用掉的触点（以及按下后几乎没移动就松开的触点），吸附到 SNAP 设计像素内最近的按钮，下一帧触发。
-- 精确命中永远优先；战斗中的触点会被摇杆 / 视角占用，不参与吸附。
local SNAP = 44
local rects_, tapsRef_, relRef_, pend_ = {}, nil, nil, nil
local function snapCheck()
    if UI.taps == tapsRef_ then return end
    pend_ = nil
    if tapsRef_ and #rects_ > 0 then
        local cands = {}
        for _, t in ipairs(tapsRef_) do if not t.used and not t.st.owner then cands[#cands + 1] = { t.rx, t.ry } end end
        for _, st in ipairs(relRef_ or {}) do if not st.owner and not st.clicked and (st.travel or 0) < 24 then cands[#cands + 1] = { st.rx, st.ry } end end
        for _, c in ipairs(cands) do
            local best, bd = nil, SNAP
            for _, r in ipairs(rects_) do
                local dx = math.max(r[1] - c[1], 0, c[1] - (r[1] + r[3])); local dy = math.max(r[2] - c[2], 0, c[2] - (r[2] + r[4]))
                local d = math.sqrt(dx * dx + dy * dy); if d < bd then bd, best = d, r end
            end
            if best then pend_ = best; break end
        end
    end
    tapsRef_, relRef_, rects_ = UI.taps, UI.released, {}
end
local function tapDown(x, y, w, h)
    snapCheck()
    if W.block then return false end
    local ax, ay = x + UI.fox, y + UI.foy                                           -- 换成与触点相同的屏幕设计坐标
    if not W.clip then rects_[#rects_ + 1] = { ax, ay, w, h } end                 -- 滚动区内的条目不参与吸附
    if pend_ and pend_[1] == ax and pend_[2] == ay and pend_[3] == w and pend_[4] == h then pend_ = nil; return true end
    for _, t in ipairs(UI.taps) do if not t.used and t.x >= x and t.x <= x + w and t.y >= y and t.y <= y + h and (not W.clip or (t.x >= W.clip[1] and t.x <= W.clip[1] + W.clip[3] and t.y >= W.clip[2] and t.y <= W.clip[2] + W.clip[4])) then t.used = true; t.st.owner = "btn"; return true end end
    return false
end
-- 在滚动区域里的点击：松手时位移 < 14 才算点击（拖动用于滚动）
function W.click(x, y, w, h)
    if W.block then return false end
    for _, st in ipairs(UI.released) do
        if not st.clicked and (st.travel or 0) < 14 and st.sx >= x and st.sx <= x + w and st.sy >= y and st.sy <= y + h and st.x >= x and st.x <= x + w and st.y >= y and st.y <= y + h
            and (not W.clip or (st.sx >= W.clip[1] and st.sx <= W.clip[1] + W.clip[3] and st.sy >= W.clip[2] and st.sy <= W.clip[2] + W.clip[4])) then st.clicked = true; return true end
    end
    return false
end
function W.hit(x, y, w, h, scroll) if scroll then return W.click(x, y, w, h) end return tapDown(x, y, w, h) end
-- o: primary / teal / purple（配色）、sub（副标题）、size、disabled、active（选中态：teal 描边）、click（滚动区内使用）、subSize、icon
function W.btn(x, y, w, h, label, o)
    o = o or {}
    local base, light, dark, ink = C.hi, { 255, 255, 255 }, C.lo, C.bone
    local la = 31
    if o.primary then base, light, dark, ink, la = C.amber, C.amberHi, C.amberLo, C.ink, 255
    elseif o.teal then base, light, dark, ink, la = C.teal, { 190, 255, 245 }, { 40, 150, 140 }, C.ink, 255
    elseif o.purple then base, light, dark, ink, la = { 60, 38, 100 }, { 255, 255, 255 }, C.lo, C.bone, 31
    elseif o.flat then base, light, dark, ink, la = { 14, 18, 44 }, { 255, 255, 255 }, C.lo, C.bone, 10 end
    local dis = o.disabled
    if W.clip and (y + h < W.clip[2] or y > W.clip[2] + W.clip[4]) then return false end      -- 滚动区外不绘制
    W.rect(x, y, w, h, base, dis and 130 or 255); W.rect(x, y, w, 5, light, la); W.rect(x, y + h - 8, w, 8, dark, dis and 130 or 255)
    if o.active then W.box(x, y, w, h, { bg = { 0, 0, 0 }, alpha = 0, border = C.teal, bw = 4 }) end
    local ic = dis and C.muted or ink; local size = W.fitSize(label, o.size or 34, w - 20)
    if o.sub then
        local ss = o.subSize or math.max(16, math.floor(size * 0.64)); local total = size * 1.3 + ss * 1.2; local ty = y + (h - total) / 2
        W.text(x + w / 2, ty, label, size, ic, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, dis and 160 or 255); W.text(x + w / 2, ty + size * 1.3, o.sub, ss, ic, NVG_ALIGN_CENTER + NVG_ALIGN_TOP, dis and 130 or 215)
    else W.text(x + w / 2, y + h / 2 - 2, label, size, ic, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE, dis and 160 or 255) end
    if dis then return false end
    return W.hit(x, y, w, h, o.click)
end
-- ---------------------------------------------------------------- 小部件
function W.badge(g, x, y, w, h, size)                       -- .mk-grade：彩色方块 + 深色字
    local c = W.GRADE[g] or C.muted; W.rect(x, y, w, h, c); W.text(x + w / 2, y + h / 2, g, size or math.floor(h * 0.7), { 10, 12, 34 }, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
end
function W.tag(s, x, y, w, h, bg, fg, size) W.rect(x, y, w, h, bg or C.teal); W.text(x + w / 2, y + h / 2, s, size or math.floor(h * 0.62), fg or C.ink, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE) end
function W.stars(n, x, y, size, max)                        -- .st：旋转 45° 的菱形，亮起为琥珀色
    size = size or 18
    for i = 1, (max or 5) do
        local cx, cy = x + (i - 1) * (size + 2) + size / 2, y + size / 2; local r = size * 0.5
        nvgBeginPath(vg()); nvgMoveTo(vg(), cx, cy - r); nvgLineTo(vg(), cx + r, cy); nvgLineTo(vg(), cx, cy + r); nvgLineTo(vg(), cx - r, cy); nvgClosePath(vg())
        nvgFillColor(vg(), i <= n and col(C.amber) or nvgRGBA(163, 171, 207, 64)); nvgFill(vg())
    end
end
function W.pips(n, max, x, y, size, c)                      -- 等级小方块
    for i = 1, max do W.rect(x + (i - 1) * (size + 3), y, size, size, i <= n and (c or C.amber) or C.muted, i <= n and 255 or 60) end
end
function W.stat(label, v, max, c, x, y, w)                  -- .mk-stat：70px 标签 | 条 | 64px 数值
    W.text(x, y + 4, label, 22, C.muted); local bx, bw = x + 82, w - 82 - 76
    W.rect(bx, y + 12, bw, 14, C.lo, 230); W.rect(bx, y + 12, bw * math.max(0, math.min(1, v / max)), 14, c)
    W.text(x + w, y, tostring(math.floor(v + 0.5)), 28, C.bone, NVG_ALIGN_RIGHT + NVG_ALIGN_TOP)
end
function W.res(x, y, w, h, iconId, text, plus)             -- .mk-res > span
    W.box(x, y, w, h, { bg = C.lo, alpha = 210 }); UI.Icon(UI.ResIcon(iconId), x + 14, y + (h - 34) / 2, 34)
    W.text(x + 62, y + h / 2, text, 38, C.bone, NVG_ALIGN_LEFT + NVG_ALIGN_MIDDLE)
end
-- ---------------------------------------------------------------- 像素图标
-- ic: { w, h, pal, px }；color: 把所有格子画成同一颜色（currentColor 图标）
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
function W.pix(ic, x, y, size, mono, alpha, byHeight)
    if not ic then return end
    local w, h = ic.w, ic.h; local cs = byHeight and (size / h) or (size / w); local pal = ic.pal; local js = pal and pal.length ~= nil
    for j = 0, h - 1 do for i = 0, w - 1 do
        local ch = ic.px:sub(j * w + i + 1, j * w + i + 1)
        if ch ~= "." then
            local c
            if mono then c = mono else local idx = B36:find(ch, 1, true) - 1; local hex = js and pal[idx] or pal[idx + 1]; c = hex end
            nvgBeginPath(vg()); nvgRect(vg(), x + i * cs, y + j * cs, cs + 0.6, cs + 0.6)
            if type(c) == "table" then nvgFillColor(vg(), col(c, alpha)) else nvgFillColor(vg(), Canvas.parseColor(c, (alpha or 255) / 255)) end
            nvgFill(vg())
        end
    end end
end
local NAV = {
    go = { '..aa....', '..aaa...', '..aaaa..', '..aaaaa.', '..aaaa..', '..aaa...', '..aa....', '........' },
    mech = { '..aaaa..', '..abba..', 'aaaaaaaa', 'a.aaaa.a', '..aaaa..', '..a..a..', '..a..a..', '.aa..aa.' },
    pilot = { '..aaaa..', '.aaaaaa.', '.abaaba.', '.aaaaaa.', '..aaaa..', '.aaaaaa.', 'aaaaaaaa', 'aaaaaaaa' },
    summon = { '...a....', '..aba...', '.abbba..', 'abbbbba.', '.abbba..', '..aba...', '...a....', '........' },
    daily = { 'aaaaaaaa', 'abbbbbba', 'aaaaaaaa', 'abababba', 'aaaaaaaa', 'ababbaba', 'aaaaaaaa', '........' },
    work = { '.a.aa.a.', 'aaaaaaaa', '.abbbba.', 'aabaabaa', 'aabaabaa', '.abbbba.', 'aaaaaaaa', '.a.aa.a.' },
}
function W.navIcon(id, x, y, size, a, b)
    local rows = NAV[id]; local cs = size / 8
    for j = 1, 8 do for i = 1, 8 do
        local ch = rows[j]:sub(i, i)
        if ch ~= "." then nvgBeginPath(vg()); nvgRect(vg(), x + (i - 1) * cs, y + (j - 1) * cs, cs + 0.6, cs + 0.6); nvgFillColor(vg(), col(ch == "a" and a or b)); nvgFill(vg()) end
    end end
end
-- ---------------------------------------------------------------- 滚动区域
W.sc = {}
function W.scrollBegin(id, x, y, w, h, contentH)
    local s = W.sc[id] or { off = 0 }; W.sc[id] = s
    local maxOff = math.max(0, contentH - h)
    local wheel = input.mouseMoveWheel or 0
    if wheel ~= 0 then local mx, my = input.mousePosition.x / UI.s - UI.fox, input.mousePosition.y / UI.s - UI.foy; if mx >= x and mx <= x + w and my >= y and my <= y + h then s.off = s.off - wheel * 80 end end
    for _, st in pairs(UI.ptr) do
        if st.sx >= x and st.sx <= x + w and st.sy >= y and st.sy <= y + h and (st.travel or 0) > 14 and (st.scroll == nil or st.scroll == id) then st.scroll = id; s.off = s.off - (st.dy or 0) end
    end
    s.off = math.max(0, math.min(maxOff, s.off)); W.clip = { x, y, w, h }
    if nvgScissor then nvgSave(vg()); nvgScissor(vg(), x, y, w, h) end
    return y - s.off, s, maxOff
end
function W.scrollEnd(s, x, y, w, h, maxOff)
    if nvgScissor and W.clip then nvgResetScissor(vg()); nvgRestore(vg()) end; W.clip = nil
    if maxOff and maxOff > 0 then                                        -- 滚动条
        local th = math.max(40, h * h / (h + maxOff)); local ty = y + (h - th) * (s.off / maxOff)
        W.rect(x + w - 8, y, 8, h, C.lo, 120); W.rect(x + w - 8, ty, 8, th, C.hi)
    end
end
function W.visible(y, h, top, bottom) return y + h > top and y < bottom end
return W
