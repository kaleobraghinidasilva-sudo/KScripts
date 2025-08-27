-- Modules/Five Nights - Hunted/ESP.luau
-- ESP (Highlight-only): Players = Blue, Object-Players (no Humanoid) = Orange
-- Controle de enable/disable é FEITO pela main (sem hotkeys aqui).
-- Expondo API: ESP.create(opts?) -> controller { Enable, Disable, Destroy, IsEnabled, InspectUnderMouse }

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.__index = ESP

-- ================== CONFIG DEFAULTS ==================
local DEFAULTS = {
	Enabled = false,
	MaxDistance = 3000,   -- studs
	UpdateHz = 10,        -- updates per second
	ShowBillboard = false -- labels desativados
}
local COLORS = {
	playerBlue   = Color3.fromRGB(58,130,247),
	objectOrange = Color3.fromRGB(255,165,0),
}
-- ====================================================

-- helpers locais
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

local function createBillboard(adorneePart, maxDistance)
	local attach = Instance.new("Attachment")
	attach.Name = "ESP_Attach"
	attach.Position = Vector3.new(0, (adorneePart.Size.Y * 0.5) + 2, 0)
	attach.Parent = adorneePart

	local bill = Instance.new("BillboardGui")
	bill.Name = "ESP_Billboard"
	bill.Adornee = attach
	bill.Size = UDim2.fromOffset(220, 48)
	bill.AlwaysOnTop = true
	bill.LightInfluence = 0
	bill.MaxDistance = (maxDistance or DEFAULTS.MaxDistance) + 200
	bill.Enabled = false -- nunca mostramos texto

	bill.Parent = Workspace:FindFirstChildOfClass("Camera") or adorneePart
	return bill, attach
end

-- =====================================================

function ESP.create(opts)
	opts = opts or {}
	local self = setmetatable({}, ESP)

	self.Enabled      = false
	self.MaxDistance  = tonumber(opts.MaxDistance) or DEFAULTS.MaxDistance
	self.UpdateHz     = tonumber(opts.UpdateHz) or DEFAULTS.UpdateHz
	self.ShowBillboard= (opts.ShowBillboard == true) and true or false

	self._tracked     = {}   -- [Instance] = { highlight, bill, attach, bestPart, isPlayerChar, ownerPlayer, conns={} }
	self._accum       = 0
	self._conns       = {}   -- conexões gerais (players/workspace/update)
	self._charConns   = {}   -- [Player] = { charAddedConn }
	return self
end

-- limpeza de um alvo
function ESP:_cleanupTrack(inst)
	local t = self._tracked[inst]
	if not t then return end
	if t.conns then
		for _, c in ipairs(t.conns) do pcall(function() c:Disconnect() end) end
	end
	if t.bill then pcall(function() t.bill:Destroy() end) end
	if t.attach then pcall(function() t.attach:Destroy() end) end
	if t.highlight then pcall(function() t.highlight:Destroy() end) end
	self._tracked[inst] = nil
end

function ESP:_trackInstance(inst, ownerPlr, isPlayerChar)
	if self._tracked[inst] then return end
	local bestPart = findBestPart(inst)
	if not bestPart then return end

	local color = isPlayerChar and COLORS.playerBlue or COLORS.objectOrange
	local highlight = createHighlight(inst, color)

	local bill, attach = nil, nil
	if self.ShowBillboard then
		bill, attach = createBillboard(bestPart, self.MaxDistance)
	end

	local tr = {
		highlight = highlight,
		bill      = bill,
		attach    = attach,
		bestPart  = bestPart,
		isPlayerChar = isPlayerChar,
		ownerPlayer  = ownerPlr,
		conns     = {},
	}
	self._tracked[inst] = tr

	-- auto-cleanup
	table.insert(tr.conns, inst.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanupTrack(inst) end
	end))
	if bestPart then
		table.insert(tr.conns, bestPart.AncestryChanged:Connect(function(_, parent)
			if not parent then self:_cleanupTrack(inst) end
		end))
	end
end

-- players
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

-- objetos custom (Attribute "ESP"=true ou Tag "ESP")
function ESP:_considerCustomTarget(inst)
	local isTagged = false
	if inst:GetAttribute("ESP") == true then isTagged = true end
	if not isTagged and CollectionService:HasTag(inst, "ESP") then isTagged = true end
	if isTagged then
		self:_trackInstance(inst, nil, false)
	end
end

-- update por alvo
function ESP:_updateOne(inst, data)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetPart = data.bestPart
	if myRoot and targetPart then
		local dist = (myRoot.Position - targetPart.Position).Magnitude
		local within = dist <= self.MaxDistance
		if data.highlight then data.highlight.Enabled = self.Enabled and within end
		if data.bill then data.bill.Enabled = false end -- nunca usamos labels
	end
	-- reforça cores
	if data.highlight then
		local color = data.isPlayerChar and COLORS.playerBlue or COLORS.objectOrange
		data.highlight.FillColor = color
		data.highlight.OutlineColor = color
	end
end

-- loop
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

-- público
function ESP:Enable()
	if self.Enabled then return end
	self.Enabled = true

	-- Players que já existem
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

	-- Varre workspace atual + listen
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

	-- desconecta listeners gerais
	for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}

	-- desconecta listeners de char
	for plr, pack in pairs(self._charConns) do
		for _,c in ipairs(pack) do pcall(function() c:Disconnect() end) end
		self._charConns[plr] = nil
	end

	-- limpa adornos e tracked
	for inst,_ in pairs(self._tracked) do
		self:_cleanupTrack(inst)
	end
end

function ESP:Destroy()
	self:Disable()
end

-- util opcional (não ligado a tecla aqui)
function ESP:InspectUnderMouse()
	local mouse = LocalPlayer:GetMouse()
	local target = mouse.Target
	if not target then
		print("[ESP Inspect] No target under cursor.")
		return
	end
	local path, node = {}, target
	while node do
		table.insert(path, 1, string.format("%s(%s)", node.Name, node.ClassName))
		node = node.Parent
	end
	print("[ESP Inspect] PATH: " .. table.concat(path, " > "))

	local rootModel = target:FindFirstAncestorOfClass("Model")
	if rootModel then
		local hum = rootModel:FindFirstChildWhichIsA("Humanoid")
		local _, size = rootModel:GetBoundingBox()
		print(("[ESP Inspect] RootModel: %s | Humanoid: %s | BBox: (%.1f, %.1f, %.1f)")
			:format(rootModel:GetFullName(), hum and "yes" or "no", size.X, size.Y, size.Z))
	else
		print(("[ESP Inspect] No ancestor Model. Target is %s (%s)"):format(target.Name, target.ClassName))
	end
end

return ESP