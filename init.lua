
pathfinder = {}


--~ minetest.get_content_id(name)
--~ minetest.registered_nodes
--~ minetest.get_name_from_content_id(id)
--~ local ivm = a:index(pos.x, pos.y, pos.z)
--~ local ivm = a:indexp(pos)

print("loading pathfinder")

local openSet = {}
local closedSet = {}

local vm
local a
local data


local function get_distance(start_index, end_index)
	local start_pos = a:position(start_index)
	local end_pos = a:position(end_index)

	local distX = math.abs(start_pos.x - end_pos.x)
	local distZ = math.abs(start_pos.z - end_pos.z)

	if distX > distZ then
		return 14 * distZ + 10 * (distX - distZ)
	else
		return 14 * distX + 10 * (distZ - distX)
	end
end

local function walkable(node_id)
	if node_id then
		local name = minetest.get_name_from_content_id(node_id)
		return minetest.registered_nodes[name].walkable
	end
	-- out of range.
	return true
end

function pathfinder.find_path(endpos, pos, entity)

	local radius = vector.distance(pos, endpos) + 32
	vm = VoxelManip()
	local minp, maxp = vm:read_from_map(
			vector.subtract(pos, {x=radius, y=16, z=radius}),
			vector.add(pos, {x=radius, y=16, z=radius})
	)
	a = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	data = vm:get_data()

	local starttime = minetest.get_us_time()

	local start_index = a:indexp(pos)
	local target_index = a:indexp(endpos)
	local count = 1

	openSet = {}
	closedSet = {}

	openSet[start_index] = {hCost = 0, gCost = 0, fCost = 0, parent = 0, pos = pos}

	-- Entity values
	local entity_height = entity.collisionbox[5] - entity.collisionbox[2]
--~ print(dump(entity))
--~ print(entity.object:get_luaentity().name)
--~ print(dump(minetest.registered_entities[entity.object:get_luaentity().name]))
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
			--~ local file = io.open("debug.txt", "w")
			--~ io.output(file)
			--~ io.write(start_index.." "..target_index)
			--~ io.write(dump(closedSet))
			--~ io.write(dump(openSet))
			--~ io.close(file)
			repeat
				table.insert(path, a:position(closedSet[current_index].parent))
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
			print("Pathfinder: "..(minetest.get_us_time() - starttime) / 1000 .."ms")
			print("path lenght: "..#path)
			return path
		end

		local current_pos = a:position(current_index)

		local neighbors = {}
		for neighbor in a:iterp({x = current_pos.x - 1, y = current_pos.y, z = current_pos.z - 1},
				{x = current_pos.x + 1, y = current_pos.y, z = current_pos.z + 1}) do
			table.insert(neighbors, neighbor)
		end

		for id, neighbor in ipairs(neighbors) do
			-- don't cut corners
			local cut_corner = false
			if id == 1 then
				if walkable(data[neighbors[id + 1]]) or walkable(data[neighbors[id + 3]]) then
					cut_corner = true
				end
			elseif id == 3 then
				if walkable(data[neighbors[id - 1]]) or walkable(data[neighbors[id + 3]]) then
					cut_corner = true
				end
			elseif id == 7 then
				if walkable(data[neighbors[id + 1]]) or walkable(data[neighbors[id - 3]]) then
					cut_corner = true
				end
			elseif id == 9 then
				if walkable(data[neighbors[id - 1]]) or walkable(data[neighbors[id - 3]]) then
					cut_corner = true
				end
			end

			if neighbor ~= current_index and not closedSet[neighbor] and not walkable(data[neighbor]) and not cut_corner then
				local move_cost_to_neighbor = current_values.gCost + get_distance(current_index, neighbor)
				local gCost = 0
				if openSet[neighbor] then
					gCost = openSet[neighbor].gCost
				end
				if move_cost_to_neighbor < gCost or not openSet[neighbor] then
					local hCost = get_distance(neighbor, target_index)
					openSet[neighbor] = {
							gCost = move_cost_to_neighbor,
							hCost = hCost,
							fCost = move_cost_to_neighbor + hCost,
							parent = current_index,
							pos = a:position(neighbor)
					}
					count = count + 1
				end
			end
		end
		if count > 10000 then
			print("fail")
			return
		end
	until count < 1
	return
end
