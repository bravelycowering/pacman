local ui = {}

local icons = {}
for index, value in ipairs(love.filesystem.getDirectoryItems("ui/icons")) do
	local name = value:gsub("%.[^%.]+$", "")
	icons[name] = love.graphics.newImage("ui/icons/"..value)
	icons[name]:setFilter("nearest", "nearest")
end
ui.icons = icons

local achievements = {}
for i = 0, 25 do
	achievements[i] = love.graphics.newImage("ui/achievements/achv_"..tostring(i)..".png")
	achievements[i]:setFilter("nearest", "nearest")
end
ui.achievements = achievements

local scale = 1
local cursorx = 0
local cursory = 0
local sameline = false
local lasttouched
local istouched
local lasttouchedtimer = 0
local opacity = 1

local padding = 8
local iconpadding = 8
local spacing = 8
local margin = 8
local font = love.graphics.getFont()
local fontscale = 2
local transform = love.math.newTransform()

local mousex, mousey, pressed, released = 0, 0, false, false

local newText

local buttonsoft = love.graphics.newImage("ui/buttonsmooth.png")
local buttonsharp = love.graphics.newImage("ui/button.png")
buttonsharp:setFilter("nearest", "nearest")
local buttonquads = {
	ul = love.graphics.newQuad(0, 0, 2, 2, 5, 5),
	u = love.graphics.newQuad(2, 0, 1, 2, 5, 5),
	ur = love.graphics.newQuad(3, 0, 2, 2, 5, 5),
	l = love.graphics.newQuad(0, 2, 2, 1, 5, 5),
	m = love.graphics.newQuad(2, 2, 1, 1, 5, 5),
	r = love.graphics.newQuad(3, 2, 2, 1, 5, 5),
	bl = love.graphics.newQuad(0, 3, 2, 2, 5, 5),
	b = love.graphics.newQuad(2, 3, 1, 2, 5, 5),
	br = love.graphics.newQuad(3, 3, 2, 2, 5, 5),
}

local function drawbutton(x, y, w, h, hovered)
	local r, g, b, a = love.graphics.getColor()
	if hovered then
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(buttonsharp, buttonquads.u, x + 4, y, 0, w - 8, 2)
	love.graphics.draw(buttonsharp, buttonquads.l, x, y + 4, 0, 2, h - 8)
	love.graphics.draw(buttonsharp, buttonquads.r, x + w - 4, y + 4, 0, 2, h - 8)
	love.graphics.draw(buttonsharp, buttonquads.b, x + 4, y + h - 4, 0, w - 8, 2)
	if hovered then
		love.graphics.setColor(r, g, b, a)
	end
	love.graphics.draw(buttonsoft, buttonquads.m, x + 2, y + 2, 0, w - 4, h - 4)
	if hovered then
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.draw(buttonsharp, buttonquads.ul, x, y, 0, 2, 2)
	love.graphics.draw(buttonsharp, buttonquads.ur, x + w - 4, y, 0, 2, 2)
	love.graphics.draw(buttonsharp, buttonquads.bl, x, y + h - 4, 0, 2, 2)
	love.graphics.draw(buttonsharp, buttonquads.br, x + w - 4, y + h - 4, 0, 2, 2)
	if hovered then
		love.graphics.setColor(r, g, b, a)
	end
end

if love.getVersion() == 12 then
---@diagnostic disable-next-line: undefined-field
	newText = love.graphics.newTextBatch
else
	newText = love.graphics.newText
end

function ui.pressed(x, y)
	lasttouched = nil
	pressed, mousex, mousey = true, transform:inverseTransformPoint(x, y)
	istouched = true
end

function ui.released(x, y)
	released, mousex, mousey = true, transform:inverseTransformPoint(x, y)
	istouched = false
end

function ui.reset()
	scale = math.min(love.graphics.getWidth()/400, love.graphics.getHeight()/400)
	cursorx = 0
	cursory = 0
	sameline = false
	padding = 16
	iconpadding = 8
	spacing = 16
	margin = 0
	font = love.graphics.getFont()
	opacity = 1
	fontscale = 2
	if Mobile then
		margin = 8
	else
		scale = math.max(1, math.ceil(scale * 2 / 1.5) / 2)
	end
	pressed, released = false, false
	mousex, mousey = transform:inverseTransformPoint(love.mouse.getPosition())
	transform:reset()
	transform:scale(scale)
	if not istouched then
		lasttouchedtimer = lasttouchedtimer - 1
	end
end

function ui.opacity(o)
	if o then
		opacity = o
	end
	return opacity
end

function ui.scale(s)
	if s then
		scale = s
		transform:scale(scale)
	end
	return scale
end

function ui.padding(p, ip)
	if p then
		padding = p
	else
		padding = 16
	end
	if ip then
		iconpadding = ip
	else
		iconpadding = 8
	end
	return padding, iconpadding
end

function ui.spacing(s)
	if s then
		spacing = s
	else
		spacing = 16
	end
	return spacing
end

function ui.resettouched()
	lasttouched = nil
end

function ui.cursor(x, y)
	if x then
		cursorx = x
	end
	if y then
		cursory = y
	end
	return ui.cursorx, ui.cursory
end

function ui.font(f, s)
	if type(f) == "number" then
		s = f
		f = nil
	end
	if f then
		font = f
	end
	if s then
		fontscale = s
	end
end

function ui.nonewline()
	sameline = true
end

function ui.contentsize()
	local width, height = transform:inverseTransformPoint(love.graphics.getDimensions())
	return width - spacing * 2, height - spacing * 2
end

function ui.button(icon, label, w, enabled)
	love.graphics.push()
	love.graphics.origin()
	love.graphics.scale(scale)
	if type(icon) == "string" then
		enabled = w
		w = label
		label = icon
		icon = nil
	end
	if enabled == nil then
		enabled = true
	end
	local id
	if type(label) == "nil" then
		label = ""
		id = icon
	elseif type(label) == "table" then
		id = label[1]
		label = table.concat(label)
	else
		label = tostring(label)
		if icon then
			id = icon
		else
			id = label
		end
	end
	local text = newText(font, label)
	local width, height = text:getDimensions()
	local textoffsetx, textoffsety = padding, padding
	width = width * fontscale + padding * 2
	height = height * fontscale + padding * 2
	if icon then
		width = width + icon:getWidth() + iconpadding
		height = math.max(icon:getHeight() + iconpadding * 2, height)
		textoffsetx = icon:getWidth() + iconpadding + padding
		textoffsety = math.max(0, icon:getHeight() - text:getHeight() * fontscale) / 2 + iconpadding
		if label == "" then
			width = width - padding * 2 - 1 + iconpadding
		end
	end
	if w then
		width = w
	end
	local x, y = cursorx + spacing, cursory + spacing
	local b = 0.35
	if enabled then
		b = 1
	end
	local hovered = enabled and mousex >= x - margin and mousex < x + width + margin and mousey >= y - margin and mousey < y + height + margin

	if lasttouched == id then
		if istouched then
			if Mobile then
				love.graphics.setColor(1, 1, 1)
			else
				love.graphics.setColor(0, 0, b / 2)
			end
		else
			love.graphics.setColor(lasttouchedtimer / 8, lasttouchedtimer / 8, b, opacity)
		end
	else
		love.graphics.setColor(0, 0, b, opacity)
	end
	drawbutton(x, y, width, height, not Mobile and ((hovered and not istouched) or (istouched and lasttouched == id)))
	love.graphics.setColor(b, b, b, opacity)
	if istouched and lasttouched == id then
		if Mobile then
			love.graphics.setColor(1, 1, 1)
		else
			love.graphics.setColor(b/2, b/2, b/2)
		end
	end
	if icon then
		love.graphics.draw(icon, x + iconpadding, y + iconpadding)
	end
	love.graphics.draw(text, x + textoffsetx, y + textoffsety + fontscale / 2, 0, fontscale, fontscale)
	if sameline then
		sameline = false
		cursorx = cursorx + width + spacing
	else
		cursory = cursory + height + spacing
	end
	love.graphics.pop()
	if hovered and pressed then
		lasttouched = id
		lasttouchedtimer = 10
	end
	if hovered and released and lasttouched == id then
		lasttouchedtimer = 10
		return true
	end
	return false
end

return ui