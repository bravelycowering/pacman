---@diagnostic disable-next-line: undefined-field
local f = io.open(love.filesystem.getExecutablePath(), "rb")
assert(f)
local rom = f:read("*a")
f:close()
return rom