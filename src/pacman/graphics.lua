local shader = love.graphics.newShader "pacman/shader.glsl"

local graphics = {}

local function setPalette(index)
	shader:send("index", index)
end

local function getPaletteColor(x, y)
	return {graphics.palettedata:getPixel(x, y)}
end

local palstrip = {}

local function getPaletteStrip(x)
	if not palstrip[x] then
		local h = graphics.palettedata:getHeight()
		local imgdat = love.image.newImageData(1, h)
		for y = 0, h - 1 do
			imgdat:setPixel(0, y, graphics.palettedata:getPixel(x, y))
		end
		palstrip[x] = love.graphics.newImage(imgdat)
	end
	return palstrip[x]
end

local function getMaxPalette()
	return graphics.palettedata:getWidth() - 1
end

local function setOpaque(opaque)
	shader:send("opaque", opaque)
end

local tileQuads = {}
for i = 0, 255 do
	tileQuads[i] = love.graphics.newQuad((i % 16) * 8, math.floor(i / 16) * 8, 8, 8, 256, 256)
end

local function tile(x)
	return tileQuads[x % 256]
end

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

local function draw(...)
	love.graphics.draw(graphics.texture, ...)
end

local function reload(texture, palette)
	local texdat
	local paldat
	if type(texture) == "string" then
		texdat = love.image.newImageData(texture)
	elseif type(texture) == "nil" then
		texdat = love.image.newImageData("pacman/texture.png")
	else
		texdat = texture
	end
	if type(palette) == "string" then
		paldat = love.image.newImageData(palette)
	elseif type(palette) == "nil" then
		paldat = love.image.newImageData "pacman/palette.png"
	else
		paldat = palette
	end
	graphics.palettedata = paldat
	graphics.palette = love.graphics.newImage(paldat)
	graphics.palette:setFilter("nearest", "nearest")
	graphics.texture = love.graphics.newImage(texdat)
	graphics.texture:setFilter("nearest", "nearest")
	shader:send("palette", graphics.palette)
	shader:send("palette_size", {graphics.palette:getDimensions()})

	graphics.ghostanim = {
		quadStrip(2, 0, 128, 16, 16), -- right
		quadStrip(2, 32, 128, 16, 16), -- down
		quadStrip(2, 64, 128, 16, 16), -- left
		quadStrip(2, 96, 128, 16, 16), -- up
		quadColumn(2, 80, 192, 16, 16), -- frightened
	}

	graphics.ghostscore = quadColumn(4, 64, 192, 16, 16) -- 200, 400, 800, 1600

	graphics.score = {
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

	graphics.pacmananim = {
		quadStrip(4, 0, 192, 16, 16), -- right
		quadStrip(4, 0, 208, 16, 16), -- down
		quadStrip(4, 0, 224, 16, 16), -- left
		quadStrip(4, 0, 240, 16, 16), -- up
	}

	graphics.pacmanbig = quadStrip(3, 0, 160, 32, 32)

	graphics.pacmandie = concat(quadColumn(6, 96, 160, 16, 16), quadColumn(6, 112, 160, 16, 16))

	graphics.mobilearrows = concat(quadStrip(2, 64, 240, 8, 8), quadStrip(2, 64, 248, 8, 8))

	graphics.unusedsprite = quad(80, 224, 16, 16)
end

reload()

graphics.tile = tile
graphics.draw = draw
graphics.setPalette = setPalette
graphics.getPaletteColor = getPaletteColor
graphics.getMaxPalette = getMaxPalette
graphics.setOpaque = setOpaque
graphics.shader = shader
graphics.reload = reload

return graphics