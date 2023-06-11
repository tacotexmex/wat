-- Create public mod table
wat = {
    itemstring = {},
    description = {}
}

-- Check mod settings
local show_itemstring = minetest.settings:get_bool("wat.itemstring") or true

-- Check for Scramble mod
local scramble_exists = minetest.get_modpath("scramble")

-- Create HUD for new players
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    -- Create HUD element for node description
    wat.description[name] = player:hud_add({
        name = "wat:description",
        position = {
            x = 0.5,
            y = 0
        },
        hud_elem_type = "text",
        number = 0xFFFFFF,
        alignment = 0,
        offset = {
            x = 0,
            y = 34
        },
        text = ""
    })
    if show_itemstring then
        -- Create HUD element for node name
        wat.itemstring[name] = player:hud_add({
            name = "wat:name",
            position = {
                x = 0.5,
                y = 0
            },
            hud_elem_type = "text",
            number = 0xE5E5E5,
            alignment = 0,
            offset = {
                x = 0,
                y = 54
            },
            text = ""
        })
    end
end)

-- Create timer variable
local timer = 0
-- Create loop for updating frequency
minetest.register_globalstep(function(dtime)
    -- Iterate on timer with past time
    timer = timer + dtime
    -- Do things when 200 milliseconds have passed
    if timer > 0.2 then
        -- Check for all online players
        for _, player in pairs(minetest:get_connected_players()) do
            -- Get player name
            local name = player:get_player_name()
            -- Get pointed node
            local pointed = pointlib.update(player)
            local itemstring = pointed.itemstring or ""
            local description = ""
            -- If both itemstring and description
            if itemstring ~= "" and minetest.registered_nodes[itemstring].description then
                -- Get node description
                description = minetest.registered_nodes[itemstring].description
            end
            if scramble_exists or string.sub(itemstring, 1, 2) == "0x" then
                itemstring = scramble.unhash(itemstring) or ""
            end
            -- Update itemstring HUD if setting is true
            if show_itemstring then
                player:hud_change(wat.itemstring[name], "text", itemstring)
            end
            -- Update description HUD
            player:hud_change(wat.description[name], "text", description)
        end
        -- Reset timer
        timer = 0
    end
end)
