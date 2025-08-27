-- fps.luau
-- Módulo FPS GUI (arrastável + mostra FPS atual/min/max)

-- criação do módulo FPS com contador básico
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local FPS = {}
FPS.__index = FPS

local BASE = Vector2.new(180,84)
local HEADER_H = 20
local C_PANEL = Color3.fromRGB(35,35,35)
local C_TEXT  = Color3.fromRGB(235,235,235)
local C_MUTED = Color3.fromRGB(160,160,160)

local function make(class, props, kids)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(kids or {}) do c.Parent = o end
    return o
end

-- correção: problema do salto da janela FPS ao arrastar
local function attachDrag(frame: Frame, handle: GuiObject)
    handle.Active = true
    local dragging, dragInput = false, nil
    local dragStart, startPos = Vector2.zero, UDim2.fromOffset(0,0)

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
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)
end

-- adição: min/max no contador de FPS
function FPS.create(parent: Instance)
    local win = make("Frame", {
        Size = UDim2.fromOffset(BASE.X, BASE.Y),
        Position = UDim2.fromOffset(500,200),
        BackgroundColor3 = C_PANEL,
        Active = true
    })
    win.Parent = parent

    local header = make("Frame", {
        Size = UDim2.new(1,0,0,HEADER_H),
        BackgroundColor3 = Color3.fromRGB(50,50,50),
        Active = true
    })
    header.Parent = win

    make("TextLabel", {
        Text="FPS", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C_TEXT,
        BackgroundTransparency=1, Size=UDim2.fromScale(1,1)
    }).Parent = header

    local lblNow = make("TextLabel", {
        Text="FPS: 0", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C_TEXT,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,24),
        Position=UDim2.fromOffset(6,HEADER_H+2),
        TextXAlignment=Enum.TextXAlignment.Left
    })
    lblNow.Parent = win

    local lblMinMax = make("TextLabel", {
        Text="Min: 0 | Max: 0", Font=Enum.Font.Gotham, TextSize=14, TextColor3=C_MUTED,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,22),
        Position=UDim2.fromOffset(6,HEADER_H+28),
        TextXAlignment=Enum.TextXAlignment.Left
    })
    lblMinMax.Parent = win

    attachDrag(win, header)

    local minF, maxF = math.huge, 0
    RunService.RenderStepped:Connect(function(dt)
        local fps = math.floor(1/dt + 0.5)
        minF = math.min(minF, fps)
        maxF = math.max(maxF, fps)
        lblNow.Text = "FPS: " .. fps
        lblMinMax.Text = ("Min: %d | Max: %d"):format(minF == math.huge and 0 or minF, maxF)
    end)

    return win
end

return FPS