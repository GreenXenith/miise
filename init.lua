miise = {
    feature_types = {},
    registered_features = {},
}

-- Feature Type Definition = {
--     label = "String",
--     symmetrical = false,
--     range = {
--         min = {x = 0, y = 0},
--         max = {x = 4, y = 4},
--     },
--     default = {x = 2, y = 2},
-- }
miise.register_feature_type = function(name, definition)
    assert(not miise.feature_types[name], ("Feature type '%s' already exists."):format(name))
    definition.features = {}
    definition.name = name
    miise.feature_types[name] = definition
end

-- Feature Definition = {
--     texture = "path_to_texture.png",
--     mask = "path_to_color_mask.png",
-- }
miise.register_feature = function(name, feature_type, definition)
    assert(not miise.registered_features[name], ("Feature '%s' already exists."):format(name))
    assert(miise.feature_types[feature_type], ("Type '%s' does not exist."):format(type))
    definition.name = name
    definition.type = feature_type
    definition.pos = miise.feature_types[feature_type].default
    definition.color = "#00000000"
    miise.registered_features[name] = definition
    miise.feature_types[feature_type].features[name] = miise.registered_features[name]
end

-- Create texture from features
local function texture_escape(texture)
    return texture:gsub("[%^:]", "\\%1"):gsub("\\\\+", "\\")
end

local function add_to_texture(texture1, size, texture2, pos)
    return ("%s^([combine:%sx%s:%s,%s=(%s))"):format(texture1, size.x, size.y, pos.x, pos.y, texture_escape(texture2))
end

local vec2_add = function(v1, v2) return {x = v1.x + v2.x, y = v1.y + v2.y} end

local add_feature_to_texture = function(feature, base, size, offset)
    local type_def = miise.feature_types[feature.type]
    local pos = feature.pos
    local anchor = vec2_add(type_def.anchor, offset)

    local color, alpha = feature.color:match("^(#%x%x%x%x%x%x)(%x%x)$")
    color, alpha = color or feature.color, tonumber(alpha or "c0", 16)

    local texture = feature.texture .. ("^((%s^[mask:%s)^[colorize:%s:%s)"):format(feature.texture, feature.mask, color, alpha)
    base = add_to_texture(base, size, texture, vec2_add(anchor, pos))

    if type_def.symmetrical then
        base = add_to_texture(base, size, texture .. "^[transformFX", vec2_add(anchor, {x = -pos.x, y = pos.y}))
    end

    return base
end

local build_texture = function(features)
    local base = "miise_base_skin.png"
    for _, feature in pairs(features) do
        base = add_feature_to_texture(feature, base, {x = 64, y = 32}, {x = 0, y = 0})
    end
    return base
end

-- Data helpers
local get_all_defaults = function()
    local defaults = {}
    for feature_type, type_def in pairs(miise.feature_types) do
        local _, feature_def = next(type_def.features)
        defaults[feature_type] = feature_def
    end
    return defaults
end

local get_sorted_types = function()
    local sorted_types = {}
    for ftype in pairs(miise.feature_types) do
        sorted_types[#sorted_types + 1] = ftype
    end
    table.sort(sorted_types, function(a, b) return a < b end)
    return sorted_types
end

local get_sorted_type_index = function(feature_type)
    for i, ftype in pairs(get_sorted_types()) do
        if ftype == feature_type then return i end
    end
    return 1
end

local get_miise = function(player)
    local features = player:get_meta():get_string("miise:miise")
    return features ~= "" and minetest.deserialize(features) or get_all_defaults()
end

local apply_miise = function(player, features)
    player:set_properties({textures = {build_texture(features)}})
    player:get_meta():set_string("miise:miise", minetest.serialize(features))
end

-- Form builders
local place_section = function(form, pos)
    return ("container[%s,%s] %s container_end[]"):format(pos.x, pos.y, form)
end

local build_preview = function(feature)
    return add_feature_to_texture(feature, "[combine:8x8:-8,-8=miise_base_skin.png", {x = 8, y = 8}, {x = -8, y = -8})
end

local build_selection = function(feature_type)
    local features = {}
    local type_def = miise.feature_types[feature_type]
    for _, definition in pairs(type_def.features) do
        features[#features + 1] = definition
    end

    local form = ""
    local rowsize = 5
    for y = 0, math.ceil(#features / rowsize) - 1 do
        for x = 0, rowsize - 1 do
            local i = rowsize * y + x + 1
            if features[i] then
                form = form .. ("image_button[%s,%s;1,1;%s;%s;]"):format(x * 1.2, y * 1.2, minetest.formspec_escape(build_preview(features[i])), "feature:" .. features[i].name)
            end
        end
    end

    return form
end

local build_controller = function()
    local form = [[
        button[1,0;1,1;move:up;^]
        button[0,1;1,1;move:left;<]
        button[2,1;1,1;move:right;>]
        button[1,2;1,1;move:down;v]
    ]]

    local colors = {
        "red", "orange", "yellow", "limegreen",
        "darkgreen", "cyan", "blue", "violet",
        "pink", "magenta", "brown", "black",
        "grey", "white",
    }

    colors[#colors + 1] = "#00000000"

    local cform = ""
    local rowsize = 5
    for y = 0, math.ceil(#colors / rowsize) - 1 do
        for x = 0, rowsize - 1 do
            local i = rowsize * y + x + 1
            if colors[i] then
                local c = colors[i]
                if c == colors[#colors] then
                    cform = cform .. ("button[%s,%s;1,1;color:%s;X]"):format(x * 1.2, y * 1.2, c)
                else
                    cform = cform .. ("image_button[%s,%s;1,1;%s;%s;]"):format(x * 1.2, y * 1.2, "blank.png^[noalpha^[colorize:" .. c .. ":255", "color:" .. c)
                end
            end
        end
    end

    form = form .. place_section(cform, {x = 0, y = 3.5})

    return form
end

local build_interface = function(player, feature_type)
    local form = [[
        formspec_version[3]
        size[20,8,false]
        no_prepend[] real_coordinates[true]
    ]]

    form = form .. ("tabheader[1,0;0.5;type;%s;%s;false;false]"):format(table.concat(get_sorted_types(), ","), get_sorted_type_index(feature_type))

    form = form .. place_section(build_controller(), {x = 1, y = 1})
    form = form .. place_section(build_selection(feature_type), {x = 20 - (5 * 1.2) - 1 + 0.2, y = 1})

    form = form .. ("model[8,0;4,8;preview;%s;%s;{0,180};false;true;0,40]"):format(player:get_properties().mesh, minetest.formspec_escape(build_texture(get_miise(player))))

    return form
end

-- Form handler
local actions = {
    move = function(feature, dir)
        local type_def = miise.feature_types[feature.type]
        local dirs = {
            up = {x = 0, y = -1},
            down = {x = 0, y = 1},
            left = {x = -1, y = 0},
            right = {x = 1, y = 0},
        }

        local pos = vec2_add(feature.pos, dirs[dir])
        if pos.x >= type_def.range.min.x and pos.x <= type_def.range.max.x and
           pos.y >= type_def.range.min.y and pos.y <= type_def.range.max.y then
            feature.pos = pos
        end

        return feature
    end,
    feature = function(oldfeature, newfeature)
        local new = table.copy(miise.registered_features[newfeature])
        new.pos = oldfeature.pos
        new.color = oldfeature.color
        return new
    end,
    color = function(feature, color)
        feature.color = color
        return feature
    end
}

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if fields.quit then return end

    if formname:match("^miise:") then
        if fields.type then
            local ftype = get_sorted_types()[tonumber(fields.type)]
            minetest.show_formspec(player:get_player_name(), "miise:" .. ftype, build_interface(player, ftype))
            return
        end

        local features = get_miise(player)
        local ftype = formname:match(":(.+)$")

        for field in pairs(fields) do
            for action, func in pairs(actions) do
                if field:match("^" .. action .. ":") then
                    features[ftype] = func(features[ftype], field:match(":(.+)$"))
                end
            end
        end

        apply_miise(player, features)
        minetest.show_formspec(player:get_player_name(), formname, build_interface(player, ftype))
    end
end)

minetest.register_on_joinplayer(function(player)
    apply_miise(player, get_miise(player))
end)

minetest.register_chatcommand("miise", {
    func = function(name)
        local ftype = get_sorted_types()[1]
        minetest.show_formspec(name, "miise:" .. ftype, build_interface(minetest.get_player_by_name(name), ftype))
    end
})

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/features.lua")
