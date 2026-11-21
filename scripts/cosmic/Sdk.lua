-- Sdk.lua：TapTap 嵌入式容器 SDK 封装（见 UrhoX 文档 recipes/sdk.md）。非嵌入环境 / 编辑器里 sdk 为 nil，自动降级。
local Sdk = {}
local function has() return type(sdk) == "table" or type(sdk) == "userdata" end
-- 激励视频：只有 result.success 为 true 才发奖励；不可用时返回 false（不发奖励，也不弹模拟广告）
function Sdk.ShowRewardAd(cb)
    if not has() or not sdk.ShowRewardVideoAd then cb({ success = false, msg = "unsupported platform" }); return end
    sdk:ShowRewardVideoAd(function(result) cb(result or { success = false, msg = "no result" }) end)
end
function Sdk.AdAvailable() return has() and sdk.ShowRewardVideoAd ~= nil end
-- 宿主退出按钮区域（归一化 0~1）；UI 要避开
local exit_
function Sdk.ExitRect()
    if exit_ == nil then
        exit_ = false
        if has() and sdk.GetNativeExitMenuRect then local ok, r = pcall(function() return sdk:GetNativeExitMenuRect() end); if ok and r then exit_ = r end end
    end
    return exit_ or nil
end
return Sdk
