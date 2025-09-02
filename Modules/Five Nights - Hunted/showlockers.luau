-- Modules/Five Nights - Hunted/showlockers.luau
-- Destaca "New Locker" quando o atributo IsOccupied for true.
-- Tolerante a nome: NewLocker / New Locker / NEW-LOCKER / new_locker etc.
-- API:
--   local m = ShowLockers.new({ color = Color3.fromRGB(58,130,247) })
--   m:Enable() / m:Disable() / m:Destroy()

local Workspace = game:GetService("Workspace")

local ShowLockers = {}
ShowLockers.__index = ShowLockers

local function cameraParent()
	return Workspace.CurrentCamera
		or Workspace:FindFirstChildOfClass("Camera")
		or Workspace
end

-- normaliza nomes: " New__Locker-01 " -> "new locker 01"
local function normalize(s: string): string
	s = string.lower(s)
	s = s:gsub("[_%-]+", " ")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("%s+", " ")
	return s
end

-- decide se um Model é um "New Locker"
local function isNewLockerModel(model: Model): boolean
	local n = normalize(model.Name or "")
	-- aceitamos "new locker" e "newlocker"
	return n:find("new locker", 1, true) ~= nil or n:find("newlocker", 1, true) ~= nil
end

local function makeHighlight(adornee: Instance, color: Color3)
	local h = Instance.new("Highlight")
	h.Name = "KScripts_NewLocker_Occupied"
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = cameraParent()
	return h
end

function ShowLockers.new(opts)
	opts = opts or {}
	local self = setmetatable({}, ShowLockers)
	self.color   = opts.color or Color3.fromRGB(58,130,247) -- azul
	self.enabled = false
	self._tracked = {} -- [Model] = {h=Highlight?, conns={}}
	self._conns   = {} -- conexões globais
	return self
end

-- cria/remove highlight conforme IsOccupied
function ShowLockers:_apply(model: Model)
	local occupied = model:GetAttribute("IsOccupied") == true
	local t = self._tracked[model]
	if occupied then
		if not (t and t.h) then
			-- cria ou repõe highlight
			self:_ensureTracked(model)
			t = self._tracked[model]
			t.h = makeHighlight(model, self.color)
		end
	else
		if t and t.h then
			pcall(function() t.h:Destroy() end)
			t.h = nil
		end
	end
end

function ShowLockers:_ensureTracked(model: Model)
	if self._tracked[model] then return end
	local conns = {}

	-- sair do mundo
	table.insert(conns, model.AncestryChanged:Connect(function(_, parent)
		if not parent then self:_cleanup(model) end
	end))

	-- renomeou e deixou de ser "New Locker" → limpar tudo
	table.insert(conns, model:GetPropertyChangedSignal("Name"):Connect(function()
		if not isNewLockerModel(model) then
			self:_cleanup(model)
		end
	end))

	-- atributo mudou → reaplicar
	table.insert(conns, model:GetAttributeChangedSignal("IsOccupied"):Connect(function()
		self:_apply(model)
	end))

	self._tracked[model] = { h=nil, conns=conns }
end

function ShowLockers:_cleanup(model: Model)
	local t = self._tracked[model]
	if not t then return end
	for _,c in ipairs(t.conns or {}) do pcall(function() c:Disconnect() end) end
	if t.h then pcall(function() t.h:Destroy() end) end
	self._tracked[model] = nil
end

function ShowLockers:_consider(inst: Instance)
	-- só nos interessa o Model (o atributo está no Model)
	local model = inst
	if not model:IsA("Model") then
		model = inst:FindFirstAncestorOfClass("Model")
	end
	if not model or not model:IsA("Model") then return end
	if not isNewLockerModel(model) then return end

	self:_ensureTracked(model)
	self:_apply(model)
end

function ShowLockers:Enable()
	if self.enabled then return end
	self.enabled = true

	-- varredura inicial
	for _, d in ipairs(Workspace:GetDescendants()) do
		self:_consider(d)
	end
	-- dinâmico
	table.insert(self._conns, Workspace.DescendantAdded:Connect(function(i) self:_consider(i) end))
	table.insert(self._conns, Workspace.DescendantRemoving:Connect(function(i)
		if i:IsA("Model") and self._tracked[i] then
			self:_cleanup(i)
		end
	end))
end

function ShowLockers:Disable()
	if not self.enabled then return end
	self.enabled = false

	for _,c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
	self._conns = {}

	for m,_ in pairs(self._tracked) do
		self:_cleanup(m)
	end
end

function ShowLockers:Destroy()
	self:Disable()
end

return ShowLockers