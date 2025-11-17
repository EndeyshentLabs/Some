local utf8 = require("utf8")

local Some = {
	_VERSION = "0.0.1",
	_DESCRIPTION = "GUI library for LOVE2D",
	_AUTHOR = "EndeyshentLabs",
	_LICENSE = "MIT",
	_URL = "https://github.com/EndeyshentLabs/Some",
}

---@type Some.Theme
Some.defaultTheme = {
	foreground = { 1, 1, 1 },
	secondary = { 0.95, 0.95, 0.95 },
	background = { 0, 0, 0 },
	background2 = { 0.05, 0.05, 0.05 },
	accent = { 0, 1, 0 },

	error = { 1, 0, 0 },
	warning = { 1, 1, 0 },

	font = love.graphics.newFont(12),

	lineWidth = 2,

	pfxInactive = "I",
	pfxActive = "A",
	prot = { "<", ">" },
	norm = { "[", "]" },
}

---@type Some.Theme
Some.theme = Some.defaultTheme

---@type table<Some.Wdow>
local wdows = {}
local lastId = 0

---@type Some.Wdow?
local activeWdow = nil

---Returns true if point `vec2` is in box `xywh`
---@param xywh Some.XYWH
---@param vec2 Some.XY
---@return boolean
local function pointInXYWH(xywh, vec2)
	if ((vec2.x < xywh.x) or (vec2.y < xywh.y))
		or ((vec2.x > xywh.x + xywh.w) or (vec2.y > xywh.y + xywh.h))
	then
		return false
	end

	return true
end

---Initializes the Some
---@param theme Some.Theme
function Some:init(theme)
	if type(theme) == "table" then
		self.theme = theme
	end
end

---Creates a new Some window
---@param _title string
---@param _x number
---@param _y number
---@param _w number
---@param _h number
---@param _active boolean?
---@param _protected boolean?
---@param _alwaysontop boolean?
---@return Some.Wdow
function Some.addWindow(_title, _x, _y, _w, _h, _active, _protected, _alwaysontop)
	local _id = #wdows + 1
	lastId = _id

	---@type Some.Wdow
	local wdow = {
		id = _id,
		title = _title,
		x = _x,
		y = _y,
		-- TODO: Accommodate for title bar. <2025-04-11>
		w = _w,
		h = _h,
		active = _active == nil and true or _active,
		protected = _protected == nil and false or _protected,
		alwaysontop = _alwaysontop == nil and false or _alwaysontop,
		contentX = _x + 0,
		contentY = _y + Some.theme.font:getHeight(),
		quad = {
			x = _x,
			y = _y,
			w = _w,
			h = _h,
		},
		activeWidget = nil,
		widgets = {},
		move = function(self, x, y)
			self.x = self.x + x
			self.y = self.y + y
			self.contentX = self.x + 0
			self.contentY = self.y + Some.theme.font:getHeight()
			self.quad = {
				x = self.x,
				y = self.y,
				w = self.w,
				h = self.h,
			}

			self:mousemoved(love.mouse.getX(), love.mouse.getY())
		end,
		textinput = function(self, t)
			if self.activeWidget and self.activeWidget.textinput then
				self.activeWidget:textinput(t)
			end
		end,
		keypressed = function(self, k, sc, isrepeat)
			if k == "escape" and love.keyboard.isDown("lalt") then
				self:exit()
			elseif k == "tab" and love.keyboard.isDown("lalt") then
				self:hide()
			else
				if love.keyboard.isDown("lalt") then
					if sc == "s" or k == "down" then
						self:move(0, 1)
					elseif sc == "w" or k == "up" then
						self:move(0, -1)
					elseif sc == "d" or k == "right" then
						self:move(1, 0)
					elseif sc == "a" or k == "left" then
						self:move(-1, 0)
					end
				elseif self.activeWidget and self.activeWidget.keypressed then
					self.activeWidget:keypressed(k, sc, isrepeat)
				end
			end
		end,
		exists = function(self)
			return wdows[self.id] ~= nil
		end,
		mousemoved = function(self, x, y)
			local oldActive = self.activeWidget
			self.activeWidget = nil
			for _, widget in pairs(self.widgets) do
				local w = {
					x = self.contentX + widget.x,
					y = self.contentY + widget.y,
					w = widget.w,
					h = widget.h,
				}
				if pointInXYWH(w, { x = x, y = y }) then
					self.activeWidget = widget
					break
				end
			end

			if self.activeWidget ~= oldActive then
				if oldActive and oldActive.mouseexit then
					oldActive:mouseexit()
				end
				if self.activeWidget and self.activeWidget.mouseenter then
					self.activeWidget:mouseenter()
				end
			end
		end,
		mousepressed = function(self, x, y, button)
			if self.activeWidget and self.activeWidget.mousepressed then
				-- NOTE: First two arguments are in content coordinate system.
				--       Last two arguments are in screen space coordinates.
				--       <2025-11-17>
				self.activeWidget:mousepressed(x - self.contentX, y - self.contentY, button, x, y)
			end
		end,
		exit = function(self)
			if not self.protected then
				self.active = false
				activeWdow = nil
				wdows[self.id] = nil
				self = nil
				Some:mousemoved(love.mouse.getX(), love.mouse.getY())
			end
		end,
		hide = function(self)
			if not self.alwaysontop then
				self.active = false
				activeWdow = nil
				Some:mousemoved(love.mouse.getX(), love.mouse.getY())
			end
		end,
		show = function(self)
			self.active = true
			Some:mousemoved(love.mouse.getX(), love.mouse.getY())
		end,
	}
	---@diagnostic disable-next-line: inject-field
	wdow.__index = wdow

	wdows[_id] = wdow

	return wdows[#wdows]
end

---Basic text widget
---@param wdow Some.Wdow
---@param _text string
---@param _x number
---@param _y number
---@return Some.Widget created widget
function Some.Wtext(wdow, _text, _x, _y)
	local w = {
		text = _text,
		x = _x,
		y = _y,
		w = Some.theme.font:getWidth(_text),
		h = Some.theme.font:getHeight(),
		draw = function(self)
			love.graphics.setColor(Some.theme.foreground)
			love.graphics.print(self.text, Some.theme.font, self.x, self.y)
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

---Input field widget
---@param wdow Some.Wdow
---@param _x number
---@param _y number
---@param _w number
---@param _onsubmit function? What to do on `Enter` keypress
---@return Some.Widget created widget
function Some.Winput(wdow, _x, _y, _w, _onsubmit)
	local w = {
		_private = {
			text = "",
			cursor = nil,
		},
		x = _x,
		y = _y,
		w = _w,
		h = Some.theme.font:getHeight(),
		onsubmit = _onsubmit,
		draw = function(self, hovered)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

			love.graphics.setColor(Some.theme.secondary)
			love.graphics.print(
				self._private.text,
				Some.theme.font,
				self.x,
				self.y
			)

			if hovered then
				local b = self._private.text
				local c = self._private.cursor
				local w = Some.theme.font:getWidth(b)

				if c ~= nil then
					if c == 0 then
						w = 0
					else
						w = Some.theme.font:getWidth(
							b:sub(
								1,
								utf8.offset(b, c + 1) - 1
							)
						)
					end
				end

				love.graphics.line(
					self.x + w + 1,
					self.y,
					self.x + w + 1,
					self.y + self.h
				)
			end
		end,
		textinput = function(self, t)
			local b = self._private.text
			local c = self._private.cursor
			if not c then
				self._private.text = b .. t
			else
				self._private.text = string.sub(b, 1, utf8.offset(b, c + 1) - 1)
					.. t .. string.sub(b, utf8.offset(b, c + 1))
				self._private.cursor =
					math.min(self._private.cursor + 1, utf8.len(b) + 1)
			end
		end,
		keypressed = function(self, k, sc, isrepeat)
			if k == "backspace" then
				local b = self._private.text
				local c = self._private.cursor
				if c ~= nil then
					self._private.text = b:sub(1, utf8.offset(b, c) - 1)
						.. b:sub(utf8.offset(b, c + 1))
					self._private.cursor = math.max(self._private.cursor - 1, 0)
				else
					local byteoffset = utf8.offset(b, -1)

					if byteoffset then
						self._private.text = string.sub(b, 1, byteoffset - 1)
					end
				end
			elseif k == "delete" then
				local b = self._private.text
				local c = self._private.cursor
				if c ~= nil and c < utf8.len(b) then
					self._private.text = b:sub(1, utf8.offset(b, c + 1) - 1)
						.. b:sub(utf8.offset(b, c + 2))
				end
			elseif k == "left" then
				local c = self._private.cursor
				if c then
					self._private.cursor = math.max(c - 1, 0)
				else
					self._private.cursor =
						math.max(utf8.len(self._private.text) - 1, 0)
				end
			elseif k == "right" then
				local c = self._private.cursor
				if c then
					self._private.cursor =
						math.min(c + 1, utf8.len(self._private.text))
				end
			elseif k == "home" then
				self._private.cursor = 0
			elseif k == "end" then
				self._private.cursor = nil
			elseif k == "v" and love.keyboard.isDown("lctrl") then
				self._private.text =
					self._private.text .. love.system.getClipboardText()
			elseif k == "return" then
				if self.onsubmit then
					self:onsubmit(self._private.text)
				end
			end
		end,
		mouseexit = function(self)
			if self.onsubmit then
				self:onsubmit(self._private.text)
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w
	wdow.widgets[#wdow.widgets]._private = w._private

	return wdow.widgets[#wdow.widgets]
end

---Toggle/Check button
---@param wdow Some.Wdow
---@param _x number
---@param _y number
---@param _enabled boolean Default button state
---@return Some.Widget created widget
function Some.WcheckButton(wdow, _x, _y, _enabled)
	local w = {
		x = _x,
		y = _y,
		w = 20,
		h = 20,
		enabled = _enabled == nil and false or _enabled,
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			if self.enabled then
				love.graphics.setColor(Some.theme.accent)
				love.graphics.rectangle(
					"fill",
					self.x + 2,
					self.y + 2,
					self.w - 4,
					self.h - 4
				)
			end
		end,
		mousepressed = function(self, x, y, button)
			if button == 1 then
				self.enabled = not self.enabled
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

---Basic button with text
---@param wdow Some.Wdow
---@param _text string
---@param _x number
---@param _y number
---@param _callback function What to do on LMB click
---@return Some.Widget created widget
function Some.WtextButton(wdow, _text, _x, _y, _callback)
	local w = {
		text = _text,
		x = _x,
		y = _y,
		w = Some.theme.font:getWidth(_text),
		h = Some.theme.font:getHeight(),
		callback = _callback,
		draw = function(self, hovered)
			if hovered then
				love.graphics.setColor(Some.theme.foreground)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.setColor(Some.theme.background2)
				love.graphics.print(self.text, Some.theme.font, self.x, self.y)
			else
				love.graphics.setColor(Some.theme.background2)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.setColor(Some.theme.foreground)
				love.graphics.print(self.text, Some.theme.font, self.x, self.y)
			end
		end,
		mousepressed = function(self, x, y, button)
			if button == 1 and self.callback then
				self:callback()
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

---Progress bar. Can display progress or (if clickable=false) set progress.
---`progress` field is normalized to [0; 1] range
---@param wdow Some.Wdow
---@param _x number
---@param _y number
---@param _w number
---@param _clickable boolean
---@return Some.Widget created widget
function Some.Wprogressbar(wdow, _x, _y, _w, _clickable)
	local w = {
		progress = 0,
		clickable = _clickable == nil and false or _clickable,
		x = _x,
		y = _y,
		w = _w,
		h = 20,
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			love.graphics.setColor(Some.theme.accent)
			love.graphics.rectangle(
				"fill",
				self.x,
				self.y,
				self.progress * self.w,
				self.h
			)
		end,
		mousepressed = function(self, x, y, button)
			if self.clickable and button == 1 then
				self.progress = (x - self.x) / self.w
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

---Dropdown menu (more like create-window menu)
---@param wdow Some.Wdow
---@param _x number
---@param _y number
---@param _items table Options to choose from
---@param default number? Default option
---@return Some.Widget created widget
function Some.Wdropdown(wdow, _x, _y, _items, default)
	local w = {
		x = _x,
		y = _y,
		items = _items,
		current = default == nil and 1 or default,
		w = (function()
			local longest = Some.theme.font:getWidth("(none)")
			for _, item in ipairs(_items) do
				local lenght = Some.theme.font:getWidth(item)
				if lenght > longest then
					longest = lenght
				end
			end
			return longest + Some.theme.font:getHeight()
		end)(),
		h = Some.theme.font:getHeight(),
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			love.graphics.setColor(Some.theme.foreground)
			if self.items[self.current] then
				love.graphics.print(
					self.items[self.current],
					Some.theme.font,
					Some.theme.font:getHeight() + self.x,
					self.y
				)
			else
				love.graphics.print(
					"(none)",
					Some.theme.font,
					Some.theme.font:getHeight() + self.x,
					self.y
				)
			end
			love.graphics.setColor(Some.theme.secondary)
			love.graphics.rectangle(
				"fill",
				self.x,
				self.y,
				Some.theme.font:getHeight(),
				self.h
			)
		end,
		mousepressed = function(self, x, y, button, screenX, screenY)
			if button ~= 1 then return end

			local itemsWdow = Some.addWindow(
				"Select one item",
				screenX,
				screenY,
				math.max(
					self.w,
					Some.theme.font:getWidth(
						"Select one item"
					) + Some.theme.font:getWidth(Some.theme.pfxActive .. "[ ]")
				),
				(#self.items + 1) * Some.theme.font:getHeight(),
				true,
				false,
				true
			)
			for k, item in ipairs(self.items) do
				Some.WtextButton(
					itemsWdow,
					item,
					0,
					(k - 1) * Some.theme.font:getHeight(),
					function()
						self.current = k
						itemsWdow:exit()
					end
				)
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

---Basic image widget
---@param wdow Some.Wdow
---@param _image love.Image
---@param _x number
---@param _y number
---@param _r number?
---@param _w number?
---@param _h number?
---@return Some.Widget created widget
function Some.Wimage(wdow, _image, _x, _y, _r, _w, _h)
	local w = {
		image = _image,
		x = _x,
		y = _y,
		r = _r == nil and 0 or _r,
		w = _w == nil and _image:getWidth() or _w,
		h = _h == nil and _image:getHeight() or _h,
		draw = function(self)
			love.graphics.setColor(Some.theme.foreground)
			love.graphics.draw(self.image, self.x, self.y, self.r, self.w / self.image:getWidth(),
				self.h / self.image:getHeight())
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w

	return wdow.widgets[#wdow.widgets]
end

function Some:draw()
	local lWidthBefore = love.graphics.getLineWidth()

	love.graphics.setLineWidth(self.theme.lineWidth)

	for _, wdow in pairs(wdows) do
		if not wdow.active then
			goto continue
		end
		love.graphics.setColor(self.theme.background)
		love.graphics.rectangle("fill", wdow.x, wdow.y, wdow.w, wdow.h)
		love.graphics.setColor(self.theme.foreground)
		love.graphics.rectangle(
			"fill",
			wdow.x,
			wdow.y,
			wdow.w,
			self.theme.font:getHeight()
		)

		local lSurround = self.theme.norm[1]
		local rSurround = self.theme.norm[2]
		if wdow.protected then
			lSurround = self.theme.prot[1]
			rSurround = self.theme.prot[2]
		end

		local prefix = self.theme.pfxInactive
		local isactive = false

		if activeWdow and wdow.id == activeWdow.id then
			prefix = self.theme.pfxActive
			isactive = true
		end

		love.graphics.setColor(self.theme.background)
		love.graphics.print(
			lSurround .. prefix .. rSurround .. " " .. wdow.title,
			self.theme.font,
			wdow.x,
			wdow.y
		)

		love.graphics.push("all")
		-- Clip things that are outside of wdow bounds
		-- TODO: Create scrollable wdows. <2025-04-11>
		love.graphics.setScissor(
			wdow.quad.x,
			wdow.quad.y,
			wdow.quad.w,
			wdow.quad.h
		)
		for _, widget in pairs(wdow.widgets) do
			love.graphics.translate(wdow.contentX, wdow.contentY)
			widget:draw(widget == wdow.activeWidget)
			love.graphics.origin()
		end
		love.graphics.setScissor()
		love.graphics.pop()

		love.graphics.setColor(self.theme.background2)
		if isactive then
			love.graphics.setColor(self.theme.secondary)
		end
		love.graphics.rectangle(
			"line",
			wdow.x - self.theme.lineWidth / 2,
			wdow.y - self.theme.lineWidth / 2,
			wdow.w + self.theme.lineWidth,
			wdow.h + self.theme.lineWidth
		)
		::continue::
	end

	if activeWdow
		and activeWdow.activeWidget
		and activeWdow.activeWidget.tooltip
	then
		love.graphics.setColor(self.theme.background2)
		local x, y = love.mouse.getPosition()
		local fontHeight = self.theme.font:getHeight()
		love.graphics.rectangle(
			"fill",
			x,
			y - fontHeight,
			self.theme.font:getWidth(activeWdow.activeWidget.tooltip),
			fontHeight
		)
		love.graphics.setColor(self.theme.secondary)
		love.graphics.print(activeWdow.activeWidget.tooltip, x, y - fontHeight)
	end

	love.graphics.setLineWidth(lWidthBefore)
end

function Some:mousemoved(x, y, dx, dy)
	activeWdow = nil
	for i = lastId, 1, -1 do
		local wdow = wdows[i]
		if wdow and wdow.active and pointInXYWH(wdow, { x = x, y = y }) then
			activeWdow = wdow
			activeWdow:mousemoved(x, y)
			break
		end
	end

	if
		dx ~= nil
		and dy ~= nil
		and activeWdow
		and pointInXYWH(activeWdow, { x = x, y = y })
		and love.mouse.isDown(1)
		and not activeWdow.activeWidget
	then
		activeWdow:move(dx, dy)
	end
end

function Some:mousepressed(x, y, button)
	if activeWdow then
		-- TODO: Make close button
		-- NOTE: This works if wdow's title starts with "[X]"
		-- if pointInXYWH({ x = activeWdow.x, y = activeWdow.y, w = self.theme.font:getWidth("[X]"), h = self.theme.font:getHeight() }, { x = x, y = y }) then
		--	activeWdow:exit()
		--	return
		-- end
		activeWdow:mousepressed(x, y, button)
	end
end

function Some:keypressed(k, sc, isrepeat)
	if not activeWdow then
		return
	end
	activeWdow:keypressed(k, sc, isrepeat)
end

function Some:textinput(t)
	if not activeWdow then
		return
	end
	activeWdow:textinput(t)
end

function Some.isInputGrabbed()
	return activeWdow ~= nil
end

return Some

---@class Some.Theme
---@field foreground table Main foreground color
---@field secondary table Secondary foreground color
---@field background table Main background color
---@field background2 table Secondary background color
---@field accent table Accent color (also success color)
---@field error table Error color
---@field warning table Warning color
---@field font love.Font Font to Some to use
---@field lineWidth integer Line width
---@field pfxInactive string Prefix for windows that aren't active
---@field pfxActive string Prefix for windows that are active
---@field prot table Surround for prefix. [1] is left, [2] is right
---@field norm table Surround for prefix. [1] is left, [2] is right

---Basic Vector2 or Point
---@class Some.XY
---@field x number X position
---@field y number Y position

---Basic AA rectangle
---@class Some.XYWH: Some.XY
---@field w number Width
---@field h number Height

---Widget attachable to window
---@class Some.Widget: Some.XYWH
---@field tooltip string?

---@class Some.Wdow: Some.XYWH
---@field id integer Window's ID
---@field title string Window's title
---@field active boolean Is window visible
---@field protected boolean
---@field alwaysontop boolean Is this window cannot be hidden
---@field contentX number Base X postion for content
---@field contentY number Base Y postion for content
---@field widgets table<Some.Widget> Pool of widgets
---@field activeWidget Some.Widget?
