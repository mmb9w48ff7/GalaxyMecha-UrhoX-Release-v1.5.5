-- Util.lua：向量 / 角度 / 随机工具（角度制，与网页版约定一致：pitch 正 = 机头向下，yaw 正 = 转向 +X）
local U = {}
U.DEG = math.pi / 180
function U.clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
function U.lerp(a, b, t) return a + (b - a) * t end
function U.rand(a, b) return a + math.random() * (b - a) end
function U.pick(t) return t[math.random(1, #t)] end
function U.wrap(a) return ((a % 360) + 540) % 360 - 180 end
function U.ease(c, g, k, dt) return c + (g - c) * (1 - math.exp(-k * dt)) end
function U.len3(x, y, z) return math.sqrt(x * x + y * y + z * z) end
function U.dist2(a, b) local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z; return dx * dx + dy * dy + dz * dz end
function U.norm(x, y, z) local l = math.sqrt(x * x + y * y + z * z); if l < 1e-6 then return 0, 0, 1 end return x / l, y / l, z / l end
-- 由方向向量求 yaw / pitch（度）
function U.angOf(x, y, z) local l = math.sqrt(x * x + y * y + z * z); if l < 1e-6 then return 0, 0 end return math.atan(x, z) / U.DEG, -math.asin(U.clamp(y / l, -1, 1)) / U.DEG end
function U.fwdOf(yaw, pitch) local cy, sy, cp, sp = math.cos(yaw * U.DEG), math.sin(yaw * U.DEG), math.cos(pitch * U.DEG), math.sin(pitch * U.DEG); return sy * cp, -sp, cy * cp end
function U.hex(h) h = h:gsub("#", ""); return { tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255 } end
function U.fmtTime(t) t = math.max(0, math.floor(t)); return string.format("%02d:%02d", t // 60, t % 60) end
function U.copy(t) local o = {}; for k, v in pairs(t) do o[k] = v end return o end
-- 简易确定性随机（按字符串种子，用于每日规则等）
function U.seeded(str)
    local h = 2166136261
    for i = 1, #str do h = (h ~ str:byte(i)) * 16777619 % 4294967296 end
    return function() h = (h * 1664525 + 1013904223) % 4294967296; return h / 4294967296 end
end
return U
