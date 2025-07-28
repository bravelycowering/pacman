local shader = love.graphics.newShader "shader.glsl"
local palette = love.graphics.newImage "assets/palette.png"
local texture = love.graphics.newImage "assets/texture.png"
local font = love.graphics.newImage "font.png"

shader:send("palette", palette)
shader:send("palette_size", {palette:getDimensions()})

local function setPalette(index)
	shader:send("index", index)
end

local function setOpaque(opaque)
	shader:send("opaque", opaque)
end

local tileQuads = {}
for i = 0, 255 do
	tileQuads[i] = love.graphics.newQuad((i % 16) * 8, math.floor(i / 16) * 8, 8, 8, 128, 256)
end

local charQuads = {}
for i = 0, 255 do
	charQuads[i] = love.graphics.newQuad((i % 16) * 8, math.floor(i / 16) * 8, 8, 8, 128, 128)
end

local function tile(x)
	return tileQuads[x % 256]
end

local function char(x)
	return charQuads[x % 256]
end

local function enableShader()
	love.graphics.setShader(shader)
end

local function quadStrip(count, x, y, width, height, sw, sh)
	local quads = {}
	for i = 1, count do
		quads[i] = love.graphics.newQuad(x, y, width, height, sw, sh)
		x = x + width
	end
	return quads
end

local function quadColumn(count, x, y, width, height, sw, sh)
	local quads = {}
	for i = 1, count do
		quads[i] = love.graphics.newQuad(x, y, width, height, sw, sh)
		y = y + height
	end
	return quads
end

local function draw(...)
	love.graphics.draw(texture, ...)
end

local function text(str, anchorx, anchory)
	anchorx = anchorx or 0
	anchory = anchory or 0
	local sb = love.graphics.newSpriteBatch(font, #str)
	local w, h = 0, 0
	local x, y = 0, 0
	for i = 1, #str do
		if string.byte(str, i) == 13 then
			x = 0
			y = y + 8
		else
			x = x + 8
		end
		w = math.max(w, x)
		h = math.max(h, y + 8)
	end
	x, y = -w * anchorx, -h * anchory
	for i = 1, #str do
		local b = string.byte(str, i)
		if b == 13 then
			x = -w * anchorx
			y = y + 8
		else
			sb:add(char(b), x, y)
			x = x + 8
		end
	end
	return sb
end

return {
	quadStrip = quadStrip,
	quadColumn = quadColumn,
	quad = love.graphics.newQuad,
	tile = tile,
	draw = draw,
	text = text,
	setPalette = setPalette,
	setOpaque = setOpaque,
	enableShader = enableShader,
}