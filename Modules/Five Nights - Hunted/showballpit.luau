-- Modules/Five Nights - Hunted/showballpit.luau
-- Destaca TODOS os objetos chamados "Ball Pit"/"ball pit" (case-insensitive), sem limite de distância (vermelho).

local Workspace = game:GetService("Workspace")

local ShowBallPit = {}
ShowBallPit.__index = ShowBallPit

local function cameraParent()
	return Workspace.CurrentCamera
		or Workspace:FindFirstChildOfClass("Camera")
		or Workspace
end

function ShowBallPit.new(opts)
	opts = opts or {}
	local self = setmetatable({}, ShowBallPit)
	self.Enabled   = false
	self._tracked  = {}  -- [Instance] = {h=Highlight, conns={...}}
	self._conns    = {}  -- conexões globais

	self.targetLower = string.lower(opts.name or "ball pit")
	self.color = opts.color or Color3.fromRGB(255, 0, 0) -- vermelho

	return self
end

function ShowBallPit:_isTarget(inst: Instance): boolean
	if typeof(inst.Name) ~= "string" then return false end
	local n = string.lower(inst.Name)
	if n ~= self.targetLower then return false end
	return inst:IsA("Model") or inst:IsA("BasePart")
end

function ShowBallPit:_cleanup(inst: Instance)
	local t = self._tracked[inst]
	if not t then return end
	for _,c in ipairs(t.conns or {}) do pcall(function() c:Disconnect() end) end
	if t.h then pcall(function() t.h:Destroy() end) end
	self._tracked[inst] = nil
end

function ShowBallPit:_createHighlight(adornee: Instance): Highlight
	local h = Instance.new("Highlight")
	h.Name = "KScripts_ShowBallPit"
	h.FillColor = self.color
	h.OutlineColor = self.color
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = cameraParent()
	return h
end

function ShowBallPit:_track(inst: Instance)
	if self._tracked[inst] then return end
	if not self:_isTarget(inst) then return end

	local h = self:_createHighlight(inst)
	local conns = {}
	table.insert(conns, inst.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanup(inst) end
	end))
	table.insert(conns, inst:GetPropertyChangedSignal("Name"):Connect(function()
		if not self:_isTarget(inst) then self:_cleanup(inst) end
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
	if self.Enabled then return end
	self.Enabled = true

	for _,d in ipairs(Workspace:GetDescendants()) do
		self:_consider(d)
	end
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(inst)
		self:_consider(inst)
	end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(inst)
		self:_cleanup(inst)
	end))
end

function ShowBallPit:Disable()
	if not self.Enabled then return end
	self.Enabled = false

	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}

	for inst,_ in pairs(self._tracked) do
		self:_cleanup(inst)
	end
end

function ShowBallPit:Destroy()
	self:Disable()
end

return ShowBallPit