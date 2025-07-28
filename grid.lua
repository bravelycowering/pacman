local has_ffi, ffi = pcall(require, "ffi")

local grid = {}

function grid:set(x, y, value)
	self.data[(x + y * self.width) % (self.width * self.height)] = value
end

function grid:setstr(x, y, str)
	local p = x + y * self.width
	for i = 1, #str do
		self.data[p % (self.width * self.height)] = string.byte(str, i, i)
		p = p + 1
	end
end

function grid:get(x, y)
	return self.data[(x + y * self.width) % (self.width * self.height)]
end

function grid:getstr(x, y, length)
	local p = x + y * self.width
	local str = {}
	for i = 1, length do
		str[#str+1] = string.char(self.data[p % (self.width * self.height)])
		p = p + 1
	end
	return table.concat(str)
end

function grid:xypairs()
    local i = -1
    return function ()
		i = i + 1
		local x, y = i % self.width, math.floor(i / self.width)
		if i < self.width * self.height then return x, y, self.data[i] end
	end
end

local newbuf

if has_ffi then
	function newbuf(size, init)
		local data = ffi.new("unsigned char[?]", size)
		if type(init) == "string" then
			for i = 1, math.min(#init, size) do
				data[i - 1] = string.byte(init, i, i)
			end
		elseif type(init) == "number" then
			for i = 0, size - 1 do
				data[i] = init
			end
		else
			error("cannot init grid from type "..type(init))
		end
		return data
	end
else
	function newbuf(size, init)
		local data = {}
		if type(init) == "string" then
			for i = 1, math.min(#init, size) do
				data[i - 1] = string.byte(init, i, i)
			end
		elseif type(init) == "number" then
			for i = 0, size - 1 do
				data[i] = init
			end
		else
			error("cannot init grid from type "..type(init))
		end
		return data
	end
end

function grid.new(width, height, init)
	return {
		width = width,
		height = height,
		set = grid.set,
		get = grid.get,
		setstr = grid.setstr,
		getstr = grid.getstr,
		xypairs = grid.xypairs,
		data = newbuf(width*height, init),
	}
end

return grid