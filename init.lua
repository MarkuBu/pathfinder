
pathfinder = {}


--~ minetest.get_content_id(name)
--~ minetest.registered_nodes
--~ minetest.get_name_from_content_id(id)
--~ local ivm = a:index(pos.x, pos.y, pos.z)
--~ local ivm = a:indexp(pos)
--~ minetest.hash_node_position({x=,y=,z=})
--~ minetest.get_position_from_hash(hash)

print("loading pathfinder")

local openSet = {}
local closedSet = {}

local vm
local a
local data


local function get_distance(start_pos, end_pos)

	local distX = math.abs(start_pos.x - end_pos.x)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return 14 * distZ + 10 * (distX - distZ)
	else
		return 14 * distX + 10 * (distZ - distX)
	end
end

local function walkable(name)
		return minetest.registered_nodes[name].walkable
end

function pathfinder.find_path(endpos, pos, entity)
	local start_index = minetest.hash_node_position(pos)
	local target_index = minetest.hash_node_position(endpos)
	local count = 1

	openSet = {}
	closedSet = {}

	openSet[start_index] = {hCost = 0, gCost = 0, fCost = 0, parent = 0, pos = pos}

	-- Entity values
	--~ local entity_height = entity.collisionbox[5] - entity.collisionbox[2]

	repeat
		local current_index
		local current_values
		for i, v in pairs(openSet) do
			current_index = i
			current_values = v
			break
		end
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
			print("Success")
			local path = {}
			repeat
				table.insert(path, closedSet[current_index].pos)
				current_index = closedSet[current_index].parent
				if #path > 100 then
					print("path to long")
					openSet = nil
					closedSet = nil
					return
				end
			until start_index == current_index

			openSet = nil
			closedSet = nil
			print("path lenght: "..#path)
			return path
		end

		local current_pos = current_values.pos

		local neighbors = {}
		local neighbors_index = 1
		for z = -1, 1 do
		for x = -1, 1 do
			local neighbor_pos = {x = current_pos.x + x, y = current_pos.y, z = current_pos.z + z}
			local neighbor_name = minetest.get_node(neighbor_pos).name
			local neighbor_hash = minetest.hash_node_position(neighbor_pos)
			neighbors[neighbors_index] = {
					name = neighbor_name,
					hash = neighbor_hash,
					pos = neighbor_pos,
					walkable = walkable(neighbor_name),
			}
			neighbors_index = neighbors_index + 1
		end
		end

		for id, neighbor in pairs(neighbors) do
			-- don't cut corners
			local cut_corner = false
			if id == 1 then
				if neighbors[id + 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 3 then
				if neighbors[id - 1].walkable or neighbors[id + 3].walkable then
					cut_corner = true
				end
			elseif id == 7 then
				if neighbors[id + 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			elseif id == 9 then
				if neighbors[id - 1].walkable or neighbors[id - 3].walkable then
					cut_corner = true
				end
			end

			if neighbor.hash ~= current_index and not closedSet[neighbor.hash] and not neighbor.walkable and not cut_corner then
				local move_cost_to_neighbor = current_values.gCost + get_distance(current_values.pos, neighbor.pos)
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
		if count > 100 then
			print("fail")
			return
		end
	until count < 1
	print("count < 1")
	return
end
