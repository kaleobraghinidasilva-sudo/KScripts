-- Modules/Five Nights - Hunted/showcomputer.luau
-- Destaca TODOS os objetos chamados "Computer"/"computer" (case-insensitive), sem limite de distância.
-- API: local mod = ShowComputer.new({color = Color3.fromRGB(0,255,0), name = "computer"}); mod:Enable(); mod:Disable(); mod:Destroy()

local Workspace = game:GetService("Workspace")

local ShowComputer = {}
ShowComputer.__index = ShowComputer

local function cameraParent()
	return Workspace.CurrentCamera
		or Workspace:FindFirstChildOfClass("Camera")
		or Workspace
end

function ShowComputer.new(opts)
	opts = opts or {}
	local self = setmetatable({}, ShowComputer)
	self.Enabled = false
	self._tracked = {}  -- [Instance] = {h=Highlight, conns={...}}
	self._conns = {}    -- conexões globais (added/removing)

	self.targetLower = string.lower(opts.name or "computer")
	self.color = opts.color or Color3.fromRGB(0,255,0)

	return self
end

function ShowComputer:_isTarget(inst: Instance): boolean
	if typeof(inst.Name) ~= "string" then return false end
	local n = string.lower(inst.Name)
	if n ~= self.targetLower then return false end
	return inst:IsA("Model") or inst:IsA("BasePart")
end

function ShowComputer:_cleanup(inst: Instance)
	local t = self._tracked[inst]
	if not t then return end
	for _,c in ipairs(t.conns or {}) do pcall(function() c:Disconnect() end) end
	if t.h then pcall(function() t.h:Destroy() end) end
	self._tracked[inst] = nil
end

function ShowComputer:_createHighlight(adornee: Instance): Highlight
	local h = Instance.new("Highlight")
	h.Name = "KScripts_ShowComputer"
	h.FillColor = self.color
	h.OutlineColor = self.color
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = cameraParent()
	return h
end

function ShowComputer:_track(inst: Instance)
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

function ShowComputer:_consider(inst: Instance)
	if self:_isTarget(inst) then
		self:_track(inst)
	else
		if self._tracked[inst] then self:_cleanup(inst) end
	end
end

function ShowComputer:Enable()
	if self.Enabled then return end
	self.Enabled = true

	-- varredura inicial
	for _,d in ipairs(Workspace:GetDescendants()) do
		self:_consider(d)
	end

	-- dinâmico
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(inst)
		self:_consider(inst)
	end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(inst)
		self:_cleanup(inst)
	end))
end

function ShowComputer:Disable()
	if not self.Enabled then return end
	self.Enabled = false
	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}
	for inst,_ in pairs(self._tracked) do
		self:_cleanup(inst)
	end
end

function ShowComputer:Destroy()
	self:Disable()
end

return ShowComputer