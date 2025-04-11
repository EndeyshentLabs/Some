local Some = require("some")

function love.load()
	-- Some:init()
	TestWdow = Some.addWindow("Test wdow", 100, 100, 400, 80)

	Some.Wtext(TestWdow, "Input: ", 0, 5)
	Some.Winput(
		TestWdow,
		Some.theme.font:getWidth("Input: "),
		5,
		TestWdow.w - Some.theme.font:getWidth("Input: "),
		function(self, text)
			print(text)
		end
	)

	ProgressW = Some.Wprogressbar(TestWdow, 0, 20, 100, true)
	DropdownW = Some.Wdropdown(TestWdow, 0, 44, { "Alpha", "Beta", "Gamma", "Delta" })

	love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Progress bar:\t" .. ProgressW.progress, 0, 0)
	love.graphics.print("Dropdown menu:\t" .. DropdownW.current, 0, love.graphics.getFont():getHeight() + 1)
	Some:draw()
end

function love.update(dt)
	if TestWdow and not TestWdow:exists() then
		TestWdow = nil
	end
end

function love.mousemoved(x, y, dx, dy)
	Some:mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button)
	Some:mousepressed(x, y, button)
end

---@diagnostic disable-next-line: unused-local
function love.keypressed(key, scancode, isrepeat)
	Some:keypressed(key, scancode, isrepeat)
	if key == "space" then
		TestWdow.active = not TestWdow.active
	elseif key == "d" then
		print(TestWdow.widgets[#TestWdow.widgets].current)
	elseif key == "`" then
		debug.debug()
	end
end

function love.textinput(text)
	Some:textinput(text)
end
