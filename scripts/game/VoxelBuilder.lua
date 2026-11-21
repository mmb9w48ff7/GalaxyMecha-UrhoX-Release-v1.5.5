-- VoxelBuilder.lua
-- 把 voxeldata/models/*.lua 中贪婪合并后的四边形展开为 CustomGeometry。
-- 每种颜色一个子几何体 + 一个 PBR 纯色材质（只使用文档允许的 Technique）。
-- 四边形编码：face, p, u0, v0, u1, v1
--   face = 轴 * 2 + 方向（0 正 / 1 负）；u = (轴+1)%3，v = (轴+2)%3
--   p 为该面所在平面坐标，u0..u1 / v0..v1 为体素单位下的矩形范围

local VoxelBuilder = { verbose = false }

local TECH_PBR = "Techniques/PBR/PBRNoTexture.xml"
local TECH_UNLIT = "Techniques/NoTextureUnlit.xml"

local modelCache_ = {}
local materialCache_ = {}
local stats_ = { models = 0, quads = 0, vertices = 0 }

local NORMALS = {
    { 1, 0, 0 }, { -1, 0, 0 },
    { 0, 1, 0 }, { 0, -1, 0 },
    { 0, 0, 1 }, { 0, 0, -1 },
}
-- 两个三角形的角点（u 取 0/1 端，v 取 0/1 端）
local CORNERS = { { 0, 0 }, { 1, 0 }, { 1, 1 }, { 0, 0 }, { 1, 1 }, { 0, 1 } }

function VoxelBuilder.LoadData(id)
    local data = modelCache_[id]
    if not data then
        local ok, result = pcall(require, "voxeldata.models." .. id)
        if not ok then
            print("[VoxelBuilder] 模型数据加载失败: " .. tostring(id) .. " " .. tostring(result))
            return nil
        end
        data = result
        modelCache_[id] = data
        if VoxelBuilder.verbose then print(string.format("[VoxelBuilder] 载入模型 %s（%d 个合并面）", id, data.quadCount)) end
    end
    return data
end

local function MaterialKey(c, metallic, roughness, emissive, unlit)
    return string.format("%.3f_%.3f_%.3f_%.2f_%.2f_%.2f_%s", c[1], c[2], c[3], metallic, roughness, emissive, unlit and "u" or "l")
end

-- 色彩校正（实机对比：UrhoX 的 PBR 光照比网页版着色器发灰，中央 3D 区域饱和度低约 25-45%）：
--  1. 金属度只取 25%：网页版里金属度只让漫反射变暗 45%，而 UrhoX PBR 里金属没有漫反射、只反射灰色的环境光，会整片发灰；粗糙度不低于 0.5，避免环境高光糊成灰白。
--  2. 反照率饱和度按 SAT 提升（默认 1.3，设置里可调 1.0 / 1.3 / 1.6，实时生效）：补偿网页版 ACES 色调映射在暗部拉开通道比例带来的更艳的效果。
--  3. 不受光的发光材质按“最大通道不超过 1”缩放亮度（原来固定乘 1.6 会把青色削成发白）。
local SAT = 1.3
local matInfo_ = setmetatable({}, { __mode = "k" })
local function boost(c, k)
    local g = 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
    local r, gg, b = g + (c[1] - g) * k, g + (c[2] - g) * k, g + (c[3] - g) * k
    return { math.max(0, math.min(1, r)), math.max(0, math.min(1, gg)), math.max(0, math.min(1, b)) }
end
local FX_SAT = 1.35
local function apply(mat, info)
    local c = info.noBoost and info.color or boost(info.color, SAT)
    if info.fx then                                                             -- v1.4.4：特效颜色先归一再提饱和度（白芯保持白色，彩色更艳）
        local m = math.max(info.color[1], info.color[2], info.color[3], 1e-4); c = boost({ info.color[1] / m, info.color[2] / m, info.color[3] / m }, FX_SAT)
    end
    if info.halo then                                                           -- 外层光晕：叠加混合，亮度按辉光设置
        local k = info.halo; mat:SetShaderParameter("MatDiffColor", Variant(Color(c[1] * k, c[2] * k, c[3] * k, 1.0))); return
    end
    if info.unlit then
        local mx = math.max(c[1], c[2], c[3], 1e-4); local k = math.min(info.glow or 1, 1 / mx)
        mat:SetShaderParameter("MatDiffColor", Variant(Color(c[1] * k, c[2] * k, c[3] * k, 1.0)))
    else
        mat:SetShaderParameter("MatDiffColor", Variant(Color(c[1], c[2], c[3], 1.0)))
        if info.emissive and info.emissive > 0 then                            -- v1.4.9：自发光最大通道不超过 0.85（原来 x1.6~3 后三个通道都被截成白色）
            local em = math.min(info.emissive, 0.85 / math.max(c[1], c[2], c[3], 1e-4))
            mat:SetShaderParameter("MatEmissiveColor", Variant(Color(c[1] * em, c[2] * em, c[3] * em)))
        end
    end
end
function VoxelBuilder.SetSaturation(k)
    if not k or k == SAT then return end
    SAT = k; for mat, info in pairs(matInfo_) do apply(mat, info) end
end
function VoxelBuilder.GetMaterial(color, metallic, roughness, emissive, unlit, opt)
    opt = opt or {}
    local key = MaterialKey(color, metallic or 0, roughness or 0.7, emissive or 0, unlit) .. (opt.noBoost and "|nb" or "") .. (opt.glow and ("|g" .. opt.glow) or "") .. (opt.fx and "|fx" or "") .. (opt.halo and ("|h" .. opt.halo) or "")
    local mat = materialCache_[key]
    if mat then return mat end
    mat = Material:new()
    if opt.halo then mat:SetTechnique(0, VoxelBuilder.AddTechnique())
    elseif unlit then mat:SetTechnique(0, cache:GetResource("Technique", TECH_UNLIT))
    else
        mat:SetTechnique(0, cache:GetResource("Technique", TECH_PBR))
        mat:SetShaderParameter("Metallic", Variant((metallic or 0.0) * 0.25))
        mat:SetShaderParameter("Roughness", Variant(math.max(0.5, roughness or 0.7)))
    end
    local info = { color = color, unlit = unlit, emissive = emissive, noBoost = opt.noBoost, glow = opt.glow, fx = opt.fx, halo = opt.halo }
    matInfo_[mat] = info; apply(mat, info)
    -- 体素面不依赖绕序：关闭背面剔除，法线由数据直接给出
    mat:SetCullMode(CULL_NONE)
    materialCache_[key] = mat
    return mat
end

-- 在 parent 下创建一个节点并生成体素网格，返回节点
-- 叠加混合（光晕）用的技术：引擎里找不到时返回 nil，渲染器会跳过光晕
local addTech_ = nil
function VoxelBuilder.AddTechnique()
    if addTech_ == nil then
        addTech_ = false
        for _, n in ipairs({ "Techniques/NoTextureAdd.xml", "Techniques/NoTextureUnlitAdd.xml", "Techniques/DiffAdd.xml" }) do local t = cache:GetResource("Technique", n); if t then addTech_ = t; break end end
    end
    return addTech_ or nil
end
function VoxelBuilder.Build(parent, id, nodeName, tint, opt_)
    local data = VoxelBuilder.LoadData(id)
    local node = parent:CreateChild(nodeName or id)
    if not data then
        return node
    end
    local sc = data.scale
    local ox, oy, oz = data.origin[1], data.origin[2], data.origin[3]
    local geom = node:CreateComponent("CustomGeometry")
    geom:SetNumGeometries(#data.mats)
    local pos = { 0, 0, 0 }
    local vertexCount = 0
    for gi, mt in ipairs(data.mats) do
        geom:BeginGeometry(gi - 1, TRIANGLE_LIST)
        local q = mt.quads
        for k = 1, #q, 6 do
            local face, p = q[k], q[k + 1]
            local uu = { q[k + 2], q[k + 4] }
            local vv = { q[k + 3], q[k + 5] }
            local axis = face // 2
            local n = NORMALS[face + 1]
            local normal = Vector3(n[1], n[2], n[3])
            for c = 1, 6 do
                local cu, cv = uu[CORNERS[c][1] + 1], vv[CORNERS[c][2] + 1]
                if axis == 0 then
                    pos[1], pos[2], pos[3] = p, cu, cv
                elseif axis == 1 then
                    pos[1], pos[2], pos[3] = cv, p, cu
                else
                    pos[1], pos[2], pos[3] = cu, cv, p
                end
                geom:DefineVertex(Vector3((pos[1] - ox) * sc, (pos[2] - oy) * sc, (pos[3] - oz) * sc))
                geom:DefineNormal(normal)
            end
            vertexCount = vertexCount + 6
        end
    end
    geom:Commit()
    for gi, mt in ipairs(data.mats) do
        -- 网页版着色器：emissive < -1.5 = 不受光（亮度 0.8）；< -0.5 = 不受光（亮度 1.6）；其余按 PBR 受光；tint 整体替换颜色
        local em, col = mt.emissive or 0, tint or mt.color
        if opt_ and opt_.halo then geom:SetMaterial(gi - 1, VoxelBuilder.GetMaterial(col, 0, 1, 0, true, { halo = opt_.halo, fx = true }))
        elseif em < -0.5 then geom:SetMaterial(gi - 1, VoxelBuilder.GetMaterial(col, 0, 1, 0, true, { glow = (em < -1.5) and 0.8 or 1.6, noBoost = tint ~= nil }))
        elseif em > 0 and id:sub(1, 3) == "fx_" then
            -- v1.4.3：特效模型（弹道、激光、火花、拖尾）用“不受光 + 最大通道为 1”的发光材质。
            -- 原来走 PBR + 自发光（颜色 x 1.6~3.5），在 UrhoX 的 LDR 输出里三个通道都被截到 1，青色 / 红色弹道全变成白色。
            geom:SetMaterial(gi - 1, VoxelBuilder.GetMaterial(col, 0, 1, 0, true, { glow = math.max(1, em), noBoost = tint ~= nil, fx = true }))
        else geom:SetMaterial(gi - 1, VoxelBuilder.GetMaterial(col, mt.metallic, mt.roughness, em, false, { noBoost = tint ~= nil })) end
    end
    geom.castShadows = not (opt_ and opt_.halo)
    stats_.models = stats_.models + 1
    stats_.quads = stats_.quads + data.quadCount
    stats_.vertices = stats_.vertices + vertexCount
    return node
end

-- 星空：每颗星是一个不受光照的小立方体，按 3 种颜色分组。
-- def.zoneMask：星点只受“无雾区域”影响（网页版着色器在算雾之前就输出星点；UrhoX 的不受光材质也会被雾盖住，
-- 战斗场景 420 米处雾已全浓，而星点在 3000 米外，不单独处理就完全看不见）。
-- def.glow：亮度系数（网页版星点 = 颜色 x0.8（线性），约等于 gamma 空间 x0.9，低于辉光阈值，转动镜头时不会闪）。
local function trySet(obj, prop, setter, v)
    if pcall(function() obj[setter](obj, v) end) then return true end
    return pcall(function() obj[prop] = v end)
end
VoxelBuilder.TrySet = trySet
function VoxelBuilder.BuildStars(parent, def)
    local node = parent:CreateChild("Stars")
    local geom = node:CreateComponent("CustomGeometry")
    local colors = def.colors
    geom:SetNumGeometries(#colors)
    local d = def.data
    for ci = 1, #colors do
        geom:BeginGeometry(ci - 1, TRIANGLE_LIST)
        for i = 1, #d, 5 do
            if d[i + 4] == ci - 1 then
                local cx, cy, cz, hs = d[i], d[i + 1], d[i + 2], d[i + 3] * 0.5
                for f = 0, 5 do
                    local axis = f // 2
                    local sg = (f % 2 == 0) and 1 or -1
                    for c = 1, 6 do
                        local a = sg * hs
                        local b = CORNERS[c][1] == 1 and hs or -hs
                        local e = CORNERS[c][2] == 1 and hs or -hs
                        local x, y, z
                        if axis == 0 then x, y, z = a, b, e
                        elseif axis == 1 then x, y, z = e, a, b
                        else x, y, z = b, e, a end
                        geom:DefineVertex(Vector3(cx + x, cy + y, cz + z))
                        geom:DefineNormal(Vector3(0, 1, 0))
                    end
                end
            end
        end
    end
    geom:Commit()
    for ci, c in ipairs(colors) do
        geom:SetMaterial(ci - 1, VoxelBuilder.GetMaterial(c, 0, 1, 0, true, { glow = def.glow or 0.9, noBoost = true }))
    end
    geom.castShadows = false
    if def.zoneMask then trySet(geom, "zoneMask", "SetZoneMask", def.zoneMask) end
    return node
end

-- 模型包围球半径（米，未乘节点缩放）
function VoxelBuilder.Radius(id)
    local d = VoxelBuilder.LoadData(id)
    if not d then return 1 end
    local s = d.size
    return 0.5 * math.sqrt(s[1] * s[1] + s[2] * s[2] + s[3] * s[3]) * d.scale
end

-- 实例化：每个模型只在 protoRoot 下生成一次网格，之后用 Node:Clone() 复制，
-- 避免小行星带几十个同款岩石在 Lua 里反复展开顶点。
local protos_ = {}
function VoxelBuilder.Instance(protoRoot, parent, id)
    local key = tostring(protoRoot) .. ":" .. id
    local proto = protos_[key]
    if not proto then
        proto = VoxelBuilder.Build(protoRoot, id, "proto_" .. id)
        proto:SetDeepEnabled(false)
        protos_[key] = proto
    end
    local node = proto:Clone()
    node:SetParent(parent)
    node:SetDeepEnabled(true)
    return node
end

function VoxelBuilder.GetStats()
    return stats_
end

return VoxelBuilder
