local function quad(x, y, width, height)
	return love.graphics.newQuad(x, y, width, height, 256, 256)
end

local function quadStrip(count, x, y, width, height)
	local quads = {}
	for i = 1, count do
		quads[i] = quad(x, y, width, height)
		x = x + width
	end
	return quads
end

local function quadColumn(count, x, y, width, height)
	local quads = {}
	for i = 1, count do
		quads[i] = quad(x, y, width, height)
		y = y + height
	end
	return quads
end

local function concat(...)
	local tbl = {}
	for i, t in ipairs({...}) do
		for index, value in ipairs(t) do
			tbl[#tbl+1] = value
		end
	end
	return tbl
end

local data = {}

-- ======== SPRITES ========

function data.loadSprites()
	data.ghostanim = {
		quadStrip(2, 0, 128, 16, 16), -- right
		quadStrip(2, 32, 128, 16, 16), -- down
		quadStrip(2, 64, 128, 16, 16), -- left
		quadStrip(2, 96, 128, 16, 16), -- up
		quadColumn(2, 80, 192, 16, 16), -- frightened
	}

	data.ghostscore = quadColumn(4, 64, 192, 16, 16) -- 200, 400, 800, 1600

	data.score = {
		[0] = quad(64, 192, 8, 8),
		[1] = quad(72, 192, 8, 8),
		[2] = quad(64, 200, 8, 8),
		[3] = quad(72, 200, 8, 8),
		[4] = quad(64, 208, 8, 8),
		[5] = quad(72, 208, 8, 8),
		[6] = quad(64, 216, 8, 8),
		[7] = quad(72, 216, 8, 8),
		[8] = quad(64, 224, 8, 8),
		[9] = quad(72, 224, 8, 8),
		[16] = quad(64, 232, 8, 8),
	}

	data.pacmananim = {
		quadStrip(4, 0, 192, 16, 16), -- right
		quadStrip(4, 0, 208, 16, 16), -- down
		quadStrip(4, 0, 224, 16, 16), -- left
		quadStrip(4, 0, 240, 16, 16), -- up
	}

	data.pacmanbig = quadStrip(3, 0, 160, 32, 32)

	data.pacmandie = concat(quadColumn(6, 96, 160, 16, 16), quadColumn(6, 112, 160, 16, 16))

	data.mobilearrows = concat(quadStrip(2, 64, 240, 8, 8), quadStrip(2, 64, 248, 8, 8))

	data.unusedsprite = quad(80, 224, 16, 16)
end

-- ======== CONSTANTS ========

data.width = 28
data.height = 36

-- ======== POI ========

data.poi = {}
data.poiargs = {}
data.poinames = {}

local FLAG = string.byte "F"

local function poi(name)
	return function(id, formatstr)
		local names = {}
		local args = {}
		if formatstr then
			for m in formatstr:gmatch("%S+") do
				local colon = m:find(":")
				local k, v = m:sub(1, colon - 1), m:sub(colon + 1)
				if v:byte(1) == FLAG then
					local flagnames = {}
					for f in k:gmatch("[^,]+") do
						flagnames[#flagnames+1] = f
					end
					k = flagnames
					v = "I"..v:sub(2)
				end
				names[#names+1] = k
				args[#args+1] = v
			end
		end
		data.poi[id] = name
		data.poiargs[id] = args
		data.poinames[id] = names
	end
end

poi "pacman" (1, "subpos:I1")
poi "ghost" (2, "subpos:I1 behavior:I1 palette:I1 direction:I1")
poi "status" (3)
poi "fruit" (4, "subpos:I1")
poi "ghostbox" (5, "x2:I1 y2:I1")

local poidebug = false
if poidebug then
	for key, value in pairs(data.poi) do
		print(key, value, ">"..table.concat(data.poiargs[key]))
		for i, v in ipairs(data.poiargs[key]) do
			local k = data.poinames[key][i]
			if type(k) == "table" then
				print("", table.concat(k, ","), v)
			else
				print("", k, v)
			end
		end
	end
end

return data