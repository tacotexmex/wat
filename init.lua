-- Create mod table for storing player values
local wat = {}

-- Check mod settings
local technical_name = minetest.settings:get_bool("wat.technical_name") or false
local hud_timeout = tonumber(minetest.settings:get("wat.hud_timeout")) or 2

-- Check for Pointlib mod
local pointlib_exists = minetest.get_modpath("pointlib")

-- Check for Scramble mod
local scramble_exists = minetest.get_modpath("scramble")

-- Create HUD for new players
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	-- Create HUD element for node description
	wat[name] = player:hud_add({
		name = "wat:text",
		position = {
			x = 0,
			y = 0.17,
		},
		hud_elem_type = "text",
		number = 0xFFFFFF,
		alignment = {
			x = 1,
			y = -1,
		},
		style = 0,
		offset = {
			x = 134,
			y = 0,
		},
		text = "",
	})
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player:hud_remove(wat[name])
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
				local node_name = pointed.itemstring or ""
				local description = ""
				-- If both node_name and description
				if node_name ~= "" and minetest.registered_nodes[node_name].description then
					-- Get node description
					description = minetest.registered_nodes[node_name].description
				end
				if scramble_exists or string.sub(node_name, 1, 2) == "0x" then
					node_name = scramble.unhash(node_name) or ""
				end
				-- Define what text should be drawn
				local text = description
				if technical_name then
					text = text .. "\n" .. node_name
				end
				text = text .. "\n"
				-- Update description HUD
				player:hud_change(wat[name], "text", text)
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
	minetest.register_on_punchnode(function(pos, node, player, pointed_thing)
		-- Ensure that the thing punched is a node
		if pointed_thing.type ~= "node" then
			return
		end
		-- Variables for the node_name name and the node description
		local node_name
		local description
		-- Get player name
		local name = player:get_player_name()
		-- Set the node_name
		node_name = node.name
		-- Unhash the node_name if hashed by scramble mod
		if scramble_exists or string.sub(node_name, 1, 2) == "0x" then
			node_name = scramble.unhash(node_name)
		end
		-- Get the node description
		description = minetest.registered_nodes[node_name].description
		-- Define what text should be drawn
		local text = description
		if technical_name then
			text = text .. "\n" .. node_name
		end
		text = text .. "\n"
		-- Draw the description in the HUD item
		player:hud_change(wat[name], "text", text)
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
				if wathudtimer[name] >= hud_timeout then
					-- Clear the HUD item of text
					player:hud_change(wat[name], "text", "")
				end
			end
			-- Reset the timer
			timer = 0
		end
	end)
end
