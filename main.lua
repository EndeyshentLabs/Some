local Some = require("some")

local checkboxTextString = "<- this is a checkbox and it is "

local function bool2EnabledDisabled(b)
	return b and "enabled" or "disabled"
end

function love.load()
	Some:init()

	TestWdow = Some.addWindow("Test wdow", 100, 100, 400, 80)

	TestWdow:attach(Some.Wtext("Input: ", 0, 5))
	TestWdow:attach(Some.Winput(
		Some.theme.font:getWidth("Input: "),
		5,
		TestWdow.w - Some.theme.font:getWidth("Input: "),
		function(self, text)
			print(text)
		end
	))

	ProgressW = Some.Wprogressbar(0, 20, 100, true)
	ProgressW.tooltip = "Look for value in top-left corner"
	DropdownW =
		Some.Wdropdown(0, 44, { "Alpha", "Beta", "Gamma", "Delta" })
	CheckboxW = Some.WcheckButton(
		DropdownW.x + DropdownW.w + 2,
		DropdownW.y,
		false
	)
	CheckboxTextW = Some.Wtext(
		checkboxTextString .. bool2EnabledDisabled(CheckboxW.enabled),
		CheckboxW.x + CheckboxW.w,
		CheckboxW.y
	)

	TestWdow:attach(ProgressW, DropdownW, CheckboxW, CheckboxTextW)

	love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Progress bar:\t" .. ProgressW.progress, 0, 0)
	love.graphics.print(
		"Dropdown menu:\t" .. DropdownW.current,
		0,
		love.graphics.getFont():getHeight() + 1
	)
	CheckboxTextW.text = checkboxTextString
		.. bool2EnabledDisabled(CheckboxW.enabled)
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
