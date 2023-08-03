-- Create public mod table
wat = {
	itemstring = {},
	description = {},
}

-- Check mod settings
local show_itemstring = minetest.settings:get_bool("wat.itemstring") or false

-- Check for Pointlib mod
local pointlib_exists = minetest.get_modpath("pointlib")

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
			y = 0,
		},
		hud_elem_type = "text",
		number = 0xFFFFFF,
		alignment = 0,
		offset = {
			x = 0,
			y = 34,
		},
		text = "",
	})
	if show_itemstring then
		-- Create HUD element for node name
		wat.itemstring[name] = player:hud_add({
			name = "wat:name",
			position = {
				x = 0.5,
				y = 0,
			},
			hud_elem_type = "text",
			number = 0xE5E5E5,
			alignment = 0,
			offset = {
				x = 0,
				y = 54,
			},
			text = "",
		})
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if show_itemstring then
		player:hud_remove(wat.itemstring[name])
	end
	player:hud_remove(wat.description[name])
end)

if pointlib_exists then
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
else
	-- Create timer variable
	local timer = 0
	-- Create HUD timer to keep track of the time HUD item has been visible
	local wathudtimer = {}
	-- Create HUD timer for player when joining
	minetest.register_on_joinplayer(function(player)
		local name = player:get_player_name()
		wathudtimer[name] = 0
	end)
	-- Register punch event
	minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
		-- Ensure that the thing punched is a node
		if pointed_thing.type ~= "node" then
			return
		end
		-- I like "player" more
		local player = puncher
		-- Variables for the itemstring name and the node description
		local itemstring
		local description
		-- Get player name
		local name = puncher:get_player_name()
		-- Set the itemstring
		itemstring = node.name
		-- Unhash the itemstring if hashed by scramble mod
		if scramble_exists or string.sub(itemstring, 1, 2) == "0x" then
			itemstring = scramble.unhash(itemstring)
		end
		-- Get the node description
		description = minetest.registered_nodes[itemstring].description
		-- Draw the itemstring in the HUD item if setting allows
		if show_itemstring then
			player:hud_change(wat.itemstring[name], "text", itemstring)
		end
		-- Draw the description in the HUD item
		player:hud_change(wat.description[name], "text", description)
		-- Reset the HUD timer to display its full cycle
		wathudtimer[name] = 0
	end)
	-- Register loop
	minetest.register_globalstep(function(dtime)
		-- Count time passed
		timer = timer + dtime
		-- If time passed is more than a second
		if timer >= 1 then
			-- Check for all online players
			for _, player in pairs(minetest:get_connected_players()) do
				-- Get player name
				local name = player:get_player_name()
				-- Postpone the clearing of text in the HUD item
				wathudtimer[name] = wathudtimer[name] + 1
				-- Check if HUD timer is surpassing 2 seconds
				if wathudtimer[name] >= 2 then
					-- Clear the HUD item of text
					if show_itemstring then
						player:hud_change(wat.itemstring[name], "text", "")
					end
					player:hud_change(wat.description[name], "text", "")
				end
			end
			-- Reset the timer
			timer = 0
		end
	end)
end
