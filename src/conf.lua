function love.conf(t)
	t.window.resizable = true
	t.window.width = 224 * 6
	t.window.height = 288 * 3
	t.window.icon = "icon.png"
	t.window.title = "PAC-MAN"
	t.identity = "bravelycowering-pacman"
	t.externalstorage = true
	t.appendidentity = true
end