local pacman = require "pacman.pacman"
local sounds = require "sounds"
local input = require "input"

---@diagnostic disable-next-line: duplicate-set-field
function pacman:update(maze, frightspeed)
	if self.sp == nil then
		self.sp = 0
	end
	local mul = 1
	if frightspeed then mul = 2 end
	if self.dead then
		self.frame = math.min(math.floor(self.deathtimer / 9) + 1, 12)
		if self.deathtimer == 0 then
			sounds.play_sfx("death_0")
		end
		if self.deathtimer == 80 then
			sounds.stop_all()
			sounds.play_sfx("death_1")
		end
		if self.deathtimer == 92 then
			sounds.play_sfx("death_1")
		end
		self.deathtimer = self.deathtimer + 1
	else
		local opposite_direction = (self:getdirection() + 2) % 4
		if input.direction == opposite_direction then
			self.sp = self.sp - self.speed / 20 * mul
			if self.sp <= 0 then
				self.sp = 0
				self.mover:setdirection(input.direction)
			end
		else
			self.sp = math.min(self.sp + self.speed / 100 * mul, 4)
			-- turn pac man if hes able
			self.mover:setdirection(input.direction)
		end
		-- move pacman
		local tilex = math.floor(self.mover.x / 8)
		local tiley = math.floor(self.mover.y / 8)
		if maze:eat(tilex, tiley) then
			self.eatsound = 1 - self.eatsound
			if self.eatsound == 0 then
				sounds.play_sfx("eat_dot_0")
			else
				sounds.play_sfx("eat_dot_1")
			end
		end
		if self.mover:move(self.sp) then
			if self.sp == 0 then
				self.frame = 0
			else
				self.frame = (self.frame + self.sp / 4) % 4
			end
		else
			self.mover:setdirection(opposite_direction)
			self.sp = self.sp * 0.75
			sounds.play_sfx("bump")
		end
	end
end