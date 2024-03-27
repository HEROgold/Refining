-- Initialize mixing base
function initial_color_rgb()
    return {r=0, g=0, b=0, a=0}
end

function initial_color_hsv()
    return {h=0, s=0, v=0, a=0}
end

-- Weighted average for RGB/HSV values, per item count
function weigh_colors_rgb(color, p)
    local final_color = {}
    for index, value in pairs(color) do
        final_color[index] = value*p
    end
    return final_color
end

function weigh_colors_hsv(color, p)
    color=rgb_to_hsv(color)
    local final_color = {}
    for index, value in pairs(color) do
        final_color[index] = value*p
    end
    return final_color
end

-- Add colors...
function add_colors_rgb(color1, color2)
    color1.r = color1.r + color2.r
    color1.g = color1.g + color2.g
    color1.b = color1.b + color2.b
    color1.a = color1.a + color2.a
    return color1
end

function add_colors_hsv(color1, color2)
    color1.h = color1.h + color2.h
    color1.s = color1.s + color2.s
    color1.v = color1.v + color2.v
    color1.a = color1.a + color2.a
    return color1
end

-- The brains of the operation
function color_calculator(train_content, colors, custom_colors)
    -- Make sure train content is not nil
    if train_content == nil then
        return nil, false
    end

    -- Filter and direct train content
    local train_content_filtered = {}
    local paint_color
    local custom_setting = settings.global["atp-custom-colors-enable"].value

    if custom_setting == "Only" then
        for item, value in pairs(train_content) do
            -- Include only items present in custom color list
            item = remove_name_string(item)
            if custom_colors ~= nil and custom_colors[item] ~= nil then
                train_content_filtered[item] = value
                paint_color = custom_colors
            end
        end
    elseif custom_setting == "Priority" then
        for item, value in pairs(train_content) do
            -- Check only items present in custom color list
            item = remove_name_string(item)
            if custom_colors ~= nil and custom_colors[item] ~= nil then
                if  custom_colors[item] ~= nil then
                    train_content_filtered[item] = value
                    paint_color = custom_colors
                end
            else
                -- Check only items present in colors database
                item = filter_name(item)
                if colors[item] ~= nil then
                    train_content_filtered[item] = value
                    paint_color = colors
                end
            end
        end
    else
        for item, value in pairs(train_content) do
            item = filter_name(item)
            -- Include only items present in colors database
            if colors[item] ~= nil then
                train_content_filtered[item] = value
                paint_color = colors
            end

        end
    end

    -- Calculate total item count
    local q = 0
    local total_count = 0
    for _, count in pairs(train_content_filtered) do
        total_count = total_count+count
        q = q+1
    end

    -- Return for single item
    if q==1 then
        local item_color = {}
        for item, _ in pairs(train_content_filtered) do
            item_color = paint_color[item]
        end
        return item_color, true
    end

    -- Calculate color mix
    local mixed_color_rgb = initial_color_rgb()
    local mixed_color_hsv = initial_color_hsv()
    local mix_flag = false

    for item, count in pairs(train_content_filtered) do
        local p = count/total_count
        if custom_colors ~= nil and custom_colors[item] ~= nil and custom_setting ~= "Off" then
            paint_color = custom_colors
        else
            paint_color = colors
        end
        local weighted_color_rgb = weigh_colors_rgb(paint_color[item], p)
        local weighted_color_hsv = weigh_colors_hsv(paint_color[item], p)
        mixed_color_rgb = add_colors_rgb(weighted_color_rgb, mixed_color_rgb)
        mixed_color_hsv = add_colors_hsv(weighted_color_hsv, mixed_color_hsv)
        mix_flag = true
    end

    -- Replace final RGB value with averaged HSV value
    local hybrid_hsv=rgb_to_hsv(mixed_color_rgb)
    hybrid_hsv.v=mixed_color_hsv.v
    local mixed_color=hsv_to_rgb(hybrid_hsv)

    return mixed_color, mix_flag
end