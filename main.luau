-- main.luau — KScripts (layout original) + Settings (Show FPS) + Five Nights: Hunted (ESP + Walkspeed + Show Computers)

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")

-- RAWs dos módulos
local FPS_URL         = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Settings/showfps.luau"
local ESP_URL         = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/esp.luau"
local WALKSPEED_URL   = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/walkspeed.luau"
local SHOWCOMP_URL    = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/showcomputer.luau"

local FPS              = loadstring(game:HttpGet(FPS_URL))()
local ESPModule        = loadstring(game:HttpGet(ESP_URL))()
local WalkspeedModule  = loadstring(game:HttpGet(WALKSPEED_URL))()
local ShowComputerMod  = loadstring(game:HttpGet(SHOWCOMP_URL))()

-- =================== UI CONSTS ===================
local TITLEBAR_H, SIDEBAR_W, PAD = 36, 200, 8
local DEFAULT_SIZE = Vector2.new(860, 520)
local SECTIONS = { "Universal", "Five Nights: Hunted", "Settings" }

local COLORS = {
	BG     = Color3.fromRGB(24,24,24),
	PANEL  = Color3.fromRGB(35,35,35),
	ACCENT = Color3.fromRGB(0,132,255),
	TEXT   = Color3.new(1,1,1),
	MUTED  = Color3.fromRGB(180,180,180),
	BTN    = Color3.fromRGB(60,60,60),
}

-- =================== HELPERS ===================
local function make(class, props, kids)
	local o = Instance.new(class)
	for k,v in pairs(props or {}) do o[k]=v end
	for _,c in ipairs(kids or {}) do c.Parent = o end
	return o
end

local function centerOffset(size: Vector2)
	local cam = workspace.CurrentCamera
	local vp  = cam and cam.ViewportSize or Vector2.new(1280,720)
	return Vector2.new(math.floor((vp.X-size.X)/2), math.floor((vp.Y-size.Y)/2))
end

local function attachDrag(frame: Frame, handle: GuiObject)
	handle.Active = true
	local dragging, dragInput = false, nil
	local dragStart, startPos = Vector2.zero, UDim2.fromOffset(0,0)

	local function update(input: InputObject)
		local d = input.Position - dragStart
		local vp = workspace.CurrentCamera.ViewportSize
		local newX = math.clamp(startPos.X.Offset + d.X, 0, vp.X - frame.AbsoluteSize.X)
		local newY = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - frame.AbsoluteSize.Y)
		frame.Position = UDim2.fromOffset(newX, newY)
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
		if input==dragInput and dragging then update(input) end
	end)
end

local function forceYScroll(sf: ScrollingFrame)
	local function upd()
		local a = sf.AbsoluteSize
		sf.CanvasSize = UDim2.new(0, a.X, 0, a.Y + 1)
	end
	upd()
	sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd)
end

-- =================== BUILD ROOT ===================
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rootGui = make("ScreenGui", {
	Name="KScriptsGUI", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=50
})
rootGui.Parent = playerGui

-- Toast
local toastGui = make("ScreenGui", {
	Name="KScriptsToast", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=10000
})
toastGui.Parent = playerGui
local function showToast(msg: string, duration: number?)
	duration = duration or 3.5
	local holder = make("Frame", {
		AnchorPoint=Vector2.new(1,1),
		Position=UDim2.fromScale(1,1),
		Size=UDim2.fromOffset(420, 56),
		BackgroundTransparency=1,
	})
	holder.Parent = toastGui
	local card = make("Frame", { BackgroundColor3=COLORS.PANEL, BorderSizePixel=0, Size=UDim2.fromScale(1,1) })
	card.Parent = holder
	make("TextLabel", {
		BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14,
		TextColor3=COLORS.TEXT, TextXAlignment=Enum.TextXAlignment.Left,
		TextWrapped=true, Text = msg, Size=UDim2.fromScale(1,1),
		Position=UDim2.fromOffset(12,0)
	}).Parent = card
	task.delay(duration, function() if holder then holder:Destroy() end end)
end

local startPos = centerOffset(DEFAULT_SIZE)
local win = make("Frame", {
	Name="KScriptsWindow",
	Position=UDim2.fromOffset(startPos.X, startPos.Y),
	Size=UDim2.fromOffset(DEFAULT_SIZE.X, DEFAULT_SIZE.Y),
	BackgroundColor3=COLORS.BG, BorderSizePixel=0, Active=true
}, { make("UICorner", { CornerRadius=UDim.new(0,12) }) })
win.Parent = rootGui

local bar = make("Frame", {
	Size=UDim2.new(1,0,0,TITLEBAR_H), BackgroundColor3=COLORS.PANEL, BorderSizePixel=0, Active=true
}, { make("UICorner",{CornerRadius=UDim.new(0,12)}) })
bar.Parent = win
make("TextLabel", {
	BackgroundTransparency=1, Text="KScripts",
	Font=Enum.Font.GothamBold, TextSize=16, TextColor3=COLORS.TEXТ,
	TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1)
}).Parent = bar
local close = make("TextButton", {
	Text="X", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
	BackgroundColor3=COLORS.BTN, AutoButtonColor=true, ZIndex=2,
	Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-(28+PAD),0.5,-14)
}, { make("UICorner",{CornerRadius=UDim.new(0,8)}) })
close.Parent = bar
attachDrag(win, bar)

local body = make("Frame", {
	BackgroundTransparency=1,
	Size=UDim2.new(1,-PAD*2,1,-(TITLEBAR_H+PAD*2)),
	Position=UDim2.fromOffset(PAD, TITLEBAR_H+PAD)
})
	body.Parent = win

-- Sidebar à esquerda
local sidebar = make("ScrollingFrame", {
	Name="Sidebar",
	BackgroundColor3=COLORS.PANEL, BorderSizePixel=0,
	ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y,
	Active=true,
	Size=UDim2.new(0, 200, 1, 0),
	Position=UDim2.fromOffset(0,0)
}, { make("UICorner",{CornerRadius=UDim.new(0,10)}) })
sidebar.Parent = body
make("UIPadding", {
	PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
	PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)
}).Parent = sidebar
local sbList = make("UIListLayout", { Padding=UDim.new(0,6) })
sbList.Parent = sidebar
forceYScroll(sidebar)

-- Conteúdo à direita
local content = make("ScrollingFrame", {
	Name="Content",
	BackgroundColor3=COLORS.PANEL, BorderSizePixel=0,
	ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y,
	Active=true,
	Position=UDim2.fromOffset(200 + PAD, 0),
	Size=UDim2.new(1, -(200 + PAD), 1, 0)
}, { make("UICorner",{CornerRadius=UDim.new(0,10)}) })
content.Parent = body
make("UIPadding", {
	PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
	PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)
}).Parent = content
forceYScroll(content)

-- Seções
local sectionFrames, sidebarButtons = {}, {}
local function setActive(name: string)
	for n,btn in pairs(sidebarButtons) do
		btn.BackgroundColor3 = (n==name) and COLORS.ACCENT or COLORS.BTN
	end
	for n,fr in pairs(sectionFrames) do
		fr.Visible = (n==name)
	end
end

for _, name in ipairs(SECTIONS) do
	local tab = make("TextButton", {
		BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Text=name, Font=Enum.Font.GothamBold, TextSize=14,
		TextColor3=COLORS.TEXT,
		Size=UDim2.new(1,-20,0,36)
	}, { make("UICorner",{CornerRadius=UDim.new(0,8)}) })
	tab.Parent = sidebar
	sidebarButtons[name] = tab

	local cont = make("Frame", { BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Visible=false })
	cont.Parent = content
	sectionFrames[name] = cont

	tab.MouseButton1Click:Connect(function() setActive(name) end)
end
setActive(SECTIONS[1])

-- SETTINGS: FPS
local fpsEnabled, fpsWin = false, nil
do
	local settings = sectionFrames["Settings"]
	make("TextLabel", {
		Text="Show FPS", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,4)
	}).Parent = settings

	local switch = make("TextButton", {
		Text="", BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,4)
	}, { make("UICorner",{CornerRadius=UDim.new(0,13)}) })
	switch.Parent = settings
	local ball = make("Frame", {
		Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(2,2),
		BackgroundColor3=Color3.fromRGB(200,200,200)
	}, { make("UICorner",{CornerRadius=UDim.new(0,11)}) })
	ball.Parent = switch

	local function setSwitch(on: boolean)
		if on then
			ball:TweenPosition(UDim2.fromOffset(30,2),"Out","Quad",0.15,true)
			ball.BackgroundColor3 = COLORS.ACCENT
		else
			ball:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.15,true)
			ball.BackgroundColor3 = Color3.fromRGB(200,200,200)
		end
	end

	switch.MouseButton1Click:Connect(function()
		fpsEnabled = not fpsEnabled
		setSwitch(fpsEnabled)
		if fpsEnabled then
			fpsWin = FPS.create(rootGui)
		else
			if fpsWin then fpsWin:Destroy() fpsWin=nil end
		end
	end)
end

-- FIVE NIGHTS: ESP + Walkspeed + Show Computers
local espEnabled, espCtl, walkCtl = false, nil, WalkspeedModule.new()
local scEnabled, scCtl = false, nil
do
	local fnH = sectionFrames["Five Nights: Hunted"]

	-- ESP
	make("TextLabel", {
		Text="ESP", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,4)
	}).Parent = fnH
	local espSwitch = make("TextButton", {
		Text="", BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,4)
	}, { make("UICorner",{CornerRadius=UDim.new(0,13)}) })
	espSwitch.Parent = fnH
	local espBall = make("Frame", {
		Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(2,2),
		BackgroundColor3=Color3.fromRGB(200,200,200)
	}, { make("UICorner",{CornerRadius=UDim.new(0,11)}) })
	espBall.Parent = espSwitch
	local function setESPSwitch(on: boolean)
		if on then
			espBall:TweenPosition(UDim2.fromOffset(30,2),"Out","Quad",0.15,true)
			espBall.BackgroundColor3 = COLORS.ACCENT
		else
			espBall:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.15,true)
			espBall.BackgroundColor3 = Color3.fromRGB(200,200,200)
		end
	end
	espSwitch.MouseButton1Click:Connect(function()
		espEnabled = not espEnabled
		setESPSwitch(espEnabled)
		if espEnabled then
			if not espCtl then espCtl = ESPModule.create({MaxDistance=3000, UpdateHz=10}) end
			espCtl:Enable()
		else
			if espCtl then espCtl:Disable() end
		end
	end)

	-- Walkspeed (tecla + base/boost)
	make("TextLabel", {
		Text="Walkspeed", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,40),
		TextXAlignment=Enum.TextXAlignment.Left
	}).Parent = fnH
	local wsKeyBtn = make("TextButton", {
		Text="Set Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.BTN, Size=UDim2.fromOffset(100,26),
		Position=UDim2.fromOffset(220,40)
	}); wsKeyBtn.Parent = fnH
	local clearBtn = make("TextButton", {
		Text="Clear Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.BTN, Size=UDim2.fromOffset(100,26),
		Position=UDim2.fromOffset(330,40)
	}); clearBtn.Parent = fnH
	local baseBox = make("TextBox", {
		Text="16", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.PANEL, Size=UDim2.fromOffset(60,26),
		Position=UDim2.fromOffset(220,75)
	}); baseBox.Parent = fnH
	local boostBox = make("TextBox", {
		Text="32", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.PANEL, Size=UDim2.fromOffset(60,26),
		Position=UDim2.fromOffset(290,75)
	}); boostBox.Parent = fnH
	make("TextLabel", {Text="Base",  Font=Enum.Font.Gotham, TextSize=12, TextColor3=COLORS.MUTED, BackgroundTransparency=1, Size=UDim2.fromOffset(40,20), Position=UDim2.fromOffset(220,100)}).Parent = fnH
	make("TextLabel", {Text="Boost", Font=Enum.Font.Gotham, TextSize=12, TextColor3=COLORS.MUTED, BackgroundTransparency=1, Size=UDim2.fromOffset(40,20), Position=UDim2.fromOffset(290,100)}).Parent = fnH

	local currentKey: Enum.KeyCode? = nil
	wsKeyBtn.MouseButton1Click:Connect(function()
		wsKeyBtn.Text="Press..."
		local conn; conn = UIS.InputBegan:Connect(function(input,gp)
			if not gp and input.KeyCode ~= Enum.KeyCode.Unknown then
				currentKey = input.KeyCode
				walkCtl:SetKey(currentKey)
				wsKeyBtn.Text = "Key: " .. input.KeyCode.Name
				conn:Disconnect()
			end
		end)
	end)
	clearBtn.MouseButton1Click:Connect(function()
		currentKey=nil
		walkCtl:SetKey(nil)
		wsKeyBtn.Text="Set Key"
	end)
	local function updateSpeeds()
		walkCtl:SetSpeeds(tonumber(baseBox.Text) or 16, tonumber(boostBox.Text) or 32)
	end
	baseBox.FocusLost:Connect(updateSpeeds)
	boostBox.FocusLost:Connect(updateSpeeds)

	-- Show Computers (novo)
	make("TextLabel", {
		Text="Show Computers", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,130)
	}).Parent = fnH
	local scSwitch = make("TextButton", {
		Text="", BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,130)
	}, { make("UICorner",{CornerRadius=UDim.new(0,13)}) })
	scSwitch.Parent = fnH
	local scBall = make("Frame", {
		Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(2,2),
		BackgroundColor3=Color3.fromRGB(200,200,200)
	}, { make("UICorner",{CornerRadius=UDim.new(0,11)}) })
	scBall.Parent = scSwitch
	local function setSCSwitch(on: boolean)
		if on then
			scBall:TweenPosition(UDim2.fromOffset(30,2),"Out","Quad",0.15,true)
			scBall.BackgroundColor3 = COLORS.ACCENT
		else
			scBall:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.15,true)
			scBall.BackgroundColor3 = Color3.fromRGB(200,200,200)
		end
	end
	scSwitch.MouseButton1Click:Connect(function()
		scEnabled = not scEnabled
		setSCSwitch(scEnabled)
		if scEnabled then
			if not scCtl then scCtl = ShowComputerMod.new({color = Color3.fromRGB(0,255,0), name = "computer"}) end
			scCtl:Enable()
		else
			if scCtl then scCtl:Disable() end
		end
	end)
end

-- Fechar + F1
close.MouseButton1Click:Connect(function()
	win.Visible = false
	showToast("KScripts oculto. Pressione F1 para reabrir.", 3.5)
end)
UIS.InputBegan:Connect(function(input,gp)
	if not gp and input.KeyCode==Enum.KeyCode.F1 then
		win.Visible = not win.Visible
	end
end)

print("KScripts: GUI carregada (FPS + ESP + Walkspeed + Show Computers).")