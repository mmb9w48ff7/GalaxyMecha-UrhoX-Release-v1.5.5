-- GameApp.lua：应用入口逻辑。装配 UrhoX 场景 / NanoVG / 渲染后端，加载由网页版转换来的数据与战斗模块，驱动 机库 <-> 战斗。
local JS = require("jsrt.JS")
local Host = require("jsrt.Host")
local E = require("jsrt.Engine")
local Renderer = require("jsrt.Renderer")
local Canvas = require("jsrt.CanvasShim")
local UI = require("cosmic.UI")
local GameUI = require("cosmic.GameUI")
local Hub = require("cosmic.Hub")
local Snd = require("cosmic.Sound")
local Sdk = require("cosmic.Sdk")
local App = { t = 0, errN = 0 }
local SAVE_FILE, SAVE_KEY = "cosmic_mecha_save_v8.json", "galaxy-mecha-save-v8"
local vg_, scene_, H, S, C, ctx_, canvasObj_, lastMusic_
local function readSave()
    if fileSystem and fileSystem:FileExists(SAVE_FILE) then local f = File(SAVE_FILE, FILE_READ); if f:IsOpen() then local t = f:ReadString(); f:Close(); return t end end
    return nil
end
local function writeSave(v) local f = File(SAVE_FILE, FILE_WRITE); if f:IsOpen() then f:WriteString(v); f:Close() end end
local function jsarr(n, ...) local a = JS.newarr(0); local args = { ... }; for i = 1, n do rawset(a, i - 1, args[i]) end rawset(a, "length", n); return a end

function App.Start()
    print("=== 宇宙银河机甲 Start（网页版转换内核）===")
    SubscribeToEvent("Update", "HandleUpdate"); SubscribeToEvent("NanoVGRender", "HandleNanoVGRender")
    math.randomseed(os.time())
    scene_ = Scene(); scene_:CreateComponent("Octree")
    local zn = scene_:CreateChild("Zone"); local zone = zn:CreateComponent("Zone"); zone.boundingBox = BoundingBox(Vector3(-20000, -20000, -20000), Vector3(20000, 20000, 20000)); zone.fogStart = 5000; zone.fogEnd = 9000
    -- 星空专用的无雾区域：网页版星点在算雾之前直接输出；UrhoX 的雾对不受光材质同样生效（战斗 420 米处全浓，星点在 3000 米外会被完全盖住）。
    -- 区域掩码：主区域 = 1，星空区域 = 2（优先级更低）。普通物体两个区域都匹配，取优先级高的主区域；星点只匹配星空区域，所以不受雾。
    local VB = require("game.VoxelBuilder")
    VB.TrySet(zone, "zoneMask", "SetZoneMask", 1)
    local szn = scene_:CreateChild("StarZone"); local starZone = szn:CreateComponent("Zone"); starZone.boundingBox = BoundingBox(Vector3(-20000, -20000, -20000), Vector3(20000, 20000, 20000))
    starZone.fogStart = 8000; starZone.fogEnd = 9000; VB.TrySet(starZone, "priority", "SetPriority", -1); VB.TrySet(starZone, "zoneMask", "SetZoneMask", Renderer.STAR_ZONE_MASK)
    local keyNode = scene_:CreateChild("Key"); local keyLight = keyNode:CreateComponent("Light"); keyLight.lightType = LIGHT_DIRECTIONAL; keyLight.castShadows = false
    local fillNode = scene_:CreateChild("Fill"); local fillLight = fillNode:CreateComponent("Light"); fillLight.lightType = LIGHT_DIRECTIONAL; fillLight.castShadows = false
    local camNode = scene_:CreateChild("Camera"); local camera = camNode:CreateComponent("Camera"); camera.nearClip = 0.3; camera.farClip = 9000; camera.fov = 64
    local vp = Viewport:new(scene_, camera); local rp = vp:GetRenderPath()
    local tone = false
    do local f = fileSystem and fileSystem:FileExists(SAVE_FILE) and File(SAVE_FILE, FILE_READ); if f and f:IsOpen() then local t = f:ReadString(); f:Close(); tone = t and t:find('"tone":true', 1, true) ~= nil end end
    if tone then renderer.HDRRendering = true end                                       -- 实验：HDR + 色调映射（设置里开启，重启生效）
    rp:Append(cache:GetResource("XMLFile", "PostProcess/Bloom.xml"))
    if tone then rp:Append(cache:GetResource("XMLFile", "PostProcess/Tonemap.xml")); rp:SetShaderParameter("TonemapExposureBias", Variant(1.05)); rp:SetShaderParameter("TonemapMaxWhite", Variant(1.0)) end
    rp:Append(cache:GetResource("XMLFile", "PostProcess/FXAA3.xml")); renderer:SetViewport(0, vp)
    Renderer.Init({ scene = scene_, camNode = camNode, camera = camera, zone = zone, starZone = starZone, keyNode = keyNode, keyLight = keyLight, fillNode = fillNode, fillLight = fillLight, renderPath = rp })
    E.backend = Renderer.Frame
    Snd.Init(scene_)
    vg_ = nvgCreate(1); UI.Init(vg_)
    ctx_ = Canvas.New(vg_, "sans"); canvasObj_ = { getContext = function() return ctx_ end, width = 1920, height = 1080 }
    -- 网页版的 #warp（进入星门的跃迁遮罩）与 #hitflash（受击闪光）是 DOM 层；这里返回能记录 classList / style.opacity 的元素，由 GameUI.DrawFx 用 NanoVG 画出
    local document = setmetatable({ getElementById = function(_, id) if id == "hud2d" then return canvasObj_ end return GameUI.FxEl(id) or Host.DOM end }, { __index = function() return Host.DOM end })
    local store = {}; store[SAVE_KEY] = readSave()
    H = Host.Load({ rigs = require("voxeldata.Rigs"), store = store, document = document, exitRect = Sdk.ExitRect(), onSave = function(_, v) writeSave(v) end })
    S, C = H.S, H.C
    H.HOST.onSfx = function(name) Snd.Sfx(name, App.t) end
    H.HOST.onMusic = function(name) Snd.Music(name) end
    H.HOST.onAd = function(reason, cb) Sdk.ShowRewardAd(function(res) cb(nil, res) end) end
    H.HOST.onMusicRefresh = function() end
    GameUI.Install(S, C, H.HOST)
    GameUI.onHome = function() App.EnterHub() end
    Hub.Init(C, H.HOST)
    Hub.onStart = function(ch, opt) App.StartRun(ch, opt) end
    App.EnterHub()
end
function App.EnterHub()
    H.A:setMode("cosmic-hub"); GameUI.Reset(); S.paused = false; Hub.modal = nil; Hub.results = nil
    local st = C.save.settings; Snd.enabled, Snd.music = st.sound, st.music; Snd.Music("hub")
end
function App.StartRun(ch, opt)
    GameUI.Reset()
    local o = {}; for k, v in pairs(opt or {}) do o[k] = v end
    if o.mods then local m = JS.newarr(0); for i = 0, o.mods.length - 1 do m:push(o.mods[i]) end; o.mods = m end
    H.run:start(ch, o)
end
function App.Get() return H, S, C end
function App.Stop() if C then C:write() end end
function App.OnError(err)
    App.errN = App.errN + 1
    if App.errN == 1 or App.errN % 120 == 0 then pcall(function() C:write() end); if H and H.A:mode() == "cosmic-run" then S.R = nil; App.EnterHub(); GameUI.Toast("出现异常，已返回机库") end end
end
-- 暗角：网页版合成着色器 c *= 1 - dot(d, d) * 0.55（d 为到屏幕中心的归一化偏移，角落约暗 27%）
function App.Vignette(w, h)
    if not (nvgRadialGradient and nvgFillPaint) then return end
    local R = math.sqrt(w * w + h * h) / 2
    local paint = nvgRadialGradient(vg_, w / 2, h / 2, R * 0.38, R, nvgRGBA(0, 0, 0, 0), nvgRGBA(0, 0, 10, 60))
    nvgBeginPath(vg_); nvgRect(vg_, 0, 0, w, h); nvgFillPaint(vg_, paint); nvgFill(vg_)
end
local function updateView()
    local w, h = graphics:GetWidth(), graphics:GetHeight(); local v = H.HOST.view; v.w, v.h, v.s, v.dpr = w, h, h / 1080, 1
    return w, h
end
function App.Update(dt)
    dt = math.min(dt, 0.05); App.t = App.t + dt
    local w, h = updateView(); H.HOST.advance(dt); GameUI.Update(dt); Snd.Tick()
    local st = C.save.settings
    if st.music ~= lastMusic_ then lastMusic_ = st.music; Snd.music = st.music; Snd.enabled = st.sound; Snd.Music(H.A:mode() == "cosmic-run" and "battle" or "hub") end
    require("game.VoxelBuilder").SetSaturation(({ std = 1.15, vivid = 1.5, more = 1.8 })[st.sat or "vivid"] or 1.5)      -- v1.4.4：整体饱和度提高（原 1.0 / 1.3 / 1.6）
    Snd.enabled = st.sound; Renderer.glow = ({ low = 0.6, mid = 1.0, high = 1.5 })[st.glow or "mid"] or 1.0
    local D = require("cosmic.DevUI"); D.fps = D.fps * 0.9 + (1 / math.max(dt, 0.001)) * 0.1
    if H.A:mode() == "cosmic-run" and S.R then
        local sp = D.On() and D.speed or 1                                     -- 开发者模式：战斗速度倍率
        if sp >= 2 then for _ = 1, sp do S:step(dt) end else S:step(dt * sp) end
        S:render()
    else E:render(Hub.Scene(E, jsarr, w / h, dt)) end
end
function App.Render()
    local w, h = updateView()
    UI.BeginFrame(w, h); nvgBeginFrame(vg_, w, h, 1.0)
    App.Vignette(w, h)
    if H.A:mode() == "cosmic-run" and S.R then
        S:drawOverlay()
        GameUI.DrawFx(w, h)                                                      -- 受击闪光 / 跃迁遮罩：在 3D 标记之上、HUD 之下（与网页版层级一致）
        UI.Frame("edge"); GameUI.DrawHud(); UI.EndFrame()                    -- HUD 贴真实屏幕边缘
        UI.Frame("center"); GameUI.DrawModals(); UI.EndFrame()               -- 弹窗放在居中的 1920 内容区
        GameUI.Input(w, h, h / 1080)
    else
        UI.Frame("center"); Hub.Draw(); GameUI.DrawToast(); UI.EndFrame()
    end
    nvgEndFrame(vg_)
end
return App
