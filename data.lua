local function quad(x, y, width, height)
	return love.graphics.newQuad(x, y, width, height, 128, 256)
end

local function quadStrip(count, x, y, width, height)
	local quads = {}
	for i = 1, count do
		quads[i] = love.graphics.newQuad(x, y, width, height, 128, 256)
		x = x + width
	end
	return quads
end

local function quadColumn(count, x, y, width, height)
	local quads = {}
	for i = 1, count do
		quads[i] = love.graphics.newQuad(x, y, width, height, 128, 256)
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
		quadStrip(2, 0, 128, 16, 16), -- left
		quadStrip(2, 32, 128, 16, 16), -- up
		quadStrip(2, 64, 128, 16, 16), -- right
		quadStrip(2, 96, 128, 16, 16), -- down
		quadColumn(2, 80, 192, 16, 16), -- frightened
	}

	data.ghostscore = quadColumn(4, 64, 192, 16, 16) -- 200, 400, 800, 1600

	data.pacmananim = {
		quadStrip(4, 0, 192, 16, 16), -- left
		quadStrip(4, 0, 208, 16, 16), -- up
		quadStrip(4, 0, 224, 16, 16), -- right
		quadStrip(4, 0, 240, 16, 16), -- down
	}

	data.pacmanbig = quadStrip(3, 0, 160, 32, 32)

	data.pacmandie = concat(quadColumn(6, 96, 160, 16, 16), quadColumn(6, 112, 160, 16, 16))

	data.mobilearrows = concat(quadStrip(2, 80, 240, 8, 8), quadStrip(2, 80, 248, 8, 8))

	data.unusedsprite = quad(80, 224, 16, 16)
end

-- ======== CONSTANTS ========

data.width = 28
data.height = 36

-- ======== MAZE DATA ========

data.mazewidth = 28
data.mazeheight = 32

return data