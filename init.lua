local ADDON, ns = ...
local oUF = ns.oUF or oUF

local path = "Interface\\AddOns\\"..ADDON.."\\Media\\"
ns.statusbars = { }

local defaults = {
	indicator_size 	= 8,
	buff_size 		= 15,
	debuff_size 	= 19,

	statusbarNAME 			= "Hal M",
	overlaybarNAME 			= "Flat",
	fonttextNAME 			= "Expressway Free",

	absorbtexture 			= path..'absorbTexture',
	absorbtextureInverted 	= path..'absorbTextureInverted', 
	absorbspark 			= path..'absorbSpark',
	bordertexture 	= path.."textureNormal",
	bordershadow 	= path.."textureShadow",
	borderglow 		= path.."textureGlow",
	backdrop_alpha 	= 0.9,

	fonttext_size 	= 13,
	health_format 	= 1, 

	bars_vertical 		= true,
	healthbar_mult 		= 0.8, 
	healthbar_bgmult 	= 0.33, 

	powerbar_enable 	= true,
	powerbar_height 	= 4,
	powerbar_mult 		= 0.9,
	powerbar_bgmult 	= 0.3,

	threat_threshold 	= 3, 	
	show_debuffborder 	= true, -- Color the border after debuff type even if you cant dispel it


	-- visibility options
	showSolo 		= false,
	showInParty 	= false,

	grow_vertical 	= false, 	
	grow_anchor 	= "TOPLEFT", 
	frame_spacing 	= 8,
	group_spacing 	= 10,

	layouts = {
		["raid40"] 	= { width = 50, height = 40, scale = 1},
		["raid25"] 	= { width = 80, height = 40, scale = 1},
		["raid10"] 	= { width = 80, height = 40, scale = 1},
		["party"] 	= { width = 80, height = 40, scale = 1},
	},

	position = {"TOPLEFT", "UIParent", "TOPLEFT", 15, -15 }, --Can be changed ingame

}

ns.WhiteList = { 
	[871	] = true, --shield-wall
	[114030	] = true, --vigilance

	[33206	] = true, --pain-suppression
	[47788	] = true, --guardian-spirit

	[1022	] = true, --hand-of-protection
	[498	] = true, --divine-protection
	[6940	] = true, --hand-of-sacrifice

	[115176	] = true, --zen-meditation
	[115295	] = true, --guard
	[115203	] = true, --fortifying-brew
	[116849	] = true, --life-cocoon

	[61336	] = true, --survival-instincts
	[102342	] = true, --ironbark

	[48707	] = true, --anti-magic-shell
	[48792	] = true, --icebound-fortitude
	[155835	] = true, --bristling-fur
}

ns.IndicatorList = {
	ALL = {
		{ ind = 'topright', id = 20707,		onlyOwn = false,	showcd = false,	color = {0.7, 0, 1} }, -- Soulstone
	},
	DRUID = {
		{ ind = "top", 		id = 774, 		onlyOwn = true, 	showcd = true,	color = {1, 0.2, 1}	}, -- rejuvination 
		{ ind = "topl", 	id = 48438,		onlyOwn = true,  	showcd = true,	color = {0.60, 0.20, 0.80 } }, --"Wild Growth"
		{ ind = "topr", 	id = 33763,		onlyOwn = true,  	showcd = true,	color = { 0.00, 0.90, 0.00 } },
		{ ind = "topright", id = 8936, 		onlyOwn = true, 	showcd = true,	color = { 0, 0.4, 0.9 } }, --"Regrowth"
	},
	MONK = {
	    { ind = 'top', 		id = 119611,	onlyOwn = true,		showcd = true,	color = {0, 1, 0}}, -- Renewing Mist
	    { ind = 'topr', 	id = 124682,	onlyOwn = true,		showcd = true,	color = {0.15, 0.98, 0.64}}, -- Enveloping Mist
	    { ind = 'topl', 	id = 115175,	onlyOwn = true,		showcd = true,	color = {0.15, 0.98, 0.64}}, -- Soothing Mist
	    { ind = 'topright', id = 124081,	onlyOwn = true,		showcd = true,	color = {0.7, 0.8, 1}}, -- Zen Sphere
	},
	PALADIN = {
	    { ind = 'topl', 	id = 53563,		onlyOwn = true,		showcd = true,	color = {0, 1, 0}}, -- Beacon of Light
	    { ind = 'topr', 	id = 20925,		onlyOwn = true,		showcd = true,	color = {1, 1, 0}}, -- Sacred Shield
	},
	PRIEST = {
	    { ind = 'top', 		id = 6788, 		onlyOwn = true,		showcd = true,	color = {0.6, 0, 0} }, -- Weakened Soul
	    { ind = 'topl', 	id = 17, 		onlyOwn = true,		showcd = true,	color = {1, 1, 0} }, -- Power Word: Shield
	    { ind = 'topr', 	id = 33076,		onlyOwn = false,	showcd = true,	color = {1, 0.6, 0.6} }, -- Prayer of Mending
	    { ind = 'topright', id = 139, 		onlyOwn = true,		showcd = true,	color = {0, 1, 0} }, -- Renew
	},
	SHAMAN = {
	    { ind = 'top', 		id = 61295,		onlyOwn = true,		showcd = true,	color = {0.7, 0.3, 0.7} }, -- Riptide
	    { ind = 'topl', 	id = 974, 		onlyOwn = true,		showcd = true,	color = {0.7, 0.4, 0} }, -- Earth Shield
	},
}

ns.config = defaults
local colors = oUF.colors
colors.charmed = colors.charmed or {1, 0, 0.4}
colors.debuff = {
	["Curse"] = { 0.8, 0, 1 },
	["Disease"] = { 0.8, 0.6, 0 },
	["Magic"] = { 0, 0.8, 1 },
	["Poison"] = { 0, 0.8, 0 },
}
colors.threat = colors.threat or {}
for i = 1, 3 do
	local r, g, b = GetThreatStatusColor(i)
	colors.threat[i] = { r, g, b }
end

local addon = CreateFrame("Frame", 'oUF_AbuRaid')
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("SPELLS_CHANGED")
addon:SetScript("OnEvent", function(self, event, ...)
	if (event == "ADDON_LOADED") then
		local addonname = ...
		if (addonname ~= ADDON) then return; end
		self:OnInitialize(event, ...)
	elseif (event == "SPELLS_CHANGED") then
		self:UpdateDispelTypes()
	elseif (event == "GROUP_ROSTER_UPDATE") or (event == "PLAYER_REGEN_ENABLED") then
		self:UpdateRaidLayout(event)
	elseif (event == "PLAYER_REGEN_DISABLED") then
		self:LockAnchors()
	end
end)

function addon:OnInitialize(event, ...)
	self.config = ns.config

	-- Load the LibSharedMedia files
	local SharedMedia = LibStub("LibSharedMedia-3.0")
	SharedMedia:Register("font", 		"Expressway Free",  path.."fontSmall.ttf")
	SharedMedia:Register("font", 		"Expressway RG",    path.."fontThick.ttf")
	SharedMedia:Register("statusbar", 	"Hal G", 			path.."HalH.tga")
	SharedMedia:Register("statusbar", 	"Hal M", 			path.."HalM.tga")

	self.config.statusbar = SharedMedia:Fetch("statusbar", self.config.statusbarNAME)
	self.config.overlaybar = SharedMedia:Fetch("statusbar", self.config.overlaybarNAME)
	self.config.fonttext = SharedMedia:Fetch("font", self.config.fonttextNAME)

	if not oUF_AbuRaid_Settings then 
		_G.oUF_AbuRaid_Settings = {} 
	end
	if not oUF_AbuRaid_Settings.position then
		oUF_AbuRaid_Settings['position'] = defaults.position
	end
	self.config['position'] = oUF_AbuRaid_Settings.position

	-- KILLKILLKILL
	CompactRaidFrameManager.Show = CompactRaidFrameManager.Hide
	CompactRaidFrameManager:UnregisterAllEvents()
	CompactRaidFrameManager:Hide()

	CompactRaidFrameContainer.Show = CompactRaidFrameContainer.Hide
	CompactRaidFrameContainer:UnregisterAllEvents()
	CompactRaidFrameContainer:Hide()
	
	self:UpdateDispelTypes()
	self:UpdateRaidLayout(event)
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

-- Figure out anchors etc. never again
local getFramePoints, getHeaderPoints 
do
	function getFramePoints(growVertical, growAnchor, frameSpacing)
		local offset_x, offset_y, point = 0, 0

		if (growVertical) then
			if (growAnchor:find("LEFT")) then
				point = "LEFT"
				offset_x = 1
			else
				point = "RIGHT"
				offset_x = -1
			end
		else
			if (growAnchor:find("BOTTOM")) then
				point = "BOTTOM"
				offset_y = 1
			else
				point = "TOP"
				offset_y = -1
			end
		end
		return offset_x*frameSpacing, offset_y*frameSpacing, point
	end

	local pointTable = {
		["TOPLEFT"] = { "TOPRIGHT", "BOTTOMLEFT" },
		["TOPRIGHT"] = { "TOPLEFT", "BOTTOMRIGHT" },
		["BOTTOMLEFT"] = { "BOTTOMRIGHT", "TOPLEFT" },
		["BOTTOMRIGHT"] = { "BOTTOMLEFT", "TOPRIGHT" },
	}
	function getHeaderPoints(growVertical, growAnchor, groupSpacing)
		local header_offset_x, header_offset_y, header_relPoint = 0, 0
		if (growVertical) then
			header_relPoint = pointTable[growAnchor][2]
			if (growAnchor:find("BOTTOM")) then
				header_offset_y = 1
			else
				header_offset_y = -1
			end
		else
			header_relPoint = pointTable[growAnchor][1]
			if (growAnchor:find("LEFT")) then
				header_offset_x = 1
			else
				header_offset_x = -1
			end
		end
		return header_offset_x*groupSpacing, header_offset_y*groupSpacing, header_relPoint
	end
end

function addon:CreateHeaders(width, height, scale)
	oUF:SetActiveStyle("oUF_AbuRaid")
	self.headers = { }

	for i = 1, NUM_RAID_GROUPS do
		local header = oUF:SpawnHeader("oUF_AbuRaid"..i, nil, nil,
			"showPlayer", true,
			'showParty', true,
			'showRaid', true,
			'showSolo', true,
			
			"oUF-initialConfigFunction", [[
				local unit = ...
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('initial-width'))
				self:SetHeight(header:GetAttribute('initial-height'))
				self:SetScale(header:GetAttribute('initial-scale'))
			]],

			"sortMethod", "INDEX",
			"groupBy", "GROUP",
			"groupingOrder", "1,2,3,4,5,6,7,8",

			"initial-width", width,
			"initial-height", height,
			"initial-scale", scale,
			"unitsPerColumn", 5
		)
		--header:Show()
		self.headers[i] = header
	end
end

local function getRaidLayout()
	local groupSize = GetNumGroupMembers()
	local numGroups = 0
	for i = 1, groupSize do
		local _, _, group = GetRaidRosterInfo(i)
		-- doesnt account for empty groups
		numGroups = group > numGroups and group or numGroups
	end
	if (numGroups > 5) then
		return "raid40"
	elseif (numGroups > 2) then
		return "raid25"
	elseif (numGroups > 1) then
		return "raid10"
	end
	return "party" -- or solo
end

function addon:UpdateRaidLayout(event)
	local layout = getRaidLayout()
	if (event ~= 'ForceUpdate') and self.loadedLayout == layout then return; end

	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent(event)
	end
	if (InCombatLockdown()) then
		return self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	local data = self.config.layouts[layout]
	local grow_vertical, grow_anchor = self.config.grow_vertical, self.config.grow_anchor
	local frame_spacing, group_spacing = self.config.frame_spacing, self.config.group_spacing


	self.config.maxLetters = math.ceil(data.width/self.config.fonttext_size*1.5)

	local needCreation = false
	if (not self.headers) then
		self:CreateHeaders(data.width, data.height, data.scale)
		needCreation = true
	end

	local hxOffset, hyOffset, hRelPoint = getHeaderPoints(grow_vertical, grow_anchor, group_spacing)
	local xOffset, yOffset, point = getFramePoints(grow_vertical, grow_anchor, frame_spacing)


	local visibility = ""
	if self.config.showSolo then
		visibility = visibility .. "[@player,exists] [nogroup:party] "
	end
	if self.config.showInParty then
		visibility = visibility .. "[group] "
	end
	visibility = visibility .. "[@raid6,exists] show;hide"
	
	for i = 1, #self.headers do
		local header = self.headers[i]
		header:Hide()
		RegisterAttributeDriver(header, "state-visibility", visibility)

		header:SetAttribute("showSolo", (layout == "party") and self.config.showSolo or nil)
		header:SetAttribute("showParty", (layout == "party") and self.config.showInParty or nil)
		header:SetAttribute("showRaid", true)

		header:SetAttribute("xOffset", xOffset)
		header:SetAttribute("yOffset", yOffset)
		header:SetAttribute("point", point)

		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		header:SetAttribute('sortMethod', 'INDEX')
		header:SetAttribute("groupBy", 'GROUP')

		if (i == 1) and (layout == "party") then
			header:SetAttribute("groupFilter", nil)
		else
			header:SetAttribute("groupFilter", tonumber(i))
		end

		if needCreation then  -- Creates all frames, so no fuckups
			header:Show()
			header:SetAttribute("startingIndex", -4)
			header:Hide()
			for index, child in next, {header:GetChildren()} do
				header[index] = child
			end
		end
		header:SetAttribute("startingIndex", 1)
		header:SetScale(data.scale)

		for i = 1, #header do
			header[i]:UpdateLayout(data.width, data.height)
		end

		if i == 1 then
			header:SetPoint(unpack(self.config.position))
		else
			header:SetPoint(grow_anchor, self.headers[i-1], hRelPoint, hxOffset, hyOffset)
		end
		header:Show()
	end

	self.loadedLayout = layout
end

-- positions
local POINT, PARENT = "TOPLEFT", "UIParent"

local function getCurrentPosition(self)
	local point, _, rpoint, x, y = self:GetPoint()
	-- convert whatever point we get over to topleft
	local width, height = self:GetSize()

	if point:find('RIGHT') then
		x = x - (width)
	elseif not point:find('LEFT') then
		x = x - (width / 2)
	end

	if point:find('BOTTOM') then
		y = y + height
	elseif (not point:find('TOP')) then
		y = y + height/2
	end

	local scale = self.owner.headers[1]:GetEffectiveScale()
	return POINT, PARENT, rpoint, math.floor(x/scale + .5), math.floor(y/scale + .5)
end

local function onDragStop(self)
	if self.isMoving then
		self:StopMovingOrSizing()
		local p, par, rp, x, y = getCurrentPosition(self)
		local t = self.owner.config.position
		t[1] = p
		t[2] = par
		t[3] = rp
		t[4] = x
		t[5] = y

		local header = self.owner.headers[1]
		header:ClearAllPoints()
		header:SetPoint(p, par, rp, x, y)

		self:ClearAllPoints()
		self:SetPoint(POINT, header)
	end
	self.isMoving = false
end

local function onDragStart(self)
	self.isMoving = true
	self:StartMoving()

	local header = self.owner.headers[1]
	header:ClearAllPoints()
	header:SetPoint(POINT,self)
end

local LOCKED = true
function addon:UnlockAnchors()
	if not LOCKED then 
		return
	elseif (InCombatLockdown()) then
		return ns.print("Can't move frames during combat")
	end
	LOCKED = false

	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	for i = 1, #self.headers do
		local header = self.headers[i]
		local numMembers = 0

		for j = 1, 40 do
			local name, rank, subgroup = GetRaidRosterInfo(j)
			if name and subgroup == i then
				numMembers = numMembers + 1
			end
		end

		header:SetAttribute("startingIndex", 1 - header:GetAttribute("unitsPerColumn"))
		RegisterAttributeDriver(header, 'state-visibility', 'show')
		header:SetAttribute("showSolo", nil)
		header:SetAttribute("showParty", nil)
		header:SetAttribute("showRaid", nil)

		for i = 1, header:GetNumChildren() do
			local obj = select(i, header:GetChildren())
			obj.old_unit = obj.unit
			obj.unit = "player"

			obj.old_onUpdate = obj:GetScript('OnUpdate')
			obj:SetScript("OnUpdate", nil)

			UnregisterUnitWatch(obj)
			RegisterUnitWatch(obj, true)

			obj:Show()
		end
	end

	local f = self.moverFrame or CreateFrame("Frame", self:GetName().."MoverFrame")
	f.owner = self
	self.moverFrame = f
	f:Show()

	f:SetPoint('TOPLEFT', self.headers[1])
	f:SetPoint('BOTTOMRIGHT', self.headers[#self.headers])

	f:EnableMouse(true)
	f:SetFrameStrata('HIGH')
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true)

	f:SetScript("OnDragstart",onDragStart)
	f:SetScript("OnDragStop", onDragStop)

	return true
end

function addon:LockAnchors()
	if LOCKED then return end

	for i = 1, #self.headers do
		local header = self.headers[i]
		for i = 1, header:GetNumChildren() do
			local obj = select(i, header:GetChildren())
			if obj.old_unit then
				obj.unit = obj.old_unit
				obj.old_unit = nil
				obj:SetScript("OnUpdate", obj.old_onUpdate)
				obj.old_onUpdate = nil

				UnregisterUnitWatch(obj)
				RegisterUnitWatch(obj)
				obj:UpdateAllElements("OnShow")
			end
		end
	end
	LOCKED = true

	if event then
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	end
	onDragStop(self.moverFrame)
	self.moverFrame:Hide()
	self:UpdateRaidLayout('ForceUpdate')

	return true
end

function addon:ToggleAnchors()
	if self:IsAnchorsLocked() then
		return self:UnlockAnchors()
	else
		return self:LockAnchors()
	end
end

function addon:IsAnchorsLocked()
	return LOCKED
end

function addon:UpdateDispelTypes()
	local _, class = UnitClass("player")
	ns.playerClass = class
	ns.Dispel = ns.Dispel or { }
	wipe(ns.Dispel)

	if class == "DRUID" then
		ns.Dispel.Curse   = IsPlayerSpell(88423) or IsPlayerSpell(2782) -- Remove Corruption
		ns.Dispel.Magic   = IsPlayerSpell(88423) -- Nature's Cure
		ns.Dispel.Poison  = ns.Dispel.Curse

	elseif class == "MAGE" then
		ns.Dispel.Curse   = IsPlayerSpell(475) -- Remove Curse

	elseif class == "MONK" then
		ns.Dispel.Disease = IsPlayerSpell(115450) -- Detox
		ns.Dispel.Magic   = IsPlayerSpell(115451) -- Internal Medicine
		ns.Dispel.Poison  = ns.Dispel.Disease

	elseif class == "PALADIN" then
		ns.Dispel.Disease = IsPlayerSpell(4987) -- Cleanse
		ns.Dispel.Magic   = IsPlayerSpell(53551) -- Sacred Cleansing
		ns.Dispel.Poison  = ns.Dispel.Disease

	elseif class == "PRIEST" then
		ns.Dispel.Disease = IsPlayerSpell(527) -- Purify
		ns.Dispel.Magic   = IsPlayerSpell(527) or IsPlayerSpell(32375) -- Mass Dispel

	elseif class == "SHAMAN" then
		ns.Dispel.Curse   = IsPlayerSpell(51886) -- Cleanse Spirit (upgrades to Purify Spirit)
		ns.Dispel.Magic   = IsPlayerSpell(77130) -- Purify Spirit

	elseif class == "WARLOCK" then
		ns.Dispel.Magic   = IsPlayerSpell(115276, true) or IsPlayerSpell(89808, true) -- Sear Magic (Fel Imp) or Singe Magic (Imp)
	end
end

function ns.print(...)
	print("|cffffcf00oUF_AbuRaid: |r", ...)
end

_G.SLASH_OUFABURAID1 = "/oufaburaid"
SlashCmdList['OUFABURAID'] = function(...)
	if addon:ToggleAnchors() then
		local s = addon:IsAnchorsLocked() and "locked" or "un-locked"
		ns.print("Raid frames "..s..".")
	end
end