-- JS.lua：JavaScript 语义运行库（供 xpile/transpile.js 生成的 Lua 使用）
-- 约定：函数第一个参数是 _this；数组是 0 起始的表，带 length 字段与 AMT 元表；undefined / null 都是 nil。
local JS = {}
local floor, huge, fmt, concat = math.floor, math.huge, string.format, table.concat
local mtype = math.type

-- ---------------------------------------------------------------- 基础语义
local function T(x) return x ~= nil and x ~= false and x ~= 0 and x ~= "" and x == x end
JS.T = T
function JS.OR(a, b) if T(a) then return a end return b end
function JS.AND(a, b) if not T(a) then return a end return b end
function JS.typeof(x)
    local t = type(x)
    if t == "nil" then return "undefined" elseif t == "table" or t == "userdata" then return "object" end
    return t
end
function JS.tonum(x)
    local t = type(x)
    if t == "number" then return x elseif t == "string" then x = x:match("^%s*(.-)%s*$"); if x == "" then return 0 end return tonumber(x) or (0 / 0)
    elseif t == "boolean" then return x and 1 or 0 elseif t == "nil" then return 0 / 0 end
    return 0 / 0
end
function JS.mod(a, b)
    if b == 0 or a ~= a or b ~= b or a == huge or a == -huge then return 0 / 0 end
    if b == huge or b == -huge then return a end
    return math.fmod(a, b)
end
-- 数字转字符串（与 JS 一致：整数不带 .0）
local function numstr(x)
    if x ~= x then return "NaN" elseif x == huge then return "Infinity" elseif x == -huge then return "-Infinity" end
    if x == floor(x) and x > -1e21 and x < 1e21 then return fmt("%.0f", x) end
    local s = fmt("%.15g", x); if tonumber(s) ~= x then s = fmt("%.16g", x); if tonumber(s) ~= x then s = fmt("%.17g", x) end end
    s = s:gsub("e([+-])0*(%d+)", "e%1%2")
    return s
end
local function S(x)
    local t = type(x)
    if t == "string" then return x elseif t == "number" then return numstr(x) elseif t == "nil" then return "undefined" elseif t == "boolean" then return x and "true" or "false" end
    if t == "table" then
        if getmetatable(x) == JS.AMT then local p = {}; for i = 0, x.length - 1 do local v = x[i]; p[#p + 1] = (v == nil) and "" or S(v) end return concat(p, ",") end
        return "[object Object]"
    end
    return tostring(x)
end
JS.S = S; JS.numstr = numstr
function JS.len(x)
    local t = type(x)
    if t == "table" then return x.length or 0 elseif t == "string" then return utf8.len(x) or #x end
    return 0
end
function JS.setlen(a, n) local old = a.length or 0; for i = n, old - 1 do a[i] = nil end; rawset(a, "length", n) end
function JS.callk(o, k, ...) return o[k](o, ...) end
-- 有序对象：键按插入顺序枚举（JS 的 Object.keys / for-in 行为）；只给“空对象字面量 {}”、模块级常量表和 JSON 解析出的对象使用
local ORD = setmetatable({}, { __mode = "k" })
local ODMT = { __newindex = function(t, k, v) rawset(t, k, v); local o = ORD[t]; o[#o + 1] = k end }
function JS.dict() local t = setmetatable({}, ODMT); ORD[t] = {}; return t end
function JS.odict(t, keys) ORD[t] = keys; return setmetatable(t, ODMT) end
function JS.keys(o)
    local out = {}
    if type(o) ~= "table" then return out end
    if getmetatable(o) == JS.AMT then for i = 0, (o.length or 0) - 1 do out[#out + 1] = tostring(i) end return out end
    local ord = ORD[o]
    if ord then
        local seen, rev = {}, {}
        for i = #ord, 1, -1 do local k = ord[i]; if not seen[k] and o[k] ~= nil then seen[k] = true; rev[#rev + 1] = k end end
        for i = #rev, 1, -1 do out[#out + 1] = rev[i] end
        return out
    end
    local nums, strs = {}, {}
    for k in pairs(o) do if type(k) == "number" then nums[#nums + 1] = k elseif k ~= "length" or o.length ~= nil then strs[#strs + 1] = k end end
    table.sort(nums); table.sort(strs)
    for _, k in ipairs(nums) do out[#out + 1] = k end; for _, k in ipairs(strs) do out[#out + 1] = k end
    return out
end

-- ---------------------------------------------------------------- 位运算（32 位）
local function toi32(x)
    if type(x) ~= "number" then x = JS.tonum(x) end
    if x ~= x or x == huge or x == -huge then return 0 end
    x = x >= 0 and floor(x) or -floor(-x); x = x % 4294967296; if x >= 2147483648 then x = x - 4294967296 end
    return math.tointeger(x) or x
end
JS.toi32 = toi32
function JS.bor(a, b) return toi32(toi32(a) | toi32(b)) end
function JS.band(a, b) return toi32(toi32(a) & toi32(b)) end
function JS.bxor(a, b) return toi32(toi32(a) ~ toi32(b)) end
function JS.shl(a, n) return toi32(toi32(a) << (toi32(n) & 31)) end
function JS.shr(a, n) return toi32(a) // (1 << (toi32(n) & 31)) end
function JS.ushr(a, n) return (toi32(a) & 0xFFFFFFFF) >> (toi32(n) & 31) end

-- ---------------------------------------------------------------- Math
JS.Math_abs = math.abs
function JS.Math_min(...) local n = select("#", ...); local r = huge; for i = 1, n do local v = select(i, ...); if v ~= v then return v end if v < r then r = v end end return r end
function JS.Math_max(...) local n = select("#", ...); local r = -huge; for i = 1, n do local v = select(i, ...); if v ~= v then return v end if v > r then r = v end end return r end
function JS.Math_floor(x) if x ~= x or x == huge or x == -huge then return x end return floor(x) end
function JS.Math_ceil(x) if x ~= x or x == huge or x == -huge then return x end return math.ceil(x) end
function JS.Math_round(x) if x ~= x or x == huge or x == -huge then return x end return floor(x + 0.5) end
function JS.Math_sqrt(x) if x < 0 then return 0 / 0 end return math.sqrt(x) end
JS.Math_sin, JS.Math_cos, JS.Math_tan, JS.Math_exp = math.sin, math.cos, math.tan, math.exp
function JS.Math_asin(x) if x > 1 or x < -1 then return 0 / 0 end return math.asin(x) end
JS.Math_atan2 = function(y, x) return math.atan(y, x) end
function JS.Math_hypot(...) local s = 0; for i = 1, select("#", ...) do local v = select(i, ...); s = s + v * v end return math.sqrt(s) end
function JS.Math_pow(a, b) return a ^ b end
function JS.Math_imul(a, b) return toi32(toi32(a) * toi32(b)) end
function JS.Math_sign(x) if x > 0 then return 1 elseif x < 0 then return -1 end return x end
JS.rng = nil                                   -- 测试时可替换为确定性随机数
function JS.Math_random() local r = JS.rng; if r then return r() end return math.random() end

-- ---------------------------------------------------------------- 数组
local AMT = {}; JS.AMT = AMT
local AM = {}
AMT.__index = AM
AMT.__newindex = function(t, k, v) rawset(t, k, v); if type(k) == "number" and k >= t.length then rawset(t, "length", k + 1) end end
local function newarr(n) return setmetatable({ length = n or 0 }, AMT) end
JS.newarr = newarr
function AM.push(a, ...)
    local n = select("#", ...); local len = a.length
    for i = 1, n do rawset(a, len + i - 1, (select(i, ...))) end
    rawset(a, "length", len + n); return len + n
end
function AM.pop(a) local len = a.length; if len == 0 then return nil end local v = a[len - 1]; rawset(a, len - 1, nil); rawset(a, "length", len - 1); return v end
function AM.shift(a) local len = a.length; if len == 0 then return nil end local v = a[0]; for i = 1, len - 1 do rawset(a, i - 1, a[i]) end rawset(a, len - 1, nil); rawset(a, "length", len - 1); return v end
function AM.unshift(a, ...) local n = select("#", ...); local len = a.length; for i = len - 1, 0, -1 do rawset(a, i + n, a[i]) end for i = 1, n do rawset(a, i - 1, (select(i, ...))) end rawset(a, "length", len + n); return len + n end
function AM.indexOf(a, v) for i = 0, a.length - 1 do if a[i] == v then return i end end return -1 end
function AM.includes(a, v) return AM.indexOf(a, v) >= 0 end
function AM.forEach(a, f) for i = 0, a.length - 1 do f(nil, a[i], i, a) end end
function AM.map(a, f) local r = newarr(a.length); for i = 0, a.length - 1 do rawset(r, i, f(nil, a[i], i, a)) end return r end
function AM.filter(a, f) local r = newarr(0); local n = 0; for i = 0, a.length - 1 do local v = a[i]; if T(f(nil, v, i, a)) then rawset(r, n, v); n = n + 1 end end rawset(r, "length", n); return r end
function AM.some(a, f) for i = 0, a.length - 1 do if T(f(nil, a[i], i, a)) then return true end end return false end
function AM.every(a, f) for i = 0, a.length - 1 do if not T(f(nil, a[i], i, a)) then return false end end return true end
function AM.find(a, f) for i = 0, a.length - 1 do if T(f(nil, a[i], i, a)) then return a[i] end end return nil end
function AM.reduce(a, f, init) local acc, s = init, 0; if acc == nil then acc = a[0]; s = 1 end for i = s, a.length - 1 do acc = f(nil, acc, a[i], i, a) end return acc end
function AM.join(a, sep) sep = sep == nil and "," or sep; local p = {}; for i = 0, a.length - 1 do local v = a[i]; p[#p + 1] = v == nil and "" or S(v) end return concat(p, sep) end
function AM.reverse(a) local n = a.length; for i = 0, floor(n / 2) - 1 do a[i], a[n - 1 - i] = a[n - 1 - i], a[i] end return a end
function AM.concat(a, ...)
    local r = newarr(0); local n = 0
    for i = 0, a.length - 1 do rawset(r, n, a[i]); n = n + 1 end
    for k = 1, select("#", ...) do local b = select(k, ...); if type(b) == "table" and getmetatable(b) == AMT then for i = 0, b.length - 1 do rawset(r, n, b[i]); n = n + 1 end else rawset(r, n, b); n = n + 1 end end
    rawset(r, "length", n); return r
end
function AM.slice(a, s, e)
    local len = a.length; s = s or 0; e = e == nil and len or e
    if s < 0 then s = math.max(0, len + s) end; if e < 0 then e = math.max(0, len + e) end; if e > len then e = len end
    local r = newarr(0); local n = 0
    for i = s, e - 1 do rawset(r, n, a[i]); n = n + 1 end
    rawset(r, "length", n); return r
end
function AM.splice(a, start, del, ...)
    local len = a.length; if start < 0 then start = math.max(0, len + start) end; if start > len then start = len end
    if del == nil then del = len - start end; del = math.max(0, math.min(del, len - start))
    local ins = select("#", ...); local removed = newarr(0)
    for i = 0, del - 1 do rawset(removed, i, a[start + i]) end; rawset(removed, "length", del)
    local tail = {}; for i = start + del, len - 1 do tail[#tail + 1] = a[i] end
    for i = start, len - 1 do rawset(a, i, nil) end
    for i = 1, ins do rawset(a, start + i - 1, (select(i, ...))) end
    for i, v in ipairs(tail) do rawset(a, start + ins + i - 1, v) end
    rawset(a, "length", start + ins + #tail); return removed
end
-- 稳定排序（与 V8 一致）
local function msort(t, lo, hi, cmp, tmp)
    if hi - lo < 1 then return end
    local mid = (lo + hi) // 2; msort(t, lo, mid, cmp, tmp); msort(t, mid + 1, hi, cmp, tmp)
    local i, j, k = lo, mid + 1, lo
    while i <= mid and j <= hi do if cmp(t[j], t[i]) < 0 then tmp[k] = t[j]; j = j + 1 else tmp[k] = t[i]; i = i + 1 end k = k + 1 end
    while i <= mid do tmp[k] = t[i]; i = i + 1; k = k + 1 end
    while j <= hi do tmp[k] = t[j]; j = j + 1; k = k + 1 end
    for x = lo, hi do t[x] = tmp[x] end
end
function AM.sort(a, f)
    local n = a.length; local t = {}; for i = 0, n - 1 do t[i + 1] = a[i] end
    local cmp = f and function(x, y) local r = f(nil, x, y); return (r ~= r) and 0 or r end or function(x, y) local sx, sy = S(x), S(y); return sx < sy and -1 or (sx > sy and 1 or 0) end
    msort(t, 1, n, cmp, {}); for i = 1, n do rawset(a, i - 1, t[i]) end return a
end

-- ---------------------------------------------------------------- 字符串 / 数字方法
local SM = {}
function SM.indexOf(s, sub, from) local i = s:find(sub, (from or 0) + 1, true); return i and i - 1 or -1 end
function SM.lastIndexOf(s, sub) local last = -1; local i = 0; while true do local p = s:find(sub, i + 1, true); if not p then break end last = p - 1; i = p end return last end
function SM.charAt(s, i) return s:sub(i + 1, i + 1) end
function SM.charCodeAt(s, i) return s:byte(i + 1) or (0 / 0) end
function SM.substr(s, st, len) if st < 0 then st = math.max(0, #s + st) end return len == nil and s:sub(st + 1) or s:sub(st + 1, st + len) end
function SM.substring(s, a, b) b = b == nil and #s or b; if a > b then a, b = b, a end return s:sub(math.max(0, a) + 1, b) end
function SM.slice(s, a, b) local n = #s; a = a or 0; b = b == nil and n or b; if a < 0 then a = math.max(0, n + a) end; if b < 0 then b = math.max(0, n + b) end return s:sub(a + 1, b) end
function SM.trim(s) return (s:match("^%s*(.-)%s*$")) end
function SM.toUpperCase(s) return s:upper() end
function SM.toLowerCase(s) return s:lower() end
function SM.replace(s, a, b) local i, j = s:find(a, 1, true); if not i then return s end return s:sub(1, i - 1) .. (type(b) == "function" and S(b(nil, a)) or b) .. s:sub(j + 1) end
function SM.split(s, sep) local r = newarr(0); local n = 0; if sep == "" then for _, c in utf8.codes(s) do rawset(r, n, utf8.char(c)); n = n + 1 end rawset(r, "length", n) return r end
    local pos = 1; while true do local i, j = s:find(sep, pos, true); if not i then rawset(r, n, s:sub(pos)); n = n + 1; break end rawset(r, n, s:sub(pos, i - 1)); n = n + 1; pos = j + 1 end rawset(r, "length", n); return r end
function SM.padStart(s, n, p) p = p or " "; while #s < n do s = p .. s end return s end
function SM.toString(s) return s end
local smeta = getmetatable("")
smeta.__index = function(s, k) if type(k) == "number" then if k < 0 or k >= #s then return nil end return s:sub(k + 1, k + 1) end local f = SM[k]; if f then return f end local g = string[k]; if g then return g end if k == "length" then return utf8.len(s) or #s end return nil end
smeta.__add = function(a, b) return S(a) .. S(b) end          -- JS：字符串 + 任意值 = 字符串连接
local NM = {}
function NM.toFixed(x, d) d = d or 0; if x ~= x then return "NaN" end if x == 0 then x = 0.0 end; return fmt("%." .. d .. "f", x) end
function NM.toString(x, base) if base and base ~= 10 then local digits = "0123456789abcdefghijklmnopqrstuvwxyz"; local n, s = floor(x), ""; if n == 0 then return "0" end while n > 0 do local d = n % base; s = digits:sub(d + 1, d + 1) .. s; n = n // base end return s end return numstr(x) end
function NM.toLocaleString(x) local s = numstr(floor(x * 1000 + 0.5) / 1000); local ip, fp = s:match("^(-?%d+)(%.?%d*)$"); if not ip then return s end ip = ip:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""):gsub("^%-,", "-"); return ip .. fp end
debug.setmetatable(0, { __index = NM })
-- JS 里布尔值参与算术时 true = 1、false = 0
local function bn(x) if x == true then return 1 elseif x == false then return 0 end return x end
debug.setmetatable(true, {
    __add = function(a, b) return bn(a) + bn(b) end, __sub = function(a, b) return bn(a) - bn(b) end, __mul = function(a, b) return bn(a) * bn(b) end,
    __div = function(a, b) return bn(a) / bn(b) end, __mod = function(a, b) return JS.mod(bn(a), bn(b)) end, __unm = function(a) return -bn(a) end,
    __lt = function(a, b) return bn(a) < bn(b) end, __le = function(a, b) return bn(a) <= bn(b) end, __concat = function(a, b) return S(a) .. S(b) end,
})
-- JS 里 undefined 参与比较 / 算术不会报错：比较为 false，算术为 NaN（这里用 nil 的元表模拟）
local NAN = 0 / 0
debug.setmetatable(nil, {
    __lt = function() return false end, __le = function() return false end,
    __add = function() return NAN end, __sub = function() return NAN end, __mul = function() return NAN end, __div = function() return NAN end,
    __mod = function() return NAN end, __unm = function() return NAN end, __pow = function() return NAN end,
    __concat = function(a, b) return S(a) .. S(b) end,
})

-- ---------------------------------------------------------------- JSON
local function jsonEnc(v, out)
    local t = type(v)
    if t == "nil" then out[#out + 1] = "null" elseif t == "boolean" then out[#out + 1] = v and "true" or "false"
    elseif t == "number" then out[#out + 1] = (v ~= v or v == huge or v == -huge) and "null" or numstr(v)
    elseif t == "string" then out[#out + 1] = '"' .. v:gsub('[%c"\\]', function(c) local m = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }; return m[c] or fmt("\\u%04x", c:byte()) end) .. '"'
    elseif t == "table" then
        if getmetatable(v) == AMT then out[#out + 1] = "["; for i = 0, v.length - 1 do if i > 0 then out[#out + 1] = "," end jsonEnc(v[i], out) end out[#out + 1] = "]"
        else out[#out + 1] = "{"; local first = true; for _, k in ipairs(JS.keys(v)) do local x = v[k]; if x ~= nil and type(x) ~= "function" then if not first then out[#out + 1] = "," end first = false; jsonEnc(tostring(k), out); out[#out + 1] = ":"; jsonEnc(x, out) end end out[#out + 1] = "}" end
    else out[#out + 1] = "null" end
end
local function jsonDec(s)
    local pos = 1
    local function ws() pos = s:find("%S", pos) or #s + 1 end
    local val
    local function str()
        local out = {}; pos = pos + 1
        while true do
            local c = s:sub(pos, pos)
            if c == '"' then pos = pos + 1; break elseif c == "\\" then local n = s:sub(pos + 1, pos + 1)
                if n == "u" then out[#out + 1] = utf8.char(tonumber(s:sub(pos + 2, pos + 5), 16)); pos = pos + 6 else local m = { n = "\n", r = "\r", t = "\t", b = "\b", f = "\f" }; out[#out + 1] = m[n] or n; pos = pos + 2 end
            elseif c == "" then error("JSON 字符串未结束") else out[#out + 1] = c; pos = pos + 1 end
        end
        return concat(out)
    end
    function val()
        ws(); local c = s:sub(pos, pos)
        if c == "{" then local o = JS.dict(); pos = pos + 1; ws(); if s:sub(pos, pos) == "}" then pos = pos + 1; return o end
            while true do ws(); local k = str(); ws(); pos = pos + 1; o[k] = val(); ws(); local d = s:sub(pos, pos); pos = pos + 1; if d == "}" then break end end return o
        elseif c == "[" then local a = newarr(0); local n = 0; pos = pos + 1; ws(); if s:sub(pos, pos) == "]" then pos = pos + 1; return a end
            while true do rawset(a, n, val()); n = n + 1; ws(); local d = s:sub(pos, pos); pos = pos + 1; if d == "]" then break end end rawset(a, "length", n); return a
        elseif c == '"' then return str()
        elseif s:sub(pos, pos + 3) == "true" then pos = pos + 4; return true elseif s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false elseif s:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
        else local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos); if not num or num == "" then error("JSON 解析错误 @" .. pos) end pos = pos + #num; return tonumber(num) end
    end
    return val()
end

-- ---------------------------------------------------------------- 全局对象 G
local G = {}; JS.G = G
G.Math = setmetatable({ PI = math.pi }, { __index = function(_, k) local f = JS["Math_" .. k]; if f then return function(_, ...) return f(...) end end end })
G.JSON = { stringify = function(_, v) local o = {}; jsonEnc(v, o); return concat(o) end, parse = function(_, s) return jsonDec(s) end }
G.Object = {
    keys = function(_, o) local k = JS.keys(o); local a = newarr(#k); for i, v in ipairs(k) do rawset(a, i - 1, tostring(v)) end return a end,
    assign = function(_, t, ...) for i = 1, select("#", ...) do local s = select(i, ...); if type(s) == "table" then for k, v in pairs(s) do t[k] = v end end end return t end,
    values = function(_, o) local a = newarr(0); local n = 0; for _, k in ipairs(JS.keys(o)) do rawset(a, n, o[k]); n = n + 1 end rawset(a, "length", n); return a end,
}
G.Array = { isArray = function(_, v) return type(v) == "table" and getmetatable(v) == AMT end }
G.String = setmetatable({}, { __call = function(_, _t, x) return S(x) end })
G.Number = setmetatable({ isInteger = function(_, x) return type(x) == "number" and x == floor(x) end }, { __call = function(_, _t, x) return JS.tonum(x) end })
G.Boolean = setmetatable({}, { __call = function(_, _t, x) return T(x) end })
G.parseInt = function(_, s, radix) if type(s) == "number" then return s >= 0 and floor(s) or -floor(-s) end s = S(s):match("^%s*(.*)$"); local sign = 1; if s:sub(1, 1) == "-" then sign = -1; s = s:sub(2) elseif s:sub(1, 1) == "+" then s = s:sub(2) end
    local v; if radix == 16 or (not radix and s:match("^0[xX]")) then v = tonumber(s:gsub("^0[xX]", ""):match("^%x+") or "", 16) else v = tonumber(s:match("^%d+") or "") end return v and sign * v or (0 / 0) end
G.parseFloat = function(_, s) local v = tonumber(S(s):match("^%s*(-?%d+%.?%d*[eE]?[+-]?%d*)") or ""); return v or (0 / 0) end
G.isNaN = function(_, x) x = JS.tonum(x); return x ~= x end
G.isFinite = function(_, x) x = JS.tonum(x); return x == x and x ~= huge and x ~= -huge end
G.Error = function(_, msg) return tostring(msg) end
-- Date（只实现用到的部分）
local DM = {}
DM.__index = DM
local function mkdate(t) return setmetatable({ t = t }, DM) end
function DM.getFullYear(d) return tonumber(os.date("%Y", d.t)) end
function DM.getMonth(d) return tonumber(os.date("%m", d.t)) - 1 end
function DM.getDate(d) return tonumber(os.date("%d", d.t)) end
function DM.getTime(d) return d.t * 1000 end
function DM.setDate(d, n) local y, m = tonumber(os.date("%Y", d.t)), tonumber(os.date("%m", d.t)); d.t = os.time({ year = y, month = m, day = n, hour = 12 }); return d.t * 1000 end
G.new_Date = function(a) if a == nil then return mkdate(os.time()) end return mkdate(floor(a / 1000)) end
G.Date = { now = function() return floor(os.time() * 1000) end }
G.new_Uint8Array = function(n) local a = newarr(n); for i = 0, n - 1 do rawset(a, i, 0) end return a end
return JS
