-- Host.lua：把转换后的网页版模块（CosmicData / CosmicRun）装配成可运行的整体，并提供它们依赖的宿主接口。
local JS = require("jsrt.JS")
local E = require("jsrt.Engine")
local Host = {}
-- 空 DOM：任何属性 / 方法访问都返回自己，赋值被忽略（网页版里的界面代码在这里变成空操作，由 NanoVG 界面接管）
local D = {}
setmetatable(D, { __index = function() return D end, __call = function() return D end, __newindex = function() end })
Host.DOM = D
-- 把 Lua 列表（1 起始）递归转成 JS 数组（0 起始）
local function jsify(v)
    if type(v) ~= "table" then return v end
    if v[1] ~= nil then local a = JS.newarr(#v); for i = 1, #v do rawset(a, i - 1, jsify(v[i])) end return a end
    local o = {}; for k, x in pairs(v) do o[k] = jsify(x) end return o
end
Host.jsify = jsify
local function b64enc(s) local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; return ((s:gsub(".", function(x) local r, byte = "", x:byte(); for i = 8, 1, -1 do r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0") end return r end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x) if #x < 6 then return "" end local c = 0; for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end return b:sub(c + 1, c + 1) end) .. ({ "", "==", "=" })[#s % 3 + 1]) end
local function b64dec(s) local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; s = s:gsub("[^" .. b .. "=]", ""); return (s:gsub(".", function(x) if x == "=" then return "" end local r, f = "", (b:find(x, 1, true) - 1); for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end return r end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x) if #x ~= 8 then return "" end local c = 0; for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end return string.char(c) end)) end
-- 创建宿主环境。opts：{ store = 存档表, rigs = Rigs 表, models = 模型是否存在的函数 }
function Host.New(opts)
    opts = opts or {}
    local store = opts.store or {}
    local timers, now = {}, 0
    local HOST = { window = {}, document = opts.document or D, exitRect = opts.exitRect, navigator = D, console = { log = function() end }, performance = { now = function() return now * 1000 end } }
    HOST.localStorage = { getItem = function(_, k) return store[k] end, setItem = function(_, k, v) store[k] = v; if opts.onSave then opts.onSave(k, v) end end, removeItem = function(_, k) store[k] = nil end }
    HOST.setTimeout = function(_, fn, ms) timers[#timers + 1] = { at = now + (ms or 0) / 1000, fn = fn }; return #timers end
    HOST.setInterval = function(_, fn, ms) return 0 end
    HOST.clearTimeout = function() end
    HOST.requestAnimationFrame = function() end
    HOST.btoa = function(_, s) return b64enc(s) end; HOST.atob = function(_, s) return b64dec(s) end
    HOST.encodeURIComponent = function(_, s) return (s:gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", c:byte()) end)) end
    HOST.decodeURIComponent = function(_, s) return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)) end
    HOST.escape = function(_, s) return s end; HOST.unescape = function(_, s) return s end
    local win = HOST.window
    win.__h = {}
    win.addEventListener = function(_, name, fn) win.__h[name] = win.__h[name] or {}; table.insert(win.__h[name], fn) end; win.removeEventListener = function() end
    win.VoxEngine = E; win.VOX_MODELS = {}
    if opts.rigs then for id, r in pairs(opts.rigs) do local parts = r.parts; local rig = {}; for k, v in pairs(r) do if k ~= "parts" then rig[k] = v end end
        win.VOX_MODELS[id] = { rig = jsify(rig), parts = jsify(parts) } end end
    local VB = require("game.VoxelBuilder")
    E.hasModel = opts.models or function(id) return VB.LoadData(id) ~= nil end
    E.modelInfo = function(id) local d = VB.LoadData(id); if not d then return nil end return { size = d.size, scale = d.scale } end
    function HOST.advance(dt) now = now + dt; local i = 1; while i <= #timers do local t = timers[i]; if t.at <= now then table.remove(timers, i); t.fn(nil) else i = i + 1 end end end
    -- 网页版 boot.js 提供给战斗 / 机库的 api
    local view = { w = 1920, h = 1080, s = 1, safe = { [0] = 0, 0, 0, 0 }, dpr = 1 }
    local mode = "cosmic-hub"
    local A = {
        save = function() return win.Cosmic.save end, writeSave = function() win.Cosmic:write() end,
        toast = function(_, msg) if HOST.onToast then HOST.onToast(msg) end end, iconSVG = function() return "" end, catIcon = function() return "" end, resIcon = function() return "" end,
        byId = function(_, list, id) for i = 0, list.length - 1 do if list[i].id == id then return list[i] end end return nil end,
        fitFov = function(_, fov, aspect) local a = 1920 / 1080; if aspect >= a then return fov end return 2 * math.atan(math.tan(fov * E.DEG / 2) * a / aspect) / E.DEG end,
        view = function() return view end, mode = function() return mode end, setMode = function(_, m) mode = m end, showTitle = function() end, applyQuality = function() end, isMobile = true,
    }
    HOST.A = A; HOST.view = view
    return HOST
end
-- 加载数据 + 战斗模块，返回 { HOST, C, run(CosmicRun), S(战斗模块作用域) }
function Host.Load(opts)
    local HOST = Host.New(opts)
    local dataMod = require("jsrt.CosmicData")(HOST)          -- 设置 window.Cosmic
    HOST.window.Cosmic = dataMod.C
    dataMod.C:load()
    -- 网页版里用浏览器 API 实现的音频与广告，在这里由宿主提供（默认空实现；正式游戏会接入 Sound / Sdk）
    local C = dataMod.C
    C.sfx = function(_, name) if HOST.onSfx then HOST.onSfx(name) end end
    C.unlockAudio = function() end
    C.audioStat = function() return {} end
    C.music = { play = function(_, name) if HOST.onMusic then HOST.onMusic(name) end end, stop = function() if HOST.onMusic then HOST.onMusic(nil) end end, refresh = function() end }
    C.showAd = function(_, reason, cb) if HOST.onAd then HOST.onAd(reason, cb) else cb(nil, { success = false, msg = "unsupported platform" }) end end
    local runMod = require(opts.runModule or "jsrt.CosmicRun")(HOST)
    local api = HOST.window.CosmicRun
    api:init(HOST.A)
    return { HOST = HOST, C = dataMod.C, data = dataMod, run = api, S = runMod, A = HOST.A, E = E }
end
return Host
