function cache_mods()
    global.mods = {}
    for mod, t in pairs(mod_list) do
        if script.active_mods[mod] then
            global.mods[mod] = t
        end
    end
end

function remove_name_string(item)
    local active_removals = {
        ["Factorio"]={"%-barrel"},
        ["deadlock-integrations"]={"deadlock%-stack%-"},
    }
    for k, v in pairs(removals) do
        local mod_name = global.mods[k]
        if mod_name ~= nil then
            active_removals[k] = v
        end
    end

    for _,v in pairs(active_removals) do
        if (string.find(item,v[1]) and not string.find(item,"empty%-barrel")) then
            item=string.gsub(item,v[1],"")
        end
    end

--    game.print(item) -- for debugging
    return item
end

function divert_name(item)
    for _, filterlist in pairs(global.mods) do
        if filterlist[3] ~=nil then
            for _,x in pairs(filterlist[3]) do
                if(item==x) and filterlist[2] ~=nil then
                    item=item .. filterlist[2]
                end
            end
        end
    end

--    game.print(item) -- for debugging
    return item
end


function filter_name(item)
    -- remove sub-strings from item names
    item = remove_name_string(item)

    -- divert duplicated item-names to correct color as applicable
    item = divert_name(item)

--    game.print(item) -- for debugging
    return item
end

function default_color(setting)
    local hex = settings.global[setting].value
    local color
    local name
    local default
    local r, g, b, c1, c2, c3

    if setting == "u-loco" then
        default = default_loco_color
        name = "locomotive"
    end
    if setting == "u-cargo-wagon" then
        default = default_cargo_color
        name = "cargo wagon"
    end
    if setting == "u-fluid-wagon" then
        default = default_fluid_color
        name = "fluid wagon"
    end

    if string.len(hex) ~= 6 and string.len(hex) ~= 3 and string.len(hex) ~= 0 then
        game.print({"error-message.color-length-error", name, string.len(hex)})
        return default
    end

    if string.len(hex) == 6 then
        c1,c2,c3=hex:match('(..)(..)(..)')
        r=tonumber(c1,16)
        g=tonumber(c2,16)
        b=tonumber(c3,16)
        color = {['r']=r, ['g']=g, ['b']=b, ['a']=127}
    end

    if string.len(hex) == 3 then
        c1,c2,c3=hex:match('(.)(.)(.)')
        r=tonumber(c1..c1,16)
        g=tonumber(c2..c2,16)
        b=tonumber(c3..c3,16)
        color = {['r']=r, ['g']=g, ['b']=b, ['a']=127}
    end

    return color
end

function rgb_to_hsv(color)
    local cmax=math.max(color.r,color.g,color.b)/255
    local cmin=math.min(color.r,color.g,color.b)/255
    local diff=cmax-cmin

    -- hue
    local h
    if cmax==cmin then
        h=0
    elseif cmax==color.r/255 then
        h=math.fmod(60*((color.g/255-color.b/255)/diff)+360,360)
    elseif cmax==color.g/255 then
        h=math.fmod(60*((color.b/255-color.r/255)/diff)+120,360)
    elseif cmax==color.b/255 then
        h=math.fmod(60*((color.r/255-color.g/255)/diff)+240,360)
    end

    -- saturation
    local s
    if cmax==0 then
        s=0
    else
        s=(diff/cmax)*100
    end

    -- value
    local v=cmax*100

    return {h=h,s=s,v=v,a=color.a}
end

function hsv_to_rgb(color)
    local c=(color.v*color.s)/10000
    local h0=color.h/60
    local x=c*(1-math.abs(math.fmod(h0,2)-1))
    local m=round(color.v/100-c,14)

    -- red
    local r
    if (0<=h0 and h0<1) or (5<=h0 and h0<6) then
        r=c
    elseif (1<=h0 and h0<2) or (4<=h0 and h0<5) then
        r=x
    else
        r=0
    end
    r=(r+m)*255

    -- green
    local g
    if (1<=h0 and h0<2) or (2<=h0 and h0<3) then
        g=c
    elseif (0<=h0 and h0<1) or (3<=h0 and h0<4) then
        g=x
    else
        g=0
    end
    g=(g+m)*255

    -- blue
    local b
    if (3<=h0 and h0<4) or (4<=h0 and h0<5) then
        b=c
    elseif (2<=h0 and h0<3) or (5<=h0 and h0<6) then
        b=x
    else
        b=0
    end
    b=(b+m)*255

    return {r=r,g=g,b=b,a=color.a}
end

function verify_item_name(item_name)
    local item_name_dash = string.gsub(item_name,"-","")
    local item_name_clean = string.gsub(item_name_dash,"_","")
    if(item_name_clean:match("%W")) then
        pprint({"error-message.invalid-custom-item-name", item_name})
        return false
    end
    return true
end

function verify_rgb_key(v,item_name)
    local rgb_key = ""
    for k,_ in pairs(v) do
        rgb_key = rgb_key..k
    end
    local rgb_key_sorted = sort_string(rgb_key)
    if rgb_key_sorted ~= "abgr" then
        local key_minus_r = string.gsub(rgb_key,"r","")
        local key_minus_g = string.gsub(key_minus_r,"g","")
        local key_minus_b = string.gsub(key_minus_g,"b","")
        local remainder = string.gsub(key_minus_b,"a","")
        pprint({"error-message.invalid-custom-color-key", remainder, item_name, rgb_key_sorted})
        return false
    end
    return true
end

function verify_rgb_value(v,item_name)
    for k,n in pairs(v) do
        if n > 255 or n < 0 then
            pprint({"error-message.invalid-custom-color-value", k, n, item_name})
            return false
        end
    end
    return true
end

function verify_read_contents(color_table)
    local table_check_flag1 = true
    local table_check_flag2 = true
    if type(color_table) == "table" then
        for _, v in pairs(color_table) do
            if type(v) ~= "table" then
                table_check_flag2 = false
            end
        end
    else
        table_check_flag1 = false
    end

    if table_check_flag1 == false or table_check_flag2 == false then
        pprint({"error-message.custom-colors-not-loaded"})
        color_table = nil
        return color_table
    end

    local final_check = true
    for item_name,v in pairs(color_table) do
        local check1 = verify_item_name(item_name)
        local check2 = verify_rgb_key(v,item_name)
        local check3 = verify_rgb_value(v,item_name)
        final_check = final_check and check1 and check2 and check3
    end
    if final_check then
        pprint({"error-message.custom-colors-loaded"})
    else
        pprint({"error-message.custom-colors-not-loaded-tag"})
        color_table = nil
    end
    return color_table
end

function table_error_handler(t)
    local function pcall_convert()
        local custom_colors_table = convert_string_to_table(t)
        local t_custom_colors = verify_read_contents(custom_colors_table)
        return t_custom_colors
    end

    local function err (_)
        pprint({"error-message.invalid-custom-table"})
    end

    local _, ret, _ = xpcall (pcall_convert, err)
    return ret
end

function read_custom_colors_table()
    local color_string_input = settings.global["atp-custom-colors-list"].value
    if settings.global["atp-custom-colors-enable"].value ~= "Off" then
        custom_colors  = table_error_handler(color_string_input)
    end
end