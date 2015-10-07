local ADDON, ns = ...
local cfg = ns.config
local noop = function() end

local INDICATOR, BUFF, DEBUFF = 1,2,3
local PADDING_BORDER, PADDING_BAR = 1, 1

local PAD = PADDING_BORDER
local PAD2 = cfg.indicator_size
local indicator_data = {
	[INDICATOR] = {
		["top"] = 		{x = 0,			y = -PAD,		point = "TOP",	 		size = cfg.indicator_size},
		["topl"] = 		{x = -PAD2,		y = -PAD,		point = "TOP",			size = cfg.indicator_size},
		["topr"] = 		{x = PAD2,		y = -PAD,		point = "TOP",			size = cfg.indicator_size},
		["topleft"] = 	{x = PAD,		y = -PAD,		point = "TOPLEFT",		size = cfg.indicator_size},
		["topleftr"] = 	{x = PAD2,		y = -PAD,		point = "TOPLEFT",		size = cfg.indicator_size},
		["topleftb"] = 	{x = PAD,		y = -PAD2,		point = "TOPLEFT",		size = cfg.indicator_size},
		["topright"] = 	{x = -PAD,		y = -PAD,		point = "TOPRIGHT",		size = cfg.indicator_size},
		["toprightl"] = {x = -PAD2,		y = -PAD,		point = "TOPRIGHT",		size = cfg.indicator_size},
		["toprightb"] = {x = -PAD,		y = -PAD2,		point = "TOPRIGHT",		size = cfg.indicator_size},
	},
	[BUFF] = {
		size = cfg.buff_size, rows = 1, columns = 4, spacing = 2, 
		point = "BOTTOMRIGHT", x = -1, y = 1, spacing = 2, 
		growx = "LEFT", growy = "UP"
	},
	[DEBUFF] = {x = 0, y = 0, point = "CENTER", size = cfg.debuff_size},
}

local function createAuraButton(self, type)

	local button = CreateFrame("Frame", nil, self)
	button:SetFrameLevel(self:GetFrameLevel()+5)

	local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cd:SetReverse(true)
	cd:SetAllPoints(button)
	cd:SetHideCountdownNumbers(true)
	cd.noCooldownCount = true
	button.cd = cd

	if (type == INDICATOR) then	
		button:SetBackdrop({
			bgFile = "Interface\\BUTTONS\\WHITE8X8",
			tile = true,
			tileSize = 8,
			edgeFile = "Interface\\BUTTONS\\WHITE8X8",
			edgeSize = 1,
			insets = { left = 1, right = 1, top = 1, bottom = 1},
		})
		button:SetBackdropBorderColor(0, 0, 0, 1)
		button:SetBackdropColor(1, 1, 1, 1)

		button.cd:SetDrawEdge(false)
	else
		button:SetBackdrop{
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			insets = { left = -2, right = -2, top = -2, bottom = -2},
		}
		button:SetBackdropColor(0,0,0, 1)

		local icon = button:CreateTexture(nil, "BORDER")
		icon:SetAllPoints(button)
		icon:SetTexCoord(.1, .9, .1, .9)
		button.icon = icon
		local _, _, t = GetSpellInfo(114925)
		icon:SetTexture(t)

		local count = button:CreateFontString(nil, "OVERLAY")
		count:SetFontObject(NumberFontNormal)
		count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 5, -4)
		button.count = count

		button.EnableMouse = noop
	end

	button:Hide()
	return button
end

local function createBuffIcon(icons, index)
	local icon = createAuraButton(icons, BUFF)
	icons.createdIcons = icons.createdIcons + 1

	icon.stealable = { Hide = noop } -- So we can use the oUF aura module
	icon.overlay = { Hide = noop } -- So we can use the oUF aura module

	table.insert(icons, icon)
	return icon
end

local function customFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	return ns.WhiteList[spellID]
end

local function buildIndList()
	local list = { }
	if ns.IndicatorList.ALL then
		for i = 1, #ns.IndicatorList.ALL do
			list[1 + #list] = ns.IndicatorList.ALL[i]
		end
	end

	if ns.IndicatorList[ns.playerClass] then
		for i = 1, #ns.IndicatorList[ns.playerClass] do
			list[1 + #list] = ns.IndicatorList[ns.playerClass][i]
		end
	end
	return list
end

local list
local function addIndicators(self)
	-- Buffs
	local data = indicator_data[BUFF] 

	local buffs = CreateFrame("Frame", nil, self)
	buffs:SetPoint(data.point, data.x, data.y)
	buffs:SetSize((data.size + data.spacing)*data.columns, data.size + data.spacing)

	buffs.spacing = data.spacing
	buffs.num = data.columns*data.rows
	buffs['growth-x'] = data.growx
	buffs['growth-y'] = data.growy
	buffs.initialAnchor = data.point
	buffs.size = data.size

	buffs.CreateIcon = createBuffIcon
	buffs.CustomFilter = customFilter
	self.Buffs = buffs

	-- Debuff
	data = indicator_data[DEBUFF] 
	local debuff = createAuraButton(self, DEBUFF)
	debuff:SetPoint(data.point, data.x, data.y)
	debuff:SetSize(data.size,data.size)

	self.Debuff = debuff

	-- Build aura watcher, based of oUF_AuraWatch
	self.AuraMonitor = { }
	list = list or buildIndList()

	for i = 1, #list do
		local spell = list[i]
		data = indicator_data[INDICATOR][spell.ind]
		assert(data, "No known indicator data for: "..spell.ind..".")
		local name, _, texture = GetSpellInfo(spell.id)
		assert(name, "No spell name for spellID: "..spell.id..".")

		local indicator = createAuraButton(self, INDICATOR)
		indicator:SetPoint(data.point, self, data.x, data.y)
		indicator:SetSize(data.size, data.size)

		indicator.name = name
		indicator.onlyOwn = spell.onlyOwn
		indicator.showcd = spell.showcd

		if (type(spell.color[1]) == "table") then
			indicator.color = { }
			for j = 1, #spell.color do
				indicator.color[j] = spell.color[j]
			end
		else
			indicator:SetBackdropColor(unpack(spell.color))
		end

		self.AuraMonitor[name] = indicator
	end

	self:RegisterEvent("UNIT_AURA", ns.Update_Auras)
	table.insert(self.__elements, ns.Update_Auras)
end

local function frame_OnEnter(self)
	UnitFrame_OnEnter(self)
	UIFrameFadeIn(self.Highlight, 0.1, 0, 0.7)
end

local function frame_OnLeave(self)
	UnitFrame_OnLeave(self)
	UIFrameFadeOut(self.Highlight, 0.1, 0.6, 0)
end

local function player_TargetChanged(self)
	if ( UnitIsUnit(self.unit, "target") ) then
		self.Target:Show();
	else
		self.Target:Hide();
	end
end

local function updateRaidFrameLayout(self, width, height)
	local cfg = ns.config
	local statusbar = cfg.statusbar
	local overlaybar = cfg.overlaybar
	self.isVertical = cfg.bars_vertical

	local orientation = self.isVertical and "VERTICAL" or "HORIZONTAL"

	if width and (not InCombatLockdown()) then -- shouldnt really happen
		self:SetSize(width, height)
	end

	local health = self.Health
	health:SetStatusBarTexture(statusbar)
	health:SetOrientation(orientation)
	health:ClearAllPoints()
	health:SetPoint("TOPLEFT", PADDING_BORDER, -PADDING_BORDER)
	health:SetPoint("BOTTOMRIGHT", -PADDING_BORDER, PADDING_BORDER)
	health.multiplier = cfg.healthbar_mult

	health.bg:SetTexture(statusbar)
	health.bg.multiplier = cfg.healthbar_bgmult

	do
		local incHeals = self.HealPrediction.incHeals
		local necroHeals = self.HealPrediction.necroHeals
		local absorb = self.HealPrediction.TotalAbsorb
		local spark = absorb.Spark
		local ABSORB_WIDTH = 5

		incHeals:ClearAllPoints()
		necroHeals:ClearAllPoints()
		absorb:ClearAllPoints()
		spark:ClearAllPoints()

		incHeals:SetOrientation(orientation)
		necroHeals:SetOrientation(orientation)
		absorb:SetOrientation(orientation)

		incHeals:SetStatusBarTexture(overlaybar)
		necroHeals:SetStatusBarTexture(overlaybar)
		incHeals:SetStatusBarColor(0, 1, 0, 0.5)
		necroHeals:SetStatusBarColor(1, 0, 0, 0.5)

		if (self.isVertical) then
			incHeals:SetPoint('BOTTOMRIGHT', health:GetStatusBarTexture(), 'TOPRIGHT')
			incHeals:SetPoint('TOPLEFT')

			necroHeals:SetPoint('BOTTOMLEFT')
			necroHeals:SetPoint('TOPRIGHT', health:GetStatusBarTexture())

			-- Absorb bar
			absorb:SetPoint("BOTTOMLEFT")
			absorb:SetPoint("TOPRIGHT", health, "TOPLEFT", ABSORB_WIDTH, 0)
		--	absorb:GetStatusBarTexture():SetTexCoord(1,1,0,1,0,0,1,0) doesnt work:(
			absorb:SetStatusBarTexture(cfg.absorbtextureInverted, "OVERLAY")
			absorb:SetRotatesTexture(true) -- Not possible to use 1 texture, need 2

			spark:SetPoint('BOTTOMLEFT', absorb:GetStatusBarTexture(),'TOPLEFT')
			spark:SetSize(ABSORB_WIDTH, 5)
			spark:SetTexCoord(1,1,0,1,1,0,0,0)
		else
			incHeals:SetPoint('TOPLEFT', health:GetStatusBarTexture(), 'TOPRIGHT')
			incHeals:SetPoint('BOTTOMRIGHT')

			necroHeals:SetPoint('TOPLEFT')
			necroHeals:SetPoint('BOTTOMRIGHT', health:GetStatusBarTexture(), 'BOTTOMRIGHT')

			-- Absorb bar
			absorb:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
			absorb:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, ABSORB_WIDTH)
			absorb:SetStatusBarTexture(cfg.absorbtexture, "OVERLAY")
			absorb:SetRotatesTexture(false)

			spark:SetPoint('BOTTOMLEFT', absorb:GetStatusBarTexture(),'BOTTOMRIGHT')
			spark:SetSize(5, ABSORB_WIDTH)
			spark:SetTexCoord(0,1,0,1)
		end

		absorb:GetStatusBarTexture():SetBlendMode("ADD")
		absorb:SetStatusBarColor(1,1,1,1)
	end

	local power = self.Power
	if (cfg.powerbar_enable) then
		power.multiplier = cfg.powerbar_mult

		local r,g,b = unpack(oUF.colors.power['MANA'])
		power:SetOrientation(orientation)
		power:SetStatusBarTexture(statusbar)
		power:SetStatusBarColor(r*power.multiplier, g*power.multiplier, b*power.multiplier)

		local bg = power.bg
		bg:SetAllPoints(power)
		bg:SetTexture(statusbar)
		bg.multiplier = cfg.powerbar_bgmult
		bg:SetVertexColor(r*bg.multiplier, g*bg.multiplier, b*bg.multiplier)

		power:ClearAllPoints()
		if (self.isVertical) then
			health:SetPoint("BOTTOMRIGHT", self, -(PADDING_BORDER + cfg.powerbar_height + PADDING_BAR), PADDING_BORDER)
			power:SetPoint("TOPLEFT", health, "TOPRIGHT", PADDING_BAR, 0)
		else
			health:SetPoint("BOTTOMRIGHT", self, -PADDING_BORDER, (PADDING_BORDER + cfg.powerbar_height + PADDING_BAR))
			power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -PADDING_BAR)
		end
		power:SetPoint("BOTTOMRIGHT", -PADDING_BORDER, PADDING_BORDER)
		power.height = cfg.powerbar_height 
		power:Show()
		self:IsElementEnabled('Power')
	else
		self:DisableElement('Power')
		power:Hide()
	end
end

local function createRaidFrame(self, unit)
	self.Range = {
		insideAlpha	= 1.0,
		outsideAlpha = 0.6,
	}
	local frame_level = self:GetFrameLevel()
	local statusbar = cfg.statusbar

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", frame_OnEnter)
	self:SetScript("OnLeave", frame_OnLeave)

	self:SetBackdrop({bgFile = statusbar})
	self:SetBackdropColor(0,0,0,cfg.backdrop_alpha)
	self.UpdateBorder = ns.UpdateBorder

	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(frame_level + 3)
	self.Overlay = overlay

	ns.CreateBorder(overlay, 12, 4, "BORDER", "BACKGROUND")
	self.SetBorderColor = self.Overlay.SetBorderColor
	self.SetBorderShadowColor = self.Overlay.SetBorderShadowColor
	self.SetBorderGlowColor = self.Overlay.SetBorderGlowColor

	-- Highlight for mouseover
	local highlight = overlay:CreateTexture(nil, "BORDER")
	highlight:SetPoint("TOPLEFT", self, 0, 0)
	highlight:SetPoint("BOTTOMRIGHT", self, 0, 0)
	highlight:SetTexture[[Interface\Buttons\ButtonHilight-Square]]
	highlight:SetTexCoord(0.05, 0.95, 0.05, .95)
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(0)
	self.Highlight = highlight

	local target = overlay:CreateTexture(nil, "BACKGROUND")
	target:SetPoint("TOPLEFT", self, 0, 0)
	target:SetPoint("BOTTOMRIGHT", self, 0, 0)
	target:SetTexture[[Interface\Buttons\UI-ActionButton-Border]]
	target:SetTexCoord(18/64, 1-19/64, 19/64, 1-18/64)
	target:SetBlendMode("ADD")
	target:SetAlpha(1)
	target:Hide()
	self.Target = target

	local health = CreateFrame("StatusBar", nil, self)
	health.Override = ns.Health_UpdateOverride
	health.Smooth = true
	self.Health = health

	local bg = health:CreateTexture(nil, "BORDER")
	bg:SetAllPoints(health)
	self.Health.bg = bg

	-- Incoming Heals
	local incHeals = CreateFrame("StatusBar", nil, self.Health)
	incHeals:Hide()

	-- Absorbing Heals
	local necroHeals = CreateFrame("StatusBar", nil, self.Health)
	necroHeals:SetReverseFill(true)

	-- Absorb bar
	local absorb = CreateFrame("StatusBar", nil, self.Health)
	absorb:SetStatusBarColor(1,1,1,1)

	local spark = absorb:CreateTexture(nil, 'ARTWORK')
	spark:SetTexture(cfg.absorbspark)
	spark:SetBlendMode("ADD")
	spark:SetSize(5,5)
	absorb.Spark = spark

	self.HealPrediction = {
		incHeals = incHeals,
		necroHeals = necroHeals,
		TotalAbsorb = absorb,
		Override = ns.HealPrediction_UpdateOverride,
	}

	local power = CreateFrame("StatusBar", nil, self)
	power.Smooth = true
	power.Override = ns.Power_UpdateOverride
	self.Power = power

	local bg = power:CreateTexture(nil, "BORDER")
	self.Power.bg = bg

	local name = overlay:CreateFontString(nil, 'ARTWORK')
	name:SetPoint('CENTER', self, 0, 7)
	name:SetFont(cfg.fonttext, cfg.fonttext_size)
	name:SetShadowOffset(1, -1)
	self:Tag(name, "[oUF_AbuRaid:name]")
	self.Name = name

	local text = overlay:CreateFontString(nil, 'ARTWORK')
	text:SetPoint('CENTER', self, 0, -7)
	text:SetShadowOffset(1, -1)
	text:SetFont(cfg.fonttext, cfg.fonttext_size)
	self.Text = text

	local raid = overlay:CreateTexture(nil, 'OVERLAY')
	raid:SetPoint("CENTER", self, "BOTTOM", 0, 1)
	raid:SetSize(16, 16)
	self.RaidIcon = raid

	local role = overlay:CreateTexture(nil, 'OVERLAY')
	role:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4, -4)
	role:SetSize(12, 12)
	role:SetTexture("Interface\\Addons\\"..ADDON.."\\Media\\UI-LFG-ICON-PORTRAITROLES")
	role:SetDesaturated(true)
	self.LFDRole = role

	local ready = overlay:CreateTexture(nil, "OVERLAY")
	ready:SetSize(22, 22)
	ready:SetPoint("CENTER", self, "CENTER", 0,0)
	self.ReadyCheck = ready

	local leader = overlay:CreateTexture(nil, "OVERLAY")
	leader:SetSize(16,16)
	leader:SetPoint('TOPLEFT', self, 'TOPLEFT', -4, 4)
	leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
	leader:SetDesaturated(true)
	self.Leader = leader

	local centerIcon = overlay:CreateTexture(nil, "OVERLAY")
	centerIcon:SetSize(22, 22)
	centerIcon:SetTexture[[Interface\RaidFrame\Raid-Icon-Rez]]
	centerIcon:SetPoint("CENTER", self)
	centerIcon:Hide()
	self.CenterIcon = centerIcon

	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", ns.Threat_Update)
	tinsert(self.__elements, ns.Threat_Update)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", player_TargetChanged)
	tinsert(self.__elements, player_TargetChanged)

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", ns.Health_UpdateOverride) -- AFK status changes
	self:RegisterEvent("PLAYER_CONTROL_LOST", ns.Health_UpdateOverride, true) -- Mind control, fear, taxi, etc

	addIndicators(self)
	self.UpdateLayout = updateRaidFrameLayout
	self:UpdateLayout()
end

oUF:RegisterStyle("oUF_AbuRaid", createRaidFrame)
