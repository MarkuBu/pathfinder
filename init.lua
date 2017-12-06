
pathfinder = {}

--[[
minetest.get_content_id(name)
minetest.registered_nodes
minetest.get_name_from_content_id(id)
local ivm = a:index(pos.x, pos.y, pos.z)
local ivm = a:indexp(pos)
minetest.hash_node_position({x=,y=,z=})
minetest.get_position_from_hash(hash)

start_index, target_index, current_index
^ Hash of position

current_value
^ {int:hCost, int:gCost, int:fCost, hash:parent, vect:pos}
]]--

local openSet = {}
local closedSet = {}

local function get_distance(start_pos, end_pos)
	local distX = math.abs(start_pos.x - end_pos.x)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return 14 * distZ + 10 * (distX - distZ)
	else
		return 14 * distX + 10 * (distZ - distX)
	end
end

local function get_distance_to_neighbor(start_pos, end_pos)
	local distX = math.abs(start_pos.x - end_pos.x)
	local distY = math.abs(start_pos.y - end_pos.y)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return (14 * distZ + 10 * (distX - distZ)) * (distY + 1)
	else
		return (14 * distX + 10 * (distZ - distX)) * (distY + 1)
	end
end

local function walkable(node, pos, current_pos)
		if string.find(node.name,"doors:door") then
			if (node.param2 == 0 or
					node.param2 == 2) and
					math.abs(pos.z - current_pos.z) > 0 and
					pos.x == current_pos.x then
				return true
			elseif (node.param2 == 1 or
					node.param2 == 3) and
					math.abs(pos.z - current_pos.z) > 0 and
					pos.x == current_pos.x then
				return false
			elseif (node.param2 == 0 or
					node.param2 == 2) and
					math.abs(pos.x - current_pos.x) > 0 and
					pos.z == current_pos.z then
				return false
			elseif (node.param2 == 1 or
					node.param2 == 3) and
					math.abs(pos.x - current_pos.x) > 0 and
					pos.z == current_pos.z then
				return true
			end
		elseif string.find(node.name,"doors:hidden") then
			local node_door = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
			if (node_door.param2 == 0 or
					node_door.param2 == 2) and
					math.abs(pos.z - current_pos.z) > 0 and
					pos.x == current_pos.x then
				return true
			elseif (node_door.param2 == 1 or
					node_door.param2 == 3) and
					math.abs(pos.z - current_pos.z) > 0 and
					pos.x == current_pos.x then
				return false
			elseif (node_door.param2 == 0 or
					node_door.param2 == 2) and
					math.abs(pos.x - current_pos.x) > 0 and
					pos.z == current_pos.z then
				return false
			elseif (node_door.param2 == 1 or
					node_door.param2 == 3) and
					math.abs(pos.x - current_pos.x) > 0 and
					pos.z == current_pos.z then
				return true
			end

		end
		return minetest.registered_nodes[node.name].walkable
end

local function get_neighbor_ground_level(pos, jump_height, fall_height, current_pos)
	local node = minetest.get_node(pos)
	local height = 0
	if walkable(node, pos, current_pos) then
		repeat
			height = height + 1
			if height > jump_height then
				return nil
			end
			pos.y = pos.y + 1
			node = minetest.get_node(pos)
		until not walkable(node, pos, current_pos)
		return pos
	else
		repeat
			height = height + 1
			if height > fall_height then
				return nil
			end
			pos.y = pos.y - 1
			node = minetest.get_node(pos)
		until walkable(node, pos, current_pos)
		return {x = pos.x, y = pos.y + 1, z = pos.z}
	end
end

-- local function dot(a, b)
-- 	return a.x * b.x + a.y * b.y + a.z * b.z
-- end
--
-- local function len(a)
--   return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
-- end
--
-- local function lensq(a)
--   return a.x * a.x + a.y * a.y + a.z * a.z
-- end
--
-- local function normalize(a)
--   local l = len(a)
--   a.x = a.x / l
--   a.y = a.y / l
--   a.z = a.z / l
--   return a
-- end

function pathfinder.find_path(pos, endpos, entity, dtime)
	-- if dtime > 0.1 then
	-- 	return
	-- end
	-- round positions if not done by former functions
	pos = {
			x = math.floor(pos.x + 0.5),
			y = math.floor(pos.y + 0.5),
			z = math.floor(pos.z + 0.5)
	}

	endpos = {
			x = math.floor(endpos.x + 0.5),
			y = math.floor(endpos.y + 0.5),
			z = math.floor(endpos.z + 0.5)
	}

	local target_node = minetest.get_node(endpos)
	if walkable(target_node, endpos, endpos) then
		endpos.y = endpos.y + 1
	end

	local start_node = minetest.get_node(pos)
	if string.find(start_node.name,"doors:door") then
		if start_node.param2 == 0 then
			pos.z = pos.z + 1
		elseif start_node.param2 == 1 then
			pos.x = pos.x + 1
		elseif start_node.param2 == 2 then
			pos.z = pos.z - 1
		elseif start_node.param2 == 3 then
			pos.x = pos.x - 1
		end
	end

	local start_time = minetest.get_us_time()
	local start_index = minetest.hash_node_position(pos)
	local target_index = minetest.hash_node_position(endpos)
	local count = 1

	openSet = {}
	closedSet = {}
	-- minetest.set_node(pos, {name = "default:glass"})
	-- minetest.set_node(endpos, {name = "default:glass"})
	-- print(dump(pos))
	-- print(endpos)

	local h_start = get_distance(pos, endpos)
	openSet[start_index] = {hCost = h_start, gCost = 0, fCost = h_start, parent = nil, pos = pos}

	-- Entity values
	local entity_height = math.ceil(entity.collisionbox[5] - entity.collisionbox[2]) or 2
	local entity_fear_height = entity.fear_height or 3
	local entity_jump_height = entity.jump_height or 1
	local neighbors_cache = {}

	repeat
		local current_index
		local current_values

		-- Get one index as reference from openSet
		for i, v in pairs(openSet) do
			current_index = i
			current_values = v
			break
		end
		-- Search for lowest fCost
		for i, v in pairs(openSet) do
			if v.fCost < openSet[current_index].fCost or v.fCost == current_values.fCost and v.hCost < current_values.hCost then
				current_index = i
				current_values = v
			end
		end

		openSet[current_index] = nil
		closedSet[current_index] = current_values
		count = count - 1

		if current_index == target_index then
			--~ minetest.chat_send_all("Found path in " .. (minetest.get_us_time() - start_time) / 1000 .. "ms")
			local path = {}
			repeat
				if not closedSet[current_index] then
					return
				end
				table.insert(path, closedSet[current_index].pos)
				current_index = closedSet[current_index].parent
			until start_index == current_index
			table.insert(path, closedSet[current_index].pos)
			local reverse_path = {}
			repeat
				table.insert(reverse_path, table.remove(path))
			until #path == 0
			minetest.chat_send_all("Found path in " .. (minetest.get_us_time() - start_time) / 1000 .. "ms. " .. "Path length: " .. #reverse_path)
			return reverse_path
		end

		local current_pos = current_values.pos

		local neighbors = {}
		local neighbors_index = 1
		for z = -1, 1 do
		for x = -1, 1 do
			local neighbor_pos = {x = current_pos.x + x, y = current_pos.y, z = current_pos.z + z}
			local neighbor = minetest.get_node(neighbor_pos)
			local neighbor_ground_level = get_neighbor_ground_level(neighbor_pos, entity_jump_height, entity_fear_height, current_pos)
			local neighbor_clearance = false
			if neighbor_ground_level then
				local neighbor_hash = minetest.hash_node_position(neighbor_ground_level)
				local pos_above_head = {x = current_pos.x, y = current_pos.y + entity_height, z = current_pos.z}
				local node_above_head = minetest.get_node(pos_above_head)
				if neighbor_ground_level.y - current_pos.y > 0 and not walkable(node_above_head, pos_above_head, current_pos) then
					local height = -1
					repeat
						height = height + 1
						local pos = {	x = neighbor_ground_level.x,
										y = neighbor_ground_level.y + height,
										z = neighbor_ground_level.z}
						local node = minetest.get_node(pos)
					until walkable(node, pos, current_pos) or height > entity_height
					if height >= entity_height then
						neighbor_clearance = true
					end
				elseif neighbor_ground_level.y - current_pos.y > 0 and walkable(node_above_head, pos_above_head, current_pos) then
					neighbors[neighbors_index] = {
							hash = nil,
							pos = nil,
							clear = nil,
							walkable = nil,
					}
				else
					local height = -1
					repeat
						height = height + 1
						local pos = {	x = neighbor_ground_level.x,
										y = current_pos.y + height,
										z = neighbor_ground_level.z}
						local node = minetest.get_node(pos)
					until walkable(node, pos, current_pos) or height > entity_height
					if height >= entity_height then
						neighbor_clearance = true
					end
				end

				neighbors[neighbors_index] = {
						hash = minetest.hash_node_position(neighbor_ground_level),
						pos = neighbor_ground_level,
						clear = neighbor_clearance,
						walkable = walkable(neighbor, neighbor_pos, current_pos),
				}
			else
				neighbors[neighbors_index] = {
						hash = nil,
						pos = nil,
						clear = nil,
						walkable = nil,
				}
			end

			neighbors_index = neighbors_index + 1
		end
		end

		for id, neighbor in pairs(neighbors) do
			-- don't cut corners
			local cut_corner = false
			if id == 1 then
				if not neighbors[id + 1].clear or not neighbors[id + 3].clear
						or neighbors[id + 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 3 then
				if not neighbors[id - 1].clear or not neighbors[id + 3].clear
						or neighbors[id - 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 7 then
				if not neighbors[id + 1].clear or not neighbors[id - 3].clear
						or neighbors[id + 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			elseif id == 9 then
				if not neighbors[id - 1].clear or not neighbors[id - 3].clear
						or neighbors[id - 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			end
			if neighbor.hash ~= current_index and not closedSet[neighbor.hash] and neighbor.clear and not cut_corner then
				local move_cost_to_neighbor = current_values.gCost + get_distance_to_neighbor(current_values.pos, neighbor.pos)
				local gCost = 0
				if openSet[neighbor.hash] then
					gCost = openSet[neighbor.hash].gCost
				end
				if move_cost_to_neighbor < gCost or not openSet[neighbor.hash] then
					if not openSet[neighbor.hash] then
						count = count + 1
					end
					local hCost = get_distance(neighbor.pos, endpos)
					openSet[neighbor.hash] = {
							gCost = move_cost_to_neighbor,
							hCost = hCost,
							fCost = move_cost_to_neighbor + hCost,
							parent = current_index,
							pos = neighbor.pos
					}
				end
			end
		end
		if count > 300 then
			minetest.chat_send_all("Path fail")
			return
		end
		if (minetest.get_us_time() - start_time) / 1000 > 30 - dtime * 50 then
			minetest.chat_send_all("Path timeout")
			return
		end
	until count < 1
	minetest.chat_send_all("count < 1")
	return {pos}
end
