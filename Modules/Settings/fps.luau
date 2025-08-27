-- FPS GUI suavizado com média móvel

local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local M = {}
M.__index = M

local BASE_SIZE = Vector2.new(180, 84)
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

local function attachDrag(frame: Frame, handle: GuiObject)
	handle.Active = true
	local dragging, dragInput = false, nil
	local dragStart, startPos = Vector2.zero, UDim2.fromOffset(0,0)

	local function update(input: InputObject)
		local d = input.Position - dragStart
		local vp = workspace.CurrentCamera.ViewportSize
		local newX = math.clamp(startPos.X.Offset + d.X, 0, vp.X-frame.AbsoluteSize.X)
		local newY = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y-frame.AbsoluteSize.Y)
		frame.Position = UDim2.fromOffset(newX,newY)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging=false end end)
		end
	end)
	handle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
	UIS.InputChanged:Connect(function(input) if input==dragInput and dragging then update(input) end end)
end

function M.create(parent: Instance?, opts: table?)
	opts = opts or {}
	local sg = Instance.new("ScreenGui")
	sg.Name = "KScriptsFPS"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 60
	sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local startPos = opts.position or UDim2.fromOffset(520,240)
	local win = make("Frame",{Size=UDim2.fromOffset(BASE_SIZE.X, BASE_SIZE.Y), Position=startPos, BackgroundColor3=C_PANEL, BorderSizePixel=0, Active=true})
	win.Parent = sg

	local header = make("Frame",{Size=UDim2.new(1,0,0,HEADER_H), BackgroundColor3=Color3.fromRGB(50,50,50), Active=true})
	header.Parent = win
	make("TextLabel",{Text="FPS", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C_TEXT, BackgroundTransparency=1, Size=UDim2.fromScale(1,1)}).Parent = header

	local lblNow = make("TextLabel",{BackgroundTransparency=1, Text="FPS: 0", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C_TEXT, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,-10,0,26), Position=UDim2.fromOffset(6,HEADER_H+2)})
	lblNow.Parent = win
	local lblMinMax = make("TextLabel",{BackgroundTransparency=1, Text="Min: 0 | Max: 0", Font=Enum.Font.Gotham, TextSize=14, TextColor3=C_MUTED, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,-10,0,22), Position=UDim2.fromOffset(6,HEADER_H+28)})
	lblMinMax.Parent = win

	attachDrag(win, header)

	-- FPS suavizado
	local minF, maxF = math.huge, 0
	local buffer, bufSize = {}, 30
	local conn = RunService.RenderStepped:Connect(function(dt)
		local fps = math.max(0, math.floor(1/dt + 0.5))
		table.insert(buffer, fps)
		if #buffer > bufSize then table.remove(buffer, 1) end
		local avg = 0 for _,v in ipairs(buffer) do avg += v end avg = math.floor(avg / #buffer)

		minF = math.min(minF, fps)
		maxF = math.max(maxF, fps)
		lblNow.Text    = "FPS: " .. avg
		lblMinMax.Text = ("Min: %d | Max: %d"):format(minF==math.huge and 0 or minF, maxF)
	end)

	return setmetatable({_sg=sg, window=win, _conn=conn}, M)
end

function M:Destroy() if self._conn then self._conn:Disconnect() end if self._sg then self._sg:Destroy() end end
return M