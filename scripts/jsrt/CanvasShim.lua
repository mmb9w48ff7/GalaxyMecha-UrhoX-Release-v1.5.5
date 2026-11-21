-- CanvasShim.lua：用 NanoVG 实现网页版 drawOverlay 用到的 Canvas 2D 接口（setTransform / save / restore / translate / rotate /
-- beginPath / moveTo / lineTo / arc / stroke / fill / fillRect / fillText / strokeText / measureText，以及 font / fillStyle / strokeStyle /
-- lineWidth / globalAlpha / textAlign / textBaseline 属性）。这样 cosmic_run.js 里的 2D 叠加层（伤害数字、锁定框、预警、屏幕外箭头、摇杆圈等）
-- 无需改写，转换后直接在 UrhoX 里绘制。
local Canvas = {}
local function parseColor(c, alphaMul)
    alphaMul = alphaMul or 1
    if type(c) ~= "string" then return nvgRGBA(255, 255, 255, math.floor(255 * alphaMul)) end
    local r, g, b, a = c:match("^rgba%(%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*%)")
    if r then return nvgRGBA(math.floor(tonumber(r)), math.floor(tonumber(g)), math.floor(tonumber(b)), math.floor(255 * tonumber(a) * alphaMul)) end
    r, g, b = c:match("^rgb%(%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*%)")
    if r then return nvgRGBA(math.floor(tonumber(r)), math.floor(tonumber(g)), math.floor(tonumber(b)), math.floor(255 * alphaMul)) end
    local h = c:match("^#(%x+)$")
    if h then
        if #h == 3 then h = h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2) end
        return nvgRGBA(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16), math.floor(255 * alphaMul))
    end
    return nvgRGBA(255, 255, 255, math.floor(255 * alphaMul))
end
Canvas.parseColor = parseColor
-- vg：NanoVG 上下文；fontFace：已创建的字体名
function Canvas.New(vg, fontFace)
    local ctx = { font = "", fillStyle = "#000000", strokeStyle = "#000000", lineWidth = 1, globalAlpha = 1, textAlign = "start", textBaseline = "alphabetic" }
    local function prepText()
        local size = tonumber(ctx.font:match("([%d%.]+)px")) or 14
        nvgFontFace(vg, fontFace); nvgFontSize(vg, size)
        local ha = ctx.textAlign == "center" and NVG_ALIGN_CENTER or (ctx.textAlign == "right" and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT)
        local va = ctx.textBaseline == "middle" and NVG_ALIGN_MIDDLE or (ctx.textBaseline == "top" and NVG_ALIGN_TOP or (NVG_ALIGN_BASELINE or NVG_ALIGN_MIDDLE))
        nvgTextAlign(vg, ha + va)
        return size
    end
    function ctx.setTransform() end
    function ctx.clearRect() end
    function ctx.save() nvgSave(vg) end
    function ctx.restore() nvgRestore(vg) end
    function ctx.translate(_, x, y) nvgTranslate(vg, x, y) end
    function ctx.rotate(_, a) nvgRotate(vg, a) end
    function ctx.beginPath() nvgBeginPath(vg) end
    function ctx.moveTo(_, x, y) nvgMoveTo(vg, x, y) end
    function ctx.lineTo(_, x, y) nvgLineTo(vg, x, y) end
    function ctx.arc(_, x, y, r, a0, a1) nvgArc(vg, x, y, r, a0, a1, NVG_CW or 2) end
    function ctx.stroke() nvgStrokeColor(vg, parseColor(ctx.strokeStyle, ctx.globalAlpha)); nvgStrokeWidth(vg, ctx.lineWidth); nvgStroke(vg) end
    function ctx.fill() nvgFillColor(vg, parseColor(ctx.fillStyle, ctx.globalAlpha)); nvgFill(vg) end
    function ctx.fillRect(_, x, y, w, h) nvgBeginPath(vg); nvgRect(vg, x, y, w, h); nvgFillColor(vg, parseColor(ctx.fillStyle, ctx.globalAlpha)); nvgFill(vg) end
    function ctx.fillText(_, text, x, y) prepText(); nvgFillColor(vg, parseColor(ctx.fillStyle, ctx.globalAlpha)); nvgText(vg, x, y, tostring(text)) end
    function ctx.strokeText(_, text, x, y)             -- 描边：在 8 个方向偏移绘制描边色文字
        prepText(); local r = (ctx.lineWidth or 1) / 2; nvgFillColor(vg, parseColor(ctx.strokeStyle, ctx.globalAlpha)); text = tostring(text)
        for k = 0, 7 do local a = k * math.pi / 4; nvgText(vg, x + math.cos(a) * r, y + math.sin(a) * r, text) end
    end
    function ctx.measureText(_, text)
        local size = prepText(); local w = 0
        for _, c in utf8.codes(tostring(text)) do w = w + (c > 255 and size or size * 0.56) end
        return { width = w }
    end
    return ctx
end
return Canvas
