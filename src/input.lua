local ball = love.graphics.newImage "joystick/ball-line.png"
local base = love.graphics.newImage "joystick/base-line.png"

local input = {}

input.time = 0
input.direction = 1
input.keys = {}
input.showjoystick = false
input.touchcontrols = false
input.color = {0, 0, 1}
input.x = 100
input.y = 100
input.scale = 4
input.deadspace = 25
input.wheeldx = 0
input.wheeldy = 0

function input.wheelmoved(dx, dy)
	input.wheeldx = dx
	input.wheeldy = dy
end

function input.keypressed(key)
	input.keys["kb-"..key] = input.time
	if key == "right" or key == "d" then
		input.keys.right = input.time
	end
	if key == "down" or key == "s" then
		input.keys.down = input.time
	end
	if key == "left" or key == "a" then
		input.keys.left = input.time
	end
	if key == "up" or key == "w" then
		input.keys.up = input.time
	end
	if key == "return" or key == "z" then
		input.keys.a = input.time
	end
	if key == "rshift" or key == "x" then
		input.keys.b = input.time
	end
	if key == "escape" or key == "p" then
		input.keys.escape = input.time
	end
end

function input.keyreleased(key)
	input.keys["kb-"..key] = nil
	if key == "left" or key == "a" then
		input.keys.left = nil
	end
	if key == "up" or key == "w" then
		input.keys.up = nil
	end
	if key == "right" or key == "d" then
		input.keys.right = nil
	end
	if key == "down" or key == "s" then
		input.keys.down = nil
	end
	if key == "return" or key == "z" then
		input.keys.a = nil
	end
	if key == "rshift" or key == "x" then
		input.keys.b = nil
	end
	if key == "escape" or key == "p" then
		input.keys.escape = nil
	end
end

function input.getWheelDelta()
	return input.wheeldx, input.wheeldy
end

function input.getMouseDelta()
	return input.mousedx, input.mousedy
end

function input.isDown(key)
	if input.keys[key] then
		return true
	end
	return false
end

function input.isPressed(key)
	if input.keys[key] == input.time then
		return true
	end
	return false
end

function input.mousemoved(x, y, dx, dy)
	input.mousedx, input.mousedy = dx, dy
end

function input.mousepressed(button)
	input.keys[button] = input.time
end

function input.mousereleased(button)
	input.keys[button] = nil
	if input.showjoystick and input.touchcontrols then
		input.keys.left = nil
		input.keys.right = nil
		input.keys.up = nil
		input.keys.down = nil
	end
end

function input.touchpressed(id, x, y)
	input.touchcontrols = true
	if input.showjoystick and input.touchcontrols then
		input.x, input.y = x, y
	end
end

local function pickmax(tbl, size)
	local max = 0
	local maxval = -math.huge
	for i = 1, size do
		local v = tbl[i]
		if type(v) == "number" and v > maxval then
			maxval = v
			max = i
		end
	end
	return max
end

function input.preupdate()
	if input.touchcontrols and input.showjoystick then
		local x, y = love.mouse.getPosition()
		if love.mouse.isDown(1) then
			local dist = math.sqrt((x - input.x)^2 + (y - input.y)^2)
			if dist > input.deadspace then
				local angle = math.deg(math.atan2(y - input.y, x - input.x))
				if angle > -45 and angle <= 45 then
					input.keys.left = nil
					if not input.keys.right then
						input.keys.right = input.time
					end
					input.keys.up = nil
					input.keys.down = nil
				end
				if angle > 45 and angle <= 135 then
					input.keys.left = nil
					input.keys.right = nil
					input.keys.up = nil
					if not input.keys.down then
						input.keys.down = input.time
					end
				end
				if angle > 135 or angle <= -135 then
					if not input.keys.left then
						input.keys.left = input.time
					end
					input.keys.right = nil
					input.keys.up = nil
					input.keys.down = nil
				end
				if angle > -135 and angle <= -45 then
					input.keys.left = nil
					input.keys.right = nil
					if not input.keys.up then
						input.keys.up = input.time
					end
					input.keys.down = nil
				end
			else
				input.keys.left = nil
				input.keys.right = nil
				input.keys.up = nil
				input.keys.down = nil
			end
		end
	end
	local dir = pickmax({ input.keys.right, input.keys.down, input.keys.left, input.keys.up }, 4) - 1
	if dir > -1 then
		input.direction = dir
	end
end

function input.update()
	input.wheeldx = 0
	input.wheeldy = 0
	input.mousedx = 0
	input.mousedy = 0
	input.time = input.time + 1
end

function input.draw()
	if input.showjoystick and input.touchcontrols and #love.touch.getTouches() > 0 then
		local dx, dy = 8, 8
		if input.keys.left then
			dx = 16
		end
		if input.keys.up then
			dy = 16
		end
		if input.keys.right then
			dx = 0
		end
		if input.keys.down then
			dy = 0
		end
		love.graphics.setColor(input.color)
		love.graphics.draw(base, input.x, input.y, 0, input.scale, input.scale, 16, 16)
		love.graphics.draw(ball, input.x, input.y, 0, input.scale, input.scale, dx, dy)
	end
end

return input