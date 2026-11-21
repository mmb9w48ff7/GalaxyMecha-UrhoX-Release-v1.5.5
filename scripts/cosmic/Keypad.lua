-- Keypad.lua：屏幕小键盘（NanoVG 自绘，不依赖系统输入法）+ 物理键盘输入，用来输入兑换码 / 开发者码（Crockford Base32：数字 + 去掉 I L O U 的字母）。
local UI = require("cosmic.UI")
local W = require("cosmic.WebUI")
local Sha = require("cosmic.Sha256")
local K = W.C
local Kp = {}
local ROWS = { "01234567", "89ABCDEF", "GHJKMNPQ", "RSTVWXYZ" }
function Kp.New(max) return { text = "", max = max or 24, msg = nil, ok = false } end
function Kp.Pretty(t) local o = {}; for i = 1, #t, 6 do o[#o + 1] = t:sub(i, i + 5) end return table.concat(o, "-") end
local function add(st, ch) if #st.text < st.max then st.text = st.text .. ch; st.msg = nil end end
local function poll(st)
    local sub = { O = "0", I = "1", L = "1" }
    for c in (Sha.ALPHA .. "OIL"):gmatch(".") do
        local k = _G["KEY_" .. c]; if k and input:GetKeyPress(k) then add(st, sub[c] or c) end
    end
    if KEY_BACKSPACE and input:GetKeyPress(KEY_BACKSPACE) then st.text = st.text:sub(1, -2) end
    if KEY_RETURN and input:GetKeyPress(KEY_RETURN) then return "submit" end
    return nil
end
-- 在 (x, y) 处画输入框 + 小键盘；返回 "submit" / "cancel" / nil。宽 780。
function Kp.Draw(st, x, y, submitLabel)
    local ev = poll(st)
    W.box(x, y, 780, 84, { bg = K.lo, alpha = 230, border = (st.msg and not st.ok) and K.danger or K.teal, bw = 3 })
    local shown = Kp.Pretty(st.text); if #st.text == 0 then W.text(x + 390, y + 42, "输入 24 位兑换码（不区分大小写，可含横线）", 22, K.muted, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
    else W.text(x + 390, y + 42, shown .. (math.floor(UI.t or 0) % 2 == 0 and "▏" or ""), 40, K.bone, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE, 255, 3) end
    if st.msg then W.text(x + 390, y + 98, st.msg, 24, st.ok and K.teal or K.danger, NVG_ALIGN_CENTER + NVG_ALIGN_TOP) end
    local ky = y + 142
    for r, row in ipairs(ROWS) do for c = 1, 8 do
        local ch = row:sub(c, c)
        if W.btn(x + 6 + (c - 1) * 96, ky + (r - 1) * 80, 88, 72, ch, { size = 34, flat = false }) then add(st, ch) end
    end end
    local by = ky + 4 * 80 + 8
    if W.btn(x + 6, by, 180, 72, "退格", { size = 28 }) then st.text = st.text:sub(1, -2) end
    if W.btn(x + 198, by, 180, 72, "清空", { size = 28 }) then st.text = ""; st.msg = nil end
    if W.btn(x + 390, by, 180, 72, "取消", { size = 28 }) then ev = "cancel" end
    if W.btn(x + 582, by, 192, 72, submitLabel or "确认", { primary = true, size = 30 }) then ev = "submit" end
    return ev
end
return Kp
