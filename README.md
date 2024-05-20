# Some

Somewhat immediate GUI library for LOVE2D.

Goals:
- No dependencies (other than `utf8` and LOVE2D)
- Minimal
- Easy

## Example

See [main.lua](./main.lua) for more detailed example
### Hello, World!

```lua
local Some = require("some")

function love.load()
	TestWdow = Some.addWindow("Hello from Some window", 100, 100, 400, 100)

	Some.Wtext(TestWdow, "Hello, world!", 10, 10)

	love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
	love.keyboard.setKeyRepeat(true)
end

function love.draw()
	Some:draw()
end

function love.mousemoved(x, y)
	Some:mousemoved(x, y)
end

function love.keypressed(k, sc, isrepeat)
	Some:keypressed(k, sc, isrepeat)
end
```

## Widgets

List of window widgets

- Text (`Wtext`)
- Input box (`Winput`)
- Checkbox (`WcheckButton`)
- Text button (`WtextButton`)
- Progress bar (clickable btw) (`Wprogressbar`)
- Dropdown list (`Wdropdown`)
