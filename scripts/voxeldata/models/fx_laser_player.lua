-- 由 tools/build_voxels.py 自动生成，请勿手改。修改模型请编辑 tools/models_*.py 后重新构建。
-- 四边形编码：face, p, u0, v0, u1, v1（face = 轴*2 + 方向，u=(轴+1)%3, v=(轴+2)%3）
return {
    id = "fx_laser_player",
    name = "玩家激光",
    category = "fx",
    desc = "战斗特效。",
    scale = 0.1,
    size = {1, 1, 14},
    origin = {0.5, 0.5, 7},
    voxels = 14,
    quadCount = 6,
    mats = {
        {
            color = {0.3608, 0.949, 0.8627},
            metallic = 0,
            roughness = 0.2,
            emissive = 3,
            quads = {
                0,1,0,0,1,14,1,0,0,0,1,14,2,1,0,0,14,1,3,0,0,0,14,1,4,14,0,0,1,1,
                5,0,0,0,1,1,
            },
        },
    },
}
