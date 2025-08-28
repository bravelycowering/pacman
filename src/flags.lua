local bit = require "bit"

local flags = {}

function flags.toggle(value, flag)
	return bit.bxor(value, flag)
end

function flags.set(value, flag, enabled)
	if enabled then
		return bit.bor(value, flag)
	else
		return bit.band(value, bit.bnot(flag))
	end
end

function flags.check(value, flag)
	return bit.band(value, flag) ~= 0
end

return flags