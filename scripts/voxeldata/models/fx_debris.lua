-- 由 tools/build_voxels.py 自动生成，请勿手改。修改模型请编辑 tools/models_*.py 后重新构建。
-- 四边形编码：face, p, u0, v0, u1, v1（face = 轴*2 + 方向，u=(轴+1)%3, v=(轴+2)%3）
return {
    id = "fx_debris",
    name = "碎片",
    category = "fx",
    desc = "战斗特效。",
    scale = 0.1,
    size = {1, 1, 1},
    origin = {0.5, 0.5, 0.5},
    voxels = 1,
    quadCount = 6,
    mats = {
        {
            color = {0.2902, 0.3098, 0.3686},
            metallic = 0,
            roughness = 0.2,
            emissive = 0,
            quads = {
                0,1,0,0,1,1,1,0,0,0,1,1,2,1,0,0,1,1,3,0,0,0,1,1,4,1,0,0,1,1,
                5,0,0,0,1,1,
            },
        },
    },
}
