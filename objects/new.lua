return function(type)
	return setmetatable({}, {__index=type})
end