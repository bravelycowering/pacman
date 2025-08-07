local rom = love.filesystem.read("assets/random")
local index = 0
return function()
	index = (index * 5 + 1) % 8192
	return string.byte(rom, index, index)
end