-- Redeem.lua：兑换码与开发者解锁码的校验与发放。
-- 码 = 9 字节载荷（类型 1 + 数额 3 + 编号 3 + 有效期 2）+ 6 字节 HMAC-SHA256 签名，Crockford Base32 编码（24 字符，4 组 x 6）。
-- 私钥只在作者手里（tools/author_secret.txt，由 tools/gen_codes.py 生成码）；游戏里的密钥是混淆存放的，足以防止普通玩家伪造，
-- 但离线游戏无法做到绝对安全（有人反编译脚本就能取出密钥）。每个码每台设备只能兑换一次；开发者码绑定设备码，只对作者自己的设备有效。
local JS = require("jsrt.JS")
local Sha = require("cosmic.Sha256")
local Key = require("cosmic.RedeemKey")
local R = { fails = 0, lockUntil = 0 }
local KIND = { credits = 1, src = 2, dev = 15 }
local EPOCH_DAYS = 20454            -- 2026-01-01 距 1970-01-01 的天数
local function now() return os.time() end
-- 设备码：首次使用时随机生成并存进存档（8 位 Base32，显示成 XXXX-XXXX）
function R.DeviceId(C)
    local s = C.save
    if not s.did or #s.did ~= 8 then
        math.randomseed(os.time() + math.floor(os.clock() * 1e6)); local t = {}
        for i = 1, 8 do local v = math.random(1, 32); t[i] = Sha.ALPHA:sub(v, v) end
        s.did = table.concat(t); C:write()
    end
    return s.did
end
function R.FormatDid(d) return d:sub(1, 4) .. "-" .. d:sub(5, 8) end
local function eq(a, b) if #a ~= #b then return false end local d = 0; for i = 1, #a do d = d | (a:byte(i) ~ b:byte(i)) end return d == 0 end
-- 返回 info（{ kind, amount, id, exp }）或 nil, 错误信息
function R.Verify(code, did)
    local raw = Sha.b32dec(code or ""); if not raw or #raw ~= 15 then return nil, "兑换码格式不对（应为 24 位字母数字）" end
    local payload, sig = raw:sub(1, 9), raw:sub(10, 15)
    local kind = payload:byte(1); local amount = string.unpack(">I3", payload, 2); local id = string.unpack(">I3", payload, 5); local exp = string.unpack(">I2", payload, 8)
    local extra = ""
    if kind == KIND.dev then extra = did or "" end
    local expect = Sha.hmac(Key.key(), payload .. extra):sub(1, 6)
    if not eq(sig, expect) then return nil, "无效的兑换码" end
    if kind == KIND.dev then
        local h = Sha.sha256(did); if string.unpack(">I3", h, 1) ~= id then return nil, "这个开发者码不属于本设备" end
    else
        if Key.revoked[id] then return nil, "该兑换码已作废" end
        if exp > 0 and (math.floor(now() / 86400) - EPOCH_DAYS) > exp then return nil, "该兑换码已过期" end
    end
    return { kind = kind, amount = amount, id = id, exp = exp }
end
local function guard()
    if now() < R.lockUntil then return false, "尝试次数过多，请 " .. (R.lockUntil - now()) .. " 秒后再试" end
    return true
end
local function fail(msg) R.fails = R.fails + 1; if R.fails >= 5 then R.lockUntil = now() + 60; R.fails = 0 end return false, msg end
-- 兑换：成功返回 true, 描述；失败返回 false, 原因
function R.Redeem(C, text)
    local ok, why = guard(); if not ok then return false, why end
    local info, err = R.Verify(text, R.DeviceId(C)); if not info then return fail(err) end
    if info.kind == KIND.dev then return false, "这是开发者解锁码，请在 设置 -> 点版本号 7 次 里输入" end
    local s = C.save; s.redeemed = s.redeemed or JS.dict(); local k = tostring(info.id)
    if s.redeemed[k] then return false, "该兑换码在本设备已经使用过" end
    local msg
    if info.kind == KIND.credits then s.credits = s.credits + info.amount; msg = "信用点 +" .. info.amount
    elseif info.kind == KIND.src then s.src = s.src + info.amount; msg = "星源 +" .. info.amount
    else return fail("无法识别的兑换码类型") end
    s.redeemed[k] = 1; R.fails = 0; C:write(); return true, msg
end
-- 开发者模式
local Dev = { on = false }
R.Dev = Dev
function Dev.Check(C)            -- 启动时调用：存档里的开发者码必须仍然校验通过（改存档解锁无效）
    Dev.on = false
    local c = C.save.devCode; if not c then return false end
    local info = R.Verify(c, R.DeviceId(C)); Dev.on = (info ~= nil and info.kind == KIND.dev); if not Dev.on then C.save.devCode = nil end
    return Dev.on
end
function Dev.Unlock(C, text)
    local ok, why = guard(); if not ok then return false, why end
    local info, err = R.Verify(text, R.DeviceId(C)); if not info then return fail(err) end
    if info.kind ~= KIND.dev then return false, "这不是开发者解锁码" end
    C.save.devCode = text; Dev.on = true; R.fails = 0; C:write(); return true, "开发者模式已解锁"
end
function Dev.Lock(C) C.save.devCode = nil; Dev.on = false; C:write() end
return R
