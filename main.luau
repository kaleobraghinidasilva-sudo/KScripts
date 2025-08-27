-- main.luau
-- Autoexecutável: carrega KScripts GUI e FPS GUI ao rodar pelo executor

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- carrega FPS.luau direto do GitHub RAW
local FPS_URL = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/Modules/fps.luau"
local FPS = loadstring(game:HttpGet(FPS_URL))()

-- helpers
local function make(class, props, kids)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent = o end
    return o
end

local function attachDrag(frame: Frame, handle: GuiObject, blocks: {GuiObject}?)
    handle.Active = true
    local dragging = false
    local dragInput
    local dragStart = Vector2.zero
    local startPos = UDim2.fromOffset(0,0)

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- === Criar KScripts GUI ===
local player = Players.LocalPlayer
local parent = player:WaitForChild("PlayerGui")

local root = make("ScreenGui", {Name="KScripts", ResetOnSpawn=false, IgnoreGuiInset=true})
root.Parent = parent

local win = make("Frame", {
    Size = UDim2.fromOffset(400,250),
    Position = UDim2.fromScale(0.3,0.3),
    BackgroundColor3 = Color3.fromRGB(24,24,24),
    Active = true
})
win.Parent = root

local bar = make("Frame", {Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(35,35,35), Active=true})
bar.Parent = win
make("TextLabel", {
    Text="KScripts", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.new(1,1,1),
    BackgroundTransparency=1, Size=UDim2.fromScale(1,1)
}).Parent = bar

local close = make("TextButton", {
    Text="X", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.new(1,1,1),
    BackgroundColor3=Color3.fromRGB(60,60,60), Size=UDim2.fromOffset(24,24),
    Position=UDim2.new(1,-28,0.5,-12)
})
close.Parent = bar

attachDrag(win, bar, {close})

close.MouseButton1Click:Connect(function()
    win.Visible = false
end)

-- === Criar FPS GUI também ===
local fpsWin = FPS.create(parent)

print("✅ KScripts GUI e FPS GUI carregados com sucesso!")
