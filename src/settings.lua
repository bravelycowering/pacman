local ini = require "ini"

local settings = {}

local state = {}

function settings.set(key, value)
	state[tostring(key)] = value
	settings.save()
end

function settings.get(key, value)
	local saved = state[tostring(key)]
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
	local maxscores = 5
	local placement = maxscores + 1
	local scores = {}
	for i = 1, maxscores do
		scores[#scores+1] = {
			name = settings.get(mazeid.."["..i.."].name", defaultnames[i]),
			score = settings.getn(mazeid.."["..i.."].score", defaultscores[i])
		}
	end
	if name then
		for i = 1, maxscores do
			if score > scores[i].score then
				placement = i
				break
			end
		end
		scores[#scores+1] = {
			name = name,
			score = score or 0
		}
		table.sort(scores, function (a, b)
			return a.score > b.score
		end)
		scores[#scores] = nil
	end
	return scores, placement
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
	ini.save("settings.ini", state)
end

function settings.load()
	state = ini.load("settings.ini")
end

settings.load()

return settings