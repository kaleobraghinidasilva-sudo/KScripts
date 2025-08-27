-- fps.luau
-- FPS GUI (arrastável + redimensionável proporcional + min/max FPS)

local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")

local FPS={}
FPS.__index=FPS

local BASE=Vector2.new(180,84)
local HEADER_H=20
local MIN_SCALE,MAX_SCALE=0.6,3.0
local RESIZE_MARGIN=10

local C_PANEL=Color3.fromRGB(35,35,35)
local C_TEXT=Color3.fromRGB(235,235,235)
local C_MUTED=Color3.fromRGB(160,160,160)

local function make(class,props,kids)
	local o=Instance.new(class)
	for k,v in pairs(props or {}) do o[k]=v end
	for _,c in ipairs(kids or {}) do c.Parent=o end
	return o
end

local function attachDrag(frame: Frame, handle: GuiObject)
	handle.Active=true
	local dragging=false
	local dragInput
	local dragStart=Vector2.zero
	local startPos=UDim2.fromOffset(0,0)

	local function update(input)
		local delta=input.Position-dragStart
		frame.Position=UDim2.fromOffset(startPos.X.Offset+delta.X,startPos.Y.Offset+delta.Y)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; dragStart=input.Position; startPos=frame.Position
			input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
	end)

	UIS.InputChanged:Connect(function(input) if input==dragInput and dragging then update(input) end end)
end

function FPS.create(parent: Instance)
	local win=make("Frame",{Size=UDim2.fromOffset(BASE.X,BASE.Y),Position=UDim2.fromOffset(500,200),
		BackgroundColor3=C_PANEL,BorderSizePixel=0,Active=true})
	win.Parent=parent

	local uiScale=Instance.new("UIScale"); uiScale.Scale=1; uiScale.Parent=win

	local header=make("Frame",{Size=UDim2.new(1,0,0,HEADER_H),BackgroundColor3=Color3.fromRGB(50,50,50),Active=true})
	header.Parent=win
	make("TextLabel",{Text="FPS",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C_TEXT,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)}).Parent=header

	local lblNow=make("TextLabel",{BackgroundTransparency=1,Text="FPS: 0",Font=Enum.Font.GothamBold,
		TextSize=16,TextColor3=C_TEXT,TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.new(1,-10,0,26),Position=UDim2.fromOffset(6,HEADER_H+2)})
	lblNow.Parent=win

	local lblMinMax=make("TextLabel",{BackgroundTransparency=1,Text="Min: 0 | Max: 0",Font=Enum.Font.Gotham,
		TextSize=14,TextColor3=C_MUTED,TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.new(1,-10,0,22),Position=UDim2.fromOffset(6,HEADER_H+28)})
	lblMinMax.Parent=win

	attachDrag(win,header)

	-- resize proporcional
	local resizing=false
	local startMouse=Vector2.zero
	local startAbs=Vector2.zero
	local startScale=uiScale.Scale

	win.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			local mp=Vector2.new(input.Position.X,input.Position.Y)
			local ap,as=win.AbsolutePosition,win.AbsoluteSize
			local inCorner=(mp.X>=ap.X+as.X-RESIZE_MARGIN) and (mp.Y>=ap.Y+as.Y-RESIZE_MARGIN)
			if inCorner and mp.Y>ap.Y+HEADER_H then
				resizing=true; startMouse=mp; startAbs=as; startScale=uiScale.Scale
				input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then resizing=false end end)
			end
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if resizing and input.UserInputType==Enum.UserInputType.MouseMovement then
			local mp=Vector2.new(input.Position.X,input.Position.Y)
			local dx,dy=mp.X-startMouse.X,mp.Y-startMouse.Y
			local newW,newH=startAbs.X+dx,startAbs.Y+dy
			local scaleFromW=newW/BASE.X
			local scaleFromH=newH/BASE.Y
			uiScale.Scale=math.clamp(math.max(scaleFromW,scaleFromH),MIN_SCALE,MAX_SCALE)
		end
	end)

	-- FPS loop
	local minF,maxF=math.huge,0
	RunService.RenderStepped:Connect(function(dt)
		local fps=math.floor(1/dt+0.5)
		minF=math.min(minF,fps)
		maxF=math.max(maxF,fps)
		lblNow.Text="FPS: "..fps
		lblMinMax.Text=("Min: %d | Max: %d"):format(minF==math.huge and 0 or minF,maxF)
	end)

	function win:Destroy() win:Destroy() end
	return win
end

return FPS