-- Meridian UI
-- Single-module build. See README.md for the multi-file source layout this was generated from.

local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- ============================================================
-- Core :: Signal
-- ============================================================
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _connections = {} }, Signal)
end

function Signal:Connect(fn)
	local self_ = self
	local connection
	connection = {
		Connected = true,
		Disconnect = function()
			if not connection.Connected then return end
			connection.Connected = false
			for i, c in ipairs(self_._connections) do
				if c == connection then
					table.remove(self_._connections, i)
					break
				end
			end
		end,
		_fn = fn,
	}
	table.insert(self._connections, connection)
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	for _, connection in ipairs(table.clone(self._connections)) do
		if connection.Connected then
			task.spawn(connection._fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._connections)
end

-- ============================================================
-- Core :: Maid
-- ============================================================
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end

function Maid:Give(task_)
	if self._destroyed then
		Maid._cleanupOne(task_)
		return task_
	end
	table.insert(self._tasks, task_)
	return task_
end

function Maid._cleanupOne(task_)
	local kind = typeof(task_)
	if kind == "RBXScriptConnection" then
		task_:Disconnect()
	elseif kind == "Instance" then
		task_:Destroy()
	elseif kind == "function" then
		task.spawn(task_)
	elseif kind == "thread" then
		task.cancel(task_)
	elseif kind == "table" then
		if task_.Disconnect then
			task_.Disconnect()
		elseif task_.Destroy then
			task_:Destroy()
		end
	end
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for _, task_ in ipairs(tasks) do
		Maid._cleanupOne(task_)
	end
end

function Maid:Destroy()
	self._destroyed = true
	self:Clean()
end

-- ============================================================
-- Core :: Utility
-- ============================================================
local Utility = {}

function Utility.New(className, properties, children)
	local instance = Instance.new(className)
	local parent
	if properties then
		for property, value in pairs(properties) do
			if property == "Parent" then
				parent = value
			else
				instance[property] = value
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Utility.Round(value, increment)
	increment = increment or 1
	if increment == 0 then return value end
	return math.floor(value / increment + 0.5) * increment
end

function Utility.Clamp(value, min, max)
	if min > max then min, max = max, min end
	return math.clamp(value, min, max)
end

function Utility.Lerp(a, b, t)
	return a + (b - a) * t
end

function Utility.FormatNumber(value)
	if value == math.floor(value) then
		return tostring(math.floor(value))
	end
	return string.format("%.2f", value)
end

function Utility.GetTextWidth(text, font, size)
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, font, Vector2.new(2000, 200))
	end)
	if ok then
		return bounds.X
	end
	return #text * size * 0.55
end

function Utility.FuzzyMatch(text, query)
	if query == "" then
		return true, 0
	end
	local lowerText = text:lower()
	local lowerQuery = query:lower()
	local directIndex = lowerText:find(lowerQuery, 1, true)
	if directIndex then
		return true, 1000 - directIndex
	end
	local score = 0
	local cursor = 1
	for i = 1, #lowerQuery do
		local char = lowerQuery:sub(i, i)
		local foundAt = lowerText:find(char, cursor, true)
		if not foundAt then
			return false, 0
		end
		score += (foundAt == cursor) and 3 or 1
		cursor = foundAt + 1
	end
	return true, score
end

function Utility.MakeDraggable(handle, target)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		local viewport = workspace.CurrentCamera.ViewportSize
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y
		local sizeX = target.AbsoluteSize.X
		local sizeY = target.AbsoluteSize.Y
		newX = Utility.Clamp(newX, -sizeX + 48, viewport.X - 48)
		newY = Utility.Clamp(newY, 0, viewport.Y - 32)
		target.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end

	local connections = {}

	table.insert(connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end
	end))

	table.insert(connections, handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			update(input)
		end
	end))

	return connections
end

function Utility.MakeResizable(handle, target, minSize, maxSize, onChange)
	local resizing = false
	local startPos, startSize

	local connections = {}

	table.insert(connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startPos = input.Position
			startSize = target.Size
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
					conn:Disconnect()
				end
			end)
		end
	end))

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startPos
			local newX = Utility.Clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
			local newY = Utility.Clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			target.Size = UDim2.new(startSize.X.Scale, newX, startSize.Y.Scale, newY)
			if onChange then onChange(newX, newY) end
		end
	end))

	return connections
end

function Utility.Ripple(button, color)
	local container = Utility.New("Frame", {
		Name = "RippleContainer",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = button.ZIndex + 5,
		Parent = button,
	})
	local corner = button:FindFirstChildOfClass("UICorner")
	if corner then
		Utility.New("UICorner", { CornerRadius = corner.CornerRadius, Parent = container })
	end

	return function(inputPosition)
		local relative = inputPosition - button.AbsolutePosition
		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
		local circle = Utility.New("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(relative.X, relative.Y),
			Size = UDim2.fromOffset(0, 0),
			ZIndex = container.ZIndex,
			Parent = container,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })
		TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.5, function()
			if circle then circle:Destroy() end
		end)
	end
end

function Utility.SafePosition(position, size)
	local viewport = workspace.CurrentCamera.ViewportSize
	local x = Utility.Clamp(position.X, 0, math.max(0, viewport.X - size.X))
	local y = Utility.Clamp(position.Y, 0, math.max(0, viewport.Y - size.Y))
	return Vector2.new(x, y)
end

-- ============================================================
-- Icons
-- ============================================================
local Icons = {}

local raster = {}

local VIEWBOX = 24

local function seg(container, x1, y1, x2, y2, thickness, color)
	local dx, dy = x2 - x1, y2 - y1
	local length = math.sqrt(dx * dx + dy * dy)
	local angle = math.deg(math.atan2(dy, dx))
	local line = Utility.New("Frame", {
		Size = UDim2.fromOffset(length, thickness),
		Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = angle,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = container,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
	return line
end

local function ring(container, cx, cy, diameter, thickness, color)
	local c = Utility.New("Frame", {
		Size = UDim2.fromOffset(diameter, diameter),
		Position = UDim2.fromOffset(cx, cy),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = container,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = c })
	Utility.New("UIStroke", { Color = color, Thickness = thickness, Parent = c })
	return c
end

local function dot(container, cx, cy, diameter, color, transparency)
	local d = Utility.New("Frame", {
		Size = UDim2.fromOffset(diameter, diameter),
		Position = UDim2.fromOffset(cx, cy),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		Parent = container,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = d })
	return d
end

local function rect(container, cx, cy, w, h, color, cornerScale, rotation, transparency)
	local r = Utility.New("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(cx, cy),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
		Parent = container,
	})
	if cornerScale and cornerScale > 0 then
		Utility.New("UICorner", { CornerRadius = UDim.new(cornerScale, 0), Parent = r })
	end
	return r
end

local function stroke(target, color, thickness)
	Utility.New("UIStroke", { Color = color, Thickness = thickness, Parent = target })
	return target
end

local drawers = {}

drawers.home = function(c, s, col)
	seg(c, 4.5 * s, 11 * s, 12 * s, 4.5 * s, 1.6 * s, col)
	seg(c, 12 * s, 4.5 * s, 19.5 * s, 11 * s, 1.6 * s, col)
	local body = rect(c, 12 * s, 15 * s, 13 * s, 9 * s, col, 0.16, 0, 1)
	stroke(body, col, 1.6 * s)
	rect(c, 12 * s, 16.5 * s, 4 * s, 6 * s, col, 0.25, 0, 0)
end

drawers.grid = function(c, s, col)
	for _, off in ipairs({ { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } }) do
		rect(c, 12 * s + off[1] * s, 12 * s + off[2] * s, 7 * s, 7 * s, col, 0.25)
	end
end

drawers.sword = function(c, s, col)
	seg(c, 6 * s, 18 * s, 17 * s, 7 * s, 2 * s, col)
	seg(c, 6 * s, 18 * s, 9 * s, 18 * s, 2 * s, col)
	seg(c, 6 * s, 18 * s, 6 * s, 15 * s, 2 * s, col)
	seg(c, 14 * s, 11 * s, 17.5 * s, 14.5 * s, 2.4 * s, col)
	local pommel = dot(c, 18.5 * s, 5.5 * s, 3 * s, col, 1)
	stroke(pommel, col, 1.6 * s)
end

drawers.eye = function(c, s, col)
	local lens = rect(c, 12 * s, 12 * s, 18 * s, 10 * s, col, 0.5, 0, 1)
	stroke(lens, col, 1.6 * s)
	dot(c, 12 * s, 12 * s, 6 * s, col, 0)
end

drawers.user = function(c, s, col)
	local head = dot(c, 12 * s, 8 * s, 7 * s, col, 1)
	stroke(head, col, 1.6 * s)
	local body = rect(c, 12 * s, 19 * s, 15 * s, 9 * s, col, 0.45, 0, 1)
	stroke(body, col, 1.6 * s)
end

drawers.settings = function(c, s, col)
	ring(c, 12 * s, 12 * s, 9 * s, 1.6 * s, col)
	local inner = dot(c, 12 * s, 12 * s, 4 * s, col, 1)
	stroke(inner, col, 1.6 * s)
	for i = 0, 5 do
		local rad = math.rad(i * 60)
		local x = 12 * s + math.cos(rad) * 10.5 * s
		local y = 12 * s + math.sin(rad) * 10.5 * s
		seg(c, 12 * s + math.cos(rad) * 8.5 * s, 12 * s + math.sin(rad) * 8.5 * s, x, y, 2 * s, col)
	end
end

drawers.search = function(c, s, col)
	ring(c, 10.5 * s, 10.5 * s, 9 * s, 1.8 * s, col)
	seg(c, 16 * s, 16 * s, 20.5 * s, 20.5 * s, 2 * s, col)
end

drawers.check = function(c, s, col)
	seg(c, 5 * s, 12.5 * s, 10 * s, 17.5 * s, 2.2 * s, col)
	seg(c, 10 * s, 17.5 * s, 19.5 * s, 6.5 * s, 2.2 * s, col)
end

drawers.close = function(c, s, col)
	seg(c, 6 * s, 6 * s, 18 * s, 18 * s, 2 * s, col)
	seg(c, 18 * s, 6 * s, 6 * s, 18 * s, 2 * s, col)
end

drawers.minimize = function(c, s, col)
	seg(c, 6 * s, 12 * s, 18 * s, 12 * s, 2 * s, col)
end

drawers.maximize = function(c, s, col)
	local r = rect(c, 12 * s, 12 * s, 12 * s, 12 * s, col, 0.16, 0, 1)
	stroke(r, col, 1.8 * s)
end

drawers.collapse = function(c, s, col)
	local r = rect(c, 12 * s, 12 * s, 12 * s, 12 * s, col, 0.16, 0, 1)
	stroke(r, col, 1.8 * s)
	seg(c, 12 * s, 8 * s, 12 * s, 16 * s, 1.8 * s, col)
	seg(c, 8 * s, 12 * s, 16 * s, 12 * s, 1.8 * s, col)
end

drawers["chevron-right"] = function(c, s, col)
	seg(c, 9 * s, 5 * s, 16 * s, 12 * s, 2 * s, col)
	seg(c, 16 * s, 12 * s, 9 * s, 19 * s, 2 * s, col)
end

drawers["chevron-left"] = function(c, s, col)
	seg(c, 15 * s, 5 * s, 8 * s, 12 * s, 2 * s, col)
	seg(c, 8 * s, 12 * s, 15 * s, 19 * s, 2 * s, col)
end

drawers["chevron-down"] = function(c, s, col)
	seg(c, 5 * s, 9 * s, 12 * s, 16 * s, 2 * s, col)
	seg(c, 12 * s, 16 * s, 19 * s, 9 * s, 2 * s, col)
end

drawers.bell = function(c, s, col)
	local body = rect(c, 12 * s, 11 * s, 13 * s, 11 * s, col, 0.5, 0, 1)
	stroke(body, col, 1.6 * s)
	seg(c, 8 * s, 17 * s, 16 * s, 17 * s, 1.6 * s, col)
	local knob = dot(c, 12 * s, 20 * s, 3.5 * s, col, 1)
	stroke(knob, col, 1.4 * s)
end

drawers.key = function(c, s, col)
	ring(c, 8 * s, 8 * s, 7 * s, 1.8 * s, col)
	seg(c, 12.5 * s, 12.5 * s, 20 * s, 20 * s, 1.8 * s, col)
	seg(c, 16 * s, 16 * s, 19 * s, 13 * s, 1.8 * s, col)
	seg(c, 18 * s, 18 * s, 21 * s, 15 * s, 1.8 * s, col)
end

drawers.palette = function(c, s, col)
	local body = rect(c, 11.5 * s, 12 * s, 16 * s, 14 * s, col, 0.6, 0, 1)
	stroke(body, col, 1.6 * s)
	dot(c, 8 * s, 9 * s, 2.6 * s, col, 0)
	dot(c, 13 * s, 7.5 * s, 2.6 * s, col, 0)
	dot(c, 17 * s, 10 * s, 2.6 * s, col, 0)
end

drawers.plus = function(c, s, col)
	seg(c, 12 * s, 5 * s, 12 * s, 19 * s, 2 * s, col)
	seg(c, 5 * s, 12 * s, 19 * s, 12 * s, 2 * s, col)
end

drawers.minus = function(c, s, col)
	seg(c, 5 * s, 12 * s, 19 * s, 12 * s, 2 * s, col)
end

drawers.dot = function(c, s, col)
	dot(c, 12 * s, 12 * s, 8 * s, col, 0)
end

drawers.dashboard = function(c, s, col)
	seg(c, 12 * s, 12 * s, 12 * s, 6 * s, 1.8 * s, col)
	seg(c, 12 * s, 12 * s, 16.5 * s, 15 * s, 1.8 * s, col)
	ring(c, 12 * s, 13 * s, 15 * s, 1.6 * s, col)
end

drawers.folder = function(c, s, col)
	local body = rect(c, 12 * s, 14 * s, 16 * s, 10 * s, col, 0.16, 0, 1)
	stroke(body, col, 1.6 * s)
	local tab = rect(c, 8.5 * s, 8.5 * s, 7 * s, 3 * s, col, 0.3, 0, 1)
	stroke(tab, col, 1.6 * s)
end

drawers.link = function(c, s, col)
	ring(c, 9.5 * s, 9.5 * s, 8 * s, 1.8 * s, col)
	ring(c, 14.5 * s, 14.5 * s, 8 * s, 1.8 * s, col)
end

drawers.info = function(c, s, col)
	ring(c, 12 * s, 12 * s, 16 * s, 1.6 * s, col)
	dot(c, 12 * s, 7.5 * s, 1.8 * s, col, 0)
	seg(c, 12 * s, 11 * s, 12 * s, 17 * s, 1.8 * s, col)
end

drawers.warning = function(c, s, col)
	seg(c, 12 * s, 4 * s, 4 * s, 19 * s, 1.8 * s, col)
	seg(c, 12 * s, 4 * s, 20 * s, 19 * s, 1.8 * s, col)
	seg(c, 4 * s, 19 * s, 20 * s, 19 * s, 1.8 * s, col)
	dot(c, 12 * s, 16.5 * s, 1.6 * s, col, 0)
	seg(c, 12 * s, 9 * s, 12 * s, 13.5 * s, 1.8 * s, col)
end

drawers.combat = drawers.sword
drawers.visuals = drawers.eye
drawers.player = drawers.user
drawers.gear = drawers.settings
drawers.config = drawers.folder
drawers.command = drawers.search
drawers.box = drawers.grid
drawers.keybind = drawers.key

function Icons.Register(name, assetId, imageRectOffset, imageRectSize)
	raster[name] = {
		Image = assetId,
		ImageRectOffset = imageRectOffset,
		ImageRectSize = imageRectSize,
	}
end

function Icons.Exists(name)
	return drawers[name] ~= nil or raster[name] ~= nil
end

function Icons.Create(name, size, color)
	size = size or 16
	color = color or Color3.new(1, 1, 1)

	if type(name) == "number" or (type(name) == "string" and name:match("^rbxassetid://")) then
		return Utility.New("ImageLabel", {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			Image = type(name) == "number" and ("rbxassetid://" .. name) or name,
			ImageColor3 = color,
		})
	end

	if raster[name] then
		local data = raster[name]
		return Utility.New("ImageLabel", {
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			Image = data.Image,
			ImageRectOffset = data.ImageRectOffset,
			ImageRectSize = data.ImageRectSize,
			ImageColor3 = color,
		})
	end

	local holder = Utility.New("Frame", {
		Name = "Icon_" .. tostring(name),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
	})

	local drawer = drawers[name]
	if not drawer then
		dot(holder, size / 2, size / 2, size * 0.32, color, 0)
		return holder
	end

	local scale = size / VIEWBOX
	local ok, err = pcall(drawer, holder, scale, color)
	if not ok then
		warn("[MeridianUI] Icon draw failed for '" .. tostring(name) .. "': " .. tostring(err))
		dot(holder, size / 2, size / 2, size * 0.32, color, 0)
	end

	return holder
end

-- ============================================================
-- Themes :: Data
-- ============================================================
local Themes = {}

Themes.Midnight = {
	Name = "Midnight",
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Background = Color3.fromRGB(12, 13, 17),
	Elevated = Color3.fromRGB(17, 18, 23),
	Surface = Color3.fromRGB(21, 22, 28),
	SurfaceSecondary = Color3.fromRGB(26, 27, 34),
	SurfaceHover = Color3.fromRGB(31, 32, 40),
	SurfacePressed = Color3.fromRGB(35, 36, 45),

	Border = Color3.fromRGB(37, 38, 47),
	BorderMuted = Color3.fromRGB(27, 28, 35),
	BorderStrong = Color3.fromRGB(50, 52, 64),

	Text = Color3.fromRGB(240, 240, 243),
	TextMuted = Color3.fromRGB(150, 152, 163),
	TextDisabled = Color3.fromRGB(85, 86, 95),
	TextInverse = Color3.fromRGB(15, 16, 20),

	Accent = Color3.fromRGB(108, 122, 255),
	AccentMuted = Color3.fromRGB(56, 61, 110),
	AccentHover = Color3.fromRGB(128, 140, 255),

	Success = Color3.fromRGB(83, 209, 140),
	Warning = Color3.fromRGB(240, 177, 88),
	Danger = Color3.fromRGB(237, 108, 108),
	Info = Color3.fromRGB(96, 165, 250),

	Shadow = Color3.fromRGB(0, 0, 0),
}

Themes.Graphite = {
	Name = "Graphite",
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Background = Color3.fromRGB(16, 16, 17),
	Elevated = Color3.fromRGB(21, 21, 22),
	Surface = Color3.fromRGB(25, 25, 27),
	SurfaceSecondary = Color3.fromRGB(30, 30, 32),
	SurfaceHover = Color3.fromRGB(35, 35, 38),
	SurfacePressed = Color3.fromRGB(40, 40, 43),

	Border = Color3.fromRGB(41, 41, 44),
	BorderMuted = Color3.fromRGB(30, 30, 33),
	BorderStrong = Color3.fromRGB(55, 55, 59),

	Text = Color3.fromRGB(236, 236, 237),
	TextMuted = Color3.fromRGB(153, 153, 156),
	TextDisabled = Color3.fromRGB(88, 88, 90),
	TextInverse = Color3.fromRGB(18, 18, 19),

	Accent = Color3.fromRGB(214, 216, 222),
	AccentMuted = Color3.fromRGB(70, 70, 74),
	AccentHover = Color3.fromRGB(232, 234, 240),

	Success = Color3.fromRGB(97, 201, 146),
	Warning = Color3.fromRGB(224, 174, 96),
	Danger = Color3.fromRGB(224, 110, 110),
	Info = Color3.fromRGB(129, 162, 219),

	Shadow = Color3.fromRGB(0, 0, 0),
}

Themes.Obsidian = {
	Name = "Obsidian",
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Background = Color3.fromRGB(8, 8, 10),
	Elevated = Color3.fromRGB(13, 13, 15),
	Surface = Color3.fromRGB(17, 17, 20),
	SurfaceSecondary = Color3.fromRGB(22, 22, 25),
	SurfaceHover = Color3.fromRGB(27, 27, 31),
	SurfacePressed = Color3.fromRGB(31, 31, 36),

	Border = Color3.fromRGB(33, 33, 38),
	BorderMuted = Color3.fromRGB(22, 22, 26),
	BorderStrong = Color3.fromRGB(46, 46, 53),

	Text = Color3.fromRGB(239, 238, 235),
	TextMuted = Color3.fromRGB(146, 144, 139),
	TextDisabled = Color3.fromRGB(82, 81, 78),
	TextInverse = Color3.fromRGB(12, 12, 13),

	Accent = Color3.fromRGB(214, 168, 96),
	AccentMuted = Color3.fromRGB(84, 68, 44),
	AccentHover = Color3.fromRGB(230, 188, 122),

	Success = Color3.fromRGB(112, 199, 136),
	Warning = Color3.fromRGB(224, 174, 96),
	Danger = Color3.fromRGB(214, 105, 96),
	Info = Color3.fromRGB(122, 158, 214),

	Shadow = Color3.fromRGB(0, 0, 0),
}

Themes.Aurora = {
	Name = "Aurora",
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Background = Color3.fromRGB(9, 14, 14),
	Elevated = Color3.fromRGB(13, 19, 19),
	Surface = Color3.fromRGB(17, 24, 24),
	SurfaceSecondary = Color3.fromRGB(21, 29, 29),
	SurfaceHover = Color3.fromRGB(26, 35, 35),
	SurfacePressed = Color3.fromRGB(30, 40, 40),

	Border = Color3.fromRGB(32, 42, 41),
	BorderMuted = Color3.fromRGB(22, 30, 29),
	BorderStrong = Color3.fromRGB(44, 58, 56),

	Text = Color3.fromRGB(233, 241, 239),
	TextMuted = Color3.fromRGB(142, 163, 158),
	TextDisabled = Color3.fromRGB(79, 92, 89),
	TextInverse = Color3.fromRGB(10, 15, 15),

	Accent = Color3.fromRGB(84, 214, 178),
	AccentMuted = Color3.fromRGB(40, 86, 74),
	AccentHover = Color3.fromRGB(112, 230, 197),

	Success = Color3.fromRGB(96, 209, 143),
	Warning = Color3.fromRGB(224, 184, 96),
	Danger = Color3.fromRGB(224, 112, 112),
	Info = Color3.fromRGB(101, 188, 214),

	Shadow = Color3.fromRGB(0, 0, 0),
}

Themes.Light = {
	Name = "Light",
	Font = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,

	Background = Color3.fromRGB(246, 246, 248),
	Elevated = Color3.fromRGB(255, 255, 255),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceSecondary = Color3.fromRGB(241, 241, 244),
	SurfaceHover = Color3.fromRGB(233, 234, 238),
	SurfacePressed = Color3.fromRGB(224, 225, 230),

	Border = Color3.fromRGB(224, 224, 229),
	BorderMuted = Color3.fromRGB(235, 235, 239),
	BorderStrong = Color3.fromRGB(203, 204, 211),

	Text = Color3.fromRGB(24, 25, 28),
	TextMuted = Color3.fromRGB(107, 109, 118),
	TextDisabled = Color3.fromRGB(178, 179, 185),
	TextInverse = Color3.fromRGB(246, 246, 248),

	Accent = Color3.fromRGB(83, 92, 235),
	AccentMuted = Color3.fromRGB(224, 226, 250),
	AccentHover = Color3.fromRGB(103, 111, 240),

	Success = Color3.fromRGB(35, 155, 96),
	Warning = Color3.fromRGB(184, 122, 22),
	Danger = Color3.fromRGB(206, 62, 62),
	Info = Color3.fromRGB(42, 111, 199),

	Shadow = Color3.fromRGB(60, 60, 70),
}

-- ============================================================
-- Themes :: ThemeManager
-- ============================================================
local ThemeManager = {}
ThemeManager.Current = Themes.Midnight
ThemeManager.Changed = Signal.new()

local registry = {}

function ThemeManager.Register(instance, property, key, transform)
	local entry = { instance = instance, property = property, key = key, transform = transform }
	table.insert(registry, entry)
	local value = ThemeManager.Current[key]
	if transform then
		value = transform(value)
	end
	if value ~= nil then
		instance[property] = value
	end
	return entry
end

function ThemeManager.Unregister(entry)
	for i, e in ipairs(registry) do
		if e == entry then
			table.remove(registry, i)
			return
		end
	end
end

function ThemeManager.UnregisterInstance(instance)
	for i = #registry, 1, -1 do
		if registry[i].instance == instance then
			table.remove(registry, i)
		end
	end
end

function ThemeManager.SetTheme(theme)
	if type(theme) == "string" then
		local resolved = Themes[theme]
		if not resolved then
			warn("[MeridianUI] Unknown theme name: " .. theme)
			return
		end
		theme = resolved
	elseif type(theme) == "table" and not theme.Name then
		theme.Name = "Custom"
	end

	ThemeManager.Current = theme

	for _, entry in ipairs(table.clone(registry)) do
		local ok, instanceValid = pcall(function()
			return entry.instance and entry.instance.Parent ~= nil
		end)
		if ok and instanceValid then
			local value = theme[entry.key]
			if entry.transform then
				value = entry.transform(value)
			end
			if value ~= nil then
				pcall(function()
					entry.instance[entry.property] = value
				end)
			end
		end
	end

	ThemeManager.Changed:Fire(theme)
end

function ThemeManager.RegisterCustomTheme(name, theme)
	theme.Name = name
	Themes[name] = theme
	return theme
end

function ThemeManager.ListThemes()
	local names = {}
	for name in pairs(Themes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ThemeManager.Get(key)
	return ThemeManager.Current[key]
end

-- ============================================================
-- Animation :: AnimationManager
-- ============================================================
local AnimationManager = {}
AnimationManager.ReducedMotion = false
AnimationManager.SpeedMultiplier = 1

local activeTweens = setmetatable({}, { __mode = "k" })

local Presets = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Snappy = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Smooth = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Emphasized = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	EaseInOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

AnimationManager.Presets = Presets

local function resolveInfo(presetOrInfo)
	local info = presetOrInfo
	if type(presetOrInfo) == "string" then
		info = Presets[presetOrInfo] or Presets.Smooth
	elseif presetOrInfo == nil then
		info = Presets.Smooth
	end
	if AnimationManager.SpeedMultiplier ~= 1 then
		info = TweenInfo.new(
			info.Time * AnimationManager.SpeedMultiplier,
			info.EasingStyle,
			info.EasingDirection,
			info.RepeatCount,
			info.Reverses,
			info.DelayTime
		)
	end
	return info
end

function AnimationManager.Tween(instance, presetOrInfo, properties, onComplete)
	if not instance or not instance.Parent then
		return nil
	end

	if AnimationManager.ReducedMotion then
		for property, value in pairs(properties) do
			instance[property] = value
		end
		if onComplete then
			task.spawn(onComplete)
		end
		return nil
	end

	local info = resolveInfo(presetOrInfo)

	local perInstance = activeTweens[instance]
	if not perInstance then
		perInstance = {}
		activeTweens[instance] = perInstance
	end

	for property in pairs(properties) do
		if perInstance[property] then
			perInstance[property]:Cancel()
			perInstance[property] = nil
		end
	end

	local tween = TweenService:Create(instance, info, properties)
	for property in pairs(properties) do
		perInstance[property] = tween
	end

	tween.Completed:Once(function(state)
		for property in pairs(properties) do
			if perInstance[property] == tween then
				perInstance[property] = nil
			end
		end
		if onComplete and state == Enum.PlaybackState.Completed then
			onComplete()
		end
	end)

	tween:Play()

	return tween
end

function AnimationManager.Cancel(instance)
	local perInstance = activeTweens[instance]
	if not perInstance then
		return
	end
	for _, tween in pairs(perInstance) do
		tween:Cancel()
	end
	activeTweens[instance] = nil
end

function AnimationManager.SetReducedMotion(state)
	AnimationManager.ReducedMotion = state
end

function AnimationManager.SetSpeed(multiplier)
	AnimationManager.SpeedMultiplier = math.clamp(multiplier, 0.25, 3)
end

-- ============================================================
-- Configuration :: ConfigManager
-- ============================================================
local ConfigManager = {}
ConfigManager.__index = ConfigManager

local function fileApiAvailable()
	return typeof(writefile) == "function"
		and typeof(readfile) == "function"
		and typeof(isfile) == "function"
end

function ConfigManager.new(folderName)
	local self = setmetatable({}, ConfigManager)
	self.Folder = folderName or "MeridianUI"
	self.Flags = {}
	self.Available = fileApiAvailable()

	if self.Available and typeof(makefolder) == "function" and typeof(isfolder) == "function" then
		if not isfolder(self.Folder) then
			pcall(makefolder, self.Folder)
		end
	end

	return self
end

function ConfigManager:Register(id, accessor)
	if self.Flags[id] then
		warn("[MeridianUI] Duplicate config id registered: " .. id)
	end
	self.Flags[id] = accessor
end

function ConfigManager:Unregister(id)
	self.Flags[id] = nil
end

local function serializeValue(value)
	if typeof(value) == "Color3" then
		return { __type = "Color3", r = value.R, g = value.G, b = value.B }
	elseif typeof(value) == "EnumItem" then
		return { __type = "Enum", enum = tostring(value.EnumType), name = value.Name }
	elseif typeof(value) == "Vector2" then
		return { __type = "Vector2", x = value.X, y = value.Y }
	end
	return value
end

local function deserializeValue(value)
	if type(value) == "table" and value.__type then
		if value.__type == "Color3" then
			return Color3.new(value.r, value.g, value.b)
		elseif value.__type == "Enum" then
			local ok, enumTable = pcall(function()
				return Enum[value.enum]
			end)
			if ok and enumTable then
				return enumTable[value.name]
			end
		elseif value.__type == "Vector2" then
			return Vector2.new(value.x, value.y)
		end
	end
	return value
end

function ConfigManager:Save(name)
	local data = {}
	for id, accessor in pairs(self.Flags) do
		local ok, value = pcall(accessor.Get)
		if ok then
			data[id] = serializeValue(value)
		end
	end

	local encoded = HttpService:JSONEncode(data)

	if not self.Available then
		return false, "File system API not available in this environment"
	end

	local path = self.Folder .. "/" .. name .. ".json"
	local ok, err = pcall(writefile, path, encoded)
	if not ok then
		return false, err
	end

	return true, path
end

function ConfigManager:Load(name)
	if not self.Available then
		return false, "File system API not available in this environment"
	end

	local path = self.Folder .. "/" .. name .. ".json"
	if not isfile(path) then
		return false, "Config file does not exist"
	end

	local ok, contents = pcall(readfile, path)
	if not ok then
		return false, contents
	end

	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(contents)
	end)
	if not decodeOk then
		return false, "Failed to decode config"
	end

	for id, value in pairs(data) do
		local accessor = self.Flags[id]
		if accessor then
			pcall(accessor.Set, deserializeValue(value))
		end
	end

	return true
end

function ConfigManager:ListConfigs()
	if not self.Available or typeof(listfiles) ~= "function" then
		return {}
	end
	local results = {}
	local ok, files = pcall(listfiles, self.Folder)
	if ok then
		for _, path in ipairs(files) do
			local name = path:match("([^/\\]+)%.json$")
			if name then
				table.insert(results, name)
			end
		end
	end
	return results
end

function ConfigManager:Delete(name)
	if not self.Available or typeof(delfile) ~= "function" then
		return false
	end
	local path = self.Folder .. "/" .. name .. ".json"
	if isfile(path) then
		pcall(delfile, path)
		return true
	end
	return false
end

-- ============================================================
-- Components :: Button
-- ============================================================
local Button = {}
Button.__index = Button

local VARIANT_KEYS = {
	Primary = { bg = "Accent", text = "TextInverse", border = nil },
	Secondary = { bg = "Surface", text = "Text", border = "Border" },
	Ghost = { bg = nil, text = "Text", border = nil },
	Destructive = { bg = "Danger", text = "TextInverse", border = nil },
}

function Button.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Button)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._disabled = config.Disabled or false
	self._loading = false
	self._variant = config.Variant or "Secondary"
	local scheme = VARIANT_KEYS[self._variant] or VARIANT_KEYS.Secondary

	local hasDescription = config.Description ~= nil and config.Description ~= ""

	self.Instance = Utility.New("TextButton", {
		Name = "Button_" .. tostring(config.Title or "Button"),
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = ThemeManager.Get(scheme.bg or "SurfaceHover"),
		BackgroundTransparency = scheme.bg and 0 or 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, hasDescription and 52 or 40),
		ClipsDescendants = true,
		Parent = parent,
	})

	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })

	if scheme.border then
		local strokeObj = Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get(scheme.border), Parent = self.Instance })
		self._maid:Give(ThemeManager.Register(strokeObj, "Color", scheme.border))
	end

	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", scheme.bg or "SurfaceHover"))

	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		Parent = self.Instance,
	})
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = self.Instance,
	})

	if config.Icon then
		self.IconHolder = Utility.New("Frame", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Parent = self.Instance,
		})
		local icon = Icons.Create(config.Icon, 18, ThemeManager.Get(scheme.text))
		icon.Parent = self.IconHolder
		self._icon = icon
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", scheme.text))
	end

	local textHolder = Utility.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, config.Icon and -28 or 0, 1, 0),
		Parent = self.Instance,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 1),
		Parent = textHolder,
	})

	self.TitleLabel = Utility.New("TextLabel", {
		Text = config.Title or "Button",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get(scheme.text),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = textHolder,
	})
	self._maid:Give(ThemeManager.Register(self.TitleLabel, "TextColor3", scheme.text))

	if hasDescription then
		self.DescriptionLabel = Utility.New("TextLabel", {
			Text = config.Description,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextTransparency = self._variant == "Primary" and 0.25 or 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = textHolder,
		})
		if self._variant ~= "Primary" then
			self._maid:Give(ThemeManager.Register(self.DescriptionLabel, "TextColor3", "TextMuted"))
		end
	end

	self._spinner = Utility.New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Instance,
	})
	local ring = Utility.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = self._spinner,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	local spinnerStroke = Utility.New("UIStroke", { Thickness = 2, Color = ThemeManager.Get(scheme.text), Transparency = 0.3, Parent = ring })
	self._maid:Give(ThemeManager.Register(spinnerStroke, "Color", scheme.text))

	local ripple = Utility.Ripple(self.Instance, ThemeManager.Get(scheme.text))

	self._maid:Give(self.Instance.MouseEnter:Connect(function()
		if self._disabled or self._loading then return end
		AnimationManager.Tween(self.Instance, "Fast", { BackgroundTransparency = scheme.bg and (self._variant == "Primary" and 0.08 or 0) or 0.94 })
	end))

	self._maid:Give(self.Instance.MouseLeave:Connect(function()
		if self._disabled or self._loading then return end
		AnimationManager.Tween(self.Instance, "Fast", { BackgroundTransparency = scheme.bg and 0 or 1 })
	end))

	self._maid:Give(self.Instance.MouseButton1Down:Connect(function()
		if self._disabled or self._loading then return end
		AnimationManager.Tween(self.Instance, "Fast", { Size = UDim2.new(1, -2, 0, self.Instance.AbsoluteSize.Y) })
	end))

	self._maid:Give(self.Instance.MouseButton1Up:Connect(function()
		if self._disabled or self._loading then return end
		AnimationManager.Tween(self.Instance, "Fast", { Size = UDim2.new(1, 0, 0, self.Instance.AbsoluteSize.Y) })
	end))

	self._maid:Give(self.Instance.MouseButton1Click:Connect(function()
		if self._disabled or self._loading then return end
		local mouse = game:GetService("UserInputService"):GetMouseLocation()
		pcall(ripple, mouse)
		task.spawn(self._callback)
	end))

	if config.Tooltip then
		self:_setupTooltip(config.Tooltip)
	end

	if self._disabled then
		self:SetDisabled(true)
	end

	return self
end

function Button:_setupTooltip(text)
	local tooltip
	self._maid:Give(self.Instance.MouseEnter:Connect(function()
		if tooltip then return end
		tooltip = Utility.New("TextLabel", {
			Text = text,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("Text"),
			BackgroundColor3 = ThemeManager.Get("Elevated"),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 26),
			Position = UDim2.new(0, 0, 0, -30),
			ZIndex = 200,
			BackgroundTransparency = 1,
			TextTransparency = 1,
			Parent = self.Instance,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tooltip })
		Utility.New("UIStroke", { Color = ThemeManager.Get("Border"), Thickness = 1, Parent = tooltip })
		Utility.New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = tooltip,
		})
		AnimationManager.Tween(tooltip, "Fast", { BackgroundTransparency = 0, TextTransparency = 0 })
	end))
	self._maid:Give(self.Instance.MouseLeave:Connect(function()
		if tooltip then
			local t = tooltip
			tooltip = nil
			AnimationManager.Tween(t, "Fast", { BackgroundTransparency = 1, TextTransparency = 1 }, function()
				t:Destroy()
			end)
		end
	end))
end

function Button:SetLoading(state)
	self._loading = state
	self._spinner.Visible = state
	if self._icon then
		self.IconHolder.Visible = not state
	end
	if state then
		local rotation = 0
		self._spinnerConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
			rotation += dt * 360
			self._spinner.Rotation = rotation % 360
		end)
	elseif self._spinnerConnection then
		self._spinnerConnection:Disconnect()
		self._spinnerConnection = nil
	end
end

function Button:SetDisabled(state)
	self._disabled = state
	AnimationManager.Tween(self.Instance, "Fast", { BackgroundTransparency = state and 0.6 or self.Instance.BackgroundTransparency })
	self.TitleLabel.TextTransparency = state and 0.5 or 0
	if self.DescriptionLabel then
		self.DescriptionLabel.TextTransparency = state and 0.5 or 0
	end
end

function Button:Destroy()
	if self._spinnerConnection then
		self._spinnerConnection:Disconnect()
	end
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Toggle
-- ============================================================
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Toggle)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._value = config.Default or false
	self._disabled = config.Disabled or false

	local hasDescription = config.Description ~= nil and config.Description ~= ""

	self.Instance = Utility.New("TextButton", {
		Name = "Toggle_" .. tostring(config.Title or "Toggle"),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, hasDescription and 52 or 40),
		Parent = parent,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })
	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", "Surface"))

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = self.Instance,
	})

	local textHolder = Utility.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 1, 0),
		Parent = self.Instance,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 1),
		Parent = textHolder,
	})

	self.TitleLabel = Utility.New("TextLabel", {
		Text = config.Title or "Toggle",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = textHolder,
	})
	self._maid:Give(ThemeManager.Register(self.TitleLabel, "TextColor3", "Text"))

	if hasDescription then
		local desc = Utility.New("TextLabel", {
			Text = config.Description,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Parent = textHolder,
		})
		self._maid:Give(ThemeManager.Register(desc, "TextColor3", "TextMuted"))
	end

	self._track = Utility.New("Frame", {
		Size = UDim2.fromOffset(36, 20),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = ThemeManager.Get(self._value and "Accent" or "SurfaceSecondary"),
		BorderSizePixel = 0,
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._track })
	self._trackStroke = Utility.New("UIStroke", {
		Thickness = 1,
		Color = ThemeManager.Get("Border"),
		Transparency = self._value and 1 or 0,
		Parent = self._track,
	})
	self._maid:Give(ThemeManager.Register(self._trackStroke, "Color", "Border"))

	self._knob = Utility.New("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = self._value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = self._track,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._knob })

	self._maid:Give(self.Instance.MouseButton1Click:Connect(function()
		if self._disabled then return end
		self:Set(not self._value)
	end))

	self._maid:Give(self.Instance.MouseEnter:Connect(function()
		if self._disabled then return end
		AnimationManager.Tween(self.Instance, "Fast", { BackgroundColor3 = ThemeManager.Get("SurfaceHover") })
	end))
	self._maid:Give(self.Instance.MouseLeave:Connect(function()
		if self._disabled then return end
		AnimationManager.Tween(self.Instance, "Fast", { BackgroundColor3 = ThemeManager.Get("Surface") })
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self._value end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	if self._disabled then
		self:SetDisabled(true)
	end

	return self
end

function Toggle:Set(value, silent)
	self._value = value
	AnimationManager.Tween(self._track, "Snappy", {
		BackgroundColor3 = ThemeManager.Get(value and "Accent" or "SurfaceSecondary"),
	})
	AnimationManager.Tween(self._trackStroke, "Snappy", { Transparency = value and 1 or 0 })
	AnimationManager.Tween(self._knob, "Snappy", {
		Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
	})
	if not silent then
		task.spawn(self._callback, value)
	end
end

function Toggle:Get()
	return self._value
end

function Toggle:SetDisabled(state)
	self._disabled = state
	AnimationManager.Tween(self.Instance, "Fast", { BackgroundTransparency = state and 0.5 or 0 })
end

function Toggle:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Slider
-- ============================================================
local Slider = {}
Slider.__index = Slider

function Slider.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Slider)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._min = config.Min or 0
	self._max = config.Max or 100
	self._increment = config.Increment or 1
	self._suffix = config.Suffix or ""
	self._percentage = config.Percentage or false
	self._value = Utility.Clamp(config.Default or self._min, self._min, self._max)
	self._disabled = config.Disabled or false

	self.Instance = Utility.New("Frame", {
		Name = "Slider_" .. tostring(config.Title or "Slider"),
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 56),
		Parent = parent,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })
	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", "Surface"))
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
		Parent = self.Instance,
	})

	local header = Utility.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = self.Instance,
	})

	self.TitleLabel = Utility.New("TextLabel", {
		Text = config.Title or "Slider",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 1, 0),
		Parent = header,
	})
	self._maid:Give(ThemeManager.Register(self.TitleLabel, "TextColor3", "Text"))

	self._valueBox = Utility.New("TextBox", {
		Text = "",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("TextMuted"),
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -70, 0, 0),
		Parent = header,
	})
	self._maid:Give(ThemeManager.Register(self._valueBox, "TextColor3", "TextMuted"))

	self._maid:Give(self._valueBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local numeric = tonumber((self._valueBox.Text:gsub("[^%-%d%.]", "")))
			if numeric then
				self:Set(numeric)
			end
		end
		self._valueBox.Text = self:_format(self._value)
	end))

	self._track = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = ThemeManager.Get("SurfaceSecondary"),
		BorderSizePixel = 0,
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._track })
	self._maid:Give(ThemeManager.Register(self._track, "BackgroundColor3", "SurfaceSecondary"))

	self._fill = Utility.New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = ThemeManager.Get("Accent"),
		BorderSizePixel = 0,
		Parent = self._track,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._fill })
	self._maid:Give(ThemeManager.Register(self._fill, "BackgroundColor3", "Accent"))

	self._knob = Utility.New("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self._track,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self._knob })
	Utility.New("UIStroke", { Color = ThemeManager.Get("Accent"), Thickness = 2, Parent = self._knob })

	local hitArea = Utility.New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 12, 0, 24),
		Position = UDim2.new(0, -6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = self._track,
	})

	local dragging = false

	local function updateFromX(x)
		local relative = Utility.Clamp((x - self._track.AbsolutePosition.X) / self._track.AbsoluteSize.X, 0, 1)
		local raw = self._min + relative * (self._max - self._min)
		self:Set(Utility.Round(raw, self._increment))
	end

	self._maid:Give(hitArea.InputBegan:Connect(function(input)
		if self._disabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end))

	self._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end))

	self._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local hovering = false
	self._maid:Give(hitArea.MouseEnter:Connect(function() hovering = true end))
	self._maid:Give(hitArea.MouseLeave:Connect(function() hovering = false end))

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if not hovering or self._disabled or processed then return end
		if input.KeyCode == Enum.KeyCode.Left then
			self:Set(self._value - self._increment)
		elseif input.KeyCode == Enum.KeyCode.Right then
			self:Set(self._value + self._increment)
		end
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self._value end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	self:Set(self._value, true)

	return self
end

function Slider:_format(value)
	if self._percentage then
		return Utility.FormatNumber(value) .. "%"
	end
	return Utility.FormatNumber(value) .. (self._suffix ~= "" and (" " .. self._suffix) or "")
end

function Slider:Set(value, silent)
	value = Utility.Clamp(Utility.Round(value, self._increment), self._min, self._max)
	self._value = value
	local alpha = (self._max ~= self._min) and (value - self._min) / (self._max - self._min) or 0
	AnimationManager.Tween(self._fill, "Fast", { Size = UDim2.new(alpha, 0, 1, 0) })
	AnimationManager.Tween(self._knob, "Fast", { Position = UDim2.new(alpha, 0, 0.5, 0) })
	self._valueBox.Text = self:_format(value)
	if not silent then
		task.spawn(self._callback, value)
	end
end

function Slider:Get()
	return self._value
end

function Slider:SetDisabled(state)
	self._disabled = state
	self.Instance.BackgroundTransparency = state and 0.5 or 0
end

function Slider:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Dropdown
-- ============================================================
local Dropdown = {}
Dropdown.__index = Dropdown

local function normalizeOptions(options)
	local normalized = {}
	for _, option in ipairs(options or {}) do
		if type(option) == "string" then
			table.insert(normalized, { Text = option, Value = option })
		else
			table.insert(normalized, {
				Text = option.Text or tostring(option.Value),
				Value = option.Value,
				Icon = option.Icon,
				Disabled = option.Disabled,
			})
		end
	end
	return normalized
end

function Dropdown.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Dropdown)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._multi = config.Multi or false
	self._options = normalizeOptions(config.Options)
	self._searchable = config.Searchable or false
	self._open = false
	self._overlay = config.Overlay

	if self._multi then
		self._value = config.Default or {}
	else
		self._value = config.Default
	end

	self.Instance = Utility.New("Frame", {
		Name = "Dropdown_" .. tostring(config.Title or "Dropdown"),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = parent,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		Parent = self.Instance,
	})

	if config.Title then
		local titleLabel = Utility.New("TextLabel", {
			Text = config.Title,
			Font = ThemeManager.Get("FontMedium"),
			TextSize = 13,
			TextColor3 = ThemeManager.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Parent = self.Instance,
		})
		self._maid:Give(ThemeManager.Register(titleLabel, "TextColor3", "Text"))
	end

	self._button = Utility.New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 36),
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self._button })
	self._buttonStroke = Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = self._button })
	self._maid:Give(ThemeManager.Register(self._button, "BackgroundColor3", "Surface"))
	self._maid:Give(ThemeManager.Register(self._buttonStroke, "Color", "Border"))

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = self._button,
	})

	self._selectedLabel = Utility.New("TextLabel", {
		Text = "",
		Font = ThemeManager.Get("Font"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Parent = self._button,
	})
	self._maid:Give(ThemeManager.Register(self._selectedLabel, "TextColor3", "Text"))

	self._chevron = Icons.Create("chevron-down", 14, ThemeManager.Get("TextMuted"))
	self._chevron.AnchorPoint = Vector2.new(1, 0.5)
	self._chevron.Position = UDim2.new(1, 0, 0.5, 0)
	self._chevron.Parent = self._button
	self._maid:Give(ThemeManager.Register(self._chevron, "ImageColor3", "TextMuted"))

	self._maid:Give(self._button.MouseButton1Click:Connect(function()
		self:Toggle()
	end))

	self._maid:Give(self._button.MouseEnter:Connect(function()
		AnimationManager.Tween(self._buttonStroke, "Fast", { Color = ThemeManager.Get("BorderStrong") })
	end))
	self._maid:Give(self._button.MouseLeave:Connect(function()
		if not self._open then
			AnimationManager.Tween(self._buttonStroke, "Fast", { Color = ThemeManager.Get("Border") })
		end
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self._value end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	self:_refreshLabel()

	return self
end

function Dropdown:_refreshLabel()
	if self._multi then
		if #self._value == 0 then
			self._selectedLabel.Text = "Select..."
			self._selectedLabel.TextTransparency = 0.4
		else
			local names = {}
			for _, v in ipairs(self._value) do
				for _, opt in ipairs(self._options) do
					if opt.Value == v then
						table.insert(names, opt.Text)
					end
				end
			end
			self._selectedLabel.Text = table.concat(names, ", ")
			self._selectedLabel.TextTransparency = 0
		end
	else
		local found
		for _, opt in ipairs(self._options) do
			if opt.Value == self._value then
				found = opt
				break
			end
		end
		if found then
			self._selectedLabel.Text = found.Text
			self._selectedLabel.TextTransparency = 0
		else
			self._selectedLabel.Text = "Select..."
			self._selectedLabel.TextTransparency = 0.4
		end
	end
end

function Dropdown:SetOptions(options)
	self._options = normalizeOptions(options)
	self:_refreshLabel()
	if self._open then
		self:Close()
	end
end

function Dropdown:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

function Dropdown:Open()
	if self._open then return end
	self._open = true
	AnimationManager.Tween(self._buttonStroke, "Fast", { Color = ThemeManager.Get("Accent") })
	AnimationManager.Tween(self._chevron, "Fast", { Rotation = 180 })

	local overlayParent = self._overlay or self.Instance

	local popup = Utility.New("Frame", {
		Name = "DropdownPopup",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		ZIndex = 500,
		ClipsDescendants = true,
		Size = UDim2.fromOffset(self._button.AbsoluteSize.X, 0),
		Parent = overlayParent,
	})

	if self._overlay then
		local abs = self._button.AbsolutePosition
		local size = self._button.AbsoluteSize
		local viewport = workspace.CurrentCamera.ViewportSize
		local openUpward = (abs.Y + size.Y + 220) > viewport.Y
		popup.Position = UDim2.fromOffset(abs.X, openUpward and (abs.Y - 6) or (abs.Y + size.Y + 6))
		if openUpward then
			popup.AnchorPoint = Vector2.new(0, 1)
		end
	else
		popup.Position = UDim2.new(0, 0, 1, 6)
	end

	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = popup })
	Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = popup })

	Utility.New("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = popup,
	})

	local searchBox
	if self._searchable then
		searchBox = Utility.New("TextBox", {
			PlaceholderText = "Search...",
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("Text"),
			PlaceholderColor3 = ThemeManager.Get("TextDisabled"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = ThemeManager.Get("SurfaceSecondary"),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28),
			ClearTextOnFocus = false,
			Parent = popup,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBox })
		Utility.New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = searchBox })
	end

	local list = Utility.New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, self._searchable and -34 or 0),
		Position = UDim2.new(0, 0, 0, self._searchable and 34 or 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = ThemeManager.Get("BorderStrong"),
		Parent = popup,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
		Parent = list,
	})

	local optionMaid = Maid.new()

	local function renderOptions(filter)
		optionMaid:Clean()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		for _, opt in ipairs(self._options) do
			if not filter or filter == "" or Utility.FuzzyMatch(opt.Text, filter) then
				local isSelected = (self._multi and table.find(self._value, opt.Value) ~= nil) or (not self._multi and self._value == opt.Value)

				local row = Utility.New("TextButton", {
					Text = "",
					AutoButtonColor = false,
					BackgroundColor3 = isSelected and ThemeManager.Get("AccentMuted") or ThemeManager.Get("Surface"),
					BackgroundTransparency = isSelected and 0 or 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 30),
					Parent = list,
				})
				Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
				Utility.New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = row })
				Utility.New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
					Parent = row,
				})

				if opt.Icon then
					local ic = Icons.Create(opt.Icon, 14, ThemeManager.Get("TextMuted"))
					ic.Parent = row
				end

				Utility.New("TextLabel", {
					Text = opt.Text,
					Font = ThemeManager.Get("Font"),
					TextSize = 12.5,
					TextColor3 = opt.Disabled and ThemeManager.Get("TextDisabled") or ThemeManager.Get("Text"),
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -30, 1, 0),
					Parent = row,
				})

				if isSelected then
					local check = Icons.Create("check", 12, ThemeManager.Get("Accent"))
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Position = UDim2.new(1, 0, 0.5, 0)
					check.Parent = row
				end

				if not opt.Disabled then
					optionMaid:Give(row.MouseEnter:Connect(function()
						if not isSelected then
							AnimationManager.Tween(row, "Fast", { BackgroundTransparency = 0, BackgroundColor3 = ThemeManager.Get("SurfaceHover") })
						end
					end))
					optionMaid:Give(row.MouseLeave:Connect(function()
						if not isSelected then
							AnimationManager.Tween(row, "Fast", { BackgroundTransparency = 1 })
						end
					end))
					optionMaid:Give(row.MouseButton1Click:Connect(function()
						self:_selectOption(opt.Value)
						if not self._multi then
							self:Close()
						else
							renderOptions(searchBox and searchBox.Text or nil)
						end
					end))
				end
			end
		end
	end

	renderOptions(nil)

	if searchBox then
		optionMaid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			renderOptions(searchBox.Text)
		end))
	end

	task.defer(function()
		if not popup.Parent then return end
		local contentHeight = 0
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				contentHeight += child.AbsoluteSize.Y + 2
			end
		end
		local finalHeight = math.min(240, contentHeight + (self._searchable and 46 or 12))
		AnimationManager.Tween(popup, "Snappy", { Size = UDim2.fromOffset(self._button.AbsoluteSize.X, finalHeight) })
	end)

	self._popup = popup
	self._optionMaid = optionMaid

	task.defer(function()
		if not self._open then return end
		self._outsideConnection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local mousePos = UserInputService:GetMouseLocation()
			local pAbs, pSize = popup.AbsolutePosition, popup.AbsoluteSize
			local bAbs, bSize = self._button.AbsolutePosition, self._button.AbsoluteSize
			local insidePopup = mousePos.X >= pAbs.X and mousePos.X <= pAbs.X + pSize.X and mousePos.Y >= pAbs.Y and mousePos.Y <= pAbs.Y + pSize.Y
			local insideButton = mousePos.X >= bAbs.X and mousePos.X <= bAbs.X + bSize.X and mousePos.Y >= bAbs.Y and mousePos.Y <= bAbs.Y + bSize.Y
			if not insidePopup and not insideButton then
				self:Close()
			end
		end)
	end)
end

function Dropdown:_selectOption(value)
	if self._multi then
		local index = table.find(self._value, value)
		if index then
			table.remove(self._value, index)
		else
			table.insert(self._value, value)
		end
	else
		self._value = value
	end
	self:_refreshLabel()
	task.spawn(self._callback, self._value)
end

function Dropdown:Close()
	if not self._open then return end
	self._open = false
	AnimationManager.Tween(self._buttonStroke, "Fast", { Color = ThemeManager.Get("Border") })
	AnimationManager.Tween(self._chevron, "Fast", { Rotation = 0 })
	if self._outsideConnection then
		self._outsideConnection:Disconnect()
		self._outsideConnection = nil
	end
	if self._popup then
		local p = self._popup
		self._popup = nil
		AnimationManager.Tween(p, "Fast", { Size = UDim2.fromOffset(p.AbsoluteSize.X, 0) }, function()
			p:Destroy()
		end)
	end
	if self._optionMaid then
		self._optionMaid:Destroy()
		self._optionMaid = nil
	end
end

function Dropdown:Set(value, silent)
	self._value = value
	self:_refreshLabel()
	if not silent then
		task.spawn(self._callback, value)
	end
end

function Dropdown:Get()
	return self._value
end

function Dropdown:Destroy()
	self:Close()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Input
-- ============================================================
local Input = {}
Input.__index = Input

function Input.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Input)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._validate = config.Validate
	self._numeric = config.Numeric or false
	self._multiline = config.Multiline or false

	local boxHeight = self._multiline and 76 or 36
	local hasTitle = config.Title ~= nil

	self.Instance = Utility.New("Frame", {
		Name = "Input_" .. tostring(config.Title or "Input"),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = parent,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		Parent = self.Instance,
	})

	if hasTitle then
		self.TitleLabel = Utility.New("TextLabel", {
			Text = config.Title,
			Font = ThemeManager.Get("FontMedium"),
			TextSize = 13,
			TextColor3 = ThemeManager.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Parent = self.Instance,
		})
		self._maid:Give(ThemeManager.Register(self.TitleLabel, "TextColor3", "Text"))
	end

	self._field = Utility.New("Frame", {
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, boxHeight),
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self._field })
	self._stroke = Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = self._field })
	self._maid:Give(ThemeManager.Register(self._field, "BackgroundColor3", "Surface"))
	self._maid:Give(ThemeManager.Register(self._stroke, "Color", "Border"))

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, config.Clearable and 32 or 12),
		PaddingTop = UDim.new(0, self._multiline and 8 or 0),
		Parent = self._field,
	})

	self.Box = Utility.New("TextBox", {
		Text = config.Default or "",
		PlaceholderText = config.Placeholder or "",
		Font = ThemeManager.Get("Font"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		PlaceholderColor3 = ThemeManager.Get("TextDisabled"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = self._multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
		MultiLine = self._multiline,
		TextWrapped = self._multiline,
		TextEditable = not config.ReadOnly,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = self._field,
	})
	self._maid:Give(ThemeManager.Register(self.Box, "TextColor3", "Text"))
	self._maid:Give(ThemeManager.Register(self.Box, "PlaceholderColor3", "TextDisabled"))

	if config.IsPassword then
		self._realText = self.Box.Text
		self._maid:Give(self.Box:GetPropertyChangedSignal("Text"):Connect(function()
			if self._suppressMask then return end
			local displayed = self.Box.Text
			if #displayed > #self._realText then
				self._realText = self._realText .. displayed:sub(#self._realText + 1)
			elseif #displayed < #self._realText then
				self._realText = self._realText:sub(1, #displayed)
			end
			self._suppressMask = true
			self.Box.Text = string.rep("\226\128\162", #displayed)
			self._suppressMask = false
		end))
	end

	if config.Clearable then
		local clearButton = Utility.New("TextButton", {
			Text = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.new(1, -26, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = self._field,
		})
		local icon = Icons.Create("close", 12, ThemeManager.Get("TextMuted"))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = clearButton
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", "TextMuted"))
		self._maid:Give(clearButton.MouseButton1Click:Connect(function()
			self:Set("")
		end))
	end

	self._maid:Give(self.Box.Focused:Connect(function()
		AnimationManager.Tween(self._stroke, "Fast", { Color = ThemeManager.Get("Accent"), Thickness = 1.5 })
	end))

	self._maid:Give(self.Box.FocusLost:Connect(function(enterPressed)
		AnimationManager.Tween(self._stroke, "Fast", { Color = ThemeManager.Get("Border"), Thickness = 1 })
		local text = config.IsPassword and self._realText or self.Box.Text
		if self._numeric then
			local numeric = tonumber(text)
			if not numeric then
				self.Box.Text = self._lastValid or ""
				return
			end
			text = tostring(numeric)
		end
		if self._validate then
			local ok, message = self._validate(text)
			if not ok then
				self:SetError(message)
				return
			end
		end
		self:SetError(nil)
		self._lastValid = text
		task.spawn(self._callback, text, enterPressed)
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self:Get() end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	return self
end

function Input:SetError(message)
	if message then
		AnimationManager.Tween(self._stroke, "Fast", { Color = ThemeManager.Get("Danger") })
		if not self._errorLabel then
			self._errorLabel = Utility.New("TextLabel", {
				Font = ThemeManager.Get("Font"),
				TextSize = 11,
				TextColor3 = ThemeManager.Get("Danger"),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				Parent = self.Instance,
			})
		end
		self._errorLabel.Text = message
		self._errorLabel.Visible = true
	elseif self._errorLabel then
		self._errorLabel.Visible = false
	end
end

function Input:Set(text, silent)
	self.Box.Text = text
	self._lastValid = text
	if not silent then
		task.spawn(self._callback, text, true)
	end
end

function Input:Get()
	return self._realText or self.Box.Text
end

function Input:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Keybind
-- ============================================================
local Keybind = {}
Keybind.__index = Keybind

local function keyName(keyCode)
	if not keyCode then return "None" end
	return keyCode.Name
end

function Keybind.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Keybind)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._value = config.Default
	self._listening = false

	self.Instance = Utility.New("Frame", {
		Name = "Keybind_" .. tostring(config.Title or "Keybind"),
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = parent,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })
	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", "Surface"))
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = self.Instance,
	})

	self.TitleLabel = Utility.New("TextLabel", {
		Text = config.Title or "Keybind",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -100, 1, 0),
		Parent = self.Instance,
	})
	self._maid:Give(ThemeManager.Register(self.TitleLabel, "TextColor3", "Text"))

	self._keyButton = Utility.New("TextButton", {
		Text = keyName(self._value),
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 12,
		TextColor3 = ThemeManager.Get("TextMuted"),
		AutoButtonColor = false,
		BackgroundColor3 = ThemeManager.Get("SurfaceSecondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 88, 0, 26),
		Position = UDim2.new(1, -88, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._keyButton })
	self._maid:Give(ThemeManager.Register(self._keyButton, "BackgroundColor3", "SurfaceSecondary"))
	self._maid:Give(ThemeManager.Register(self._keyButton, "TextColor3", "TextMuted"))

	self._maid:Give(self._keyButton.MouseButton1Click:Connect(function()
		if self._listening then return end
		self._listening = true
		self._keyButton.Text = "..."
		AnimationManager.Tween(self._keyButton, "Fast", { BackgroundColor3 = ThemeManager.Get("Accent") })
	end))

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if not self._listening then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self:Set(nil)
			else
				self:Set(input.KeyCode)
			end
			self._listening = false
			AnimationManager.Tween(self._keyButton, "Fast", { BackgroundColor3 = ThemeManager.Get("SurfaceSecondary") })
		elseif input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2 then
			self._listening = false
			self._keyButton.Text = keyName(self._value)
			AnimationManager.Tween(self._keyButton, "Fast", { BackgroundColor3 = ThemeManager.Get("SurfaceSecondary") })
		end
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self._value end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	if config.CallOnPress ~= false then
		self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
			if processed or self._listening then return end
			if self._value and input.KeyCode == self._value then
				task.spawn(self._callback, self._value)
			end
		end))
	end

	return self
end

function Keybind:Set(keyCode, silent)
	self._value = keyCode
	self._keyButton.Text = keyName(keyCode)
	if not silent then
		task.spawn(self._callback, keyCode)
	end
end

function Keybind:Get()
	return self._value
end

function Keybind:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: ColorPicker
-- ============================================================
local ColorPicker = {}
ColorPicker.__index = ColorPicker

local function toHex(color)
	return string.format("%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function fromHex(hex)
	hex = hex:gsub("#", "")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

function ColorPicker.new(parent, config)
	config = config or {}
	local self = setmetatable({}, ColorPicker)
	self._maid = Maid.new()
	self._callback = config.Callback or function() end
	self._value = config.Default or Color3.fromRGB(255, 255, 255)
	self._alpha = config.DefaultTransparency or 0
	self._overlay = config.Overlay
	self._presets = config.Presets or {
		Color3.fromRGB(237, 108, 108), Color3.fromRGB(240, 177, 88), Color3.fromRGB(233, 214, 107),
		Color3.fromRGB(83, 209, 140), Color3.fromRGB(96, 165, 250), Color3.fromRGB(108, 122, 255),
		Color3.fromRGB(198, 122, 235), Color3.fromRGB(255, 255, 255), Color3.fromRGB(20, 20, 24),
	}

	local h, s, v = Color3.toHSV(self._value)
	self._hue, self._sat, self._val = h, s, v

	self.Instance = Utility.New("Frame", {
		Name = "ColorPicker_" .. tostring(config.Title or "Color"),
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = parent,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })
	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", "Surface"))
	Utility.New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = self.Instance })

	Utility.New("TextLabel", {
		Text = config.Title or "Color",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, 0),
		Parent = self.Instance,
	})

	self._swatchButton = Utility.New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = self._value,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(40, 24),
		Position = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = self.Instance,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = self._swatchButton })
	Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = self._swatchButton })

	self._maid:Give(self._swatchButton.MouseButton1Click:Connect(function()
		self:Toggle()
	end))

	if config.Flag and config.ConfigManager then
		config.ConfigManager:Register(config.Flag, {
			Get = function() return self._value end,
			Set = function(v) self:Set(v, true) end,
		})
	end

	return self
end

function ColorPicker:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

function ColorPicker:Open()
	if self._open then return end
	self._open = true

	local overlayParent = self._overlay or self.Instance
	local abs = self._swatchButton.AbsolutePosition
	local size = self._swatchButton.AbsoluteSize

	local popup = Utility.New("Frame", {
		Name = "ColorPickerPopup",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		ZIndex = 500,
		Size = UDim2.fromOffset(232, 240),
		Parent = overlayParent,
	})
	if self._overlay then
		popup.Position = UDim2.fromOffset(abs.X - 232 + size.X, abs.Y + size.Y + 6)
	else
		popup.Position = UDim2.new(1, -232, 1, 6)
	end
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = popup })
	Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = popup })
	Utility.New("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = popup })

	local svBox = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 130),
		BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1),
		BorderSizePixel = 0,
		Parent = popup,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = svBox })
	local whiteOverlay = Utility.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = svBox,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = whiteOverlay })
	Utility.New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = whiteOverlay,
	})
	local blackOverlay = Utility.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = svBox,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = blackOverlay })
	Utility.New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = blackOverlay,
	})

	local svCursor = Utility.New("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(self._sat, 0, 1 - self._val, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = svBox,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svCursor })
	Utility.New("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Parent = svCursor })

	local hueBar = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 142),
		BorderSizePixel = 0,
		Parent = popup,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
	Utility.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
			ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
			ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
			ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
			ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
		}),
		Parent = hueBar,
	})
	local hueCursor = Utility.New("Frame", {
		Size = UDim2.fromOffset(4, 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(self._hue, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = hueBar,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 2), Parent = hueCursor })

	local hexRow = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 0, 168),
		BackgroundTransparency = 1,
		Parent = popup,
	})
	local hexPrefix = Utility.New("TextLabel", {
		Text = "#",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("TextMuted"),
		BackgroundColor3 = ThemeManager.Get("SurfaceSecondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 20, 1, 0),
		Parent = hexRow,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hexPrefix })
	local hexBox = Utility.New("TextBox", {
		Text = toHex(self._value),
		Font = ThemeManager.Get("Font"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		BackgroundColor3 = ThemeManager.Get("SurfaceSecondary"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 24, 0, 0),
		ClearTextOnFocus = false,
		Parent = hexRow,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hexBox })
	Utility.New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = hexBox })

	local presetRow = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 204),
		BackgroundTransparency = 1,
		Parent = popup,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = presetRow,
	})
	for _, preset in ipairs(self._presets) do
		local swatch = Utility.New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = preset,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(20, 20),
			Parent = presetRow,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = swatch })
		Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = swatch })
		self._maid:Give(swatch.MouseButton1Click:Connect(function()
			local ph, ps, pv = Color3.toHSV(preset)
			self._hue, self._sat, self._val = ph, ps, pv
			self:_applyColor()
			svBox.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
			hueCursor.Position = UDim2.new(self._hue, 0, 0.5, 0)
			svCursor.Position = UDim2.new(self._sat, 0, 1 - self._val, 0)
			hexBox.Text = toHex(self._value)
		end))
	end

	local function updateSV(pos)
		local rel = svBox.AbsolutePosition
		local sz = svBox.AbsoluteSize
		local sat = Utility.Clamp((pos.X - rel.X) / sz.X, 0, 1)
		local val = 1 - Utility.Clamp((pos.Y - rel.Y) / sz.Y, 0, 1)
		self._sat, self._val = sat, val
		svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
		self:_applyColor()
		hexBox.Text = toHex(self._value)
	end

	local function updateHue(pos)
		local rel = hueBar.AbsolutePosition
		local sz = hueBar.AbsoluteSize
		local hue = Utility.Clamp((pos.X - rel.X) / sz.X, 0, 1)
		self._hue = hue
		hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
		svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		self:_applyColor()
		hexBox.Text = toHex(self._value)
	end

	local draggingSV, draggingHue = false, false

	self._popupMaid = Maid.new()
	self._popupMaid:Give(svBox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
			updateSV(input.Position)
		end
	end))
	self._popupMaid:Give(hueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			updateHue(input.Position)
		end
	end))
	self._popupMaid:Give(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if draggingSV then updateSV(input.Position) end
			if draggingHue then updateHue(input.Position) end
		end
	end))
	self._popupMaid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSV, draggingHue = false, false
		end
	end))

	self._popupMaid:Give(hexBox.FocusLost:Connect(function()
		local color = fromHex(hexBox.Text)
		if color then
			local h2, s2, v2 = Color3.toHSV(color)
			self._hue, self._sat, self._val = h2, s2, v2
			self:_applyColor()
			svBox.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
			hueCursor.Position = UDim2.new(self._hue, 0, 0.5, 0)
			svCursor.Position = UDim2.new(self._sat, 0, 1 - self._val, 0)
		else
			hexBox.Text = toHex(self._value)
		end
	end))

	self._popup = popup

	task.defer(function()
		if not self._open then return end
		self._outsideConnection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local mousePos = UserInputService:GetMouseLocation()
			local pAbs, pSize = popup.AbsolutePosition, popup.AbsoluteSize
			local bAbs, bSize = self._swatchButton.AbsolutePosition, self._swatchButton.AbsoluteSize
			local insidePopup = mousePos.X >= pAbs.X and mousePos.X <= pAbs.X + pSize.X and mousePos.Y >= pAbs.Y and mousePos.Y <= pAbs.Y + pSize.Y
			local insideButton = mousePos.X >= bAbs.X and mousePos.X <= bAbs.X + bSize.X and mousePos.Y >= bAbs.Y and mousePos.Y <= bAbs.Y + bSize.Y
			if not insidePopup and not insideButton then
				self:Close()
			end
		end)
	end)
end

function ColorPicker:_applyColor()
	self._value = Color3.fromHSV(self._hue, self._sat, self._val)
	self._swatchButton.BackgroundColor3 = self._value
	task.spawn(self._callback, self._value, self._alpha)
end

function ColorPicker:Close()
	if not self._open then return end
	self._open = false
	if self._outsideConnection then
		self._outsideConnection:Disconnect()
		self._outsideConnection = nil
	end
	if self._popupMaid then
		self._popupMaid:Destroy()
		self._popupMaid = nil
	end
	if self._popup then
		self._popup:Destroy()
		self._popup = nil
	end
end

function ColorPicker:Set(color, silent)
	self._value = color
	local h, s, v = Color3.toHSV(color)
	self._hue, self._sat, self._val = h, s, v
	self._swatchButton.BackgroundColor3 = color
	if not silent then
		task.spawn(self._callback, color, self._alpha)
	end
end

function ColorPicker:Get()
	return self._value, self._alpha
end

function ColorPicker:Destroy()
	self:Close()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Section
-- ============================================================
local Section = {}
Section.__index = Section

function Section.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Section)
	self._maid = Maid.new()

	self.Instance = Utility.New("Frame", {
		Name = "Section_" .. tostring(config.Title or "Section"),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = parent,
	})

	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 8),
		Parent = self.Instance,
	})

	if config.Title then
		local header = Utility.New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = -1,
			Parent = self.Instance,
		})
		local title = Utility.New("TextLabel", {
			Text = string.upper(config.Title),
			Font = ThemeManager.Get("FontMedium"),
			TextSize = 11,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = header,
		})
		self._maid:Give(ThemeManager.Register(title, "TextColor3", "TextMuted"))
	end

	self.Container = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Instance,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		Parent = self.Container,
	})

	return self
end

function Section:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: Paragraph
-- ============================================================
local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(parent, config)
	config = config or {}
	local self = setmetatable({}, Paragraph)
	self._maid = Maid.new()
	self._expanded = not config.Collapsed

	self.Instance = Utility.New("Frame", {
		Name = "Paragraph_" .. tostring(config.Title or "Paragraph"),
		BackgroundColor3 = ThemeManager.Get("Surface"),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Parent = parent,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Instance })
	self._maid:Give(ThemeManager.Register(self.Instance, "BackgroundColor3", "Surface"))

	if config.Accent then
		local bar = Utility.New("Frame", {
			Size = UDim2.new(0, 3, 1, -16),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = ThemeManager.Get("Accent"),
			BorderSizePixel = 0,
			Parent = self.Instance,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
		self._maid:Give(ThemeManager.Register(bar, "BackgroundColor3", "Accent"))
	end

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, config.Accent and 16 or 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = self.Instance,
	})

	local content = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.Instance,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		Parent = content,
	})

	local headerRow = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = content,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		Parent = headerRow,
	})

	if config.Icon then
		local iconHolder = Utility.New("Frame", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Parent = headerRow,
		})
		local icon = Icons.Create(config.Icon, 18, ThemeManager.Get("TextMuted"))
		icon.Parent = iconHolder
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", "TextMuted"))
	end

	local textCol = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, config.Icon and -26 or 0, 0, 0),
		Parent = headerRow,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 3),
		Parent = textCol,
	})

	if config.Title then
		local title = Utility.New("TextLabel", {
			Text = config.Title,
			Font = ThemeManager.Get("FontMedium"),
			TextSize = 13,
			TextColor3 = ThemeManager.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = textCol,
		})
		self._maid:Give(ThemeManager.Register(title, "TextColor3", "Text"))
	end

	if config.Description then
		local desc = Utility.New("TextLabel", {
			Text = config.Description,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = textCol,
		})
		self._maid:Give(ThemeManager.Register(desc, "TextColor3", "TextMuted"))
	end

	if config.Expandable and config.ExpandedContent then
		local expandedBox = Utility.New("TextLabel", {
			Text = config.ExpandedContent,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = self._expanded,
			Parent = content,
		})
		self._maid:Give(ThemeManager.Register(expandedBox, "TextColor3", "TextMuted"))

		local toggleButton = Utility.New("TextButton", {
			Text = self._expanded and "Show less" or "Show more",
			Font = ThemeManager.Get("FontMedium"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("Accent"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Parent = content,
		})
		self._maid:Give(ThemeManager.Register(toggleButton, "TextColor3", "Accent"))

		self._maid:Give(toggleButton.MouseButton1Click:Connect(function()
			self._expanded = not self._expanded
			expandedBox.Visible = self._expanded
			toggleButton.Text = self._expanded and "Show less" or "Show more"
		end))
	end

	return self
end

function Paragraph:Destroy()
	self._maid:Destroy()
	self.Instance:Destroy()
end

-- ============================================================
-- Components :: NotificationManager
-- ============================================================
local NotificationManager = {}
NotificationManager.__index = NotificationManager

local TYPE_STYLE = {
	Info = { icon = "info", color = "Info" },
	Success = { icon = "check", color = "Success" },
	Warning = { icon = "warning", color = "Warning" },
	Error = { icon = "close", color = "Danger" },
}

function NotificationManager.new(screenGui)
	local self = setmetatable({}, NotificationManager)

	self.Container = Utility.New("Frame", {
		Name = "NotificationLayer",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 1, -32),
		Position = UDim2.new(1, -16, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 1000,
		Parent = screenGui,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Container,
	})

	return self
end

function NotificationManager:Notify(config)
	config = config or {}
	local style = TYPE_STYLE[config.Type] or TYPE_STYLE.Info
	local duration = config.Duration or 4

	local card = Utility.New("Frame", {
		Name = "Notification",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Position = UDim2.new(1, 40, 0, 0),
		Parent = self.Container,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
	Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = card })

	local accent = Utility.New("Frame", {
		Size = UDim2.new(0, 3, 1, -16),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = ThemeManager.Get(style.color),
		BorderSizePixel = 0,
		Parent = card,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accent })

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		Parent = card,
	})

	local row = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = card,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		Parent = row,
	})

	local iconHolder = Utility.New("Frame", {
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Parent = row,
	})
	local icon = Icons.Create(config.Icon or style.icon, 18, ThemeManager.Get(style.color))
	icon.Parent = iconHolder

	local textCol = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, -50, 0, 0),
		Parent = row,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
		Parent = textCol,
	})

	Utility.New("TextLabel", {
		Text = config.Title or "Notification",
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = textCol,
	})

	if config.Content then
		Utility.New("TextLabel", {
			Text = config.Content,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = textCol,
		})
	end

	local closeButton = Utility.New("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(18, 18),
		Parent = row,
	})
	local closeIcon = Icons.Create("close", 12, ThemeManager.Get("TextMuted"))
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Parent = closeButton

	if duration and duration > 0 then
		local progressTrack = Utility.New("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, 6),
			BackgroundColor3 = ThemeManager.Get("BorderMuted"),
			BorderSizePixel = 0,
			Parent = card,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressTrack })
		local fill = Utility.New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = ThemeManager.Get(style.color),
			BorderSizePixel = 0,
			Parent = progressTrack,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
		AnimationManager.Tween(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })
	end

	local dismissed = false
	local function dismiss()
		if dismissed then return end
		dismissed = true
		AnimationManager.Tween(card, "Smooth", { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
		task.delay(0.22, function()
			card:Destroy()
		end)
	end

	closeButton.MouseButton1Click:Connect(dismiss)

	AnimationManager.Tween(card, "Emphasized", { Position = UDim2.new(0, 0, 0, 0) })

	if duration and duration > 0 then
		task.delay(duration, dismiss)
	end

	return { Dismiss = dismiss, Instance = card }
end

-- ============================================================
-- CommandPalette
-- ============================================================
local CommandPalette = {}
CommandPalette.__index = CommandPalette

function CommandPalette.new(screenGui)
	local self = setmetatable({}, CommandPalette)
	self._maid = Maid.new()
	self._commands = {}
	self._recentIds = {}
	self._open = false

	self.Backdrop = Utility.New("TextButton", {
		Name = "CommandPaletteBackdrop",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 900,
		Visible = false,
		Parent = screenGui,
	})

	self.Frame = Utility.New("Frame", {
		Name = "CommandPalette",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(480, 60),
		Position = UDim2.new(0.5, 0, 0.28, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		ZIndex = 901,
		ClipsDescendants = true,
		Parent = self.Backdrop,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.Frame })
	Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("BorderStrong"), Parent = self.Frame })

	local searchRow = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = self.Frame,
	})
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = searchRow,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		Parent = searchRow,
	})

	local searchIcon = Icons.Create("search", 16, ThemeManager.Get("TextMuted"))
	searchIcon.Parent = searchRow

	self.SearchBox = Utility.New("TextBox", {
		PlaceholderText = "Search commands, tabs, settings...",
		Font = ThemeManager.Get("Font"),
		TextSize = 14,
		TextColor3 = ThemeManager.Get("Text"),
		PlaceholderColor3 = ThemeManager.Get("TextDisabled"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, -26, 1, 0),
		Parent = searchRow,
	})

	Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 52),
		BackgroundColor3 = ThemeManager.Get("Border"),
		BorderSizePixel = 0,
		Parent = self.Frame,
	})

	self.List = Utility.New("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 60),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = ThemeManager.Get("BorderStrong"),
		Parent = self.Frame,
	})
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		Parent = self.List,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
		Parent = self.List,
	})

	self._maid:Give(self.Backdrop.MouseButton1Click:Connect(function()
		self:Close()
	end))

	self._maid:Give(self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_render()
	end))

	self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if not self._open then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:Close()
		elseif input.KeyCode == Enum.KeyCode.Down then
			self:_moveSelection(1)
		elseif input.KeyCode == Enum.KeyCode.Up then
			self:_moveSelection(-1)
		elseif input.KeyCode == Enum.KeyCode.Return then
			self:_activateSelected()
		end
	end))

	return self
end

function CommandPalette:RegisterCommand(command)
	table.insert(self._commands, command)
end

function CommandPalette:UnregisterById(id)
	for i, c in ipairs(self._commands) do
		if c.Id == id then
			table.remove(self._commands, i)
			return
		end
	end
end

function CommandPalette:_render()
	for _, child in ipairs(self.List:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local query = self.SearchBox.Text
	local matches = {}

	for _, command in ipairs(self._commands) do
		if query == "" then
			table.insert(matches, { command = command, score = table.find(self._recentIds, command.Id) and 500 or 0 })
		else
			local ok, score = Utility.FuzzyMatch(command.Title, query)
			if ok then
				table.insert(matches, { command = command, score = score })
			end
		end
	end

	table.sort(matches, function(a, b) return a.score > b.score end)

	self._rows = {}
	self._selectedIndex = 1

	if #matches == 0 then
		Utility.New("TextLabel", {
			Text = "No results found",
			Font = ThemeManager.Get("Font"),
			TextSize = 13,
			TextColor3 = ThemeManager.Get("TextMuted"),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			Parent = self.List,
		})
	end

	for index, match in ipairs(matches) do
		local command = match.command
		local row = Utility.New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = ThemeManager.Get("SurfaceHover"),
			BackgroundTransparency = index == 1 and 0 or 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 38),
			Parent = self.List,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = row })
		Utility.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = row })
		Utility.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			Parent = row,
		})

		if command.Icon then
			local icon = Icons.Create(command.Icon, 16, ThemeManager.Get("TextMuted"))
			icon.Parent = row
		end

		Utility.New("TextLabel", {
			Text = command.Title,
			Font = ThemeManager.Get("Font"),
			TextSize = 13,
			TextColor3 = ThemeManager.Get("Text"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -80, 1, 0),
			Parent = row,
		})

		if command.Keybind then
			Utility.New("TextLabel", {
				Text = command.Keybind,
				Font = ThemeManager.Get("Font"),
				TextSize = 11,
				TextColor3 = ThemeManager.Get("TextDisabled"),
				TextXAlignment = Enum.TextXAlignment.Right,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 60, 1, 0),
				Parent = row,
			})
		end

		row.MouseEnter:Connect(function()
			self._selectedIndex = index
			self:_highlight()
		end)

		row.MouseButton1Click:Connect(function()
			self._selectedIndex = index
			self:_activateSelected()
		end)

		table.insert(self._rows, { row = row, command = command })
	end

	self:_highlight()

	local targetHeight = math.min(360, 8 + #matches * 40)
	AnimationManager.Tween(self.List, "Fast", { Size = UDim2.new(1, 0, 0, targetHeight) })
	AnimationManager.Tween(self.Frame, "Fast", { Size = UDim2.fromOffset(480, 68 + targetHeight) })
end

function CommandPalette:_highlight()
	for i, entry in ipairs(self._rows or {}) do
		entry.row.BackgroundTransparency = (i == self._selectedIndex) and 0 or 1
	end
end

function CommandPalette:_moveSelection(delta)
	if not self._rows or #self._rows == 0 then return end
	self._selectedIndex = ((self._selectedIndex - 1 + delta) % #self._rows) + 1
	self:_highlight()
	local entry = self._rows[self._selectedIndex]
	if entry then
		self.List.CanvasPosition = Vector2.new(0, math.max(0, entry.row.AbsolutePosition.Y - self.List.AbsolutePosition.Y + self.List.CanvasPosition.Y - 100))
	end
end

function CommandPalette:_activateSelected()
	local entry = self._rows and self._rows[self._selectedIndex]
	if not entry then return end
	table.insert(self._recentIds, 1, entry.command.Id)
	for i = #self._recentIds, 6, -1 do
		table.remove(self._recentIds)
	end
	self:Close()
	task.spawn(entry.command.Action)
end

function CommandPalette:Open()
	if self._open then return end
	self._open = true
	self.Backdrop.Visible = true
	self.SearchBox.Text = ""
	self:_render()
	AnimationManager.Tween(self.Backdrop, "Fast", { BackgroundTransparency = 0.5 })
	self.Frame.Size = UDim2.fromOffset(480, 60)
	self.Frame.Position = UDim2.new(0.5, 0, 0.32, 0)
	AnimationManager.Tween(self.Frame, "Emphasized", { Position = UDim2.new(0.5, 0, 0.28, 0) })
	task.defer(function()
		self.SearchBox:CaptureFocus()
	end)
end

function CommandPalette:Close()
	if not self._open then return end
	self._open = false
	AnimationManager.Tween(self.Backdrop, "Fast", { BackgroundTransparency = 1 }, function()
		self.Backdrop.Visible = false
	end)
	self.SearchBox:ReleaseFocus()
end

function CommandPalette:Toggle()
	if self._open then
		self:Close()
	else
		self:Open()
	end
end

function CommandPalette:Destroy()
	self._maid:Destroy()
	self.Backdrop:Destroy()
end

-- ============================================================
-- Tab
-- ============================================================
local Tab = {}
Tab.__index = Tab

local function injectDefaults(config, window)
	config = config or {}
	if config.ConfigManager == nil then
		config.ConfigManager = window.ConfigManager
	end
	if config.Overlay == nil then
		config.Overlay = window.Overlay
	end
	return config
end

local function attachComponentFactory(target, containerGetter, window)
	function target:Button(config)
		return ButtonComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Toggle(config)
		return ToggleComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Slider(config)
		return SliderComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Dropdown(config)
		return DropdownComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Input(config)
		return InputComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Keybind(config)
		return KeybindComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:ColorPicker(config)
		return ColorPickerComponent.new(containerGetter(), injectDefaults(config, window))
	end
	function target:Paragraph(config)
		return ParagraphComponent.new(containerGetter(), injectDefaults(config, window))
	end
end

function Tab.new(window, config)
	config = config or {}
	local self = setmetatable({}, Tab)
	self._maid = Maid.new()
	self.Window = window
	self.Title = config.Title or "Tab"
	self.Id = config.Id or self.Title

	self.NavButton = Utility.New("TextButton", {
		Name = "Nav_" .. self.Title,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = ThemeManager.Get("SurfaceHover"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34),
		Parent = window.SidebarList,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 7), Parent = self.NavButton })

	self.ActiveIndicator = Utility.New("Frame", {
		Size = UDim2.new(0, 3, 0, 16),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = ThemeManager.Get("Accent"),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = self.NavButton,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.ActiveIndicator })
	self._maid:Give(ThemeManager.Register(self.ActiveIndicator, "BackgroundColor3", "Accent"))

	self.BadgeLabel = Utility.New("TextLabel", {
		Text = "",
		Font = ThemeManager.Get("FontBold"),
		TextSize = 10,
		TextColor3 = ThemeManager.Get("TextInverse"),
		BackgroundColor3 = ThemeManager.Get("Accent"),
		Visible = false,
		Size = UDim2.fromOffset(18, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		ZIndex = 2,
		Parent = self.NavButton,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = self.BadgeLabel })
	self._maid:Give(ThemeManager.Register(self.BadgeLabel, "BackgroundColor3", "Accent"))
	self._maid:Give(ThemeManager.Register(self.BadgeLabel, "TextColor3", "TextInverse"))

	self._content = Utility.New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -14 - 34, 1, 0),
		Parent = self.NavButton,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		Parent = self._content,
	})

	if config.Icon then
		self.IconHolder = Utility.New("Frame", {
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Parent = self._content,
		})
		local icon = Icons.Create(config.Icon, 16, ThemeManager.Get("TextMuted"))
		icon.Parent = self.IconHolder
		self._icon = icon
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", "TextMuted"))
	end

	self.Label = Utility.New("TextLabel", {
		Text = self.Title,
		Font = ThemeManager.Get("FontMedium"),
		TextSize = 13,
		TextColor3 = ThemeManager.Get("TextMuted"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, config.Icon and -26 or 0, 1, 0),
		Parent = self._content,
	})
	self._maid:Give(ThemeManager.Register(self.Label, "TextColor3", "TextMuted"))

	self.Page = Utility.New("ScrollingFrame", {
		Name = "Page_" .. self.Title,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = ThemeManager.Get("BorderStrong"),
		ScrollBarImageTransparency = 0.3,
		Visible = false,
		Parent = window.ContentArea,
	})
	self._maid:Give(ThemeManager.Register(self.Page, "ScrollBarImageColor3", "BorderStrong"))
	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 24),
		Parent = self.Page,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 10),
		Parent = self.Page,
	})

	self._maid:Give(self.NavButton.MouseButton1Click:Connect(function()
		window:SelectTab(self)
	end))
	self._maid:Give(self.NavButton.MouseEnter:Connect(function()
		if window.ActiveTab ~= self then
			AnimationManager.Tween(self.NavButton, "Fast", { BackgroundTransparency = 0.5 })
		end
	end))
	self._maid:Give(self.NavButton.MouseLeave:Connect(function()
		if window.ActiveTab ~= self then
			AnimationManager.Tween(self.NavButton, "Fast", { BackgroundTransparency = 1 })
		end
	end))

	attachComponentFactory(self, function() return self.Page end, window)

	function self:CreateSection(sectionConfig)
		local section = SectionComponent.new(self.Page, sectionConfig)
		attachComponentFactory(section, function() return section.Container end, window)
		return section
	end

	function self:SetBadge(count)
		if count and count > 0 then
			self.BadgeLabel.Visible = true and not window.Collapsed
			self.BadgeLabel.Text = count > 99 and "99+" or tostring(count)
		else
			self.BadgeLabel.Visible = false
		end
	end

	return self
end

function Tab:SetActive(active)
	if active then
		self.Page.Visible = true
		AnimationManager.Tween(self.NavButton, "Fast", { BackgroundTransparency = 0 })
		AnimationManager.Tween(self.ActiveIndicator, "Fast", { BackgroundTransparency = 0 })
		AnimationManager.Tween(self.Label, "Fast", { TextColor3 = ThemeManager.Get("Text") })
		if self._icon then
			AnimationManager.Tween(self._icon, "Fast", { ImageColor3 = ThemeManager.Get("Text") })
		end
	else
		AnimationManager.Tween(self.NavButton, "Fast", { BackgroundTransparency = 1 })
		AnimationManager.Tween(self.ActiveIndicator, "Fast", { BackgroundTransparency = 1 })
		AnimationManager.Tween(self.Label, "Fast", { TextColor3 = ThemeManager.Get("TextMuted") })
		if self._icon then
			AnimationManager.Tween(self._icon, "Fast", { ImageColor3 = ThemeManager.Get("TextMuted") })
		end
		task.delay(0.14, function()
			if self.Window.ActiveTab ~= self then
				self.Page.Visible = false
			end
		end)
	end
end

function Tab:Destroy()
	self._maid:Destroy()
	self.NavButton:Destroy()
	self.Page:Destroy()
end

-- ============================================================
-- Window
-- ============================================================
local Window = {}
Window.__index = Window

local function getGuiParent()
	local ok, hidden = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and hidden then
		return hidden
	end
	return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

function Window.new(config)
	config = config or {}
	local self = setmetatable({}, Window)
	self._maid = Maid.new()
	self.Closed = Signal.new()
	self.Minimized = false
	self.Collapsed = false
	self.Tabs = {}
	self.ActiveTab = nil

	if config.Theme then
		ThemeManager.SetTheme(config.Theme)
	end

	self.ConfigManager = ConfigManager.new(config.ConfigFolder or config.Title or "MeridianUI")

	self.ScreenGui = Utility.New("ScreenGui", {
		Name = config.Name or "MeridianUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = getGuiParent(),
	})

	self.Overlay = Utility.New("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 400,
		Parent = self.ScreenGui,
	})

	self.Notifications = NotificationManager.new(self.ScreenGui)
	self.CommandPalette = CommandPalette.new(self.ScreenGui)

	local minSize = config.MinSize or Vector2.new(560, 360)
	local maxSize = config.MaxSize or Vector2.new(1400, 960)
	local defaultSize = config.Size or Vector2.new(760, 480)

	self._sidebarWidth = 208
	self._sidebarCollapsedWidth = 64

	self.Root = Utility.New("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(defaultSize.X, defaultSize.Y),
		Parent = self.ScreenGui,
	})

	for i, cfg in ipairs({ { 16, 0.9 }, { 8, 0.75 } }) do
		Utility.New("Frame", {
			Name = "Shadow" .. i,
			BackgroundColor3 = ThemeManager.Get("Shadow"),
			BackgroundTransparency = cfg[2],
			BorderSizePixel = 0,
			Size = UDim2.new(1, cfg[1], 1, cfg[1]),
			Position = UDim2.new(0.5, 0, 0.5, cfg[1] * 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 0,
			Parent = self.Root,
		})
	end

	self.Frame = Utility.New("Frame", {
		Name = "Window",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = self.Root,
	})
	Utility.New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.Frame })
	local outerStroke = Utility.New("UIStroke", { Thickness = 1, Color = ThemeManager.Get("Border"), Parent = self.Frame })
	self._maid:Give(ThemeManager.Register(self.Frame, "BackgroundColor3", "Elevated"))
	self._maid:Give(ThemeManager.Register(outerStroke, "Color", "Border"))

	if config.Center ~= false then
		local viewport = workspace.CurrentCamera.ViewportSize
		self.Root.Position = UDim2.fromOffset((viewport.X - defaultSize.X) / 2, (viewport.Y - defaultSize.Y) / 2)
	elseif config.Position then
		self.Root.Position = config.Position
	end

	self:_buildTitleBar(config)
	self:_buildBody(config)
	self:_buildResizeHandle(minSize, maxSize)

	self._maid:Give(RunService.RenderStepped:Connect(function()
		if self.Root.Parent then
			local pos = self.Root.AbsolutePosition
			local size = self.Root.AbsoluteSize
			local safe = Utility.SafePosition(pos, size)
			if (safe - pos).Magnitude > 400 then
				self.Root.Position = UDim2.fromOffset(safe.X, safe.Y)
			end
		end
	end))

	self:_setupCommandPalette(config)

	if config.Settings ~= false then
		self:_buildSettingsTab()
	end

	return self
end

function Window:_buildTitleBar(config)
	self.TitleBar = Utility.New("Frame", {
		Name = "TitleBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 3,
		Parent = self.Frame,
	})

	local divider = Utility.New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = ThemeManager.Get("Border"),
		BorderSizePixel = 0,
		Parent = self.TitleBar,
	})
	self._maid:Give(ThemeManager.Register(divider, "BackgroundColor3", "Border"))

	Utility.New("UIPadding", {
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 10),
		Parent = self.TitleBar,
	})

	local leftGroup = Utility.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -110, 1, 0),
		Parent = self.TitleBar,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		Parent = leftGroup,
	})

	if config.Icon then
		local iconHolder = Utility.New("Frame", {
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Parent = leftGroup,
		})
		local icon = Icons.Create(config.Icon, 18, ThemeManager.Get("Accent"))
		icon.Parent = iconHolder
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", "Accent"))
	end

	local textGroup = Utility.New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = leftGroup,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = textGroup,
	})

	local titleLabel = Utility.New("TextLabel", {
		Text = config.Title or "MeridianUI",
		Font = ThemeManager.Get("FontBold"),
		TextSize = 14,
		TextColor3 = ThemeManager.Get("Text"),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = textGroup,
	})
	self._maid:Give(ThemeManager.Register(titleLabel, "TextColor3", "Text"))

	if config.Subtitle then
		local subtitleLabel = Utility.New("TextLabel", {
			Text = config.Subtitle,
			Font = ThemeManager.Get("Font"),
			TextSize = 12,
			TextColor3 = ThemeManager.Get("TextMuted"),
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Parent = textGroup,
		})
		self._maid:Give(ThemeManager.Register(subtitleLabel, "TextColor3", "TextMuted"))
	end

	local controls = Utility.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(96, 28),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = self.TitleBar,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = controls,
	})

	local function makeControlButton(iconName, hoverColorKey)
		local button = Utility.New("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = ThemeManager.Get("SurfaceHover"),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(28, 28),
			Parent = controls,
		})
		Utility.New("UICorner", { CornerRadius = UDim.new(0, 7), Parent = button })
		local icon = Icons.Create(iconName, 13, ThemeManager.Get("TextMuted"))
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = button
		self._maid:Give(ThemeManager.Register(icon, "ImageColor3", "TextMuted"))

		self._maid:Give(button.MouseEnter:Connect(function()
			AnimationManager.Tween(button, "Fast", { BackgroundTransparency = 0 })
			if hoverColorKey then
				AnimationManager.Tween(icon, "Fast", { ImageColor3 = ThemeManager.Get(hoverColorKey) })
			end
		end))
		self._maid:Give(button.MouseLeave:Connect(function()
			AnimationManager.Tween(button, "Fast", { BackgroundTransparency = 1 })
			AnimationManager.Tween(icon, "Fast", { ImageColor3 = ThemeManager.Get("TextMuted") })
		end))

		return button
	end

	self.MinimizeButton = makeControlButton("minimize")
	self.CollapseButton = makeControlButton("collapse")
	self.CloseButton = makeControlButton("close", "Danger")

	self._maid:Give(self.MinimizeButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end))
	self._maid:Give(self.CollapseButton.MouseButton1Click:Connect(function()
		self:ToggleSidebar()
	end))
	self._maid:Give(self.CloseButton.MouseButton1Click:Connect(function()
		self:Close()
	end))

	self._maid:Give(Utility.MakeDraggable(self.TitleBar, self.Root))
end

function Window:_buildBody(config)
	self.Body = Utility.New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		Parent = self.Frame,
	})

	self.Sidebar = Utility.New("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = ThemeManager.Get("Elevated"),
		BorderSizePixel = 0,
		Size = UDim2.new(0, self._sidebarWidth, 1, 0),
		Parent = self.Body,
	})
	self._maid:Give(ThemeManager.Register(self.Sidebar, "BackgroundColor3", "Elevated"))

	local sidebarDivider = Utility.New("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = ThemeManager.Get("Border"),
		BorderSizePixel = 0,
		Parent = self.Sidebar,
	})
	self._maid:Give(ThemeManager.Register(sidebarDivider, "BackgroundColor3", "Border"))

	Utility.New("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = self.Sidebar,
	})

	self.SidebarList = Utility.New("Frame", {
		Name = "NavList",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = self.Sidebar,
	})
	Utility.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 3),
		Parent = self.SidebarList,
	})

	self.ContentArea = Utility.New("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, self._sidebarWidth, 0, 0),
		Size = UDim2.new(1, -self._sidebarWidth, 1, 0),
		Parent = self.Body,
	})
end

function Window:_buildResizeHandle(minSize, maxSize)
	local handle = Utility.New("Frame", {
		Name = "ResizeHandle",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -18, 1, -18),
		ZIndex = 5,
		Parent = self.Frame,
	})
	for i = 1, 3 do
		Utility.New("Frame", {
			Size = UDim2.fromOffset(3, 3),
			Position = UDim2.new(1, -6 - (i - 1) * 6, 1, -6),
			BackgroundColor3 = ThemeManager.Get("TextDisabled"),
			BorderSizePixel = 0,
			Rotation = 45,
			Parent = handle,
		})
	end
	self._maid:Give(Utility.MakeResizable(handle, self.Root, minSize, maxSize, function()
		self.ContentArea.Size = UDim2.new(1, -self._sidebarWidth, 1, 0)
	end))
end

function Window:_setupCommandPalette(config)
	if config.CommandPalette == false then
		return
	end
	local toggleKey = config.CommandPaletteKeybind or Enum.KeyCode.K
	self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		local ctrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if ctrlHeld and input.KeyCode == toggleKey then
			self.CommandPalette:Toggle()
		end
	end))

	self.CommandPalette:RegisterCommand({
		Id = "toggle-ui",
		Title = "Toggle UI Visibility",
		Icon = "eye",
		Action = function() self:ToggleVisible() end,
	})
	self.CommandPalette:RegisterCommand({
		Id = "close-window",
		Title = "Close Window",
		Icon = "close",
		Action = function() self:Close() end,
	})
	self.CommandPalette:RegisterCommand({
		Id = "minimize-window",
		Title = "Minimize Window",
		Icon = "minimize",
		Action = function() self:ToggleMinimize() end,
	})
	self.CommandPalette:RegisterCommand({
		Id = "reload-config",
		Title = "Reload Configuration",
		Icon = "settings",
		Action = function()
			ThemeManager.SetTheme(ThemeManager.Current)
			self:Notify({ Title = "Configuration Reloaded", Content = "Theme and settings refreshed.", Type = "Info", Duration = 3 })
		end,
	})

	if config.ToggleKeybind then
		self._maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == config.ToggleKeybind then
				self:ToggleVisible()
			end
		end))
	end
end

function Window:CreateTab(config)
	local tab = Tab.new(self, config)
	table.insert(self.Tabs, tab)

	self.CommandPalette:RegisterCommand({
		Id = "open-tab-" .. tab.Id,
		Title = "Open " .. tab.Title,
		Icon = config.Icon,
		Action = function() self:SelectTab(tab) end,
	})

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	if self.ActiveTab == tab then return end
	if self.ActiveTab then
		self.ActiveTab:SetActive(false)
	end
	self.ActiveTab = tab
	tab:SetActive(true)
end

function Window:ToggleMinimize()
	self.Minimized = not self.Minimized
	if self.Minimized then
		self._preMinimizeSize = self.Root.Size
		AnimationManager.Tween(self.Root, "Emphasized", { Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, 44) })
	else
		AnimationManager.Tween(self.Root, "Emphasized", { Size = self._preMinimizeSize })
	end
end

function Window:ToggleSidebar()
	self.Collapsed = not self.Collapsed
	local targetWidth = self.Collapsed and self._sidebarCollapsedWidth or self._sidebarWidth
	AnimationManager.Tween(self.Sidebar, "Smooth", { Size = UDim2.new(0, targetWidth, 1, 0) })
	AnimationManager.Tween(self.ContentArea, "Smooth", { Position = UDim2.new(0, targetWidth, 0, 0), Size = UDim2.new(1, -targetWidth, 1, 0) })
	for _, tab in ipairs(self.Tabs) do
		tab.Label.Visible = not self.Collapsed
		if tab.BadgeLabel.Text ~= "" then
			tab.BadgeLabel.Visible = not self.Collapsed
		end
	end
end

function Window:ToggleVisible()
	self.Root.Visible = not self.Root.Visible
end

function Window:Show()
	self.Root.Visible = true
end

function Window:Hide()
	self.Root.Visible = false
end

function Window:Close()
	self.Closed:Fire()
	self:Hide()
end

function Window:Notify(config)
	return self.Notifications:Notify(config)
end

function Window:SetTheme(theme)
	ThemeManager.SetTheme(theme)
end

function Window:SaveConfig(name)
	return self.ConfigManager:Save(name)
end

function Window:LoadConfig(name)
	return self.ConfigManager:Load(name)
end

function Window:_buildSettingsTab()
	local settingsTab = self:CreateTab({ Title = "Settings", Icon = "settings", Id = "__settings" })

	local appearance = settingsTab:CreateSection({ Title = "Appearance" })
	local themeNames = ThemeManager.ListThemes()
	local themeOptions = {}
	for _, name in ipairs(themeNames) do
		table.insert(themeOptions, { Text = name, Value = name })
	end

	appearance:Dropdown({
		Title = "Theme",
		Options = themeOptions,
		Default = ThemeManager.Current.Name,
		Callback = function(value)
			ThemeManager.SetTheme(value)
		end,
	})

	appearance:ColorPicker({
		Title = "Accent Color",
		Default = ThemeManager.Get("Accent"),
		Callback = function(color)
			local merged = {}
			for k, v in pairs(ThemeManager.Current) do
				merged[k] = v
			end
			merged.Accent = color
			merged.AccentHover = color:Lerp(Color3.new(1, 1, 1), 0.15)
			ThemeManager.SetTheme(merged)
		end,
	})

	local behavior = settingsTab:CreateSection({ Title = "Behavior" })

	behavior:Slider({
		Title = "UI Scale",
		Min = 80,
		Max = 130,
		Default = 100,
		Increment = 5,
		Percentage = true,
		Callback = function(value)
			if not self._uiScale then
				self._uiScale = Utility.New("UIScale", { Parent = self.Frame })
			end
			self._uiScale.Scale = value / 100
		end,
	})

	behavior:Slider({
		Title = "Animation Speed",
		Min = 50,
		Max = 200,
		Default = 100,
		Increment = 10,
		Percentage = true,
		Callback = function(value)
			AnimationManager.SetSpeed(value / 100)
		end,
	})

	behavior:Toggle({
		Title = "Reduced Motion",
		Description = "Disable non-essential animations",
		Default = false,
		Callback = function(value)
			AnimationManager.SetReducedMotion(value)
		end,
	})

	behavior:Toggle({
		Title = "Collapse Sidebar",
		Default = false,
		Callback = function()
			self:ToggleSidebar()
		end,
	})

	local configSection = settingsTab:CreateSection({ Title = "Configuration" })
	local configNameValue = "default"

	configSection:Input({
		Title = "Configuration Name",
		Placeholder = "default",
		Default = configNameValue,
		Callback = function(text)
			configNameValue = text ~= "" and text or "default"
		end,
	})

	configSection:Button({
		Title = "Save Configuration",
		Description = "Store current settings to disk",
		Icon = "check",
		Variant = "Secondary",
		Callback = function()
			local ok, result = self:SaveConfig(configNameValue)
			self:Notify({
				Title = ok and "Configuration Saved" or "Save Failed",
				Content = ok and ("Saved as \"" .. configNameValue .. "\"") or tostring(result),
				Type = ok and "Success" or "Error",
				Duration = 3,
			})
		end,
	})

	configSection:Button({
		Title = "Load Configuration",
		Description = "Restore settings from disk",
		Icon = "folder",
		Variant = "Secondary",
		Callback = function()
			local ok, result = self:LoadConfig(configNameValue)
			self:Notify({
				Title = ok and "Configuration Loaded" or "Load Failed",
				Content = ok and ("Loaded \"" .. configNameValue .. "\"") or tostring(result),
				Type = ok and "Success" or "Error",
				Duration = 3,
			})
		end,
	})
end

function Window:Destroy()
	self._maid:Destroy()
	for _, tab in ipairs(self.Tabs) do
		tab:Destroy()
	end
	self.CommandPalette:Destroy()
	self.ScreenGui:Destroy()
end

-- ============================================================
-- Public API
-- ============================================================
local MeridianUI = {}
MeridianUI.Version = "1.0.0"
MeridianUI.Icons = Icons

function MeridianUI.CreateWindow(config)
	return Window.new(config)
end

function MeridianUI.SetTheme(theme)
	ThemeManager.SetTheme(theme)
end

function MeridianUI.RegisterCustomTheme(name, theme)
	return ThemeManager.RegisterCustomTheme(name, theme)
end

function MeridianUI.ListThemes()
	return ThemeManager.ListThemes()
end

function MeridianUI.SetReducedMotion(state)
	AnimationManager.SetReducedMotion(state)
end

function MeridianUI.SetAnimationSpeed(multiplier)
	AnimationManager.SetSpeed(multiplier)
end

function MeridianUI.RegisterIcon(name, assetId, imageRectOffset, imageRectSize)
	Icons.Register(name, assetId, imageRectOffset, imageRectSize)
end

return MeridianUI
