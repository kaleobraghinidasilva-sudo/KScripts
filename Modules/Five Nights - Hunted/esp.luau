-- Modules/Five Nights - Hunted/esp.luau
-- ESP:
-- Azul = Player no avatar normal OU Player sem Humanoid (ex: dentro do armário)
-- Laranja = Player em morph/objeto controlado
-- Laranja = NPCs/objetos sem Player

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.__index = ESP

local DEFAULTS = {
	Enabled = false,
	MaxDistance = 3000,
	UpdateHz = 10,
}
local COLORS = {
	playerBlue   = Color3.fromRGB(58,130,247),
	objectOrange = Color3.fromRGB(255,165,0),
}

-- Helpers
local function findBestPart(model)
	if model:IsA("BasePart") then return model end
	if not model:IsA("Model") then return nil end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	local primary = model.PrimaryPart
	if primary and primary:IsA("BasePart") then return primary end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function createHighlight(adorneeInst, color)
	local h = Instance.new("Highlight")
	h.Name = "ESP_Highlight"
	h.FillColor = color
	h.FillTransparency = 0.75
	h.OutlineColor = color
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adorneeInst
	h.Enabled = true
	h.Parent = Workspace:FindFirstChildOfClass("Camera") or adorneeInst
	return h
end

-- =============================================

function ESP.create(opts)
	opts = opts or {}
	local self = setmetatable({}, ESP)

	self.Enabled      = false
	self.MaxDistance  = tonumber(opts.MaxDistance) or DEFAULTS.MaxDistance
	self.UpdateHz     = tonumber(opts.UpdateHz) or DEFAULTS.UpdateHz

	self._tracked     = {}
	self._accum       = 0
	self._conns       = {}
	self._charConns   = {}
	return self
end

-- Detecta se o Player está em avatar normal
function ESP:_isNormalAvatar(model: Model, plr: Player)
	if plr.Character ~= model then return false end
	local head = model:FindFirstChild("Head")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if head and hrp and humanoid then
		return true
	end
	return false
end

-- Detecta se pertence a um Player (mesmo sem humanoid, ex: armário)
function ESP:_belongsToPlayer(model: Model)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character == model then
			return plr
		end
	end
	return nil
end

function ESP:_cleanupTrack(inst)
	local t = self._tracked[inst]
	if not t then return end
	if t.conns then
		for _, c in ipairs(t.conns) do pcall(function() c:Disconnect() end) end
	end
	if t.highlight then pcall(function() t.highlight:Destroy() end) end
	self._tracked[inst] = nil
end

function ESP:_trackInstance(inst, ownerPlr, isPlayerChar)
	if self._tracked[inst] then return end
	local bestPart = findBestPart(inst)
	if not bestPart then return end

	local color = COLORS.objectOrange -- padrão

	local plr = self:_belongsToPlayer(inst)
	if plr then
		if self:_isNormalAvatar(inst, plr) then
			color = COLORS.playerBlue -- player no avatar normal
		else
			local humanoid = inst:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				color = COLORS.objectOrange -- morph/animatronic controlado
			else
				color = COLORS.playerBlue -- player sem humanoid (ex: armário)
			end
		end
	end

	local highlight = createHighlight(inst, color)

	local tr = {
		highlight = highlight,
		bestPart  = bestPart,
		isPlayerChar = isPlayerChar,
		ownerPlayer  = plr,
		conns     = {},
	}
	self._tracked[inst] = tr

	table.insert(tr.conns, inst.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanupTrack(inst) end
	end))
	if bestPart then
		table.insert(tr.conns, bestPart.AncestryChanged:Connect(function(_, parent)
			if not parent then self:_cleanupTrack(inst) end
		end))
	end
end

function ESP:_trackCharacterForPlayer(plr, char)
	if not char then return end
	self:_trackInstance(char, plr, true)
end

function ESP:_onPlayerAdded(plr)
	if plr.Character then
		self:_trackCharacterForPlayer(plr, plr.Character)
	end
	self._charConns[plr] = {
		plr.CharacterAdded:Connect(function(char)
			self:_trackCharacterForPlayer(plr, char)
		end)
	}
end

function ESP:_considerCustomTarget(inst)
	if inst:GetAttribute("ESP") == true or CollectionService:HasTag(inst, "ESP") then
		self:_trackInstance(inst, nil, false)
	end
end

function ESP:_updateOne(inst, data)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetPart = data.bestPart
	if myRoot and targetPart then
		local dist = (myRoot.Position - targetPart.Position).Magnitude
		local within = dist <= self.MaxDistance
		if data.highlight then data.highlight.Enabled = self.Enabled and within end
	end

	if data.highlight then
		local color = COLORS.objectOrange
		local plr = self:_belongsToPlayer(inst)
		if plr then
			if self:_isNormalAvatar(inst, plr) then
				color = COLORS.playerBlue
			else
				local humanoid = inst:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					color = COLORS.objectOrange -- morph controlado
				else
					color = COLORS.playerBlue -- player sem humanoid (armário)
				end
			end
		end
		data.highlight.FillColor = color
		data.highlight.OutlineColor = color
	end
end

function ESP:_bindUpdate()
	local conn = RunService.Heartbeat:Connect(function(dt)
		self._accum += dt
		if self._accum < (1 / self.UpdateHz) then return end
		self._accum = 0
		for inst, data in pairs(self._tracked) do
			if inst.Parent == nil then
				self:_cleanupTrack(inst)
			else
				self:_updateOne(inst, data)
			end
		end
	end)
	table.insert(self._conns, conn)
end

-- API
function ESP:Enable()
	if self.Enabled then return end
	self.Enabled = true

	for _, plr in ipairs(Players:GetPlayers()) do
		self:_onPlayerAdded(plr)
	end
	table.insert(self._conns, Players.PlayerAdded:Connect(function(plr) self:_onPlayerAdded(plr) end))
	table.insert(self._conns, Players.PlayerRemoving:Connect(function(plr)
		if plr.Character then self:_cleanupTrack(plr.Character) end
		local pack = self._charConns[plr]
		if pack then
			for _,c in ipairs(pack) do pcall(function() c:Disconnect() end) end
			self._charConns[plr] = nil
		end
	end))

	for _, d in ipairs(Workspace:GetDescendants()) do
		self:_considerCustomTarget(d)
	end
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(inst) self:_considerCustomTarget(inst) end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(inst)
		if self._tracked[inst] then self:_cleanupTrack(inst) end
	end))

	self:_bindUpdate()
end

function ESP:Disable()
	if not self.Enabled then return end
	self.Enabled = false

	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}

	for plr, pack in pairs(self._charConns) do
		for _,c in ipairs(pack) do pcall(function() c:Disconnect() end) end
		self._charConns[plr] = nil
	end

	for inst,_ in pairs(self._tracked) do
		self:_cleanupTrack(inst)
	end
end

function ESP:Destroy()
	self:Disable()
end

return ESP