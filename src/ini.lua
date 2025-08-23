local ini = {}

function ini.save(filename, state)
	local data = {}
	for key, value in pairs(state) do
		data[#data+1] = key.."="..tostring(value)
	end
	love.filesystem.write(filename, table.concat(data, "\n"))
end

function ini.load(filename)
	local state = {}
	local exists, content = pcall(love.filesystem.read, filename)
	if exists and type(content) == "string" then
		for line in content:gmatch("[^\n\r]+") do
			local pos = line:find("=")
			local key = line:sub(1, pos-1)
			local val = line:sub(pos+1)
			state[key] = val
		end
	end
	return state
end

return ini