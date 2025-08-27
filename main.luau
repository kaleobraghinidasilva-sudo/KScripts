-- main.luau
-- KScripts GUI (completo) + integração FPS GUI
-- Autoexecutável: roda direto no Solara

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- === IMPORT FPS MODULE ===
local FPS_URL = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/fps.luau"
local FPS = loadstring(game:HttpGet(FPS_URL))()

-- === CONFIG ===
local COLORS = {
	BG     = Color3.fromRGB(24,24,24),
	PANEL  = Color3.fromRGB(35,35,35),
	ACCENT = Color3.fromRGB(0,132,255),
	TEXT   = Color3.fromRGB(235,235,235),
	MUTED  = Color3.fromRGB(160,160,160),
	BTN    = Color3.fromRGB(60,60,60),
}
local TITLEBAR_H, SIDEBAR_W, PAD = 36, 200, 8
local DEFAULT_SECTIONS = {"Universal","Five Nights: Hunted","Settings"}
local DEFAULT_SIZE = Vector2.new(860,520)

-- === HELPERS ===
local function make(class, props, kids)
	local o=Instance.new(class)
	for k,v in pairs(props or {}) do o[k]=v end
	for _,c in ipairs(kids or {}) do c.Parent=o end
	return o
end

local function centerOffset(size: Vector2)
	local cam=workspace.CurrentCamera
	local vp=cam and cam.ViewportSize or Vector2.new(1280,720)
	return Vector2.new(math.floor((vp.X-size.X)/2), math.floor((vp.Y-size.Y)/2))
end

local function attachDrag(frame: Frame, handle: GuiObject, blocks: {GuiObject}?)
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
			if blocks then
				local mp=Vector2.new(input.Position.X,input.Position.Y)
				for _,b in ipairs(blocks) do
					local ap,as=b.AbsolutePosition,b.AbsoluteSize
					if mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y then
						return
					end
				end
			end
			dragging=true
			dragStart=input.Position
			startPos=frame.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then dragging=false end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseMovement then
			dragInput=input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input==dragInput and dragging then update(input) end
	end)
end

-- === TOAST SYSTEM ===
local function createToastGui(parent)
	local toastGui=make("ScreenGui",{Name="KScriptsToast",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=10000})
	toastGui.Parent=parent
	return function(msg: string, duration: number?)
		duration=duration or 3
		local box=make("Frame",{
			AnchorPoint=Vector2.new(1,1),Position=UDim2.fromScale(1,1),
			Size=UDim2.fromOffset(320,42),BackgroundColor3=COLORS.PANEL
		})
		box.Parent=toastGui
		make("TextLabel",{Text=msg,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=COLORS.TEXT,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1)}).Parent=box
		task.delay(duration,function() if box then box:Destroy() end end)
	end
end

-- === MAIN CREATE ===
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")

local rootGui=make("ScreenGui",{Name="KScriptsGUI",ResetOnSpawn=false,IgnoreGuiInset=true})
rootGui.Parent=parent
local showToast=createToastGui(parent)

-- janela
local startPos=centerOffset(DEFAULT_SIZE)
local win=make("Frame",{
	Size=UDim2.fromOffset(DEFAULT_SIZE.X,DEFAULT_SIZE.Y),Position=UDim2.fromOffset(startPos.X,startPos.Y),
	BackgroundColor3=COLORS.BG,Active=true
})
win.Parent=rootGui

-- barra título
local bar=make("Frame",{Size=UDim2.new(1,0,0,TITLEBAR_H),BackgroundColor3=COLORS.PANEL,Active=true})
bar.Parent=win
make("TextLabel",{Text="KScripts",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=COLORS.TEXT,
	BackgroundTransparency=1,Size=UDim2.new(1,-50,1,0),Position=UDim2.fromOffset(8,0)}).Parent=bar
local close=make("TextButton",{Text="X",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=COLORS.TEXT,
	BackgroundColor3=COLORS.BTN,Size=UDim2.fromOffset(28,28),Position=UDim2.new(1,-36,0.5,-14)})
close.Parent=bar
attachDrag(win,bar,{close})

-- sidebar
local sidebar=make("Frame",{Size=UDim2.fromOffset(SIDEBAR_W,DEFAULT_SIZE.Y-TITLEBAR_H),
	Position=UDim2.fromOffset(0,TITLEBAR_H),BackgroundColor3=COLORS.PANEL})
sidebar.Parent=win

-- content
local content=make("Frame",{Size=UDim2.new(1,-SIDEBAR_W,1,-TITLEBAR_H),
	Position=UDim2.fromOffset(SIDEBAR_W,TITLEBAR_H),BackgroundColor3=COLORS.PANEL})
content.Parent=win

-- sections
local sectionFrames={}
for i,name in ipairs(DEFAULT_SECTIONS) do
	local btn=make("TextButton",{Text=name,Font=Enum.Font.GothamBold,TextSize=14,
		Size=UDim2.fromOffset(180,30),Position=UDim2.fromOffset(10,10+(i-1)*40),
		BackgroundColor3=COLORS.BTN,TextColor3=COLORS.MUTED})
	btn.Parent=sidebar
	local frame=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
	frame.Parent=content
	sectionFrames[name]=frame
	btn.MouseButton1Click:Connect(function()
		for n,f in pairs(sectionFrames) do f.Visible=false end
		frame.Visible=true
		for _,b in ipairs(sidebar:GetChildren()) do
			if b:IsA("TextButton") then
				b.BackgroundColor3=COLORS.BTN; b.TextColor3=COLORS.MUTED
			end
		end
		btn.BackgroundColor3=COLORS.ACCENT; btn.TextColor3=COLORS.TEXT
	end)
	if i==1 then frame.Visible=true; btn.BackgroundColor3=COLORS.ACCENT; btn.TextColor3=COLORS.TEXT end
end

-- settings: toggle FPS
local fpsToggleBtn=make("TextButton",{
	Text="",BackgroundColor3=COLORS.BTN,Size=UDim2.fromOffset(50,24),Position=UDim2.fromOffset(20,40),
	Parent=sectionFrames["Settings"]
})
local fpsBall=make("Frame",{
	Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(2,2),
	BackgroundColor3=Color3.fromRGB(200,200,200),Parent=fpsToggleBtn
})
fpsBall.AnchorPoint=Vector2.new(0,0)

local fpsEnabled=false
local fpsWin=nil
fpsToggleBtn.MouseButton1Click:Connect(function()
	fpsEnabled=not fpsEnabled
	if fpsEnabled then
		fpsBall:TweenPosition(UDim2.fromOffset(28,2),"Out","Quad",0.2,true)
		fpsBall.BackgroundColor3=COLORS.ACCENT
		fpsWin=FPS.create(parent)
	else
		fpsBall:TweenPosition(UDim2.fromOffset(2,2),"Out","Quad",0.2,true)
		fpsBall.BackgroundColor3=Color3.fromRGB(200,200,200)
		if fpsWin then fpsWin:Destroy(); fpsWin=nil end
	end
end)

-- fechar KScripts
close.MouseButton1Click:Connect(function()
	win.Visible=false
	showToast("KScripts oculto. Pressione F1 para reabrir.",3)
end)

-- toggle KScripts via F1
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode==Enum.KeyCode.F1 then
		win.Visible=not win.Visible
	end
end)

print("✅ KScripts GUI carregado com sucesso!")