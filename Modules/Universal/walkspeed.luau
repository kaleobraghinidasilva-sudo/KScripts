-- Walkspeed Module

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local M = {}
M.__index = M

function M.new()
	return setmetatable({
		enabled = true,
		baseSpeed = 16,
		boostSpeed = 32,
		key = Enum.KeyCode.LeftShift,
		conn = nil,
	}, M)
end

function M:SetSpeeds(base:number, boost:number)
	self.baseSpeed = base
	self.boostSpeed = boost
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = self.baseSpeed end
end

function M:SetKey(key:Enum.KeyCode?)
	if self.conn then self.conn:Disconnect() self.conn=nil end
	self.key = key
	if not key then return end
	self.conn = UIS.InputBegan:Connect(function(input,gp)
		if not gp and input.KeyCode==self.key then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = self.boostSpeed end
		end
	end)
	UIS.InputEnded:Connect(function(input,gp)
		if not gp and input.KeyCode==self.key then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = self.baseSpeed end
		end
	end)
end

function M:Enable()
	self:SetSpeeds(self.baseSpeed, self.boostSpeed)
	self:SetKey(self.key)
end

function M:Disable()
	if self.conn then self.conn:Disconnect() end
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 16 end
end

return M