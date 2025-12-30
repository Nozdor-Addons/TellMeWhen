
local L = LibStub("AceLocale-3.0"):NewLocale("TellMeWhen", "enUS", true)

L["CMD_OPTIONS"] = "Options" 
L["ICON_TOOLTIP1"] = "TellMeWhen"
L["ICON_TOOLTIP2"] = "Right click for icon options. More options are in the Blizzard interface options menu. Type /tmw to lock and enable addon."
L["LDB_TOOLTIP1"] = "|cff7fffffLeft-click|r to toggle the group locks"
L["LDB_TOOLTIP2"] = "|cff7fffffRight-click|r to show the main TMW options"

L["RESIZE"] = "Resize"
L["RESIZE_TOOLTIP"] = "Click and drag to change size"

L["HPSSWARN"] = "Warning! Any icon conditions that you had set that checked for holy power or soul shards may be messed up! Check them to prevent later confusion!"
L["ERRSPAMWARN"] = " disabled to prevent massive error spam. Type /tmw and change the name of the icon to a spellID to fix this."
L["CONDITIONORMETA_INVALIDATED"] = "Warning! The following icons were checking icons in the group that you just deleted. You may wish to modify their settings to restore functionality."
L["CONDITIONORMETA_CHECKINGINVALID"] = "Warning! Group %d, Icon %d is checking an invalid icon (Group %d, Icon %d)"

-- -------------
-- ICONMENU
-- -------------

L["ICONMENU_CHOOSENAME"] = "Choose name/ID"
L["ICONMENU_ENABLE"] = "Enable icon"
L["CHOOSENAME_EQUIVS_TOOLTIP"] = "You can select a predefined set of buffs/debuffs, spell casts, or dispel types (Magic, Curse, etc.) from this menu to insert into the editbox."
L["CHOOSENAME_DIALOG_DDDEFAULT"] = "Predefined Spell Sets/Dispel Types"
L["CHOOSENAME_DIALOG"] = "Enter the Name or ID of what you want this icon to monitor. You can add multiple items (but not cooldowns/reactives) by seperating them with ';'.  PET ABILITIES must use SpellIDs."
L["CHOOSENAME_DIALOG_ICD"] = "ICD/duration"
L["CHOOSENAME_DIALOG_ICD_DESC"] = "All times are in seconds. This only applies to the internal cooldown/spell duration icon type. You can safely ignore it otherwise."

L["ICONMENU_ALPHA"] = "Alpha"
L["ICONMENU_TYPE"] = "Icon type"
L["ICONMENU_COOLDOWN"] = "Cooldown"
L["ICONMENU_BUFFDEBUFF"] = "Buff/Debuff"
L["ICONMENU_REACTIVE"] = "Reactive ability"
L["ICONMENU_WPNENCHANT"] = "Temporary weapon enchant"
L["ICONMENU_TOTEM"] = "Totem/non-MoG Ghoul"
L["ICONMENU_TOTEM_DESC"] = "The name entered should be 'Risen Ghoul' (for English clients) in order to track a non-Master of Ghouls ghoul."
L["ICONMENU_MULTISTATECD"] = "Multi-state Cooldown"
L["ICONMENU_MULTISTATECD_DESC"] = [=[This icon should be used when you want to track multiple states/textures/etc of a cooldown.
Some examples are: Holy Word: Chastise, Dark Simulacrum, Stealth, and aspects/auras/shapeshifts/stealths.
IMPORTANT: The action being tracked MUST be on your action bars for this icon type to work.
You should also make sure that the ability is in its default state before leaving config mode.]=]
L["ICONMENU_ICD"] = "Internal cooldown/Spell duration"
L["ICONMENU_ICD_DESC"] = [=[This icon type can be used to track either the internal cooldown of something such as a proc from a talent or a trinket,
or to track the duration of a spell (e.g. traps, mage orb), or even the duration of a summon (e.g. Infernal).
Enter the spellID (or name, but not reccomended, capitalization counts) of the buff/debuff that is placed when the cooldown starts,
or the name of the spell that you would like to track the duration of. Semicolon-delimited lists are valid.
The duration is customized in the choose name/ID dialog.]=]
L["ICONMENU_CAST"] = "Casting"
L["ICONMENU_CAST_DESC"] = [=[The name dialog can be left blank to show the icon for any cast, or in order to only shown the icon for certain spells,
you can enter a single spell, or a semicolon-delimited list of spells.]=]
L["ICONMENU_META"] = "Meta Icon"
L["ICONMENU_META_DESC"] = [=[This icon type can be used to combine several icons into one.
Icons that have fake hidden enabled will still be shown if they would otherwise be shown.]=]
L["ICONMENU_OPTIONS"] = "More options"


L["ICONMENU_COOLDOWNTYPE"] = "Cooldown type"
L["ICONMENU_SPELL"] = "Spell or ability"
L["ICONMENU_ITEM"] = "Item"

L["ICONMENU_SHOWWHEN"] = "Show icon when"
L["ICONMENU_USABLE"] = "Usable"
L["ICONMENU_UNUSABLE"] = "Unusable"

L["ICONMENU_BUFFTYPE"] = "Buff or debuff"
L["ICONMENU_BUFF"] = "Buff"
L["ICONMENU_DEBUFF"] = "Debuff"
L["ICONMENU_BOTH"] = "Either"

L["ICONMENU_DISPEL"] = "Dispel Type"
L["ICONMENU_CASTS"] = "Spell Casts"

L["ICONMENU_UNIT"] = "Unit to watch"
L["ICONMENU_TARGETTARGET"] = "Target's target"
L["ICONMENU_FOCUSTARGET"] = "Focus' target"
L["ICONMENU_PETTARGET"] = "Pet's target"
L["ICONMENU_MOUSEOVER"] = "Mouseover"
L["ICONMENU_MOUSEOVERTARGET"] = "Mouseover's target"
L["ICONMENU_VEHICLE"] = "Vehicle"

L["ICONMENU_PRESENT"] = "Present"
L["ICONMENU_ABSENT"] = "Absent"
L["ICONMENU_ALWAYS"] = "Always"

L["ICONMENU_CASTSHOWWHEN"] = "Show when a cast is"
L["ICONMENU_ONLYINTERRUPTIBLE"] = "Only Interruptible"

L["ICONMENU_ICONS"] = "Edit Icons"

L["ICONMENU_ONLYMINE"] = "Only show if cast by self"
L["ICONMENU_SHOWTIMER"] = "Show timer"
L["ICONMENU_SHOWTIMERTEXT"] = "Show timer number"
L["ICONMENU_SHOWTIMERTEXT_DESC"] = "This is only applicable if 'Show timer' is checked and OmniCC (or similar) is installed."

L["ICONMENU_BARS"] = "Bars"
L["ICONMENU_SHOWPBAR"] = "Show power bar"
L["ICONMENU_SHOWCBAR"] = "Show cooldown/timer bar"
L["ICONMENU_INVERTBARS"] = "Fill bars up"
L["ICONMENU_DURATIONANDCD"] = "Duration > CD"

L["ICONMENU_REACT"] = "Unit Reaction"
L["ICONMENU_FRIEND"] = "Friendly"
L["ICONMENU_HOSTILE"] = "Hostile"
L["ICONMENU_EITHER"] = "Any"

L["ICONMENU_ICDTYPE"] = "Triggered by"
L["ICONMENU_SPELLCAST"] = "Spell Cast"
L["ICONMENU_SPELLCAST_DESC"] = "Select this option if the internal cooldown begins when you cast the spell that you chose"
L["ICONMENU_ICDAURA_DESC"] = "Select this option if the internal cooldown begins when you apply the buff or debuff that you chose"
L["ICONMENU_ICDUSABLE"] = "Usable cooldown/Expired spell"
L["ICONMENU_ICDUNUSABLE"] = "Unusable cooldown/Present spell"


L["ICONMENU_RANGECHECK"] = "Range check"
L["ICONMENU_MANACHECK"] = "Power check"
L["ICONMENU_COOLDOWNCHECK"] = "Cooldown check"
L["ICONMENU_IGNORERUNES"] = "Ignore Runes"
L["ICONMENU_IGNORERUNES_DESC"] = "Check this to treat the ability as usable if the only thing hindering it is a rune cooldown."
L["ICONMENU_RANGECHECK_DESC"] = "Check this to enable changing the color of the icon when you are out of range"
L["ICONMENU_MANACHECK_DESC"] = "Check this to enable changing the color of the icon when you are out of mana/rage/runic power/etc"
L["ICONMENU_COOLDOWNCHECK_DESC"] = "Check this to enable changing the color of the icon when the reactive ability is on cooldown"

L["EDITORPANEL_TITLE"] = "TellMeWhen Icon Editor"
L["ICONMENU_EDIT"] = "Edit"

L["STACKSPANEL_TITLE"] = "Stacks"
L["ICONMENU_STACKS_MIN_DESC"] = "Minimum number of stacks of the aura needed to show the icon"
L["ICONMENU_STACKS_MAX_DESC"] = "Maximum number of stacks of the aura allowed to show the icon"

L["DURATIONPANEL_TITLE"] = "Duration"
L["ICONMENU_DURATION_MIN_DESC"] = "Minimum duration needed to show the icon"
L["ICONMENU_DURATION_MAX_DESC"] = "Maximum duration allowed to show the icon"

L["METAPANEL_TITLE"] = "Meta Icon Editor"

L["ALPHAPANEL_TITLE"] = "Alpha"
L["ICONMENU_SETALPHA"] = "Set Alpha Levels"
L["ICONMENU_SETALPHAMOD"] = "Set Alpha Levels |cFFFF5959(Modified)|r"
L["ICONALPHAPANEL_ALPHA"] = "Usable/Present"
L["ICONALPHAPANEL_ALPHA_DESC"] = "Slide to set the alpha level for the icon when the ability is usable/present"
L["ICONALPHAPANEL_UNALPHA"] = "Unusable/Absent"
L["ICONALPHAPANEL_UNALPHA_DESC"] = "Slide to set the alpha level for the icon when ability is unusable/absent"

L["ICONALPHAPANEL_DURATIONALPHA"] = "Incorrect Duration"
L["ICONALPHAPANEL_DURATIONALPHA_DESC"] = "Slide to set the alpha level for the icon when its duration requirements fail."
L["ICONALPHAPANEL_STACKALPHA"] = "Incorrect Stacks"
L["ICONALPHAPANEL_STACKALPHA_DESC"] = "Slide to set the alpha level for the icon when its stack requirements fail."

L["ICONALPHAPANEL_CNDTALPHA"] = "Failed Condition"
L["ICONALPHAPANEL_CNDTALPHA_DESC"] = "Slide to set the alpha level for the icon when its conditions fail."
L["ICONALPHAPANEL_FAKEHIDDEN"] = "Fake Hidden"
L["ICONALPHAPANEL_FAKEHIDDEN_DESC"] = [[Causes the icon to be hidden all the time, but still enabled in order to allow the conditions of other icons to check this icon, or for meta icons to include this icon.

IMPORTANT: Alpha sliders need to be set to 0 in order for this icon to be considered hidden by 'icon shown' conditions when the alpha level controlled by each slider would normally be used.]]

L["ICONMENU_WPNENCHANTTYPE"] = "Weapon slot to monitor"
L["ICONMENU_HIDEUNEQUIPPED"] = "Hide when slot is empty"

L["ICONMENU_CLEAR"] = "Clear Icon"


-- -------------
-- UI PANEL
-- -------------

L["UIPANEL_SUBTEXT1"] = "These options allow you to change the number, arrangement, and behavior of reminder icons."
L["UIPANEL_SUBTEXT2"] = "Icons work when locked. When unlocked, you can move/size icon groups and right click individual icons for more settings. You can also type /tellmewhen or /tmw to lock/unlock."
L["UIPANEL_ICONGROUP"] = "Icon group "
L["UIPANEL_MAINOPT"] = "Main Options"
L["UIPANEL_GROUPS"] = "Groups"
L["UIPANEL_COLORS"] = "Colors"
L["UIPANEL_ENABLEGROUP"] = "Enable Group"
L["UIPANEL_GROUPNAME"] = "Rename Group"
L["UIPANEL_ROWS"] = "Rows"
L["UIPANEL_COLUMNS"] = "Columns"
L["UIPANEL_ONLYINCOMBAT"] = "Only show in combat"
L["UIPANEL_NOTINVEHICLE"] = "Hide in Vehicle"
L["UIPANEL_SPEC"] = "Talent Spec"
L["UIPANEL_PRIMARYSPEC"] = "Primary Spec"
L["UIPANEL_SECONDARYSPEC"] = "Secondary Spec"
L["UIPANEL_GROUPRESET"] = "Reset Position"
L["UIPANEL_TOOLTIP_GROUPRESET"] = "Reset this group's position and scale"
L["UIPANEL_ALLRESET"] = "Reset all"
L["UIPANEL_TOOLTIP_ALLRESET"] = "Reset DATA and POSITION of all icons and groups, as well as any other settings."
L["UIPANEL_LOCKUNLOCK"] = "Lock/Unlock AddOn"
L["UIPANEL_BARTEXTURE"] = "Bar Texture"
L["UIPANEL_NOCOUNT"] = "Toggle Timer Text"
L["UIPANEL_NOCOUNT_DESC"] = "Enables/disables the text that displays the cooldown on the icon. It will only be shown if the icon's timer is enabled, this option is enabled, and OMNICC IS INSTALLED"
L["UIPANEL_BARIGNOREGCD"] = "Bars Ignore GCD"
L["UIPANEL_BARIGNOREGCD_DESC"] = "If checked, cooldown bars will not change values if the cooldown triggered is a global cooldown"
L["UIPANEL_CLOCKIGNOREGCD"] = "Timers Ignore GCD"
L["UIPANEL_CLOCKIGNOREGCD_DESC"] = "If checked, timers and the cooldown clock will not trigger from a global cooldown"
L["UIPANEL_UPDATEINTERVAL"] = "Update Interval"
L["UIPANEL_TOOLTIP_UPDATEINTERVAL"] = "Sets how often (in seconds) icons are checked for show/hide, alpha, conditions, etc. Zero is as fast as possible. Lower values can have a significant impact on framerate for low-end computers"
L["UIPANEL_ICONSPACING"] = "Icon Spacing"
L["UIPANEL_ICONSPACING_DESC"] = "Distance that icons within a group are away from eachother"
L["UIPANEL_ADDGROUP"] = "Add Another Group"
L["UIPANEL_ADDGROUP_DESC"] = "The new group will be assigned the next available groupID"
L["UIPANEL_DELGROUP"] = "Delete this Group"
L["UIPANEL_DELGROUP_DESC"] = "Any groups after this group will have their ID shifted up one, and any icons that are checking icons in groups that will be shifted will have their settings automatically updated."

L["UIPANEL_TOOLTIP_ENABLEGROUP"] = "Show and enable this group"
L["UIPANEL_TOOLTIP_ROWS"] = "Set the number of rows in this group"
L["UIPANEL_TOOLTIP_COLUMNS"] = "Set the number of columns in this group"
L["UIPANEL_TOOLTIP_ONLYINCOMBAT"] = "Check to only show this group while in combat"
L["UIPANEL_TOOLTIP_NOTINVEHICLE"] = "Check to hide this group when you are in a vehicle and your action bars have changed to that vehicle's abilities"
L["UIPANEL_TOOLTIP_PRIMARYSPEC"] = "Check to show this group while your primary spec is active"
L["UIPANEL_TOOLTIP_SECONDARYSPEC"] = "Check to show this group while your secondary spec is active"
L["UIPANEL_COLOR"] = "Cooldown/Duration Bar Color"
L["UIPANEL_COLOR_COMPLETE"] = "CD/Duration Complete"
L["UIPANEL_COLOR_STARTED"] = "CD/Duration Begin"
L["UIPANEL_COLOR_COMPLETE_DESC"] = "Color of the cooldown/duration overlay bar when the cooldown/duration is complete"
L["UIPANEL_COLOR_STARTED_DESC"] = "Color of the cooldown/duration overlay bar when the cooldown/duration has just begun"
L["UIPANEL_DRAWEDGE"] = "Highlight timer edge"
L["UIPANEL_DRAWEDGE_DESC"] = "Highlights the edge of the cooldown timer (clock animation) to increase visibility"
L["UIPANEL_COLOR_OOR"] = "Out of range color"
L["UIPANEL_COLOR_OOR_DESC"] = "Tint and alpha of the icon when you are not in range of the target to cast the spell"
L["UIPANEL_COLOR_OOM"] = "Out of power color"
L["UIPANEL_COLOR_OOM_DESC"] = "Tint and alpha of the icon when you lack the mana/rage/energy/focus/runicpower to cast the spell"
L["UIPANEL_COLOR_DESC"] = "The following options only affect the colors of icons when they are set to show all the time"
L["UIPANEL_COLOR_PRESENT"] = "Present color"
L["UIPANEL_COLOR_PRESENT_DESC"] = "The tint of the icon when the buff/debuff/enchant/totem is present and the icon is set to always show."
L["UIPANEL_COLOR_ABSENT"] = "Absent color"
L["UIPANEL_COLOR_ABSENT_DESC"] = "The tint of the icon when the buff/debuff/enchant/totem is absent and the icon is set to always show."
L["UIPANEL_STANCE"] = "Show while in:"
L["NONE"] = "None of the below"
L["CASTERFORM"] = "Caster Form"

L["UIPANEL_FONT"] = "Stack Text"
L["UIPANEL_FONT_DESC"] = "Chose the font to be used by the stack text on icons."
L["UIPANEL_FONT_SIZE"] = "Font Size"
L["UIPANEL_FONT_SIZE_DESC"] = "Change the size of the font used for stack text on icons. If ButtonFacade is used and the set skin has a font size defined, then this value will be ignored."
L["UIPANEL_FONT_OUTLINE"] = "Font Outline"
L["UIPANEL_FONT_OUTLINE_DESC"] = "Sets the outline style for the stack text on icons."
L["OUTLINE_NO"] = "No Outline"
L["OUTLINE_THIN"] = "Thin Outline"
L["OUTLINE_THICK"] = "Thick Outline"
L["UIPANEL_FONT_OVERRIDELBF"] = "Override ButtonFacade"
L["UIPANEL_FONT_OVERRIDELBF_DESC"] = "Check this to override the position of the stack text that is defined in your ButtonFacade skin. If you do not use ButtonFacade, ignore this."
L["UIPANEL_FONT_XOFFS"] = "X Offset"
L["UIPANEL_FONT_YOFFS"] = "Y Offset"
-- -------------
-- CONDITION PANEL
-- -------------

L["CONDITIONPANEL_TITLE"] = "TellMeWhen Condition Editor"
L["ICONMENU_ADDCONDITION"] = "Add Condition"
L["ICONMENU_EDITCONDITION"] = "|cFFFF5959Edit|r Condition"
L["CONDITIONPANEL_ICON"] = "Icon Shown"
L["ICONTOCHECK"] = "Icon to check"
L["MOON"] = "Moon"
L["SUN"] = "Sun"
L["TRUE"] = "True"
L["FALSE"] = "False"
L["CONDITIONPANEL_TYPE"] = "Type"
L["CONDITIONPANEL_UNIT"] = "Unit"
L["CONDITIONPANEL_OPERATOR"] = "Operator"
L["CONDITIONPANEL_VALUE"] = "Percent"
L["CONDITIONPANEL_VALUEN"] = "Value"
L["CONDITIONPANEL_ANDOR"] = "And / Or"
L["CONDITIONPANEL_AND"] = "And"
L["CONDITIONPANEL_OR"] = "Or"
L["CONDITIONPANEL_POWER"] = "Primary Resource"
L["CONDITIONPANEL_COMBO"] = "Combo Points"
L["CONDITIONPANEL_EXISTS"] = "Unit Exists"
L["CONDITIONPANEL_EXISTS_DESC"] = "The condition will pass if the unit specified exists."
L["CONDITIONPANEL_ALIVE"] = "Unit is Alive"
L["CONDITIONPANEL_ALIVE_DESC"] = "The condition will pass if the unit specified is alive. Has a built-in Unit Exists check."
L["CONDITIONPANEL_COMBAT"] = "Unit in Combat"
L["CONDITIONPANEL_POWER_DESC"] = [=[Will check for energy if the unit is a druid in cat form,
rage if the unit is a warrior, etc.]=]
L["ECLIPSE_DIRECTION"] = "Eclipse Direction"
L["CONDITIONPANEL_ECLIPSE_DESC"] = [=[Eclipse has a range of -100 (a lunar eclipse) to 100 (a solar eclipse).
Input -80 if you want the icon to work with a value of 80 lunar power.]=]
L["CONDITIONPANEL_ICON_DESC"] = [=[The condition will pass if the icon specified is currently shown with an alpha above 0%, or hidden with an alpha of 0%.
If you don't want to display the icons that are being checked, check 'Fake Hidden' in the icon's alpha settings.
The group of the icon being checked must also be shown in order to check the icon, even if it is checking if the icon is hidden.]=]
L["CONDITIONPANEL_PVPFLAG"] = "Unit is PvP Flagged"
L["CONDITIONPANEL_EQUALS"] = "Equals"
L["CONDITIONPANEL_NOTEQUAL"] = "Not Equal to"
L["CONDITIONPANEL_LESS"] = "Less Than"
L["CONDITIONPANEL_LESSEQUAL"] = "Less Than or Equal to"
L["CONDITIONPANEL_GREATER"] = "Greater Than"
L["CONDITIONPANEL_GREATEREQUAL"] = "Greater Than or Equal to"

-- ----------
-- STUFF THAT I GOT SICK OF ADDING PREFIXES TOO AND PUTTING IN THE RIGHT PLACE
-- ----------

L["GROUPICON"] = "Group: %s, Icon: %d"
L["COPYPANEL_GROUP"] = "Group: "
L["GROUP"] = "Group "
L["COPYPANEL_ICON"] = "Icon: "
L["FROM"] = "From:"
L["TO"] = "To:"
L["COPY"] = "Copy"
L["ENABLED"] = "Enabled"
L["DISABLED"] = "Disabled"
L["COPYGROUPICON"] = "Copy group/icon"
L["COPYPOS"] = "Copy position/scale"
L["COPYALL"] = "Copy entire group"
L["GROUPSETTINGS"] = "Group settings"
L["COPYICON"] = "Icon "





-- --------
-- EQUIVS
-- --------

L["CrowdControl"] = "Crowd Control"
L["Bleeding"] = "Bleeding"
L["Feared"] = "Fear"
L["Incapacitated"] = "Incapacitated"
L["Stunned"] = "Stunned"
--L["DontMelee"] = "Dont Melee"
L["ImmuneToStun"] = "Immune To Stun"
L["ImmuneToMagicCC"] = "Immune To Magic CC"
--L["MovementSlowed"] = "Movement Slowed"
L["Disoriented"] = "Disoriented"
L["Silenced"] = "Silenced"
L["Disarmed"] = "Disarmed"
L["Rooted"] = "Rooted"
L["IncreasedStats"] = "Stats"
L["IncreasedDamage"] = "Damage Done"
L["IncreasedCrit"] = "Crit Chance"
L["IncreasedAP"] = "Attack Power"
L["IncreasedSPsix"] = "Spellpower (6%)"
L["IncreasedSPten"] = "Spellpower (10%)"
L["IncreasedPhysHaste"] = "Physical Haste"
L["IncreasedSpellHaste"] = "Spell Haste"
L["BurstHaste"] = "Heroism/Bloodlust"
L["BonusAgiStr"] = "Agility/Strength"
L["BonusStamina"] = "Stamina"
L["BonusArmor"] = "Armor"
L["BonusMana"] = "Mana Pool"
L["ManaRegen"] = "Mana Regen"
L["BurstManaRegen"] = "Burst Mana Regen"
L["PushbackResistance"] = "Pushback Resistance"
L["Resistances"] = "Spell Resistance"
L["PhysicalDmgTaken"] = "Physical Damage Taken"
L["SpellDamageTaken"] = "Spell Damage Taken"
L["SpellCritTaken"] = "Spell Crit Chance"
L["BleedDamageTaken"] = "Bleed Damage Taken"
L["ReducedAttackSpeed"] = "Attack Speed"
L["ReducedCastingSpeed"] = "Casting Speed"
L["ReducedArmor"] = "Armor"
L["ReducedHealing"] = "Healing"
L["ReducedPhysicalDone"] = "Physical Damage Done"

L["Heals"] = "Player Heals"
L["PvPSpells"] = "PvP Crowd Control, etc."
L["Tier11Interrupts"] = "Tier 11 Interruptables"

L["Magic"] = "Magic"
L["Curse"] = "Curse"
L["Disease"] = "Disease"
L["Poison"] = "Poison"


