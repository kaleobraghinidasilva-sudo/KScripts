-- Modules/Five Nights - Hunted/showballpit.luau
-- Destaca TUDO que se chama "Ball Pit" (case/spacing/underscore/hífen tolerantes)
-- API: local mod = M.new({ color = Color3.fromRGB(255,0,0), name = "ball pit" })
--      mod:Enable() / mod:Disable() / mod:Destroy()

local Workspace = game:GetService("Workspace")

local M = {}
M.__index = M

-- util: câmera para parent do Highlight
local function cameraParent()
	return Workspace.CurrentCamera
		or Workspace:FindFirstChildOfClass("Camera")
		or Workspace
end

-- util: normalização de nome (" Ball__Pit  " -> "ball pit")
local function normalize(s: string): string
	s = string.lower(s)
	-- troca underscores e hífens por espaço
	s = s:gsub("[_%-]+", " ")
	-- tira espaços na ponta
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	-- colapsa múltiplos espaços
	s = s:gsub("%s+", " ")
	return s
end

local function creatHighlight(adornee: Instance, color: Color3)
	local h = Instance.new("Highlight")
	h.Name = "KScripts_BallPit_Highlight"
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = cameraParent()
	return h
end

function M.new(opts)
	opts = opts or {}
	local self = setmetatable({}, M)
	self.targetName = normalize(opts.name or "ball pit")
	self.color      = opts.color or Color3.fromRGB(255,0,0)
	self.enabled    = false
	self._tracked   = {}   -- [Instance] = {h=Highlight, conns={...}}
	self._conns     = {}   -- conexões globais (added/removed)
	return self
end

-- checa se o Instance é um target válido
function M:_isTarget(inst: Instance): boolean
	if not (inst:IsA("Model") or inst:IsA("BasePart")) then
		return false
	end
	local n = normalize(inst.Name or "")
	return (n == self.targetName)
end

function M:_cleanup(inst: Instance)
	local t = self._tracked[inst]
	if not t then return end
	for _,c in ipairs(t.conns or {}) do
		pcall(function() c:Disconnect() end)
	end
	if t.h then pcall(function() t.h:Destroy() end) end
	self._tracked[inst] = nil
end

function M:_track(inst: Instance)
	if self._tracked[inst] then return end
	if not self:_isTarget(inst) then return end

	local h = creatHighlight(inst, self.color)
	local conns = {}

	-- soltar quando sair do workspace
	table.insert(conns, inst.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanup(inst) end
	end))

	-- se renomear e deixar de ser alvo -> remover
	table.insert(conns, inst:GetPropertyChangedSignal("Name"):Connect(function()
		if not self:_isTarget(inst) then
			self:_cleanup(inst)
		end
	end))

	self._tracked[inst] = { h = h, conns = conns }
end

function M:_consider(inst: Instance)
	if self:_isTarget(inst) then
		self:_track(inst)
	else
		-- se já estava e deixou de ser alvo
		if self._tracked[inst] then
			self:_cleanup(inst)
		end
	end
end

function M:Enable()
	if self.enabled then return end
	self.enabled = true

	-- inicial: varrer todos
	for _, d in ipairs(Workspace:GetDescendants()) do
		self:_consider(d)
	end

	-- dinâmico
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(inst)
		self:_consider(inst)
	end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(inst)
		if self._tracked[inst] then
			self:_cleanup(inst)
		end
	end))
end

function M:Disable()
	if not self.enabled then return end
	self.enabled = false

	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}

	for inst,_ in pairs(self._tracked) do
		self:_cleanup(inst)
	end
end

function M:Destroy()
	self:Disable()
end

return ShowBallPit