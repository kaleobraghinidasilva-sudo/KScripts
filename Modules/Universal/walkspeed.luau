-- Modules/Universal/walkspeed.luau
-- Controla WalkSpeed com toggle via tecla configurável

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Walkspeed = {}
Walkspeed.__index = Walkspeed

function Walkspeed.new()
    local self = setmetatable({}, Walkspeed)
    self.Enabled = false
    self.ToggleKey = Enum.KeyCode.LeftShift -- tecla padrão
    self.BaseSpeed = 16
    self.BoostSpeed = 32
    self._conn = nil
    return self
end

function Walkspeed:Apply(speed)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = speed
    end
end

function Walkspeed:SetKey(keyCode)
    self.ToggleKey = keyCode
end

function Walkspeed:SetSpeeds(base, boost)
    self.BaseSpeed = base
    self.BoostSpeed = boost
    self:Apply(self.BaseSpeed)
end

function Walkspeed:Enable()
    if self._conn then self._conn:Disconnect() end
    self._conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            self.Enabled = not self.Enabled
            if self.Enabled then
                self:Apply(self.BoostSpeed)
            else
                self:Apply(self.BaseSpeed)
            end
        end
    end)
    self:Apply(self.BaseSpeed)
end

function Walkspeed:Disable()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    self:Apply(self.BaseSpeed)
end

return Walkspeed