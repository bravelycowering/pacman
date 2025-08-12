---@diagnostic disable: undefined-field
if love.window.showFileDialog then
	---@return string|nil
	local function showFileDialogSync(type, options)
		local f
		local wait = true
		love.window.showFileDialog(type, function (files, arg2, arg3)
			f = files
			wait = false
		end, options)
		while wait do
			love.event.pump()
			love.event.clear()
			love.timer.sleep(0.001)
		end
		if options.multiselect then
			return f
		end
		return f[1]
	end
	local function open(filename, filter)
		return showFileDialogSync("openfile", {
			filename = filename,
			filter = filter,
			attachtowindow = true,
		})
	end
	local function save(filename, filter)
		return showFileDialogSync("savefile", {
			filename = filename,
			filter = filter,
			attachtowindow = true,
		})
	end
	return {
		open = open,
		save = save,
	}
end

local ffi = require "ffi"

local function pickfile(save, directory, filter, filterindex, multiple)
	love.window.showMessageBox("error", "file dialog implementation does not exist for your platform", "error")
end

if ffi.os == "Windows" then
	-- windows file picker
	local com = ffi.load("Comdlg32")

	ffi.cdef [[
		int MultiByteToWideChar(unsigned int codepage, unsigned long flags, const char* str, int strlen, wchar_t* wstr, int wstrlen);
		int WideCharToMultiByte(unsigned int codepage, unsigned long flags, const wchar_t* wstr, int wstrlen, char* str, int strlen, char* defchr, int* udefchr);

		typedef struct {
			unsigned long	lStructSize;
			void*			hwndOwner;
			void*			hInstance;
			const wchar_t*	lpstrFilter;
			wchar_t*		lpstrCustomFilter;
			unsigned long	nMaxCustFilter;
			unsigned long	nFilterIndex;
			wchar_t*		lpstrFile;
			unsigned long	nMaxFile;
			wchar_t*		lpstrFileTitle;
			unsigned long 	nMaxFileTitle;
			const wchar_t*	lpstrInitialDir;
			const wchar_t*	lpstrTitle;
			unsigned long 	flags;
			unsigned short	nFileOffset;
			unsigned short	nFileExtension;
			const wchar_t*	lpstrDefExt;
			unsigned long	lCustData;
			void*			lpfnHook;
			const wchar_t*	lpTemplateName;
			void*			pvReserved;
			unsigned long	dwReserved;
			unsigned long	flagsEx;
		} OPENFILENAMEW;

		int _chdir(const char *path);

		int GetOpenFileNameW(OPENFILENAMEW *lpofn);
		int GetSaveFileNameW(OPENFILENAMEW *lpofn);
	]]

	local function _T(utf8)
		local ptr = ffi.cast("const char*", utf8.."\0")
		local len = ffi.C.MultiByteToWideChar(65001, 0, ptr, #utf8 + 1, nil, 0)
		local utf16 = ffi.new("wchar_t[?]", len)
		ffi.C.MultiByteToWideChar(65001, 0, ptr, #utf8 + 1, utf16, len)
		return utf16, len
	end

	local function _TtoLuaStr(utf16, len)
		len = len or -1
		local mblen = ffi.C.WideCharToMultiByte(65001, 0, utf16, len, nil, 0, nil, nil)
		local mb = ffi.new("char[?]", mblen)
		ffi.C.WideCharToMultiByte(65001, 0, utf16, len, mb, mblen, nil, nil)
		return ffi.string(mb, mblen):sub(1, -2)
	end

	function pickfile(save, filter, filterindex, multiple, directory)
		local wd = love.filesystem.getWorkingDirectory()
		local ofnptr = ffi.new("OPENFILENAMEW[1]")
		local ofn = ofnptr[0]

		ofn.lStructSize = ffi.sizeof("OPENFILENAMEW")
		ofn.hwndOwner = nil

		ofn.lpstrFile = ffi.new("wchar_t[32768]")
		ofn.nMaxFile = 32767

		ofn.nFilterIndex = filterindex or 1

		if type(filter) == "string" then
			ofn.lpstrFilter = _T(filter.."\0")
		elseif type(filter) == "table" then
			local filterlist = {}
			local name
			for index, value in ipairs(filter) do
				if name then
					filterlist[#filterlist+1] = name.."\0"..value
					name = nil
				else
					name = value
				end
			end
			ofn.lpstrFilter = _T(table.concat(filterlist, "\0").."\0")
		else
			ofn.lpstrFilter = _T("All Files\0*.*\0")
		end

		ofn.lpstrFileTitle = nil
		ofn.nMaxFileTitle = 0

		if directory then
			ofn.lpstrInitialDir = _T(directory:gsub("/", "\\").."\0")
		end

		ofn.flags = 0x02081804 + (multiple and 0x00000200 or 0)

		local res

		if save then
			res = com.GetSaveFileNameW(ofnptr)
		else
			res = com.GetOpenFileNameW(ofnptr)
		end

		if res > 0 then
			if multiple then
				local list = {}
				local dir = _TtoLuaStr(ofn.lpstrFile):sub(1, -2):gsub("\\", "/")
				local ptr = ofn.lpstrFile + #dir + 1

				if dir:sub(-1) == "/" then
					dir = dir:sub(1, -2)
				end

				while ptr[0] ~= 0 do
					local name = _TtoLuaStr(ptr)

					list[#list + 1] = dir.."/"..name:sub(1, -2)
					ptr = ptr + #name
				end

				if #list == 0 then
					list[1] = dir
				end

				ffi.C._chdir(wd)
				return unpack(list)
			else
				ffi.C._chdir(wd)
				return _TtoLuaStr(ofn.lpstrFile):gsub("\\", "/")
			end
		end

		return nil
	end
end

return {
	save = function(filename, filter)
		return pickfile(true, filter)
	end,
	open = function(filename, filter)
		return pickfile(false, filter)
	end
}