-- Modules/Five Nights - Hunted/showballpit.luau
-- Destaca TUDO que CONTENHA "ball pit" no nome (case-insensitive, _, - e espaços tratados)
-- API:
--   local mod = ShowBallPit.new({ color = Color3.fromRGB(255,0,0), name = "ball pit" })
--   mod:Enable() / mod:Disable() / mod:Destroy()

local Workspace = game:GetService("Workspace")

local ShowBallPit = {}
ShowBallPit.__index = ShowBallPit

-- câmera/parent para o Highlight
local function cameraParent()
	return Workspace.CurrentCamera
		or Workspace:FindFirstChildOfClass("Camera")
		or Workspace
end

-- "  Ball__Pit-Deluxe " -> "ball pit deluxe"
local function normalize(s: string): string
	s = string.lower(s)
	s = s:gsub("[_%-]+", " ")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("%s+", " ")
	return s
end

local function makeHighlight(adornee: Instance, color: Color3)
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

function ShowBallPit.new(opts)
	opts = opts or {}
	local self = setmetatable({}, ShowBallPit)
	self.targetNeedle = normalize(opts.name or "ball pit") -- “agulha” para contains
	self.color        = opts.color or Color3.fromRGB(255, 0, 0)
	self.enabled      = false
	self._tracked     = {}  -- [Instance] = { h=Highlight, conns={} }
	self._conns       = {}  -- conexões globais
	return self
end

function ShowBallPit:_isTarget(inst: Instance): boolean
	if not (inst:IsA("Model") or inst:IsA("BasePart")) then return false end
	local hay = normalize(inst.Name or "")
	-- CONTAINS (não igualdade):
	return hay:find(self.targetNeedle, 1, true) ~= nil
end

function ShowBallPit:_cleanup(inst: Instance)
	local t = self._tracked[inst]
	if not t then return end
	for _,c in ipairs(t.conns or {}) do pcall(function() c:Disconnect() end) end
	if t.h then pcall(function() t.h:Destroy() end) end
	self._tracked[inst] = nil
end

function ShowBallPit:_track(inst: Instance)
	if self._tracked[inst] then return end
	if not self:_isTarget(inst) then return end

	local h = makeHighlight(inst, self.color)
	local conns = {}

	table.insert(conns, inst.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanup(inst) end
	end))

	table.insert(conns, inst:GetPropertyChangedSignal("Name"):Connect(function()
		if not self:_isTarget(inst) then
			self:_cleanup(inst)
		end
	end))

	self._tracked[inst] = { h = h, conns = conns }
end

function ShowBallPit:_consider(inst: Instance)
	if self:_isTarget(inst) then
		self:_track(inst)
	else
		if self._tracked[inst] then self:_cleanup(inst) end
	end
end

function ShowBallPit:Enable()
	if self.enabled then return end
	self.enabled = true

	for _,d in ipairs(Workspace:GetDescendants()) do
		self:_consider(d)
	end
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(i) self:_consider(i) end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(i) if self._tracked[i] then self:_cleanup(i) end end))
end

function ShowBallPit:Disable()
	if not self.enabled then return end
	self.enabled = false
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
	for inst,_ in pairs(self._tracked) do self:_cleanup(inst) end
end

function ShowBallPit:Destroy()
	self:Disable()
end

return ShowBallPit