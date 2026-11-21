# 宇宙银河机甲 · UrhoX（TapTap 制造）移植说明（v1.1.0：网页版转换内核）

> **这一版的做法与之前不同**：游戏玩法与数据**不是手写重写**，而是把网页版源码（`preview/src/cosmic_run.js`、`cosmic_data.js`）用自动转换器逐行转成 Lua，
> 所以战斗规则、敌人行为、卡牌、芯片、召唤、每日挑战等与网页版**代码级一致**。UrhoX 是 Lua 引擎，不能直接运行网页，这是保证“照搬”的最可靠办法。
> **仍然没有在真正的 UrhoX / TapTap 制造里运行过**，请先试跑并核对文末“未验证”清单。

## 一、架构
```
preview/src/*.js（网页版，唯一玩法源码）
   │  tools/build_xpile.py + tools/xpile/transpile.js（acorn 语法树 -> Lua；只加 1 处界面钩子补丁：结算数据存入 R.result）
   ▼
scripts/jsrt/CosmicData.lua   数据 + 存档 + 抽取 / 卡牌 / 芯片 / 每日 / 成就……（转换产物）
scripts/jsrt/CosmicRun.lua    战斗：飞行、武器、技能、敌人 AI、首领、卡牌、元素反应、星域目标……（转换产物）
scripts/jsrt/JS.lua           JavaScript 语义运行库（数组从 0 起、真值判断、字符串相加、取模、undefined 参与运算、有序对象键、JSON、Date）
scripts/jsrt/Engine.lua       网页版 engine.js 的接口：Float32 矩阵 m4/m4mul/trs、投影、getMesh（含 radius）
scripts/jsrt/Renderer.lua     E.render 的 UrhoX 后端：绘制列表 -> 节点对象池（矩阵分解、颜色替换、相机、灯光、辉光、星空）
scripts/jsrt/CanvasShim.lua   Canvas 2D 接口的 NanoVG 实现：网页版 drawOverlay（伤害数字、锁定框、预警、屏幕外箭头、摇杆圈）无需改写
scripts/jsrt/Host.lua         宿主装配：window / document / localStorage / 定时器 / 音频与广告钩子
scripts/cosmic/WebUI.lua      与网页版 CSS 一致的 NanoVG 控件：斜切角面板、凸起按钮、导航栏、资源条、属性条、菱形星级、像素图标、滚动区域
scripts/cosmic/GameUI.lua     战斗界面（HUD、升级选卡、商人、暂停、复活、结算、新手引导）与触控 / 键盘输入
scripts/cosmic/Hub.lua        机库（出击、机库、驾驶员、工坊、召唤、每日、设置、关于）——版面坐标取自网页版在 1920x1080 下的真实渲染，按钮逻辑与网页版逐条对应
scripts/cosmic/GameApp.lua    应用入口，scripts/main.lua 为 UrhoX 入口（每帧 pcall 保护）
```
更新玩法：改网页版源码 -> `python3 tools/build_xpile.py` -> `python3 tools/build_urhox_release.py`。

## 二、一致性证据（见 tools/xpile/tests 与 docs/release/UrhoX版与网页版一致性对照.md）
- 1080 张卡牌（名称、词条）、每日挑战规则、研发费用、等级倍率、芯片属性：与网页版逐项一致。
- 战斗：同一随机种子 + 同一段操作，网页版与 Lua 版各跑 900 帧（6 台机甲 x 3 章节）以及 1200 帧（首领战 x 2、无尽 + 危险等级、每日挑战），
  玩家位置 / 耐久 / 击破 / 等级 / 经验 / 每个敌人的血量与位置全部一致。

## 三、界面还原方法与差异（只在“显示”层）
- 用浏览器在 1920x1080 下导出网页版每个元素的位置、尺寸、颜色（见 docs/release/ui_compare 的对照图），按这些坐标用 NanoVG 重画；`tools/nvg_render.py` + `tools/run_shot.py` 可以在没有真机时把界面渲染成图片检查版式。
- 3D 画面颜色：UrhoX 用 PBR 材质 + 方向光；已按网页版着色器补上雾（线性近似二次曲线）、辉光阈值换算（线性空间 -> gamma 空间）、暗角（NanoVG 径向渐变）；设置里提供“辉光 弱 / 标准 / 强”和实验性的“色调映射”（HDR + Tonemap，重启生效）。网页版的 ACES 色调映射、半球环境光、阴影无法在 UrhoX 的 PBR 里逐项复制。
- 机库与战斗 HUD / 弹窗：网页版是 HTML + CSS（DOM），这里用 NanoVG 重画，**版式不是像素一致**；每个按钮的处理逻辑与网页版一致。
- 召唤动画：已按网页版 summonScene 移植（蓄力 -> 陨星坠落 -> 爆发 -> 翻牌 -> 新角色展示，可跳过）；闪光 / 光线 / 翻牌 / 展示页是用 NanoVG 重画的。
- 存档导出 / 导入（文本框）未提供；其余存档逻辑一致（存档文件由引擎的项目 + 用户隔离目录保存）。
- 3D 机库场景已按网页版 frame() 移植（地砖、墙、门、集装箱、补给箱、控制台、水晶、炮台等装饰；出击 / 工坊 / 每日页展示机甲 + 驾驶员，机库 / 驾驶员页展示单个主体慢速自转）；拖动旋转未移植。

## 四、怎么运行
1. 以发布包根目录作为 UrhoX 项目，入口 `scripts/main.lua`；音频在 `assets/Sounds/*.ogg`（路径 `Sounds/xxx.ogg`）；`.project/` 含构建配置（全量引用 + 全部边玩边下）。
2. 自检（没有 Lua 解释器时也能跑）：`python3 tools/run_xp_test.py`（模拟引擎：机库 -> 抽卡 / 召唤 -> 6 台机甲战斗 -> 首领 -> 结算 -> 无尽 -> 每日）。
3. 对照测试：`node tools/xpile/tests/...`（需要 playwright）——见 tools/xpile/tests。

## 五、未验证（必须在 UrhoX 里确认）
1. 矩阵 -> 节点的转换：`Quaternion(w, x, y, z)` 构造、`node.rotation`、`SetScale` 是否与预期一致（机甲 / 敌人朝向是否正确、有没有镜像）。
2. 相机：`LookAt` 与 `camera.fov`；`WorldToScreen` 由 Engine.project 自己计算（不依赖引擎）。
3. 颜色空间：模型颜色与特效 tint 的亮度是否接近网页版；辉光参数（`BloomThreshold` / `BloomMix`）。
4. NanoVG：`nvgArc`、`nvgText` 对齐常量、字体 `Fonts/MiSans-Bold.ttf`；2D 叠加层的字号与位置。
5. 触控：`input:GetTouch` 坐标是像素还是归一化；多点触控；`UI.lua` 的点击检测。
6. 性能：每帧最多数百个节点的位置 / 旋转 / 缩放更新（Renderer 用对象池）；`Fx` 已不使用，粒子全部走绘制列表。必要时降低粒子数量（网页版有“柔和”特效选项）。
7. 音频与 SDK：`Sounds/xxx.ogg`、DWP 占位；`sdk:ShowRewardVideoAd` 在容器内的行为；退出按钮避让。
8. 提审材料：版号、实名防沉迷、隐私政策 / 用户协议（见 docs）。
