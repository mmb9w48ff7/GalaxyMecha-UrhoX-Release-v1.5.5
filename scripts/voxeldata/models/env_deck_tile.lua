-- 由 tools/build_voxels.py 自动生成，请勿手改。修改模型请编辑 tools/models_*.py 后重新构建。
-- 四边形编码：face, p, u0, v0, u1, v1（face = 轴*2 + 方向，u=(轴+1)%3, v=(轴+2)%3）
return {
    id = "env_deck_tile",
    name = "金属甲板",
    category = "env",
    desc = "空间站地面瓦片，2 x 2 米，可无缝拼接。",
    scale = 0.25,
    size = {8, 1, 8},
    origin = {4, 0, 4},
    voxels = 64,
    quadCount = 22,
    mats = {
        {
            color = {0.3529, 0.3804, 0.4588},
            metallic = 0.7,
            roughness = 0.45,
            emissive = 0,
            quads = {
                0,8,0,1,1,8,2,1,1,2,2,8,2,1,2,1,8,2,2,1,2,6,8,8,2,1,6,2,8,6,
                3,0,1,2,2,8,3,0,2,1,8,2,3,0,2,6,8,8,3,0,6,2,8,6,4,8,1,0,8,1,
            },
        },
        {
            color = {0.2706, 0.2941, 0.3608},
            metallic = 0.7,
            roughness = 0.5,
            emissive = 0,
            quads = {2, 1, 2, 2, 6, 6, 3, 0, 2, 2, 6, 6},
        },
        {
            color = {0.1686, 0.1843, 0.2275},
            metallic = 0.5,
            roughness = 0.6,
            emissive = 0,
            quads = {
                0,8,0,0,1,1,1,0,0,0,1,8,2,1,0,0,1,8,2,1,1,0,8,1,3,0,0,0,1,8,
                3,0,1,0,8,1,4,8,0,0,1,1,5,0,0,0,8,1,
            },
        },
        {
            color = {0.3608, 0.949, 0.8627},
            metallic = 0,
            roughness = 0.2,
            emissive = 1,
            quads = {2, 1, 1, 1, 2, 2, 3, 0, 1, 1, 2, 2},
        },
    },
}
