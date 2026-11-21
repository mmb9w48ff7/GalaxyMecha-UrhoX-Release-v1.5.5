# 宇宙银河机甲 · UrhoX 版 v1.5.5

UrhoX / TapTap 制造 版本（v1.5.5）。内容原样取自 `GalaxyMecha_UrhoX_Release_v1_5_5.zip`，只把内层 `UrhoX_Release/` 摊平到仓库根目录，并把压缩时损坏的中文文件名（含重复的「特效对比」目录）合并还原。未修改任何代码或资源。

## 版本与结构

- 版本号以 `VERSION` 为准：**1.5.5**
- 文件 217 个

```
.project/                    UrhoX 工程配置
VERSION                      1.5.5
assets/Sounds/               音效与 BGM（.ogg）
assets/Textures/             贴图（含 v1.5.0 起新增的 fx_glow.png 径向渐变柔光贴图）
docs/                        22 篇文档（含 更新说明 v1.3.6 → v1.5.5 各版）
docs/特效对比/                7 张方案对比图（v1.4.9 攻击特效 + v1.5.0 ~ v1.5.5 各版）
scripts/
  main.lua                   引擎入口
  cosmic/                    界面与流程脚本
  game/                      体素构建
  jsrt/                      运行时（本版只改 Renderer.lua）
  voxeldata/                 体素数据与模型
tools/xpile_lite/            网页版 -> Lua 转换器
tools/fx_preview/            UrhoX 观感预览（make_preview.py / rules.js）
网页版19源码_供转换器/        19 版网页版 JS 源码
```

## v1.5.5 改动（摘自 `docs/更新说明_v1.5.5.md`）

只改 `scripts/jsrt/Renderer.lua` 与版本号，修两个 v1.5.x 引入的问题。

**问题 1：激光 / 子弹两侧出现一排排粉色、青色竖条**

v1.5.0 起细长柔光用的是 UrhoX 广告牌的「沿方向」模式（`FC_DIRECTION`）。该模式在 TapTap 制造的 UrhoX 里朝向与标准 Urho3D 不一致：柔光没有沿激光方向，而是横在激光上，长条变成垂直于激光的竖条；首领激光、狙击线由很多小段组成，于是变成一整排竖条。预览页模拟的是标准行为，所以之前没发现。

修复：不再使用「沿方向」广告牌。子弹 / 激光改为 **细本体（横向 0.8 倍）+ 一层贴身光套**（横向 1.7 倍、长度 1.04 倍，亮度 敌 0.1 / 我 0.08，预警细线减半）。光套是跟模型一起摆放的方块，方向由弹道自身矩阵决定，一定与弹道对齐。圆形柔光（火花、余烬、闪光，「面向镜头」模式是粒子默认模式）保留。

**问题 2：机甲被打中时整台变成粉色**

受击时战斗代码给机甲部件加了红色「颜色替换」。网页版只是一闪；UrhoX 里颜色替换会把整台机甲所有颜色换成粉红，像出错。现在 UrhoX 不给机甲部件做受击染色，受击反馈保留屏幕边缘红闪、震屏和音效。

验证：Lua 与预览规则逐项一致（14 项，含新的贴身光套）；渲染后端（柔光 / 退回两条路径）、界面流程、无尽测试无报错；预览图见 `docs/特效对比/对比_v1.5.5_激光修复.jpg`。

## 怎么运行

1. 以仓库根目录作为 UrhoX 项目，入口 `scripts/main.lua`
2. 音频、模型、贴图路径相对根目录，请保留原目录结构（`assets/Textures/fx_glow.png` 必须一起部署）
3. 上架流程见 `docs/TapTap制造接入指南.md` 与 `docs/提审清单.md`

## 使用前请注意

- 整体仍未在真实 UrhoX / TapTap 制造真机验证，首次运行请按 `docs/UrhoX移植说明.md` 末尾的未验证清单核对
- `docs/用户协议模板.md`、`docs/隐私政策模板.md` 为模板，上线前需按运营主体与法务意见修改
- 包内 `docs/RELEASE_NOTES.md` 正文仍停留在 v1.1.0 措辞，与 `VERSION` 不一致（本仓库不改用户文档，仅在此注明）

## 相关仓库

- 上一版（v1.5.4 边缘光辉收小）：`https://github.com/mmb9w48ff7/GalaxyMecha-UrhoX-Release-v1.5.4`
- 更早：v1.4.9（攻击特效重做）、v1.4.8、v1.4.7、v1.4.6、v1.4.4、v1.4.3、v1.4.2、v1.4.1、v1.3.5
- 源码工程（作者专用）：`https://github.com/mmb9w48ff7/GalaxyMecha-Source-v1.3.5`
- 网页版合集：`https://github.com/mmb9w48ff7/GalaxyMecha-Web-2`
