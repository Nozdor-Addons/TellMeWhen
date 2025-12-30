-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock 
-- Cybeloras of Mal'Ganis
-- --------------------


local L = LibStub("AceLocale-3.0"):GetLocale("TellMeWhen", true)
if not TMW then return end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("TellMeWhen") or
	ldb:NewDataObject("TellMeWhen", {
		type = "launcher",
		icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	})

dataobj.OnClick = function(self, button)
	if button == "RightButton" then
		TMW.DoInitializeOptions = true
		TMW:CompileOptions()
		InterfaceOptionsFrame_OpenToCategory(L["ICON_TOOLTIP1"])
	else
		TMW:LockToggle()
	end
end

dataobj.OnTooltipShow = function(tt)
	tt:AddLine(L["ICON_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP1"])
	tt:AddLine(L["LDB_TOOLTIP2"])
end