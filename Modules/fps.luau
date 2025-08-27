-- Modules/fps.luau — FPS GUI (arrastável + redimensionável proporcional + FPS atual/min/max)

local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local M = {}
M.__index = M

-- Estilo/base
local BASE_SIZE = Vector2.new(180, 84)     -- tamanho base antes da escala
local HEADER_H  = 20
local MIN_SCALE, MAX_SCALE = 0.6, 3.0
local RESIZE_MARGIN = 10

local C_PANEL = Color3.fromRGB(35,35,35)
local C_TEXT  = Color3.fromRGB(235,235,235)
local C_MUTED = Color3.fromRGB(160,160,160)

local function make(class, props, kids)
	local o = Instance.new(class)
	for k,v in pairs(props or {}) do o[k]=v end
	for _,c in ipairs(kids or {}) do c.Parent=o end
	return o
end

-- Drag sem salto
local function attachDrag(frame: Frame, handle: GuiObject)
	handle.Active = true
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input: InputObject)
		local delta = input.Position - dragStart
		frame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging=false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end)
end

-- API
function M.create(parent: Instance, opts: table?)
	opts = opts or {}
	local startPos   = opts.position or UDim2.fromOffset(520, 240)
	local startScale = tonumber(opts.scale) or 1

	local win = make("Frame",{
		Size=UDim2.fromOffset(BASE_SIZE.X, BASE_SIZE.Y),
		Position=startPos, BackgroundColor3=C_PANEL, BorderSizePixel=0, Active=true
	})
	win.Parent = parent

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = startScale
	uiScale.Parent = win

	local header = make("Frame",{Size=UDim2.new(1,0,0,HEADER_H), BackgroundColor3=Color3.fromRGB(50,50,50), Active=true})
	header.Parent = win
	make("TextLabel",{
		Text="FPS", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C_TEXT,
		BackgroundTransparency=1, Size=UDim2.fromScale(1,1)
	}).Parent = header

	local lblNow = make("TextLabel",{
		BackgroundTransparency=1, Text="FPS: 0", Font=Enum.Font.GothamBold,
		TextSize=16, TextColor3=C_TEXT, TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.new(1,-10,0,26), Position=UDim2.fromOffset(6,HEADER_H+2)
	})
	lblNow.Parent = win

	local lblMinMax = make("TextLabel",{
		BackgroundTransparency=1, Text="Min: 0 | Max: 0", Font=Enum.Font.Gotham,
		TextSize=14, TextColor3=C_MUTED, TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.new(1,-10,0,22), Position=UDim2.fromOffset(6,HEADER_H+28)
	})
	lblMinMax.Parent = win

	attachDrag(win, header)

	-- Redimensionar proporcional (canto inferior-direito)
	local resizing = false
	local startMouse = Vector2.zero
	local startAbs   = Vector2.zero

	win.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = Vector2.new(input.Position.X, input.Position.Y)
			local ap, as = win.AbsolutePosition, win.AbsoluteSize
			local corner = (mp.X >= ap.X + as.X - RESIZE_MARGIN) and (mp.Y >= ap.Y + as.Y - RESIZE_MARGIN)
			if corner and mp.Y > ap.Y + HEADER_H then
				resizing   = true
				startMouse = mp
				startAbs   = as
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then resizing = false end
				end)
			end
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mp = Vector2.new(input.Position.X, input.Position.Y)
			local dx, dy = mp.X - startMouse.X, mp.Y - startMouse.Y
			local desiredW = startAbs.X + dx
			local desiredH = startAbs.Y + dy
			local scaleW   = desiredW / BASE_SIZE.X
			local scaleH   = desiredH / BASE_SIZE.Y
			uiScale.Scale  = math.clamp(math.max(scaleW, scaleH), MIN_SCALE, MAX_SCALE)
		end
	end)

	-- FPS loop
	local minF, maxF = math.huge, 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		local fps = math.max(0, math.floor(1/dt + 0.5))
		minF = math.min(minF, fps)
		maxF = math.max(maxF, fps)
		lblNow.Text    = "FPS: " .. fps
		lblMinMax.Text = ("Min: %d | Max: %d"):format(minF == math.huge and 0 or minF, maxF)
	end)

	-- objeto retornado
	local self = setmetatable({
		window = win,
		uiScale = uiScale,
		_conn = conn,
	}, M)

	function self:Destroy()
		if self._conn then pcall(function() self._conn:Disconnect() end) end
		if self.window then self.window:Destroy() end
	end
	function self:Show()  self.window.Visible = true  end
	function self:Hide()  self.window.Visible = false end
	function self:Toggle() self.window.Visible = not self.window.Visible end

	return self
end

return M