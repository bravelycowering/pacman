local files = {}
for index, value in ipairs(love.filesystem.getDirectoryItems("assets/sounds")) do
	local name = value:gsub("%.[^%.]+$", "")
	files[name] = love.audio.newSource("assets/sounds/"..value, "static")
end

local sounds = {}
local bgm

function sounds.play_sfx(name)
	local sound = files[name]
	if sound then
		sound:stop()
		sound:setLooping(false)
		sound:play()
	else
		print("missing sound "..name)
	end
end

function sounds.pause_bgm()
	if bgm and bgm:isPlaying() then
		bgm:pause()
	end
end

function sounds.unpause_bgm()
	if bgm and not bgm:isPlaying() then
		bgm:play()
	end
end

function sounds.stop_all()
	love.audio.stop()
	bgm = nil
end

function sounds.bgm(name)
	local sound = files[name]
	if sound then
		if bgm ~= sound then
			if bgm then
				bgm:stop()
			end
			sound:stop()
			sound:setLooping(true)
			sound:play()
			bgm = sound
		elseif not bgm:isPlaying() then
			bgm:play()
		end
	else
		print("missing sound "..name)
	end
end

function sounds.stop_bgm()
	if bgm then
		bgm:stop()
		bgm = nil
	end
end

return sounds