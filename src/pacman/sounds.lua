local sounds = {}
local bgm

sounds.files = {}

function sounds.reload()
	local files = {}
	for index, value in ipairs(love.filesystem.getDirectoryItems("assets/sounds")) do
		local name = value:gsub("%.[^%.]+$", "")
		files[name] = love.audio.newSource("assets/sounds/"..value, "static")
	end
	sounds.stop_all()
	sounds.files = files
end

function sounds.play_sfx(name)
	local sound = sounds.files[name]
	if sound then
		sound:stop()
		sound:setLooping(false)
		sound:play()
	else
		print("missing sound "..name)
	end
end

function sounds.loop_sfx(name)
	local sound = sounds.files[name]
	if sound then
		sound:setLooping(true)
		sound:play()
	else
		print("missing sound "..name)
	end
end

function sounds.stop_sfx(name)
	local sound = sounds.files[name]
	if sound then
		sound:stop()
	else
		print("missing sound "..name)
	end
end

function sounds.pause()
	for key, value in pairs(sounds.files) do
		if value and value:isPlaying() then
			value:pause()
		end
	end
end

function sounds.unpause()
	for key, value in pairs(sounds.files) do
		if value and not value:isPlaying() and value:tell() ~= 0 then
			value:play()
		end
	end
end

function sounds.stop_all()
	for key, value in pairs(sounds.files) do
		value:stop()
	end
	bgm = nil
end

function sounds.bgm(name)
	local sound = sounds.files[name]
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

sounds.reload()

return sounds