local settings = {}

local state = {}

function settings.set(key, value)
	state[key] = value
	settings.save()
end

function settings.get(key, value)
	local saved = state[key]
	if saved ~= nil then
		value = saved
	end
	return tostring(value)
end

function settings.getn(key, value)
	return tonumber(settings.get(key, value))
end

function settings.getb(key, value)
	return settings.get(key, value) == "true"
end

local defaultnames = {"NED", "ANN", "MEL", "C.J", "OSC"}
local defaultscores = {10000, 9000, 8000, 7000, 5000}

function settings.getscores(mazeid, name, score)
	local scores = {}
	for i = 1, 5 do
		scores[#scores+1] = {
			name = settings.get(mazeid.."["..i.."].name", defaultnames[i]),
			score = settings.getn(mazeid.."["..i.."].score", defaultscores[i])
		}
	end
	if name then
		scores[#scores+1] = {
			name = name,
			score = score or 0
		}
		table.sort(scores, function (a, b)
			return a.score > b.score
		end)
		scores[#scores] = nil
	end
	return scores
end

function settings.setscores(mazeid, scores)
	for i = 1, 5 do
		settings.set(mazeid.."["..i.."].name", scores[i].name)
		settings.set(mazeid.."["..i.."].score", scores[i].score)
	end
end

function settings.reset()
	state = {}
	settings.save()
end

function settings.save()
	local data = {}
	for key, value in pairs(state) do
		data[#data+1] = key.."="..tostring(value)
	end
	love.filesystem.write("settings.ini", table.concat(data, "\n"))
end

function settings.load()
	local exists, content = pcall(love.filesystem.read, "settings.ini")
	if exists and type(content) == "string" then
		for line in content:gmatch("[^\n]+") do
			local pos = line:find("=")
			local key = line:sub(1, pos-1)
			local val = line:sub(pos+1)
			state[key] = val
		end
	end
end

settings.load()

return settings