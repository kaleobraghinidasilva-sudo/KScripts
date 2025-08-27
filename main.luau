-- main.luau — KScripts completo (menu lateral, toast, drag sem salto) + integração com FPS
-- Executa direto no Solara com uma linha de loadstring.

-- === Services ===
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")

-- === RAW do módulo FPS (ajuste se mudar o repo) ===
local FPS_URL = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/fps.luau"
local FPS     = loadstring(game:HttpGet(FPS_URL))()

-- === Estilo/Constantes ===
local TITLEBAR_H, SIDEBAR_W, PAD = 36, 200, 8
local COLORS = {
	BG     = Color3.fromRGB(24,24,24),
	PANEL  = Color3.fromRGB(35,35,35),
	ACCENT = Color3.fromRGB(0,132,255),
	TEXT   = Color3.fromRGB(235,235,235),
	MUTED  = Color3.fromRGB(160,160,160),
	BTN    = Color3.fromRGB(60,60,60),
}
local DEFAULT_SIZE = Vector2.new(860,520)
local SECTIONS     = {"Universal","Five Nights: Hunted","Settings"}

-- === Helpers ===
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

-- Drag estável (sem salto)
local function attachDrag(frame: Frame, handle: GuiObject, blocked: {GuiObject}?)
	handle.Active = true
	local dragging = false
	local dragInput, dragStart, startPos

	local function inside(o: GuiObject, p: Vector2)
		local ap, as = o.AbsolutePosition, o.AbsoluteSize
		return p.X>=ap.X and p.X<=ap.X+as.X and p.Y>=ap.Y and p.Y<=ap.Y+as.Y
	end

	local function update(input: InputObject)
		local delta = input.Position - dragStart
		frame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if blocked then
				local mp = Vector2.new(input.Position.X, input.Position.Y)
				for _,b in ipairs(blocked) do if inside(b, mp) then return end end
			end
			dragging  = true
			dragStart = input.Position
			startPos  = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
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

-- Força barra de rolagem vertical visível
local function forceYScroll(sf: ScrollingFrame)
	local function upd()
		local a = sf.AbsoluteSize
		sf.CanvasSize = UDim2.new(0, a.X, 0, a.Y + 1)
	end
	upd()
	sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd)
end

-- === Build KScripts ===
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")

-- Raízes
local rootGui  = make("ScreenGui", {Name="KScriptsGUI", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=50})
rootGui.Parent = parent

local toastGui = make("ScreenGui", {Name="KScriptsToast", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=10000})
toastGui.Parent = parent

local function showToast(msg: string, duration: number?)
	duration = duration or 3.5
	local container = make("Frame",{
		BackgroundTransparency=1, AnchorPoint=Vector2.new(1,1),
		Position=UDim2.fromScale(1,1), Size=UDim2.fromOffset(410,56)
	})
	container.Parent = toastGui
	local card = make("Frame",{BackgroundColor3=COLORS.PANEL, BorderSizePixel=0, Size=UDim2.fromScale(1,1)})
	card.Parent = container
	make("TextLabel",{
		BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=14,
		TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, TextColor3=COLORS.TEXT,
		Text=msg, Size=UDim2.fromScale(1,1), Position=UDim2.fromOffset(12,0)
	}).Parent = card
	task.delay(duration, function() if container then container:Destroy() end end)
end

-- Janela
local startPos = centerOffset(DEFAULT_SIZE)
local win = make("Frame",{
	Name="KScriptsWindow",
	Position=UDim2.fromOffset(startPos.X, startPos.Y),
	Size=UDim2.fromOffset(DEFAULT_SIZE.X, DEFAULT_SIZE.Y),
	BackgroundColor3=COLORS.BG, BorderSizePixel=0, Active=true
},{ make("UICorner",{CornerRadius=UDim.new(0,12)}) })
win.Parent = rootGui

-- Título
local bar = make("Frame",{Size=UDim2.new(1,0,0,TITLEBAR_H), BackgroundColor3=COLORS.PANEL, BorderSizePixel=0, Active=true},{ make("UICorner",{CornerRadius=UDim.new(0,12)}) })
bar.Parent = win
make("TextLabel",{
	BackgroundTransparency=1, Text="KScripts", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=COLORS.TEXT,
	TextXAlignment=Enum.TextXAlignment.Center, Size=UDim2.fromScale(1,1)
}).Parent = bar
local close = make("TextButton",{
	Text="X", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=COLORS.TEXT,
	BackgroundColor3=COLORS.BTN, AutoButtonColor=true, ZIndex=2,
	Size=UDim2.fromOffset(28,28), Position=UDim2.new(1,-(28+PAD),0.5,-14)
},{ make("UICorner",{CornerRadius=UDim.new(0,8)}) })
close.Parent = bar
close.Selectable = false
attachDrag(win, bar, {close})

-- Body
local body = make("Frame",{BackgroundTransparency=1, Size=UDim2.new(1,-PAD*2,1,-(TITLEBAR_H+PAD*2)), Position=UDim2.fromOffset(PAD, TITLEBAR_H+PAD)})
body.Parent = win

-- Sidebar (com rolagem)
local sidebar = make("ScrollingFrame",{
	Name="Sidebar", BackgroundColor3=COLORS.PANEL, BorderSizePixel=0,
	ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y,
	Active=true, AutomaticCanvasSize=Enum.AutomaticSize.None,
	Size=UDim2.fromOffset(SIDEBAR_W, body.AbsoluteSize.Y), Position=UDim2.fromOffset(0,0)
},{ make("UICorner",{CornerRadius=UDim.new(0,10)}) })
sidebar.Parent = body
forceYScroll(sidebar)
make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}).Parent = sidebar
local sbList = make("UIListLayout",{Padding=UDim.new(0,6), FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder})
sbList.Parent = sidebar

-- Content (com rolagem)
local content = make("ScrollingFrame",{
	Name="Content", BackgroundColor3=COLORS.PANEL, BorderSizePixel=0,
	ScrollBarThickness=8, ScrollingDirection=Enum.ScrollingDirection.Y,
	Active=true, AutomaticCanvasSize=Enum.AutomaticSize.None,
	Position=UDim2.fromOffset(SIDEBAR_W+PAD,0), Size=UDim2.new(1,-(SIDEBAR_W+PAD),1,0)
},{ make("UICorner",{CornerRadius=UDim.new(0,10)}) })
content.Parent = body
forceYScroll(content)
make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)}).Parent = content

-- Abas/Seções
local sectionFrames = {}
local sidebarButtons = {}
local function setActive(name: string)
	for n,btn in pairs(sidebarButtons) do
		if n==name then btn.BackgroundColor3=COLORS.ACCENT; btn.TextColor3=Color3.new(1,1,1)
		else btn.BackgroundColor3=COLORS.BTN; btn.TextColor3=COLORS.MUTED end
	end
	for n,fr in pairs(sectionFrames) do fr.Visible=(n==name) end
end

for _, name in ipairs(SECTIONS) do
	local tab = make("TextButton",{
		BackgroundColor3=COLORS.BTN, AutoButtonColor=true, Text=name, Font=Enum.Font.GothamBold, TextSize=14,
		TextColor3=COLORS.MUTED, Size=UDim2.new(1,-20,0,36)
	},{ make("UICorner",{CornerRadius=UDim.new(0,8)}) })
	tab.Parent = sidebar
	sidebarButtons[name] = tab

	local cont = make("Frame",{BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Visible=false})
	cont.Parent = content
	sectionFrames[name] = cont

	tab.MouseButton1Click:Connect(function() setActive(name) end)
end
-- inicial
setActive(SECTIONS[1])

-- SETTINGS → Toggle "Show FPS"
do
	local settings = sectionFrames["Settings"]
	-- rótulo
	make("TextLabel",{
		Text="Show FPS", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=COLORS.TEXT,
		BackgroundTransparency=1, Size=UDim2.fromOffset(200,26), Position=UDim2.fromOffset(4,4),
		TextXAlignment=Enum.TextXAlignment.Left
	}).Parent = settings

	-- switch
	local switch = make("TextButton",{
		AutoButtonColor=true, Text="", BackgroundColor3=COLORS.BTN,
		Size=UDim2.fromOffset(54,26), Position=UDim2.fromOffset(220,4)
	},{ make("UICorner",{CornerRadius=UDim.new(0,13)}) })
	switch.Parent = settings
	local ball = make("Frame",{
		Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(2,2), BackgroundColor3=Color3.fromRGB(200,200,200)
	},{ make("UICorner",{CornerRadius=UDim.new(0,11)}) })
	ball.Parent = switch

	local fpsEnabled = false
	local fpsWin : any = nil
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
			fpsWin = FPS.create(parent) -- cria janela FPS
		else
			if fpsWin and fpsWin.Destroy then fpsWin:Destroy() end
			fpsWin = nil
		end
	end)
end

-- Fechar + Toast
close.MouseButton1Click:Connect(function()
	win.Visible = false
	showToast("KScripts oculto. Pressione F1 para reabrir.", 3.5)
end)

-- Atalho F1 para mostrar/ocultar
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		win.Visible = not win.Visible
	end
end)

print("KScripts: GUI carregada.")