-- 由 tools/build_voxels.py 自动生成，请勿手改。修改模型请编辑 tools/models_*.py 后重新构建。
-- 四边形编码：face, p, u0, v0, u1, v1（face = 轴*2 + 方向，u=(轴+1)%3, v=(轴+2)%3）
return {
    id = "fx_laser_enemy",
    name = "海贼激光",
    category = "fx",
    desc = "战斗特效。",
    scale = 0.1,
    size = {1, 1, 12},
    origin = {0.5, 0.5, 6},
    voxels = 12,
    quadCount = 6,
    mats = {
        {
            color = {1, 0.302, 0.4157},
            metallic = 0,
            roughness = 0.2,
            emissive = 3,
            quads = {
                0,1,0,0,1,12,1,0,0,0,1,12,2,1,0,0,12,1,3,0,0,0,12,1,4,12,0,0,1,1,
                5,0,0,0,1,1,
            },
        },
    },
}
