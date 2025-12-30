-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Other contributions by 
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Predeter of Proudmoore
-- Xenyr of Aszune
-- Cybeloras of Mal'Ganis
-- --------------------

-- -------------
-- ADDON GLOBALS AND LOCALS
-- -------------

TMW = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame"),"TellMeWhen", "AceEvent-3.0", "AceTimer-3.0")
local TMW = TMW
TMW.Initd = false
TMW.Warns = {}
TMW.Icons = {}
local db
local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
local LBF = LibStub("LibButtonFacade", true)
local AceDB = LibStub("AceDB-3.0")

TELLMEWHEN_VERSION = "3.0.3"
TELLMEWHEN_VERSION_MINOR = ""
TELLMEWHEN_WARNINGSTRING = "|cFFFF0000" .. L["ICON_TOOLTIP1"] .. " v" .. TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR .. ":|r "
TELLMEWHEN_MAXGROUPS = 10 	--this is a default, used by SetTheory (addon), so dont rename
TELLMEWHEN_MAXROWS = 20
TELLMEWHEN_MAXCONDITIONS = 1 --this is a default
TELLMEWHEN_ICONSPACING = 0	--this is a default
local UPDATE_INTERVAL = 0.05	--this is a default, local because i use it in onupdate functions

local GetSpellCooldown, GetSpellInfo, IsUsableSpell, IsSpellInRange, GetSpellTexture, GetSpellLink =
	  GetSpellCooldown, GetSpellInfo, IsUsableSpell, IsSpellInRange, GetSpellTexture, GetSpellLink
local GetItemCooldown, IsItemInRange, GetItemInfo, GetInventoryItemTexture, GetInventoryItemID =
	  GetItemCooldown, IsItemInRange, GetItemInfo, GetInventoryItemTexture, GetInventoryItemID
local GetShapeshiftForm, GetNumShapeshiftForms, GetShapeshiftFormInfo =
	  GetShapeshiftForm, GetNumShapeshiftForms, GetShapeshiftFormInfo
local GetInventorySlotInfo, GetWeaponEnchantInfo, GetTotemInfo =
	  GetInventorySlotInfo, GetWeaponEnchantInfo, GetTotemInfo
local SetValue, SetTexCoord, SetStatusBarColor, SetMinMaxValues, SetCooldown =
	  SetValue, SetTexCoord, SetStatusBarColor, SetMinMaxValues, SetCooldown
local SetVertexColor, SetAlpha, GetAlpha, GetTexture, SetTexture =
	  SetVertexColor, SetAlpha, GetAlpha, GetTexture, SetTexture
local UnitIsEnemy, UnitAura, UnitReaction, UnitExists, UnitPower, UnitPowerMax, UnitHealth, UnitHealthMax, UnitIsDeadOrGhost, UnitAffectingCombat, UnitHasVehicleUI, UnitIsPVP, UnitCastingInfo, UnitChannelInfo =
	  UnitIsEnemy, UnitAura, UnitReaction, UnitExists, UnitPower, UnitPowerMax, UnitHealth, UnitHealthMax, UnitIsDeadOrGhost, UnitAffectingCombat, UnitHasVehicleUI, UnitIsPVP, UnitCastingInfo, UnitChannelInfo
local GetPetHappiness, GetEclipseDirection, GetComboPoints, GetActiveTalentGroup =
	  GetPetHappiness, GetEclipseDirection, GetComboPoints, GetActiveTalentGroup
local GetActionCooldown, GetActionInfo, GetActionTexture, IsActionInRange, IsUsableAction =
	  GetActionCooldown, GetActionInfo, GetActionTexture, IsActionInRange, IsUsableAction
local tonumber, tostring, type, pairs, ipairs, tinsert, error, tremove, sort, select, wipe =
	  tonumber, tostring, type, pairs, ipairs, tinsert, error, tremove, sort, select, wipe
local strfind, strmatch, format, gsub, strsub, strtrim, strsplit, min, max, ceil =
	  strfind, strmatch, format, gsub, strsub, strtrim, strsplit, min, max, ceil
local GetTime = GetTime
local _G = _G
local _,pclass = UnitClass("Player")
local pGUID = UnitGUID("player") -- this isnt actually defined right here (it returns nil), so I will do it later too
local st, co, rc, mc, pr, ab, GCDSpell, talenthandler, warnhandler, BarGCD, ClockGCD
local GCD = 0
local TMW_CNDT,TMW_OP = {},{}
local oldp = print
local function print(...)
	if TMW.TestOn then
		oldp("|cffff0000TMW:|r ", ...)
	end
end
local function tContains(table, item)
	for k,v in pairs(table) do
		if v == item then return k end
	end
	return nil
end
local function ClearScripts(f)
	f:SetScript("OnEvent", nil)
	f:SetScript("OnUpdate", nil)
	if f:HasScript("OnValueChanged") then
		f:SetScript("OnValueChanged", nil)
	end
end
local SlotsToNumbers = {
	MainHandSlot = 1,
	SecondaryHandSlot = 4,
	RangedSlot = 7,
}

TMW.RelevantIconSettings = {
	all = {
		Enabled = true,
		Name = true,
		ShowTimer = true,
		ShowTimerText = true,
		ShowPBar = true,
		ShowCBar = true,
		InvertBars = true,
		Type = true,
		Conditions = true,
		Alpha = true,
		UnAlpha = true,
		ConditionAlpha = true,
		DurationMin = true,
		DurationMax = true,
		DurationMinEnabled = true,
		DurationMaxEnabled = true,
		DurationAlpha = true,
		FakeHidden = true,
	},
	cooldown = {
		CooldownShowWhen = true,
		CooldownType = true,
		RangeCheck = true,
		ManaCheck = true,
		IgnoreRunes = (pclass == "DEATHKNIGHT"),
	},
	buff = {
		BuffOrDebuff = true,
		BuffShowWhen = true,
		OnlyMine = true,
		Unit = true,
		StackAlpha = true,
		StackMin = true,
		StackMax = true,
		StackMinEnabled = true,
		StackMaxEnabled = true,
	},
	reactive = {
		CooldownShowWhen = true,
		RangeCheck = true,
		ManaCheck = true,
		CooldownCheck = true,
	},
	wpnenchant = {
		HideUnequipped = true,
		WpnEnchantType = true,
		BuffShowWhen = true,
	},
	totem = {
		BuffShowWhen = true,
	},
	multistatecd = {
		CooldownShowWhen = true,
		RangeCheck = true,
		ManaCheck = true,
	},
	icd = {
		ICDType = true,
		ICDDuration = true,
		ICDShowWhen = true,
	},
	cast = {
		BuffShowWhen = true,
		Interruptible = true,
		Unit = true,
	},
	meta = {
		Icons = true,
	}
}

TMW.DeletedIconSettings = {
	OORColor = true,
	OOMColor = true,
	Color = true,
	ColorOverride = true,
	UnColor = true,
	DurationAndCD = true,
	Shapeshift = true, -- i used this one during some initial testing for shapeshifts
	UnitReact = true,
}

TMW.Defaults = {
	profile = {
--	Version 	= 	TELLMEWHEN_VERSION,  -- DO NOT DEFINE VERSION AS A DEFAULT, OTHERWISE WE CANT TRACK IF A USER HAS AN OLD VERSION BECAUSE IT WILL ALWAYS DEFAULT TO THE LATEST
	Locked 		= 	false,
	NumGroups	=	10,
	Interval	=	UPDATE_INTERVAL,
	CDCOColor 	= 	{r=0,g=1,b=0,a=1},
	CDSTColor 	= 	{r=1,g=0,b=0,a=1},
	PRESENTColor=	{r=1,g=1,b=1,a=1},
	ABSENTColor	=	{r=1,g=0.35,b=0.35,a=1},
	OORColor	=	{r=0.5,g=0.5,b=0.5,a=1},
	OOMColor	=	{r=0.5,g=0.5,b=0.5,a=1},
	Spacing		=	TELLMEWHEN_ICONSPACING,
	Texture		=	"Interface\\TargetingFrame\\UI-StatusBar",
	TextureName = 	"Blizzard",
	DrawEdge	=	false,
	TestOn 		= 	false,
	Font 		= 	{
		Path = "Fonts\\ARIALN.TTF",
		Name = "Arial Narrow",
		Size = 12,
		Outline = "THICKOUTLINE",
		x = -2,
		y = 2,
		OverrideLBFPos = false,
	},
	Groups 		= 	{
		[1] = {
			Enabled			= true,
		},
		["**"] = {
			Enabled			= false,
			Name			= "",
			Scale			= 2.0,
			Rows			= 1,
			Columns			= 4,
			OnlyInCombat	= false,
			NotInVehicle	= false,
			PrimarySpec		= true,
			SecondarySpec	= true,
HideTalents		= {
				["*"] = "0",
			},
			ShowTalents		= {
				["*"] = "0",
			},
			Stance = {
				["*"] = true
			},
			Point = {
				point = "TOPLEFT",
				relativePoint = "TOPLEFT",
				x = 50,
				y = -50,
				defined = false,
			},
			LBF	= {
				Gloss = 0,
				Colors = {},
				Backdrop = false,
				SkinID = "Blizzard",
			},
			Icons = {
				["**"] = {
					BuffOrDebuff		= "HELPFUL",
					BuffShowWhen		= "present",
					CooldownShowWhen	= "usable",
					CooldownType		= "spell",
					Enabled				= false,
					Name				= "",
					OnlyMine			= false,
					ShowTimer			= false,
					ShowTimerText		= true,
					ShowPBar			= false,
					ShowCBar			= false,
					InvertBars			= false,
					Type				= "",
					Unit				= "player",
					WpnEnchantType		= "MainHandSlot",
					Icons				= {},
					Alpha				= 1,
					UnAlpha				= 1,
					ConditionAlpha		= 0,
					RangeCheck			= false,
					ManaCheck			= false,
					CooldownCheck		= false,
					StackAlpha			= 0,
					StackMin			= 0,
					StackMax			= 100,
					StackMinEnabled		= false,
					StackMaxEnabled		= false,
					DurationMin			= 0,
					DurationMax			= 50,
					DurationMinEnabled	= false,
					DurationMaxEnabled	= false,
					DurationAlpha		= 0,
					FakeHidden			= false,
					HideUnequipped		= false,
					Interruptible		= false,
					ICDType				= "aura",
					ICDDuration			= 45,
					ICDShowWhen			= "usable",
					Conditions = {
						["**"] = {
							AndOr = "AND",
							Type = "HEALTH",
							Icon = "",
							Operator = "==",
							Level = 0,
							Unit = "player",
						}
					},
				}
			},
		}
	},
	}
}
TMW.Group_Defaults = TMW.Defaults.profile.Groups["**"]
TMW.Icon_Defaults = TMW.Group_Defaults.Icons["**"]
TMW.Condition_Defaults = TMW.Icon_Defaults.Conditions["**"]

TMW.BE = {	--Much of these are thanks to Malazee @ US-Dalaran's chart: http://forums.wow-petopia.com/download/file.php?mode=view&id=4979 and spreadsheet https://spreadsheets.google.com/ccc?key=0Aox2ZHZE6e_SdHhTc0tZam05QVJDU0lONnp0ZVgzdkE&hl=en#gid=18
	debuffs = {
		CrowdControl = "339;2637;33786;118;61305;28272;61721;61780;28271;1499;60192;19503;19386;20066;10326;9484;6770;2094;51514;76780;710;5782;6358", -- by calico0 of Curse
		Bleeding = "9007;1822;1079;33745;1943;703;94009;43104;89775",
		Incapacitated = "1776;20066;49203",
		Feared = "5782;5246;8122;10326;1513;5484;6789",
		Stunned = "1833;408;91800;5211;9005;22570;19577;56626;44572;82691;90337;853;2812;85388;64044;20549;46968;30283;20252;65929;7922;12809;50519",
		--DontMelee = "5277;871;Retaliation;Dispersion;Hand of Sacrifice;Hand of Protection;Divine Shield;Divine Protection;Ice Block;Icebound Fortitude;Cyclone;Banish",  --does somebody want to update these for me?
		--MovementSlowed = "Incapacitating Shout;Chains of Ice;Icy Clutch;Slow;Daze;Hamstring;Piercing Howl;Wing Clip;Ice Trap;Frostbolt;Cone of Cold;Blast Wave;Mind Flay;Crippling Poison;Deadly Throw;Frost Shock;Earthbind;Curse of Exhaustion",
		Disoriented = "19503;31661;2094;51514",
		Silenced = "47476;78675;34490;55021;18469;31935;15487;1330;19647;18498;25046;80483;50613;28730;69179",
		Disarmed = "51722;676;64058;50541;91644",
		Rooted = "122;23694;58373;64695;19185;64803;4167;54706;50245;90327;16979;83301;83302",
		PhysicalDmgTaken = "30070;58683;81326;50518;55749",
		SpellDamageTaken = "93068;1490;65142;85547;60433;34889;24844",
		SpellCritTaken = "17800;22959",
		BleedDamageTaken = "33878;33876;16511;46857;50271;35290;57386",
		ReducedAttackSpeed = "6343;55095;58180;68055;8042;90314;50285",
		ReducedCastingSpeed = "1714;5760;31589;73975;50274;50498",
		ReducedArmor = "8647;50498;35387;91565;7386",
		ReducedHealing = "12294;13218;56112;48301;82654;30213;54680",
		ReducedPhysicalDone = "1160;99;26017;81130;702;24423",
	},
	buffs = {
		ImmuneToStun = "642;45438;34471;19574;48792;1022;33786;710",
		ImmuneToMagicCC = "642;45438;34471;19574;33786;710",
		IncreasedStats = "79061;79063;90363",
		IncreasedDamage = "75447;82930",
		IncreasedCrit = "24932;29801;51701;51470;24604;90309",
		IncreasedAP = "79102;53138;19506;30808",
		IncreasedSPsix = "79058;52109",
		IncreasedSPten = "77747;53646",
		IncreasedPhysHaste = "55610;53290;8515",
		IncreasedSpellHaste = "2895;24907;49868",
		BurstHaste = "2825;32182;80353;90355",
		BonusAgiStr = "6673;8076;57330;93435",
		BonusStamina = "79105;469;6307;90364",
		BonusArmor = "465;8072",
		BonusMana = "79058;54424",
		ManaRegen = "54424;79102;5677",
		BurstManaRegen = "29166;16191;64901",
		PushbackResistance = "19746;87717",
		Resistances = "19891;8185",
	},
	casts = {
		Heals = "50464;5185;8936;740;2050;2060;2061;32546;596;64843;635;82326;19750;331;77472;8004;1064;73920",
		PvPSpells = "33786;339;20484;1513;982;64901;605;453;5782;5484;79268;10326;51514;118;12051",
		Tier11Interrupts = "43088;82752;82636;83070;79710;77908;77569;80734",
	},
}

TMW.GCDSpells = {
	ROGUE=1752, -- sinister strike
	PRIEST=139, -- renew
	DRUID=774, -- rejuvenation
	WARRIOR=772, -- rend
	MAGE=133, -- fireball
	WARLOCK=687, -- demon armor
	PALADIN=20154, -- seal of righteousness
	SHAMAN=324, -- lightning shield
	HUNTER=1978, -- serpent sting
	DEATHKNIGHT=47541, -- death coil
}
GCDSpell = TMW.GCDSpells[pclass]

TMW.Chakra = {
	{abid = 88685, buffid = 81206}, 	-- sanctuary, prayer of healing,mending
	{abid = 88684, buffid = 81208},		-- serenity, heal
	{abid = 88682, buffid = 81207},		-- aspire, renew
} local Chakra = TMW.Chakra

TMW.DS = { -- dispel types
	Magic = true,
	Curse = true,
	Disease = true,
	Poison = true,
} local DS = TMW.DS

do -- STANCES
	TMW.Stances = {
		{class = "WARRIOR",		id = 2457},		-- Battle Stance
		{class = "WARRIOR",		id = 71},		-- Defensive Stance
		{class = "WARRIOR",		id = 2458},		-- Berserker Stance

		{class = "DRUID",		id = 5487},		-- Bear Form
		{class = "DRUID",		id = 768},		-- Cat Form
		{class = "DRUID",		id = 1066},		-- Aquatic Form
		{class = "DRUID",		id = 783},		-- Travel Form
		{class = "DRUID",		id = 24858},	-- Moonkin Form
		{class = "DRUID",		id = 33891},	-- Tree of Life
		{class = "DRUID",		id = 33943},	-- Flight Form
		{class = "DRUID",		id = 40120},	-- Swift Flight Form

		{class = "PRIEST",		id = 15473},	-- Shadowform

		{class = "ROGUE",		id = 1784},		-- Stealth

		{class = "HUNTER",		id = 82661},	-- Aspect of the Fox
		{class = "HUNTER",		id = 13165},	-- Aspect of the Hawk
		{class = "HUNTER",		id = 5118},		-- Aspect of the Cheetah
		{class = "HUNTER",		id = 13159},	-- Aspect of the Pack
		{class = "HUNTER",		id = 20043},	-- Aspect of the Wild

		{class = "DEATHKNIGHT",	id = 48263},	-- Blood Presence
		{class = "DEATHKNIGHT",	id = 48266},	-- Frost Presence
		{class = "DEATHKNIGHT",	id = 48265},	-- Unholy Presence

		{class = "PALADIN",		id = 19746},	-- Concentration Aura
		{class = "PALADIN",		id = 32223},	-- Crusader Aura
		{class = "PALADIN",		id = 465},		-- Devotion Aura
		{class = "PALADIN",		id = 19891},	-- Resistance Aura
		{class = "PALADIN",		id = 7294},		-- Retribution Aura

		{class = "WARLOCK",		id = 47241},	-- Metamorphosis
	}

	TMW.CSN = {
		[0] = L["NONE"],
	}

	if pclass == "DRUID" then
		TMW.CSN[0] = L["CASTERFORM"]
	end

	for k,v in pairs(TMW.Stances) do
		if v.class == pclass then
			local z = GetSpellInfo(v.id)
			tinsert(TMW.CSN, z)
		end
	end
end


-- --------------------------
-- EXECUTIVE FUNCTIONS,ETC
-- --------------------------

StaticPopupDialogs["TMW_RESTARTNEEDED"] = {
	text = "A complete restart of WoW is required to use TellMeWhen "..TELLMEWHEN_VERSION..TELLMEWHEN_VERSION_MINOR..". Would you like to restart WoW now?", --not worth translating imo, most people will never see it by the time it gets translated.
	button1 = EXIT_GAME,
	button2 = CANCEL,
	OnAccept = ForceQuit,
	OnCancel = function() StaticPopup_Hide("TMW_RESTARTNEEDED") end,
	timeout = 0,
	showAlert = true,
	whileDead = true,
}

if LBF then
	local function SkinCallback(arg, SkinID, Gloss, Backdrop, Group, Button, Colors)
		if Group and SkinID then
			local groupID = tonumber(strmatch(Group,"%d+")) --Group is a string like "Group 5", so cant use :GetID()
			db.profile.Groups[groupID]["LBF"]["SkinID"] = SkinID
			db.profile.Groups[groupID]["LBF"]["Gloss"] = Gloss
			db.profile.Groups[groupID]["LBF"]["Backdrop"] = Backdrop
			db.profile.Groups[groupID]["LBF"]["Colors"] = Colors
		end
		if not TMW.DontRun then
			TMW:Update()
		else
			TMW.DontRun = false
		end
	end

	LBF:RegisterSkinCallback("TellMeWhen", SkinCallback, TMW)
end

function TMW:OnInitialize()
	if TELLMEWHEN_VERSION >= "3.0.0" and TellMeWhen_Settings and (GetAddOnMetadata("TellMeWhen", "Version") ~= TELLMEWHEN_VERSION..TELLMEWHEN_VERSION_MINOR) then
		StaticPopup_Show("TMW_RESTARTNEEDED")
		return
	end
	
	SlashCmdList["TELLMEWHEN"] = TellMeWhen_SlashCommand
	SLASH_TELLMEWHEN1 = "/tellmewhen"
	SLASH_TELLMEWHEN2 = "/tmw"
	
	if not (type(TellMeWhenDB) == "table") then TellMeWhenDB = {} end
	TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
	db = TMW.db
	db.RegisterCallback(TMW, "OnProfileChanged", "OnProfile")
	db.RegisterCallback(TMW, "OnProfileCopied", "OnProfile")
	db.RegisterCallback(TMW, "OnProfileReset", "OnProfile")
	db.RegisterCallback(TMW, "OnNewProfile", "OnProfile")
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups

	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSION -- this only does anything for new profiles
	if (db.profile.Version < TELLMEWHEN_VERSION) or (TellMeWhen_Settings and TellMeWhen_Settings.Version < TELLMEWHEN_VERSION) then
		TMW:Upgrade()
	end
	TMW:InitOptionsDB()
	TELLMEWHEN_ICONSPACING = db.profile.Spacing
	if LBF then
		LBF:RegisterSkinCallback("TellMeWhen", TellMeWhen_SkinCallback, self)
	end
	TMW:RegisterEvent("PLAYER_ENTERING_WORLD","EnteringWorld")
	
	local f = CreateFrame('Frame', nil, InterfaceOptionsFrame)
	f:SetScript('OnShow', function()
		TMW.DoInitializeOptions = true
		TMW:CompileOptions()
	end)
	TMW.VarsLoaded = true
end

function TMW:OnProfile()
	db.profile.Version = db.profile.Version or TELLMEWHEN_VERSION -- this is for new profiles
	if db.profile.Version < TELLMEWHEN_VERSION then
		TMW:Upgrade()
	end
	TMW:Update()
	TMW:CompileOptions()
end

function TMW:Upgrade()
	if TellMeWhen_Settings and TellMeWhen_Settings.Version < "3.0.0" then -- needs to be the first one
		for k,v in pairs(TellMeWhen_Settings) do
			db.profile[k] = v
		end
		TMW.db = AceDB:New("TellMeWhenDB", TMW.Defaults)
		db = TMW.db
		db.profile.Version = TellMeWhen_Settings.Version
		TellMeWhen_Settings = nil
	end
	
	if db.profile.Version < "1.1.4" then
		db:ResetProfile()
		return
	end
	if db.profile.Version < "1.2.0" then
		db.profile["Spec"] = nil
	end
	if db.profile.Version < "1.4.5" then
		for groupID = 1, 8 do
			local group = _G["TellMeWhen_Group"..groupID] or CreateFrame("Frame","TellMeWhen_Group"..groupID, UIParent, "TellMeWhen_GroupTemplate", groupID)
			local p = db.profile.Groups[groupID]["Point"]
			p.point,_,p.relativePoint,p.x,p.y = group:GetPoint(1)
		end
	end
	if db.profile.Version < "1.5.3" then
		for groupID = 1, 8 do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID]["Alpha"] > 1 then
					db.profile.Groups[groupID].Icons[iconID]["Alpha"] = (db.profile.Groups[groupID].Icons[iconID]["Alpha"] / 100)
				else
					db.profile.Groups[groupID].Icons[iconID]["Alpha"] = 1
				end
			end
		end
	end
	if db.profile.Version < "1.5.4" then
		for groupID = 1, 8 do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID]["Alpha"] == 0.01 then db.profile.Groups[groupID].Icons[iconID]["Alpha"] = 1 end
			end
		end
	end
	if db.profile.Version < "2.0.1" then
		local needtowarn = ""
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				for k,v in pairs(db.profile.Groups[groupID].Icons[iconID]["Conditions"]) do
					v.ConditionLevel = tonumber(v.ConditionLevel) or 0
					if ((v.ConditionType == "SOUL_SHARDS") or (v.ConditionType == "HOLY_POWER")) and (v.ConditionLevel > 3) then
						needtowarn = needtowarn .. (format(L["GROUPICON"],groupID,iconID)) .. ";  "
						v.ConditionLevel = ceil((v.ConditionLevel/100)*3)
					end
				end
			end
		end
		if needtowarn ~= "" then
			tinsert(TMW.Warns,L["HPSSWARN"] .. " " .. needtowarn)
		end
	end
	if db.profile.Version < "2.0.2.1" then
		local needtowarn = ""
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				for k,v in pairs(db.profile.Groups[groupID].Icons[iconID]["Conditions"]) do
					local isgood = false
					for z,x in pairs(TMW.IconMenu_SubMenus.Unit) do
						if v.ConditionUnit and v.ConditionUnit == x.value then
							isgood = true
						end
					end
					if not isgood then
						needtowarn = needtowarn .. (format(L["GROUPICON"],groupID,iconID)) .. ";  "
						v.Unit = "player"
					end
				end
			end
		end
		if needtowarn ~= "" then
			tinsert(TMW.Warns,"The following icons have had the unit that their conditions check changed/fixed. You may wish to check them: " .. needtowarn)
		end
	end
	if db.profile.Version < "2.1.0" then
		if db.profile.Font.Path == "FontsARIALN.TTF" then db.profile.Font.Path = "Fonts\\ARIALN.TTF" end --i screwed something up and only put a single slash in at first that just acted as an escape so it dissapeared
	end
	if db.profile.Version < "2.1.2" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] == "thrown" then
					db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] = "RangedSlot"
				elseif db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] == "offhand" then
					db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] = "SecondaryHandSlot"
				elseif db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] == "mainhand" then --idk why this would happen, but you never know
					db.profile.Groups[groupID].Icons[iconID]["WpnEnchantType"] = "MainHandSlot"
				end
			end
		end
	end
	if db.profile.Version < "2.2.0" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID]["Conditions"] then
					for k,v in pairs(db.profile.Groups[groupID].Icons[iconID]["Conditions"]) do
						if ((v.ConditionType == "ICON") or (v.ConditionType == "EXISTS") or (v.ConditionType == "ALIVE")) then
							db.profile.Groups[groupID].Icons[iconID]["Conditions"][k]["ConditionLevel"] = 0
						end
					end
				end
			end
		end
	end
	if db.profile.Version < "2.2.0.1" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				for i in pairs(db.profile.Groups[groupID].Icons[iconID]["Conditions"]) do
					local temp = {}
					for k,v in pairs(db.profile.Groups[groupID].Icons[iconID]["Conditions"][i]) do
						temp[gsub(k,"Condition","")] = v
					end
					db.profile.Groups[groupID].Icons[iconID]["Conditions"][i] = CopyTable(temp)
				end
			end
		end
	end
	if db.profile.Version < "2.2.1" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID]["UnitReact"] and db.profile.Groups[groupID].Icons[iconID]["UnitReact"] ~= 0 then
					tinsert(db.profile.Groups[groupID].Icons[iconID]["Conditions"],{
						["Type"] = "REACT",
						["Level"] = db.profile.Groups[groupID].Icons[iconID]["UnitReact"],
						["Unit"] = "target",
					})
				end
			end
		end
	end
	if db.profile.Version < "2.3.0" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID].StackMin ~= TMW.Icon_Defaults.StackMin then
					db.profile.Groups[groupID].Icons[iconID].StackMinEnabled = true
				end
				if db.profile.Groups[groupID].Icons[iconID].StackMax ~= TMW.Icon_Defaults.StackMax then
					db.profile.Groups[groupID].Icons[iconID].StackMaxEnabled = true
				end
			end
		end
	end
	if db.profile.Version < "2.4.0" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				db.profile.Groups[groupID].Icons[iconID].Name = gsub(db.profile.Groups[groupID].Icons[iconID].Name,"StunnedOrIncapacitated","Stunned;Incapacitated")
				db.profile.Groups[groupID].Icons[iconID].Name = gsub(db.profile.Groups[groupID].Icons[iconID].Name,"IncreasedSPboth","IncreasedSPsix;IncreasedSPten")
				if db.profile.Groups[groupID].Icons[iconID].Type == "darksim" then
					db.profile.Groups[groupID].Icons[iconID].Type = "multistatecd"
					db.profile.Groups[groupID].Icons[iconID].Name = "77606"
				end
			end
		end
	end
	if db.profile.Version < "2.4.1" then
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				if db.profile.Groups[groupID].Icons[iconID].Type == "meta" and type(db.profile.Groups[groupID].Icons[iconID].Icons) == "table" then
					for k,v in pairs(db.profile.Groups[groupID].Icons[iconID].Icons) do
						tinsert(db.profile.Groups[groupID].Icons[iconID].Icons,k)
						db.profile.Groups[groupID].Icons[iconID].Icons[k] = nil
					end
				end
			end
		end
	end
	if db.profile.Version < "3.0.0" then
		db.profile.NumGroups = 10
		db.profile.Condensed = nil
		db.profile.NumCondits = nil
		db.profile.DSN = nil
		db.profile.UNUSEColor = nil
		db.profile.USEColor = nil
		if db.profile.Font.Outline == "THICK" then db.profile.Font.Outline = "THICKOUTLINE" end --oops
		for groupID = 1, TELLMEWHEN_MAXGROUPS do
			db.profile.Groups[groupID].Point.defined = true
			db.profile.Groups[groupID].LBFGroup = nil
			for k,v in pairs(db.profile.Groups[groupID].Stance) do
				oldp(k,v)
				if TMW.CSN[k] then
					if v then
						db.profile.Groups[groupID].Stance[TMW.CSN[k]] = false
					else
						db.profile.Groups[groupID].Stance[TMW.CSN[k]] = true
					end
					db.profile.Groups[groupID].Stance[k] = true
				end
			end
			for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
				for k,v in pairs(TMW.DeletedIconSettings) do
					if db.profile.Groups[groupID].Icons[iconID][k] ~= nil then
						db.profile.Groups[groupID].Icons[iconID][k] = nil
					end
				end
				-- this is part of the old CondenseSettings (but modified slightly), just to get rid of values that are defined in the saved variables that dont need to be (basically, they were set automatically on accident, most of them in early versions)
				local n = 0
				for s,v in pairs(db.profile.Groups[groupID].Icons[iconID]) do
					if (not (v == TMW.Icon_Defaults[s])) and ((s == "Enabled") or (s == "ShowTimerText")) then
						n = n+1
					end
				end
				if n == 1 or n == 2 then
					local wipeit = true
					for s,v in pairs(db.profile.Groups[groupID].Icons[iconID]) do
						if (not (v == TMW.Icon_Defaults[s] or type(v) == "table")) and not ((s == "Enabled") or (s == "ShowTimerText")) then
							wipeit = false
						end
					end
					if wipeit then
						db.profile.Groups[groupID].Icons[iconID] = nil
					end
				end
			end
		end
	end
	--All Upgrades Complete
	db.profile.Version = TELLMEWHEN_VERSION
end

function TMW:Update()
	if not (TMW.EnteredWorld and TMW.VarsLoaded) then return end
	UPDATE_INTERVAL = db.profile.Interval or UPDATE_INTERVAL
	TELLMEWHEN_ICONSPACING = db.profile.Spacing
	TELLMEWHEN_MAXGROUPS = db.profile.NumGroups
	local i=1
	while _G["TellMeWhen_Group"..i] do
		_G["TellMeWhen_Group"..i]:Hide()
		i=i+1
	end
	wipe(TMW.Icons)
	TMW:ColorUpdate()
	for groupID = 1, TELLMEWHEN_MAXGROUPS do
		TMW:Group_Update(groupID)
	end
	BarGCD = db.profile["BarGCD"]
	ClockGCD = db.profile["ClockGCD"]
	pGUID = UnitGUID("player")
	TMW.Initd = true
	if not db.profile.Locked then
		TMW:CheckForInvalidIcons()
	end
end

function TMW:CheckForInvalidIcons()
	for gID in pairs(db.profile.Groups) do
		local group = _G["TellMeWhen_Group"..gID]
		if group and group.Enabled and group.CorrectSpec then
			for iID in pairs(db.profile.Groups[gID].Icons) do
				if db.profile.Groups[gID].Icons[iID].Conditions then
					for k,v in pairs(db.profile.Groups[gID].Icons[iID].Conditions) do
						if v.Icon and v.Icon ~= "" then
							if not tContains(TMW.Icons,v.Icon) then
								local g,i = strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon(%d+)")
								g,i = tonumber(g), tonumber(i)
								if TMW.Warned then
									DEFAULT_CHAT_FRAME:AddMessage(TELLMEWHEN_WARNINGSTRING .. "|cff7fffff"..format(L["CONDITIONORMETA_CHECKINGINVALID"],gID,iID,g,i))
								else
									TMW.Warns[gID.."-"..iID.."-"..g.."-"..i] = "|cff7fffff"..format(L["CONDITIONORMETA_CHECKINGINVALID"],gID,iID,g,i)
								end
							end
						end
					end
				end
				if db.profile.Groups[gID].Icons[iID].Type == "meta" then
					for k,v in pairs(db.profile.Groups[gID].Icons[iID].Icons) do
						if not tContains(TMW.Icons,v) then
							local g,i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
							g,i = tonumber(g), tonumber(i)
							if TMW.Warned then
								DEFAULT_CHAT_FRAME:AddMessage(TELLMEWHEN_WARNINGSTRING .. "|cff7fffff"..format(L["CONDITIONORMETA_CHECKINGINVALID"],gID,iID,g,i))
							else
								TMW.Warns[gID.."-"..iID.."-"..g.."-"..i] = "|cff7fffff"..format(L["CONDITIONORMETA_CHECKINGINVALID"],gID,iID,g,i)
							end
						end
					end
				end
			end
		end
	end
end

function TMW:ColorUpdate()
	st = db.profile.CDSTColor
	co = db.profile.CDCOColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
end

function TMW:EnteringWorld()
	if not TMW.VarsLoaded then return end
	TMW.EnteredWorld = true
	TMW:RegisterEvent("PLAYER_TALENT_UPDATE", "TalentUpdate")
	TMW:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "TalentUpdate")
	if not TMW.Warned then
		TMW:CancelTimer(warnhandler, 1)
		warnhandler = TMW:ScheduleTimer("Warn",20)
	end
	TMW:SetScript("OnUpdate", TMW.OnUpdate)
	TMW:Update()
end

function TMW:TalentUpdate()
	TMW:CancelTimer(talenthandler, 1)
	talenthandler = TMW:ScheduleTimer("Update",1)
end

function TMW:Warn()
	for k,v in pairs(TMW.Warns) do
		DEFAULT_CHAT_FRAME:AddMessage(TELLMEWHEN_WARNINGSTRING .. v)
	end
	TMW.Warned = true
end

function TMW:OnUpdate()
	_,GCD=GetSpellCooldown(GCDSpell)
end

-- -----------
-- GROUP FRAME
-- -----------

local function Group_StanceCheck(group)
	if not group.CorrectSpec then
		return
	end
	if #(TMW.CSN) == 0 then group.CorrectStance = true return end 
	
	local groupID = group:GetID()
	local index = GetShapeshiftForm()

	if pclass == "WARLOCK" and index == 2 then  --UGLY HACK FOR METAMORPHOSIS, IT IS INDEX 2 FOR SOME REASON
		index = 1
	end
	if pclass == "ROGUE" and index >= 2 then	--UGLY FIX FOR ROGUES, VANISH AND SHADOW DANCE RETURN 3 WHEN ACTIVE, VANISH RETURNS 2 WHEN SHADOW DANCE ISNT LEARNED.
		index = 1
	end
	if index > GetNumShapeshiftForms() then --MANY CLASSES RETURN AN INVALID NUMBER ON LOGIN, BUT NOT ANYMORE!
		index = 0
	end
	if index == 0 then
		if db.profile.Groups[groupID]["Stance"][TMW.CSN[0]] then
			group.CorrectStance = true
		else
			group.CorrectStance = false
		end
	elseif index then
		local _, name = GetShapeshiftFormInfo(index)
		for k,v in pairs(TMW.CSN) do
			if v == name then
				if db.profile.Groups[groupID]["Stance"][name] then
					group.CorrectStance = true
				else
					group.CorrectStance = false
				end
			end
		end
	end
end

local function Group_ShowHide(group)
	local combat = UnitAffectingCombat("player")
	local vehicle = UnitHasVehicleUI("player")
	
	if group.CorrectStance then
		if group.OnlyInCombat and group.NotInVehicle then
			if combat then
				if vehicle then
					group:Hide()
				else
					group:Show()
				end
			else
				group:Hide()
			end
		elseif group.OnlyInCombat then
			if combat then
				group:Show()
			else
				group:Hide()
			end
		elseif group.NotInVehicle then
			if vehicle then
				group:Hide()
			else
				group:Show()
			end
		else
			group:Show()
		end
	else
		group:Hide()
	end
end

local function Group_OnEvent(group, event,...)
	if event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
		Group_StanceCheck(group)
	end
	if (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and ... ~= "player" then return end
		Group_ShowHide(group)
end

function TMW:Group_Update(groupID)
	local groupName = "TellMeWhen_Group"..groupID
	local group = _G[groupName] or CreateFrame("Frame",groupName, UIParent, "TellMeWhen_GroupTemplate",groupID)
	group:SetID(groupID)
	group.groupName = groupName
	group.CorrectStance = true
	
	for k,v in pairs(TMW.Defaults.profile.Groups["**"]) do
		group[k] = db.profile.Groups[groupID][k]
	end

	local locked = db.profile["Locked"]
	
	group.CorrectSpec = true

	local function TalentIsLearned(key)
		if not key or key == "0" then return false end
		local tab, idx = strmatch(key, "^(%d+):(%d+)$")
		tab, idx = tonumber(tab), tonumber(idx)
		if not tab or not idx then return false end
		local _, _, _, _, rank = GetTalentInfo(tab, idx)
		return rank and rank > 0
	end

	local hide = group.HideTalents
	local show = group.ShowTalents

	if hide then
		for i = 1, 5 do
			local key = hide[i]
			if key and key ~= "0" and TalentIsLearned(key) then
				group.CorrectSpec = false
				break
			end
		end
	end

	if group.CorrectSpec and show then
		local anyShow = false
		for i = 1, 5 do
			local key = show[i]
			if key and key ~= "0" then
				anyShow = true
				if not TalentIsLearned(key) then
					group.CorrectSpec = false
					break
				end
			end
		end
	end
	
	if LBF then
		TMW.DontRun = true
		local lbfs = db.profile.Groups[groupID]["LBF"]
		LBF:Group("TellMeWhen", L["GROUP"] .. groupID)
		if lbfs.SkinID then
			LBF:Group("TellMeWhen", L["GROUP"] .. groupID):Skin(lbfs.SkinID,lbfs.Gloss,lbfs.Backdrop,lbfs.Colors)
		end
	end
	group:SetSize(group.Columns*30,group.Rows*30)
	if group.Enabled and group.CorrectSpec then
		for row = 1, group.Rows do
			for column = 1, group.Columns do
				local iconID = (row-1)*group.Columns + column
				local iconName = group.groupName.."_Icon"..iconID
				local icon = _G[iconName] or CreateFrame("Button", iconName, group, "TellMeWhen_IconTemplate",iconID)
				local powerbarname = iconName.."_PowerBar"
				local cooldownbarname = iconName.."_CooldownBar"
				icon.powerbar = icon.powerbar or CreateFrame("StatusBar",powerbarname,icon)
				icon.cooldownbar = icon.cooldownbar or CreateFrame("StatusBar",cooldownbarname,icon)
				icon:Show()
				if (column > 1) then
					icon:SetPoint("TOPLEFT", _G[group.groupName.."_Icon"..(iconID-1)], "TOPRIGHT", TELLMEWHEN_ICONSPACING, 0)
				elseif (row > 1) and (column == 1) then
					icon:SetPoint("TOPLEFT", _G[group.groupName.."_Icon"..(iconID-group.Columns)], "BOTTOMLEFT", 0, -TELLMEWHEN_ICONSPACING)
				elseif (iconID == 1) then
					icon:SetPoint("TOPLEFT", group, "TOPLEFT")
				end
				TMW:Icon_Update(icon)
			end
		end
		for iconID = group.Rows*group.Columns+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
			local icon = _G[group.groupName.."_Icon"..iconID]
			if icon then
				icon:Hide()
				ClearScripts(icon)
			end
		end

		group:SetScale(group.Scale)
		local lastIcon = group.groupName.."_Icon"..(group.Rows*group.Columns)
		group.resizeButton:SetPoint("BOTTOMRIGHT", lastIcon, "BOTTOMRIGHT", 3, -3)
		if (locked) then
			group.resizeButton:Hide()
		else
			group.resizeButton:Show()
		end

	end
	TMW:Group_SetPosition(group,groupID)

	if group.OnlyInCombat then
		group:RegisterEvent("PLAYER_REGEN_ENABLED")
		group:RegisterEvent("PLAYER_REGEN_DISABLED")
		group:RegisterEvent("PLAYER_ALIVE")
		group:RegisterEvent("PLAYER_DEAD")
		group:RegisterEvent("PLAYER_UNGHOST")
	end
	
	if group.NotInVehicle then
		group:RegisterEvent("UNIT_ENTERED_VEHICLE")
		group:RegisterEvent("UNIT_EXITED_VEHICLE")
	end
	
	if group.Enabled and group.CorrectSpec and locked then
		Group_ShowHide(group)
		if #(TMW.CSN) > 0 then
			group:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
			group:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
			Group_StanceCheck(group)
		end
		Group_ShowHide(group)
	else
		group:UnregisterAllEvents()
		if group.Enabled and group.CorrectSpec then
			group:Show()
		else
			group:Hide()
		end
	end

	group:SetScript("OnEvent", Group_OnEvent)
end

-- -------------
-- ICON SCRIPTS
-- -------------

local function OnGCD(d)
	if GCD > 1.7 then return false end
	if d == 1 then return true end
	return GCD == d and d > 0
end

local function ConditionCheck(Cs)
	local retCode = TMW_CNDT[Cs[1].Type](Cs[1])
	for i=2,#Cs do
		local c = Cs[i]
		if c.AndOr == "OR" then
			retCode = retCode or TMW_CNDT[c.Type](c)
		else
			retCode = retCode and TMW_CNDT[c.Type](c)
		end
	end
	return retCode
end

local function SetCD(cd, startTime, duration)
	cd.Start = startTime
	cd.Duration = duration
	if ( startTime and startTime > 0 and duration > 0) then
		cd:SetCooldown(startTime, duration)
		cd:Show()
	else
		cd:Hide()
	end
end

local function CDBarOnUpdate(bar)
	local startTime = bar.startTime
	local duration = bar.duration
	if not bar.icon.InvertBars then
		if duration == 0 then
			bar:SetValue(0)
		else
			bar:SetMinMaxValues(0,  duration)
			bar:SetValue(duration - (GetTime() - startTime))
		end
	else
		--inverted
		if duration == 0 then
			bar:SetMinMaxValues(0,1)
			bar:SetValue(1)
		else
			bar:SetMinMaxValues(0, duration)
			bar:SetValue((GetTime() - startTime))
		end
	end
end

local function CDBarOnValueChanged(bar)
	local startTime = bar.startTime
	local duration = bar.duration
	local percentcomplete = 1
	if not bar.icon.InvertBars then
		if duration ~= 0 then
			percentcomplete = ((GetTime() - bar.startTime) / duration)
			bar.texture:SetTexCoord(0, min((1-percentcomplete),1), 0, 1)
			bar:SetStatusBarColor(
				(co.r*percentcomplete) + (st.r * (1-percentcomplete)),
				(co.g*percentcomplete) + (st.g * (1-percentcomplete)),
				(co.b*percentcomplete) + (st.b * (1-percentcomplete)),
				(co.a*percentcomplete) + (st.a * (1-percentcomplete))
			)
		end
	else
		--inverted
		if duration == 0 then
			bar:SetStatusBarColor(co.r, co.g, co.b, co.a)
			bar.texture:SetTexCoord(0, 1, 0, 1)
		else
			percentcomplete = (((GetTime() - bar.startTime) / duration))
			bar.texture:SetTexCoord(0, min(percentcomplete,1), 0, 1)
			bar:SetStatusBarColor(
				(co.r*percentcomplete) + (st.r * (1-percentcomplete)),
				(co.g*percentcomplete) + (st.g * (1-percentcomplete)),
				(co.b*percentcomplete) + (st.b * (1-percentcomplete)),
				(co.a*percentcomplete) + (st.a * (1-percentcomplete))
			)
		end
	end
end

local function CDBarStart(icon,startTime,duration,buff)
	local bar = icon.cooldownbar
	bar.startTime = startTime
	if OnGCD(duration) and not buff and not BarGCD then
		duration = 0
	end
	bar.duration = duration
	if not bar:GetScript("OnUpdate") then
		bar:SetScript("OnUpdate",CDBarOnUpdate)
		bar:SetScript("OnValueChanged",CDBarOnValueChanged)
	end
end

local function PwrBarOnUpdate(bar)
	local cost = bar.cost
	bar:SetMinMaxValues(0, cost)
	local power = UnitPower("player",bar.powerType)
	bar.power = power
	if not bar.icon.InvertBars then
		bar:SetValue(cost - power)
	else
		bar:SetValue(power)
	end
end

local function PwrBarOnValueChanged(bar)
	if not bar.icon.InvertBars then
		local cost = bar.cost
		bar.texture:SetTexCoord(0, max(0,min(((cost - bar.power) / cost),1)), 0, 1)
	else
		bar.texture:SetTexCoord(0, max(0,min((bar.power / bar.cost),1)), 0, 1)
	end
end

local function PwrBarStart(icon,name)
	local bar = icon.powerbar
	bar.name = name
	_,_,_,bar.cost,_,bar.powerType = GetSpellInfo(name)
	if not bar:GetScript("OnUpdate") and bar.cost then
		bar:SetScript("OnUpdate",PwrBarOnUpdate)
		bar:SetScript("OnValueChanged",PwrBarOnValueChanged)
	end
end


local function SpellCooldown_OnEvent(icon)
	local startTime, duration = GetSpellCooldown(icon.NameFirst)
	if (not icon.ShowTimer) or ((not ClockGCD) and OnGCD(duration)) then SetCD(icon.cooldown, 0, 0) return end
	if duration then
		SetCD(icon.cooldown, startTime, duration)
	end
end

local function SpellCooldown_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		local Name = icon.NameFirst
		local NameName = icon.NameName
		local startTime, duration = GetSpellCooldown(Name)
		if duration and NameName then
			if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
				local a = icon.ConditionAlpha
				icon:SetAlpha(a)
				icon.FakeAlpha = a
				return
			end
			if icon.IgnoreRunes then
				if startTime == GetSpellCooldown(45477) or startTime == GetSpellCooldown(45462) or startTime == GetSpellCooldown(45902) then
					startTime, duration = 0, 0
				end
				if not icon.ShowTimer then
					SetCD(icon.cooldown, 0, 0)
				else
					SetCD(icon.cooldown, startTime, duration)
				end
			end
			if icon.ShowCBar then
				CDBarStart(icon,startTime,duration)
			end
			if icon.ShowPBar then
				PwrBarStart(icon,Name)
			end
			if icon.Duration then
				local remaining = duration - (GetTime() - startTime)
				if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
					local a = icon.DurationAlpha
					icon:SetAlpha(a)
					icon.FakeAlpha = a
					if icon.FakeHidden then icon:SetAlpha(0) end
					return
				end
			end
			local active = true
			if icon.ChakraID then
				if UnitAura("player",GetSpellInfo(Chakra[icon.ChakraID]["buffid"])) then
					active = true
				else
					active = false
				end
			end
			local inrange = IsSpellInRange(NameName, "target")
			local _, nomana = IsUsableSpell(Name)
			if not icon.RangeCheck or not inrange then
				inrange = 1
			end
			if not icon.ManaCheck then
				nomana = nil
			end

			if ((duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana and active) then
				icon.texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.PresUsableAlpha)
			elseif (icon.PresUsableAlpha ~= 0 and active) then
				if inrange ~= 1 then
					icon.texture:SetVertexColor(rc.r, rc.g, rc.b, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha*rc.a)
				elseif nomana then
					icon.texture:SetVertexColor(mc.r, mc.g, mc.b, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha*mc.a)
				elseif not icon.ShowTimer then
					icon.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha)
				else
					icon.texture:SetVertexColor(1, 1, 1, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha)
				end
			else
				icon.texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			end
			icon.FakeAlpha = icon:GetAlpha()
			if icon.FakeHidden then
				icon:SetAlpha(0)
			end
		elseif (not NameName) and duration then
			ClearScripts(icon)
			if TMW.Warned then
				DEFAULT_CHAT_FRAME:AddMessage(TELLMEWHEN_WARNINGSTRING .. icon:GetName() .. L["ERRSPAMWARN"])
			else
				TMW.Warns[tonumber(icon:GetID() .. icon:GetParent():GetID())] = icon:GetName() .. L["ERRSPAMWARN"]
			end
		end
	end
end

local function ItemCooldown_OnEvent(icon, event, ...)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		local slot, has = ...
		if icon.Slot == slot and has then
			icon.NameFirst = TMW:GetItemIDs(icon,icon.Name,1)
			local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(icon.NameFirst)
			if (itemTexture) then
				icon.texture:SetTexture(itemTexture)
				if icon.ShowTimer then
					icon:RegisterEvent("BAG_UPDATE_COOLDOWN")
				end
			else
				icon.LearnedTexture = false
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
		elseif icon.Slot == slot then
			icon.NameFirst = 0
			icon.LearnedTexture = false
			icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
		return
	end
	local startTime, duration = GetItemCooldown(icon.NameFirst)
	if (not ClockGCD) and OnGCD(duration) then SetCD(icon.cooldown, 0, 0) return end
	if duration then
		SetCD(icon.cooldown, startTime, duration)
	end
end

local function ItemCooldown_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	local NameFirst = icon.NameFirst
	local startTime, duration = GetItemCooldown(NameFirst)
	if icon.UpdateTimer <= 0 and duration then
		icon.UpdateTimer = UPDATE_INTERVAL
		if icon.ShowCBar then
			CDBarStart(icon,startTime,duration)
		end
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		if icon.Duration then
			local remaining = duration - (GetTime() - startTime)
			if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
				local a = icon.DurationAlpha
				icon:SetAlpha(a)
				icon.FakeAlpha = a
				if icon.FakeHidden then icon:SetAlpha(0) end
				return
			end
		end
		local inrange = IsItemInRange(NameFirst, "target")
		if (not icon.RangeCheck or inrange == nil) then
			inrange = 1
		end
		if (duration == 0 or OnGCD(duration)) and inrange == 1 then
			icon.texture:SetVertexColor(1, 1, 1, 1)
			icon:SetAlpha(icon.PresUsableAlpha)
		elseif (icon.PresUsableAlpha ~= 0) then
			if inrange ~= 1 then
				icon.texture:SetVertexColor(rc.r, rc.g, rc.b, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha*rc.a)
			elseif not icon.ShowTimer then
				icon.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			else
				icon.texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			end
		else
			icon.texture:SetVertexColor(1, 1, 1, 1)
			icon:SetAlpha(icon.AbsentUnUsableAlpha)
		end
		icon.FakeAlpha = icon:GetAlpha()
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function Buff_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if icon.ConditionPresent and not ConditionCheck(icon.Conditions) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		local unit,filter,filterh,nna = icon.Unit,icon.Filter,icon.Filterh,icon.NameNameArray
		local texture = icon.texture
		local us,un = icon.PresUsableAlpha,icon.AbsentUnUsableAlpha
		if UnitExists(unit) then
			for i, iName in pairs(icon.NameArray) do
				if icon.ShowPBar then
					PwrBarStart(icon,iName)
				end
				local buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, nna[i], nil, filter)
				if DS[iName] then
					for z=1,60 do --60 because i can and it breaks when there are no more buffs anyway
						buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, z, filter)
						if (not buffName) or (dispelType == iName) then
							break
						end
					end
					if filterh and not buffName then
						for z=1,60 do
							buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, z, filterh)
							if (not buffName) or (dispelType == iName) then
								break
							end
						end
					end
				end
				if filterh and not buffName then
					buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, nna[i], nil, filterh)
				end
				if buffName and not (id == iName) and tonumber(iName) then
					for z=1,60 do
						buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, z, filter)
						if (not id) or (id == iName) then
							break
						end
					end
					if filterh and not id then
						for z=1,60 do
							buffName, _, iconTexture, count, dispelType, duration, expirationTime,_,_,_,id = UnitAura(unit, z, filterh)
							if (not id) or (id == iName) then
								break
							end
						end
					end
				end
				if buffName then
					if count > 1 then
						icon.countText:SetText(count)
					else
						icon.countText:SetText(nil)
					end
					
					texture:SetTexture(iconTexture)
					icon.LearnedTexture = true
					icon:SetAlpha(us)

					if us ~= 0 and un ~= 0 then
						texture:SetVertexColor(pr.r, pr.g, pr.b, 1)
					else
						texture:SetVertexColor(1, 1, 1, 1)
					end
					
					if icon.ShowTimer then
						SetCD(icon.cooldown, expirationTime - duration, duration)
					end
					if icon.ShowCBar then
						CDBarStart(icon, expirationTime - duration, duration,true)
					end
					if count and icon.Stacks then
						if (icon.StackMinEnabled and not (icon.StackMin <= count)) or  (icon.StackMaxEnabled and not (count <= icon.StackMax)) then
							local a = icon.StackAlpha
							icon:SetAlpha(a)
							icon.FakeAlpha = a
							if icon.FakeHidden then icon:SetAlpha(0) end
							return
						end
					end
					if expirationTime ~= 0 and icon.Duration then
						local remaining = expirationTime - GetTime()
						if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
							local a = icon.DurationAlpha
							icon:SetAlpha(a)
							icon.FakeAlpha = a
							if icon.FakeHidden then icon:SetAlpha(0) end
							return
						end
					end
					icon.FakeAlpha = us
					if icon.FakeHidden then
						icon:SetAlpha(0)
					end
					return
				end
			end
		end
		
		ClearScripts(icon.cooldownbar)
		icon.cooldownbar:SetValue(-1)
		icon:SetAlpha(un)
		if us ~= 0 and un ~= 0 then
			texture:SetVertexColor(ab.r, ab.g, ab.b, 1)
		else
			texture:SetVertexColor(1, 1, 1, 1)
		end
		
		local nf = icon.NameFirst
		if nf then
			local t = GetSpellTexture(nf)
			if t then
				texture:SetTexture(t)
			end
		end
		icon.countText:SetText(nil)
		if icon.ShowTimer then
			icon.cooldown:Hide()
		end
		icon.FakeAlpha = un
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function Reactive_OnUpdate(icon,elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	local name = icon.NameFirst
	local startTime, duration = GetSpellCooldown(name)
	if duration and icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if icon.ShowCBar then
			CDBarStart(icon,startTime,duration)
		end
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		if duration and icon.Duration then
			local remaining = duration - (GetTime() - startTime)
			if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
				local a = icon.DurationAlpha
				icon:SetAlpha(a)
				icon.FakeAlpha = a
				if icon.FakeHidden then icon:SetAlpha(0) end
				return
			end
		end
		local usable, nomana = IsUsableSpell(name)
		if icon.ChakraID then
			if UnitAura("player",GetSpellInfo(Chakra[icon.ChakraID]["buffid"])) then
				usable = true
			else
				usable = false
			end
		end
		local inrange = IsSpellInRange(icon.NameName, "target")
		if (not icon.RangeCheck or inrange == nil) then
			inrange = 1
		end
		if not icon.ManaCheck then
			nomana = nil
		end
		local CD = false
		if icon.CooldownCheck then
			if not (duration == 0 or OnGCD(duration)) then
				CD = true
			end
		end
		if (usable and not CD) then
			if(inrange == 1 and not nomana) then
				icon.texture:SetVertexColor(1,1,1,1)
				icon:SetAlpha(icon.PresUsableAlpha)
			elseif (inrange ~= 1 or nomana) then
				if inrange ~= 1 then
					icon.texture:SetVertexColor(rc.r, rc.g, rc.b, 1)
					icon:SetAlpha(icon.PresUsableAlpha*rc.a)
				elseif nomana then
					icon.texture:SetVertexColor(mc.r, mc.g, mc.b, 1)
					icon:SetAlpha(icon.PresUsableAlpha*mc.a)
				end
			else
				icon.texture:SetVertexColor(1,1,1,1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			end
		else
			icon.texture:SetVertexColor(0.5,0.5,0.5,1)
			icon:SetAlpha(icon.AbsentUnUsableAlpha)
		end
	end
	icon.FakeAlpha = icon:GetAlpha()
	if icon.FakeHidden then
		icon:SetAlpha(0)
	end
end

local function WpnEnchant_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		local i = SlotsToNumbers[icon.WpnEnchantType] or 1
		local has, expiration, charges = select(i,GetWeaponEnchantInfo())
		if has then
			expiration = expiration/1000
			if icon.PresUsableAlpha ~= 0 and icon.AbsentUnUsableAlpha ~= 0 then
				icon.texture:SetVertexColor(pr.r, pr.g, pr.b, 1)
			else
				icon.texture:SetVertexColor(1, 1, 1, 1)
			end
			icon:SetAlpha(icon.PresUsableAlpha)
			if (charges > 1) then
				icon.countText:SetText(charges)
			else
				icon.countText:SetText(nil)
			end
			if icon.ShowTimer then
				SetCD(icon.cooldown, GetTime(), expiration)
			end
			if icon.Duration then
				if (icon.DurationMinEnabled and not (icon.DurationMin <= expiration)) or  (icon.DurationMaxEnabled and not (expiration <= icon.DurationMax)) then
					local a = icon.DurationAlpha
					icon:SetAlpha(a)
					icon.FakeAlpha = a
					if icon.FakeHidden then icon:SetAlpha(0) end
					return
				end
			end
		else
			local un = icon.AbsentUnUsableAlpha
			if icon.PresUsableAlpha ~= 0 and un ~= 0 then
				icon.texture:SetVertexColor(ab.r, ab.g, ab.b, 1)
			else
				icon.texture:SetVertexColor(1, 1, 1, 1)
			end
			icon:SetAlpha(un)
			SetCD(icon.cooldown, 0, 0)
		end
		icon.FakeAlpha = icon:GetAlpha()
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function WpnEnchant_OnEvent(icon, event, r)
	if (r == "player") then
		local slotID = GetInventorySlotInfo(icon.WpnEnchantType)
		local wpnTexture = GetInventoryItemTexture("player", slotID)
		if (not wpnTexture) and icon.HideUnequipped then
			icon:SetAlpha(0)
			icon.FakeAlpha = 0
			icon:SetScript("OnUpdate", nil)
		else
			icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
		end
		if wpnTexture then
			icon.texture:SetTexture(wpnTexture)
		else
			icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
end

local function Totem_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		local texture = icon.texture
		for iSlot=1, 4 do
			local _, totemName, startTime, duration, totemIcon = GetTotemInfo(iSlot)
			if icon.NameFirst == "" or icon.NameNameDictionary[totemName] then
				if icon.ShowPBar then
					PwrBarStart(icon,iName)
				end
				if icon.ShowCBar then
					CDBarStart(icon,startTime,duration,1)
				end
				local us = icon.PresUsableAlpha
				if us ~= 0 and icon.AbsentUnUsableAlpha ~= 0 then
					texture:SetVertexColor(pr.r, pr.g, pr.b, 1)
				else
					texture:SetVertexColor(1, 1, 1, 1)
				end
				icon:SetAlpha(us)

				if texture:GetTexture() ~= totemIcon then
					texture:SetTexture(totemIcon)
					icon.LearnedTexture = true
				end

				if icon.ShowTimer then
					SetCD(icon.cooldown, startTime, duration)
				end
				if duration and icon.Duration then
					local remaining = duration - (GetTime() - startTime)
					if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
						local a = icon.DurationAlpha
						icon:SetAlpha(a)
						icon.FakeAlpha = a
						if icon.FakeHidden then icon:SetAlpha(0) end
						return
					end
				end
				
				icon.FakeAlpha = us
				if icon.FakeHidden then
					icon:SetAlpha(0)
				end
				return
			end
		end
		local nn = icon.NameName
		if nn then
			texture:SetTexture(GetSpellTexture(nn))
		end
		local un = icon.AbsentUnUsableAlpha
		if icon.PresUsableAlpha ~= 0 and un ~= 0 then
			texture:SetVertexColor(ab.r, ab.g, ab.b, 1)
		else
			texture:SetVertexColor(1, 1, 1, 1)
		end
		icon:SetAlpha(un)
		SetCD(icon.cooldown, 0, 0)
		icon.FakeAlpha = un
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function MultiStateCD_OnEvent(icon, event, ...)
	local _, spellID = GetActionInfo(icon.Slot) -- check the current slot first, because it probably didnt change
	if spellID == icon.NameFirst then
		return
	end
	for i=1,120 do
		_, spellID = GetActionInfo(i)
		if spellID == icon.NameFirst then
			icon.Slot = i
			return
		end
	end
end

local function MultiStateCD_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	local startTime, duration = GetActionCooldown(icon.Slot)
	if duration and icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if (not icon.ShowTimer) or ((not ClockGCD) and OnGCD(duration)) then
			SetCD(icon.cooldown, 0, 0)
		else
			SetCD(icon.cooldown, startTime, duration)
		end
		if icon.ShowCBar then
			CDBarStart(icon,startTime,duration)
		end
		local texture = icon.texture
		texture:SetTexture(GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		if duration and icon.Duration then
			local remaining = duration - (GetTime() - startTime)
			if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
				local a = icon.DurationAlpha
				icon:SetAlpha(a)
				icon.FakeAlpha = a
				if icon.FakeHidden then icon:SetAlpha(0) end
				return
			end
		end
		local inrange = IsActionInRange(icon.Slot, "target")
		local _, nomana = IsUsableAction(icon.Slot)
		if not icon.RangeCheck or not inrange then
			inrange = 1
		end
		if not icon.ManaCheck then
			nomana = nil
		end
		if ((duration == 0 or OnGCD(duration)) and inrange == 1 and not nomana) then
			texture:SetVertexColor(1, 1, 1, 1)
			icon:SetAlpha(icon.PresUsableAlpha)
		elseif (icon.PresUsableAlpha ~= 0) then
			if inrange ~= 1 then
				texture:SetVertexColor(rc.r, rc.g, rc.b, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha*rc.a)
			elseif nomana then
				texture:SetVertexColor(mc.r, mc.g, mc.b, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha*mc.a)
			elseif not icon.ShowTimer then
				texture:SetVertexColor(0.5, 0.5, 0.5, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			else
				texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			end
		else
			texture:SetVertexColor(1, 1, 1, 1)
			icon:SetAlpha(icon.AbsentUnUsableAlpha)
		end
		icon.FakeAlpha = icon:GetAlpha()
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function Cast_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		local unit = icon.Unit
		local us = icon.PresUsableAlpha
		local name, _, _, iconTexture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
		if not name then
			name, _, _, iconTexture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
		end
		if name then
			if icon.NameFirst == "" or icon.NameNameDictionary[name] then
				startTime, endTime = startTime/1000, endTime/1000
				if notInterruptible and icon.Interruptible then
					icon:SetAlpha(0)
					icon.FakeAlpha = 0
					if icon.FakeHidden then icon:SetAlpha(0) end
					return
				end
				local duration = endTime - startTime
				local texture = icon.texture
				texture:SetTexture(iconTexture)
				icon.LearnedTexture = true
				icon:SetAlpha(us)

				if us ~= 0 and icon.AbsentUnUsableAlpha ~= 0 then
					texture:SetVertexColor(pr.r, pr.g, pr.b, 1)
				else
					texture:SetVertexColor(1, 1, 1, 1)
				end
				
				if icon.ShowTimer then
					SetCD(icon.cooldown, startTime, duration)
				end
				if icon.ShowCBar then
					CDBarStart(icon, startTime, duration, true)
				end
				if icon.Duration then
					local remaining = endTime - GetTime()
					if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
						local a = icon.DurationAlpha
						icon:SetAlpha(a)
						icon.FakeAlpha = a
						if icon.FakeHidden then icon:SetAlpha(0) end
						return
					end
				end
				icon.FakeAlpha = icon:GetAlpha()
				if icon.FakeHidden then
					icon:SetAlpha(0)
				end
				return
			end
		end
		local un = icon.AbsentUnUsableAlpha
		ClearScripts(icon.cooldownbar)
		icon.cooldownbar:SetValue(-1)

		icon:SetAlpha(un)
		if us ~= 0 and un ~= 0 then
			icon.texture:SetVertexColor(ab.r, ab.g, ab.b, 1)
		else
			icon.texture:SetVertexColor(1, 1, 1, 1)
		end

		icon.countText:SetText(nil)
		if icon.ShowTimer then
			SetCD(icon.cooldown, 0, 0)
		end
		icon.FakeAlpha = un
		if icon.FakeHidden then
			icon:SetAlpha(0)
		end
	end
end

local function Meta_OnUpdate(icon,elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
--	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
			local a = icon.ConditionAlpha
			icon:SetAlpha(a)
			icon.FakeAlpha = a
			if icon.FakeHidden then icon:SetAlpha(0) end
			return
		end
		for k,i in pairs(icon.Icons) do
			local ic = _G[i]
			if ic then
				local shown = ic:IsShown() and ic:GetParent():IsShown() and ic.FakeAlpha > 0
				if shown then
					local iconc, icc = icon.cooldown, ic.cooldown
					iconc.noCooldownCount = icc.noCooldownCount
					local icont, ict = icon.texture, ic.texture
					icont:SetTexture(ict:GetTexture())
					icont:SetVertexColor(ict:GetVertexColor())
					local a = ic.FakeAlpha
					icon:SetAlpha(a)
					icon.FakeAlpha = a
					SetCD(iconc,icc.Start,icc.Duration)
					iconc:SetReverse(icc:GetReverse())
					icon.countText:SetText(ic.countText:GetText())
					if ic.ShowPBar then
						PwrBarStart(icon,ic.powerbar.name)
					end
					if ic.ShowCBar then
						local iccb = ic.cooldownbar
						CDBarStart(icon,iccb.startTime,iccb.duration)
					end
					return
				end
			end
		end
		icon:SetAlpha(0)
		icon.FakeAlpha = 0
	--end
end

local function ICD_OnEvent(icon,event,...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _,event,sourceGUID,_,_,_,_,_,spellID,spellName = ...
		if sourceGUID == pGUID and (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") then
			local named = icon.NameDictionary
			if named[spellName] or named[spellID] then
				icon.texture:SetTexture(GetSpellTexture(spellID))
				icon.LearnedTexture = true
				local t = GetTime()
				icon.StartTime = t
				if icon.ShowTimer then
					print(t,icon.ICDDuration)
					SetCD(icon.cooldown, t, icon.ICDDuration)
				end
			end
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit,spellName,_,_,spellID = ...
		if unit == "player" then
			local named = icon.NameDictionary
			if named[spellName] or named[spellID] then
				icon.texture:SetTexture(GetSpellTexture(spellID))
				icon.LearnedTexture = true
				local t = GetTime()
				icon.StartTime = t
				if icon.ShowTimer then
					SetCD(icon.cooldown, t, icon.ICDDuration)
				end
			end
		end
	end
end

local function ICD_OnUpdate(icon, elapsed)
	icon.UpdateTimer = icon.UpdateTimer - elapsed
	if icon.UpdateTimer <= 0 then
		icon.UpdateTimer = UPDATE_INTERVAL
		local name = icon.NameFirst
		local startTime, duration = icon.StartTime, icon.ICDDuration
		if duration then
			if icon.ShowCBar then
				CDBarStart(icon,startTime,duration)
			end
			if icon.Duration then
				local remaining = duration - (GetTime() - startTime)
				if (icon.DurationMinEnabled and not (icon.DurationMin <= remaining)) or  (icon.DurationMaxEnabled and not (remaining <= icon.DurationMax)) then
					local a = icon.DurationAlpha
					icon:SetAlpha(a)
					icon.FakeAlpha = a
					if icon.FakeHidden then icon:SetAlpha(0) end
					return
				end
			end
			if (icon.ConditionPresent and not ConditionCheck(icon.Conditions)) then
				icon:SetAlpha(icon.ConditionAlpha)
				icon.FakeAlpha = 0
				return
			end
			if (GetTime() - startTime) > duration then
				icon.texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.PresUsableAlpha)
			elseif icon.PresUsableAlpha ~= 0 then
				if not icon.ShowTimer then
					icon.texture:SetVertexColor(0.5, 0.5, 0.5, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha)
				else
					icon.texture:SetVertexColor(1, 1, 1, 1)
					icon:SetAlpha(icon.AbsentUnUsableAlpha)
				end
			else
				icon.texture:SetVertexColor(1, 1, 1, 1)
				icon:SetAlpha(icon.AbsentUnUsableAlpha)
			end
			icon.FakeAlpha = icon:GetAlpha()
			if icon.FakeHidden then
				icon:SetAlpha(0)
			end
		end
	end
end

do --Condition functions
	TMW_CNDT.HEALTH = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitHealth(condition.Unit)/UnitHealthMax(condition.Unit))
	end
	TMW_CNDT.DEFAULT = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit)/UnitPowerMax(condition.Unit))
	end
	TMW_CNDT.MANA = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,0)/UnitPowerMax(condition.Unit,0))
	end
	TMW_CNDT.RAGE = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,1)/UnitPowerMax(condition.Unit,1))
	end
	TMW_CNDT.FOCUS = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,2)/UnitPowerMax(condition.Unit,2))
	end
	TMW_CNDT.ENERGY = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,3)/UnitPowerMax(condition.Unit,3))
	end
	TMW_CNDT.RUNIC_POWER = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,6)/UnitPowerMax(condition.Unit,6))
	end
	TMW_CNDT.HAPPINESS = function(condition)
		return TMW_OP[condition.Operator](condition.Level, GetPetHappiness() or 0)
	end
	TMW_CNDT.SOUL_SHARDS = function(condition)
		return TMW_OP[condition.Operator](condition.Level, UnitPower("player",7))
	end
	TMW_CNDT.ECLIPSE = function(condition)
		return TMW_OP[condition.Operator](condition.Level, 100 * UnitPower(condition.Unit,8)/UnitPowerMax(condition.Unit,8))
	end
	TMW_CNDT.HOLY_POWER = function(condition)
		return TMW_OP[condition.Operator](condition.Level, UnitPower("player",9))
	end
	TMW_CNDT.ECLIPSE_DIRECTION = function(condition)
		local l = condition.Level
		if l <= 0 then return GetEclipseDirection() == "moon"  --  (<=) because it used to be -1 and i dont want to upgrade it
		elseif l == 1 then return GetEclipseDirection() == "sun"
		else return false end
	end
	TMW_CNDT.ICON = function(condition)
		local icon = _G[condition.Icon]
		if icon and icon:GetParent():IsShown() then
			if condition.Level == 0 then return ((icon.FakeAlpha or 0) > 0)
			elseif condition.Level == 1 then return ((icon.FakeAlpha or 0) == 0)
			else return false end
		else return false end
	end
	TMW_CNDT.COMBO = function(condition)
		return TMW_OP[condition.Operator](condition.Level, GetComboPoints("player",condition.Unit))
	end
	TMW_CNDT.EXISTS = function(condition)
		return ((condition.Level == 1) == not UnitExists(condition.Unit)) --the not turns it into a true/false instead of 1/nil (instead of ((condition.Level == 0) == UnitExists(condition.Unit)) )
	end
	TMW_CNDT.ALIVE = function(condition)
		return (((condition.Level == 0) == (not UnitIsDeadOrGhost(condition.Unit))) and UnitExists(condition.Unit))
	end
	TMW_CNDT.SPEC = function(condition)
		return (condition.Level == GetActiveTalentGroup())
	end
	TMW_CNDT.REACT = function(condition)
		local unit = condition.Unit
		if (UnitIsEnemy("player", unit)) or ((UnitReaction("player", unit) or 5) <= 4) then
			return condition.Level == 1
		else
			return condition.Level == 2
		end
	end
	TMW_CNDT.COMBAT = function(condition)
		return (condition.Level == 1) == not UnitAffectingCombat(condition.Unit)
	end
	TMW_CNDT.PVPFLAG = function(condition)
		return (condition.Level == 1) == not UnitIsPVP(condition.Unit)
	end

	
	TMW_OP["=="] = function(a, b)
		return b == a
	end
	TMW_OP["<"] = function(a, b)
		return b < a
	end
	TMW_OP["<="] = function(a, b)
		return b <= a
	end
	TMW_OP[">"] = function(a, b)
		return b > a
	end
	TMW_OP[">="] = function(a, b)
		return b >= a
	end
	TMW_OP["~="] = function(a, b)
		return b ~= a
	end
end


-- -------------
-- ICON FUNCTIONS
-- -------------

local function Icon_Bars_Update(icon, groupID, iconID)
	if icon.ShowPBar or icon.ShowCBar then
		local groupName = "TellMeWhen_Group"..groupID
		local iconName = groupName.."_Icon"..iconID
		local Enabled = icon.Enabled
		local locked = db.profile["Locked"]
		local OnlyInCombat = icon:GetParent().OnlyInCombat
		local width, height = icon:GetSize()
		local scale = icon:GetParent().Scale
		if not db.profile["Texture"] then
			db.profile["Texture"] = "Interface\\TargetingFrame\\UI-StatusBar"
		end
		if not db.profile["TextureName"] then
			db.profile["TextureName"] = "Blizzard"
		end
		local tex = db.profile["Texture"]
		if icon.ShowPBar then
			local _,_,_,cost,_,powerType = GetSpellInfo(icon.NameFirst)
			if cost == nil then cost = 0 end
			local powerbarname = iconName.."_PowerBar"
			if not icon.powerbar then
				icon.powerbar = CreateFrame("StatusBar",powerbarname,icon)
			end
			icon.powerbar.power = icon.powerbar.power or 0
			icon.powerbar.icon = icon
			icon.powerbar:SetSize(width*(icon.Width/36), ((height / 2)*(icon.Height/36))-0.5)
			icon.powerbar:SetPoint("BOTTOM",icon,"CENTER",0,0.5)--(((height/2)*(icon.Height/36))-(icon.cooldownbar:GetHeight())))
			if cost then
				icon.powerbar:SetMinMaxValues(0, cost)
			end
			if not icon.powerbar.texture then
				icon.powerbar.texture = icon.powerbar:CreateTexture()
			end
			icon.powerbar.texture:SetTexture(tex)
			if powerType then
				local colorinfo = PowerBarColor[powerType]
				icon.powerbar:SetStatusBarColor(colorinfo.r, colorinfo.g, colorinfo.b, 0.9)
			end
			icon.powerbar:SetStatusBarTexture(icon.powerbar.texture)
			icon.powerbar:SetFrameLevel(icon:GetFrameLevel() + 2)
		end
		if icon.ShowCBar then
			local cooldownbarname = iconName.."_CooldownBar"
			icon.cooldownbar = icon.cooldownbar or CreateFrame("StatusBar",cooldownbarname,icon)
			icon.cooldownbar.icon = icon
			icon.cooldownbar:SetSize(width*(icon.Width/36), ((height / 2)*(icon.Height/36))-0.5)
			icon.cooldownbar:SetPoint("TOP",icon,"CENTER",0,-0.5)---(((height/2)*(icon.Height/36))-(icon.cooldownbar:GetHeight())))
			icon.cooldownbar.texture = icon.cooldownbar.texture or icon.cooldownbar:CreateTexture()
			icon.cooldownbar.texture:SetTexture(tex)
			icon.cooldownbar:SetStatusBarTexture(icon.cooldownbar.texture)
			icon.cooldownbar:SetFrameLevel(icon:GetFrameLevel() + 2)
			icon.cooldownbar:SetMinMaxValues(0,  1)
		end
	end
	if not icon.ShowPBar then
		icon.powerbar:Hide()
	else
		icon.powerbar:Show()
	end
	if not icon.ShowCBar then
		icon.cooldownbar:Hide()
	else
		icon.cooldownbar:Show()
	end
end

function TMW:Icon_Update(icon, groupID, iconID)
	if type(icon) == "number" then --allow omission of icon
		iconID = groupID
		groupID = icon
		icon = _G["TellMeWhen_Group"..groupID.."_Icon"..iconID]
	elseif type(icon) == "table" then --allow omission of IDs
		iconID = icon:GetID()
		groupID = icon:GetParent():GetID()
	end
	
	for k in pairs(TMW.Defaults.profile.Groups["**"].Icons["**"]) do 	--lets clear any settings that might get left behind.
		icon[k] = nil
	end

	for k in pairs(TMW.RelevantIconSettings.all) do
		icon[k] = db.profile.Groups[groupID].Icons[iconID][k]
	end
	if TMW.RelevantIconSettings[icon.Type] then
		for k in pairs(TMW.RelevantIconSettings[icon.Type]) do
			icon[k] = db.profile.Groups[groupID].Icons[iconID][k]
		end
	end

	icon.Width			= icon.Width or 36*0.9
	icon.Height			= icon.Height or 36*0.9
	icon.UpdateTimer 	= 0
	icon.FakeAlpha 		= 0
	if not (pclass == "DEATHKNIGHT") then
		icon.IgnoreRunes = nil
	end

	icon:UnregisterAllEvents()
	ClearScripts(icon)
	
	if icon.DurationMinEnabled or icon.DurationMaxEnabled then
		icon.Duration = true
	else
		icon.Duration = false
	end
	icon.countText:SetText(nil)
	icon.ConditionPresent = false
	if icon.Conditions and #(icon.Conditions) > 0 then
		icon.ConditionPresent = true
	end
	if icon.Enabled and icon:GetParent().Enabled then
		if not tContains(TMW.Icons,icon:GetName()) then tinsert(TMW.Icons,icon:GetName()) end
	else
		local k = tContains(TMW.Icons,icon:GetName())
		if k then tremove(TMW.Icons,k) end
	end
	sort(TMW.Icons,function(a,b) return TMW:GetGlobalIconID(strmatch(a, "TellMeWhen_Group(%d+)_Icon(%d+)")) < TMW:GetGlobalIconID(strmatch(b, "TellMeWhen_Group(%d+)_Icon(%d+)")) end)

	icon.cooldown.noCooldownCount = not icon.ShowTimerText
	icon.cooldown:SetFrameLevel(icon:GetFrameLevel() + 1)
	icon.cooldown:SetDrawEdge(db.profile["DrawEdge"])
	icon.cooldown:SetReverse(false)
	icon.countText:SetFont(db.profile.Font.Path, db.profile.Font.Size, db.profile.Font.Outline)

	if LBF then
		TMW.DontRun = true -- TMW:Update() is ran in the LBF skin callback, which just causes an infinite loop. This tells it not to
		local lbfs = db.profile.Groups[groupID]["LBF"]
		LBF:Group("TellMeWhen", L["GROUP"] .. groupID):AddButton(icon)
		local SkID = lbfs.SkinID or "Blizzard"
		local tab = LBF:GetSkins()
		if tab and SkID then
			if SkID == "Blizzard" then --blizzard needs custom overlay bar sizes because of the borders, other skins might like to use this too
				icon.Width = (tab[SkID].Icon.Width)*0.9
				icon.Height = (tab[SkID].Icon.Height)*0.9
			else
				icon.Width = tab[SkID].Icon.Width
				icon.Height = tab[SkID].Icon.Height
			end
		end
		if db.profile.Font.OverrideLBFPos then
			icon.countText:ClearAllPoints()
			icon.countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", db.profile.Font.x, db.profile.Font.y)
		end
		icon.countText:SetFont(db.profile.Font.Path, tab[SkID].Count.FontSize or db.profile.Font.Size, db.profile.Font.Outline)
	else
		icon.countText:ClearAllPoints()
		icon.countText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", db.profile.Font.x, db.profile.Font.y)
	end

	if not (db.profile["Locked"] and not icon.Enabled) then
		if icon.Type == "icd" then icon.CooldownShowWhen = icon.ICDShowWhen end
		if icon.CooldownShowWhen == "usable" or icon.BuffShowWhen == "present" then
			icon.PresUsableAlpha = 1 * icon.Alpha
			icon.AbsentUnUsableAlpha = 0
		elseif icon.CooldownShowWhen == "unusable" or icon.BuffShowWhen == "absent" then
			icon.PresUsableAlpha = 0
			icon.AbsentUnUsableAlpha = 1 * icon.UnAlpha
		elseif icon.CooldownShowWhen == "always" or icon.BuffShowWhen == "always" then
			icon.PresUsableAlpha = 1 * icon.Alpha
			icon.AbsentUnUsableAlpha = 1 * icon.UnAlpha
		else
			icon.PresUsableAlpha = 1
			icon.AbsentUnUsableAlpha = 1
		end

		
		if icon.Type == "cooldown" then
		
			if icon.CooldownType == "spell" then
				icon.ChakraID = nil
				icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
				icon.NameName = TMW:GetSpellNames(icon,icon.Name,1,true)
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst) or "Interface\\Icons\\INV_Misc_QuestionMark")
				icon:SetScript("OnUpdate", SpellCooldown_OnUpdate)
				if icon.ShowTimer and not icon.IgnoreRunes then --icons that ignore runes handle timers in their onupdate
					icon:RegisterEvent("SPELL_UPDATE_USABLE")
					icon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
					icon:SetScript("OnEvent", SpellCooldown_OnEvent)
					SpellCooldown_OnEvent(icon)
				end
				SpellCooldown_OnUpdate(icon,1)

			elseif icon.CooldownType == "item" then
				icon.NameFirst = TMW:GetItemIDs(icon,icon.Name,1)
				if icon.Slot and icon.Slot <= 19 then
					icon.NameFirst = icon.NameFirst or 0
					icon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
					icon:SetScript("OnEvent", ItemCooldown_OnEvent)
					ItemCooldown_OnEvent(icon)
				end
				icon.ShowPBar = false
				icon.powerbar:Hide()
				local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(icon.NameFirst)
				icon:SetScript("OnUpdate", ItemCooldown_OnUpdate)
				if itemName then
					icon.texture:SetTexture(itemTexture)
					if icon.ShowTimer then
						icon:RegisterEvent("BAG_UPDATE_COOLDOWN")
						icon:SetScript("OnEvent", ItemCooldown_OnEvent)
						ItemCooldown_OnEvent(icon)
					end
				else
					ClearScripts(icon)
					icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				end
				ItemCooldown_OnUpdate(icon,1)
			end
		end
		
		if icon.Type == "buff" then
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			icon.NameName = TMW:GetSpellNames(icon,icon.Name,1,1)
			icon.NameArray = TMW:GetSpellNames(icon,icon.Name)
			icon.NameNameArray = TMW:GetSpellNames(icon,icon.Name,nil,1)

			icon.Filter = icon.BuffOrDebuff
			icon.Filterh = ((icon.BuffOrDebuff == "EITHER") and "HARMFUL")
			if icon.OnlyMine then
				icon.Filter = icon.Filter.."|PLAYER"
				if icon.Filterh then icon.Filterh = icon.Filterh.."|PLAYER" end
			end

			icon:SetScript("OnUpdate",Buff_OnUpdate)
			if icon.StackMinEnabled or icon.StackMaxEnabled then
				icon.Stacks = true
			else
				icon.Stacks = false
			end
			if (icon.Name == "") then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			elseif (GetSpellTexture(icon.NameFirst)) then
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst))
			elseif (not icon.LearnedTexture) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
			end
			icon.cooldown:SetReverse(true)
			Buff_OnUpdate(icon,1)
		end
		
		if icon.Type == "reactive" then
			icon.ChakraID = nil
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			icon.NameName = TMW:GetSpellNames(icon,icon.Name,1,true)
			if icon.ShowPBar then
				PwrBarStart(icon,icon.NameFirst)
			end
			if (GetSpellTexture(icon.NameFirst)) then
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst))
				icon:SetScript("OnUpdate", Reactive_OnUpdate)
			else
				ClearScripts(icon)
				icon.LearnedTexture = false
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
			if icon.ShowTimer then
				icon:RegisterEvent("SPELL_UPDATE_USABLE")
				icon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
				icon:SetScript("OnEvent", SpellCooldown_OnEvent)
				SpellCooldown_OnEvent(icon)
			end
			Reactive_OnUpdate(icon,1)
		end

		if icon.Type == "wpnenchant" then
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)

			icon.ShowPBar = false
			icon.ShowCBar = false
			icon:RegisterEvent("UNIT_INVENTORY_CHANGED")
			local slotID = GetInventorySlotInfo(icon.WpnEnchantType)
			local wpnTexture = GetInventoryItemTexture("player", slotID)
			if wpnTexture then
				icon.texture:SetTexture(wpnTexture)
			else
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
			icon:SetScript("OnEvent", WpnEnchant_OnEvent)
			icon:SetScript("OnUpdate", WpnEnchant_OnUpdate)
			WpnEnchant_OnUpdate(icon,1)
			WpnEnchant_OnEvent(icon,nil,"player")
		end
		
		if icon.Type == "totem" then
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			icon.NameName = TMW:GetSpellNames(icon,icon.Name,1,1)
			icon.NameNameDictionary = TMW:GetSpellNames(icon,icon.Name,nil,1,1)
			if pclass == "DEATHKNIGHT" then
				icon.NameName = GetSpellInfo(46584)
			end
			icon.ShowPBar = false

			icon:SetScript("OnUpdate", Totem_OnUpdate)
			if (icon.Name == "") then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				icon.LearnedTexture = false
			elseif (GetSpellTexture(icon.NameFirst)) then
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst))
			elseif (not icon.LearnedTexture) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
			end
			Totem_OnUpdate(icon,1)
		end
		
		if icon.Type == "multistatecd" then
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			
			if icon.NameFirst and icon.NameFirst ~= "" and GetSpellLink(icon.NameFirst) and not tonumber(icon.NameFirst) then
				_,_,icon.NameFirst = strfind(GetSpellLink(icon.NameFirst), ":(%d+)")
				icon.NameFirst = tonumber(icon.NameFirst)
			end
			icon.Slot = 0
			for i=1,120 do
				local type, spellID = GetActionInfo(i)
				if spellID == icon.NameFirst then
					icon.Slot = i
					break
				end
			end
			if icon.ShowPBar then
				PwrBarStart(icon,icon.NameFirst)
			end
			icon.texture:SetTexture(GetActionTexture(icon.Slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
			icon:SetScript("OnUpdate", MultiStateCD_OnUpdate)
			icon:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
			icon:SetScript("OnEvent", MultiStateCD_OnEvent)
			MultiStateCD_OnUpdate(icon,1)
			MultiStateCD_OnEvent(icon)
		end
		
		if icon.Type == "cast" then
		
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			icon.NameNameDictionary = TMW:GetSpellNames(icon,icon.Name,nil,1,1)
			
			if (icon.Name == "") then
				icon.texture:SetTexture("Interface\\Icons\\Temp")
			elseif (GetSpellTexture(icon.NameFirst)) then
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst))
			elseif (not icon.LearnedTexture) then
				icon.texture:SetTexture("Interface\\Icons\\Temp")
			end
			
			icon:SetScript("OnUpdate", Cast_OnUpdate)
			icon.ShowPBar = false
			Cast_OnUpdate(icon,1)
		end
		
		if icon.Type == "meta" then
			icon.NameFirst = "" --need to set this to something for bars update
			icon.ShowPBar = true
			icon.ShowCBar = true
			icon.texture:SetTexture("Interface\\Icons\\LevelUpIcon-LFD")
			icon:SetScript("OnUpdate", Meta_OnUpdate)
		end
		
		if icon.Type == "icd" then
			icon.ShowPBar = false
			icon.NameFirst = TMW:GetSpellNames(icon,icon.Name,1)
			icon.NameDictionary = TMW:GetSpellNames(icon,icon.Name,nil,nil,1)
			
			if (icon.Name == "") then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			elseif (GetSpellTexture(icon.NameFirst)) then
				icon.texture:SetTexture(GetSpellTexture(icon.NameFirst))
			elseif (not icon.LearnedTexture) then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
			end
			
			icon.StartTime = icon.ICDDuration
			icon:SetScript("OnUpdate", ICD_OnUpdate)
			ICD_OnUpdate(icon,1)
			if icon.ICDType == "spellcast" then
				icon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
				icon.cooldown:SetReverse(true)
			elseif icon.ICDType == "aura" then
				icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			end
			icon:SetScript("OnEvent", ICD_OnEvent)
		end
		
		if icon.Type == "" then
			if icon.Name ~= "" then
				icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			else
				icon.texture:SetTexture(nil)
			end
		end
	end

	icon.cooldown:Hide()

	Icon_Bars_Update(icon, groupID, iconID)
	icon:Show()
	if db.profile["Locked"] then
		icon:DisableDrawLayer("BACKGROUND")
		icon:EnableMouse(0)
		if (not icon.Enabled) or (icon.Name == "" and icon.Type ~= "wpnenchant" and icon.Type ~= "cast" and icon.Type ~= "meta") then
			icon:Hide()
		end
		icon.powerbar:SetValue(0)
		icon.cooldownbar:SetValue(0)
		icon.powerbar:SetAlpha(.9)
		
	else
		if icon.Enabled then
			icon:SetAlpha(1.0)
		else
			icon:SetAlpha(0.4)
		end
		if not icon.texture:GetTexture() then
			icon:EnableDrawLayer("BACKGROUND")
		else
			icon:DisableDrawLayer("BACKGROUND")
		end
		if not icon.cooldownbar.texture then
			icon.cooldownbar.texture = icon.cooldownbar:CreateTexture()
		end
		if not icon.powerbar.texture then
			icon.powerbar.texture = icon.powerbar:CreateTexture()
		end
		ClearScripts(icon.cooldownbar)
		icon.cooldownbar:SetMinMaxValues(0,  1)
		icon.cooldownbar:SetValue(1)
		icon.cooldownbar:SetStatusBarColor(0, 1, 0, 0.5)
		icon.cooldownbar.texture:SetTexCoord(0, 1, 0, 1)
		ClearScripts(icon.powerbar)
		icon.powerbar:SetValue(2000000)
		icon.powerbar:SetAlpha(.5)
		icon.powerbar.texture:SetTexCoord(0, 1, 0, 1)
		icon:EnableMouse(1)
		icon.texture:SetVertexColor(1, 1, 1, 1)
		ClearScripts(icon)
		if icon.Type == "meta" then
			icon.cooldownbar:SetValue(0)
			icon.powerbar:SetValue(0)
		end
	end
end


-- -------------
-- NAME FUNCTIONS
-- -------------

function TMW:EquivToTable(name)
	local names, tab
	for k,v in pairs(TMW.BE) do
		if TMW.BE[k][name] then
			names = TMW.BE[k][name]
			break
		end
	end
	if not names then return false end
	if strfind(names,";") then
		tab = { strsplit(";", names) }
	else
		tab =  { names }
	end
	for a,b in pairs(tab) do
		local new = strtrim(tostring(b))
		tab[a] = tonumber(new) or tostring(new)
	end
	return tab
end

function TMW:GetSpellNames(icon,setting,firstOnly,toname,dictionary)
	local buffNames = {}
	local settings = TMW:SplitNames(setting)
	
	for k,v in pairs(settings) do
		local eqtt = TMW:EquivToTable(v)
		if eqtt then --insert equivalencies into the return table
			for z,x in pairs(eqtt) do
				tinsert(buffNames,x)
			end
		else
			tinsert(buffNames,v)
		end
	end
	
	local new = {}
	for k,v in ipairs(buffNames) do -- remove duplicates
		local count = 0
		for z,x in pairs(new) do
			if v == x then count = count + 1 end
		end
		if count == 0 then
			tinsert(new,v)
		end
	end
	buffNames = new
	
	for k,v in pairs(TMW.Chakra) do --determine if the icon is tracking a chakra state
		if GetSpellInfo(v.abid) == buffNames[1] then
			buffNames[1] = v.abid
			icon.ChakraID = k
		end
		if v.abid == tonumber(buffNames[1]) then
			icon.ChakraID = k
		end
	end

	if dictionary then
		local dictionary = {}
		for k,v in pairs(buffNames) do
			dictionary[v] = true
			if toname then
				v = GetSpellInfo(v) or v
			end
			dictionary[v] = true
		end
		return dictionary
	end
	if toname then
		if firstOnly then
			return GetSpellInfo(buffNames[1])
		else
			local buffNamesNames = {}
			for k,v in pairs(buffNames) do
				buffNamesNames[k] = GetSpellInfo(v) or v --convert everything to a name and return a table of names with no IDs (hopefully) (for buff/debuff icons)
			end
			return buffNamesNames
		end
	end
	if firstOnly then
		return buffNames[1]
	end
	return buffNames
end

function TMW:GetItemIDs(icon,item,firstOnly)
	item = strtrim(tostring(item))
	local itemID = tonumber(item)
	if (not itemID) then
		local _,itemLink = GetItemInfo(item)
		if itemLink then
			_, _, itemID = strfind(itemLink, ":(%d+)")
		end
	elseif (itemID <= 19) then
		icon.Slot = itemID
		itemID = GetInventoryItemID("player",itemID)
	end
	return tonumber(itemID) or 0
end

function TMW:CleanString(text)
	text = strtrim(text,"; \t\r\n")
	while strfind(text," ;") do
		text = gsub(text," ;","; ")
	end
	while strfind(text,";  ") do
		text = gsub(text,";  ","; ")
	end
	while strfind(text,";;") do
		text = gsub(text,";;",";")
	end
	return text
end

function TMW:SplitNames(input)
	local buffNames = {}
	-- If input contains one or more semicolons, split the list into parts
	if strfind(input,";") then
		buffNames = { strsplit(";", input) }
	else
		buffNames = { input }
	end
	for a,b in pairs(buffNames) do --remove spaces from the beginning and end of each name
		local new = strtrim(tostring(b)) or error("Error removing spaces from:" .. a .. ":" .. b ..":.")
		buffNames[a] = tonumber(new) or tostring(new)
	end
	return buffNames
end




 