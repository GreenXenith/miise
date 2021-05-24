miise.register_feature_type("mouth", {
    label = "Mouth",
    range = {
        min = {x = -1, y = 0},
        max = {x = 1, y = 7},
    },
    anchor = {x = 8, y = 8},
    default = {x = 0, y = 6},
})

miise.register_feature_type("eyes", {
    label = "Eyes",
    symmetrical = true,
    range = {
        min = {x = 0, y = 0},
        max = {x = 3, y = 7},
    },
    anchor = {x = 8, y = 8},
    default = {x = 1, y = 4},
})

miise.register_feature_type("eyebrows", {
    label = "Eyebrows",
    symmetrical = true,
    range = {
        min = {x = 0, y = 0},
        max = {x = 3, y = 7},
    },
    anchor = {x = 8, y = 8},
    default = {x = 1, y = 3},
})

miise.register_feature_type("hair", {
    label = "Hair",
    range = {
        min = {x = 0, y = 0},
        max = {x = 0, y = 0},
    },
    anchor = {x = 0, y = 0},
    default = {x = 0, y = 0},
})

miise.register_feature_type("beard", {
    label = "Beard",
    range = {
        min = {x = 0, y = 0},
        max = {x = 0, y = 0},
    },
    anchor = {x = 0, y = 0},
    default = {x = 0, y = 0},
})

for ftype, count in pairs({mouth = 2, eyes = 4, hair = 5, beard = 5, eyebrows = 3}) do
    for i = 1, count do
        miise.register_feature(("miise:%s_%s"):format(ftype, i), ftype, {
            texture = ("miise_%s_%s.png"):format(ftype, i),
            mask = ("miise_%s_%s_mask.png"):format(ftype, i),
        })
    end
end
