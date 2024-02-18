local Some = require("some")

function love.load()
	-- Some:init()
	TestWdow = Some.addWindow("Test wdow", 100, 100, 400, 70)

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

	love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	Some:draw()
end

local moveSpeed = 5
function love.update(dt)
	if TestWdow and not TestWdow:exists() then
		TestWdow = nil
	end
end

function love.mousemoved(x, y, dx, dy)
	Some:mousemoved(x, y, dx, dy)
end

---@diagnostic disable-next-line: unused-local
function love.keypressed(key, scancode, isrepeat)
	Some:keypressed(key, scancode, isrepeat)
	if key == "space" then
		TestWdow.active = not TestWdow.active
	elseif key == "`" then
		debug.debug()
	end
end

function love.textinput(text)
	Some:textinput(text)
end
