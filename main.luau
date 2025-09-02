-- main.luau — KScripts (layout original) + Settings (Show FPS)
-- + Five Nights: Hunted (ESP + Walkspeed + Show Computers + Show Ball Pits)
-- Corrigido: (1) caminhos; (2) fetch de módulos sem desalinhamento.

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")

-- URLs (ajustadas à sua estrutura atual)
local FPS_URL          = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Settings/showfps.luau"
local ESP_URL          = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/esp.luau"
local WALKSPEED_URL    = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/walkspeed.luau"
local SHOWCOMP_URL     = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/showcomputer.luau"
local SHOWBALLPIT_URL  = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/Five%20Nights%20-%20Hunted/showballpit.luau"

-- ========= helpers de UI =========
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

-- ========= ROOT GUI =========
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

-- ========= carregador robusto =========
local function safeFetch(url: string, name: string)
	local okGet, src = pcall(function() return game:HttpGet(url) end)
	if not okGet then
		showToast(("Falha ao baixar módulo '%s'"):format(name))
		return nil, ("HttpGet fail: %s"):format(name)
	end
	local okChunk, chunk = pcall(loadstring, src)
	if not okChunk then
		showToast(("Falha ao compilar módulo '%s'"):format(name))
		return nil, ("loadstring fail: %s"):format(name)
	end
	local okRet, mod = pcall(chunk)
	if not okRet then
		showToast(("Falha ao iniciar módulo '%s'"):format(name))
		return nil, ("chunk run fail: %s"):format(name)
	end
	return mod, nil
end

-- NADA de múltiplos retornos aqui. Cada fetch em sua linha:
local FPS              = select(1, safeFetch(FPS_URL,         "showfps"))
local ESPModule        = select(1, safeFetch(ESP_URL,         "esp"))
local WalkspeedModule  = select(1, safeFetch(WALKSPEED_URL,   "walkspeed"))
local ShowComputerMod  = select(1, safeFetch(SHOWCOMP_URL,    "showcomputer"))
local ShowBallPitMod   = select(1, safeFetch(SHOWBALLPIT_URL, "showballpit"))

-- ========= janela principal =========
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
	Font=Enum.Font.GothamBold, TextSize=16, TextColor3=COLORS.TEXT,
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

-- Sidebar
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

-- Content
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
		btn.TextColor3       = COLORS.TEXT
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

-- ===== Settings: Show FPS =====
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
		if not FPS then showToast("Módulo FPS ausente"); return end
		fpsEnabled = not fpsEnabled
		setSwitch(fpsEnabled)
		if fpsEnabled then
			fpsWin = FPS.create(rootGui)
		else
			if fpsWin then fpsWin:Destroy() fpsWin=nil end
		end
	end)
end

-- ===== Five Nights: ESP + Show Computers + Show Ball Pits + Walkspeed =====
local espEnabled, espCtl = false, nil
local scEnabled, scCtl   = false, nil
local bpEnabled, bpCtl   = false, nil
local walkCtl = WalkspeedModule and WalkspeedModule.new() or nil

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
		if not ESPModule then showToast("Módulo ESP ausente"); return end
		espEnabled = not espEnabled
		setESPSwitch(espEnabled)
		if espEnabled then
			if not espCtl then espCtl = ESPModule.create({MaxDistance=3000, UpdateHz=10}) end
			espCtl:Enable()
		else
			if espCtl then espCtl:Disable() end
		end
	end)

	-- Show Computers (verde)
	make("TextLabel", {
		Text="Show Computers", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,40)
	}).Parent = fnH
	local scSwitch = make("TextButton", {
		Text="", BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,40)
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
		if not ShowComputerMod then showToast("Módulo Show Computers ausente"); return end
		scEnabled = not scEnabled
		setSCSwitch(scEnabled)
		if scEnabled then
			if not scCtl then scCtl = ShowComputerMod.new({color = Color3.fromRGB(0,255,0), name = "computer"}) end
			scCtl:Enable()
		else
			if scCtl then scCtl:Disable() end
		end
	end)

	-- Show Ball Pits (vermelho)
	make("TextLabel", {
		Text="Show Ball Pits", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,86)
	}).Parent = fnH
	local bpSwitch = make("TextButton", {
		Text="", BackgroundColor3=COLORS.BTN, AutoButtonColor=true,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,86)
	}, { make("UICorner",{CornerRadius=UDim.new(0,13)}) })
	bpSwitch.Parent = fnH
	local bpBall = make("Frame", {
		Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(2,2),
		BackgroundColor3=Color3.fromRGB(200,200,200)
	}, { make("UICorner",{CornerRadius=UDim.new(0,11)}) })
	bpBall.Parent = bpSwitch
	local function setBPSwitch(on: boolean)
		if on then
			bpBall:TweenPosition(UDim2.fromOffset(30,2),"Out","Quad",0.15,true)
			bpBall.BackgroundColor3 = COLORS.ACCENT
		else
			bpBall:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.15,true)
			bpBall.BackgroundColor3 = Color3.fromRGB(200,200,200)
		end
	end
	bpSwitch.MouseButton1Click:Connect(function()
		if not ShowBallPitMod then showToast("Módulo Show Ball Pits ausente"); return end
		bpEnabled = not bpEnabled
		setBPSwitch(bpEnabled)
		if bpEnabled then
			if not bpCtl then bpCtl = ShowBallPitMod.new({color = Color3.fromRGB(255,0,0), name = "ball pit"}) end
			bpCtl:Enable()
		else
			if bpCtl then bpCtl:Disable() end
		end
	end)

	-- Walkspeed (tecla + base/boost)
	make("TextLabel", {
		Text="Walkspeed", Font=Enum.Font.GothamBold, TextSize=16,
		TextColor3=COLORS.TEXT, BackgroundTransparency=1,
		Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,132),
		TextXAlignment=Enum.TextXAlignment.Left
	}).Parent = fnH

	local wsKeyBtn = make("TextButton", {
		Text="Set Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.BTN, Size=UDim2.fromOffset(100,26),
		Position=UDim2.fromOffset(220,132)
	}); wsKeyBtn.Parent = fnH

	local clearBtn = make("TextButton", {
		Text="Clear Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.BTN, Size=UDim2.fromOffset(100,26),
		Position=UDim2.fromOffset(330,132)
	}); clearBtn.Parent = fnH

	local baseBox = make("TextBox", {
		Text="16", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.PANEL, Size=UDim2.fromOffset(60,26),
		Position=UDim2.fromOffset(220,167)
	}); baseBox.Parent = fnH

	local boostBox = make("TextBox", {
		Text="32", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
		BackgroundColor3=COLORS.PANEL, Size=UDim2.fromOffset(60,26),
		Position=UDim2.fromOffset(290,167)
	}); boostBox.Parent = fnH

	make("TextLabel",{Text="Base",  Font=Enum.Font.Gotham, TextSize=12, TextColor3=COLORS.MUTED, BackgroundTransparency=1, Size=UDim2.fromOffset(40,20), Position=UDim2.fromOffset(220,192)}).Parent = fnH
	make("TextLabel",{Text="Boost", Font=Enum.Font.Gotham, TextSize=12, TextColor3=COLORS.MUTED, BackgroundTransparency=1, Size=UDim2.fromOffset(40,20), Position=UDim2.fromOffset(290,192)}).Parent = fnH

	local currentKey: Enum.KeyCode? = nil
	wsKeyBtn.MouseButton1Click:Connect(function()
		if not walkCtl then showToast("Módulo Walkspeed ausente"); return end
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
		if not walkCtl then return end
		currentKey=nil
		walkCtl:SetKey(nil)
		wsKeyBtn.Text="Set Key"
	end)
	local function updateSpeeds()
		if not walkCtl then return end
		walkCtl:SetSpeeds(tonumber(baseBox.Text) or 16, tonumber(boostBox.Text) or 32)
	end
	baseBox.FocusLost:Connect(updateSpeeds)
	boostBox.FocusLost:Connect(updateSpeeds)
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