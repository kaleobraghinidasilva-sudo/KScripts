-- main.luau
-- KScripts GUI (layout original) + requireRemote (para Solara)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")

-- Função para requerer módulos direto do GitHub
local function requireRemote(path)
    local url = "https://raw.githubusercontent.com/kaleobraghinidasilva-sudo/KScripts/main/" .. path
    local src = game:HttpGet(url)
    return loadstring(src)()
end

-- Carregar módulos
local FPSModule = requireRemote("Modules/Settings/fps.luau")
local WalkspeedModule = requireRemote("Modules/Universal/walkspeed.luau")
local ESPModule = requireRemote("Modules/Five Nights - Hunted/esp.luau")

-- GUI principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KScripts"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(760, 460)
mainFrame.Position = UDim2.fromScale(0.18, 0.22)
mainFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
topBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "KScripts"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(44,44)
closeBtn.Position = UDim2.new(1, -44, 0, 0)
closeBtn.Text = "X"
closeBtn.Parent = topBar

local sideMenu = Instance.new("ScrollingFrame")
sideMenu.Size = UDim2.new(0, 180, 1, -44)
sideMenu.Position = UDim2.new(0,0,0,44)
sideMenu.CanvasSize = UDim2.new(0,0,0,0)
sideMenu.ScrollBarThickness = 6
sideMenu.BackgroundColor3 = Color3.fromRGB(35,35,35)
sideMenu.Parent = mainFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, -180, 1, -44)
contentFrame.Position = UDim2.new(0, 180, 0, 44)
contentFrame.CanvasSize = UDim2.new(0,0,0,0)
contentFrame.ScrollBarThickness = 6
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Sections
local sections = {
    { Name = "Universal" },
    { Name = "Five Nights: Hunted" },
    { Name = "Settings" },
}

local buttons = {}
for _, section in ipairs(sections) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, (#buttons)*45 + 5)
    btn.Text = section.Name
    btn.Parent = sideMenu
    table.insert(buttons, btn)

    btn.MouseButton1Click:Connect(function()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end

        -- UNIVERSAL → Walkspeed
        if section.Name == "Universal" then
            local wsFrame = Instance.new("Frame")
            wsFrame.Size = UDim2.new(1, -10, 0, 100)
            wsFrame.BackgroundTransparency = 1
            wsFrame.Parent = contentFrame

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(0.5, 0, 0, 30)
            desc.BackgroundTransparency = 1
            desc.Text = "Walkspeed"
            desc.TextColor3 = Color3.new(1,1,1)
            desc.Font = Enum.Font.SourceSansBold
            desc.TextSize = 18
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = wsFrame

            local keyButton = Instance.new("TextButton")
            keyButton.Size = UDim2.new(0, 80, 0, 28)
            keyButton.Position = UDim2.new(0, 200, 0, 0)
            keyButton.Text = "Key: LShift"
            keyButton.Parent = wsFrame

            local baseBox = Instance.new("TextBox")
            baseBox.Size = UDim2.new(0, 50, 0, 28)
            baseBox.Position = UDim2.new(0, 200, 0, 35)
            baseBox.Text = "16"
            baseBox.PlaceholderText = "Base"
            baseBox.Parent = wsFrame

            local boostBox = Instance.new("TextBox")
            boostBox.Size = UDim2.new(0, 50, 0, 28)
            boostBox.Position = UDim2.new(0, 260, 0, 35)
            boostBox.Text = "32"
            boostBox.PlaceholderText = "Boost"
            boostBox.Parent = wsFrame

            local Walkspeed = WalkspeedModule.new()
            Walkspeed:Enable()

            keyButton.MouseButton1Click:Connect(function()
                keyButton.Text = "Press key..."
                local conn
                conn = UIS.InputBegan:Connect(function(input, gp)
                    if not gp and input.KeyCode ~= Enum.KeyCode.Unknown then
                        Walkspeed:SetKey(input.KeyCode)
                        keyButton.Text = "Key: " .. input.KeyCode.Name
                        conn:Disconnect()
                    end
                end)
            end)

            local function updateSpeeds()
                local base = tonumber(baseBox.Text) or 16
                local boost = tonumber(boostBox.Text) or 32
                Walkspeed:SetSpeeds(base, boost)
            end
            baseBox.FocusLost:Connect(updateSpeeds)
            boostBox.FocusLost:Connect(updateSpeeds)
        end

        -- FIVE NIGHTS → ESP
        if section.Name == "Five Nights: Hunted" then
            local espFrame = Instance.new("Frame")
            espFrame.Size = UDim2.new(1, -10, 0, 60)
            espFrame.BackgroundTransparency = 1
            espFrame.Parent = contentFrame

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(0.5, 0, 1, 0)
            desc.BackgroundTransparency = 1
            desc.Text = "ESP"
            desc.TextColor3 = Color3.new(1,1,1)
            desc.Font = Enum.Font.SourceSansBold
            desc.TextSize = 18
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = espFrame

            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 80, 0, 28)
            toggle.Position = UDim2.new(0, 200, 0, 0)
            toggle.Text = "OFF"
            toggle.Parent = espFrame

            local esp = ESPModule.create()
            toggle.MouseButton1Click:Connect(function()
                if esp.Enabled then
                    esp:Disable()
                    toggle.Text = "OFF"
                else
                    esp:Enable()
                    toggle.Text = "ON"
                end
            end)
        end

        -- SETTINGS → FPS
        if section.Name == "Settings" then
            local fpsFrame = Instance.new("Frame")
            fpsFrame.Size = UDim2.new(1, -10, 0, 60)
            fpsFrame.BackgroundTransparency = 1
            fpsFrame.Parent = contentFrame

            local desc = Instance.new("TextLabel")
            desc.Size = UDim2.new(0.5, 0, 1, 0)
            desc.BackgroundTransparency = 1
            desc.Text = "Show FPS"
            desc.TextColor3 = Color3.new(1,1,1)
            desc.Font = Enum.Font.SourceSansBold
            desc.TextSize = 18
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Parent = fpsFrame

            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 80, 0, 28)
            toggle.Position = UDim2.new(0, 200, 0, 0)
            toggle.Text = "OFF"
            toggle.Parent = fpsFrame

            local fps = FPSModule.new()
            toggle.MouseButton1Click:Connect(function()
                if fps.Enabled then
                    fps:Disable()
                    toggle.Text = "OFF"
                else
                    fps:Enable()
                    toggle.Text = "ON"
                end
            end)
        end
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)