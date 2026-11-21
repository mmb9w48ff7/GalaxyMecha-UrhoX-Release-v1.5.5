-- Engine.lua：网页版 engine.js 的接口（E.m4 / m4mul / trs / project / getMesh / buildStars / render）的 Lua 实现。
-- 矩阵与网页版一致：16 个元素的列主序、0 起始数组（与转换后的 Lua 战斗代码共用同一数组约定）。
local JS = require("jsrt.JS")
local AMT = JS.AMT
local E = { DEG = math.pi / 180 }
local DEG = E.DEG
local sin, cos, tan, sqrt = math.sin, math.cos, math.tan, math.sqrt
-- Float32Array 语义：每次写入都舍入到单精度（网页版的矩阵是 Float32Array，枪口位置由它算出，会影响战斗结果）
local pack, unpack = string.pack, string.unpack
local function f32(x) return (unpack("<f", pack("<f", x))) end
local F32 = {}
F32.__index = function(t, k) if k == "length" then return 16 end return rawget(t, "d")[k] end
F32.__newindex = function(t, k, v) rawget(t, "d")[k] = f32(v) end
local function arr16()
    local d = {}; for i = 0, 15 do d[i] = 0.0 end
    return setmetatable({ d = d }, F32)
end
E.F32 = F32; E.f32 = f32
function E.m4(_) local m = arr16(); local d = m.d; d[0], d[5], d[10], d[15] = 1.0, 1.0, 1.0, 1.0; return m end
function E.m4mul(_, a, b)
    local o = arr16(); local od, ad, bd = o.d, a.d or a, b.d or b
    for c = 0, 3 do for r = 0, 3 do
        od[c * 4 + r] = f32(ad[r] * bd[c * 4] + ad[4 + r] * bd[c * 4 + 1] + ad[8 + r] * bd[c * 4 + 2] + ad[12 + r] * bd[c * 4 + 3])
    end end
    return o
end
-- T * Ry(yaw) * Rx(pitch) * Rz(roll) * S（与 UrhoX 的 Quaternion(pitch, yaw, roll) 一致）
function E.trs(_, p, yaw, pitch, roll, s)
    local cy, sy, cx, sx, cz, sz = cos(yaw * DEG), sin(yaw * DEG), cos(pitch * DEG), sin(pitch * DEG), cos(roll * DEG), sin(roll * DEG)
    local r00, r01, r02 = cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx
    local r10, r11, r12 = cx * sz, cx * cz, -sx
    local r20, r21, r22 = -sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx
    local m = arr16(); local d = m.d
    d[0], d[1], d[2] = f32(r00 * s), f32(r10 * s), f32(r20 * s)
    d[4], d[5], d[6] = f32(r01 * s), f32(r11 * s), f32(r21 * s)
    d[8], d[9], d[10] = f32(r02 * s), f32(r12 * s), f32(r22 * s)
    d[12], d[13], d[14], d[15] = f32(p[0]), f32(p[1]), f32(p[2]), 1.0
    return m
end
local function v3sub(a, b) return { [0] = a[0] - b[0], a[1] - b[1], a[2] - b[2] } end
local function v3norm(a) local l = sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]); if l < 1e-9 then return { [0] = 0, 0, 1 } end return { [0] = a[0] / l, a[1] / l, a[2] / l } end
local function v3cross(a, b) return { [0] = a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0] } end
local function v3dot(a, b) return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] end
function E.perspLH(fovY, aspect, n, f)
    local m = arr16(); local ys = 1 / tan(fovY / 2)
    m[0] = ys / aspect; m[5] = ys; m[10] = (f + n) / (f - n); m[11] = 1; m[14] = -2 * f * n / (f - n); return m
end
function E.lookAtLH(eye, target, up)
    local z = v3norm(v3sub(target, eye)); local x = v3norm(v3cross(up, z)); local y = v3cross(z, x); local m = arr16()
    m[0], m[4], m[8], m[12] = x[0], x[1], x[2], -v3dot(x, eye)
    m[1], m[5], m[9], m[13] = y[0], y[1], y[2], -v3dot(y, eye)
    m[2], m[6], m[10], m[14] = z[0], z[1], z[2], -v3dot(z, eye)
    m[15] = 1; return m
end
function E.project(_, VP, p, w, h)
    local V = VP.d or VP
    local x = V[0] * p[0] + V[4] * p[1] + V[8] * p[2] + V[12]
    local y = V[1] * p[0] + V[5] * p[1] + V[9] * p[2] + V[13]
    local ww = V[3] * p[0] + V[7] * p[1] + V[11] * p[2] + V[15]
    if ww <= 0.01 then return nil end
    return setmetatable({ [0] = (x / ww * 0.5 + 0.5) * w, (1 - (y / ww * 0.5 + 0.5)) * h, ww, length = 3 }, AMT)
end
-- 模型是否存在：由宿主注入 E.hasModel(id)
E.hasModel = function(id) return true end
local meshes = {}
function E.getMesh(_, id)
    local m = meshes[id]; if m then return m end
    if not E.hasModel(id) then return nil end
    m = { id = id }
    local info = E.modelInfo and E.modelInfo(id)        -- { size = {x,y,z}, scale = s }：与网页版 mesh.radius / mesh.height 一致
    if info then local sz, sc = info.size, info.scale; m.radius = 0.5 * math.sqrt(sz[1] * sz[1] + sz[2] * sz[2] + sz[3] * sz[3]) * sc; m.height = sz[2] * sc end
    meshes[id] = m; return m
end
function E.buildStars(_, st) return { stars = st } end
local DUM = {}; setmetatable(DUM, { __index = function() return DUM end, __call = function() return DUM end, __newindex = function() end })
E.canvas = DUM
E.lastFrame = nil
-- 渲染：计算 VP（返回给战斗代码用于投影），并把整帧交给后端（Urho 渲染器 / 测试里的空实现）
function E.render(_, f)
    local P = E.perspLH(f.fov * DEG, f.aspect, f.near or 0.1, f.far or 800)
    local V = E.lookAtLH(f.eye, f.target, f.up or { [0] = 0, 1, 0 })
    local VP = E.m4mul(nil, P, V)
    E.lastFrame = f
    if E.backend then E.backend(f, VP) end
    return VP
end
function E.setBloomPasses(_, n) end
return E
