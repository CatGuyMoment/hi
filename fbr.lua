
local UIS = game:GetService("UserInputService")
local RUNSERVICE = game:GetService("RunService")



-- CONSTANTS

-- Private Functions

local function getAbsDist(a, b)
	local d = b - a
	if (type(d) == "number") then
		return math.abs(d)
	end
	return d.Magnitude
end

-- Class

local SpringClass = {}
SpringClass.__index = SpringClass
SpringClass.__type = "Spring"

function SpringClass:__tostring()
	return SpringClass.__type
end

-- Public Constructors

function SpringClass.new(stiffness, dampingCoeff, dampingRatio, initialPos)
	local self = setmetatable({}, SpringClass)

	self.instant = false
	self.marginOfError = 1E-6

	dampingRatio = dampingRatio or 1
	local m = dampingCoeff*dampingCoeff/(4*stiffness*dampingRatio*dampingRatio)
	self.k = stiffness/m
	self.d = -dampingCoeff/m
	self.x = initialPos
	self.t = initialPos
	self.v = initialPos*0

	return self
end

-- Public Methods

function SpringClass:Update(dt)
	if (not self.instant) then
		local t, k, d, x0, v0 = self.t, self.k, self.d, self.x, self.v
		local a0 = k*(t - x0) + v0*d
		local v1 = v0 + a0*(dt/2)
		local a1 = k*(t - (x0 + v0*(dt/2))) + v1*d
		local v2 = v0 + a1*(dt/2)
		local a2 = k*(t - (x0 + v1*(dt/2))) + v2*d
		local v3 = v0 + a2*dt
		local x4 = x0 + (v0 + 2*(v1 + v2) + v3)*(dt/6)
		self.x, self.v = x4, v0 + (a0 + 2*(a1 + a2) + k*(t - (x0 + v2*dt)) + v3*d)*(dt/6)

		if (getAbsDist(x4, self.t) > self.marginOfError) then
			return x4
		end
	end

	self.x, self.v = self.t, self.v*0
	return self.x
end

--








-- CONSTANTS

local FORMAT_STR = "Maid does not support type \"%s\""

local DESTRUCTORS = {
	["function"] = function(item)
		item()
	end;
	["RBXScriptConnection"] = function(item)
		item:Disconnect()
	end;
	["Instance"] = function(item)
		item:Destroy()
	end;
}

-- Class

local MaidClass = {}
MaidClass.__index = MaidClass
MaidClass.__type = "Maid"

function MaidClass:__tostring()
	return MaidClass.__type
end

-- Public Constructors

function MaidClass.new()
	local self = setmetatable({}, MaidClass)

	self.Trash = {}

	return self
end

-- Public Methods

function MaidClass:Mark(item)
	local tof = typeof(item)

	if (DESTRUCTORS[tof]) then
		self.Trash[item] = tof
	else
		error(FORMAT_STR:format(tof), 2)
	end
end

function MaidClass:Unmark(item)
	if (item) then
		self.Trash[item] = nil
	else
		self.Trash = {}
	end
end

function MaidClass:Sweep()
	for item, tof in next, self.Trash do
		DESTRUCTORS[tof](item)
	end
	self.Trash = {}
end

--
















local XBOX_STEP = 0.01
local DEBOUNCE_TICK = 0.1
local XBOX_DEADZONE = 0.35
local THUMBSTICK = Enum.KeyCode.Thumbstick2


local DEADZONE2 = 0.15^2
local FLIP_THUMB = Vector3.new(1, -1, 1)

local VALID_PRESS = {
	[Enum.UserInputType.MouseButton1] = true;
	[Enum.UserInputType.Touch] = true;
}

local VALID_MOVEMENT = {
	[Enum.UserInputType.MouseMovement] = true;
	[Enum.UserInputType.Touch] = true;
}

-- Class

local DraggerClass = {}
DraggerClass.__index = DraggerClass
DraggerClass.__type = "Dragger"

function DraggerClass:__tostring()
	return DraggerClass.__type
end

-- Public Constructors

function DraggerClass.new(element)
	local self = setmetatable({}, DraggerClass)

	self._Maid = MaidClass.new()
	self._DragBind = Instance.new("BindableEvent")
	self._StartBind = Instance.new("BindableEvent")
	self._StopBind = Instance.new("BindableEvent")

	self.Element = element
	self.IsDragging = false
	self.DragChanged = self._DragBind.Event
	self.DragStart = self._StartBind.Event
	self.DragStop = self._StopBind.Event

	init(self)

	return self
end

-- Private Methods

function init(self)
	local element = self.Element
	local maid = self._Maid
	local dragBind = self._DragBind
	local lastMousePosition = Vector3.new()

	maid:Mark(self._DragBind)
	maid:Mark(self._StartBind)
	maid:Mark(self._StopBind)

	maid:Mark(element.InputBegan:Connect(function(input)
		if (VALID_PRESS[input.UserInputType]) then
			lastMousePosition = input.Position
			self.IsDragging = true
			self._StartBind:Fire()
		end
	end))

	maid:Mark(UIS.InputEnded:Connect(function(input)
		if (VALID_PRESS[input.UserInputType]) then
			self.IsDragging = false
			self._StopBind:Fire()
		end
	end))

	maid:Mark(UIS.InputChanged:Connect(function(input, process)
		if (self.IsDragging) then
			if (VALID_MOVEMENT[input.UserInputType]) then
				local delta = input.Position - lastMousePosition
				lastMousePosition = input.Position
				dragBind:Fire(element, input, delta)
			end
		end
	end))
end

-- Public Methods

function DraggerClass:Destroy()
	self._Maid:Sweep()
	self.DragChanged = nil
	self.DragStart = nil
	self.DragStop = nil
	self.Element = nil
end

--
















SliderClass = {}
function SliderClass.new(sliderFrame, axis)
	local self = setmetatable({}, SliderClass)

	self._Maid = MaidClass.new()
	self._Spring = SpringClass.new(1, 0.1, 1, 0)
	self._Axis = axis or "x"
	self._ChangedBind = Instance.new("BindableEvent")
	self._ClickedBind = Instance.new("BindableEvent")

	self.Interval = 0
	self.IsActive = true
	self.TweenClick = true
	self.Inverted = false

	self.Frame = sliderFrame
	self.Changed = self._ChangedBind.Event
	self.Clicked = self._ClickedBind.Event
	self.DragStart = nil
	self.DragStop = nil

	dinit(self)
	self:Set(0.5)

	return self
end


-- Private Methods
function SliderClass:Get(selfe)
	local self = selfe
	local t = self._Spring.x
	if (self.Inverted) then t = 1 - t end
	return t
end
function dinit(self)
	print(self)
	function self:Get()
		return SliderClass:Get(self)
	end
	function self:Set(a,b)
		return SliderClass:Set(a,b,self)
	end
	local frame = self.Frame
	local dragger = frame.Dragger
	local background = frame.Background

	local axis = self._Axis
	local maid = self._Maid
	local spring = self._Spring
	local dragTracker = DraggerClass.new(dragger)

	self.DragStart = dragTracker.DragStart
	self.DragStop = dragTracker.DragStop

	maid:Mark(frame)
	maid:Mark(self._ChangedBind)
	maid:Mark(self._ClickedBind)
	maid:Mark(function() dragTracker:Destroy() end)

	-- Get bounds and background size scaled accordingly for calculations
	local function setUdim2(a, b)
		if (axis == "y") then a, b = b, a end
		return UDim2.new(a, 0, b, 0)
	end

	local last = -1
	local bPos, bSize
	local function updateBounds()
		bPos, bSize = getBounds(self)
		background.Size = setUdim2(bSize / frame.AbsoluteSize[axis], 1)
		last = -1
	end

	updateBounds()
	maid:Mark(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBounds))
	maid:Mark(frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBounds))
	maid:Mark(frame:GetPropertyChangedSignal("Parent"):Connect(updateBounds))

	-- Move the slider when the xbox moves it
	local xboxDir = 0
	local xboxTick = 0
	local xboxSelected = false

	maid:Mark(dragger.SelectionGained:Connect(function()
		xboxSelected = true
	end))

	maid:Mark(dragger.SelectionLost:Connect(function()
		xboxSelected = false
	end))

	maid:Mark(UIS.InputChanged:Connect(function(input, process)
		if (process and input.KeyCode == THUMBSTICK) then
			local pos = input.Position
			xboxDir = math.abs(pos[axis]) > XBOX_DEADZONE and math.sign(pos[axis]) or 0
		end
	end))

	-- Move the slider when we drag it
	maid:Mark(dragTracker.DragChanged:Connect(function(element, input, delta)
		if (self.IsActive) then
			self:Set((input.Position[axis] - bPos) / bSize, false)
		end
	end))

	-- Move the slider when we click somewhere on the bar
	maid:Mark(frame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			local t = (input.Position[axis] - bPos) / bSize
			self._ClickedBind:Fire(math.clamp(t, 0, 1))
			if (self.IsActive) then
				self:Set(t, self.TweenClick)
			end
		end
	end))

	-- position the slider
	maid:Mark(RUNSERVICE.RenderStepped:Connect(function(dt)
		if (xboxSelected) then
			local t = tick()
			if (self.Interval <= 0) then
				self:Set(self:Get() + xboxDir*XBOX_STEP*dt*60)
			elseif (t - xboxTick > DEBOUNCE_TICK) then
				xboxTick = t
				self:Set(self:Get() + self.Interval*xboxDir)
			end
		end

		spring:Update(dt)
		local x = spring.x
		if (x ~= last) then
			local scalePos = (bPos + (x * bSize) - frame.AbsolutePosition[axis]) / frame.AbsoluteSize[axis]
			dragger.Position = setUdim2(scalePos, 0.5)
			self._ChangedBind:Fire(self:Get())
			last = x
		end
	end))
end

function getBounds(self)
	local frame = self.Frame
	local dragger = frame.Dragger
	local axis = self._Axis

	local pos = frame.AbsolutePosition[axis] + dragger.AbsoluteSize[axis]/2
	local size = frame.AbsoluteSize[axis] - dragger.AbsoluteSize[axis]

	return pos, size
end

-- Public Methods


function SliderClass:Set(value, doTween,selfe)
	local self = selfe
	local spring = self._Spring
	local newT = math.clamp(value, 0, 1)

	if (self.Interval > 0) then
		newT = math.floor((newT / self.Interval) + 0.5) * self.Interval
	end

	spring.t = newT
	spring.instant = not doTween
end

function SliderClass:Destroy()
	self._Maid:Sweep()
	self.Frame:Destroy()
	self.Changed = nil
	self.Clicked = nil
	self.StartDrag = nil
	self.StopDrag = nil
	self.Frame = nil
end

--




















local primary = Instance.new("ScreenGui")
primary.Name = "primary"
primary.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
primary.ResetOnSpawn = false

local background = Instance.new("Frame")
background.Name = "Background"
background.AnchorPoint = Vector2.new(0, 1)
background.BackgroundColor3 = Color3.fromRGB(47, 47, 48)
background.BackgroundTransparency = 0.3
background.Position = UDim2.fromScale(0, 1)
background.Size = UDim2.new(1, 0, 0, 50)
background.ZIndex = 0

local sliderFrameX = Instance.new("Frame")
sliderFrameX.Name = "SliderFrameX"
sliderFrameX.AnchorPoint = Vector2.new(0.5, 0.5)
sliderFrameX.BackgroundColor3 = Color3.fromRGB(29, 29, 30)
sliderFrameX.BackgroundTransparency = 1
sliderFrameX.BorderSizePixel = 0
sliderFrameX.Position = UDim2.fromScale(0.5, 0.5)
sliderFrameX.Size = UDim2.new(0.9, 0, 0, 20)

local background1 = Instance.new("Frame")
background1.Name = "Background"
background1.AnchorPoint = Vector2.new(0.5, 0.5)
background1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
background1.BackgroundTransparency = 1
background1.Position = UDim2.fromScale(0.5, 0.5)
background1.Size = UDim2.fromScale(1, 1)

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 0.5)
bar.BackgroundColor3 = Color3.fromRGB(17, 154, 222)
bar.BorderSizePixel = 0
bar.LayoutOrder = 1
bar.Position = UDim2.fromScale(0.5, 0.5)
bar.Size = UDim2.fromScale(1, 0.125)
bar.Parent = background1

background1.Parent = sliderFrameX

local dragger = Instance.new("ImageLabel")
dragger.Name = "Dragger"
dragger.Image = "rbxassetid://4504304159"
dragger.ImageColor3 = Color3.fromRGB(33, 95, 222)
dragger.Active = true
dragger.AnchorPoint = Vector2.new(0.5, 0.5)
dragger.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dragger.BackgroundTransparency = 1
dragger.Position = UDim2.fromScale(0.5, 0.5)
dragger.Selectable = true
dragger.Size = UDim2.fromScale(0.5, 0.5)
dragger.SizeConstraint = Enum.SizeConstraint.RelativeYY
dragger.ZIndex = 4
dragger.Parent = sliderFrameX

sliderFrameX.Parent = background

local show = Instance.new("TextLabel")
show.Name = "Show"
show.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json")
show.Text = "TARGET: MAX"
show.TextColor3 = Color3.fromRGB(255, 255, 255)
show.TextSize = 14
show.TextTruncate = Enum.TextTruncate.AtEnd
show.TextXAlignment = Enum.TextXAlignment.Left
show.AnchorPoint = Vector2.new(0.5, 1)
show.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
show.BackgroundTransparency = 1
show.ClipsDescendants = true
show.LayoutOrder = 1
show.Position = UDim2.new(0.5, 0, 0.5, -7)
show.Size = UDim2.new(0, 100, 0.2, 0)
show.Parent = background

background.Parent = primary

primary.Parent = game.CoreGui





sliderFrameX:WaitForChild("Dragger")
slider = SliderClass.new(sliderFrameX,"x")
slider:Set(0)

slider.Changed:Connect(function(new)
	game.Lighting.ExposureCompensation = new*3
	show.Text = "SET TO: "..math.round(new*3*2)/2
end)

local clock = tick()

