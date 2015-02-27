local addon, ns = ...

local colors = oUF.colors

----------------------------------------------------------------------
--		Basic stuff
----------------------------------------------------------------------

ns.utf8sub = function(string)
	local index = ns.config.maxLetters 
    local bytes = string:len()
    if (bytes <= index) then
        return string
    else
        local length, currentIndex = 0, 1

        while currentIndex <= bytes do
            length = length + 1
            local char = string:byte(currentIndex)

            if (char > 240) then
                currentIndex = currentIndex + 4
            elseif (char > 225) then
                currentIndex = currentIndex + 3
            elseif (char > 192) then
                currentIndex = currentIndex + 2
            else
                currentIndex = currentIndex + 1
            end

            if (length == index) then
                break
            end
        end

        if (length == index and currentIndex <= bytes) then
            return string:sub(1, currentIndex - 1)
        else
            return string
        end
    end
end

function ns.FormatValue(value)
	local absvalue = abs(value)

	if absvalue >= 1e9 then
		return tonumber(format('%.2f', value/1e9))..'b'
	elseif absvalue >= 1e7 then
		return tonumber(format('%.1f', value/1e6))..'m'
	elseif absvalue >= 1e6 then
		return tonumber(format('%.2f', value/1e6))..'m'
	elseif absvalue >= 1e5 then
		return tonumber(format('%.0f', value/1e3))..'k'
	elseif absvalue >= 1e3 then
		return tonumber(format('%.1f', value/1e3))..'k'
	else
		return value
	end
end

----------------------------------------------------------------------
--		TAGS
----------------------------------------------------------------------

oUF.Tags.Methods["oUF_AbuRaid:name"] = function(u, r)
	local name = UnitName(r or u) or 'Unknown'
	return ns.utf8sub(name)
end
oUF.Tags.Events["oUF_AbuRaid:name"] = "UNIT_NAME_UPDATE UNIT_ENTERED_VEHICLE UNIT_EXITED_VEHICLE UNIT_PET"

----------------------------------------------------------------------
--		Border Coloring
----------------------------------------------------------------------

function ns.UpdateBorder(self)
	local glowcolor, shadowcolor

	local type = self.debuffType
	if (type and (self.canDispel or ns.config.show_debuffborder)) then
		glowcolor = colors.debuff[type]
	end

	local threat = self.threat_status
	if (threat) then
		shadowcolor = colors.threat[threat]
	end

	if (glowcolor) then
		self:SetBorderGlowColor(glowcolor[1], glowcolor[2], glowcolor[3], 1)
	else
		self:SetBorderGlowColor(0,0,0,0)
	end

	if (shadowcolor) then
		self:SetBorderShadowColor(shadowcolor[1], shadowcolor[2], shadowcolor[3], 1)
	else
		self:SetBorderShadowColor(0,0,0,1)
	end
end

----------------------------------------------------------------------
--		Threat Update
----------------------------------------------------------------------

function ns.Threat_Update(self, event, unit)
	if (not unit) or (not self:IsShown()) then
		return;
	end
	local threat = (UnitThreatSituation(unit) or 0)
	threat = (threat >= ns.config.threat_threshold) and threat

	if (self.threat_status == threat) then return; end
	self.threat_status = threat
	self:UpdateBorder()
end

----------------------------------------------------------------------
--		Health Update Override
----------------------------------------------------------------------

do
	local UnitIsPlayer, UnitIsConnected, UnitIsAFK, UnitIsDead, UnitIsGhost, UnitHasVehicleUI, 
		  UnitIsCharmed, UnitIsDeadOrGhost, UnitName, UnitHealth, UnitHealthMax, UnitClass = 
		  UnitIsPlayer, UnitIsConnected, UnitIsAFK, UnitIsDead, UnitIsGhost, UnitHasVehicleUI, 
		  UnitIsCharmed, UnitIsDeadOrGhost, UnitName, UnitHealth, UnitHealthMax, UnitClass

	local AFK, DISCONNECTED, DEAD, GHOST, VEHICLE, CHARMED = 1,2,3,4,5,6

	local statusmap = {
		[AFK] = _G.DEFAULT_AFK_MESSAGE,
		[DISCONNECTED] = _G.PLAYER_OFFLINE,
		[DEAD] = _G.DEAD,
		[GHOST] = GetSpellInfo(8326),
		[CHARMED] = "Charm",
	}

--0-> disable, 1-> hp lost, 2-> hp remaining, 3-> percent
	local formattext = {
		[0] = function(cur, max) return "" end,
		[1] = function(cur, max) return ns.FormatValue(cur-max) end,
		[2] = function(cur, max) return ns.FormatValue(cur) end,
		[3] = function(cur, max) return ("%.1f"):format((max == 0 and 0 or ((max-min)/max)*100)) end,
	}

	local function updateHealthText(self, status, cur, max)
		if (statusmap[status]) then
			self.Text:SetText("|cff999999"..statusmap[status].."|r")
		elseif (self.realUnit and UnitHasVehicleUI(self.realUnit)) then
			local realName = UnitName(SecureButton_GetUnit(self) or self.unit) or _G.UNKNOWN
			self.Text:SetText(ns.utf8sub(realName))
		elseif (cur ~= max) then
			self.Text:SetText(formattext[ns.config.health_format](cur, max))
		else
			self.Text:SetText("")
		end
	end

	local function getUnitStatus(unit)
		if (UnitIsPlayer(unit)) then
			if (not UnitIsConnected(unit)) then
				return DISCONNECTED
			elseif (UnitIsAFK(unit)) then
				return AFK
			elseif (UnitIsDead(unit)) then
				return DEAD
			elseif (UnitIsGhost(unit)) then
				return GHOST
			elseif (UnitHasVehicleUI(unit)) then
				return VEHICLE
			elseif (UnitIsCharmed(unit)) then
				return CHARMED
			end
		else
			return UnitIsDeadOrGhost(unit) and DEAD
		end
	end

	function ns.Health_UpdateOverride(self, event, unit)
		if (unit) and (self.unit ~= unit) and (self.realUnit ~= unit) then return; end
		unit = unit or self.unit or self.realUnit


		local h = self.Health
		local cur, max = UnitHealth(unit), UnitHealthMax(unit)

		local class = UnitName(self.realUnit or unit) ~= UNKNOWN and select(2, UnitClass(self.realUnit or unit))
		local status = getUnitStatus(self.realUnit or unit) or class or 0
		local oldstatus = self.unit_status
		self.unit_status = status

		updateHealthText(self, status, cur, max)
		h:SetMinMaxValues(0, max)
		if (status ~= DISCONNECTED) then
			h:SetValue(cur)
		end

		--if (oldstatus == status) then return; end

		local color
		if (status == DISCONNECTED) then
			color = colors.disconnected
		elseif (status == CHARMED) then
			color = colors.charmed
		elseif (status == VEHICLE) then
			color = colors.health
		elseif (UnitIsPlayer(unit)) then
			color = colors.class[class]
		else
			color = colors.health
		end
		local r,g,b = color[1], color[2], color[3]

		--self.Name:SetTextColor(r,g,b)
		--self.Text:SetTextColor(r,g,b)

		if (status == DISCONNECTED) then
			h:SetValue(0)
			h.bg:Hide()
			self:SetBackdropColor(0, 0, 0, 0.7)
		else
			if (oldstatus == DISCONNECTED) then
				h.bg:Show()
				self:SetBackdropColor(0, 0, 0, ns.config.backdrop_alpha)
			end

			local m = h.multiplier
			local m1 = h.bg.multiplier
			h:SetStatusBarColor(r*m, g*m, b*m)
			h.bg:SetVertexColor(r*m1, g*m1, b*m1)
		end
	end
end
------------------------------------------------------------------
--						Extra health bars						--
------------------------------------------------------------------
do	
	local UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGetTotalAbsorbs = 
		  UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGetTotalAbsorbs

	function ns.HealPrediction_UpdateOverride(self, event, unit)
		if (unit) and (self.unit ~= unit) and (self.realUnit ~= unit) then return; end
		local hp = self.HealPrediction
		local curHP, maxHP = UnitHealth(unit), UnitHealthMax(unit)
		local incHeal = (UnitGetIncomingHeals(unit) or 0) * 2
		local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0

		if ( healAbsorb > 0) then
			hp.necroHeals:SetMinMaxValues(0, curHP)
			hp.necroHeals:SetValue(math.min(healAbsorb, curHP))
			hp.necroHeals:Show()
		else
			hp.necroHeals:Hide()
		end

		if ((incHeal - healAbsorb) <= 0) or (curHP == maxHP) then
			hp.incHeals:Hide()
		else
			hp.incHeals:SetMinMaxValues(0, maxHP - curHP)
			hp.incHeals:SetValue(incHeal - healAbsorb)
			hp.incHeals:Show()
		end

		if (hp.TotalAbsorb) then
			local absorb = UnitGetTotalAbsorbs(unit) or 0
			hp.TotalAbsorb:SetMinMaxValues(0, maxHP)
			hp.TotalAbsorb:SetValue(math.min(absorb, maxHP))
			if (absorb < (maxHP * 0.05)) then
				hp.TotalAbsorb:Hide()
			else
				hp.TotalAbsorb:Show()
				if not hp.TotalAbsorb.Spark:IsShown() then
					hp.TotalAbsorb.Spark:Show()
				end
			end
		end
	end
end
----------------------------------------------------------------------
--		Power Update Override
----------------------------------------------------------------------
do
	local UnitPowerMax, UnitPower, UnitPowerType = 
		UnitPowerMax, UnitPower, UnitPowerType

	local MANA = SPELL_POWER_MANA 
	local PADDING_BORDER, PADDING_BAR = 1, 1

	function ns.Power_UpdateOverride(self, event, unit)
		if (unit) and (self.unit ~= unit) and (self.realUnit ~= unit) then return; end
		unit = unit or self.unit or self.realUnit

		local p = self.Power
		local type = UnitPowerType(unit)

		if (type ~= MANA) then
			if (p:IsShown()) then
				p:Hide()
				self.Health:SetPoint("BOTTOMRIGHT", self, -1, 1)
			end
			return
		elseif (not p:IsShown()) then
			if self.isVertical then
				self.Health:SetPoint("BOTTOMRIGHT", self, -(PADDING_BORDER + p.height + PADDING_BAR), PADDING_BORDER)
			else
				self.Health:SetPoint("BOTTOMRIGHT", self, -PADDING_BORDER, (PADDING_BORDER + p.height + PADDING_BAR))
			end
			p:Show()
		end

		p:SetMinMaxValues(0, UnitPowerMax(unit))
		p:SetValue(UnitPower(unit))
	end
end

----------------------------------------------------------------------
-- Res Icon
----------------------------------------------------------------------

local LibRes = LibStub("LibResInfo-1.0", true)

local function UpdateResIcon(event, unit, guid)
	for i = 1, #oUF.objects do
		local obj = oUF.objects[i]
		if obj.style == "oUF_AbuRaid" and obj.CenterIcon then
			local status = LibRes:UnitHasIncomingRes(obj.unit)
			if status then
				obj.CenterIcon:Show()
			else
				obj.CenterIcon:Hide()
			end
		end
	end
end

LibRes.RegisterAllCallbacks("oUF_AbuRaid", UpdateResIcon, true)

----------------------------------------------------------------------
-- Aura, indicators and debuff highlight
----------------------------------------------------------------------
do
	local UnitDebuff, UnitBuff, UnitCanAssist = UnitDebuff, UnitBuff, UnitCanAssist
	local dispelPriority = { 
		["Poison"] = 1,
		["Disease"] = 2,
		["Curse"] = 3,
		["Magic"] = 4,
	}

	local blackList = ns.debuffs_BlackList

	local function indicator_Activate(self, start, duration, count)

		if 	(self.active == true) and
			(self.laststart == start) and
			(self.lastduratoin == duration) and
			(self.lastcount == count)
		then
			return;
		end

		self.active = true
		self.laststart = start
		self.lastduratoin = duration
		self.lastcount = count

		self:Show()
		if (self.color) then
			local color = self.color[count]
			self:SetBackdropColor(color[1], color[2], color[3])
		end
		if (duration) and (self.showcd) then
			self.cd:SetCooldown(start, duration)
		end
	end

	local isMe = { player = true, pet = true, vehicle = true }

	function ns.Update_Auras(self, event, unit)
		if (unit ~= self.unit) then return; end

		local debuff = self.Debuff
		local noDebuff = true
		local icons = self.AuraMonitor
		local canAssist = UnitCanAssist("player", unit)
		local lastPrior, lastType, canDispelLast = 0

		local harmful, index = true, 0
		while (true) do
			index = index + 1

			local name, _, icon, count, debuffType, duration, expirationTime, caster, _, _, spellId, canApplyAura, isBossDebuff = (harmful and UnitDebuff or UnitBuff)(unit, index)

			if (not name) then
				if harmful then
					harmful = nil
					index = 0
				else
					break;
				end
			else
				if (not isBossDebuff) then
					isBossDebuff = caster and caster:find("boss")
				end
				if (harmful) and (canAssist) and (dispelPriority[debuffType]) and (
					(canDispelLast and ns.Dispel[debuffType] and dispelPriority[debuffType] > lastPrior) or
					(not canDispelLast and (ns.Dispel[debuffType] or dispelPriority[debuffType] > lastPrior))) -- looks pretty dont it
				then
					lastType = debuffType
					canDispelLast = ns.Dispel[debuffType]
					lastPrior = dispelPriority[debuffType]
				end

				-- Only show the first seen debuff for now
				if (noDebuff) and (isBossDebuff or (harmful and ns.WhiteList[spellId])) then
					debuff:Show()
					if (duration) then
						debuff.cd:SetCooldown(expirationTime - duration, duration)
					end
					debuff.icon:SetTexture(icon)
					debuff.count:SetText(count > 1 and count)
					noDebuff = false
				end	

				-- Check for indicators
				local indicator = icons[name]
				if (indicator) and (not indicator.onlyOwn or isMe[caster]) then
					indicator.seen = true
					indicator_Activate(indicator, expirationTime and (expirationTime - duration), duration, count)
				end 
			end
		end

		if (noDebuff) then
			debuff:Hide()
		end

		if (self.debuffType ~= lastType) then
			self.debuffType = lastType
			self.canDispel = canDispelLast
			self:UpdateBorder()
		end

		-- Reset indicators
		for _, indicator in pairs(icons) do 
			if (not indicator.seen) and (indicator.active) then
				indicator.active = false
				indicator:Hide()
			else
				indicator.seen = nil
			end
		end
	end
end