
-- note: fastfaces are generated in x-direction
-- => don't make stripes in x-dir (in north-east)

-- north: +z
-- east: +x

local layer_y = -5

local function register_colored_node(name, r, g, b)
	assert(not minetest.registered_nodes[name])
	for _, c in ipairs({r, g, b}) do
		assert(math.floor(c) == c)
		assert(c >= 0x0)
		assert(c <= 0xff)
	end
	minetest.register_node(name, {
		description = name,
		tiles = {string.format("blank.png^[noalpha^[colorize:#%.2x%.2x%.2x:255", r, g, b)},
		groups = {cracky = 1}
	})
end

register_colored_node("test_mapblock_drawcalls:estagkh", 0xf0, 0, 0) -- TODO: remove

local function range_map_tolist0(min, max, step, fun)
	local t = {}
	local idx = 0
	for i = min, max, step do
		t[idx] = fun(i)
		idx = idx + 1
	end
	return t
end

local areas = {
	{ -- north-east
		minp = vector.new(0, layer_y, 0),
		maxp = vector.new(math.huge, layer_y, math.huge), -- inclusive
		dimens = vector.new(2, 1, 1), -- dimensions of the nodes array below
		nodes = { -- [z][y][x]
			[0] = "test_mapblock_drawcalls:ne_0",
			"test_mapblock_drawcalls:ne_1",
		},
	},
	{ -- north-west
		minp = vector.new(-math.huge, layer_y, 0),
		maxp = vector.new(-1, layer_y, math.huge),
		dimens = vector.new(16, 1, 1),
		nodes = range_map_tolist0(0, 15, 1, function(i)
			return "test_mapblock_drawcalls:nw_"..i
		end),
	},
	{ -- south-west
		minp = vector.new(-math.huge, layer_y, -math.huge),
		maxp = vector.new(-1, layer_y, -1),
		dimens = vector.new(16, 1, 16),
		nodes = range_map_tolist0(0, 16*16-1, 1, function(i)
			return "test_mapblock_drawcalls:sw_"..i
		end),
	},
	{ -- south-east
		minp = vector.new(0, layer_y, -math.huge),
		maxp = vector.new(math.huge, layer_y, -1),
		dimens = vector.new(32, 1, 32),
		nodes = range_map_tolist0(0, 32*32-1, 1, function(i)
			return "test_mapblock_drawcalls:se_"..i
		end),
	},
}

do
	register_colored_node("test_mapblock_drawcalls:ne_0", 0x22, 0x22, 0x22)
	register_colored_node("test_mapblock_drawcalls:ne_1", 0x99, 0x99, 0x99)

	for x = 0, 15 do
		local c = x * 0x11
		register_colored_node("test_mapblock_drawcalls:nw_"..x, c, c, c)
	end

	for z = 0, 15 do
		for x = 0, 15 do
			local i = z * 16 + x
			register_colored_node("test_mapblock_drawcalls:sw_"..i, x * 0x11, z * 0x11, 0)
		end
	end

	for z = 0, 31 do
		local zc = math.floor(z * (0xff/31) + 0.5)
		for x = 0, 31 do
			local xc = math.floor(x * (0xff/31) + 0.5)
			local i = z * 32 + x
			register_colored_node("test_mapblock_drawcalls:se_"..i, xc, 0, zc)
		end
	end
end

local function generate_area(minp, maxp, area, vmanip_p)
	minp = vector.combine(minp, area.minp, math.max)
	maxp = vector.combine(maxp, area.maxp, math.min)
	if minp.x > maxp.x or minp.y > maxp.y or minp.z > maxp.z then
		return
	end

	local vmanip = vmanip_p[1]
	if not vmanip then
		vmanip = minetest.get_mapgen_object("voxelmanip")
		vmanip_p[1] = vmanip
	end

	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
	for x = minp.x, maxp.x do
		local p = vector.new(x, y, z)
		local lp = vector.combine(p, area.dimens, function(a, b) return a % b end)
		local idx = (lp.z * area.dimens.y + lp.y) * area.dimens.x + lp.x
		vmanip:set_node_at(p, {name = area.nodes[idx]})
	end
	end
	end
end

-- maxp is inclusive
minetest.register_on_generated(function(minp, maxp, _blockseed)
	--~ local t0 = minetest.get_us_time()

	local vmanip_p = {}
	for _, area in ipairs(areas) do
		generate_area(minp, maxp, area, vmanip_p)
	end
	if vmanip_p[1] then
		vmanip_p[1]:write_to_map()
	end

	--~ local t1 = minetest.get_us_time()
	--~ minetest.log("on_generate_took "..(t1-t0).." ms")
end)
