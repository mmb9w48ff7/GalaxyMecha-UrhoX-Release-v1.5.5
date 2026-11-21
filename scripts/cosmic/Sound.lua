-- Sound.lua：音效与背景音乐（.ogg）。
-- 注意（UrhoX 构建规则）：增强引用模式只能追踪“完整路径字面量”，所以这里把每个音频路径都写成完整字符串，不用拼接。
-- .ogg 属于 DWP 媒体资源：首次读取可能先得到静音占位，下载完成后自动热替换，所以不能把“读不到”永久缓存成失败。
local Sound = { enabled = true, music = true }
local nodes_, bgm_ = nil, nil
local cache_, tries_, last_ = {}, {}, {}
local PATH = {
    sfx_shoot = "Sounds/sfx_shoot.ogg", sfx_pop = "Sounds/sfx_pop.ogg", sfx_boom = "Sounds/sfx_boom.ogg", sfx_pick = "Sounds/sfx_pick.ogg", sfx_hurt = "Sounds/sfx_hurt.ogg",
    sfx_level = "Sounds/sfx_level.ogg", sfx_skill = "Sounds/sfx_skill.ogg", sfx_warp = "Sounds/sfx_warp.ogg", sfx_gate = "Sounds/sfx_gate.ogg", sfx_boss = "Sounds/sfx_boss.ogg",
    sfx_win = "Sounds/sfx_win.ogg", sfx_click = "Sounds/sfx_click.ogg", sfx_dash = "Sounds/sfx_dash.ogg", sfx_nitro = "Sounds/sfx_nitro.ogg", sfx_hit = "Sounds/sfx_hit.ogg", sfx_crit = "Sounds/sfx_crit.ogg",
    bgm_hub = "Sounds/bgm_hub.ogg", bgm_battle = "Sounds/bgm_battle.ogg", bgm_boss = "Sounds/bgm_boss.ogg",
}
local GAP = { shoot = 0.09, pop = 0.05, hit = 0.07, crit = 0.1, hurt = 0.15, boom = 0.08, pick = 0.06 }
local VOL = { nitro = 0.75, hit = 0.8, crit = 0.9, shoot = 0.8 }
function Sound.Init(scene) nodes_ = scene:CreateChild("Audio") end
local function get(key)
    local s = cache_[key]; if s then return s end
    tries_[key] = (tries_[key] or 0) + 1
    if tries_[key] > 1 and tries_[key] % 60 ~= 0 then return nil end      -- 读不到时每 60 次再试一次，避免每帧都查
    local path = PATH[key]; if not path then return nil end
    local ok, res = pcall(function() return cache:GetResource("Sound", path) end)
    if ok and res then cache_[key] = res; return res end
    return nil
end
function Sound.Sfx(name, now)
    if not Sound.enabled or not nodes_ then return end
    if GAP[name] and last_[name] and now - last_[name] < GAP[name] then return end
    last_[name] = now
    local snd = get("sfx_" .. name); if not snd then return end
    local src = nodes_:CreateComponent("SoundSource")
    src.soundType = SOUND_EFFECT; src.gain = VOL[name] or 1; src.autoRemoveMode = REMOVE_COMPONENT; src:Play(snd)
end
local want_ = nil
function Sound.Music(name)
    want_ = name
    if not nodes_ then return end
    if bgm_ then bgm_:Stop(); bgm_:Remove(); bgm_ = nil end
    if not Sound.music or not name then return end
    local snd = get("bgm_" .. name); if not snd then return end
    snd.looped = true
    bgm_ = nodes_:CreateComponent("SoundSource"); bgm_.soundType = SOUND_MUSIC; bgm_.gain = 0.7; bgm_:Play(snd)
end
-- 每帧调用：背景音乐因下载未完成而没播起来时，重试
function Sound.Tick() if want_ and Sound.music and not bgm_ and nodes_ then Sound.Music(want_) end end
return Sound
