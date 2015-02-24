local _, ns = ...

-- These are names of the fonts inside LibSharedMedia
ns.config.statusbarNAME 	= "Hal M"
ns.config.overlaybarNAME 	= "Flat"
ns.config.fonttextNAME 		= "Expressway Free"

-- Forgot what this does
ns.config.backdrop_alpha 	= 0.9

-- What the health text should display
-- 0 = Show nothing
-- 1 = Display health lost ( -12k)
-- 2 = Health remaining (current)
-- 3 = Show a percent (0-99%)
ns.config.health_format 	= 1 		-- [0 - 3]

-- The text size
ns.config.fonttext_size 	= 13		--[number]

-- Let the health (and power) bars expand vertical
ns.config.bars_vertical 	= false		--[true - false]

-- Show a Manabar for classes that use mana
ns.config.powerbar_enable 	= true 		--[true - false]
ns.config.powerbar_height 	= 4 		--[number]

-- Bar color multiplier, normally colored by class. 
-- [0 - 1] [completely black - full class color]
ns.config.healthbar_mult 	= 0.8 		-- [0 - 1]
ns.config.healthbar_bgmult 	= 0.33		-- [0 - 1]
ns.config.powerbar_mult 	= 0.9		-- [0 - 1]
ns.config.powerbar_bgmult 	= 0.33		-- [0 - 1]

-- Only color threat border if higher than this, set to 4 to never show
ns.config.threat_threshold 	= 3 		--[1 - 4]
-- Color border even if you can't dispel it
ns.config.show_debuffborder = true 		--[true - false]

-- Default Indicators sizes
ns.config.indicator_size 	= 8			--[number]
ns.config.buff_size 		= 15		--[number]
ns.config.debuff_size 		= 19		--[number]

-- Visibility options
ns.config.showSolo 			= true		--[true - false]
ns.config.showInParty 		= false		--[true - false]

-- Which direction the groups expand
ns.config.grow_vertical 	= false		--[true - false]
ns.config.grow_anchor 		= "TOPLEFT" --["TOPLEFT", "BOTTOMLEFT", "TOPRIGHT", "BOTTOMRIGHT"]
-- The space between the frames
ns.config.frame_spacing 	= 8			--[number]
-- The space between the groups
ns.config.group_spacing 	= 10		--[number]

-- Decide the layout for each group type
ns.config.layouts["raid40"] 	= { width = 50, height = 40, scale = 1, position = {"TOPLEFT", "UIParent", "TOPLEFT", 15, -15 } }
ns.config.layouts["raid25"] 	= { width = 70, height = 40, scale = 1, position = {"TOPLEFT", "UIParent", "TOPLEFT", 15, -15 } }
ns.config.layouts["raid10"] 	= { width = 80, height = 40, scale = 1, position = {"TOPLEFT", "UIParent", "TOPLEFT", 15, -15 } }
ns.config.layouts["party"] 		= { width = 100, height = 40, scale = 1, position = {"TOPLEFT", "UIParent", "TOPLEFT", 15, -15 } }

--[[	_________________________________________________________
		|topleft topleftr	topl top  topr 	toprightl  topright |
		|														|
		|topleftb									   toprightb|
		|														|
		|														|
		|														|
		|														|
		|														|
		|														|
		|														|
		|														|
		|														|
		|_______________________________________________________|

	ind 	= where to position it, look above
	id  	= The spell ID of the spell you want to track
	onlyOwn = Only show if the spell is cast by you.
	showcd  = show a cooldown spiral on it.
	
	color   = The color it should have, if the aura has stacks you can also use this:
	color = {
		[1] = {1, 0.2, 1},
		[2] = {1, 0.2, 1},
		[3] = {1, 0.2, 1},
	}

]]

ns.IndicatorList["ALL"] = {
	{ ind = 'topright', id = 20707,		onlyOwn = false,	showcd = false,	color = {0.7, 0, 1} }, -- Soulstone
}

ns.IndicatorList["DRUID"] = {
	{ ind = "top", 		id = 774, 		onlyOwn = true, 	showcd = true,	color = {1, 0.2, 1}	}, -- rejuvination 
	{ ind = "topl", 	id = 48438,		onlyOwn = true,  	showcd = true,	color = {0.60, 0.20, 0.80 } }, --"Wild Growth"
	{ ind = "topr", 	id = 33763,		onlyOwn = true,  	showcd = true,	color = { 0.00, 0.90, 0.00 } },
	{ ind = "topright", id = 8936, 		onlyOwn = true, 	showcd = true,	color = { 0, 0.4, 0.9 } }, --"Regrowth"
}

ns.IndicatorList["MONK"] = {
    { ind = 'top', 		id = 119611,	onlyOwn = true,		showcd = true,	color = {0, 1, 0}}, -- Renewing Mist
    { ind = 'topr', 	id = 124682,	onlyOwn = true,		showcd = true,	color = {0.15, 0.98, 0.64}}, -- Enveloping Mist
    { ind = 'topl', 	id = 115175,	onlyOwn = true,		showcd = true,	color = {0.15, 0.98, 0.64}}, -- Soothing Mist
    { ind = 'topright', id = 124081,	onlyOwn = true,		showcd = true,	color = {0.7, 0.8, 1}}, -- Zen Sphere
}

ns.IndicatorList["PALADIN"] = {
    { ind = 'topl', 	id = 53563,		onlyOwn = true,		showcd = true,	color = {0, 1, 0}}, -- Beacon of Light
    { ind = 'topr', 	id = 20925,		onlyOwn = true,		showcd = true,	color = {1, 1, 0}}, -- Sacred Shield
}

ns.IndicatorList["PRIEST"] = {
    { ind = 'top', 		id = 6788, 		onlyOwn = true,		showcd = true,	color = {0.6, 0, 0} }, -- Weakened Soul
    { ind = 'topl', 	id = 17, 		onlyOwn = true,		showcd = true,	color = {1, 1, 0} }, -- Power Word: Shield
    { ind = 'topr', 	id = 33076,		onlyOwn = false,	showcd = true,	color = {1, 0.6, 0.6} }, -- Prayer of Mending
    { ind = 'topright', id = 139, 		onlyOwn = true,		showcd = true,	color = {0, 1, 0} }, -- Renew
}

ns.IndicatorList["SHAMAN"] = {
    { ind = 'top', 		id = 61295,		onlyOwn = true,		showcd = true,	color = {0.7, 0.3, 0.7} }, -- Riptide
    { ind = 'topl', 	id = 974, 		onlyOwn = true,		showcd = true,	color = {0.7, 0.4, 0} }, -- Earth Shield
}

-- Add Buffs to show like this:
-- ns.WhiteList[spellID] = true
ns.WhiteList[871	] = true 		--shield-wall
ns.WhiteList[114030	] = true 		--vigilance

ns.WhiteList[33206	] = true 		--pain-suppression
ns.WhiteList[47788	] = true 		--guardian-spirit

ns.WhiteList[1022	] = true 		--hand-of-protection
ns.WhiteList[498	] = true 		--divine-protection
ns.WhiteList[6940	] = true 		--hand-of-sacrifice

ns.WhiteList[115176	] = true 		--zen-meditation
ns.WhiteList[115295	] = true 		--guard
ns.WhiteList[115203	] = true 		--fortifying-brew
ns.WhiteList[116849	] = true 		--life-cocoon

ns.WhiteList[61336	] = true 		--survival-instincts
ns.WhiteList[102342	] = true 		--ironbark

ns.WhiteList[48707	] = true 		--anti-magic-shell
ns.WhiteList[48792	] = true 		--icebound-fortitude
ns.WhiteList[155835	] = true 		--bristling-fur

ns.WhiteList[1949	] = true 		--bristling-fur