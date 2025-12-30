-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether 
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

if not TMW then return end
local TMW = TMW
local db

-- -----------------------
-- LOCALS/GLOBALS/UTILITIES
-- -----------------------

local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
local _,pclass = UnitClass("Player")
local tonumber, tostring, type, pairs, ipairs, tinsert, error, tremove, sort, select =
	  tonumber, tostring, type, pairs, ipairs, tinsert, error, tremove, sort, select
local strfind, strmatch, format, gsub, strsub, strlower, strtrim, strsplit, min, max =
	  strfind, strmatch, format, gsub, strsub, strlower, strtrim, strsplit, min, max 
local _G = _G
local tiptemp,conditionstemp = {},{}
local AE,SE,DE,IE,ME,CN,CNDT

TMW.TempEnabled = {}
TMW.CI = { g = 1, i = 1 }		--current icon, for dropdown menus and such
TMW.CNI = { g = 1, i = 1 }		--current name icon
TMW.CCnI = { g = 1, i = 1 }		--current condition icon
TMW.CEI = { g = 1, i = 1 }		--current editor icon
TMW.CMI = { g = 1, i = 1 }		--current meta icon
TMW.D = {} 						--group settings to restore on icon copier hide
TMW.Flags = {
	MONOCHROME = L["OUTLINE_NO"],
	OUTLINE = L["OUTLINE_THIN"],
	THICKOUTLINE = L["OUTLINE_THICK"],
}

local oldp=print
local function print(...)
	if TMW.TestOn then
		oldp("|cffff0000TMW:|r ", ...)
	end
end

local function CopyWithMetatable(settings)
	local copy = {}
	for k, v in pairs(settings) do
		if ( type(v) == "table" ) then
			copy[k] = CopyWithMetatable(v)
		else
			copy[k] = v
		end
	end
	return setmetatable(copy, getmetatable(settings))
end

local function TT(f,t)
	f:HookScript("OnEnter",function(self)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(t, 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	f:HookScript("OnLeave",function(self)
		GameTooltip:Hide()
	end)
end

local function GetLocalizedSettingString(setting,value)
	for k,v in pairs(TMW.IconMenu_SubMenus[setting]) do
		if v.value == value then
			return v.text
		end
	end
end

-- Talent dropdown values: all talents of current class (with icons). Key format: "tab:index"
local function TMW_GetTalentDropdownValues()
	local vals = {}
	vals["0"] = "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16:0:0|t Не выбрано"

	local numTabs = (GetNumTalentTabs and GetNumTalentTabs()) or 0
	for tab = 1, numTabs do
		local tabName = select(1, GetTalentTabInfo(tab)) or ("Tab "..tab)
		local numTalents = (GetNumTalents and GetNumTalents(tab)) or 0
		for idx = 1, numTalents do
			local name, iconTexture = GetTalentInfo(tab, idx)
			if name then
				iconTexture = iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
				local key = tab .. ":" .. idx
				vals[key] = ("|T%s:16:16:0:0|t %s - %s"):format(iconTexture, tabName, name)
			end
		end
	end

	return vals
end

function TMW:InitOptionsDB()
	db = TMW.db
end

function TMW:GetIconMenuText(g,i)
	g,i = tonumber(g),tonumber(i)
	local text = db.profile.Groups[g].Icons[i].Name
	if db.profile.Groups[g].Icons[i].Type == "wpnenchant" then
		if db.profile.Groups[g].Icons[i].WpnEnchantType == "MainHandSlot" then text = INVTYPE_WEAPONMAINHAND
		elseif db.profile.Groups[g].Icons[i].WpnEnchantType == "SecondaryHandSlot" then text = INVTYPE_WEAPONOFFHAND
		elseif db.profile.Groups[g].Icons[i].WpnEnchantType == "RangedSlot" then text = INVTYPE_THROWN end
		text = text .. " ((" .. L["ICONMENU_WPNENCHANT"] .. "))"
	elseif db.profile.Groups[g].Icons[i].Type == "meta" then
		text = "((" .. L["ICONMENU_META"] .. "))"
	elseif db.profile.Groups[g].Icons[i].Type == "cast" and text == "" then
		text = "((" .. L["ICONMENU_CAST"] .. "))"
	end
	local textshort = strsub(text,1,35)
	if strlen(text) > 35 then textshort = textshort .. "..." end
	return text,textshort
end

function TMW:GetGlobalIconID(g,i)
	g,i = tostring(g),tostring(i)
	return tonumber(g .. strsub("000",1,3-#i) .. i)
end

function TMW:GetGroupName(n,g,short)
	if (not n) or n == "" then
		if short then return g end
		return L["GROUP"]..g
	end
	if short then return n .. " ("..g..")" end
	return n .. " ("..L["GROUP"]..g..")"
end

StaticPopupDialogs["TMW_RENAMEGROUP"] = {
	text = L["UIPANEL_GROUPNAME"],
	button1 = OKAY,
	button2 = CANCEL,
	OnAccept = function(self,groupID)
		db.profile.Groups[groupID].Name = strtrim(self.editBox:GetText())
		TMW:Group_Update(groupID)
	end,
	EditBoxOnEnterPressed = function(self,groupID)
		db.profile.Groups[groupID].Name = strtrim(self:GetText())
		StaticPopup_Hide("TMW_RENAMEGROUP")
		TMW:Group_Update(groupID)
	end,
	OnCancel = function() StaticPopup_Hide("TMW_RENAMEGROUP") end,
	hasEditBox = true,
	timeout = 0,
	whileDead = true, 
	hideOnEscape = true,
}

-- --------------
-- MAIN OPTIONS
-- --------------

function TMW:LockToggle()
	db.profile.Locked = not db.profile.Locked
	PlaySound("UChatScrollButton")
	TMW:Update()
end

function TMW:CompileOptions() -- options
	if not TMW.DoInitializeOptions then return end
	if not TMW.InitializedOptions then	
		TMW.OptionsTable = {
			type = "group",
			args = {
				main = {
					type = "group",
					name = L["UIPANEL_MAINOPT"],
					order = 1,
					args = {
						header = {
							name = L["ICON_TOOLTIP1"] .. " " .. TELLMEWHEN_VERSION .. TELLMEWHEN_VERSION_MINOR,
							type = "header",
							order = 1,
						},
						togglelock = {
							name = L["UIPANEL_LOCKUNLOCK"],
							desc = L["UIPANEL_SUBTEXT2"],
							type = "toggle",
							order = 2,
							set = function(info,val)
								db.profile["Locked"] = val
								TMW:Update()
							end,
							get = function(info) return db.profile["Locked"] end
						},
						bartexture = {
							name = L["UIPANEL_BARTEXTURE"],
							type = "select",
							order = 3,
							dialogControl = 'LSM30_Statusbar',
							values = LSM:HashTable("statusbar"),
							set = function(info,val)
								db.profile["Texture"] = LSM:Fetch("statusbar",val)
								db.profile["TextureName"] = val
								TMW:Update()
							end,
							get = function(info) return db.profile["TextureName"] end
						},
						sliders = {
							type = "group",
							order = 9,
							name = "",
							guiInline = true,
							dialogInline = true,
							args = {
								updinterval = {
									name = L["UIPANEL_UPDATEINTERVAL"],
									desc = L["UIPANEL_TOOLTIP_UPDATEINTERVAL"],
									type = "range",
									order = 9,
									min = 0,
									max = 0.5,
									step = 0.01,
									bigStep = 0.01,
									set = function(info,val)
									db.profile.Interval = val
									TMW:Update()
									end,
									get = function(info) return db.profile.Interval end

								},
								iconspacing = {
									name = L["UIPANEL_ICONSPACING"],
									desc = L["UIPANEL_ICONSPACING_DESC"],
									type = "range",
									order = 10,
									min = 0,
									softMax = 20,
									step = 0.1,
									bigStep = 1,
									set = function(info,val)
										db.profile["Spacing"] = val
										TELLMEWHEN_ICONSPACING = db.profile["Spacing"] or TELLMEWHEN_ICONSPACING
										TMW:Update()
									end,
									get = function(info) return TELLMEWHEN_ICONSPACING end
								},
							},
						},
						addgroup = {
							name = L["UIPANEL_ADDGROUP"],
							desc = L["UIPANEL_ADDGROUP_DESC"],
							type = "execute",
							order = 11,
							func = function()
								db.profile.NumGroups = db.profile.NumGroups + 1
								db.profile.Groups[db.profile.NumGroups].LBF = CopyWithMetatable(db.profile.Groups[db.profile.NumGroups-1].LBF)
								db.profile.Groups[db.profile.NumGroups].Enabled = true
								TMW:Update()
								TMW:CompileOptions()
							end,
						},
						ignoregcd = {
							type = "group",
							order = 21,
							name = "",
							guiInline = true,
							dialogInline = true,
							args = {
								barignoregcd = {
									name = L["UIPANEL_BARIGNOREGCD"],
									desc = L["UIPANEL_BARIGNOREGCD_DESC"],
									type = "toggle",
									order = 21,
									set = function(info,val)
										db.profile.BarGCD = not val
										TMW:Update()
									end,
									get = function(info) return not db.profile.BarGCD end
								},
								clockignoregcd = {
									name = L["UIPANEL_CLOCKIGNOREGCD"],
									desc = L["UIPANEL_CLOCKIGNOREGCD_DESC"],
									type = "toggle",
									order = 22,
									set = function(info,val)
										db.profile.ClockGCD = not val
										TMW:Update()
									end,
									get = function(info) return not db.profile.ClockGCD end
								},
							},
						},
						drawedge = {
							name = L["UIPANEL_DRAWEDGE"],
							desc = L["UIPANEL_DRAWEDGE_DESC"],
							type = "toggle",
							order = 40,
							set = function(info,val)
								db.profile["DrawEdge"] = val
								TMW:Update()
							end,
							get = function(info) return db.profile["DrawEdge"] end
						},
						resetall = {
							name = L["UIPANEL_ALLRESET"],
							desc = L["UIPANEL_TOOLTIP_ALLRESET"],
							type = "execute",
							order = 51,
							confirm = true,
							func = function() db:ResetProfile() end,
						},
						coloropts = {
							type = "group",
							name = L["UIPANEL_COLORS"],
							order = 3,
							args = {
								cdstcolor = {
									name = L["UIPANEL_COLOR_STARTED"],
									desc = L["UIPANEL_COLOR_STARTED_DESC"],
									type = "color",
									order = 31,
									hasAlpha = true,
									set = function(info,nr,ng,nb,na) local c = db.profile["CDSTColor"] c.r = nr c.g = ng c.b = nb c.a = na TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["CDSTColor"]  return c.r, c.g, c.b, c.a end,
								},
								cdcocolor = {
									name = L["UIPANEL_COLOR_COMPLETE"],
									desc = L["UIPANEL_COLOR_COMPLETE_DESC"],
									type = "color",
									order = 32,
									hasAlpha = true,
									set = function(info,nr,ng,nb,na) local c = db.profile["CDCOColor"] c.r = nr c.g = ng c.b = nb c.a = na TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["CDCOColor"]  return c.r, c.g, c.b, c.a end,
								},
								oorcolor = {
									name = L["UIPANEL_COLOR_OOR"],
									desc = L["UIPANEL_COLOR_OOR_DESC"],
									type = "color",
									order = 37,
									hasAlpha = true,
									set = function(info,nr,ng,nb,na) local c = db.profile["OORColor"] c.r = nr c.g = ng c.b = nb c.a = na TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["OORColor"]  return c.r, c.g, c.b, c.a end,
								},
								oomcolor = {
									name = L["UIPANEL_COLOR_OOM"],
									desc = L["UIPANEL_COLOR_OOM_DESC"],
									type = "color",
									order = 38,
									hasAlpha = true,
									set = function(info,nr,ng,nb,na) local c = db.profile["OOMColor"] c.r = nr c.g = ng c.b = nb c.a = na TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["OOMColor"]  return c.r, c.g, c.b, c.a end,
								},
								desc = {
									name = L["UIPANEL_COLOR_DESC"],
									type = "description",
									order = 40,
								},
								presentcolor = {
									name = L["UIPANEL_COLOR_PRESENT"],
									desc = L["UIPANEL_COLOR_PRESENT_DESC"],
									type = "color",
									order = 45,
									hasAlpha = false,
									set = function(info,nr,ng,nb) local c = db.profile["PRESENTColor"] c.r = nr c.g = ng c.b = nb TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["PRESENTColor"] return c.r, c.g, c.b end,
								},
								absentcolor = {
									name = L["UIPANEL_COLOR_ABSENT"],
									desc = L["UIPANEL_COLOR_ABSENT_DESC"],
									type = "color",
									order = 47,
									hasAlpha = false,
									set = function(info,nr,ng,nb) local c = db.profile["ABSENTColor"] c.r = nr c.g = ng c.b = nb TMW:ColorUpdate() end,
									get = function(info) local c = db.profile["ABSENTColor"] return c.r, c.g, c.b end,
								},
							},
						},
						countfont = {
							type = "group",
							name = L["UIPANEL_FONT"],
							order = 4,
							args = {
								font = {
									name = L["UIPANEL_FONT"],
									desc = L["UIPANEL_FONT_DESC"],
									type = "select",
									order = 3,
									dialogControl = 'LSM30_Font',
									values = LSM:HashTable("font"),
									set = function(info,val)
										db.profile.Font.Path = LSM:Fetch("font",val)
										db.profile.Font.Name = val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.Name end,
								},
								fontSize = {
									name = L["UIPANEL_FONT_SIZE"],
									desc = L["UIPANEL_FONT_SIZE_DESC"],
									type = "range",
									order = 10,
									min = 6,
									max = 26,
									step = 1,
									bigStep = 1,
									set = function(info,val)
										db.profile.Font.Size = val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.Size end,
								},
								outline = {
									name = L["UIPANEL_FONT_OUTLINE"],
									desc = L["UIPANEL_FONT_OUTLINE_DESC"],
									type = "select",
									values = TMW.Flags,
									style = "dropdown",
									order = 11,
									set = function(info,val)
										db.profile.Font.Outline = val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.Outline end,
								},
								overridelbf = {
									name = L["UIPANEL_FONT_OVERRIDELBF"],
									desc = L["UIPANEL_FONT_OVERRIDELBF_DESC"],
									type = "toggle",
									order = 20,
									set = function(info,val)
										db.profile.Font.OverrideLBFPos = not not val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.OverrideLBFPos end
								},
								x = {
									name = L["UIPANEL_FONT_XOFFS"],
									type = "range",
									order = 21,
									min = -30,
									max = 10,
									step = 1,
									bigStep = 1,
									set = function(info,val)
										db.profile.Font.x = val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.x end,
								},
								y = {
									name = L["UIPANEL_FONT_YOFFS"],
									type = "range",
									order = 22,
									min = -10,
									max = 30,
									step = 1,
									bigStep = 1,
									set = function(info,val)
										db.profile.Font.y = val
										TMW:Update()
									end,
									get = function(info) return db.profile.Font.y end,
								},
							},
						},
					},
				},
				groups = {
					type = "group",
					name = L["UIPANEL_GROUPS"],
					order = 2,
					args = {
					}
				}
			}
		}
		TMW.OptionsTable.args.groups.args.addgroup = TMW.OptionsTable.args.main.args.addgroup
		TMW.OptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
		TMW.InitializedOptions = true
	end
	
	for zz=1,TELLMEWHEN_MAXGROUPS do
		if not TMW.OptionsTable.args.groups.args[tostring(zz)] then
			TMW.OptionsTable.args.groups.args[tostring(zz)] = {
				type = "group",
				name = TMW:GetGroupName(db.profile.Groups[zz].Name,zz),
				order = zz,
				args = {
					name = {
						name = L["UIPANEL_GROUPNAME"],
						type = "input",
						order = 1,
						set = function(info,val)
							db.profile.Groups[zz].Name = strtrim(val)
							TMW:Group_Update(zz)
							TMW:CompileOptions()
						end,
						get = function(info) return db.profile.Groups[zz].Name end
					},
					enable = {
						name = L["UIPANEL_ENABLEGROUP"],
						desc = L["UIPANEL_TOOLTIP_ENABLEGROUP"],
						type = "toggle",
						order = 2,
						set = function(info,val)
							db.profile.Groups[zz].Enabled = val
							TMW:Group_Update(zz)
						end,
						get = function(info) return db.profile.Groups[zz].Enabled end
					},
					showwhen = {
						type = "group",
						order = 3,
						name = "",
						guiInline = true,
						dialogInline = true,
						args = {
							combat = {
								name = L["UIPANEL_ONLYINCOMBAT"],
								desc = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"],
								type = "toggle",
								order = 3,
								set = function(info,val)
									db.profile.Groups[zz]["OnlyInCombat"] = val
									TMW:Group_Update(zz)
								end,
								get = function(info) return db.profile.Groups[zz].OnlyInCombat end
							},
							vehicle = {
								name = L["UIPANEL_NOTINVEHICLE"],
								desc = L["UIPANEL_TOOLTIP_NOTINVEHICLE"],
								type = "toggle",
								order = 4,
								set = function(info,val)
									db.profile.Groups[zz]["NotInVehicle"] = val
									TMW:Group_Update(zz)
								end,
								get = function(info) return db.profile.Groups[zz].NotInVehicle end
							},
						},
					},
					rowcolumn = {
						type = "group",
						order = 10,
						name = "",
						guiInline = true,
						dialogInline = true,
						args = {
							columns = {
								name = L["UIPANEL_COLUMNS"],
								desc = L["UIPANEL_TOOLTIP_COLUMNS"],
								type = "range",
								order = 10,
								min = 1,
								max = TELLMEWHEN_MAXROWS,
								step = 1,
								bigStep = 1,
								set = function(info,val)
									db.profile.Groups[zz]["Columns"] = val
									TMW:Group_Update(zz)
								end,
								get = function(info) return db.profile.Groups[zz].Columns end

							},
							rows = {
								name = L["UIPANEL_ROWS"],
								desc = L["UIPANEL_TOOLTIP_ROWS"],
								type = "range",
								order = 11,
								min = 1,
								max = TELLMEWHEN_MAXROWS,
								step = 1,
								bigStep = 1,
								set = function(info,val)
									db.profile.Groups[zz]["Rows"] = val
									TMW:Group_Update(zz)
								end,
								get = function(info) return db.profile.Groups[zz].Rows end

							},
						},
					},
					
					talents = {
						type = "group",
						order = 6,
						name = "Фильтр талантов",
						guiInline = true,
						dialogInline = true,
						args = {
							headerShow = {
								type = "header",
								name = "Показывать, если прокачаны таланты (все выбранные)",
								order = 1,
							},
							show1 = {
								name = "Талант 1",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 2,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].ShowTalents
									if not t then t = {}; db.profile.Groups[zz].ShowTalents = t end
									t[1] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].ShowTalents
									return (t and t[1]) or "0"
								end,
							},
							show2 = {
								name = "Талант 2",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 3,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].ShowTalents
									if not t then t = {}; db.profile.Groups[zz].ShowTalents = t end
									t[2] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].ShowTalents
									return (t and t[2]) or "0"
								end,
							},
							show3 = {
								name = "Талант 3",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 4,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].ShowTalents
									if not t then t = {}; db.profile.Groups[zz].ShowTalents = t end
									t[3] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].ShowTalents
									return (t and t[3]) or "0"
								end,
							},
							show4 = {
								name = "Талант 4",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 5,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].ShowTalents
									if not t then t = {}; db.profile.Groups[zz].ShowTalents = t end
									t[4] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].ShowTalents
									return (t and t[4]) or "0"
								end,
							},
							show5 = {
								name = "Талант 5",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 6,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].ShowTalents
									if not t then t = {}; db.profile.Groups[zz].ShowTalents = t end
									t[5] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].ShowTalents
									return (t and t[5]) or "0"
								end,
							},
							headerHide = {
								type = "header",
								name = "Не показывать, если прокачан талант (приоритет)",
								order = 20,
							},
							hide1 = {
								name = "Талант 1",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 21,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].HideTalents
									if not t then t = {}; db.profile.Groups[zz].HideTalents = t end
									t[1] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].HideTalents
									return (t and t[1]) or "0"
								end,
							},
							hide2 = {
								name = "Талант 2",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 22,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].HideTalents
									if not t then t = {}; db.profile.Groups[zz].HideTalents = t end
									t[2] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].HideTalents
									return (t and t[2]) or "0"
								end,
							},
							hide3 = {
								name = "Талант 3",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 23,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].HideTalents
									if not t then t = {}; db.profile.Groups[zz].HideTalents = t end
									t[3] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].HideTalents
									return (t and t[3]) or "0"
								end,
							},
							hide4 = {
								name = "Талант 4",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 24,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].HideTalents
									if not t then t = {}; db.profile.Groups[zz].HideTalents = t end
									t[4] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].HideTalents
									return (t and t[4]) or "0"
								end,
							},
							hide5 = {
								name = "Талант 5",
								type = "select",
								style = "dropdown",
								width = "full",
								order = 25,
								values = function() return TMW_GetTalentDropdownValues() end,
								set = function(info,val)
									local t = db.profile.Groups[zz].HideTalents
									if not t then t = {}; db.profile.Groups[zz].HideTalents = t end
									t[5] = val
									TMW:Group_Update(zz)
								end,
								get = function(info)
									local t = db.profile.Groups[zz].HideTalents
									return (t and t[5]) or "0"
								end,
							},
						},
					},
					reset =  {
						name = L["UIPANEL_GROUPRESET"],
						desc = L["UIPANEL_TOOLTIP_GROUPRESET"],
						type = "execute",
						order = 13,
						func = function() TMW:Group_ResetPosition(zz) end
					},
					delete = {
						name = L["UIPANEL_DELGROUP"],
						desc = L["UIPANEL_DELGROUP_DESC"],
						type = "execute",
						order = 20,
						func = function()
							TMW:Group_OnDelete(zz)
						end
					}
				}
			}
			if #(TMW.CSN) > 0 then 		-- 	[0] doesnt factor into the length
				TMW.OptionsTable.args.groups.args[tostring(zz)].args.stance = {
					type = "multiselect",
					name = L["UIPANEL_STANCE"],
					order = 12,
					values = TMW.CSN,
					set = function(info,key,val)		
						db.profile.Groups[zz].Stance[TMW.CSN[key]] = val
						TMW:Group_Update(zz)
					end,
					get = function(info,key)
						return db.profile.Groups[zz].Stance[TMW.CSN[key]]
					end,
				}
			end
		else
			TMW.OptionsTable.args.groups.args[tostring(zz)].name = TMW:GetGroupName(db.profile.Groups[zz].Name,zz)
		end
	end
	
	for k,v in pairs(TMW.OptionsTable.args.groups.args) do
		if tonumber(k) and tonumber(k) > TELLMEWHEN_MAXGROUPS then
			TMW.OptionsTable.args.groups.args[k] = nil
		end
	end
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TellMeWhen Options", TMW.OptionsTable)
	if not TMW.AddedToBlizz then
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TellMeWhen Options",L["ICON_TOOLTIP1"])
		TMW.AddedToBlizz = true
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("TellMeWhen Options")
	end
end

function TellMeWhen_SlashCommand(cmd)
	cmd = strlower(tostring(cmd))
	if cmd == strlower(L["CMD_OPTIONS"]) then
		InterfaceOptionsFrame_OpenToCategory(L["ICON_TOOLTIP1"])
	else
		TMW:LockToggle()
	end
end


-- --------
-- ICON GUI
-- --------

TMW.IconMenuOptions = {}
TMW.IconMenuOptions.cooldown = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "CooldownType", 		text = L["ICONMENU_COOLDOWNTYPE"], 	hasArrow = true,								},
	{ value = "CooldownShowWhen",	text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "RangeCheck", 		text = L["ICONMENU_RANGECHECK"], 	tooltipText = L["ICONMENU_RANGECHECK_DESC"],	},
	{ value = "ManaCheck", 			text = L["ICONMENU_MANACHECK"], 	tooltipText = L["ICONMENU_MANACHECK_DESC"],		},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.reactive = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"],														},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "CooldownShowWhen", 	text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "CooldownCheck", 		text = L["ICONMENU_COOLDOWNCHECK"], tooltipText = L["ICONMENU_COOLDOWNCHECK_DESC"],	},
	{ value = "RangeCheck", 		text = L["ICONMENU_RANGECHECK"],	tooltipText = L["ICONMENU_RANGECHECK_DESC"],	},
	{ value = "ManaCheck", 			text = L["ICONMENU_MANACHECK"], 	tooltipText = L["ICONMENU_MANACHECK_DESC"],		},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.buff = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "OnlyMine", 			text = L["ICONMENU_ONLYMINE"],														},
	{ value = "BuffOrDebuff", 		text = L["ICONMENU_BUFFTYPE"], 		hasArrow = true,								},
	{ value = "Unit",				text = L["ICONMENU_UNIT"], 			hasArrow = true,								},
	{ value = "BuffShowWhen", 		text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.wpnenchant = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "HideUnequipped", 	text = L["ICONMENU_HIDEUNEQUIPPED"],												},
	{ value = "WpnEnchantType", 	text = L["ICONMENU_WPNENCHANTTYPE"],hasArrow = true,								},
	{ value = "BuffShowWhen", 		text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
}

TMW.IconMenuOptions.totem = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"],														},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "BuffShowWhen", 		text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.multistatecd = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "CooldownShowWhen",	text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "RangeCheck", 		text = L["ICONMENU_RANGECHECK"], 	tooltipText = L["ICONMENU_RANGECHECK_DESC"],	},
	{ value = "ManaCheck", 			text = L["ICONMENU_MANACHECK"], 	tooltipText = L["ICONMENU_MANACHECK_DESC"],		},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.icd = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "ICDType",			text = L["ICONMENU_ICDTYPE"], 		hasArrow = true,								},
	{ value = "ICDShowWhen",		text = L["ICONMENU_SHOWWHEN"], 		hasArrow = true,								},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.cast = {
	{ value = "ShowTimer", 			text = L["ICONMENU_SHOWTIMER"], 													},
	{ value = "ShowTimerText", 		text = L["ICONMENU_SHOWTIMERTEXT"], tooltipText = L["ICONMENU_SHOWTIMERTEXT_DESC"],	},
	{ value = "Interruptible", 		text = L["ICONMENU_ONLYINTERRUPTIBLE"],												},
	{ value = "Unit",				text = L["ICONMENU_UNIT"], 			hasArrow = true,								},
	{ value = "BuffShowWhen", 		text = L["ICONMENU_CASTSHOWWHEN"], 	hasArrow = true,								},
	{ value = "Bars", 				text = L["ICONMENU_BARS"], 			hasArrow = true,								},
}

TMW.IconMenuOptions.meta = {}

TMW.IconMenu_SubMenus = {
	-- the keys on this table need to match the settings variable names
	Type = {
		{ value = "cooldown", 		text = L["ICONMENU_COOLDOWN"] },
		{ value = "buff", 			text = L["ICONMENU_BUFFDEBUFF"] },
		{ value = "reactive", 		text = L["ICONMENU_REACTIVE"] },
		{ value = "wpnenchant",		text = L["ICONMENU_WPNENCHANT"] },
		{ value = "totem", 			text = L["ICONMENU_TOTEM"], 			tooltipText = pclass == "DEATHKNIGHT" and L["ICONMENU_TOTEM_DESC"]},
		{ value = "multistatecd",	text = L["ICONMENU_MULTISTATECD"], 		tooltipText = L["ICONMENU_MULTISTATECD_DESC"] },
		{ value = "icd", 			text = L["ICONMENU_ICD"],				tooltipText = L["ICONMENU_ICD_DESC"] },
		{ value = "cast",			text = L["ICONMENU_CAST"], 				tooltipText = L["ICONMENU_CAST_DESC"] },
		{ value = "meta", 			text = L["ICONMENU_META"],				tooltipText = L["ICONMENU_META_DESC"] },
	},
	CooldownType = {
		{ value = "spell", 			text = L["ICONMENU_SPELL"] },
		{ value = "item", 			text = L["ICONMENU_ITEM"] },
	},
	BuffOrDebuff = {
		{ value = "HELPFUL", 		text = L["ICONMENU_BUFF"], 				colorCode = "|cFF00FF00" },
		{ value = "HARMFUL", 		text = L["ICONMENU_DEBUFF"], 			colorCode = "|cFFFF0000" },
		{ value = "EITHER", 		text = L["ICONMENU_BOTH"] },
	},
	Unit = {
		{ value = "player", 		text = PLAYER },
		{ value = "target", 		text = TARGET },
		{ value = "targettarget", 	text = L["ICONMENU_TARGETTARGET"] },
		{ value = "focus", 			text = FOCUS },
		{ value = "focustarget", 	text = L["ICONMENU_FOCUSTARGET"] },
		{ value = "pet", 			text = PET },
		{ value = "pettarget", 		text = L["ICONMENU_PETTARGET"] },
		{ value = "mouseover", 		text = L["ICONMENU_MOUSEOVER"] },
		{ value = "mouseovertarget",text = L["ICONMENU_MOUSEOVERTARGET"]  },
		{ value = "vehicle", 		text = L["ICONMENU_VEHICLE"] },
	},
	BuffShowWhen = {
		{ value = "present", 		text = L["ICONMENU_PRESENT"], 			colorCode = "|cFF00FF00" },
		{ value = "absent", 		text = L["ICONMENU_ABSENT"], 			colorCode = "|cFFFF0000" },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},
	CooldownShowWhen = {
		{ value = "usable", 		text = L["ICONMENU_USABLE"], 			colorCode = "|cFF00FF00" },
		{ value = "unusable", 		text = L["ICONMENU_UNUSABLE"], 			colorCode = "|cFFFF0000" },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},
	ICDShowWhen = {
		{ value = "usable", 		text = L["ICONMENU_ICDUSABLE"], },
		{ value = "unusable", 		text = L["ICONMENU_ICDUNUSABLE"], },
		{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
	},
	ICDType = {
		{ value = "aura", 			text = L["ICONMENU_BUFFDEBUFF"],		tooltipText = L["ICONMENU_ICDAURA_DESC"]},
		{ value = "spellcast", 		text = L["ICONMENU_SPELLCAST"],			tooltipText = L["ICONMENU_SPELLCAST_DESC"]},
	},
	WpnEnchantType = {
		{ value = "MainHandSlot", 	text = INVTYPE_WEAPONMAINHAND },
		{ value = "SecondaryHandSlot",text = INVTYPE_WEAPONOFFHAND },
	},
	Bars = {
		{ value = "ShowPBar", 		text = L["ICONMENU_SHOWPBAR"],},
		{ value = "ShowCBar", 		text = L["ICONMENU_SHOWCBAR"],},
		{ value = "InvertBars", 	text = L["ICONMENU_INVERTBARS"],},
	},
}


for i=1,MAX_BOSS_FRAMES do tinsert(TMW.IconMenu_SubMenus.Unit, { value = "boss" .. i, text = BOSS .. " " .. i }) end
for i=1,4 do tinsert(TMW.IconMenu_SubMenus.Unit, { value = "party" .. i, text = PARTY .. " " .. i }) end
for i=1,5 do tinsert(TMW.IconMenu_SubMenus.Unit, { value = "arena" .. i, text = ARENA .. " " .. i }) end
if pclass == "ROGUE" then
	tinsert(TMW.IconMenu_SubMenus.WpnEnchantType, { value = "RangedSlot", text = INVTYPE_THROWN })
elseif pclass == "DEATHKNIGHT" then
	tinsert(TMW.IconMenuOptions.cooldown, 7, { value = "IgnoreRunes", text = L["ICONMENU_IGNORERUNES"], tooltipText = L["ICONMENU_IGNORERUNES_DESC"],})
end


function TellMeWhen_IconMenu_Initialize(self) -- icon menu
	local groupID = TMW.CI.g
	local iconID = TMW.CI.i
	local icon = _G["TellMeWhen_Group"..groupID.."_Icon"..iconID]
	if not (icon and icon.Conditions) then return end
	local info
	
	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		-- show name
		info = UIDropDownMenu_CreateInfo()
		if icon.Name and icon.Name ~= "" and icon.Type ~= "wpnenchant" and icon.Type ~= "meta" then
			info = UIDropDownMenu_CreateInfo()
			local textshort = strsub(icon.Name,1,35)
			if strlen(icon.Name) > 35 then
				textshort = textshort .. "..."
				info.tooltipTitle = icon.Name
				info.tooltipOnButton = true
				info.tooltipWhileDisabled = true
			end
			info.text = textshort
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)
		end

		-- enable icon
		info = UIDropDownMenu_CreateInfo()
		info.value = "Enabled"
		info.text = L["ICONMENU_ENABLE"]
		info.checked = icon.Enabled
		info.func = TellMeWhen_IconMenu_ToggleSetting
		info.keepShownOnClick = true
		info.isNotRadio = true
		UIDropDownMenu_AddButton(info)

		-- choose name
		if icon.Type ~= "wpnenchant" and icon.Type ~= "meta" then
			info = UIDropDownMenu_CreateInfo()
			info.value = L["ICONMENU_CHOOSENAME"]
			info.text = L["ICONMENU_CHOOSENAME"]
			info.func = CN.Load
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)
		end

		-- icon type
		info = UIDropDownMenu_CreateInfo()
		info.value = "Type"
		info.text = L["ICONMENU_TYPE"]
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)

		
		if icon.Type ~= "" then
		
			-- conditions
			info = UIDropDownMenu_CreateInfo()
			if (#(icon.Conditions) > 0) then
				info.text = L["ICONMENU_EDITCONDITION"]
				info.value = "Edit condition"
				info.func = function()
					TMW.CCnI = { g = TMW.CI.g, i = TMW.CI.i }
					CNDT:LoadDialog()
				end
			else
				info.text = L["ICONMENU_ADDCONDITION"]
				info.value = "Add condition"
				info.func = function()
					TMW.CCnI = { g = TMW.CI.g, i = TMW.CI.i }
					CNDT:ClearDialog()
				end
			end
			info.hasArrow = false
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)
			
			--alpha/duration/stacks
			if icon.Type ~= "meta" then
				info = UIDropDownMenu_CreateInfo()
				local text = L["ICONMENU_EDIT"] .. " "
				if db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].Alpha ~= 1 or db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].UnAlpha ~= 1
				or db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].StackAlpha ~= 0 or db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].DurationAlpha ~= 0
				or db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].ConditionAlpha ~= 0 or db.profile.Groups[TMW.CI.g].Icons[TMW.CI.i].FakeHidden == true  then
					text = text .. "|cFFFF5959" .. L["ICONMENU_ALPHA"] .. "|r"
				else
					text = text .. L["ICONMENU_ALPHA"]
				end
				if db.profile.Groups[groupID].Icons[iconID].DurationMinEnabled or db.profile.Groups[groupID].Icons[iconID].DurationMaxEnabled then
					text = text .. "/" .. "|cFFFF5959" .. L["DURATIONPANEL_TITLE"] .. "|r" 
				else
					text = text .. "/" .. L["DURATIONPANEL_TITLE"]
				end
				if icon.Type == "buff" then
					if db.profile.Groups[groupID].Icons[iconID].StackMinEnabled or db.profile.Groups[groupID].Icons[iconID].StackMaxEnabled then
						text = text .. "/" .. "|cFFFF5959" .. L["STACKSPANEL_TITLE"] .. "|r"
					else
						text = text .. "/" .. L["STACKSPANEL_TITLE"]
					end
					info.func = function()
						TMW.CEI = { g = TMW.CI.g, i = TMW.CI.i }
						TellMeWhen_StackEditorFrame:Show()
						IE:Load()
					end
				else
					info.func = function()
						TMW.CEI = { g = TMW.CI.g, i = TMW.CI.i }
						TellMeWhen_StackEditorFrame:Hide()
						IE:Load()
					end
				end
				info.text = text
				info.notCheckable = true
				UIDropDownMenu_AddButton(info)
			end

			info = UIDropDownMenu_CreateInfo()
			info.text = ""
			info.disabled = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)

			--meta icons
			if icon.Type == "meta" then
				info = UIDropDownMenu_CreateInfo()
				info.text = L["ICONMENU_ICONS"]
				info.func = function()
					TMW.CMI = { g = TMW.CI.g, i = TMW.CI.i }
					ME:Update()
					TellMeWhen_MetaEditorFrame:Show()
				end
				info.hasArrow = false
				info.notCheckable = true
				UIDropDownMenu_AddButton(info)
			end
			
			-- additional options
			if icon.Type ~= "" then
				local moreOptions = TMW.IconMenuOptions[icon.Type] or {}
				for k,v in pairs(moreOptions) do
					info = UIDropDownMenu_CreateInfo()
					info.hasArrow = v.hasArrow
					if v.tooltipText then
						info.tooltipTitle = v.text
						info.tooltipText = v.tooltipText
						info.tooltipOnButton = true
					end
					info.text = v.text
					info.value = v.value

					if not v.hasArrow then
						info.func = TellMeWhen_IconMenu_ToggleSetting
						info.checked = db.profile.Groups[groupID].Icons[iconID][v.value]
						info.notCheckable = false
					else
						info.notCheckable = true
					end
					
					info.isNotRadio = true
					if v.value == "ShowTimerText" then
						if IsAddOnLoaded("OmniCC") or IsAddOnLoaded("tullaCC") then
							info.disabled = false
						else
							info.disabled = true
							info.tooltipWhileDisabled = true
							info.checked = false
						end
					end
					info.keepShownOnClick = true
					UIDropDownMenu_AddButton(info)
				end
			else
				info = UIDropDownMenu_CreateInfo()
				info.text = L["ICONMENU_OPTIONS"]
				info.disabled = true
				UIDropDownMenu_AddButton(info)
			end
		end
		
		info = UIDropDownMenu_CreateInfo()
		info.text = ""
		info.disabled = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		-- copy settings
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYGROUPICON"]
		info.value = "Copy"
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		-- group settings
		info = UIDropDownMenu_CreateInfo()
		info.text = L["GROUPSETTINGS"]
		info.value = "Group"
		info.hasArrow = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		-- clear settings
		if ((icon.Name) and (icon.Name ~= "")) or (icon.Type ~= "") then
			info = UIDropDownMenu_CreateInfo()
			info.text = L["ICONMENU_CLEAR"]
			info.func = TellMeWhen_IconMenu_ClearSettings
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)
		end
	end

	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == "Copy" then
			local current = db:GetCurrentProfile()
			if db.profiles[current] then
				info = UIDropDownMenu_CreateInfo()
				info.text = current
				info.value = current
				info.hasArrow = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				
				info = UIDropDownMenu_CreateInfo()
				info.text = ""
				info.isTitle = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			for profilename,profiletable in pairs(db.profiles) do
				if not (profilename == current or profilename == "Default") then
					info = UIDropDownMenu_CreateInfo()
					info.text = profilename
					info.value = profilename
					info.hasArrow = true
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
			if db.profiles["Default"] then
				info = UIDropDownMenu_CreateInfo()
				info.text = "Default"
				info.value = "Default"
				info.hasArrow = true
				info.notCheckable = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			return
		end
		if UIDROPDOWNMENU_MENU_VALUE == "Group" then
		
			info = UIDropDownMenu_CreateInfo() -- rename
			info.text = L["UIPANEL_GROUPNAME"]
			info.func = function()
				local d = StaticPopup_Show("TMW_RENAMEGROUP")
				if d then
					d.text:SetText(L["UIPANEL_GROUPNAME"].."\r\n"..TMW:GetGroupName(db.profile.Groups[groupID].Name,groupID))
					d.data = groupID
					d.editBox:SetText(db.profile.Groups[groupID].Name)
				end
			end
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo() -- enabled
			info.text = L["UIPANEL_ENABLEGROUP"]
			info.tooltipText = L["UIPANEL_TOOLTIP_ENABLEGROUP"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.func = function()
				db.profile.Groups[groupID].Enabled = not db.profile.Groups[groupID].Enabled
				TMW:Group_Update(groupID)
			end
			info.checked = db.profile.Groups[groupID].Enabled
			info.keepShownOnClick = true
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo() --combat
			info.text = L["UIPANEL_ONLYINCOMBAT"]
			info.tooltipText = L["UIPANEL_TOOLTIP_ONLYINCOMBAT"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.func = function()
				db.profile.Groups[groupID].OnlyInCombat = not db.profile.Groups[groupID].OnlyInCombat
				TMW:Group_Update(groupID)
			end
			info.checked = db.profile.Groups[groupID].OnlyInCombat
			info.keepShownOnClick = true
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo() --vehicle
			info.text = L["UIPANEL_NOTINVEHICLE"]
			info.tooltipText = L["UIPANEL_TOOLTIP_NOTINVEHICLE"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.func = function()
				db.profile.Groups[groupID].NotInVehicle = not db.profile.Groups[groupID].NotInVehicle
				TMW:Group_Update(groupID)
			end
			info.checked = db.profile.Groups[groupID].NotInVehicle
			info.keepShownOnClick = true
			info.isNotRadio = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			
			info = UIDropDownMenu_CreateInfo() -- columns
			info.text = L["UIPANEL_COLUMNS"]
			info.value = "Columns"
			info.tooltipText = L["UIPANEL_TOOLTIP_COLUMNS"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo() -- rows
			info.text = L["UIPANEL_ROWS"]
			info.value = "Rows"
			info.tooltipText = L["UIPANEL_TOOLTIP_ROWS"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.hasArrow = true
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			if #(TMW.CSN) > 0 then
				info = UIDropDownMenu_CreateInfo() -- stance
				info.text = L["UIPANEL_STANCE"]
				info.value = "Stance"
				info.hasArrow = true
				info.notCheckable = true
				info.keepShownOnClick = true
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			
			info = UIDropDownMenu_CreateInfo()
			info.text = ""
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				
			info = UIDropDownMenu_CreateInfo() -- delete
			info.text = L["UIPANEL_DELGROUP"]
			info.tooltipText = L["UIPANEL_DELGROUP_DESC"]
			info.tooltipTitle = info.text
			info.tooltipOnButton = true
			info.func = function()
				TMW:Group_OnDelete(groupID)
			end
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			return
		end
		
		if not TMW.IconMenu_SubMenus[UIDROPDOWNMENU_MENU_VALUE] then return end
		for k,v in pairs(TMW.IconMenu_SubMenus[UIDROPDOWNMENU_MENU_VALUE]) do
			-- here, UIDROPDOWNMENU_MENU_VALUE is the setting name
			info = UIDropDownMenu_CreateInfo()
			info.text = v.text
			info.value = v.value
			if v.tooltipText then
				info.tooltipTitle = v.tooltipTitle or v.text
				info.tooltipText = v.tooltipText
				info.tooltipOnButton = true
			end
			info.colorCode = v.colorCode
			if UIDROPDOWNMENU_MENU_VALUE == "Bars" then
				info.checked = db.profile.Groups[groupID].Icons[iconID][info.value]
				info.func = TellMeWhen_IconMenu_ToggleSetting
				info.keepShownOnClick = true
				info.isNotRadio = true
			else
				info.checked = (info.value == db.profile.Groups[groupID].Icons[iconID][UIDROPDOWNMENU_MENU_VALUE])
				info.func = TellMeWhen_IconMenu_ChooseSetting
			end
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end

	if UIDROPDOWNMENU_MENU_LEVEL == 3 then
		if UIDROPDOWNMENU_MENU_VALUE == "Columns" then
			info = UIDropDownMenu_CreateInfo()
			info.text = ADD
			info.func = function()
				db.profile.Groups[groupID].Columns = min(db.profile.Groups[groupID].Columns + 1,TELLMEWHEN_MAXROWS)
				TMW:Group_Update(groupID)
			end
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo()
			info.text = REMOVE
			info.func = function()
				db.profile.Groups[groupID].Columns = max(db.profile.Groups[groupID].Columns - 1, 1)
				TMW:Group_Update(groupID)
			end
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			return
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "Rows" then
			info = UIDropDownMenu_CreateInfo()
			info.text = ADD
			info.func = function()
				db.profile.Groups[groupID].Rows = min(db.profile.Groups[groupID].Rows + 1,TELLMEWHEN_MAXROWS)
				TMW:Group_Update(groupID)
			end
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			info = UIDropDownMenu_CreateInfo()
			info.text = REMOVE
			info.func = function()
				db.profile.Groups[groupID].Rows = max(db.profile.Groups[groupID].Rows - 1, 1)
				TMW:Group_Update(groupID)
			end
			info.notCheckable = true
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			return
		end
		
		if UIDROPDOWNMENU_MENU_VALUE == "Stance" then
			info = UIDropDownMenu_CreateInfo()
			info.text = TMW.CSN[0]
			info.func = function()
				db.profile.Groups[groupID].Stance[TMW.CSN[0]] = not db.profile.Groups[groupID].Stance[TMW.CSN[0]]
				TMW:Group_Update(groupID)
			end
			info.keepShownOnClick = true
			info.isNotRadio = true
			info.checked = db.profile.Groups[groupID].Stance[TMW.CSN[0]]
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			
			for k,v in pairs(TMW.CSN) do
				if not (k == 0) then
					info = UIDropDownMenu_CreateInfo()
					info.text = v
					info.func = function()
						db.profile.Groups[groupID].Stance[v] = not db.profile.Groups[groupID].Stance[v]
						TMW:Group_Update(groupID)
					end
					info.keepShownOnClick = true
					info.isNotRadio = true
					info.checked = db.profile.Groups[groupID].Stance[v]
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
			return
		end
		
		for g,v in pairs(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups) do
			info = UIDropDownMenu_CreateInfo()
			info.text = TMW:GetGroupName(db.profiles[UIDROPDOWNMENU_MENU_VALUE].Groups[g].Name, g)
			info.value = {profilename = UIDROPDOWNMENU_MENU_VALUE, groupid = g}
			info.hasArrow = true
			info.notCheckable = true
			info.tooltipTitle = L["COPYPANEL_GROUP"] .. g
			info.tooltipText = 	(L["UIPANEL_ROWS"]..": "..(v.Rows or 1).."\r\n")..
							L["UIPANEL_COLUMNS"]..": "..(v.Columns or 4)..
							(v.OnlyInCombat and "\r\n"..L["UIPANEL_ONLYINCOMBAT"] or "")..
							(v.NotInVehicle and "\r\n"..L["UIPANEL_NOTINVEHICLE"] or "")..
							
							
							((v.Enabled and "") or "\r\n("..L["DISABLED"]..")")
			info.tooltipOnButton = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
	
	if UIDROPDOWNMENU_MENU_LEVEL == 4 then
		local g = UIDROPDOWNMENU_MENU_VALUE.groupid
		local n = UIDROPDOWNMENU_MENU_VALUE.profilename
		
		info = UIDropDownMenu_CreateInfo()
		info.text = n .. ": " .. TMW:GetGroupName(db.profiles[n].Groups[g].Name, g)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYPOS"]
		info.func = function() -- yes, i do realize that the way all of these are coded is really, really lame. feel free to figure out a better way.
			local currentprofile = db:GetCurrentProfile()
			db:SetProfile(n) -- i have to do this because the metatables are not put in for inactive profiles.
			local temp = CopyWithMetatable(db.profile.Groups[g].Point)
			local tempscale = db.profile.Groups[g].Scale
			db:SetProfile(currentprofile)
			wipe(db.profile.Groups[groupID].Point)
			db.profile.Groups[groupID].Point = CopyWithMetatable(temp)
			db.profile.Groups[groupID].Scale = tempscale
			TMW:Group_Update(groupID)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		info = UIDropDownMenu_CreateInfo()
		info.text = L["COPYALL"]
		info.func = function()
			local currentprofile = db:GetCurrentProfile()
			db:SetProfile(n)
			local temp = CopyWithMetatable(db.profile.Groups[g])
			db:SetProfile(currentprofile)
			wipe(db.profile.Groups[groupID])
			db.profile.Groups[groupID] = CopyWithMetatable(temp)
			TMW:Group_Update(groupID)
		end
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		if db.profiles[n].Groups[g].Icons and #db.profiles[n].Groups[g].Icons > 0 then
		
			info = UIDropDownMenu_CreateInfo()
			info.text = ""
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			for i,d in pairs(db.profiles[n].Groups[g].Icons) do
				local nsettings = 0
				for icondatakey,icondatadata in pairs(d) do
					if type(icondatadata) == "table" then if #icondatadata ~= 0 then nsettings = nsettings + 1 end
					elseif TMW.Icon_Defaults[icondatakey] ~= icondatadata then
						nsettings = nsettings + 1
					end
				end
				if nsettings > 0 and tonumber(i) then
					local tex = nil
					local ic = _G["TellMeWhen_Group"..g.."_Icon"..i]
					if db:GetCurrentProfile() == n and ic and ic.texture:GetTexture() then
						tex = ic.texture:GetTexture()
					end
					if (d.Name and d.Name ~= "" and d.Type ~= "meta" and d.Type ~= "wpnenchant") and not tex then
						local name = TMW:GetSpellNames(nil,d.Name,1)
						if name then
							tex = GetSpellTexture(name)
							if d.Type == "cooldown" and d.CooldownType == "item" then
								tex = select(10,GetItemInfo(name)) or tex
							end
						end
					end
					if d.Type == "cast" and not tex then tex = "Interface\\Icons\\Temp"
					elseif d.Type == "buff" and not tex then tex = "Interface\\Icons\\INV_Misc_PocketWatch_01"
					elseif d.Type == "meta" and not tex then tex = "Interface\\Icons\\LevelUpIcon-LFD"
					elseif d.Type == "wpnenchant" and not tex then tex = GetInventoryItemTexture("player", GetInventorySlotInfo(d.WpnEnchantType or "MainHandSlot")) or GetInventoryItemTexture("player", "MainHandSlot") end
					if not tex then tex = "Interface\\Icons\\INV_Misc_QuestionMark" end
					
					info = UIDropDownMenu_CreateInfo()
					info.text = L["COPYICON"] .. i
					info.func = function()
						local currentprofile = db:GetCurrentProfile()
						db:SetProfile(n)
						local temp = CopyWithMetatable(db.profile.Groups[g].Icons[i])
						db:SetProfile(currentprofile)
						wipe(db.profile.Groups[groupID].Icons[iconID])
						db.profile.Groups[groupID].Icons[iconID] = CopyWithMetatable(temp)
						TMW:Group_Update(groupID)
					end
					info.tooltipTitle = format(L["GROUPICON"], TMW:GetGroupName(db.profiles[n].Groups[g].Name, g, 1), i)
					info.tooltipText = 	((d.Name and d.Name ~= "" and d.Type ~= "meta" and d.Type ~= "wpnenchant") and d.Name.."\r\n" or "")..
									(d.Type and GetLocalizedSettingString("Type",d.Type) and GetLocalizedSettingString("Type",d.Type) or "")..
									((d.Enabled and "") or "\r\n("..L["DISABLED"]..")")
					info.tooltipOnButton = true
					info.icon = tex
					info.notCheckable = true
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
	end
	
end

function TellMeWhen_IconMenu_ToggleSetting(self)
	local groupID = TMW.CI.g
	local iconID = TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID][self.value] = self.checked
	TMW:Icon_Update(groupID, iconID)
end

function TellMeWhen_IconMenu_ChooseSetting(self)
	local groupID = TMW.CI.g
	local iconID = TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID][UIDROPDOWNMENU_MENU_VALUE] = self.value
	TMW:Icon_Update(groupID, iconID)
	if (UIDROPDOWNMENU_MENU_VALUE == "Type") then
		CloseDropDownMenus()
	end
end

function TellMeWhen_IconMenu_ClearSettings()
	local groupID = TMW.CI.g
	local iconID = TMW.CI.i
	db.profile.Groups[groupID].Icons[iconID] = nil
	TMW:Icon_Update(groupID, iconID)
	CloseDropDownMenus()
end


function TellMeWhen_Icon_OnEnter(icon, motion)
	GameTooltip_SetDefaultAnchor(GameTooltip, icon)
	GameTooltip:AddLine(L["ICON_TOOLTIP1"] .. " " .. format(L["GROUPICON"], TMW:GetGroupName(icon:GetParent().Name, icon:GetParent():GetID(), 1),icon:GetID()), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
	GameTooltip:AddLine(L["ICON_TOOLTIP2"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
	GameTooltip:Show()
end

function TellMeWhen_Icon_OnMouseDown(icon, button)
	if (button == "RightButton") then
 		PlaySound("UChatScrollButton")
		TMW.CI.i = icon:GetID()		-- yay for dirty hacks
		TMW.CI.g = icon:GetParent():GetID()
		ToggleDropDownMenu(1, nil, TellMeWhen_IconDropDown, "cursor", 0, 0)
 	end
end


-- ----------------------
-- ICON CONFIG DIALOGS
-- ----------------------

AE = TMW:NewModule("AlphaEditor")

function AE:Init()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	TellMeWhen_AlphaEditorFrameFS1:SetText(L["ALPHAPANEL_TITLE"])

	TellMeWhen_AlphaEditorFrameAlphaSliderText:SetText(L["ICONALPHAPANEL_ALPHA"])
	TellMeWhen_AlphaEditorFrameUnAlphaSliderText:SetText(L["ICONALPHAPANEL_UNALPHA"])
	TellMeWhen_AlphaEditorFrameConditionAlphaSliderText:SetText(L["ICONALPHAPANEL_CNDTALPHA"])
	TellMeWhen_AlphaEditorFrameDurationSliderText:SetText(L["ICONALPHAPANEL_DURATIONALPHA"])
	TellMeWhen_AlphaEditorFrameStackSliderText:SetText(L["ICONALPHAPANEL_STACKALPHA"])
	TellMeWhen_AlphaEditorFrameFakeHiddenText:SetText(L["ICONALPHAPANEL_FAKEHIDDEN"])
	TellMeWhen_AlphaEditorFrameFakeHiddenText:SetFontObject("GameFontHighlight")
	
	
	TT(TellMeWhen_AlphaEditorFrameAlphaSlider,L["ICONALPHAPANEL_ALPHA_DESC"])
	TT(TellMeWhen_AlphaEditorFrameUnAlphaSlider,L["ICONALPHAPANEL_UNALPHA_DESC"])
	TT(TellMeWhen_AlphaEditorFrameConditionAlphaSlider,L["ICONALPHAPANEL_CNDTALPHA_DESC"])
	TT(TellMeWhen_AlphaEditorFrameDurationSlider,L["ICONALPHAPANEL_DURATIONALPHA_DESC"])
	TT(TellMeWhen_AlphaEditorFrameStackSlider,L["ICONALPHAPANEL_STACKALPHA_DESC"])
	TT(TellMeWhen_AlphaEditorFrameFakeHidden,L["ICONALPHAPANEL_FAKEHIDDEN_DESC"])
end

function AE:OK()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	local Alpha = TellMeWhen_AlphaEditorFrameAlphaSlider
	local UnAlpha = TellMeWhen_AlphaEditorFrameUnAlphaSlider
	local StackAlpha = TellMeWhen_AlphaEditorFrameStackSlider
	local DurationAlpha = TellMeWhen_AlphaEditorFrameDurationSlider
	local ConditionAlpha = TellMeWhen_AlphaEditorFrameConditionAlphaSlider
	local FakeHidden = TellMeWhen_AlphaEditorFrameFakeHidden

	if Alpha:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].Alpha then
		db.profile.Groups[groupID].Icons[iconID]["Alpha"] = Alpha:GetValue()/100
	end
	if UnAlpha:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].UnAlpha then
		db.profile.Groups[groupID].Icons[iconID]["UnAlpha"] = UnAlpha:GetValue()/100
	end
	if StackAlpha:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].StackAlpha then
		db.profile.Groups[groupID].Icons[iconID]["StackAlpha"] = StackAlpha:GetValue()/100
	end
	if DurationAlpha:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].DurationAlpha then
		db.profile.Groups[groupID].Icons[iconID]["DurationAlpha"] = DurationAlpha:GetValue()/100
	end
	if ConditionAlpha:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].ConditionAlpha then
		db.profile.Groups[groupID].Icons[iconID]["ConditionAlpha"] = ConditionAlpha:GetValue()/100
	end
	if FakeHidden:GetChecked() ~= db.profile.Groups[groupID].Icons[iconID].FakeHidden then
		db.profile.Groups[groupID].Icons[iconID]["FakeHidden"] = not not FakeHidden:GetChecked() --not not turns it into true/false isntead of 1/nil
	end
end

function AE:Reset()
	if not TMW.AlphaInitd then
		AE:Init()
		TMW.AlphaInitd = true
	end
	TellMeWhen_AlphaEditorFrameAlphaSlider:SetValue(TMW.Icon_Defaults.Alpha*100)
	TellMeWhen_AlphaEditorFrameUnAlphaSlider:SetValue(TMW.Icon_Defaults.UnAlpha*100)
	TellMeWhen_AlphaEditorFrameStackSlider:SetValue(TMW.Icon_Defaults.StackAlpha*100)
	TellMeWhen_AlphaEditorFrameDurationSlider:SetValue(TMW.Icon_Defaults.DurationAlpha*100)
	TellMeWhen_AlphaEditorFrameConditionAlphaSlider:SetValue(TMW.Icon_Defaults.ConditionAlpha*100)
	
	TellMeWhen_AlphaEditorFrameFakeHidden:SetChecked(false)
	IE:CheckOrChange()
end

function AE:Load()
	AE:Reset()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i

	TellMeWhen_AlphaEditorFrameAlphaSlider:SetValue(db.profile.Groups[groupID].Icons[iconID].Alpha*100)
	TellMeWhen_AlphaEditorFrameUnAlphaSlider:SetValue(db.profile.Groups[groupID].Icons[iconID].UnAlpha*100)
	TellMeWhen_AlphaEditorFrameStackSlider:SetValue(db.profile.Groups[groupID].Icons[iconID].StackAlpha*100)
	TellMeWhen_AlphaEditorFrameDurationSlider:SetValue(db.profile.Groups[groupID].Icons[iconID].DurationAlpha*100)
	TellMeWhen_AlphaEditorFrameConditionAlphaSlider:SetValue(db.profile.Groups[groupID].Icons[iconID].ConditionAlpha*100)
	TellMeWhen_AlphaEditorFrameFakeHidden:SetChecked(db.profile.Groups[groupID].Icons[iconID].FakeHidden)
	IE:CheckOrChange()
end

SE = TMW:NewModule("StackEditor")

function SE:Init()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	TellMeWhen_StackEditorFrameFS1:SetText(L["STACKSPANEL_TITLE"])
	TellMeWhen_StackEditorFrameMinSliderText:SetText(MINIMUM)
	TellMeWhen_StackEditorFrameMaxSliderText:SetText(MAXIMUM)
	
	TT(TellMeWhen_StackEditorFrameMinSlider,L["ICONMENU_STACKS_MIN_DESC"])
	TT(TellMeWhen_StackEditorFrameMaxSlider,L["ICONMENU_STACKS_MAX_DESC"])
end

function SE:OK()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	local StackMin = TellMeWhen_StackEditorFrameMinSlider
	local StackMax = TellMeWhen_StackEditorFrameMaxSlider
	local StackMinCheck = TellMeWhen_StackEditorFrameMinCheck
	local StackMaxCheck = TellMeWhen_StackEditorFrameMaxCheck

	if StackMin:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].StackMin then
		db.profile.Groups[groupID].Icons[iconID]["StackMin"] = StackMin:GetValue()
	end
	if StackMax:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].StackMax then
		db.profile.Groups[groupID].Icons[iconID]["StackMax"] = StackMax:GetValue()
	end
	if StackMinCheck:GetChecked() ~= db.profile.Groups[groupID].Icons[iconID].StackMinEnabled then
		db.profile.Groups[groupID].Icons[iconID]["StackMinEnabled"] = not not StackMinCheck:GetChecked()
	end
	if StackMaxCheck:GetChecked() ~= db.profile.Groups[groupID].Icons[iconID].StackMaxEnabled then
		db.profile.Groups[groupID].Icons[iconID]["StackMaxEnabled"] = not not StackMaxCheck:GetChecked()
	end
end

function SE:Reset()
	if not TMW.StackInitd then
		SE:Init()
		TMW.StackInitd = true
	end
	local StackMin = TellMeWhen_StackEditorFrameMinSlider
	local StackMax = TellMeWhen_StackEditorFrameMaxSlider
	
	StackMin:Disable()
	StackMin:SetAlpha(.4)
	StackMax:Disable()
	StackMax:SetAlpha(.4)
	TellMeWhen_StackEditorFrameMinCheck:SetChecked(false)
	TellMeWhen_StackEditorFrameMaxCheck:SetChecked(false)
	
	StackMin:SetMinMaxValues(max(0,(TMW.Icon_Defaults.StackMin-20)),max(20,(TMW.Icon_Defaults.StackMin+20)))
	StackMax:SetMinMaxValues(max(0,(TMW.Icon_Defaults.StackMax-20)),max(20,(TMW.Icon_Defaults.StackMax+20)))
	StackMin:SetValue(TMW.Icon_Defaults.StackMin)
	StackMax:SetValue(TMW.Icon_Defaults.StackMax)
	StackMin:SetMinMaxValues(max(0,(StackMin:GetValue()-20)),max(20,(StackMin:GetValue()+20)))
	StackMax:SetMinMaxValues(max(0,(StackMax:GetValue()-20)),max(20,(StackMax:GetValue()+20)))
	IE:CheckOrChange()
end

function SE:Load()
	SE:Reset()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	
	local StackMin = TellMeWhen_StackEditorFrameMinSlider
	local StackMax = TellMeWhen_StackEditorFrameMaxSlider
	local StackMinCheck = TellMeWhen_StackEditorFrameMinCheck
	local StackMaxCheck = TellMeWhen_StackEditorFrameMaxCheck
	
	local MinVal = db.profile.Groups[groupID].Icons[iconID].StackMin
	local MaxVal = db.profile.Groups[groupID].Icons[iconID].StackMax
	StackMin:SetMinMaxValues(max(0,(MinVal-20)),max(20,(MinVal+20)))
	StackMax:SetMinMaxValues(max(0,(MaxVal-20)),max(20,(MaxVal+20)))
	StackMin:SetValue(MinVal)
	StackMax:SetValue(MaxVal)
	StackMinCheck:SetChecked(db.profile.Groups[groupID].Icons[iconID].StackMinEnabled)
	StackMaxCheck:SetChecked(db.profile.Groups[groupID].Icons[iconID].StackMaxEnabled)
	StackMin:SetMinMaxValues(max(0,(StackMin:GetValue()-20)),max(20,(StackMin:GetValue()+20)))
	StackMax:SetMinMaxValues(max(0,(StackMax:GetValue()-20)),max(20,(StackMax:GetValue()+20)))
	if StackMinCheck:GetChecked() then
		StackMin:Enable()
		StackMin:SetAlpha(1)
	else
		StackMin:Disable()
		StackMin:SetAlpha(.4)
	end
	if StackMaxCheck:GetChecked() then
		StackMax:Enable()
		StackMax:SetAlpha(1)
	else
		StackMax:Disable()
		StackMax:SetAlpha(.4)
	end
	IE:CheckOrChange()
end

DE = TMW:NewModule("DurationEditor")

function DE:Init()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	TellMeWhen_DurationEditorFrameFS1:SetText(L["DURATIONPANEL_TITLE"])
	TellMeWhen_DurationEditorFrameMinSliderText:SetText(MINIMUM)
	TellMeWhen_DurationEditorFrameMaxSliderText:SetText(MAXIMUM)
	
	TT(TellMeWhen_DurationEditorFrameMinSlider,L["ICONMENU_DURATION_MIN_DESC"])
	TT(TellMeWhen_DurationEditorFrameMaxSlider,L["ICONMENU_DURATION_MAX_DESC"])
end

function DE:OK()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	local DurationMin = TellMeWhen_DurationEditorFrameMinSlider
	local DurationMax = TellMeWhen_DurationEditorFrameMaxSlider
	local DurationMinCheck = TellMeWhen_DurationEditorFrameMinCheck
	local DurationMaxCheck = TellMeWhen_DurationEditorFrameMaxCheck

	if DurationMin:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].DurationMin then
		db.profile.Groups[groupID].Icons[iconID]["DurationMin"] = DurationMin:GetValue()
	end
	if DurationMax:GetValue() ~= db.profile.Groups[groupID].Icons[iconID].DurationMax then
		db.profile.Groups[groupID].Icons[iconID]["DurationMax"] = DurationMax:GetValue()
	end
	if DurationMinCheck:GetChecked() ~= db.profile.Groups[groupID].Icons[iconID].DurationMinEnabled then
		db.profile.Groups[groupID].Icons[iconID]["DurationMinEnabled"] = not not DurationMinCheck:GetChecked()
	end
	if DurationMaxCheck:GetChecked() ~= db.profile.Groups[groupID].Icons[iconID].DurationMaxEnabled then
		db.profile.Groups[groupID].Icons[iconID]["DurationMaxEnabled"] = not not DurationMaxCheck:GetChecked()
	end
end

function DE:Reset()
	if not TMW.DurationInitd then
		DE:Init()
		TMW.DurationInitd = true
	end
	local DurationMin = TellMeWhen_DurationEditorFrameMinSlider
	local DurationMax = TellMeWhen_DurationEditorFrameMaxSlider
	
	DurationMin:Disable()
	DurationMin:SetAlpha(.4)
	DurationMax:Disable()
	DurationMax:SetAlpha(.4)
	TellMeWhen_DurationEditorFrameMinCheck:SetChecked(false)
	TellMeWhen_DurationEditorFrameMaxCheck:SetChecked(false)
	
	DurationMin:SetMinMaxValues(max(0,(TMW.Icon_Defaults.DurationMin-20)),max(20,(TMW.Icon_Defaults.DurationMin+20)))
	DurationMax:SetMinMaxValues(max(0,(TMW.Icon_Defaults.DurationMax-20)),max(20,(TMW.Icon_Defaults.DurationMax+20)))
	DurationMin:SetValue(TMW.Icon_Defaults.DurationMin)
	DurationMax:SetValue(TMW.Icon_Defaults.DurationMax)
	DurationMin:SetMinMaxValues(max(0,(DurationMin:GetValue()-20)),max(20,(DurationMin:GetValue()+20)))
	DurationMax:SetMinMaxValues(max(0,(DurationMax:GetValue()-20)),max(20,(DurationMax:GetValue()+20)))
	IE:CheckOrChange()
end

function DE:Load()
	DE:Reset()
	local groupID,iconID = TMW.CEI.g,TMW.CEI.i
	
	local DurationMin = TellMeWhen_DurationEditorFrameMinSlider
	local DurationMax = TellMeWhen_DurationEditorFrameMaxSlider
	local DurationMinCheck = TellMeWhen_DurationEditorFrameMinCheck
	local DurationMaxCheck = TellMeWhen_DurationEditorFrameMaxCheck
	
	local MinVal = db.profile.Groups[groupID].Icons[iconID].DurationMin
	local MaxVal = db.profile.Groups[groupID].Icons[iconID].DurationMax
	DurationMin:SetMinMaxValues(max(0,(MinVal-20)),max(20,(MinVal+20)))
	DurationMax:SetMinMaxValues(max(0,(MaxVal-20)),max(20,(MaxVal+20)))
	DurationMin:SetValue(MinVal)
	DurationMax:SetValue(MaxVal)
	DurationMinCheck:SetChecked(db.profile.Groups[groupID].Icons[iconID].DurationMinEnabled)
	DurationMaxCheck:SetChecked(db.profile.Groups[groupID].Icons[iconID].DurationMaxEnabled)
	DurationMin:SetMinMaxValues(max(0,(DurationMin:GetValue()-20)),max(20,(DurationMin:GetValue()+20)))
	DurationMax:SetMinMaxValues(max(0,(DurationMax:GetValue()-20)),max(20,(DurationMax:GetValue()+20)))
	if DurationMinCheck:GetChecked() then
		DurationMin:Enable()
		DurationMin:SetAlpha(1)
	else
		DurationMin:Disable()
		DurationMin:SetAlpha(.4)
	end
	if DurationMaxCheck:GetChecked() then
		DurationMax:Enable()
		DurationMax:SetAlpha(1)
	else
		DurationMax:Disable()
		DurationMax:SetAlpha(.4)
	end
	IE:CheckOrChange()
end

IE = TMW:NewModule("IconEditor")

function IE:Init()
	TellMeWhen_EditorFrameCancelButton:SetText(CANCEL)
	TellMeWhen_EditorFrameOkayButton:SetText(OKAY)
end

function IE:OK()
	AE:OK()
	DE:OK()
	SE:OK()
end

function IE:Load()
	if not TMW.EditorInitd then
		IE:Init()
		TMW.EditorInitd = true
	end
	TellMeWhen_EditorFrameIconTexture:SetTexture(_G["TellMeWhen_Group" .. TMW.CEI.g .. "_Icon" .. TMW.CEI.i].texture:GetTexture())
		TellMeWhen_EditorFrameFS1:SetText(L["EDITORPANEL_TITLE"] .. ": " .. (format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[TMW.CEI.g].Name,TMW.CEI.g,1), TMW.CEI.i)))
	AE:Load()
	DE:Load()
	SE:Load()
	TellMeWhen_EditorFrame:Show()
	TellMeWhen_EditorFrame:SetFrameLevel(110)
	IE:CheckOrChange()
end

function IE:CheckOrChange()
	if not TMW.Initd then return end
	if TellMeWhen_DurationEditorFrameMinCheck:GetChecked()
	or TellMeWhen_DurationEditorFrameMaxCheck:GetChecked() then
		TellMeWhen_DurationEditorFrameFS1:SetText("|cFFFF5959" .. L["DURATIONPANEL_TITLE"] .. "|r")
	else
		TellMeWhen_DurationEditorFrameFS1:SetText(L["DURATIONPANEL_TITLE"])
	end
	
	if TellMeWhen_StackEditorFrameMinCheck:GetChecked()
	or TellMeWhen_StackEditorFrameMaxCheck:GetChecked() then
		TellMeWhen_StackEditorFrameFS1:SetText("|cFFFF5959" .. L["STACKSPANEL_TITLE"] .. "|r")
	else
		TellMeWhen_StackEditorFrameFS1:SetText(L["STACKSPANEL_TITLE"])
	end
	
	if TellMeWhen_AlphaEditorFrameAlphaSlider:GetValue() ~= 100
	or TellMeWhen_AlphaEditorFrameUnAlphaSlider:GetValue() ~= 100
	or TellMeWhen_AlphaEditorFrameStackSlider:GetValue() ~= 0
	or TellMeWhen_AlphaEditorFrameDurationSlider:GetValue() ~= 0
	or TellMeWhen_AlphaEditorFrameConditionAlphaSlider:GetValue() ~= 0
	or TellMeWhen_AlphaEditorFrameFakeHidden:GetChecked() then
		TellMeWhen_AlphaEditorFrameFS1:SetText("|cFFFF5959" .. L["ALPHAPANEL_TITLE"] .. "|r")
	else
		TellMeWhen_AlphaEditorFrameFS1:SetText(L["ALPHAPANEL_TITLE"])
	end
	
	
	local height = 245
	if TellMeWhen_StackEditorFrame:IsShown() then
		height = height + 90
	end
	if TellMeWhen_DurationEditorFrame:IsShown() then
		height = height + 90
	end
	TellMeWhen_EditorFrame:SetHeight(height)
end

ME = TMW:NewModule("MetaEditor")

function ME:Reset()
	local groupID,iconID = TMW.CMI.g,TMW.CMI.i
	local i=1
	while _G["TellMeWhen_MetaEditorGroup" .. i] do
		UIDropDownMenu_SetSelectedValue(_G["TellMeWhen_MetaEditorGroup" .. i].icon, nil)
		UIDropDownMenu_SetText(_G["TellMeWhen_MetaEditorGroup" .. i].icon,"")
		if i>1 then
			_G["TellMeWhen_MetaEditorGroup" .. i]:Hide()
		end
		i=i+1
	end
	db.profile.Groups[groupID].Icons[iconID].Icons={}
	ME:Update()
end

function ME:UpOrDown(self,delta)
	local groupID,iconID = TMW.CMI.g,TMW.CMI.i
	local settings = db.profile.Groups[groupID].Icons[iconID].Icons
	local ID = self:GetParent():GetID()
	local curdata,destinationdata
	curdata = settings[ID]
	destinationdata = settings[ID+delta]
	settings[ID] = destinationdata
	settings[ID+delta] = curdata
	ME:Update()
end

function ME:Insert(self)
	local groupID,iconID = TMW.CMI.g,TMW.CMI.i
	local where = self:GetParent():GetID()+1
	db.profile.Groups[groupID].Icons[iconID].Icons = db.profile.Groups[groupID].Icons[iconID].Icons or {}
	if not db.profile.Groups[groupID].Icons[iconID].Icons[1] then
		db.profile.Groups[groupID].Icons[iconID].Icons[1] = TMW.Icons[1]
		UIDropDownMenu_SetSelectedValue(TellMeWhen_MetaEditorGroup1.icon, TMW.Icons[1])
		UIDropDownMenu_SetText(TellMeWhen_MetaEditorGroup1.icon,TMW.Icons[1])
	end
	tinsert(db.profile.Groups[groupID].Icons[iconID].Icons,where,TMW.Icons[1])
	ME:Update()
end

function ME:Delete(self)
	tremove(db.profile.Groups[TMW.CMI.g].Icons[TMW.CMI.i].Icons, self:GetParent():GetID())
	ME:Update()
end

function ME:Update()
	local groupID,iconID = TMW.CMI.g,TMW.CMI.i
	TellMeWhen_MetaEditorFrameFS1:SetText(L["METAPANEL_TITLE"] .. ": " .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[groupID].Name,groupID,1),iconID))
	TellMeWhen_MetaEditorFrameIconTexture:SetTexture(_G["TellMeWhen_Group" .. groupID .. "_Icon" .. iconID].texture:GetTexture())
	TellMeWhen_MetaEditorFrame:SetFrameLevel(130)
	db.profile.Groups[groupID].Icons[iconID].Icons = db.profile.Groups[groupID].Icons[iconID].Icons or {}
	local settings = db.profile.Groups[groupID].Icons[iconID].Icons
	local i=1
	UIDropDownMenu_SetSelectedValue(TellMeWhen_MetaEditorGroup1.icon, nil)
	UIDropDownMenu_SetText(TellMeWhen_MetaEditorGroup1.icon, "")
	while _G["TellMeWhen_MetaEditorGroup" .. i] do
		local g = _G["TellMeWhen_MetaEditorGroup" .. i]
		g.up:Show()
		g.down:Show()
		g:Show()
		i=i+1
	end
	i=i-1 -- i is always the number of groups plus 1
	TellMeWhen_MetaEditorGroup1.up:Hide()
	TellMeWhen_MetaEditorGroup1.delete:Hide()
	
	for k,v in pairs(settings) do
		local mg = _G["TellMeWhen_MetaEditorGroup"..k]
		if not mg then
			mg = CreateFrame("Frame","TellMeWhen_MetaEditorGroup"..k,TellMeWhen_MetaEditorFrame,"TellMeWhen_MetaEditorGroup",k)
		end
		mg:Show()
		mg:SetPoint("TOP",_G["TellMeWhen_MetaEditorGroup"..k-1],"BOTTOM",0,0)
		mg:SetFrameLevel(131)
		UIDropDownMenu_SetSelectedValue(mg.icon, v)
		local text = TMW:GetIconMenuText(strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)"))
		UIDropDownMenu_SetText(mg.icon,text)
	end
	for f=#settings+1,i do
		_G["TellMeWhen_MetaEditorGroup" .. f]:Hide()
	end
	if #settings > 0 then
		_G["TellMeWhen_MetaEditorGroup" .. #settings].down:Hide()
	else
		TellMeWhen_MetaEditorGroup1.down:Hide()
	end
	TellMeWhen_MetaEditorGroup1:Show()
end

function ME:IconMenu()
	for k,v in pairs(TMW.Icons) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = ME.IconMenuOnClick
		local g,i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
		local text,textshort = TMW:GetIconMenuText(g,i)
		info.text = textshort
		info.value = v
		info.tooltipTitle = text
		info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name,g,1),i)
		info.tooltipOnButton = true
		info.icon = _G["TellMeWhen_Group"..g.."_Icon"..i].texture:GetTexture()
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function ME:IconMenuOnClick(frame)
	db.profile.Groups[TMW.CMI.g].Icons[TMW.CMI.i].Icons[frame:GetParent():GetID()] = self.value
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end

CN = TMW:NewModule("ChooseName")

function CN:Init()
	local groupID,iconID = TMW.CNI.g,TMW.CNI.i
	TellMeWhen_ChooseNameFrameText:SetText(L["CHOOSENAME_DIALOG"])
	TellMeWhen_ChooseNameFrameICDEditBoxFS1:SetText(L["CHOOSENAME_DIALOG_ICD"])
	TT(TellMeWhen_ChooseNameFrameICDEditBox,L["CHOOSENAME_DIALOG_ICD_DESC"])
	TellMeWhen_ChooseNameFrame:SetHeight(160 + TellMeWhen_ChooseNameFrameText:GetStringHeight())
	TellMeWhen_ChooseNameFrameCancelButton:SetText(CANCEL)
	TellMeWhen_ChooseNameFrameOkayButton:SetText(OKAY)
	UIDropDownMenu_SetText(TellMeWhen_EquivSelectDropdown,L["CHOOSENAME_DIALOG_DDDEFAULT"])
end

function CN:Load()
	if not TMW.ChooseNameInitd then
		CN:Init()
		TMW.ChooseNameInitd = true
	end
	TMW.CNI = { g = TMW.CI.g, i = TMW.CI.i }
	local groupID,iconID = TMW.CNI.g,TMW.CNI.i
	TellMeWhen_ChooseNameFrameIconTexture:SetTexture(_G["TellMeWhen_Group" .. groupID .. "_Icon" .. iconID].texture:GetTexture())
	TellMeWhen_ChooseNameFrameEditBox:SetText(db.profile.Groups[groupID].Icons[iconID].Name)
	TellMeWhen_ChooseNameFrameEditBox:SetFocus()
	TellMeWhen_ChooseNameFrameFS1:SetText(L["ICONMENU_CHOOSENAME"] .. ": " .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[groupID].Name,groupID,1),iconID))
	TellMeWhen_ChooseNameFrameICDEditBox:SetText(db.profile.Groups[groupID].Icons[iconID].ICDDuration)
	TellMeWhen_ChooseNameFrame:Show()
	TellMeWhen_ChooseNameFrame:SetFrameLevel(120)
end

function CN:OK()
	local groupID = TMW.CNI.g
	local iconID = TMW.CNI.i
	db.profile.Groups[groupID].Icons[iconID]["Name"] = TMW:CleanString(TellMeWhen_ChooseNameFrameEditBox:GetText())
	db.profile.Groups[groupID].Icons[iconID].ICDDuration = tonumber(strtrim(TellMeWhen_ChooseNameFrameICDEditBox:GetText())) or 45
	TMW:Icon_Update(groupID, iconID)
	TellMeWhen_ChooseNameFrame:Hide()
end

function CN:Equiv_GenerateTips(BoD,equiv)
	local r = "" --tconcat doesnt allow me to exclude duplicates unless i make another garbage table, so lets just do this
	local tab = TMW:SplitNames(TMW.BE[BoD][equiv])
	for k,v in pairs(tab) do
		local name = GetSpellInfo(v)
		if not tiptemp[name] then --prevents display of the same name twice when there are multiple ranks.
			if not (k == #tab) then
				r = r .. GetSpellInfo(v) .. "\r\n"
			else
				r = r .. GetSpellInfo(v)
			end
		end
		tiptemp[name] = true
	end
	wipe(tiptemp)
	return r
end

function CN:Equiv_OnEnter(self)
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(L["CHOOSENAME_EQUIVS_TOOLTIP"], 1, 1, 1, 1)
	GameTooltip:Show()
end

function CN:Equiv_DropDown()
	if (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		if TMW.BE[UIDROPDOWNMENU_MENU_VALUE] then
			for k,v in pairs(TMW.BE[UIDROPDOWNMENU_MENU_VALUE]) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = CN.Equiv_Insert
				info.text = L[k]
				info.tooltipTitle = k
				local text = CN:Equiv_GenerateTips(UIDROPDOWNMENU_MENU_VALUE,k)
				info.tooltipText = text
				info.tooltipOnButton = true
				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info,2)
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == "dispel" then
			for k,v in pairs(TMW.DS) do
				local info = UIDropDownMenu_CreateInfo()
				info.func = CN.Equiv_Insert
				info.text = L[k]
				info.value = k
				info.arg1 = k
				info.notCheckable = true
				UIDropDownMenu_AddButton(info,2)
			end
		end
		return
	end
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["ICONMENU_BUFF"]
	info.value = "buffs"
	info.hasArrow = true
	info.colorCode = "|cFF00FF00"
	info.notCheckable = true
	UIDropDownMenu_AddButton(info)

	--some stuff is reused for this one
	info.text = L["ICONMENU_DEBUFF"]
	info.value = "debuffs"
	info.colorCode = "|cFFFF0000"
	UIDropDownMenu_AddButton(info)

	info.text = L["ICONMENU_CASTS"]
	info.value = "casts"
	info.colorCode = nil
	UIDropDownMenu_AddButton(info)
	
	info.text = L["ICONMENU_DISPEL"]
	info.value = "dispel"
	UIDropDownMenu_AddButton(info)
	
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function CN:Equiv_Insert(value)
	local e = TellMeWhen_ChooseNameFrameEditBox
	e:Insert(";" .. value .. ";")
	e:SetText(TMW:CleanString(e:GetText()))
	CloseDropDownMenus()
end


-- -------------
-- GROUP CONFIG
-- -------------

function TMW:Group_ResizeOnEnter(self, shortText, longText)
	local tooltip = _G["GameTooltip"]
	if (GetCVar("UberTooltips") == "1") then
		GameTooltip_SetDefaultAnchor(tooltip, self)
		tooltip:AddLine(L[shortText], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, 1)
		tooltip:AddLine(L[longText], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		tooltip:Show()
	else
		tooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		tooltip:SetText(L[shortText])
	end
end

function TMW:Group_StartSizing(self, button)
	local scalingFrame = self:GetParent()
	scalingFrame.oldScale = scalingFrame:GetScale()
	self.oldCursorX, self.oldCursorY = GetCursorPosition(UIParent)
	scalingFrame.oldX = scalingFrame:GetLeft()
	scalingFrame.oldY = scalingFrame:GetTop()
	self:SetScript("OnUpdate", TMW.Group_SizeUpdate)
end

function TMW:Group_SizeUpdate()
	local uiScale = UIParent:GetScale()
	local scalingFrame = self:GetParent()
	local cursorX, cursorY = GetCursorPosition(UIParent)

	-- calculate new scale
	local newXScale = scalingFrame.oldScale * (cursorX/uiScale - scalingFrame.oldX*scalingFrame.oldScale) / (self.oldCursorX/uiScale - scalingFrame.oldX*scalingFrame.oldScale)
	local newYScale = scalingFrame.oldScale * (cursorY/uiScale - scalingFrame.oldY*scalingFrame.oldScale) / (self.oldCursorY/uiScale - scalingFrame.oldY*scalingFrame.oldScale)
	local newScale = max(0.6, newXScale, newYScale)
	scalingFrame:SetScale(newScale)

	-- calculate new frame position
	local newX = scalingFrame.oldX * scalingFrame.oldScale / newScale
	local newY = scalingFrame.oldY * scalingFrame.oldScale / newScale
	scalingFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newX, newY)
end

function TMW:Group_StopSizing(self, button)
	self:SetScript("OnUpdate", nil)
	local scalingFrame = self:GetParent()
	db.profile.Groups[scalingFrame:GetID()]["Scale"] = scalingFrame:GetScale()
	local p = db.profile.Groups[scalingFrame:GetID()]["Point"]
	p.point,_,p.relativePoint,p.x,p.y = scalingFrame:GetPoint(1)
	p.defined = true
end

function TMW:Group_StopMoving(self, button)
	local scalingFrame = self:GetParent()
	scalingFrame:StopMovingOrSizing()
	local p = db.profile.Groups[scalingFrame:GetID()]["Point"]
	p.point,_,p.relativePoint,p.x,p.y = scalingFrame:GetPoint(1)
	p.defined = true
end

function TMW:Group_ResetPosition(groupID)
	local group = _G["TellMeWhen_Group"..groupID]
	db.profile.Groups[groupID].Point.defined = false
	db.profile.Groups[groupID]["Scale"] = 2.0
	TMW:Group_SetPosition(group,groupID)
	TMW:Update()
end

function TMW:Group_SetPosition(group,groupID)
	local p = db.profile.Groups[groupID].Point
	group:ClearAllPoints()
	if p.defined and p.x then
		group:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
	else
		groupID=groupID-1
		local xoffs = 50 + 135*floor(groupID/10)
		local yoffs = (floor(groupID/10)*-10)+groupID
		group:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", xoffs, (-50 - (30*yoffs)))
	end
end

function TMW:Group_OnDelete(groupID)
	tremove(db.profile.Groups,groupID)				
	local t = TELLMEWHEN_WARNINGSTRING .. "|cff7fffff" .. L["CONDITIONORMETA_INVALIDATED"] .. "\r\n"
	local warntext = t
	for gID in pairs(db.profile.Groups) do
		for iID in pairs(db.profile.Groups[gID].Icons) do
			if db.profile.Groups[gID].Icons[iID].Conditions then
				for k,v in pairs(db.profile.Groups[gID].Icons[iID].Conditions) do
					if v.Icon ~= "" then
						local g = tonumber(strmatch(v.Icon, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							db.profile.Groups[gID].Icons[iID].Conditions[k].Icon = gsub(v.Icon,"_Group"..g,"_Group"..g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[gID].Name,gID,1),iID) .. ", " 
						end
					end
				end
			end
			if db.profile.Groups[gID].Icons[iID].Type == "meta" then
				for k,v in pairs(db.profile.Groups[gID].Icons[iID].Icons) do
					if v ~= "" then
						local g =  tonumber(strmatch(v, "TellMeWhen_Group(%d+)_Icon"))
						if g > groupID then
							db.profile.Groups[gID].Icons[iID].Icons[k] = gsub(v,"_Group"..g,"_Group"..g-1)
						elseif g == groupID then
							warntext = warntext .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[gID].Name,gID,1),iID) .. ", " 
						end
					end
				end
			end
		end
	end
	if warntext ~= t then
		DEFAULT_CHAT_FRAME:AddMessage(warntext)
	end
	db.profile.NumGroups = db.profile.NumGroups - 1
	for k,v in pairs(TMW.Icons) do
		if tonumber(strmatch(v, "TellMeWhen_Group(%d+)_Icon")) == groupID then
			tremove(TMW.Icons,k)
		end
	end
	sort(TMW.Icons,function(a,b) return TMW:GetGlobalIconID(strmatch(a, "TellMeWhen_Group(%d+)_Icon(%d+)")) < TMW:GetGlobalIconID(strmatch(b, "TellMeWhen_Group(%d+)_Icon(%d+)")) end)
	TMW:Update()
	TMW:CompileOptions()
	CloseDropDownMenus()
end


-- -----------------------
-- CONDITION EDITOR DIALOG
-- -----------------------

TMW.CondtMenu_Types = {
	{ -- health
		text = HEALTH,
		value = "HEALTH",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_alchemy_elixir_05",
	}, { -- primary resource
		text = L["CONDITIONPANEL_POWER"],
		tooltip = L["CONDITIONPANEL_POWER_DESC"],
		value = "DEFAULT",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_alchemy_elixir_02",
	}, { -- mana
		text = MANA,
		value = "MANA",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_potion_126",
	}, { -- energy
		text = ENERGY,
		value = "ENERGY",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_potion_125",
	}, { -- rage
		text = RAGE,
		value = "RAGE",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_potion_120",
	}, { -- focus
		text = FOCUS,
		value = "FOCUS",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_potion_124",
	}, { -- runic power
		text = RUNIC_POWER,
		value = "RUNIC_POWER",
		percent = true,
		min = 0,
		max = 100,
		icon = "Interface/Icons/inv_potion_128",
	}, { -- combo
		text = L["CONDITIONPANEL_COMBO"],
		value = "COMBO",
		percent = false,
		min = 0,
		max = 5,
		icon = "Interface/Icons/ability_rogue_eviscerate",
	}, { -- exists
		text = L["CONDITIONPANEL_EXISTS"],
		tooltip = L["CONDITIONPANEL_EXISTS_DESC"],
		value = "EXISTS",
		percent = false,
		min = 0,
		max = 1,
		bool = true,
		nooperator = true,
		icon = "Interface/Icons/ABILITY_SEAL",
	}, { -- alive
		text = L["CONDITIONPANEL_ALIVE"],
		tooltip = L["CONDITIONPANEL_ALIVE_DESC"],
		value = "ALIVE",
		percent = false,
		min = 0,
		max = 1,
		bool = true,
		nooperator = true,
		icon = "Interface/Icons/Ability_Vanish",
	}, { -- combat
		text = L["CONDITIONPANEL_COMBAT"],
		value = "COMBAT",
		percent = false,
		min = 0,
		max = 1,
		bool = true,
		nooperator = true,
		icon = "Interface/CharacterFrame/UI-StateIcon",
		tcoords = {0.53, 0.92,0.05,0.42},
	}, { -- pvp
		text = L["CONDITIONPANEL_PVPFLAG"],
		value = "PVPFLAG",
		percent = false,
		min = 0,
		max = 1,
		bool = true,
		nooperator = true,
		icon = "Interface/TargetingFrame/UI-PVP-"..UnitFactionGroup("player"),
		tcoords = {0.046875,0.609375,0.015625,0.59375},
	}, { -- react
		text = L["ICONMENU_REACT"],
		value = "REACT",
		percent = false,
		min = 1,
		max = 2,
		mint = L["ICONMENU_HOSTILE"],
		maxt = L["ICONMENU_FRIEND"],
		nooperator = true,
		icon = "Interface/Icons/Warrior_talent_icon_FuryInTheBlood",
	}, { -- talent spec
		text = L["UIPANEL_SPEC"],
		value = "SPEC",
		percent = false,
		min = 1,
		max = 2,
		mint = L["UIPANEL_PRIMARYSPEC"],
		maxt = L["UIPANEL_SECONDARYSPEC"],
		nooperator = true,
		unit = PLAYER,
		icon = "Interface/Icons/Ability_Marksmanship"
	},{ -- icon shown
		text = L["CONDITIONPANEL_ICON"],
		tooltip = L["CONDITIONPANEL_ICON_DESC"],
		value = "ICON",
		percent = false,
		min = 0,
		max = 1,
		bool = true,
		isicon = true,
		nooperator = true,
		icon = "Interface/Icons/INV_Misc_PocketWatch_01"
	},
}

TMW.CondtMenu_Operators={
	{ text=L["CONDITIONPANEL_EQUALS"], 		value="==" 	},
	{ text=L["CONDITIONPANEL_NOTEQUAL"], 	value="~=" 	},
	{ text=L["CONDITIONPANEL_LESS"], 		value="<" 	},
	{ text=L["CONDITIONPANEL_LESSEQUAL"], 	value="<=" 	},
	{ text=L["CONDITIONPANEL_GREATER"], 	value=">" 	},
	{ text=L["CONDITIONPANEL_GREATEREQUAL"],value=">=" 	},
}

TMW.CondtMenu_AndOrs={
	{ text=L["CONDITIONPANEL_AND"], value="AND" },
	{ text=L["CONDITIONPANEL_OR"], 	value="OR" 	},
}

if pclass == "WARLOCK" then
	tinsert(TMW.CondtMenu_Types,8,{
		text = SOUL_SHARDS,
		value = "SOUL_SHARDS",
		percent = false, 
		min = 0, 
		max = 3,
		unit = PLAYER,
		icon = "Interface/Icons/inv_misc_gem_amethyst_02"
	})
elseif pclass == "DRUID" then
	tinsert(TMW.CondtMenu_Types,8,{
		text = ECLIPSE,
		tooltip = L["CONDITIONPANEL_ECLIPSE_DESC"],
		value = "ECLIPSE",
		percent = false,
		min = -100,
		max = 100,
		mint = "-100 ("..L["MOON"].. ")",
		maxt = "-100 ("..L["SUN"].. ")",
		unit = PLAYER,
		icon = "Interface/PlayerFrame/UI-DruidEclipse",
		tcoords = {0.65625000, 0.74609375, 0.37500000, 0.55468750},
	})
	tinsert(TMW.CondtMenu_Types,8,{
		text = L["ECLIPSE_DIRECTION"],
		value = "ECLIPSE_DIRECTION",
		percent = false,
		min = 0,
		max = 1,
		mint = L["MOON"],
		maxt = L["SUN"],
		unit = PLAYER,
		nooperator = true,
		icon = "Interface/PlayerFrame/UI-DruidEclipse",
		tcoords = {0.55859375, 0.64843750, 0.57031250, 0.75000000},
	})
elseif pclass == "HUNTER" then
	tinsert(TMW.CondtMenu_Types,8,{
		text = HAPPINESS, value = "HAPPINESS",
		percent = false,
		min = 1,
		max = 3,
		mint = PET_HAPPINESS1,
		maxt = PET_HAPPINESS3,
		unit = PET,
		icon = "Interface/PetPaperDollFrame/UI-PetHappiness",
		tcoords = {0.375 , 0.5625, 0, 0.359375},
	})
elseif pclass == "PALADIN" then
	tinsert(TMW.CondtMenu_Types,8,{
		text = HOLY_POWER,
		value = "HOLY_POWER",
		percent = false,
		min = 0,
		max = 3,
		unit = PLAYER,
		icon = "Interface/Icons/Spell_Holy_Rune",
	})
end

CNDT = TMW:NewModule("Conditions")

function CNDT:TypeMenuOnClick(frame,i)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
	local num = frame:GetParent():GetID()
	local group = _G["TellMeWhen_ConditionEditorGroup" .. num]
	local showval = CNDT:Typecheck(num,TMW.CondtMenu_Types[i].unit,TMW.CondtMenu_Types[i].isicon, TMW.CondtMenu_Types[i].nooperator, TMW.CondtMenu_Types[i].noslide)
	CNDT:SetSliderMinMax(group.Slider)
	if showval then
		CNDT:SetValText(group.Slider)
	else
		group.ValText:SetText("")
	end

end

function CNDT:TypeMenu_DropDown()
	for k,v in pairs(TMW.CondtMenu_Types) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.TypeMenuOnClick
		info.text = v.text
		info.tooltipTitle = v.text
		info.tooltipText = v.tooltip
		info.tooltipOnButton = true
		info.value = v.value
		info.arg1 = self
		info.arg2 = k
		info.icon = v.icon
		if v.tcoords then
			info.tCoordLeft = v.tcoords[1]
			info.tCoordRight = v.tcoords[2]
			info.tCoordTop = v.tcoords[3]
			info.tCoordBottom = v.tcoords[4]
		end
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function CNDT:UnitMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end

function CNDT:UnitMenu_DropDown()
	for k,v in pairs(TMW.IconMenu_SubMenus.Unit) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.UnitMenuOnClick
		info.text = v.text
		info.value = v.value
		info.hasArrow = v.hasArrow
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function CNDT:IconMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end

function CNDT:IconMenu_DropDown()
	for k,v in pairs(TMW.Icons) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.IconMenuOnClick
		local g,i = strmatch(v, "TellMeWhen_Group(%d+)_Icon(%d+)")
		g,i = tonumber(g),tonumber(i)
		local text,textshort = TMW:GetIconMenuText(g,i)
		info.text = textshort
		info.value = v
		info.tooltipTitle = text
		info.tooltipText = format(L["GROUPICON"], TMW:GetGroupName(db.profile.Groups[g].Name,g,1),i)
		info.tooltipOnButton = true
		info.arg1 = self
		info.icon = _G["TellMeWhen_Group"..g.."_Icon"..i].texture:GetTexture()
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function CNDT:OperatorMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end

function CNDT:OperatorMenu_DropDown()
	for k,v in pairs(TMW.CondtMenu_Operators) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.OperatorMenuOnClick
		info.text = v.text
		info.value = v.value
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "LEFT")
end

function CNDT:AndOrMenuOnClick(frame)
	UIDropDownMenu_SetSelectedValue(frame, self.value)
end

function CNDT:AndOrMenu_DropDown()
	for k,v in pairs(TMW.CondtMenu_AndOrs) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = CNDT.AndOrMenuOnClick
		info.text = v.text
		info.value = v.value
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_JustifyText(self, "CENTER")
end


function CNDT:CheckboxHandler()
	local i=1
	while _G["TellMeWhen_ConditionEditorGroup" .. i] do
		if _G["TellMeWhen_ConditionEditorGroup" .. i+1] then
			if (_G["TellMeWhen_ConditionEditorGroup" .. i .. "Check"]:GetChecked()) then
				_G["TellMeWhen_ConditionEditorGroup" .. i]:Show()
				_G["TellMeWhen_ConditionEditorGroup" .. i+1 .. "Check"]:Show()
			else
				_G["TellMeWhen_ConditionEditorGroup" .. i]:Hide()
				_G["TellMeWhen_ConditionEditorGroup" .. i+1 .. "Check"]:Hide()
				_G["TellMeWhen_ConditionEditorGroup" .. i+1 .. "Check"]:SetChecked(false)
			end
		else -- this handles the last one in the frame
			if (_G["TellMeWhen_ConditionEditorGroup" .. i .. "Check"]:GetChecked()) then
				_G["TellMeWhen_ConditionEditorGroup" .. i]:Show()
				CNDT:CreateGroups(i+1)
			else
				_G["TellMeWhen_ConditionEditorGroup" .. i]:Hide()
			end
		end
		i=i+1
	end
end

function CNDT:CondtOk(i,conditionstemp)
	local group = _G["TellMeWhen_ConditionEditorGroup" .. i]
	if (group.Check:GetChecked()) then
		local condition = {
			Type		= "HEALTH",
			Unit		= "player",
			Operator	= "==",
			Level		= 0,
			Icon		= "",
			AndOr		= "AND",
		}
		condition.Type = UIDropDownMenu_GetSelectedValue(group.Type) or "HEALTH"
		condition.Unit = UIDropDownMenu_GetSelectedValue(group.Unit) or "player"
		condition.Operator = UIDropDownMenu_GetSelectedValue(group.Operator) or "=="
		condition.Icon = UIDropDownMenu_GetSelectedValue(group.Icon) or ""
		condition.Level = tonumber(group.Slider:GetValue()) or 0
		condition.AndOr = UIDropDownMenu_GetSelectedValue(group.AndOr) or "AND"

		tinsert(conditionstemp, condition)
		i=i+1
		if (i <= TELLMEWHEN_MAXCONDITIONS) and (group.Check:GetChecked()) then
			return CNDT:CondtOk(i,conditionstemp)
		else
			return conditionstemp or {}
		end
	else
		return conditionstemp or {}
	end
end

function CNDT:EditorOkayOnClick()
	local groupID = TMW.CCnI.g
	local iconID = TMW.CCnI.i
	conditionstemp = {}
	local conditions = CNDT:CondtOk(1,conditionstemp)
	db.profile.Groups[groupID].Icons[iconID]["Conditions"] = conditions
	TMW:Icon_Update(groupID, iconID)
end

function CNDT:LoadCondt(i,conditions)
	local group = _G["TellMeWhen_ConditionEditorGroup" .. i]
	if (#conditions >= i) then
		CNDT:SetUIDropdownText(group.Type, conditions[i].Type, TMW.CondtMenu_Types)
		CNDT:SetUIDropdownText(group.Unit, conditions[i].Unit, TMW.IconMenu_SubMenus.Unit)
		CNDT:SetUIDropdownText(group.Icon, conditions[i].Icon, TMW.Icons)
		CNDT:SetUIDropdownText(group.Operator, conditions[i].Operator, TMW.CondtMenu_Operators)
		group.Slider:SetValue(conditions[i].Level or 0)
		CNDT:SetValText(group.Slider)
		group.Check:SetChecked(true)
		if i > 1 then
			CNDT:SetUIDropdownText(group.AndOr, conditions[i].AndOr, TMW.CondtMenu_AndOrs)
		end
	end
	i=i+1
	if (#conditions >= i) and (i <= TELLMEWHEN_MAXCONDITIONS) then
		CNDT:LoadCondt(i,conditions)
	end
end

function CNDT:LoadDialog()
	CNDT:ClearDialog()
	local groupID = TMW.CCnI.g
	local iconID = TMW.CCnI.i
	local conditions = db.profile.Groups[groupID].Icons[iconID].Conditions
	CNDT:CreateGroups(#conditions)
	TMW.CurrConditions = conditions
	CNDT:LoadCondt(1,conditions)
	TellMeWhen_ConditionEditorFrameFS1:SetText(L["CONDITIONPANEL_TITLE"] .. ": " .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[groupID].Name,groupID,1),iconID))
	CNDT:CheckboxHandler()
	TellMeWhen_ConditionEditorFrame:Show()
	TellMeWhen_ConditionEditorFrame:SetFrameLevel(100)
end

function CNDT:ClearDialog()
	TellMeWhen_ConditionEditorScrollFrameScrollBar:Hide()
	for i=1,TELLMEWHEN_MAXCONDITIONS do
		local group = _G["TellMeWhen_ConditionEditorGroup" .. i]
		UIDropDownMenu_SetSelectedValue(group.Type, "HEALTH")
		UIDropDownMenu_SetSelectedValue(group.Unit, "player")
		UIDropDownMenu_SetSelectedValue(group.Icon, "")
		UIDropDownMenu_SetSelectedValue(group.Operator, "==")
		UIDropDownMenu_SetText(group.Type, "")
		UIDropDownMenu_SetText(group.Unit, "")
		UIDropDownMenu_SetText(group.Operator, "")
		group.Slider:SetValue(0)
		group.Check:SetChecked(false)
		group.Unit:Show()
		group.Operator:Show()
		group.Icon:Hide()
		CNDT:SetSliderMinMax(group.Slider)
		CNDT:SetValText(group.Slider)
	end
	for i=2,TELLMEWHEN_MAXCONDITIONS do
		local group = _G["TellMeWhen_ConditionEditorGroup" .. i]
		UIDropDownMenu_SetSelectedValue(group.AndOr, "AND")
		UIDropDownMenu_SetText(group.AndOr, "")
	end
	local groupID = TMW.CCnI.g
	local iconID = TMW.CCnI.i
	local conditions = db.profile.Groups[groupID].Icons[iconID].Conditions
	TellMeWhen_ConditionEditorFrameFS1:SetText(L["CONDITIONPANEL_TITLE"] .. ": " .. format(L["GROUPICON"],TMW:GetGroupName(db.profile.Groups[groupID].Name,groupID,1),iconID))
	TellMeWhen_ConditionEditorFrameIconTexture:SetTexture(_G["TellMeWhen_Group" .. groupID .. "_Icon" .. iconID].texture:GetTexture())
	CNDT:CheckboxHandler()
	TellMeWhen_ConditionEditorFrame:Show()
	TellMeWhen_ConditionEditorFrame:SetFrameLevel(100)
	CNDT:SetText()
end


function CNDT:CreateGroups(num)
	while _G["TellMeWhen_ConditionEditorGroup"..TELLMEWHEN_MAXCONDITIONS] do
		TELLMEWHEN_MAXCONDITIONS=TELLMEWHEN_MAXCONDITIONS+1
	end
	for i=TELLMEWHEN_MAXCONDITIONS,num do
		local condtgrp = _G["TellMeWhen_ConditionEditorGroup"..i] or CreateFrame("Frame","TellMeWhen_ConditionEditorGroup"..i,TellMeWhen_ConditionEditorGroups,"TellMeWhen_ConditionEditorGroup",i)
		condtgrp:SetPoint("TOPLEFT",_G["TellMeWhen_ConditionEditorGroup"..i-1],"BOTTOMLEFT",0,0)
		condtgrp.Check:ClearAllPoints()
		condtgrp.Check:SetPoint("TOPLEFT",_G["TellMeWhen_ConditionEditorGroup"..i],17,10)
	end
	TELLMEWHEN_MAXCONDITIONS = num
	CNDT:SetText()
end

function CNDT:SetUIDropdownText(frame, value, tab)
	UIDropDownMenu_SetSelectedValue(frame, value)
	local num = frame:GetParent():GetID()
	CNDT:SetSliderMinMax(_G["TellMeWhen_ConditionEditorGroup" .. num .. "Slider"])
	if tab == TMW.CondtMenu_Types then
		for k,v in pairs(tab) do
			if (v.value == value) then
				CNDT:Typecheck(num,v.unit, v.isicon, v.nooperator, v.noslide)
			end
		end
	end
	if tab == TMW.Icons then
		for k,v in pairs(tab) do
			if (v == value) then
				UIDropDownMenu_SetText(frame, _G[v].Name)
				return
			end
		end
	end
	for k,v in pairs(tab) do
		if (v.value == value) then
			UIDropDownMenu_SetText(frame, v.text)
			return
		end
	end
	UIDropDownMenu_SetText(frame, "")
end

function CNDT:SetText(num)
	TellMeWhen_ConditionEditorFrameCancelButton:SetText(CANCEL)
	TellMeWhen_ConditionEditorFrameOkayButton:SetText(OKAY)
	for i=1,TELLMEWHEN_MAXCONDITIONS do
		if num then i=num end
		local group = _G["TellMeWhen_ConditionEditorGroup" .. i]
		if not (group and group.TextType) then return end
		group.TextType:SetText(L["CONDITIONPANEL_TYPE"])
		group.TextUnitOrIcon:SetText(L["CONDITIONPANEL_UNIT"])
		group.TextUnitDef:SetText("")
		group.TextOperator:SetText(L["CONDITIONPANEL_OPERATOR"])
		group.AndOrTxt:SetText(L["CONDITIONPANEL_ANDOR"])
		group.TextValue:SetText(L["CONDITIONPANEL_VALUEN"])
		if num then break end
	end
end

function CNDT:SetValText(self)
	if TMW.Initd then
		local val = self:GetValue()
		local type = UIDropDownMenu_GetSelectedValue(_G[self:GetParent():GetName() .. "Type"])
		if type == "ECLIPSE_DIRECTION" then
			if val == 0 then val = L["MOON"] end
			if val == 1 then val = L["SUN"] end
		end
		if type == "HAPPINESS" then
			val = _G["PET_HAPPINESS" .. val]
		end
		if type == "REACT" then
			if val == 1 then val = L["ICONMENU_HOSTILE"] end
			if val == 2 then val = L["ICONMENU_FRIEND"] end
		end
		for k,v in pairs(TMW.CondtMenu_Types) do
			if (v.value == type) and (v.bool) then
				if val == 0 then val = L["TRUE"] end
				if val == 1 then val = L["FALSE"] end
			end
		end
		for k,v in pairs(TMW.CondtMenu_Types) do
			if (v.value == type) and (v.percent) then
				val = val .. "%"
			end
		end
		if _G[self:GetParent():GetName() .. "ValText"] then
			_G[self:GetParent():GetName() .. "ValText"]:SetText(val)
		end
	end
end

function CNDT:SetSliderMinMax(self)
	local type = UIDropDownMenu_GetSelectedValue(_G[self:GetParent():GetName() .. "Type"])
	for k,v in pairs(TMW.CondtMenu_Types) do
		if (v.value == type) then
			self:SetMinMaxValues(v.min,v.max)
			if v.bool then
				_G[self:GetName() .. "Low"]:SetText(L["TRUE"])
				_G[self:GetName() .. "High"]:SetText(L["FALSE"])
				break
			end
			_G[self:GetName() .. "Low"]:SetText(v.mint or v.min)
			_G[self:GetName() .. "Mid"]:SetText(v.midt or "")
			_G[self:GetName() .. "High"]:SetText(v.maxt or v.max)
			break
		end
	end
end

function CNDT:Typecheck(num,unit,isicon,nooperator,noslide)
	local group = _G["TellMeWhen_ConditionEditorGroup" .. num]
	group.Icon:Hide() --it bugs sometimes so just do it by default
	local showval = true
	CNDT:SetText(num)
	group.Unit:Show()
	if unit then
		group.Unit:Hide()
		group.TextUnitDef:SetText(unit)
	end
	if nooperator then
		group.TextOperator:SetText("")
		group.Operator:Hide()
	else
		group.Operator:Show()
	end
	if noslide then
		showval = false
		group.Slider:Hide()
		group.TextValue:SetText("")
		group.ValText:Hide()
	else
		group.ValText:Show()
		group.Slider:Show()
	end
	if isicon then
		group.TextUnitOrIcon:SetText(L["ICONTOCHECK"])
		group.Icon:Show()
		group.Unit:Hide()
	else
		group.Icon:Hide()
	end
	return showval
end

