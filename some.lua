local utf8 = require("utf8")

---@module "Some"
local Some = {
	_VERSION = "0.0.1",
	_DESCRIPTION = "Immidiate mode ui library for LOVE2D",
	_AUTHOR = "EndeyshentLabs",
	_LICENSE = "MIT",
	_URL = "https://github.com/EndeyshentLabs/Some",
}

Some.__index = Some

Some.defaultTheme = {
	foreground = { 1, 1, 1 },
	secondary = { 0.95, 0.95, 0.95 },
	background = { 0, 0, 0 },
	background2 = { 0.05, 0.05, 0.05 },
	accent = { 0, 1, 0 },

	error = { 1, 0, 0 },
	warning = { 1, 1, 0 },

	font = love.graphics.newFont(12),

	pfxInactive = "[I]",
	pfxActive = "[A]"
}

Some.theme = Some.defaultTheme

local wdows = {}

local activeWdow = nil

local function pointInXYWH(xywh, vec2)
	if ((vec2.x < xywh.x) or (vec2.y < xywh.y)) or ((vec2.x > xywh.x + xywh.w) or (vec2.y > xywh.y + xywh.h)) then
		return false
	end

	return true
end

function Some:init(theme)
	if type(theme) == "table" then
		self.theme = theme
	end
end

function Some.addWindow(_title, _x, _y, _w, _h, _active)
function Some.addWindow(_title, _x, _y, _w, _h, _active, _protected)
	local _id = #wdows + 1
	local wdow = {
		id = _id,
		title = _title,
		x = _x,
		y = _y,
		w = _w,
		h = _h,
		active = _active or true,
		protected = _protected or false,
		contentX = _x + 0,
		contentY = _y + Some.theme.font:getHeight(),
		activeWidget = nil,
		widgets = {},
		move = function(self, x, y)
			self.x = self.x + x
			self.y = self.y + y
			self.contentX = self.x + 0
			self.contentY = self.y + Some.theme.font:getHeight()

			for _, widget in pairs(self.widgets) do
				widget:recalc()
			end

			self:mousemoved(love.mouse.getX(), love.mouse.getY())
		end,
		textinput = function(self, t)
			if self.activeWidget and self.activeWidget.textinput then
				self.activeWidget:textinput(t)
			end
		end,
		keypressed = function(self, k, sc, isrepeat)
			if k == "escape" and love.keyboard.isDown("lalt") and not self.protected then
				self.active = false
				activeWdow = nil
				wdows[self.id] = nil
				self = nil
				Some:mousemoved(love.mouse.getX(), love.mouse.getY())
			elseif k == "tab" and love.keyboard.isDown("lalt") then
				self.active = false
				activeWdow = nil
				Some:mousemoved(love.mouse.getX(), love.mouse.getY())
			else
				if love.keyboard.isDown("lalt") then
					if k == "s" or k == "down" then
						self:move(0, 1)
					elseif k == "w" or k == "up" then
						self:move(0, -1)
					elseif k == "d" or k == "right" then
						self:move(1, 0)
					elseif k == "a" or k == "left" then
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
				if pointInXYWH(widget, { x = x, y = y }) then
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
				self.activeWidget:mousepressed(x, y, button)
			end
		end,
	}
	wdow.__index = wdow

	wdows[_id] = wdow

	return wdows[#wdows]
end

function Some.Wtext(wdow, _text, _x, _y)
	local w = {
		text = _text,
		x = wdow.contentX + _x,
		y = wdow.contentY + _y,
		w = Some.theme.font:getWidth(_text),
		h = Some.theme.font:getHeight(),
		draw = function(self)
			love.graphics.setColor(Some.theme.foreground)
			love.graphics.print(self.text, Some.theme.font, self.x, self.y)
		end,
		recalc = function(self)
			self.x = wdow.contentX + _x
			self.y = wdow.contentY + _y
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w
end

function Some.Winput(wdow, _x, _y, _w, _onsubmit)
	local w = {
		_private = {
			text = "",
		},
		x = wdow.contentX + _x,
		y = wdow.contentY + _y,
		w = _w,
		h = Some.theme.font:getHeight(),
		onsubmit = _onsubmit,
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			love.graphics.setColor(Some.theme.secondary)
			love.graphics.print(self._private.text, Some.theme.font, self.x, self.y)
			if #self._private.text > 0 and wdow.activeWidget == self then
				local w = Some.theme.font:getWidth(self._private.text)
				love.graphics.line(self.x + w + 1, self.y, self.x + w + 1, self.y + self.h)
			end
		end,
		recalc = function(self)
			self.x = wdow.contentX + _x
			self.y = wdow.contentY + _y
		end,
		textinput = function(self, t)
			self._private.text = self._private.text .. t
		end,
		keypressed = function(self, k, sc, isrepeat)
			if k == "backspace" then
				local byteoffset = utf8.offset(self._private.text, -1)

				if byteoffset then
					self._private.text = string.sub(self._private.text, 1, byteoffset - 1)
				end
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
end

function Some.WcheckButton(wdow, _x, _y, _enabled)
	local w = {
		x = wdow.contentX + _x,
		y = wdow.contentY + _y,
		w = 20,
		h = 20,
		enabled = _enabled or false,
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			if self.enabled then
				love.graphics.setColor(Some.theme.accent)
				love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.w - 4, self.h - 4)
			end
		end,
		recalc = function(self)
			self.x = wdow.contentX + _x
			self.y = wdow.contentY + _y
		end,
		mousepressed = function(self, x, y, button)
			if pointInXYWH(self, { x = x, y = y }) and button == 1 then
				self.enabled = not self.enabled
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w
end

function Some.WtextButton(wdow, _text, _x, _y, _callback)
	local w = {
		text = _text,
		x = wdow.contentX + _x,
		y = wdow.contentY + _y,
		w = Some.theme.font:getWidth(_text),
		h = Some.theme.font:getHeight(),
		callback = _callback,
		draw = function(self)
			if pointInXYWH(self, { x = love.mouse.getX(), y = love.mouse.getY() }) then -- hovered
				love.graphics.setColor(Some.theme.foreground)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.setColor(Some.theme.background2)
				love.graphics.print(self.text, Some.theme.font, self.x, self.y)
			else -- not hovered
				love.graphics.setColor(Some.theme.background2)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.setColor(Some.theme.foreground)
				love.graphics.print(self.text, Some.theme.font, self.x, self.y)
			end
		end,
		recalc = function(self)
			self.x = wdow.contentX + _x
			self.y = wdow.contentY + _y
		end,
		mousepressed = function(self, x, y, button)
			if button == 1 and pointInXYWH(self, { x = x, y = y }) then
				if self.callback then
					self:callback()
				end
			end
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w
end

function Some.Wprogressbar(wdow, _x, _y, _w, _clickable)
	local w = {
		progress = 0,
		clickable = _clickable or false,
		x = wdow.contentX + _x,
		y = wdow.contentY + _y,
		w = _w,
		h = 20,
		draw = function(self)
			love.graphics.setColor(Some.theme.background2)
			love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			love.graphics.setColor(Some.theme.accent)
			love.graphics.rectangle("fill", self.x, self.y, self.progress * self.w, self.h)
		end,
		recalc = function(self)
			self.x = wdow.contentX + _x
			self.y = wdow.contentY + _y
		end,
		mousepressed = function(self, x, y, button)
			if not self.clickable or not pointInXYWH(self, { x = x, y = y }) or button ~= 1 then
				return
			end

			self.progress = (x - self.x) / self.w
		end,
	}
	w.__index = w

	wdow.widgets[#wdow.widgets + 1] = w
end

function Some:draw()
	for _, wdow in pairs(wdows) do
		if not wdow.active then
			goto continue
		end
		love.graphics.setColor(self.theme.background)
		love.graphics.rectangle("fill", wdow.x, wdow.y, wdow.w, wdow.h)
		love.graphics.setColor(self.theme.foreground)
		love.graphics.rectangle("fill", wdow.x, wdow.y, wdow.w, self.theme.font:getHeight())

		local prefix = self.theme.pfxInactive
		local isactive = false

		if activeWdow and wdow.id == activeWdow.id then
			prefix = self.theme.pfxInactive
			isactive = true
		end

		love.graphics.setColor(self.theme.background)
		love.graphics.print(prefix .. " " .. wdow.title, self.theme.font, wdow.x, wdow.y)

		for _, widget in pairs(wdow.widgets) do
			widget:draw()
		end

		love.graphics.setColor(self.theme.background2)
		if isactive then
			love.graphics.setColor(self.theme.secondary)
		end
		love.graphics.rectangle("line", wdow.x - 1, wdow.y - 1, wdow.w + 2, wdow.h + 2)
		::continue::
	end
end

function Some:mousemoved(x, y, dx, dy)
	activeWdow = nil
	for i = #wdows, 1, -1 do
		local wdow = wdows[i]
		if wdow.active and pointInXYWH(wdow, { x = x, y = y }) then
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

return setmetatable({}, Some)
