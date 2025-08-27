-- Modules/Settings/fps.luau
-- Mostra FPS atual, mínimo e máximo

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local FPS = {}
FPS.__index = FPS

function FPS.new()
    local self = setmetatable({}, FPS)
    self.Enabled = false
    self.FrameCount = 0
    self.LastTime = os.clock()
    self.CurrentFPS = 0
    self.MinFPS = math.huge
    self.MaxFPS = 0
    self.Gui = nil
    return self
end

function FPS:_createGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(140, 60)
    frame.Position = UDim2.fromOffset(100, 100)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = "FPS: 0"
    label.Parent = frame

    self.Gui = { Screen = screenGui, Label = label }
end

function FPS:Enable()
    if self.Enabled then return end
    self.Enabled = true
    if not self.Gui then self:_createGui() end

    self.Connection = RunService.RenderStepped:Connect(function()
        self.FrameCount += 1
        local now = os.clock()
        if now - self.LastTime >= 1 then
            self.CurrentFPS = self.FrameCount / (now - self.LastTime)
            self.MinFPS = math.min(self.MinFPS, self.CurrentFPS)
            self.MaxFPS = math.max(self.MaxFPS, self.CurrentFPS)
            self.Gui.Label.Text = string.format("FPS: %d\nMin: %d | Max: %d",
                self.CurrentFPS, self.MinFPS, self.MaxFPS)
            self.LastTime = now
            self.FrameCount = 0
        end
    end)
end

function FPS:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    if self.Connection then self.Connection:Disconnect() end
    if self.Gui then self.Gui.Screen:Destroy() end
    self.Gui = nil
end

return FPS