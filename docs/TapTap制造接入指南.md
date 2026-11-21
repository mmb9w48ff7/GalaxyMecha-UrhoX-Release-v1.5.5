# 接入 TapTap 制造（UrhoX 嵌入式容器）指南

> 依据：你提供的《UrhoX 引擎文档》（SDK、资源构建引用、DWP、文件存储等章节）。文档里**没有**写“提审 / 发布 / 上架”的具体流程，那部分请以 TapTap 制造平台后台与客服的说明为准。

## 一、工程结构（本发布包已按文档要求整理）
```
UrhoX_Release/
├── .project/resources.json   构建引用 / 预下载策略（见下）
├── .project/settings.json    asset_dirs = ["../assets", "../scripts"]
├── scripts/main.lua          入口（Start / Stop / HandleUpdate / HandleNanoVGRender）
├── scripts/cosmic/*.lua      游戏逻辑
├── scripts/game/VoxelBuilder.lua  体素网格构建
├── scripts/voxeldata/        体素模型数据（Lua）与机甲挂点 Rigs.lua
├── assets/Sounds/*.ogg       音效与 BGM（资源路径 Sounds/xxx.ogg）
├── store/                    图标、截图、宣传片
└── docs/                     本指南、提审清单、隐私 / 协议模板、一致性对照
```

## 二、资源构建引用（重要）
- 文档规定：`groups` 里有独立的 `**` 为**全量引用**（所有资源入包）；否则为**增强引用**（只打包能从脚本里“追踪”到的资源，路径必须是**完整字符串字面量**）。
- 本包 `resources.json` 采用**全量引用 + 全部 DWP（不预下载）**，最稳妥，不会因为路径拼接而丢资源。
- 同时 `Sound.lua` 已把 19 个音频写成完整路径字面量，即使你改成增强引用也能被追踪到。
- `.ogg` 属于 **DWP 媒体资源**：首次读取可能先是静音占位，下载完成后自动热替换。`Sound.lua` 已处理（读不到不会永久放弃，BGM 会自动重试）。
- 文档提到资源需要有对应的 `.meta` 文件（含 UUID）。本包**没有**手工生成 `.meta`（UUID 由平台生成）；导入平台后请确认 `assets/Sounds/*.ogg` 已被识别（有 `.meta`）。若没有，需要在平台里“导入 / 刷新资源”。

## 三、接入步骤（建议）
1. 在 TapTap 制造里新建 / 打开一个 UrhoX 项目，把本包的 `scripts/`、`assets/`、`.project/` 放进项目根目录（覆盖脚手架的同名文件，入口为 `scripts/main.lua`）。
2. 刷新资源，确认音频被识别；在编辑器 / 预览里启动游戏。
3. 按“五、必须验证”逐项试玩（真机优先）。
4. 在**嵌入式容器**里测试激励视频：`sdk` 只在容器里可用，编辑器里为 nil，此时游戏不会弹广告也不发奖励（这是有意设计）。
5. 准备商店资料（`store/`）与合规文档（`docs/`），按平台流程提交审核。

## 四、与 SDK 的对接点
| 功能 | 位置 | 说明 |
|---|---|---|
| 激励视频 | `cosmic/Sdk.lua` | `sdk:ShowRewardVideoAd(cb)`；只有 `result.success == true`（`embed success`）才发奖励；`embed manual close` / 其他均不发 |
| 退出按钮避让 | `Sdk.ExitRect()` | `sdk:GetNativeExitMenuRect()`，HUD 的“暂停”按钮会向左让开 |
| 存档 | `cosmic/Save.lua` | 本地 JSON（项目 + 用户隔离）。**没有**接云存档 / 排行榜（文档有 `clientScore` 接口，可作为后续版本的功能：每日挑战排行榜、无尽最高波数） |

## 五、必须验证（我无法在这里验证）
1. 手臂 / 腿的转向（欧拉角约定）、枪口位置（`node.worldPosition`）。
2. 触控：`input:GetTouch` 坐标单位、摇杆与按钮点击、`nvgScale` 后的坐标换算。
3. 帧率 / 发热 / 内存（Lua 版每帧创建大量粒子节点；`Fx.max` 可调小，默认 320）。
4. 音频是否正常出声（DWP 热替换）、BGM 是否循环。
5. 激励视频回调（在容器里）。
6. 不同分辨率 / 刘海屏下的 HUD 布局。
