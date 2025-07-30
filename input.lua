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

function input.keypressed(key)
	if key == "right" or key == "d" then
		input.direction = 0
		input.keys.right = input.time
	end
	if key == "down" or key == "s" then
		input.direction = 1
		input.keys.down = input.time
	end
	if key == "left" or key == "a" then
		input.direction = 2
		input.keys.left = input.time
	end
	if key == "up" or key == "w" then
		input.direction = 3
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

function input.mousepressed()
	if input.showjoystick and input.touchcontrols then
		input.x, input.y = love.mouse.getPosition()
	end
end

function input.mousereleased()
	if input.showjoystick and input.touchcontrols then
		input.keys.left = nil
		input.keys.right = nil
		input.keys.up = nil
		input.keys.down = nil
	end
end

function input.update()
	input.time = input.time + 1
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
					input.direction = 0
				end
				if angle > 45 and angle <= 135 then
					input.keys.left = nil
					input.keys.right = nil
					input.keys.up = nil
					if not input.keys.down then
						input.keys.down = input.time
					end
					input.direction = 1
				end
				if angle > 135 or angle <= -135 then
					if not input.keys.left then
						input.keys.left = input.time
					end
					input.keys.right = nil
					input.keys.up = nil
					input.keys.down = nil
					input.direction = 2
				end
				if angle > -135 and angle <= -45 then
					input.keys.left = nil
					input.keys.right = nil
					if not input.keys.up then
						input.keys.up = input.time
					end
					input.keys.down = nil
					input.direction = 3
				end
			else
				input.keys.left = nil
				input.keys.right = nil
				input.keys.up = nil
				input.keys.down = nil
			end
		end
	end
end

function input.draw()
	if input.showjoystick and input.touchcontrols and love.mouse.isDown(1) then
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