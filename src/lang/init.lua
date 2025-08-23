local ini = require "ini"

local locale = "en_us"

local langfile = ini.load("lang/"..locale..".ini")

for key, value in pairs(langfile) do
	langfile[key] = value:gsub("%%n", "\n")
end

local lang = {}

function lang.translate(key, ...)
	return string.format(langfile[key] or key, ...)
end

return lang