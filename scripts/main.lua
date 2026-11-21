-- main.lua：宇宙银河机甲（体素 Q 版机甲割草）—— UrhoX / TapTap 嵌入式容器入口
-- 玩法逻辑与数据由网页版源码自动转换而来（tools/build_xpile.py -> scripts/jsrt/CosmicData.lua、CosmicRun.lua），
-- 运行库 jsrt/JS.lua 提供 JavaScript 语义；引擎接口 jsrt/Engine.lua + Renderer.lua；界面 cosmic/GameUI.lua（战斗）与 Hub.lua（机库）。
local App = require("cosmic.GameApp")
local errCount_ = 0
function Start() App.Start() end
function Stop() App.Stop() end
-- 每帧都在 pcall 里执行：脚本出错时记录日志、保存存档并回到机库，不会闪退
function HandleUpdate(eventType, eventData)
    local ok, err = pcall(App.Update, eventData["TimeStep"]:GetFloat())
    if not ok then errCount_ = errCount_ + 1; if errCount_ <= 3 then print("[错误] Update: " .. tostring(err)) end; App.OnError(err) end
end
function HandleNanoVGRender(eventType, eventData)
    local ok, err = pcall(App.Render)
    if not ok then errCount_ = errCount_ + 1; if errCount_ <= 3 then print("[错误] Render: " .. tostring(err)) end; App.OnError(err) end
end
