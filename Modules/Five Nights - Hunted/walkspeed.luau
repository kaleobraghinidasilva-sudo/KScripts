-- Modules/Five Nights - Hunted/walkspeed.luau
-- Walkspeed com tecla dinâmica + base/boost configuráveis

local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local M = {}
M.__index = M

function M.new()
	return setmetatable({
		baseSpeed  = 16,
		boostSpeed = 32,
		key        = Enum.KeyCode.LeftShift,
		_beginConn = nil,
		_endConn   = nil,
	}, M)
end

function M:_bind()
	self:_unbind()
	if not self.key then return end

	self._beginConn = UIS.InputBegan:Connect(function(input,gp)
		if gp then return end
		if input.KeyCode == self.key then
			local char = LocalPlayer.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = self.boostSpeed end
		end
	end)

	self._endConn = UIS.InputEnded:Connect(function(input,gp)
		if gp then return end
		if input.KeyCode == self.key then
			local char = LocalPlayer.Character
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = self.baseSpeed end
		end
	end)
end

function M:_unbind()
	if self._beginConn then self._beginConn:Disconnect() self._beginConn = nil end
	if self._endConn   then self._endConn:Disconnect()   self._endConn   = nil end
end

function M:SetSpeeds(base:number, boost:number)
	self.baseSpeed  = base
	self.boostSpeed = boost
	-- atualiza a velocidade base imediatamente
	local char = LocalPlayer.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = self.baseSpeed end
end

function M:SetKey(key: Enum.KeyCode?)
	self.key = key
	self:_bind()
end

function M:Enable()
	-- garantir valor base aplicado
	self:SetSpeeds(self.baseSpeed, self.boostSpeed)
	self:_bind()
end

function M:Disable()
	self:_unbind()
	local char = LocalPlayer.Character
	local hum  = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16 end -- padrão Roblox
end

return M